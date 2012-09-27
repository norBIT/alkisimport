#!/usr/bin/python
# -*- coding: utf8 -*-

import re
import sys 
import os 

f = open(os.path.join( os.path.dirname(__file__), "re"), "rbU")
pattern = re.compile( f.read().strip("\n").replace("\n","|") )
f.close()

if len(sys.argv)!=2:
	print "usage: %s logfile" % (sys.argv[0])
	exit(1)

try:
	f = open(sys.argv[1], "rbU")
except:
	print "%s: could not open %s" % (sys.argv[0], sys.argv[1])
	exit(1)

for l in f.read().splitlines():
	if pattern.match(l):
		continue
	print l

f.close()
