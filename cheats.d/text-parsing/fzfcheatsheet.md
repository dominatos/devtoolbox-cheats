Title: ⚡ fzf — Fuzzy Finder
Group: Text & Parsing
Icon: ⚡
Order: 11

history | fzf                                   # Search history / Поиск по истории
fd -t f | fzf | xargs -r $EDITOR                # Pick file to edit / Выбор файла для редактирования
git branch | fzf | xargs -r git checkout        # Switch branch / Переключить ветку

