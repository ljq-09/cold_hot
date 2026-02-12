#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=lib/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

RULE_FILE="$ETC_DIR/rules.conf"

rule_add() {
  local rule_id="$1" field="$2" op="$3" threshold="$4" target="$5"
  ensure_defaults

  if awk -F'|' -v id="$rule_id" '$1==id {found=1} END{exit !found}' "$RULE_FILE" 2>/dev/null; then
    die "规则已存在: $rule_id"
  fi

  echo "$rule_id|$field|$op|$threshold|$target|1" >> "$RULE_FILE"
  log "INFO" "新增规则: $rule_id"
}

rule_disable() {
  local rule_id="$1"
  ensure_defaults
  awk -F'|' -v OFS='|' -v id="$rule_id" '
    BEGIN{changed=0}
    /^#/ {print; next}
    $1==id {$6=0; changed=1}
    {print}
    END{if(!changed) exit 2}
  ' "$RULE_FILE" > "$RULE_FILE.tmp" || {
    rm -f "$RULE_FILE.tmp"
    die "规则不存在: $rule_id"
  }
  mv "$RULE_FILE.tmp" "$RULE_FILE"
  log "INFO" "禁用规则: $rule_id"
}

rule_enable() {
  local rule_id="$1"
  ensure_defaults
  awk -F'|' -v OFS='|' -v id="$rule_id" '
    BEGIN{changed=0}
    /^#/ {print; next}
    $1==id {$6=1; changed=1}
    {print}
    END{if(!changed) exit 2}
  ' "$RULE_FILE" > "$RULE_FILE.tmp" || {
    rm -f "$RULE_FILE.tmp"
    die "规则不存在: $rule_id"
  }
  mv "$RULE_FILE.tmp" "$RULE_FILE"
  log "INFO" "启用规则: $rule_id"
}

rule_list() {
  ensure_defaults
  cat "$RULE_FILE"
}

rule_remove() {
  local rule_id="$1"
  ensure_defaults
  awk -F'|' -v OFS='|' -v id="$rule_id" '
    BEGIN{removed=0}
    /^#/ {print; next}
    $1==id {removed=1; next}
    {print}
    END{if(!removed) exit 2}
  ' "$RULE_FILE" > "$RULE_FILE.tmp" || {
    rm -f "$RULE_FILE.tmp"
    die "规则不存在: $rule_id"
  }
  mv "$RULE_FILE.tmp" "$RULE_FILE"
  log "INFO" "删除规则: $rule_id"
}

# 输入: age access size biz
# 输出: hot|cold（首次命中即返回）
rule_eval_tier() {
  local age="$1" access="$2" size_mb="$3" biz="$4"
  ensure_defaults

  awk -F'|' -v age="$age" -v access="$access" -v size_mb="$size_mb" -v biz="$biz" '
    function compare(v, op, t) {
      if (op==">") return (v+0) > (t+0)
      if (op==">=") return (v+0) >= (t+0)
      if (op=="<") return (v+0) < (t+0)
      if (op=="<=") return (v+0) <= (t+0)
      if (op=="=") return (v "" == t "")
      if (op=="!=") return (v "" != t "")
      return 0
    }
    BEGIN{tier="hot"}
    /^#/ {next}
    NF<6 {next}
    {
      id=$1; field=$2; op=$3; th=$4; target=$5; enabled=$6
      if (enabled != 1) next
      if (field=="age" && compare(age, op, th)) {tier=target; print tier; exit}
      if (field=="access" && compare(access, op, th)) {tier=target; print tier; exit}
      if (field=="size_mb" && compare(size_mb, op, th)) {tier=target; print tier; exit}
      if (field=="biz" && compare(biz, op, th)) {tier=target; print tier; exit}
    }
    END{if (NR==0 || tier=="hot") print tier}
  ' "$RULE_FILE" | head -n1
}
