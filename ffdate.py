#!/usr/bin/env python3

"""
***************************************************************************
    ffdate.py
    ---------------------
    Date                 : Feb 2023
    Copyright            : (C) 2023 by Jürgen Fischer
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

from datetime import datetime
from lxml import etree as et


def getdate(inputfile):
    maxChunks = 100
    chunkSize = 1000
    key = "geaenderteObjekte"

    f = open(inputfile, "rb")

    header = b""
    i = 0
    p = -1
    while i < maxChunks and p < 0:
        header += f.read(chunkSize)
        i += 1
        p = header.find("<{}>".format(key).encode("utf-8"))

    if p < 0:
        return None

    header = header[:p]

    footer = b""

    f.seek(0, 2)
    fl = f.tell()

    i = 0
    p = -1
    while i < maxChunks and p < 0 and fl > 0:
        pos = fl - i * chunkSize
        if pos < 0:
            chunkSize += pos
            pos = 0
        f.seek(pos, 0)
        i += 1
        footer = f.read(chunkSize) + footer
        p = footer.find("</{}>".format(key).encode("utf-8"))

    if p < 0:
        raise BaseException("</{}> nicht in den letzten {} Bytes der Datei {} gefunden.".format(key, maxChunks * chunkSize, inputfile))

    parser = et.XMLParser(remove_blank_text=True)
    data = header + footer[(p + 3 + len(key)):]
    nba = et.fromstring(data, parser)

    ts = nba.find('.//portionskennung/AX_Portionskennung/datum', nba.nsmap)
    if ts is None:
        return None

    try:
        return datetime.strptime(ts.text, '%Y-%m-%dT%H:%M:%SZ').strftime("%Y%m%dT%H%M%SZ")
    except:
        return datetime.strptime(ts.text, '%Y-%m-%dT%H:%M:%S.%fZ').strftime("%Y%m%dT%H%M%SZ")

if __name__ == '__main__':
    import sys
    import os

    def usage(msg=None):
        print("Usage: {} eingabe".format(sys.argv[0]), file=sys.stderr)
        if msg is not None:
            print("  error: {}".format(msg), file=sys.stderr)
        print("  eingabe: Eingabedatei", file=sys.stderr)
        sys.exit(1)

    if len(sys.argv) != 2:
        usage()

    inputfile = sys.argv[1]

    if not os.path.exists(inputfile):
        sys.exit(1)

    try:
        date = getdate(inputfile)
        if date is None:
            sys.exit(2)
        print(date)
    except Exception as e:
        usage(str(e))
