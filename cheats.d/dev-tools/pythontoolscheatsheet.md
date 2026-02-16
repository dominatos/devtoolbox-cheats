Title: 🐍 Python — venv/pip/pipx/poetry
Group: Dev & Tools
Icon: 🐍
Order: 3

## Table of Contents
- [venv — Virtual Environments](#-venv--virtual-environments)
- [pip — Package Manager](#-pip--package-manager)
- [pipx — CLI Tool Installer](#-pipx--cli-tool-installer)
- [poetry — Dependency Management](#-poetry--dependency-management)
- [pyenv — Python Version Manager](#-pyenv--python-version-manager)
- [Troubleshooting](#-troubleshooting--устранение-неполадок)

---

# 🌍 venv — Virtual Environments

### Create & Activate / Создание и активация
python3 -m venv .venv                         # Create venv / Создать venv
source .venv/bin/activate                     # Activate (Linux/Mac) / Активировать (Linux/Mac)
.venv\Scripts\activate                        # Activate (Windows) / Активировать (Windows)
deactivate                                    # Deactivate venv / Деактивировать venv

### With System Packages / С системными пакетами
python3 -m venv --system-site-packages .venv  # Include system packages / Включить системные пакеты
python3 -m venv --clear .venv                 # Recreate venv / Пересоздать venv

---

# 📦 pip — Package Manager

### Install Packages / Установка пакетов
pip install requests                          # Install package / Установить пакет
pip install requests==2.28.0                  # Install specific version / Установить конкретную версию
pip install requests>=2.28.0                  # Install minimum version / Установить минимальную версию
pip install -e .                              # Install in editable mode / Установить в редактируемом режиме

### Requirements Files / Файлы требований
pip install -r requirements.txt               # Install from file / Установить из файла
pip freeze > requirements.txt                 # Generate requirements / Сгенерировать requirements
pip install -r requirements-dev.txt           # Install dev dependencies / Установить dev зависимости

### Update & Upgrade / Обновление
pip install -U pip                            # Upgrade pip / Обновить pip
pip install -U pip setuptools wheel           # Update base tools / Обновить базовые инструменты
pip install -U requests                       # Upgrade package / Обновить пакет
pip list --outdated                           # Show outdated packages / Показать устаревшие пакеты

### Remove & Clean / Удаление и очистка
pip uninstall requests                        # Uninstall package / Удалить пакет
pip uninstall -r requirements.txt -y          # Uninstall from file / Удалить из файла
pip cache purge                               # Clear cache / Очистить кэш

### List & Show / Список и информация
pip list                                      # List installed packages / Список установленных пакетов
pip show requests                             # Show package info / Показать информацию о пакете
pip check                                     # Verify dependencies / Проверить зависимости

---

# 🎯 pipx — CLI Tool Installer

### Install Tools / Установка инструментов
pipx install black                            # Install CLI tool / Установить CLI инструмент
pipx install flake8                           # Install linter / Установить линтер
pipx install poetry                           # Install poetry / Установить poetry
pipx install ansible                          # Install ansible / Установить ansible

### Manage Tools / Управление инструментами
pipx list                                     # List installed tools / Список установленных инструментов
pipx upgrade black                            # Upgrade tool / Обновить инструмент
pipx upgrade-all                              # Upgrade all tools / Обновить все инструменты
pipx uninstall black                          # Uninstall tool / Удалить инструмент

### Run Temporarily / Запустить временно
pipx run black script.py                      # Run without installing / Запустить без установки
pipx run --spec black==22.0.0 black           # Run specific version / Запустить конкретную версию

---

# 📚 poetry — Dependency Management

### Initialize Project / Инициализировать проект
poetry new myproject                          # Create new project / Создать новый проект
poetry init                                   # Initialize in existing dir / Инициализировать в существующей директории

### Install Dependencies / Установка зависимостей
poetry install                                # Install dependencies / Установить зависимости
poetry add requests                           # Add package / Добавить пакет
poetry add -D pytest                          # Add dev dependency / Добавить dev зависимость
poetry add requests@^2.28.0                   # Add with version constraint / Добавить с ограничением версии

### Update & Remove / Обновление и удаление
poetry update                                 # Update dependencies / Обновить зависимости
poetry update requests                        # Update specific package / Обновить конкретный пакет
poetry remove requests                        # Remove package / Удалить пакет

### Virtual Environment / Виртуальная среда
poetry shell                                  # Activate venv / Активировать venv
poetry run python script.py                   # Run in venv / Запустить в venv
poetry run pytest                             # Run tests / Запустить тесты
poetry env info                               # Show venv info / Показать информацию о venv

### Build & Publish / Сборка и публикация
poetry build                                  # Build package / Собрать пакет
poetry publish                                # Publish to PyPI / Опубликовать в PyPI
poetry publish --build                        # Build and publish / Собрать и опубликовать

---

# 🔧 pyenv — Python Version Manager

### Install Python Versions / Установка версий Python
pyenv install 3.11.0                          # Install specific version / Установить конкретную версию
pyenv install 3.11:latest                     # Install latest 3.11 / Установить последнюю 3.11
pyenv install --list                          # List available versions / Список доступных версий

### Use Python Versions / Использование версий Python
pyenv global 3.11.0                           # Set global version / Установить глобальную версию
pyenv local 3.10.0                            # Set local version / Установить локальную версию
pyenv shell 3.11.0                            # Set shell version / Установить версию для shell

### List & Manage / Список и управление
pyenv versions                                # List installed versions / Список установленных версий
pyenv version                                 # Show current version / Показать текущую версию
pyenv uninstall 3.9.0                         # Uninstall version / Удалить версию

---

# 🐛 Troubleshooting / Устранение неполадок

### Reinstall Packages / Переустановить пакеты
```bash
# Clean install / Чистая установка
rm -rf .venv
python3 -m venv .venv
source .venv/bin/activate
pip install -U pip setuptools wheel
pip install -r requirements.txt
```

### Fix SSL Issues / Исправить SSL проблемы
```bash
pip install --trusted-host pypi.org --trusted-host files.pythonhosted.org <PACKAGE>
```

### Fix Permission Issues / Исправить проблемы с правами
```bash
pip install --user <PACKAGE>                  # Install for user / Установить для пользователя
```

### Resolve Conflicts / Разрешить конфликты
```bash
pip install pip-tools                         # Install pip-tools / Установить pip-tools
pip-compile requirements.in                   # Compile dependencies / Скомпилировать зависимости
pip-sync requirements.txt                     # Sync environment / Синхронизировать окружение
```

---

# 🌟 Real-World Examples / Примеры из практики

### New Python Project / Новый Python проект
```bash
# Create project / Создать проект
mkdir myproject && cd myproject
python3 -m venv .venv
source .venv/bin/activate

# Install tools / Установить инструменты
pip install -U pip setuptools wheel
pip install black flake8 pytest

# Create requirements / Создать requirements
pip freeze > requirements.txt
```

### Poetry Project / Проект с Poetry
```bash
# Initialize / Инициализировать
poetry new myproject
cd myproject

# Add dependencies / Добавить зависимости
poetry add fastapi uvicorn
poetry add -D pytest black

# Run / Запустить
poetry run python main.py
```

### Jupyter Notebook / Jupyter Notebook
```bash
# Install Jupyter / Установить Jupyter
pip install jupyter notebook

# Create kernel / Создать kernel
python -m ipykernel install --user --name=myproject

# Start notebook / Запустить notebook
jupyter notebook
```

### Flask Development / Разработка Flask
```bash
python3 -m venv .venv
source .venv/bin/activate
pip install flask python-dotenv
pip install -D pytest pytest-flask

# Run dev server / Запустить dev сервер
export FLASK_APP=app.py
export FLASK_ENV=development
flask run
```

### Django Setup / Настройка Django
```bash
python3 -m venv .venv
source .venv/bin/activate
pip install django psycopg2-binary python-dotenv

# Create project / Создать проект
django-admin startproject myproject .
python manage.py migrate
python manage.py runserver
```

### Data Science Environment / Окружение для Data Science
```bash
python3 -m venv .venv
source .venv/bin/activate
pip install numpy pandas matplotlib jupyter scikit-learn

# Save requirements / Сохранить requirements
pip freeze > requirements.txt
```

### CLI Tool Development / Разработка CLI инструментов
```bash
# Install in editable mode / Установить в редактируемом режиме
pip install -e .

# Run CLI / Запустить CLI
mycli --help
```

### Docker Python Image / Docker образ Python
```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
CMD ["python", "app.py"]
```

# 💡 Best Practices / Лучшие практики
# Always use virtual environments / Всегда используйте виртуальные окружения
# Pin dependencies in requirements.txt / Фиксируйте зависимости в requirements.txt
# Separate dev dependencies / Разделяйте dev зависимости
# Use pipx for CLI tools / Используйте pipx для CLI инструментов
# Update pip before installing packages / Обновляйте pip перед установкой пакетов
# Use poetry for modern dependency management / Используйте poetry для современного управления зависимостями

# 🔧 Virtual Environment Tools / Инструменты виртуального окружения
# venv: Built-in (Python 3.3+) / Встроенный (Python 3.3+)
# virtualenv: Third-party (more features) / Сторонний (больше функций)
# conda: For data science / Для data science
# poetry: All-in-one solution / Всё в одном решении

# 📋 Requirements Files / Файлы требований
# requirements.txt — Production dependencies / Продакшн зависимости
# requirements-dev.txt — Development dependencies / Dev зависимости
# requirements-test.txt — Test dependencies / Тестовые зависимости
# pyproject.toml — Poetry/Modern format / Poetry/Современный формат

# ⚠️ Common Issues / Распространённые проблемы
# pip: error: externally-managed-environment / pip: error: externally-managed-environment
# Solution: Use venv or --break-system-packages / Решение: Используйте venv или --break-system-packages

# 🔍 Package Indexes / Индексы пакетов
# PyPI: https://pypi.org / Официальный индекс
# TestPyPI: https://test.pypi.org / Тестовый индекс
# Private: Configure in pip.conf / Приватный: Настройте в pip.conf
