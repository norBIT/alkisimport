#!/usr/bin/env python3

"""
***************************************************************************
    quittierung.py
    --------------
    Date                 : Feb 2022
    Copyright            : (C) 2022-2023 by Jürgen Fischer
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
import sys
import os
from datetime import datetime
from lxml import etree as et
from copy import deepcopy

parser = et.XMLParser(remove_blank_text=True)

chunkSize = 1000
key = "geaenderteObjekte"


def usage(msg=None):
    print("Usage: {} verzeichnis eingabe gml_id impid status".format(sys.argv[0]), file=sys.stderr)
    if msg is not None:
        print("  error: {}".format(msg), file=sys.stderr)
    print("  verzeichnis: Quittierungsverzeichnis", file=sys.stderr)
    print("  eingabe: zu quittierende Eingabedatei", file=sys.stderr)
    print("  gml_id: Kennung der Portionsquittierung", file=sys.stderr)
    print("  impid: Quittierungskennung", file=sys.stderr)
    print("  status: true, wenn Portion erfolgreich verarbeitet wurde, sonst false", file=sys.stderr)
    sys.exit(1)


if len(sys.argv) != 6:
    usage()

outputdir, inputfile, gml_id, impid, status = sys.argv[1:]

if not os.path.exists(inputfile):
    usage("eingabe: Datei {} existiert nicht".format(inputfile))

if status not in ['true', 'false']:
    usage("status: true oder false erwartet")

f = open(inputfile, "rb")

header = b""
i = 0
p = -1
while i < 10 and p < 0:
    header += f.read(chunkSize)
    i += 1
    p = header.find("<{}>".format(key).encode("utf-8"))

if p < 0:
    usage("<{}> nicht in den ersten {} Bytes der Datei {} gefunden.".format(key, 10 * chunkSize, inputfile))

header = header[:p]

footer = b""

f.seek(0, 2)
fl = f.tell()

i = 0
p = -1
while i < 10 and p < 0 and fl > 0:
    pos = fl - i * chunkSize
    if pos < 0:
        chunkSize += pos
        pos = 0
    f.seek(pos, 0)
    i += 1
    footer = f.read(chunkSize) + footer
    p = footer.find("</{}>".format(key).encode("utf-8"))

if p < 0:
    usage("</{}> nicht in den letzten {} Bytes der Datei {} gefunden.".format(key, 10 * chunkSize, inputfile))

nba = et.fromstring(header + footer[(p + 3 + len(key)):], parser)

if not nba.tag.endswith("AX_NutzerbezogeneBestandsdatenaktualisierung_NBA"):
    usage("AX_NutzerbezogeneBestandsdatenaktualisierung_NBA auf oberster Ebene erwartet. {} gefunden.".format(nba.tag))

outputfile = os.path.join(outputdir, "{}_{}_NBA_Quittierung_ID_{}.xml".format(
    nba.find('.//portionskennung/AX_Portionskennung/profilkennung', nba.nsmap).text,
    datetime.strptime(
        nba.find('.//portionskennung/AX_Portionskennung/datum', nba.nsmap).text,
        '%Y-%m-%dT%H:%M:%SZ'
    ).strftime("%Y%m%dT%H%M%S"),
    impid
))

if os.path.exists(outputfile):
    q = et.parse(outputfile, parser=parser).getroot()

    if status == "false":
        q.find('.//gesamtNBAErfolgreich', nba.nsmap).text = status

    last = q.findall("portionNBAErfolgreich", namespaces=q.nsmap)[-1]

else:
    q = et.Element("AX_NBAQuittierung", nsmap=nba.nsmap)

    e = nba.find('.//allgemeineAngaben/AX_K_Benutzungsergebnis/empfaenger', nba.nsmap)
    if e is not None:
        q.append(e)

    af = et.SubElement(q, "ausgabeform", nsmap=nba.nsmap)
    af.text = "application/xml"
    q.append(af)

    for n in [
        './/portionskennung/AX_Portionskennung/profilkennung',
        './/antragsnummer',
        './/auftragsnummer'
    ]:
        e = nba.find(n, nba.nsmap)
        if e is not None:
            q.append(deepcopy(e))

    erfolg = et.SubElement(q, "gesamtNBAErfolgreich", nsmap=nba.nsmap)
    erfolg.text = status
    q.append(erfolg)

    last = erfolg

    protokoll = et.SubElement(q, 'uebernahmeprotokoll', nsmap=nba.nsmap)
    protokoll.text = 'a.A.'
    q.append(protokoll)

erfolgreich = et.SubElement(q, "portionNBAErfolgreich", nsmap=nba.nsmap)

portion = et.SubElement(erfolgreich, 'AX_Portion_Erfolgreich', attrib={"{%s}id" % nba.nsmap['gml']: gml_id}, nsmap=nba.nsmap)
portion.append(nba.find('.//portionskennung', nba.nsmap))

pe = et.SubElement(portion, 'erfolgreich', nsmap=nba.nsmap)
pe.text = status
portion.append(pe)

protokoll = et.SubElement(portion, 'uebernahmeprotokoll', nsmap=nba.nsmap)
protokoll.text = 'Portion ohne Fehlermeldung übernommen' if status == "true" else 'Fehlermeldungen beim Import der Portion'
portion.append(protokoll)

last.addnext(erfolgreich)

f = open(outputfile, "wb")
f.write(et.tostring(q, pretty_print=True, xml_declaration=True, encoding="UTF-8"))
f.close()
