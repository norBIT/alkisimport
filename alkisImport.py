#! /usr/bin/env python
# -*- coding: utf8 -*-

from __future__ import unicode_literals

"""
***************************************************************************
    alkisImport.py
    ---------------------
    Date                 : Sep 2012
    Copyright            : (C) 2012-2023 by Jürgen Fischer
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

try:
    import sip
    for c in ["QDate", "QDateTime", "QString", "QTextStream", "QTime", "QUrl", "QVariant"]:
        sip.setapi(c, 2)
except ImportError:
    pass

import sys
import os
import fnmatch
import traceback
import gzip
import re

from zipfile import ZipFile
from itertools import islice
from ffdate import getdate

try:
    from PyQt4.QtCore import QSettings, QProcess, QDir, QFileInfo, Qt, QDateTime, QElapsedTimer, QByteArray
    from PyQt4.QtGui import QApplication, QDialog, QIcon, QFileDialog, QMessageBox, QFont, QIntValidator, QListWidgetItem
    from PyQt4.QtSql import QSqlDatabase, QSqlQuery
    from PyQt4 import uic
except ImportError:
    from PyQt5.QtCore import QSettings, QProcess, QDir, QFileInfo, Qt, QDateTime, QElapsedTimer, QByteArray
    from PyQt5.QtGui import QIcon, QFont, QIntValidator
    from PyQt5.QtWidgets import QApplication, QDialog, QFileDialog, QMessageBox, QListWidgetItem
    from PyQt5.QtSql import QSqlDatabase, QSqlQuery
    from PyQt5 import uic

BASEDIR = os.path.dirname(__file__)
sys.path.insert(0, BASEDIR)
alkisImportDlgBase = uic.loadUiType(os.path.join(BASEDIR, 'alkisImportDlg.ui'))[0]
aboutDlgBase = uic.loadUiType(os.path.join(BASEDIR, 'about.ui'))[0]
sys.path.pop(0)

TEMP = os.getenv("TEMP")
if not TEMP:
    from tempfile import gettempdir
    TEMP = gettempdir()

# Felder als String interpretieren (d.h. führende Nullen nicht abschneiden)
os.putenv("GML_FIELDTYPES", "ALWAYS_STRING")

# Warnen, wenn numerische Felder mit alphanumerischen Werten gefüllt werden sollen
os.putenv("OGR_SETFIELD_NUMERIC_WARNING", "ON")

# Mindestlänge für Kreisbogensegmente
os.putenv("OGR_ARC_MINLENGTH", "0.1")

# Headerkennungen die NAS-Daten identifizieren
os.putenv("NAS_INDICATOR", "NAS-Operationen;AAA-Fachschema;aaa.xsd;aaa-suite;adv/gid/6.0")

os.putenv("PGCLIENTENCODING", "UTF8")

os.putenv("OGR_PG_RETRIEVE_FID", "OFF")


os.putenv("NAS_SKIP_CORRUPTED_FEATURES", "YES")
os.putenv("TABLES", "aa_advstandardmodell,aa_nas_ausgabeform,nas_filter_capabilities,aa_themendimension,aa_art_themendefinition,operation,ap_horizontaleausrichtung,ap_vertikaleausrichtung,ap_dateityp_3d,ax_artdesnullpunktes_nullpunkt,ax_li_processstep_mitdatenerhebung_description,ax_datenerhebung,ax_sportart_bauwerkoderanlagefuersportfreizeitunderholung,ax_lagezurerdoberflaeche_transportanlage,ax_produkt_transportanlage,ax_bauwerksfunktion_turm,ax_hydrologischesmerkmal_sonstigesbauwerkodersonstigeeinri,ax_zustand_turm,ax_art_heilquellegasquelle,ax_bauwerksfunktion_transportanlage,ax_lagezurerdoberflaeche_vorratsbehaelterspeicherbauwerk,ax_speicherinhalt_vorratsbehaelterspeicherbauwerk,ax_bauwerksfunktion_bauwerkoderanlagefuerindustrieundgewer,ax_art_einrichtunginoeffentlichenbereichen,ax_bauwerksfunktion_bauwerkoderanlagefuersportfreizeitunde,ax_archaeologischertyp_historischesbauwerkoderhistorischee,ax_hydrologischesmerkmal_heilquellegasquelle,ax_zustand_bauwerkoderanlagefuerindustrieundgewerbe,ax_bauwerksfunktion_sonstigesbauwerkodersonstigeeinrichtun,ax_funktion_bauwerk,ax_bauwerksfunktion_leitung,ax_bauwerksfunktion_vorratsbehaelterspeicherbauwerk,ax_befestigung_wegpfadsteig,ax_oberflaechenmaterial_flugverkehrsanlage,ax_art_gleis,ax_bahnkategorie_gleis,ax_art_strassenverkehrsanlage,ax_markierung_wegpfadsteig,ax_bahnhofskategorie_bahnverkehrsanlage,ax_bahnkategorie_seilbahnschwebebahn,ax_zustand_bahnverkehrsanlage,ax_zustand_bauwerkimgewaesserbereich,ax_art_wegpfadsteig,ax_lagezuroberflaeche_gleis,ax_art_flugverkehrsanlage,ax_bauwerksfunktion_bauwerkimverkehrsbereich,ax_bauwerksfunktion_bauwerkimgewaesserbereich,ax_art_einrichtungenfuerdenschiffsverkehr,ax_zustand_bauwerkimverkehrsbereich,ax_artdergewaesserachse,ax_art_schifffahrtsliniefaehrverkehr,ax_zustand_schleuse,ax_nutzung_hafen,ax_konstruktionsmerkmalbauart_schleuse,ax_hafenkategorie_hafen,ax_art_gewaessermerkmal,ax_hydrologischesmerkmal_untergeordnetesgewaesser,ax_lagezurerdoberflaeche_untergeordnetesgewaesser,ax_artdespolders,ax_funktion_polder,ax_funktion_untergeordnetesgewaesser,ax_hydrologischesmerkmal_gewaessermerkmal,ax_funktion_vegetationsmerkmal,ax_zustand_vegetationsmerkmal,ax_bewuchs_vegetationsmerkmal,ax_eigentuemerart_namensnummer,ax_li_processstep_ohnedatenerhebung_description,ax_blattart_buchungsblatt,ax_anrede_person,ax_artderrechtsgemeinschaft_namensnummer,ax_buchungsart_buchungsstelle,ax_klassifikation_hierarchiestufe3d_lagefestpunkt,ax_punktstabilitaet,ax_punktstabilitaet_hoehenfestpunkt_geologischestabilitaet,ax_klassifikation_ordnung_lagefestpunkt,ax_punktstabilitaet_hoehenfestpunkt_guetedesvermarkungstra,ax_ordnung_schwerefestpunkt,ax_funktion_referenzstationspunkt,ax_funktion_lagefestpunkt,ax_skizzenart_skizze,ax_funktion_schwerefestpunkt,ax_punktstabilitaet_hoehenfestpunkt_hoehenstabilitaetauswi,ax_punktstabilitaet_hoehenfestpunkt_guetedesbaugrundes,ax_punktstabilitaet_hoehenfestpunkt_grundwasserschwankung,ax_punktstabilitaet_hoehenfestpunkt_topographieundumwelt,ax_klassifikation_wertigkeit_lagefestpunkt,ax_gnsstauglichkeit,ax_punktstabilitaet_hoehenfestpunkt_grundwasserstand,ax_punktstabilitaet_hoehenfestpunkt_vermutetehoehenstabili,ax_ordnung_hoehenfestpunkt,ax_horizontfreiheit_grenzpunkt,ax_gruendederausgesetztenabmarkung_grenzpunkt,ax_bemerkungzurabmarkung_grenzpunkt,ax_artderflurstuecksgrenze_besondereflurstuecksgrenze,ax_horizontfreiheit_netzpunkt,ax_marke,ax_genauigkeitsstufe_punktort,ax_messmethode_schwere,ax_koordinatenstatus_punktort,ax_datenerhebung_schwere,ax_vertrauenswuerdigkeit_schwere,ax_schwereanomalie_schwere_art,ax_vertrauenswuerdigkeit_punktort,ax_schwerestatus_schwere,ax_li_processstep_punktort_description,ax_genauigkeitsstufe_schwere,ax_datenerhebung_punktort,ax_schweresystem_schwere,ax_blattart_historischesflurstueck,ax_qualitaet_hauskoordinate,ax_art_punktkennung,ax_art_reservierung,ax_art_adressat_auszug,ax_lagezurerdoberflaeche_bauteil,ax_lagezurerdoberflaeche_gebaeude,ax_zustand_gebaeude,ax_dachgeschossausbau_gebaeude,ax_dachform,ax_bauweise_gebaeude,ax_gebaeudefunktion,ax_art_gebaeudepunkt,ax_weitere_gebaeudefunktion,ax_beschaffenheit_besonderegebaeudelinie,ax_bauart_bauteil,ax_nutzung,ax_art_verbandsgemeinde,ax_art_baublock,ax_artdergebietsgrenze_gebietsgrenze,ax_sonstigeangaben_bodenschaetzung,ax_kulturart_musterlandesmusterundvergleichsstueck,ax_entstehungsartoderklimastufewasserverhaeltnisse_bodensc,ax_sonstigeangaben_musterlandesmusterundvergleichsstueck,ax_kulturart_bodenschaetzung,ax_klassifizierung_bewertung,ax_merkmal_musterlandesmusterundvergleichsstueck,ax_zustandsstufeoderbodenstufe_bodenschaetzung,ax_bedeutung_grablochderbodenschaetzung,ax_zustandsstufeoderbodenstufe_musterlandesmusterundvergle,ax_entstehungsartoderklimastufewasserverhaeltnisse_musterl,ax_bodenart_bodenschaetzung,ax_bodenart_musterlandesmusterundvergleichsstueck,ax_landschaftstyp,ax_art_verband,ax_behoerde,ax_administrative_funktion,ax_bezeichnung_verwaltungsgemeinschaft,ax_funktion_schutzgebietnachwasserrecht,ax_artderfestlegung_schutzgebietnachnaturumweltoderbodensc,ax_artderfestlegung_anderefestlegungnachstrassenrecht,ax_artderfestlegung_schutzgebietnachwasserrecht,ax_besonderefunktion_forstrecht,ax_zone_schutzzone,ax_artderfestlegung_klassifizierungnachstrassenrecht,ax_artderfestlegung_denkmalschutzrecht,ax_artderfestlegung_klassifizierungnachwasserrecht,ax_rechtszustand_schutzzone,ax_artderfestlegung_bauraumoderbodenordnungsrecht,ax_artderfestlegung_anderefestlegungnachwasserrecht,ax_artderfestlegung_forstrecht,ax_zustand_naturumweltoderbodenschutzrecht,ax_artderfestlegung_sonstigesrecht,ax_artderfestlegung_naturumweltoderbodenschutzrecht,ax_liniendarstellung_topographischelinie,ax_darstellung_gebaeudeausgestaltung,ax_datenformat_benutzer,ax_art_bereichzeitlich,ax_letzteabgabeart,ax_ausgabemedium_benutzer,ax_identifikation,ax_dqerfassungsmethodemarkantergelaendepunkt,ax_dqerfassungsmethodestrukturiertegelaendepunkte,ax_dqerfassungsmethode,ax_besonderebedeutung,ax_dqerfassungsmethodebesondererhoehenpunkt,ax_artdergeripplinie,ax_artdergelaendekante,ax_artderstrukturierung,ax_dqerfassungsmethodegewaesserbegrenzung,ax_artdernichtgelaendepunkte,ax_artdesmarkantengelaendepunktes,ax_artderaussparung,ax_besondereartdergewaesserbegrenzung,ax_ursprung,ax_funktion_dammwalldeich,ax_art_dammwalldeich,ax_funktion_einschnitt,ax_zustand_boeschungkliff,ax_zustand_hoehleneingang,ax_berechnungsmethode,ax_verwendeteobjekte,ax_berechnungsmethodehoehenlinie,ax_dqerfassungsmethodesekundaeresdgm,ax_zustand_kanal,ax_funktion_stehendesgewaesser,ax_schifffahrtskategorie,ax_hydrologischesmerkmal_fliessgewaesser,ax_schifffahrtskategorie_kanal,ax_funktion_fliessgewaesser,ax_widmung_wasserlauf,ax_funktion_meer,ax_hydrologischesmerkmal_gewaesserachse,ax_tidemerkmal_meer,ax_nutzung_hafenbecken,ax_hydrologischesmerkmal_stehendesgewaesser,ax_widmung_stehendesgewaesser,ax_funktion_gewaesserachse,ax_funktion_hafenbecken,ax_widmung_kanal,ax_zustand_wohnbauflaeche,ax_artderbebauung_wohnbauflaeche,ax_zustand_flaechebesondererfunktionalerpraegung,ax_funktion_flaechegemischternutzung,ax_foerdergut_industrieundgewerbeflaeche,ax_artderbebauung_flaechegemischternutzung,ax_zustand_sportfreizeitunderholungsflaeche,ax_funktion_flaechebesondererfunktionalerpraegung,ax_funktion_sportfreizeitunderholungsflaeche,ax_lagergut_industrieundgewerbeflaeche,ax_zustand_halde,ax_zustand_bergbaubetrieb,ax_abbaugut_tagebaugrubesteinbruch,ax_primaerenergie_industrieundgewerbeflaeche,ax_abbaugut_bergbaubetrieb,ax_zustand_flaechegemischternutzung,ax_zustand_industrieundgewerbeflaeche,ax_funktion_friedhof,ax_zustand_friedhof,ax_lagergut_halde,ax_funktion_industrieundgewerbeflaeche,ax_zustand_tagebaugrubesteinbruch,ax_artderbebauung_siedlungsflaeche,ax_artderbebauung_flaechebesondererfunktionalerpraegung,ax_vegetationsmerkmal_gehoelz,ax_vegetationsmerkmal_wald,ax_vegetationsmerkmal_landwirtschaft,ax_oberflaechenmaterial_unlandvegetationsloseflaeche,ax_funktion_unlandvegetationsloseflaeche,ax_funktion_gehoelz,ax_bahnkategorie,ax_funktion_weg,ax_funktion_bahnverkehr,ax_verkehrsbedeutunginneroertlich,ax_internationalebedeutung_strasse,ax_besonderefahrstreifen,ax_zustand_bahnverkehr,ax_befestigung_fahrwegachse,ax_spurweite,ax_zustand_schiffsverkehr,ax_funktion_platz,ax_art_flugverkehr,ax_elektrifizierung,ax_zustand,ax_fahrbahntrennung_strasse,ax_funktion_fahrbahnachse,ax_oberflaechenmaterial_strasse,ax_funktion_flugverkehr,ax_funktion_wegachse,ax_zustand_strasse,ax_markierung_wegachse,ax_zustand_flugverkehr,ax_funktion_strassenachse,ax_verkehrsbedeutungueberoertlich,ax_nutzung_flugverkehr,ax_funktion_schiffsverkehr,ax_funktion_strasse,ax_widmung_strasse,ax_anzahlderstreckengleise,ax_funktionoa_k_tngr_all,ax_klassifizierunggr_k_bewgr,ax_funktionoa_k_tnfl,ax_klassifizierungobg_k_bewfl,ax_funktionoa_k_tngrerweitert_all,ax_funktionhgr_k_tnhgr,ax_wirtschaftsart,ax_punktart_k_punkte,ax_k_zeile_punktart,aa_besonderemeilensteinkategorie,aa_anlassart,aa_levelofdetail,aa_anlassart_benutzungsauftrag,aa_weiteremodellart,aa_instanzenthemen,ax_benutzer,ax_benutzergruppemitzugriffskontrolle,ax_benutzergruppenba,ap_darstellung,aa_projektsteuerung,aa_meilenstein,aa_antrag,aa_aktivitaet,aa_vorgang,ax_person,ax_namensnummer,ax_anschrift,ax_verwaltung,ax_buchungsstelle,ax_personengruppe,ax_buchungsblatt,ax_vertretung,ax_skizze,ax_schwere,ax_historischesflurstueckalb,ax_historischesflurstueckohneraumbezug,ax_lagebezeichnungohnehausnummer,ax_lagebezeichnungmithausnummer,ax_lagebezeichnungmitpseudonummer,ax_reservierung,ax_punktkennunguntergegangen,ax_punktkennungvergleichend,ax_fortfuehrungsnachweisdeckblatt,ax_fortfuehrungsfall,ax_gemeinde,ax_buchungsblattbezirk,ax_gemarkungsteilflur,ax_kreisregion,ax_bundesland,ax_regierungsbezirk,ax_gemeindeteil,ax_lagebezeichnungkatalogeintrag,ax_gemarkung,ax_dienststelle,ax_verband,ax_nationalstaat,ax_besondererbauwerkspunkt,ax_netzknoten,ax_referenzstationspunkt,ax_lagefestpunkt,ax_hoehenfestpunkt,ax_schwerefestpunkt,ax_grenzpunkt,ax_aufnahmepunkt,ax_sonstigervermessungspunkt,ax_sicherungspunkt,ax_besonderergebaeudepunkt,ax_wirtschaftlicheeinheit,ax_verwaltungsgemeinschaft,ax_schutzgebietnachnaturumweltoderbodenschutzrecht,ax_schutzgebietnachwasserrecht,ax_boeschungkliff,ax_besonderertopographischerpunkt,ax_kanal,ax_wasserlauf,ax_strasse,ap_fpo,aa_antragsgebiet,ax_polder,ax_historischesflurstueck,ax_kondominium,ax_baublock,ax_aussparungsflaeche,ax_soll,ax_duene,ax_transportanlage,ax_wegpfadsteig,ax_gleis,ax_bahnverkehrsanlage,ax_strassenverkehrsanlage,ax_einrichtungenfuerdenschiffsverkehr,ax_flugverkehrsanlage,ax_hafen,ax_testgelaende,ax_schleuse,ax_ortslage,ax_grenzuebergang,ax_gewaessermerkmal,ax_untergeordnetesgewaesser,ax_vegetationsmerkmal,ax_musterlandesmusterundvergleichsstueck,ax_insel,ax_gewann,ax_kleinraeumigerlandschaftsteil,ax_landschaft,ax_felsenfelsblockfelsnadel,ap_lto,ax_leitung,ax_abschnitt,ax_ast,ap_lpo,ax_seilbahnschwebebahn,ax_gebaeudeausgestaltung,ax_topographischelinie,ax_geripplinie,ax_gewaesserbegrenzung,ax_strukturierterfasstegelaendepunkte,ax_einschnitt,ax_hoehenlinie,ax_abgeleitetehoehenlinie,ap_pto,ax_heilquellegasquelle,ax_wasserspiegelhoehe,ax_nullpunkt,ax_punktortau,ax_georeferenziertegebaeudeadresse,ax_grablochderbodenschaetzung,ax_wohnplatz,ax_markantergelaendepunkt,ax_besondererhoehenpunkt,ax_hoehleneingang,ap_ppo,ax_sickerstrecke,ax_firstlinie,ax_besonderegebaeudelinie,ax_gelaendekante,ax_sonstigesbauwerkodersonstigeeinrichtung,ax_bauwerkoderanlagefuersportfreizeitunderholung,ax_bauwerkoderanlagefuerindustrieundgewerbe,ax_einrichtunginoeffentlichenbereichen,ax_historischesbauwerkoderhistorischeeinrichtung,ax_turm,ax_vorratsbehaelterspeicherbauwerk,ax_bauwerkimgewaesserbereich,ax_bauwerkimverkehrsbereich,ax_schifffahrtsliniefaehrverkehr,ax_gebaeude,ax_anderefestlegungnachstrassenrecht,ax_naturumweltoderbodenschutzrecht,ax_klassifizierungnachstrassenrecht,ax_sonstigesrecht,ax_denkmalschutzrecht,ax_dammwalldeich,ax_punktortag,ax_bauteil,ax_tagesabschnitt,ax_bewertung,ax_anderefestlegungnachwasserrecht,ax_klassifizierungnachwasserrecht,ax_forstrecht,ax_bauraumoderbodenordnungsrecht,ax_schutzzone,ax_boeschungsflaeche,ax_flurstueck,ax_gebiet_kreis,ax_gebiet_bundesland,ax_gebiet_regierungsbezirk,ax_gebiet_nationalstaat,ax_kommunalesgebiet,ax_gebiet_verwaltungsgemeinschaft,ax_bodenschaetzung,ax_gewaesserstationierungsachse,ax_besondereflurstuecksgrenze,ax_gebietsgrenze,ax_gewaesserachse,ax_strassenachse,ax_bahnstrecke,ax_fahrwegachse,ax_fahrbahnachse,ax_punktortta,ax_stehendesgewaesser,ax_meer,ax_fliessgewaesser,ax_hafenbecken,ax_bergbaubetrieb,ax_friedhof,ax_flaechegemischternutzung,ax_wohnbauflaeche,ax_flaechebesondererfunktionalerpraegung,ax_industrieundgewerbeflaeche,ax_siedlungsflaeche,ax_tagebaugrubesteinbruch,ax_sportfreizeitunderholungsflaeche,ax_halde,ax_flaechezurzeitunbestimmbar,ax_sumpf,ax_unlandvegetationsloseflaeche,ax_gehoelz,ax_wald,ax_heide,ax_moor,ax_landwirtschaft,ax_bahnverkehr,ax_weg,ax_schiffsverkehr,ax_flugverkehr,ax_platz,ax_strassenverkehr,ta_compositesolidcomponent_3d,ta_surfacecomponent_3d,ta_curvecomponent_3d,ta_pointcomponent_3d,au_trianguliertesoberflaechenobjekt_3d,au_mehrfachflaechenobjekt_3d,au_mehrfachlinienobjekt_3d,au_umringobjekt_3d,ap_kpo_3d,au_punkthaufenobjekt_3d,au_koerperobjekt_3d,au_geometrieobjekt_3d,ax_fortfuehrungsauftrag,ks_einrichtunginoeffentlichenbereichen,ks_bauwerkanlagenfuerverundentsorgung,ks_sonstigesbauwerk,ks_verkehrszeichen,ks_bauwerkimgewaesserbereich,ks_vegetationsmerkmal,ks_bauraumoderbodenordnungsrecht,ks_kommunalerbesitz")
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
        self.cbxUseCopy.setChecked(s.value("usecopy", False, type=bool))
        self.cbxAvoidDupes.setChecked(s.value("avoiddupes", True, type=bool))
        self.cbxCreate.setChecked(False)
        self.cbxClean.setChecked(False)
        self.cbxHistorie.setDisabled(True)
        self.cbxHistorie.setChecked(s.value("historie", True, type=bool))
        self.cbxQuittierung.setChecked(s.value("quittierung", False, type=bool))
        self.cbxTransform.setChecked(s.value("transform", False, type=bool))

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
        self.cbEPSG.addItem("Benutzer-EPSG", "-1")

        self.pbAdd.clicked.connect(self.selFiles)
        self.pbAddDir.clicked.connect(self.selDir)
        self.pbRemove.clicked.connect(self.rmFiles)
        self.pbSelectAll.clicked.connect(self.lstFiles.selectAll)
        self.pbLoad.clicked.connect(self.loadList)
        self.pbSave.clicked.connect(self.saveList)
        self.lstFiles.itemSelectionChanged.connect(self.selChanged)
        self.cbxSkipFailures.toggled.connect(self.skipFailuresToggled)
        self.cbEPSG.currentIndexChanged.connect(self.epsgChanged)
        self.cbxCreate.toggled.connect(self.createChanged)

        epsg = s.value("epsg", "25832")
        i = self.cbEPSG.findData(epsg)
        if i == -1:
            i = self.cbEPSG.findData("-1")
            self.leCustomEpsg.setText(str(epsg))
        self.cbEPSG.setCurrentIndex(i)

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

    def createChanged(self):
        self.cbEPSG.setEnabled(self.cbxCreate.isChecked())
        self.cbxHistorie.setEnabled(self.cbxCreate.isChecked())
        self.cbxClean.setEnabled(not self.cbxCreate.isChecked())
        self.cbxTransform.setEnabled(self.cbxCreate.isChecked())
        self.epsgChanged()

    def epsgChanged(self):
        self.leCustomEpsg.setEnabled(self.cbxCreate.isChecked() and self.cbEPSG.currentIndex() == self.cbEPSG.findData("-1"))

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
        if save is None or save == "":
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

    def keep(self, line):
        if not self.reFilter:
            self.loadRe()

        for r in self.reFilter:
            if r.match(line):
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
                lines.insert(0, current)
            else:
                lines[0] = current + lines[0]
            current = ""

        for line in lines:
            if self.keep(line):
                self.log("> {}|".format(line.rstrip()))
            else:
                self.logDb(line)

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

    # INSERT…ON CONFLICT DO NOTHING nur verwendbar mit GDAL>=3.10, PostgreSQL>=9.5 und ohne COPY
    def useonconflict(self):
        return self.avoiddupes and not self.usecopy and (self.GDAL_MAJOR > 3 or (self.GDAL_MAJOR == 3 and self.GDAL_MINOR >= 10)) and (self.PG_MAJOR > 9 or (self.PG_MAJOR == 9 and self.PG_MINOR >= 5))

    def runSQLScript(self, conn, fn, parallel=False):
        # Trigger nur, wenn OGR_PG_SKIP_CONFLICTS nicht möglich ist
        avoiddupes = self.avoiddupes and not self.useonconflict()

        return self.runProcess([
            self.psql,
            "-v", "alkis_epsg={}".format(3068 if self.epsg == 13068 else self.epsg),
            "-v", "alkis_transform={}".format(self.transform),
            "-v", "alkis_schema={}".format(self.schema),
            "-v", "postgis_schema={}".format(self.pgschema),
            "-v", "parent_schema={}".format(self.parentschema if self.parentschema else self.schema),
            "-v", "alkis_fnbruch={}".format("true" if self.fnbruch else "false"),
            "-v", "alkis_pgverdraengen={}".format("true" if self.pgverdraengen else "false"),
            "-v", "alkis_avoiddupes={}".format("true" if avoiddupes else "false"),
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

        conn += "dbname='{}' user='{}' password='{}'".format(self.leDBNAME.text(), self.leUID.text(), self.lePWD.text())

        self.db = QSqlDatabase.addDatabase("QPSQL")
        self.db.setConnectOptions(conn)
        if not self.db.open():
            self.log("Konnte Datenbankverbindung nicht aufbauen! [{}]".format(self.db.lastError().text()))
            return None

        self.db.exec_("SET STANDARD_CONFORMING_STRINGS TO ON")

        self.schema = self.leSCHEMA.text()
        self.pgschema = self.lePGSCHEMA.text()

        if self.schema == "":
            self.log("Kein ALKIS-Schema angegeben")
            return None

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
        self.usecopy = self.cbxUseCopy.isChecked()
        s.setValue("usecopy", self.usecopy)

        self.avoiddupes = self.cbxAvoidDupes.isChecked()
        s.setValue("avoiddupes", self.avoiddupes)

        self.fnbruch = self.cbFnbruch.currentIndex() == 0
        s.setValue("fnbruch", self.fnbruch)

        self.pgverdraengen = self.cbPgVerdraengen.currentIndex() == 1
        s.setValue("pgverdraengen", self.pgverdraengen)

        self.historie = self.cbxHistorie.isChecked()
        s.setValue("historie", self.historie)

        self.quittierung = self.cbxQuittierung.isChecked()
        s.setValue("quittierung", self.quittierung)

        self.transform = self.cbxTransform.isChecked()
        s.setValue("transform", self.transform)

        self.epsg = int(self.cbEPSG.itemData(self.cbEPSG.currentIndex()))
        if self.epsg == -1:
            self.epsg = int(self.leCustomEpsg.text())
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

        id_quittierung = None
        i_quittierung = 0

        while True:
            t0 = QElapsedTimer()
            t0.start()

            self.loadRe()

            self.lstFiles.clearSelection()

            conn = self.connectDb()
            if conn is None:
                break

            qry = self.db.exec_("SELECT version()")

            if not qry or not qry.next():
                self.log("Konnte PostgreSQL-Version nicht bestimmen!")
                break

            self.log("Datenbank-Version: {}".format(qry.value(0)))

            m = re.search("PostgreSQL (\\d+)\\.(\\d+)", qry.value(0))
            if not m:
                self.log("PostgreSQL-Version nicht im erwarteten Format")
                break

            self.PG_MAJOR = int(m.group(1))
            self.PG_MINOR = int(m.group(2))

            if self.PG_MAJOR < 8 or (self.PG_MAJOR == 8 and self.PG_MAJOR < 4):
                self.log("Mindestens PostgreSQL 8.4 erforderlich")
                break

            if self.PG_MAJOR >= 9:
                self.db.exec_("SET application_name='ALKIS-Import - Frontend'")

            if self.PG_MAJOR > 9 or (self.PG_MAJOR == 9 and self.PG_MINOR >= 4):
                self.db.exec_("SET client_min_messages TO notice")

            qry = self.db.exec_("SELECT COUNT(*) FROM information_schema.tables WHERE table_schema=current_schema() AND table_name='alkis_importlog'")
            if not qry or not qry.next():
                self.log("Konnte Existenz der Protokolltabelle nicht überprüfen.")
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

            if not os.path.exists(".git"):
                self.log("Import-Version: $Format:%h$")
            else:
                git = which("git")
                if not git:
                    git = which("git.exe")
                if git:
                    self.runProcess([git, "log", "-1", "--pretty=Import-Version: %h"])
                else:
                    self.log("Import-Version: unbekannt")

            qry = self.db.exec_("SELECT postgis_full_version()")
            if not qry or not qry.next():
                qry = self.db.exec_("SELECT postgis_version()")
                if not qry or not qry.next():
                    self.log("Konnte PostGIS-Version nicht bestimmen!")
                    break

            self.log("PostGIS-Version: {}".format(qry.value(0)))

            qry = self.db.exec_("SELECT inet_client_addr()")
            if qry and qry.next():
                self.log("Import von Client: {}".format(qry.value(0)))

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

            if int(m.group(1)) < 3 or (int(m.group(1)) == 3 and int(m.group(2)) < 8):
                os.putenv("NAS_GFS_TEMPLATE", os.path.join(BASEDIR, "alkis-schema.37.gfs"))
                os.putenv("NAS_NO_RELATION_LAYER", "YES")
            else:
                os.putenv("NAS_GFS_TEMPLATE", os.path.join(BASEDIR, "alkis-schema.gfs"))

            # Verhindern, dass andere GML-Treiber übernehmen
            if int(m.group(1)) < 3 or (int(m.group(1)) == 3 and int(m.group(2)) < 3):
                os.putenv("OGR_SKIP", "GML,SEGY")
            else:
                os.putenv("OGR_SKIP", "GML")

            self.GDAL_MAJOR = int(m.group(1))
            self.GDAL_MINOR = int(m.group(2))

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

                ok = self.rund(conn, "prepare")
                if not ok:
                    self.log("Vorbereitung schlug fehl.")
                    break

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
                if not ok:
                    self.log("Preprocessing schlug fehl.")
                    break

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

                        src = os.path.join(TEMP, os.path.basename(src))

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
                            self.logDb("Größe der Datei {} nicht gefunden.".format(src))
                            break

                        size = sizes[src]

                        self.status("{} wird extrahiert.".format(fn))
                        app.processEvents()

                        src = os.path.join(TEMP, os.path.basename(src))

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

                    if ok:
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
                        ]

                        if self.GDAL_MAJOR < 3 or (self.GDAL_MAJOR == 3 and self.GDAL_MINOR < 1):
                            args.append("PG:{} active_schema={}','{}".format(conn, self.schema, self.pgschema))
                        else:
                            args.append("PG:{0} schemas='{1},{2}' active_schema={1}".format(conn, self.schema, self.pgschema))

                        if self.GDAL_MAJOR >= 3:
                            if self.epsg == 131466 or self.epsg == 131467 or self.epsg == 131468:
                                args.extend(["-a_srs", os.path.join(BASEDIR, "{}.prj".format(self.epsg))])

                            elif self.epsg == 31466 or self.epsg == 31467 or self.epsg == 31468:
                                args.extend([
                                    "-s_srs", os.path.join(BASEDIR, "1{}.prj".format(self.epsg)),
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
                            self.log("WARNUNG: Importfehler werden ignoriert")
                            args.extend(["-skipfailures", "--config", "PG_USE_COPY", "NO"])
                        else:
                            if int(self.leGT.text() or '0') >= 1:
                                args.extend(["-gt", self.leGT.text()])
                            args.extend(["--config", "PG_USE_COPY", "YES" if self.usecopy else "NO"])

                        if self.useonconflict():
                            args.extend(["--config", "OGR_PG_SKIP_CONFLICTS", "YES"])

                        args.extend(["-nlt", "CONVERT_TO_LINEAR", "-ds_transaction"])

                        try:
                            ffdate = getdate(src)
                            if ffdate is not None:
                                args.extend(["-doo", f"PRELUDE_STATEMENTS=CREATE TEMPORARY TABLE deletedate AS SELECT '{ffdate}'::character(20) AS endet"])
                                self.log(f"{fn}: Fortführungsdatum {ffdate}")
                        except Exception:
                            ffdate = None

                        args.append(src)

                        self.status("{} mit {} wird importiert...".format(fn, self.memunits(size)))

                        t1 = QElapsedTimer()
                        t1.start()

                        ok = self.runProcess(args)

                        if ok:
                            if qry.prepare("INSERT INTO alkis_importe(filename,datadate) VALUES (?,?)"):
                                qry.addBindValue(fn)
                                qry.addBindValue(ffdate)
                                if not qry.exec_():
                                    self.log("Konnte Import nicht speichern! [{}]".format(qry.lastError().text()))
                                    break
                            else:
                                self.log("Konnte Speichern des Imports nicht vorbereiten! [{}]".format(qry.lastError().text()))
                                break
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

                    elif self.quittierung:
                        self.status("{} mit {} wurde übersprungen...".format(fn, self.memunits(size)))
                        self.log("{} mit {} wurde übersprungen...".format(fn, self.memunits(size)))

                    if self.quittierung:
                        self.db.exec_("CREATE SEQUENCE \"{}\".alkis_quittierungen_seq".format(self.schema.replace('"', '""')))

                        if id_quittierung is None:
                            qry = self.db.exec_("SELECT nextval('\"{}\".alkis_quittierungen_seq')".format(self.schema.replace('"', '""').replace("'", "''")))
                            if qry and qry.next():
                                id_quittierung = qry.value(0)

                        if not self.runProcess([sys.executable, os.path.join(BASEDIR, "quittierung.py"), ".", src, str(id_quittierung), "true" if ok else "false"]):
                            self.log("Quittierung gescheitert!")
                            ok = False
                            break

                    item.setSelected(ok)
                    if src != fn and os.path.exists(src):
                        os.unlink(src)

                    s = s + size
                    self.pbProgress.setValue(int(10000 * s / ts))

                    remaining_data = ts - s
                    remaining_time = remaining_data * t0.elapsed() / s

                    self.alive.setText("Noch {} in etwa {}\nETA: {} -".format(
                        self.memunits(remaining_data),
                        self.timeunits(remaining_time),
                        QDateTime.currentDateTime().addMSecs(int(remaining_time)).toString(Qt.ISODate)
                    ))

                    app.processEvents()

                    if not ok and not self.quittierung:
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
