---
Title: 📊 systemd-analyze — Boot Analysis
Group: "System & Logs"
Icon: 📊
Order: 21
tags:
  - systemd
  - boot
  - performance
  - systemd-analyze
  - sysadmin
  - linux
---

## Table of Contents

- [Description](#description)
- [Core Management](#core-management)
- [Sysadmin Operations](#sysadmin-operations)
- [Troubleshooting](#troubleshooting)
- [Comparison Tables](#comparison-tables)
- [Production Runbooks](#production-runbooks)
- [Documentation Links](#documentation-links)

---

# 📊 systemd-analyze Cheatsheet

## Description

**systemd-analyze** is a tool to analyze **systemd boot performance**, unit dependencies, and critical chain. Helps identify slow units and security issues. / **systemd-analyze** — инструмент анализа загрузки systemd, зависимостей unit-ов и критической цепочки. Помогает найти медленные unit-ы и проблемы безопасности.

**Common use cases / Типовые сценарии:**
- Measure boot time / Измерение времени загрузки
- Find slowest units / Поиск медленных unit-ов
- Visualize unit dependencies / Визуализация зависимостей
- Security audit of units / Аудит безопасности unit-ов

**Status:** Built-in systemd utility. Alternatives: **systemd-analyze plot**, **bootchart**, **dmesg**. / **Статус:** встроена в systemd; альтернативы — plot, bootchart, dmesg.

**Paths:** unit files `/etc/systemd/system/`, `/lib/systemd/system/`.

Cross-reference: [systemctl](systemctlcheatsheet.md), [journalctl](journalctlcheatsheet.md), [dmesg](dmesgcheatsheet.md).

---

## Core Management

### Boot time / Время загрузки

```bash
systemd-analyze
systemd-analyze time
systemd-analyze blame
systemd-analyze critical-chain
systemd-analyze critical-chain multi-user.target
```

### Plot / Построение графика

```bash
systemd-analyze plot > /tmp/boot-plot.svg
# Open in browser
```

### Security audit / Аудит безопасности

```bash
systemd-analyze security
systemd-analyze security sshd.service
systemd-analyze security --no-pager | head -40
```

---

## Sysadmin Operations

### Dependencies / Зависимости

```bash
systemd-analyze dot --to-pattern="*.target" | dot -Tsvg > /tmp/deps.svg
systemd-analyze verify /etc/systemd/system/myservice.service
systemd-analyze cat-config
```

### Compare boots / Сравнение загрузок

```bash
systemd-analyze time --history
# Or compare two boots via journal
journalctl -b -1 -o short-monotonic | head
journalctl -b -o short-monotonic | head
```

---

## Troubleshooting

| Symptom | Cause | Fix |
| :--- | :--- | :--- |
| Slow boot | Slow unit at top of blame | Optimize or disable unit |
| Missing dependency | Broken Requires/After | Fix unit file |
| Security score high | Over-permissive unit | Add sandboxing |
| verify fails | Syntax error | Fix unit file |

```bash
systemd-analyze blame | head -20
systemd-analyze critical-chain
systemd-analyze verify <UNIT>
```

---

## Comparison Tables

### Boot analysis tools / Инструменты анализа загрузки

| Tool | Notes |
| :--- | :--- |
| **systemd-analyze** | Built-in, precise |
| **bootchart** | Visual history |
| **dmesg** | Kernel messages |
| **journalctl -b** | Full boot journal |

---

## Production Runbooks

### Runbook: Optimize boot time / Оптимизация времени загрузки

1. `systemd-analyze blame` — find slowest units / Найти медленные unit-ы
2. Review critical-chain / Проверить critical-chain
3. Disable unnecessary services / Отключить ненужные сервисы
4. Delay non-critical units / Отложить некритичные unit-ы
5. `systemd-analyze verify` fixed units / Проверить исправления
6. Reboot and re-measure / Перезагрузить и замерить
7. Document baseline boot time / Задокументировать базовый boot time

### Runbook: Security hardening via analyze / Ужесточение через analyze

1. `systemd-analyze security` — review score / Проверить score
2. Focus on high-risk services / Сфокусироваться на рискованных
3. Add ProtectSystem, PrivateTmp, NoNewPrivileges / Добавить sandboxing
4. `systemd-analyze security` again — verify / Проверить снова
5. Test service after hardening / Протестировать после hardening
6. Document changes / Задокументировать изменения

---

## Documentation Links

- systemd-analyze man — https://www.freedesktop.org/software/systemd/man/systemd-analyze.html
- systemd docs — https://systemd.io/
