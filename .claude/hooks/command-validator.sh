#!/bin/bash
# command-validator.sh — PreToolUse hook
# Blocks destructive infra commands, SQL injection, recursive deletions, and pipe-to-shell attacks.

INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Nothing to validate
if [ -z "$CMD" ]; then
  exit 2
fi

# ──────────────────────────────────────────────
# 1. DESTRUCTIVE INFRASTRUCTURE COMMANDS
# ──────────────────────────────────────────────
# Catches: terraform destroy, terraform apply -auto-approve, aws s3 rm/rb
if echo "$CMD" | grep -qE \
  'terraform[[:space:]]+destroy|terraform[[:space:]]+apply.*-auto-approve|aws[[:space:]]+s3[[:space:]]+rm|aws[[:space:]]+s3[[:space:]]+rb'; then
  echo '{"decision": "block", "reason": "Destructive infrastructure command detected (terraform destroy / apply --auto-approve / s3 rm). Operation blocked."}'
  exit 2
fi

# ──────────────────────────────────────────────
# 2. RECURSIVE / FORCED DELETION
# ──────────────────────────────────────────────
# Catches: rm -rf, rm -fr, rm -Rf, find … -delete, find … -exec rm
if echo "$CMD" | grep -qE \
  'rm[[:space:]]+-[a-zA-Z]*[rR][a-zA-Z]*[fF]|rm[[:space:]]+-[a-zA-Z]*[fF][a-zA-Z]*[rR]|find[[:space:]].*-delete[[:space:]]|find[[:space:]].*-exec[[:space:]]+rm'; then
  echo '{"decision": "block", "reason": "Recursive/forced deletion detected (rm -rf, find -delete, find -exec rm …). Operation blocked."}'
  exit 2
fi

# ──────────────────────────────────────────────
# 3. PIPE-TO-SHELL ATTACKS
# ──────────────────────────────────────────────
# Pattern A — classic: curl URL | bash, wget … | sh
if echo "$CMD" | grep -qE \
  '(curl|wget|fetch)[[:space:]].*\|[[:space:]]*(bash|sh|zsh|dash|fish|python3?|ruby|perl|node)'; then
  echo '{"decision": "block", "reason": "Pipe-to-shell attack detected (e.g. curl URL | bash). Operation blocked."}'
  exit 2
fi

# Pattern B — process substitution: bash <(curl …), sh <(wget …)
if echo "$CMD" | grep -qE \
  '(bash|sh|zsh|dash)[[:space:]]+<[[:space:]]*\([[:space:]]*(curl|wget)'; then
  echo '{"decision": "block", "reason": "Process-substitution shell execution detected (e.g. bash <(curl …)). Operation blocked."}'
  exit 2
fi

# Pattern C — eval of downloaded content: eval $(curl …), eval "$(wget …)"
if echo "$CMD" | grep -qE \
  'eval[[:space:]]+(\$\(|`)(curl|wget)'; then
  echo '{"decision": "block", "reason": "eval of remote content detected (e.g. eval \$(curl …)). Operation blocked."}'
  exit 2
fi

# Pattern D — explicit download-then-execute chain: curl -o /tmp/x … && bash /tmp/x
if echo "$CMD" | grep -qE \
  '(curl|wget)[[:space:]].*-[oO][[:space:]].*&&.*(bash|sh|zsh|python3?)'; then
  echo '{"decision": "block", "reason": "Download-and-execute chain detected. Operation blocked."}'
  exit 2
fi

# ──────────────────────────────────────────────
# 4. SQL INJECTION
# ──────────────────────────────────────────────
# Targets commands that pipe user-controlled data into a DB client
# (mysql, psql, sqlite3, sqlcmd) or embed inline SQL with injection markers.

# Pattern A — stacked query injection: '; DROP TABLE …, "; DELETE FROM …
if echo "$CMD" | grep -iqE \
  "['\"][[:space:]]*;[[:space:]]*(DROP|DELETE|TRUNCATE|ALTER|INSERT|UPDATE|CREATE|EXEC(UTE)?)[[:space:]]+(TABLE|DATABASE|SCHEMA|INTO|FROM)"; then
  echo '{"decision": "block", "reason": "SQL stacked-query injection pattern detected. Operation blocked."}'
  exit 2
fi

# Pattern B — UNION-based injection
if echo "$CMD" | grep -iqE \
  'UNION[[:space:]]+(ALL[[:space:]]+)?SELECT'; then
  echo '{"decision": "block", "reason": "SQL UNION SELECT injection pattern detected. Operation blocked."}'
  exit 2
fi

# Pattern C — dangerous SQL built-ins often used in injection payloads
if echo "$CMD" | grep -iqE \
  'xp_cmdshell|INTO[[:space:]]+OUTFILE[[:space:]]|LOAD_FILE[[:space:]]*\('; then
  echo '{"decision": "block", "reason": "Dangerous SQL built-in (xp_cmdshell / INTO OUTFILE / LOAD_FILE) detected. Operation blocked."}'
  exit 2
fi

# Pattern D — tautology-based injection: ' OR '1'='1, ' OR 1=1--
if echo "$CMD" | grep -iqE \
  "['][[:space:]]*(OR|AND)[[:space:]]+'?1'?[[:space:]]*=[[:space:]]*'?1'?|['][[:space:]]*(OR|AND)[[:space:]]+1[[:space:]]*=[[:space:]]*1[[:space:]]*--"; then
  echo '{"decision": "block", "reason": "SQL tautology injection pattern detected (OR 1=1). Operation blocked."}'
  exit 2
fi

exit 0
