Title: ⚡ ripgrep / fd / bat
Group: Text & Parsing
Icon: ⚡
Order: 10

rg 'pattern' -n --hidden -g '!node_modules'     # Fast search (ripgrep) / Быстрый поиск (ripgrep)
fd -t f -e log error .                          # Find files (fd) / Поиск файлов (fd)
bat -p file.txt                                 # Pretty cat (bat) / Красивый просмотр (bat)
rg -n 'TODO' | fzf                               # Search then fuzzy-pick / Поиск и выбор (fzf)

