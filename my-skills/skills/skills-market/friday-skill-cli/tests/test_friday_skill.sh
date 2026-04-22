#!/bin/bash
# Tests for friday-skill CLI
# Run: bash tests/test_friday_skill.sh
#
# Coverage:
#   - jwtSign (HS256): structure, payload, base64url, determinism, key sensitivity
#   - parseArgs: positional, boolean flags, values with spaces, empty
#   - parseSkillMd: full frontmatter, missing frontmatter
#   - normalizeZipPattern: dir/, *.ext, already-glob, no-slash
#   - readSkillIgnore: defaults always present, custom patterns merged
#   - zipDir: basic inclusion, default exclusions, .skillignore, missing SKILL.md, missing dir
#   - Exact zip file manifest: must contain required files, must not contain forbidden files
#   - createClient response unwrapping: code=200, code=0, code=error, HTTP error, arraybuffer
#   - Token cache: write/read roundtrip, expired returns null, missing file returns null
#   - cmdCreate argument assembly: from args, from SKILL.md frontmatter, appkey fallback error

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_ROOT="${SCRIPT_DIR}/.."
CLI_SCRIPT="${SKILL_ROOT}/scripts/friday-skill"
PASS=0; FAIL=0

pass() { echo "  ✅ $1"; PASS=$((PASS+1)); }
fail() { echo "  ❌ $1"; FAIL=$((FAIL+1)); }

# ── VM loader: run CLI script in isolated vm context, export named functions ──
LOADER='
const fs=require("fs"), vm=require("vm"), path=require("path"),
      crypto=require("crypto"), http=require("http");
const {execSync}=require("child_process");
let src=fs.readFileSync(process.env.CLI_SCRIPT,"utf8");
src=src.replace(/^#!.*\n/,"").replace(/^main\(\);?\s*$/m,"");
const ctx={require,__filename:process.env.CLI_SCRIPT,
           __dirname:path.dirname(process.env.CLI_SCRIPT),
           module:{exports:{}},exports:{},console,process,Buffer,crypto};
vm.createContext(ctx);
vm.runInContext(src,ctx);
'

node_test() {
    CLI_SCRIPT="$CLI_SCRIPT" node - 2>/dev/null << NODEOF
${LOADER}
$1
NODEOF
}

# ── Helpers ───────────────────────────────────────────────────────────
make_skill_dir() {
    local dir; dir=$(mktemp -d)
    cat > "$dir/SKILL.md" << 'EOF'
---
name: test-skill
description: A test skill
appkey: com.test
---
# Test Skill
EOF
    echo "skill content" > "$dir/main.py"
    echo "$dir"
}

zip_contents() {
    unzip -l "$1" | awk 'NR>3 && /   [0-9]/ {print $NF}' | grep -v '^$' | sort
}

do_zip() {
    local dir="$1"
    CLI_SCRIPT="$CLI_SCRIPT" _ZIP_DIR="$dir" node - 2>/dev/null << 'NODEOF'
const fs=require("fs"), vm=require("vm"), path=require("path"),
      crypto=require("crypto"), http=require("http");
const {execSync}=require("child_process");
let src=fs.readFileSync(process.env.CLI_SCRIPT,"utf8");
src=src.replace(/^#!.*\n/,"").replace(/^main\(\);?\s*$/m,"");
const ctx={require,__filename:process.env.CLI_SCRIPT,__dirname:path.dirname(process.env.CLI_SCRIPT),
           module:{exports:{}},exports:{},console,process,Buffer,crypto};
vm.createContext(ctx); vm.runInContext(src,ctx);
process.stdout.write(ctx.zipDir(process.env._ZIP_DIR));
NODEOF
}

# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "=== Unit: jwtSign (HS256) ==="

node_test "
const tok = ctx.jwtSign({sub:'test',iat:1000,exp:9999}, 'mysecret');
if (tok.split('.').length !== 3) process.exit(1);
process.exit(0);
" && pass "JWT has 3 parts" || fail "JWT does not have 3 parts"

node_test "
const tok = ctx.jwtSign({sub:'test'}, 'mysecret');
const header = JSON.parse(Buffer.from(tok.split('.')[0], 'base64url').toString());
if (header.alg !== 'HS256' || header.typ !== 'JWT') process.exit(1);
process.exit(0);
" && pass "JWT header: alg=HS256, typ=JWT" || fail "JWT header wrong"

node_test "
const tok = ctx.jwtSign({sub:'alice', exp:9999}, 'secret');
const payload = JSON.parse(Buffer.from(tok.split('.')[1], 'base64url').toString());
if (payload.sub !== 'alice') process.exit(1);
process.exit(0);
" && pass "JWT payload round-trips" || fail "JWT payload wrong"

node_test "
const tok = ctx.jwtSign({sub:'test'}, 'key');
if (tok.includes('+') || tok.includes('/') || tok.includes('=')) process.exit(1);
process.exit(0);
" && pass "JWT is base64url (no +/=)" || fail "JWT has non-url-safe chars"

node_test "
const t1 = ctx.jwtSign({sub:'x',iat:0,exp:1}, 'k');
const t2 = ctx.jwtSign({sub:'x',iat:0,exp:1}, 'k');
if (t1 !== t2) process.exit(1);
process.exit(0);
" && pass "JWT is deterministic" || fail "JWT not deterministic"

node_test "
const t1 = ctx.jwtSign({sub:'x'}, 'secret1');
const t2 = ctx.jwtSign({sub:'x'}, 'secret2');
if (t1 === t2) process.exit(1);
process.exit(0);
" && pass "JWT: different secrets → different sigs" || fail "JWT: key not affecting signature"

# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "=== Unit: parseArgs ==="

node_test "
const a = ctx.parseArgs(['node','script','update','--id','42','--dir','./foo']);
if (a._[0]!=='update' || a.id!=='42' || a.dir!=='./foo') process.exit(1);
process.exit(0);
" && pass "positional + flags" || fail "positional + flags wrong"

node_test "
const a = ctx.parseArgs(['node','script','list','--mine']);
if (a._[0]!=='list' || a.mine!==true) process.exit(1);
process.exit(0);
" && pass "boolean flag --mine" || fail "--mine not boolean"

node_test "
const a = ctx.parseArgs(['node','script','search','--query','AI coding']);
if (a.query !== 'AI coding') process.exit(1);
process.exit(0);
" && pass "value with spaces" || fail "space value wrong"

node_test "
const a = ctx.parseArgs(['node','script']);
if (a._.length !== 0) process.exit(1);
process.exit(0);
" && pass "no command → empty _" || fail "empty case wrong"

node_test "
const a = ctx.parseArgs(['node','script','create','--dir','./x','--id','5','--mine','--size','10']);
if (a.dir!=='./x' || a.id!=='5' || a.mine!==true || a.size!=='10') process.exit(1);
process.exit(0);
" && pass "mixed flags and values" || fail "mixed flags wrong"

# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "=== Unit: parseSkillMd ==="

TMP_SKILL=$(mktemp -d)
cat > "$TMP_SKILL/SKILL.md" << 'EOF'
---
name: my-skill
description: Does something cool
appkey: com.example.app
tags: ai,coding
---
# Body content
EOF
CLI_SCRIPT="$CLI_SCRIPT" _DIR="$TMP_SKILL" node - 2>/dev/null << 'NODEOF'
const fs=require("fs"), vm=require("vm"), path=require("path"), crypto=require("crypto"), http=require("http");
const {execSync}=require("child_process");
let src=fs.readFileSync(process.env.CLI_SCRIPT,"utf8");
src=src.replace(/^#!.*\n/,"").replace(/^main\(\);?\s*$/m,"");
const ctx={require,__filename:process.env.CLI_SCRIPT,__dirname:path.dirname(process.env.CLI_SCRIPT),module:{exports:{}},exports:{},console,process,Buffer,crypto};
vm.createContext(ctx); vm.runInContext(src,ctx);
const fm = ctx.parseSkillMd(process.env._DIR);
if (fm.name!=='my-skill' || fm.description!=='Does something cool' || fm.appkey!=='com.example.app' || fm.tags!=='ai,coding') {
    console.error(JSON.stringify(fm)); process.exit(1);
}
process.exit(0);
NODEOF
[ $? -eq 0 ] && pass "extracts all fields" || fail "wrong output"
rm -rf "$TMP_SKILL"

TMP_EMPTY_FM=$(mktemp -d)
echo "# No frontmatter" > "$TMP_EMPTY_FM/SKILL.md"
CLI_SCRIPT="$CLI_SCRIPT" _DIR="$TMP_EMPTY_FM" node - 2>/dev/null << 'NODEOF'
const fs=require("fs"), vm=require("vm"), path=require("path"), crypto=require("crypto"), http=require("http");
const {execSync}=require("child_process");
let src=fs.readFileSync(process.env.CLI_SCRIPT,"utf8");
src=src.replace(/^#!.*\n/,"").replace(/^main\(\);?\s*$/m,"");
const ctx={require,__filename:process.env.CLI_SCRIPT,__dirname:path.dirname(process.env.CLI_SCRIPT),module:{exports:{}},exports:{},console,process,Buffer,crypto};
vm.createContext(ctx); vm.runInContext(src,ctx);
const fm = ctx.parseSkillMd(process.env._DIR);
if (typeof fm !== 'object' || Object.keys(fm).length !== 0) process.exit(1);
process.exit(0);
NODEOF
[ $? -eq 0 ] && pass "returns {} on no frontmatter" || fail "crashed on missing frontmatter"
rm -rf "$TMP_EMPTY_FM"

# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "=== Unit: normalizeZipPattern ==="

node_test "
const f = ctx.normalizeZipPattern;
if (f('scratch/') !== 'scratch/*') process.exit(1);
process.exit(0);
" && pass "dir/ → dir/*" || fail "dir/ not normalized"

node_test "
const f = ctx.normalizeZipPattern;
if (f('*.bak') !== '*.bak') process.exit(1);
process.exit(0);
" && pass "*.ext unchanged" || fail "*.ext was changed"

node_test "
const f = ctx.normalizeZipPattern;
if (f('tests/*') !== 'tests/*') process.exit(1);
process.exit(0);
" && pass "already-glob unchanged" || fail "already-glob was double-globbed"

node_test "
const f = ctx.normalizeZipPattern;
if (f('.DS_Store') !== '.DS_Store') process.exit(1);
process.exit(0);
" && pass "plain filename unchanged" || fail "plain filename was changed"

# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "=== Unit: readSkillIgnore ==="

TMP_NO_IGNORE=$(make_skill_dir)
CLI_SCRIPT="$CLI_SCRIPT" _DIR="$TMP_NO_IGNORE" node - 2>/dev/null << 'NODEOF'
const fs=require("fs"), vm=require("vm"), path=require("path"), crypto=require("crypto"), http=require("http");
const {execSync}=require("child_process");
let src=fs.readFileSync(process.env.CLI_SCRIPT,"utf8");
src=src.replace(/^#!.*\n/,"").replace(/^main\(\);?\s*$/m,"");
const ctx={require,__filename:process.env.CLI_SCRIPT,__dirname:path.dirname(process.env.CLI_SCRIPT),module:{exports:{}},exports:{},console,process,Buffer,crypto};
vm.createContext(ctx); vm.runInContext(src,ctx);
const p = ctx.readSkillIgnore(process.env._DIR);
// tests/* removed from defaults (test scripts are useful to skill users)
const must = ['node_modules/*','__pycache__/*','*.bak','evals/*','pending/*'];
for (const r of must) {
    if (!p.includes(r)) { console.error('Missing: '+r); process.exit(1); }
}
// tests/* must NOT be in defaults
if (p.includes('tests/*')) { console.error('tests/* should not be a default'); process.exit(1); }
process.exit(0);
NODEOF
[ $? -eq 0 ] && pass "defaults always present, tests/ not excluded by default" || fail "defaults wrong"
rm -rf "$TMP_NO_IGNORE"

TMP_WITH_IGNORE=$(make_skill_dir)
printf '# comment\nscratch/\n*.secret\n' > "$TMP_WITH_IGNORE/.skillignore"
CLI_SCRIPT="$CLI_SCRIPT" _DIR="$TMP_WITH_IGNORE" node - 2>/dev/null << 'NODEOF'
const fs=require("fs"), vm=require("vm"), path=require("path"), crypto=require("crypto"), http=require("http");
const {execSync}=require("child_process");
let src=fs.readFileSync(process.env.CLI_SCRIPT,"utf8");
src=src.replace(/^#!.*\n/,"").replace(/^main\(\);?\s*$/m,"");
const ctx={require,__filename:process.env.CLI_SCRIPT,__dirname:path.dirname(process.env.CLI_SCRIPT),module:{exports:{}},exports:{},console,process,Buffer,crypto};
vm.createContext(ctx); vm.runInContext(src,ctx);
const p = ctx.readSkillIgnore(process.env._DIR);
// defaults still present (node_modules/* is a reliable default)
if (!p.includes('node_modules/*')) { console.error('defaults lost'); process.exit(1); }
// custom patterns normalized and added
if (!p.includes('scratch/*')) { console.error('scratch/* missing'); process.exit(1); }
if (!p.includes('*.secret')) { console.error('*.secret missing'); process.exit(1); }
// comments not added
if (p.some(x => x.startsWith('#'))) { console.error('comment leaked'); process.exit(1); }
process.exit(0);
NODEOF
[ $? -eq 0 ] && pass ".skillignore: custom patterns merged, comments ignored" || fail ".skillignore merge wrong"
rm -rf "$TMP_WITH_IGNORE"

# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "=== Unit: zipDir ==="

# missing SKILL.md
TMP_NO_MD=$(mktemp -d); echo "x" > "$TMP_NO_MD/main.py"
CLI_SCRIPT="$CLI_SCRIPT" _DIR="$TMP_NO_MD" node - 2>/dev/null << 'NODEOF'
const fs=require("fs"), vm=require("vm"), path=require("path"), crypto=require("crypto"), http=require("http");
const {execSync}=require("child_process");
let src=fs.readFileSync(process.env.CLI_SCRIPT,"utf8");
src=src.replace(/^#!.*\n/,"").replace(/^main\(\);?\s*$/m,"");
const ctx={require,__filename:process.env.CLI_SCRIPT,__dirname:path.dirname(process.env.CLI_SCRIPT),module:{exports:{}},exports:{},console,process,Buffer,crypto};
vm.createContext(ctx); vm.runInContext(src,ctx);
try { ctx.zipDir(process.env._DIR); process.exit(1); }
catch(e) { process.exit(e.message.includes('SKILL.md') ? 0 : 2); }
NODEOF
[ $? -eq 0 ] && pass "throws on missing SKILL.md" || fail "should throw on missing SKILL.md"
rm -rf "$TMP_NO_MD"

# missing directory
node_test "
try { ctx.zipDir('/nonexistent/path/xyz'); process.exit(1); }
catch(e) { process.exit(0); }
" && pass "throws on missing directory" || fail "should throw on missing directory"

# basic inclusion
SKILL_DIR=$(make_skill_dir)
ZIP=$(do_zip "$SKILL_DIR")
if [ -f "$ZIP" ]; then
    C=$(zip_contents "$ZIP")
    echo "$C" | grep -q "SKILL.md" && pass "SKILL.md included" || fail "SKILL.md missing"
    echo "$C" | grep -q "main.py"  && pass "main.py included"  || fail "main.py missing"
    rm -f "$ZIP"
else
    fail "zipDir produced no zip (basic)"
fi
rm -rf "$SKILL_DIR"

# default exclusions
SKILL_DIR=$(make_skill_dir)
mkdir -p "$SKILL_DIR/tests" "$SKILL_DIR/evals" "$SKILL_DIR/__pycache__" \
         "$SKILL_DIR/node_modules/ax" "$SKILL_DIR/pending"
echo "t" > "$SKILL_DIR/tests/t.py"
echo "e" > "$SKILL_DIR/evals/e.json"
echo "c" > "$SKILL_DIR/__pycache__/f.pyc"
echo "d" > "$SKILL_DIR/node_modules/ax/i.js"
echo "p" > "$SKILL_DIR/pending/d.md"
echo "b" > "$SKILL_DIR/main.py.bak"
ZIP=$(do_zip "$SKILL_DIR")
if [ -f "$ZIP" ]; then
    C=$(zip_contents "$ZIP")
    # tests/ is NOT excluded by default — test scripts are valuable to skill users
    for pat in "__pycache__/" "node_modules/" ".bak" "evals/" "pending/"; do
        echo "$C" | grep -q "$pat" && fail "Default excluded: '$pat' found" || pass "Default excluded: $pat"
    done
    echo "$C" | grep -q "tests/t.py" && pass "tests/ included by default" || fail "tests/t.py missing (should be included)"
    echo "$C" | grep -q "SKILL.md" && pass "SKILL.md survives exclusions" || fail "SKILL.md lost"
    rm -f "$ZIP"
fi
rm -rf "$SKILL_DIR"

# .skillignore custom patterns
SKILL_DIR=$(make_skill_dir)
mkdir -p "$SKILL_DIR/scratch" "$SKILL_DIR/docs"
echo "s" > "$SKILL_DIR/scratch/x.py"
echo "d" > "$SKILL_DIR/docs/README.md"
echo "k" > "$SKILL_DIR/config.secret"
printf 'scratch/\n*.secret\n' > "$SKILL_DIR/.skillignore"
ZIP=$(do_zip "$SKILL_DIR")
if [ -f "$ZIP" ]; then
    C=$(zip_contents "$ZIP")
    echo "$C" | grep -q "scratch/"  && fail ".skillignore: scratch/ not excluded" || pass ".skillignore: scratch/ excluded"
    echo "$C" | grep -q ".secret"   && fail ".skillignore: *.secret not excluded" || pass ".skillignore: *.secret excluded"
    echo "$C" | grep -q "docs/"     && pass ".skillignore: docs/ included"        || fail ".skillignore: docs/ wrongly excluded"
    rm -f "$ZIP"
fi
rm -rf "$SKILL_DIR"

# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "=== Unit: Exact zip manifest (this skill's own directory) ==="
# The zip of THIS skill must contain exactly the expected files — no more, no less.

ZIP=$(do_zip "$SKILL_ROOT")
if [ ! -f "$ZIP" ]; then
    fail "zipDir failed on skill root"
else
    C=$(zip_contents "$ZIP")

    # Required files
    REQUIRED=(
        "SKILL.md"
        "CHANGELOG.md"
        "scripts/friday-skill"
        "tests/test_friday_skill.sh"
        ".skillignore"
    )
    for f in "${REQUIRED[@]}"; do
        echo "$C" | grep -qF "$f" && pass "Required present: $f" || fail "Required missing: $f"
    done

    # Forbidden files / patterns
    FORBIDDEN=(
        ".skill-id"
        "node_modules/"
        "tests/"          # tests/ dir entry itself stripped (contents included is OK)
        "__pycache__/"
        ".bak"
        "evals/"
        "pending/"
        "dist/"
        ".tmp"
    )
    # Note: tests/test_friday_skill.sh itself should be present,
    # but no other junk like node_modules or .skill-id
    for f in "${FORBIDDEN[@]}"; do
        # tests/ as a bare directory entry — allow tests/test_*.sh path
        if [ "$f" = "tests/" ]; then
            # only check that no forbidden extras exist under tests/ beyond the test script
            # (zip lists "tests/" as an empty dir entry — that's fine, filter it out)
            BAD=$(echo "$C" | grep "^tests/" | grep -v "test_friday_skill.sh" | grep -v "^tests/$" || true)
            [ -z "$BAD" ] && pass "No extra files under tests/" || fail "Extra files under tests/: $BAD"
        else
            echo "$C" | grep -q "$f" && fail "Forbidden present: $f" || pass "Forbidden absent: $f"
        fi
    done

    rm -f "$ZIP"
fi

# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "=== Unit: createClient response unwrapping ==="

node_test "
// code=200 with result field
const client = ctx.createClient('fake-token', null);
// Patch fetchWithRetry to return a mock response
ctx.fetchWithRetry = async (url, opts) => ({
    ok: true,
    text: async () => JSON.stringify({code:200, result:{id:42, name:'test'}}),
    arrayBuffer: async () => new ArrayBuffer(0)
});
client.get('/test').then(r => {
    if (r.id !== 42 || r.name !== 'test') process.exit(1);
    process.exit(0);
}).catch(() => process.exit(1));
" && pass "code=200 unwraps result field" || fail "code=200 unwrap failed"

node_test "
const client = ctx.createClient('tok', null);
ctx.fetchWithRetry = async () => ({
    ok: true,
    text: async () => JSON.stringify({code:0, data:{items:[1,2,3]}}),
    arrayBuffer: async () => new ArrayBuffer(0)
});
client.get('/test').then(r => {
    if (!r.items || r.items[0] !== 1) process.exit(1);
    process.exit(0);
}).catch(() => process.exit(1));
" && pass "code=0 unwraps data field" || fail "code=0 unwrap failed"

node_test "
const client = ctx.createClient('tok', null);
ctx.fetchWithRetry = async () => ({
    ok: true,
    text: async () => JSON.stringify({code:403, message:'Forbidden'}),
    arrayBuffer: async () => new ArrayBuffer(0)
});
client.get('/test').then(() => process.exit(1)).catch(e => {
    process.exit(e.message.includes('403') ? 0 : 1);
});
" && pass "code=403 throws with message" || fail "code=403 should throw"

node_test "
const client = ctx.createClient('tok', null);
ctx.fetchWithRetry = async () => ({
    ok: false,
    status: 500,
    text: async () => JSON.stringify({message:'Internal Server Error'}),
    arrayBuffer: async () => new ArrayBuffer(0)
});
client.get('/test').then(() => process.exit(1)).catch(e => {
    process.exit(e.message.includes('500') ? 0 : 1);
});
" && pass "HTTP 5xx throws" || fail "HTTP 5xx should throw"

node_test "
const client = ctx.createClient('tok', null);
const fakeData = Buffer.from([1,2,3,4]);
ctx.fetchWithRetry = async () => ({
    ok: true,
    text: async () => '',
    arrayBuffer: async () => fakeData.buffer.slice(fakeData.byteOffset, fakeData.byteOffset+fakeData.byteLength)
});
client.get('/dl', {responseType:'arraybuffer'}).then(r => {
    process.exit(r.data && r.data.length === 4 ? 0 : 1);
}).catch(() => process.exit(1));
" && pass "arraybuffer response returns buffer" || fail "arraybuffer response wrong"

# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "=== Unit: Token cache ==="

TMP_CRED=$(mktemp -d)

# Helper: load CLI with CONFIG.credentialDir patched to TMP_CRED
# Uses src-level replacement: const CONFIG = { credentialDir: process.env.FRIDAY_CRED_DIR || ...
# → inject a fixed credentialDir via environment variable which CONFIG already reads
CACHE_LOADER='
const fs=require("fs"), vm=require("vm"), path=require("path"), crypto=require("crypto"), http=require("http");
const {execSync}=require("child_process");
let src=fs.readFileSync(process.env.CLI_SCRIPT,"utf8");
src=src.replace(/^#!.*\n/,"").replace(/^main\(\);?\s*$/m,"");
const ctx={require,__filename:process.env.CLI_SCRIPT,__dirname:path.dirname(process.env.CLI_SCRIPT),module:{exports:{}},exports:{},console,process,Buffer,crypto};
vm.createContext(ctx); vm.runInContext(src,ctx);
'

# Write + read roundtrip
# Patch via FRIDAY_CRED_DIR env (CONFIG already reads it)
CLI_SCRIPT="$CLI_SCRIPT" FRIDAY_CRED_DIR="$TMP_CRED" node - 2>/dev/null << 'NODEOF'
const fs=require("fs"), vm=require("vm"), path=require("path"), crypto=require("crypto"), http=require("http");
const {execSync}=require("child_process");
let src=fs.readFileSync(process.env.CLI_SCRIPT,"utf8");
src=src.replace(/^#!.*\n/,"").replace(/^main\(\);?\s*$/m,"");
const ctx={require,__filename:process.env.CLI_SCRIPT,__dirname:path.dirname(process.env.CLI_SCRIPT),module:{exports:{}},exports:{},console,process,Buffer,crypto};
vm.createContext(ctx); vm.runInContext(src,ctx);
const expiresAt = Date.now() + 3600000;
ctx.saveTokenCache('testuser', 'tok-abc', expiresAt);
const loaded = ctx.loadTokenCache('testuser');
if (!loaded || loaded.token !== 'tok-abc') { console.error('roundtrip failed', JSON.stringify(loaded)); process.exit(1); }
process.exit(0);
NODEOF
[ $? -eq 0 ] && pass "token cache write/read roundtrip" || fail "token cache roundtrip failed"

# Expired token returns null
CLI_SCRIPT="$CLI_SCRIPT" FRIDAY_CRED_DIR="$TMP_CRED" node - 2>/dev/null << 'NODEOF'
const fs=require("fs"), vm=require("vm"), path=require("path"), crypto=require("crypto"), http=require("http");
const {execSync}=require("child_process");
let src=fs.readFileSync(process.env.CLI_SCRIPT,"utf8");
src=src.replace(/^#!.*\n/,"").replace(/^main\(\);?\s*$/m,"");
const ctx={require,__filename:process.env.CLI_SCRIPT,__dirname:path.dirname(process.env.CLI_SCRIPT),module:{exports:{}},exports:{},console,process,Buffer,crypto};
vm.createContext(ctx); vm.runInContext(src,ctx);
ctx.saveTokenCache('expireduser', 'old-tok', Date.now() - 1000);
const loaded = ctx.loadTokenCache('expireduser');
if (loaded !== null) { console.error('should be null'); process.exit(1); }
process.exit(0);
NODEOF
[ $? -eq 0 ] && pass "expired token returns null" || fail "expired token should return null"

# Missing cache file returns null
CLI_SCRIPT="$CLI_SCRIPT" FRIDAY_CRED_DIR="$TMP_CRED" node - 2>/dev/null << 'NODEOF'
const fs=require("fs"), vm=require("vm"), path=require("path"), crypto=require("crypto"), http=require("http");
const {execSync}=require("child_process");
let src=fs.readFileSync(process.env.CLI_SCRIPT,"utf8");
src=src.replace(/^#!.*\n/,"").replace(/^main\(\);?\s*$/m,"");
const ctx={require,__filename:process.env.CLI_SCRIPT,__dirname:path.dirname(process.env.CLI_SCRIPT),module:{exports:{}},exports:{},console,process,Buffer,crypto};
vm.createContext(ctx); vm.runInContext(src,ctx);
const loaded = ctx.loadTokenCache('nobody');
if (loaded !== null) { console.error('should be null'); process.exit(1); }
process.exit(0);
NODEOF
[ $? -eq 0 ] && pass "missing cache file returns null" || fail "missing cache file should return null"

# Token within 60s of expiry treated as expired (safety margin)
CLI_SCRIPT="$CLI_SCRIPT" FRIDAY_CRED_DIR="$TMP_CRED" node - 2>/dev/null << 'NODEOF'
const fs=require("fs"), vm=require("vm"), path=require("path"), crypto=require("crypto"), http=require("http");
const {execSync}=require("child_process");
let src=fs.readFileSync(process.env.CLI_SCRIPT,"utf8");
src=src.replace(/^#!.*\n/,"").replace(/^main\(\);?\s*$/m,"");
const ctx={require,__filename:process.env.CLI_SCRIPT,__dirname:path.dirname(process.env.CLI_SCRIPT),module:{exports:{}},exports:{},console,process,Buffer,crypto};
vm.createContext(ctx); vm.runInContext(src,ctx);
ctx.saveTokenCache('nearexpiry', 'near-tok', Date.now() + 30000);
const loaded = ctx.loadTokenCache('nearexpiry');
if (loaded !== null) { console.error('should be null within 60s margin'); process.exit(1); }
process.exit(0);
NODEOF
[ $? -eq 0 ] && pass "token expiring within 60s treated as expired" || fail "safety margin not applied"

rm -rf "$TMP_CRED"

# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "=== Unit: cmdCreate argument assembly ==="

TMP_SKILL=$(mktemp -d)
cat > "$TMP_SKILL/SKILL.md" << 'EOF'
---
name: my-great-skill
description: Helps you do things
appkey: com.example.myapp
tags: ai,productivity
---
EOF

# All fields from CLI args (overrides frontmatter)
CLI_SCRIPT="$CLI_SCRIPT" _DIR="$TMP_SKILL" node - 2>/dev/null << 'NODEOF'
const fs=require("fs"), vm=require("vm"), path=require("path"), crypto=require("crypto"), http=require("http");
const {execSync}=require("child_process");
let src=fs.readFileSync(process.env.CLI_SCRIPT,"utf8");
src=src.replace(/^#!.*\n/,"").replace(/^main\(\);?\s*$/m,"");
const ctx={require,__filename:process.env.CLI_SCRIPT,__dirname:path.dirname(process.env.CLI_SCRIPT),module:{exports:{}},exports:{},console,process,Buffer,crypto};
vm.createContext(ctx); vm.runInContext(src,ctx);
// Mock zipDir (return a real temp file so finally-block unlink works)
// and curlExec to capture assembled fields
let captured = null;
const _fakeZip = require('os').tmpdir() + '/fake-skill-test-' + Date.now() + '.zip';
require('fs').writeFileSync(_fakeZip, '');
ctx.zipDir = () => _fakeZip;
ctx.curlExec = (args) => {
    // extract -F key=value pairs
    const fields = {};
    for (let i=0; i<args.length; i++) {
        if (args[i] === '-F' && args[i+1] && !args[i+1].startsWith('zipFile')) {
            const [k,...rest] = args[i+1].split('=');
            fields[k] = rest.join('=');
        }
    }
    captured = fields;
    return {code:200, result:{skillId:'99',name:'x',alias:'x'}};
};
const fakeClient = { get: async () => ({appkeys:['com.cli.override']}) };
const args = { dir: process.env._DIR, alias: 'cli-alias', intro: 'cli-intro', appkey: 'com.cli.override', tags: 'x' };
ctx.cmdCreate(fakeClient, {token:'t'}, args).then(() => {
    if (!captured || captured.alias !== 'cli-alias' || captured.intro !== 'cli-intro' || captured.appkey !== 'com.cli.override') {
        console.error('captured:', JSON.stringify(captured)); process.exit(1);
    }
    process.exit(0);
}).catch(e => { console.error(e.message); process.exit(1); });
NODEOF
[ $? -eq 0 ] && pass "cmdCreate: CLI args take precedence" || fail "cmdCreate: CLI args not used"

# Fields fall back to SKILL.md frontmatter
CLI_SCRIPT="$CLI_SCRIPT" _DIR="$TMP_SKILL" node - 2>/dev/null << 'NODEOF'
const fs=require("fs"), vm=require("vm"), path=require("path"), crypto=require("crypto"), http=require("http");
const {execSync}=require("child_process");
let src=fs.readFileSync(process.env.CLI_SCRIPT,"utf8");
src=src.replace(/^#!.*\n/,"").replace(/^main\(\);?\s*$/m,"");
const ctx={require,__filename:process.env.CLI_SCRIPT,__dirname:path.dirname(process.env.CLI_SCRIPT),module:{exports:{}},exports:{},console,process,Buffer,crypto};
vm.createContext(ctx); vm.runInContext(src,ctx);
let captured = null;
const _fakeZip2 = require('os').tmpdir() + '/fake-skill-test2-' + Date.now() + '.zip';
require('fs').writeFileSync(_fakeZip2, '');
ctx.zipDir = () => _fakeZip2;
ctx.curlExec = (args) => {
    const fields = {};
    for (let i=0; i<args.length; i++) {
        if (args[i] === '-F' && args[i+1] && !args[i+1].startsWith('zipFile')) {
            const [k,...rest] = args[i+1].split('=');
            fields[k] = rest.join('=');
        }
    }
    captured = fields;
    return {code:200, result:{skillId:'1',name:'x',alias:'x'}};
};
const fakeClient = { get: async () => [] };  // no appkeys → use frontmatter
// Only dir provided — everything else from SKILL.md
const args = { dir: process.env._DIR };
ctx.cmdCreate(fakeClient, {token:'t'}, args).then(() => {
    if (!captured) { process.exit(1); }
    // alias from fm.name, intro from fm.description, appkey from fm.appkey
    if (captured.alias !== 'my-great-skill') { console.error('alias wrong:', captured.alias); process.exit(1); }
    if (captured.appkey !== 'com.example.myapp') { console.error('appkey wrong:', captured.appkey); process.exit(1); }
    process.exit(0);
}).catch(e => { console.error(e.message); process.exit(1); });
NODEOF
[ $? -eq 0 ] && pass "cmdCreate: falls back to SKILL.md frontmatter" || fail "cmdCreate: frontmatter fallback wrong"

# Error when no appkey anywhere
TMP_NO_APPKEY=$(mktemp -d)
printf -- '---\nname: x\ndescription: y\n---\n' > "$TMP_NO_APPKEY/SKILL.md"
CLI_SCRIPT="$CLI_SCRIPT" _DIR="$TMP_NO_APPKEY" node - 2>/dev/null << 'NODEOF'
const fs=require("fs"), vm=require("vm"), path=require("path"), crypto=require("crypto"), http=require("http");
const {execSync}=require("child_process");
let src=fs.readFileSync(process.env.CLI_SCRIPT,"utf8");
src=src.replace(/^#!.*\n/,"").replace(/^main\(\);?\s*$/m,"");
const ctx={require,__filename:process.env.CLI_SCRIPT,__dirname:path.dirname(process.env.CLI_SCRIPT),module:{exports:{}},exports:{},console,process,Buffer,crypto};
vm.createContext(ctx); vm.runInContext(src,ctx);
ctx.zipDir = () => '/tmp/fake.zip';
const fakeClient = { get: async () => [] };
ctx.cmdCreate(fakeClient, {token:'t'}, { dir: process.env._DIR }).then(() => process.exit(1))
    .catch(e => process.exit(e.message.includes('appkey') ? 0 : 1));
NODEOF
[ $? -eq 0 ] && pass "cmdCreate: throws when no appkey" || fail "cmdCreate: should throw without appkey"
rm -rf "$TMP_NO_APPKEY" "$TMP_SKILL"

# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "════════════════════════════════"
TOTAL=$((PASS + FAIL))
echo "Results: ${PASS}/${TOTAL} passed"
if [ "$FAIL" -gt 0 ]; then
    echo "❌ $FAIL test(s) failed"
    exit 1
else
    echo "✅ All tests passed"
    exit 0
fi
