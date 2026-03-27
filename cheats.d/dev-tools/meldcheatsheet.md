Title: 🔍 Meld (Merge & Diff)
Group: Dev & Tools
Icon: 🔍
Order: 18

# Meld Cheatsheet — Visual Diff & Merge Tool

> **Description:** Meld is a free, open-source visual diff and merge tool for files, directories, and version-controlled projects. It provides two- and three-way comparison with syntax highlighting and real-time merge editing. Built with GTK, it integrates natively with GNOME but works on any Linux desktop.
> Meld — это бесплатный визуальный инструмент сравнения и слияния файлов, директорий и проектов с контролем версий. Поддерживает 2- и 3-стороннее сравнение.

> **Status:** Actively maintained. Alternatives include **KDiff3** (KDE-native, 3-way merge), **Beyond Compare** (commercial, cross-platform), **vimdiff** (terminal-based), and **VS Code** built-in diff.
> **Role:** Developer / Sysadmin

---

## 📚 Table of Contents / Содержание

1. [Installation / Установка](#installation--установка)
2. [Basic CLI Usage / Основы CLI](#basic-cli-usage--основы-cli)
3. [Version Control Integration / Интеграция с Git/SVN](#version-control-integration--интеграция-с-gitsvn)
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
Meld — это прежде всего GUI-инструмент, но запуск из командной строки — самый частый способ использования.

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
Если вы хотите, чтобы Meld автоматически сливал бесконфликтные изменения при сравнении трёх файлов:

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
> При разрешении конфликтов в 3-стороннем окне, средняя панель — это обычно итоговый файл. Слева — LOCAL (ваша ветка), справа — REMOTE (входящая ветка).

### Diff Tool Comparison / Сравнение инструментов сравнения

| Tool | Type | Description (EN / RU) | Best For |
|------|------|----------------------|----------|
| **Meld** | GUI (GTK) | Visual 2/3-way diff & merge / Визуальное 2/3-стороннее сравнение | GNOME users, directory diffs |
| **KDiff3** | GUI (Qt) | 3-way merge with auto-merge / 3-стороннее слияние с авто-слиянием | KDE users, complex merges |
| **vimdiff** | Terminal | Vim-based inline diff / Vim-based построчное сравнение | Terminal-only environments |
| **Beyond Compare** | GUI (commercial) | Advanced file/folder comparison / Продвинутое сравнение файлов/папок | Professional use, cross-platform |
| **VS Code** | Editor | Built-in diff view / Встроенный просмотр различий | Developers already using VS Code |

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
Meld может сравнивать целые структуры папок.

```bash
# Compare two directories / Сравнить две директории
meld /path/to/dirA/ /path/to/dirB/

# Compare three directories / Сравнить три директории
meld /path/to/dir1 /path/to/dir2 /path/to/dir3
```

### Filtering Options / Настройки фильтрации

By default, Meld filters out some file types (object files, binaries).
You can toggle custom text filters via `Preferences -> Text Filters`.
По умолчанию Meld фильтрует некоторые типы файлов (объектные файлы, бинарники). Вы можете настроить текстовые фильтры через `Preferences -> Text Filters`.

> [!NOTE]
> In directory view, files colored **blue** are new/modified, **green** are identical, **red** are missing.
> В директорийном режиме файлы: **синие** — новые/изменённые, **зелёные** — идентичные, **красные** — отсутствующие.

---

## Official Documentation / Официальная документация

- **Meld:** https://meldmerge.org/
- **Meld Help:** https://meldmerge.org/help/
- **Git Diff/Merge Tools:** https://git-scm.com/docs/git-difftool
