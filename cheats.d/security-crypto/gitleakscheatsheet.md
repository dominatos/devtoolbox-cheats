Title: 🔐 Git Secret Leak Detection
Group: Security & Crypto
Icon: 🔐
Order: 6

> Complete guide for detecting, removing, and preventing sensitive data leaks in Git repositories.  
> Полное руководство по обнаружению, удалению и предотвращению утечек чувствительных данных в Git-репозиториях.

---

## 📋 Table of Contents

1. [Installation & Configuration](#installation--configuration)
2. [Scanning Tools Overview](#scanning-tools-overview)
3. [Automated Scanning](#automated-scanning)
4. [Manual Search](#manual-search)
5. [Removing Secrets from History](#removing-secrets-from-history)
6. [Revoking Compromised Secrets](#revoking-compromised-secrets)
7. [Prevention & Best Practices](#prevention--best-practices)
8. [GitHub-Specific Tools](#github-specific-tools)
9. [CI/CD Integration](#cicd-integration)
10. [Secret Managers](#secret-managers)
11. [Language-Specific Examples](#language-specific-examples)
12. [Pre-Publication Checklist](#pre-publication-checklist)
13. [Emergency Incident Runbook](#emergency-incident-runbook)
14. [Quick Reference](#quick-reference)
15. [Resources & Links](#resources--links)

---

## Installation & Configuration

### Gitleaks — Установка / Installation

Default ports: N/A (CLI tool)
Config file: `.gitleaks.toml` (project root)

```bash
# macOS
brew install gitleaks  # Install via Homebrew / Установка через Homebrew

# Linux — download binary / Скачать бинарник
wget https://github.com/gitleaks/gitleaks/releases/download/v8.18.2/gitleaks_8.18.2_linux_x64.tar.gz
tar -xzf gitleaks_8.18.2_linux_x64.tar.gz
sudo mv gitleaks /usr/local/bin/

# Docker
docker pull zricethezav/gitleaks:latest  # Pull Docker image / Скачать Docker-образ

# Windows (Scoop)
scoop install gitleaks
```

### TruffleHog — Установка / Installation

```bash
# Go version (recommended) / Go-версия (рекомендуется)
brew install truffleHog

# Python legacy version / Python-версия (устаревшая)
pip install truffleHog

# Docker
docker pull trufflesecurity/trufflehog:latest
```

### git-secrets (AWS) — Установка / Installation

```bash
# macOS
brew install git-secrets

# Linux — from source / Из исходников
git clone https://github.com/awslabs/git-secrets.git
cd git-secrets
sudo make install
```

### detect-secrets (Yelp) — Установка / Installation

```bash
pip install detect-secrets  # Install via pip / Установка через pip
```

### GitGuardian CLI (ggshield) — Установка / Installation

```bash
# macOS
brew install gitguardian/tap/ggshield

# pip
pip install ggshield
```

### git-filter-repo — Установка / Installation

```bash
# pip
pip3 install git-filter-repo  # Install via pip / Установка через pip

# macOS
brew install git-filter-repo

# Manual download / Ручная установка
wget https://raw.githubusercontent.com/newren/git-filter-repo/main/git-filter-repo
chmod +x git-filter-repo
sudo mv git-filter-repo /usr/local/bin/
```

### BFG Repo-Cleaner — Установка / Installation

```bash
# macOS
brew install bfg

# Manual (requires Java) / Ручная установка (требуется Java)
wget https://repo1.maven.org/maven2/com/madgag/bfg/1.14.0/bfg-1.14.0.jar
```

---

## Scanning Tools Overview

### Comparison Table — Сравнительная таблица инструментов сканирования

| Tool | Language | Method | Verified Secrets | Baseline Support | Best For / Лучше всего для |
|------|----------|--------|------------------|------------------|---------------------------|
| **gitleaks** | Go | Regex + entropy | ✅ | ❌ | Fast repo scanning, CI/CD integration / Быстрое сканирование, интеграция в CI/CD |
| **TruffleHog** | Go | Regex + entropy + API verification | ✅ (active checks) | ❌ | Finding real (verified) secrets / Поиск реальных (верифицированных) секретов |
| **git-secrets** | Bash | Regex (AWS-focused) | ❌ | ❌ | AWS-centric projects, pre-commit hooks / AWS-проекты, pre-commit хуки |
| **detect-secrets** | Python | Regex + entropy + plugins | ❌ | ✅ | Incremental scanning with baselines / Инкрементальное сканирование с baseline |
| **GitGuardian** | Python | Cloud ML + regex | ✅ (cloud) | ❌ | Enterprise, commercial environments / Корпоративные среды |

> [!TIP]
> For most projects, start with **gitleaks** for speed, and run **TruffleHog** with `--only-verified` for a second pass to reduce false positives.
> Для большинства проектов используйте **gitleaks** для скорости, а затем **TruffleHog** с `--only-verified` для снижения ложных срабатываний.

### History Cleaning Methods — Сравнение методов очистки истории

| Method | Speed | Complexity | Safety | Recommendation / Рекомендация |
|--------|-------|------------|--------|------------------------------|
| **git-filter-repo** | ⚡ Fast | Medium | ✅ Safe | ✅ Recommended / Рекомендуется |
| **BFG Repo-Cleaner** | ⚡ Fast | Low | ✅ Safe | Good for simple cases / Хорош для простых случаев |
| **git filter-branch** | 🐢 Slow | High | ⚠️ Risky | ❌ Legacy, avoid / Устаревший, избегайте |

---

## Automated Scanning

### Gitleaks — Сканирование / Scanning

```bash
gitleaks detect --source . --verbose  # Basic scan / Базовое сканирование

gitleaks detect --source . --report-path gitleaks-report.json  # JSON report / Отчёт в JSON

gitleaks detect --source . --report-format sarif --report-path gitleaks.sarif  # SARIF report (for GitHub) / Отчёт в SARIF (для GitHub)

gitleaks detect --source . --log-opts="origin/main"  # Scan specific branch / Сканирование конкретной ветки

gitleaks detect --source . --config .gitleaks.toml  # Custom config / Пользовательский конфиг

gitleaks detect --source . --no-git  # Scan without Git history / Сканирование без Git-истории

gitleaks detect --source . --log-opts="-- . ':!*.test.js'"  # Ignore specific files / Игнорировать конкретные файлы

gitleaks protect --staged --verbose  # Pre-commit mode (scan staged) / Режим pre-commit (сканировать staged)
```

#### Gitleaks Configuration / Конфигурация Gitleaks
`.gitleaks.toml`

```toml
title = "gitleaks config"

[extend]
useDefault = true

[allowlist]
description = "Allowlist"
paths = [
    '''\.example$''',
    '''\.sample$''',
    '''test/''',
    '''docs/'''
]
regexes = [
    '''(fake|example|test|dummy)''',
]

[[rules]]
id = "custom-api-key"
description = "Custom API Key"
regex = '''(?i)api[_-]?key[_-]?([a-z0-9]{32,})'''
entropy = 3.5
```

---

### TruffleHog — Сканирование / Scanning

```bash
trufflehog git file://. --since-commit HEAD~100 --only-verified  # Scan recent commits (verified only) / Сканирование последних коммитов

trufflehog git file://. --json > trufflehog-report.json  # Full history scan with JSON report / Полное сканирование с отчётом

trufflehog git https://github.com/<USER>/<REPO>  # Scan remote repo / Сканирование удалённого репозитория

trufflehog git file://. --regex --rules custom-rules.json  # Custom regex rules / Пользовательские regex-правила

trufflehog filesystem /path/to/directory  # Scan filesystem (non-Git) / Сканирование файловой системы (не Git)

trufflehog github --org=<ORG_NAME> --token=<GITHUB_TOKEN>  # Scan GitHub organization / Сканирование GitHub-организации
```

---

### git-secrets (AWS) — Использование / Usage

```bash
git secrets --install  # Install hooks into repo / Установить хуки в репозиторий

# Install globally for all new repos / Установить глобально для всех новых репозиториев
git secrets --install ~/.git-templates/git-secrets
git config --global init.templateDir ~/.git-templates/git-secrets

git secrets --register-aws  # Register AWS patterns / Зарегистрировать AWS-паттерны

git secrets --add 'password\s*=\s*.+'  # Add custom pattern / Добавить пользовательский паттерн
git secrets --add --allowed 'password\s*=\s*"example"'  # Add allowed exception / Добавить исключение

git secrets --scan-history  # Scan full history / Сканировать всю историю
git secrets --scan  # Scan last commit / Сканировать последний коммит
git secrets --list  # List registered patterns / Список зарегистрированных паттернов
```

---

### detect-secrets (Yelp) — Использование / Usage

```bash
detect-secrets scan > .secrets.baseline  # Create baseline / Создать baseline

detect-secrets scan --baseline .secrets.baseline  # Scan against baseline / Сканирование относительно baseline

detect-secrets audit .secrets.baseline  # Interactive audit / Интерактивный аудит

detect-secrets scan file1.py file2.js  # Scan specific files / Сканировать конкретные файлы

detect-secrets scan --baseline .secrets.baseline --update  # Update baseline / Обновить baseline

detect-secrets scan --exclude-files '\.example$' --exclude-files 'test/.*'  # Exclude patterns / Исключить паттерны
```

---

### GitGuardian CLI (ggshield) — Использование / Usage

```bash
ggshield auth login  # Authenticate / Авторизация

ggshield secret scan repo .  # Scan repository / Сканирование репозитория

ggshield secret scan pre-commit  # Pre-commit scan / Сканирование pre-commit

ggshield secret scan ci  # CI scan / Сканирование CI

ggshield secret scan docker nginx:latest  # Scan Docker image / Сканирование Docker-образа
```

---

## Manual Search

### Basic Git Commands — Базовые Git-команды

#### Search by Content / Поиск по содержимому

```bash
git log -p --all -S "<SEARCH_STRING>"  # Search for string in history / Поиск строки во всей истории

git log -p --all -G "password\s*=\s*['\"].*['\"]"  # Search with regex / Поиск с regex

git log -p --all -S "<SECRET_KEY>" | grep -B 3 -A 3 "<SECRET_KEY>"  # Search with context (±3 lines) / Поиск с контекстом (±3 строки)

git log --all --grep="password"  # Search in commit messages / Поиск в сообщениях коммитов
```

#### Search in Specific Files / Поиск в конкретных файлах

```bash
git log --all --full-history -p -- path/to/file.conf  # File history / История конкретного файла

git log --all --full-history -- "*.env" "*.conf"  # All versions of file types / Все версии файлов по типу

git show <COMMIT_HASH>:path/to/file  # Show file at specific commit / Показать файл в конкретном коммите

git log --diff-filter=D --summary | grep delete  # Find when a file was deleted / Найти когда файл был удалён
```

#### Search Deleted Files / Поиск удалённых файлов

```bash
git log --diff-filter=D --summary | grep delete | awk '{print $4}'  # List all deleted files / Список всех удалённых файлов

git checkout <COMMIT_HASH>^ -- path/to/deleted/file  # Restore deleted file for review / Восстановить удалённый файл для просмотра
```

---

### Pattern Search — Поиск по паттернам

#### Private Keys / Приватные ключи

```bash
git log -p --all | grep -i "BEGIN.*PRIVATE" -B 5 -A 10  # Any private key / Любой приватный ключ
git log -p --all | grep -i "BEGIN RSA PRIVATE KEY"  # RSA key / RSA-ключ
git log -p --all | grep -i "BEGIN OPENSSH PRIVATE KEY"  # OpenSSH key / OpenSSH-ключ
```

#### Passwords & Tokens / Пароли и токены

```bash
git log -p --all | grep -Ei "(password|passwd|pwd)\s*[:=]" -B 2 -A 2  # Passwords / Пароли
git log -p --all | grep -Ei "(api[_-]?key|token|secret)\s*[:=]" -B 2 -A 2  # API keys & tokens / API-ключи и токены
git log -p --all | grep -Ei "authorization\s*:\s*bearer" -i  # Bearer tokens / Bearer-токены
```

#### Credentials in URLs / Реквизиты доступа в URL

```bash
git log -p --all | grep -E "https?://[^:]+:[^@]+@" -B 2 -A 2  # URL with embedded credentials / URL со встроенными реквизитами
```

#### Email Addresses / Email-адреса

```bash
git log -p --all | grep -E "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}"  # Find email addresses / Поиск email-адресов
```

#### IP Addresses / IP-адреса

```bash
git log -p --all | grep -E "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b"  # Find IP addresses / Поиск IP-адресов
```

#### AWS Keys / AWS-ключи

```bash
git log -p --all | grep -E "AKIA[0-9A-Z]{16}"  # AWS Access Key ID / ID ключа доступа AWS
git log -p --all | grep -E "aws_secret_access_key"  # AWS Secret Key reference / Ссылка на секретный ключ AWS
```

#### JWT Tokens / JWT-токены

```bash
git log -p --all | grep -E "eyJ[A-Za-z0-9_-]*\.eyJ[A-Za-z0-9_-]*\.[A-Za-z0-9_-]*"  # JWT pattern / JWT-паттерн
```

---

### Search by File Type / Поиск по типу файла

```bash
# Config files / Конфиг-файлы
git log -p --all -- "*.conf" "*.config" "*.ini" "*.yaml" "*.yml" "*.toml"

# Environment files / Файлы окружения
git log -p --all -- "*.env" "*.env.*" ".envrc"

# Credential files / Файлы с реквизитами
git log -p --all -- "*credentials*" "*secret*" "*password*"

# SSH keys / SSH-ключи
git log -p --all -- "*.pem" "*.key" "*id_rsa*" "*id_ed25519*"

# Certificate files / Файлы сертификатов
git log -p --all -- "*.p12" "*.pfx" "*.jks" "*.keystore"

# Backup files (often contain secrets) / Резервные копии (часто содержат секреты)
git log -p --all -- "*.bak" "*.backup" "*.old" "*~"
```

---

### Advanced Search / Расширенный поиск

#### By Author and Date / По автору и дате

```bash
git log -p --all --author="<EMAIL>" | grep -i "password"  # Commits by author / Коммиты конкретного автора

git log -p --all --since="2024-01-01" --until="2024-12-31" | grep -i "secret"  # Commits by date range / Коммиты за период

git log --all --shortstat | grep -B 1 "100[0-9]\+ insertion"  # Large commits (potential dumps) / Большие коммиты (потенциальные дампы)
```

#### Stash and Reflog / Stash и Reflog

```bash
git stash list  # List stashes / Список сохранённых stash
git stash show -p stash@{0} | grep -i "password"  # Search in stash / Поиск в stash

git reflog show --all | grep -i "sensitive"  # Search in reflog / Поиск в reflog
git show HEAD@{5}:path/to/file  # Show file from reflog entry / Показать файл из reflog
```

---

## Removing Secrets from History

> [!CAUTION]
> **All methods below rewrite Git history.** After cleaning, you MUST `force push` and all collaborators MUST re-clone or `git reset --hard`. Coordinate with your team before proceeding!
> **Все методы ниже перезаписывают историю Git.** После очистки необходим `force push`, и все участники ДОЛЖНЫ заново клонировать репозиторий или выполнить `git reset --hard`. Согласуйте с командой перед началом!

### Method 1: git-filter-repo (Recommended) / git-filter-repo (Рекомендуется)

#### Remove Files / Удаление файлов

```bash
git filter-repo --path path/to/secret.conf --invert-paths  # Remove single file / Удалить один файл

git filter-repo --path secret1.conf --path secret2.key --invert-paths  # Remove multiple files / Удалить несколько файлов

git filter-repo --path-glob '*.env' --invert-paths  # Remove by pattern / Удалить по паттерну

git filter-repo --path secrets/ --invert-paths  # Remove entire directory / Удалить целую директорию
```

#### Replace Content / Заменить содержимое в файлах

```bash
# Create expressions file / Создайте файл с заменами (expressions.txt)
# Format: literal:old_text==>new_text or regex:pattern==>replacement
```

`expressions.txt`

```text
literal:<PASSWORD>==>REDACTED
regex:api[_-]?key\s*=\s*['"]([^'"]+)['"]==>api_key="REDACTED"
literal:smtp.gmail.com==>smtp.example.com
```

```bash
git filter-repo --replace-text expressions.txt  # Apply replacements / Применить замены
```

#### Remove Large Files / Удалить большие файлы

```bash
git filter-repo --strip-blobs-bigger-than 10M  # Remove files > 10MB / Удалить файлы больше 10MB
```

#### Fix Author Info / Исправить информацию об авторе

`mailmap.txt`

```text
Correct Name <correct@email.com> <old@email.com>
Correct Name <correct@email.com> Old Name <old@email.com>
```

```bash
git filter-repo --mailmap mailmap.txt  # Apply mailmap / Применить mailmap
```

#### Combined Operations / Комбинированные операции

```bash
git filter-repo \
  --path secrets/ --invert-paths \
  --path '*.env' --invert-paths \
  --replace-text expressions.txt \
  --strip-blobs-bigger-than 10M
```

---

### Method 2: BFG Repo-Cleaner / BFG Repo-Cleaner

#### Remove Files / Удаление файлов

```bash
bfg --delete-files secret.conf  # Single file / Один файл
bfg --delete-files "{secret.conf,password.txt,api_key.json}"  # Multiple files / Несколько файлов
bfg --delete-files "*.env"  # By pattern / По паттерну
bfg --delete-folders secrets  # Delete folders / Удалить папки
bfg --delete-folders "{logs,temp,cache}"  # Multiple folders / Несколько папок
```

#### Replace Strings / Заменить строки

```bash
# Create file with secrets (one per line) / Создайте файл с секретами (по одному на строку)
echo "<PASSWORD>" > passwords.txt
echo "<API_KEY>" >> passwords.txt
echo "<SECRET_TOKEN>" >> passwords.txt

bfg --replace-text passwords.txt  # Replace with ***REMOVED*** / Заменить на ***REMOVED***
```

#### Remove Large Files / Удалить большие файлы

```bash
bfg --strip-blobs-bigger-than 10M  # Remove files > 10MB / Удалить файлы больше 10MB
```

> [!IMPORTANT]
> After BFG, always run cleanup / После BFG всегда выполняйте очистку:
> ```bash
> git reflog expire --expire=now --all
> git gc --prune=now --aggressive
> ```

---

### Method 3: git filter-branch (Legacy — Not Recommended) / git filter-branch (Устаревший — не рекомендуется)

> [!WARNING]
> `git filter-branch` is slow, error-prone, and officially deprecated. Use `git-filter-repo` instead.
> `git filter-branch` медленный, подвержен ошибкам и официально устарел. Используйте `git-filter-repo`.

#### Remove File / Удалить файл

```bash
git filter-branch --force --index-filter \
  'git rm --cached --ignore-unmatch path/to/secret.conf' \
  --prune-empty --tag-name-filter cat -- --all
```

#### Remove Directory / Удалить папку

```bash
git filter-branch --force --index-filter \
  'git rm -r --cached --ignore-unmatch secrets/' \
  --prune-empty --tag-name-filter cat -- --all
```

#### Replace Content / Заменить содержимое

```bash
git filter-branch --tree-filter \
  'find . -name "*.conf" -exec sed -i "s/<PASSWORD>/REDACTED/g" {} \;' \
  --prune-empty --tag-name-filter cat -- --all
```

#### Cleanup after filter-branch / Очистка после filter-branch

```bash
rm -rf .git/refs/original/
git reflog expire --expire=now --all
git gc --prune=now --aggressive
```

---

### Post-Cleanup Finalization / Финализация после очистки

> [!CAUTION]
> `--force` push will overwrite remote history. Ensure all collaborators are notified!
> `--force` push перезапишет удалённую историю. Убедитесь что все участники уведомлены!

```bash
# 1. Verify result / Проверить результат
gitleaks detect --source . --verbose
git log --all --oneline | head -20

# 2. Force push (CAREFUL!) / Force push (ОСТОРОЖНО!)
git push origin --force --all
git push origin --force --tags

# 3. Collaborators must re-clone / Участники должны переклонировать:
rm -rf local-repo
git clone https://github.com/<USER>/<REPO>.git

# Or reset / Или сбросить:
cd local-repo
git fetch origin
git reset --hard origin/main
git clean -fdx
```

---

## Revoking Compromised Secrets

> [!WARNING]
> Removing secrets from Git history is NOT enough. Always revoke and rotate the compromised credentials immediately.
> Удаление секретов из истории Git НЕДОСТАТОЧНО. Всегда отзывайте и ротируйте скомпрометированные реквизиты немедленно.

### AWS Keys / AWS-ключи

```bash
aws iam list-access-keys  # List keys / Список ключей

aws iam update-access-key --access-key-id <ACCESS_KEY_ID> --status Inactive  # Deactivate / Деактивировать

aws iam delete-access-key --access-key-id <ACCESS_KEY_ID>  # Delete key / Удалить ключ

aws iam create-access-key  # Create new / Создать новый

# Key rotation (best practice) / Ротация ключей (best practice)
aws iam create-access-key --user-name <USER>
# Update applications with the new key / Обновите приложения с новым ключом
aws iam update-access-key --access-key-id <OLD_KEY_ID> --status Inactive
# Test / Тестируйте
aws iam delete-access-key --access-key-id <OLD_KEY_ID>
```

### GitHub Personal Access Token / GitHub Personal Access Token

```bash
# Web UI:
# Settings → Developer settings → Personal access tokens → Revoke

# Or via API / Или через API:
curl -X DELETE \
  -H "Authorization: token <OLD_TOKEN>" \
  https://api.github.com/applications/<CLIENT_ID>/token

# Create new / Создать новый:
# Settings → Developer settings → Personal access tokens → Generate new token
```

### Telegram Bot Token / Токен бота Telegram

```bash
# @BotFather
/mybots
# Select bot / Выберите бота
# API Token → Revoke current token
# Generate new / Сгенерируйте новый
```

### Google Cloud / OAuth

```bash
# Web UI:
# Google Cloud Console → APIs & Services → Credentials
# Find compromised credential → Delete / Найдите скомпрометированный credential → Удалите

# gcloud CLI
gcloud auth revoke <ACCOUNT>  # Revoke auth / Отозвать авторизацию
gcloud iam service-accounts keys delete <KEY_ID> \
  --iam-account=<SA_NAME>@<PROJECT>.iam.gserviceaccount.com  # Delete key / Удалить ключ

gcloud iam service-accounts keys create key.json \
  --iam-account=<SA_NAME>@<PROJECT>.iam.gserviceaccount.com  # Create new key / Создать новый ключ
```

### SSH Keys / SSH-ключи

```bash
# GitHub: Settings → SSH and GPG keys → Delete

ssh-keygen -R <HOST>  # Remove from known_hosts / Удалить из known_hosts
vim ~/.ssh/authorized_keys  # Remove public key / Удалить публичный ключ

ssh-keygen -t ed25519 -C "<EMAIL>"  # Generate new key pair / Создать новую пару ключей
```

### Database Passwords / Пароли БД

```sql
-- MySQL/MariaDB
ALTER USER '<USER>'@'<HOST>' IDENTIFIED BY '<PASSWORD>';
FLUSH PRIVILEGES;

-- PostgreSQL
ALTER USER <USER> WITH PASSWORD '<PASSWORD>';

-- MongoDB
db.updateUser("<USER>", {pwd: "<PASSWORD>"})
```

### Docker Registry Tokens / Токены Docker Registry

```bash
# Docker Hub: Account Settings → Security → Access Tokens → Revoke

# Harbor / Private registry:
# Delete robot account and recreate / Удалить robot account и создать заново
```

### NPM Token / NPM-токен

```bash
npm token revoke <TOKEN_ID>  # Revoke / Отозвать
npm token create --read-only  # Create new (read-only) / Создать (только чтение)
npm token create --publish  # Create new (publish) / Создать (publish)
```

---

## Prevention & Best Practices

### Pre-commit Hooks / Pre-commit хуки

#### Using pre-commit Framework / Использование pre-commit framework

```bash
pip install pre-commit  # Install / Установка
```

`.pre-commit-config.yaml`

```yaml
repos:
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.18.2
    hooks:
      - id: gitleaks

  - repo: https://github.com/Yelp/detect-secrets
    rev: v1.4.0
    hooks:
      - id: detect-secrets
        args: ['--baseline', '.secrets.baseline']

  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.5.0
    hooks:
      - id: detect-private-key
      - id: check-added-large-files
        args: ['--maxkb=1000']
      - id: check-merge-conflict
      - id: trailing-whitespace
```

```bash
pre-commit install  # Install hooks / Установить хуки
pre-commit run --all-files  # Run manually / Запустить вручную
```

#### Custom Bash Pre-commit Hook / Пользовательский bash pre-commit хук

`.git/hooks/pre-commit`

```bash
#!/bin/bash

# Check for gitleaks / Проверка на gitleaks
if command -v gitleaks &> /dev/null; then
    gitleaks protect --staged --verbose
    if [ $? -ne 0 ]; then
        echo "❌ Gitleaks found secrets! Commit rejected."
        exit 1
    fi
fi

# Check for large files / Проверка на большие файлы
MAX_SIZE=1048576  # 1MB in bytes / 1MB в байтах
for file in $(git diff --cached --name-only); do
    if [ -f "$file" ]; then
        size=$(wc -c < "$file")
        if [ $size -gt $MAX_SIZE ]; then
            echo "❌ File $file is too large: $size bytes"
            exit 1
        fi
    fi
done

# Check for private keys / Проверка на приватные ключи
if git diff --cached | grep -E "BEGIN.*PRIVATE KEY"; then
    echo "❌ Private key detected in commit!"
    exit 1
fi

echo "✅ Pre-commit checks passed"
exit 0
```

```bash
chmod +x .git/hooks/pre-commit  # Make executable / Сделать исполняемым
```

---

### .gitignore — Recommended Template / Рекомендуемый шаблон

`.gitignore`

```gitignore
# Secrets and credentials / Секреты и реквизиты
.env
.env.*
!.env.example
*.pem
*.key
*.p12
*.pfx
*.jks
*.keystore
id_rsa*
id_ed25519*
id_ecdsa*

# Configs with secrets / Конфиги с секретами
*secret*
*password*
*credential*
config/secrets.yml
config/database.yml
!config/database.yml.example

# Cloud provider configs / Конфиги облачных провайдеров
.aws/
.azure/
.gcloud/
credentials.json
service-account.json

# Logs (may contain secrets) / Логи (могут содержать секреты)
*.log
logs/
*.log.*

# Backups / Резервные копии
*.bak
*.backup
*.old
*~
*.swp
*.swo

# Directories / Директории
secrets/
private/
.secrets/
tmp/
temp/

# IDE
.vscode/
.idea/
*.iml

# OS
.DS_Store
Thumbs.db
```

---

### Git Attributes for Sensitive Files / Git Attributes для чувствительных файлов

`.gitattributes`

```gitattributes
# Never show diff for these files / Никогда не показывать diff для этих файлов
*.pem diff=secret
*.key diff=secret
*secret* diff=secret
.env* diff=secret
```

`~/.gitconfig` or `.git/config`

```ini
[diff "secret"]
    textconv = echo "REDACTED"
```

---

### Environment-Based Configuration / Конфигурация через переменные окружения

#### Using dotenv / Использование dotenv

`.env` (add to `.gitignore`)

```bash
DATABASE_PASSWORD=<PASSWORD>
API_KEY=<API_KEY>
```

`.env.example` (safe to commit / безопасно коммитить)

```bash
DATABASE_PASSWORD=your_password_here
API_KEY=your_api_key_here
```

#### Docker Secrets / Docker-секреты

`docker-compose.yml`

```yaml
version: '3.8'
services:
  app:
    image: myapp
    secrets:
      - db_password

secrets:
  db_password:
    file: ./secrets/db_password.txt
```

#### Kubernetes Secrets / Kubernetes-секреты

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: mysecret
type: Opaque
data:
  password: <BASE64_ENCODED_PASSWORD>  # base64 encoded / в кодировке base64
```

```bash
kubectl create secret generic mysecret --from-literal=password=<PASSWORD>  # Create secret / Создать секрет
```

---

## GitHub-Specific Tools

### GitHub Secret Scanning / Сканирование секретов GitHub

Automatically active for public repositories / Автоматически активно для публичных репозиториев.

**For private repos (requires GitHub Advanced Security) / Для приватных (требует GitHub Advanced Security):**

```text
Repository → Settings → Code security and analysis
→ Enable Secret scanning
→ Enable Push protection
```

### GitHub Advanced Security API / GitHub Advanced Security API

```bash
curl -X PUT \
  -H "Authorization: token <GITHUB_TOKEN>" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/<OWNER>/<REPO>/vulnerability-alerts  # Enable vulnerability alerts / Включить оповещения об уязвимостях
```

---

## CI/CD Integration

### GitHub Actions Secret Scanning Workflow / GitHub Actions для сканирования секретов

`.github/workflows/secret-scan.yml`

```yaml
name: Secret Scanning

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  gitleaks:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
        with:
          fetch-depth: 0

      - name: Run Gitleaks
        uses: gitleaks/gitleaks-action@v2
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

  trufflehog:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
        with:
          fetch-depth: 0

      - name: TruffleHog OSS
        uses: trufflesecurity/trufflehog@main
        with:
          path: ./
          base: main
          head: HEAD

  detect-secrets:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.10'

      - name: Install detect-secrets
        run: pip install detect-secrets

      - name: Run detect-secrets
        run: |
          detect-secrets scan --baseline .secrets.baseline
          detect-secrets audit .secrets.baseline
```

---

## Secret Managers

### HashiCorp Vault

Default port: `8200`

```bash
brew install vault  # Install / Установка

vault server -dev  # Start dev server / Запуск dev-сервера

vault kv put secret/myapp password=<PASSWORD>  # Store secret / Сохранить секрет

vault kv get secret/myapp  # Retrieve secret / Получить секрет
```

### AWS Secrets Manager

```bash
# Create secret / Создать секрет
aws secretsmanager create-secret \
    --name MySecret \
    --secret-string '{"username":"<USER>","password":"<PASSWORD>"}'

# Retrieve secret / Получить секрет
aws secretsmanager get-secret-value --secret-id MySecret
```

### SOPS (Secrets OPerationS)

```bash
brew install sops  # Install / Установка

sops secrets.yaml  # Create/edit encrypted file / Создать/редактировать зашифрованный файл

sops -d secrets.yaml  # Decrypt / Расшифровать
```

---

## Language-Specific Examples

### Python (Django/Flask)

```python
# settings.py
import os
from dotenv import load_dotenv

load_dotenv()

SECRET_KEY = os.getenv('DJANGO_SECRET_KEY')
DATABASE_PASSWORD = os.getenv('DB_PASSWORD')

# NEVER / НИКОГДА:
# SECRET_KEY = 'django-insecure-hardcoded-key-123'
```

### Node.js

```javascript
// config.js
require('dotenv').config();

module.exports = {
    apiKey: process.env.API_KEY,
    dbPassword: process.env.DB_PASSWORD
};

// NEVER / НИКОГДА:
// const API_KEY = 'hardcoded-api-key-123';
```

### Go

```go
package main

import (
    "os"
    "github.com/joho/godotenv"
)

func main() {
    godotenv.Load()
    apiKey := os.Getenv("API_KEY")

    // NEVER / НИКОГДА:
    // apiKey := "hardcoded-api-key-123"
}
```

### Ruby (Rails)

```ruby
# config/database.yml
production:
  password: <%= ENV['DATABASE_PASSWORD'] %>

# NEVER / НИКОГДА:
# password: hardcoded_password_123
```

### PHP

```php
<?php
// config.php
$dotenv = Dotenv\Dotenv::createImmutable(__DIR__);
$dotenv->load();

$apiKey = $_ENV['API_KEY'];

// NEVER / НИКОГДА:
// $apiKey = 'hardcoded-api-key-123';
?>
```

---

## Pre-Publication Checklist

### Minimal Checklist / Минимальный чеклист

```bash
# 1. Scan / Сканирование
gitleaks detect --source . --verbose
trufflehog git file://. --only-verified

# 2. Manual check critical files / Ручная проверка критичных файлов
git log -p --all -- "*.env" "*.conf" "*.yaml"
git log -p --all -- "*secret*" "*password*" "*credential*"

# 3. Verify .gitignore / Проверить .gitignore
cat .gitignore | grep -E "(env|secret|password|key|credential)"

# 4. Remove temporary files and logs / Удалить временные файлы и логи
git clean -fdx
rm -rf logs/ *.log tmp/ temp/

# 5. Create example files / Создать example-файлы
cp .env .env.example
# Replace real values with placeholders / Заменить реальные значения на плейсхолдеры

# 6. Commit changes / Коммит изменений
git add .gitignore *.example
git commit -m "Prepare for public release"

# 7. Final scan / Финальное сканирование
gitleaks detect --source . --verbose
```

### Extended Checklist / Расширенный чеклист

- [ ] Run `gitleaks detect` / Запустить `gitleaks detect`
- [ ] Run `trufflehog` / Запустить `trufflehog`
- [ ] Check all `*.env`, `*.conf`, `*.yaml` files / Проверить все `*.env`, `*.conf`, `*.yaml`
- [ ] Check logs and temp files / Проверить логи и временные файлы
- [ ] Verify `.gitignore` is up-to-date / Убедиться что `.gitignore` актуален
- [ ] Create `.env.example`, `config.example`, etc. / Создать `.env.example`, `config.example` и т.д.
- [ ] Remove all `*.log`, `*.bak`, `*.old` files / Удалить все `*.log`, `*.bak`, `*.old` файлы
- [ ] Check code comments for TODO with secrets / Проверить комментарии на TODO с секретами
- [ ] Check `docker-compose.yml` for hardcoded values / Проверить `docker-compose.yml` на hardcoded значения
- [ ] Check `README` for real data examples / Проверить `README` на примеры с реальными данными
- [ ] Check CI/CD configs (`.github`, `.gitlab-ci.yml`) / Проверить CI/CD конфиги
- [ ] Install pre-commit hooks / Установить pre-commit хуки
- [ ] Add secret files to `.gitignore` / Добавить секретные файлы в `.gitignore`
- [ ] Add `.gitattributes` for diff filtering / Добавить `.gitattributes` для diff-фильтрации
- [ ] Verify all secrets are in env variables / Проверить что все секреты в переменных окружения
- [ ] Update documentation with secret instructions / Обновить документацию с инструкциями по секретам
- [ ] Enable GitHub Secret Scanning (if available) / Настроить GitHub Secret Scanning (если доступно)
- [ ] Create GitHub Actions for auto scanning / Создать GitHub Actions для автосканирования
- [ ] Check all branches and tags / Проверить все branches и tags
- [ ] Verify `node_modules/`, `vendor/` are in `.gitignore` / Убедиться что `node_modules/`, `vendor/` в `.gitignore`
- [ ] Final scan with all tools / Финальное сканирование всеми инструментами

---

## Emergency Incident Runbook

### Production Runbook: Secret Leak Response / Экстренный протокол при утечке секретов

> [!CAUTION]
> If secrets have been pushed to a **public** repository, they are already compromised. Bots continuously scan GitHub for leaked credentials. Revoke and rotate ALL exposed secrets immediately — do NOT rely solely on history cleanup.
> Если секреты были запушены в **публичный** репозиторий, они уже скомпрометированы. Боты непрерывно сканируют GitHub на утечки. Отзовите и ротируйте ВСЕ раскрытые секреты немедленно — НЕ полагайтесь только на очистку истории.

1. **Immediately (0-1 min)** — Make the repository private / Немедленно сделать репозиторий приватным
   ```text
   GitHub: Repository → Settings → Danger Zone → Change visibility → Private
   ```

2. **Within 5 minutes** — Revoke ALL compromised secrets / Отозвать ВСЕ скомпрометированные секреты
   ```bash
   # AWS
   aws iam update-access-key --access-key-id <ACCESS_KEY_ID> --status Inactive

   # GitHub Token
   # Settings → Developer settings → Tokens → Revoke

   # Database — change passwords immediately / Сменить пароли немедленно
   ```

3. **Within 15 minutes** — Clean Git history / Очистить историю Git
   ```bash
   git filter-repo --path <SECRET_FILE> --invert-paths
   git push --force --all
   ```

4. **Within 1 hour** — Full audit / Полный аудит
   ```bash
   # Check access logs / Проверить логи доступа
   # Check for unusual activity / Проверить необычную активность
   # Notify the team / Уведомить команду
   ```

5. **Within 1 day** — Post-mortem / Постмортем
   - Document the incident / Документировать инцидент
   - Update procedures / Обновить процедуры
   - Set up automation to prevent recurrence / Настроить автоматизацию для предотвращения

---

## Quick Reference

### Scan (pick one) / Сканирование (выберите один)

```bash
gitleaks detect --source . --verbose  # Fastest / Самый быстрый
# or / или
trufflehog git file://. --only-verified  # Most accurate / Самый точный
# or / или
detect-secrets scan  # Baseline support / Поддержка baseline
```

### Clean History (pick one) / Очистка истории (выберите один)

```bash
# Modern (recommended) / Современный (рекомендуется)
git filter-repo --path secret.conf --invert-paths

# Simple / Простой
bfg --delete-files secret.conf
git reflog expire --expire=now --all && git gc --prune=now --aggressive

# Legacy (not recommended) / Устаревший (не рекомендуется)
git filter-branch --index-filter 'git rm --cached --ignore-unmatch secret.conf' --prune-empty -- --all
```

### After Cleanup / После очистки

```bash
gitleaks detect --source . --verbose  # Verify / Проверка

# Force push (CAREFUL!) / Force push (ОСТОРОЖНО!)
git push origin --force --all
git push origin --force --tags
```

### Prevention / Предотвращение

```bash
pip install pre-commit  # Install pre-commit / Установить pre-commit
pre-commit install  # Activate hooks / Активировать хуки

# Add to .gitignore / Добавить в .gitignore
echo ".env" >> .gitignore
echo "*.log" >> .gitignore
echo "*secret*" >> .gitignore
```

---

## Sysadmin Operations

### Log Locations / Расположение логов

| Tool | Log Location / Расположение лога |
|------|----------------------------------|
| gitleaks | stdout / report file (`--report-path`) |
| TruffleHog | stdout / JSON (`--json`) |
| git-secrets | stdout |
| detect-secrets | `.secrets.baseline` |
| pre-commit | stdout |
| GitHub Actions | GitHub UI → Actions tab |
| Vault | `/var/log/vault/vault_audit.log` (when configured) |

### Logrotate Configuration / Конфигурация Logrotate

`/etc/logrotate.d/vault`

```text
/var/log/vault/*.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    create 0640 vault vault
    sharedscripts
    postrotate
        systemctl reload vault 2>/dev/null || true
    endscript
}
```

> [!NOTE]
> Most secret scanning tools (gitleaks, TruffleHog, detect-secrets) are CLI tools that write to stdout or report files. They don't typically require logrotate. Configure logrotate only for long-running services like HashiCorp Vault.
> Большинство инструментов сканирования (gitleaks, TruffleHog, detect-secrets) — CLI утилиты, пишущие в stdout или файлы отчётов. Logrotate обычно не нужен. Настраивайте logrotate только для долгоживущих сервисов вроде HashiCorp Vault.

---

## Resources & Links

### Tools / Инструменты

- [gitleaks](https://github.com/gitleaks/gitleaks)
- [TruffleHog](https://github.com/trufflesecurity/trufflehog)
- [git-secrets](https://github.com/awslabs/git-secrets)
- [detect-secrets](https://github.com/Yelp/detect-secrets)
- [git-filter-repo](https://github.com/newren/git-filter-repo)
- [BFG Repo-Cleaner](https://rtyley.github.io/bfg-repo-cleaner/)

### Documentation / Документация

- [GitHub Secret Scanning](https://docs.github.com/en/code-security/secret-scanning)
- [GitLab Secret Detection](https://docs.gitlab.com/ee/user/application_security/secret_detection/)
- [Pre-commit framework](https://pre-commit.com/)

### Secret Pattern Lists / Списки секретных паттернов

- [GitGuardian Secret Patterns](https://github.com/GitGuardian/ggshield/tree/main/ggshield/core/scan/secret/secret_patterns)
- [Gitleaks Rules](https://github.com/gitleaks/gitleaks/blob/master/config/gitleaks.toml)
- [Common Regex Patterns](https://github.com/dxa4481/truffleHogRegexes/blob/master/truffleHogRegexes/regexes.json)

---

**Last Updated / Последнее обновление:** February 2026  
**Version / Версия:** 2.0

> [!WARNING]
> **Always treat a secret leak as a serious security incident.** Even after removing from Git history, secrets may have been indexed by search engines or cloned by attackers. **ALWAYS** revoke and recreate compromised secrets.
> **Всегда считайте утечку секретов серьёзным инцидентом безопасности.** Даже после удаления из истории Git, секреты могли быть проиндексированы поисковиками или склонированы злоумышленниками. **ВСЕГДА** отзывайте и пересоздавайте скомпрометированные секреты.
