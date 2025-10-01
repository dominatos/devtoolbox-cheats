Title: 📦 ZIP / 7z / ZSTD — Commands
Group: Files & Archives
Icon: 📦
Order: 3

zip -r archive.zip dir/                         # Create zip recursively / Создать zip рекурсивно
unzip archive.zip -d out/                       # Extract zip to out/ / Распаковать zip в out/
7z a archive.7z file1 dir/                      # Create .7z with files/dir / Создать .7z из файлов/каталога
7z x archive.7z                                 # Extract .7z / Распаковать .7z
zstd -19 bigfile && unzstd bigfile.zst          # Compress/decompress with zstd / Сжать/распаковать zstd
tar --use-compress-program=zstd -cvf archive.tar.zst dir/  # Tar with zstd / Tar со zstd
tar --use-compress-program=unzstd -xvf archive.tar.zst     # Extract tar.zst / Распаковать tar.zst

