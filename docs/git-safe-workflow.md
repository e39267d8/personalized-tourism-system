# Git 安全协作流程

本文档用于本项目 `personalized-tourism-system` 的日常协作：如何拉下别人修改的最新代码，以及如何把自己的修改安全上传到自己的分支。

## 1. 先确认自己在哪个目录

打开终端，进入项目根目录：

```bat
cd C:\Users\seele\Desktop\code\personalized-tourism-system
```

确认当前 Git 状态：

```bat
git status
```

重点看三件事：

- 当前分支名，例如 `main`、`feature/xxx`、`local-save-tourism`
- 有没有 `modified`、`untracked` 文件
- 有没有提示 `ahead` 或 `behind`

如果看到 `modified`，说明你有本地改动；如果看到 `untracked`，说明有新文件还没有加入 Git。

## 2. 拉取别人最新代码之前先保护自己的改动

拉代码前，不要直接 `git pull`。先看有没有本地改动：

```bat
git status
```

如果没有任何改动，可以直接进入第 3 步。

如果有本地改动，推荐先临时保存：

```bat
git stash push -m "before pull"
```

这个命令会把你当前没提交的改动临时收起来，避免拉取别人代码时发生冲突或覆盖。

注意：普通 `git stash push` 默认主要保存已经被 Git 跟踪过的文件，也就是 `modified` 文件。  
如果你有新建但还没有 `git add` 的文件，例如：

```txt
docs/day1-run-notes.md
docs/git-safe-workflow.md
```

这些属于 `untracked files`，普通 stash 可能不会保存它们。为了把新文件也一起临时保存，使用：

```bat
git stash push -u -m "before pull include new files"
```

这里的 `-u` 表示 include untracked files，也就是连新文件一起保存。  
如果你不确定有没有新文件，拉取代码前用这个更稳：

```bat
git status
git stash push -u -m "before pull"
```

查看保存记录：

```bat
git stash list
```

## 3. 拉下远程最新代码

先获取远程分支信息：

```bat
git fetch origin
```

查看当前分支和远程分支关系：

```bat
git branch -vv
```

如果你在自己的功能分支上，并且它已经跟踪远程分支，可以执行：

```bat
git pull --rebase
```

如果你想明确从某个远程分支更新，例如从 `origin/main` 更新：

```bat
git pull --rebase origin main
```

如果项目团队主要在 `feature/lxd-search` 分支上开发，可以执行：

```bat
git pull --rebase origin feature/lxd-search
```

说明：

- `git pull` 会把远程代码拉下来并合并
- `--rebase` 可以让你的本地提交排在别人最新提交之后，提交历史更干净
- 初学阶段尽量用 `git pull --rebase`，不要随便使用 `git reset --hard`

## 4. 恢复刚才临时保存的改动

如果第 2 步执行过 `git stash push`，拉完代码后恢复：

```bat
git stash pop
```

如果恢复时出现冲突，Git 会提示哪些文件冲突。冲突文件里通常会出现：

```txt
<<<<<<< Updated upstream
别人修改的内容
=======
你自己的内容
>>>>>>> Stashed changes
```

处理方法：

1. 打开冲突文件。
2. 保留最终想要的代码。
3. 删除 `<<<<<<<`、`=======`、`>>>>>>>` 这些标记。
4. 保存文件。
5. 执行：

```bat
git add 冲突文件路径
git rebase --continue
```

如果不是 rebase 阶段，只是 stash 冲突，解决后执行：

```bat
git add 冲突文件路径
git status
```

## 5. 开发前新建自己的分支

不要直接在 `main` 上写代码。建议每个任务新建一个分支。

例如要做推荐功能：

```bat
git switch -c feature/recommendation-improve
```

如果你的 Git 版本较旧，不支持 `git switch`，可以用：

```bat
git checkout -b feature/recommendation-improve
```

分支命名建议：

- `feature/xxx`：新功能
- `fix/xxx`：修 bug
- `docs/xxx`：文档修改
- `refactor/xxx`：代码整理

例如：

```txt
feature/personalized-recommendation
fix/search-duplicate-spots
docs/git-workflow
```

## 6. 修改代码后先自查

查看改了哪些文件：

```bat
git status
```

查看具体改动：

```bat
git diff
```

如果只想看某个文件：

```bat
git diff frontend/src/views/Home.vue
```

建议提交前至少运行一次项目，确认页面或后端没有明显报错。

前端常用：

```bat
cd frontend
npm run dev
```

后端按项目已有方式启动即可。

## 7. 安全提交自己的修改

把需要提交的文件加入暂存区：

```bat
git add 文件路径
```

例如：

```bat
git add frontend/src/views/Home.vue
git add backend/src/main.cpp
git add database/personalized_tags.sql
```

不建议初学者直接使用：

```bat
git add .
```

因为它可能把不该提交的临时文件、构建产物也加进去。

确认暂存内容：

```bat
git status
```

提交：

```bat
git commit -m "feat: improve personalized recommendation"
```

提交信息建议格式：

- `feat: xxx` 新功能
- `fix: xxx` 修复问题
- `docs: xxx` 文档
- `refactor: xxx` 代码整理
- `chore: xxx` 配置或杂项

## 8. 上传到自己的远程分支

第一次推送新分支：

```bat
git push -u origin 当前分支名
```

例如：

```bat
git push -u origin feature/recommendation-improve
```

以后这个分支再次上传，只需要：

```bat
git push
```

## 9. 如果远程也被别人更新了，push 被拒绝怎么办

如果执行 `git push` 时提示远程有新提交，先不要强推。

正确做法：

```bat
git pull --rebase
```

如果有冲突，按第 4 步解决。

解决后再推送：

```bat
git push
```

不要随便使用：

```bat
git push --force
```

除非你非常确定自己在做什么，并且已经和队友确认。

## 10. 推荐的日常完整流程

每天开始写代码前，如果你有未提交修改或新文件：

```bat
cd C:\Users\seele\Desktop\code\personalized-tourism-system
git status
git stash push -u -m "before pull"
git fetch origin
git pull --rebase
git stash pop
```

如果 `git status` 显示没有本地改动，可以跳过 `stash`：

```bat
cd C:\Users\seele\Desktop\code\personalized-tourism-system
git status
git fetch origin
git pull --rebase
```

写完代码后：

```bat
git status
git diff
git add 需要提交的文件
git commit -m "feat: describe your change"
git push
```

如果是新分支第一次上传：

```bat
git push -u origin 当前分支名
```

## 11. 本项目当前状态提醒

当前仓库远程地址是：

```txt
https://github.com/e39267d8/personalized-tourism-system.git
```

当前本地分支曾显示为：

```txt
local-save-tourism
```

并且它跟踪：

```txt
origin/feature/lxd-search
```

如果你不确定应该基于哪个远程分支开发，先问队友或老师。通常小组项目会约定一个主开发分支，例如：

```txt
main
feature/lxd-search
develop
```

确认后再执行：

```bat
git pull --rebase origin 分支名
```

## 12. 常见危险命令

初学阶段谨慎使用下面命令：

```bat
git reset --hard
git clean -fd
git push --force
git checkout -- 文件名
```

这些命令可能丢失本地修改。除非你明确知道后果，或者已经备份，否则不要执行。

## 13. 最安全的求助方式

如果 Git 提示你看不懂，先执行：

```bat
git status
```

然后把完整输出发给队友或 AI 助手。  
不要急着乱试命令，尤其不要在冲突时反复 `reset`。

