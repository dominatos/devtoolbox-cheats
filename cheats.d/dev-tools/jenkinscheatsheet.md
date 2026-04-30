Title: 🛠️ Jenkins CI/CD
Group: Dev & Tools
Icon: 🛠️
Order: 7

# Jenkins Sysadmin Cheatsheet

> **Description:** Jenkins is an open-source automation server for building, testing, and deploying software. It supports 1800+ plugins for integration with virtually any tool in the CI/CD toolchain. Written in Java, it runs as a standalone servlet or in containers.
> Jenkins — это open-source сервер автоматизации для сборки, тестирования и деплоя ПО. Поддерживает 1800+ плагинов для интеграции с любым инструментом CI/CD.

> **Status:** Actively maintained. Alternatives: **GitHub Actions** (SaaS, GitHub-native), **GitLab CI/CD** (built-in), **Drone CI** (container-native), **Woodpecker CI** (Drone fork, FOSS), **Tekton** (Kubernetes-native).
> **Role:** DevOps / Build Engineer
> **URL:** `http://<HOST>:8080`

---

## 📚 Table of Contents / Содержание

1. [Service Management](#service-management--управление-сервисом)
2. [Jenkins CLI](#jenkins-cli--jenkins-cli)
3. [Groovy Script Console](#groovy-script-console--консоль-скриптов-groovy)
4. [Pipeline Syntax](#pipeline-syntax--синтаксис-pipeline-declarative)
5. [Security](#security--безопасность)
6. [Logrotate Configuration](#logrotate-configuration--конфигурация-logrotate)

---

## 1. Service Management / Управление сервисом

### Default Ports / Стандартные порты

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

### Logs / Логи
*   Linux (Systemd): `/var/log/jenkins/jenkins.log`
*   Windows: `%JENKINS_HOME%\jenkins.out`

---

## 2. Jenkins CLI / Jenkins CLI
Download CLI jar from: `http://<HOST>:8080/jnlpJars/jenkins-cli.jar`

```bash
# General Syntax / Общий синтаксис
java -jar jenkins-cli.jar -s http://<HOST>:8080/ -auth <USER>:<TOKEN> <COMMAND>
```

### Common Commands / Частые команды
```bash
# Restart Jenkins (Safe) / Перезагрузка (Безопасная)
java -jar jenkins-cli.jar -s ... safe-restart

# List Jobs / Список задач
java -jar jenkins-cli.jar -s ... list-jobs

# Build Job / Запуск сборки
java -jar jenkins-cli.jar -s ... build <JOB_NAME> -s -v

# Install Plugin / Установка плагина
java -jar jenkins-cli.jar -s ... install-plugin <PLUGIN_ID>
```

---

## 3. Groovy Script Console / Консоль скриптов Groovy
URL: `http://<HOST>:8080/script`

### Useful Scripts / Полезные скрипты

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

## 4. Pipeline Syntax / Синтаксис Pipeline (Declarative)

### Basic Structure / Базовая структура
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

### Agents (Docker) / Агенты (Docker)
```groovy
agent {
    docker {
        image 'maven:3.8.1-adoptopenjdk-11'
        args '-v /tmp:/tmp'
    }
}
```

---

## 5. Security / Безопасность

### User Database / База пользователей
Located in `$JENKINS_HOME/users/`. 

### Reset Admin Password / Сброс пароля админа
If locked out, edit `$JENKINS_HOME/config.xml` and change `<useSecurity>true</useSecurity>` to `false`. Restart Jenkins.
Если заблокированы, измените `true` на `false` в теге `<useSecurity>`. Перезапустите Jenkins.

---

## 6. Logrotate Configuration / Конфигурация Logrotate

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

## Official Documentation / Официальная документация

- **Jenkins:** https://www.jenkins.io/doc/
- **Jenkins Pipeline Syntax:** https://www.jenkins.io/doc/book/pipeline/syntax/
- **Jenkins Plugins Index:** https://plugins.jenkins.io/
- **Jenkins CLI:** https://www.jenkins.io/doc/book/managing/cli/
