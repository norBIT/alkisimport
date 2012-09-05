#!/usr/bin/python
# -*- coding: utf8 -*-

import re

f = open("re", "rbU")
pattern = re.compile( f.read().strip("\n").replace("\n","|") )
f.close()

f = open("output.log", "rbU")

for l in f.read().splitlines():
	if pattern.match(l):
		continue
	print l

f.close()
