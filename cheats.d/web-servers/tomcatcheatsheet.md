Title: 🐱 Tomcat — Cheatsheet
Group: Web Servers
Icon: 🐱
Order: 3

# Manage / Управление (service name may vary / имя сервиса может отличаться)
sudo systemctl status tomcat9                                        # Status / Статус
sudo systemctl restart tomcat9                                       # Restart / Перезапуск
sudo tail -f /var/log/tomcat9/catalina.out                           # Tail main log / Хвост основного лога

# Deploy WAR / Деплой WAR
sudo cp app.war /var/lib/tomcat9/webapps/                            # Drop-in deploy / Копировать для деплоя
# or unpack to webapps/app/ for exploded / или распаковать в webapps/app/

# setenv.sh / env options / переменные окружения
# export JAVA_OPTS="-Xms512m -Xmx1024m"                              # JVM memory / Память JVM
# export CATALINA_OPTS="-Dspring.profiles.active=prod"               # App opts / Опции приложения

# Connector in server.xml / Коннектор в server.xml
# <Connector port="8080" protocol="HTTP/1.1" connectionTimeout="20000" redirectPort="8443" />

