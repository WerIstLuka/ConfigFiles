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
	return os.system(f"cp -r {path} {os.path.dirname(path)[1:]}/")

def CopyFiles(files:List[str]) -> None:
	for file in files:
		if copyFile(file):
			print(f"[ERORR] could not copy file \"{file}\"")
			exit(1)
