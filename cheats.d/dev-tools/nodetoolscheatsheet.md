Title: 🟢 Node — nvm/npm/yarn/pnpm
Group: Dev & Tools
Icon: 🟢
Order: 4

# Node.js Tools Cheatsheet — nvm / npm / yarn / pnpm

> **Description:** A collection of Node.js ecosystem tools for version management and package management. **nvm** manages multiple Node.js versions. **npm** is the default package manager bundled with Node.js. **yarn** (by Meta/Facebook) focuses on speed and caching. **pnpm** uses content-addressable storage for efficient disk usage, ideal for monorepos.
> Коллекция инструментов экосистемы Node.js для управления версиями и пакетами. **nvm** управляет версиями Node.js. **npm** — стандартный менеджер пакетов. **yarn** — быстрый менеджер от Meta. **pnpm** — эффективный менеджер с экономией дискового пространства.

> **Status:** All actively maintained. npm is the default; yarn and pnpm are popular alternatives. Modern alternative for version management: **fnm** (Fast Node Manager, Rust-based, faster than nvm).
> **Role:** Developer / DevOps

---

## Table of Contents
- [nvm — Version Manager](#-nvm--version-manager)
- [npm — Package Manager](#-npm--package-manager)
- [yarn — Fast Package Manager](#-yarn--fast-package-manager)
- [pnpm — Efficient Package Manager](#-pnpm--efficient-package-manager)
- [Package Manager Comparison](#package-manager-comparison)
- [Package Scripts](#-package-scripts--скрипты-пакетов)
- [Troubleshooting](#-troubleshooting--устранение-неполадок)
- [Real-World Examples](#-real-world-examples--примеры-из-практики)
- [Best Practices](#-best-practices--лучшие-практики)

---

# 📦 nvm — Version Manager

### Install & Use Versions / Установка и использование версий
```bash
nvm install --lts                             # Install latest LTS / Установить последнюю LTS
nvm install node                              # Install latest / Установить последнюю
nvm install 18.16.0                           # Install specific version / Установить конкретную версию
nvm use --lts                                 # Use LTS / Использовать LTS
nvm use 18                                    # Use version 18.x / Использовать версию 18.x
nvm use node                                  # Use latest / Использовать последнюю
```

### List & Manage / Список и управление
```bash
nvm ls                                        # List installed versions / Список установленных версий
nvm ls-remote                                 # List available versions / Список доступных версий
nvm ls-remote --lts                           # List LTS versions / Список LTS версий
nvm current                                   # Show current version / Показать текущую версию
nvm uninstall 16.0.0                          # Uninstall version / Удалить версию
```

### Default Version / Версия по умолчанию
```bash
nvm alias default 18                          # Set default version / Установить версию по умолчанию
nvm alias default node                        # Set default to latest / Установить по умолчанию последнюю
```

---

# 📦 npm — Package Manager

### Install Packages / Установка пакетов
```bash
npm install                                   # Install all dependencies / Установить все зависимости
npm ci                                        # Clean install (faster, CI) / Чистая установка (быстрее, CI)
npm install express                           # Install package / Установить пакет
npm install -D typescript                     # Install as dev dependency / Установить как dev зависимость
npm install -g pm2                            # Install globally / Установить глобально
```

### Update & Audit / Обновление и аудит
```bash
npm update                                    # Update packages / Обновить пакеты
npm update express                            # Update specific package / Обновить конкретный пакет
npm outdated                                  # Check outdated packages / Проверить устаревшие пакеты
npm audit                                     # Security audit / Аудит безопасности
npm audit fix                                 # Fix vulnerabilities / Исправить уязвимости
npm audit fix --force                         # Force fix (breaking changes) / Принудительное исправление
```

> [!WARNING]
> `npm audit fix --force` can introduce breaking changes by upgrading to major versions. Review changes carefully.
> `npm audit fix --force` может привести к breaking changes при обновлении до мажорных версий. Проверяйте изменения.

### Remove & Clean / Удаление и очистка
```bash
npm uninstall express                         # Uninstall package / Удалить пакет
npm prune                                     # Remove unused packages / Удалить неиспользуемые пакеты
npm cache clean --force                       # Clean cache / Очистить кэш
```

### Scripts / Скрипты
```bash
npm run build                                 # Run build script / Запустить скрипт build
npm run dev                                   # Run dev script / Запустить скрипт dev
npm start                                     # Run start script / Запустить скрипт start
npm test                                      # Run tests / Запустить тесты
```

### Publish / Публикация
```bash
npm login                                     # Login to npm registry / Войти в npm registry
npm publish                                   # Publish package / Опубликовать пакет
npm version patch                             # Bump patch version / Увеличить patch версию
npm version minor                             # Bump minor version / Увеличить minor версию
```

---

# 🧶 yarn — Fast Package Manager

### Install Packages / Установка пакетов
```bash
yarn                                          # Install all dependencies / Установить все зависимости
yarn install                                  # Same as above / То же что выше
yarn add express                              # Add package / Добавить пакет
yarn add -D typescript                        # Add as dev dependency / Добавить как dev зависимость
yarn global add pm2                           # Add globally / Добавить глобально
```

### Update & Audit / Обновление и аудит
```bash
yarn upgrade                                  # Upgrade packages / Обновить пакеты
yarn upgrade express                          # Upgrade specific package / Обновить конкретный пакет
yarn upgrade-interactive                      # Interactive upgrade / Интерактивное обновление
yarn audit                                    # Security audit / Аудит безопасности
```

### Remove & Clean / Удаление и очистка
```bash
yarn remove express                           # Remove package / Удалить пакет
yarn cache clean                              # Clean cache / Очистить кэш
```

### Scripts / Скрипты
```bash
yarn build                                    # Run build script / Запустить скрипт build
yarn dev                                      # Run dev script / Запустить скрипт dev
yarn start                                    # Run start script / Запустить скрипт start
yarn test                                     # Run tests / Запустить тесты
```

### Workspaces / Рабочие пространства
```bash
yarn workspaces info                          # Show workspaces / Показать workspaces
yarn workspace <NAME> add express             # Add to specific workspace / Добавить в конкретный workspace
```

---

# 📦 pnpm — Efficient Package Manager

### Install Packages / Установка пакетов
```bash
pnpm install                                  # Install all dependencies / Установить все зависимости
pnpm add express                              # Add package / Добавить пакет
pnpm add -D typescript                        # Add as dev dependency / Добавить как dev зависимость
pnpm add -g pm2                               # Add globally / Добавить глобально
```

### Update & Audit / Обновление и аудит
```bash
pnpm update                                   # Update packages / Обновить пакеты
pnpm update express                           # Update specific package / Обновить конкретный пакет
pnpm outdated                                 # Check outdated packages / Проверить устаревшие пакеты
pnpm audit                                    # Security audit / Аудит безопасности
```

### Remove & Clean / Удаление и очистка
```bash
pnpm remove express                           # Remove package / Удалить пакет
pnpm prune                                    # Remove unused packages / Удалить неиспользуемые пакеты
pnpm store prune                              # Prune store / Очистить хранилище
```

### Scripts / Скрипты
```bash
pnpm run build                                # Run build script / Запустить скрипт build
pnpm dev                                      # Run dev script / Запустить скрипт dev
pnpm start                                    # Run start script / Запустить скрипт start
```

---

## Package Manager Comparison

| Feature | npm | yarn | pnpm |
|---------|-----|------|------|
| **Default with Node** | ✅ Yes / Да | ❌ No / Нет | ❌ No / Нет |
| **Speed** | Moderate / Средняя | Fast / Быстрая | Fastest / Самая быстрая |
| **Disk Space** | Standard / Стандартное | Standard / Стандартное | Efficient (hardlinks) / Эффективное |
| **Lock File** | `package-lock.json` | `yarn.lock` | `pnpm-lock.yaml` |
| **Workspaces** | ✅ v7+ | ✅ v1+ | ✅ Yes / Да |
| **Phantom Dependencies** | ⚠️ Possible / Возможны | ⚠️ Possible / Возможны | ✅ Prevented / Предотвращены |
| **Best For** | Default choice / По умолчанию | Caching & speed / Кэш и скорость | Monorepos & disk savings / Monorepo и экономия диска |

---

# 📜 Package Scripts / Скрипты пакетов

### Common Scripts / Распространённые скрипты
```json
{
  "scripts": {
    "dev": "nodemon src/index.js",
    "build": "tsc",
    "start": "node dist/index.js",
    "test": "jest",
    "lint": "eslint src/**/*.ts",
    "format": "prettier --write src/**/*.ts",
    "clean": "rm -rf dist node_modules"
  }
}
```

### Run Scripts / Запуск скриптов
```bash
npm run <SCRIPT>                              # Run script / Запустить скрипт
yarn <SCRIPT>                                 # Run script (yarn) / Запустить скрипт (yarn)
pnpm <SCRIPT>                                 # Run script (pnpm) / Запустить скрипт (pnpm)
```

---

# 🐛 Troubleshooting / Устранение неполадок

### Clear Cache & Reinstall / Очистить кэш и переустановить
```bash
# npm
rm -rf node_modules package-lock.json
npm cache clean --force
npm install

# yarn
rm -rf node_modules yarn.lock
yarn cache clean
yarn install

# pnpm
rm -rf node_modules pnpm-lock.yaml
pnpm store prune
pnpm install
```

> [!CAUTION]
> Deleting lock files (`package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`) may change resolved dependency versions. Only do this as a last resort.
> Удаление lock-файлов может изменить версии зависимостей. Делайте это только в крайнем случае.

### Fix Permissions / Исправить права
```bash
# Fix npm global permissions / Исправить глобальные права npm
mkdir -p ~/.npm-global
npm config set prefix '~/.npm-global'
# Add to ~/.bashrc: export PATH=~/.npm-global/bin:$PATH
```

### Node Version Issues / Проблемы с версией Node
```bash
nvm use 18                                    # Switch Node version / Переключить версию Node
node -v                                       # Check version / Проверить версию
npm rebuild                                   # Rebuild native modules / Пересобрать нативные модули
```

---

# 🌟 Real-World Examples / Примеры из практики

### Initialize New Project / Инициализировать новый проект
```bash
mkdir myproject && cd myproject
nvm use --lts
npm init -y
npm install express dotenv
npm install -D nodemon typescript @types/node @types/express
```

### CI/CD Setup / Настройка CI/CD
```bash
# Use npm ci for faster, reproducible builds / Используйте npm ci для быстрых, воспроизводимых сборок
npm ci
npm run build
npm test
```

### Corepack (Yarn/pnpm Manager) / Corepack (менеджер Yarn/pnpm)
```bash
corepack enable                               # Enable Corepack / Включить Corepack
corepack prepare yarn@stable --activate       # Activate Yarn / Активировать Yarn
yarn -v                                       # Check Yarn version / Проверить версию Yarn
```

### Monorepo with Workspaces / Monorepo с workspaces
```json
{
  "workspaces": [
    "packages/*"
  ]
}
```

```bash
npm install                                   # Install all workspace dependencies / Установить все зависимости workspaces
yarn workspaces run build                     # Run build in all workspaces / Запустить build во всех workspaces
```

---

# 💡 Best Practices / Лучшие практики

- Use `nvm` to manage Node versions / Используйте `nvm` для управления версиями Node
- Use `npm ci` in CI/CD pipelines / Используйте `npm ci` в CI/CD пайплайнах
- Lock dependencies with lock files / Фиксируйте зависимости с lock файлами
- Run `audit` regularly / Регулярно запускайте `audit`
- Use `-D` for dev dependencies / Используйте `-D` для dev зависимостей
- Avoid global installs when possible / Избегайте глобальных установок когда возможно

> [!TIP]
> Use `npx` to run packages without installing them globally (e.g., `npx create-react-app myapp`).
> Используйте `npx` для запуска пакетов без глобальной установки.

---

## Official Documentation / Официальная документация

- **Node.js:** https://nodejs.org/en/docs
- **npm:** https://docs.npmjs.com/
- **yarn:** https://yarnpkg.com/getting-started
- **pnpm:** https://pnpm.io/motivation
- **nvm:** https://github.com/nvm-sh/nvm
- **fnm (alternative):** https://github.com/Schniz/fnm
- **Corepack:** https://nodejs.org/api/corepack.html
