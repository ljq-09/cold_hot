#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ETC_DIR="$PROJECT_ROOT/etc"
VAR_DIR="$PROJECT_ROOT/var"
LOG_DIR="$PROJECT_ROOT/logs"
TASK_DIR="$VAR_DIR/tasks"

mkdir -p "$ETC_DIR" "$VAR_DIR" "$LOG_DIR" "$TASK_DIR"

log() {
  local level="$1"; shift
  local ts
  ts="$(date '+%Y-%m-%d %H:%M:%S')"
  echo "[$ts][$level] $*" | tee -a "$LOG_DIR/system.log" >/dev/null
}

die() {
  log "ERROR" "$*"
  echo "ERROR: $*" >&2
  exit 1
}

require_file() {
  local f="$1"
  [[ -f "$f" ]] || die "文件不存在: $f"
}

ensure_defaults() {
  local rules="$ETC_DIR/rules.conf"
  local policies="$ETC_DIR/storage_policies.conf"

  if [[ ! -f "$rules" ]]; then
    cat > "$rules" <<'RULES'
# rule_id|field|operator|threshold|target_tier|enabled
age_gt_30_days|age|>|30|cold|1
access_lt_5|access|<|5|cold|1
RULES
  fi

  if [[ ! -f "$policies" ]]; then
    cat > "$policies" <<'POLICIES'
# tier|policy_name|description|enabled
hot|HDFS_REPLICA_3|HDFS三副本策略|1
cold|HDFS_EC_6_3|HDFS EC(6+3)策略|1
POLICIES
  fi
}

now_epoch() {
  date +%s
}

duration_human() {
  local start="$1"
  local end="$2"
  local sec=$(( end - start ))
  printf '%02dh:%02dm:%02ds' $((sec/3600)) $(((sec%3600)/60)) $((sec%60))
}
