Title: 🛠️ Terraform
Group: Dev & Tools
Icon: 🛠️
Order: 6

# Terraform Cheatsheet

> **Context:** Terraform is an open-source infrastructure as code software tool. / Terraform - это open-source инструмент "инфраструктура как код".
> **Role:** DevOps / Cloud Engineer
> **Version:** 1.x+

---

## 📚 Table of Contents / Содержание

1. [Workflow](#workflow--рабочий-процесс)
2. [State Management](#state-management--управление-состоянием-state)
3. [Workspaces](#workspaces--рабочие-окружения)
4. [Debugging](#debugging--отладка)

---

## 1. Workflow / Рабочий процесс

### Init & Validate / Инициализация и Проверка
```bash
# Initialize directory (Download providers) / Инициализация (Скачать провайдеры)
terraform init

# Upgrade providers / Обновить провайдеры
terraform init -upgrade

# Format code / Форматирование кода
terraform fmt -recursive

# Validate syntax / Проверка синтаксиса
terraform validate
```

### Plan & Apply / План и Применение
```bash
# Plan (Preview changes) / План (Предпросмотр)
terraform plan -out=tfplan

# Apply changes / Применить изменения
terraform apply "tfplan"

# Auto approve / Автоподтверждение
terraform apply -auto-approve
```

> [!WARNING]
> `terraform apply -auto-approve` skips the confirmation prompt. Use only in CI/CD pipelines or non-critical environments.
> `terraform apply -auto-approve` пропускает подтверждение. Используйте только в CI/CD или некритичных окружениях.

```bash
# Destroy infrastructure / Удалить инфраструктуру
terraform destroy
```

> [!CAUTION]
> `terraform destroy` permanently removes all managed resources. Always run `terraform plan -destroy` first to preview what will be deleted.
> `terraform destroy` безвозвратно удаляет все ресурсы. Всегда сначала выполняйте `terraform plan -destroy`.

---

## 2. State Management / Управление состоянием (State)

### List & Show / Список и Просмотр
```bash
# List resources in state / Список ресурсов в стейте
terraform state list

# Show details of resource / Детали ресурса
terraform state show <RESOURCE_ADDRESS>
```

### Manipulation / Манипуляция
```bash
# Remove from state (Does not destroy real resource) / Удалить из стейта (Не удаляет реальный ресурс)
terraform state rm <RESOURCE_ADDRESS>

# Move/Rename resource / Переместить/Переименовать ресурс
terraform state mv <OLD_ADDR> <NEW_ADDR>

# Import existing resource / Импорт существующего ресурса
terraform import <RESOURCE_ADDRESS> <ID>
```

---

## 3. Workspaces / Рабочие окружения

```bash
# List workspaces / Список окружений
terraform workspace list

# Create new workspace / Создать новое окружение
terraform workspace new dev

# Select workspace / Выбрать окружение
terraform workspace select prod
```

---

## 4. Debugging / Отладка

### Logs / Логи
Set env var `TF_LOG`. Levels: `TRACE`, `DEBUG`, `INFO`, `WARN`, `ERROR`.

```bash
export TF_LOG=DEBUG
export TF_LOG_PATH=/tmp/terraform.log
terraform apply
```

### Console / Консоль
Interactive console to test expressions. / Интерактивная консоль для теста выражений.

```bash
terraform console
> local.my_variable
```

---

## Best Practices

- Always run `terraform plan` before `apply` / Всегда выполняйте `terraform plan` перед `apply`
- Use remote state backend (S3, GCS) for team collaboration / Используйте удалённый state backend для командной работы
- Lock state files to prevent conflicts / Блокируйте state файлы для предотвращения конфликтов
- Use workspaces for multi-environment setups (dev/staging/prod) / Используйте workspaces для многосредных настроек
- Pin provider versions in `required_providers` / Фиксируйте версии провайдеров
- Use `terraform fmt` to keep code consistent / Используйте `terraform fmt` для единообразия кода
