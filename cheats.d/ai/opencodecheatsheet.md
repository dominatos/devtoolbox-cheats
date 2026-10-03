---
Title: 🧬 OpenCode — AI Coding Agent
Group: AI
Icon: 🧬
Order: 2
tags:
  - ai
  - coding-agent
  - opencode
  - llm
  - mcp
  - sysadmin
  - linux
---

## Table of Contents

- [Description](#description)
- [Installation](#installation)
- [Configuration](#configuration)
- [Core Management](#core-management)
- [Sysadmin Operations](#sysadmin-operations)
- [Security](#security)
- [Troubleshooting](#troubleshooting)
- [Comparison Tables](#comparison-tables)
- [Production Runbooks](#production-runbooks)
- [Documentation Links](#documentation-links)

---

# 🧬 OpenCode Cheatsheet

## Description

**OpenCode** is an open-source **AI coding agent** — terminal TUI, desktop app, and IDE extension. Multi-provider LLMs, plan/build modes, MCP support, skills, and permission policies. Used in this repo's toolchain. / **OpenCode** — open-source AI-агент для кодинга: TUI, desktop, IDE-расширение. Мультипровайдерные LLM, plan/build, MCP, skills, политики разрешений.

**Common use cases / Типовые сценарии:**
- AI-assisted automation and IaC scripting / AI-ассистированные скрипты и IaC
- Terminal pair programming / Парное программирование в терминале
- MCP tool integration / Интеграция MCP-инструментов
- Code review and refactor with local or cloud LLMs / Ревью и рефакторинг

**Status:** Active (anomalyco/opencode). Alternatives: **Aider**, **Claude Code**, **Codex CLI**. / **Статус:** активно развивается; альтернативы — Aider, Claude Code, Codex CLI.

**Paths:** config via `/connect` or opencode.ai/docs/config; project `AGENTS.md`.  
**Install:** script, npm, Homebrew tap.

Cross-reference: [Ollama](ollamacheatsheet.md), [LiteLLM](litellmcheatsheet.md), [MCP](mcpcheatsheet.md).

---

## Installation

### Install OpenCode / Установка OpenCode

```bash
# Install script
curl -fsSL https://opencode.ai/install | bash

# npm
npm install -g opencode-ai

# Homebrew (macOS)
brew install anomalyco/tap/opencode
```

```bash
opencode --version
opencode
```

---

## Configuration

### Main files / Основные файлы

`AGENTS.md` (project instructions)

`~/.config/opencode/` (user config)

`opencode.json` / `opencode.jsonc` (optional project config)

### Provider connection / Подключение провайдера

```bash
# In TUI
# /connect  — choose provider (Anthropic, OpenAI, OpenRouter, Ollama, ...)
# /init     — generate AGENTS.md
# /share    — share session
```

### Using local Ollama / С локальным Ollama

```bash
# /connect → Ollama → pick model (e.g. llama3.2)
# Or configure provider base URL to http://127.0.0.1:11434
```

---

## Core Management

### TUI commands / Команды TUI

| Command | Action |
| :--- | :--- |
| `/connect` | Choose LLM provider |
| `/init` | Create AGENTS.md |
| `/models` | Switch model |
| `/share` | Share session |
| `/help` | Show help |
| `Ctrl+C` | Cancel / exit |

### Non-interactive / Неинтерактивный режим

```bash
opencode run "explain this repo structure"
opencode -p "list systemd units related to nginx"
```

---

## Sysadmin Operations

### Sessions and logs / Сессии и логи

```bash
ls ~/.local/share/opencode/
# Session data under user data dir
```

### MCP servers / MCP-серверы

```bash
# Configure MCP servers in project or user config
# See opencode.ai/docs for MCP config format
```

### Permissions / Разрешения

```bash
# OpenCode enforces tool permissions (shell, edit, etc.)
# Review permission prompts; use project policies for automation
```

---

## Security

### Hardening / Ужесточение

1. Do not commit API keys / Не коммитьте API-ключи
2. Prefer scoped provider keys / Используйте ключи с ограниченными правами
3. Review shell tool permissions / Проверяйте разрешения shell-инструментов
4. Use AGENTS.md to constrain agent behavior / Ограничивайте поведение через AGENTS.md
5. Keep OpenCode updated / Обновляйте OpenCode
6. Audit MCP server configs / Аудируйте конфиги MCP-серверов

```bash
# Keys typically via /connect or environment — never hardcode in repo
```

---

## Troubleshooting

| Symptom | Cause | Fix |
| :--- | :--- | :--- |
| Provider auth failed | Wrong/expired key | `/connect` re-auth |
| Model not found | Wrong model id | `/models` select valid model |
| Ollama not reachable | Ollama down / wrong port | Check Ollama at :11434 |
| MCP server fails | Bad config / binary missing | Fix MCP config; install server |
| Slow responses | Large context / small model | Trim context; use faster model |

```bash
# Check Ollama backend
curl http://127.0.0.1:11434/api/tags
opencode --version
```

---

## Comparison Tables

### AI coding agents / AI-агенты для кодинга

| Agent | Interface | Notes |
| :--- | :--- | :--- |
| **OpenCode** | TUI / desktop / IDE | Multi-provider, MCP, skills |
| **Aider** | Terminal | Git-native, repo map |
| **Claude Code** | Terminal | Anthropic-focused |
| **Codex CLI** | Terminal | OpenAI-focused |

---

## Production Runbooks

### Runbook: Onboard OpenCode for a team / Внедрение OpenCode в команде

1. Install via script or package manager / Установить
2. Each user `/connect` to approved provider / Подключить провайдер
3. Create project `AGENTS.md` with repo rules / Создать AGENTS.md
4. Define permission policies for automation / Задать политики разрешений
5. Document allowed models and key storage / Задокументировать модели и ключи
6. Optional: route via LiteLLM gateway / Опционально: шлюз LiteLLM

### Runbook: Use Ollama as backend / Ollama как бэкенд

1. Deploy Ollama; pull coding model / Развернуть Ollama; загрузить модель
2. `/connect` → Ollama → model / Подключить
3. Test with small prompt / Проверить
4. Document model choice and RAM needs / Задокументировать модель и RAM

---

## Documentation Links

- OpenCode docs — https://opencode.ai/docs/
- OpenCode GitHub — https://github.com/anomalyco/opencode
- Install — https://opencode.ai/install
