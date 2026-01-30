Title: 🔍 strace / perf / tcpdump — Commands
Group: Diagnostics
Icon: 🔍
Order: 1

sudo strace -p PID -f -e trace=network          # Trace network syscalls of PID / Трассировка сетевых вызовов PID
sudo strace -o trace.txt -f -tt -T -s 200 -p PID# Detailed trace to file / Детальная трассировка в файл
sudo perf top                                   # Live CPU hot spots / «Горячие точки» CPU
sudo perf record -g -- ./app && sudo perf report# Profile app and report / Профилировать и отчёт
sudo tcpdump -n -i eth0 tcp port 443            # Capture TCP 443 without name resolve / Захват TCP 443 без резолва имён
sudo tcpdump -A -s0 -i any host 10.0.0.5        # Full packets, ASCII, host filter / Полные пакеты ASCII, фильтр по хосту

