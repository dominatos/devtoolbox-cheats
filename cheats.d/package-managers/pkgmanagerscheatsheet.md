Title: 📦 Package Managers
Group: Package Managers
Icon: 📦
Order: 1

sudo dnf update && sudo dnf install pkg         # DNF update/install / Обновить/установить (DNF)
sudo pacman -Syu pkg                            # pacman sync+upgrade / Обновление (pacman)
sudo zypper refresh && sudo zypper in pkg       # zypper refresh+install / Обновить+установить
sudo snap install pkg                           # snap install / Установка snap
flatpak install flathub org.app.App             # flatpak install / Установка из Flathub

