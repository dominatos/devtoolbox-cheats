Title: ✂️ SED — Commands
Group: Text & Parsing
Icon: ✂️
Order: 5

sed 's/foo/bar/g' file                          # Replace all 'foo'→'bar' per line / Замена всех 'foo' на 'bar' в строке
sed -n '10,20p' file                            # Print only lines 10..20 / Печать только строк 10..20
sed '/^#/d' file                                # Delete commented lines / Удалить строки-комментарии
sed -i 's/DEBUG=false/DEBUG=true/' .env         # In-place edit .env / Правка на месте .env
sed -n 's/^ID=//p' /etc/os-release              # Extract value after ID= / Извлечь значение после ID=

