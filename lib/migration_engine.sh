#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=lib/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"
# shellcheck source=lib/rule_engine.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/rule_engine.sh"
# shellcheck source=lib/storage_engine.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/storage_engine.sh"
# shellcheck source=lib/notifier.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/notifier.sh"

create_task() {
  local task_id="$1" data_file="$2"
  require_file "$data_file"

  local task_file="$TASK_DIR/${task_id}.task"
  if [[ -f "$task_file" ]]; then
    die "任务已存在: $task_id"
  fi

  cat > "$task_file" <<TASK
id=$task_id
data_file=$data_file
status=created
created_at=$(date '+%FT%T')
TASK

  log "INFO" "创建任务: $task_id data_file=$data_file"
}

list_tasks() {
  local f
  for f in "$TASK_DIR"/*.task; do
    [[ -e "$f" ]] || continue
    echo "--- $(basename "$f") ---"
    cat "$f"
  done
}

run_task() {
  local task_id="$1"
  local task_file="$TASK_DIR/${task_id}.task"
  require_file "$task_file"

  # shellcheck disable=SC1090
  source "$task_file"

  [[ -n "${data_file:-}" ]] || die "任务配置缺少 data_file"
  require_file "$data_file"

  local start end duration
  start="$(now_epoch)"

  local out_file="${data_file%.csv}.migrated.csv"
  local report_file="$TASK_DIR/${task_id}.report"

  local hot_policy cold_policy
  hot_policy="$(storage_get_policy hot)"
  cold_policy="$(storage_get_policy cold)"
  [[ -n "$hot_policy" ]] || hot_policy="UNSET"
  [[ -n "$cold_policy" ]] || cold_policy="UNSET"

  local moved=0 total=0

  {
    IFS= read -r header || die "空数据文件: $data_file"
    echo "$header"

    while IFS=',' read -r id age access size_mb biz current_tier rest; do
      total=$((total+1))
      local target_tier
      target_tier="$(rule_eval_tier "$age" "$access" "$size_mb" "$biz")"
      if [[ "$target_tier" != "$current_tier" ]]; then
        moved=$((moved+1))
      fi
      echo "$id,$age,$access,$size_mb,$biz,$target_tier"
    done
  } < "$data_file" > "$out_file"

  end="$(now_epoch)"
  duration="$(duration_human "$start" "$end")"

  cat > "$report_file" <<REPORT
id=$task_id
source=$data_file
output=$out_file
total_rows=$total
moved_rows=$moved
started_epoch=$start
ended_epoch=$end
duration=$duration
hot_policy=$hot_policy
cold_policy=$cold_policy
status=done
REPORT

  awk -F= -v OFS='=' '
    $1=="status" {$2="done"}
    $1=="finished_at" {$2=strftime("%Y-%m-%dT%H:%M:%S")}
    {print}
  ' "$task_file" > "$task_file.tmp" || true

  if ! awk -F= '$1=="finished_at" {found=1} END{exit !found}' "$task_file.tmp" 2>/dev/null; then
    echo "finished_at=$(date '+%FT%T')" >> "$task_file.tmp"
  fi
  mv "$task_file.tmp" "$task_file"

  notify_task_done "$task_id" "$moved" "$duration" "$hot_policy" "$cold_policy"
  log "INFO" "任务执行完成: $task_id moved=$moved total=$total"
}

show_report() {
  local task_id="$1"
  local report_file="$TASK_DIR/${task_id}.report"
  require_file "$report_file"
  cat "$report_file"
}
