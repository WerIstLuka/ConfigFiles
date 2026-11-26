#!/bin/python3

import os
import libGetConfig

# to include a directory use `/*` at the end
files = [
	"/home/luka/.config/discord/settings.json",
	"/home/luka/.config/discord/Local Storage/leveldb/*",
	"/home/luka/.config/Vencord/settings/*",
	"/home/luka/.config/lutris/*",
]

libGetConfig.CopyFiles(files)
