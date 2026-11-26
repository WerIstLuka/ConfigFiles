#!/bin/python3

import os
from typing import List

if __name__ == "__main__":
	print("don't run this file, instead run the files in private and public")
	exit(1)

def copyFile(path:str) -> int:
	directory = os.path.dirname(path)[1:]
	try:
		os.makedirs(directory)
	except FileExistsError:
		pass
	if path[-1] == "*":
		os.system(f"bash -c 'cp -r \"{path[:-1]}\"* \"{directory}\"'")
	else:
		os.system(f"bash -c 'cp -r \"{path}\" \"{directory}\"'")

def CopyFiles(files:List[str]) -> None:
	for file in files:
		if copyFile(file):
			print(f"[ERORR] could not copy file \"{file}\"")
			exit(1)
