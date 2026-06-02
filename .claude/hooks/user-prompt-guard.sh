#!/bin/bash
# SAY hook — catches destructive intent in user prompts

INPUT=$(cat)
PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty')

if echo "$PROMPT" | grep -iqE "delete all|destroy everything|remove all resources|wipe|nuke|drop all|delete *"; then
  echo '{"decision": "block", "reason": "Destructive intent detected. Please use /tf-destroy for controlled infrastructure teardown."}'
fi

# ──────────────────────────────────────────────
# 1. DESTRUCTIVE INFRASTRUCTURE COMMANDS
# ──────────────────────────────────────────────
# Catches: terraform destroy, terraform apply -auto-approve, aws s3 rm/rb
if echo "$PROMPT" | grep -qE \
  'terraform[[:space:]]+destroy|terraform[[:space:]]+apply.*-auto-approve|aws[[:space:]]+s3[[:space:]]+rm|aws[[:space:]]+s3[[:space:]]+rb'; then
  echo '{"decision": "block", "reason": "Destructive infrastructure command detected in prompt (terraform destroy / apply --auto-approve / s3 rm). Operation blocked."}'
  exit 2
fi

# ──────────────────────────────────────────────
# 2. RECURSIVE / FORCED DELETION
# ──────────────────────────────────────────────
# Catches: rm -rf, rm -fr, rm -Rf, find … -delete, find … -exec rm
if echo "$PROMPT" | grep -qE \
  'rm[[:space:]]+-[a-zA-Z]*[rR][a-zA-Z]*[fF]|rm[[:space:]]+-[a-zA-Z]*[fF][a-zA-Z]*[rR]|find[[:space:]].*-delete[[:space:]]|find[[:space:]].*-exec[[:space:]]+rm'; then
  echo '{"decision": "block", "reason": "Recursive/forced deletion detected in prompt (rm -rf, find -delete, find -exec rm …). Operation blocked."}'
  exit 2
fi

# ──────────────────────────────────────────────
# 3. PIPE-TO-SHELL ATTACKS
# ──────────────────────────────────────────────

# Pattern A — classic: curl URL | bash, wget … | sh
if echo "$PROMPT" | grep -qE \
  '(curl|wget|fetch)[[:space:]].*\|[[:space:]]*(bash|sh|zsh|dash|fish|python3?|ruby|perl|node)'; then
  echo '{"decision": "block", "reason": "Pipe-to-shell attack detected in prompt (e.g. curl URL | bash). Operation blocked."}'
  exit 2
fi

# Pattern B — process substitution: bash <(curl …), sh <(wget …)
if echo "$PROMPT" | grep -qE \
  '(bash|sh|zsh|dash)[[:space:]]+<[[:space:]]*\([[:space:]]*(curl|wget)'; then
  echo '{"decision": "block", "reason": "Process-substitution shell execution detected in prompt (e.g. bash <(curl …)). Operation blocked."}'
  exit 2
fi

# Pattern C — eval of downloaded content: eval $(curl …), eval "$(wget …)"
if echo "$PROMPT" | grep -qE \
  'eval[[:space:]]+(\$\(|`)(curl|wget)'; then
  echo '{"decision": "block", "reason": "eval of remote content detected in prompt (e.g. eval \$(curl …)). Operation blocked."}'
  exit 2
fi

# Pattern D — explicit download-then-execute chain: curl -o /tmp/x … && bash /tmp/x
if echo "$PROMPT" | grep -qE \
  '(curl|wget)[[:space:]].*-[oO][[:space:]].*&&.*(bash|sh|zsh|python3?)'; then
  echo '{"decision": "block", "reason": "Download-and-execute chain detected in prompt. Operation blocked."}'
  exit 2
fi

# ──────────────────────────────────────────────
# 4. SQL INJECTION
# ──────────────────────────────────────────────

# Pattern A — stacked query injection: '; DROP TABLE …, "; DELETE FROM …
if echo "$PROMPT" | grep -iqE \
  "['\"][[:space:]]*;[[:space:]]*(DROP|DELETE|TRUNCATE|ALTER|INSERT|UPDATE|CREATE|EXEC(UTE)?)[[:space:]]+(TABLE|DATABASE|SCHEMA|INTO|FROM)"; then
  echo '{"decision": "block", "reason": "SQL stacked-query injection pattern detected in prompt. Operation blocked."}'
  exit 2
fi

# Pattern B — UNION-based injection
if echo "$PROMPT" | grep -iqE \
  'UNION[[:space:]]+(ALL[[:space:]]+)?SELECT'; then
  echo '{"decision": "block", "reason": "SQL UNION SELECT injection pattern detected in prompt. Operation blocked."}'
  exit 2
fi

# Pattern C — dangerous SQL built-ins often used in injection payloads
if echo "$PROMPT" | grep -iqE \
  'xp_cmdshell|INTO[[:space:]]+OUTFILE[[:space:]]|LOAD_FILE[[:space:]]*\('; then
  echo '{"decision": "block", "reason": "Dangerous SQL built-in detected in prompt (xp_cmdshell / INTO OUTFILE / LOAD_FILE). Operation blocked."}'
  exit 2
fi

# Pattern D — tautology-based injection: ' OR '1'='1, ' OR 1=1--
if echo "$PROMPT" | grep -iqE \
  "['][[:space:]]*(OR|AND)[[:space:]]+'?1'?[[:space:]]*=[[:space:]]*'?1'?|['][[:space:]]*(OR|AND)[[:space:]]+1[[:space:]]*=[[:space:]]*1[[:space:]]*--"; then
  echo '{"decision": "block", "reason": "SQL tautology injection pattern detected in prompt (OR 1=1). Operation blocked."}'
  exit 2
fi