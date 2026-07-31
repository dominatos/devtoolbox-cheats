---
Title: 🛠️ Terraform
Group: "Dev & Tools"
Icon: 🛠️
Order: 6
tags:
  - dev-tools
  - devops
  - sysadmin
---

# Terraform Cheatsheet

> **Description:** Terraform is an open-source Infrastructure as Code (IaC) tool by HashiCorp. It allows you to define, provision, and manage cloud infrastructure using a declarative configuration language (HCL). Terraform supports 3000+ providers (AWS, Azure, GCP, Kubernetes, etc.) and manages the full lifecycle of infrastructure resources.
> Terraform — это open-source инструмент «Инфраструктура как код» (IaC) от HashiCorp. Позволяет определять, провижинить и управлять облачной инфраструктурой с помощью декларативного языка конфигурации (HCL).

> **Status:** Actively maintained. **OpenTofu** is an open-source fork (post-BSL license change) and a drop-in replacement. Other IaC alternatives: **Pulumi** (multi-language), **AWS CloudFormation** (AWS-only), **Ansible** (procedural).
> **Role:** DevOps / Cloud Engineer / SRE
> **Version:** 1.x+

---

## 📚 Table of Contents

- [1. Workflow](#1.%20Workflow)
- [2. State Management](#2.%20State%20Management)
- [3. Workspaces](#3.%20Workspaces)
- [4. Modules](#4.%20Modules)
- [5. Variables & Outputs](#5.%20Variables%20&%20Outputs)
- [6. Debugging](#6.%20Debugging)
- [Best Practices](#Best%20Practices)
- [Official Documentation](#Official%20Documentation)

---

## 1. Workflow

### Init & Validate
```bash
# Initialize directory (Download providers)
terraform init

# Upgrade providers
terraform init -upgrade

# Format code
terraform fmt -recursive

# Validate syntax
terraform validate
```

### Plan & Apply
```bash
# Plan (Preview changes)
terraform plan -out=tfplan

# Apply changes
terraform apply "tfplan"

# Auto approve
terraform apply -auto-approve
```

> [!WARNING]
> `terraform apply -auto-approve` skips the confirmation prompt. Use only in CI/CD pipelines or non-critical environments.
> `terraform apply -auto-approve` пропускает подтверждение. Используйте только в CI/CD или некритичных окружениях.

```bash
# Destroy infrastructure
terraform destroy

# Preview what will be destroyed
terraform plan -destroy
```

> [!CAUTION]
> `terraform destroy` permanently removes all managed resources. Always run `terraform plan -destroy` first to preview what will be deleted.
> `terraform destroy` безвозвратно удаляет все ресурсы. Всегда сначала выполняйте `terraform plan -destroy`.

### Targeted Operations
```bash
# Apply only specific resource
terraform apply -target=aws_instance.web

# Destroy only specific resource
terraform destroy -target=aws_instance.web

# Refresh state from real infrastructure
terraform refresh
```

---

## 2. State Management

### List & Show
```bash
# List resources in state
terraform state list

# Show details of resource
terraform state show <RESOURCE_ADDRESS>

# Pull remote state to local file
terraform state pull > terraform.tfstate.backup
```

### Manipulation
```bash
# Remove from state (Does not destroy real resource)
terraform state rm <RESOURCE_ADDRESS>

# Move/Rename resource
terraform state mv <OLD_ADDR> <NEW_ADDR>

# Import existing resource
terraform import <RESOURCE_ADDRESS> <ID>

# Replace a tainted resource
terraform apply -replace=<RESOURCE_ADDRESS>
```

> [!WARNING]
> `terraform state rm` removes the resource from Terraform's tracking but does NOT destroy the actual cloud resource. Use `terraform destroy -target` to destroy.
> `terraform state rm` удаляет ресурс из отслеживания Terraform, но НЕ уничтожает реальный облачный ресурс.

### Remote State Backend

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

## 3. Workspaces

```bash
# List workspaces
terraform workspace list

# Create new workspace
terraform workspace new dev

# Select workspace
terraform workspace select prod

# Show current workspace
terraform workspace show

# Delete workspace
terraform workspace delete staging
```

> [!TIP]
> Use `terraform.workspace` in HCL to branch logic by environment (e.g., instance sizes, replica counts).
> Используйте `terraform.workspace` в HCL для ветвления логики по окружению.

---

## 4. Modules

```bash
# Download modules
terraform get

# Update modules
terraform get -update
```

### Module Usage Example
```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "my-vpc"
  cidr = "10.0.0.0/16"
}
```

---

## 5. Variables & Outputs

### Passing Variables
```bash
# Via command line
terraform apply -var="instance_type=t3.micro"

# Via variable file
terraform apply -var-file="prod.tfvars"

# Via environment variable
export TF_VAR_instance_type="t3.micro"
terraform apply
```

### Show Outputs
```bash
# List all outputs
terraform output

# Show specific output
terraform output instance_ip

# Output in JSON
terraform output -json
```

---

## 6. Debugging

### Logs
Set env var `TF_LOG`. Levels: `TRACE`, `DEBUG`, `INFO`, `WARN`, `ERROR`.
Установите переменную окружения `TF_LOG`. Уровни: `TRACE`, `DEBUG`, `INFO`, `WARN`, `ERROR`.

```bash
export TF_LOG=DEBUG
export TF_LOG_PATH=/tmp/terraform.log
terraform apply
```

### Console
Interactive console to test expressions. / Интерактивная консоль для теста выражений.

```bash
terraform console
> local.my_variable
> length(var.subnets)
```

### Generate Graph
```bash
# Generate dependency graph
terraform graph | dot -Tpng -o graph.png
```

---

## Best Practices

- Always run `terraform plan` before `apply` / Всегда выполняйте `terraform plan` перед `apply`
- Use remote state backend (S3, GCS) for team collaboration / Используйте удалённый state backend для командной работы
- Lock state files to prevent conflicts / Блокируйте state файлы для предотвращения конфликтов
- Use workspaces for multi-environment setups (dev/staging/prod) / Используйте workspaces для многосредных настроек
- Pin provider versions in `required_providers` / Фиксируйте версии провайдеров
- Use `terraform fmt` to keep code consistent / Используйте `terraform fmt` для единообразия кода
- Store `.tfstate` files securely (never commit to Git) / Храните `.tfstate` файлы безопасно (никогда не коммитьте в Git)
- Use modules for reusable infrastructure / Используйте модули для переиспользуемой инфраструктуры

### IaC Tools Comparison

| Tool | Language | Type | Description (EN / RU) | Best For |
|------|----------|------|----------------------|----------|
| **Terraform** | HCL | Declarative | Multi-cloud IaC / Мультиоблачный IaC | Multi-cloud, provider ecosystem |
| **OpenTofu** | HCL | Declarative | Open-source Terraform fork / Open-source форк Terraform | Terraform replacement (open-source) |
| **Pulumi** | Python/TS/Go/C# | Declarative | Multi-language IaC / Мультиязычный IaC | Teams preferring real languages |
| **CloudFormation** | JSON/YAML | Declarative | AWS-native IaC / AWS-нативный IaC | AWS-only environments |
| **Ansible** | YAML | Procedural | Configuration management / Управление конфигурацией | Server config, hybrid IaC |

---

## Official Documentation

- **Terraform:** https://developer.hashicorp.com/terraform/docs
- **Terraform Registry (Providers):** https://registry.terraform.io/
- **HCL Language:** https://developer.hashicorp.com/terraform/language
- **OpenTofu (fork):** https://opentofu.org/docs/
- **Pulumi (alternative):** https://www.pulumi.com/docs/
