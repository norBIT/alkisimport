/******************************************************************************
 *
 * Projekt:  norGIS ALKIS Import
 * Zweck:    Initialisierung des ALKIS-Schema
 * Author:   Jürgen E. Fischer <jef@norbit.de>
 *
 ******************************************************************************/

-- Damit die Includes (\i) funktionieren muß psql im Verzeichnis ausgeführt
-- werden in dem das Skript liegt. Z.B. per
-- (cd /pfad/zu/postnas; psql -f alkis-init.sql)

-- Variable für das Koordinatensystem übergeben mit "psql .. -v alkis_epsg=25832 -v alkis-schema=public"

SET client_encoding = 'UTF8';
SET default_with_oids = false;

-- Abbruch bei Fehlern
\set ON_ERROR_STOP

-- Stored Procedures laden
\i alkis-functions.sql

-- Alle Tabellen löschen
SELECT alkis_drop();

CREATE TABLE alkis_version(version integer);
INSERT INTO alkis_version(version) VALUES (15);

-- BW/BY-Koordinatensystem anlegen
SELECT alkis_create_bsrs(:alkis_epsg);

--- Tabelle "delete" für Lösch- und Fortführungsdatensätze
CREATE TABLE "delete" (
       ogc_fid         serial NOT NULL,
       typename        varchar,
       featureid       varchar,
       context         varchar,                -- delete/replace/update
       safetoignore    varchar,                -- replace.safetoignore 'true'/'false'
       replacedBy      varchar,                -- gmlid
       anlass          varchar[],              -- update.anlass
       endet           character(20),          -- update.endet
       ignored         boolean DEFAULT false,  -- Satz wurde nicht verarbeitet
       PRIMARY KEY (ogc_fid)
);

CREATE INDEX delete_fid ON "delete"(featureid);

COMMENT ON COLUMN delete.context      IS 'Operation ''delete'', ''replace'' oder ''update''.';
COMMENT ON COLUMN delete.safetoignore IS 'Attribut safeToIgnore von wfsext:Replace';
COMMENT ON COLUMN delete.replacedBy   IS 'gml_id des Objekts, das featureid ersetzt';
COMMENT ON COLUMN delete.anlass       IS 'Anlaß des Endes';
COMMENT ON COLUMN delete.endet        IS 'Zeitpunkt des Endes';
COMMENT ON COLUMN delete.ignored      IS 'Löschsatz wurde ignoriert';

CREATE TRIGGER delete_feature_trigger
	BEFORE INSERT ON delete
	FOR EACH ROW
	EXECUTE PROCEDURE delete_feature_hist();


CREATE TABLE alkis_beziehungen (
       ogc_fid                 serial NOT NULL,
       beziehung_von           character(16) NOT NULL,
       beziehungsart           varchar,
       beziehung_zu            character(16) NOT NULL,
       PRIMARY KEY (ogc_fid)
);

CREATE INDEX alkis_beziehungen_von_idx ON alkis_beziehungen USING btree (beziehung_von);
CREATE INDEX alkis_beziehungen_zu_idx  ON alkis_beziehungen USING btree (beziehung_zu);
CREATE INDEX alkis_beziehungen_art_idx ON alkis_beziehungen USING btree (beziehungsart);

COMMENT ON TABLE  alkis_beziehungen               IS 'zentrale Multi-Verbindungstabelle';
COMMENT ON COLUMN alkis_beziehungen.beziehung_von IS 'Join auf Feld gml_id verschiedener Tabellen';
COMMENT ON COLUMN alkis_beziehungen.beziehung_zu  IS 'Join auf Feld gml_id verschiedener Tabellen';
COMMENT ON COLUMN alkis_beziehungen.beziehungsart IS 'Typ der Beziehung zwischen der von- und zu-Tabelle';

CREATE TRIGGER insert_beziehung_trigger
	AFTER INSERT ON alkis_beziehungen
	FOR EACH ROW
	EXECUTE PROCEDURE alkis_beziehung_inserted();

\i alkis-schema.sql

\i alkis-wertearten.sql
-- \i alkis-wertearten-nrw.sql
