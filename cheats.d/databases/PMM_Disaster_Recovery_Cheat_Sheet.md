Title: 🗄️ PMM Disaster Recovery
Group: Databases
Icon: 🗄️
Order: 20

# PMM Disaster Recovery — Full Production Recovery Cheatsheet

> **Percona Monitoring and Management (PMM)** is an open-source database monitoring, management, and observability solution by Percona. It bundles Prometheus, Grafana, VictoriaMetrics, ClickHouse, and PostgreSQL (QAN) into a single Docker-based appliance for MySQL, PostgreSQL, MongoDB, and ProxySQL.
>
> **Common use cases / Типичные сценарии:** Database performance monitoring, query analytics (QAN), slow query analysis, replication monitoring, backup monitoring, security threat detection.
>
> **Status / Статус:** Actively maintained by Percona (current: PMM 3.x). Alternatives: **Datadog** (commercial SaaS), **Grafana Cloud** (managed), **Zabbix** (general-purpose), **New Relic** (APM).
>
> **Default port / Порт по умолчанию:** `443/tcp` (HTTPS)

---

## 📚 Table of Contents / Содержание

1. [Architecture](#architecture)
2. [Installation & Configuration](#installation--configuration)
3. [Core Management](#core-management)
4. [Sysadmin Operations](#sysadmin-operations)
5. [Security](#security)
6. [Backup & Restore](#backup--restore)
7. [Troubleshooting & Tools](#troubleshooting--tools)
8. [Production Runbooks](#production-runbooks)
9. [Disaster Recovery Case Study](#disaster-recovery-case-study)
10. [Logrotate Configuration](#logrotate-configuration)
11. [Additional Notes](#additional-notes)
12. [Official Documentation](#official-documentation)

---

## Architecture

### PMM Internal Components / Внутренние компоненты PMM

| Component / Компонент | Purpose / Назначение |
|---|---|
| Prometheus | Metrics collection / Сбор метрик |
| PostgreSQL | QAN (Query Analytics) storage / Хранение QAN |
| Grafana | Dashboards and visualization / Дашборды |
| Nginx | Frontend routing and TLS / Маршрутизация и TLS |
| VictoriaMetrics | Additional TSDB storage / Доп. хранилище TSDB |
| PMM UI plugins | Main PMM interface / Интерфейс PMM |
| Supervisord | Internal service management / Управление сервисами |

### Service Dependency Chain / Цепочка зависимостей

```text
PostgreSQL → Grafana datasource init → PMM plugin init → PMM UI available
```

> [!IMPORTANT]
> If PostgreSQL fails, the entire PMM UI cascade will fail. Grafana depends on PostgreSQL for datasource configuration.
> Если PostgreSQL не стартует, весь каскад PMM UI выйдет из строя.

### Internal Paths / Внутренние пути

| Path / Путь | Purpose / Назначение |
|---|---|
| `/srv/prometheus` | Prometheus metrics data / Данные метрик |
| `/srv/postgres14` | PostgreSQL data / Данные PostgreSQL |
| `/srv/grafana` | Grafana configs and plugins / Конфиги Grafana |
| `/srv/logs` | PMM internal logs / Логи PMM |

### Default Ports / Порты по умолчанию

| Port / Порт | Purpose / Назначение |
|---|---|
| `443` | PMM Web UI (HTTPS) |
| `80` | HTTP redirect to HTTPS |
| `42000-42010` | PMM agent communication / Агенты PMM |

---

## Installation & Configuration

### Volume Strategy / Стратегия томов

> [!WARNING]
> **Always use named volumes, never bind mounts.** Bind mounts cause data corruption if the compose directory is copied.
> **Всегда используйте именованные тома, никогда bind mounts.**

| Strategy / Стратегия | Example / Пример | Safety / Безопасность |
|---|---|---|
| **Named volume** | `pmm-data:/srv` | ✅ Isolated / Изолировано — **Recommended** |
| **Bind mount** | `./data:/srv` | ❌ Shared if copied / Общий — **Avoid** |

### Production docker-compose.yml

`/opt/pmm/docker-compose.yml`

```yaml
version: '3.8'

services:
  pmm-server:
    image: percona/pmm-server:3
    container_name: pmm-server
    restart: always
    ports:
      - "443:443"
    environment:
      GF_PLUGINS_ALLOW_LOADING_UNSIGNED_PLUGINS: pmm-app,pmm-qan-app-panel
      PMM_QAN_API2__SERVICE_TYPE: none
    volumes:
      - pmm-data:/srv

volumes:
  pmm-data:
```

### Start Services / Запуск сервисов

```bash
docker compose up -d       # Start PMM / Запустить PMM
docker compose ps          # Check status / Проверить статус
docker compose logs -f     # Follow logs / Следить за логами
```

### PMM User ID

```bash
docker run --rm percona/pmm-server:3 id pmm  # Check UID / Проверить UID
# Output: uid=1000(pmm) gid=1000(pmm)
```

> [!NOTE]
> PMM runs as UID `1000`. All `/srv` data must be owned by `1000:1000`.

---

## Core Management

### Internal Service Control / Управление сервисами

```bash
docker exec pmm-server supervisorctl status              # List services / Список сервисов
docker exec pmm-server supervisorctl restart all          # Restart all / Перезапустить все
docker exec pmm-server supervisorctl restart postgresql   # Restart PostgreSQL
docker exec pmm-server supervisorctl restart grafana      # Restart Grafana
```

### Health Checks / Проверки здоровья

```bash
curl -k https://localhost/pmm/server-status                # PMM status / Статус PMM
curl -k https://localhost/grafana/api/health               # Grafana health / Здоровье Grafana
curl -k -I https://localhost/pmm-ui/graph/                 # PMM UI check / Проверка PMM UI
```

---

## Sysadmin Operations

### Log Locations / Расположение логов

| Log / Лог | Path (inside container) / Путь |
|---|---|
| Grafana | `/srv/logs/grafana.log` |
| PostgreSQL | `/srv/logs/postgresql.log` |
| PMM managed | `/srv/logs/pmm-managed.log` |
| Nginx | `/srv/logs/nginx.log` |

```bash
docker exec pmm-server tail -f /srv/logs/grafana.log      # Follow Grafana log / Логи Grafana
docker exec pmm-server tail -f /srv/logs/postgresql.log    # Follow PG log / Логи PostgreSQL
```

### Docker Volume Inspection / Инспекция томов

```bash
docker volume ls                                           # List volumes / Список томов
docker volume inspect pmm-data                             # Inspect PMM volume / Инспекция тома
docker inspect pmm-server | jq '.[0].Mounts'               # Check mounts / Монтирования
```

### Shell Access / Доступ в контейнер

```bash
docker exec -it pmm-server bash                            # Enter container / Войти в контейнер
mount | grep srv                                           # Check mounts / Точки монтирования
ls -lah /srv/postgres14                                    # Check PG data / Данные PostgreSQL
```

### Network & Firewall / Сеть и файрвол

```bash
sudo ufw allow 443/tcp                                    # UFW: allow PMM / Разрешить PMM
sudo firewall-cmd --permanent --add-port=443/tcp && sudo firewall-cmd --reload  # firewalld
```

---

## Security

### Grafana Password Reset / Сброс пароля Grafana

```bash
docker exec pmm-server grafana-cli \
  --config /etc/grafana/grafana.ini \
  --homepath /usr/share/grafana \
  admin reset-admin-password '<PASSWORD>'                  # Reset password / Сброс пароля
```

> [!CAUTION]
> Change the default PMM admin password immediately after deployment.
> Смените пароль по умолчанию сразу после развёртывания.

### Unsigned Plugins / Неподписанные плагины

```yaml
# Required in docker-compose.yml / Обязательно в docker-compose.yml
GF_PLUGINS_ALLOW_LOADING_UNSIGNED_PLUGINS: pmm-app,pmm-qan-app-panel
```

---

## Backup & Restore

### Full Backup / Полный бэкап

```bash
docker run --rm \
  -v pmm-data:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/pmm-backup-$(date +%Y%m%d_%H%M%S).tar.gz /data
```

### Restore / Восстановление

```bash
docker compose down                                        # Stop PMM / Остановить PMM

docker run --rm \
  -v pmm-data:/data \
  -v $(pwd):/backup \
  alpine sh -c 'cd / && tar xzf /backup/pmm-backup-<TIMESTAMP>.tar.gz'

docker compose up -d                                       # Start PMM / Запустить PMM
```

### Automated Backup Script / Скрипт автобэкапа

`/usr/local/bin/pmm-backup.sh`

```bash
#!/bin/bash
BACKUP_DIR="/backup/pmm"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
mkdir -p "$BACKUP_DIR"

docker run --rm \
  -v pmm-data:/data \
  -v "$BACKUP_DIR":/backup \
  alpine tar czf "/backup/pmm-backup-$TIMESTAMP.tar.gz" /data

find "$BACKUP_DIR" -name "*.tar.gz" -mtime +7 -delete     # Retain 7 days / Хранить 7 дней
echo "✅ PMM backup: pmm-backup-$TIMESTAMP.tar.gz"
```

**Cron:**

```bash
0 3 * * * /usr/local/bin/pmm-backup.sh >> /var/log/pmm-backup.log 2>&1
```

---

## Troubleshooting & Tools

### Diagnostic Commands / Команды диагностики

```bash
docker logs pmm-server | grep -Ei 'postgres|grafana|error|panic|wal|permission'  # Find errors / Поиск ошибок
docker exec pmm-server supervisorctl status                                       # Service status / Статус сервисов
docker volume inspect pmm-data                                                    # Verify volume / Проверка тома
```

### Common Issues / Частые проблемы

| Problem / Проблема | Symptom / Симптом | Fix / Решение |
|---|---|---|
| PostgreSQL crash | `PANIC: could not locate valid checkpoint record` | WAL reset (see runbook) |
| Permission denied | `Permission denied: postgresql.conf` | Fix ownership to `1000:1000` |
| Grafana auth broken | `{"code":7,"error":"Access denied"}` | Reset admin password |
| PMM UI 404 | `404 page not found` | Set `GF_PLUGINS_ALLOW_LOADING_UNSIGNED_PLUGINS` |
| Stale PID | PostgreSQL won't start | Remove `postmaster.pid` |

---

## Production Runbooks

### Runbook: Full PMM Emergency Recovery / Полное аварийное восстановление

> [!CAUTION]
> This involves destructive operations on PostgreSQL WAL. Ensure backups exist first.
> Убедитесь в наличии бэкапов перед началом.

1. **Stop PMM / Остановить PMM:**
   ```bash
   docker compose down
   ```

2. **Fix ownership / Исправить владельца:**
   ```bash
   docker run --rm -v pmm-data:/data alpine sh -c '
   chown -R 1000:1000 /data/postgres14
   chown -R 1000:1000 /data/grafana
   chown -R 1000:1000 /data/prometheus
   '
   ```

3. **Fix permissions / Исправить права:**
   ```bash
   docker run --rm -v pmm-data:/data alpine sh -c '
   chmod 700 /data/postgres14
   chmod 644 /data/postgres14/postgresql.conf
   chmod 644 /data/postgres14/pg_hba.conf
   '
   ```

4. **Remove stale PID / Удалить PID:**
   ```bash
   docker run --rm -v pmm-data:/data alpine sh -c '
   rm -f /data/postgres14/postmaster.pid
   rm -f /data/postgres14/postmaster.opts
   '
   ```

5. **Reset WAL (if needed) / Сброс WAL:**
   ```bash
   docker run --rm -u 1000 \
   -v pmm-data:/data \
   postgres:14 bash -c 'cd /data/postgres14 && pg_resetwal -f .'
   ```

6. **Start PMM / Запустить PMM:**
   ```bash
   docker compose up -d
   ```

7. **Reset Grafana password / Сброс пароля Grafana:**
   ```bash
   docker exec pmm-server grafana-cli \
     --config /etc/grafana/grafana.ini \
     --homepath /usr/share/grafana \
     admin reset-admin-password '<PASSWORD>'
   ```

8. **Verify / Проверить:**
   ```bash
   curl -k https://localhost/pmm/server-status
   curl -k https://localhost/grafana/api/health
   curl -k -I https://localhost/pmm-ui/graph/
   docker exec pmm-server supervisorctl status
   ```

### Runbook: PostgreSQL WAL Recovery / Восстановление WAL

> [!WARNING]
> `pg_resetwal` may cause data inconsistency. Use only when PostgreSQL refuses to start.

1. **Reset WAL:**
   ```bash
   docker run --rm -u 1000 -v pmm-data:/data \
   postgres:14 bash -c 'cd /data/postgres14 && pg_resetwal -f .'
   ```

2. **Remove WAL files (if reset fails):**
   ```bash
   docker run --rm -v pmm-data:/data alpine sh -c 'rm -rf /data/postgres14/pg_wal/*'
   ```

3. **Full PostgreSQL removal (last resort):**
   > [!CAUTION]
   > Deletes all QAN data. Prometheus metrics are preserved.
   ```bash
   docker run --rm -v pmm-data:/data alpine sh -c 'rm -rf /data/postgres14'
   ```

### Runbook: Volume Migration (Bind → Named) / Миграция томов

1. **Stop deployment:**
   ```bash
   docker compose down
   ```
2. **Create named volume:**
   ```bash
   docker volume create pmm-data
   ```
3. **Copy data:**
   ```bash
   docker run --rm -v $(pwd)/data:/source:ro -v pmm-data:/dest \
   alpine sh -c 'cp -a /source/. /dest/'
   ```
4. **Update docker-compose.yml** from `./data:/srv` to `pmm-data:/srv`
5. **Start and verify:**
   ```bash
   docker compose up -d
   docker exec pmm-server supervisorctl status
   ```

### Recovery Timeline / Время восстановления

| Step / Шаг | Time / Время |
|---|---|
| Diagnostics / Диагностика | 5 min |
| Permission repair / Права | 1 min |
| WAL cleanup / WAL | 2 min |
| PMM restart / Перезапуск | 1 min |
| Grafana recovery / Grafana | 2 min |
| Validation / Валидация | 5 min |
| **Total / Итого** | **~16 min** |

---

## Disaster Recovery Case Study

### What Happened / Что произошло

PMM 3.x was running in Docker Compose with ~33 GB Prometheus metrics, active Grafana dashboards, and QAN data.

A second deployment was started from a **copied directory** using **bind mounts** (`./data:/srv`). Both deployments wrote to the same PostgreSQL data simultaneously.

### Root Cause / Причина

Two PMM instances accessing the same PostgreSQL data directory caused WAL corruption, invalid checkpoints, and cascading PMM failure.

### Symptoms / Симптомы

```text
PostgreSQL:  PANIC: could not locate valid checkpoint record
Grafana:     {"code":7,"error":"Access denied"}
PMM UI:      404 page not found
```

### Resolution / Решение

Recovered using the Emergency Recovery runbook above. Migrated to named volumes.

### Lessons Learned / Выводы

1. Named volumes > bind mounts — isolated per project / Изолированы по проекту
2. PMM runs as UID 1000 — all `/srv` data must be `1000:1000`
3. QAN is secondary — Prometheus metrics are the priority
4. PMM UI depends on Grafana plugins — unsigned plugins must be allowed
5. WAL corruption is common after dirty shutdowns
6. `docker volume inspect` should always be step #1

---

## Logrotate Configuration

> [!NOTE]
> PMM logs are inside Docker at `/srv/logs/`. Use logrotate on host only if logs are mounted out.

`/etc/logrotate.d/pmm-server`

```conf
/opt/pmm/logs/*.log {
    daily
    rotate 14
    compress
    delaycompress
    missingok
    notifempty
    copytruncate
}
```

---

## Additional Notes

### Validation Checklist / Чеклист

- [ ] `curl -k https://localhost/pmm/server-status` → 200
- [ ] `curl -k https://localhost/grafana/api/health` → OK
- [ ] `curl -k -I https://localhost/pmm-ui/graph/` → 200
- [ ] `supervisorctl status` → all RUNNING
- [ ] Named volumes used (not bind mounts)
- [ ] Admin password changed from default
- [ ] Backup cron configured

### Production Tips / Рекомендации

- Use named Docker volumes for all PMM data
- Configure daily backups with retention
- Monitor disk space on PMM host
- Set up alerting for PMM failures
- Test disaster recovery periodically

---

## Official Documentation

- **Percona PMM Docs:** https://docs.percona.com/percona-monitoring-and-management/
- **PMM Docker Setup:** https://docs.percona.com/percona-monitoring-and-management/setting-up/server/docker.html
- **PMM Backup & Restore:** https://docs.percona.com/percona-monitoring-and-management/how-to/backup.html
- **PMM GitHub:** https://github.com/percona/pmm
- **Percona Forum:** https://forums.percona.com/
- **PostgreSQL pg_resetwal:** https://www.postgresql.org/docs/14/app-pgresetwal.html

---
