#!/bin/python3

import os
import libGetConfig

# to include a directory use `/*` at the end
files = [
	"/etc/illyria-default-lockscreen-nobrand.png",
	"/etc/nanorc",
	"/etc/ps3.wav",
	"/home/luka/.bashrc",
	"/home/luka/.config/aliasrc",
	"/home/luka/.config/cinnamon/spices/BlurCinnamon@klangman/*",
	"/home/luka/.config/cinnamon/spices/calendar@cinnamon.org/*",
	"/home/luka/.config/cinnamon/spices/compiz-windows-effect@hermes83.github.com/*",
	"/home/luka/.config/cinnamon/spices/cpu-monitor-text@gnemonix/*",
	"/home/luka/.config/cinnamon/spices/gpumonitor@axel358/*",
	"/home/luka/.config/cinnamon/spices/grouped-window-list@cinnamon.org/*",
	"/home/luka/.config/cinnamon/spices/LukaMenu@luka/*",
	"/home/luka/.config/cinnamon/spices/mem-monitor-text@datanom.net/*",
	"/home/luka/.config/cinnamon/spices/multicore-sys-monitor@ccadeptic23/*",
	"/home/luka/.config/cinnamon/spices/opacify@anish.org/*",
	"/home/luka/.config/cinnamon/spices/sound@cinnamon.org/*",
	"/home/luka/.config/cinnamon/spices/spacer@cinnamon.org/*",
	"/home/luka/.config/cinnamon/spices/transparent-panels@germanfr/*",
	"/home/luka/.config/cinnamon/spices/user-shadows@nathan818fr/*",
	"/home/luka/.config/fastfetch/config.jsonc",
	"/home/luka/.config/menus/*",
	"/home/luka/.config/micro/bindings.json",
	"/home/luka/.config/micro/colorschemes/*",
	"/home/luka/.config/micro/plug/*",
	"/home/luka/.config/micro/settings.json",
	"/home/luka/.config/mimeapps.list",
	"/home/luka/.config/neofetch/config.conf",
	"/home/luka/.config/user-dirs.dirs",
	"/home/luka/.gitconfig",
	"/home/luka/.local/share/desktop-directories/*",
	"/home/luka/.profile",
]

libGetConfig.CopyFiles(files)
