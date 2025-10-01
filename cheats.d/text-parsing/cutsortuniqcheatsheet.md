Title: 🔪 cut/sort/uniq — Commands
Group: Text & Parsing
Icon: 🔪
Order: 6

cut -d',' -f1,3 data.csv                        # Take columns 1 and 3 (CSV) / Взять столбцы 1 и 3 (CSV)
cut -c1-10 file                                 # First 10 characters of each line / Первые 10 символов строки
sort -n numbers.txt                             # Numeric sort / Числовая сортировка
sort file | uniq -c | sort -nr | head           # Top repeated lines (freq desc) / Топ повторяющихся строк (по убыванию)

