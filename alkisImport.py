#!/usr/bin/python
# -*- coding: utf8 -*-

import sys
import os
import traceback
import tempfile
import zipfile
import gzip
import re
import tempfile

from PyQt4.QtCore import QSettings, QProcess, QString, QVariant, QStringList, QFile, QDir, QFileInfo, QIODevice, Qt, QDateTime, QTime
from PyQt4.QtGui import QApplication, QDialog, QIcon, QFileDialog, QMessageBox
from PyQt4.QtSql import QSqlDatabase, QSqlQuery, QSqlError, QSql

from alkisImportDlg import Ui_Dialog

# Felder als String interpretieren (führende Nullen nicht abschneiden)
os.putenv("GML_FIELDTYPES", "ALWAYS_STRING")

# Warnen, wenn numerische Felder mit alphanumerischen Werten gefällt werden sollen
os.putenv("OGR_SETFIELD_NUMERIC_WARNING", "ON")

# Mindestlänge für Kreisbogensegmente
os.putenv("OGR_ARC_MINLENGTH", "0.1" )

os.putenv("PGCLIENTENCODING", "UTF8" )

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
			files.extend( getFiles( pattern, fi.filePath() ) )
		elif re.search( pattern, f):
			files.append( os.path.abspath( fi.filePath() ) )

	return files

class ProcessError(Exception):
	def __init__(self, msg):
		self.msg = msg

	def __str__(self):
		return unicode(msg)

class alkisImportDlg(QDialog, Ui_Dialog):

	def __init__(self):
		QDialog.__init__(self)
		self.setupUi(self)
		self.setWindowIcon( QIcon('logo.png') )
		self.setWindowFlags( Qt.WindowMinimizeButtonHint )

		s = QSettings( "norBIT", "norGIS-ALKIS-Import" )

		self.leSERVICE.setText( s.value( "service", "" ).toString() )
		self.leHOST.setText( s.value( "host", "" ).toString() )
		self.lePORT.setText( s.value( "port", "5432" ).toString() )
		self.leDBNAME.setText( s.value( "dbname", "" ).toString() )
		self.leUID.setText( s.value( "uid", "" ).toString() )
		self.lePWD.setText( s.value( "pwd", "" ).toString() )
		self.lstFiles.addItems( s.value( "files", QVariant.fromList( QStringList() ) ).toStringList() )
		self.cbxSkipFailures.setChecked( s.value( "skipfailures", False ).toBool() )
		self.cbxDebug.setChecked( s.value( "debug", False ).toBool() )

		self.albDSN.setText( s.value( "albDSN", "" ).toString() )
		self.albUID.setText( s.value( "albUID", "" ).toString() )
		self.albPWD.setText( s.value( "albPWD", "" ).toString() )

		self.pbAdd.clicked.connect(self.selFiles)
		self.pbAddDir.clicked.connect(self.selDir)
		self.pbRemove.clicked.connect(self.rmFiles)
		self.pbLoad.clicked.connect(self.loadList)
		self.pbSave.clicked.connect(self.saveList)
		self.lstFiles.itemSelectionChanged.connect(self.selChanged)

		# Bottom
		self.pbStart.clicked.connect(self.run)
		self.pbSaveLog.clicked.connect(self.saveLog)
		self.pbClearLog.clicked.connect(self.clearLog)
		self.pbClose.clicked.connect(self.accept)
		self.pbProgress.setValue( 0 )

		self.status("")

		self.canceled = False
		self.running = False
		self.logqry = None


	def loadRe(self):
		f = open("re", "r")
		self.reFilter = re.compile( f.read().strip("\n").replace("\n","|") )
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
		lastDir = s.value( "lastDir", "." ).toString()

		files = QFileDialog.getOpenFileNames( self, u"NAS-Dateien wählen", lastDir, "NAS-Dateien (*.xml *.xml.gz *.zip)")
		if files is None:
			return

		dirs = []

		for f in files:
			f = os.path.abspath(f)
			self.lstFiles.addItem( f )
			dirs.append( os.path.dirname( f ) )

		s.setValue( "lastDir", os.path.commonprefix( dirs ) )

	def selDir(self):
		s = QSettings( "norBIT", "norGIS-ALKIS-Import" )
		lastDir = s.value( "lastDir", "." ).toString()

		dir = QFileDialog.getExistingDirectory( self, u"Verzeichnis mit NAS-Dateien wählen", lastDir )
		if dir is None: 
			return

		s.setValue( "lastDir", dir )

		QApplication.setOverrideCursor( Qt.WaitCursor )

		self.status( "Verzeichnis wird durchsucht..." )

		self.lstFiles.addItems( sorted( getFiles( "\.(xml|xml\.gz|zip)$", dir ) ) )

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

		if len(msg)>300:
			msg=msg[:300] + "..."

		self.lwProtocol.addItem( QDateTime.currentDateTime().toString( Qt.ISODate ) + " " + msg )

		app.processEvents()
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

	def saveLog(self):
		save = QFileDialog.getSaveFileName(self, u"Protokolldatei angeben", ".", "Protokoll-Dateien (*.log)" )
		if save is None:
			return

		f = QFile(save)
		if not f.open( QIODevice.WriteOnly ):
			return

		for i in range(0, self.lwProtocol.count()):
			f.write( self.lwProtocol.item(i).text().toLocal8Bit() )
			f.write( "\n" )
		f.close()

	def clearLog(self):
		self.lwProtocol.clear()

	def accept(self):
		if not self.running:
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
		if self.reFilter.match(l):
			return False
		else:
			return True

	def processOutput(self, current, output):
		if output.isEmpty():
			return

		if not current:
			current = ""

		r = QString.fromUtf8( output )

		lines = r.split("\n")

		if not r.endsWith("\n"):
			lastline = lines.takeLast()
		else:
			lastline = ""

		if current<>"" and lines.count()>0:
			if r.startsWith("\n"):
				lines.prepend( current )
			else:
				lines[0].prepend( current )
			current = ""

		for l in lines:
			l = unicode( l )
			if self.keep(l):
				self.log( "> %s|" % l )
			else:
				self.logDb( l )

		return current + lastline

	def runProcess(self, args):
		self.logDb( "BEFEHL: '%s'" % ( "' '".join(args) ) )

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
			self.log( "Prozess abgebrochen %d" % p.exitCode() )

		self.logDb( "EXITCODE: %d" % p.exitCode() )

		p.close()

		return ok


	def runSQLScript(self, conn, fn):
		return self.runProcess([self.psql, "-q", "-f", fn, conn])


	def run(self):
		if self.tabWidget.currentIndex()==0:
			self.importALKIS()
		else:
			self.importUserData()

	def importALKIS(self):
		if self.cbxDebug.isChecked():
			os.putenv("CPL_DEBUG", "ON" )
		else:
			os.putenv("CPL_DEBUG", "" )

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
		s.setValue( "files", files )
		s.setValue( "skipfailures", self.cbxSkipFailures.isChecked() )
		s.setValue( "debug", self.cbxDebug.isChecked() )

		if self.leSERVICE.text()<>'':
			conn = "service=%s " % self.leSERVICE.text()
		else:
			if self.leHOST.text()<>'':
				conn = "host=%s port=%s " % (self.leHOST.text(), self.lePORT.text() )
			else:
				conn = ""

		conn += "dbname=%s user='%s' password='%s'" % (self.leDBNAME.text(), self.leUID.text(), self.lePWD.text() )

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

		self.lwProtocol.setUniformItemSizes(True)

		self.lstFiles.itemSelectionChanged.disconnect(self.selChanged)

		QApplication.setOverrideCursor( Qt.WaitCursor )

		while True:
			t0 = QTime()
			t0.start()

			self.loadRe()

			self.lstFiles.clearSelection()

			self.db = QSqlDatabase.addDatabase( "QPSQL" )
			self.db.setConnectOptions( conn )
			if not self.db.open():
				self.log(u"Konnte Datenbankverbindung nicht aufbauen!")
				break

			qry = self.db.exec_( "SET application_name='ALKIS-Import - Frontend" )

			qry = self.db.exec_( "SELECT version()" )

			if not qry or not qry.next():
				self.log(u"Konnte PostgreSQL-Version nicht bestimmen!")
				break

			self.log( "PostgreSQL-Version: %s" % qry.value(0).toString() )

			qry = self.db.exec_( "SELECT postgis_version()" )
			if not qry or not qry.next():
				self.log(u"Konnte PostGIS-Version nicht bestimmen!")
				break

			self.log( "PostGIS-Version: %s" % qry.value(0).toString() )

			qry = self.db.exec_( "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public' AND table_name='alkis_importlog'" )
			if not qry or not qry.next():
				self.log( u"Konnte Existenz von Protokolltabelle nicht überprüfen." )
				break

			if qry.value(0).toInt()[0] == 0:
				qry = self.db.exec_( "CREATE TABLE alkis_importlog(n SERIAL PRIMARY KEY, ts timestamp default now(), msg text)" )
				if not qry:
					self.log( u"Konnte Protokolltabelle nicht anlegen [%s]" % qry.lastError().text() )
					break

			qry = self.db.exec_( "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public' AND table_name='alkis_beziehungen'" )
			if not qry or not qry.next():
				self.log( u"Konnte Existenz des ALKIS-Schema nicht überprüfen." )
				break

			if not self.cbxCreate.isChecked() and qry.value(0).toInt()[0] == 0:
				self.cbxCreate.setChecked( True )
				self.log( u"ALKIS-Daten nicht nicht vorhanden - Datenbank muß angelegt werden." )
				break

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

			if not self.runProcess([self.ogr2ogr, "--version"]):
				self.log(u"Konnte ogr2ogr-Version nicht abfragen!")
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

					if fn[-4:] == ".xml":
						s = os.path.getsize(fn)
						sizes[ fn ] = s

					elif fn[-4:] == ".zip":
						self.status( u"%s wird abgefragt..." % fn )
						app.processEvents()

						f = zipfile.ZipFile(fn, "r")
						il = f.infolist()
						if len(il) <> 1:
							raise ProcessError(u"ZIP-Archiv %s enthält mehr als eine Datei!" % fn)
						s = il[0].file_size
						sizes[ fn[:-4] + ".xml" ] = s

					elif fn[-7:] == ".xml.gz":
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
					self.status( u"Datenbank wird angelegt..." )
					if not self.runSQLScript( conn, "alkis-schema.sql" ):
						raise ProcessError(u"Anlegen der Datenbank schlug fehl.")
					self.status( u"KompatibilitÃ¤tsfunktionen werden importiert..." )
					if not self.runSQLScript( conn, "alkis-compat.sql" ):
						raise ProcessError(u"Import der KompatibilitÃtsfunktionen schlug fehl.")
					self.cbxCreate.setChecked( False )
					self.log( u"Datenbank angelegt." )

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
					except:
						pass

					if size==623:
						item.setSelected( True )
						self.log( u"Kurze Datei %s übersprungen." % fn )
						continue

					args = [self.ogr2ogr,
						"-f", "PostgreSQL",
						"-append",
						"-update",
						"PG:%s" % conn,
						"-a_srs", "EPSG:25832",
						]

					if self.cbxSkipFailures.isChecked():
						args.append("-skipfailures")

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
					self.status( u"Signaturen werden importiert..." )
					ok = self.runSQLScript( conn, "alkis-signaturen.sql" )
					if ok:
						self.log( "Signaturen importiert." )
					else:
						self.log( "Signaturen importiert." )

				if ok:
					self.status( u"Ableitungsregeln werden verarbeitet..." )
					ok = self.runSQLScript( conn, "alkis-ableitungsregeln.sql" )
					if ok:
						self.log( "Ableitungsregeln verarbeitet." )

				if ok:
					self.status( u"Liegenschaftsbuch-Daten werden übernommen..." )
					ok = self.runSQLScript( conn, "nas2alb.sql" )
					if ok:
						self.log( u"Liegenschaftsbuch-Daten übernommen." )

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

		self.lwProtocol.setUniformItemSizes(False)

		self.lstFiles.itemSelectionChanged.connect(self.selChanged)

		QApplication.restoreOverrideCursor()

		self.logqry = None
		self.running = False

		self.db.close()
		self.db = None

	def importUserData(self):
		if self.leSERVICE.text()<>'':
			conn = "service=%s " % self.leSERVICE.text()
		else:
			if self.leHOST.text()<>'':
				conn = "host=%s port=%s " % (self.leHOST.text(), self.lePORT.text() )
			else:
				conn = ""

		conn += "dbname=%s user='%s' password='%s'" % (self.leDBNAME.text(), self.leUID.text(), self.lePWD.text() )

		dstDb = QSqlDatabase.addDatabase( "QPSQL", "DST" )
		dstDb.setConnectOptions( conn )
		if not dstDb.open():
			self.log(u"Konnte Verbindung zur ALKIS-Datenbank nicht aufbauen!")
			return

		qry = dstDb.exec_( "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public' AND table_name='user_daten'" )
		if not qry or not qry.next():
			self.log( u"Konnte Existenz von Benutzerdatentabelle nicht überprüfen." )
			return

		n = qry.value(0).toInt()[0]
		if n == 1 and self.cbxCreate.isChecked():
			if not dstDb.exec_( "DROP TABLE user_daten" ):
				self.log( u"Konnte Benutzerdatentabelle nicht löschen." )
				return
			n = 0
			
		if n == 0:
			if not dstDb.exec_( "CREATE TABLE user_daten(u_nr CHAR(20) NOT NULL PRIMARY KEY, flsnr CHAR(20), flaeche CHAR(32), thema INTEGER, az CHAR(80), dokument CHAR(80), bemerkungen CHAR(255), kundennr CHAR(20), user1 CHAR(40), user2 CHAR(40), user3 CHAR(40), user4 CHAR(40), user5 CHAR(40), user6 CHAR(40), user7 CHAR(40), user8 CHAR(40), user9 CHAR(40), user10 CHAR(40))" ) or \
			   not dstDb.exec_( "CREATE INDEX user_daten_i1 ON user_daten(flsnr)" ) or \
			   not dstDb.exec_( "CREATE INDEX user_daten_i2 ON user_daten(kundennr)" ) or \
			   not dstDb.exec_( "CREATE INDEX user_daten_i3 ON user_daten(thema)" ):
				self.log( u"Konnte Benutzerdatentabelle nicht anlegen. [%s: %s]" % (dstDb.lastError().text(), dstDb.executedQuery()) )
				return

		insud = QSqlQuery(dstDb)
		if not insud.prepare( "INSERT INTO user_daten(u_nr,flsnr,flaeche,thema,az,dokument,bemerkungen,kundennr,user1,user2,user3,user4,user5,user6,user7,user8,user9,user10) VALUES (:u_nr,:flsnr,:flaeche,:thema,:az,:dokument,:bemerkungen,:kundennr,:user1,:user2,:user3,:user4,:user5,:user6,:user7,:user8,:user9,:user10)" ):
			self.log( u"Konnte Einfügeanweisung nicht vorbereiten [%s]" % insud.lastError().text() )
			return

		s = QSettings( "norBIT", "norGIS-ALKIS-Import" )
		s.setValue( "service", self.leSERVICE.text() )
		s.setValue( "host", self.leHOST.text() )
		s.setValue( "port", self.lePORT.text() )
		s.setValue( "dbname", self.leDBNAME.text() )
		s.setValue( "uid", self.leUID.text() )
		s.setValue( "pwd", self.lePWD.text() )

		srcDb = QSqlDatabase.addDatabase( "QODBC", "SRC" )
		srcDb.setDatabaseName( self.albDSN.text() )
		srcDb.setUserName( self.albUID.text() )
		srcDb.setPassword( self.albPWD.text() )
		if not srcDb.open():
			self.log(u"Konnte Verbindung zur ALB-Datenbank nicht aufbauen!")
			return

		s.setValue( "albDSN", self.albDSN.text() )
		s.setValue( "albUID", self.albUID.text() )
		s.setValue( "albPWD", self.albPWD.text() )

		selud = QSqlQuery(srcDb)
		if not selud.exec_( "SELECT u_nr,flsnr,flaeche,thema,az,dokument,bemerkungen,kundennr,user1,user2,user3,user4,user5,user6,user7,user8,user9,user10 FROM user_daten" ):
			self.log( u"Konnte Abfrage nicht vorbereiten [%s]" % selud.lastError().text() )
			return

		QApplication.setOverrideCursor( Qt.WaitCursor )

		i = 1
		while selud.next():
			for c in range(18):
				insud.addBindValue( selud.value(c) )
			if not insud.exec_():
				self.log( u"Benutzerdatensatz %d konnte nicht eingefügt werden [%s/%s]" % (i, insud.lastError().text(), insud.executedQuery()) )
				i -= 1
				break
			i += 1

		self.log( u"%d Benutzerdatensätze kopiert." % i )

		QApplication.restoreOverrideCursor()

		selud = None
		insud = None
		srcDb = None
		dstDb = None

app = QApplication(sys.argv)
dlg = alkisImportDlg()
dlg.exec_()
