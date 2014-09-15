/******************************************************************************
 *
 * Projekt:  norGIS ALKIS Import
 * Zweck:    ALKIS-Schema
 * Herkunft: Durch den GDAL/OGR NAS-Treiber erzeugt,
 *           angepaßt, ergänzt und kommentiert PostNAS 0.7
 *           (http://trac.wheregroup.com/PostNAS/browser/trunk/import/alkis_PostNAS_schema.sql)
 *
 * Authors:
 *   Frank Jäger <f.jaeger@KRZ.DE>
 *   Jürgen E. Fischer <jef@norbit.de>
 *   Astrid Emde <astrid.emde@wheregroup.com>
 *
 ******************************************************************************/

-- *****************************
--       A  L   K   I   S
-- *****************************
--
--

-- Damit die Includes (\i) funktionieren muß psql im Verzeichnis ausgeführt
-- werden in dem das Skript liegt. Z.B. per
-- (cd /pfad/zu/postnas; psql -f alkis-schema.sql)

-- Variable für das Koordinatensystem übergeben mit "psql .. -v alkis_epsg=25832"

-- ALKIS-Dokumentation (NRW):
--  http://www.bezreg-koeln.nrw.de/extra/33alkis/alkis_nrw.htm
--  http://www.bezreg-koeln.nrw.de/extra/33alkis/geoinfodok.htm
--  http://www.bezreg-koeln.nrw.de/extra/33alkis/dokumente/GeoInfoDok/ALKIS/ALKIS_OK_V6-0.html

  SET client_encoding = 'UTF8';
  SET default_with_oids = false;

-- Abbruch bei Fehlern
\set ON_ERROR_STOP


-- Stored Procedures laden
\i alkis-functions.sql

-- Alle Tabellen löschen
SELECT alkis_drop();

CREATE TABLE alkis_version(version integer);
INSERT INTO alkis_version(version) VALUES (1);

-- BW/BY-Koordinatensystem anlegen
SELECT alkis_create_bsrs(:alkis_epsg);

-- Tabelle "delete" für Lösch- und Fortführungsdatensätze
CREATE TABLE "delete" (
	ogc_fid		serial NOT NULL,
	typename	varchar,
	featureid	varchar,
	context		varchar,		-- delete/replace/update
	safetoignore	varchar,		-- replace.safetoignore 'true'/'false'
	replacedBy	varchar,		-- gmlid
	anlass		varchar,		-- update.anlass
	endet		character(20),		-- update.endet
	ignored		boolean DEFAULT false,	-- Satz wurde nicht verarbeitet
	CONSTRAINT delete_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('delete','dummy',:alkis_epsg,'POINT',2);

CREATE UNIQUE INDEX delete_fid ON "delete"(featureid);

COMMENT ON TABLE "delete"             IS 'Hilfstabelle für das Speichern von Löschinformationen.';
COMMENT ON COLUMN delete.typename     IS 'Objektart, also Name der Tabelle, aus der das Objekt zu löschen ist.';
COMMENT ON COLUMN delete.featureid    IS 'gml_id des zu löschenden Objekts (falls ein Objekt in einer Datei in verschiedenen Version angesprochen wird mit Timestamp).';
COMMENT ON COLUMN delete.context      IS 'Operation ''delete'', ''replace'' oder ''update''.';
COMMENT ON COLUMN delete.safetoignore IS 'Attribut safeToIgnore von wfsext:Replace';
COMMENT ON COLUMN delete.replacedBy   IS 'gml_id des Objekts, das featureid ersetzt';
COMMENT ON COLUMN delete.anlass       IS 'Anlaß des Endes';
COMMENT ON COLUMN delete.endet        IS 'Zeitpunkt des Endes';
COMMENT ON COLUMN delete.ignored      IS 'Löschsatz wurde ignoriert';

CREATE TABLE alkis_beziehungen (
       ogc_fid                 serial NOT NULL,
       beziehung_von           character(16) NOT NULL,
       beziehungsart           varchar,
       beziehung_zu            character(16) NOT NULL,
       CONSTRAINT alkis_beziehungen_pk PRIMARY KEY (ogc_fid)
);

CREATE INDEX alkis_beziehungen_von_idx ON alkis_beziehungen USING btree (beziehung_von);
CREATE INDEX alkis_beziehungen_zu_idx  ON alkis_beziehungen USING btree (beziehung_zu);
CREATE INDEX alkis_beziehungen_art_idx ON alkis_beziehungen USING btree (beziehungsart);

SELECT AddGeometryColumn('alkis_beziehungen','dummy',:alkis_epsg,'POINT',2);

COMMENT ON TABLE  alkis_beziehungen               IS 'zentrale Multi-Verbindungstabelle';
COMMENT ON COLUMN alkis_beziehungen.beziehung_von IS 'Join auf Feld gml_id verschiedener Tabellen';
COMMENT ON COLUMN alkis_beziehungen.beziehung_zu  IS 'Join auf Feld gml_id verschiedener Tabellen';
COMMENT ON COLUMN alkis_beziehungen.beziehungsart IS 'Typ der Beziehung zwischen der von- und zu-Tabelle';

-- S o n s t i g e s   B a u w e r k
-- ----------------------------------
-- Wird von OGR generiert, ist aber keiner Objektartengruppe zuzuordnen.
CREATE TABLE ks_sonstigesbauwerk (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	sonstigesmodell		varchar[],
	anlass			varchar,
	bauwerksfunktion	integer,
	CONSTRAINT ks_sonstigesbauwerk_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ks_sonstigesbauwerk','wkb_geometry',:alkis_epsg,'GEOMETRY',2);

CREATE INDEX ks_sonstigesbauwerk_geom_idx ON ks_sonstigesbauwerk USING gist (wkb_geometry);

COMMENT ON TABLE  ks_sonstigesbauwerk IS 'Sonstiges Bauwerk';


-- Löschtrigger setzen
\i alkis-trigger.sql


--*** ############################################################
--*** Objektbereich: AAA Basisschema
--*** ############################################################

--** Objektartengruppe: AAA_Praesentationsobjekte
--   ===================================================================

-- A P   P P O
-- ----------------------------------------------
-- Objektart: AP_PPO Kennung: 02310
CREATE TABLE ap_ppo (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	signaturnummer		varchar,
	darstellungsprioritaet  integer,
	art			varchar,
	drehwinkel		double precision,
	skalierung		double precision,

	-- Beziehung
	dientzurdarstellungvon	character(16)[],

	CONSTRAINT ap_ppo_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ap_ppo','wkb_geometry',:alkis_epsg,'GEOMETRY',2); -- POINT/MULTIPOLYGON

CREATE INDEX ap_ppo_geom_idx   ON ap_ppo USING gist (wkb_geometry);
CREATE UNIQUE INDEX ap_ppo_gml ON ap_ppo USING btree (gml_id,beginnt);
CREATE INDEX ap_ppo_endet      ON ap_ppo USING btree (endet);
CREATE INDEX ap_ppo_dzdv       ON ap_ppo USING gin (dientzurdarstellungvon);


-- A P   L P O
-- ----------------------------------------------
-- Objektart: AP_LPO Kennung: 02320
CREATE TABLE ap_lpo (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	signaturnummer		varchar,
	darstellungsprioritaet  integer,
	art			varchar,

	-- Beziehung
	dientzurdarstellungvon	character(16)[],

	CONSTRAINT ap_lpo_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ap_lpo','wkb_geometry',:alkis_epsg,'GEOMETRY',2); -- LINESTRING/MULTILINESTRING

CREATE INDEX ap_lpo_geom_idx   ON ap_lpo USING gist (wkb_geometry);
CREATE UNIQUE INDEX ap_lpo_gml ON ap_lpo USING btree (gml_id,beginnt);
CREATE INDEX ap_lpo_dzdv       ON ap_lpo USING gin (dientzurdarstellungvon);
CREATE INDEX ap_lpo_endet      ON ap_lpo USING btree (endet);


-- A P   P T O
-- ----------------------------------------------
-- Objektart: AP_PTO Kennung: 02341
CREATE TABLE ap_pto (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	schriftinhalt		varchar,
	fontsperrung		double precision,
	skalierung		double precision,
	horizontaleausrichtung	varchar,
	vertikaleausrichtung	varchar,
	signaturnummer		varchar,
	darstellungsprioritaet  integer,
	art			varchar,		-- Inhalte z.B. "ZAE_NEN" siehe unten
	drehwinkel		double precision,       -- falsche Masseinheit für Mapserver, im View umrechnen

	-- Beziehungen
	dientzurdarstellungvon	character(16)[],
	hat			character(16),

	CONSTRAINT ap_pto_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ap_pto','wkb_geometry',:alkis_epsg,'POINT',2);

CREATE INDEX ap_pto_geom_idx   ON ap_pto USING gist (wkb_geometry);
CREATE UNIQUE INDEX ap_pto_gml ON ap_pto USING btree (gml_id,beginnt);
CREATE INDEX ap_pto_art_idx    ON ap_pto USING btree (art);
CREATE INDEX ap_pto_endet_idx  ON ap_pto USING btree (endet);
CREATE INDEX ap_pto_sn_idx     ON ap_pto USING btree (signaturnummer);
CREATE INDEX ap_pto_dzdv       ON ap_pto USING gin (dientzurdarstellungvon);
CREATE INDEX ap_pto_hat        ON ap_pto USING btree (hat);

COMMENT ON INDEX  ap_pto_art_idx                IS 'Suchindex auf häufig benutztem Filterkriterium';


-- A P   L T O
-- ----------------------------------------------
-- Objektart: AP_LTO Kennung: 02342
CREATE TABLE ap_lto (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	schriftinhalt		varchar,
	fontsperrung		double precision,
	skalierung		double precision,
	horizontaleausrichtung	varchar,
	vertikaleausrichtung	varchar,
	signaturnummer		varchar,
	art			varchar,
	darstellungsprioritaet  integer,

	-- Beziehungen
	dientzurdarstellungvon	character(16)[],
	hat			character(16),

	CONSTRAINT ap_lto_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ap_lto','wkb_geometry',:alkis_epsg,'LINESTRING',2);

CREATE INDEX ap_lto_geom_idx   ON ap_lto USING gist (wkb_geometry);
CREATE UNIQUE INDEX ap_lto_gml ON ap_lto USING btree (gml_id,beginnt);
CREATE INDEX ap_lto_dzdv       ON ap_lto USING gin (dientzurdarstellungvon);
CREATE INDEX ap_lto_hat        ON ap_lto USING btree (hat);
CREATE INDEX ap_lto_endet_idx  ON ap_lto USING btree (endet);



-- A P  D a r s t e l l u n g
-- ----------------------------------------------
-- Objektart: AP_Darstellung Kennung: 02350
CREATE TABLE ap_darstellung (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20), -- Datumsformat
	endet			character(20), -- Datumsformat
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	signaturnummer		varchar,
	darstellungsprioritaet  integer,
	art			varchar,
	positionierungsregel    integer,

	-- Beziehung
	dientzurdarstellungvon	character(16)[],

	CONSTRAINT ap_darstellung_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ap_darstellung','dummy',:alkis_epsg,'POINT',2);

CREATE UNIQUE INDEX ap_darstellung_gml ON ap_darstellung USING btree (gml_id,beginnt);
CREATE INDEX ap_darstellung_endet_idx  ON ap_darstellung USING btree (endet);
CREATE INDEX ap_darstellung_dzdv       ON ap_darstellung USING gin (dientzurdarstellungvon);

COMMENT ON TABLE  ap_darstellung        IS 'A P  D a r s t e l l u n g';



--*** ############################################################
--*** Objektbereich: Flurstücke, Lage, Punkte
--*** ############################################################

--** Objektartengruppe: Angaben zu Festpunkten der Landesvermessung

--** Objektartengruppe: Angaben zum Flurstück
--   ===================================================================

-- F l u r s t u e c k
-- ----------------------------------------------
-- Objektart: AX_Flurstueck Kennung: 11001
CREATE TABLE ax_flurstueck (
	ogc_fid					serial NOT NULL,
	gml_id					character(16) NOT NULL,		-- Datenbank-Tabelle interner Schlüssel

	-- GID: AX_Flurstueck_Kerndaten
	     -- 'Flurstück_Kerndaten' enthält Eigenschaften des Flurstücks, die auch für andere Flurstücksobjektarten gelten (z.B. Historisches Flurstück).
	land					varchar,
	gemarkungsnummer			varchar,
	flurnummer				integer,
	zaehler					integer,
	nenner					varchar,
	flurstuecksfolge			varchar,
	-- daraus abgeleitet:
	flurstueckskennzeichen			character(20),			-- Inhalt rechts mit __ auf 20 aufgefüllt
	amtlicheflaeche				double precision,		-- AFL
	abweichenderrechtszustand		varchar DEFAULT 'false',	-- ARZ
	rechtsbehelfsverfahren			varchar DEFAULT 'false',	-- RBV
	zweifelhafterFlurstuecksnachweis	varchar DEFAULT 'false',	-- ZFM
	zeitpunktderentstehung			varchar,			-- ZDE  Inhalt jjjj-mm-tt  besser Format date ?
	gemeinde				varchar,
	-- GID: ENDE AX_Flurstueck_Kerndaten

	identifier				varchar,
	beginnt					character(20),			-- Timestamp der Entstehung
	endet					character(20),			-- Timestamp des Untergangs
	advstandardmodell			varchar[],
	sonstigesmodell				varchar[],
	anlass					varchar,
	name					varchar[],
	regierungsbezirk			varchar,
	kreis					varchar,
	stelle					varchar,
	angabenzumabschnittflurstueck		varchar[],
	kennungschluessel			varchar[],
	flaechedesabschnitts			double precision[],
	angabenzumabschnittnummeraktenzeichen	varchar[],
	angabenzumabschnittbemerkung		varchar[],

	-- Beziehungen
	beziehtsichaufflurstueck		character(16)[],
	zeigtauf				character(16)[],
	istgebucht				character(16),
	weistauf				character(16)[],
	gehoertanteiligzu			character(16)[],

	CONSTRAINT ax_flurstueck_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_flurstueck','wkb_geometry',:alkis_epsg,'GEOMETRY',2);

CREATE INDEX ax_flurstueck_geom_idx   ON ax_flurstueck USING gist (wkb_geometry);
CREATE UNIQUE INDEX ax_flurstueck_gml ON ax_flurstueck USING btree (gml_id,beginnt);
CREATE INDEX ax_flurstueck_lgfzn ON ax_flurstueck USING btree (land,gemarkungsnummer,flurnummer,zaehler,nenner);
CREATE INDEX ax_flurstueck_arz ON ax_flurstueck USING btree (abweichenderrechtszustand);
CREATE INDEX ax_flurstueck_bsaf ON ax_flurstueck USING gin (beziehtsichaufflurstueck);
CREATE INDEX ax_flurstueck_za ON ax_flurstueck USING gin (zeigtauf);
CREATE INDEX ax_flurstueck_ig ON ax_flurstueck USING btree (istgebucht);
CREATE INDEX ax_flurstueck_kz ON ax_flurstueck USING btree (flurstueckskennzeichen);
CREATE INDEX ax_flurstueck_wa ON ax_flurstueck USING gin (weistauf);
CREATE INDEX ax_flurstueck_gaz ON ax_flurstueck USING gin (gehoertanteiligzu);



-- B e s o n d e r e   F l u r s t u e c k s g r e n z e
-- -----------------------------------------------------
-- Objektart: AX_BesondereFlurstuecksgrenze Kennung: 11002
CREATE TABLE ax_besondereflurstuecksgrenze (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	artderflurstuecksgrenze	integer[],
	CONSTRAINT ax_besondereflurstuecksgrenze_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_besondereflurstuecksgrenze','wkb_geometry',:alkis_epsg,'LINESTRING',2);

CREATE INDEX ax_besondereflurstuecksgrenze_geom_idx   ON ax_besondereflurstuecksgrenze USING gist (wkb_geometry);
CREATE UNIQUE INDEX ax_besondereflurstuecksgrenze_gml ON ax_besondereflurstuecksgrenze USING btree (gml_id,beginnt);
CREATE INDEX ax_besondereflurstuecksgrenze_adfg       ON ax_besondereflurstuecksgrenze USING gin (artderflurstuecksgrenze);


-- G r e n z p u n k t
-- ----------------------------------------------
-- Objektart: AX_Grenzpunkt Kennung: 11003
CREATE TABLE ax_grenzpunkt (
	ogc_fid				serial NOT NULL,
	gml_id				character(16) NOT NULL,
	identifier			varchar,
	beginnt				character(20),
	endet				character(20),
	advstandardmodell		varchar[],
	sonstigesmodell			varchar[],
	anlass				varchar,
	punktkennung			varchar,
	land				varchar,
	stelle				varchar,
	abmarkung_marke			integer,
	festgestelltergrenzpunkt	varchar,
	besonderepunktnummer		varchar,
	bemerkungzurabmarkung		integer,
	sonstigeeigenschaft		varchar[],
	art				varchar,
	name				varchar[],
	zeitpunktderentstehung		varchar,
	relativehoehe			double precision,

	-- Beziehung
	zeigtauf			character(16),

	CONSTRAINT ax_grenzpunkt_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_grenzpunkt','dummy',:alkis_epsg,'POINT',2);

CREATE UNIQUE INDEX ax_grenzpunkt_gml ON ax_grenzpunkt USING btree (gml_id,beginnt);
CREATE INDEX ax_grenzpunkt_abmm ON ax_grenzpunkt USING btree (abmarkung_marke);
CREATE INDEX ax_grenzpunkt_za ON ax_grenzpunkt USING btree (zeigtauf);



--** Objektartengruppe: Angaben zur Lage
--   ===================================================================

-- L a g e b e z e i c h n u n g   o h n e   H a u s n u m m e r
-- -------------------------------------------------------------
-- Objektart: AX_LagebezeichnungOhneHausnummer Kennung: 12001
CREATE TABLE ax_lagebezeichnungohnehausnummer (
	ogc_fid				serial NOT NULL,
	gml_id				character(16) NOT NULL,
	identifier			varchar,
	beginnt				character(20),
	endet				character(20),
	advstandardmodell		varchar[],
	sonstigesmodell			varchar[],
	anlass				varchar,
	unverschluesselt		varchar,  -- Gewanne
	land				varchar,
	regierungsbezirk		varchar,
	kreis				varchar,
	gemeinde			varchar,
	lage				varchar,  -- Strassenschlüssel
	zusatzzurlagebezeichnung	varchar,

	-- Beziehungen
	beschreibt			character(16)[],
	gehoertzu			varchar[],

	CONSTRAINT ax_lagebezeichnungohnehausnummer_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_lagebezeichnungohnehausnummer','dummy',:alkis_epsg,'POINT',2);

CREATE UNIQUE INDEX ax_lagebezeichnungohnehausnummer_gml ON ax_lagebezeichnungohnehausnummer USING btree (gml_id,beginnt);
CREATE INDEX ax_lagebezeichnungohnehausnummer_beschreibt ON ax_lagebezeichnungohnehausnummer USING gin (beschreibt);
CREATE INDEX ax_lagebezeichnungohnehausnummer_gehoertzu  ON ax_lagebezeichnungohnehausnummer USING gin (gehoertzu);
CREATE INDEX ax_lagebezeichnungohnehausnummer_key        ON ax_lagebezeichnungohnehausnummer USING btree (land,regierungsbezirk,kreis,gemeinde,lage);


-- L a g e b e z e i c h n u n g   m i t   H a u s n u m m e r
-- -----------------------------------------------------------
-- Objektart: AX_LagebezeichnungOhneHausnummer Kennung: 12001
CREATE TABLE ax_lagebezeichnungmithausnummer (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	land			varchar,
	regierungsbezirk	varchar,
	kreis			varchar,
	gemeinde		varchar,
	lage			varchar,  -- Strassenschluessel
	hausnummer		varchar,  -- Nummer (blank) Zusatz

	-- Beziehungen
	hat			character(16)[],
	beziehtsichauf		character(16),
	beziehtsichauchauf	character(16),
	gehoertzu		character(16)[],
	weistzum		character(16),

	CONSTRAINT ax_lagebezeichnungmithausnummer_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_lagebezeichnungmithausnummer','dummy',:alkis_epsg,'POINT',2);

CREATE UNIQUE INDEX ax_lagebezeichnungmithausnummer_gml ON ax_lagebezeichnungmithausnummer USING btree (gml_id,beginnt);
CREATE INDEX ax_lagebezeichnungmithausnummer_lage       ON ax_lagebezeichnungmithausnummer USING btree (gemeinde,lage);
CREATE INDEX ax_lagebezeichnungmithausnummer_hat        ON ax_lagebezeichnungmithausnummer USING gin (hat);
CREATE INDEX ax_lagebezeichnungmithausnummer_bsa        ON ax_lagebezeichnungmithausnummer USING btree (beziehtsichauf);
CREATE INDEX ax_lagebezeichnungmithausnummer_bsaa       ON ax_lagebezeichnungmithausnummer USING btree (beziehtsichauchauf);
CREATE INDEX ax_lagebezeichnungmithausnummer_gehoertzu  ON ax_lagebezeichnungmithausnummer USING gin (gehoertzu);
CREATE INDEX ax_lagebezeichnungmithausnummer_weistzum   ON ax_lagebezeichnungmithausnummer USING btree (weistzum);



-- L a g e b e z e i c h n u n g   m i t  P s e u d o n u m m e r
-- --------------------------------------------------------------
-- Objektart: AX_LagebezeichnungMitPseudonummer Kennung: 12003
-- Nebengebäude: lfd-Nummer eines Nebengebäudes zu einer (Pseudo-) Hausnummer
CREATE TABLE ax_lagebezeichnungmitpseudonummer (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	land			varchar,
	regierungsbezirk	varchar,
	kreis			varchar,
	gemeinde		varchar,
	lage			varchar, -- Strassenschluessel
	pseudonummer		varchar,
	laufendenummer		varchar, -- leer, Zahl, "P2"

	-- Beziehung
	gehoertzu		character(16),

	CONSTRAINT ax_lagebezeichnungmitpseudonummer_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_lagebezeichnungmitpseudonummer','dummy',:alkis_epsg,'POINT',2);

CREATE UNIQUE INDEX ax_lagebezeichnungmitpseudonummer_gml ON ax_lagebezeichnungmitpseudonummer USING btree (gml_id,beginnt);
CREATE INDEX ax_lagebezeichnungmitpseudonummer_gehoertzu  ON ax_lagebezeichnungmitpseudonummer USING btree (gehoertzu);


-- Georeferenzierte  G e b ä u d e a d r e s s e
-- ----------------------------------------------
-- Objektart: AX_GeoreferenzierteGebaeudeadresse Kennung: 12006
CREATE TABLE ax_georeferenziertegebaeudeadresse (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),	-- Inhalt z.B. "2008-06-10T15:19:17Z"
	endet			character(20),	-- Inhalt z.B. "2008-06-10T15:19:17Z"

	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	qualitaetsangaben	integer,

	land			varchar,
	regierungsbezirk	varchar,
	kreis			varchar,
	gemeinde		varchar,
	ortsteil		varchar,

	postleitzahl		varchar,
	ortsnamepost		varchar,
	zusatzortsname		varchar,
	strassenname		varchar,
	strassenschluessel	varchar,
	hausnummer		varchar,
	adressierungszusatz	varchar,

	-- Beziehung
	hatauch			character(16),

	CONSTRAINT ax_georeferenziertegebaeudeadresse_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_georeferenziertegebaeudeadresse','wkb_geometry',:alkis_epsg,'POINT',2);

CREATE INDEX ax_georeferenziertegebaeudeadresse_geom_idx ON ax_georeferenziertegebaeudeadresse USING gist (wkb_geometry);
CREATE UNIQUE INDEX ax_georeferenziertegebaeudeadresse_gml ON ax_georeferenziertegebaeudeadresse USING btree (gml_id,beginnt);
CREATE INDEX ax_georeferenziertegebaeudeadresse_adr ON ax_georeferenziertegebaeudeadresse USING btree (strassenschluessel,hausnummer,adressierungszusatz);



--** Objektartengruppe: Angaben zum Netzpunkt
--   ===================================================================

-- A u f n a h m e p u n k t
-- ----------------------------------------------
-- Objektart: AX_Aufnahmepunkt Kennung: 13001
CREATE TABLE ax_aufnahmepunkt (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier              varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	punktkennung		varchar,
	land			varchar,
	stelle			varchar,
	sonstigeeigenschaft	varchar[],
	vermarkung_marke	integer,
	relativehoehe		double precision,

	-- Beziehung
	hat			character(16)[],

	CONSTRAINT ax_aufnahmepunkt_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_aufnahmepunkt','dummy',:alkis_epsg,'POINT',2);

CREATE UNIQUE INDEX ax_aufnahmepunkt_gml ON ax_aufnahmepunkt USING btree (gml_id,beginnt);
CREATE INDEX ax_aufnahmepunkt_hat ON ax_aufnahmepunkt USING gin (hat);



-- S i c h e r u n g s p u n k t
-- ----------------------------------------------
-- Objektart: AX_Sicherungspunkt Kennung: 13002
CREATE TABLE ax_sicherungspunkt (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	name			varchar,
	punktkennung		varchar,
	land			varchar,
	stelle			varchar,
	sonstigeeigenschaft	varchar[],
	vermarkung_marke	integer,
	relativehoehe		double precision,

	-- Beziehungen
	beziehtsichauf		character(16),
	gehoertzu		character(16),

	CONSTRAINT ax_sicherungspunkt_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_sicherungspunkt','dummy',:alkis_epsg,'POINT',2);


-- s o n s t i g e r   V e r m e s s u n g s p u n k t
-- ---------------------------------------------------
-- Objektart: AX_SonstigerVermessungspunkt Kennung: 13003
CREATE TABLE ax_sonstigervermessungspunkt (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	vermarkung_marke	integer,
	punktkennung		varchar,
	art			varchar,
	land			varchar,
	stelle			varchar,
	sonstigeeigenschaft	varchar[],
	relativehoehe		double precision,

	-- Beziehung
	hat			character(16)[],

	CONSTRAINT ax_sonstigervermessungspunkt_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_sonstigervermessungspunkt','dummy',:alkis_epsg,'POINT',2);

CREATE UNIQUE INDEX ax_sonstigervermessungspunkt_gml ON ax_sonstigervermessungspunkt USING btree (gml_id,beginnt);
CREATE INDEX ax_sonstigervermessungspunkt_hat ON ax_sonstigervermessungspunkt USING gin (hat);


-- Objektart: AX_Netzpunkt Kennung: 13004
-- ** Tabelle bisher noch nicht generiert

--** Objektartengruppe: Angaben zum Punktort
--   ===================================================================

--AX_Punktort

-- P u n k t o r t   AG
-- ----------------------------------------------
-- Objektart: AX_PunktortAG Kennung: 14002
CREATE TABLE ax_punktortag (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	art			varchar[],
	name			varchar[],
	kartendarstellung	varchar,
	ax_datenerhebung_punktort integer,
	genauigkeitsstufe	integer,
	vertrauenswuerdigkeit	integer,
	koordinatenstatus	integer,
	hinweise		varchar,

	-- Beziehungen
	istteilvon		character(16),

	CONSTRAINT ax_punktortag_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_punktortag','wkb_geometry',:alkis_epsg,'POINT',2);

CREATE INDEX ax_punktortag_geom_idx ON ax_punktortag USING gist (wkb_geometry);
CREATE UNIQUE INDEX ax_punktortag_gml ON ax_punktortag USING btree (gml_id,beginnt);
CREATE INDEX ax_punktortag_itv_idx ON ax_punktortag USING btree (istteilvon);


-- P u n k t o r t   A U
-- ----------------------------------------------
-- Objektart: AX_PunktortAU Kennung: 14003
CREATE TABLE ax_punktortau (
	ogc_fid				serial NOT NULL,
	gml_id				character(16) NOT NULL,
	identifier			varchar,
	beginnt				character(20),
	endet				character(20),
	advstandardmodell		varchar[],
	sonstigesmodell			varchar[],
	anlass				varchar,
	kartendarstellung		varchar,
	ax_datenerhebung_punktort	integer,
	name				varchar[],
	individualname			varchar,
	vertrauenswuerdigkeit		integer,
	genauigkeitsstufe		integer,
	koordinatenstatus		integer,
	hinweise			varchar,

	-- Beziehung
	istteilvon			character(16),

	CONSTRAINT ax_punktortau_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_punktortau','wkb_geometry',:alkis_epsg,'POINT',3); -- 0, 0, Höhe

CREATE INDEX ax_punktortau_geom_idx ON ax_punktortau USING gist (wkb_geometry);
CREATE UNIQUE INDEX ax_punktortau_gml ON ax_punktortau USING btree (gml_id,beginnt);
CREATE INDEX ax_punktortau_itv_idx ON ax_punktortau USING btree (istteilvon);


-- P u n k t o r t   T A
-- ----------------------------------------------
-- Objektart: AX_PunktortTA Kennung: 14004
CREATE TABLE ax_punktortta (
	ogc_fid			  serial NOT NULL,
	gml_id			  character(16) NOT NULL,
	identifier		  varchar,
	beginnt			  character(20),
	endet			  character(20),
	advstandardmodell	  varchar[],
	sonstigesmodell		  varchar[],
	anlass			  varchar,
	kartendarstellung	  varchar,
	description		  integer,
	ax_datenerhebung_punktort integer,
	art			  varchar[],
	name			  varchar[],
	genauigkeitsstufe	  integer,
	vertrauenswuerdigkeit	  integer,
	koordinatenstatus	  integer,
	hinweise		  varchar,

	-- Beziehung
	istteilvon                character(16),

	CONSTRAINT ax_punktortta_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_punktortta','wkb_geometry',:alkis_epsg,'POINT',2);

CREATE INDEX ax_punktortta_geom_idx ON ax_punktortta USING gist (wkb_geometry);
CREATE UNIQUE INDEX ax_punktortta_gml ON ax_punktortta USING btree (gml_id,beginnt);
CREATE INDEX ax_punktortta_endet_idx ON ax_punktortta USING btree (endet);
CREATE INDEX ax_punktortta_itv_idx ON ax_punktortta USING btree (istteilvon);


--** Objektartengruppe: Fortführungsnachweis
--   ===================================================================

-- F o r t f u e h r u n g s n a c h w e i s / D e c k b l a t t
-- --------------------------------------------------------------
-- Objektart: AX_FortfuehrungsnachweisDeckblatt Kennung: 15001
CREATE TABLE ax_fortfuehrungsnachweisdeckblatt (
	ogc_fid				serial NOT NULL,
	gml_id				character(16) NOT NULL,
	identifier			varchar,
	beginnt				character(20),
	endet				character(20),
	advstandardmodell		varchar[],
	sonstigesmodell			varchar[],
	anlass				varchar,
	uri				varchar,
	fortfuehrungsfallnummernbereich	varchar,
	land				varchar,
	gemarkungsnummer		varchar,
	laufendenummer			integer,
	titel				varchar,
	erstelltam			varchar,  -- Datum jjjj-mm-tt
	fortfuehrungsentscheidungam	varchar,
	fortfuehrungsentscheidungvon	varchar,  -- Bearbeiter-Name und -Titel
	bemerkung			varchar,

	-- Beziehung
	beziehtsichauf			character(16),

	CONSTRAINT ax_fortfuehrungsnachweisdeckblatt_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_fortfuehrungsnachweisdeckblatt','dummy',:alkis_epsg,'POINT',2);


-- F o r t f u e h r u n g s f a l l
-- ---------------------------------
-- Objektart: AX_Fortfuehrungsfall Kennung: 15002
CREATE TABLE ax_fortfuehrungsfall (
	ogc_fid					serial NOT NULL,
	gml_id					character(16) NOT NULL,
	identifier				varchar,
	beginnt					character(20),
	endet					character(20),
	advstandardmodell			varchar[],
	sonstigesmodell				varchar[],
	anlass					varchar,
	uri					varchar,
	fortfuehrungsfallnummer			integer,
	laufendenummer				integer,
	ueberschriftimfortfuehrungsnachweis	integer[],
	anzahlderfortfuehrungsmitteilungen	integer,

	-- Beziehungen
	zeigtaufaltesflurstueck			character(16)[],
	zeigtaufneuesflurstueck			character(16)[],
	bemerkung				character(16),

	CONSTRAINT ax_fortfuehrungsfall_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_fortfuehrungsfall','dummy',:alkis_epsg,'POINT',2);


--** Objektartengruppe: Angaben zur Reservierung
--   ===================================================================

-- R e s e r v i e r u n g
-- -----------------------
-- Objektart: AX_Reservierung Kennung: 16001
CREATE TABLE ax_reservierung (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	art			integer,
	nummer			varchar,
	land			varchar,
	stelle			varchar,
	ablaufderreservierung	varchar,
	antragsnummer		varchar,
	auftragsnummer		varchar,
	CONSTRAINT ax_reservierung_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_reservierung','dummy',:alkis_epsg,'POINT',2);


-- P u n k t k e n n u n g   U n t e r g e g a n g e n
-- ---------------------------------------------------
-- Objektart: AX_PunktkennungUntergegangen Kennung: 16002
CREATE TABLE ax_punktkennunguntergegangen (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	punktkennung		varchar,
	art			integer,
	CONSTRAINT ax_punktkennunguntergegangen_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_punktkennunguntergegangen','dummy',:alkis_epsg,'POINT',2);


-- Objektart: AX_PunktkennungVergleichend Kennung: 16003
-- 'Punktkennung vergleichend' (NREO) enthält vorläufige Punktkennungen.


--** Objektartengruppe: Angaben zur Historie
--   ===================================================================

-- Historisches Flurstück (ALKIS)
-- ------------------------------
-- Objektart: AX_HistorischesFlurstueck Kennung: 17001
-- Die "neue" Historie, die durch Fortführungen innerhalb von ALKIS entstanden ist.
CREATE TABLE ax_historischesflurstueck (
	ogc_fid						serial NOT NULL,
	gml_id						character(16) NOT NULL,
	identifier					varchar,
	beginnt						character(20),
	endet						character(20),
	advstandardmodell				varchar[],
	sonstigesmodell					varchar[],
	anlass						varchar,
	art						varchar[],
	name						varchar[],

	-- GID: AX_Flurstueck_Kerndaten
	-- 'Flurstück_Kerndaten' enthält Eigenschaften des Flurstücks, die auch für andere Flurstücksobjektarten gelten (z.B. Historisches Flurstück).
	land						varchar,
	gemarkungsnummer				varchar,
	flurnummer					integer,			-- Teile des Flurstückskennzeichens
	zaehler						varchar,			--    (redundant zu flurstueckskennzeichen)
	nenner					        varchar,			-- tlw. nicht nummerische Werte in SN
	-- daraus abgeleitet:
	flurstueckskennzeichen				character(20),			-- Inhalt rechts mit __ auf 20 aufgefüllt
	amtlicheflaeche					double precision,		-- AFL
	abweichenderrechtszustand			varchar DEFAULT 'false',	-- ARZ
	zweifelhafterflurstuecksnachweis		varchar DEFAULT 'false',	-- ZFM
	rechtsbehelfsverfahren				varchar DEFAULT 'false',	-- RBV
	zeitpunktderentstehung				character(10),			-- ZDE  Inhalt jjjj-mm-tt  besser Format date ?
	zeitpunktderhistorisierung                      character(10),
	gemeinde					varchar,
	-- GID: ENDE AX_Flurstueck_Kerndaten

	regierungsbezirk				varchar,
	kreis						varchar,
	vorgaengerflurstueckskennzeichen		varchar[],
	nachfolgerflurstueckskennzeichen		varchar[],
	blattart					integer,
	buchungsart					varchar,
	buchungsblattkennzeichen			varchar[],
	bezirk						varchar,
	buchungsblattnummermitbuchstabenerweiterung	varchar[],
	laufendenummerderbuchungsstelle			varchar,			-- tlw. nicht nummerische Werte in SN

	CONSTRAINT ax_historischesflurstueck_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_historischesflurstueck','wkb_geometry',:alkis_epsg,'GEOMETRY',2); -- POLYGON/MULTIPOLYGON

CREATE INDEX ax_historischesflurstueck_geom_idx   ON ax_historischesflurstueck USING gist (wkb_geometry);
CREATE UNIQUE INDEX ax_historischesflurstueck_gml ON ax_historischesflurstueck USING btree (gml_id,beginnt);

CREATE INDEX ax_historischesflurstueck_kennz      ON ax_historischesflurstueck USING btree (flurstueckskennzeichen);
COMMENT ON INDEX ax_historischesflurstueck_kennz IS 'Suche nach Flurstückskennzeichen';

-- Suche nach Vorgänger / Nachfolger
CREATE INDEX idx_histfs_vor ON ax_historischesflurstueck USING btree (vorgaengerflurstueckskennzeichen);
CREATE INDEX idx_histfs_nach ON ax_historischesflurstueck USING btree (nachfolgerflurstueckskennzeichen);

COMMENT ON INDEX idx_histfs_vor  IS 'Suchen nach Vorgänger-Flurstück';
COMMENT ON INDEX idx_histfs_nach IS 'Suchen nach Nachfolger-Flurstück';



-- H i s t o r i s c h e s   F l u r s t ü c k   A L B
-- ---------------------------------------------------
-- Objektart: AX_HistorischesFlurstueckALB Kennung: 17002

-- Variante A: "Standardhistorie" (statt ax_historischesflurstueckohneraumbezug)

-- Die "alte" Historie, die schon aus dem Vorgängerverfahren ALB übernommen wurde.
-- Vorgänger-Nachfolger-Beziehungen, ohne Geometrie

CREATE TABLE ax_historischesflurstueckalb (
	ogc_fid						serial NOT NULL,
	gml_id						character(16) NOT NULL,
	identifier					varchar,
	beginnt						character(20),
	endet						character(20),
	advstandardmodell				varchar[],
	sonstigesmodell					varchar[],
	anlass						varchar,
	name						varchar[],

	-- GID: AX_Flurstueck_Kerndaten
	-- 'Flurstück_Kerndaten' enthält Eigenschaften des Flurstücks, die auch für andere Flurstücksobjektarten gelten (z.B. Historisches Flurstück).
	land						varchar,
	gemarkungsnummer				varchar,
	flurnummer					integer,			-- Teile des Flurstückskennzeichens
	zaehler						integer,			--    (redundant zu flurstueckskennzeichen)
	nenner						varchar,			-- tlw. nicht nummerische Werte in SN
	flurstuecksfolge				varchar,
	-- daraus abgeleitet:
	flurstueckskennzeichen				character(20),			-- Inhalt rechts mit __ auf 20 aufgefüllt

	amtlicheflaeche					double precision,		-- AFL
	abweichenderrechtszustand			varchar DEFAULT 'false',	-- ARZ
	zweifelhafterFlurstuecksnachweis		varchar DEFAULT 'false',	-- ZFM
	rechtsbehelfsverfahren				varchar DEFAULT 'false',	-- RBV
	zeitpunktderentstehung				character(10),			-- ZDE  jjjj-mm-tt
	gemeinde					varchar,
	-- GID: ENDE AX_Flurstueck_Kerndaten

	blattart					integer,
	buchungsart					varchar[],
	buchungsblattkennzeichen			varchar[],
	bezirk						varchar,
	buchungsblattnummermitbuchstabenerweiterung	varchar[],
	laufendenummerderbuchungsstelle			varchar[],
	zeitpunktderentstehungdesbezugsflurstuecks	varchar,
	laufendenummerderfortfuehrung			varchar,
	fortfuehrungsart				varchar,
	vorgaengerflurstueckskennzeichen		varchar[],
	nachfolgerflurstueckskennzeichen		varchar[],

	CONSTRAINT ax_historischesflurstueckalb_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_historischesflurstueckalb','dummy',:alkis_epsg,'POINT',2);

CREATE UNIQUE INDEX ax_historischesflurstueckalb_gml ON ax_historischesflurstueckalb USING btree (gml_id,beginnt);
CREATE INDEX idx_histfsalb_vor ON ax_historischesflurstueckalb USING btree (vorgaengerflurstueckskennzeichen);
CREATE INDEX idx_histfsalb_nach ON ax_historischesflurstueckalb USING btree (nachfolgerflurstueckskennzeichen);

COMMENT ON INDEX idx_histfsalb_vor IS 'Suchen nach Vorgänger-Flurstück';
COMMENT ON INDEX idx_histfsalb_nach IS 'Suchen nach Nachfolger-Flurstück';

COMMENT ON COLUMN ax_historischesflurstueck.gemeinde  IS 'GDZ "Gemeindekennzeichen zur Zuordnung der Flurstücksdaten zu einer Gemeinde.';


-- Variante B: "Vollhistorie" (statt ax_historischesflurstueckalb)
-- H i s t o r i s c h e s   F l u r s t ü c k  O h n e   R a u m b e z u g
-- ------------------------------------------------------------------------
-- Objektart: AX_HistorischesFlurstueckOhneRaumbezug Kennung: 17003
CREATE TABLE ax_historischesflurstueckohneraumbezug (
	ogc_fid					serial NOT NULL,
	gml_id					character(16) NOT NULL,
	identifier				varchar,
	beginnt					character(20),
	endet					character(20),
	advstandardmodell			varchar[],
	sonstigesmodell				varchar[],
	anlass					varchar,
	name					varchar[],

	-- GID: AX_Flurstueck_Kerndaten
	-- 'Flurstück_Kerndaten' enthält Eigenschaften des Flurstücks, die auch für andere Flurstücksobjektarten gelten (z.B. Historisches Flurstück).
	land					varchar,
	gemarkungsnummer			varchar,
	flurnummer				integer,		-- Teile des Flurstückskennzeichens
	zaehler					varchar,		--    (redundant zu flurstueckskennzeichen)
	nenner					varchar,		-- tlw. nicht nummerische Werte in SN
	-- daraus abgeleitet:
	flurstueckskennzeichen			character(20),		-- Inhalt rechts mit __ auf 20 aufgefüllt
	amtlicheflaeche				double precision,	-- AFL
	abweichenderrechtszustand		varchar,		-- ARZ
	zweifelhafterFlurstuecksnachweis	varchar,		-- ZFM
	rechtsbehelfsverfahren			varchar,		-- RBV
	zeitpunktderentstehung			varchar,		-- ZDE  Inhalt jjjj-mm-tt  besser Format date ?
	gemeinde				varchar,
	-- GID: ENDE AX_Flurstueck_Kerndaten

	nachfolgerflurstueckskennzeichen	varchar[],
	vorgaengerflurstueckskennzeichen	varchar[],

	-- Beziehungen
	gehoertanteiligzu			character(16)[],
	weistauf				character(16)[],
	zeigtauf				character(16)[],
	istgebucht				character(16),

	CONSTRAINT ax_historischesflurstueckohneraumbezug_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_historischesflurstueckohneraumbezug','dummy',:alkis_epsg,'POINT',2);

CREATE INDEX ax_hist_fs_ohne_kennz ON ax_historischesflurstueckohneraumbezug USING btree (flurstueckskennzeichen);
COMMENT ON INDEX ax_hist_fs_ohne_kennz IS 'Suche nach Flurstückskennzeichen';

CREATE INDEX idx_histfsor_vor  ON ax_historischesflurstueckohneraumbezug USING btree (vorgaengerflurstueckskennzeichen);
CREATE INDEX idx_histfsor_nach ON ax_historischesflurstueckohneraumbezug USING btree (nachfolgerflurstueckskennzeichen);

CREATE INDEX ax_hist_gaz ON ax_historischesflurstueckohneraumbezug  USING gin   (gehoertanteiligzu);
CREATE INDEX ax_hist_ig  ON ax_historischesflurstueckohneraumbezug  USING btree (istgebucht);
CREATE INDEX ax_hist_wa  ON ax_historischesflurstueckohneraumbezug  USING gin   (weistauf);
CREATE INDEX ax_hist_za  ON ax_historischesflurstueckohneraumbezug  USING gin   (zeigtauf);

COMMENT ON COLUMN ax_historischesflurstueckohneraumbezug.anlass IS 'Anlass des Updates';
COMMENT ON COLUMN ax_historischesflurstueckohneraumbezug.name IS 'Array mit Fortführungsjahr und -Nummer';



-- *** ############################################################
-- *** Objektbereich: Eigentümer
-- *** ############################################################

-- ** Objektartengruppe: Personen- und Bestandsdaten
--   ===================================================================

-- P e r s o n
-- ----------------------------------------------
-- Objektart: AX_Person Kennung: 21001
CREATE TABLE ax_person (
	ogc_fid				serial NOT NULL,
	gml_id				character(16) NOT NULL,
	identifier			varchar,
	beginnt				character(20),
	endet				character(20),
	advstandardmodell		varchar[],
	sonstigesmodell			varchar[],
	anlass				varchar,
	nachnameoderfirma		varchar,
	anrede				integer,
	vorname				varchar,
	geburtsname			varchar,
	geburtsdatum			varchar,
	namensbestandteil		varchar,
	akademischergrad		varchar,

	-- Beziehungen
	hat				character(16)[],
	weistauf			character(16)[],
	wirdvertretenvon		character(16)[],
	gehoertzu			character(16)[],
	uebtaus				character(16)[],
	besitzt				character(16)[],
	zeigtauf			character(16),
	benennt				character(16)[],

	CONSTRAINT ax_person_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_person','dummy',:alkis_epsg,'POINT',2);

CREATE UNIQUE INDEX id_ax_person_gml ON ax_person USING btree (gml_id,beginnt);
CREATE INDEX ax_person_hat ON ax_person USING gin (hat);
CREATE INDEX ax_person_wa  ON ax_person USING gin (weistauf);
CREATE INDEX ax_person_wvv ON ax_person USING gin (wirdvertretenvon);
CREATE INDEX ax_person_gz  ON ax_person USING gin (gehoertzu);
CREATE INDEX ax_person_ua  ON ax_person USING gin (uebtaus);
CREATE INDEX ax_person_bes ON ax_person USING gin (besitzt);
CREATE INDEX ax_person_za  ON ax_person USING btree (zeigtauf);
CREATE INDEX ax_person_ben ON ax_person USING gin (benennt);



--AX_Personengruppe
-- Objektart: AX_Personengruppe Kennung: 21002
-- 'Personengruppe' ist die Zusammenfassung von Personen unter einem Ordnungsbegriff.
-- ** Tabelle bisher noch nicht generiert

-- A n s c h r i f t
-- ----------------------------------------------
-- Objektart: AX_Anschrift Kennung: 21003
CREATE TABLE ax_anschrift (
	ogc_fid				serial NOT NULL,
	gml_id				character(16) NOT NULL,
	identifier			varchar,
	beginnt				character(20),
	endet				character(20),
	advstandardmodell		varchar[],
	sonstigesmodell			varchar[],
	anlass				varchar,
	ort_post			varchar,
	postleitzahlpostzustellung	varchar,
	strasse				varchar,
	hausnummer			varchar,
	bestimmungsland			varchar,
	postleitzahlpostfach		varchar,
	postfach			varchar,
	ortsteil			varchar,
	weitereAdressen			varchar[],
	telefon				varchar,
	fax				varchar,
	organisationname		varchar,

	-- Beziehungen
	beziehtsichauf			character(16)[],
	gehoertzu			character(16)[],

	CONSTRAINT ax_anschrift_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_anschrift','dummy',:alkis_epsg,'POINT',2);

CREATE UNIQUE INDEX ax_anschrift_gml ON ax_anschrift USING btree (gml_id,beginnt);
CREATE INDEX ax_anschrift_bsa ON ax_anschrift USING gin (beziehtsichauf);
CREATE INDEX ax_anschrift_gz  ON ax_anschrift USING gin (gehoertzu);


-- V e r w a l t u n g
-- -------------------
-- Objektart: AX_Verwaltung Kennung: 21004
CREATE TABLE ax_verwaltung (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,

	-- Beziehungen
	beziehtsichauf		character(16)[],
	haengtan		character(16),

	CONSTRAINT ax_verwaltung_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_verwaltung','dummy',:alkis_epsg,'POINT',2);


-- V e r t r e t u n g
-- -------------------
-- Objektart: AX_Vertretung Kennung: 21005
CREATE TABLE ax_vertretung (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,

	-- Beziehung
	vertritt		character(16)[],
	haengtan		character(16),
	beziehtsichauf		character(16)[],

	CONSTRAINT ax_vertretung_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_vertretung','dummy',:alkis_epsg,'POINT',2);



-- N a m e n s n u m m e r
-- ----------------------------------------------
-- AX_Namensnummer Kennung: 21006
CREATE TABLE ax_namensnummer (
	ogc_fid					serial NOT NULL,
	gml_id					character(16) NOT NULL,
	identifier				varchar,
	beginnt					character(20),
	endet					character(20),
	advstandardmodell			varchar[],
	sonstigesmodell				varchar[],
	anlass					varchar,
	laufendenummernachdin1421		character(16),      -- 0000.00.00.00.00
	zaehler					double precision,   -- Anteil ..
	nenner					double precision,   --    .. als Bruch
	eigentuemerart				integer,
	nummer					varchar, -- immer leer ?
	artderrechtsgemeinschaft		integer, -- Schlüssel
	beschriebderrechtsgemeinschaft		varchar,

	-- Beziehungen
	bestehtausrechtsverhaeltnissenzu	character(16),
	istbestandteilvon			character(16),
	hatvorgaenger				character(16)[],
	benennt					character(16),

	CONSTRAINT ax_namensnummer_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_namensnummer','dummy',:alkis_epsg,'POINT',2);

-- Verbindungstabellen indizieren
CREATE UNIQUE INDEX ax_namensnummer_gml ON ax_namensnummer USING btree (gml_id,beginnt);
CREATE INDEX ax_namensnummer_barvz ON ax_namensnummer USING btree (bestehtausrechtsverhaeltnissenzu);
CREATE INDEX ax_namensnummer_ibv   ON ax_namensnummer USING btree (istbestandteilvon);
CREATE INDEX ax_namensnummer_hv    ON ax_namensnummer USING gin (hatvorgaenger);
CREATE INDEX ax_namensnummer_ben   ON ax_namensnummer USING btree (benennt);



-- B u c h u n g s b l a t t
-- -------------------------
-- Objektart: AX_Buchungsblatt Kennung: 21007
CREATE TABLE ax_buchungsblatt (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	buchungsblattkennzeichen	varchar,
	land			varchar,
	bezirk			varchar,
	buchungsblattnummermitbuchstabenerweiterung	varchar,
	blattart		varchar,
	art			varchar,

	-- Beziehung
	bestehtaus		character(16)[],

	CONSTRAINT ax_buchungsblatt_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_buchungsblatt','dummy',:alkis_epsg,'POINT',2);

CREATE UNIQUE INDEX ax_buchungsblatt_gml ON ax_buchungsblatt USING btree (gml_id,beginnt);
CREATE INDEX ax_buchungsblatt_lbb ON ax_buchungsblatt USING btree (land,bezirk,buchungsblattnummermitbuchstabenerweiterung);
CREATE INDEX ax_buchungsblatt_bsa ON ax_buchungsblatt USING gin (bestehtaus);


-- B u c h u n g s s t e l l e
-- -----------------------------
-- Objektart: AX_Buchungsstelle Kennung: 21008
CREATE TABLE ax_buchungsstelle (
	ogc_fid					serial NOT NULL,
	gml_id					character(16) NOT NULL,
	identifier				varchar,
	beginnt					character(20),
	endet					character(20),
	advstandardmodell			varchar[],
	sonstigesmodell				varchar[],
	anlass					varchar,
	buchungsart				integer,
	laufendenummer				varchar,
	beschreibungdesumfangsderbuchung	character(1),
	zaehler					double precision,
	nenner					double precision,
	nummerimaufteilungsplan			varchar,
	beschreibungdessondereigentums		varchar,
	buchungstext				varchar,

	-- Beziehungen
	istbestandteilvon			character(16),
	durch					character(16)[],
	verweistauf				character(16)[],
	grundstueckbestehtaus			character(16)[],
	zu					character(16)[],
	an					character(16)[],
	hatvorgaenger				character(16)[],
	wirdverwaltetvon			character(16),
	beziehtsichauf				character(16)[],

	CONSTRAINT ax_buchungsstelle_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_buchungsstelle','dummy',:alkis_epsg,'POINT',2);

CREATE UNIQUE INDEX ax_buchungsstelle_gml ON ax_buchungsstelle USING btree (gml_id,beginnt);
CREATE INDEX ax_buchungsstelle_ibv   ON ax_buchungsstelle USING btree (istbestandteilvon);
CREATE INDEX ax_buchungsstelle_durch ON ax_buchungsstelle USING gin (durch);
CREATE INDEX ax_buchungsstelle_vwa   ON ax_buchungsstelle USING gin (verweistauf);
CREATE INDEX ax_buchungsstelle_gba   ON ax_buchungsstelle USING gin (grundstueckbestehtaus);
CREATE INDEX ax_buchungsstelle_zu    ON ax_buchungsstelle USING gin (zu);
CREATE INDEX ax_buchungsstelle_an    ON ax_buchungsstelle USING gin (an);
CREATE INDEX ax_buchungsstelle_hv    ON ax_buchungsstelle USING gin (hatvorgaenger);
CREATE INDEX ax_buchungsstelle_wvv   ON ax_buchungsstelle USING btree (wirdverwaltetvon);
CREATE INDEX ax_buchungsstelle_bsa   ON ax_buchungsstelle USING gin (beziehtsichauf);



--*** ############################################################
--*** Objektbereich: Gebäude
--*** ############################################################

--** Objektartengruppe: Angaben zum Gebäude
--   ===================================================================

-- G e b ä u d e
-- ---------------
-- Objektart: AX_Gebaeude Kennung: 31001
CREATE TABLE ax_gebaeude (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	gebaeudefunktion	integer,  -- Werte siehe Schlüsseltabelle
	weiteregebaeudefunktion	integer[],
	name			varchar[],
	bauweise		integer,
	anzahlderoberirdischengeschosse	integer,
	anzahlderunterirdischengeschosse	integer,
	hochhaus                varchar,  -- "true"/"false", meist leer
	objekthoehe		double precision,
	dachform		integer,
	zustand			integer,
	geschossflaeche		double precision,
	grundflaeche		double precision,
	umbauterraum		double precision,
	baujahr			integer,
	lagezurerdoberflaeche	integer,
	dachart			varchar,
	dachgeschossausbau	integer,
	qualitaetsangaben	varchar,
	ax_datenerhebung	integer,
	description		integer,
	art			varchar,
	individualname		varchar,

	-- Beziehungen
	gehoertzu		character(16),
	hat			character(16),
	gehoert			character(16)[],
	zeigtauf		character(16)[],
	haengtzusammenmit	character(16),

	CONSTRAINT ax_gebaeude_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_gebaeude','wkb_geometry',:alkis_epsg,'GEOMETRY',2); -- POLYGON/MULTIPOLYGON

CREATE INDEX ax_gebaeude_geom_idx   ON ax_gebaeude USING gist (wkb_geometry);
CREATE UNIQUE INDEX ax_gebaeude_gml ON ax_gebaeude USING btree (gml_id,beginnt);
CREATE INDEX ax_gebaeude_gz  ON ax_gebaeude USING btree (gehoertzu);
CREATE INDEX ax_gebaeude_hat ON ax_gebaeude USING btree (hat);
CREATE INDEX ax_gebaeude_geh ON ax_gebaeude USING gin (gehoert);
CREATE INDEX ax_gebaeude_za  ON ax_gebaeude USING gin (zeigtauf);
CREATE INDEX ax_gebaeude_hzm ON ax_gebaeude USING btree (haengtzusammenmit);



-- B a u t e i l
-- -------------
-- Objektart: AX_Bauteil Kennung: 31002
CREATE TABLE ax_bauteil (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	bauart			integer,
	dachform		integer,
	anzahlderoberirdischengeschosse	integer,
	anzahlderunterirdischengeschosse	integer,
	lagezurerdoberflaeche	integer,
	CONSTRAINT ax_bauteil_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_bauteil','wkb_geometry',:alkis_epsg,'GEOMETRY',2);

CREATE INDEX ax_bauteil_geom_idx ON ax_bauteil USING gist (wkb_geometry);

CREATE UNIQUE INDEX ax_bauteil_gml ON ax_bauteil USING btree (gml_id,beginnt);



-- B e s o n d e r e   G e b ä u d e l i n i e
-- ----------------------------------------------
-- Objektart: AX_BesondereGebaeudelinie Kennung: 31003
CREATE TABLE ax_besonderegebaeudelinie (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	beschaffenheit		integer[],
	anlass			varchar,
	CONSTRAINT ax_besonderegebaeudelinie_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_besonderegebaeudelinie','wkb_geometry',:alkis_epsg,'GEOMETRY',2); -- LINESTRING/MULTILINESTRING

CREATE INDEX ax_besonderegebaeudelinie_geom_idx ON ax_besonderegebaeudelinie USING gist (wkb_geometry);
CREATE UNIQUE INDEX ax_besonderegebaeudelinie_gml ON ax_besonderegebaeudelinie USING btree (gml_id,beginnt);
CREATE INDEX ax_besonderegebaeudelinie_bes ON ax_besonderegebaeudelinie USING gin (beschaffenheit);



-- F i r s t l i n i e
-- -----------------------------------------------------
-- Objektart: AX_Firstlinie Kennung: 31004
CREATE TABLE ax_firstlinie (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	art			varchar,
	uri			varchar,
	CONSTRAINT ax_firstlinie_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_firstlinie','wkb_geometry',:alkis_epsg,'LINESTRING',2);

CREATE INDEX ax_firstlinie_geom_idx ON ax_firstlinie USING gist (wkb_geometry);
CREATE UNIQUE INDEX ax_firstlinie_gml ON ax_firstlinie USING btree (gml_id,beginnt);



-- B e s o n d e r e r   G e b ä u d e p u n k t
-- -----------------------------------------------
-- Objektart: AX_BesondererGebaeudepunkt Kennung: 31005
CREATE TABLE ax_besonderergebaeudepunkt (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	land			varchar,
	stelle			varchar,
	punktkennung		varchar,
	art			varchar,
	name			varchar[],
	sonstigeeigenschaft	varchar[],
	CONSTRAINT ax_besonderergebaeudepunkt_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_besonderergebaeudepunkt','dummy',:alkis_epsg,'POINT',2);

CREATE UNIQUE INDEX ax_besonderergebaeudepunkt_gml ON ax_besonderergebaeudepunkt USING btree (gml_id,beginnt);


--*** ############################################################
--*** Objektbereich: Tatsächliche Nutzung (AX_TatsaechlicheNutzung)
--*** ############################################################
-- Objektart: AX_TatsaechlicheNutzung Kennung: 40001
-- abstrakte Oberklasse für alle tatsächlichen Nutzungen

-- Gemeinsame Attribute:
--   DLU datumDerLetztenUeberpruefung DateTime
--   DAQ qualitaetsangaben

--** Objektartengruppe: Siedlung (in Objektbereich: Tatsächliche Nutzung)
--   ====================================================================

-- W o h n b a u f l ä c h e
-- ----------------------------------------------
-- Objektart: AX_Wohnbauflaeche Kennung: 41001
CREATE TABLE ax_wohnbauflaeche (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	artderbebauung		integer,
	zustand			integer,
	name			varchar,
	CONSTRAINT ax_wohnbauflaeche_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_wohnbauflaeche','wkb_geometry',:alkis_epsg,'GEOMETRY',2);

CREATE INDEX ax_wohnbauflaeche_geom_idx ON ax_wohnbauflaeche USING gist (wkb_geometry);

CREATE UNIQUE INDEX ax_wohnbauflaeche_gml ON ax_wohnbauflaeche USING btree (gml_id,beginnt);



-- Objektart: I n d u s t r i e -   u n d   G e w e r b e f l ä c h e
-- --------------------------------------------------------------------
-- Objektart: AX_IndustrieUndGewerbeflaeche Kennung: 41002
CREATE TABLE ax_industrieundgewerbeflaeche (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	funktion		integer,
	name			varchar,
	zustand			integer,
	foerdergut		integer,
	primaerenergie		integer,
	lagergut		integer,
	CONSTRAINT ax_industrieundgewerbeflaeche_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_industrieundgewerbeflaeche','wkb_geometry',:alkis_epsg,'GEOMETRY',2); -- POLYGON/POINT

CREATE INDEX ax_industrieundgewerbeflaeche_geom_idx ON ax_industrieundgewerbeflaeche USING gist (wkb_geometry);

CREATE UNIQUE INDEX ax_industrieundgewerbeflaeche_gml ON ax_industrieundgewerbeflaeche USING btree (gml_id,beginnt);



-- H a l d e
-- ----------------------------------------------
-- Objektart: AX_Halde Kennung: 41003
CREATE TABLE ax_halde (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	lagergut		integer,
	name			varchar,
	zustand			integer,
	CONSTRAINT ax_halde_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_halde','wkb_geometry',:alkis_epsg,'GEOMETRY',2);

CREATE INDEX ax_halde_geom_idx ON ax_halde USING gist (wkb_geometry);
CREATE UNIQUE INDEX ax_halde_gml ON ax_halde USING btree (gml_id,beginnt);


-- B e r b a u b e t r i e b
-- -------------------------
-- Objektart: AX_Bergbaubetrieb Kennung: 41004
CREATE TABLE ax_bergbaubetrieb (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	abbaugut		integer,
	name			varchar,
	bezeichnung		varchar,
	zustand			integer,
	CONSTRAINT ax_bergbaubetrieb_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_bergbaubetrieb','wkb_geometry',:alkis_epsg,'GEOMETRY',2);

CREATE INDEX ax_bergbaubetrieb_geom_idx   ON ax_bergbaubetrieb USING gist  (wkb_geometry);
CREATE UNIQUE INDEX ax_bergbaubetrieb_gml ON ax_bergbaubetrieb USING btree (gml_id,beginnt);


-- T a g e b a u  /  G r u b e  /  S t e i n b r u c h
-- ---------------------------------------------------
-- Objektart: AX_TagebauGrubeSteinbruch Kennung: 41005
CREATE TABLE ax_tagebaugrubesteinbruch (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	abbaugut		integer,
	name			varchar,
	zustand			integer,

	CONSTRAINT ax_tagebaugrubesteinbruch_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_tagebaugrubesteinbruch','wkb_geometry',:alkis_epsg,'GEOMETRY',2);

CREATE INDEX ax_tagebaugrubesteinbruch_geom_idx ON ax_tagebaugrubesteinbruch USING gist (wkb_geometry);

CREATE UNIQUE INDEX ax_tagebaugrubesteinbruchb_gml ON ax_tagebaugrubesteinbruch USING btree (gml_id,beginnt);



-- F l ä c h e n   g e m i s c h t e r   N u t z u n g
-- -----------------------------------------------------
-- Objektart: AX_FlaecheGemischterNutzung Kennung: 41006
CREATE TABLE ax_flaechegemischternutzung (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	artderbebauung		integer,
	funktion		integer,
	name			varchar,
	zustand			integer,
	CONSTRAINT ax_flaechegemischternutzung_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_flaechegemischternutzung','wkb_geometry',:alkis_epsg,'GEOMETRY',2);

CREATE INDEX ax_flaechegemischternutzung_geom_idx ON ax_flaechegemischternutzung USING gist (wkb_geometry);
CREATE UNIQUE INDEX ax_flaechegemischternutzung_gml ON ax_flaechegemischternutzung USING btree (gml_id,beginnt);


-- F l ä c h e   b e s o n d e r e r   f u n k t i o n a l e r   P r ä g u n g
-- -------------------------------------------------------------------------------
-- Objektart: AX_FlaecheBesondererFunktionalerPraegung Kennung: 41007
CREATE TABLE ax_flaechebesondererfunktionalerpraegung (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	funktion		integer,
	artderbebauung		integer,
	name			varchar,
	zustand			integer,
	CONSTRAINT ax_flaechebesondererfunktionalerpraegung_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_flaechebesondererfunktionalerpraegung','wkb_geometry',:alkis_epsg,'GEOMETRY',2);

CREATE INDEX ax_flaechebesondererfunktionalerpraegung_geom_idx ON ax_flaechebesondererfunktionalerpraegung USING gist (wkb_geometry);
CREATE UNIQUE INDEX ax_flaechebesondererfunktionalerpraegung_gml ON ax_flaechebesondererfunktionalerpraegung USING btree (gml_id,beginnt);


-- S p o r t - ,   F r e i z e i t -   u n d   E r h o h l u n g s f l ä c h e
-- ---------------------------------------------------------------------------
-- Objektart: AX_SportFreizeitUndErholungsflaeche Kennung: 41008
CREATE TABLE ax_sportfreizeitunderholungsflaeche (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	funktion		integer,
	zustand			integer,
	name			varchar,
	CONSTRAINT ax_sportfreizeitunderholungsflaeche_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_sportfreizeitunderholungsflaeche','wkb_geometry',:alkis_epsg,'GEOMETRY',2);

CREATE INDEX ax_sportfreizeitunderholungsflaeche_geom_idx ON ax_sportfreizeitunderholungsflaeche USING gist (wkb_geometry);

CREATE UNIQUE INDEX ax_sportfreizeitunderholungsflaeche_gml ON ax_sportfreizeitunderholungsflaeche USING btree (gml_id,beginnt);


-- F r i e d h o f
-- ----------------
-- Objektart: AX_Friedhof Kennung: 41009
CREATE TABLE ax_friedhof (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	funktion		integer,
	name			varchar,
	zustand			integer,
	CONSTRAINT ax_friedhof_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_friedhof','wkb_geometry',:alkis_epsg,'GEOMETRY',2);

CREATE INDEX ax_friedhof_geom_idx ON ax_friedhof USING gist (wkb_geometry);
CREATE UNIQUE INDEX ax_friedhof_gml ON ax_friedhof USING btree (gml_id,beginnt);


--** Objektartengruppe: Verkehr (in Objektbereich: Tatsächliche Nutzung)
--   ===================================================================

-- S t r a s s e n v e r k e h r
-- ----------------------------------------------
-- Objektart: AX_Strassenverkehr Kennung: 42001
CREATE TABLE ax_strassenverkehr (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	funktion		integer,
	name			varchar,
	zweitname		varchar,
	zustand			integer,
	land			varchar,
	regierungsbezirk	varchar,
	kreis			varchar,
	gemeinde		varchar,
	lage			varchar,
	unverschluesselt	varchar,
	CONSTRAINT ax_strassenverkehr_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_strassenverkehr','wkb_geometry',:alkis_epsg,'GEOMETRY',2);

CREATE INDEX ax_strassenverkehr_geom_idx ON ax_strassenverkehr USING gist (wkb_geometry);
CREATE UNIQUE INDEX ax_strassenverkehr_gml ON ax_strassenverkehr USING btree (gml_id,beginnt);


-- W e g
-- ----------------------------------------------
-- Objektart: AX_Strassenverkehr Kennung: 42001
CREATE TABLE ax_weg (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	funktion		integer,
	name			varchar,
	bezeichnung		varchar,
	land			varchar,
	regierungsbezirk	varchar,
	kreis			varchar,
	gemeinde		varchar,
	lage			varchar,
	unverschluesselt	varchar,
	CONSTRAINT ax_weg_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_weg','wkb_geometry',:alkis_epsg,'GEOMETRY',2);

CREATE INDEX ax_weg_geom_idx ON ax_weg USING gist (wkb_geometry);
CREATE UNIQUE INDEX ax_weg_gml ON ax_weg USING btree (gml_id,beginnt);


-- P l a t z
-- ----------------------------------------------
-- Objektart: AX_Platz Kennung: 42009
CREATE TABLE ax_platz (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	funktion		integer,
	name			varchar,
	zweitname		varchar,
	land			varchar,
	regierungsbezirk	varchar,
	kreis			varchar,
	gemeinde		varchar,
	lage			varchar, -- Straßenschlüssel
	unverschluesselt	varchar, -- Gewanne?
	CONSTRAINT ax_platz_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_platz','wkb_geometry',:alkis_epsg,'GEOMETRY',2);

CREATE INDEX ax_platz_geom_idx ON ax_platz USING gist (wkb_geometry);
CREATE UNIQUE INDEX ax_platz_gml ON ax_platz USING btree (gml_id,beginnt);


-- B a h n v e r k e h r
-- ----------------------------------------------
-- Objektart: AX_Bahnverkehr Kennung: 42010
CREATE TABLE ax_bahnverkehr (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	funktion		integer,
	bahnkategorie		integer,
	bezeichnung		varchar,
	nummerderbahnstrecke	varchar,
	zweitname		varchar,
	zustand			integer,
	CONSTRAINT ax_bahnverkehr_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_bahnverkehr','wkb_geometry',:alkis_epsg,'GEOMETRY',2);

CREATE INDEX ax_bahnverkehr_geom_idx ON ax_bahnverkehr USING gist (wkb_geometry);
CREATE UNIQUE INDEX ax_bahnverkehr_gml ON ax_bahnverkehr USING btree (gml_id,beginnt);


-- F l u g v e r k e h r
-- ----------------------
-- Objektart: AX_Flugverkehr Kennung: 42015
CREATE TABLE ax_flugverkehr (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	funktion		integer,
	art			integer,
	name			varchar,
	bezeichnung		varchar,
	nutzung			integer,
	zustand			integer,
	CONSTRAINT ax_flugverkehr_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_flugverkehr','wkb_geometry',:alkis_epsg,'GEOMETRY',2);

CREATE INDEX ax_flugverkehr_geom_idx   ON ax_flugverkehr USING gist  (wkb_geometry);
CREATE UNIQUE INDEX ax_flugverkehr_gml ON ax_flugverkehr USING btree (gml_id,beginnt);


-- S c h i f f s v e r k e h r
-- ---------------------------
-- Objektart: AX_Schiffsverkehr Kennung: 42016
CREATE TABLE ax_schiffsverkehr (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	funktion		integer,
	name			varchar,
	zustand			integer,
	CONSTRAINT ax_schiffsverkehr_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_schiffsverkehr','wkb_geometry',:alkis_epsg,'GEOMETRY',2);

CREATE INDEX ax_schiffsverkehr_geom_idx ON ax_schiffsverkehr USING gist (wkb_geometry);
CREATE UNIQUE INDEX ax_schiffsverkehr_gml ON ax_schiffsverkehr USING btree (gml_id,beginnt);


--** Objektartengruppe:Vegetation (in Objektbereich:Tatsächliche Nutzung)
--   ===================================================================

-- L a n d w i r t s c h a f t
-- ----------------------------------------------
-- Objektart: AX_Landwirtschaft Kennung: 43001
CREATE TABLE ax_landwirtschaft (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	vegetationsmerkmal	integer,
	name			varchar,
	CONSTRAINT ax_landwirtschaft_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_landwirtschaft','wkb_geometry',:alkis_epsg,'GEOMETRY',2);

CREATE INDEX ax_landwirtschaft_geom_idx ON ax_landwirtschaft USING gist (wkb_geometry);
CREATE UNIQUE INDEX ax_landwirtschaft_gml ON ax_landwirtschaft USING btree (gml_id,beginnt);


-- W a l d
-- ----------------------------------------------
-- Objektart: AX_Wald Kennung: 43002
CREATE TABLE ax_wald (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	vegetationsmerkmal	integer,
	name			varchar,
	bezeichnung		varchar,
	CONSTRAINT ax_wald_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_wald','wkb_geometry',:alkis_epsg,'GEOMETRY',2);

CREATE INDEX ax_wald_geom_idx ON ax_wald USING gist (wkb_geometry);
CREATE UNIQUE INDEX ax_wald_gml ON ax_wald USING btree (gml_id,beginnt);


-- G e h ö l z
-- ----------------------------------------------
-- Objektart: AX_Gehoelz Kennung: 43003
CREATE TABLE ax_gehoelz (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	vegetationsmerkmal	integer,
	name			varchar,
	funktion		integer,
	CONSTRAINT ax_gehoelz_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_gehoelz','wkb_geometry',:alkis_epsg,'GEOMETRY',2);

CREATE INDEX ax_gehoelz_geom_idx ON ax_gehoelz USING gist (wkb_geometry);
CREATE UNIQUE INDEX ax_gehoelz_gml ON ax_gehoelz USING btree (gml_id,beginnt);


-- H e i d e
-- ----------------------------------------------
-- Objektart: AX_Heide Kennung: 43004
CREATE TABLE ax_heide (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	name			varchar,
	CONSTRAINT ax_heide_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_heide','wkb_geometry',:alkis_epsg,'GEOMETRY',2);

CREATE INDEX ax_heide_geom_idx ON ax_heide USING gist (wkb_geometry);
CREATE UNIQUE INDEX ax_heide_gml ON ax_heide USING btree (gml_id,beginnt);


-- M o o r
-- ----------------------------------------------
-- Objektart: AX_Moor Kennung: 43005
CREATE TABLE ax_moor (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	name			varchar,
	CONSTRAINT ax_moor_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_moor','wkb_geometry',:alkis_epsg,'GEOMETRY',2);

CREATE INDEX ax_moor_geom_idx   ON ax_moor USING gist (wkb_geometry);
CREATE UNIQUE INDEX ax_moor_gml ON ax_moor USING btree (gml_id,beginnt);

-- Torfstich bzw. Torfabbaufläche wird der Objektart 41005 'Tagebau, Grube, Steinbruch' mit AGT 'Torf' zugeordnet.


-- S u m p f
-- ----------------------------------------------
-- Objektart: AX_Sumpf Kennung: 43006
CREATE TABLE ax_sumpf (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	name			varchar,
	CONSTRAINT ax_sumpf_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_sumpf','wkb_geometry',:alkis_epsg,'GEOMETRY',2);

CREATE INDEX ax_sumpf_geom_idx ON ax_sumpf USING gist (wkb_geometry);
CREATE UNIQUE INDEX ax_sumpf_gml ON ax_sumpf USING btree (gml_id,beginnt);


-- U n l a n d  /  V e g e t a t i o n s f l ä c h e
-- ---------------------------------------------------
-- Objektart: AX_UnlandVegetationsloseFlaeche Kennung: 43007
CREATE TABLE ax_unlandvegetationsloseflaeche (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	oberflaechenmaterial	integer,
	name			varchar,
	funktion		integer,
	CONSTRAINT ax_unlandvegetationsloseflaeche_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_unlandvegetationsloseflaeche','wkb_geometry',:alkis_epsg,'GEOMETRY',2);

CREATE INDEX ax_unlandvegetationsloseflaeche_geom_idx ON ax_unlandvegetationsloseflaeche USING gist (wkb_geometry);
CREATE UNIQUE INDEX ax_unlandvegetationsloseflaeche_gml ON ax_unlandvegetationsloseflaeche USING btree (gml_id,beginnt);


--** Objektartengruppe: Gewässer (in Objektbereich: Tatsächliche Nutzung)
--   ===================================================================

-- F l i e s s g e w ä s s e r
-- ----------------------------------------------
-- Objektart: AX_Fliessgewaesser Kennung: 44001
CREATE TABLE ax_fliessgewaesser (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	funktion		integer,
	name			varchar,
	zustand			integer,
	unverschluesselt	varchar,
	CONSTRAINT ax_fliessgewaesser_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_fliessgewaesser','wkb_geometry',:alkis_epsg,'GEOMETRY',2);

CREATE INDEX ax_fliessgewaesser_geom_idx ON ax_fliessgewaesser USING gist (wkb_geometry);
CREATE UNIQUE INDEX ax_fliessgewaesser_gml ON ax_fliessgewaesser USING btree (gml_id,beginnt);


-- H a f e n b e c k e n
-- ---------------------
-- Objektart: AX_Hafenbecken Kennung: 44005
CREATE TABLE ax_hafenbecken (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	funktion		integer,
	name			varchar,
	nutzung			integer,
	CONSTRAINT ax_hafenbecken_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_hafenbecken','wkb_geometry',:alkis_epsg,'GEOMETRY',2);

CREATE INDEX ax_hafenbecken_geom_idx   ON ax_hafenbecken USING gist  (wkb_geometry);
CREATE UNIQUE INDEX ax_hafenbecken_gml ON ax_hafenbecken USING btree (gml_id,beginnt);


-- S t e h e n d e s   G e w ä s s e r
-- ----------------------------------------------
-- Objektart: AX_StehendesGewaesser Kennung: 44006
CREATE TABLE ax_stehendesgewaesser (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	funktion		integer,
	name			varchar,
	gewaesserkennziffer	varchar,
	hydrologischesmerkmal	integer,
	unverschluesselt	varchar,
	CONSTRAINT ax_stehendesgewaesser_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_stehendesgewaesser','wkb_geometry',:alkis_epsg,'GEOMETRY',2);

CREATE INDEX ax_stehendesgewaesser_geom_idx ON ax_stehendesgewaesser USING gist (wkb_geometry);
CREATE UNIQUE INDEX ax_stehendesgewaesser_gml ON ax_stehendesgewaesser USING btree (gml_id,beginnt);


-- M e e r
-- ----------------------------------------------
-- Objektart: AX_Meer Kennung: 44007
CREATE TABLE ax_meer (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	funktion		integer,
	name			varchar,
	bezeichnung		varchar,
	tidemerkmal		integer,
	CONSTRAINT ax_meer_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_meer','wkb_geometry',:alkis_epsg,'GEOMETRY',2);

CREATE INDEX ax_meer_geom_idx ON ax_meer USING gist (wkb_geometry);
CREATE UNIQUE INDEX ax_meer_gml ON ax_meer USING btree (gml_id,beginnt);


--*** ############################################################
--*** Objektbereich: Bauwerke, Einrichtungen und sonstige Angaben
--*** ############################################################
-- .. ist Ziel einer Relation


--** Objektartengruppe: Bauwerke und Einrichtungen in Siedlungsflächen
--   ===================================================================

-- T u r m
-- ---------------------------------------------------
-- Objektart: AX_Turm Kennung: 51001
CREATE TABLE ax_turm (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	bauwerksfunktion	integer,
	zustand			integer,
	name			varchar,

	-- Beziehung
	zeigtauf		character(16),

	CONSTRAINT ax_turm_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_turm','wkb_geometry',:alkis_epsg,'GEOMETRY',2);

CREATE INDEX ax_turm_geom_idx ON ax_turm USING gist (wkb_geometry);
CREATE UNIQUE INDEX ax_turm_gml ON ax_turm USING btree (gml_id,beginnt);
CREATE INDEX ax_turm_za ON ax_turm USING btree (zeigtauf);


-- Bauwerk oder Anlage fuer Industrie und Gewerbe
-- ----------------------------------------------
-- Objektart: AX_BauwerkOderAnlageFuerIndustrieUndGewerbe Kennung: 51002
CREATE TABLE ax_bauwerkoderanlagefuerindustrieundgewerbe (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	bauwerksfunktion	integer,
	name			varchar,
	zustand			integer,
	objekthoehe		double precision,
	CONSTRAINT ax_bauwerkoderanlagefuerindustrieundgewerbe_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_bauwerkoderanlagefuerindustrieundgewerbe','wkb_geometry',:alkis_epsg,'GEOMETRY',2); -- POLYGON/POINT

CREATE INDEX ax_bauwerkoderanlagefuerindustrieundgewerbe_geom_idx ON ax_bauwerkoderanlagefuerindustrieundgewerbe USING gist (wkb_geometry);
CREATE UNIQUE INDEX ax_bauwerkoderanlagefuerindustrieundgewerbe_gml ON ax_bauwerkoderanlagefuerindustrieundgewerbe USING btree (gml_id,beginnt);


-- V o r r a t s b e h ä l t e r  /  S p e i c h e r b a u w e r k
-- -----------------------------------------------------------------
-- Objektart: AX_VorratsbehaelterSpeicherbauwerk Kennung: 51003
CREATE TABLE ax_vorratsbehaelterspeicherbauwerk (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	speicherinhalt		integer,
	bauwerksfunktion	integer,
	lagezurerdoberflaeche   integer,
	name			varchar,
	CONSTRAINT ax_vorratsbehaelterspeicherbauwerk_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_vorratsbehaelterspeicherbauwerk','wkb_geometry',:alkis_epsg,'GEOMETRY',2);

CREATE INDEX ax_vorratsbehaelterspeicherbauwerk_geom_idx ON ax_vorratsbehaelterspeicherbauwerk USING gist (wkb_geometry);
CREATE UNIQUE INDEX ax_vorratsbehaelterspeicherbauwerk_gml ON ax_vorratsbehaelterspeicherbauwerk USING btree (gml_id,beginnt);


-- T r a n s p o r t a n l a g e
-- ---------------------------------------------------
-- Objektart: AX_Transportanlage Kennung: 51004
CREATE TABLE ax_transportanlage (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	bauwerksfunktion	integer,
	lagezurerdoberflaeche	integer,
	art			varchar,
	name			varchar,
	produkt                 integer,
	CONSTRAINT ax_transportanlage_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_transportanlage','wkb_geometry',:alkis_epsg,'GEOMETRY',2); -- POINT/LINESTRING

CREATE INDEX ax_transportanlage_geom_idx ON ax_transportanlage USING gist (wkb_geometry);
CREATE UNIQUE INDEX ax_transportanlage_gml ON ax_transportanlage USING btree (gml_id,beginnt);


-- L e i t u n g
-- ----------------------------------------------
-- Objektart: AX_Leitung Kennung: 51005
CREATE TABLE ax_leitung (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	bauwerksfunktion	integer,
	spannungsebene		integer,
	CONSTRAINT ax_leitung_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_leitung','wkb_geometry',:alkis_epsg,'LINESTRING',2);

CREATE INDEX ax_leitung_geom_idx ON ax_leitung USING gist (wkb_geometry);
CREATE UNIQUE INDEX ax_leitung_gml ON ax_leitung USING btree (gml_id,beginnt);


-- Bauwerk oder Anlage fuer Sport, Freizeit und Erholung
-- -----------------------------------------------------
-- Objektart: AX_BauwerkOderAnlageFuerSportFreizeitUndErholung Kennung: 51006
CREATE TABLE ax_bauwerkoderanlagefuersportfreizeitunderholung (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	bauwerksfunktion	integer,
	sportart		integer,
	name			varchar,
	CONSTRAINT ax_bauwerkoderanlagefuersportfreizeitunderholung_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_bauwerkoderanlagefuersportfreizeitunderholung','wkb_geometry',:alkis_epsg,'GEOMETRY',2); -- POLYGON/POINT

CREATE INDEX ax_bauwerkoderanlagefuersportfreizeitunderholung_geom_idx ON ax_bauwerkoderanlagefuersportfreizeitunderholung USING gist (wkb_geometry);
CREATE UNIQUE INDEX ax_bauwerkoderanlagefuersportfreizeitunderholung_gml ON ax_bauwerkoderanlagefuersportfreizeitunderholung USING btree (gml_id,beginnt);


-- Historisches Bauwerk oder historische Einrichtung
-- -------------------------------------------------
-- Objektart: AX_HistorischesBauwerkOderHistorischeEinrichtung Kennung: 51007
CREATE TABLE ax_historischesbauwerkoderhistorischeeinrichtung (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	archaeologischertyp	integer,
	name			varchar,
	CONSTRAINT ax_historischesbauwerkoderhistorischeeinrichtung_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_historischesbauwerkoderhistorischeeinrichtung','wkb_geometry',:alkis_epsg,'GEOMETRY',2); -- POLYGON/POINT

CREATE INDEX ax_historischesbauwerkoderhistorischeeinrichtung_geom_idx ON ax_historischesbauwerkoderhistorischeeinrichtung USING gist (wkb_geometry);
CREATE UNIQUE INDEX ax_historischesbauwerkoderhistorischeeinrichtung_gml ON ax_historischesbauwerkoderhistorischeeinrichtung USING btree (gml_id,beginnt);


-- H e i l q u e l l e  /  G a s q u e l l e
-- ----------------------------------------------
-- Objektart: AX_HeilquelleGasquelle Kennung: 51008
CREATE TABLE ax_heilquellegasquelle (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	art			integer,
	name			varchar,
	CONSTRAINT ax_heilquellegasquelle_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_heilquellegasquelle','wkb_geometry',:alkis_epsg,'POINT',2);

CREATE INDEX ax_heilquellegasquelle_geom_idx ON ax_heilquellegasquelle USING gist (wkb_geometry);
CREATE UNIQUE INDEX ax_heilquellegasquelle_gml ON ax_heilquellegasquelle USING btree (gml_id,beginnt);


-- sonstiges Bauwerk oder sonstige Einrichtung
-- ----------------------------------------------
-- Objektart: AX_SonstigesBauwerkOderSonstigeEinrichtung Kennung: 51009
CREATE TABLE ax_sonstigesbauwerkodersonstigeeinrichtung (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	description		integer,
	name			varchar,
	bauwerksfunktion	integer,
	funktion		integer,

	-- Beziehungen
	gehoertZuBauwerk	character(16),
	gehoertzu		character(16),

	CONSTRAINT ax_sonstigesbauwerkodersonstigeeinrichtung_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_sonstigesbauwerkodersonstigeeinrichtung','wkb_geometry',:alkis_epsg,'GEOMETRY',2); -- POLYGON/LINESTRING

CREATE INDEX ax_sonstigesbauwerkodersonstigeeinrichtung_geom_idx ON ax_sonstigesbauwerkodersonstigeeinrichtung USING gist (wkb_geometry);
CREATE UNIQUE INDEX ax_sonstigesbauwerkodersonstigeeinrichtung_gml ON ax_sonstigesbauwerkodersonstigeeinrichtung USING btree (gml_id,beginnt);
CREATE INDEX ax_sonstigesbauwerkodersonstigeeinrichtung_gzb ON ax_sonstigesbauwerkodersonstigeeinrichtung USING btree (gehoertZuBauwerk);
CREATE INDEX ax_sonstigesbauwerkodersonstigeeinrichtung_gz ON ax_sonstigesbauwerkodersonstigeeinrichtung USING btree (gehoertzu);


-- E i n r i c h t u n g  i n  Ö f f e n t l i c h e n  B e r e i c h e n
-- ------------------------------------------------------------------------
-- Objektart: AX_EinrichtungInOeffentlichenBereichen Kennung: 51010
CREATE TABLE ax_einrichtunginoeffentlichenbereichen (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	art			integer,
	kilometerangabe         varchar,
	CONSTRAINT ax_einrichtunginoeffentlichenbereichen_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_einrichtunginoeffentlichenbereichen','wkb_geometry',:alkis_epsg,'GEOMETRY',2);

CREATE INDEX ax_einrichtunginoeffentlichenbereichen_geom_idx ON ax_einrichtunginoeffentlichenbereichen USING gist (wkb_geometry);
CREATE UNIQUE INDEX ax_einrichtunginoeffentlichenbereichen_gml ON ax_einrichtunginoeffentlichenbereichen USING btree (gml_id,beginnt);


-- B e s o n d e r e r   B a u w e r k s p u n k t
-- -----------------------------------------------
-- Objektart: AX_BesondererBauwerkspunkt Kennung: 51011
CREATE TABLE ax_besondererbauwerkspunkt (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	punktkennung		varchar,
	land			varchar,
	stelle			varchar,
	sonstigeeigenschaft	varchar[],
	CONSTRAINT ax_besondererbauwerkspunkt_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_besondererbauwerkspunkt','dummy',:alkis_epsg,'POINT',2);

CREATE UNIQUE INDEX ax_besondererbauwerkspunkt_gml ON ax_besondererbauwerkspunkt USING btree (gml_id,beginnt);


--** Objektartengruppe: Besondere Anlagen auf Siedlungsflächen
--   ===================================================================

--** Objektartengruppe: Bauwerke, Anlagen und Einrichtungen für den Verkehr
--   =======================================================================


-- B a u w e r k   i m  V e r k e h s b e r e i c h
-- ------------------------------------------------
-- Objektart: AX_BauwerkImVerkehrsbereich Kennung: 53001
CREATE TABLE ax_bauwerkimverkehrsbereich (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	bauwerksfunktion	integer,
	name                    varchar,
	zustand			integer,
	CONSTRAINT ax_bauwerkimverkehrsbereich_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_bauwerkimverkehrsbereich','wkb_geometry',:alkis_epsg,'GEOMETRY',2); -- POLYGON/MULTIPOLYGON

CREATE INDEX ax_bauwerkimverkehrsbereich_geom_idx ON ax_bauwerkimverkehrsbereich USING gist (wkb_geometry);
CREATE UNIQUE INDEX ax_bauwerkimverkehrsbereich_gml ON ax_bauwerkimverkehrsbereich USING btree (gml_id,beginnt);


-- S t r a ß e n v e r k e h r s a n l a g e
-- ------------------------------------------
-- Objektart: AX_Strassenverkehrsanlage Kennung: 53002
CREATE TABLE ax_strassenverkehrsanlage (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	art			integer,
	bezeichnung             varchar,
	name			varchar,
	CONSTRAINT ax_strassenverkehrsanlage_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_strassenverkehrsanlage','wkb_geometry',:alkis_epsg,'GEOMETRY',2); -- LINESTRING/MULTIPOLYGON

CREATE INDEX ax_strassenverkehrsanlage_geom_idx ON ax_strassenverkehrsanlage USING gist (wkb_geometry);
CREATE UNIQUE INDEX ax_strassenverkehrsanlage_gml ON ax_strassenverkehrsanlage USING btree (gml_id,beginnt);


-- W e g  /  P f a d  /  S t e i g
-- ----------------------------------------------
-- Objektart: AX_WegPfadSteig Kennung: 53003
CREATE TABLE ax_wegpfadsteig (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	art			integer,
	name			varchar,
	CONSTRAINT ax_wegpfadsteig_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_wegpfadsteig','wkb_geometry',:alkis_epsg,'GEOMETRY',2); -- LINESTRING/POLYGON

CREATE INDEX ax_wegpfadsteig_geom_idx ON ax_wegpfadsteig USING gist (wkb_geometry);
CREATE UNIQUE INDEX ax_wegpfadsteig_gml ON ax_wegpfadsteig USING btree (gml_id,beginnt);


-- B a h n v e r k e h r s a n l a g e
-- ----------------------------------------------
-- Objektart: AX_Bahnverkehrsanlage Kennung: 53004
CREATE TABLE ax_bahnverkehrsanlage (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	bahnhofskategorie	integer,
	bahnkategorie		integer,
	name			varchar,
	CONSTRAINT ax_bahnverkehrsanlage_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_bahnverkehrsanlage','wkb_geometry',:alkis_epsg,'GEOMETRY',2); -- POINT/POLYGON

CREATE INDEX ax_bahnverkehrsanlage_geom_idx ON ax_bahnverkehrsanlage USING gist (wkb_geometry);
CREATE UNIQUE INDEX ax_bahnverkehrsanlage_gml ON ax_bahnverkehrsanlage USING btree (gml_id,beginnt);


-- S e i l b a h n, S c h w e b e b a h n
-- --------------------------------------
-- Objektart: AX_SeilbahnSchwebebahn Kennung: 53005
CREATE TABLE ax_seilbahnschwebebahn (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	bahnkategorie		integer,
	name			varchar,
	CONSTRAINT ax_seilbahnschwebebahn_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_seilbahnschwebebahn','wkb_geometry',:alkis_epsg,'GEOMETRY',2); -- LINESTRING/MULTILINESTRING

CREATE INDEX ax_seilbahnschwebebahn_geom_idx ON ax_seilbahnschwebebahn USING gist (wkb_geometry);
CREATE UNIQUE INDEX ax_seilbahnschwebebahn_gml ON ax_seilbahnschwebebahn USING btree (gml_id,beginnt);


-- G l e i s
-- ----------------------------------------------
-- Objektart: AX_Gleis Kennung: 53006
CREATE TABLE ax_gleis (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	bahnkategorie		integer,
	art			integer,
	lagezuroberflaeche      integer,
	name			varchar,
	CONSTRAINT ax_gleis_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_gleis','wkb_geometry',:alkis_epsg,'GEOMETRY',2); -- LINESTRING/POLYGON

CREATE INDEX ax_gleis_geom_idx ON ax_gleis USING gist (wkb_geometry);
CREATE UNIQUE INDEX ax_gleis_gml ON ax_gleis USING btree (gml_id,beginnt);


-- F l u g v e r k e h r s a n l a g e
-- -----------------------------------
-- Objektart: AX_Flugverkehrsanlage Kennung: 53007
CREATE TABLE ax_flugverkehrsanlage (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	art			integer,
	oberflaechenmaterial	integer,
	name			varchar,
	CONSTRAINT ax_flugverkehrsanlage_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_flugverkehrsanlage','wkb_geometry',:alkis_epsg,'GEOMETRY',2);

CREATE INDEX ax_flugverkehrsanlage_geom_idx ON ax_flugverkehrsanlage USING gist (wkb_geometry);
CREATE UNIQUE INDEX ax_flugverkehrsanlage_gml ON ax_flugverkehrsanlage USING btree (gml_id,beginnt);


-- E i n r i c h t u n g e n  f ü r   d e n   S c h i f f s v e r k e h r
-- ------------------------------------------------------------------------
-- Objektart: AX_EinrichtungenFuerDenSchiffsverkehr Kennung: 53008
CREATE TABLE ax_einrichtungenfuerdenschiffsverkehr (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	art			integer,
	kilometerangabe		varchar,
	name			varchar,
	CONSTRAINT ax_einrichtungfuerdenschiffsverkehr_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_einrichtungenfuerdenschiffsverkehr','wkb_geometry',:alkis_epsg,'GEOMETRY',2); -- POINT/POLYGON

CREATE INDEX ax_einrichtungenfuerdenschiffsverkehr_geom_idx ON ax_einrichtungenfuerdenschiffsverkehr USING gist (wkb_geometry);
CREATE UNIQUE INDEX ax_einrichtungenfuerdenschiffsverkehr_gml ON ax_einrichtungenfuerdenschiffsverkehr USING btree (gml_id,beginnt);


-- B a u w e r k   i m   G e w ä s s e r b e r e i c h
-- -----------------------------------------------------
-- Objektart: AX_BauwerkImGewaesserbereich Kennung: 53009
CREATE TABLE ax_bauwerkimgewaesserbereich (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	bauwerksfunktion	integer,
	name			varchar,
	zustand			integer,
	CONSTRAINT ax_bauwerkimgewaesserbereich_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_bauwerkimgewaesserbereich','wkb_geometry',:alkis_epsg,'GEOMETRY',2); -- LINESTRING/POINT

CREATE INDEX ax_bauwerkimgewaesserbereich_geom_idx ON ax_bauwerkimgewaesserbereich USING gist (wkb_geometry);
CREATE UNIQUE INDEX ax_bauwerkimgewaesserbereich_gml ON ax_bauwerkimgewaesserbereich USING btree (gml_id,beginnt);


--** Objektartengruppe: Besondere Vegetationsmerkmale
--   ===================================================================

-- V e g a t a t i o n s m e r k m a l
-- ----------------------------------------------
-- Objektart: AX_Vegetationsmerkmal Kennung: 54001
CREATE TABLE ax_vegetationsmerkmal (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	bewuchs			integer,
	zustand			integer,
	name			varchar,
	CONSTRAINT ax_vegetationsmerkmal_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_vegetationsmerkmal','wkb_geometry',:alkis_epsg,'GEOMETRY',2);

CREATE INDEX ax_vegetationsmerkmal_geom_idx ON ax_vegetationsmerkmal USING gist (wkb_geometry);
CREATE UNIQUE INDEX ax_vegetationsmerkmal_gml ON ax_vegetationsmerkmal USING btree (gml_id,beginnt);


--** Objektartengruppe: Besondere Eigenschaften von Gewässern
--   ===================================================================

-- G e w ä s s e r m e r k m a l
-- ----------------------------------------------
-- Objektart: AX_Gewaessermerkmal Kennung: 55001
CREATE TABLE ax_gewaessermerkmal (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	art			integer,
	name			varchar,
	CONSTRAINT ax_gewaessermerkmal_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_gewaessermerkmal','wkb_geometry',:alkis_epsg,'GEOMETRY',2); -- POINT/LINESTRING/POLYGON

CREATE INDEX ax_gewaessermerkmal_geom_idx ON ax_gewaessermerkmal USING gist (wkb_geometry);
CREATE UNIQUE INDEX ax_gewaessermerkmal_gml ON ax_gewaessermerkmal USING btree (gml_id,beginnt);


-- U n t e r g e o r d n e t e s   G e w ä s s e r
-- -------------------------------------------------
-- Objektart: AX_UntergeordnetesGewaesser Kennung: 55002
CREATE TABLE ax_untergeordnetesgewaesser (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	funktion		integer,
	lagezurerdoberflaeche	integer,
	hydrologischesmerkmal	integer,
	name			varchar,
	CONSTRAINT ax_untergeordnetesgewaesser_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_untergeordnetesgewaesser','wkb_geometry',:alkis_epsg,'GEOMETRY',2); -- LINESTRING/POLYGON

CREATE INDEX ax_untergeordnetesgewaesser_geom_idx ON ax_untergeordnetesgewaesser USING gist (wkb_geometry);
CREATE UNIQUE INDEX ax_untergeordnetesgewaesser_gml ON ax_untergeordnetesgewaesser USING btree (gml_id,beginnt);


-- Objektart: AX_Wasserspiegelhoehe Kennung: 57001
-- 'Wasserspiegelhöhe' ist die Höhe des mittleren Wasserstandes über bzw. unter der Höhenbezugsfläche.


--** Objektartengruppe: Besondere Angaben zum Verkehr
--   ===================================================================
-- 56001 'Netzknoten'
-- 56002 'Nullpunkt'
-- 56003 'Abschnitt'
-- 56004 'Ast'


--** Objektartengruppe: Besondere Angaben zum Gewässer
--   ===================================================================

-- W a s s e r s p i e g e l h ö h e
-- ---------------------------------
-- Objektart: AX_Wasserspiegelhoehe Kennung: 57001
CREATE TABLE ax_wasserspiegelhoehe (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	hoehedeswasserspiegels	double precision,
	CONSTRAINT ax_wasserspiegelhoehe_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_wasserspiegelhoehe','wkb_geometry',:alkis_epsg,'POINT',2);

CREATE INDEX ax_wasserspiegelhoehe_geom_idx ON ax_wasserspiegelhoehe USING gist (wkb_geometry);
CREATE UNIQUE INDEX ax_wasserspiegelhoehe_gml ON ax_wasserspiegelhoehe USING btree (gml_id,beginnt);


-- S c h i f f f a h r t s l i n i e  /  F ä h r v e r k e h r
-- -----------------------------------------------------------
-- Objektart: AX_SchifffahrtslinieFaehrverkehr Kennung: 57002
CREATE TABLE ax_schifffahrtsliniefaehrverkehr (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	art			integer[],
	name			varchar,
	CONSTRAINT ax_schifffahrtsliniefaehrverkehr_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_schifffahrtsliniefaehrverkehr','wkb_geometry',:alkis_epsg,'LINESTRING',2);

CREATE INDEX ax_schifffahrtsliniefaehrverkehr_geom_idx ON ax_schifffahrtsliniefaehrverkehr USING gist (wkb_geometry);
CREATE UNIQUE INDEX ax_schifffahrtsliniefaehrverkehr_gml ON ax_schifffahrtsliniefaehrverkehr USING btree (gml_id,beginnt);


--*** ############################################################
--*** Objektbereich: Relief
--*** ############################################################

--** Objektartengruppe: Reliefformen
--   ===================================================================


-- B ö s c h u n g s k l i f f
-- -----------------------------
-- Objektart: AX_BoeschungKliff Kennung: 61001
CREATE TABLE ax_boeschungkliff (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	objekthoehe		double precision,
	CONSTRAINT ax_boeschungkliff_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_boeschungkliff','dummy',:alkis_epsg,'POINT',2);

CREATE UNIQUE INDEX ax_boeschungkliff_gml ON ax_boeschungkliff USING btree (gml_id,beginnt);


-- B ö s c h u n g s f l ä c h e
-- ---------------------------------
-- Objektart: AX_Boeschungsflaeche Kennung: 61002
CREATE TABLE ax_boeschungsflaeche (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,

	-- Beziehung
	istteilvon		character(16),

	CONSTRAINT ax_boeschungsflaeche_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_boeschungsflaeche','wkb_geometry',:alkis_epsg,'GEOMETRY',2);

CREATE INDEX ax_boeschungsflaeche_geom_idx ON ax_boeschungsflaeche USING gist (wkb_geometry);
CREATE UNIQUE INDEX ax_boeschungsflaeche_gml ON ax_boeschungsflaeche USING btree (gml_id,beginnt);
CREATE INDEX ax_boeschungsflaeche_itv        ON ax_boeschungsflaeche USING btree (istteilvon);


-- D a m m  /  W a l l  /  D e i c h
-- ----------------------------------------------
-- Objektart: AX_DammWallDeich Kennung: 61003
CREATE TABLE ax_dammwalldeich (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	art			integer,
	name			varchar,
	funktion		integer,
	CONSTRAINT ax_dammwalldeich_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_dammwalldeich','wkb_geometry',:alkis_epsg,'GEOMETRY',2); -- LINESTRING/POLYGON

CREATE INDEX ax_dammwalldeich_geom_idx ON ax_dammwalldeich USING gist (wkb_geometry);
CREATE UNIQUE INDEX ax_dammwalldeich_gml ON ax_dammwalldeich USING btree (gml_id,beginnt);


-- H ö h l e n e i n g a n g
-- -------------------------
-- Objektart: AX_Hoehleneingang Kennung: 61005
CREATE TABLE ax_hoehleneingang (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	name			varchar,
	ax_datenerhebung	integer,
	CONSTRAINT ax_hoehleneingang_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_hoehleneingang','wkb_geometry',:alkis_epsg,'POINT',2);

CREATE INDEX ax_hoehleneingang_geom_idx ON ax_hoehleneingang USING gist (wkb_geometry);
CREATE UNIQUE INDEX ax_hoehleneingang_gml ON ax_hoehleneingang USING btree (gml_id,beginnt);


-- F e l s e n ,  F e l s b l o c k ,   F e l s n a d e l
-- ------------------------------------------------------
-- Objektart: AX_FelsenFelsblockFelsnadel Kennung: 61006
CREATE TABLE ax_felsenfelsblockfelsnadel (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	name			varchar,
	CONSTRAINT ax_felsenfelsblockfelsnadel_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_felsenfelsblockfelsnadel','wkb_geometry',:alkis_epsg,'GEOMETRY',2);

CREATE INDEX ax_felsenfelsblockfelsnadel_geom_idx ON ax_felsenfelsblockfelsnadel USING gist (wkb_geometry);
CREATE UNIQUE INDEX ax_felsenfelsblockfelsnadel_gml ON ax_felsenfelsblockfelsnadel USING btree (gml_id,beginnt);


-- D ü n e
-- -------
-- Objektart: AX_Duene Kennung: 61007
CREATE TABLE ax_duene (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	name			varchar,
	CONSTRAINT ax_duene_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_duene','wkb_geometry',:alkis_epsg,'GEOMETRY',2);

CREATE INDEX ax_duene_geom_idx ON ax_duene USING gist (wkb_geometry);
CREATE UNIQUE INDEX ax_duene_gml ON ax_duene USING btree (gml_id,beginnt);


-- H ö h e n l i n i e
-- --------------------
-- Objektart: AX_Hoehenlinie Kennung: 61008
CREATE TABLE ax_hoehenlinie (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	hoehevonhoehenlinie	double precision,
	CONSTRAINT ax_hoehenlinie_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_hoehenlinie','wkb_geometry',:alkis_epsg,'LINESTRING',2);

CREATE INDEX ax_hoehenlinie_geom_idx ON ax_hoehenlinie USING gist (wkb_geometry);
CREATE UNIQUE INDEX ax_hoehenlinie_gml ON ax_hoehenlinie USING btree (gml_id,beginnt);


-- B e s o n d e r e r   T o p o g r a f i s c h e r   P u n k t
-- -------------------------------------------------------------
-- Objektart: AX_BesondererTopographischerPunkt Kennung: 61009
CREATE TABLE ax_besonderertopographischerpunkt (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	land			varchar,
	stelle			varchar,
	punktkennung		varchar,
	sonstigeeigenschaft	varchar[],
	CONSTRAINT ax_besonderertopographischerpunkt_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_besonderertopographischerpunkt','dummy',:alkis_epsg,'POINT',2);

CREATE UNIQUE INDEX ax_besonderertopographischerpunkt_gml ON ax_besonderertopographischerpunkt USING btree (gml_id,beginnt);


-- S o l l
-- -------
-- Objektart: AX_Soll Kennung: 61010
CREATE TABLE ax_soll (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	name			varchar,
	CONSTRAINT ax_soll_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_soll','wkb_geometry',:alkis_epsg,'POLYGON',2);

CREATE INDEX ax_soll_geom_idx ON ax_soll USING gist (wkb_geometry);
CREATE UNIQUE INDEX ax_soll_gml ON ax_soll USING btree (gml_id,beginnt);


--** Objektartengruppe: Primäres DGM
--   ===================================================================
-- Kennung '62000'


-- G e l ä n d e k a n t e
-- ----------------------------------------------
-- Objektart: AX_Gelaendekante Kennung: 62040
CREATE TABLE ax_gelaendekante (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	artdergelaendekante	integer,
	ax_dqerfassungsmethode	integer,
	identifikation		integer,
	art			integer,

	-- Beziehung
	istteilvon		character(16),

	CONSTRAINT ax_gelaendekante_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_gelaendekante','wkb_geometry',:alkis_epsg,'LINESTRING',2);

CREATE INDEX ax_gelaendekante_geom_idx ON ax_gelaendekante USING gist (wkb_geometry);
CREATE UNIQUE INDEX ax_gelaendekante_gml ON ax_gelaendekante USING btree (gml_id,beginnt);
CREATE INDEX ax_gelaendekante_itv_idx ON ax_gelaendekante USING btree (istteilvon);


-- M a r k a n t e r   G e l ä n d e p u n k t
-- -------------------------------------------
-- Objektart: AX_MarkanterGelaendepunkt Kennung: 62070
-- ** Tabelle bisher noch nicht generiert
-- "Markanter Geländepunkt" ist ein Höhenpunkt an markanter Stelle des Geländes, der zur Ergänzung eines gitterförmigen DGM und/oder der Höhenliniendarstellung dient.


-- B e s o n d e r e r   H ö h e n p u n k t
-- -------------------------------------------------------------
-- Objektart: AX_BesondererHoehenpunkt Kennung: 62090
CREATE TABLE ax_besondererhoehenpunkt (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	besonderebedeutung	integer,
	CONSTRAINT ax_besondererhoehenpunkt_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_besondererhoehenpunkt','wkb_geometry',:alkis_epsg,'POINT',2);

CREATE INDEX ax_besondererhoehenpunkt_geom_idx ON ax_besondererhoehenpunkt USING gist (wkb_geometry);
CREATE UNIQUE INDEX ax_besondererhoehenpunkt_gml ON ax_besondererhoehenpunkt USING btree (gml_id,beginnt);


--** Objektartengruppe: Sekundäres DGM
--   ===================================================================
-- Kennung '63000'
-- 63010 'DGM-Gitter'
-- 63020 'Abgeleitete Höhenlinie'


--*** ############################################################
--*** Objektbereich: Gesetzliche Festlegungen, Gebietseinheiten, Kataloge
--*** ############################################################

--** Objektartengruppe: Öffentlich-rechtliche und sonstige Festlegungen
--   ===================================================================
-- Kennung '71000'

-- K l a s s i f i z i e r u n g   n a c h   S t r a s s e n r e c h t
-- -------------------------------------------------------------------
-- Objektart: AX_KlassifizierungNachStrassenrecht Kennung: 71001
CREATE TABLE ax_klassifizierungnachstrassenrecht (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	artderfestlegung	integer,
	land			varchar,
	stelle			varchar,
	bezeichnung		varchar,
	CONSTRAINT ax_klassifizierungnachstrassenrecht_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_klassifizierungnachstrassenrecht','wkb_geometry',:alkis_epsg,'GEOMETRY',2); -- POLYGON/MULTIPOLYGON

CREATE INDEX ax_klassifizierungnachstrassenrecht_geom_idx   ON ax_klassifizierungnachstrassenrecht USING gist  (wkb_geometry);
CREATE UNIQUE INDEX ax_klassifizierungnachstrassenrecht_gml ON ax_klassifizierungnachstrassenrecht USING btree (gml_id,beginnt);
CREATE INDEX ax_klassifizierungnachstrassenrecht_afs ON ax_klassifizierungnachstrassenrecht(land,stelle);


-- Objektart: AX_AndereFestlegungNachStrassenrecht Kennung: 71002
-- "Andere Festlegung nach Straßenrecht" ist die auf den Grund und Boden bezogene Beschränkung, Belastung oder andere Eigenschaft einer Fläche nach öffentlichen, straßenrechtlichen Vorschriften.



-- K l a s s i f i z i e r u n g   n a c h   W a s s e r r e c h t
-- ---------------------------------------------------------------
-- Objektart: AX_KlassifizierungNachWasserrecht Kennung: 71003
CREATE TABLE ax_klassifizierungnachwasserrecht (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	artderfestlegung	integer,
	land			varchar,
	stelle			varchar,
	CONSTRAINT ax_klassifizierungnachwasserrecht_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_klassifizierungnachwasserrecht','wkb_geometry',:alkis_epsg,'GEOMETRY',2);

CREATE INDEX ax_klassifizierungnachwasserrecht_geom_idx ON ax_klassifizierungnachwasserrecht USING gist (wkb_geometry);
CREATE INDEX ax_klassifizierungnachwasserrecht_afs ON ax_klassifizierungnachwasserrecht(land,stelle);


-- A n d e r e   F e s t l e g u n g   n a c h   W a s s e r r e c h t
-- --------------------------------------------------------------------
-- Objektart: AX_AndereFestlegungNachWasserrecht Kennung: 71004
CREATE TABLE ax_anderefestlegungnachwasserrecht (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	artderfestlegung	integer,
	land			varchar,
	stelle			varchar,
	CONSTRAINT ax_anderefestlegungnachwasserrecht_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_anderefestlegungnachwasserrecht','wkb_geometry',:alkis_epsg,'GEOMETRY',2);

CREATE INDEX ax_anderefestlegungnachwasserrecht_geom_idx ON ax_anderefestlegungnachwasserrecht USING gist (wkb_geometry);
CREATE UNIQUE INDEX ax_anderefestlegungnachwasserrecht_gml ON ax_anderefestlegungnachwasserrecht USING btree (gml_id,beginnt);
CREATE INDEX ax_anderefestlegungnachwasserrecht_afs ON ax_anderefestlegungnachwasserrecht(land,stelle);


-- S c h u t z g e b i e t   n a c h   W a s s e r r e c h t
-- -----------------------------------------------------------
-- Objektart: AX_SchutzgebietNachWasserrecht Kennung: 71005
CREATE TABLE ax_schutzgebietnachwasserrecht (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	artderfestlegung	integer,
	land			varchar,
	stelle			varchar,
	art			varchar[],
	name			varchar,
	nummerdesschutzgebietes	varchar,
	CONSTRAINT ax_schutzgebietnachwasserrecht_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_schutzgebietnachwasserrecht','dummy',:alkis_epsg,'POINT',2);

CREATE UNIQUE INDEX ax_schutzgebietnachwasserrecht_gml ON ax_schutzgebietnachwasserrecht USING btree (gml_id,beginnt);
CREATE INDEX ax_schutzgebietnachwasserrecht_afs ON ax_schutzgebietnachwasserrecht USING btree (land,stelle);


-- N  a t u r -,  U m w e l t -   o d e r   B o d e n s c h u t z r e c h t
-- ------------------------------------------------------------------------
-- Objektart: AX_NaturUmweltOderBodenschutzrecht Kennung: 71006
CREATE TABLE ax_naturumweltoderbodenschutzrecht (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	artderfestlegung	integer,
	land			varchar,
	stelle			varchar,
	name			varchar,
	CONSTRAINT ax_naturumweltoderbodenschutzrecht_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_naturumweltoderbodenschutzrecht','wkb_geometry',:alkis_epsg,'GEOMETRY',2); -- POLYGON/MULTIPOLYGON

CREATE INDEX ax_naturumweltoderbodenschutzrecht_geom_idx   ON ax_naturumweltoderbodenschutzrecht USING gist (wkb_geometry);
CREATE UNIQUE INDEX ax_naturumweltoderbodenschutzrecht_gml ON ax_naturumweltoderbodenschutzrecht USING btree (gml_id,beginnt);
CREATE INDEX ax_naturumweltoderbodenschutzrecht_afs ON ax_naturumweltoderbodenschutzrecht(land,stelle);


-- S c h u t z g e b i e t   n a c h   N a t u r,  U m w e l t  o d e r  B o d e n s c h u t z r e c h t
-- -----------------------------------------------------------------------------------------------------
-- Objektart: AX_SchutzgebietNachNaturUmweltOderBodenschutzrecht Kennung: 71007
CREATE TABLE ax_schutzgebietnachnaturumweltoderbodenschutzrecht (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	artderfestlegung	integer,
	land			varchar,
	stelle			varchar,
	name			varchar,
	CONSTRAINT ax_schutzgebietnachnaturumweltoderbodenschutzrecht_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_schutzgebietnachnaturumweltoderbodenschutzrecht','dummy',:alkis_epsg,'POINT',2);

CREATE UNIQUE INDEX ax_schutzgebietnachnaturumweltoderbodenschutzrecht_gml ON ax_schutzgebietnachnaturumweltoderbodenschutzrecht USING btree (gml_id,beginnt);
CREATE INDEX ax_schutzgebietnachnaturumweltoderbodenschutzrecht_afs ON ax_schutzgebietnachnaturumweltoderbodenschutzrecht(land,stelle);


-- B a u - ,   R a u m -   o d e r   B o d e n o r d n u n g s r e c h t
-- ---------------------------------------------------------------------
-- Objektart: AX_BauRaumOderBodenordnungsrecht Kennung: 71008
CREATE TABLE ax_bauraumoderbodenordnungsrecht (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	art			varchar,
	name			varchar,
	artderfestlegung	integer,
	land			varchar,
	stelle			varchar,
	bezeichnung		varchar,
	datumanordnung		varchar,
	CONSTRAINT ax_bauraumoderbodenordnungsrecht_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_bauraumoderbodenordnungsrecht','wkb_geometry',:alkis_epsg,'GEOMETRY',2);

CREATE INDEX ax_bauraumoderbodenordnungsrecht_geom_idx ON ax_bauraumoderbodenordnungsrecht USING gist (wkb_geometry);
CREATE UNIQUE INDEX ax_bauraumoderbodenordnungsrecht_gml ON ax_bauraumoderbodenordnungsrecht USING btree (gml_id,beginnt);


-- D e n k m a l s c h u t z r e c h t
-- -----------------------------------
-- Objektart: AX_Denkmalschutzrecht Kennung: 71009
CREATE TABLE ax_denkmalschutzrecht (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	artderfestlegung	integer,
	land			varchar,
	stelle			varchar,
	art			varchar,
	name			varchar,
	CONSTRAINT ax_denkmalschutzrecht_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_denkmalschutzrecht','wkb_geometry',:alkis_epsg,'GEOMETRY',2); -- POLYGON/MULTIPOLYGON

CREATE INDEX ax_denkmalschutzrecht_geom_idx   ON ax_denkmalschutzrecht USING gist  (wkb_geometry);
CREATE UNIQUE INDEX ax_denkmalschutzrecht_gml ON ax_denkmalschutzrecht USING btree (gml_id,beginnt);
CREATE INDEX ax_denkmalschutzrecht_afs ON ax_denkmalschutzrecht(land,stelle);


-- F o r s t r e c h t
-- -------------------
-- Objektart: AX_Forstrecht Kennung: 71010
CREATE TABLE ax_forstrecht (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	artderfestlegung	integer,
	besonderefunktion	integer,
	land			varchar,
	stelle			varchar,
	CONSTRAINT ax_forstrecht_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_forstrecht','wkb_geometry',:alkis_epsg,'GEOMETRY',2); -- POLYGON/MULTIPOLYGON

CREATE INDEX ax_forstrecht_geom_idx   ON ax_forstrecht USING gist  (wkb_geometry);
CREATE UNIQUE INDEX ax_forstrecht_gml ON ax_forstrecht USING btree (gml_id,beginnt);
CREATE INDEX ax_forstrecht_afs ON ax_forstrecht(land,stelle);


-- S o n s t i g e s   R e c h t
-- -----------------------------
-- Objektart: AX_SonstigesRecht Kennung: 71011
CREATE TABLE ax_sonstigesrecht (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	artderfestlegung	integer,
	land			varchar,
	stelle			varchar,
	bezeichnung		varchar,
	characterstring		varchar,
	art			varchar,
	name			varchar,
	funktion		integer,
	CONSTRAINT ax_sonstigesrecht_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_sonstigesrecht','wkb_geometry',:alkis_epsg,'GEOMETRY',2);

CREATE INDEX ax_sonstigesrecht_geom_idx ON ax_sonstigesrecht USING gist (wkb_geometry);
CREATE UNIQUE INDEX ax_sonstigesrecht_gml ON ax_sonstigesrecht USING btree (gml_id,beginnt);


-- S c h u t z z o n e
-- -------------------
-- Objektart: AX_Schutzzone Kennung: 71012
CREATE TABLE ax_schutzzone (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	"zone"			integer,
	art			varchar[],

	-- Beziehung
	istteilvon		character(16),  -- Nur RP?

	CONSTRAINT ax_schutzzone_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_schutzzone','wkb_geometry',:alkis_epsg,'GEOMETRY',2); -- POLYGON/MULTIPOLYGON

CREATE INDEX ax_schutzzone_geom_idx   ON ax_schutzzone USING gist (wkb_geometry);
CREATE UNIQUE INDEX ax_schutzzone_gml ON ax_schutzzone USING btree (gml_id,beginnt);
CREATE INDEX ax_schutzzone_itv        ON ax_schutzzone USING btree (istteilvon);


--** Objektartengruppe: Bodenschätzung, Bewertung
--   ===================================================================
-- Kennung '72000'


-- B o d e n s c h ä t z u n g
-- ----------------------------------------------
-- Objektart: AX_Bodenschaetzung Kennung: 72001
CREATE TABLE ax_bodenschaetzung (
	ogc_fid				serial NOT NULL,
	gml_id				character(16) NOT NULL,
	identifier			varchar,
	beginnt				character(20),
	endet				character(20),
	advstandardmodell		varchar[],
	sonstigesmodell			varchar[],
	anlass				varchar,
	art				varchar,
	name				varchar,
	kulturart			integer,
	bodenart			integer,
	zustandsstufeoderbodenstufe	integer,
	entstehungsartoderklimastufewasserverhaeltnisse	integer[],
	bodenzahlodergruenlandgrundzahl	varchar,
	ackerzahlodergruenlandzahl	varchar,
	sonstigeangaben			integer[],
	jahreszahl			integer,
	CONSTRAINT ax_bodenschaetzung_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_bodenschaetzung','wkb_geometry',:alkis_epsg,'GEOMETRY',2); -- POLYGON/MULTIPOLYGON

CREATE INDEX ax_bodenschaetzung_geom_idx ON ax_bodenschaetzung USING gist (wkb_geometry);
CREATE UNIQUE INDEX ax_bodenschaetzung_gml ON ax_bodenschaetzung USING btree (gml_id,beginnt);


-- M u s t e r -,  L a n d e s m u s t e r -   u n d   V e r g l e i c h s s t u e c k
-- -----------------------------------------------------------------------------------
-- Objektart: AX_MusterLandesmusterUndVergleichsstueck Kennung: 72002
CREATE TABLE ax_musterlandesmusterundvergleichsstueck (
	ogc_fid				serial NOT NULL,
	gml_id				character(16) NOT NULL,
	identifier			varchar,
	beginnt				character(20),
	endet				character(20),
	advstandardmodell		varchar[],
	sonstigesmodell			varchar[],
	anlass				varchar,
	art				varchar,
	name				varchar,
	merkmal				integer,
	nummer				varchar,
	kulturart			integer,
	bodenart			integer,
	zustandsstufeoderbodenstufe	integer,
	entstehungsartoderklimastufewasserverhaeltnisse	integer,
	bodenzahlodergruenlandgrundzahl	varchar,
	ackerzahlodergruenlandzahl	varchar,
	sonstigeangaben			integer,

	CONSTRAINT ax_musterlandesmusterundvergleichsstueck_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_musterlandesmusterundvergleichsstueck','wkb_geometry',:alkis_epsg,'GEOMETRY',2); -- POLYGON/POINT

CREATE INDEX ax_musterlandesmusterundvergleichsstueck_geom_idx   ON ax_musterlandesmusterundvergleichsstueck USING gist (wkb_geometry);
CREATE UNIQUE INDEX ax_musterlandesmusterundvergleichsstueck_gml ON ax_musterlandesmusterundvergleichsstueck USING btree (gml_id,beginnt);


-- G r a b l o c h   d e r   B o d e n s c h ä t z u n g
-- -----------------------------------------------------
-- Objektart: AX_GrablochDerBodenschaetzung Kennung: 72003
CREATE TABLE ax_grablochderbodenschaetzung (
	ogc_fid				serial NOT NULL,
	gml_id				character(16) NOT NULL,
	identifier			varchar,
	beginnt				character(20),
	endet				character(20),
	advstandardmodell		varchar[],
	sonstigesmodell			varchar[],
	anlass				varchar,
	art				varchar,
	name				varchar,
	bedeutung			integer[],
	land				varchar,
	nummerierungsbezirk		varchar,
	gemarkungsnummer		varchar,
	nummerdesgrablochs		varchar,
	bodenzahlodergruenlandgrundzahl varchar,

	-- Beziehung
	gehoertzu			character(16),

	CONSTRAINT ax_grablochderbodenschaetzung_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_grablochderbodenschaetzung','wkb_geometry',:alkis_epsg,'POINT',2);

CREATE INDEX ax_grablochderbodenschaetzung_geom_idx   ON ax_grablochderbodenschaetzung USING gist  (wkb_geometry);
CREATE UNIQUE INDEX ax_grablochderbodenschaetzung_gml ON ax_grablochderbodenschaetzung USING btree (gml_id,beginnt);


-- B e w e r t u n g
-- ------------------
-- Objektart: AX_Bewertung Kennung: 72004
CREATE TABLE ax_bewertung (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	klassifizierung		integer,
	CONSTRAINT ax_bewertung_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_bewertung','wkb_geometry',:alkis_epsg,'GEOMETRY',2);

CREATE INDEX ax_bewertung_geom_idx   ON ax_bewertung USING gist  (wkb_geometry);
CREATE UNIQUE INDEX ax_bewertung_gml ON ax_bewertung USING btree (gml_id,beginnt);



-- T a g e s a b s c h n i t t
-- ---------------------------
-- Objektart: AX_Tagesabschnitt Kennung: 72006
CREATE TABLE ax_tagesabschnitt (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	tagesabschnittsnummer	varchar,
	CONSTRAINT ax_tagesabschnitt_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_tagesabschnitt','wkb_geometry',:alkis_epsg,'POLYGON',2);

CREATE INDEX ax_tagesabschnitt_geom_idx   ON ax_tagesabschnitt USING gist  (wkb_geometry);
CREATE UNIQUE INDEX ax_tagesabschnitt_gml ON ax_tagesabschnitt USING btree (gml_id,beginnt);


--** Objektartengruppe: Kataloge
--   ===================================================================
-- Kennung '73000'


-- B u n d e s l a n d
-- ----------------------------------------------
-- Objektart: AX_Bundesland Kennung: 73002
CREATE TABLE ax_bundesland (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	schluesselgesamt	varchar,
	bezeichnung		varchar,
	land			varchar,
	stelle			varchar,

	CONSTRAINT ax_bundesland_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_bundesland','dummy',:alkis_epsg,'POINT',2);

CREATE UNIQUE INDEX ax_bundesland_gml ON ax_bundesland USING btree (gml_id,beginnt);


-- R e g i e r u n g s b e z i r k
-- ----------------------------------------------
-- Objektart: AX_Regierungsbezirk Kennung: 73003
CREATE TABLE ax_regierungsbezirk (
	ogc_fid				serial NOT NULL,
	gml_id				character(16) NOT NULL,
	identifier			varchar,
	beginnt				character(20),
	endet				character(20),
	advstandardmodell		varchar[],
	sonstigesmodell			varchar[],
	anlass				varchar,
	schluesselgesamt		varchar,
	bezeichnung			varchar,
	land				varchar,
	regierungsbezirk		varchar,
	CONSTRAINT ax_regierungsbezirk_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_regierungsbezirk','dummy',:alkis_epsg,'POINT',2);

CREATE UNIQUE INDEX ax_regierungsbezirk_gml ON ax_regierungsbezirk USING btree (gml_id,beginnt);


-- K r e i s   /   R e g i o n
-- ---------------------------
-- Objektart: AX_KreisRegion Kennung: 73004
CREATE TABLE ax_kreisregion (
	ogc_fid				serial NOT NULL,
	gml_id				character(16) NOT NULL,
	identifier			varchar,
	beginnt				character(20),
	endet				character(20),
	advstandardmodell		varchar[],
	sonstigesmodell			varchar[],
	anlass				varchar,
	schluesselgesamt		varchar,
	bezeichnung			varchar,
	land				varchar,
	regierungsbezirk		varchar,
	kreis				varchar,
	CONSTRAINT ax_kreisregion_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_kreisregion','dummy',:alkis_epsg,'POINT',2);

CREATE UNIQUE INDEX ax_kreisregion_gml ON ax_kreisregion USING btree (gml_id,beginnt);


-- G e m e i n d e
-- ----------------------------------------------
-- Objektart: AX_Gemeinde Kennung: 73005
CREATE TABLE ax_gemeinde (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	schluesselgesamt	varchar,
	bezeichnung		varchar,
	land			varchar,
	regierungsbezirk	varchar,
	kreis			varchar,
	gemeinde		varchar,
	stelle			varchar,

	-- Beziehungen
	istamtsbezirkvon        character(16)[],

	CONSTRAINT ax_gemeinde_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_gemeinde','dummy',:alkis_epsg,'POINT',2);

CREATE UNIQUE INDEX ax_gemeinde_gml ON ax_gemeinde USING btree (gml_id,beginnt);
CREATE INDEX ax_gemeinde_iabv ON ax_gemeinde USING gin (istamtsbezirkvon);


-- G e m e i n d e t e i l
-- -----------------------------------------
-- Objektart: AX_Gemeindeteil Kennung: 73006
CREATE TABLE ax_gemeindeteil (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	schluesselgesamt	varchar,
	bezeichnung		varchar,
	administrativefunktion	integer,
	land			varchar,
	regierungsbezirk	varchar,
	kreis			varchar,
	gemeinde		varchar,
	gemeindeteil		integer,
	CONSTRAINT ax_gemeindeteil_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_gemeindeteil','dummy',:alkis_epsg,'POINT',2);

CREATE UNIQUE INDEX ax_gemeindeteil_gml ON ax_gemeindeteil USING btree (gml_id,beginnt);


-- G e m a r k u n g
-- ----------------------------------------------
-- Objektart: AX_Gemarkung Kennung: 73007
CREATE TABLE ax_gemarkung (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	schluesselgesamt	varchar,
	bezeichnung		varchar,
	land			varchar,
	gemarkungsnummer	varchar,
	stelle			varchar,
	CONSTRAINT ax_gemarkung_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_gemarkung','dummy',:alkis_epsg,'POINT',2);

CREATE UNIQUE INDEX ax_gemarkung_gml ON ax_gemarkung USING btree (gml_id,beginnt);         -- Index für alkis_beziehungen
CREATE INDEX ax_gemarkung_nr         ON ax_gemarkung USING btree (land,gemarkungsnummer); -- Such-Index, Verweis aus ax_Flurstueck


-- G e m a r k u n g s t e i l   /   F l u r
-- ----------------------------------------------
-- Objektart: AX_GemarkungsteilFlur Kennung: 73008
CREATE TABLE ax_gemarkungsteilflur (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	schluesselgesamt	varchar,
	bezeichnung		varchar,
	land			varchar,
	gemarkung		integer,
	gemarkungsteilflur	integer,

	-- Beziehung
	gehoertzu		character(16)[],

	CONSTRAINT ax_gemarkungsteilflur_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_gemarkungsteilflur','dummy',:alkis_epsg,'POINT',2);

CREATE UNIQUE INDEX ax_gemarkungsteilflur_gml ON ax_gemarkungsteilflur USING btree (gml_id,beginnt);
CREATE INDEX ax_gemarkungsteilflur_ghz ON ax_gemarkungsteilflur USING gin (gehoertzu);


-- V e r w a l t u n g s g e m e i n s c h a f t
-- ---------------------------------------------
-- Objektart: AX_Verwaltungsgemeinschaft Kennung: 73009
CREATE TABLE ax_verwaltungsgemeinschaft (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	schluesselgesamt	varchar,
	bezeichnung		varchar,
	bezeichnungart		integer,
	land			varchar,
	regierungsbezirk	varchar,
	kreis			varchar,
	verwaltungsgemeinschaft	integer,
	CONSTRAINT ax_verwaltungsgemeinschaft_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_verwaltungsgemeinschaft','dummy',:alkis_epsg,'POINT',2);

-- Werte:
-- 1000 Samtgemeinde     'Samtgemeinde' umfasst in Niedersachsen das Gebiet einer Samtgemeinde.
-- 2000 Verbandsgemeinde
-- 3000 Amt              'Amt' umfasst das Gebiet eines Amtes, das aus Gemeinden desselben Landkreises besteht.


-- B u c h u n g s b l a t t - B e z i r k
-- ----------------------------------------------
-- Objektart: AX_Buchungsblattbezirk Kennung: 73010
CREATE TABLE ax_buchungsblattbezirk (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	schluesselgesamt	varchar,
	bezeichnung		varchar,
	land			varchar,
	bezirk			varchar,
	stelle			varchar,

	-- Beziehung
	gehoertzu               character(16),

	CONSTRAINT ax_buchungsblattbezirk_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_buchungsblattbezirk','dummy',:alkis_epsg,'POINT',2);

CREATE UNIQUE INDEX ax_buchungsblattbezirk_gml ON ax_buchungsblattbezirk USING btree (gml_id,beginnt);
CREATE INDEX ax_buchungsblattbez_ghz ON ax_buchungsblattbezirk USING btree (gehoertzu);

CREATE INDEX ax_buchungsblattbez_key ON ax_buchungsblattbezirk USING btree (land,bezirk);


-- D i e n s t s t e l l e
-- ----------------------------------------------
-- Objektart: AX_Dienststelle Kennung: 73011
CREATE TABLE ax_dienststelle (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	schluesselgesamt	varchar,
	bezeichnung		varchar,
	land			varchar,
	stelle			varchar,
	stellenart		integer,
	kennung			varchar,

	-- Beziehung
	hat			character(16),

	CONSTRAINT ax_dienststelle_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_dienststelle','dummy',:alkis_epsg,'POINT',2);

CREATE UNIQUE INDEX ax_dienststelle_gml ON ax_dienststelle USING btree (gml_id,beginnt);


-- V e r b a n d
-- -------------
-- Objektart: AX_Verband Kennung: 73012
-- "Verband" umfasst die Verbände, denen Gemeinden angehören (z.B. Planungsverbände) mit den entsprechenden Bezeichnungen.


-- L a g e b e z e i c h n u n g s - K a t a l o g e i n t r a g
-- --------------------------------------------------------------
-- Objektart: AX_LagebezeichnungKatalogeintrag Kennung: 73013
CREATE TABLE ax_lagebezeichnungkatalogeintrag (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	schluesselgesamt	varchar,
	bezeichnung		varchar,
	land			varchar,
	regierungsbezirk	varchar,
	kreis			varchar,
	gemeinde		varchar,
	lage			varchar, -- Straßenschlüssel
	CONSTRAINT ax_lagebezeichnungkatalogeintrag_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_lagebezeichnungkatalogeintrag','dummy',:alkis_epsg,'POINT',2);

CREATE UNIQUE INDEX ax_lagebezeichnungkatalogeintrag_gml ON ax_lagebezeichnungkatalogeintrag USING btree (gml_id,beginnt);

-- NRW: Nummerierung Strassenschluessel innerhalb einer Gemeinde
-- Die Kombination Gemeinde und Straßenschlüssel ist also ein eindeutiges Suchkriterium.
CREATE INDEX ax_lagebezeichnungkatalogeintrag_lage ON ax_lagebezeichnungkatalogeintrag USING btree (gemeinde,lage);

-- Suchindex (Verwendung in Navigations-Programm)
CREATE INDEX ax_lagebezeichnungkatalogeintrag_gesa ON ax_lagebezeichnungkatalogeintrag USING btree (schluesselgesamt);
CREATE INDEX ax_lagebezeichnungkatalogeintrag_bez  ON ax_lagebezeichnungkatalogeintrag USING btree (bezeichnung);


--** Objektartengruppe: Geographische Gebietseinheiten
--   ===================================================================


-- Objektart: AX_Landschaft Kennung: 74001
-- "Landschaft" ist hinsichtlich des äußeren Erscheinungsbildes (Bodenformen, Bewuchs, Besiedlung, Bewirtschaftung) ein in bestimmter Weise geprägter Teil der Erdoberfläche.


-- k l e i n r ä u m i g e r   L a n d s c h a f t s t e i l
-- -----------------------------------------------------------
-- Objektart: AX_KleinraeumigerLandschaftsteil Kennung: 74002
CREATE TABLE ax_kleinraeumigerlandschaftsteil (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	landschaftstyp		integer,
	name			varchar,
	CONSTRAINT ax_kleinraeumigerlandschaftsteil_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_kleinraeumigerlandschaftsteil','wkb_geometry',:alkis_epsg,'GEOMETRY',2); -- POINT/LINESTRING

CREATE INDEX ax_kleinraeumigerlandschaftsteil_geom_idx   ON ax_kleinraeumigerlandschaftsteil USING gist (wkb_geometry);
CREATE UNIQUE INDEX ax_kleinraeumigerlandschaftsteil_gml ON ax_kleinraeumigerlandschaftsteil USING btree (gml_id,beginnt);


-- W o h n p l a t z
-- -----------------------------------------------------------
-- Objektart: AX_Wohnplatz Kennung: 74005
CREATE TABLE ax_wohnplatz (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	name			varchar,
	zweitname		varchar,
	CONSTRAINT ax_wohnplatz_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_wohnplatz','wkb_geometry',:alkis_epsg,'POINT',2);

CREATE INDEX ax_wohnplatz_geom_idx   ON ax_wohnplatz USING gist (wkb_geometry);
CREATE UNIQUE INDEX ax_wohnplatz_gml ON ax_wohnplatz USING btree (gml_id,beginnt);


--** Objektartengruppe: Administrative Gebietseinheiten
--   ===================================================================
-- Kennung '75000'


-- B a u b l o c k
-- ----------------------------------------------
-- Objektart: AX_Baublock Kennung: 75001
CREATE TABLE ax_baublock (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	baublockbezeichnung	varchar,
	art			integer,
	CONSTRAINT ax_baublock_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_baublock','wkb_geometry',:alkis_epsg,'GEOMETRY',2);

CREATE INDEX ax_baublock_geom_idx ON ax_baublock USING gist (wkb_geometry);
CREATE UNIQUE INDEX ax_baublock_gml ON ax_baublock USING btree (gml_id,beginnt);


-- W i r t s c h a f t l i c h e   E i n h e i t
-- ---------------------------------------------
-- Objektart: AX_WirtschaftlicheEinheit Kennung: 75002
CREATE TABLE ax_wirtschaftlicheeinheit (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	CONSTRAINT ax_wirtschaftlicheeinheit_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_wirtschaftlicheeinheit','dummy',:alkis_epsg,'POINT',2);


-- K o m m u n a l e s   G e b i e t
-- ----------------------------------------------
-- Objektart: AX_KommunalesGebiet Kennung: 75003
CREATE TABLE ax_kommunalesgebiet (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	schluesselgesamt	varchar,
	land			varchar,
	regierungsbezirk	varchar,
	kreis			varchar,
	gemeinde		varchar,
	gemeindeflaeche		double precision,
	CONSTRAINT ax_kommunalesgebiet_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_kommunalesgebiet','wkb_geometry',:alkis_epsg,'GEOMETRY',2);

CREATE INDEX ax_kommunalesgebiet_geom_idx   ON ax_kommunalesgebiet USING gist (wkb_geometry);
CREATE UNIQUE INDEX ax_kommunalesgebiet_gml ON ax_kommunalesgebiet USING btree (gml_id,beginnt);


-- abstrakte Objektart: AX_Gebiet Kennung: 75010


--*** ############################################################
--*** Objektbereich: Nutzerprofile
--*** ############################################################


--** Objektartengruppe: Nutzerprofile
--   ===================================================================
-- Kennung '81000'

-- Objektart: AX_Benutzer Kennung: 81001
-- In der Objektart 'Benutzer' werden allgemeine Informationen über den Benutzer verwaltet.

-- Objektart: AX_Benutzergruppe Kennung: 81002

-- Objektart: AX_BenutzergruppeMitZugriffskontrolle Kennung: 81003
-- In der Objektart 'Benutzergruppe mit Zugriffskontrolle' werden Informationen über die Benutzer der ALKIS-Bestandsdaten verwaltet, die den Umfang der Benutzung und Fortführung aus Gründen der Datenkonsistenz und des Datenschutzes einschränken.

-- Objektart: AX_BenutzergruppeNBA Kennung: 81004
-- In der Objektart 'Benutzergruppe (NBA)' werden relevante Informationen für die Durchführung der NBA-Versorgung, z.B. die anzuwendenden Selektionskriterien, gespeichert. 
--  Eine gesonderte Prüfung der Zugriffsrechte erfolgt in diesem Fall nicht, deren Berücksichtigung ist von dem Administrator bei der Erzeugung und Pflege der NBA-Benutzergruppen sicherzustellen.


--*** ############################################################
--*** Objektbereich: Migration
--*** ############################################################

--** Objektartengruppe: Migrationsobjekte
--   ===================================================================
-- Kennung '91000'


-- G e b ä u d e a u s g e s t a l t u n g
-- -----------------------------------------
-- Objektart: AX_Gebaeudeausgestaltung Kennung: 91001
CREATE TABLE ax_gebaeudeausgestaltung (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	darstellung		integer,

	-- Beziehung
	zeigtauf		character(16),

	CONSTRAINT ax_gebaeudeausgestaltung_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_gebaeudeausgestaltung','wkb_geometry',:alkis_epsg,'GEOMETRY',2);  -- LINESTRING/MULTILINESTRING

CREATE INDEX ax_gebaeudeausgestaltung_geom_idx ON ax_gebaeudeausgestaltung USING gist (wkb_geometry);
CREATE UNIQUE INDEX ax_gebaeudeausgestaltung_gml ON ax_gebaeudeausgestaltung USING btree (gml_id,beginnt);


-- T o p o g r a p h i s c h e   L i n i e
-- ---------------------------------------
-- Objektart: AX_TopographischeLinie Kennung: 91002
CREATE TABLE ax_topographischelinie (
	ogc_fid			serial NOT NULL,
	gml_id			character(16) NOT NULL,
	identifier		varchar,
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar[],
	sonstigesmodell		varchar[],
	anlass			varchar,
	liniendarstellung	integer,
	sonstigeeigenschaft	varchar,
	CONSTRAINT ax_topographischelinie_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_topographischelinie','wkb_geometry',:alkis_epsg,'LINESTRING',2);

CREATE INDEX ax_topographischelinie_geom_idx   ON ax_topographischelinie USING gist (wkb_geometry);
CREATE UNIQUE INDEX ax_topographischelinie_gml ON ax_topographischelinie USING btree (gml_id,beginnt);


\i alkis-wertearten.sql
SELECT alkis_set_comments();


-- Schlüsseltabelle "advstandardmodell" (9):
-- ----------------------------------------
-- LiegenschaftskatasterModell = DLKM
-- KatasterkartenModell500     = DKKM500
-- KatasterkartenModell1000    = DKKM1000
-- KatasterkartenModell2000    = DKKM2000
-- KatasterkartenModell5000    = DKKM5000
-- BasisLandschaftsModell      = Basis-DLM
-- LandschaftsModell50         = DLM50
-- LandschaftsModell250        = DLM250
-- LandschaftsModell1000       = DLM1000
-- TopographischeKarte10       = DTK10
-- TopographischeKarte25       = DTK25
-- TopographischeKarte50       = DTK50
-- TopographischeKarte100      = DTK100
-- TopographischeKarte250      = DTK250
-- TopographischeKarte1000     = DTK1000
-- Festpunktmodell             = DFGM
-- DigitalesGelaendemodell2    = DGM2
-- DigitalesGelaendemodell5    = DGM5
-- DigitalesGelaendemodell25   = DGM25
-- Digitales Gelaendemodell50  = DGM50

/*
Nicht abgebildete Beziehungen aus alkis_relationsart:
ALTER TABLE ax_benutzer ADD COLUMN ist varchar;
ALTER TABLE ax_benutzer ADD COLUMN gehoertzu varchar;
ALTER TABLE ax_benutzergruppe ADD COLUMN bestehtaus varchar[];
ALTER TABLE ax_fortfuehrungsnachweisdeckblatt ADD COLUMN beziehtsichauf varchar[];
ALTER TABLE ax_personengruppe ADD COLUMN bestehtaus varchar[];
*/

--
--          THE  (happy)  END
--
