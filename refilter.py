#!/usr/bin/python
# -*- coding: utf8 -*-

"""
***************************************************************************
    refilter.py
    ---------------------
    Date                 : Sep 2012
    Copyright            : (C) 2012-2014 by Jürgen Fischer
    Email                : jef at norbit dot de
***************************************************************************
*                                                                         *
*   This program is free software; you can redistribute it and/or modify  *
*   it under the terms of the GNU General Public License as published by  *
*   the Free Software Foundation; either version 2 of the License, or     *
*   (at your option) any later version.                                   *
*                                                                         *
***************************************************************************
"""

import re
import sys
import os

f = open(os.path.join( os.path.dirname(__file__), "re"), "rbU")
pattern = re.compile( f.read().strip("\n").replace("\n","|") )
f.close()

if len(sys.argv)>2:
	print "usage: %s [logfile]" % (sys.argv[0])
	exit(1)

try:
	if len(sys.argv)==2:
		f = open(sys.argv[1], "rbU")
	else:
		f = os.fdopen(0, "rbU")
except:
	print "%s: could not open %s" % (sys.argv[0], sys.argv[1])
	exit(1)

while True:
	l = f.readline()
	if l=="":
		break
	elif pattern.match(l):
		continue
	else:
		print l,
		sys.stdout.flush()

f.close()
