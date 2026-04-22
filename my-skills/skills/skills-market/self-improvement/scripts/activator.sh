#!/bin/bash
# Self-Improvement Activator (CatPaw Desk)
# Emits a lightweight reminder to evaluate learning capture.

set -e

cat << 'EOF'
<self-improvement-reminder>
Task checkpoint: decide whether this run produced reusable learnings.
- User correction?
- Tool/command failure requiring investigation?
- Better repeatable approach discovered?
- Pattern recurring across tasks?

If yes, log to .learnings/.
If cross-session value exists, promote to memory or extract a skill.
</self-improvement-reminder>
EOF
