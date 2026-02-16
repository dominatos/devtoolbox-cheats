Title: 🧬 Git — Advanced Techniques
Group: Dev & Tools
Icon: 🧬
Order: 2

## Table of Contents
- [Worktrees](#-worktrees--рабочие-деревья)
- [Bisect](#-bisect--бинарный-поиск)
- [Reflog](#-reflog--журнал-ссылок)
- [Submodules](#-submodules--подмодули)
- [Cherry Pick & Rebase](#-cherry-pick--rebase)
- [Stash](#-stash--откладывание)
- [Hooks](#-hooks--хуки)
- [Advanced Techniques](#-advanced-techniques--продвинутые-техники)

---

# 🌳 Worktrees / Рабочие деревья

### Create Worktree / Создать worktree
git worktree add ../feature feature-branch    # Create worktree for branch / Создать worktree для ветки
git worktree add -b new-feature ../feature    # Create new branch and worktree / Создать новую ветку и worktree
git worktree add --detach ../temp <COMMIT>    # Detached HEAD worktree / Worktree с отсоединённым HEAD

### List & Remove / Список и удаление
git worktree list                             # List all worktrees / Список всех worktrees
git worktree remove ../feature                # Remove worktree / Удалить worktree
git worktree prune                            # Clean up stale worktrees / Очистить устаревшие worktrees

---

# 🔍 Bisect / Бинарный поиск

### Basic Bisect / Базовый bisect
git bisect start                              # Start bisect / Начать bisect
git bisect bad                                # Mark current as bad / Отметить текущий как плохой
git bisect good <COMMIT>                      # Mark commit as good / Отметить коммит как хороший
git bisect reset                              # End bisect / Закончить bisect

### Automated Bisect / Автоматический bisect
git bisect start HEAD v1.0                    # Start with range / Начать с диапазоном
git bisect run ./test.sh                      # Automate with script / Автоматизировать со скриптом
git bisect skip                               # Skip current commit / Пропустить текущий коммит

---

# 📜 Reflog / Журнал ссылок

### View Reflog / Просмотр reflog
git reflog                                    # Show reflog / Показать reflog
git reflog show HEAD                          # Show HEAD reflog / Показать reflog HEAD
git reflog show main                          # Show branch reflog / Показать reflog ветки

### Restore from Reflog / Восстановление из reflog
git reset --hard HEAD@{1}                     # Restore to previous HEAD / Восстановить к предыдущему HEAD
git reset --hard HEAD@{2.hours.ago}           # Restore to 2 hours ago / Восстановить к 2 часам назад
git reflog expire --expire=now --all         # Clear reflog / Очистить reflog

---

# 📦 Submodules / Подмодули

### Add Submodule / Добавить подмодуль
git submodule add <REPO_URL> path/to/submodule  # Add submodule / Добавить подмодуль
git submodule add -b branch <REPO_URL> path   # Add specific branch / Добавить конкретную ветку

### Update Submodules / Обновить подмодули
git submodule update --init --recursive       # Initialize submodules / Инициализировать подмодули
git submodule update --remote                 # Update to latest / Обновить до последних
git submodule foreach git pull origin main    # Pull all submodules / Подтянуть все подмодули

### Remove Submodule / Удалить подмодуль
git submodule deinit path/to/submodule        # Deinitialize submodule / Деинициализировать подмодуль
git rm path/to/submodule                      # Remove submodule / Удалить подмодуль
rm -rf .git/modules/path/to/submodule         # Clean up git directory / Очистить git директорию

---

# 🍒 Cherry Pick & Rebase

### Cherry Pick / Выбор коммитов
git cherry-pick <COMMIT>                      # Apply commit / Применить коммит
git cherry-pick <COMMIT1> <COMMIT2>           # Apply multiple / Применить несколько
git cherry-pick <COMMIT1>..<COMMIT2>          # Apply range / Применить диапазон
git cherry-pick --continue                    # Continue after conflict / Продолжить после конфликта
git cherry-pick --abort                       # Abort cherry-pick / Отменить cherry-pick

### Interactive Rebase / Интерактивный rebase
git rebase -i HEAD~3                          # Rebase last 3 commits / Rebase последних 3 коммитов
git rebase -i main                            # Rebase onto main / Rebase на main
git rebase --continue                         # Continue after resolving / Продолжить после разрешения
git rebase --abort                            # Abort rebase / Отменить rebase
git rebase --skip                             # Skip current commit / Пропустить текущий коммит

### Rebase Options / Опции rebase
git rebase -i --autosquash HEAD~5             # Auto-squash fixup commits / Автослияние fixup коммитов
git rebase --onto main feature~3 feature      # Advanced rebase / Продвинутый rebase

---

# 💾 Stash / Откладывание

### Basic Stash / Базовый stash
git stash                                     # Stash changes / Отложить изменения
git stash push -m "description"               # Stash with message / Отложить с сообщением
git stash -u                                  # Include untracked files / Включить неотслеживаемые файлы
git stash -a                                  # Include all (ignored too) / Включить все

### List & Apply / Список и применение
git stash list                                # List stashes / Список stash
git stash show                                # Show latest stash / Показать последний stash
git stash show -p stash@{1}                   # Show specific stash diff / Показать diff конкретного stash
git stash apply                               # Apply latest stash / Применить последний stash
git stash apply stash@{2}                     # Apply specific stash / Применить конкретный stash
git stash pop                                 # Apply and remove stash / Применить и удалить stash

### Manage Stashes / Управление stash
git stash drop stash@{1}                      # Remove specific stash / Удалить конкретный stash
git stash clear                               # Remove all stashes / Удалить все stash
git stash branch new-branch stash@{0}         # Create branch from stash / Создать ветку из stash

---

# 🪝 Hooks / Хуки

### Git Hooks Location / Расположение хуков
.git/hooks/                                   # Hooks directory / Директория хуков
.git/hooks/pre-commit                         # Pre-commit hook / Хук перед коммитом
.git/hooks/pre-push                           # Pre-push hook / Хук перед push
.git/hooks/commit-msg                         # Commit message hook / Хук сообщения коммита

### Sample Pre-Commit Hook / Пример хука pre-commit
```bash
#!/bin/bash
# Run tests before commit / Запустить тесты перед коммитом
npm test || exit 1
```

### Enable Hooks / Включить хуки
chmod +x .git/hooks/pre-commit                # Make executable / Сделать исполняемым
git config core.hooksPath custom-hooks/       # Custom hooks path / Пользовательский путь хуков

---

# 🔬 Advanced Techniques / Продвинутые техники

### Filter-Branch / Фильтр-ветка
git filter-branch --tree-filter 'rm -f passwords.txt' HEAD  # Remove file from history / Удалить файл из истории
git filter-branch --env-filter 'export GIT_AUTHOR_NAME="<NAME>"' HEAD  # Rewrite author / Переписать автора

### BFG Repo-Cleaner / BFG очистка репозитория
bfg --delete-files passwords.txt              # Remove file / Удалить файл
bfg --strip-blobs-bigger-than 10M             # Remove large files / Удалить большие файлы

### Find Large Files / Найти большие файлы
git rev-list --objects --all | git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' | awk '/^blob/ {print substr($0,6)}' | sort -n -k 2 | tail -10

### Blame & Log / Обвинение и лог
git blame file.txt                            # Show who changed each line / Показать кто изменил каждую строку
git blame -L 10,20 file.txt                   # Blame specific lines / Обвинить конкретные строки
git log --follow file.txt                     # Follow file renames / Следовать за переименованиями
git log -p -S "function"                      # Search for code changes / Искать изменения кода
git log --graph --oneline --all               # Visual graph / Визуальный график

### Diff Advanced / Продвинутый diff
git diff HEAD~3..HEAD                         # Diff range / Diff диапазона
git diff --stat                               # Show statistics / Показать статистику
git diff --word-diff                          # Word-level diff / Diff на уровне слов
git diff main...feature                       # Three-dot diff / Трёхточечный diff

### Archive / Архив
git archive --format=zip --output=repo.zip HEAD  # Create ZIP archive / Создать ZIP архив
git archive --format=tar HEAD | gzip > repo.tar.gz  # Create tar.gz / Создать tar.gz

### Sparse Checkout / Частичная выборка
git sparse-checkout init                      # Initialize sparse checkout / Инициализировать sparse checkout
git sparse-checkout set dir1 dir2             # Checkout specific directories / Выборка конкретных директорий

### Maintenance / Обслуживание
git gc                                        # Garbage collection / Сборка мусора
git gc --aggressive                           # Aggressive GC / Агрессивная сборка мусора
git fsck                                      # Check integrity / Проверить целостность
git prune                                     # Prune unreachable objects / Очистить недостижимые объекты

---

# 🌟 Real-World Examples / Примеры из практики

### Fix Commit Message / Исправить сообщение коммита
```bash
git commit --amend -m "New message"           # Amend last commit message / Изменить последнее сообщение
git rebase -i HEAD~3                          # Reword older commit / Переписать старый коммит
```

### Undo Last Commit / Отменить последний коммит
```bash
git reset --soft HEAD~1                       # Keep changes staged / Оставить изменения staged
git reset --mixed HEAD~1                      # Keep changes unstaged / Оставить изменения unstaged
git reset --hard HEAD~1                       # Discard changes / Отбросить изменения
```

### Squash Commits / Слить коммиты
```bash
git rebase -i HEAD~3                          # Interactive rebase / Интерактивный rebase
# Change 'pick' to 'squash' for commits to squash / Изменить 'pick' на 'squash'
```

### Split Commit / Разделить коммит
```bash
git rebase -i HEAD~3
# Mark commit for 'edit'
git reset HEAD~
git add file1.txt && git commit -m "Part 1"
git add file2.txt && git commit -m "Part 2"
git rebase --continue
```

### Emergency Recovery / Экстренное восстановление
```bash
git reflog                                    # Find lost commit / Найти потерянный коммит
git reset --hard <COMMIT>                     # Restore / Восстановить
```

# 💡 Best Practices / Лучшие практики
# Use worktrees for parallel work / Используйте worktrees для параллельной работы
# Bisect to find bugs quickly / Используйте bisect для быстрого поиска багов
# Reflog saves you from mistakes / Reflog спасает от ошибок
# Interactive rebase for clean history / Интерактивный rebase для чистой истории
# Stash before switching branches / Используйте stash перед переключением веток
# Never rebase published history / Никогда не делайте rebase опубликованной истории

# 🔧 Useful Aliases / Полезные алиасы
git config --global alias.lg "log --graph --oneline --all"
git config --global alias.st "status -sb"
git config --global alias.co "checkout"
git config --global alias.br "branch"
git config --global alias.unstage "reset HEAD --"
