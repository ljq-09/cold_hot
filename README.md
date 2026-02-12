# 分支合并说明

当前需要处理的功能分支是：

- `codex/add-customizable-hot/cold-data-rules`

建议合并流程：

```bash
# 1) 拉取远端最新
git fetch origin

# 2) 切到 main 并更新
git checkout main
git pull origin main

# 3) 合并目标分支
git merge --no-ff origin/codex/add-customizable-hot/cold-data-rules

# 4) 解决冲突并提交（如有）
# git add <resolved_files>
# git commit

# 5) 推送 main
git push origin main
```

如果你更偏好通过 PR 合并，请创建：

- base: `main`
- compare: `codex/add-customizable-hot/cold-data-rules`

