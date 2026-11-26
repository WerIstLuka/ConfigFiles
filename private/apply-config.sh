#!/bin/bash

echo "make sure to put all the files into this directory"
read -r -p "enter \"done\" to continue: " continue

if [ "$continue" != "done" ]; then
	exit 1
f

echo "applying .config"
cp -r home/luka/.config ~/

# echo "applying .local"
# cp -r home/luka/.local ~/

# echo "applying dconf settings"
# dconf load / < dconf/dconf
