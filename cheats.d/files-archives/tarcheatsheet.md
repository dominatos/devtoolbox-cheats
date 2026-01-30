Title: 📦 TAR — Commands
Group: Files & Archives
Icon: 📦
Order: 2

# No compression / Без сжатия
tar -cvf archive.tar folder/         # Create archive / Создать архив
tar -xvf archive.tar                 # Extract / Распаковать
tar -tvf archive.tar                 # List / Просмотр

# TAR.GZ
tar -czvf archive.tar.gz folder/     # Create tar.gz / Создать tar.gz
tar -xzvf archive.tar.gz             # Extract tar.gz / Распаковать .tar.gz
tar -tzvf archive.tar.gz             # List tar.gz / Просмотр .tar.gz

# TAR.BZ2
tar -cjvf archive.tar.bz2 folder/    # Create tar.bz2 / Создать tar.bz2
tar -xjvf archive.tar.bz2            # Extract tar.bz2 / Распаковать .tar.bz2
tar -tjvf archive.tar.bz2            # List tar.bz2 / Просмотр .tar.bz2

