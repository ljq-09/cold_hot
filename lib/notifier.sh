#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=lib/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

NOTIFY_LOG="$LOG_DIR/notify.log"

notify_task_done() {
  local task_id="$1" moved_rows="$2" duration="$3" hot_policy="$4" cold_policy="$5"
  local msg="任务[$task_id] 完成; 迁移行数=$moved_rows; 耗时=$duration; hot_policy=$hot_policy; cold_policy=$cold_policy"
  echo "$(date '+%F %T')|$msg" >> "$NOTIFY_LOG"
  log "INFO" "$msg"
}
