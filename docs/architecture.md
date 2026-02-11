# 冷热分层架构说明

## 目标

- 提供规则驱动的数据冷热识别
- 提供可配置存储策略映射
- 提供可观测的迁移任务编排与报告

## 关键模块

1. `rule_engine.sh`
2. `storage_engine.sh`
3. `migration_engine.sh`
4. `notifier.sh`

## 扩展建议

- 将 `run_task` 里 CSV 改写替换为实际 HDFS DistCp / Spark 作业调用
- 将通知模块接入企业 IM/邮件/Webhook
- 增加规则优先级字段、规则分组及布尔表达式
