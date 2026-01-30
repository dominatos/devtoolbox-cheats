Title: 🔁 diff / patch — Commands
Group: Files & Archives
Icon: 🔁
Order: 4

diff -u old.conf new.conf > change.patch        # Unified diff to patch file / Патч в формате unified
diff -qrl /path1/ /path2/ #diiference between 2 folders/ Разница между 2 папками.
patch -p1 < change.patch                        # Apply patch / Применить патч
patch -R -p1 < change.patch                     # Reverse patch / Откатить патч

