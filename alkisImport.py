#!/usr/bin/python
# -*- coding: utf8 -*-

"""
***************************************************************************
    alkisImport.py
    ---------------------
    Date                 : Sep 2012
    Copyright            : (C) 2012-2018 by Jürgen Fischer
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


import sip
for c in ["QDate", "QDateTime", "QString", "QTextStream", "QTime", "QUrl", "QVariant"]:
        sip.setapi(c, 2)

import sys
import os
import traceback
import gzip
import re

from zipfile import ZipFile
from tempfile import gettempdir
from itertools import islice
from glob import glob

from PyQt4.QtCore import QSettings, QProcess, QFile, QDir, QFileInfo, QIODevice, Qt, QDateTime, QTime, QByteArray
from PyQt4.QtGui import QApplication, QDialog, QIcon, QFileDialog, QMessageBox, QFont, QIntValidator, QListWidgetItem
from PyQt4.QtSql import QSqlDatabase, QSqlQuery
from PyQt4 import uic

d = os.path.dirname(__file__)
sys.path.insert(0, d)
alkisImportDlgBase = uic.loadUiType(os.path.join(d, 'alkisImportDlg.ui'))[0]
aboutDlgBase = uic.loadUiType(os.path.join(d, 'about.ui'))[0]
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
os.putenv("NAS_INDICATOR", "NAS-Operationen.xsd;NAS-Operationen_optional.xsd;AAA-Fachschema.xsd;ASDKOM-NAS-Operationen_1_1_NRW.xsd;aaa.xsd;aaa-suite")

os.putenv("PGCLIENTENCODING", "UTF8")


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
            files.extend(getFiles(pattern, unicode(fi.filePath())))
        elif re.search(pattern, f, re.IGNORECASE):
            files.append(os.path.abspath(unicode(fi.filePath())))

    return files


class ProcessError(Exception):
    def __init__(self, msg):
        self.msg = msg

    def __str__(self):
        return unicode(self.msg)


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

        self.cbEPSG.addItem("UTM32N", "25832")
        self.cbEPSG.addItem("UTM33N", "25833")
        self.cbEPSG.addItem("3GK2 (BW)", "131466")
        self.cbEPSG.addItem("3GK3 (BW)", "131467")
        self.cbEPSG.addItem("3GK4 (BY)", "131468")
        self.cbEPSG.addItem("DHDN GK2 (BW)", "31466")
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

        f = QFont("Monospace")
        f.setStyleHint(QFont.TypeWriter)
        self.lwProtocol.setFont(f)
        self.lwProtocol.setUniformItemSizes(True)

        self.status("")

        self.restoreGeometry(s.value("geometry", QByteArray(), type=QByteArray))

        self.canceled = False
        self.running = False
        self.skipScroll = False
        self.logqry = None

        self.reFilter = []

    def loadRe(self):
        f = open("re", "r")
        while True:
            l = list(islice(f, 50))
            if not l:
                break

            self.reFilter.append(re.compile("|".join(map(str.rstrip, l))))

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

        return "{}{}".format(s, u)

    def timeunits(self, t):
        ms = t % 1000

        t = t / 1000

        s = t % 60
        m = (t / 60) % 60
        h = (t / 60 / 60) % 24
        d = t / 60 / 60 / 24

        r = ""
        if d > 0:
            r += "{}t".format(d)
        if h > 0:
            r += "{}h".format(h)
        if m > 0:
            r += "{}m".format(m)
        if s > 0:
            r += "{}s".format(s)
        if r == "":
            r = "{}ms".format(ms)

        return r

    def selFiles(self):
        s = QSettings("norBIT", "norGIS-ALKIS-Import")
        lastDir = s.value("lastDir", ".")

        files = QFileDialog.getOpenFileNames(self, u"NAS-Dateien wählen", lastDir, "NAS-Dateien (*.xml *.xml.gz *.zip)")
        if files is None:
            return

        dirs = []

        for f in files:
            f = os.path.abspath(unicode(f))
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

        d = QFileDialog.getExistingDirectory(self, u"Verzeichnis mit NAS-Dateien wählen", lastDir)
        if d is None or d == '':
            QMessageBox.critical(self, u"norGIS-ALKIS-Import", u"Kein eindeutiges Verzeichnis gewählt!", QMessageBox.Cancel)
            return

        s.setValue("lastDir", d)

        QApplication.setOverrideCursor(Qt.WaitCursor)

        self.status("Verzeichnis wird durchsucht...")

        for f in sorted(getFiles("\.(xml|xml\.gz|zip)$", d)):
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
        fn = QFileDialog.getSaveFileName(self, u"Liste wählen", ".", "Dateilisten (*.lst)")
        if file is None:
            return

        f = open(unicode(fn), "w")

        for i in range(self.lstFiles.count()):
            f.write(self.lstFiles.item(i).text())
            f.write("\n")

        f.close()

    def loadList(self):
        fn = QFileDialog.getOpenFileName(self, u"Liste wählen", ".", "Dateilisten (*.lst)")
        if fn is None:
            return

        fn = unicode(fn)

        f = open(fn, "rU")
        for l in f.read().splitlines():
            if not os.path.isabs(l):
                l = os.path.join(os.path.dirname(fn), l)
            self.lstFiles.addItem(os.path.abspath(l))
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

            self.log(u"Datenbank-Protokollierung fehlgeschlagen [{}: {}]".format(err, msg))
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
        save = QFileDialog.getSaveFileName(self, u"Protokolldatei angeben", ".", "Protokoll-Dateien (*.log)")
        if save is None:
            return

        f = QFile(save)
        if not f.open(QIODevice.WriteOnly):
            return

        for i in range(0, self.lwProtocol.count()):
            f.write(self.lwProtocol.item(i).text().encode("utf-8", "ignore"))
            f.write(os.linesep)
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

    def processOutput(self, current, output):
        if output.isEmpty():
            return

        if not current:
            current = ""

        # r = str(output).decode('utf-8')
        r = output.data().decode('utf-8')

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
                self.log(u"> {}|".format(l.rstrip()))
            else:
                self.logDb(l)

        return current + lastline

    def runProcess(self, args):
        self.logDb(u"BEFEHL: '{}'".format(re.sub(u'password=\S+', u'password=*removed*', u"' '".join(args))))

        currout = ""
        currerr = ""

        p = QProcess()
        p.start(args[0], args[1:])

        i = 0
        while not p.waitForFinished(500):
            i += 1
            self.alive.setText(self.alive.text()[:-1] + ("-\|/")[i % 4])
            app.processEvents()

            currout = self.processOutput(currout, p.readAllStandardOutput())
            currerr = self.processOutput(currerr, p.readAllStandardError())

            if p.state() != QProcess.Running:
                if self.canceled:
                    self.log(u"Prozeß abgebrochen.")
                break

            if self.canceled:
                self.log(u"Prozeß wird abgebrochen.")
                p.kill()

        currout = self.processOutput(currout, p.readAllStandardOutput())
        if currout and currout != "":
            self.log("E {}".format(currout))

        currerr = self.processOutput(currerr, p.readAllStandardError())
        if currerr and currerr != "":
            self.log("E {}".format(currerr))

        ok = False
        if p.exitStatus() == QProcess.NormalExit:
            if p.exitCode() == 0:
                ok = True
            else:
                self.log(u"Fehler bei Prozeß: {}".format(p.exitCode()))
        else:
            self.log(u"Prozeß abgebrochen: {}".format(p.exitCode()))

        self.logDb("EXITCODE: {}".format(p.exitCode()))

        p.close()

        return ok

    def runSQLScript(self, conn, fn, parallel=False):
        return self.runProcess([
            self.psql,
            "-v", "alkis_epsg={}".format(3068 if self.epsg==13068 else self.epsg),
            "-v", "alkis_fnbruch={}".format("true" if self.fnbruch else "false"),
            "-v", "alkis_pgverdraengen={}".format("true" if self.pgverdraengen else "false"),
            "-q", "-f", fn, conn])

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
            self.log(u"Konnte Datenbankverbindung nicht aufbauen!")
            return None

        self.db.exec_("SET STANDARD_CONFORMING_STRINGS TO ON")

        return conn

    def rund(self, conn, dir):
        for f in sorted(glob("{}.d/*.sql".format(dir))):
            self.status(u"{} wird gestartet...".format(f))
            if not self.runSQLScript(conn, f):
                self.log(u"{} gescheitert.".format(f))
                return False

            self.log(u"{} ausgeführt.".format(f))

        return True

    def importALKIS(self):
        if 'CPL_DEBUG' in os.environ:
            self.log(u"Debug-Ausgaben aktiv.")

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
            t0 = QTime()
            t0.start()

            self.loadRe()

            self.lstFiles.clearSelection()

            conn = self.connectDb()
            if conn is None:
                break

            self.db.exec_("SET application_name='ALKIS-Import - Frontend'")
            self.db.exec_("SET client_min_messages TO notice")

            qry = self.db.exec_("SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public' AND table_name='alkis_importlog'")
            if not qry or not qry.next():
                self.log(u"Konnte Existenz von Protokolltabelle nicht überprüfen.")
                break

            if int(qry.value(0)) == 0:
                qry = self.db.exec_("CREATE TABLE alkis_importlog(n SERIAL PRIMARY KEY, ts timestamp default now(), msg text)")
                if not qry:
                    self.log(u"Konnte Protokolltabelle nicht anlegen [{}]".format(qry.lastError().text()))
                    break
            elif self.cbxClearProtocol.isChecked():
                qry = self.db.exec_("TRUNCATE alkis_importlog")
                if not qry:
                    self.log(u"Konnte Protokolltabelle nicht leeren [{}]".format(qry.lastError().text()))
                    break
                self.cbxClearProtocol.setChecked(False)
                self.log(u"Protokolltabelle gelöscht.")

            self.logqry = QSqlQuery(self.db)
            if not self.logqry.prepare("INSERT INTO alkis_importlog(msg) VALUES (?)"):
                self.log(u"Konnte Protokollierungsanweisung nicht vorbereiten [{}]".format(qry.lastError().text()))
                self.logqry = None
                break

            self.log("Import-Version: $Format:%h$")

            qry = self.db.exec_("SELECT version()")

            if not qry or not qry.next():
                self.log(u"Konnte PostgreSQL-Version nicht bestimmen!")
                break

            self.log("Datenbank-Version: {}".format(qry.value(0)))

            m = re.search("PostgreSQL (\d+)\.(\d+)", qry.value(0))
            if not m:
                self.log(u"PostgreSQL-Version nicht im erwarteten Format")
                break

            if int(m.group(1)) < 8 or (int(m.group(1)) == 8 and int(m.group(2)) < 3):
                self.log(u"Mindestens PostgreSQL 8.3 erforderlich")
                break

            qry = self.db.exec_("SELECT postgis_version()")
            if not qry or not qry.next():
                self.log(u"Konnte PostGIS-Version nicht bestimmen!")
                break

            self.log("PostGIS-Version: {}".format(qry.value(0)))

            qry = self.db.exec_("SELECT inet_client_addr()" )
            if not qry or not qry.next():
                self.log(u"Konnte Client-Adresse nicht bestimmen!")
                break

            self.log("Import von: {}".format(qry.value(0)))


            qry = self.db.exec_("SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public' AND table_name='ax_flurstueck'")
            if not qry or not qry.next():
                self.log(u"Konnte Existenz des ALKIS-Schema nicht überprüfen.")
                break

            if not self.cbxCreate.isChecked():
                if int(qry.value(0)) == 0:
                    self.cbxCreate.setChecked(True)
                    self.log(u"Keine ALKIS-Daten vorhanden - Datenbestand muß angelegt werden.")
                    break

                if not qry.exec_("SELECT find_srid('','ax_flurstueck','wkb_geometry')") or not qry.next():
                    self.log(u"Konnte Koordinatensystem der vorhandenen Datenbank nicht bestimmen.")
                    break

                self.epsg = int(qry.value(0))

            self.ogr2ogr = which("ogr2ogr")
            if not self.ogr2ogr:
                self.ogr2ogr = which("ogr2ogr.exe")

            if not self.ogr2ogr:
                self.log(u"ogr2ogr nicht gefunden!")
                break

            n = self.lwProtocol.count() - 1

            if not self.runProcess([self.ogr2ogr, "--version"]):
                self.log(u"Konnte ogr2ogr-Version nicht abfragen!")
                break

            for i in range(n, self.lwProtocol.count()):
                m = re.search("GDAL (\d+)\.(\d+)", self.lwProtocol.item(i).text())
                if m:
                    break

            if not m:
                self.log(u"GDAL-Version nicht gefunden")
                break

            gdal2 = int(m.group(1)) > 1

            self.psql = which("psql")
            if not self.psql:
                self.psql = which("psql.exe")

            if not self.psql:
                self.log(u"psql nicht gefunden!")
                break

            if not self.runProcess([self.psql, "--version"]):
                self.log(u"Konnte psql-Version nicht abfragen!")
                break

            try:
                self.status(u"Bestimme Gesamtgröße des Imports...")

                self.pbProgress.setVisible(True)
                self.pbProgress.setRange(0, self.lstFiles.count())

                sizes = {}

                ts = 0
                for i in range(self.lstFiles.count()):
                    self.pbProgress.setValue(i)
                    item = self.lstFiles.item(i)
                    fn = unicode(item.text())

                    if fn.lower().endswith(".xml"):
                        s = os.path.getsize(fn)
                        sizes[fn] = s

                    elif fn.lower().endswith(".zip"):
                        l = -8 if fn[-8:].lower() == ".xml.zip" else -4
                        self.status(u"{} wird abgefragt...".format(fn))
                        app.processEvents()

                        f = ZipFile(fn, "r")
                        il = f.infolist()
                        if len(il) != 1:
                            raise ProcessError(u"ZIP-Archiv {} enthält mehr als eine Datei!".format(fn))
                        s = il[0].file_size
                        sizes[fn[:l] + ".xml"] = s

                    elif fn.lower().endswith(".xml.gz"):
                        self.status(u"{} wird abgefragt...".format(fn))

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

                self.log(u"Gesamtgröße des Imports: {}".format(self.memunits(ts)))

                self.pbProgress.setRange(0, 10000)
                self.pbProgress.setValue(0)

                self.status(u"Kompatibilitätsfunktionen werden importiert...")
                if not self.runSQLScript(conn, "alkis-compat.sql"):
                    self.log(u"Import der Kompatibilitätsfunktionen schlug fehl.")
                    break

                self.log(u"Kompatibilitätsfunktionen importiert.")

                if self.cbxCreate.isChecked():
                    if not self.rund(conn, "precreate"):
                        break

                    self.status(u"Datenbestand wird angelegt...")
                    if not self.runSQLScript(conn, "alkis-schema.sql"):
                        self.log(u"Anlegen des Datenbestands schlug fehl.")
                        break
                    self.log(u"Datenbestand angelegt.")

                    self.status(u"Präsentationstabellen werden erzeugt...")
                    if not self.runSQLScript(conn, "alkis-po-tables.sql"):
                        self.log(u"Anlegen der Präsentationstabellen schlug fehl.")
                        break
                    self.log(u"Präsentationstabellen angelegt.")

                    if not self.rund(conn, "postcreate"):
                        break

                    self.cbxCreate.setChecked(False)
                else:
                    if self.cbxClean.isChecked():
                        if not self.rund(conn, "preclean"):
                            break

                        self.status(u"Datenbankschema wird geleert...")
                        if not self.runSQLScript(conn, "alkis-clean.sql"):
                            self.log(u"Datenbankleerung schlug fehl.")
                            break
                        self.cbxClean.setChecked(False)

                        if not self.rund(conn, "postclean"):
                            break

                    if not self.rund(conn, "preupdate"):
                        break

                    self.status(u"Datenbankschema wird geprüft...")
                    if not self.runSQLScript(conn, "alkis-update.sql"):
                        self.log(u"Schemaprüfung schlug fehl.")
                        break

                    if not self.rund(conn, "postupdate"):
                                                break

                self.status(u"Signaturen werden importiert...")
                if not self.runSQLScript(conn, "alkis-signaturen.sql"):
                    self.log(u"Import der Signaturen schlug fehl.")
                    break
                self.log(u"Signaturen importiert.")

                ok = self.rund(conn, "preprocessing")

                self.pbProgress.setVisible(True)

                s = 0
                for i in range(self.lstFiles.count()):
                    if self.canceled:
                        self.log("Import abgebrochen.")
                        break

                    item = self.lstFiles.item(i)
                    self.lstFiles.setCurrentItem(item)

                    fn = unicode(item.text())

                    src = ""
                    if fn.lower().endswith(".xml.gz"):
                        src = fn[:-3]
                        size = sizes[src]

                        self.status(u"{} wird extrahiert.".format(fn))
                        app.processEvents()

                        src = os.path.join(gettempdir(), os.path.basename(src))

                        f_in = gzip.open(fn)
                        f_out = open(src, "wb")
                        while True:
                            chunk = f_in.read(1024 * 1024)
                            if not chunk:
                                break

                            f_out.write(chunk)

                        f_out.close()
                        f_in.close()

                        self.logDb(u"{} wurde entpackt.".format(fn))

                    elif fn.lower().endswith(".zip"):
                        src = fn[:-4] + ".xml"
                        size = sizes[src]

                        self.status(u"{} wird extrahiert.".format(fn))
                        app.processEvents()

                        src = os.path.join(gettempdir(), os.path.basename(src))

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

                        self.logDb(u"{} wurde entpackt.".format(fn))

                    else:
                        src = fn
                        size = sizes[fn]

                    try:
                        os.unlink(src[:-4] + ".gfs")
                    except OSError:
                        pass

                    # if size==623 or size==712:
                    #    item.setSelected(True)
                    #    self.log(u"Kurze Datei {} übersprungen.".format(fn))
                    #    continue

                    args = [
                        self.ogr2ogr,
                        "-f", "PostgreSQL",
                        "-update",
                        "-append",
                        u"PG:{}".format(conn),
                    ]

                    if int(self.leGT.text() or '0') >= 1:
                        args.extend(["-gt", self.leGT.text()])

                    if self.epsg == 131466 or self.epsg == 131467 or self.epsg == 131468:
                        args.extend(["-a_srs", "+init=custom:{}".format(self.epsg)])
                        os.putenv("PROJ_LIB", ".")

                    elif self.epsg == 31466 or self.epsg == 31467 or self.epsg == 31468:
                        args.extend([
                            "-s_srs", "+init=custom:1{}".format(self.epsg),
                            "-t_srs", "EPSG:{}".format(self.epsg)
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
                        args.append("-skipfailures")
                        args.extend(["--config", "PG_USE_COPY", "NO"])
                    else:
                        args.extend(["--config", "PG_USE_COPY", "YES" if self.cbxUseCopy.isChecked() else "NO"])

                    if gdal2:
                        args.extend(["-nlt", "CONVERT_TO_LINEAR", "-ds_transaction"])

                    args.append(src)

                    self.status(u"{} mit {} wird importiert...".format(fn, self.memunits(size)))

                    t1 = QTime()
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

                    self.log(u"{} mit {} in {} importiert{}".format(
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

                    self.alive.setText(u"Noch {} in etwa {}\nETA: {} -".format(
                        self.memunits(remaining_data),
                        self.timeunits(remaining_time),
                        QDateTime.currentDateTime().addMSecs(remaining_time).toString(Qt.ISODate)
                    ))

                    app.processEvents()

                    if not ok:
                        self.status(u"Fehler bei {}.".format(fn))
                        break

                self.pbProgress.setValue(10000)
                self.pbProgress.setVisible(False)

                if ok and self.lstFiles.count() > 0:
                    self.alive.setText(" -")
                    self.log(u"{} Dateien mit {} in {} importiert{}".format(
                        self.lstFiles.count(),
                        self.memunits(ts),
                        self.timeunits(t0.elapsed()),
                        " ({}/s)".format(self.memunits(ts * 1000 / t0.elapsed()))
                    ))

                if ok:
                    t1 = QTime()
                    t1.start()

                    self.status(u"Ableitungsregeln werden verarbeitet...")
                    ok = self.runSQLScript(conn, "alkis-ableitungsregeln.sql")
                    if ok:
                        self.log(u"Ableitungsregeln in {} verarbeitet.".format(self.timeunits(t1.elapsed())))

                if ok:
                    ok = self.rund(conn, "postprocessing")

                if ok:
                    self.status(u"VACUUM...")
                    ok = self.db.exec_("VACUUM")
                    if ok:
                        self.log(u"VACUUM abgeschlossen.")

                if ok:
                    self.log(u"Import nach {} erfolgreich beendet.".format(self.timeunits(t0.elapsed())))
                else:
                    self.log(u"Import nach {} abgebrochen.".format(self.timeunits(t0.elapsed())))

            except Exception:
                exc_type, exc_value, exc_traceback = sys.exc_info()
                err = u"\n> ".join(traceback.format_exception(exc_type, exc_value, exc_traceback))
                if sys.stdout:
                    print err
                self.log(u"Abbruch nach Fehler\n> {}".format(unicode(err)))

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
