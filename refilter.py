#!/usr/bin/python3
# -*- coding: utf-8 -*-

"""
***************************************************************************
    refilter.py
    ---------------------
    Date                 : Sep 2012
    Copyright            : (C) 2012-2023 by Jürgen E. Fischer
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

from __future__ import print_function
from builtins import str

import re
import sys
import os
from itertools import islice

patterns = []

f = open(os.path.join(os.path.dirname(__file__), "re"), "r", encoding="utf-8")
while True:
    line = list(islice(f, 50))
    if not line:
        break
    patterns.append(re.compile("|".join([x.replace('\n','') for x in line])))
f.close()

if len(sys.argv) > 2:
    print("usage: %s [logfile]" % (sys.argv[0]))
    exit(1)

try:
    if len(sys.argv) == 2:
        f = open(sys.argv[1], "r", encoding="utf-8")
    else:
        f = os.fdopen(0, "r", encoding="utf-8")
except IOError:
    print("%s: could not open %s" % (sys.argv[0], sys.argv[1]))
    exit(1)

while True:
    try:
        line = f.readline()
    except UnicodeDecodeError:
        continue

    if line == "":
        break

    found = False
    for p in patterns:
        if p.match(line):
            found = True
            break

    if found:
        continue

    print(line, end=' ')
    sys.stdout.flush()

f.close()
