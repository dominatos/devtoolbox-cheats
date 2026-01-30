Title: 📦 TAR (zstd) — Commands
Group: Files & Archives
Icon: 📦
Order: 1

# Zstandard compression / Сжатие Zstandard

# Method 1: explicit compressor / Явный компрессор
tar -I zstd -cvf archive.tar.zst dir/           # Pack dir → .tar.zst / Упаковать dir → .tar.zst
tar -I unzstd -xvf archive.tar.zst               # Extract .tar.zst / Распаковать .tar.zst

# Method 2: GNU tar flags / Флаги GNU tar
tar --zstd -cvf archive.tar.zst dir/            # Pack with --zstd / Упаковать с --zstd
tar --zstd -xvf archive.tar.zst                 # Extract / Распаковать

# Levels / Уровни (0..19)
tar -I 'zstd -19' -cvf archive.tar.zst dir/     # Max compression / Максимальное сжатие

# Streaming / Поточное использование
tar -cv dir/ | zstd -T0 -19 -o archive.tar.zst  # Use all cores / Все ядра
zstdcat archive.tar.zst | tar -xv               # Extract from stream / Распаковка из потока

# List / Просмотр
tar -I zstd -tvf archive.tar.zst | less         # List contents / Показать содержимое

