/******************************************************************************
 *
 * Projekt:  norGIS ALKIS Import
 * Zweck:    Trigger des ALKIS-Schema
 * Author:   Jürgen E. Fischer <jef@norbit.de>
 *
 ******************************************************************************/

SET client_encoding = 'UTF8';
SET default_with_oids = false;
SET search_path = :"alkis_schema", public;

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

COMMENT ON TABLE delete IS 'BASE: Lösch- und Fortführungsdatensätze';
COMMENT ON COLUMN delete.context      IS 'Operation ''delete'', ''replace'' oder ''update''.';
COMMENT ON COLUMN delete.safetoignore IS 'Attribut safeToIgnore von wfsext:Replace';
COMMENT ON COLUMN delete.replacedBy   IS 'gml_id des Objekts, das featureid ersetzt';
COMMENT ON COLUMN delete.anlass       IS 'Anlaß des Endes';
COMMENT ON COLUMN delete.endet        IS 'Zeitpunkt des Endes';
COMMENT ON COLUMN delete.ignored      IS 'Löschsatz wurde ignoriert';

-- Löschsatz verarbeiten (MIT Historie)
-- context='delete'        => "endet" auf aktuelle Zeit setzen
-- context='replace'       => "endet" des ersetzten auf "beginnt" des neuen Objekts setzen
-- context='update'        => "endet" auf übergebene Zeit setzen und "anlass" festhalten
CREATE OR REPLACE FUNCTION delete_feature_hist() RETURNS TRIGGER AS $$
DECLARE
	n INTEGER;
	beginnt TEXT;
	s TEXT;
BEGIN
	NEW.context := coalesce(lower(NEW.context),'delete');

	IF length(NEW.featureid)=32 THEN
		beginnt := substr(NEW.featureid, 17, 4) || '-'
			|| substr(NEW.featureid, 21, 2) || '-'
			|| substr(NEW.featureid, 23, 2) || 'T'
			|| substr(NEW.featureid, 26, 2) || ':'
			|| substr(NEW.featureid, 28, 2) || ':'
			|| substr(NEW.featureid, 30, 2) || 'Z'
			;
	ELSIF length(NEW.featureid)=16 THEN
		-- Ältestes nicht gelöschtes Objekt
		EXECUTE 'SELECT min(beginnt) FROM ' || NEW.typename
			|| ' WHERE gml_id=''' || substr(NEW.featureid, 1, 16) || ''''
			|| ' AND endet IS NULL'
			INTO beginnt;

		IF beginnt IS NULL THEN
			RAISE EXCEPTION '%: Keinen Kandidaten zum Löschen gefunden.', NEW.featureid;
		END IF;
	ELSE
		RAISE EXCEPTION '%: Identifikator gescheitert.', NEW.featureid;
	END IF;

	IF NEW.context='delete' THEN
		NEW.endet := to_char(CURRENT_TIMESTAMP AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS"Z"');

	ELSIF NEW.context='update' THEN
		IF NEW.endet IS NULL THEN
			RAISE EXCEPTION '%: Endedatum nicht gesetzt', NEW.featureid;
		END IF;

	ELSIF NEW.context='replace' THEN
		NEW.safetoignore := lower(NEW.safetoignore);
		IF NEW.safetoignore IS NULL THEN
			RAISE EXCEPTION '%: safeToIgnore nicht gesetzt.', NEW.featureid;
		ELSIF NEW.safetoignore<>'true' AND NEW.safetoignore<>'false' THEN
			RAISE EXCEPTION '%: safeToIgnore ''%'' ungültig (''true'' oder ''false'' erwartet).', NEW.featureid, NEW.safetoignore;
		END IF;

		IF length(NEW.replacedby)=32 AND NEW.replacedby<>NEW.featureid THEN
			NEW.endet := substr(NEW.replacedby, 17, 4) || '-'
				  || substr(NEW.replacedby, 21, 2) || '-'
				  || substr(NEW.replacedby, 23, 2) || 'T'
				  || substr(NEW.replacedby, 26, 2) || ':'
				  || substr(NEW.replacedby, 28, 2) || ':'
				  || substr(NEW.replacedby, 30, 2) || 'Z'
				  ;
		END IF;

		IF NEW.endet IS NULL THEN
			-- Beginn des ersten Nachfolgeobjektes
			EXECUTE 'SELECT min(beginnt) FROM ' || NEW.typename || ' a'
				|| ' WHERE gml_id=''' || substr(NEW.replacedby, 1, 16) || ''''
				|| ' AND beginnt>''' || beginnt || ''''
				INTO NEW.endet;
		ELSE
			EXECUTE 'SELECT count(*) FROM ' || NEW.typename
				|| ' WHERE gml_id=''' || substr(NEW.replacedby, 1, 16) || ''''
				|| ' AND beginnt=''' || NEW.endet || ''''
				INTO n;
			IF n<>1 THEN
				RAISE EXCEPTION '%: Ersatzobjekt % % nicht gefunden.', NEW.featureid, NEW.replacedby, NEW.endet;
			END IF;
		END IF;

		IF NEW.endet IS NULL THEN
			IF NEW.safetoignore='false' THEN
				RAISE EXCEPTION '%: Beginn des Ersatzobjekts % nicht gefunden.', NEW.featureid, NEW.replacedby;
				-- RAISE NOTICE '%: Beginn des ersetzenden Objekts % nicht gefunden.', NEW.featureid, NEW.replacedby;
			END IF;

			NEW.ignored=true;
			RETURN NEW;
		END IF;

	ELSE
		RAISE EXCEPTION '%: Ungültiger Kontext % (''delete'', ''replace'' oder ''update'' erwartet).', NEW.featureid, NEW.context;

	END IF;

	s := 'UPDATE ' || NEW.typename || ' SET endet=''' || NEW.endet || '''';

	IF NEW.context='update' AND NEW.anlass IS NOT NULL THEN
		s := s || ',anlass=array_cat(anlass,''{' || array_to_string(NEW.anlass,',') || '}'')';
	END IF;

	s := s || ' WHERE gml_id=''' || substr(NEW.featureid, 1, 16) || ''''
	       || ' AND beginnt=''' || beginnt || ''''
	       ;
	EXECUTE s;
	GET DIAGNOSTICS n = ROW_COUNT;
	-- RAISE NOTICE 'SQL[%]:%', n, s;
	IF n<>1 THEN
		RAISE EXCEPTION '%: % schlug fehl [%]', NEW.featureid, NEW.context, n;
		-- RAISE NOTICE '%: % schlug fehl [%]', NEW.featureid, NEW.context, n;
		-- NEW.ignored=true;
		-- RETURN NEW;
	END IF;

	NEW.ignored := false;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

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

COMMENT ON TABLE alkis_beziehungen IS 'BASE: Objektbeziehungen';
COMMENT ON COLUMN alkis_beziehungen.beziehung_von IS 'Join auf Feld gml_id verschiedener Tabellen';
COMMENT ON COLUMN alkis_beziehungen.beziehung_zu  IS 'Join auf Feld gml_id verschiedener Tabellen';
COMMENT ON COLUMN alkis_beziehungen.beziehungsart IS 'Typ der Beziehung zwischen der von- und zu-Tabelle';

-- Beziehungssätze aufräumen
CREATE OR REPLACE FUNCTION alkis_beziehung_inserted() RETURNS TRIGGER AS $$
BEGIN
        DELETE FROM alkis_beziehungen WHERE ogc_fid<NEW.ogc_fid AND beziehung_von=NEW.beziehung_von AND beziehungsart=NEW.beziehungsart AND beziehung_zu=NEW.beziehung_zu;
        RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER insert_beziehung_trigger
	AFTER INSERT ON alkis_beziehungen
	FOR EACH ROW
	EXECUTE PROCEDURE alkis_beziehung_inserted();
