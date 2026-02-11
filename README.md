# 数据存储冷热分层 Shell 工程

这是一个纯 Shell 的“数据基础服务-数据存储冷热分层”参考实现，支持：

- 自定义冷热数据规则（按年龄、访问频次、数据量、业务标签等）
- 冷热数据标识与标记调整
- 针对冷热数据配置不同存储策略（如 HOT=HDFS-3副本、COLD=HDFS-EC）
- 动态创建与执行迁移任务
- 输出迁移完成信息（迁移量、耗时、策略、结果）并记录通知

> 工程重点是可扩展、可审计、可自动化执行，适合在没有复杂依赖的 Linux 环境快速落地。

## 快速开始

```bash
chmod +x bin/coldhotctl
./bin/coldhotctl init
./bin/coldhotctl rule add age_gt_30_days age ">" 30 cold
./bin/coldhotctl rule add access_lt_5 access "<" 5 cold
./bin/coldhotctl storage set hot HDFS_REPLICA_3
./bin/coldhotctl storage set cold HDFS_EC_6_3
./bin/coldhotctl task create task001 ./data/sample_data.csv
./bin/coldhotctl task run task001
./bin/coldhotctl report show task001
```

## 目录结构

- `bin/coldhotctl`：CLI 入口
- `lib/`：核心模块
- `etc/`：规则、策略、系统配置
- `var/tasks/`：任务定义与执行状态
- `logs/`：系统日志与通知日志
- `tests/`：基础测试脚本
- `docs/`：设计文档

## 规则格式

`etc/rules.conf` 每行一个规则（`|` 分隔）：

```text
rule_id|field|operator|threshold|target_tier|enabled
```

示例：

```text
age_gt_30_days|age|>|30|cold|1
access_lt_5|access|<|5|cold|1
```

支持字段：
- `age`（天数）
- `access`（访问次数）
- `size_mb`（数据大小 MB）
- `biz`（业务标签，配合 `=` 或 `!=`）

支持操作符：`> >= < <= = !=`

## 存储策略格式

`etc/storage_policies.conf`：

```text
tier|policy_name|description|enabled
hot|HDFS_REPLICA_3|HDFS三副本策略|1
cold|HDFS_EC_6_3|HDFS EC(6+3)策略|1
```

## 数据文件格式

CSV 文件头必须包含以下列：

```text
id,age,access,size_mb,biz,current_tier
```

执行迁移时会输出新文件：`<原文件>.migrated.csv`，并更新 `current_tier`。

## 设计目标

1. 规则可热更新，任务运行时动态读取。
2. 迁移可追踪（日志 + 报告 + 通知）。
3. 模块化设计，便于替换执行后端（如接入真实 HDFS 命令）。

## 测试

```bash
bash tests/test_core.sh
```

