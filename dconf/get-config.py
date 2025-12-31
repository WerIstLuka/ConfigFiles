#!/bin/python3

import json
import dconf
import os

newfile = ""

with open("dconf.json", "r") as file:
	data = json.load(file)

for key in data:
	data_type = type(data[key])
	newfile += f"[{key}]\n"
	if data_type == str:
		# os.system(f"dconf read /{key}/{data[key]}")
		value = os.popen(f"dconf read /{key}/{data[key]}").read()
		newfile += f"{data[key]}={value}\n"
	elif data_type == list:
		for i in data[key]:
			# os.system(f"dconf read /{key}/{i}")
			value = os.popen(f"dconf read /{key}/{i}").read()
			newfile += f"{i}={value}"
				
	with open("dconf", "w") as output:
		output.write(newfile)		
