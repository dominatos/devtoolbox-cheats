---
Title: 🛠️ Jenkins CI/CD
Group: "Dev & Tools"
Icon: 🛠️
Order: 7
tags:
  - dev-tools
  - devops
  - sysadmin
---

# Jenkins Sysadmin Cheatsheet

> **Description:** Jenkins is an open-source automation server for building, testing, and deploying software. It supports 1800+ plugins for integration with virtually any tool in the CI/CD toolchain. Written in Java, it runs as a standalone servlet or in containers.
> Jenkins — это open-source сервер автоматизации для сборки, тестирования и деплоя ПО. Поддерживает 1800+ плагинов для интеграции с любым инструментом CI/CD.

> **Status:** Actively maintained. Alternatives: **GitHub Actions** (SaaS, GitHub-native), **GitLab CI/CD** (built-in), **Drone CI** (container-native), **Woodpecker CI** (Drone fork, FOSS), **Tekton** (Kubernetes-native).
> **Role:** DevOps / Build Engineer
> **URL:** `http://<HOST>:8080`

---

## 📚 Table of Contents

- [1. Service Management](#1.%20Service%20Management)
- [2. Jenkins CLI](#2.%20Jenkins%20CLI)
- [3. Groovy Script Console](#3.%20Groovy%20Script%20Console)
- [4. Pipeline Syntax](#4.%20Pipeline%20Syntax)
- [5. Security](#5.%20Security)
- [6. Logrotate Configuration](#6.%20Logrotate%20Configuration)
- [Official Documentation](#Official%20Documentation)

---

## 1. Service Management

### Default Ports

| Port | Description (EN / RU) |
|------|----------------------|
| 8080 | Web UI / Веб-интерфейс |
| 50000 | Agent (JNLP) connection / Подключение агентов |

### Systemd / Systemd

`/etc/systemd/system/jenkins.service`

```bash
systemctl start jenkins   # Start / Запуск
systemctl stop jenkins    # Stop / Остановка
systemctl restart jenkins # Restart / Перезапуск
systemctl status jenkins  # Status / Статус
```

### Logs
*   Linux (Systemd): `/var/log/jenkins/jenkins.log`
*   Windows: `%JENKINS_HOME%\jenkins.out`

---

## 2. Jenkins CLI
Download CLI jar from: `http://<HOST>:8080/jnlpJars/jenkins-cli.jar`

```bash
# General Syntax
java -jar jenkins-cli.jar -s http://<HOST>:8080/ -auth <USER>:<TOKEN> <COMMAND>
```

### Common Commands
```bash
# Restart Jenkins (Safe)
java -jar jenkins-cli.jar -s ... safe-restart

# List Jobs
java -jar jenkins-cli.jar -s ... list-jobs

# Build Job
java -jar jenkins-cli.jar -s ... build <JOB_NAME> -s -v

# Install Plugin
java -jar jenkins-cli.jar -s ... install-plugin <PLUGIN_ID>
```

---

## 3. Groovy Script Console
URL: `http://<HOST>:8080/script`

### Useful Scripts

**Print System Info:**
```groovy
println("Jenkins Version: " + jenkins.model.Jenkins.instance.version)
println("Home: " + System.getenv("JENKINS_HOME"))
```

**Disable Security (Emergency Only!):**
```groovy
def instance = jenkins.model.Jenkins.getInstance()
instance.setSecurityRealm(hudson.security.SecurityRealm.NO_AUTHENTICATION)
instance.setAuthorizationStrategy(hudson.security.AuthorizationStrategy.UNSECURED)
instance.save()
```

> [!CAUTION]
> This completely disables authentication. Use only as a last resort when locked out. Re-enable security immediately after access is restored.
> Это полностью отключает аутентификацию. Используйте только как крайнюю меру.

---

## 4. Pipeline Syntax

### Basic Structure
```groovy
pipeline {
    agent any
    stages {
        stage('Build') {
            steps {
                echo 'Building...'
                sh 'make'
            }
        }
        stage('Test') {
            steps {
                echo 'Testing...'
                sh 'make check'
            }
        }
        stage('Deploy') {
            steps {
                echo 'Deploying...'
            }
        }
    }
    post {
        always {
            echo 'Cleanup...'
        }
    }
}
```

### Agents (Docker)
```groovy
agent {
    docker {
        image 'maven:3.8.1-adoptopenjdk-11'
        args '-v /tmp:/tmp'
    }
}
```

---

## 5. Security

### User Database
Located in `$JENKINS_HOME/users/`.

### Reset Admin Password
If locked out, edit `$JENKINS_HOME/config.xml` and change `<useSecurity>true</useSecurity>` to `false`. Restart Jenkins.
Если заблокированы, измените `true` на `false` в теге `<useSecurity>`. Перезапустите Jenkins.

---

## 6. Logrotate Configuration

`/etc/logrotate.d/jenkins`

```conf
/var/log/jenkins/*.log {
    daily
    rotate 14
    compress
    delaycompress
    missingok
    notifempty
    create 640 jenkins jenkins
    copytruncate
}
```

> [!TIP]
> Use `copytruncate` as Jenkins keeps the log file handle open.
> Используйте `copytruncate`, так как Jenkins держит файл лога открытым.

---

## Official Documentation

- **Jenkins:** https://www.jenkins.io/doc/
- **Jenkins Pipeline Syntax:** https://www.jenkins.io/doc/book/pipeline/syntax/
- **Jenkins Plugins Index:** https://plugins.jenkins.io/
- **Jenkins CLI:** https://www.jenkins.io/doc/book/managing/cli/
