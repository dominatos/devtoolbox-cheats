Title: 🛠️ Terraform
Group: Dev & Tools
Icon: 🛠️
Order: 6

# Terraform Cheatsheet

> **Description:** Terraform is an open-source Infrastructure as Code (IaC) tool by HashiCorp. It allows you to define, provision, and manage cloud infrastructure using a declarative configuration language (HCL). Terraform supports 3000+ providers (AWS, Azure, GCP, Kubernetes, etc.) and manages the full lifecycle of infrastructure resources.
> Terraform — это open-source инструмент «Инфраструктура как код» (IaC) от HashiCorp. Позволяет определять, провижинить и управлять облачной инфраструктурой с помощью декларативного языка конфигурации (HCL).

> **Status:** Actively maintained. **OpenTofu** is an open-source fork (post-BSL license change) and a drop-in replacement. Other IaC alternatives: **Pulumi** (multi-language), **AWS CloudFormation** (AWS-only), **Ansible** (procedural).
> **Role:** DevOps / Cloud Engineer / SRE
> **Version:** 1.x+

---

## 📚 Table of Contents / Содержание

1. [Workflow](#workflow--рабочий-процесс)
2. [State Management](#state-management--управление-состоянием-state)
3. [Workspaces](#workspaces--рабочие-окружения)
4. [Modules](#modules--модули)
5. [Variables & Outputs](#variables--outputs--переменные-и-выводы)
6. [Debugging](#debugging--отладка)
7. [Best Practices](#best-practices--лучшие-практики)

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

# Preview what will be destroyed / Предпросмотр удаления
terraform plan -destroy
```

> [!CAUTION]
> `terraform destroy` permanently removes all managed resources. Always run `terraform plan -destroy` first to preview what will be deleted.
> `terraform destroy` безвозвратно удаляет все ресурсы. Всегда сначала выполняйте `terraform plan -destroy`.

### Targeted Operations / Целевые операции
```bash
# Apply only specific resource / Применить только конкретный ресурс
terraform apply -target=aws_instance.web

# Destroy only specific resource / Удалить только конкретный ресурс
terraform destroy -target=aws_instance.web

# Refresh state from real infrastructure / Обновить стейт из реальной инфраструктуры
terraform refresh
```

---

## 2. State Management / Управление состоянием (State)

### List & Show / Список и Просмотр
```bash
# List resources in state / Список ресурсов в стейте
terraform state list

# Show details of resource / Детали ресурса
terraform state show <RESOURCE_ADDRESS>

# Pull remote state to local file / Загрузить удалённый стейт в локальный файл
terraform state pull > terraform.tfstate.backup
```

### Manipulation / Манипуляция
```bash
# Remove from state (Does not destroy real resource) / Удалить из стейта (Не удаляет реальный ресурс)
terraform state rm <RESOURCE_ADDRESS>

# Move/Rename resource / Переместить/Переименовать ресурс
terraform state mv <OLD_ADDR> <NEW_ADDR>

# Import existing resource / Импорт существующего ресурса
terraform import <RESOURCE_ADDRESS> <ID>

# Replace a tainted resource / Заменить повреждённый ресурс
terraform apply -replace=<RESOURCE_ADDRESS>
```

> [!WARNING]
> `terraform state rm` removes the resource from Terraform's tracking but does NOT destroy the actual cloud resource. Use `terraform destroy -target` to destroy.
> `terraform state rm` удаляет ресурс из отслеживания Terraform, но НЕ уничтожает реальный облачный ресурс.

### Remote State Backend / Удалённый бэкенд стейта

`backend.tf`

```hcl
terraform {
  backend "s3" {
    bucket         = "<BUCKET_NAME>"
    key            = "terraform/state.tfstate"
    region         = "<REGION>"
    dynamodb_table = "<LOCK_TABLE>"
    encrypt        = true
  }
}
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

# Show current workspace / Показать текущее окружение
terraform workspace show

# Delete workspace / Удалить окружение
terraform workspace delete staging
```

> [!TIP]
> Use `terraform.workspace` in HCL to branch logic by environment (e.g., instance sizes, replica counts).
> Используйте `terraform.workspace` в HCL для ветвления логики по окружению.

---

## 4. Modules / Модули

```bash
# Download modules / Скачать модули
terraform get

# Update modules / Обновить модули
terraform get -update
```

### Module Usage Example / Пример использования модуля
```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "my-vpc"
  cidr = "10.0.0.0/16"
}
```

---

## 5. Variables & Outputs / Переменные и выводы

### Passing Variables / Передача переменных
```bash
# Via command line / Через командную строку
terraform apply -var="instance_type=t3.micro"

# Via variable file / Через файл переменных
terraform apply -var-file="prod.tfvars"

# Via environment variable / Через переменную окружения
export TF_VAR_instance_type="t3.micro"
terraform apply
```

### Show Outputs / Показать выводы
```bash
# List all outputs / Список всех выводов
terraform output

# Show specific output / Показать конкретный вывод
terraform output instance_ip

# Output in JSON / Вывод в JSON
terraform output -json
```

---

## 6. Debugging / Отладка

### Logs / Логи
Set env var `TF_LOG`. Levels: `TRACE`, `DEBUG`, `INFO`, `WARN`, `ERROR`.
Установите переменную окружения `TF_LOG`. Уровни: `TRACE`, `DEBUG`, `INFO`, `WARN`, `ERROR`.

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
> length(var.subnets)
```

### Generate Graph / Генерация графа
```bash
# Generate dependency graph / Генерация графа зависимостей
terraform graph | dot -Tpng -o graph.png
```

---

## Best Practices / Лучшие практики

- Always run `terraform plan` before `apply` / Всегда выполняйте `terraform plan` перед `apply`
- Use remote state backend (S3, GCS) for team collaboration / Используйте удалённый state backend для командной работы
- Lock state files to prevent conflicts / Блокируйте state файлы для предотвращения конфликтов
- Use workspaces for multi-environment setups (dev/staging/prod) / Используйте workspaces для многосредных настроек
- Pin provider versions in `required_providers` / Фиксируйте версии провайдеров
- Use `terraform fmt` to keep code consistent / Используйте `terraform fmt` для единообразия кода
- Store `.tfstate` files securely (never commit to Git) / Храните `.tfstate` файлы безопасно (никогда не коммитьте в Git)
- Use modules for reusable infrastructure / Используйте модули для переиспользуемой инфраструктуры

### IaC Tools Comparison / Сравнение IaC инструментов

| Tool | Language | Type | Description (EN / RU) | Best For |
|------|----------|------|----------------------|----------|
| **Terraform** | HCL | Declarative | Multi-cloud IaC / Мультиоблачный IaC | Multi-cloud, provider ecosystem |
| **OpenTofu** | HCL | Declarative | Open-source Terraform fork / Open-source форк Terraform | Terraform replacement (open-source) |
| **Pulumi** | Python/TS/Go/C# | Declarative | Multi-language IaC / Мультиязычный IaC | Teams preferring real languages |
| **CloudFormation** | JSON/YAML | Declarative | AWS-native IaC / AWS-нативный IaC | AWS-only environments |
| **Ansible** | YAML | Procedural | Configuration management / Управление конфигурацией | Server config, hybrid IaC |

---

## Official Documentation / Официальная документация

- **Terraform:** https://developer.hashicorp.com/terraform/docs
- **Terraform Registry (Providers):** https://registry.terraform.io/
- **HCL Language:** https://developer.hashicorp.com/terraform/language
- **OpenTofu (fork):** https://opentofu.org/docs/
- **Pulumi (alternative):** https://www.pulumi.com/docs/
