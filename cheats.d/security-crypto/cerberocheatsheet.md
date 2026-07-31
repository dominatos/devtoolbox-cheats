---
Title: 🔬 Cerbero Suite
Group: "Security & Crypto"
Icon: 🔬
Order: 10
tags:
  - security
  - crypto
  - sysadmin
  - linux
---

# Cerbero Suite Sysadmin Cheatsheet

> **Context:** Cerbero Suite is a comprehensive multi-platform tool for file analysis, reverse engineering, malware triage, and digital forensics. It supports deep inspection of PE, ELF, Mach-O, PDF, Office docs, Java, DEX, and many other formats. Includes hex editor, disassembler (Carbon engine), decompilers, debuggers, YARA integration, and memory forensics. / Cerbero Suite — комплексный инструмент для анализа файлов, реверс-инжиниринга, сортировки вредоносного ПО и цифровой криминалистики. Поддерживает глубокую инспекцию PE, ELF, Mach-O, PDF, Office и других форматов.
> **Website:** [cerbero.io](https://cerbero.io/)
> **Role:** Security Engineer / Malware Analyst / Forensic Investigator / Sysadmin
> **Version:** Cerbero Suite 7.x
> **Platforms:** Windows, macOS, Linux

---

## 📚 Table of Contents

1. [Installation & Configuration](#1.%20Installation%20&%20Configuration)
2. [Core Management](#2.%20Core%20Management)
3. [File Analysis](#3.%20File%20Analysis)
4. [Malware Analysis & YARA](#4.%20Malware%20Analysis%20&%20YARA)
5. [Reverse Engineering](#5.%20Reverse%20Engineering)
6. [Memory Forensics](#6.%20Memory%20Forensics)
7. [Scripting & Automation](#7.%20Scripting%20&%20Automation)
8. [Troubleshooting & Tools](#8.%20Troubleshooting%20&%20Tools)
9. [Documentation Links](#9.%20Documentation%20Links)

---

## 1. Installation & Configuration

### Install on Linux

```bash
# Download from official site
wget https://cerbero.io/downloads/CerberoSuite-<VERSION>-linux-x86_64.tar.gz

# Extract
tar -xzf CerberoSuite-<VERSION>-linux-x86_64.tar.gz
cd CerberoSuite

# Run
./CerberoSuite
```

### Install via Package (if provided)

```bash
# Debian/Ubuntu (.deb)
dpkg -i cerbero-suite_<VERSION>_amd64.deb
apt install -f  # Fix dependencies / Установить зависимости

# RHEL/Fedora (.rpm)
rpm -ivh cerbero-suite-<VERSION>.x86_64.rpm
```

### License Activation

```bash
# Activate license via GUI
# Help → License → Enter License Key → <LICENSE_KEY>

# Or via environment variable
export CERBERO_LICENSE_KEY=<LICENSE_KEY>
```

### Editions Comparison

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

### Configuration Paths

| Path | Description |
|------|-------------|
| `~/.config/CerberoSuite/` | User configuration (Linux) / Пользовательская конфигурация |
| `~/.local/share/CerberoSuite/` | User data and plugins / Данные и плагины |
| `~/.local/share/CerberoSuite/plugins/` | Custom plugins directory / Каталог кастомных плагинов |
| `~/.local/share/CerberoSuite/yara/` | YARA rules directory / Каталог правил YARA |

---

## 2. Core Management

### Supported File Formats

| Category | Formats |
|----------|---------|
| Executables / Исполняемые | PE (32/64), ELF, Mach-O, DEX, Java Class |
| Documents / Документы | PDF, DOC, DOCX, XLS, XLSX, RTF, VBA macros |
| Archives / Архивы | ZIP, RAR, 7z, CAB, MSI, NSIS |
| Media / Медиа | SWF, images (JPEG, PNG, GIF, BMP) |
| Firmware / Прошивки | UPX packed, UEFI, firmware images |
| Memory / Память | Raw memory dumps, hibernation files, crash dumps |

### Basic Operations

```
# Open file for analysis
File → Open → Select file

# Scan directory for embedded files
File → Scan Directory → Select directory

# Batch analysis
File → Batch Analysis → Configure and run

# Export analysis report
File → Export → Choose format (JSON, XML, Text)
```

### Hex Editor / Hex-редактор

```
# Open file in hex editor
Right-click file → Open in Hex Editor

# Key features
# - Define structures (C-like syntax)
# - Bookmark regions
# - Pattern search (hex, text, regex)
# - Compare files
# - Edit live process memory (Advanced)
```

### Keyboard Shortcuts

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

### PE (Windows Executable) Analysis

```
# Inspect PE headers
# Automatic on opening .exe/.dll files:
# - DOS Header, PE Header, Optional Header
# - Sections table (text/data/rsrc/reloc)
# - Import/Export tables
# - Resources (icons, version info, manifests)
# - Digital signatures
# - Overlay data detection
```

### ELF (Linux Executable) Analysis

```
# Inspect ELF binaries
# - ELF Header (class, type, machine, entry point)
# - Program Headers (segments)
# - Section Headers
# - Symbol tables (.symtab, .dynsym)
# - Dynamic section (.dynamic)
# - Relocation entries
# - DWARF debug info (if present)
```

### Document Analysis

```
# Inspect Office documents for macros
# Open .doc/.xls/.docx/.xlsx:
# - Automatic VBA macro extraction
# - OLE stream inspection
# - Embedded object detection
# - Suspicious pattern highlighting

# PDF analysis
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

### YARA Rules Management

```
# Download YARA rules
# Tools → YARA → Download Rules

# Scan file with YARA
# Right-click file → Scan with YARA

# Create custom YARA rule
# Tools → YARA → New Rule
```

### YARA Rule Example

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

### Malware Triage Workflow

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

### Carbon Disassembler

```
# Disassemble executable
# Right-click PE/ELF/Mach-O → Disassemble

# Supported architectures
# - x86 / x86-64
# - ARM / ARM64
# - MIPS
# - PowerPC

# Features
# - Interactive navigation
# - Cross-references (xrefs)
# - Function detection
# - Ghidra Sleigh decompiler integration
# - Comment and rename symbols
```

### Decompilers

| Target | Description / Описание |
|--------|------------------------|
| .NET (MSIL) | Decompile to C# / Декомпиляция в C# |
| Java (bytecode) | Decompile to Java / Декомпиляция в Java |
| Android (DEX) | Decompile to Java/Smali / Декомпиляция в Java/Smali |
| Native (via Ghidra Sleigh) | Decompile to pseudo-C / Декомпиляция в псевдо-C |

### Debugger

```
# Attach to process
# Debug → Attach → Select PID

# Debug executable
# Debug → Start → Select file

# Debug shellcode
# Debug → Shellcode → Paste or load shellcode

# Convert shellcode to executable
# Tools → Shellcode → Convert to EXE
```

---

## 6. Memory Forensics

> [!NOTE]
> Memory forensics features require the **Advanced** edition. Supports Windows memory images (XP through 11). / Криминалистика памяти — функция Advanced-редакции. Поддержка образов памяти Windows (от XP до 11).

### Supported Memory Image Types

| Type | Description / Описание |
|------|------------------------|
| Raw memory dump / Сырой дамп | Physical memory image / Образ физической памяти |
| Hibernation file / Файл гибернации | `hiberfil.sys` |
| Crash dump / Аварийный дамп | Full/kernel memory dump / Полный/ядрёной дамп |
| VMware `.vmem` | VMware memory snapshot / Снимок памяти VMware |

### Memory Analysis Workflow

```
# Open memory image
File → Open → Select memory dump

# Analysis features
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
# Example: analyze a PE file
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

# Run
analyze_pe("/path/to/sample.exe")
```

### Batch Processing Script

```python
# Example: scan directory for suspicious PDFs
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

### Plugin Development

```
# Plugin directory
~/.local/share/CerberoSuite/plugins/

# Plugin structure
# my_plugin/
# ├── __init__.py       # Plugin entry point
# ├── plugin.json       # Metadata
# └── modules/          # Additional modules
```

---

## 8. Troubleshooting & Tools

### Common Issues

#### 1. GUI Not Starting on Linux / GUI

```bash
# Check library dependencies
ldd ./CerberoSuite | grep "not found"

# Install missing Qt/GUI libraries
# Debian/Ubuntu
apt install libqt5widgets5 libqt5gui5 libqt5core5a libgl1-mesa-glx

# RHEL/CentOS
dnf install qt5-qtbase qt5-qtbase-gui mesa-libGL
```

#### 2. Large File Performance

```
# For large files (> 1GB)
# - Use hex editor with lazy loading / Hex-редактор
# - Disable auto-scan for embedded files
# Settings → Analysis → Disable "Auto-scan embedded files"
```

#### 3. YARA Rules Not Loading

```bash
# Check YARA rules directory
ls -la ~/.local/share/CerberoSuite/yara/

# Validate YARA rule syntax
yara -C /path/to/rule.yar    # Compile check / Проверка компиляции
```

### CLI Usage

```bash
# Analyze file from CLI
CerberoSuite --analyze /path/to/file

# Scan with specific YARA rules
CerberoSuite --yara-scan /path/to/rules.yar /path/to/file

# Batch scan directory
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
