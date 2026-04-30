Title: 🔬 Cerbero Suite
Group: Security & Crypto
Icon: 🔬
Order: 10

# Cerbero Suite Sysadmin Cheatsheet

> **Context:** Cerbero Suite is a comprehensive multi-platform tool for file analysis, reverse engineering, malware triage, and digital forensics. It supports deep inspection of PE, ELF, Mach-O, PDF, Office docs, Java, DEX, and many other formats. Includes hex editor, disassembler (Carbon engine), decompilers, debuggers, YARA integration, and memory forensics. / Cerbero Suite — комплексный инструмент для анализа файлов, реверс-инжиниринга, сортировки вредоносного ПО и цифровой криминалистики. Поддерживает глубокую инспекцию PE, ELF, Mach-O, PDF, Office и других форматов.
> **Website:** [cerbero.io](https://cerbero.io/)
> **Role:** Security Engineer / Malware Analyst / Forensic Investigator / Sysadmin
> **Version:** Cerbero Suite 7.x
> **Platforms:** Windows, macOS, Linux

---

## 📚 Table of Contents / Содержание

1. [Installation & Configuration](#1-installation--configuration)
2. [Core Management](#2-core-management)
3. [File Analysis](#3-file-analysis)
4. [Malware Analysis & YARA](#4-malware-analysis--yara)
5. [Reverse Engineering](#5-reverse-engineering)
6. [Memory Forensics](#6-memory-forensics)
7. [Scripting & Automation](#7-scripting--automation)
8. [Troubleshooting & Tools](#8-troubleshooting--tools)
9. [Documentation Links](#9-documentation-links)

---

## 1. Installation & Configuration

### Install on Linux / Установка на Linux

```bash
# Download from official site / Скачать с официального сайта
wget https://cerbero.io/downloads/CerberoSuite-<VERSION>-linux-x86_64.tar.gz

# Extract / Распаковать
tar -xzf CerberoSuite-<VERSION>-linux-x86_64.tar.gz
cd CerberoSuite

# Run / Запустить
./CerberoSuite
```

### Install via Package (if provided) / Установка через пакет

```bash
# Debian/Ubuntu (.deb)
dpkg -i cerbero-suite_<VERSION>_amd64.deb
apt install -f  # Fix dependencies / Установить зависимости

# RHEL/Fedora (.rpm)
rpm -ivh cerbero-suite-<VERSION>.x86_64.rpm
```

### License Activation / Активация лицензии

```bash
# Activate license via GUI / Активация через GUI
# Help → License → Enter License Key → <LICENSE_KEY>

# Or via environment variable / Или через переменную окружения
export CERBERO_LICENSE_KEY=<LICENSE_KEY>
```

### Editions Comparison / Сравнение редакций

| Feature | Standard | Advanced |
|---------|----------|----------|
| File format analysis / Анализ файлов | ✅ | ✅ |
| Hex editor / Hex-редактор | ✅ | ✅ |
| Python SDK / Python SDK | ✅ | ✅ |
| YARA integration / Интеграция YARA | ✅ | ✅ |
| Carbon disassembler / Дизассемблер Carbon | ❌ | ✅ |
| Decompilers / Декомпиляторы | ❌ | ✅ |
| Debugger / Отладчик | ❌ | ✅ |
| Memory forensics / Криминалистика памяти | ❌ | ✅ |
| Emulators / Эмуляторы | ❌ | ✅ |

### Configuration Paths / Пути конфигурации

| Path | Description |
|------|-------------|
| `~/.config/CerberoSuite/` | User configuration (Linux) / Пользовательская конфигурация |
| `~/.local/share/CerberoSuite/` | User data and plugins / Данные и плагины |
| `~/.local/share/CerberoSuite/plugins/` | Custom plugins directory / Каталог кастомных плагинов |
| `~/.local/share/CerberoSuite/yara/` | YARA rules directory / Каталог правил YARA |

---

## 2. Core Management

### Supported File Formats / Поддерживаемые форматы файлов

| Category | Formats |
|----------|---------|
| Executables / Исполняемые | PE (32/64), ELF, Mach-O, DEX, Java Class |
| Documents / Документы | PDF, DOC, DOCX, XLS, XLSX, RTF, VBA macros |
| Archives / Архивы | ZIP, RAR, 7z, CAB, MSI, NSIS |
| Media / Медиа | SWF, images (JPEG, PNG, GIF, BMP) |
| Firmware / Прошивки | UPX packed, UEFI, firmware images |
| Memory / Память | Raw memory dumps, hibernation files, crash dumps |

### Basic Operations / Основные операции

```
# Open file for analysis / Открыть файл для анализа
File → Open → Select file

# Scan directory for embedded files / Сканировать каталог на встроенные файлы
File → Scan Directory → Select directory

# Batch analysis / Пакетный анализ
File → Batch Analysis → Configure and run

# Export analysis report / Экспорт отчёта
File → Export → Choose format (JSON, XML, Text)
```

### Hex Editor / Hex-редактор

```
# Open file in hex editor / Открыть файл в hex-редакторе
Right-click file → Open in Hex Editor

# Key features / Ключевые возможности:
# - Define structures (C-like syntax)
# - Bookmark regions
# - Pattern search (hex, text, regex)
# - Compare files
# - Edit live process memory (Advanced)
```

### Keyboard Shortcuts / Горячие клавиши

| Shortcut | Action / Действие |
|----------|-------------------|
| `Ctrl+O` | Open file / Открыть файл |
| `Ctrl+G` | Go to offset / Перейти к смещению |
| `Ctrl+F` | Find / Поиск |
| `Ctrl+H` | Find and replace (hex editor) / Найти и заменить |
| `Ctrl+B` | Toggle bookmark / Переключить закладку |
| `F5` | Run script / Запустить скрипт |
| `F9` | Toggle breakpoint (debugger) / Переключить точку останова |
| `F10` | Step over (debugger) / Шаг через |
| `F11` | Step into (debugger) / Шаг в |
| `Ctrl+Shift+Y` | Open YARA scanner / Открыть YARA-сканер |

---

## 3. File Analysis

### PE (Windows Executable) Analysis / Анализ PE

```
# Inspect PE headers / Инспекция PE-заголовков
# Automatic on opening .exe/.dll files:
# - DOS Header, PE Header, Optional Header
# - Sections table (text/data/rsrc/reloc)
# - Import/Export tables
# - Resources (icons, version info, manifests)
# - Digital signatures
# - Overlay data detection
```

### ELF (Linux Executable) Analysis / Анализ ELF

```
# Inspect ELF binaries / Инспекция ELF-бинарников
# - ELF Header (class, type, machine, entry point)
# - Program Headers (segments)
# - Section Headers
# - Symbol tables (.symtab, .dynsym)
# - Dynamic section (.dynamic)
# - Relocation entries
# - DWARF debug info (if present)
```

### Document Analysis / Анализ документов

```
# Inspect Office documents for macros / Инспекция Office-документов на макросы
# Open .doc/.xls/.docx/.xlsx:
# - Automatic VBA macro extraction
# - OLE stream inspection
# - Embedded object detection
# - Suspicious pattern highlighting

# PDF analysis / Анализ PDF
# Open .pdf:
# - Object tree inspection
# - JavaScript extraction
# - Embedded file detection
# - Action/trigger analysis
# - Stream decompression
```

> [!WARNING]
> When analyzing suspected malware, always work in an isolated environment (VM/sandbox). Cerbero's emulator provides a safe environment, but host-level precautions are still recommended. / При анализе подозрительных файлов всегда работайте в изолированной среде.

---

## 4. Malware Analysis & YARA

### YARA Rules Management / Управление правилами YARA

```
# Download YARA rules / Скачать правила YARA
# Tools → YARA → Download Rules

# Scan file with YARA / Сканировать файл правилами YARA
# Right-click file → Scan with YARA

# Create custom YARA rule / Создать кастомное правило YARA
# Tools → YARA → New Rule
```

### YARA Rule Example / Пример YARA-правила

```yara
rule Suspicious_PDF_JavaScript
{
    meta:
        description = "Detects PDF with embedded JavaScript"
        author = "<USER>"
        date = "2024-01-01"

    strings:
        $js1 = "/JavaScript" ascii
        $js2 = "/JS" ascii
        $launch = "/Launch" ascii
        $openaction = "/OpenAction" ascii

    condition:
        uint32(0) == 0x46445025 and  // %PDF
        ($js1 or $js2) and
        ($launch or $openaction)
}
```

### Malware Triage Workflow / Рабочий процесс сортировки вредоносного ПО

1. **Open suspicious file / Открыть подозрительный файл**
2. **Check file type detection / Проверить определение типа файла** — verify actual format vs extension / сравнить реальный формат с расширением
3. **Scan with YARA rules / Сканировать правилами YARA** — check against known signatures / проверить известные сигнатуры
4. **Inspect embedded content / Инспектировать встроенное содержимое** — auto-scan for nested files / автосканирование вложенных файлов
5. **Analyze strings / Анализ строк** — look for URLs, IPs, C2 indicators / поиск URL, IP, индикаторов C2
6. **Check imports/exports / Проверить импорт/экспорт** — suspicious API calls / подозрительные API-вызовы
7. **Disassemble if needed / Дизассемблировать при необходимости** — (Advanced edition)
8. **Export IOCs / Экспортировать индикаторы компрометации** — generate report / создать отчёт

---

## 5. Reverse Engineering

> [!NOTE]
> Reverse engineering features (Carbon disassembler, decompilers, debugger, emulators) require the **Advanced** edition. / Функции реверс-инжиниринга требуют редакции **Advanced**.

### Carbon Disassembler / Дизассемблер Carbon

```
# Disassemble executable / Дизассемблировать исполняемый файл
# Right-click PE/ELF/Mach-O → Disassemble

# Supported architectures / Поддерживаемые архитектуры:
# - x86 / x86-64
# - ARM / ARM64
# - MIPS
# - PowerPC

# Features / Возможности:
# - Interactive navigation
# - Cross-references (xrefs)
# - Function detection
# - Ghidra Sleigh decompiler integration
# - Comment and rename symbols
```

### Decompilers / Декомпиляторы

| Target | Description / Описание |
|--------|------------------------|
| .NET (MSIL) | Decompile to C# / Декомпиляция в C# |
| Java (bytecode) | Decompile to Java / Декомпиляция в Java |
| Android (DEX) | Decompile to Java/Smali / Декомпиляция в Java/Smali |
| Native (via Ghidra Sleigh) | Decompile to pseudo-C / Декомпиляция в псевдо-C |

### Debugger / Отладчик

```
# Attach to process / Присоединиться к процессу
# Debug → Attach → Select PID

# Debug executable / Отладить исполняемый файл
# Debug → Start → Select file

# Debug shellcode / Отладить шелл-код
# Debug → Shellcode → Paste or load shellcode

# Convert shellcode to executable / Конвертировать шелл-код в исполняемый файл
# Tools → Shellcode → Convert to EXE
```

---

## 6. Memory Forensics

> [!NOTE]
> Memory forensics features require the **Advanced** edition. Supports Windows memory images (XP through 11). / Криминалистика памяти — функция Advanced-редакции. Поддержка образов памяти Windows (от XP до 11).

### Supported Memory Image Types / Поддерживаемые типы образов памяти

| Type | Description / Описание |
|------|------------------------|
| Raw memory dump / Сырой дамп | Physical memory image / Образ физической памяти |
| Hibernation file / Файл гибернации | `hiberfil.sys` |
| Crash dump / Аварийный дамп | Full/kernel memory dump / Полный/ядрёной дамп |
| VMware `.vmem` | VMware memory snapshot / Снимок памяти VMware |

### Memory Analysis Workflow / Рабочий процесс анализа памяти

```
# Open memory image / Открыть образ памяти
File → Open → Select memory dump

# Analysis features / Возможности анализа:
# - Process list with PID/PPID tree
# - DLL list per process
# - Handle list (files, registry, mutexes)
# - Network connections
# - Registry hive extraction
# - File extraction from memory
# - Injected code detection
# - Rootkit detection
```

---

## 7. Scripting & Automation

### Python SDK / Python SDK

```python
# Example: analyze a PE file / Пример: анализ PE-файла
from Pro.Core import *

def analyze_pe(file_path):
    """Analyze a PE file and print sections. / Анализ PE-файла и вывод секций."""
    ctx = createContainerFromFile(file_path)
    if ctx.isNull():
        print(f"Cannot open: {file_path}")
        return

    obj = ctx.getObjectByFormat("PE")
    if obj.isNull():
        print("Not a PE file")
        return

    # Print sections / Вывести секции
    for i in range(obj.SectionCount()):
        sect = obj.Section(i)
        print(f"Section: {sect.Name()}  VA: 0x{sect.VirtualAddress():08X}  Size: {sect.SizeOfRawData()}")

# Run / Запуск
analyze_pe("/path/to/sample.exe")
```

### Batch Processing Script / Скрипт пакетной обработки

```python
# Example: scan directory for suspicious PDFs / Пример: сканирование каталога на подозрительные PDF
import os
from Pro.Core import *

def scan_pdfs(directory):
    """Scan directory for PDFs with JavaScript. / Сканирование каталога на PDF с JavaScript."""
    for root, dirs, files in os.walk(directory):
        for f in files:
            if f.lower().endswith('.pdf'):
                path = os.path.join(root, f)
                ctx = createContainerFromFile(path)
                if ctx.isNull():
                    continue

                obj = ctx.getObjectByFormat("PDF")
                if not obj.isNull():
                    # Check for JavaScript actions / Проверить наличие JavaScript
                    content = ctx.read(0, min(ctx.size(), 10000))
                    if b"/JavaScript" in content or b"/JS" in content:
                        print(f"[ALERT] JavaScript found in: {path}")

scan_pdfs("/path/to/scan/")
```

### Plugin Development / Разработка плагинов

```
# Plugin directory / Каталог плагинов
~/.local/share/CerberoSuite/plugins/

# Plugin structure / Структура плагина:
# my_plugin/
# ├── __init__.py       # Plugin entry point / Точка входа
# ├── plugin.json       # Metadata / Метаданные
# └── modules/          # Additional modules / Доп. модули
```

---

## 8. Troubleshooting & Tools

### Common Issues / Частые проблемы

#### 1. GUI Not Starting on Linux / GUI не запускается на Linux

```bash
# Check library dependencies / Проверить зависимости библиотек
ldd ./CerberoSuite | grep "not found"

# Install missing Qt/GUI libraries / Установить недостающие Qt/GUI библиотеки
# Debian/Ubuntu
apt install libqt5widgets5 libqt5gui5 libqt5core5a libgl1-mesa-glx

# RHEL/CentOS
dnf install qt5-qtbase qt5-qtbase-gui mesa-libGL
```

#### 2. Large File Performance / Производительность с большими файлами

```
# For large files (> 1GB) / Для больших файлов:
# - Use hex editor with lazy loading / Hex-редактор с ленивой загрузкой
# - Disable auto-scan for embedded files / Отключить автосканирование вложений
# Settings → Analysis → Disable "Auto-scan embedded files"
```

#### 3. YARA Rules Not Loading / Правила YARA не загружаются

```bash
# Check YARA rules directory / Проверить каталог правил YARA
ls -la ~/.local/share/CerberoSuite/yara/

# Validate YARA rule syntax / Проверить синтаксис правил YARA
yara -C /path/to/rule.yar    # Compile check / Проверка компиляции
```

### CLI Usage / Использование из командной строки

```bash
# Analyze file from CLI / Анализ файла из командной строки
CerberoSuite --analyze /path/to/file

# Scan with specific YARA rules / Сканирование конкретными YARA-правилами
CerberoSuite --yara-scan /path/to/rules.yar /path/to/file

# Batch scan directory / Пакетное сканирование каталога
CerberoSuite --batch /path/to/directory --output /path/to/report.json
```

> [!TIP]
> Cerbero Suite can handle millions of files in a single project. For large-scale investigations, use batch mode and filter by file type to focus analysis. / Cerbero Suite может обрабатывать миллионы файлов в одном проекте. Для масштабных расследований используйте пакетный режим.

---

## 9. Documentation Links

- [Cerbero Suite Official Website](https://cerbero.io/)
- [Cerbero Suite Documentation](https://docs.cerbero.io/)
- [Cerbero Suite Python SDK](https://docs.cerbero.io/sdk/)
- [YARA Official Documentation](https://yara.readthedocs.io/)
- [VirusTotal (YARA rules sharing)](https://www.virustotal.com/)

---
