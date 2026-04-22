#!/bin/bash
#
# Draw.io XML Lint & Auto-Fix Tool
#
# 检测并自动修复以下问题：
#   1. XML 注释中的 --> (注释内箭头导致提前结束)
#   2. XML 注释中的 -- (双连字符，XML 规范禁止)
#   3. value 属性中的中文引号 "" ''（替换为 &quot; &apos;）
#
# 不自动修复（需人工处理）：
#   - 节点坐标重叠（逻辑复杂，输出警告提示）
#
# Usage:
#   bash lint_and_fix.sh <input.drawio>              # 原地修复
#   bash lint_and_fix.sh <input.drawio> <output.drawio>  # 输出到新文件
#
# Exit codes:
#   0  - 无问题 / 修复成功
#   1  - 存在无法自动修复的错误

set -euo pipefail

# ── 参数处理 ──────────────────────────────────────────────────────────────────
[ $# -lt 1 ] && echo "Usage: $0 <input.drawio> [output.drawio]" && exit 1

INPUT="$1"
OUTPUT="${2:-$INPUT}"
TMPFILE="${INPUT}.fix.tmp"

[ ! -f "$INPUT" ] && echo "Error: 文件 '$INPUT' 不存在" && exit 1
[ ! -r "$INPUT" ] && echo "Error: 文件 '$INPUT' 无读权限" && exit 1
[ "$OUTPUT" = "$INPUT" ] && [ ! -w "$INPUT" ] && echo "Error: 文件 '$INPUT' 无写权限" && exit 1

cp "$INPUT" "$TMPFILE"
trap 'rm -f "$TMPFILE" "${TMPFILE}.bak" "/tmp/drawio_lint_err.$$"' EXIT

FIXED=0
WARNINGS=0

echo "===== lint_and_fix: $INPUT ====="

# ── Fix 1+2: 注释中的非法 -- 和 --> ─────────────────────────────────────────
# XML 规范：注释内容不能包含 --（包括 --> 中的 --）
# 修复策略（perl 单次完成）：
#   对每一行中的注释块，将注释内容里的所有 -- 替换为 -（单横线）
#   这样 --> 变成 ->，-- 变成 -，均合法
#
# 检测：是否存在注释内含 -- 的行
if grep -q '<!--.*--' "$TMPFILE" 2>/dev/null; then
    echo "[Fix 1+2] 检测到注释中含有 -- 或 -->，正在修复..."
    if command -v perl >/dev/null 2>&1; then
        # perl：对每行，找到所有 <!-- ... --> 注释块，将内部的 -- 替换为 -
        perl -i -pe '
            s{(<!--)(.*?)(-->)}{
                my ($open, $body, $close) = ($1, $2, $3);
                $body =~ s{--}{-}g;
                $open . $body . $close
            }ge
        ' "$TMPFILE"
    else
        # sed 兜底：处理常见单行模式
        # <!-- A --xxx--> B --> 变成 <!-- A -xxx-> B ->
        sed -i.bak \
            -e 's/<!--\(.*\)--\([^>]\)/<!--\1-\2/g' \
            -e 's/<!--\(.*\)-->/<!\1->/g' \
            "$TMPFILE" 2>/dev/null || echo "  [Warn] sed 兜底修复失败，请检查文件"
    fi
    FIXED=$((FIXED + 1))
    echo "  [Fix 1+2] 完成"
fi

# ── Fix 3: value 属性中的中文引号 ────────────────────────────────────────────
if grep -q '[""'\'']' "$TMPFILE" 2>/dev/null; then
    echo "[Fix 3] 检测到中文引号，正在替换为 XML 实体..."
    # 中文左引号 " -> &quot;
    # 中文右引号 " -> &quot;
    # 中文左单引号 ' -> &apos;
    # 中文右单引号 ' -> &apos;
    if command -v perl >/dev/null 2>&1; then
        perl -i -pe '
            s/\x{201C}/&quot;/g;
            s/\x{201D}/&quot;/g;
            s/\x{2018}/&apos;/g;
            s/\x{2019}/&apos;/g;
        ' "$TMPFILE" 2>/dev/null || echo "  [Warn] perl 中文引号修复失败，请检查文件"
    else
        sed -i.bak \
            -e 's/\xe2\x80\x9c/\&quot;/g' \
            -e 's/\xe2\x80\x9d/\&quot;/g' \
            -e 's/\xe2\x80\x98/\&apos;/g' \
            -e 's/\xe2\x80\x99/\&apos;/g' \
            "$TMPFILE" 2>/dev/null || echo "  [Warn] sed 中文引号修复失败，请检查文件"
    fi
    FIXED=$((FIXED + 1))
    echo "  [Fix 3] 完成"
fi

# ── 清理 sed 备份文件 ─────────────────────────────────────────────────────────
rm -f "${TMPFILE}.bak"

# ── XML 语法校验 ──────────────────────────────────────────────────────────────
echo ""
echo "[Lint] 执行 XML 语法校验..."
if command -v xmllint >/dev/null 2>&1; then
    if ! xmllint --noout "$TMPFILE" 2>/tmp/drawio_lint_err.$$; then
        echo "  [Error] XML 仍然非法，请人工检查："
        cat /tmp/drawio_lint_err.$$
        rm -f /tmp/drawio_lint_err.$$ "$TMPFILE"
        exit 1
    fi
    rm -f /tmp/drawio_lint_err.$$
    echo "  [OK] XML 语法合法"
else
    echo "  [Skip] xmllint 未安装，跳过语法校验"
fi

# ── 节点重叠检测（仅报告，不自动修复）────────────────────────────────────────
# 用纯 awk 解析 mxCell vertex 节点的坐标，检测同一 parent 下的矩形重叠
# 依赖：awk（macOS/Linux 均内置）
echo ""
echo "[Lint] 检测节点重叠..."

awk '
# 从字符串中提取 attr="value"，匹配词边界（空格/tab/<开头）
# 兼容 macOS awk（不支持三参数 match 或 \b）
function get_attr(line, attr,    pat, pos, val, c) {
    # 在 line 中查找 " attr=" 或 "<attr=" 或行首 attr=
    # 策略：逐个尝试前缀 " "、"\t"，确保是完整属性名
    pat = " " attr "=\""
    pos = index(line, pat)
    if (pos == 0) {
        pat = "\t" attr "=\""
        pos = index(line, pat)
    }
    if (pos == 0) return ""
    val = substr(line, pos + length(pat))
    sub(/".*/, "", val)
    return val
}

BEGIN { n = 0; overlap = 0; in_cell = 0; buf = "" }

# 进入 mxCell 块：开始拼接
/<mxCell/ {
    in_cell = 1
    buf = $0
    # 单行 mxCell（含 />）直接处理
    if ($0 ~ />[ \t]*$/ || $0 ~ "/>") {
        # 检查是否完整（含 vertex 或 />）
    }
}

# 在 mxCell 块内：继续拼接
in_cell && !/mxCell/ && !/mxGeometry/ && !/\/mxCell/ {
    buf = buf " " $0
}

# mxGeometry 行：拼接到 buf，然后处理整个块
in_cell && /mxGeometry/ {
    buf = buf " " $0

    # 只处理 vertex="1" 的节点
    if (buf !~ /vertex="1"/) { in_cell = 0; buf = ""; next }

    id     = get_attr(buf, "id")
    parent = get_attr(buf, "parent")
    val    = get_attr(buf, "value")
    if (parent == "") parent = "1"
    if (length(val) > 20) val = substr(val, 1, 20)
    # 跳过根节点和连接线标签
    if (id == "0" || id == "1") { in_cell = 0; buf = ""; next }

    w = get_attr(buf, "width")  + 0
    h = get_attr(buf, "height") + 0
    if (w == 0 || h == 0) { in_cell = 0; buf = ""; next }

    id_arr[n]  = id
    par_arr[n] = parent
    val_arr[n] = val
    x_arr[n]   = get_attr(buf, "x") + 0
    y_arr[n]   = get_attr(buf, "y") + 0
    w_arr[n]   = w
    h_arr[n]   = h
    n++
    in_cell = 0; buf = ""
}

# 遇到 </mxCell> 结束块（无 mxGeometry 的节点，如边）
/\/mxCell/ { in_cell = 0; buf = "" }

END {
    for (i = 0; i < n; i++) {
        for (j = i + 1; j < n; j++) {
            if (par_arr[i] != par_arr[j]) continue
            ax1 = x_arr[i]; ay1 = y_arr[i]; ax2 = ax1+w_arr[i]; ay2 = ay1+h_arr[i]
            bx1 = x_arr[j]; by1 = y_arr[j]; bx2 = bx1+w_arr[j]; by2 = by1+h_arr[j]
            if (ax1 < bx2 && bx1 < ax2 && ay1 < by2 && by1 < ay2) {
                if (overlap == 0) print "  [Warning] 发现节点重叠（需人工修复坐标）："
                overlap++
                printf "    parent=%s: id=%s(%s) 与 id=%s(%s) 重叠\n",
                    par_arr[i], id_arr[i], val_arr[i], id_arr[j], val_arr[j]
                printf "      A: x=%g y=%g w=%g h=%g (右下角 x=%g y=%g)\n",
                    ax1, ay1, w_arr[i], h_arr[i], ax2, ay2
                printf "      B: x=%g y=%g w=%g h=%g (右下角 x=%g y=%g)\n",
                    bx1, by1, w_arr[j], h_arr[j], bx2, by2
            }
        }
    }
    if (overlap == 0) print "  [OK] 无节点重叠"
}
' "$TMPFILE"

# ── 写入输出 ──────────────────────────────────────────────────────────────────
echo ""
if [ "$FIXED" -gt 0 ]; then
    cp "$TMPFILE" "$OUTPUT"
    echo "===== 修复完成：共修复 $FIXED 类问题，已写入 $OUTPUT ====="
else
    echo "===== 无需修复，文件已通过检查 ====="
fi

rm -f "$TMPFILE"
exit 0
