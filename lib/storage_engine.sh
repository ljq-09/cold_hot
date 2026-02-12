#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=lib/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

POLICY_FILE="$ETC_DIR/storage_policies.conf"

storage_set() {
  local tier="$1" policy="$2" desc="${3:-自动配置}"
  ensure_defaults

  if awk -F'|' -v t="$tier" '$1==t {found=1} END{exit !found}' "$POLICY_FILE" 2>/dev/null; then
    awk -F'|' -v OFS='|' -v t="$tier" -v p="$policy" -v d="$desc" '
      /^#/ {print; next}
      $1==t {$2=p; $3=d; $4=1}
      {print}
    ' "$POLICY_FILE" > "$POLICY_FILE.tmp"
    mv "$POLICY_FILE.tmp" "$POLICY_FILE"
  else
    echo "$tier|$policy|$desc|1" >> "$POLICY_FILE"
  fi

  log "INFO" "存储策略设置完成: tier=$tier policy=$policy"
}

storage_list() {
  ensure_defaults
  cat "$POLICY_FILE"
}

storage_get_policy() {
  local tier="$1"
  ensure_defaults
  awk -F'|' -v t="$tier" '
    /^#/ {next}
    $1==t && $4==1 {print $2; exit}
  ' "$POLICY_FILE"
}
