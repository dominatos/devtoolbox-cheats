Title: 🔍 Meld (Merge & Diff)
Group: Dev & Tools
Icon: 🔍
Order: 18

---

## 📚 Table of Contents / Содержание

1. [Installation / Установка](#installation--установка)
2. [Basic CLI Usage / Основы CLI](#basic-cli-usage--основы-cli)
3. [Version Control Integration / Интеграция с GitSVN](#version-control-integration--интеграция-с-gitsvn)
4. [Keyboard Shortcuts / Горячие клавиши](#keyboard-shortcuts--горячие-клавиши)
5. [Directory Comparison / Сравнение директорий](#directory-comparison--сравнение-директорий)

---

## Installation / Установка

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install meld

# RHEL/AlmaLinux/Fedora
sudo dnf install meld

# macOS (Homebrew)
brew install --cask meld
```

---

## Basic CLI Usage / Основы CLI

Meld is primarily a GUI tool, but passing arguments from the command line is the most common way to launch it.

```bash
# Compare two files (2-way diff) / Сравнение двух файлов
meld file1.txt file2.txt

# Compare three files (3-way diff) / Сравнение трёх файлов
meld file1.txt file2.txt file3.txt

# View uncommitted changes in current Git/SVN repo / Просмотр несохраненных изменений
meld .

# Launch without files / Запуск пустого окна
meld
```

### Auto-Merge Flag / Флаг авто-слияния

If you want Meld to automatically merge non-conflicting changes when comparing three files (usually in a VCS conflict scenario):

```bash
# Typical auto-merge syntax / Синтаксис авто-слияния
meld --auto-merge <BASE> <LOCAL> <REMOTE> -o <MERGED_OUTPUT>
```

---

## Version Control Integration / Интеграция с Git/SVN

### Setting Meld as Git Diff Tool / Meld как Git Diff

To use Meld whenever you run `git difftool`:

```bash
git config --global diff.tool meld
git config --global difftool.prompt false      # Replaces prompt with instant Meld / Убирает запрос подтверждения
```

```bash
# Usage / Использование
git difftool                       # Diff working tree vs index / Сравнить рабочую копию
git difftool --cached              # Diff index vs HEAD / Сравнить индекс (staged)
git difftool <COMMIT_A> <COMMIT_B> # Diff between two commits / Сравнить коммиты
```

### Setting Meld as Git Merge Tool / Meld как Git Merge

To use Meld to resolve merge conflicts (`git mergetool`):

```bash
git config --global merge.tool meld
git config --global mergetool.prompt false
```

```bash
# Usage / Использование
git merge <BRANCH_NAME>
# If conflict occurs:
git mergetool
```

> [!TIP]
> When resolving conflicts in a 3-way merge window, the middle pane is usually the final output file where you should combine changes. Left is usually LOCAL (your branch), Right is usually REMOTE (incoming branch).

---

## Keyboard Shortcuts / Горячие клавиши

| Key / Клавиша | Action (EN / RU) |
|---------------|------------------|
| `Alt + Down` | Next difference / Следующее различие |
| `Alt + Up` | Previous difference / Предыдущее различие |
| `Alt + Right` | Push changes from left pane to right pane / Копировать изменения вправо |
| `Alt + Left` | Push changes from right pane to left pane / Копировать изменения влево |
| `Ctrl + S` | Save file / Сохранить файл |
| `Ctrl + F` | Find / Найти |
| `Ctrl + G` | Find next / Найти следующее |
| `Ctrl + Shift + R` | Refresh comparison / Обновить сравнение |

---

## Directory Comparison / Сравнение директорий

Meld can compare entire folder structures.

```bash
# Compare two directories / Сравнить две директории
meld /path/to/dirA/ /path/to/dirB/

# Compare three directories / Сравнить три директории
meld /path/to/dir1 /path/to/dir2 /path/to/dir3
```

### Filtering Options / Настройки фильтрации

By default, Meld filters out some file types (object files, binaries).
You can toggle custom text filters via `Preferences -> Text Filters`.

> [!NOTE]
> In directory view, files colored **blue** are new/modified, **green** are identical, **red** are missing.
