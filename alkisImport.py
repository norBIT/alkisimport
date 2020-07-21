#! /usr/bin/env python
# -*- coding: utf8 -*-

from __future__ import unicode_literals

"""
***************************************************************************
    alkisImport.py
    ---------------------
    Date                 : Sep 2012
    Copyright            : (C) 2012-2020 by Jürgen E. Fischer
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

from builtins import str
from io import open

import sip
for c in ["QDate", "QDateTime", "QString", "QTextStream", "QTime", "QUrl", "QVariant"]:
        sip.setapi(c, 2)

import sys
import os
import fnmatch
import traceback
import gzip
import re

from zipfile import ZipFile
from itertools import islice

try:
    from PyQt4.QtCore import QSettings, QProcess, QFile, QDir, QFileInfo, QIODevice, Qt, QDateTime, QElapsedTimer, QByteArray
    from PyQt4.QtGui import QApplication, QDialog, QIcon, QFileDialog, QMessageBox, QFont, QIntValidator, QListWidgetItem
    from PyQt4.QtSql import QSqlDatabase, QSqlQuery
    from PyQt4 import uic
except ImportError:
    from PyQt5.QtCore import QSettings, QProcess, QFile, QDir, QFileInfo, QIODevice, Qt, QDateTime, QElapsedTimer, QByteArray
    from PyQt5.QtGui import QIcon, QFont, QIntValidator
    from PyQt5.QtWidgets import QApplication, QDialog, QFileDialog, QMessageBox, QListWidgetItem
    from PyQt5.QtSql import QSqlDatabase, QSqlQuery
    from PyQt5 import uic

BASEDIR = os.path.dirname(__file__)
sys.path.insert(0, BASEDIR)
alkisImportDlgBase = uic.loadUiType(os.path.join(BASEDIR, 'alkisImportDlg.ui'))[0]
aboutDlgBase = uic.loadUiType(os.path.join(BASEDIR, 'about.ui'))[0]
sys.path.pop(0)

# Felder als String interpretieren (d.h. führende Nullen nicht abschneiden)
os.putenv("GML_FIELDTYPES", "ALWAYS_STRING")

# Warnen, wenn numerische Felder mit alphanumerischen Werten gefüllt werden sollen
os.putenv("OGR_SETFIELD_NUMERIC_WARNING", "ON")

# Mindestlänge für Kreisbogensegmente
os.putenv("OGR_ARC_MINLENGTH", "0.1")

# Verhindern, dass andere GML-Treiber übernehmen
os.putenv("OGR_SKIP", "GML,SEGY")

# Headerkennungen die NAS-Daten identifizieren
os.putenv("NAS_INDICATOR", "NAS-Operationen;AAA-Fachschema;aaa.xsd;aaa-suite;adv/gid/6.0")

os.putenv("PGCLIENTENCODING", "UTF8")

os.putenv("NAS_GFS_TEMPLATE", os.path.join(BASEDIR, "alkis-schema.gfs"))

os.putenv("NAS_NO_RELATION_LAYER", "YES")
os.putenv("NAS_SKIP_CORRUPTED_FEATURES", "YES")
os.putenv("TABLES", "aa_aktivitaet,aa_antrag,aa_antragsgebiet,aa_meilenstein,aa_projektsteuerung,aa_vorgang,ap_darstellung,ap_fpo,ap_kpo_3d,ap_lpo,ap_lto,ap_ppo,ap_pto,au_koerperobjekt_3d,au_mehrfachlinienobjekt_3d,au_punkthaufenobjekt_3d,au_trianguliertesoberflaechenobjekt_3d,au_umringobjekt_3d,ax_abgeleitetehoehenlinie,ax_abschlussflaeche3d,ax_abschnitt,ax_anderefestlegungnachstrassenrecht,ax_anderefestlegungnachwasserrecht,ax_anschrift,ax_ast,ax_aufnahmepunkt,ax_bahnstrecke,ax_bahnverkehr,ax_bahnverkehrsanlage,ax_baublock,ax_bauraumoderbodenordnungsrecht,ax_bauraumoderbodenordnungsrechtgrundbuch,ax_bauteil,ax_bauteil3d,ax_bauwerk3d,ax_bauwerkimgewaesserbereich,ax_bauwerkimverkehrsbereich,ax_bauwerkoderanlagefuerindustrieundgewerbe,ax_bauwerkoderanlagefuersportfreizeitunderholung,ax_benutzer,ax_benutzergruppemitzugriffskontrolle,ax_benutzergruppenba,ax_bergbaubetrieb,ax_besondereflurstuecksgrenze,ax_besonderegebaeudelinie,ax_besondererbauwerkspunkt,ax_besonderergebaeudepunkt,ax_besonderertopographischerpunkt,ax_bewertung,ax_bodenflaeche3d,ax_bodenschaetzung,ax_boeschungkliff,ax_boeschungsflaeche,ax_buchungsblatt,ax_buchungsblattbezirk,ax_buchungsstelle,ax_bundesland,ax_dachflaeche3d,ax_dammwalldeich,ax_denkmalschutzrecht,ax_dhmgitter,ax_dienststelle,ax_duene,ax_einrichtungenfuerdenschiffsverkehr,ax_einrichtunginoeffentlichenbereichen,ax_einschnitt,ax_fahrbahnachse,ax_fahrwegachse,ax_felsenfelsblockfelsnadel,ax_fenster3d,ax_firstlinie,ax_flaeche3d,ax_flaechebesondererfunktionalerpraegung,ax_flaechegemischternutzung,ax_fliessgewaesser,ax_flugverkehr,ax_flugverkehrsanlage,ax_flurstueck,ax_flurstueckgrundbuch,ax_forstrecht,ax_fortfuehrungsfall,ax_fortfuehrungsfallgrundbuch,ax_fortfuehrungsnachweisdeckblatt,ax_friedhof,ax_gebaeude,ax_gebaeudeausgestaltung,ax_gebaeudeinstallation3d,ax_gebiet_bundesland,ax_gebiet_kreis,ax_gebiet_nationalstaat,ax_gebiet_regierungsbezirk,ax_gebiet_verwaltungsgemeinschaft,ax_gebietsgrenze,ax_gehoelz,ax_gemarkung,ax_gemarkungsteilflur,ax_gemeinde,ax_gemeindeteil,ax_georeferenziertegebaeudeadresse,ax_gewaesserachse,ax_gewaessermerkmal,ax_gewaesserstationierungsachse,ax_gewann,ax_gleis,ax_grablochderbodenschaetzung,ax_grenzpunkt,ax_grenzuebergang,ax_hafen,ax_hafenbecken,ax_halde,ax_heide,ax_heilquellegasquelle,ax_historischesbauwerkoderhistorischeeinrichtung,ax_historischesflurstueck,ax_historischesflurstueckalb,ax_historischesflurstueckohneraumbezug,ax_hoehenfestpunkt,ax_hoehenlinie,ax_hoehleneingang,ax_industrieundgewerbeflaeche,ax_insel,ax_kanal,ax_klassifizierungnachstrassenrecht,ax_klassifizierungnachwasserrecht,ax_kleinraeumigerlandschaftsteil,ax_kommunalesgebiet,ax_kommunalesteilgebiet,ax_kondominium,ax_kreisregion,ax_lagebezeichnungkatalogeintrag,ax_lagebezeichnungmithausnummer,ax_lagebezeichnungmitpseudonummer,ax_lagebezeichnungohnehausnummer,ax_lagefestpunkt,ax_landschaft,ax_landwirtschaft,ax_leitung,ax_material3d,ax_meer,ax_moor,ax_musterundvergleichsstueck,ax_namensnummer,ax_nationalstaat,ax_naturumweltoderbodenschutzrecht,ax_netzknoten,ax_nullpunkt,ax_ortslage,ax_person,ax_personengruppe,ax_platz,ax_polder,ax_punkt3d,ax_punktkennunguntergegangen,ax_punktkennungvergleichend,ax_punktortag,ax_punktortau,ax_punktortta,ax_punktwolke3d,ax_referenzstationspunkt,ax_regierungsbezirk,ax_reservierung,ax_schifffahrtsliniefaehrverkehr,ax_schiffsverkehr,ax_schleuse,ax_schutzgebietnachnaturumweltoderbodenschutzrecht,ax_schutzgebietnachwasserrecht,ax_schutzzone,ax_schwere,ax_schwerefestpunkt,ax_seilbahnschwebebahn,ax_sicherungspunkt,ax_sickerstrecke,ax_siedlungsflaeche,ax_skizze,ax_soll,ax_sonstigervermessungspunkt,ax_sonstigesbauwerkodersonstigeeinrichtung,ax_sonstigesrecht,ax_sportfreizeitunderholungsflaeche,ax_stehendesgewaesser,ax_strasse,ax_strassenachse,ax_strassenverkehr,ax_strassenverkehrsanlage,ax_strukturlinie3d,ax_sumpf,ax_tagebaugrubesteinbruch,ax_tagesabschnitt,ax_testgelaende,ax_textur3d,ax_topographischelinie,ax_transportanlage,ax_tuer3d,ax_turm,ax_unlandvegetationsloseflaeche,ax_untergeordnetesgewaesser,ax_vegetationsmerkmal,ax_verband,ax_vertretung,ax_verwaltung,ax_verwaltungsgemeinschaft,ax_vorratsbehaelterspeicherbauwerk,ax_wald,ax_wandflaeche3d,ax_wasserlauf,ax_wasserspiegelhoehe,ax_weg,ax_wegpfadsteig,ax_wirtschaftlicheeinheit,ax_wohnbauflaeche,ax_wohnplatz,ks_bauraumoderbodenordnungsrecht,ks_bauwerkanlagenfuerverundentsorgung,ks_bauwerkimgewaesserbereich,ks_bauwerkoderanlagefuerindustrieundgewerbe,ks_einrichtungenundanlageninoeffentlichenbereichen,ks_einrichtungimbahnverkehr,ks_einrichtungimstrassenverkehr,ks_einrichtunginoeffentlichenbereichen,ks_kommunalerbesitz,ks_sonstigesbauwerk,ks_sonstigesbauwerkodersonstigeeinrichtung,ks_strassenverkehrsanlage,ks_topographischeauspraegung,ks_vegetationsmerkmal,ks_verkehrszeichen,lb_binnengewaesser,lb_eis,lb_festgestein,lb_hochbauundbaulichenebenflaeche,lb_holzigevegetation,lb_krautigevegetation,lb_lockermaterial,lb_meer,lb_tiefbau,ln_abbau,ln_aquakulturundfischereiwirtschaft,ln_bahnverkehr,ln_bestattung,ln_flugverkehr,ln_forstwirtschaft,ln_freiluftundnaherholung,ln_freizeitanlage,ln_gewerblichedienstleistungen,ln_industrieundverarbeitendesgewerbe,ln_kulturundunterhaltung,ln_lagerung,ln_landwirtschaft,ln_oeffentlicheeinrichtungen,ln_ohnenutzung,ln_schiffsverkehr,ln_schutzanlage,ln_sportanlage,ln_strassenundwegeverkehr,ln_versorgungundentsorgung,ln_wasserwirtschaft,ln_wohnnutzung")

os.putenv("LIST_ALL_TABLES", "YES")


def which(program):
    def is_exe(fpath):
        return os.path.isfile(fpath) and os.access(fpath, os.X_OK)

    fpath, fname = os.path.split(program)
    if fpath:
        if is_exe(program):
            return program
    else:
        for path in os.environ["PATH"].split(os.pathsep):
            exe_file = os.path.join(path, program)
            if is_exe(exe_file):
                return exe_file

    return None


def getFiles(pattern, directory):
    files = []

    d = QDir(directory)
    for f in d.entryList():
        if f == "." or f == "..":
            continue

        fi = QFileInfo(d, f)

        if fi.isDir():
            files.extend(getFiles(pattern, fi.filePath()))
        elif re.search(pattern, f, re.IGNORECASE):
            files.append(os.path.abspath(fi.filePath()))

    return files


class ProcessError(Exception):
    def __init__(self, msg):
        self.msg = msg

    def __str__(self):
        return str(self.msg)


class aboutDlg(QDialog, aboutDlgBase):
    def __init__(self):
        QDialog.__init__(self)
        self.setupUi(self)


class alkisImportDlg(QDialog, alkisImportDlgBase):

    def __init__(self):
        QDialog.__init__(self)
        self.setupUi(self)
        self.setWindowIcon(QIcon('logo.svg'))
        self.setWindowFlags(Qt.WindowMinimizeButtonHint)

        s = QSettings("norBIT", "norGIS-ALKIS-Import")

        self.leSERVICE.setText(s.value("service", ""))
        self.leHOST.setText(s.value("host", ""))
        self.lePORT.setText(s.value("port", "5432"))
        self.leDBNAME.setText(s.value("dbname", ""))
        self.leUID.setText(s.value("uid", ""))
        self.lePWD.setText(s.value("pwd", ""))
        self.leSCHEMA.setText(s.value("schema", "public"))
        self.lePGSCHEMA.setText(s.value("pgschema", "public"))
        self.lePARENTSCHEMA.setText(s.value("parentschema", ""))
        self.leGT.setText(s.value("gt", "20000"))
        self.leGT.setValidator(QIntValidator(-1, 99999999))

        self.cbxSkipFailures.setChecked(s.value("skipfailures", False, type=bool))

        checked = s.value("files_sf", []) or []
        for i in s.value("files", []) or []:
            item = QListWidgetItem(i)
            if not self.cbxSkipFailures.isChecked():
                item.setFlags(item.flags() | Qt.ItemIsUserCheckable)
                item.setCheckState(Qt.Checked if i in checked else Qt.Unchecked)
            self.lstFiles.addItem(item)

        self.cbFnbruch.setCurrentIndex(0 if s.value("fnbruch", True, type=bool) else 1)
        self.cbPgVerdraengen.setCurrentIndex(1 if s.value("pgverdraengen", False, type=bool) else 0)
        self.cbxUseCopy.setChecked(s.value("usecopy", True, type=bool))
        self.cbxCreate.setChecked(False)
        self.cbxClean.setChecked(False)
        self.cbxHistorie.setDisabled(True)
        self.cbxHistorie.setChecked(s.value("historie", True, type=bool))

        self.cbEPSG.addItem("UTM32N", "25832")
        self.cbEPSG.addItem("UTM33N", "25833")
        self.cbEPSG.addItem("3GK2 (BW/SL)", "131466")
        self.cbEPSG.addItem("3GK3 (BW)", "131467")
        self.cbEPSG.addItem("3GK4 (BY)", "131468")
        self.cbEPSG.addItem("DHDN GK2 (BW/SL)", "31466")
        self.cbEPSG.addItem("DHDN GK3 (BW)", "31467")
        self.cbEPSG.addItem("DHDN GK4 (BY)", "31468")
        self.cbEPSG.addItem("Soldner-Berlin (vortransformiert)", "3068")
        self.cbEPSG.addItem("Soldner-Berlin (transformieren)", "13068")
        self.cbEPSG.setCurrentIndex(self.cbEPSG.findData(s.value("epsg", "25832")))

        self.pbAdd.clicked.connect(self.selFiles)
        self.pbAddDir.clicked.connect(self.selDir)
        self.pbRemove.clicked.connect(self.rmFiles)
        self.pbSelectAll.clicked.connect(self.lstFiles.selectAll)
        self.pbLoad.clicked.connect(self.loadList)
        self.pbSave.clicked.connect(self.saveList)
        self.lstFiles.itemSelectionChanged.connect(self.selChanged)
        self.cbxSkipFailures.toggled.connect(self.skipFailuresToggled)

        self.pbStart.clicked.connect(self.run)
        self.pbLoadLog.clicked.connect(self.loadLog)
        self.pbSaveLog.clicked.connect(self.saveLog)
        self.pbClearLog.clicked.connect(self.clearLog)
        self.pbAbout.clicked.connect(self.about)
        self.pbClose.clicked.connect(self.accept)
        self.pbProgress.setVisible(False)
        self.pbProgressFile.setVisible(False)

        f = QFont("Monospace")
        f.setStyleHint(QFont.TypeWriter)
        self.lwProtocol.setFont(f)
        self.lwProtocol.setUniformItemSizes(True)

        self.status("")

        self.restoreGeometry(s.value("geometry", QByteArray(), type=QByteArray))
        self.splitter.restoreState(s.value("splitter", QByteArray(), type=QByteArray))

        self.canceled = False
        self.running = False
        self.skipScroll = False
        self.logqry = None

        self.reFilter = []

    def loadRe(self):
        f = open("re", "r", encoding="utf-8")
        while True:
            line = list(islice(f, 50))
            if not line:
                break

            self.reFilter.append(re.compile("|".join([x.replace('\n', '') for x in line])))

        f.close()

        if not self.reFilter:
            raise ProcessError("reFilter not set")

    def memunits(self, s):
        u = " Bytes"

        if s > 10240:
            s /= 1024
            u = "kiB"

        if s > 10240:
            s /= 1024
            u = "MiB"

        if s > 10240:
            s /= 1024
            u = "GiB"

        return "{}{}".format(int(s), u)

    def timeunits(self, t):
        ms = t % 1000

        t = t / 1000

        s = t % 60
        m = (t / 60) % 60
        h = (t / 60 / 60) % 24
        d = t / 60 / 60 / 24

        r = ""
        if d >= 1:
            r += "{}t".format(int(d))
        if h >= 1:
            r += "{}h".format(int(h))
        if m >= 1:
            r += "{}m".format(int(m))
        if s >= 1:
            r += "{}s".format(int(s))
        if r == "":
            r = "{}ms".format(ms)

        return r

    def selFiles(self):
        s = QSettings("norBIT", "norGIS-ALKIS-Import")
        lastDir = s.value("lastDir", ".")

        files = QFileDialog.getOpenFileNames(self, "NAS-Dateien wählen", lastDir, "NAS-Dateien (*.xml *.xml.gz *.zip)")
        if isinstance(files, tuple):
            files = files[0]
        if files is None:
            return

        dirs = []

        for f in files:
            f = os.path.abspath(f)
            item = QListWidgetItem(f)
            if not self.cbxSkipFailures.isChecked():
                item.setFlags(item.flags() | Qt.ItemIsUserCheckable)
                item.setCheckState(Qt.Unchecked)
            self.lstFiles.addItem(item)
            dirs.append(os.path.dirname(f))

        s.setValue("lastDir", os.path.commonprefix(dirs))

    def selDir(self):
        s = QSettings("norBIT", "norGIS-ALKIS-Import")
        lastDir = s.value("lastDir", ".")

        d = QFileDialog.getExistingDirectory(self, "Verzeichnis mit NAS-Dateien wählen", lastDir)
        if d is None or d == '':
            QMessageBox.critical(self, "norGIS-ALKIS-Import", "Kein eindeutiges Verzeichnis gewählt!", QMessageBox.Cancel)
            return

        s.setValue("lastDir", d)

        QApplication.setOverrideCursor(Qt.WaitCursor)

        self.status("Verzeichnis wird durchsucht...")

        for f in sorted(getFiles("\\.(xml|xml\\.gz|zip)$", d)):
            item = QListWidgetItem(f)
            if not self.cbxSkipFailures.isChecked():
                item.setFlags(item.flags() | Qt.ItemIsUserCheckable)
                item.setCheckState(Qt.Unchecked)
            self.lstFiles.addItem(item)

        self.status("")

        QApplication.restoreOverrideCursor()

    def rmFiles(self):
        for item in self.lstFiles.selectedItems():
            self.lstFiles.takeItem(self.lstFiles.row(item))

    def saveList(self):
        fn = QFileDialog.getSaveFileName(self, "Liste wählen", ".", "Dateilisten (*.lst)")
        if isinstance(fn, tuple):
            fn = fn[0]
        if fn is None or fn == "":
            return

        f = open(fn, "w", encoding="utf-8")

        for i in range(self.lstFiles.count()):
            f.write(self.lstFiles.item(i).text())
            f.write("\n")

        f.close()

    def loadList(self):
        fn = QFileDialog.getOpenFileName(self, "Liste wählen", ".", "Dateilisten (*.lst)")
        if isinstance(fn, tuple):
            fn = fn[0]
        if fn is None or fn == "":
            return

        f = open(fn, "r", encoding="utf-8")
        for line in f.read().splitlines():
            if not os.path.isabs(line):
                line = os.path.join(os.path.dirname(fn), line)
            self.lstFiles.addItem(os.path.abspath(line))
        f.close()

    def selChanged(self):
        self.pbRemove.setDisabled(len(self.lstFiles.selectedItems()) == 0)

    def status(self, msg):
        self.leStatus.setText(msg)
        app.processEvents()

    def log(self, msg):
        self.logDb(msg)
        self.logDlg(msg)

    def logDlg(self, msg, ts=None):
        if len(msg) > 300:
            msg = msg[:300] + "..."

        if not ts:
            ts = QDateTime.currentDateTime()

        for m in msg.splitlines():
            m = m.rstrip()
            if m == "":
                continue
            self.lwProtocol.addItem(ts.toString(Qt.ISODate) + " " + m)

        app.processEvents()
        if not self.skipScroll:
            self.lwProtocol.scrollToBottom()

    def logDb(self, msg):
        if not self.logqry:
            return

        self.logqry.bindValue(0, msg)

        if not self.logqry.exec_():
            err = self.logqry.lastError().text()
            logqry = self.logqry
            self.logqry = None

            self.log("Datenbank-Protokollierung fehlgeschlagen [{}: {}]".format(err, msg))
            self.logqry = logqry

    def loadLog(self):
        QApplication.setOverrideCursor(Qt.WaitCursor)
        self.lwProtocol.setUpdatesEnabled(False)

        conn = self.connectDb()
        if not conn:
            QMessageBox.critical(self, "norGIS-ALKIS-Import", "Konnte keine Datenbankverbindung aufbauen!", QMessageBox.Cancel)
            return

        qry = self.db.exec_("SELECT ts,msg FROM alkis_importlog ORDER BY n")
        if not qry:
            QMessageBox.critical(self, "norGIS-ALKIS-Import", "Konnte Protokoll nicht abfragen!", QMessageBox.Cancel)
            return

        self.skipScroll = True

        while qry.next():
            if self.keep(qry.value(1)):
                self.logDlg(qry.value(1), qry.value(0))

        self.skipScroll = False

        self.logDlg("Protokoll geladen.")

        self.lwProtocol.scrollToBottom()

        self.lwProtocol.setUpdatesEnabled(True)
        QApplication.restoreOverrideCursor()

    def saveLog(self):
        save = QFileDialog.getSaveFileName(self, "Protokolldatei angeben", ".", "Protokoll-Dateien (*.log)")
        if isinstance(save, tuple):
            save = save[0]
        if save is None:
            return

        f = open(save, "w", encoding="utf-8")

        for i in range(0, self.lwProtocol.count()):
            f.write(self.lwProtocol.item(i).text())
            f.write("\n")

        f.close()

    def clearLog(self):
        self.lwProtocol.clear()

    def skipFailuresToggled(self):
        for i in range(self.lstFiles.count()):
            item = self.lstFiles.item(i)
            if self.cbxSkipFailures.isChecked():
                item.setFlags(item.flags() & ~Qt.ItemIsUserCheckable)
                item.setData(Qt.CheckStateRole, None)
            else:
                item.setFlags(item.flags() | Qt.ItemIsUserCheckable)
                item.setCheckState(Qt.Unchecked)
        self.update()

    def about(self):
        dlg = aboutDlg()
        dlg.exec_()

    def accept(self):
        if not self.running:
            s = QSettings("norBIT", "norGIS-ALKIS-Import")
            s.setValue("geometry", self.saveGeometry())
            s.setValue("splitter", self.splitter.saveState())
            QDialog.accept(self)

    def closeEvent(self, e):
        if not self.running:
            e.accept()
            return

        self.cancel()
        e.ignore()

    def cancel(self):
        if QMessageBox.question(self, "norGIS-ALKIS-Import", "Laufenden Import abbrechen?", QMessageBox.Yes | QMessageBox.No) == QMessageBox.Yes:
            self.canceled = True

    def keep(self, l):
        if not self.reFilter:
            self.loadRe()

        for r in self.reFilter:
            if r.match(l):
                return False

        return True

    def processOutputOut(self, current, output):
        if output.isEmpty():
            return current

        current = self.processOutput(current, output)

        if current == "0" or current[:2] == "0.":
            if not self.pbProgressFile.isVisible():
                self.pbProgressFile.setVisible(True)
                self.pbProgressFile.setRange(0, 1000)

            p = current

            while p.startswith("."):
                p = p[1:]

            progress = 0

            for i in range(0, 100, 10):
                if p.startswith(str(i)):
                    progress = i * 10
                    p = p[len(str(i)):]

                    while p.startswith("."):
                        progress += 25
                        p = p[1:]

            self.pbProgressFile.setValue(progress)
            if progress == 1000:
                self.pbProgressFile.setVisible(False)

            app.processEvents()

        return current

    def processOutputErr(self, current, output):
        if output.isEmpty():
            return current

        return self.processOutput(current, output)

    def processOutput(self, current, output):
        if output.isEmpty():
            return current

        if not current:
            current = ""

        try:
            r = output.data().decode('utf-8')
        except UnicodeDecodeError:
            r = output.data().decode('latin-1')

        lines = r.split("\n")

        if not r.endswith("\n"):
            lastline = lines.pop()
        else:
            lastline = ""

        if current != "" and len(lines) > 0:
            if r.startswith("\n"):
                lines.prepend(current)
            else:
                lines[0] = current + lines[0]
            current = ""

        for l in lines:
            if self.keep(l):
                self.log("> {}|".format(l.rstrip()))
            else:
                self.logDb(l)

        return current + lastline

    def runProcess(self, args):
        self.logDb("BEFEHL: '{}'".format(re.sub('password=\\S+', 'password=*removed*', "' '".join(args))))

        currout = ""
        currerr = ""

        p = QProcess()
        p.start(args[0], args[1:])

        i = 0
        while not p.waitForFinished(500):
            i += 1
            self.alive.setText(self.alive.text()[:-1] + ("-\\|/")[i % 4])
            app.processEvents()

            currout = self.processOutputOut(currout, p.readAllStandardOutput())
            currerr = self.processOutputErr(currerr, p.readAllStandardError())

            if p.state() != QProcess.Running:
                if self.canceled:
                    self.log("Prozeß abgebrochen.")
                break

            if self.canceled:
                self.log("Prozeß wird abgebrochen.")
                p.kill()

        currout = self.processOutputOut(currout, p.readAllStandardOutput())
        if currout and currout != "":
            self.log("E {}".format(currout))

        currerr = self.processOutputErr(currerr, p.readAllStandardError())
        if currerr and currerr != "":
            self.log("E {}".format(currerr))

        ok = False
        if p.exitStatus() == QProcess.NormalExit:
            if p.exitCode() == 0:
                ok = True
            else:
                self.log("Fehler bei Prozeß: {}".format(p.exitCode()))
        else:
            self.log("Prozeß abgebrochen: {}".format(p.exitCode()))

        self.logDb("EXITCODE: {}".format(p.exitCode()))

        p.close()

        self.pbProgressFile.setVisible(False)

        return ok

    def runSQLScript(self, conn, fn, parallel=False):
        return self.runProcess([
            self.psql,
            "-v", "alkis_epsg={}".format(3068 if self.epsg == 13068 else self.epsg),
            "-v", "alkis_schema={}".format(self.schema),
            "-v", "postgis_schema={}".format(self.pgschema),
            "-v", "parent_schema={}".format(self.parentschema if self.parentschema else self.schema),
            "-v", "alkis_fnbruch={}".format("true" if self.fnbruch else "false"),
            "-v", "alkis_pgverdraengen={}".format("true" if self.pgverdraengen else "false"),
            "-v", "alkis_hist={}".format("true" if self.historie else "false"),
            "-v", "ON_ERROR_STOP=1",
            "-v", "ECHO=errors",
            "--quiet",
            "--no-psqlrc",
            "-f", fn, conn])

    def run(self):
        self.importALKIS()

    def connectDb(self):
        if self.leSERVICE.text() != '':
            conn = "service={} ".format(self.leSERVICE.text())
        else:
            if self.leHOST.text() != '':
                conn = "host={} port={} ".format(self.leHOST.text(), self.lePORT.text())
            else:
                conn = ""

        conn += "dbname={} user='{}' password='{}'".format(self.leDBNAME.text(), self.leUID.text(), self.lePWD.text())

        self.db = QSqlDatabase.addDatabase("QPSQL")
        self.db.setConnectOptions(conn)
        if not self.db.open():
            self.log("Konnte Datenbankverbindung nicht aufbauen! [{}]".format(self.db.lastError().text()))
            return None

        self.db.exec_("SET STANDARD_CONFORMING_STRINGS TO ON")

        self.schema = self.leSCHEMA.text()
        self.pgschema = self.lePGSCHEMA.text()

        qry = self.db.exec_("SELECT 1 FROM pg_namespace WHERE nspname='{}'".format(self.schema.replace("'", "''")))
        if not qry:
            self.log("Konnte Schema nicht überprüfen! [{}]".format(qry.lastError().text()))
            return None

        if not qry.next():
            if not self.db.exec_("CREATE SCHEMA \"{}\"".format(self.schema.replace('"', '""'))):
                self.log("Konnte Schema nicht erstellen!")
                return None

        self.db.exec_("SET search_path = \"{}\", \"{}\", public".format(self.schema, self.pgschema))

        return conn

    def rund(self, conn, dir):
        matches = []
        for root, dirnames, filenames in os.walk("{}.d".format(dir)):
            for filename in fnmatch.filter(filenames, '*.sql'):
                matches.append(os.path.join(root, filename))

        for f in sorted(matches):
            self.status("{} wird gestartet...".format(f))
            if not self.runSQLScript(conn, f):
                self.log("{} gescheitert.".format(f))
                return False

            self.log("{} ausgeführt.".format(f))

        return True

    def importALKIS(self):
        if 'CPL_DEBUG' in os.environ:
            self.log("Debug-Ausgaben aktiv.")

        files = []
        for i in range(self.lstFiles.count()):
            files.append(self.lstFiles.item(i).text())

        s = QSettings("norBIT", "norGIS-ALKIS-Import")
        s.setValue("service", self.leSERVICE.text())
        s.setValue("host", self.leHOST.text())
        s.setValue("port", self.lePORT.text())
        s.setValue("dbname", self.leDBNAME.text())
        s.setValue("uid", self.leUID.text())
        s.setValue("pwd", self.lePWD.text())
        s.setValue("schema", self.leSCHEMA.text())
        s.setValue("pgschema", self.lePGSCHEMA.text())
        s.setValue("parentschema", self.lePARENTSCHEMA.text())
        self.schema = self.leSCHEMA.text()
        self.pgschema = self.lePGSCHEMA.text()
        self.parentschema = self.lePARENTSCHEMA.text()
        s.setValue("gt", self.leGT.text())
        s.setValue("files", files)

        checked = []
        for i in range(0, self.lstFiles.count()):
            item = self.lstFiles.item(i)
            if item.checkState() == Qt.Checked:
                checked.append(item.text())

        s.setValue("files_sf", checked)

        s.setValue("skipfailures", self.cbxSkipFailures.isChecked())
        s.setValue("usecopy", self.cbxUseCopy.isChecked())

        self.fnbruch = self.cbFnbruch.currentIndex() == 0
        s.setValue("fnbruch", self.fnbruch)

        self.pgverdraengen = self.cbPgVerdraengen.currentIndex() == 1
        s.setValue("pgverdraengen", self.pgverdraengen)

        self.historie = self.cbxHistorie.isChecked()
        s.setValue("historie", self.historie)

        self.epsg = int(self.cbEPSG.itemData(self.cbEPSG.currentIndex()))
        s.setValue("epsg", self.epsg)

        self.running = True
        self.canceled = False

        self.pbStart.setText("Abbruch")
        self.pbStart.clicked.disconnect(self.run)
        self.pbStart.clicked.connect(self.cancel)

        self.pbAdd.setDisabled(True)
        self.pbAddDir.setDisabled(True)
        self.pbRemove.setDisabled(True)
        self.pbLoad.setDisabled(True)
        self.pbSave.setDisabled(True)

        self.lstFiles.itemSelectionChanged.disconnect(self.selChanged)

        QApplication.setOverrideCursor(Qt.WaitCursor)

        while True:
            t0 = QElapsedTimer()
            t0.start()

            self.loadRe()

            self.lstFiles.clearSelection()

            conn = self.connectDb()
            if conn is None:
                break

            self.db.exec_("SET application_name='ALKIS-Import - Frontend'")
            self.db.exec_("SET client_min_messages TO notice")

            qry = self.db.exec_("SELECT COUNT(*) FROM information_schema.tables WHERE table_schema=current_schema() AND table_name='alkis_importlog'")
            if not qry or not qry.next():
                self.log("Konnte Existenz von Protokolltabelle nicht überprüfen.")
                break

            if int(qry.value(0)) == 0:
                qry = self.db.exec_("CREATE TABLE alkis_importlog(n SERIAL PRIMARY KEY, ts timestamp default now(), msg text)")
                if not qry:
                    self.log("Konnte Protokolltabelle nicht anlegen [{}]".format(qry.lastError().text()))
                    break
            elif self.cbxClearProtocol.isChecked():
                qry = self.db.exec_("TRUNCATE alkis_importlog")
                if not qry:
                    self.log("Konnte Protokolltabelle nicht leeren [{}]".format(qry.lastError().text()))
                    break
                self.cbxClearProtocol.setChecked(False)
                self.log("Protokolltabelle gelöscht.")

            self.logqry = QSqlQuery(self.db)
            if not self.logqry.prepare("INSERT INTO alkis_importlog(msg) VALUES (?)"):
                self.log("Konnte Protokollierungsanweisung nicht vorbereiten [{}]".format(qry.lastError().text()))
                self.logqry = None
                break

            self.log("Import-Version: $Format:%h$")

            qry = self.db.exec_("SELECT version()")

            if not qry or not qry.next():
                self.log("Konnte PostgreSQL-Version nicht bestimmen!")
                break

            self.log("Datenbank-Version: {}".format(qry.value(0)))

            m = re.search("PostgreSQL (\\d+)\\.(\\d+)", qry.value(0))
            if not m:
                self.log("PostgreSQL-Version nicht im erwarteten Format")
                break

            if int(m.group(1)) < 8 or (int(m.group(1)) == 8 and int(m.group(2)) < 4):
                self.log("Mindestens PostgreSQL 8.4 erforderlich")
                break

            qry = self.db.exec_("SELECT postgis_version()")
            if not qry or not qry.next():
                self.log("Konnte PostGIS-Version nicht bestimmen!")
                break

            self.log("PostGIS-Version: {}".format(qry.value(0)))

            qry = self.db.exec_("SELECT COUNT(*) FROM information_schema.tables WHERE table_schema=current_schema() AND table_name='ax_flurstueck'")
            if not qry or not qry.next():
                self.log("Konnte Existenz des ALKIS-Schema nicht überprüfen.")
                break

            if not self.cbxCreate.isChecked():
                if int(qry.value(0)) == 0:
                    self.log("Keine ALKIS-Daten vorhanden - Datenbestand muß angelegt werden.")
                    break

                if not qry.exec_("SELECT find_srid(current_schema()::text,'ax_flurstueck','wkb_geometry')") or not qry.next():
                    self.log("Konnte Koordinatensystem der vorhandenen Datenbank nicht bestimmen.")
                    break

                self.epsg = int(qry.value(0))

            self.ogr2ogr = which("ogr2ogr")
            if not self.ogr2ogr:
                self.ogr2ogr = which("ogr2ogr.exe")

            if not self.ogr2ogr:
                self.log("ogr2ogr nicht gefunden!")
                break

            n = self.lwProtocol.count() - 1

            if not self.runProcess([self.ogr2ogr, "--version"]):
                self.log("Konnte ogr2ogr-Version nicht abfragen!")
                break

            for i in range(n, self.lwProtocol.count()):
                m = re.search("GDAL (\\d+)\\.(\\d+)", self.lwProtocol.item(i).text())
                if m:
                    break

            if not m:
                self.log("GDAL-Version nicht gefunden")
                break

            if int(m.group(1)) < 2 or (int(m.group(1)) == 2 and int(m.group(2)) < 3):
                self.log("Mindestens GDAL 2.3 erforderlich")
                break

            GDAL_MAJOR = int(m.group(1))

            self.psql = which("psql")
            if not self.psql:
                self.psql = which("psql.exe")

            if not self.psql:
                self.log("psql nicht gefunden!")
                break

            if not self.runProcess([self.psql, "--version"]):
                self.log("Konnte psql-Version nicht abfragen!")
                break

            try:
                self.status("Bestimme Gesamtgröße des Imports...")

                self.pbProgress.setVisible(True)
                self.pbProgress.setRange(0, self.lstFiles.count())

                sizes = {}

                ts = 0
                for i in range(self.lstFiles.count()):
                    self.pbProgress.setValue(i)
                    item = self.lstFiles.item(i)
                    fn = item.text()

                    if not os.path.isfile(fn):
                        self.log("{} nicht gefunden.".format(fn))
                        continue

                    if fn.lower().endswith(".xml"):
                        s = os.path.getsize(fn)
                        sizes[fn] = s

                    elif fn.lower().endswith(".zip"):
                        extl = -8 if fn[-8:].lower() == ".xml.zip" else -4
                        self.status("{} wird abgefragt...".format(fn))
                        app.processEvents()

                        f = ZipFile(fn, "r")
                        il = f.infolist()
                        if len(il) != 1:
                            raise ProcessError("ZIP-Archiv {} enthält mehr als eine Datei!".format(fn))
                        s = il[0].file_size
                        sizes[fn[:extl] + ".xml"] = s

                    elif fn.lower().endswith(".xml.gz"):
                        self.status("{} wird abgefragt...".format(fn))

                        f = gzip.open(fn)
                        s = 0
                        while True:
                            chunk = f.read(1024 * 1024)
                            if not chunk:
                                break
                            s = s + len(chunk)
                        f.close()
                        sizes[fn[:-3]] = s

                    ts += s

                    if self.canceled:
                        break

                if self.canceled:
                    break

                self.pbProgress.setVisible(False)

                self.log("Gesamtgröße des Imports: {}".format(self.memunits(ts)))

                self.pbProgress.setRange(0, 10000)
                self.pbProgress.setValue(0)

                if self.cbxCreate.isChecked():
                    if self.parentschema == "" or self.parentschema == self.schema:
                        if not self.rund(conn, "precreate"):
                            break

                        self.status("Datenbestand wird angelegt...")
                        if not self.runSQLScript(conn, "alkis-init.sql"):
                            self.log("Anlegen des Datenbestands schlug fehl.")
                            break
                        self.log("Datenbestand angelegt.")

                        if not self.rund(conn, "postcreate"):
                            break
                    else:
                        if not self.rund(conn, "preinherit"):
                            break

                        self.status("Datenmodell wird vererbt...")
                        if not self.runSQLScript(conn, "alkis-inherit.sql"):
                            self.log("Vererben des Datenmodell schlug fehl.")
                            break
                        self.log("Datenmodell vererbt.")

                        if not self.rund(conn, "postinherit"):
                            break

                    self.cbxCreate.setChecked(False)
                else:
                    if self.cbxClean.isChecked():
                        if not self.rund(conn, "preclean"):
                            break

                        self.status("Datenbankschema wird geleert...")
                        if not self.runSQLScript(conn, "alkis-clean.sql"):
                            self.log("Datenbankleerung schlug fehl.")
                            break
                        self.cbxClean.setChecked(False)

                        if not self.rund(conn, "postclean"):
                            break

                    if not self.rund(conn, "preupdate"):
                        break

                    self.status("Datenbankschema wird geprüft...")
                    if not self.runSQLScript(conn, "alkis-update.sql"):
                        self.log("Schemaprüfung schlug fehl.")
                        break

                    if not self.rund(conn, "postupdate"):
                                                break

                ok = self.rund(conn, "preprocessing")

                self.pbProgress.setVisible(True)

                s = 0
                for i in range(self.lstFiles.count()):
                    if self.canceled:
                        self.log("Import abgebrochen.")
                        break

                    item = self.lstFiles.item(i)
                    self.lstFiles.setCurrentItem(item)

                    fn = item.text()

                    if not os.path.isfile(fn):
                        continue

                    src = ""
                    if fn.lower().endswith(".xml.gz"):
                        src = fn[:-3]
                        size = sizes[src]

                        self.status("{} wird extrahiert.".format(fn))
                        app.processEvents()

                        src = os.path.join(os.getenv("TEMP"), os.path.basename(src))

                        f_in = gzip.open(fn)
                        f_out = open(src, "wb")
                        while True:
                            chunk = f_in.read(1024 * 1024)
                            if not chunk:
                                break

                            f_out.write(chunk)

                        f_out.close()
                        f_in.close()

                        self.logDb("{} wurde entpackt.".format(fn))

                    elif fn.lower().endswith(".zip"):
                        src = fn[:-4]
                        if not src.endswith(".xml"):
                            src += ".xml"

                        if src not in sizes:
                            logDb("Größe der Datei {} nicht gefunden.".format(src))
                            break

                        size = sizes[src]

                        self.status("{} wird extrahiert.".format(fn))
                        app.processEvents()

                        src = os.path.join(os.getenv("TEMP"), os.path.basename(src))

                        zipf = ZipFile(fn, "r")
                        f_in = zipf.open(zipf.infolist()[0].filename)
                        f_out = open(src, "wb")
                        while True:
                            chunk = f_in.read(1024 * 1024)
                            if not chunk:
                                break

                            f_out.write(chunk)
                        f_out.close()
                        f_in.close()
                        zipf.close()

                        self.logDb("{} wurde entpackt.".format(fn))

                    else:
                        src = fn
                        size = sizes[fn]

                    try:
                        os.unlink(src[:-4] + ".gfs")
                    except OSError:
                        pass

                    # if size==623 or size==712:
                    #    item.setSelected(True)
                    #    self.log("Kurze Datei {} übersprungen.".format(fn))
                    #    continue

                    args = [
                        self.ogr2ogr,
                        "-f", "PostgreSQL",
                        "-update",
                        "-append",
                        "-progress",
                        "PG:{} active_schema={}','{}".format(conn, self.schema, self.pgschema)
                    ]

                    if int(self.leGT.text() or '0') >= 1:
                        args.extend(["-gt", self.leGT.text()])

                    if GDAL_MAJOR >= 3:
                        if self.epsg == 131466 or self.epsg == 131467 or self.epsg == 131468:
                            args.extend(["-a_srs", os.path.join(BASEDIR, "{}.wkt2".format(self.epsg))])

                        elif self.epsg == 31466 or self.epsg == 31467 or self.epsg == 31468:
                            args.extend([
                                "-s_srs", os.path.join(BASEDIR, "1{}.wkt2".format(self.epsg)),
                                "-t_srs", "EPSG:{}".format(self.epsg)
                            ])

                        elif self.epsg == 13068:
                            args.extend([
                                "-ct", "+proj=pipeline +step +inv +proj=utm +zone=33 +ellps=GRS80 +step +inv +proj=hgridshift +grids=ntv2berlin20130508.GSB +step +proj=cass +lat_0=52.4186482777778 +lon_0=13.6272036666667 +x_0=40000 +y_0=10000 +ellps=bessel +step +proj=axisswap +order=2",
                                "-a_srs", "EPSG:3068"
                            ])

                        else:
                            args.extend(["-a_srs", "EPSG:{}".format(self.epsg)])

                    elif self.epsg == 131466 or self.epsg == 131467 or self.epsg == 131468:
                        args.extend(["-a_srs", "+init=custom:{}".format(self.epsg)])
                        os.putenv("PROJ_LIB", ".")

                    elif self.epsg == 31466 or self.epsg == 31467 or self.epsg == 31468:
                        args.extend([
                            "-s_srs", "+init=custom:1{}".format(self.epsg),
                            "-t_srs", "+init=custom:{}".format(self.epsg)
                        ])
                        os.putenv("PROJ_LIB", ".")

                    elif self.epsg == 13068:
                        args.extend([
                            "-s_srs", "EPSG:25833",
                            "-t_srs", "+init=custom:3068",
                        ])
                        os.putenv("PROJ_LIB", ".")

                    else:
                        args.extend(["-a_srs", "EPSG:{}".format(self.epsg)])

                    if self.cbxSkipFailures.isChecked() or fn in checked:
                        args.extend(["-skipfailures", "--config", "PG_USE_COPY", "NO"])
                    else:
                        args.extend(["--config", "PG_USE_COPY", "YES" if self.cbxUseCopy.isChecked() else "NO"])

                    args.extend(["-nlt", "CONVERT_TO_LINEAR", "-ds_transaction"])

                    args.append(src)

                    self.status("{} mit {} wird importiert...".format(fn, self.memunits(size)))

                    t1 = QElapsedTimer()
                    t1.start()

                    ok = self.runProcess(args)

                    try:
                        os.unlink(src[:-4] + ".gfs")
                    except OSError:
                        pass

                    elapsed = t1.elapsed()

                    if elapsed > 0:
                        throughput = " ({}/s)".format(self.memunits(size * 1000 / elapsed))
                    else:
                        throughput = ""

                    self.log("{} mit {} in {} importiert{}".format(
                        fn,
                        self.memunits(size),
                        self.timeunits(elapsed),
                        throughput
                    ))

                    item.setSelected(ok)
                    if src != fn and os.path.exists(src):
                        os.unlink(src)

                    s = s + size
                    self.pbProgress.setValue(10000 * s / ts)

                    remaining_data = ts - s
                    remaining_time = remaining_data * t0.elapsed() / s

                    self.alive.setText("Noch {} in etwa {}\nETA: {} -".format(
                        self.memunits(remaining_data),
                        self.timeunits(remaining_time),
                        QDateTime.currentDateTime().addMSecs(remaining_time).toString(Qt.ISODate)
                    ))

                    app.processEvents()

                    if not ok:
                        self.status("Fehler bei {}.".format(fn))
                        break

                self.pbProgress.setValue(10000)
                self.pbProgress.setVisible(False)

                if ok and self.lstFiles.count() > 0:
                    self.alive.setText(" -")
                    self.log("{} Dateien mit {} in {} importiert{}".format(
                        self.lstFiles.count(),
                        self.memunits(ts),
                        self.timeunits(t0.elapsed()),
                        " ({}/s)".format(self.memunits(ts * 1000 / t0.elapsed()))
                    ))

                if ok:
                    ok = self.rund(conn, "postprocessing")

                if ok:
                    self.status("VACUUM...")
                    ok = self.db.exec_("VACUUM")
                    if ok:
                        self.log("VACUUM abgeschlossen.")

                if ok:
                    self.log("Import nach {} erfolgreich beendet.".format(self.timeunits(t0.elapsed())))
                else:
                    self.log("Import nach {} abgebrochen.".format(self.timeunits(t0.elapsed())))

            except Exception:
                exc_type, exc_value, exc_traceback = sys.exc_info()
                try:
                    err = "\n> ".join([x.decode("utf-8", 'replace') for x in traceback.format_exception(exc_type, exc_value, exc_traceback)])
                except AttributeError:
                    err = "\n> ".join([x for x in traceback.format_exception(exc_type, exc_value, exc_traceback)])
                if sys.stdout:
                    print(err)
                self.log("Abbruch nach Fehler\n> {}".format(str(err)))

            break

        self.status("")
        self.alive.setText("-")

        self.pbStart.clicked.disconnect(self.cancel)
        self.pbStart.clicked.connect(self.run)
        self.pbStart.setText("Start")

        self.pbAdd.setEnabled(True)
        self.pbAddDir.setEnabled(True)
        self.pbLoad.setEnabled(True)
        self.pbSave.setEnabled(True)
        self.selChanged()

        self.lstFiles.itemSelectionChanged.connect(self.selChanged)

        QApplication.restoreOverrideCursor()

        self.logqry = None
        self.running = False

        self.db.close()
        self.db = None


app = QApplication(sys.argv)
dlg = alkisImportDlg()
dlg.exec_()
