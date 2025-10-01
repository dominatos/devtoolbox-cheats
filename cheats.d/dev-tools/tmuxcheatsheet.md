Title: 🧷 tmux — Commands
Group: Dev & Tools
Icon: 🧷
Order: 6

tmux new -s work                                # New session 'work' / Новая сессия 'work'
tmux attach -t work                             # Attach to session / Подключиться к сессии
tmux kill-session -t work                       # Kill session / Убить сессию
# Keys (prefix = Ctrl+b) / Клавиши (префикс = Ctrl+b):
#  % split vertical | " split horizontal | arrows move pane / Вертик/гориз сплит, стрелки — перемещение
#  z toggle zoom | x kill-pane | d detach | [ copy-mode | c new-window | , rename / Зум/убить/отсоединить/копир/новое окно/переим.

