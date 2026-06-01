#!/bin/bash
# file-protector.sh — PreToolUse hook
# Prevents agents from editing protected paths:
#   .claude/   .mcp.json   CLAUDE.md (any case)

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')

# Only applies to file-writing tools
case "$TOOL" in
  Edit|Write|NotebookEdit) ;;
  *) exit 0 ;;
esac

FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [ -z "$FILE" ]; then
  exit 0
fi

# Normalise to an absolute path for reliable prefix matching
REAL=$(realpath -m "$FILE" 2>/dev/null || echo "$FILE")

# ── Protected path definitions ────────────────────────────────────────────────
PROTECTED_DIRS=(
  "$HOME/.claude"
  "$(pwd)/.claude"
)

PROTECTED_FILES=(
  "$(pwd)/.mcp.json"
  "$HOME/.mcp.json"
  "$(pwd)/CLAUDE.md"
  "$(pwd)/claude.md"
  "$(pwd)/Claude.md"
)

# Check directory prefixes
for DIR in "${PROTECTED_DIRS[@]}"; do
  REAL_DIR=$(realpath -m "$DIR" 2>/dev/null || echo "$DIR")
  if [[ "$REAL" == "$REAL_DIR" || "$REAL" == "$REAL_DIR/"* ]]; then
    echo "{\"decision\": \"block\", \"reason\": \"Protected path: agents may not edit '${FILE}'. The .claude/ directory is restricted to authorized users only.\"}"
    exit 2
  fi
done

# Check exact protected files
for PFILE in "${PROTECTED_FILES[@]}"; do
  REAL_PFILE=$(realpath -m "$PFILE" 2>/dev/null || echo "$PFILE")
  if [[ "$REAL" == "$REAL_PFILE" ]]; then
    echo "{\"decision\": \"block\", \"reason\": \"Protected file: agents may not edit '${FILE}'. This file is restricted to authorized users only.\"}"
    exit 2
  fi
done

exit 0
