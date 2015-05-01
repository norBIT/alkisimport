#!/usr/bin/python
# -*- coding: utf8 -*-

"""
***************************************************************************
    alkisImport.py
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


import sip
for c in [ "QDate", "QDateTime", "QString", "QTextStream", "QTime", "QUrl", "QVariant" ]:
        sip.setapi(c,2)

import sys
import os
import traceback
import tempfile
import zipfile
import gzip
import re
import tempfile
import glob

from PyQt4.QtCore import QSettings, QProcess, QVariant, QFile, QDir, QFileInfo, QIODevice, Qt, QDateTime, QTime, QByteArray
from PyQt4.QtGui import QApplication, QDialog, QIcon, QFileDialog, QMessageBox, QFont, QIntValidator
from PyQt4.QtSql import QSqlDatabase, QSqlQuery, QSqlError, QSql
from PyQt4 import uic

d = os.path.dirname(__file__)
sys.path.insert( 0, d )
alkisImportDlgBase = uic.loadUiType( os.path.join( d, 'alkisImportDlg.ui' ) )[0]
aboutDlgBase = uic.loadUiType( os.path.join( d, 'about.ui' ) )[0]
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
os.putenv("NAS_INDICATOR", "NAS-Operationen.xsd;NAS-Operationen_optional.xsd;AAA-Fachschema.xsd;ASDKOM-NAS-Operationen_1_1_NRW.xsd")

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
		if f=="." or f=="..":
			continue

		fi = QFileInfo(d, f)

		if fi.isDir():
			files.extend( getFiles( pattern, unicode( fi.filePath() ) ) )
		elif re.search( pattern, f):
			files.append( os.path.abspath( unicode( fi.filePath() ) ) )

	return files

class ProcessError(Exception):
	def __init__(self, msg):
		self.msg = msg

	def __str__(self):
		return unicode(msg)

class aboutDlg(QDialog, aboutDlgBase):
	def __init__(self):
		QDialog.__init__(self)
		self.setupUi(self)

class alkisImportDlg(QDialog, alkisImportDlgBase):

	def __init__(self):
		QDialog.__init__(self)
		self.setupUi(self)
		self.setWindowIcon( QIcon('logo.svg') )
		self.setWindowFlags( Qt.WindowMinimizeButtonHint )

		s = QSettings( "norBIT", "norGIS-ALKIS-Import" )

		self.leSERVICE.setText( s.value( "service", "" ) )
		self.leHOST.setText( s.value( "host", "" ) )
		self.lePORT.setText( s.value( "port", "5432" ) )
		self.leDBNAME.setText( s.value( "dbname", "" ) )
		self.leUID.setText( s.value( "uid", "" ) )
		self.lePWD.setText( s.value( "pwd", "" ) )
		self.leGT.setText( s.value( "gt", "20000" ) )
		self.leGT.setValidator( QIntValidator( -1, 99999999 ) )
		self.lstFiles.addItems( s.value( "files", [] ) or [] )
		self.cbxSkipFailures.setChecked( s.value( "skipfailures", False, type=bool ) )
		self.cbFnbruch.setCurrentIndex( 0 if s.value( "fnbruch", True, type=bool ) else 1 )
		self.cbxUseCopy.setChecked( s.value( "usecopy", False, type=bool ) )
		self.cbxCreate.setChecked( False )

		self.cbEPSG.addItem( "UTM32N", "25832")
		self.cbEPSG.addItem( "UTM33N", "25833")
		self.cbEPSG.addItem( "3GK2 (BW)", "131466")
		self.cbEPSG.addItem( "3GK3 (BW)", "131467")
		self.cbEPSG.addItem( "3GK4 (BY)", "131468")
		self.cbEPSG.setCurrentIndex( self.cbEPSG.findData( s.value( "epsg", "25832" ) ) )

		self.pbAdd.clicked.connect(self.selFiles)
		self.pbAddDir.clicked.connect(self.selDir)
		self.pbRemove.clicked.connect(self.rmFiles)
		self.pbSelectAll.clicked.connect( self.lstFiles.selectAll )
		self.pbLoad.clicked.connect(self.loadList)
		self.pbSave.clicked.connect(self.saveList)
		self.lstFiles.itemSelectionChanged.connect(self.selChanged)

		self.pbStart.clicked.connect(self.run)
		self.pbLoadLog.clicked.connect(self.loadLog)
		self.pbSaveLog.clicked.connect(self.saveLog)
		self.pbClearLog.clicked.connect(self.clearLog)
		self.pbAbout.clicked.connect(self.about)
		self.pbClose.clicked.connect(self.accept)
		self.pbProgress.setValue( 0 )

		f = QFont("Monospace")
		f.setStyleHint( QFont.TypeWriter )
		self.lwProtocol.setFont( f )
		self.lwProtocol.setUniformItemSizes(True)

		self.status("")

		self.restoreGeometry( s.value("geometry", QByteArray(), type=QByteArray) )

		self.canceled = False
		self.running = False
		self.skipScroll = False
		self.logqry = None

		self.reFilter = None

	def loadRe(self):
		f = open("re", "r")
		self.reFilter = re.compile( f.read().rstrip("\n").replace("\n","|") )
		f.close()

		if not self.reFilter:
			raise ProcessError("reFilter not set")


	def memunits(self,s):
		u=" Bytes"

		if s > 10240:
			s /= 1024
			u = "kiB"

		if s > 10240:
			s /= 1024
			u = "MiB"

		if s > 10240:
			s /= 1024
			u = "GiB"

		return "%d%s" % (s,u)

	def timeunits(self,t):
		ms = t % 1000

		t = t / 1000

		s = t % 60
		m = (t/60) % 60
		h = (t/60/60) % 24
		d = t/60/60/24

		r = ""
		if d>0: r += "%dt" % d
		if h>0: r += "%dh" % h
		if m>0: r += "%dm" % m
		if s>0: r += "%ds" % s
		if r=="": r = "%dms" % ms

		return r

	def selFiles(self):
		s = QSettings( "norBIT", "norGIS-ALKIS-Import" )
		lastDir = s.value( "lastDir", "." )

		files = QFileDialog.getOpenFileNames( self, u"NAS-Dateien wählen", lastDir, "NAS-Dateien (*.xml *.xml.gz *.zip)")
		if files is None:
			return

		dirs = []

		for f in files:
			f = os.path.abspath( unicode(f) )
			self.lstFiles.addItem( f )
			dirs.append( os.path.dirname( f ) )

		s.setValue( "lastDir", os.path.commonprefix( dirs ) )

	def selDir(self):
		s = QSettings( "norBIT", "norGIS-ALKIS-Import" )
		lastDir = s.value( "lastDir", "." )

		d = QFileDialog.getExistingDirectory( self, u"Verzeichnis mit NAS-Dateien wählen", lastDir )
		if d is None or d == '':
			QMessageBox.critical(self, u"norGIS-ALKIS-Import", u"Kein eindeutiges Verzeichnis gewählt!", QMessageBox.Cancel )
			return

		s.setValue( "lastDir", d )

		QApplication.setOverrideCursor( Qt.WaitCursor )

		self.status( "Verzeichnis wird durchsucht..." )

		self.lstFiles.addItems( sorted( getFiles( "\.(xml|xml\.gz|zip)$", d ) ) )

		self.status("")

		QApplication.restoreOverrideCursor()

	def rmFiles(self):
		for item in self.lstFiles.selectedItems():
			self.lstFiles.takeItem( self.lstFiles.row( item ) )

	def saveList(self):
		fn = QFileDialog.getSaveFileName( self, u"Liste wählen", ".", "Dateilisten (*.lst)")
		if file is None:
			return

		f = open( unicode(fn), "w")

		for i in range(self.lstFiles.count()):
			f.write( self.lstFiles.item(i).text() )
			f.write( "\n" )

		f.close()

	def loadList(self):
		fn = QFileDialog.getOpenFileName( self, u"Liste wählen", ".", "Dateilisten (*.lst)")
		if fn is None:
			return

		fn = unicode(fn)

		f = open( fn, "rU")
		for l in f.read().splitlines():
			if not os.path.isabs(l):
				l = os.path.join( os.path.dirname(fn), l )
			self.lstFiles.addItem( os.path.abspath(l) )
		f.close()

	def selChanged(self):
		self.pbRemove.setDisabled( len(self.lstFiles.selectedItems()) == 0 )

	def status(self, msg):
		self.leStatus.setText( msg )
		app.processEvents()

	def log(self, msg):
		self.logDb( msg )
		self.logDlg( msg )

	def logDlg(self, msg, ts = None):
		if len(msg)>300:
			msg=msg[:300] + "..."

		if not ts:
			ts = QDateTime.currentDateTime()

		for m in msg.splitlines():
			m = m.rstrip()
			if m == "":
				continue
			self.lwProtocol.addItem( ts.toString( Qt.ISODate ) + " " + m )

		app.processEvents()
		if not self.skipScroll:
			self.lwProtocol.scrollToBottom()

	def logDb(self, msg):
		if not self.logqry:
			return

		self.logqry.bindValue(0, msg )

		if not self.logqry.exec_():
			err = self.logqry.lastError().text()
			logqry = self.logqry
			self.logqry = None

			self.log( u"Datenbank-Protokollierung fehlgeschlagen [%s: %s]" % (err, msg ) )
			self.logqry = logqry

	def loadLog(self):
		QApplication.setOverrideCursor( Qt.WaitCursor )
		self.lwProtocol.setUpdatesEnabled(False)

		conn = self.connectDb()
		if not conn:
			QMessageBox.critical(self, "norGIS-ALKIS-Import", "Konnte keine Datenbankverbindung aufbauen!", QMessageBox.Cancel )
			return

		qry = self.db.exec_( "SELECT ts,msg FROM alkis_importlog ORDER BY n" )
		if not qry:
			QMessageBox.critical(self, "norGIS-ALKIS-Import", "Konnte Protokoll nicht abfragen!", QMessageBox.Cancel )
			return

		self.skipScroll = True

		while qry.next():
			if self.keep( qry.value(1) ):
				self.logDlg( qry.value(1), qry.value(0) )

		self.skipScroll = False

		self.logDlg( "Protokoll geladen." )

		self.lwProtocol.scrollToBottom()

		self.lwProtocol.setUpdatesEnabled(True)
		QApplication.restoreOverrideCursor()

	def saveLog(self):
		save = QFileDialog.getSaveFileName(self, u"Protokolldatei angeben", ".", "Protokoll-Dateien (*.log)" )
		if save is None:
			return

		f = QFile(save)
		if not f.open( QIODevice.WriteOnly ):
			return

		for i in range(0, self.lwProtocol.count()):
			f.write( self.lwProtocol.item(i).text().encode( "utf-8", "ignore" ) )
			f.write( os.linesep )
		f.close()

	def clearLog(self):
		self.lwProtocol.clear()

	def about(self):
		dlg = aboutDlg()
		dlg.exec_()

	def accept(self):
		if not self.running:
			s = QSettings( "norBIT", "norGIS-ALKIS-Import" )
			s.setValue( "geometry", self.saveGeometry() )
			QDialog.accept(self)

	def closeEvent(self, e):
		if not self.running:
			e.accept()
			return

		self.cancel()
		e.ignore()

	def cancel(self):
		if QMessageBox.question(self, "norGIS-ALKIS-Import", "Laufenden Import abbrechen?", QMessageBox.Yes | QMessageBox.No ) == QMessageBox.Yes:
			self.canceled = True

	def keep(self,l):
		if not self.reFilter:
			self.loadRe()

		if self.reFilter.match(l):
			return False
		else:
			return True

	def processOutput(self, current, output):
		if output.isEmpty():
			return

		if not current:
			current = ""

		#r = str(output).decode('utf-8')
		r = output.data().decode('utf-8')

		lines = r.split("\n")

		if not r.endswith("\n"):
			lastline = lines.pop()
		else:
			lastline = ""

		if current<>"" and lines.count()>0:
			if r.startsWith("\n"):
				lines.prepend( current )
			else:
				lines[0].prepend( current )
			current = ""

		for l in lines:
			if self.keep(l):
				self.log( u"> %s|" % l.rstrip() )
			else:
				self.logDb( l )

		return current + lastline

	def runProcess(self, args):
		self.logDb( u"BEFEHL: '%s'" % ( u"' '".join(args) ) )

		currout = ""
		currerr = ""

		p = QProcess()
		p.start( args[0], args[1:] )

		i=0
		while not p.waitForFinished(500):
			i += 1
			self.alive.setText( self.alive.text()[:-1] + ("-\|/")[i%4] )
			app.processEvents()

			currout = self.processOutput( currout, p.readAllStandardOutput() )
			currerr = self.processOutput( currerr, p.readAllStandardError() )

			if p.state()<>QProcess.Running:
				if self.canceled:
					self.log( u"Prozeß abgebrochen." )
				break

			if self.canceled:
				self.log( u"Prozeß wird abgebrochen." )
				p.kill()

		currout = self.processOutput( currout, p.readAllStandardOutput() )
		if currout and currout!="":
			self.log( "E %s" % currout )

		currerr = self.processOutput( currerr, p.readAllStandardError() )
		if currerr and currerr!="":
			self.log( "E %s" % currerr )

		ok = False
		if p.exitStatus()==QProcess.NormalExit:
			if p.exitCode()==0:
				ok = True
			else:
				self.log( u"Fehler bei Prozeß: %d" % p.exitCode() )
		else:
			self.log( u"Prozeß abgebrochen: %d" % p.exitCode() )

		self.logDb( "EXITCODE: %d" % p.exitCode() )

		p.close()

		return ok


	def runSQLScript(self, conn, fn):
		return self.runProcess([
				self.psql,
				"-v", "alkis_epsg=%s" % self.epsg,
				"-v", "alkis_fnbruch=%s" % ("true" if self.fnbruch else "false"),
				"-q", "-f", fn, conn])

	def run(self):
		self.importALKIS()

	def connectDb(self):
		if self.leSERVICE.text()<>'':
			conn = "service=%s " % self.leSERVICE.text()
		else:
			if self.leHOST.text()<>'':
				conn = "host=%s port=%s " % (self.leHOST.text(), self.lePORT.text() )
			else:
				conn = ""

		conn += "dbname=%s user='%s' password='%s'" % (self.leDBNAME.text(), self.leUID.text(), self.lePWD.text() )

		self.db = QSqlDatabase.addDatabase( "QPSQL" )
		self.db.setConnectOptions( conn )
		if not self.db.open():
			self.log(u"Konnte Datenbankverbindung nicht aufbauen!")
			return None

		self.db.exec_( "SET STANDARD_CONFORMING_STRINGS TO ON" )

		return conn

	def importALKIS(self):
		if os.environ.has_key('CPL_DEBUG'):
			self.log( u"Debug-Ausgaben aktiv." )

		files = []
		for i in range(self.lstFiles.count()):
			files.append( self.lstFiles.item(i).text() )

		s = QSettings( "norBIT", "norGIS-ALKIS-Import" )
		s.setValue( "service", self.leSERVICE.text() )
		s.setValue( "host", self.leHOST.text() )
		s.setValue( "port", self.lePORT.text() )
		s.setValue( "dbname", self.leDBNAME.text() )
		s.setValue( "uid", self.leUID.text() )
		s.setValue( "pwd", self.lePWD.text() )
		s.setValue( "gt", self.leGT.text() )
		s.setValue( "files", files )
		s.setValue( "skipfailures", self.cbxSkipFailures.isChecked()==True )
		s.setValue( "usecopy", self.cbxUseCopy.isChecked()==True )

		self.fnbruch = self.cbFnbruch.currentIndex()==0
		s.setValue( "fnbruch", self.fnbruch )

		self.epsg = int( self.cbEPSG.itemData( self.cbEPSG.currentIndex() ) )
		s.setValue( "epsg", self.epsg)

		self.running = True
		self.canceled = False

		self.pbStart.setText( "Abbruch" )
		self.pbStart.clicked.disconnect(self.run)
		self.pbStart.clicked.connect(self.cancel)

		self.pbAdd.setDisabled(True)
		self.pbAddDir.setDisabled(True)
		self.pbRemove.setDisabled(True)
		self.pbLoad.setDisabled(True)
		self.pbSave.setDisabled(True)

		self.lstFiles.itemSelectionChanged.disconnect(self.selChanged)

		QApplication.setOverrideCursor( Qt.WaitCursor )

		while True:
			t0 = QTime()
			t0.start()

			self.loadRe()

			self.lstFiles.clearSelection()

			conn = self.connectDb()
			if conn is None:
				break

			self.log( "Import-Version: $Format:%h$'" )

			self.db.exec_( "SET application_name='ALKIS-Import - Frontend'" )
			self.db.exec_( "SET client_min_messages TO notice" )

			qry = self.db.exec_( "SELECT version()" )

			if not qry or not qry.next():
				self.log(u"Konnte PostgreSQL-Version nicht bestimmen!")
				break

			self.log( "Datenbank-Version: %s" % qry.value(0) )

			m = re.search( "PostgreSQL (\d+)\.(\d+)", qry.value(0) )
			if not m:
				self.log(u"PostgreSQL-Version nicht im erwarteten Format")
				break

			if int(m.group(1)) < 8 or ( int(m.group(1))==8 and int(m.group(2))<3 ):
				self.log(u"Mindestens PostgreSQL 8.3 erforderlich")
				break

			qry = self.db.exec_( "SELECT postgis_version()" )
			if not qry or not qry.next():
				self.log(u"Konnte PostGIS-Version nicht bestimmen!")
				break

			self.log( "PostGIS-Version: %s" % qry.value(0) )

			qry = self.db.exec_( "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public' AND table_name='alkis_importlog'" )
			if not qry or not qry.next():
				self.log( u"Konnte Existenz von Protokolltabelle nicht überprüfen." )
				break

			if int( qry.value(0) ) == 0:
				qry = self.db.exec_( "CREATE TABLE alkis_importlog(n SERIAL PRIMARY KEY, ts timestamp default now(), msg text)" )
				if not qry:
					self.log( u"Konnte Protokolltabelle nicht anlegen [%s]" % qry.lastError().text() )
					break
			elif self.cbxClearProtocol.isChecked():
				qry = self.db.exec_( "TRUNCATE alkis_importlog" )
				if not qry:
					self.log( u"Konnte Protokolltabelle nicht leeren [%s]" % qry.lastError().text() )
					break
				self.cbxClearProtocol.setChecked( False )
				self.log( u"Protokolltabelle gelöscht." )

			qry = self.db.exec_( "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public' AND table_name='ax_flurstueck'" )
			if not qry or not qry.next():
				self.log( u"Konnte Existenz des ALKIS-Schema nicht überprüfen." )
				break

			if not self.cbxCreate.isChecked():
				if int( qry.value(0) ) == 0:
					self.cbxCreate.setChecked( True )
					self.log( u"Keine ALKIS-Daten vorhanden - Datenbestand muß angelegt werden." )
					break

				if not qry.exec_( "SELECT find_srid('','ax_flurstueck','wkb_geometry')" ) or not qry.next():
					self.log( u"Konnte Koordinatensystem der vorhandenen Datenbank nicht bestimmen." )
					break

				self.epsg = int( qry.value(0) )

			self.logqry = QSqlQuery(self.db)
			if not self.logqry.prepare( "INSERT INTO alkis_importlog(msg) VALUES (?)" ):
				self.log( u"Konnte Protokollierungsanweisung nicht vorbereiten [%s]" % qry.lastError().text() )
				self.logqry = None
				break

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
				m = re.search( "GDAL (\d+)\.(\d+)", self.lwProtocol.item( i ).text() )
				if m:
					break

			if not m:
				self.log(u"GDAL-Version nicht gefunden")
				break

			convertToLinear = int(m.group(1)) > 1

			if not self.runProcess([self.ogr2ogr, "--utility_version"]):
				self.log(u"Konnte ogr2ogr-Bibliotheksversion nicht abfragen!")
				break

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
				self.status( u"Bestimme Gesamtgröße des Imports..." )

				self.pbProgress.setRange( 0, self.lstFiles.count() )

				sizes={}

				ts = 0
				for i in range(self.lstFiles.count()):
					self.pbProgress.setValue( i )
					item = self.lstFiles.item(i)
					fn = unicode( item.text() )

					if fn[-4:].lower() == ".xml":
						s = os.path.getsize(fn)
						sizes[ fn ] = s

					elif fn[-4:].lower() == ".zip":
						l = -8 if fn[-8:].lower() == ".xml.zip" else -4
						self.status( u"%s wird abgefragt..." % fn )
						app.processEvents()

						f = zipfile.ZipFile(fn, "r")
						il = f.infolist()
						if len(il) <> 1:
							raise ProcessError(u"ZIP-Archiv %s enthält mehr als eine Datei!" % fn)
						s = il[0].file_size
						sizes[ fn[:l] + ".xml" ] = s

					elif fn[-7:].lower() == ".xml.gz":
						self.status( u"%s wird abgefragt..." % fn )

						f = gzip.open(fn)
						s = 0
						while True:
							chunk = f.read( 1024*1024 )
							if not chunk:
								break
							s = s + len( chunk )
						f.close()
						sizes[ fn[:-3] ] = s

					ts += s

					if self.canceled:
						break

				if self.canceled:
					break

				self.log( u"Gesamtgröße des Imports: %s" % self.memunits(ts) )

				self.pbProgress.setRange( 0, 10000 )
				self.pbProgress.setValue( 0 )

				if self.cbxCreate.isChecked():
					self.status( u"Datenbestand wird angelegt..." )
					if not self.runSQLScript( conn, "alkis-schema.sql" ):
						self.log( u"Anlegen des Datenbestands schlug fehl." )
						break
					self.log( u"Datenbestand angelegt." )

					self.status( u"Signaturen werden importiert..." )
					if not self.runSQLScript( conn, "alkis-signaturen.sql" ):
						self.log( u"Import der Signaturen schlug fehl." )
						break
					self.log( u"Signaturen importiert." )

					self.status( u"Präsentationstabellen werden erzeugt..." )
					if not self.runSQLScript( conn, "alkis-po-tables.sql" ):
						self.log( u"Anlegen der Präsentationstabellen schlug fehl." )
						break
					self.log( u"Präsentationstabellen angelegt." )

					self.cbxCreate.setChecked( False )
				else:
					self.status( u"Datenbankschema wird geprüft..." )
					if not self.runSQLScript( conn, "alkis-update.sql" ):
						self.log( u"Schemaprüfung schlug fehl." )
						break

				ok = True

				s = 0
				for i in range(self.lstFiles.count()):
					if self.canceled:
						self.log( "Import abgebrochen." )
						break

					item = self.lstFiles.item(i)
					self.lstFiles.setCurrentItem( item )

					fn = unicode( item.text() )

					src = ""
					if fn[-7:] == ".xml.gz":
						src = fn[:-3]
						size = sizes[ src ]

						self.status( u"%s wird extrahiert." % fn )
						app.processEvents()

						src = os.path.join( tempfile.gettempdir(), os.path.basename(src) )

						f_in = gzip.open(fn)
						f_out = open(src, "wb")
						while True:
							chunk = f_in.read( 1024*1024 )
							if not chunk:
								break

							f_out.write( chunk )

						f_out.close()
						f_in.close()

						self.logDb( u"%s wurde entpackt." % fn )

					elif fn[-4:] == ".zip":
						src = fn[:-4] + ".xml"
						size = sizes[ src ]

						self.status( u"%s wird extrahiert." % fn )
						app.processEvents()

						src = os.path.join( tempfile.gettempdir(), os.path.basename(src) )

						zipf = zipfile.ZipFile(fn, "r")
						f_in = zipf.open( zipf.infolist()[0].filename )
						f_out = open(src, "wb")
						while True:
							chunk = f_in.read( 1024*1024 )
							if not chunk:
								break

							f_out.write( chunk )
						f_out.close()
						f_in.close()
						zipf.close()

						self.logDb( u"%s wurde entpackt." % fn )

					else:
						src = fn
						size = sizes[ fn ]

					try:
						os.unlink( src[:-4] + ".gfs" )
					except OSError, e:
						pass

					#if size==623 or size==712:
					#	item.setSelected( True )
					#	self.log( u"Kurze Datei %s übersprungen." % fn )
					#	continue

					if self.epsg==131466 or self.epsg==131467 or self.epsg==131468:
						srs = "+init=custom:%d" % self.epsg
						os.putenv( "PROJ_LIB", "." )
					else:
						srs = "EPSG:%d" % self.epsg

					args = [self.ogr2ogr,
						"-f", "PostgreSQL",
						"-append",
						"-update",
						"PG:%s" % conn,
						"-a_srs", srs,
						"-gt", self.leGT.text()
						]

					if self.cbxSkipFailures.isChecked():
						args.append("-skipfailures")

					if self.cbxUseCopy.isChecked():
						args.extend( ["--config", "PG_USE_COPY", "YES" ] )

					if convertToLinear:
						args.extend( ["-nlt", "CONVERT_TO_LINEAR" ] )

					args.append(src)

					self.status( u"%s mit %s wird importiert..." % (fn, self.memunits(size) ) )

					t1 = QTime()
					t1.start()

					ok = self.runProcess(args)

					elapsed = t1.elapsed()

					if elapsed>0:
						throughput = " (%s/s)" % self.memunits( size * 1000 / elapsed )
					else:
						throughput = ""

					self.log( u"%s mit %s in %s importiert%s" % (
							fn,
							self.memunits( size ),
							self.timeunits( elapsed ),
							throughput
						) )

					item.setSelected( ok )
					if src <> fn and os.path.exists(src):
						os.unlink( src )

					s = s + size
					self.pbProgress.setValue( 10000 * s / ts )

					remaining_data = ts - s
					remaining_time = remaining_data * t0.elapsed() / s

					self.alive.setText( "Noch %s in etwa %s\nETA: %s -" % (
								self.memunits( remaining_data ),
								self.timeunits( remaining_time ),
								QDateTime.currentDateTime().addMSecs( remaining_time ).toString( Qt.ISODate )
							) )

					app.processEvents()

					if not ok:
						self.status( u"Fehler bei %s." % fn )
						break

				self.pbProgress.setValue( 10000 )

				if ok and self.lstFiles.count()>0:
					self.log( u"Alle NAS-Dateien importiert." )

				if ok:
					self.status( u"Kompatibilitätsfunktionen werden importiert..." )
					ok = self.runSQLScript( conn, "alkis-compat.sql" )
					if ok:
						self.log( u"Kompatibilitätsfunktionen importiert." )

				if ok:
					self.status( u"Ableitungsregeln werden verarbeitet..." )
					ok = self.runSQLScript( conn, "alkis-ableitungsregeln.sql" )
					if ok:
						self.log( u"Ableitungsregeln verarbeitet." )

				if ok:
					for f in glob.glob("postprocessing.d/*.sql"):
						self.status( u"Nachverarbeitungsskript %s wird gestartet..." % f )
						ok = self.runSQLScript( conn, f )
						if ok:
							self.log( u"Nachverarbeitungsskript %s ausgeführt." % f )

				if ok:
					self.status( u"VACUUM..." )
					ok = self.db.exec_( "VACUUM" )
					if ok:
						self.log( u"VACUUM abgeschlossen." )

				if ok:
					self.log( u"Import nach %s erfolgreich beendet." % self.timeunits( t0.elapsed() ) )
				else:
					self.log( u"Import nach %s abgebrochen." % self.timeunits( t0.elapsed() ) )

			except Exception, e:
				exc_type, exc_value, exc_traceback = sys.exc_info()
				err = u"\n> ".join( traceback.format_exception( exc_type, exc_value, exc_traceback ) )
				if sys.stdout:
					print err
				self.log( u"Abbruch nach Fehler\n> %s" % unicode(err) )

			break

		self.status("")
		self.alive.setText( "-" )

		self.pbStart.clicked.disconnect(self.cancel)
		self.pbStart.clicked.connect(self.run)
		self.pbStart.setText( "Start" )

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
