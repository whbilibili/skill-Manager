#!/bin/bash
# Self-Improvement Error Detector (CatPaw Desk)
# Detects likely tool/command failures from output text.

set -e

# Prefer generic env var, fallback to legacy variable.
OUTPUT="${TOOL_OUTPUT:-${CLAUDE_TOOL_OUTPUT:-}}"

ERROR_PATTERNS=(
  "error:"
  "Error:"
  "ERROR:"
  "failed"
  "FAILED"
  "command not found"
  "No such file"
  "Permission denied"
  "fatal:"
  "Exception"
  "Traceback"
  "ModuleNotFoundError"
  "SyntaxError"
  "TypeError"
  "exit code"
  "non-zero"
)

contains_error=false
for pattern in "${ERROR_PATTERNS[@]}"; do
  if [[ "$OUTPUT" == *"$pattern"* ]]; then
    contains_error=true
    break
  fi
done

if [ "$contains_error" = true ]; then
  cat << 'EOF'
<error-detected>
A potential execution error was detected.
Consider logging to .learnings/ERRORS.md if it was non-obvious,
required investigation, or is likely to recur.
Use ID format: [ERR-YYYYMMDD-XXX]
</error-detected>
EOF
fi
