-- Automatisch mit pg-to-oci.pl konvertiert.
---
---

set serveroutput on
set autocommit on
set feedback off
set verify off

define alkis_epsg=&1
whenever sqlerror exit 1
-- 
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='DELETE';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE "DELETE" CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE "DELETE"
(
	ogr_fid		integer NOT NULL,
	typename	varchar2(2047),
	featureid	character(32),
	context		varchar2(2047),
	safetoignore	varchar2(2047),
	replacedBy	varchar2(2047),
	ignored		varchar2(5) default 'false',
	CONSTRAINT ALKIS_0 PRIMARY KEY (ogr_fid)
);
ALTER TABLE "DELETE" ADD DUMMY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('DELETE','DUMMY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE UNIQUE INDEX ALKIS_1 ON "DELETE"(featureid);
COMMENT ON TABLE "DELETE"             IS 'Hilfstabelle für das Speichern von Löschinformationen.';
COMMENT ON COLUMN "DELETE".typename     IS 'Objektart, also Name der Tabelle, aus der das Objekt zu löschen ist.';
COMMENT ON COLUMN "DELETE".featureid    IS 'Zusammen gesetzt aus GML-ID (16) und Zeitstempel.';
COMMENT ON COLUMN "DELETE".context      IS 'Operation ''delete'' oder ''replace''';
COMMENT ON COLUMN "DELETE".safetoignore IS 'Attribut safeToIgnore von wfsext:Replace';
COMMENT ON COLUMN "DELETE".replacedBy   IS 'gml_id des Objekts, das featureid ersetzt';
COMMENT ON COLUMN "DELETE".ignored      IS 'Löschsatz wurde ignoriert';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='ALKIS_BEZIEHUNGEN';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE ALKIS_BEZIEHUNGEN CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE ALKIS_BEZIEHUNGEN (
	ogr_fid			integer NOT NULL,
	beziehung_von		character(16),
	beziehungsart		varchar2(2047),
	beziehung_zu		character(16),
	CONSTRAINT ALKIS_2 PRIMARY KEY (ogr_fid)
);
CREATE INDEX ALKIS_3 ON alkis_beziehungen (beziehung_von);
CREATE INDEX ALKIS_4  ON alkis_beziehungen (beziehung_zu);
CREATE INDEX ALKIS_5 ON alkis_beziehungen (beziehungsart);
ALTER TABLE ALKIS_BEZIEHUNGEN ADD DUMMY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('ALKIS_BEZIEHUNGEN','DUMMY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
COMMENT ON TABLE  alkis_beziehungen               IS 'zentrale Multi-Verbindungstabelle';
COMMENT ON COLUMN alkis_beziehungen.beziehung_von IS 'Join auf Feld gml_id verschiedener Tabellen';
COMMENT ON COLUMN alkis_beziehungen.beziehung_zu  IS 'Join auf Feld gml_id verschiedener Tabellen';
COMMENT ON COLUMN alkis_beziehungen.beziehungsart IS 'Typ der Beziehung zwischen der von- und zu-Tabelle';
@@ alkis-trigger.sql
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='KS_SONSTIGESBAUWERK';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE KS_SONSTIGESBAUWERK CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE KS_SONSTIGESBAUWERK (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet			character(20),
	sonstigesmodell 	varchar2(2047),
	anlass			varchar2(2047),
	bauwerksfunktion	integer,
	CONSTRAINT ALKIS_6 PRIMARY KEY (ogr_fid)
);
ALTER TABLE KS_SONSTIGESBAUWERK ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('KS_SONSTIGESBAUWERK','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_7 ON KS_SONSTIGESBAUWERK(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
COMMENT ON TABLE  ks_sonstigesbauwerk IS 'Sonstiges Bauwerk';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_ANDEREFESTLEGUNGNACHWASSERR';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_ANDEREFESTLEGUNGNACHWASSERR CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_ANDEREFESTLEGUNGNACHWASSERR (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	artderfestlegung	integer,
	land			integer,
	stelle			varchar2(2047),
	CONSTRAINT ALKIS_8 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_ANDEREFESTLEGUNGNACHWASSERR ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_ANDEREFESTLEGUNGNACHWASSERR','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_9 ON AX_ANDEREFESTLEGUNGNACHWASSERR(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_10 ON AX_ANDEREFESTLEGUNGNACHWASSERR (gml_id,beginnt);
CREATE INDEX ALKIS_11 ON AX_ANDEREFESTLEGUNGNACHWASSERR(land,stelle);
COMMENT ON TABLE  AX_ANDEREFESTLEGUNGNACHWASSERR        IS 'Andere Festlegung nach  W a s s e r r e c h t';
COMMENT ON COLUMN AX_ANDEREFESTLEGUNGNACHWASSERR.gml_id IS 'Identifikator, global eindeutig';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_BAUBLOCK';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_BAUBLOCK CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_BAUBLOCK (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	character(9),
	anlass			varchar2(2047),
	baublockbezeichnung	integer,
	CONSTRAINT ALKIS_12 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_BAUBLOCK ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_BAUBLOCK','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_13 ON AX_BAUBLOCK(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_14 ON ax_baublock (gml_id,beginnt);
COMMENT ON TABLE  ax_baublock        IS 'B a u b l o c k';
COMMENT ON COLUMN ax_baublock.gml_id IS 'Identifikator, global eindeutig';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_BESONDERERTOPOGRAPHISCHERPU';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_BESONDERERTOPOGRAPHISCHERPU CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_BESONDERERTOPOGRAPHISCHERPU (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	land			integer,
	stelle			integer,
	punktkennung		varchar2(2047),
	sonstigeeigenschaft	varchar2(2047),
	CONSTRAINT ALKIS_15 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_BESONDERERTOPOGRAPHISCHERPU ADD DUMMY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_BESONDERERTOPOGRAPHISCHERPU','DUMMY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE UNIQUE INDEX ALKIS_16 ON AX_BESONDERERTOPOGRAPHISCHERPU (gml_id,beginnt);
COMMENT ON TABLE  AX_BESONDERERTOPOGRAPHISCHERPU        IS 'B e s o n d e r e r   T o p o g r a f i s c h e r   P u n k t';
COMMENT ON COLUMN AX_BESONDERERTOPOGRAPHISCHERPU.gml_id IS 'Identifikator, global eindeutig';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_SOLL';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_SOLL CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_SOLL (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	name			varchar2(2047),
	CONSTRAINT ALKIS_17 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_SOLL ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_SOLL','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_18 ON AX_SOLL(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_19 ON ax_soll (gml_id,beginnt);
COMMENT ON TABLE ax_soll IS '''Soll'' ist eine runde, oft steilwandige Vertiefung in den norddeutschen Grundmoränenlandschaften; kann durch Abschmelzen von überschütteten Toteisblöcken (Toteisloch) oder durch Schmelzen periglazialer Eislinsen entstanden sein.';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_BEWERTUNG';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_BEWERTUNG CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_BEWERTUNG (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	klassifizierung		integer,
	CONSTRAINT ALKIS_20 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_BEWERTUNG ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_BEWERTUNG','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_21 ON AX_BEWERTUNG(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_22 ON ax_bewertung (gml_id,beginnt);
COMMENT ON TABLE  ax_bewertung        IS 'B e w e r t u n g';
COMMENT ON COLUMN ax_bewertung.gml_id IS 'Identifikator, global eindeutig';
COMMENT ON TABLE ax_bewertung  IS '''Bewertung'' ist die Klassifizierung einer Fläche nach dem Bewertungsgesetz (Bewertungsfläche).';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_TAGESABSCHNITT';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_TAGESABSCHNITT CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_TAGESABSCHNITT (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	tagesabschnittsnummer	varchar2(2047),
	CONSTRAINT ALKIS_23 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_TAGESABSCHNITT ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_TAGESABSCHNITT','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_24 ON AX_TAGESABSCHNITT(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_25 ON ax_tagesabschnitt (gml_id,beginnt);
COMMENT ON TABLE ax_tagesabschnitt  IS '''Tagesabschnitt'' ist ein Ordnungskriterium der Schätzungsarbeiten für eine Bewertungsfläche. Innerhalb der Tagesabschnitte sind die Grablöcher eindeutig zugeordnet.';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_DENKMALSCHUTZRECHT';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_DENKMALSCHUTZRECHT CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_DENKMALSCHUTZRECHT (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	artderfestlegung	integer,
	land			integer,
	stelle			varchar2(2047),
	art			varchar2(2047),
	name			varchar2(2047),
	CONSTRAINT ALKIS_26 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_DENKMALSCHUTZRECHT ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_DENKMALSCHUTZRECHT','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_27 ON AX_DENKMALSCHUTZRECHT(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_28 ON ax_denkmalschutzrecht (gml_id,beginnt);
CREATE INDEX ALKIS_29 ON ax_denkmalschutzrecht(land,stelle);
COMMENT ON TABLE  ax_denkmalschutzrecht        IS 'D e n k m a l s c h u t z r e c h t';
COMMENT ON COLUMN ax_denkmalschutzrecht.gml_id IS 'Identifikator, global eindeutig';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_FORSTRECHT';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_FORSTRECHT CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_FORSTRECHT (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	artderfestlegung	integer,
	besonderefunktion	integer,
	land			integer,
	stelle			varchar2(2047),
	CONSTRAINT ALKIS_30 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_FORSTRECHT ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_FORSTRECHT','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_31 ON AX_FORSTRECHT(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_32 ON ax_forstrecht (gml_id,beginnt);
CREATE INDEX ALKIS_33 ON ax_forstrecht(land,stelle);
COMMENT ON TABLE ax_forstrecht IS '''Forstrecht'' ist die auf den Grund und Boden bezogene Beschränkung, Belastung oder andere Eigenschaft einer Fläche nach öffentlichen, forstrechtlichen Vorschriften.';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_GEBAEUDEAUSGESTALTUNG';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_GEBAEUDEAUSGESTALTUNG CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_GEBAEUDEAUSGESTALTUNG (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	character(4),
	anlass			varchar2(2047),
	darstellung		integer,
	zeigtauf		varchar2(2047),
	CONSTRAINT ALKIS_34 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_GEBAEUDEAUSGESTALTUNG ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_GEBAEUDEAUSGESTALTUNG','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_35 ON AX_GEBAEUDEAUSGESTALTUNG(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_36 ON ax_gebaeudeausgestaltung (gml_id,beginnt);
COMMENT ON TABLE  ax_gebaeudeausgestaltung        IS 'G e b ä u d e a u s g e s t a l t u n g';
COMMENT ON COLUMN ax_gebaeudeausgestaltung.gml_id IS 'Identifikator, global eindeutig';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_GEOREFERENZIERTEGEBAEUDEADR';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_GEOREFERENZIERTEGEBAEUDEADR CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_GEOREFERENZIERTEGEBAEUDEADR (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	qualitaetsangaben	integer,
	land			integer,
	regierungsbezirk	integer,
	kreis			integer,
	gemeinde		integer,
	ortsteil		integer,
	postleitzahl		varchar2(2047),
	ortsnamepost		varchar2(2047),
	zusatzortsname		varchar2(2047),
	strassenname		varchar2(2047),
	strassenschluessel	integer,
	hausnummer		varchar2(2047),
	adressierungszusatz	varchar2(2047),
	CONSTRAINT ALKIS_37 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_GEOREFERENZIERTEGEBAEUDEADR ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_GEOREFERENZIERTEGEBAEUDEADR','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_38 ON AX_GEOREFERENZIERTEGEBAEUDEADR(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_39 ON AX_GEOREFERENZIERTEGEBAEUDEADR (gml_id,beginnt);
CREATE INDEX ALKIS_40 ON AX_GEOREFERENZIERTEGEBAEUDEADR (strassenschluessel, hausnummer, adressierungszusatz);
COMMENT ON TABLE  AX_GEOREFERENZIERTEGEBAEUDEADR        IS 'Georeferenzierte  G e b ä u d e a d r e s s e';
COMMENT ON COLUMN AX_GEOREFERENZIERTEGEBAEUDEADR.gml_id IS 'Identifikator, global eindeutig';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_GRABLOCHDERBODENSCHAETZUNG';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_GRABLOCHDERBODENSCHAETZUNG CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_GRABLOCHDERBODENSCHAETZUNG (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	art			varchar2(2047),
	name			varchar2(2047),
	bedeutung		varchar2(2047),
	land			integer,
	nummerierungsbezirk	varchar2(2047),
	gemarkungsnummer 	integer,
	nummerdesgrablochs	varchar2(2047),
	CONSTRAINT ALKIS_41 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_GRABLOCHDERBODENSCHAETZUNG ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_GRABLOCHDERBODENSCHAETZUNG','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_42 ON AX_GRABLOCHDERBODENSCHAETZUNG(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_43 ON ax_grablochderbodenschaetzung (gml_id,beginnt);
COMMENT ON TABLE  ax_grablochderbodenschaetzung        IS 'G r a b l o c h   d e r   B o d e n s c h ä t z u n g';
COMMENT ON COLUMN ax_grablochderbodenschaetzung.gml_id IS 'Identifikator, global eindeutig';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_HISTORISCHESFLURSTUECKALB';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_HISTORISCHESFLURSTUECKALB CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_HISTORISCHESFLURSTUECKALB (
	ogr_fid						integer NOT NULL,
	gml_id						character(16),
	land 						integer,
	gemarkungsnummer 				integer,
	flurnummer					integer,
	zaehler 					integer,
	nenner						integer,
	flurstueckskennzeichen				character(20),
	amtlicheflaeche					double precision,
	abweichenderrechtszustand			varchar2(5) default 'false',
	ZWEIFELHAFTERFLURSTUECKSNACHWE 		varchar2(5) default 'false',
	rechtsbehelfsverfahren				varchar2(5) default 'false',
	zeitpunktderentstehung				character(10),
	gemeinde					integer,
	identifier					character(44),
	beginnt						character(20),
	endet 						character(20),
	advstandardmodell				varchar2(2047),
	anlass						varchar2(2047),
	name						varchar2(2047),
	blattart					integer,
	buchungsart					varchar2(2047),
	buchungsblattkennzeichen			varchar2(2047),
	bezirk						integer,
	BUCHUNGSBLATTNUMMERMITBUCHSTAB	varchar2(2047),
	LAUFENDENUMMERDERBUCHUNGSSTELL			varchar2(2047),
	ZEITPUNKTDERENTSTEHUNGDESBEZUG	varchar2(2047),
	laufendenummerderfortfuehrung			varchar2(2047),
	fortfuehrungsart				varchar2(2047),
	VORGAENGERFLURSTUECKSKENNZEICH		varchar2(2047),
	NACHFOLGERFLURSTUECKSKENNZEICH		varchar2(2047),
	CONSTRAINT ALKIS_44 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_HISTORISCHESFLURSTUECKALB ADD DUMMY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_HISTORISCHESFLURSTUECKALB','DUMMY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE UNIQUE INDEX ALKIS_45 ON ax_historischesflurstueckalb (gml_id,beginnt);
COMMENT ON TABLE  ax_historischesflurstueckalb        IS 'Historisches Flurstück ALB';
COMMENT ON COLUMN ax_historischesflurstueckalb.gml_id IS 'Identifikator, global eindeutig';
CREATE INDEX ALKIS_46
   ON ax_historischesflurstueckalb (VORGAENGERFLURSTUECKSKENNZEICH /* ASC */);
CREATE INDEX ALKIS_47
   ON ax_historischesflurstueckalb (NACHFOLGERFLURSTUECKSKENNZEICH /* ASC */);
  COMMENT ON TABLE  ax_historischesflurstueckalb        IS 'Historisches Flurstück ALB';
  COMMENT ON COLUMN ax_historischesflurstueckalb.gml_id IS 'Identifikator, global eindeutig';
  COMMENT ON COLUMN ax_historischesflurstueckalb.flurnummer                IS 'FLN "Flurnummer" ist die von der Katasterbehörde zur eindeutigen Bezeichnung vergebene Nummer einer Flur, die eine Gruppe von zusammenhängenden Flurstücken innerhalb einer Gemarkung umfasst.';
  COMMENT ON COLUMN ax_historischesflurstueckalb.zaehler                   IS 'ZAE  Dieses Attribut enthält den Zähler der Flurstücknummer';
  COMMENT ON COLUMN ax_historischesflurstueckalb.nenner                    IS 'NEN  Dieses Attribut enthält den Nenner der Flurstücknummer';
  COMMENT ON COLUMN ax_historischesflurstueckalb.flurstueckskennzeichen    IS '"Flurstückskennzeichen" ist ein von der Katasterbehörde zur eindeutigen Bezeichnung des Flurstücks vergebenes Ordnungsmerkmal.
Die Attributart setzt sich aus den nachfolgenden expliziten Attributarten in der angegebenen Reihenfolge zusammen:
 1.  Land (2 Stellen)
 2.  Gemarkungsnummer (4 Stellen)
 3.  Flurnummer (3 Stellen)
 4.  Flurstücksnummer
 4.1 Zähler (5 Stellen)
 4.2 Nenner (4 Stellen)
 5.  Flurstücksfolge (2 Stellen)
Die Elemente sind rechtsbündig zu belegen, fehlende Stellen sind mit führenden Nullen zu belegen.
Da die Flurnummer und die Flurstücksfolge optional sind, sind aufgrund der bundeseinheitlichen Definition im Flurstückskennzeichen die entsprechenden Stellen, sofern sie nicht belegt sind, durch Unterstrich "_" ersetzt.
Gleiches gilt für Flurstücksnummern ohne Nenner, hier ist der fehlende Nenner im Flurstückskennzeichen durch Unterstriche zu ersetzen.';
  COMMENT ON COLUMN ax_historischesflurstueckalb.amtlicheflaeche           IS 'AFL "Amtliche Fläche" ist der im Liegenschaftskataster festgelegte Flächeninhalt des Flurstücks in [qm]. Flurstücksflächen kleiner 0,5 qm können mit bis zu zwei Nachkommastellen geführt werden, ansonsten ohne Nachkommastellen.';
  COMMENT ON COLUMN ax_historischesflurstueckalb.abweichenderrechtszustand IS 'ARZ "Abweichender Rechtszustand" ist ein Hinweis darauf, dass außerhalb des Grundbuches in einem durch Gesetz geregelten Verfahren der Bodenordnung (siehe Objektart "Bau-, Raum- oder Bodenordnungsrecht", AA "Art der Festlegung", Werte 1750, 1770, 2100 bis 2340) ein neuer Rechtszustand eingetreten ist und das amtliche Verzeichnis der jeweiligen ausführenden Stelle maßgebend ist.';
  COMMENT ON COLUMN ax_historischesflurstueckalb.ZWEIFELHAFTERFLURSTUECKSNACHWE IS 'ZFM "Zweifelhafter Flurstücksnachweis" ist eine Kennzeichnung eines Flurstücks, dessen Angaben nicht zweifelsfrei berichtigt werden können.';
  COMMENT ON COLUMN ax_historischesflurstueckalb.rechtsbehelfsverfahren    IS 'RBV "Rechtsbehelfsverfahren" ist der Hinweis darauf, dass bei dem Flurstück ein laufendes Rechtsbehelfsverfahren anhängig ist.';
  COMMENT ON COLUMN ax_historischesflurstueckalb.zeitpunktderentstehung    IS 'ZDE "Zeitpunkt der Entstehung" ist der Zeitpunkt, zu dem das Flurstück fachlich entstanden ist.';
  COMMENT ON COLUMN ax_historischesflurstueckalb.gemeinde                  IS 'Gemeindekennzeichen zur Zuordnung der Flustücksdaten zu einer Gemeinde.';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_HISTORISCHESFLURSTUECK';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_HISTORISCHESFLURSTUECK CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_HISTORISCHESFLURSTUECK (
	ogr_fid				integer NOT NULL,
	gml_id				character(16),
	land 				integer,
	gemarkungsnummer 		integer,
	flurnummer			integer,
	zaehler 			integer,
	nenner				integer,
	flurstueckskennzeichen	character(20),
	amtlicheflaeche			double precision,
	abweichenderrechtszustand	varchar2(5) default 'false',
	ZWEIFELHAFTERFLURSTUECKSNACHWE varchar2(5) default 'false',
	rechtsbehelfsverfahren		varchar2(5) default 'false',
	zeitpunktderentstehung		character(10),
	gemeinde			integer,
	identifier			character(44),
	beginnt				character(20),
	endet 				character(20),
	advstandardmodell		varchar2(2047),
	anlass				varchar2(2047),
	art				varchar2(2047),
	name				varchar2(2047),
	regierungsbezirk		integer,
	kreis				integer,
	VORGAENGERFLURSTUECKSKENNZEICH	varchar2(2047),
	NACHFOLGERFLURSTUECKSKENNZEICH	varchar2(2047),
	blattart			integer,
	buchungsart			integer,
	buchungsblattkennzeichen	varchar2(2047),
	bezirk				integer,
	BUCHUNGSBLATTNUMMERMITBUCHSTAB	varchar2(2047),
	LAUFENDENUMMERDERBUCHUNGSSTELL	integer,
	CONSTRAINT ALKIS_48 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_HISTORISCHESFLURSTUECK ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_HISTORISCHESFLURSTUECK','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_49 ON AX_HISTORISCHESFLURSTUECK(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_50 ON ax_historischesflurstueck (gml_id,beginnt);
CREATE INDEX ALKIS_51 ON ax_historischesflurstueck (VORGAENGERFLURSTUECKSKENNZEICH /* ASC */);
CREATE INDEX ALKIS_52 ON ax_historischesflurstueck (NACHFOLGERFLURSTUECKSKENNZEICH /* ASC */);
  COMMENT ON TABLE  ax_historischesflurstueck        IS 'Historisches Flurstück, ALKIS, MIT Geometrie';
  COMMENT ON COLUMN ax_historischesflurstueck.gml_id IS 'Identifikator, global eindeutig';
  COMMENT ON COLUMN ax_historischesflurstueck.flurnummer                IS 'FLN "Flurnummer" ist die von der Katasterbehörde zur eindeutigen Bezeichnung vergebene Nummer einer Flur, die eine Gruppe von zusammenhängenden Flurstücken innerhalb einer Gemarkung umfasst.';
  COMMENT ON COLUMN ax_historischesflurstueck.zaehler                   IS 'ZAE  Dieses Attribut enthält den Zähler der Flurstücknummer';
  COMMENT ON COLUMN ax_historischesflurstueck.nenner                    IS 'NEN  Dieses Attribut enthält den Nenner der Flurstücknummer';
  COMMENT ON COLUMN ax_historischesflurstueck.flurstueckskennzeichen    IS '"Flurstückskennzeichen" ist ein von der Katasterbehörde zur eindeutigen Bezeichnung des Flurstücks vergebenes Ordnungsmerkmal.
Die Attributart setzt sich aus den nachfolgenden expliziten Attributarten in der angegebenen Reihenfolge zusammen:
 1.  Land (2 Stellen)
 2.  Gemarkungsnummer (4 Stellen)
 3.  Flurnummer (3 Stellen)
 4.  Flurstücksnummer
 4.1 Zähler (5 Stellen)
 4.2 Nenner (4 Stellen)
 5.  Flurstücksfolge (2 Stellen)
Die Elemente sind rechtsbündig zu belegen, fehlende Stellen sind mit führenden Nullen zu belegen.
Da die Flurnummer und die Flurstücksfolge optional sind, sind aufgrund der bundeseinheitlichen Definition im Flurstückskennzeichen die entsprechenden Stellen, sofern sie nicht belegt sind, durch Unterstrich "_" ersetzt.
Gleiches gilt für Flurstücksnummern ohne Nenner, hier ist der fehlende Nenner im Flurstückskennzeichen durch Unterstriche zu ersetzen.';
  COMMENT ON COLUMN ax_historischesflurstueck.amtlicheflaeche           IS 'AFL "Amtliche Fläche" ist der im Liegenschaftskataster festgelegte Flächeninhalt des Flurstücks in [qm]. Flurstücksflächen kleiner 0,5 qm können mit bis zu zwei Nachkommastellen geführt werden, ansonsten ohne Nachkommastellen.';
  COMMENT ON COLUMN ax_historischesflurstueck.abweichenderrechtszustand IS 'ARZ "Abweichender Rechtszustand" ist ein Hinweis darauf, dass außerhalb des Grundbuches in einem durch Gesetz geregelten Verfahren der Bodenordnung (siehe Objektart "Bau-, Raum- oder Bodenordnungsrecht", AA "Art der Festlegung", Werte 1750, 1770, 2100 bis 2340) ein neuer Rechtszustand eingetreten ist und das amtliche Verzeichnis der jeweiligen ausführenden Stelle maßgebend ist.';
  COMMENT ON COLUMN ax_historischesflurstueck.ZWEIFELHAFTERFLURSTUECKSNACHWE IS 'ZFM "Zweifelhafter Flurstücksnachweis" ist eine Kennzeichnung eines Flurstücks, dessen Angaben nicht zweifelsfrei berichtigt werden können.';
  COMMENT ON COLUMN ax_historischesflurstueck.rechtsbehelfsverfahren    IS 'RBV "Rechtsbehelfsverfahren" ist der Hinweis darauf, dass bei dem Flurstück ein laufendes Rechtsbehelfsverfahren anhängig ist.';
  COMMENT ON COLUMN ax_historischesflurstueck.zeitpunktderentstehung    IS 'ZDE "Zeitpunkt der Entstehung" ist der Zeitpunkt, zu dem das Flurstück fachlich entstanden ist.';
  COMMENT ON COLUMN ax_historischesflurstueck.gemeinde                  IS 'GDZ "Gemeindekennzeichen zur Zuordnung der Flustücksdaten zu einer Gemeinde.';
CREATE INDEX ALKIS_53
   ON ax_historischesflurstueck(flurstueckskennzeichen /* ASC NULLS LAST */);
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_NATURUMWELTODERBODENSCHUTZR';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_NATURUMWELTODERBODENSCHUTZR CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_NATURUMWELTODERBODENSCHUTZR (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	artderfestlegung	integer,
	land			integer,
	stelle			varchar2(2047),
	name			varchar2(2047),
	CONSTRAINT ALKIS_54 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_NATURUMWELTODERBODENSCHUTZR ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_NATURUMWELTODERBODENSCHUTZR','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_55 ON AX_NATURUMWELTODERBODENSCHUTZR(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_56 ON AX_NATURUMWELTODERBODENSCHUTZR (gml_id,beginnt);
CREATE INDEX ALKIS_57 ON AX_NATURUMWELTODERBODENSCHUTZR(land,stelle);
COMMENT ON TABLE  AX_NATURUMWELTODERBODENSCHUTZR        IS 'N  a t u r -,  U m w e l t -   o d e r   B o d e n s c h u t z r e c h t';
COMMENT ON COLUMN AX_NATURUMWELTODERBODENSCHUTZR.gml_id IS 'Identifikator, global eindeutig';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_SCHUTZGEBIETNACHWASSERRECHT';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_SCHUTZGEBIETNACHWASSERRECHT CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_SCHUTZGEBIETNACHWASSERRECHT (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	artderfestlegung	integer,
	land			integer,
	stelle			varchar2(2047),
	art			varchar2(2047),
	name			varchar2(2047),
	nummerdesschutzgebietes	varchar2(2047),
	CONSTRAINT ALKIS_58 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_SCHUTZGEBIETNACHWASSERRECHT ADD DUMMY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_SCHUTZGEBIETNACHWASSERRECHT','DUMMY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE UNIQUE INDEX ALKIS_59 ON ax_schutzgebietnachwasserrecht (gml_id,beginnt);
CREATE INDEX ALKIS_60 ON ax_schutzgebietnachwasserrecht(land,stelle);
COMMENT ON TABLE  ax_schutzgebietnachwasserrecht        IS 'S c h u t z g e b i e t   n a c h   W a s s s e r r e c h t';
COMMENT ON COLUMN ax_schutzgebietnachwasserrecht.gml_id IS 'Identifikator, global eindeutig';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_SCHUTZGEBIETNACHNATURUMWELT';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_SCHUTZGEBIETNACHNATURUMWELT CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_SCHUTZGEBIETNACHNATURUMWELT (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	artderfestlegung	integer,
	land			integer,
	stelle			varchar2(2047),
	CONSTRAINT ALKIS_61 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_SCHUTZGEBIETNACHNATURUMWELT ADD DUMMY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_SCHUTZGEBIETNACHNATURUMWELT','DUMMY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE UNIQUE INDEX ALKIS_62 ON AX_SCHUTZGEBIETNACHNATURUMWELT (gml_id,beginnt);
CREATE INDEX ALKIS_63 ON AX_SCHUTZGEBIETNACHNATURUMWELT(land,stelle);
COMMENT ON TABLE  AX_SCHUTZGEBIETNACHNATURUMWELT IS 'S c h u t z g e b i e t   n a c h   N a t u r,  U m w e l t  o d e r  B o d e n s c h u t z r e c h t';
COMMENT ON COLUMN AX_SCHUTZGEBIETNACHNATURUMWELT.gml_id IS 'Identifikator, global eindeutig';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_SCHUTZZONE';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_SCHUTZZONE CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_SCHUTZZONE (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	"zone"			integer,
	art			varchar2(2047),
	CONSTRAINT ALKIS_64 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_SCHUTZZONE ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_SCHUTZZONE','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_65 ON AX_SCHUTZZONE(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_66 ON ax_schutzzone (gml_id,beginnt);
COMMENT ON TABLE  ax_schutzzone        IS 'S c h u t z z o n e';
COMMENT ON COLUMN ax_schutzzone.gml_id IS 'Identifikator, global eindeutig';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_TOPOGRAPHISCHELINIE';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_TOPOGRAPHISCHELINIE CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_TOPOGRAPHISCHELINIE (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	liniendarstellung	integer,
	sonstigeeigenschaft	varchar2(2047),
	CONSTRAINT ALKIS_67 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_TOPOGRAPHISCHELINIE ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_TOPOGRAPHISCHELINIE','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_68 ON AX_TOPOGRAPHISCHELINIE(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_69 ON ax_topographischelinie (gml_id,beginnt);
COMMENT ON TABLE  ax_topographischelinie        IS 'T o p o g r a p h i s c h e   L i n i e';
COMMENT ON COLUMN ax_topographischelinie.gml_id IS 'Identifikator, global eindeutig';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AP_PPO';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AP_PPO CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AP_PPO (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	sonstigesmodell		varchar2(2047),
	anlass			varchar2(2047),
	signaturnummer		varchar2(2047),
	darstellungsprioritaet  integer,
	art			varchar2(2047),
	drehwinkel		double precision,
	CONSTRAINT ALKIS_70 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AP_PPO ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AP_PPO','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_71 ON AP_PPO(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_72 ON ap_ppo (gml_id,beginnt);
CREATE INDEX ALKIS_73      ON ap_ppo (endet);
COMMENT ON TABLE  ap_ppo        IS 'PPO: Punktförmiges Präsentationsobjekt';
COMMENT ON COLUMN ap_ppo.gml_id IS 'Identifikator, global eindeutig';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AP_LPO';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AP_LPO CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AP_LPO (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	signaturnummer		varchar2(2047),
	darstellungsprioritaet  integer,
	art			varchar2(2047),
	CONSTRAINT ALKIS_74 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AP_LPO ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AP_LPO','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_75 ON AP_LPO(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_76 ON ap_lpo (gml_id,beginnt);
CREATE INDEX ALKIS_77      ON ap_lpo (endet);
COMMENT ON TABLE  ap_lpo        IS 'LPO: Linienförmiges Präsentationsobjekt';
COMMENT ON COLUMN ap_lpo.gml_id IS 'Identifikator, global eindeutig';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AP_PTO';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AP_PTO CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AP_PTO (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	schriftinhalt		varchar2(2047),
	fontsperrung		double precision,
	skalierung		double precision,
	horizontaleausrichtung	varchar2(2047),
	vertikaleausrichtung	varchar2(2047),
	signaturnummer		varchar2(2047),
	darstellungsprioritaet  integer,
	art			varchar2(2047),
	drehwinkel		double precision,
	CONSTRAINT ALKIS_78 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AP_PTO ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AP_PTO','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_79 ON AP_PTO(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_80 ON ap_pto (gml_id,beginnt);
CREATE INDEX ALKIS_81           ON ap_pto (art);
CREATE INDEX ALKIS_82  ON ap_pto (endet);
CREATE INDEX ALKIS_83     ON ap_pto (signaturnummer);
COMMENT ON TABLE  ap_pto               IS 'PTO: Textförmiges Präsentationsobjekt mit punktförmiger Textgeometrie ';
COMMENT ON COLUMN ap_pto.gml_id        IS 'Identifikator, global eindeutig';
COMMENT ON COLUMN ap_pto.schriftinhalt IS 'Label: anzuzeigender Text';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AP_LTO';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AP_LTO CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AP_LTO (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	sonstigesmodell		varchar2(2047),
	anlass			varchar2(2047),
	art			varchar2(2047),
	schriftinhalt		varchar2(2047),
	fontsperrung		double precision,
	skalierung		double precision,
	horizontaleausrichtung	varchar2(2047),
	vertikaleausrichtung	varchar2(2047),
	signaturnummer		varchar2(2047),
	darstellungsprioritaet  integer,
	CONSTRAINT ALKIS_84 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AP_LTO ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AP_LTO','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_85 ON AP_LTO(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_86 ON ap_lto (gml_id,beginnt);
CREATE INDEX ALKIS_87  ON ap_lto (endet);
COMMENT ON TABLE  ap_lto        IS 'LTO: Textförmiges Präsentationsobjekt mit linienförmiger Textgeometrie';
COMMENT ON COLUMN ap_lto.gml_id IS 'Identifikator, global eindeutig';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AP_DARSTELLUNG';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AP_DARSTELLUNG CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AP_DARSTELLUNG (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	art			varchar2(2047),
	darstellungsprioritaet  integer,
	signaturnummer		varchar2(2047),
	positionierungsregel    integer,
	CONSTRAINT ALKIS_88 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AP_DARSTELLUNG ADD DUMMY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AP_DARSTELLUNG','DUMMY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE UNIQUE INDEX ALKIS_89 ON ap_darstellung (gml_id,beginnt);
CREATE INDEX ALKIS_90  ON ap_darstellung (endet);
COMMENT ON TABLE  ap_darstellung        IS 'A P  D a r s t e l l u n g';
COMMENT ON COLUMN ap_darstellung.gml_id IS 'Identifikator, global eindeutig';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_FLURSTUECK';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_FLURSTUECK CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_FLURSTUECK (
	ogr_fid				integer NOT NULL,
	gml_id				character(16),
	land 				integer,
	gemarkungsnummer 		integer,
	flurnummer			integer,
	zaehler 			integer,
	nenner				integer,
	flurstueckskennzeichen		character(20),
	amtlicheflaeche			double precision,
	abweichenderrechtszustand	varchar2(5) default 'false',
	ZWEIFELHAFTERFLURSTUECKSNACHWE varchar2(5) default 'false',
	rechtsbehelfsverfahren		varchar2(5) default 'false',
	zeitpunktderentstehung		character(10),
	gemeinde			integer,
	identifier			character(44),
	beginnt				character(20),
	endet 				character(20),
	advstandardmodell 		varchar2(2047),
	anlass				varchar2(2047),
	name				varchar2(2047),
	regierungsbezirk		integer,
	kreis				integer,
	stelle				varchar2(2047),
	angabenzumabschnittflurstueck	varchar2(2047),
	kennungschluessel		varchar2(2047),
	flaechedesabschnitts		varchar2(2047),
	ANGABENZUMABSCHNITTNUMMERAKTEN varchar2(2047),
	angabenzumabschnittbemerkung	varchar2(2047),
	CONSTRAINT ALKIS_91 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_FLURSTUECK ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_FLURSTUECK','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_92 ON AX_FLURSTUECK(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_93 ON ax_flurstueck (gml_id,beginnt);
CREATE INDEX ALKIS_94 ON ax_flurstueck (land,gemarkungsnummer,flurnummer,zaehler,nenner);
CREATE INDEX ALKIS_95 ON ax_flurstueck (abweichenderrechtszustand);
  COMMENT ON TABLE  ax_flurstueck                           IS '"F l u r s t u e c k" ist ein Teil der Erdoberfläche, der von einer im Liegenschaftskataster festgelegten Grenzlinie umschlossen und mit einer Nummer bezeichnet ist. Es ist die Buchungseinheit des Liegenschaftskatasters.';
  COMMENT ON COLUMN ax_flurstueck.gml_id                    IS 'Identifikator, global eindeutig';
  COMMENT ON COLUMN ax_flurstueck.flurnummer                IS 'FLN "Flurnummer" ist die von der Katasterbehörde zur eindeutigen Bezeichnung vergebene Nummer einer Flur, die eine Gruppe von zusammenhängenden Flurstücken innerhalb einer Gemarkung umfasst.';
  COMMENT ON COLUMN ax_flurstueck.zaehler                   IS 'ZAE  Dieses Attribut enthält den Zähler der Flurstücknummer';
  COMMENT ON COLUMN ax_flurstueck.nenner                    IS 'NEN  Dieses Attribut enthält den Nenner der Flurstücknummer';
  COMMENT ON COLUMN ax_flurstueck.flurstueckskennzeichen    IS '"Flurstückskennzeichen" ist ein von der Katasterbehörde zur eindeutigen Bezeichnung des Flurstücks vergebenes Ordnungsmerkmal.
Die Attributart setzt sich aus den nachfolgenden expliziten Attributarten in der angegebenen Reihenfolge zusammen:
 1.  Land (2 Stellen)
 2.  Gemarkungsnummer (4 Stellen)
 3.  Flurnummer (3 Stellen)
 4.  Flurstücksnummer
 4.1 Zähler (5 Stellen)
 4.2 Nenner (4 Stellen)
 5.  Flurstücksfolge (2 Stellen)
Die Elemente sind rechtsbündig zu belegen, fehlende Stellen sind mit führenden Nullen zu belegen.
Da die Flurnummer und die Flurstücksfolge optional sind, sind aufgrund der bundeseinheitlichen Definition im Flurstückskennzeichen die entsprechenden Stellen, sofern sie nicht belegt sind, durch Unterstrich "_" ersetzt.
Gleiches gilt für Flurstücksnummern ohne Nenner, hier ist der fehlende Nenner im Flurstückskennzeichen durch Unterstriche zu ersetzen.';
  COMMENT ON COLUMN ax_flurstueck.amtlicheflaeche           IS 'AFL "Amtliche Fläche" ist der im Liegenschaftskataster festgelegte Flächeninhalt des Flurstücks in [qm]. Flurstücksflächen kleiner 0,5 qm können mit bis zu zwei Nachkommastellen geführt werden, ansonsten ohne Nachkommastellen.';
  COMMENT ON COLUMN ax_flurstueck.abweichenderrechtszustand IS 'ARZ "Abweichender Rechtszustand" ist ein Hinweis darauf, dass außerhalb des Grundbuches in einem durch Gesetz geregelten Verfahren der Bodenordnung (siehe Objektart "Bau-, Raum- oder Bodenordnungsrecht", AA "Art der Festlegung", Werte 1750, 1770, 2100 bis 2340) ein neuer Rechtszustand eingetreten ist und das amtliche Verzeichnis der jeweiligen ausführenden Stelle maßgebend ist.';
  COMMENT ON COLUMN ax_flurstueck.ZWEIFELHAFTERFLURSTUECKSNACHWE IS 'ZFM "Zweifelhafter Flurstücksnachweis" ist eine Kennzeichnung eines Flurstücks, dessen Angaben nicht zweifelsfrei berichtigt werden können.';
  COMMENT ON COLUMN ax_flurstueck.rechtsbehelfsverfahren    IS 'RBV "Rechtsbehelfsverfahren" ist der Hinweis darauf, dass bei dem Flurstück ein laufendes Rechtsbehelfsverfahren anhängig ist.';
  COMMENT ON COLUMN ax_flurstueck.zeitpunktderentstehung    IS 'ZDE "Zeitpunkt der Entstehung" ist der Zeitpunkt, zu dem das Flurstück fachlich entstanden ist.';
  COMMENT ON COLUMN ax_flurstueck.gemeinde                  IS 'Gemeindekennzeichen zur Zuordnung der Flustücksdaten zu einer Gemeinde.';
  COMMENT ON COLUMN ax_flurstueck.name                      IS 'Array mit Fortführungsjahr und -Nummer';
  COMMENT ON COLUMN ax_flurstueck.regierungsbezirk          IS 'Regierungsbezirk';
  COMMENT ON COLUMN ax_flurstueck.kreis                     IS 'Kreis';
CREATE INDEX ALKIS_96
   ON ax_flurstueck (flurstueckskennzeichen /* ASC NULLS LAST*/ );
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_BESONDEREFLURSTUECKSGRENZE';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_BESONDEREFLURSTUECKSGRENZE CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_BESONDEREFLURSTUECKSGRENZE (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	artderflurstuecksgrenze	varchar2(2047),
	CONSTRAINT ALKIS_97 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_BESONDEREFLURSTUECKSGRENZE ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_BESONDEREFLURSTUECKSGRENZE','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_98 ON AX_BESONDEREFLURSTUECKSGRENZE(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_99 ON ax_besondereflurstuecksgrenze (gml_id,beginnt);
COMMENT ON TABLE  ax_besondereflurstuecksgrenze        IS 'B e s o n d e r e   F l u r s t u e c k s g r e n z e';
COMMENT ON COLUMN ax_besondereflurstuecksgrenze.gml_id IS 'Identifikator, global eindeutig';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_GRENZPUNKT';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_GRENZPUNKT CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_GRENZPUNKT (
	ogr_fid				integer NOT NULL,
	gml_id				character(16),
	identifier			character(44),
	beginnt				character(20),
	endet 				character(20),
	advstandardmodell		varchar2(2047),
	anlass				varchar2(2047),
	punktkennung			varchar2(2047),
	land				integer,
	stelle				integer,
	abmarkung_marke			integer,
	festgestelltergrenzpunkt	varchar2(2047),
	besonderepunktnummer		varchar2(2047),
	bemerkungzurabmarkung		integer,
	sonstigeeigenschaft		varchar2(2047),
	art				varchar2(2047),
	name				varchar2(2047),
	zeitpunktderentstehung		integer,
	relativehoehe			double precision,
	CONSTRAINT ALKIS_100 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_GRENZPUNKT ADD DUMMY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_GRENZPUNKT','DUMMY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE UNIQUE INDEX ALKIS_101 ON ax_grenzpunkt (gml_id,beginnt);
CREATE INDEX ALKIS_102 ON ax_grenzpunkt (abmarkung_marke);
COMMENT ON TABLE  ax_grenzpunkt        IS 'G r e n z p u n k t';
COMMENT ON COLUMN ax_grenzpunkt.gml_id IS 'Identifikator, global eindeutig';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_LAGEBEZEICHNUNGOHNEHAUSNUMM';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_LAGEBEZEICHNUNGOHNEHAUSNUMM CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_LAGEBEZEICHNUNGOHNEHAUSNUMM (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	unverschluesselt	varchar2(2047),
	land			integer,
	regierungsbezirk	integer,
	kreis			integer,
	gemeinde		integer,
	lage			varchar2(2047),
	CONSTRAINT ALKIS_103 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_LAGEBEZEICHNUNGOHNEHAUSNUMM ADD DUMMY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_LAGEBEZEICHNUNGOHNEHAUSNUMM','DUMMY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE UNIQUE INDEX ALKIS_104 ON AX_LAGEBEZEICHNUNGOHNEHAUSNUMM (gml_id,beginnt);
CREATE INDEX ALKIS_105 ON AX_LAGEBEZEICHNUNGOHNEHAUSNUMM (land, regierungsbezirk, kreis, gemeinde,lage);
COMMENT ON TABLE  AX_LAGEBEZEICHNUNGOHNEHAUSNUMM        IS 'L a g e b e z e i c h n u n g   o h n e   H a u s n u m m e r';
COMMENT ON COLUMN AX_LAGEBEZEICHNUNGOHNEHAUSNUMM.gml_id IS 'Identifikator, global eindeutig';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_LAGEBEZEICHNUNGMITHAUSNUMME';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_LAGEBEZEICHNUNGMITHAUSNUMME CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_LAGEBEZEICHNUNGMITHAUSNUMME (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	land			integer,
	regierungsbezirk	integer,
	kreis			integer,
	gemeinde		integer,
	lage			varchar2(2047),
	hausnummer		varchar2(2047),
	CONSTRAINT ALKIS_106 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_LAGEBEZEICHNUNGMITHAUSNUMME ADD DUMMY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_LAGEBEZEICHNUNGMITHAUSNUMME','DUMMY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE UNIQUE INDEX ALKIS_107 ON AX_LAGEBEZEICHNUNGMITHAUSNUMME (gml_id,beginnt);
CREATE INDEX ALKIS_108       ON AX_LAGEBEZEICHNUNGMITHAUSNUMME (gemeinde, lage);
COMMENT ON TABLE  AX_LAGEBEZEICHNUNGMITHAUSNUMME        IS 'L a g e b e z e i c h n u n g   m i t   H a u s n u m m e r';
COMMENT ON COLUMN AX_LAGEBEZEICHNUNGMITHAUSNUMME.gml_id IS 'Identifikator, global eindeutig';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_LAGEBEZEICHNUNGMITPSEUDONUM';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_LAGEBEZEICHNUNGMITPSEUDONUM CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_LAGEBEZEICHNUNGMITPSEUDONUM (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	land			integer,
	regierungsbezirk	integer,
	kreis			integer,
	gemeinde		integer,
	lage			varchar2(2047),
	pseudonummer		varchar2(2047),
	laufendenummer		varchar2(2047),
	CONSTRAINT ALKIS_109 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_LAGEBEZEICHNUNGMITPSEUDONUM ADD DUMMY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_LAGEBEZEICHNUNGMITPSEUDONUM','DUMMY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE UNIQUE INDEX ALKIS_110 ON AX_LAGEBEZEICHNUNGMITPSEUDONUM (gml_id,beginnt);
COMMENT ON TABLE  AX_LAGEBEZEICHNUNGMITPSEUDONUM        IS 'L a g e b e z e i c h n u n g   m i t  P s e u d o n u m m e r';
COMMENT ON COLUMN AX_LAGEBEZEICHNUNGMITPSEUDONUM.gml_id IS 'Identifikator, global eindeutig';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_AUFNAHMEPUNKT';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_AUFNAHMEPUNKT CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_AUFNAHMEPUNKT (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier              character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	punktkennung		varchar2(2047),
	land			integer,
	stelle			integer,
	sonstigeeigenschaft	varchar2(2047),
	vermarkung_marke	integer,
	relativehoehe		double precision,
	CONSTRAINT ALKIS_111 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_AUFNAHMEPUNKT ADD DUMMY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_AUFNAHMEPUNKT','DUMMY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE UNIQUE INDEX ALKIS_112 ON ax_aufnahmepunkt (gml_id,beginnt);
COMMENT ON TABLE  ax_aufnahmepunkt        IS 'A u f n a h m e p u n k t';
COMMENT ON COLUMN ax_aufnahmepunkt.gml_id IS 'Identifikator, global eindeutig';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_SICHERUNGSPUNKT';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_SICHERUNGSPUNKT CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_SICHERUNGSPUNKT (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	name			varchar2(2047),
	punktkennung		varchar2(2047),
	land			integer,
	stelle			integer,
	sonstigeeigenschaft	varchar2(2047),
	vermarkung_marke	integer,
	relativehoehe		double precision,
 	CONSTRAINT ALKIS_113 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_SICHERUNGSPUNKT ADD DUMMY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_SICHERUNGSPUNKT','DUMMY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
COMMENT ON TABLE  ax_sicherungspunkt        IS 'S i c h e r u n g s p u n k t';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_SONSTIGERVERMESSUNGSPUNKT';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_SONSTIGERVERMESSUNGSPUNKT CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_SONSTIGERVERMESSUNGSPUNKT (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	vermarkung_marke	integer,
	punktkennung		varchar2(2047),
	art			varchar2(2047),
	land			integer,
	stelle			integer,
	sonstigeeigenschaft	varchar2(2047),
	relativehoehe		double precision,
	CONSTRAINT ALKIS_114 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_SONSTIGERVERMESSUNGSPUNKT ADD DUMMY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_SONSTIGERVERMESSUNGSPUNKT','DUMMY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE UNIQUE INDEX ALKIS_115 ON ax_sonstigervermessungspunkt (gml_id,beginnt);
COMMENT ON TABLE  ax_sonstigervermessungspunkt        IS 's o n s t i g e r   V e r m e s s u n g s p u n k t';
COMMENT ON COLUMN ax_sonstigervermessungspunkt.gml_id IS 'Identifikator, global eindeutig';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_PUNKTORTAG';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_PUNKTORTAG CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_PUNKTORTAG (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	art			varchar2(2047),
	name			varchar2(2047),
	kartendarstellung	varchar2(2047),
	genauigkeitsstufe	integer,
	vertrauenswuerdigkeit	integer,
	koordinatenstatus	integer,
	CONSTRAINT ALKIS_116 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_PUNKTORTAG ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_PUNKTORTAG','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_117 ON AX_PUNKTORTAG(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_118 ON ax_punktortag (gml_id,beginnt);
COMMENT ON TABLE  ax_punktortag        IS 'P u n k t o r t   AG';
COMMENT ON COLUMN ax_punktortag.gml_id IS 'Identifikator, global eindeutig';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_PUNKTORTAU';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_PUNKTORTAU CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_PUNKTORTAU (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	kartendarstellung	varchar2(2047),
	name			varchar2(2047),
	individualname		varchar2(2047),
	vertrauenswuerdigkeit	integer,
	genauigkeitsstufe	integer,
	koordinatenstatus	integer,
	CONSTRAINT ALKIS_119 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_PUNKTORTAU ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_PUNKTORTAU','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001),mdsys.sdo_dim_element('Z',-50,3000,0.001)));
CREATE INDEX ALKIS_120 ON AX_PUNKTORTAU(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_121 ON ax_punktortau (gml_id,beginnt);
COMMENT ON TABLE  ax_punktortau        IS 'P u n k t o r t   A U';
COMMENT ON COLUMN ax_punktortau.gml_id IS 'Identifikator, global eindeutig';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_PUNKTORTTA';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_PUNKTORTTA CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_PUNKTORTTA (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	kartendarstellung	varchar2(2047),
	description		integer,
	art			varchar2(2047),
	name			varchar2(2047),
	genauigkeitsstufe	integer,
	vertrauenswuerdigkeit	integer,
	koordinatenstatus	integer,
	CONSTRAINT ALKIS_122 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_PUNKTORTTA ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_PUNKTORTTA','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_123 ON AX_PUNKTORTTA(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_124 ON ax_punktortta (gml_id,beginnt);
CREATE INDEX ALKIS_125 ON ax_punktortta (endet);
COMMENT ON TABLE  ax_punktortta        IS 'P u n k t o r t   T A';
COMMENT ON COLUMN ax_punktortta.gml_id IS 'Identifikator, global eindeutig';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_FORTFUEHRUNGSNACHWEISDECKBL';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_FORTFUEHRUNGSNACHWEISDECKBL CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_FORTFUEHRUNGSNACHWEISDECKBL (
	ogr_fid				integer NOT NULL,
	gml_id				character(16),
	identifier			character(44),
	beginnt				character(20),
	endet				character(20),
	advstandardmodell		varchar2(2047),
	anlass				varchar2(2047),
	uri				varchar2(2047),
	FORTFUEHRUNGSFALLNUMMERNBEREIC	varchar2(2047),
	land				integer,
	gemarkungsnummer		integer,
	laufendenummer			integer,
	titel				varchar2(2047),
	erstelltam			varchar2(2047),
	fortfuehrungsentscheidungam	varchar2(2047),
	fortfuehrungsentscheidungvon	varchar2(2047),
	bemerkung			varchar2(2047),
	beziehtsichauf			varchar2(2047),
	CONSTRAINT ALKIS_126 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_FORTFUEHRUNGSNACHWEISDECKBL ADD DUMMY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_FORTFUEHRUNGSNACHWEISDECKBL','DUMMY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
COMMENT ON TABLE  AX_FORTFUEHRUNGSNACHWEISDECKBL
IS 'F o r t f u e h r u n g s n a c h w e i s / D e c k b l a t t';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_FORTFUEHRUNGSFALL';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_FORTFUEHRUNGSFALL CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_FORTFUEHRUNGSFALL (
	ogr_fid					integer NOT NULL,
	gml_id					character(16),
	identifier				character(44),
	beginnt					character(20),
	endet					character(20),
	advstandardmodell			varchar2(2047),
	anlass					varchar2(2047),
	uri					varchar2(2047),
	fortfuehrungsfallnummer			integer,
	laufendenummer				integer,
	UEBERSCHRIFTIMFORTFUEHRUNGSNAC	varchar2(2047),
	ANZAHLDERFORTFUEHRUNGSMITTEILU	integer,
	zeigtaufaltesflurstueck			varchar2(2047),
	zeigtaufneuesflurstueck			varchar2(2047),
	bemerkung				varchar2(2047),
	CONSTRAINT ALKIS_127 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_FORTFUEHRUNGSFALL ADD DUMMY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_FORTFUEHRUNGSFALL','DUMMY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
COMMENT ON TABLE  ax_fortfuehrungsfall IS 'F o r t f u e h r u n g s f a l l';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_RESERVIERUNG';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_RESERVIERUNG CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_RESERVIERUNG (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar2(2047),
	art			integer,
	nummer			varchar2(2047),
	land			integer,
	stelle			integer,
	ablaufderreservierung	varchar2(2047),
	antragsnummer		varchar2(2047),
	auftragsnummer		varchar2(2047),
	CONSTRAINT ALKIS_128 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_RESERVIERUNG ADD DUMMY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_RESERVIERUNG','DUMMY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
COMMENT ON TABLE  ax_reservierung IS 'R e s e r v i e r u n g';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_PUNKTKENNUNGUNTERGEGANGEN';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_PUNKTKENNUNGUNTERGEGANGEN CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_PUNKTKENNUNGUNTERGEGANGEN (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar2(2047),
	sonstigesmodell		varchar2(2047),
	anlass			varchar2(2047),
	punktkennung		varchar2(2047),
	art			integer,
	CONSTRAINT ALKIS_129 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_PUNKTKENNUNGUNTERGEGANGEN ADD DUMMY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_PUNKTKENNUNGUNTERGEGANGEN','DUMMY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
COMMENT ON TABLE  ax_punktkennunguntergegangen IS 'P u n k t k e n n u n g, untergegangen';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_HISTORISCHESFLURSTUECKOHNER';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_HISTORISCHESFLURSTUECKOHNER CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_HISTORISCHESFLURSTUECKOHNER (
	ogr_fid				integer NOT NULL,
	gml_id				character(16),
	land 				integer,
	gemarkungsnummer 		integer,
	flurnummer			integer,
	zaehler 			integer,
	nenner				integer,
	flurstueckskennzeichen		character(20),
	amtlicheflaeche			double precision,
	abweichenderrechtszustand	varchar2(2047),
	ZWEIFELHAFTERFLURSTUECKSNACHWE varchar2(2047),
	rechtsbehelfsverfahren		integer,
	zeitpunktderentstehung		character(10),
	gemeinde			integer,
	identifier			character(44),
	beginnt				character(20),
	endet 				character(20),
	advstandardmodell		character(4),
	anlass				varchar2(2047),
	name				varchar2(2047),
	NACHFOLGERFLURSTUECKSKENNZEICH	varchar2(2047),
	VORGAENGERFLURSTUECKSKENNZEICH	varchar2(2047),
	CONSTRAINT ALKIS_130 PRIMARY KEY (ogr_fid)
);
  COMMENT ON TABLE  AX_HISTORISCHESFLURSTUECKOHNER        IS '"Historisches Flurstück ohne Raumbezug" ist ein nicht mehr aktuelles Flurstück, das schon im ALB historisch geworden ist, nach ALKIS migriert und im Rahmen der Vollhistorie geführt wird.';
  COMMENT ON COLUMN AX_HISTORISCHESFLURSTUECKOHNER.gml_id IS 'Identifikator, global eindeutig';
  COMMENT ON COLUMN AX_HISTORISCHESFLURSTUECKOHNER.flurnummer                IS 'FLN "Flurnummer" ist die von der Katasterbehörde zur eindeutigen Bezeichnung vergebene Nummer einer Flur, die eine Gruppe von zusammenhängenden Flurstücken innerhalb einer Gemarkung umfasst.';
  COMMENT ON COLUMN AX_HISTORISCHESFLURSTUECKOHNER.zaehler                   IS 'ZAE  Dieses Attribut enthält den Zähler der Flurstücknummer';
  COMMENT ON COLUMN AX_HISTORISCHESFLURSTUECKOHNER.nenner                    IS 'NEN  Dieses Attribut enthält den Nenner der Flurstücknummer';
  COMMENT ON COLUMN AX_HISTORISCHESFLURSTUECKOHNER.flurstueckskennzeichen    IS '"Flurstückskennzeichen" ist ein von der Katasterbehörde zur eindeutigen Bezeichnung des Flurstücks vergebenes Ordnungsmerkmal.
Die Attributart setzt sich aus den nachfolgenden expliziten Attributarten in der angegebenen Reihenfolge zusammen:
 1.  Land (2 Stellen)
 2.  Gemarkungsnummer (4 Stellen)
 3.  Flurnummer (3 Stellen)
 4.  Flurstücksnummer
 4.1 Zähler (5 Stellen)
 4.2 Nenner (4 Stellen)
 5.  Flurstücksfolge (2 Stellen)
Die Elemente sind rechtsbündig zu belegen, fehlende Stellen sind mit führenden Nullen zu belegen.
Da die Flurnummer und die Flurstücksfolge optional sind, sind aufgrund der bundeseinheitlichen Definition im Flurstückskennzeichen die entsprechenden Stellen, sofern sie nicht belegt sind, durch Unterstrich "_" ersetzt.
Gleiches gilt für Flurstücksnummern ohne Nenner, hier ist der fehlende Nenner im Flurstückskennzeichen durch Unterstriche zu ersetzen.';
  COMMENT ON COLUMN AX_HISTORISCHESFLURSTUECKOHNER.amtlicheflaeche           IS 'AFL "Amtliche Fläche" ist der im Liegenschaftskataster festgelegte Flächeninhalt des Flurstücks in [qm]. Flurstücksflächen kleiner 0,5 qm können mit bis zu zwei Nachkommastellen geführt werden, ansonsten ohne Nachkommastellen.';
  COMMENT ON COLUMN AX_HISTORISCHESFLURSTUECKOHNER.abweichenderrechtszustand IS 'ARZ "Abweichender Rechtszustand" ist ein Hinweis darauf, dass außerhalb des Grundbuches in einem durch Gesetz geregelten Verfahren der Bodenordnung (siehe Objektart "Bau-, Raum- oder Bodenordnungsrecht", AA "Art der Festlegung", Werte 1750, 1770, 2100 bis 2340) ein neuer Rechtszustand eingetreten ist und das amtliche Verzeichnis der jeweiligen ausführenden Stelle maßgebend ist.';
  COMMENT ON COLUMN AX_HISTORISCHESFLURSTUECKOHNER.ZWEIFELHAFTERFLURSTUECKSNACHWE IS 'ZFM "Zweifelhafter Flurstücksnachweis" ist eine Kennzeichnung eines Flurstücks, dessen Angaben nicht zweifelsfrei berichtigt werden können.';
  COMMENT ON COLUMN AX_HISTORISCHESFLURSTUECKOHNER.rechtsbehelfsverfahren    IS 'RBV "Rechtsbehelfsverfahren" ist der Hinweis darauf, dass bei dem Flurstück ein laufendes Rechtsbehelfsverfahren anhängig ist.';
  COMMENT ON COLUMN AX_HISTORISCHESFLURSTUECKOHNER.zeitpunktderentstehung    IS 'ZDE "Zeitpunkt der Entstehung" ist der Zeitpunkt, zu dem das Flurstück fachlich entstanden ist.';
  COMMENT ON COLUMN AX_HISTORISCHESFLURSTUECKOHNER.gemeinde                  IS 'Gemeindekennzeichen zur Zuordnung der Flustücksdaten zu einer Gemeinde.';
  COMMENT ON COLUMN AX_HISTORISCHESFLURSTUECKOHNER.anlass                    IS '?';
  COMMENT ON COLUMN AX_HISTORISCHESFLURSTUECKOHNER.name                      IS 'Array mit Fortführungsjahr und -Nummer';
  COMMENT ON COLUMN AX_HISTORISCHESFLURSTUECKOHNER.NACHFOLGERFLURSTUECKSKENNZEICH
  IS '"Nachfolger-Flurstückskennzeichen" ist die Bezeichnung der Flurstücke, die dem Objekt "Historisches Flurstück ohne Raumbezug" direkt nachfolgen.
Array mit Kennzeichen im Format der Spalte "flurstueckskennzeichen"';
  COMMENT ON COLUMN AX_HISTORISCHESFLURSTUECKOHNER.VORGAENGERFLURSTUECKSKENNZEICH
  IS '"Vorgänger-Flurstückskennzeichen" ist die Bezeichnung der Flurstücke, die dem Objekt "Historisches Flurstück ohne Raumbezugs" direkt vorangehen.
Array mit Kennzeichen im Format der Spalte "flurstueckskennzeichen"';
ALTER TABLE AX_HISTORISCHESFLURSTUECKOHNER ADD DUMMY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_HISTORISCHESFLURSTUECKOHNER','DUMMY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_131 ON AX_HISTORISCHESFLURSTUECKOHNER (flurstueckskennzeichen /* ASC NULLS LAST */ );
CREATE INDEX ALKIS_132 ON AX_HISTORISCHESFLURSTUECKOHNER (VORGAENGERFLURSTUECKSKENNZEICH /* ASC */);
CREATE INDEX ALKIS_133 ON AX_HISTORISCHESFLURSTUECKOHNER (NACHFOLGERFLURSTUECKSKENNZEICH /* ASC */);
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_PERSON';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_PERSON CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_PERSON (
	ogr_fid				integer NOT NULL,
	gml_id				character(16),
	identifier			character(44),
	beginnt				character(20),
	endet 				character(20),
	advstandardmodell		varchar2(2047),
	anlass				varchar2(2047),
	nachnameoderfirma		varchar2(2047),
	anrede				integer,
	vorname				varchar2(2047),
	geburtsname			varchar2(2047),
	geburtsdatum			varchar2(2047),
	namensbestandteil		varchar2(2047),
	akademischergrad		varchar2(2047),
	CONSTRAINT ALKIS_134 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_PERSON ADD DUMMY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_PERSON','DUMMY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE UNIQUE INDEX ALKIS_135 ON ax_person (gml_id,beginnt);
COMMENT ON TABLE  ax_person        IS 'NREO "Person" ist eine natürliche oder juristische Person und kann z.B. in den Rollen Eigentümer, Erwerber, Verwalter oder Vertreter in Katasterangelegenheiten geführt werden.';
COMMENT ON COLUMN ax_person.gml_id IS 'Identifikator, global eindeutig';
COMMENT ON COLUMN ax_person.namensbestandteil IS 'enthält z.B. Titel wie "Baron"';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_ANSCHRIFT';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_ANSCHRIFT CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_ANSCHRIFT (
	ogr_fid				integer NOT NULL,
	gml_id				character(16),
	identifier			character(44),
	beginnt				character(20),
	endet 				character(20),
	advstandardmodell		varchar2(2047),
	anlass				varchar2(2047),
	ort_post			varchar2(2047),
	postleitzahlpostzustellung	varchar2(2047),
	strasse				varchar2(2047),
	hausnummer			varchar2(2047),
	bestimmungsland			varchar2(2047),
	postleitzahlpostfach		varchar2(2047),
	postfach			varchar2(2047),
	ortsteil			varchar2(2047),
	weitereAdressen			varchar2(2047),
	telefon				varchar2(2047),
	fax				varchar2(2047),
	CONSTRAINT ALKIS_136 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_ANSCHRIFT ADD DUMMY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_ANSCHRIFT','DUMMY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE UNIQUE INDEX ALKIS_137 ON ax_anschrift (gml_id,beginnt);
COMMENT ON TABLE  ax_anschrift        IS 'A n s c h r i f t';
COMMENT ON COLUMN ax_anschrift.gml_id IS 'Identifikator, global eindeutig';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_NAMENSNUMMER';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_NAMENSNUMMER CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_NAMENSNUMMER (
	ogr_fid				integer NOT NULL,
	gml_id				character(16),
	identifier			character(44),
	beginnt				character(20),
	endet 				character(20),
	advstandardmodell		varchar2(2047),
	anlass				varchar2(2047),
	laufendenummernachdin1421	character(16),
	zaehler				double precision,
	nenner				double precision,
	eigentuemerart			integer,
	nummer				varchar2(2047),
	artderrechtsgemeinschaft	integer,
	beschriebderrechtsgemeinschaft	varchar2(2047),
	CONSTRAINT ALKIS_138 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_NAMENSNUMMER ADD DUMMY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_NAMENSNUMMER','DUMMY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE UNIQUE INDEX ALKIS_139 ON ax_namensnummer (gml_id,beginnt);
COMMENT ON TABLE  ax_namensnummer        IS 'NREO "Namensnummer" ist die laufende Nummer der Eintragung, unter welcher der Eigentümer oder Erbbauberechtigte im Buchungsblatt geführt wird. Rechtsgemeinschaften werden auch unter AX_Namensnummer geführt.';
COMMENT ON COLUMN ax_namensnummer.gml_id IS 'Identifikator, global eindeutig';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_BUCHUNGSBLATT';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_BUCHUNGSBLATT CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_BUCHUNGSBLATT (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	buchungsblattkennzeichen	varchar2(2047),
	land			integer,
	bezirk			integer,
	BUCHUNGSBLATTNUMMERMITBUCHSTAB	varchar2(2047),
	blattart		integer,
	art			varchar2(2047),
	CONSTRAINT ALKIS_140 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_BUCHUNGSBLATT ADD DUMMY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_BUCHUNGSBLATT','DUMMY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE UNIQUE INDEX ALKIS_141 ON ax_buchungsblatt (gml_id,beginnt);
CREATE INDEX ALKIS_142 ON ax_buchungsblatt (land,bezirk,BUCHUNGSBLATTNUMMERMITBUCHSTAB);
COMMENT ON TABLE  ax_buchungsblatt        IS 'NREO "Buchungsblatt" enthält die Buchungen (Buchungsstellen und Namensnummern) des Grundbuchs und des Liegenschhaftskatasters (bei buchungsfreien Grundstücken).';
COMMENT ON COLUMN ax_buchungsblatt.gml_id IS 'Identifikator, global eindeutig';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_BUCHUNGSSTELLE';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_BUCHUNGSSTELLE CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_BUCHUNGSSTELLE (
	ogr_fid				integer NOT NULL,
	gml_id				character(16),
	identifier			character(44),
	beginnt				character(20),
	endet 				character(20),
	advstandardmodell		varchar2(2047),
	anlass				varchar2(2047),
	buchungsart			integer,
	laufendenummer			varchar2(2047),
	BESCHREIBUNGDESUMFANGSDERBUCHU	character(1),
	zaehler				double precision,
	nenner				double precision,
	nummerimaufteilungsplan		varchar2(2047),
	beschreibungdessondereigentums	varchar2(2047),
	CONSTRAINT ALKIS_143 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_BUCHUNGSSTELLE ADD DUMMY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_BUCHUNGSSTELLE','DUMMY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE UNIQUE INDEX ALKIS_144 ON ax_buchungsstelle (gml_id,beginnt);
COMMENT ON TABLE  ax_buchungsstelle        IS 'NREO "Buchungsstelle" ist die unter einer laufenden Nummer im Verzeichnis des Buchungsblattes eingetragene Buchung.';
COMMENT ON COLUMN ax_buchungsstelle.gml_id IS 'Identifikator, global eindeutig';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_GEBAEUDE';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_GEBAEUDE CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_GEBAEUDE (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	gebaeudefunktion	integer,
	weiteregebaeudefunktion	varchar2(2047),
	name			varchar2(2047),
	bauweise		integer,
	ANZAHLDEROBERIRDISCHENGESCHOSS	integer,
	ANZAHLDERUNTERIRDISCHENGESCHOS	integer,
	hochhaus		varchar2(2047),
	objekthoehe		integer,
	dachform		integer,
	zustand			integer,
	geschossflaeche		integer,
	grundflaeche		integer,
	umbauterraum		integer,
	baujahr			integer,
	lagezurerdoberflaeche	integer,
	dachart			varchar2(2047),
	dachgeschossausbau	integer,
	qualitaetsangaben	varchar2(2047),
	ax_datenerhebung	integer,
	description		integer,
	art			varchar2(2047),
	individualname		varchar2(2047),
	CONSTRAINT ALKIS_145 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_GEBAEUDE ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_GEBAEUDE','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_146 ON AX_GEBAEUDE(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_147 ON ax_gebaeude (gml_id,beginnt);
  COMMENT ON TABLE  ax_gebaeude                    IS '"G e b ä u d e" ist ein dauerhaft errichtetes Bauwerk, dessen Nachweis wegen seiner Bedeutung als Liegenschaft erforderlich ist sowie dem Zweck der Basisinformation des Liegenschaftskatasters dient.';
  COMMENT ON COLUMN ax_gebaeude.gml_id             IS 'Identifikator, global eindeutig';
  COMMENT ON COLUMN ax_gebaeude.gebaeudefunktion   IS 'GFK "Gebäudefunktion" ist die zum Zeitpunkt der Erhebung vorherrschend funktionale Bedeutung des Gebäudes (Dominanzprinzip). Werte siehe ax_gebaeude_funktion';
  COMMENT ON COLUMN ax_gebaeude.weiteregebaeudefunktion IS 'WGF "Weitere Gebäudefunktion" sind weitere Funktionen, die ein Gebäude neben der dominierenden Gebäudefunktion hat.';
  COMMENT ON COLUMN ax_gebaeude.name             IS 'NAM "Name" ist der Eigenname oder die Bezeichnung des Gebäudes.';
  COMMENT ON COLUMN ax_gebaeude.bauweise           IS 'BAW "Bauweise" ist die Beschreibung der Art der Bauweise. Werte siehe ax_gebaeude_bauweise';
  COMMENT ON COLUMN ax_gebaeude.ANZAHLDEROBERIRDISCHENGESCHOSS IS 'AOG "Anzahl der oberirdischen Geschosse" ist die Anzahl der oberirdischen Geschosse des Gebäudes.';
  COMMENT ON COLUMN ax_gebaeude.ANZAHLDERUNTERIRDISCHENGESCHOS IS 'AUG "Anzahl der unterirdischen Geschosse" ist die Anzahl der unterirdischen Geschosse des Gebäudes.';
  COMMENT ON COLUMN ax_gebaeude.hochhaus           IS 'HOH "Hochhaus" ist ein Gebäude, das nach Gebäudehöhe und Ausprägung als Hochhaus zu bezeichnen ist. Für Gebäude im Geschossbau gilt dieses i.d.R. ab 8 oberirdischen Geschossen, für andere Gebäude ab einer Gebäudehöhe von 22 m. Abweichungen hiervon können sich durch die Festlegungen in den länderspezifischen Bauordnungen ergeben.';
  COMMENT ON COLUMN ax_gebaeude.objekthoehe        IS 'HHO "Objekthöhe" ist die Höhendifferenz in [m] zwischen dem höchsten Punkt der Dachkonstruktion und der festgelegten Geländeoberfläche des Gebäudes.';
  COMMENT ON COLUMN ax_gebaeude.dachform           IS 'DAF "Dachform" beschreibt die charakteristische Form des Daches. Werte siehe ax_gebaeude_dachform';
  COMMENT ON COLUMN ax_gebaeude.zustand            IS 'ZUS "Zustand" beschreibt die Beschaffenheit oder die Betriebsbereitschaft von "Gebäude". Diese Attributart wird nur dann optional geführt, wenn der Zustand des Gebäudes vom nutzungsfähigen Zustand abweicht. Werte siehe ax_gebaeude_zustand';
  COMMENT ON COLUMN ax_gebaeude.geschossflaeche    IS 'GFL "Geschossfläche" ist die Gebäudegeschossfläche in [qm].';
  COMMENT ON COLUMN ax_gebaeude.grundflaeche       IS 'GRF "Grundfläche" ist die Gebäudegrundfläche in [qm].';
  COMMENT ON COLUMN ax_gebaeude.umbauterraum       IS 'URA "Umbauter Raum" ist der umbaute Raum [Kubikmeter] des Gebäudes.';
  COMMENT ON COLUMN ax_gebaeude.baujahr            IS 'BJA "Baujahr" ist das Jahr der Fertigstellung oder der baulichen Veränderung des Gebäudes.';
  COMMENT ON COLUMN ax_gebaeude.lagezurerdoberflaeche IS 'OFL "Lage zur Erdoberfläche" ist die Angabe der relativen Lage des Gebäudes zur Erdoberfläche. Diese Attributart wird nur bei nicht ebenerdigen Gebäuden geführt. 1200=Unter der Erdoberfläche, 1400=Aufgeständert';
  COMMENT ON COLUMN ax_gebaeude.dachart            IS 'DAA "Dachart" gibt die Art der Dacheindeckung (z.B. Reetdach) an.';
  COMMENT ON COLUMN ax_gebaeude.dachgeschossausbau IS 'DGA "Dachgeschossausbau" ist ein Hinweis auf den Ausbau bzw. die Ausbaufähigkeit des Dachgeschosses.';
  COMMENT ON COLUMN ax_gebaeude.qualitaetsangaben  IS 'QAG Angaben zur Herkunft der Informationen (Erhebungsstelle). Die Information ist konform zu den Vorgaben aus ISO 19115 zu repräsentieren.';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_BAUTEIL';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_BAUTEIL CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_BAUTEIL (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	sonstigesmodell		varchar2(2047),
	anlass			varchar2(2047),
	bauart			integer,
	dachform		integer,
	ANZAHLDEROBERIRDISCHENGESCHOSS	integer,
	ANZAHLDERUNTERIRDISCHENGESCHOS	integer,
	lagezurerdoberflaeche	integer,
	CONSTRAINT ALKIS_148 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_BAUTEIL ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_BAUTEIL','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_149 ON AX_BAUTEIL(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_150 ON ax_bauteil (gml_id,beginnt);
COMMENT ON TABLE  ax_bauteil        IS 'B a u t e i l';
COMMENT ON COLUMN ax_bauteil.gml_id IS 'Identifikator, global eindeutig';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_BESONDEREGEBAEUDELINIE';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_BESONDEREGEBAEUDELINIE CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_BESONDEREGEBAEUDELINIE (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	beschaffenheit		varchar2(2047),
	anlass			varchar2(2047),
	CONSTRAINT ALKIS_151 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_BESONDEREGEBAEUDELINIE ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_BESONDEREGEBAEUDELINIE','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_152 ON AX_BESONDEREGEBAEUDELINIE(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_153 ON ax_besonderegebaeudelinie (gml_id,beginnt);
COMMENT ON TABLE ax_besonderegebaeudelinie IS 'B e s o n d e r e   G e b ä u d e l i n i e';
COMMENT ON COLUMN ax_besonderegebaeudelinie.gml_id IS 'Identifikator, global eindeutig';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_FIRSTLINIE';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_FIRSTLINIE CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_FIRSTLINIE (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	sonstigesmodell		varchar2(2047),
	anlass			varchar2(2047),
	art			varchar2(2047),
	uri			varchar2(2047),
	CONSTRAINT ALKIS_154 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_FIRSTLINIE ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_FIRSTLINIE','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_155 ON AX_FIRSTLINIE(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_156 ON ax_firstlinie (gml_id,beginnt);
COMMENT ON TABLE  ax_firstlinie        IS 'F i r s t l i n i e';
COMMENT ON COLUMN ax_firstlinie.gml_id IS 'Identifikator, global eindeutig';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_BESONDERERGEBAEUDEPUNKT';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_BESONDERERGEBAEUDEPUNKT CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_BESONDERERGEBAEUDEPUNKT (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	land			integer,
	stelle			integer,
	punktkennung		varchar2(2047),
	art			varchar2(2047),
	name			varchar2(2047),
	sonstigeeigenschaft 	varchar2(2047),
	CONSTRAINT ALKIS_157 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_BESONDERERGEBAEUDEPUNKT ADD DUMMY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_BESONDERERGEBAEUDEPUNKT','DUMMY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE UNIQUE INDEX ALKIS_158 ON ax_besonderergebaeudepunkt (gml_id,beginnt);
COMMENT ON TABLE  ax_besonderergebaeudepunkt        IS 'B e s o n d e r e r   G e b ä u d e p u n k t';
COMMENT ON COLUMN ax_besonderergebaeudepunkt.gml_id IS 'Identifikator, global eindeutig';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_WOHNBAUFLAECHE';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_WOHNBAUFLAECHE CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_WOHNBAUFLAECHE (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	artderbebauung		integer,
	zustand			integer,
	name			varchar2(2047),
	CONSTRAINT ALKIS_159 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_WOHNBAUFLAECHE ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_WOHNBAUFLAECHE','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_160 ON AX_WOHNBAUFLAECHE(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_161 ON ax_wohnbauflaeche (gml_id,beginnt);
COMMENT ON TABLE  ax_wohnbauflaeche                 IS 'W o h n b a u f l ä c h e  ist eine baulich geprägte Fläche einschließlich der mit ihr im Zusammenhang stehenden Freiflächen (z.B. Vorgärten, Ziergärten, Zufahrten, Stellplätze und Hofraumflächen), die ausschließlich oder vorwiegend dem Wohnen dient.';
COMMENT ON COLUMN ax_wohnbauflaeche.gml_id          IS 'Identifikator, global eindeutig';
COMMENT ON COLUMN ax_wohnbauflaeche.artderbebauung  IS 'BEB "Art der Bebauung" differenziert nach offener und geschlossener Bauweise aus topographischer Sicht und nicht nach gesetzlichen Vorgaben (z.B. BauGB).';
COMMENT ON COLUMN ax_wohnbauflaeche.zustand         IS 'ZUS "Zustand" beschreibt, ob "Wohnbaufläche" ungenutzt ist oder ob eine Fläche als Wohnbaufläche genutzt werden soll.';
COMMENT ON COLUMN ax_wohnbauflaeche.name            IS 'NAM "Name" ist der Eigenname von "Wohnbaufläche" insbesondere bei Objekten außerhalb von Ortslagen.';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_INDUSTRIEUNDGEWERBEFLAECHE';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_INDUSTRIEUNDGEWERBEFLAECHE CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_INDUSTRIEUNDGEWERBEFLAECHE (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	funktion		integer,
	name			varchar2(2047),
	zustand			integer,
	foerdergut		integer,
	primaerenergie		integer,
	lagergut		integer,
	CONSTRAINT ALKIS_162 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_INDUSTRIEUNDGEWERBEFLAECHE ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_INDUSTRIEUNDGEWERBEFLAECHE','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_163 ON AX_INDUSTRIEUNDGEWERBEFLAECHE(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_164 ON ax_industrieundgewerbeflaeche (gml_id,beginnt);
COMMENT ON TABLE  ax_industrieundgewerbeflaeche            IS 'I n d u s t r i e -   u n d   G e w e r b e f l ä c h e';
COMMENT ON COLUMN ax_industrieundgewerbeflaeche.gml_id     IS 'Identifikator, global eindeutig';
COMMENT ON COLUMN ax_industrieundgewerbeflaeche.name       IS 'NAM "Name" ist der Eigenname von "Industrie- und Gewerbefläche" insbesondere außerhalb von Ortslagen.';
COMMENT ON COLUMN ax_industrieundgewerbeflaeche.zustand    IS 'ZUS "Zustand" beschreibt die Betriebsbereitschaft von "Industrie- und Gewerbefläche".';
COMMENT ON COLUMN ax_industrieundgewerbeflaeche.funktion   IS 'FKT "Funktion" ist die zum Zeitpunkt der Erhebung vorherrschende Nutzung von "Industrie- und Gewerbefläche".';
COMMENT ON COLUMN ax_industrieundgewerbeflaeche.foerdergut IS 'FGT "Fördergut" gibt an, welches Produkt gefördert wird.';
COMMENT ON COLUMN ax_industrieundgewerbeflaeche.lagergut   IS 'LGT "Lagergut" gibt an, welches Produkt gelagert wird. Diese Attributart kann nur in Verbindung mit der Attributart "Funktion" und der Werteart 1740 vorkommen.';
COMMENT ON COLUMN ax_industrieundgewerbeflaeche.primaerenergie IS 'PEG "Primärenergie" beschreibt die zur Strom- oder Wärmeerzeugung dienende Energieform oder den Energieträger.';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_HALDE';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_HALDE CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_HALDE
(	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	lagergut		integer,
	name			varchar2(2047),
	zustand			integer,
	CONSTRAINT ALKIS_165 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_HALDE ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_HALDE','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_166 ON AX_HALDE(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_167 ON ax_halde (gml_id,beginnt);
COMMENT ON TABLE ax_halde             IS 'H a l d e';
COMMENT ON COLUMN ax_halde.gml_id     IS 'Identifikator, global eindeutig';
COMMENT ON COLUMN ax_halde.name       IS 'NAM "Name" ist die einer "Halde" zugehörige Bezeichnung oder deren Eigenname.';
COMMENT ON COLUMN ax_halde.lagergut   IS 'LGT "Lagergut" gibt an, welches Produkt gelagert wird.';
COMMENT ON COLUMN ax_halde.zustand    IS 'ZUS "Zustand" beschreibt die Betriebsbereitschaft von "Halde".';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_BERGBAUBETRIEB';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_BERGBAUBETRIEB CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_BERGBAUBETRIEB (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	abbaugut		integer,
	name			varchar2(2047),
	bezeichnung		varchar2(2047),
	zustand			integer,
	CONSTRAINT ALKIS_168 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_BERGBAUBETRIEB ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_BERGBAUBETRIEB','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_169 ON AX_BERGBAUBETRIEB(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_170 ON ax_bergbaubetrieb (gml_id,beginnt);
COMMENT ON TABLE  ax_bergbaubetrieb             IS '"Bergbaubetrieb" ist eine Fläche, die für die Förderung des Abbaugutes unter Tage genutzt wird.';
COMMENT ON COLUMN ax_bergbaubetrieb.gml_id      IS 'Identifikator, global eindeutig';
COMMENT ON COLUMN ax_bergbaubetrieb.abbaugut    IS 'AGT "Abbaugut" gibt an, welches Material abgebaut wird.';
COMMENT ON COLUMN ax_bergbaubetrieb.name        IS 'NAM "Name" ist der Eigenname von "Bergbaubetrieb".';
COMMENT ON COLUMN ax_bergbaubetrieb.zustand     IS 'ZUS "Zustand" beschreibt die Betriebsbereitschaft von "Bergbaubetrieb".';
COMMENT ON COLUMN ax_bergbaubetrieb.bezeichnung IS 'BEZ "Bezeichnung" ist die von einer Fachstelle vergebene Kurzbezeichnung.';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_TAGEBAUGRUBESTEINBRUCH';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_TAGEBAUGRUBESTEINBRUCH CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_TAGEBAUGRUBESTEINBRUCH (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	abbaugut		integer,
	name			varchar2(2047),
	zustand			integer,
	CONSTRAINT ALKIS_171 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_TAGEBAUGRUBESTEINBRUCH ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_TAGEBAUGRUBESTEINBRUCH','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_172 ON AX_TAGEBAUGRUBESTEINBRUCH(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_173 ON ax_tagebaugrubesteinbruch (gml_id,beginnt);
COMMENT ON TABLE  ax_tagebaugrubesteinbruch          IS '"T a g e b a u ,  G r u b e ,  S t e i n b r u c h"  ist eine Fläche, auf der oberirdisch Bodenmaterial abgebaut wird. Rekultivierte Tagebaue, Gruben, Steinbrüche werden als Objekte entsprechend der vorhandenen Nutzung erfasst.';
COMMENT ON COLUMN ax_tagebaugrubesteinbruch.gml_id   IS 'Identifikator, global eindeutig';
COMMENT ON COLUMN ax_tagebaugrubesteinbruch.name     IS 'NAM "Name" ist der Eigenname von "Tagebau, Grube, Steinbruch".';
COMMENT ON COLUMN ax_tagebaugrubesteinbruch.abbaugut IS 'AGT "Abbaugut" gibt an, welches Material abgebaut wird.';
COMMENT ON COLUMN ax_tagebaugrubesteinbruch.zustand  IS 'ZUS "Zustand" beschreibt die Betriebsbereitschaft von "Tagebau, Grube, Steinbruch".';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_FLAECHEGEMISCHTERNUTZUNG';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_FLAECHEGEMISCHTERNUTZUNG CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_FLAECHEGEMISCHTERNUTZUNG (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	artderbebauung		integer,
	funktion		integer,
	name			varchar2(2047),
	zustand			integer,
	CONSTRAINT ALKIS_174 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_FLAECHEGEMISCHTERNUTZUNG ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_FLAECHEGEMISCHTERNUTZUNG','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_175 ON AX_FLAECHEGEMISCHTERNUTZUNG(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_176 ON ax_flaechegemischternutzung (gml_id,beginnt);
COMMENT ON TABLE  ax_flaechegemischternutzung        IS '"Fläche gemischter Nutzung" ist eine bebaute Fläche einschließlich der mit ihr im Zusammenhang stehenden Freifläche (Hofraumfläche, Hausgarten), auf der keine Art der baulichen Nutzung vorherrscht. Solche Flächen sind insbesondere ländlich-dörflich geprägte Flächen mit land- und forstwirtschaftlichen Betrieben, Wohngebäuden u.a. sowie städtisch geprägte Kerngebiete mit Handelsbetrieben und zentralen Einrichtungen für die Wirtschaft und die Verwaltung.';
COMMENT ON COLUMN ax_flaechegemischternutzung.gml_id IS 'Identifikator, global eindeutig';
COMMENT ON COLUMN ax_flaechegemischternutzung.artderbebauung IS 'BEB "Art der Bebauung" differenziert nach offener und geschlossener Bauweise aus topographischer Sicht und nicht nach gesetzlichen Vorgaben (z.B. BauGB).';
COMMENT ON COLUMN ax_flaechegemischternutzung.funktion       IS 'FKT "Funktion" ist die zum Zeitpunkt der Erhebung vorherrschende Nutzung (Dominanzprinzip).';
COMMENT ON COLUMN ax_flaechegemischternutzung.name           IS 'NAM "Name" ist der Eigenname von "Fläche gemischter Nutzung" insbesondere bei Objekten außerhalb von Ortslagen.';
COMMENT ON COLUMN ax_flaechegemischternutzung.zustand        IS 'ZUS "Zustand" beschreibt, ob "Fläche gemischter Nutzung" ungenutzt ist.';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_FLAECHEBESONDERERFUNKTIONAL';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_FLAECHEBESONDERERFUNKTIONAL CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_FLAECHEBESONDERERFUNKTIONAL (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	funktion		integer,
	artderbebauung		integer,
	name			varchar2(2047),
	zustand			integer,
	CONSTRAINT ALKIS_177 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_FLAECHEBESONDERERFUNKTIONAL ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_FLAECHEBESONDERERFUNKTIONAL','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_178 ON AX_FLAECHEBESONDERERFUNKTIONAL(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_179 ON AX_FLAECHEBESONDERERFUNKTIONAL (gml_id,beginnt);
COMMENT ON TABLE  AX_FLAECHEBESONDERERFUNKTIONAL        IS '"Fläche besonderer funktionaler Prägung" ist eine baulich geprägte Fläche einschließlich der mit ihr im Zusammenhang stehenden Freifläche, auf denen vorwiegend Gebäude und/oder Anlagen zur Erfüllung öffentlicher Zwecke oder historische Anlagen vorhanden sind.';
COMMENT ON COLUMN AX_FLAECHEBESONDERERFUNKTIONAL.gml_id IS 'Identifikator, global eindeutig';
COMMENT ON COLUMN AX_FLAECHEBESONDERERFUNKTIONAL.funktion       IS 'FKT "Funktion" ist die zum Zeitpunkt der Erhebung vorherrschende Nutzung von "Fläche besonderer funktionaler Prägung".';
COMMENT ON COLUMN AX_FLAECHEBESONDERERFUNKTIONAL.artderbebauung IS 'BEB "Art der Bebauung" differenziert nach offener und geschlossener Bauweise aus topographischer Sicht und nicht nach gesetzlichen Vorgaben (z.B. BauGB).';
COMMENT ON COLUMN AX_FLAECHEBESONDERERFUNKTIONAL.name           IS 'NAM "Name" ist der Eigenname von "Fläche besonderer funktionaler Prägung" insbesondere außerhalb von Ortslagen.';
COMMENT ON COLUMN AX_FLAECHEBESONDERERFUNKTIONAL.zustand        IS 'ZUS  "Zustand" beschreibt die Betriebsbereitschaft von "Fläche funktionaler Prägung".';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_SPORTFREIZEITUNDERHOLUNGSFL';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_SPORTFREIZEITUNDERHOLUNGSFL CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_SPORTFREIZEITUNDERHOLUNGSFL (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	funktion		integer,
	zustand			integer,
	name			varchar2(2047),
	CONSTRAINT ALKIS_180 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_SPORTFREIZEITUNDERHOLUNGSFL ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_SPORTFREIZEITUNDERHOLUNGSFL','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_181 ON AX_SPORTFREIZEITUNDERHOLUNGSFL(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_182 ON AX_SPORTFREIZEITUNDERHOLUNGSFL (gml_id,beginnt);
COMMENT ON TABLE  AX_SPORTFREIZEITUNDERHOLUNGSFL          IS '"Sport-, Freizeit- und Erhohlungsfläche" ist eine bebaute oder unbebaute Fläche, die dem Sport, der Freizeitgestaltung oder der Erholung dient.';
COMMENT ON COLUMN AX_SPORTFREIZEITUNDERHOLUNGSFL.gml_id   IS 'Identifikator, global eindeutig';
COMMENT ON COLUMN AX_SPORTFREIZEITUNDERHOLUNGSFL.funktion IS 'FKT "Funktion" ist die Art der Nutzung von "Sport-, Freizeit- und Erholungsfläche".';
COMMENT ON COLUMN AX_SPORTFREIZEITUNDERHOLUNGSFL.zustand  IS 'ZUS "Zustand" beschreibt die Betriebsbereitschaft von "SPORTFREIZEITUNDERHOLUNGSFLAEC ".';
COMMENT ON COLUMN AX_SPORTFREIZEITUNDERHOLUNGSFL.name     IS 'NAM "Name" ist der Eigenname von "Sport-, Freizeit- und Erholungsfläche".';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_FRIEDHOF';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_FRIEDHOF CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_FRIEDHOF (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	funktion		integer,
	name			varchar2(2047),
	zustand			integer,
	CONSTRAINT ALKIS_183 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_FRIEDHOF ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_FRIEDHOF','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_184 ON AX_FRIEDHOF(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_185 ON ax_friedhof (gml_id,beginnt);
COMMENT ON TABLE  ax_friedhof           IS '"F r i e d h o f"  ist eine Fläche, auf der Tote bestattet sind.';
COMMENT ON COLUMN ax_friedhof.gml_id    IS 'Identifikator, global eindeutig';
COMMENT ON COLUMN ax_friedhof.funktion  IS 'FKT "Funktion" ist die Art der Begräbnisstätte.';
COMMENT ON COLUMN ax_friedhof.name      IS 'NAM "Name" ist der Eigenname von "Friedhof".';
COMMENT ON COLUMN ax_friedhof.zustand   IS 'ZUS "Zustand" beschreibt die Betriebsbereitschaft von "Friedhof".';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_STRASSENVERKEHR';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_STRASSENVERKEHR CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_STRASSENVERKEHR (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	funktion		integer,
	name			varchar2(2047),
	zweitname		varchar2(2047),
	zustand			integer,
	land			integer,
	regierungsbezirk	integer,
	kreis			integer,
	gemeinde		integer,
	lage			varchar2(2047),
	CONSTRAINT ALKIS_186 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_STRASSENVERKEHR ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_STRASSENVERKEHR','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_187 ON AX_STRASSENVERKEHR(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_188 ON ax_strassenverkehr (gml_id,beginnt);
COMMENT ON TABLE  ax_strassenverkehr           IS '"S t r a s s e n v e r k e h r" umfasst alle für die bauliche Anlage Straße erforderlichen sowie dem Straßenverkehr dienenden bebauten und unbebauten Flächen.';
COMMENT ON COLUMN ax_strassenverkehr.gml_id    IS 'Identifikator, global eindeutig';
COMMENT ON COLUMN ax_strassenverkehr.funktion  IS 'FKT "Funktion" beschreibt die verkehrliche Nutzung von "Straßenverkehr".';
COMMENT ON COLUMN ax_strassenverkehr.name      IS 'NAM "Name" ist der Eigenname von "Strassenverkehr".';
COMMENT ON COLUMN ax_strassenverkehr.zweitname IS 'ZNM "Zweitname" ist ein von der Lagebezeichnung abweichender Name von "Strassenverkehrsflaeche" (z.B. "Deutsche Weinstraße").';
COMMENT ON COLUMN ax_strassenverkehr.zustand   IS 'ZUS "Zustand" beschreibt die Betriebsbereitschaft von "Strassenverkehrsflaeche".';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_WEG';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_WEG CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_WEG (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	funktion		integer,
	name			varchar2(2047),
	bezeichnung		varchar2(2047),
	land			integer,
	regierungsbezirk	integer,
	kreis			integer,
	gemeinde		integer,
	lage			varchar2(2047),
	CONSTRAINT ALKIS_189 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_WEG ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_WEG','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_190 ON AX_WEG(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_191 ON ax_weg (gml_id,beginnt);
COMMENT ON TABLE  ax_weg              IS '"W e g" umfasst alle Flächen, die zum Befahren und/oder Begehen vorgesehen sind. Zum "Weg" gehören auch Seitenstreifen und Gräben zur Wegentwässerung.';
COMMENT ON COLUMN ax_weg.gml_id       IS 'Identifikator, global eindeutig';
COMMENT ON COLUMN ax_weg.funktion     IS 'FKT "Funktion" ist die zum Zeitpunkt der Erhebung objektiv erkennbare oder feststellbare vorherrschend vorkommende Nutzung.';
COMMENT ON COLUMN ax_weg.name         IS 'NAM "Name" ist die Bezeichnung oder der Eigenname von "Wegflaeche".';
COMMENT ON COLUMN ax_weg.bezeichnung  IS 'BEZ "Bezeichnung" ist die amtliche Nummer des Weges.';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_PLATZ';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_PLATZ CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_PLATZ (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	funktion		integer,
	name			varchar2(2047),
	zweitname		varchar2(2047),
	land			integer,
	regierungsbezirk	integer,
	kreis			integer,
	gemeinde		integer,
	lage			varchar2(2047),
	CONSTRAINT ALKIS_192 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_PLATZ ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_PLATZ','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_193 ON AX_PLATZ(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_194 ON ax_platz (gml_id,beginnt);
COMMENT ON TABLE  ax_platz           IS 'P l a t z   ist eine Verkehrsfläche in Ortschaften oder eine ebene, befestigte oder unbefestigte Fläche, die bestimmten Zwecken dient (z. B. für Verkehr, Märkte, Festveranstaltungen).';
COMMENT ON COLUMN ax_platz.gml_id    IS 'Identifikator, global eindeutig';
COMMENT ON COLUMN ax_platz.funktion  IS 'FKT "Funktion" ist die zum Zeitpunkt der Erhebung objektiv erkennbare oder feststellbare vorkommende Nutzung.';
COMMENT ON COLUMN ax_platz.name      IS 'NAM "Name" ist der Eigenname von "Platz".';
COMMENT ON COLUMN ax_platz.zweitname IS 'ZNM "Zweitname" ist der touristische oder volkstümliche Name von "Platz".';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_BAHNVERKEHR';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_BAHNVERKEHR CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_BAHNVERKEHR (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	funktion		integer,
	bahnkategorie		integer,
	bezeichnung		varchar2(2047),
	nummerderbahnstrecke	varchar2(2047),
	zweitname		varchar2(2047),
	zustand			integer,
	CONSTRAINT ALKIS_195 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_BAHNVERKEHR ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_BAHNVERKEHR','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_196 ON AX_BAHNVERKEHR(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_197 ON ax_bahnverkehr (gml_id,beginnt);
COMMENT ON TABLE  ax_bahnverkehr        IS '"B a h n v e r k e h r"  umfasst alle für den Schienenverkehr erforderlichen Flächen.';
COMMENT ON COLUMN ax_bahnverkehr.gml_id               IS 'Identifikator, global eindeutig';
COMMENT ON COLUMN ax_bahnverkehr.funktion             IS 'FKT "Funktion" ist die objektiv feststellbare Nutzung von "Bahnverkehr".';
COMMENT ON COLUMN ax_bahnverkehr.bahnkategorie        IS 'BKT "Bahnkategorie" beschreibt die Art des Verkehrsmittels.';
COMMENT ON COLUMN ax_bahnverkehr.bezeichnung          IS 'BEZ "Bezeichnung" ist die Angabe der Orte, in denen die Bahnlinie beginnt und endet (z. B. "Bahnlinie Frankfurt - Würzburg").';
COMMENT ON COLUMN ax_bahnverkehr.nummerderbahnstrecke IS 'NRB "Nummer der Bahnstrecke" ist die von der Bahn AG festgelegte Verschlüsselung der Bahnstrecke.';
COMMENT ON COLUMN ax_bahnverkehr.zweitname            IS 'ZNM "Zweitname" ist der von der Lagebezeichnung abweichende Name von "Bahnverkehr" (z. B. "Höllentalbahn").';
COMMENT ON COLUMN ax_bahnverkehr.zustand              IS 'ZUS "Zustand" beschreibt die Betriebsbereitschaft von "Bahnverkehr".';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_FLUGVERKEHR';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_FLUGVERKEHR CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_FLUGVERKEHR (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	funktion 		integer,
	art			integer,
	name			varchar2(2047),
	bezeichnung		varchar2(2047),
	nutzung			integer,
	zustand			integer,
	CONSTRAINT ALKIS_198 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_FLUGVERKEHR ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_FLUGVERKEHR','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_199 ON AX_FLUGVERKEHR(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_200 ON ax_flugverkehr (gml_id,beginnt);
COMMENT ON TABLE  ax_flugverkehr             IS '"F l u g v e r k e h r"  umfasst die baulich geprägte Fläche und die mit ihr in Zusammenhang stehende Freifläche, die ausschließlich oder vorwiegend dem Flugverkehr dient.';
COMMENT ON COLUMN ax_flugverkehr.gml_id      IS 'Identifikator, global eindeutig';
COMMENT ON COLUMN ax_flugverkehr.funktion    IS 'FKT "Funktion" ist die zum Zeitpunkt der Erhebung vorherrschende Nutzung (Dominanzprinzip).';
COMMENT ON COLUMN ax_flugverkehr.art         IS 'ART "Art" ist Einstufung der Flugverkehrsfläche durch das Luftfahrtbundesamt.';
COMMENT ON COLUMN ax_flugverkehr.name        IS 'NAM "Name" ist der Eigenname von "Flugverkehr".';
COMMENT ON COLUMN ax_flugverkehr.bezeichnung IS 'BEZ "Bezeichnung" ist die von einer Fachstelle vergebene Kennziffer von "Flugverkehr".';
COMMENT ON COLUMN ax_flugverkehr.nutzung     IS 'NTZ "Nutzung" gibt den Nutzerkreis von "Flugverkehr" an.';
COMMENT ON COLUMN ax_flugverkehr.zustand     IS 'ZUS "Zustand" beschreibt die Betriebsbereitschaft von "Flugverkehr".';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_SCHIFFSVERKEHR';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_SCHIFFSVERKEHR CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_SCHIFFSVERKEHR (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	funktion		integer,
	name			varchar2(2047),
	zustand			integer,
	CONSTRAINT ALKIS_201 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_SCHIFFSVERKEHR ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_SCHIFFSVERKEHR','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_202 ON AX_SCHIFFSVERKEHR(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_203 ON ax_schiffsverkehr (gml_id,beginnt);
COMMENT ON TABLE  ax_schiffsverkehr          IS '"S c h i f f s v e r k e h r"  umfasst die baulich geprägte Fläche und die mit ihr in Zusammenhang stehende Freifläche, die ausschließlich oder vorwiegend dem Schiffsverkehr dient.';
COMMENT ON COLUMN ax_schiffsverkehr.gml_id   IS 'Identifikator, global eindeutig';
COMMENT ON COLUMN ax_schiffsverkehr.funktion IS 'FKT "Funktion" ist die zum Zeitpunkt der Erhebung vorherrschende Nutzung von "Schiffsverkehr".';
COMMENT ON COLUMN ax_schiffsverkehr.name     IS 'NAM "Name" ist der Eigenname von "Schiffsverkehr".';
COMMENT ON COLUMN ax_schiffsverkehr.zustand  IS 'ZUS "Zustand" beschreibt die Betriebsbereitschaft von "Schiffsverkehr".';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_LANDWIRTSCHAFT';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_LANDWIRTSCHAFT CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_LANDWIRTSCHAFT (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	vegetationsmerkmal	integer,
	name			varchar2(2047),
	CONSTRAINT ALKIS_204 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_LANDWIRTSCHAFT ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_LANDWIRTSCHAFT','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_205 ON AX_LANDWIRTSCHAFT(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_206 ON ax_landwirtschaft (gml_id,beginnt);
COMMENT ON TABLE  ax_landwirtschaft                    IS '"L a n d w i r t s c h a f t"  ist eine Fläche für den Anbau von Feldfrüchten sowie eine Fläche, die beweidet und gemäht werden kann, einschließlich der mit besonderen Pflanzen angebauten Fläche. Die Brache, die für einen bestimmten Zeitraum (z. B. ein halbes oder ganzes Jahr) landwirtschaftlich unbebaut bleibt, ist als "Landwirtschaft" bzw. "Ackerland" zu erfassen';
COMMENT ON COLUMN ax_landwirtschaft.gml_id             IS 'Identifikator, global eindeutig';
COMMENT ON COLUMN ax_landwirtschaft.vegetationsmerkmal IS 'VEG "Vegetationsmerkmal" ist die zum Zeitpunkt der Erhebung erkennbare oder feststellbare vorherrschend vorkommende landwirtschaftliche Nutzung (Dominanzprinzip).';
COMMENT ON COLUMN ax_landwirtschaft.name               IS 'NAM "Name" ist die Bezeichnung oder der Eigenname von "Landwirtschaft".';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_WALD';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_WALD CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_WALD (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	vegetationsmerkmal	integer,
	name			varchar2(2047),
	bezeichnung		varchar2(2047),
	CONSTRAINT ALKIS_207 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_WALD ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_WALD','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_208 ON AX_WALD(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_209 ON ax_wald (gml_id,beginnt);
COMMENT ON TABLE  ax_wald             IS '"W a l d" ist eine Fläche, die mit Forstpflanzen (Waldbäume und Waldsträucher) bestockt ist.';
COMMENT ON COLUMN ax_wald.gml_id      IS 'Identifikator, global eindeutig';
COMMENT ON COLUMN ax_wald.vegetationsmerkmal IS 'VEG "Vegetationsmerkmal" beschreibt den Bewuchs von "Wald".';
COMMENT ON COLUMN ax_wald.name        IS 'NAM "Name" ist der Eigenname von "Wald".';
COMMENT ON COLUMN ax_wald.bezeichnung IS 'BEZ "Bezeichnung" ist die von einer Fachstelle vergebene Kennziffer (Forstabteilungsnummer, Jagenzahl) von "Wald".';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_GEHOELZ';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_GEHOELZ CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_GEHOELZ (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	anlass 			varchar2(2047),
	vegetationsmerkmal	integer,
	name			varchar2(2047),
	funktion		integer,
	CONSTRAINT ALKIS_210 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_GEHOELZ ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_GEHOELZ','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_211 ON AX_GEHOELZ(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_212 ON ax_gehoelz (gml_id,beginnt);
COMMENT ON TABLE  ax_gehoelz        IS '"G e h ö l z" ist eine Fläche, die mit einzelnen Bäumen, Baumgruppen, Büschen, Hecken und Sträuchern bestockt ist.';
COMMENT ON COLUMN ax_gehoelz.gml_id IS 'Identifikator, global eindeutig';
COMMENT ON COLUMN ax_gehoelz.vegetationsmerkmal IS 'VEG "Vegetationsmerkmal" beschreibt den Bewuchs von "Gehölz".';
COMMENT ON COLUMN ax_gehoelz.name               IS 'NAM "Name" ist der Eigenname von "Wald".';
COMMENT ON COLUMN ax_gehoelz.funktion           IS 'FKT "Funktion" beschreibt, welchem Zweck "Gehölz" dient.';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_HEIDE';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_HEIDE CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_HEIDE (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	name			varchar2(2047),
	CONSTRAINT ALKIS_213 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_HEIDE ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_HEIDE','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_214 ON AX_HEIDE(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_215 ON ax_heide (gml_id,beginnt);
COMMENT ON TABLE  ax_heide        IS '"H e i d e"  ist eine meist sandige Fläche mit typischen Sträuchern, Gräsern und geringwertigem Baumbestand.';
COMMENT ON COLUMN ax_heide.gml_id IS 'Identifikator, global eindeutig';
COMMENT ON COLUMN ax_heide.name   IS 'NAM "Name" ist der Eigenname von "Heide".';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_MOOR';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_MOOR CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_MOOR (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	name			varchar2(2047),
	CONSTRAINT ALKIS_216 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_MOOR ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_MOOR','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_217 ON AX_MOOR(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_218 ON ax_moor (gml_id,beginnt);
COMMENT ON TABLE  ax_moor        IS '"M o o r"  ist eine unkultivierte Fläche, deren obere Schicht aus vertorften oder zersetzten Pflanzenresten besteht.';
COMMENT ON COLUMN ax_moor.gml_id IS 'Identifikator, global eindeutig';
COMMENT ON COLUMN ax_moor.name IS 'NAM "Name" ist der Eigenname von "Moor".';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_SUMPF';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_SUMPF CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_SUMPF (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	name			varchar2(2047),
	CONSTRAINT ALKIS_219 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_SUMPF ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_SUMPF','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_220 ON AX_SUMPF(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_221 ON ax_sumpf (gml_id,beginnt);
COMMENT ON TABLE  ax_sumpf        IS '"S u m p f" ist ein wassergesättigtes, zeitweise unter Wasser stehendes Gelände. Nach Regenfällen kurzzeitig nasse Stellen im Boden werden nicht als "Sumpf" erfasst.';
COMMENT ON COLUMN ax_sumpf.gml_id IS 'Identifikator, global eindeutig';
COMMENT ON COLUMN ax_sumpf.name   IS 'NAM "Name" ist der Eigenname von "Sumpf".';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_UNLANDVEGETATIONSLOSEFLAECH';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_UNLANDVEGETATIONSLOSEFLAECH CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_UNLANDVEGETATIONSLOSEFLAECH (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	oberflaechenmaterial	integer,
	name			varchar2(2047),
	funktion		integer,
	CONSTRAINT ALKIS_222 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_UNLANDVEGETATIONSLOSEFLAECH ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_UNLANDVEGETATIONSLOSEFLAECH','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_223 ON AX_UNLANDVEGETATIONSLOSEFLAECH(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_224 ON AX_UNLANDVEGETATIONSLOSEFLAECH (gml_id,beginnt);
COMMENT ON TABLE  AX_UNLANDVEGETATIONSLOSEFLAECH        IS '"Unland/Vegetationslose Fläche" ist eine Fläche, die dauerhaft landwirtschaftlich nicht genutzt wird, wie z.B. nicht aus dem Geländerelief herausragende Felspartien, Sand- oder Eisflächen, Uferstreifen längs von Gewässern und Sukzessionsflächen.';
COMMENT ON COLUMN AX_UNLANDVEGETATIONSLOSEFLAECH.gml_id IS 'Identifikator, global eindeutig';
COMMENT ON COLUMN AX_UNLANDVEGETATIONSLOSEFLAECH.oberflaechenmaterial IS 'OFM "Oberflächenmaterial" ist die Beschaffenheit des Bodens von "Unland/Vegetationslose Fläche".';
COMMENT ON COLUMN AX_UNLANDVEGETATIONSLOSEFLAECH.name                 IS 'NAM "Name" ist die Bezeichnung oder der Eigenname von "Unland/ VegetationsloseFlaeche".';
COMMENT ON COLUMN AX_UNLANDVEGETATIONSLOSEFLAECH.funktion             IS 'FKT "Funktion" ist die erkennbare Art von "Unland/Vegetationslose Fläche".';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_FLIESSGEWAESSER';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_FLIESSGEWAESSER CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_FLIESSGEWAESSER (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	funktion		integer,
	name			varchar2(2047),
	zustand			integer,
	CONSTRAINT ALKIS_225 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_FLIESSGEWAESSER ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_FLIESSGEWAESSER','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_226 ON AX_FLIESSGEWAESSER(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_227 ON ax_fliessgewaesser (gml_id,beginnt);
COMMENT ON TABLE  ax_fliessgewaesser          IS '"F l i e s s g e w ä s s e r" ist ein geometrisch begrenztes, oberirdisches, auf dem Festland fließendes Gewässer, das die Wassermengen sammelt, die als Niederschläge auf die Erdoberfläche fallen oder in Quellen austreten, und in ein anderes Gewässer, ein Meer oder in einen See transportiert';
COMMENT ON COLUMN ax_fliessgewaesser.gml_id   IS 'Identifikator, global eindeutig';
COMMENT ON COLUMN ax_fliessgewaesser.funktion IS 'FKT "Funktion" ist die Art von "Fließgewässer".';
COMMENT ON COLUMN ax_fliessgewaesser.name     IS 'NAM "Name" ist die Bezeichnung oder der Eigenname von "Fließgewässer".';
COMMENT ON COLUMN ax_fliessgewaesser.zustand  IS 'ZUS "Zustand" beschreibt die Betriebsbereitschaft von "Fließgewässer" mit FKT=8300 (Kanal).';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_HAFENBECKEN';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_HAFENBECKEN CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_HAFENBECKEN (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	funktion		integer,
	name			varchar2(2047),
	nutzung			integer,
	CONSTRAINT ALKIS_228 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_HAFENBECKEN ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_HAFENBECKEN','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_229 ON AX_HAFENBECKEN(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_230 ON ax_hafenbecken (gml_id,beginnt);
COMMENT ON TABLE  ax_hafenbecken        IS '"H a f e n b e c k e n"  ist ein natürlicher oder künstlich angelegter oder abgetrennter Teil eines Gewässers, in dem Schiffe be- und entladen werden.';
COMMENT ON COLUMN ax_hafenbecken.gml_id IS 'Identifikator, global eindeutig';
COMMENT ON COLUMN ax_hafenbecken.funktion IS 'FKT "Funktion" ist die objektiv erkennbare Nutzung von "Hafenbecken".';
COMMENT ON COLUMN ax_hafenbecken.name     IS 'NAM "Name" ist der Eigenname von "Hafenbecken".';
COMMENT ON COLUMN ax_hafenbecken.nutzung  IS 'NTZ "Nutzung" gibt den Nutzerkreis von "Hafenbecken" an.';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_STEHENDESGEWAESSER';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_STEHENDESGEWAESSER CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_STEHENDESGEWAESSER (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	funktion		integer,
	name			varchar2(2047),
	gewaesserkennziffer	varchar2(2047),
	hydrologischesMerkmal	integer,
	CONSTRAINT ALKIS_231 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_STEHENDESGEWAESSER ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_STEHENDESGEWAESSER','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_232 ON AX_STEHENDESGEWAESSER(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_233 ON ax_stehendesgewaesser (gml_id,beginnt);
COMMENT ON TABLE  ax_stehendesgewaesser           IS 's t e h e n d e s   G e w ä s s e r  ist eine natürliche oder künstliche mit Wasser gefüllte, allseitig umschlossene Hohlform der Landoberfläche ohne unmittelbaren Zusammenhang mit "Meer".';
COMMENT ON COLUMN ax_stehendesgewaesser.gml_id    IS 'Identifikator, global eindeutig';
COMMENT ON COLUMN ax_stehendesgewaesser.funktion  IS 'FKT "Funktion" ist die Art von "Stehendes Gewässer".';
COMMENT ON COLUMN ax_stehendesgewaesser.name      IS 'NAM "Name" ist der Eigenname von "Stehendes Gewässer".';
COMMENT ON COLUMN ax_stehendesgewaesser.gewaesserkennziffer   IS 'GWK  "Gewässerkennziffer" ist die von der zuständigen Fachstelle vergebene Verschlüsselung.';
COMMENT ON COLUMN ax_stehendesgewaesser.hydrologischesMerkmal IS 'HYD  "Hydrologisches Merkmal" gibt die Wasserverhältnisse von "Stehendes Gewässer" an.';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_MEER';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_MEER CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_MEER (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	funktion		integer,
	name			varchar2(2047),
	bezeichnung		varchar2(2047),
	tidemerkmal		integer,
	CONSTRAINT ALKIS_234 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_MEER ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_MEER','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_235 ON AX_MEER(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_236 ON ax_meer (gml_id,beginnt);
COMMENT ON TABLE  ax_meer              IS '"M e e r" ist die das Festland umgebende Wasserfläche.';
COMMENT ON COLUMN ax_meer.gml_id       IS 'Identifikator, global eindeutig';
COMMENT ON COLUMN ax_meer.funktion     IS 'FKT "Funktion" ist die Art von "Meer".';
COMMENT ON COLUMN ax_meer.name         IS 'NAM "Name" ist der Eigenname von "Meer".';
COMMENT ON COLUMN ax_meer.bezeichnung  IS 'BEZ "Bezeichnung" ist die von der zuständigen Fachbehörde vergebene Verschlüsselung.';
COMMENT ON COLUMN ax_meer.tidemerkmal  IS 'TID "Tidemerkmal" gibt an, ob "Meer" von den periodischen Wasserstandsänderungen beeinflusst wird.';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_TURM';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_TURM CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_TURM (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	bauwerksfunktion	integer,
	zustand			integer,
	name			varchar2(2047),
	CONSTRAINT ALKIS_237 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_TURM ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_TURM','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_238 ON AX_TURM(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_239 ON ax_turm (gml_id,beginnt);
COMMENT ON TABLE  ax_turm        IS 'T u r m';
COMMENT ON COLUMN ax_turm.gml_id IS 'Identifikator, global eindeutig';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_BAUWERKODERANLAGEFUERINDUST';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_BAUWERKODERANLAGEFUERINDUST CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_BAUWERKODERANLAGEFUERINDUST (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	bauwerksfunktion	integer,
	name			varchar2(2047),
	zustand			integer,
	objekthoehe		double precision,
	CONSTRAINT ALKIS_240 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_BAUWERKODERANLAGEFUERINDUST ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_BAUWERKODERANLAGEFUERINDUST','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_241 ON AX_BAUWERKODERANLAGEFUERINDUST(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_242 ON AX_BAUWERKODERANLAGEFUERINDUST (gml_id,beginnt);
COMMENT ON TABLE AX_BAUWERKODERANLAGEFUERINDUST         IS 'Bauwerk oder Anlage fuer Industrie und Gewerbe';
COMMENT ON COLUMN AX_BAUWERKODERANLAGEFUERINDUST.gml_id IS 'Identifikator, global eindeutig';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_VORRATSBEHAELTERSPEICHERBAU';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_VORRATSBEHAELTERSPEICHERBAU CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_VORRATSBEHAELTERSPEICHERBAU (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	speicherinhalt		integer,
	bauwerksfunktion	integer,
	lagezurerdoberflaeche   integer,
	name			varchar2(2047),
	CONSTRAINT ALKIS_243 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_VORRATSBEHAELTERSPEICHERBAU ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_VORRATSBEHAELTERSPEICHERBAU','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_244 ON AX_VORRATSBEHAELTERSPEICHERBAU(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_245 ON AX_VORRATSBEHAELTERSPEICHERBAU (gml_id,beginnt);
COMMENT ON TABLE  AX_VORRATSBEHAELTERSPEICHERBAU        IS 'V o r r a t s b e h ä l t e r  /  S p e i c h e r b a u w e r k';
COMMENT ON COLUMN AX_VORRATSBEHAELTERSPEICHERBAU.gml_id IS 'Identifikator, global eindeutig';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_TRANSPORTANLAGE';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_TRANSPORTANLAGE CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_TRANSPORTANLAGE (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	bauwerksfunktion	integer,
	lagezurerdoberflaeche	integer,
	art			varchar2(2047),
	name			varchar2(2047),
	produkt                 integer,
	CONSTRAINT ALKIS_246 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_TRANSPORTANLAGE ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_TRANSPORTANLAGE','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_247 ON AX_TRANSPORTANLAGE(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_248 ON ax_transportanlage (gml_id,beginnt);
COMMENT ON TABLE  ax_transportanlage        IS 'T r a n s p o r t a n l a g e';
COMMENT ON COLUMN ax_transportanlage.gml_id IS 'Identifikator, global eindeutig';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_LEITUNG';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_LEITUNG CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_LEITUNG (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	bauwerksfunktion	integer,
	spannungsebene		integer,
	CONSTRAINT ALKIS_249 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_LEITUNG ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_LEITUNG','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_250 ON AX_LEITUNG(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_251 ON ax_leitung (gml_id,beginnt);
COMMENT ON TABLE  ax_leitung        IS 'L e i t u n g';
COMMENT ON COLUMN ax_leitung.gml_id IS 'Identifikator, global eindeutig';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_BAUWERKODERANLAGEFUERSPORTF';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_BAUWERKODERANLAGEFUERSPORTF CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_BAUWERKODERANLAGEFUERSPORTF (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	bauwerksfunktion	integer,
	sportart		integer,
	name			varchar2(2047),
	CONSTRAINT ALKIS_252 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_BAUWERKODERANLAGEFUERSPORTF ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_BAUWERKODERANLAGEFUERSPORTF','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_253 ON AX_BAUWERKODERANLAGEFUERSPORTF(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_254 ON AX_BAUWERKODERANLAGEFUERSPORTF (gml_id,beginnt);
COMMENT ON TABLE  AX_BAUWERKODERANLAGEFUERSPORTF        IS 'Bauwerk oder Anlage fuer Sport, Freizeit und Erholung';
COMMENT ON COLUMN AX_BAUWERKODERANLAGEFUERSPORTF.gml_id IS 'Identifikator, global eindeutig';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_HISTORISCHESBAUWERKODERHIST';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_HISTORISCHESBAUWERKODERHIST CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_HISTORISCHESBAUWERKODERHIST (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	sonstigesmodell		varchar2(2047),
	anlass			varchar2(2047),
	archaeologischertyp	integer,
	name			varchar2(2047),
	CONSTRAINT ALKIS_255 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_HISTORISCHESBAUWERKODERHIST ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_HISTORISCHESBAUWERKODERHIST','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_256 ON AX_HISTORISCHESBAUWERKODERHIST(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_257 ON AX_HISTORISCHESBAUWERKODERHIST (gml_id,beginnt);
COMMENT ON TABLE  AX_HISTORISCHESBAUWERKODERHIST        IS 'Historisches Bauwerk oder historische Einrichtung';
COMMENT ON COLUMN AX_HISTORISCHESBAUWERKODERHIST.gml_id IS 'Identifikator, global eindeutig';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_HEILQUELLEGASQUELLE';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_HEILQUELLEGASQUELLE CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_HEILQUELLEGASQUELLE (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar2(2047),
	sonstigesmodell		varchar2(2047),
	anlass			varchar2(2047),
	art			integer,
	name			varchar2(2047),
	CONSTRAINT ALKIS_258 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_HEILQUELLEGASQUELLE ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_HEILQUELLEGASQUELLE','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_259 ON AX_HEILQUELLEGASQUELLE(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_260 ON ax_heilquellegasquelle (gml_id,beginnt);
COMMENT ON TABLE  ax_heilquellegasquelle        IS 'H e i l q u e l l e  /  G a s q u e l l e';
COMMENT ON COLUMN ax_heilquellegasquelle.gml_id IS 'Identifikator, global eindeutig';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_SONSTIGESBAUWERKODERSONSTIG';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_SONSTIGESBAUWERKODERSONSTIG CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_SONSTIGESBAUWERKODERSONSTIG (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	description		integer,
	name			varchar2(2047),
	bauwerksfunktion	integer,
	CONSTRAINT ALKIS_261 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_SONSTIGESBAUWERKODERSONSTIG ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_SONSTIGESBAUWERKODERSONSTIG','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_262 ON AX_SONSTIGESBAUWERKODERSONSTIG(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_263 ON AX_SONSTIGESBAUWERKODERSONSTIG (gml_id,beginnt);
COMMENT ON TABLE  AX_SONSTIGESBAUWERKODERSONSTIG        IS 'sonstiges Bauwerk oder sonstige Einrichtung';
COMMENT ON COLUMN AX_SONSTIGESBAUWERKODERSONSTIG.gml_id IS 'Identifikator, global eindeutig';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_EINRICHTUNGINOEFFENTLICHENB';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_EINRICHTUNGINOEFFENTLICHENB CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_EINRICHTUNGINOEFFENTLICHENB (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar2(2047),
	sonstigesmodell		varchar2(2047),
	anlass			varchar2(2047),
	art			integer,
	kilometerangabe         varchar2(2047),
	CONSTRAINT ALKIS_264 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_EINRICHTUNGINOEFFENTLICHENB ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_EINRICHTUNGINOEFFENTLICHENB','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_265 ON AX_EINRICHTUNGINOEFFENTLICHENB(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_266 ON AX_EINRICHTUNGINOEFFENTLICHENB (gml_id,beginnt);
COMMENT ON TABLE  AX_EINRICHTUNGINOEFFENTLICHENB        IS 'E i n r i c h t u n g   i n   Ö f f e n t l i c h e n   B e r e i c h e n';
COMMENT ON COLUMN AX_EINRICHTUNGINOEFFENTLICHENB.gml_id IS 'Identifikator, global eindeutig';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_EINRICHTUNGENFUERDENSCHIFFS';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_EINRICHTUNGENFUERDENSCHIFFS CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_EINRICHTUNGENFUERDENSCHIFFS (
	ogr_fid 		integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	art			integer,
	kilometerangabe		varchar2(2047),
	name			varchar2(2047),
	CONSTRAINT ALKIS_267 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_EINRICHTUNGENFUERDENSCHIFFS ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_EINRICHTUNGENFUERDENSCHIFFS','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_268 ON AX_EINRICHTUNGENFUERDENSCHIFFS(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_269 ON AX_EINRICHTUNGENFUERDENSCHIFFS (gml_id,beginnt);
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_BESONDERERBAUWERKSPUNKT';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_BESONDERERBAUWERKSPUNKT CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_BESONDERERBAUWERKSPUNKT (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	punktkennung		varchar2(2047),
	land			integer,
	stelle			integer,
	sonstigeeigenschaft	varchar2(2047),
	CONSTRAINT ALKIS_270 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_BESONDERERBAUWERKSPUNKT ADD DUMMY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_BESONDERERBAUWERKSPUNKT','DUMMY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE UNIQUE INDEX ALKIS_271 ON ax_besondererbauwerkspunkt (gml_id,beginnt);
COMMENT ON TABLE  ax_besondererbauwerkspunkt        IS 'B e s o n d e r e r   B a u w e r k s p u n k t';
COMMENT ON COLUMN ax_besondererbauwerkspunkt.gml_id IS 'Identifikator, global eindeutig';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_BAUWERKIMVERKEHRSBEREICH';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_BAUWERKIMVERKEHRSBEREICH CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_BAUWERKIMVERKEHRSBEREICH (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	bauwerksfunktion	integer,
	name                    varchar2(2047),
	zustand			integer,
	CONSTRAINT ALKIS_272 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_BAUWERKIMVERKEHRSBEREICH ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_BAUWERKIMVERKEHRSBEREICH','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_273 ON AX_BAUWERKIMVERKEHRSBEREICH(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_274 ON ax_bauwerkimverkehrsbereich (gml_id,beginnt);
COMMENT ON TABLE  ax_bauwerkimverkehrsbereich        IS 'B a u w e r k   i m  V e r k e h s b e r e i c h';
COMMENT ON COLUMN ax_bauwerkimverkehrsbereich.gml_id IS 'Identifikator, global eindeutig';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_STRASSENVERKEHRSANLAGE';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_STRASSENVERKEHRSANLAGE CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_STRASSENVERKEHRSANLAGE (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	sonstigesmodell		varchar2(2047),
	anlass			varchar2(2047),
	art			integer,
	bezeichnung             varchar2(2047),
	name			varchar2(2047),
	CONSTRAINT ALKIS_275 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_STRASSENVERKEHRSANLAGE ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_STRASSENVERKEHRSANLAGE','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_276 ON AX_STRASSENVERKEHRSANLAGE(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_277 ON ax_strassenverkehrsanlage (gml_id,beginnt);
COMMENT ON TABLE  ax_strassenverkehrsanlage        IS 'S t r a s s e n v e r k e h r s a n l a g e';
COMMENT ON COLUMN ax_strassenverkehrsanlage.gml_id IS 'Identifikator, global eindeutig';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_WEGPFADSTEIG';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_WEGPFADSTEIG CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_WEGPFADSTEIG (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	sonstigesmodell		varchar2(2047),
	anlass			varchar2(2047),
	art			integer,
	name			varchar2(2047),
	CONSTRAINT ALKIS_278 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_WEGPFADSTEIG ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_WEGPFADSTEIG','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_279 ON AX_WEGPFADSTEIG(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_280 ON ax_wegpfadsteig (gml_id,beginnt);
COMMENT ON TABLE  ax_wegpfadsteig        IS 'W e g  /  P f a d  /  S t e i g';
COMMENT ON COLUMN ax_wegpfadsteig.gml_id IS 'Identifikator, global eindeutig';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_BAHNVERKEHRSANLAGE';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_BAHNVERKEHRSANLAGE CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_BAHNVERKEHRSANLAGE (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	sonstigesmodell		varchar2(2047),
	anlass			varchar2(2047),
	bahnhofskategorie	integer,
	bahnkategorie		integer,
	name			varchar2(2047),
	CONSTRAINT ALKIS_281 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_BAHNVERKEHRSANLAGE ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_BAHNVERKEHRSANLAGE','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_282 ON AX_BAHNVERKEHRSANLAGE(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_283 ON ax_bahnverkehrsanlage (gml_id,beginnt);
COMMENT ON TABLE  ax_bahnverkehrsanlage        IS 'B a h n v e r k e h r s a n l a g e';
COMMENT ON COLUMN ax_bahnverkehrsanlage.gml_id IS 'Identifikator, global eindeutig';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_SEILBAHNSCHWEBEBAHN';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_SEILBAHNSCHWEBEBAHN CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_SEILBAHNSCHWEBEBAHN (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	sonstigesmodell		varchar2(2047),
	anlass			varchar2(2047),
	bahnkategorie		integer,
	name			varchar2(2047),
	CONSTRAINT ALKIS_284 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_SEILBAHNSCHWEBEBAHN ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_SEILBAHNSCHWEBEBAHN','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_285 ON AX_SEILBAHNSCHWEBEBAHN(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_286 ON ax_seilbahnschwebebahn (gml_id,beginnt);
COMMENT ON TABLE  ax_seilbahnschwebebahn        IS 'S e i l b a h n, S c h w e b e b a h n';
COMMENT ON COLUMN ax_seilbahnschwebebahn.gml_id IS 'Identifikator, global eindeutig';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_GLEIS';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_GLEIS CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_GLEIS (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	sonstigesmodell		varchar2(2047),
	anlass			varchar2(2047),
	bahnkategorie		integer,
	art			integer,
	lagezuroberflaeche      integer,
	name			varchar2(2047),
	CONSTRAINT ALKIS_287 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_GLEIS ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_GLEIS','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_288 ON AX_GLEIS(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_289 ON ax_gleis (gml_id,beginnt);
COMMENT ON TABLE  ax_gleis        IS 'G l e i s';
COMMENT ON COLUMN ax_gleis.gml_id IS 'Identifikator, global eindeutig';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_FLUGVERKEHRSANLAGE';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_FLUGVERKEHRSANLAGE CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_FLUGVERKEHRSANLAGE (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar2(2047),
	sonstigesmodell		varchar2(2047),
	anlass			varchar2(2047),
	art			integer,
	oberflaechenmaterial	integer,
	name			varchar2(2047),
	CONSTRAINT ALKIS_290 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_FLUGVERKEHRSANLAGE ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_FLUGVERKEHRSANLAGE','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_291 ON AX_FLUGVERKEHRSANLAGE(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_292 ON ax_flugverkehrsanlage (gml_id,beginnt);
COMMENT ON TABLE  ax_flugverkehrsanlage             IS 'F l u g v e r k e h r s a n l a g e';
COMMENT ON COLUMN ax_flugverkehrsanlage.gml_id      IS 'Identifikator, global eindeutig';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_BAUWERKIMGEWAESSERBEREICH';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_BAUWERKIMGEWAESSERBEREICH CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_BAUWERKIMGEWAESSERBEREICH (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	bauwerksfunktion	integer,
	name			varchar2(2047),
	zustand			integer,
	CONSTRAINT ALKIS_293 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_BAUWERKIMGEWAESSERBEREICH ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_BAUWERKIMGEWAESSERBEREICH','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_294 ON AX_BAUWERKIMGEWAESSERBEREICH(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_295 ON ax_bauwerkimgewaesserbereich (gml_id,beginnt);
COMMENT ON TABLE  ax_bauwerkimgewaesserbereich        IS 'B a u w e r k   i m   G e w ä s s e r b e r e i c h';
COMMENT ON COLUMN ax_bauwerkimgewaesserbereich.gml_id IS 'Identifikator, global eindeutig';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_VEGETATIONSMERKMAL';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_VEGETATIONSMERKMAL CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_VEGETATIONSMERKMAL (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	bewuchs			integer,
	zustand			integer,
	name			varchar2(2047),
	CONSTRAINT ALKIS_296 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_VEGETATIONSMERKMAL ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_VEGETATIONSMERKMAL','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_297 ON AX_VEGETATIONSMERKMAL(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_298 ON ax_vegetationsmerkmal (gml_id,beginnt);
COMMENT ON TABLE  ax_vegetationsmerkmal        IS 'V e g a t a t i o n s m e r k m a l';
COMMENT ON COLUMN ax_vegetationsmerkmal.gml_id IS 'Identifikator, global eindeutig';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_GEWAESSERMERKMAL';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_GEWAESSERMERKMAL CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_GEWAESSERMERKMAL (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	art			integer,
	name			varchar2(2047),
	CONSTRAINT ALKIS_299 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_GEWAESSERMERKMAL ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_GEWAESSERMERKMAL','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_300 ON AX_GEWAESSERMERKMAL(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_301 ON ax_gewaessermerkmal (gml_id,beginnt);
COMMENT ON TABLE  ax_gewaessermerkmal        IS 'G e w ä s s e r m e r k m a l';
COMMENT ON COLUMN ax_gewaessermerkmal.gml_id IS 'Identifikator, global eindeutig';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_UNTERGEORDNETESGEWAESSER';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_UNTERGEORDNETESGEWAESSER CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_UNTERGEORDNETESGEWAESSER (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	funktion		integer,
	lagezurerdoberflaeche	integer,
	hydrologischesmerkmal	integer,
	name			varchar2(2047),
	CONSTRAINT ALKIS_302 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_UNTERGEORDNETESGEWAESSER ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_UNTERGEORDNETESGEWAESSER','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_303 ON AX_UNTERGEORDNETESGEWAESSER(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_304 ON ax_untergeordnetesgewaesser (gml_id,beginnt);
COMMENT ON TABLE  ax_untergeordnetesgewaesser        IS 'u n t e r g e o r d n e t e s   G e w ä s s e r';
COMMENT ON COLUMN ax_untergeordnetesgewaesser.gml_id IS 'Identifikator, global eindeutig';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_WASSERSPIEGELHOEHE';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_WASSERSPIEGELHOEHE CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_WASSERSPIEGELHOEHE (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	hoehedeswasserspiegels	double precision,
	CONSTRAINT ALKIS_305 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_WASSERSPIEGELHOEHE ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_WASSERSPIEGELHOEHE','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_306 ON AX_WASSERSPIEGELHOEHE(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_307 ON ax_wasserspiegelhoehe (gml_id,beginnt);
COMMENT ON TABLE  ax_wasserspiegelhoehe  IS 'W a s s e r s p i e g e l h ö h e';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_SCHIFFFAHRTSLINIEFAEHRVERKE';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_SCHIFFFAHRTSLINIEFAEHRVERKE CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_SCHIFFFAHRTSLINIEFAEHRVERKE (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	art			integer,
	CONSTRAINT ALKIS_308 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_SCHIFFFAHRTSLINIEFAEHRVERKE ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_SCHIFFFAHRTSLINIEFAEHRVERKE','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_309 ON AX_SCHIFFFAHRTSLINIEFAEHRVERKE(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_310 ON AX_SCHIFFFAHRTSLINIEFAEHRVERKE (gml_id,beginnt);
COMMENT ON TABLE  AX_SCHIFFFAHRTSLINIEFAEHRVERKE  IS 'S c h i f f f a h r t s l i n i e  /  F ä h r v e r k e h r';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_BOESCHUNGKLIFF';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_BOESCHUNGKLIFF CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_BOESCHUNGKLIFF (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	sonstigesmodell		varchar2(2047),
	anlass			varchar2(2047),
	objekthoehe		double precision,
	CONSTRAINT ALKIS_311 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_BOESCHUNGKLIFF ADD DUMMY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_BOESCHUNGKLIFF','DUMMY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE UNIQUE INDEX ALKIS_312 ON ax_boeschungkliff (gml_id,beginnt);
COMMENT ON TABLE  ax_boeschungkliff        IS 'B ö s c h u n g s k l i f f';
COMMENT ON COLUMN ax_boeschungkliff.gml_id IS 'Identifikator, global eindeutig';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_BOESCHUNGSFLAECHE';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_BOESCHUNGSFLAECHE CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_BOESCHUNGSFLAECHE (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	sonstigesmodell		varchar2(2047),
	anlass			varchar2(2047),
	CONSTRAINT ALKIS_313 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_BOESCHUNGSFLAECHE ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_BOESCHUNGSFLAECHE','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_314 ON AX_BOESCHUNGSFLAECHE(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_315 ON ax_boeschungsflaeche (gml_id,beginnt);
COMMENT ON TABLE  ax_boeschungsflaeche        IS 'B ö s c h u n g s f l ä c h e';
COMMENT ON COLUMN ax_boeschungsflaeche.gml_id IS 'Identifikator, global eindeutig';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_DAMMWALLDEICH';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_DAMMWALLDEICH CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_DAMMWALLDEICH (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	art			integer,
	name			varchar2(2047),
	funktion		integer,
	CONSTRAINT ALKIS_316 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_DAMMWALLDEICH ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_DAMMWALLDEICH','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_317 ON AX_DAMMWALLDEICH(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_318 ON ax_dammwalldeich (gml_id,beginnt);
COMMENT ON TABLE  ax_dammwalldeich        IS 'D a m m  /  W a l l  /  D e i c h';
COMMENT ON COLUMN ax_dammwalldeich.gml_id IS 'Identifikator, global eindeutig';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_HOEHLENEINGANG';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_HOEHLENEINGANG CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_HOEHLENEINGANG (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	name			varchar2(2047),
	ax_datenerhebung	integer,
	CONSTRAINT ALKIS_319 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_HOEHLENEINGANG ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_HOEHLENEINGANG','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_320 ON AX_HOEHLENEINGANG(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_321 ON ax_hoehleneingang (gml_id,beginnt);
COMMENT ON TABLE  ax_hoehleneingang        IS 'Höhleneingang';
COMMENT ON COLUMN ax_hoehleneingang.gml_id IS 'Identifikator, global eindeutig';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_FELSENFELSBLOCKFELSNADEL';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_FELSENFELSBLOCKFELSNADEL CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_FELSENFELSBLOCKFELSNADEL (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	name			varchar2(2047),
	CONSTRAINT ALKIS_322 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_FELSENFELSBLOCKFELSNADEL ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_FELSENFELSBLOCKFELSNADEL','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_323 ON AX_FELSENFELSBLOCKFELSNADEL(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_324 ON ax_felsenfelsblockfelsnadel (gml_id,beginnt);
COMMENT ON TABLE  ax_felsenfelsblockfelsnadel        IS 'F e l s e n ,  F e l s b l o c k ,   F e l s n a d e l';
COMMENT ON COLUMN ax_felsenfelsblockfelsnadel.gml_id IS 'Identifikator, global eindeutig';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_DUENE';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_DUENE CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_DUENE (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	name			varchar2(2047),
	CONSTRAINT ALKIS_325 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_DUENE ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_DUENE','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_326 ON AX_DUENE(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_327 ON ax_duene (gml_id,beginnt);
COMMENT ON TABLE  ax_duene IS 'D ü n e';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_HOEHENLINIE';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_HOEHENLINIE CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_HOEHENLINIE (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	hoehevonhoehenlinie	double precision,
	CONSTRAINT ALKIS_328 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_HOEHENLINIE ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_HOEHENLINIE','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_329 ON AX_HOEHENLINIE(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_330 ON ax_hoehenlinie (gml_id,beginnt);
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_GELAENDEKANTE';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_GELAENDEKANTE CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_GELAENDEKANTE (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar2(2047),
	sonstigesmodell		varchar2(2047),
	anlass			varchar2(2047),
	istteilvon		varchar2(2047),
	artdergelaendekante	integer,
	ax_dqerfassungsmethode	integer,
	identifikation		integer,
	art			integer,
	CONSTRAINT ALKIS_331 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_GELAENDEKANTE ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_GELAENDEKANTE','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_332 ON AX_GELAENDEKANTE(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_333 ON ax_gelaendekante (gml_id,beginnt);
COMMENT ON TABLE  ax_gelaendekante        IS 'G e l ä n d e k a n t e';
COMMENT ON COLUMN ax_gelaendekante.gml_id IS 'Identifikator, global eindeutig';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_BESONDERERHOEHENPUNKT';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_BESONDERERHOEHENPUNKT CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_BESONDERERHOEHENPUNKT (
	ogr_fid			integer NOT NULL,
	gml_id 			character(16),
	identifier 		character(44),
	beginnt 		character(20),
	endet  			character(20),
	advstandardmodell	varchar2(2047),
	sonstigesmodell		varchar2(2047),
	anlass			varchar2(2047),
	besonderebedeutung	integer,
	CONSTRAINT ALKIS_334 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_BESONDERERHOEHENPUNKT ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_BESONDERERHOEHENPUNKT','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_335 ON AX_BESONDERERHOEHENPUNKT(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_336 ON ax_besondererhoehenpunkt (gml_id,beginnt);
COMMENT ON TABLE  ax_besondererhoehenpunkt        IS 'B e s o n d e r e r   H ö h e n - P u n k t';
COMMENT ON COLUMN ax_besondererhoehenpunkt.gml_id IS 'Identifikator, global eindeutig';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_KLASSIFIZIERUNGNACHSTRASSEN';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_KLASSIFIZIERUNGNACHSTRASSEN CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_KLASSIFIZIERUNGNACHSTRASSEN (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	artderfestlegung	integer,
	land			integer,
	stelle			varchar2(2047),
	bezeichnung		varchar2(2047),
	CONSTRAINT ALKIS_337 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_KLASSIFIZIERUNGNACHSTRASSEN ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_KLASSIFIZIERUNGNACHSTRASSEN','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_338 ON AX_KLASSIFIZIERUNGNACHSTRASSEN(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_339 ON AX_KLASSIFIZIERUNGNACHSTRASSEN (gml_id,beginnt);
CREATE INDEX ALKIS_340 ON AX_KLASSIFIZIERUNGNACHSTRASSEN(land,stelle);
COMMENT ON TABLE  AX_KLASSIFIZIERUNGNACHSTRASSEN        IS 'K l a s s i f i z i e r u n g   n a c h   S t r a s s e n r e c h t';
COMMENT ON COLUMN AX_KLASSIFIZIERUNGNACHSTRASSEN.gml_id IS 'Identifikator, global eindeutig';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_KLASSIFIZIERUNGNACHWASSERRE';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_KLASSIFIZIERUNGNACHWASSERRE CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_KLASSIFIZIERUNGNACHWASSERRE (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	artderfestlegung	integer,
	land			integer,
	stelle			varchar2(2047),
	CONSTRAINT ALKIS_341 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_KLASSIFIZIERUNGNACHWASSERRE ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_KLASSIFIZIERUNGNACHWASSERRE','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_342 ON AX_KLASSIFIZIERUNGNACHWASSERRE(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE INDEX ALKIS_343 ON AX_KLASSIFIZIERUNGNACHWASSERRE(land,stelle);
COMMENT ON TABLE  AX_KLASSIFIZIERUNGNACHWASSERRE        IS 'K l a s s i f i z i e r u n g   n a c h   W a s s e r r e c h t';
COMMENT ON COLUMN AX_KLASSIFIZIERUNGNACHWASSERRE.gml_id IS 'Identifikator, global eindeutig';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_BAURAUMODERBODENORDNUNGSREC';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_BAURAUMODERBODENORDNUNGSREC CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_BAURAUMODERBODENORDNUNGSREC (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	art			varchar2(2047),
	name			varchar2(2047),
	artderfestlegung	integer,
	land			integer,
	stelle			varchar2(2047),
	bezeichnung		varchar2(2047),
	CONSTRAINT ALKIS_344 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_BAURAUMODERBODENORDNUNGSREC ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_BAURAUMODERBODENORDNUNGSREC','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_345 ON AX_BAURAUMODERBODENORDNUNGSREC(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_346 ON AX_BAURAUMODERBODENORDNUNGSREC (gml_id,beginnt);
COMMENT ON TABLE  AX_BAURAUMODERBODENORDNUNGSREC             IS 'REO: Bau-, Raum- oder Bodenordnungsrecht';
COMMENT ON COLUMN AX_BAURAUMODERBODENORDNUNGSREC.gml_id      IS 'Identifikator, global eindeutig';
COMMENT ON COLUMN AX_BAURAUMODERBODENORDNUNGSREC.artderfestlegung IS 'ADF';
COMMENT ON COLUMN AX_BAURAUMODERBODENORDNUNGSREC.name      IS 'NAM, Eigenname von "Bau-, Raum- oder Bodenordnungsrecht"';
COMMENT ON COLUMN AX_BAURAUMODERBODENORDNUNGSREC.bezeichnung IS 'BEZ, Amtlich festgelegte Verschlüsselung von "Bau-, Raum- oder Bodenordnungsrecht"';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_SONSTIGESRECHT';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_SONSTIGESRECHT CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_SONSTIGESRECHT (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	artderfestlegung	integer,
	land			integer,
	stelle			varchar2(2047),
	bezeichnung		varchar2(2047),
	characterstring		varchar2(2047),
	art			varchar2(2047),
	name			varchar2(2047),
	funktion		integer,
	CONSTRAINT ALKIS_347 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_SONSTIGESRECHT ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_SONSTIGESRECHT','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_348 ON AX_SONSTIGESRECHT(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_349 ON ax_sonstigesrecht (gml_id,beginnt);
COMMENT ON TABLE  ax_sonstigesrecht        IS 'S o n s t i g e s   R e c h t';
COMMENT ON COLUMN ax_sonstigesrecht.gml_id IS 'Identifikator, global eindeutig';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_BODENSCHAETZUNG';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_BODENSCHAETZUNG CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_BODENSCHAETZUNG (
	ogr_fid				integer NOT NULL,
	gml_id				character(16),
	identifier			character(44),
	beginnt				character(20),
	endet 				character(20),
	advstandardmodell		varchar2(2047),
	anlass				varchar2(2047),
	art				varchar2(2047),
	name				varchar2(2047),
	kulturart			integer,
	bodenart			integer,
	zustandsstufeoderbodenstufe	integer,
	ENTSTEHUNGSARTODERKLIMASTUFEWA	varchar2(2047),
	BODENZAHLODERGRUENLANDGRUNDZAH	integer,
	ackerzahlodergruenlandzahl	integer,
	sonstigeangaben			varchar2(2047),
	jahreszahl			integer,
	CONSTRAINT ALKIS_350 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_BODENSCHAETZUNG ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_BODENSCHAETZUNG','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_351 ON AX_BODENSCHAETZUNG(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_352 ON ax_bodenschaetzung (gml_id,beginnt);
COMMENT ON TABLE  ax_bodenschaetzung        IS 'B o d e n s c h ä t z u n g';
COMMENT ON COLUMN ax_bodenschaetzung.gml_id IS 'Identifikator, global eindeutig';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_MUSTERLANDESMUSTERUNDVERGLE';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_MUSTERLANDESMUSTERUNDVERGLE CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_MUSTERLANDESMUSTERUNDVERGLE (
	ogr_fid				integer NOT NULL,
	gml_id				character(16),
	identifier			character(44),
	beginnt				character(20),
	endet 				character(20),
	advstandardmodell		varchar2(2047),
	anlass				varchar2(2047),
	merkmal				integer,
	nummer				integer,
	kulturart			integer,
	bodenart			integer,
	zustandsstufeoderbodenstufe	integer,
	ENTSTEHUNGSARTODERKLIMASTUFEWA	integer,
	BODENZAHLODERGRUENLANDGRUNDZAH	integer,
	ackerzahlodergruenlandzahl	integer,
	art				varchar2(2047),
	name				varchar2(2047),
	CONSTRAINT ALKIS_353 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_MUSTERLANDESMUSTERUNDVERGLE ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_MUSTERLANDESMUSTERUNDVERGLE','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_354 ON AX_MUSTERLANDESMUSTERUNDVERGLE(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_355 ON AX_MUSTERLANDESMUSTERUNDVERGLE (gml_id,beginnt);
COMMENT ON TABLE  AX_MUSTERLANDESMUSTERUNDVERGLE        IS 'Muster-, Landesmuster- und Vergleichsstueck';
COMMENT ON COLUMN AX_MUSTERLANDESMUSTERUNDVERGLE.gml_id IS 'Identifikator, global eindeutig';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_BUNDESLAND';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_BUNDESLAND CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_BUNDESLAND (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	schluesselgesamt	integer,
	bezeichnung		varchar2(2047),
	land			integer,
	stelle			varchar2(2047),
	CONSTRAINT ALKIS_356 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_BUNDESLAND ADD DUMMY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_BUNDESLAND','DUMMY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE UNIQUE INDEX ALKIS_357 ON ax_bundesland (gml_id,beginnt);
COMMENT ON TABLE  ax_bundesland        IS 'B u n d e s l a n d';
COMMENT ON COLUMN ax_bundesland.gml_id IS 'Identifikator, global eindeutig';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_REGIERUNGSBEZIRK';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_REGIERUNGSBEZIRK CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_REGIERUNGSBEZIRK (
	ogr_fid				integer NOT NULL,
	gml_id				character(16),
	identifier			character(44),
	beginnt				character(20),
	endet 				character(20),
	advstandardmodell		varchar2(2047),
	anlass				varchar2(2047),
	schluesselgesamt		integer,
	bezeichnung			varchar2(2047),
	land				integer,
	regierungsbezirk		integer,
	CONSTRAINT ALKIS_358 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_REGIERUNGSBEZIRK ADD DUMMY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_REGIERUNGSBEZIRK','DUMMY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE UNIQUE INDEX ALKIS_359 ON ax_regierungsbezirk (gml_id,beginnt);
COMMENT ON TABLE  ax_regierungsbezirk        IS 'R e g i e r u n g s b e z i r k';
COMMENT ON COLUMN ax_regierungsbezirk.gml_id IS 'Identifikator, global eindeutig';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_KREISREGION';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_KREISREGION CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_KREISREGION (
	ogr_fid				integer NOT NULL,
	gml_id				character(16),
	identifier			character(44),
	beginnt				character(20),
	endet 				character(20),
	advstandardmodell		varchar2(2047),
	anlass				varchar2(2047),
	schluesselgesamt		integer,
	bezeichnung			varchar2(2047),
	land				integer,
	regierungsbezirk		integer,
	kreis				integer,
	CONSTRAINT ALKIS_360 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_KREISREGION ADD DUMMY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_KREISREGION','DUMMY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE UNIQUE INDEX ALKIS_361 ON ax_kreisregion (gml_id,beginnt);
COMMENT ON TABLE  ax_kreisregion        IS 'K r e i s  /  R e g i o n';
COMMENT ON COLUMN ax_kreisregion.gml_id IS 'Identifikator, global eindeutig';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_GEMEINDE';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_GEMEINDE CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_GEMEINDE (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	schluesselgesamt	integer,
	bezeichnung		varchar2(2047),
	land			integer,
	regierungsbezirk	integer,
	kreis			integer,
	gemeinde		integer,
	CONSTRAINT ALKIS_362 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_GEMEINDE ADD DUMMY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_GEMEINDE','DUMMY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE UNIQUE INDEX ALKIS_363 ON ax_gemeinde (gml_id,beginnt);
COMMENT ON TABLE  ax_gemeinde        IS 'G e m e i n d e';
COMMENT ON COLUMN ax_gemeinde.gml_id IS 'Identifikator, global eindeutig';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_GEMEINDETEIL';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_GEMEINDETEIL CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_GEMEINDETEIL (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	schluesselgesamt	double precision,
	bezeichnung		varchar2(2047),
	administrativefunktion	integer,
	land			integer,
	regierungsbezirk	integer,
	kreis			integer,
	gemeinde		integer,
	gemeindeteil		integer,
	CONSTRAINT ALKIS_364 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_GEMEINDETEIL ADD DUMMY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_GEMEINDETEIL','DUMMY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE UNIQUE INDEX ALKIS_365 ON ax_gemeindeteil (gml_id,beginnt);
COMMENT ON TABLE  ax_gemeindeteil        IS 'G e m e i n d e - T e i l';
COMMENT ON COLUMN ax_gemeindeteil.gml_id IS 'Identifikator, global eindeutig';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_GEMARKUNG';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_GEMARKUNG CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_GEMARKUNG (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	schluesselgesamt	integer,
	bezeichnung		varchar2(2047),
	land			integer,
	gemarkungsnummer	integer,
	stelle			integer,
	CONSTRAINT ALKIS_366 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_GEMARKUNG ADD DUMMY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_GEMARKUNG','DUMMY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE UNIQUE INDEX ALKIS_367 ON ax_gemarkung (gml_id,beginnt);
CREATE INDEX ALKIS_368         ON ax_gemarkung (land, gemarkungsnummer);
COMMENT ON TABLE  ax_gemarkung        IS 'G e m a r k u n g';
COMMENT ON COLUMN ax_gemarkung.gml_id IS 'Identifikator, global eindeutig';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_GEMARKUNGSTEILFLUR';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_GEMARKUNGSTEILFLUR CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_GEMARKUNGSTEILFLUR (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	schluesselgesamt	integer,
	bezeichnung		varchar2(2047),
	land			integer,
	gemarkung		integer,
	gemarkungsteilflur	integer,
	CONSTRAINT ALKIS_369 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_GEMARKUNGSTEILFLUR ADD DUMMY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_GEMARKUNGSTEILFLUR','DUMMY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE UNIQUE INDEX ALKIS_370 ON ax_gemarkungsteilflur (gml_id,beginnt);
COMMENT ON TABLE  ax_gemarkungsteilflur        IS 'G e m a r k u n g s t e i l   /   F l u r';
COMMENT ON COLUMN ax_gemarkungsteilflur.gml_id IS 'Identifikator, global eindeutig';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_BUCHUNGSBLATTBEZIRK';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_BUCHUNGSBLATTBEZIRK CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_BUCHUNGSBLATTBEZIRK (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	schluesselgesamt	integer,
	bezeichnung		varchar2(2047),
	land			integer,
	bezirk			integer,
	stelle			varchar2(2047),
	CONSTRAINT ALKIS_371 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_BUCHUNGSBLATTBEZIRK ADD DUMMY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_BUCHUNGSBLATTBEZIRK','DUMMY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE UNIQUE INDEX ALKIS_372 ON ax_buchungsblattbezirk (gml_id,beginnt);
CREATE INDEX ALKIS_373 ON ax_buchungsblattbezirk (land, bezirk);
COMMENT ON TABLE  ax_buchungsblattbezirk        IS 'Buchungsblatt- B e z i r k';
COMMENT ON COLUMN ax_buchungsblattbezirk.gml_id IS 'Identifikator, global eindeutig';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_DIENSTSTELLE';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_DIENSTSTELLE CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_DIENSTSTELLE (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	sonstigesmodell		varchar2(2047),
	anlass			varchar2(2047),
	schluesselgesamt	varchar2(2047),
	bezeichnung		varchar2(2047),
	land			integer,
	stelle			varchar2(2047),
	stellenart		integer,
	CONSTRAINT ALKIS_374 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_DIENSTSTELLE ADD DUMMY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_DIENSTSTELLE','DUMMY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE UNIQUE INDEX ALKIS_375 ON ax_dienststelle (gml_id,beginnt);
COMMENT ON TABLE  ax_dienststelle        IS 'D i e n s t s t e l l e';
COMMENT ON COLUMN ax_dienststelle.gml_id IS 'Identifikator, global eindeutig';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_LAGEBEZEICHNUNGKATALOGEINTR';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_LAGEBEZEICHNUNGKATALOGEINTR CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_LAGEBEZEICHNUNGKATALOGEINTR (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	schluesselgesamt	varchar2(2047),
	bezeichnung		varchar2(2047),
	land			integer,
	regierungsbezirk	integer,
	kreis			integer,
	gemeinde		integer,
	lage			varchar2(2047),
	CONSTRAINT ALKIS_376 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_LAGEBEZEICHNUNGKATALOGEINTR ADD DUMMY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_LAGEBEZEICHNUNGKATALOGEINTR','DUMMY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE UNIQUE INDEX ALKIS_377 ON AX_LAGEBEZEICHNUNGKATALOGEINTR (gml_id,beginnt);
CREATE INDEX ALKIS_378 ON AX_LAGEBEZEICHNUNGKATALOGEINTR (gemeinde, lage);
CREATE INDEX ALKIS_379 ON AX_LAGEBEZEICHNUNGKATALOGEINTR (schluesselgesamt);
CREATE INDEX ALKIS_380  ON AX_LAGEBEZEICHNUNGKATALOGEINTR (bezeichnung);
COMMENT ON TABLE  AX_LAGEBEZEICHNUNGKATALOGEINTR              IS 'Straßentabelle';
COMMENT ON COLUMN AX_LAGEBEZEICHNUNGKATALOGEINTR.gml_id       IS 'Identifikator, global eindeutig';
COMMENT ON COLUMN AX_LAGEBEZEICHNUNGKATALOGEINTR.lage         IS 'Straßenschlüssel';
COMMENT ON COLUMN AX_LAGEBEZEICHNUNGKATALOGEINTR.bezeichnung  IS 'Straßenname';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_KLEINRAEUMIGERLANDSCHAFTSTE';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_KLEINRAEUMIGERLANDSCHAFTSTE CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_KLEINRAEUMIGERLANDSCHAFTSTE (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	sonstigesmodell		varchar2(2047),
	anlass			varchar2(2047),
	landschaftstyp		integer,
	name			varchar2(2047),
	CONSTRAINT ALKIS_381 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_KLEINRAEUMIGERLANDSCHAFTSTE ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_KLEINRAEUMIGERLANDSCHAFTSTE','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_382 ON AX_KLEINRAEUMIGERLANDSCHAFTSTE(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_383 ON AX_KLEINRAEUMIGERLANDSCHAFTSTE (gml_id,beginnt);
COMMENT ON TABLE  AX_KLEINRAEUMIGERLANDSCHAFTSTE        IS 'k l e i n r ä u m i g e r   L a n d s c h a f t s t e i l';
COMMENT ON COLUMN AX_KLEINRAEUMIGERLANDSCHAFTSTE.gml_id IS 'Identifikator, global eindeutig';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_WOHNPLATZ';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_WOHNPLATZ CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_WOHNPLATZ (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	name			varchar2(2047),
	CONSTRAINT ALKIS_384 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_WOHNPLATZ ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_WOHNPLATZ','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_385 ON AX_WOHNPLATZ(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_386 ON ax_wohnplatz (gml_id,beginnt);
COMMENT ON TABLE  ax_wohnplatz        IS 'W o h n p l a t z';
COMMENT ON COLUMN ax_wohnplatz.gml_id IS 'Identifikator, global eindeutig';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_KOMMUNALESGEBIET';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_KOMMUNALESGEBIET CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_KOMMUNALESGEBIET (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet 			character(20),
	advstandardmodell	varchar2(2047),
	anlass			varchar2(2047),
	schluesselgesamt	varchar2(2047),
	land			integer,
	regierungsbezirk	integer,
	kreis			integer,
	gemeinde		integer,
	gemeindeflaeche		double precision,
	CONSTRAINT ALKIS_387 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_KOMMUNALESGEBIET ADD ORA_GEOMETRY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_KOMMUNALESGEBIET','ORA_GEOMETRY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
CREATE INDEX ALKIS_388 ON AX_KOMMUNALESGEBIET(ORA_GEOMETRY) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;
CREATE UNIQUE INDEX ALKIS_389 ON ax_kommunalesgebiet (gml_id,beginnt);
COMMENT ON TABLE  ax_kommunalesgebiet        IS 'K o m m u n a l e s   G e b i e t';
COMMENT ON COLUMN ax_kommunalesgebiet.gml_id IS 'Identifikator, global eindeutig';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_VERTRETUNG';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_VERTRETUNG CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_VERTRETUNG (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar(4),
	anlass			varchar2(2047),
	CONSTRAINT ALKIS_390 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_VERTRETUNG ADD DUMMY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_VERTRETUNG','DUMMY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
COMMENT ON TABLE  ax_vertretung IS 'V e r t r e t u n g';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_VERWALTUNGSGEMEINSCHAFT';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_VERWALTUNGSGEMEINSCHAFT CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_VERWALTUNGSGEMEINSCHAFT (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar(4),
	anlass			varchar2(2047),
	schluesselgesamt	integer,
	bezeichnung		varchar2(2047),
	bezeichnungart		integer,
	land			integer,
	regierungsbezirk	integer,
	kreis			integer,
	verwaltungsgemeinschaft	integer,
	CONSTRAINT ALKIS_391 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_VERWALTUNGSGEMEINSCHAFT ADD DUMMY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_VERWALTUNGSGEMEINSCHAFT','DUMMY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
COMMENT ON TABLE  ax_verwaltungsgemeinschaft  IS 'V e r w a l t u n g s g e m e i n s c h a f t';
DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='AX_VERWALTUNG';
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AX_VERWALTUNG CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE AX_VERWALTUNG (
	ogr_fid			integer NOT NULL,
	gml_id			character(16),
	identifier		character(44),
	beginnt			character(20),
	endet			character(20),
	advstandardmodell	varchar(4),
	anlass			varchar2(2047),
	CONSTRAINT ALKIS_392 PRIMARY KEY (ogr_fid)
);
ALTER TABLE AX_VERWALTUNG ADD DUMMY MDSYS.SDO_GEOMETRY;
INSERT INTO user_sdo_geom_metadata(table_name,column_name,srid,diminfo) VALUES ('AX_VERWALTUNG','DUMMY',&&alkis_epsg,mdsys.sdo_dim_array(mdsys.sdo_dim_element('X',200000,800000,0.001),mdsys.sdo_dim_element('Y',5200000,6100000,0.001)));
COMMENT ON TABLE  ax_verwaltung  IS 'V e r w a l t u n g';
purge recyclebin;
QUIT;
