Title: 🛠️ Build — Make/CMake/Meson
Group: Dev & Tools
Icon: 🛠️
Order: 5

## Table of Contents
- [Make](#-make--традиционная-сборка)
- [CMake](#-cmake--современная-сборка)
- [Meson](#-meson--быстрая-сборка)
- [Ninja](#-ninja--backend-сборка)
- [Configure Options](#-configure-options--опции-конфигурации)
- [Troubleshooting](#-troubleshooting--устранение-неполадок)
- [Real-World Examples](#-real-world-examples--примеры-из-практики)

---

# 🔨 Make / Традиционная сборка

### Basic Usage / Базовое использование
make                                          # Build default target / Сборка целевой цели по умолчанию
make all                                      # Build all targets / Собрать все цели
make clean                                    # Clean build artifacts / Очистить артефакты сборки
make install                                  # Install to system / Установить в систему
sudo make install                             # Install with privileges / Установить с привилегиями
make uninstall                                # Uninstall from system / Удалить из системы

### Parallel Builds / Параллельная сборка
make -j$(nproc)                               # Use all CPU cores / Использовать все ядра CPU
make -j4                                      # Use 4 cores / Использовать 4 ядра
make -j$(nproc) --load-average=$(nproc)       # Limit load / Ограничить нагрузку

### Specific Targets / Конкретные цели
make test                                     # Run tests / Запустить тесты
make check                                    # Alternative test / Альтернативный тест
make docs                                     # Build documentation / Собрать документацию
make dist                                     # Create distribution tarball / Создать дистрибутивный архив

### Debugging / Отладка
make VERBOSE=1                                # Verbose output / Подробный вывод
make -n                                       # Dry run / Предварительный просмотр
make -d                                       # Debug makefile / Отладка Makefile

### Variables / Переменные
make CC=clang                                 # Override compiler / Переопределить компилятор
make CFLAGS="-O2 -march=native"               # Custom CFLAGS / Пользовательские CFLAGS
make PREFIX=/usr/local                        # Custom prefix / Пользовательский префикс
make DESTDIR=/tmp/install install             # Staged install / Промежуточная установка

---

# 🏗️ CMake / Современная сборка

### Basic Configuration / Базовая конфигурация
cmake -S . -B build                           # Generate build tree / Сгенерировать дерево сборки
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release  # Release build / Релизная сборка
cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug  # Debug build / Отладочная сборка
cmake -S . -B build -DCMAKE_BUILD_TYPE=RelWithDebInfo  # Release with debug info / Релиз с отладочной информацией
cmake -S . -B build -DCMAKE_BUILD_TYPE=MinSizeRel  # Minimal size / Минимальный размер

### Build / Сборка
cmake --build build                           # Build project / Собрать проект
cmake --build build -j$(nproc)                # Parallel build / Параллельная сборка
cmake --build build --target all              # Build all / Собрать всё
cmake --build build --target install          # Build and install / Собрать и установить
cmake --build build --clean-first             # Clean before build / Очистить перед сборкой

### Install / Установка
cmake --install build                         # Install project / Установить проект
cmake --install build --prefix /opt/myapp     # Custom prefix / Пользовательский префикс
sudo cmake --install build                    # Install with sudo / Установить с sudo
cmake --install build --component runtime     # Install component / Установить компонент

### Configuration Options / Опции конфигурации
cmake -S . -B build -DCMAKE_INSTALL_PREFIX=/usr/local  # Install prefix / Префикс установки
cmake -S . -B build -DCMAKE_CXX_COMPILER=clang++       # C++ compiler / C++ компилятор
cmake -S . -B build -DCMAKE_C_COMPILER=clang           # C compiler / C компилятор
cmake -S . -B build -DBUILD_SHARED_LIBS=ON             # Shared libraries / Разделяемые библиотеки
cmake -S . -B build -DBUILD_TESTING=OFF                # Disable tests / Отключить тесты

### Advanced / Продвинутое
cmake -S . -B build -G Ninja                  # Use Ninja generator / Использовать генератор Ninja
cmake -S . -B build -G "Unix Makefiles"       # Use Make generator / Использовать генератор Make
cmake -S . -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON  # Generate compile_commands.json / Генерировать compile_commands.json
cmake -S . -B build -DCMAKE_VERBOSE_MAKEFILE=ON  # Verbose makefile / Подробный вывод

### Testing / Тестирование
ctest --test-dir build                        # Run tests / Запустить тесты
ctest --test-dir build --output-on-failure    # Show failed tests / Показать проваленные тесты
ctest --test-dir build -j$(nproc)             # Parallel tests / Параллельные тесты
ctest --test-dir build -R regex               # Run tests matching regex / Запустить тесты по регулярке

### Clean / Очистка
cmake --build build --target clean            # Clean build / Очистить сборку
rm -rf build                                  # Remove build directory / Удалить директорию сборки

---

# ⚡ Meson / Быстрая сборка

### Setup / Настройка
meson setup build                             # Setup build directory / Настроить директорию сборки
meson setup build --buildtype=release         # Release build / Релизная сборка
meson setup build --buildtype=debug           # Debug build / Отладочная сборка
meson setup build --buildtype=debugoptimized  # Optimized debug / Оптимизированная отладка
meson setup build --prefix=/usr/local         # Custom prefix / Пользовательский префикс

### Compile / Компиляция
meson compile -C build                        # Compile project / Скомпилировать проект
meson compile -C build -j$(nproc)             # Parallel compile / Параллельная компиляция
ninja -C build                                # Alternative with ninja / Альтернатива с ninja

### Install / Установка
meson install -C build                        # Install project / Установить проект
meson install -C build --destdir /tmp/staging # Staged install / Промежуточная установка
sudo meson install -C build                   # Install with sudo / Установить с sudo

### Test / Тестирование
meson test -C build                           # Run tests / Запустить тесты
meson test -C build --verbose                 # Verbose tests / Подробные тесты
meson test -C build -j$(nproc)                # Parallel tests / Параллельные тесты

### Configuration / Конфигурация
meson configure build                         # Show configuration / Показать конфигурацию
meson configure build -Dprefix=/opt/myapp     # Change option / Изменить опцию
meson configure build -Dbuildtype=release     # Change build type / Изменить тип сборки

### Other Commands / Другие команды
meson dist -C build                           # Create distribution / Создать дистрибутив
meson introspect build --targets              # List targets / Список целей
meson wrap install packagename                # Install dependency / Установить зависимость

---

# 🥷 Ninja / Backend сборка

### Basic Usage / Базовое использование
ninja                                         # Build default target / Собрать цель по умолчанию
ninja -C build                                # Build in directory / Собрать в директории
ninja all                                     # Build all targets / Собрать все цели
ninja clean                                   # Clean build / Очистить сборку

### Parallel / Параллель
ninja -j$(nproc)                              # Use all cores / Использовать все ядра
ninja -j8                                     # Use 8 cores / Использовать 8 ядер

### Specific Targets / Конкретные цели
ninja test                                    # Run tests / Запустить тесты
ninja install                                 # Install / Установить
ninja <TARGET_NAME>                           # Build specific target / Собрать конкретную цель

### Info / Информация
ninja -t targets                              # List targets / Список целей
ninja -t graph | dot -Tpng -o graph.png       # Generate dependency graph / Генерировать граф зависимостей
ninja -t commands                             # Show all commands / Показать все команды

---

# ⚙️ Configure Options / Опции конфигурации

### Autotools (./configure) / Autotools
./configure                                   # Basic configure / Базовая конфигурация
./configure --prefix=/usr/local               # Install prefix / Префикс установки
./configure --help                            # Show options / Показать опции
./configure --enable-feature                  # Enable feature / Включить функцию
./configure --disable-feature                 # Disable feature / Отключить функцию
./configure --with-package                    # Include package / Включить пакет
./configure --without-package                 # Exclude package / Исключить пакет
./configure CFLAGS="-O3" CXXFLAGS="-O3"       # Custom flags / Пользовательские флаги

### Common Pattern / Распространённый шаблон
./configure && make -j$(nproc) && sudo make install  # Configure, build, install / Конфигурация, сборка, установка
./configure --prefix=$HOME/.local && make -j$(nproc) && make install  # User install / Установка пользователя

---

# 🐛 Troubleshooting / Устранение неполадок

### Build Errors / Ошибки сборки
make clean && make -j1                        # Serial build for debugging / Последовательная сборка для отладки
cmake --build build --verbose                 # Verbose build / Подробная сборка
VERBOSE=1 make                                # Verbose make / Подробный make
meson compile -C build --verbose              # Verbose meson / Подробный meson

### Missing Dependencies / Отсутствующие зависимости
apt search <PACKAGE>                          # Search package / Поиск пакета
apt-cache search <LIB>-dev                    # Search dev package / Поиск dev пакета
dnf search <PACKAGE>                          # RHEL search / Поиск RHEL
pkg-config --list-all                         # List installed packages / Список установленных пакетов
pkg-config --modversion <LIB>                 # Check version / Проверить версию

### CMake Cache Issues / Проблемы кэша CMake
rm -rf build && cmake -S . -B build           # Fresh build / Свежая сборка
cmake -S . -B build -U '*'                    # Clear cache / Очистить кэш
ccmake build                                  # Interactive config / Интерактивная конфигурация

### Check Build System / Проверка системы сборки
cmake --version                               # CMake version / Версия CMake
meson --version                               # Meson version / Версия Meson
ninja --version                               # Ninja version / Версия Ninja
make --version                                # Make version / Версия Make

---

# 🌟 Real-World Examples / Примеры из практики

### Build from Source (Autotools) / Сборка из исходников (Autotools)
```bash
wget https://example.com/project-1.0.tar.gz
tar -xzf project-1.0.tar.gz
cd project-1.0
./configure --prefix=/usr/local
make -j$(nproc)
sudo make install
sudo ldconfig                                 # Update library cache / Обновить кэш библиотек
```

### Build from Source (CMake) / Сборка из исходников (CMake)
```bash
git clone https://github.com/project/repo.git
cd repo
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local
cmake --build build -j$(nproc)
sudo cmake --install build
```

### Build from Source (Meson) / Сборка из исходников (Meson)
```bash
git clone https://github.com/project/repo.git
cd repo
meson setup build --buildtype=release --prefix=/usr/local
meson compile -C build -j$(nproc)
sudo meson install -C build
```

### User-Local Install / Установка пользователя
```bash
# CMake user install / CMake установка пользователя
cmake -S . -B build -DCMAKE_INSTALL_PREFIX=$HOME/.local
cmake --build build -j$(nproc)
cmake --install build

# Add to PATH / Добавить в PATH
echo 'export PATH=$HOME/.local/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
```

### Cross-Compilation / Кросс-компиляция
```bash
# CMake cross-compile / CMake кросс-компиляция
cmake -S . -B build -DCMAKE_TOOLCHAIN_FILE=toolchain.cmake

# Meson cross-compile / Meson кросс-компиляция
meson setup build --cross-file cross.txt
```

### Static Build / Статическая сборка
```bash
# CMake static / CMake статическая
cmake -S . -B build -DBUILD_SHARED_LIBS=OFF -DCMAKE_EXE_LINKER_FLAGS="-static"

# Autotools static / Autotools статическая
./configure --enable-static --disable-shared LDFLAGS="-static"
```

### Optimized Build / Оптимизированная сборка
```bash
# CMake with LTO / CMake с LTO
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON

# Autotools with native / Autotools с нативной оптимизацией
./configure CFLAGS="-O3 -march=native -flto" CXXFLAGS="-O3 -march=native -flto"
```

### Debug Build / Отладочная сборка
```bash
# CMake debug / CMake отладка
cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
cmake --build build -j$(nproc)

# Use with gdb / Использовать с gdb
gdb ./build/myapp
```

### Package for Distribution / Пакет для дистрибуции
```bash
# CMake CPack / CMake CPack
cmake -S . -B build
cmake --build build
cpack --config build/CPackConfig.cmake        # Create package / Создать пакет

# Meson dist / Meson дистрибутив
meson setup build
meson dist -C build                           # Create tarball / Создать архив
```

### Container Build / Сборка в контейнере
```bash
# Build in Docker / Сборка в Docker
docker run --rm -v $(pwd):/src -w /src ubuntu:22.04 bash -c "apt update && apt install -y build-essential cmake && cmake -S . -B build && cmake --build build"
```

# 💡 Best Practices / Лучшие практики
# Always use -j$(nproc) for parallel builds / Всегда используйте -j$(nproc) для параллельной сборки
# Prefer out-of-source builds / Предпочитайте сборку вне исходников
# Use Release builds for production / Используйте Release сборки для продакшена
# Check dependencies before building / Проверяйте зависимости перед сборкой
# Clean build directory on errors / Очищайте директорию сборки при ошибках
# Use DESTDIR for staged installs / Используйте DESTDIR для промежуточных установок

# 🔧 Build Tools Comparison / Сравнение инструментов сборки
# Make/Autotools: Traditional, widespread / Традиционные, распространённые
# CMake: Modern, cross-platform / Современный, кроссплатформенный
# Meson: Fast, simple syntax / Быстрый, простой синтаксис
# Ninja: Fast backend for CMake/Meson / Быстрый backend для CMake/Meson

# 📋 Common Build Types / Распространённые типы сборки
# Debug: No optimization, debug symbols / Без оптимизации, отладочные символы
# Release: Optimized, no debug symbols / Оптимизированная, без отладочных символов
# RelWithDebInfo: Optimized with debug / Оптимизированная с отладкой
# MinSizeRel: Optimized for size / Оптимизированная для размера
