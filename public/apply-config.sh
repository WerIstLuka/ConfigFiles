#!/bin/bash

echo "this only works on systems with apt installed"
echo "set mirror to fastest available to speed up install"
read -r -p "enter \"done\" to continue: " continue

if [ "$continue" != "done" ]; then
	exit
fi

echo "updating and installing packages"
sudo apt update && sudo apt upgrade -y
sudo apt install -y steam dconf-cli openssh-server zoxide eza extrepo ghex gimp kdenlive obs-studio virt-manager libvirt-daemon-system libvirt-clients git gcc g++ openjdk-8-jdk openjdk-17-jdk radeontop scanmem geary micro lutris golang htop meld oathtool gh python3-pip xapp-vorbiscomment-thumbnailer
#out of repo stuff
sudo extrepo enable librewolf

#gonna kill myself because of this
cd OTHER/packages
downloadGitRelease(){
	url=$(curl -i $1 | sed 's/\r$//' | grep -Po "(?<=location: ).+" | sed s/tag/download/)
	wget $url/$2
}

downloadGitRelease "https://github.com/WerIstLuka/20.3-Mint-Y-Luka-Icons/releases/latest" "20.3-Mint-Y-Luka-Icons.deb"
downloadGitRelease "https://github.com/WerIstLuka/20.3-Mint-Y-Luka-Themes/releases/latest" "20.3-Mint-Y-Luka-Themes.deb"
downloadGitRelease "https://github.com/WerIstLuka/LukaMenu/releases/latest" "luka-menu.deb"
cd ../..

wget https://dtinth.github.io/comic-mono-font/ComicMono.ttf -O ComicMono.ttf > /dev/null

sudo apt update
sudo apt install librewolf -y
sudo dpkg -i ./OTHER/packages/*.deb

sudo chown -R root:root etc
sudo cp -r etc /
sudo chown root:root ComicMono.ttf
sudo mv ComicMono.ttf /usr/share/fonts

echo "installing applets"
git clone https://github.com/linuxmint/cinnamon-spices-applets > /dev/null
pushd cinnamon-spices-applets/ > /dev/null
cp -r {gpumonitor@axel358/files/*,cpu-monitor-text@gnemonix/files/*,multicore-sys-monitor@ccadeptic23/files/*,mem-monitor-text@datanom.net/files/*} ~/.local/share/cinnamon/applets/
popd > /dev/null

echo "installing extensions"
git clone https://github.com/linuxmint/cinnamon-spices-extensions > /dev/null
pushd cinnamon-spices-extensions > /dev/null
cp -r {transparent-panels@germanfr/files/*,compiz-windows-effect@hermes83.github.com/files/*,opacify@anish.org/files/*,opacity-slider@neatnit/files/*,user-shadows@nathan818fr/files/*,BlurCinnamon@klangman/files/*} ~/.local/share/cinnamon/extensions/
popd > /dev/null

echo "applying .config"
cp -r home/luka/.config ~/

echo "applying .local"
cp -r home/luka/.local ~/

echo "applying other dot files"
cp home/luka/.bashrc home/luka/.profile ~/

echo "applying dconf settings"
dconf load / < OTHER/dconf/dconf
