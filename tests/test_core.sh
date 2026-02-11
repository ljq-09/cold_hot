#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CTL="$ROOT/bin/coldhotctl"

bash "$CTL" init
bash "$CTL" storage set hot HDFS_REPLICA_3 "热数据3副本"
bash "$CTL" storage set cold HDFS_EC_6_3 "冷数据EC"

TASK_ID="test_$(date +%s)"
bash "$CTL" task create "$TASK_ID" "$ROOT/data/sample_data.csv"
bash "$CTL" task run "$TASK_ID"

REPORT_CONTENT="$(bash "$CTL" report show "$TASK_ID")"
echo "$REPORT_CONTENT" | rg -q '^status=done$'
echo "$REPORT_CONTENT" | rg -q '^moved_rows='

echo "test_core PASS"
