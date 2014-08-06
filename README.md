# norGIS ALKIS Import

norGIS ALKIS Import ist ein Frontend zum Import ALKIS über den [NAS-Treiber in
GDAL/OGR](http://www.gdal.org/drv_nas.html) in PostgreSQL/PostGIS.

Funktion:
* Anlegen des Datenbankmodells
* Import einer oder mehrere NAS-Dateien oder ganzer Verzeichnisse über GDAL/OGR
* Protokollierung und Fortschrittsanzeige
* Vorbereitung der graphischen Darstellung nach [GeoInfoDok](http://www.adv-online.de/AAA-Modell/Dokumente-der-GeoInfoDok/) (insb. Ableitungsregeln des Signaturkatalog)
* Aufbereitung der Liegenschaftsbuchdaten

Die graphische Darstellung selbst erfolgt mit weiterer Software:
* [QGIS-Plugin zum Import in QGIS-Projekte und zur Erzeugung von UMN-Mapfiles](http://www.norbit.de/75/) (GPLv2)
* [Darstellung in AutoCAD & BricsCAD](http://www.norbit.de/76/) (proprietär)

[Homepage](http://www.norbit.de/68/), Lizenz: [GPLv2](http://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html),
