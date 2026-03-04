Title: 🧬 Git — Basics
Group: Dev & Tools
Icon: 🧬
Order: 1

## Table of Contents
- [Setup & Initialization](#-setup--initialization--настройка-и-инициализация)
- [Basic Workflow](#-basic-workflow--базовый-рабочий-процесс)
- [Branching & Merging](#-branching--merging--ветки-и-слияние)
- [Remote Operations](#-remote-operations--удалённые-операции)
- [Stashing](#-stashing--временное-сохранение)
- [History & Logs](#-history--logs--история-и-логи)
- [Undoing Changes](#-undoing-changes--отмена-изменений)
- [Tags](#-tags--теги)
- [Real-World Examples](#-real-world-examples--примеры-из-практики)
- [Tips & Best Practices](#-tips--best-practices--советы-и-лучшие-практики)

---

# 🛠️ Setup & Initialization / Настройка и инициализация

### Configuration / Конфигурация
```bash
git config --global user.name "Your Name"      # Set name / Установить имя
git config --global user.email "you@example.com"  # Set email / Установить email
git config --global init.defaultBranch main    # Default branch name / Название ветки по умолчанию
git config --global core.editor vim            # Set default editor / Установить редактор
git config --global pull.rebase true           # Rebase on pull / Rebase при pull
git config --list                              # Show all config / Показать всю конфигурацию
git config --global --edit                     # Edit config file / Редактировать конфигурацию
```

### Initialize Repository / Инициализация репозитория
```bash
git init                                       # Init new repo / Инициализировать новый репозиторий
git init --bare                                # Init bare repo / Инициализировать bare репозиторий
git clone <URL>                                # Clone repo / Клонировать репо
git clone --depth 1 <URL>                      # Shallow clone / Поверхностное клонирование
git clone --branch <BRANCH> <URL>              # Clone specific branch / Клонировать конкретную ветку
```

---

# 📝 Basic Workflow / Базовый рабочий процесс

### Status & Staging / Статус и индексация
```bash
git status                                     # Show status / Показать статус
git status -s                                  # Short status / Короткий статус
git add .                                      # Stage all changes / Индексировать все изменения
git add file.txt                               # Stage specific file / Индексировать конкретный файл
git add -p                                     # Interactive staging / Интерактивная индексация
git add -u                                     # Stage modified/deleted / Индексировать изменённые/удалённые
git reset file.txt                             # Unstage file / Убрать из индекса
```

### Commit / Коммит
```bash
git commit -m "message"                        # Commit with message / Коммит с сообщением
git commit -am "message"                       # Add and commit / Индексировать и закоммитить
git commit --amend                             # Amend last commit / Изменить последний коммит
git commit --amend --no-edit                   # Amend without editing message / Изменить без редактирования сообщения
git commit --allow-empty -m "trigger CI"       # Empty commit / Пустой коммит
```

### Differences / Различия
```bash
git diff                                       # Show unstaged changes / Показать неиндексированные изменения
git diff --staged                              # Show staged changes / Показать индексированные изменения
git diff HEAD                                  # Show all changes / Показать все изменения
git diff branch1 branch2                       # Compare branches / Сравнить ветки
git diff <COMMIT1> <COMMIT2>                   # Compare commits / Сравнить коммиты
```

---

# 🌿 Branching & Merging / Ветки и слияние

### Branches / Ветки
```bash
git branch                                     # List local branches / Список локальных веток
git branch -a                                  # List all branches / Список всех веток
git branch feature/new                         # Create branch / Создать ветку
git checkout feature/new                       # Switch branch / Переключить ветку
git checkout -b feature/new                    # Create and switch / Создать и переключить
git switch feature/new                         # Modern switch / Современное переключение
git switch -c feature/new                      # Create and switch (modern) / Создать и переключить (современно)
git branch -d feature/old                      # Delete merged branch / Удалить слитую ветку
git branch -D feature/old                      # Force delete branch / Принудительно удалить ветку
git branch -m old-name new-name                # Rename branch / Переименовать ветку
```

### Merging / Слияние
```bash
git merge feature/new                          # Merge branch / Слить ветку
git merge --no-ff feature/new                  # No fast-forward merge / Слияние без fast-forward
git merge --squash feature/new                 # Squash merge / Слияние с объединением коммитов
git merge --abort                              # Abort merge / Отменить слияние
git mergetool                                  # Launch merge tool / Запустить инструмент слияния
```

### Rebasing / Перебазирование
```bash
git rebase main                                # Rebase onto main / Перебазировать на main
git rebase -i HEAD~3                           # Interactive rebase last 3 / Интерактивный rebase последних 3
git rebase --continue                          # Continue rebase / Продолжить rebase
git rebase --abort                             # Abort rebase / Отменить rebase
git rebase --skip                              # Skip current patch / Пропустить текущий патч
```

> [!WARNING]
> Never rebase commits that have been pushed to a shared remote. This rewrites history and can break other contributors' work.
> Никогда не делайте rebase коммитов, которые были отправлены в общий удалённый репозиторий. Это перезаписывает историю и может сломать работу других.

---

# 🌐 Remote Operations / Удалённые операции

### Remote Management / Управление удалёнными
```bash
git remote -v                                  # List remotes / Список удалённых репозиториев
git remote add origin <URL>                    # Add remote / Добавить удалённый репозиторий
git remote remove origin                       # Remove remote / Удалить удалённый репозиторий
git remote rename origin upstream              # Rename remote / Переименовать удалённый
git remote set-url origin <NEW_URL>            # Change URL / Изменить URL
git remote show origin                         # Show remote info / Показать информацию об удалённом
```

### Push / Отправка
```bash
git push                                       # Push to upstream / Отправить в upstream
git push origin main                           # Push to branch / Отправить в ветку
git push -u origin feature/new                 # Set upstream and push / Установить upstream и отправить
git push --all                                 # Push all branches / Отправить все ветки
git push --tags                                # Push tags / Отправить теги
git push --force                               # Force push / Принудительная отправка
git push --force-with-lease                    # Safer force push / Безопасная принудительная отправка
git push origin --delete feature/old           # Delete remote branch / Удалить удалённую ветку
```

> [!CAUTION]
> `git push --force` overwrites remote history. Always prefer `--force-with-lease` which checks that no one else has pushed.
> `git push --force` перезаписывает удалённую историю. Всегда предпочитайте `--force-with-lease`, который проверяет, что никто не отправлял изменения.

### Pull & Fetch / Получение и загрузка
```bash
git pull                                       # Fetch and merge / Загрузить и слить
git pull --rebase                              # Fetch and rebase / Загрузить и перебазировать
git pull origin main                           # Pull specific branch / Получить конкретную ветку
git fetch                                      # Fetch all remotes / Загрузить все удалённые
git fetch origin                               # Fetch specific remote / Загрузить конкретный удалённый
git fetch --prune                              # Remove deleted remote branches / Удалить удалённые ветки
git fetch --tags                               # Fetch tags / Загрузить теги
```

---

# 💾 Stashing / Временное сохранение

```bash
git stash                                      # Stash changes / Спрятать изменения
git stash push -m "WIP: feature"               # Stash with message / Спрятать с сообщением
git stash list                                 # List stashes / Список спрятанных
git stash show                                 # Show latest stash / Показать последнее спрятанное
git stash show -p stash@{0}                    # Show stash diff / Показать diff спрятанного
git stash pop                                  # Apply and drop stash / Применить и удалить
git stash apply                                # Apply stash / Применить спрятанное
git stash drop stash@{0}                       # Drop stash / Удалить спрятанное
git stash clear                                # Clear all stashes / Очистить все спрятанные
git stash branch feature/from-stash            # Create branch from stash / Создать ветку из спрятанного
```

---

# 📜 History & Logs / История и логи

```bash
git log                                        # Show commit history / Показать историю коммитов
git log --oneline                              # Compact log / Компактный лог
git log --graph                                # Show graph / Показать граф
git log --oneline --graph --decorate --all     # Pretty history / Красивая история
git log -n 10                                  # Last 10 commits / Последние 10 коммитов
git log --since="2 weeks ago"                  # Commits since date / Коммиты с даты
git log --author="John"                        # By author / По автору
git log --grep="fix"                           # Search commit messages / Поиск в сообщениях коммитов
git log -- file.txt                            # File history / История файла
git log -p file.txt                            # File history with diff / История файла с diff
git log --stat                                 # Show file stats / Показать статистику файлов
git log --follow file.txt                      # Follow file renames / Следить за переименованиями
git show <COMMIT>                              # Show commit details / Показать детали коммита
git show <COMMIT>:file.txt                     # Show file at commit / Показать файл в коммите
```

---

# ↩️ Undoing Changes / Отмена изменений

### Discard Changes / Отмена изменений
```bash
git checkout -- file.txt                       # Discard file changes / Отменить изменения файла
git restore file.txt                           # Modern discard / Современная отмена
git restore --staged file.txt                  # Unstage file / Убрать из индекса
git clean -fd                                  # Remove untracked files/dirs / Удалить неотслеживаемые
```

> [!CAUTION]
> `git clean -fd` permanently deletes untracked files and directories. Use `git clean -fdn` (dry run) first to preview.
> `git clean -fd` безвозвратно удаляет неотслеживаемые файлы и директории. Используйте `git clean -fdn` (пробный запуск) для предварительного просмотра.

### Reset / Сброс
```bash
git reset HEAD~1                               # Undo last commit (keep changes) / Отменить последний коммит (сохранить изменения)
git reset --soft HEAD~1                        # Undo commit (keep staged) / Отменить коммит (сохранить индекс)
git reset --hard HEAD~1                        # Undo commit (discard changes) / Отменить коммит (отменить изменения)
git reset <COMMIT>                             # Reset to commit / Сбросить до коммита
git reset --hard origin/main                   # Reset to remote / Сбросить до удалённого
```

> [!WARNING]
> `git reset --hard` permanently discards uncommitted changes. Make sure to stash or commit first.
> `git reset --hard` безвозвратно удаляет незакоммиченные изменения. Убедитесь, что сделали stash или commit.

### Revert / Откат
```bash
git revert <COMMIT>                            # Create revert commit / Создать откатывающий коммит
git revert HEAD                                # Revert last commit / Откатить последний коммит
git revert --no-commit <COMMIT>                # Revert without committing / Откатить без коммита
```

---

# 🏷️ Tags / Теги

```bash
git tag                                        # List tags / Список тегов
git tag v1.0.0                                 # Create lightweight tag / Создать лёгкий тег
git tag -a v1.0.0 -m "Release 1.0.0"           # Create annotated tag / Создать аннотированный тег
git tag -a v1.0.0 <COMMIT>                     # Tag specific commit / Отметить конкретный коммит
git show v1.0.0                                # Show tag info / Показать информацию о теге
git push origin v1.0.0                         # Push tag / Отправить тег
git push --tags                                # Push all tags / Отправить все теги
git tag -d v1.0.0                              # Delete local tag / Удалить локальный тег
git push origin --delete v1.0.0                # Delete remote tag / Удалить удалённый тег
```

---

# 🌟 Real-World Examples / Примеры из практики

### Quick Start / Быстрый старт
```bash
git init && git add . && git commit -m "Initial commit"  # Initialize project / Инициализировать проект
git clone <URL> && cd $(basename <URL> .git)   # Clone and enter / Клонировать и войти
```

### Feature Development / Разработка функции
```bash
git checkout -b feature/login                  # Start feature / Начать функцию
git add . && git commit -m "Add login UI"      # Save progress / Сохранить прогресс
git push -u origin feature/login               # Push feature / Отправить функцию
git checkout main && git pull --rebase         # Update main / Обновить main
git rebase main feature/login                  # Rebase feature / Перебазировать функцию
git checkout main && git merge --no-ff feature/login  # Merge feature / Слить функцию
```

### Emergency Hotfix / Экстренное исправление
```bash
git checkout -b hotfix/critical main           # Create hotfix branch / Создать ветку исправления
git commit -am "Fix critical bug"              # Quick fix / Быстрое исправление
git checkout main && git merge hotfix/critical # Merge to main / Слить в main
git push && git branch -d hotfix/critical      # Push and cleanup / Отправить и очистить
```

### Cleanup History / Очистка истории
```bash
git log --oneline -n 5                         # Review recent commits / Просмотреть последние коммиты
git rebase -i HEAD~5                           # Interactive rebase / Интерактивный rebase
git push --force-with-lease                    # Safe force push / Безопасная принудительная отправка
```

### Collaboration / Совместная работа
```bash
git fetch --prune                              # Clean remote branches / Очистить удалённые ветки
git branch -vv                                 # Show tracking branches / Показать отслеживаемые ветки
git log --oneline origin/main..HEAD            # Commits ahead of origin / Коммиты впереди origin
git log --oneline HEAD..origin/main            # Commits behind origin / Коммиты позади origin
```

---

# 💡 Tips & Best Practices / Советы и лучшие практики

- Always pull before push / Всегда делайте `pull` перед `push`
- Use `--force-with-lease` instead of `--force` / Используйте `--force-with-lease` вместо `--force`
- Write meaningful commit messages / Пишите осмысленные сообщения коммитов
- Commit often, push once working / Коммитьте часто, пушьте когда работает
- Use branches for features / Используйте ветки для функций
