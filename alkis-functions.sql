/******************************************************************************
 *
 * Project:  norGIS ALKIS Import
 * Purpose:  SQL-Funktionen für ALKIS
 * Author:   Jürgen E. Fischer <jef@norbit.de>
 *
 ******************************************************************************
 * Copyright (c) 2012-2014, Jürgen E. Fischer <jef@norbit.de>
 *
 *   This program is free software; you can redistribute it and/or modify
 *   it under the terms of the GNU General Public License as published by
 *   the Free Software Foundation; either version 2 of the License, or
 *   (at your option) any later version.
 *
 ****************************************************************************/

-- Table/View/Sequence löschen, wenn vorhanden
CREATE OR REPLACE FUNCTION alkis_dropobject(t TEXT) RETURNS varchar AS $$
DECLARE
	c RECORD;
	s varchar;
	r varchar;
	d varchar;
	i integer;
	tn varchar;
BEGIN
	r := '';
	d := '';

	-- drop objects
	FOR c IN SELECT relkind,relname
		FROM pg_class
		JOIN pg_namespace ON pg_class.relnamespace=pg_namespace.oid
		WHERE pg_namespace.nspname='public' AND pg_class.relname=t
		ORDER BY relkind
	LOOP
		IF c.relkind = 'v' THEN
			r := r || d || 'Sicht ' || c.relname || ' gelöscht.';
			EXECUTE 'DROP VIEW ' || c.relname || ' CASCADE';
		ELSIF c.relkind = 'r' THEN
			r := r || d || 'Tabelle ' || c.relname || ' gelöscht.';
			EXECUTE 'DROP TABLE ' || c.relname || ' CASCADE';
		ELSIF c.relkind = 'S' THEN
			r := r || d || 'Sequenz ' || c.relname || ' gelöscht.';
			EXECUTE 'DROP SEQUENCE ' || c.relname;
		ELSIF c.relkind <> 'i' THEN
			r := r || d || 'Typ ' || c.table_type || '.' || c.table_name || ' unerwartet.';
		ELSE
			CONTINUE;
		END IF;
		d := E'\n';
	END LOOP;

	FOR c IN SELECT indexname FROM pg_indexes WHERE schemaname='public' AND indexname=t
	LOOP
		r := r || d || 'Index ' || c.indexname || ' gelöscht.';
		EXECUTE 'DROP INDEX ' || c.indexname;
		d := E'\n';
	END LOOP;

	FOR c IN SELECT proname,proargtypes
		FROM pg_proc
		JOIN pg_namespace ON pg_proc.pronamespace=pg_namespace.oid
		WHERE pg_namespace.nspname='public' AND pg_proc.proname=t
	LOOP
		r := r || d || 'Funktion ' || c.proname || ' gelöscht.';

		s := 'DROP FUNCTION ' || c.proname || '(';
		d := '';

		FOR i IN array_lower(c.proargtypes,1)..array_upper(c.proargtypes,1) LOOP
			SELECT typname INTO tn FROM pg_type WHERE oid=c.proargtypes[i];
			s := s || d || tn;
			d := ',';
		END LOOP;

		s := s || ')';

		EXECUTE s;

		d := E'\n';
	END LOOP;

	FOR c IN SELECT relname,conname
		FROM pg_constraint
		JOIN pg_class ON pg_constraint.conrelid=pg_constraint.oid
		JOIN pg_namespace ON pg_constraint.connamespace=pg_namespace.oid
		WHERE pg_namespace.nspname='public' AND pg_constraint.conname=t
	LOOP
		r := r || d || 'Constraint ' || c.conname || ' von ' || c.relname || ' gelöscht.';
		EXECUTE 'ALTER TABLE ' || c.relname || ' DROP CONSTRAINT ' || c.conname;
		d := E'\n';
	END LOOP;

	RETURN r;
END;
$$ LANGUAGE plpgsql;

-- Alle ALKIS-Tabellen löschen
SELECT alkis_dropobject('alkis_drop');
CREATE FUNCTION alkis_drop() RETURNS varchar AS $$
DECLARE
	c RECORD;
	r VARCHAR;
	d VARCHAR;
BEGIN
	r := '';
	d := '';
	-- drop tables & views
	FOR c IN SELECT table_type,table_name FROM information_schema.tables WHERE table_schema='public' AND ( substr(table_name,1,3) IN ('ax_','ap_','ks_') OR table_name IN ('alkis_beziehungen','delete')) ORDER BY table_type DESC LOOP
		IF c.table_type = 'VIEW' THEN
			r := r || d || 'Sicht ' || c.table_name || ' gelöscht.';
			EXECUTE 'DROP VIEW ' || c.table_name || ' CASCADE';
		ELSIF c.table_type = 'BASE TABLE' THEN
			r := r || d || 'Tabelle ' || c.table_name || ' gelöscht.';
			EXECUTE 'DROP TABLE ' || c.table_name || ' CASCADE';
		ELSE
			r := r || d || 'Typ ' || c.table_type || '.' || c.table_name || ' unerwartet.';
		END IF;
		d := E'\n';
	END LOOP;

	-- clean geometry_columns
	DELETE FROM geometry_columns
		WHERE f_table_schema='public'
		AND ( substr(f_table_name,1,2) IN ('ax_','ap_','ks_')
		 OR f_table_name IN ('alkis_beziehungen','delete') );

	RETURN r;
END;
$$ LANGUAGE plpgsql;

SELECT alkis_dropobject('alkis_create_bsrs');
CREATE FUNCTION alkis_create_bsrs(id INTEGER) RETURNS varchar AS $$
DECLARE
	n INTEGER;
BEGIN
	SELECT count(*) INTO n FROM spatial_ref_sys WHERE srid=id;
	IF n=1 THEN
		RETURN NULL;
	END IF;

	IF NOT has_table_privilege('spatial_ref_sys', 'INSERT') THEN
		RAISE EXCEPTION 'Darf fehlendes Koordinatensystem % nicht einfügen.', id;
	END IF;

	IF id=131466 THEN
		-- DE_DHDN_3GK2_BW100
		INSERT INTO spatial_ref_sys(srid,auth_name,auth_srid,srtext,proj4text)
			SELECT
				131466,auth_name,131466
				,replace(replace(srtext,'PARAMETER["false_easting",2500000]','PARAMETER["false_easting",500000]'),'"EPSG","31466"','"EPSG","131466"')
				,replace(proj4text,'+x_0=2500000','+x_0=500000')
			FROM spatial_ref_sys
			WHERE srid=31466
			  AND NOT EXISTS (SELECT * FROM spatial_ref_sys WHERE srid=131466);
		RETURN 'Koordinatensystem '||id||' angelegt.';
	END IF;

	IF id=131467 THEN
		-- DE_DHDN_3GK3_BW100
		INSERT INTO spatial_ref_sys(srid,auth_name,auth_srid,srtext,proj4text)
			SELECT
				131467,auth_name,131467
				,replace(replace(srtext,'PARAMETER["false_easting",3500000]','PARAMETER["false_easting",500000]'),'"EPSG","31467"','"EPSG","131467"')
				,replace(proj4text,'+x_0=3500000','+x_0=500000')
			FROM spatial_ref_sys
			WHERE srid=31467
			  AND NOT EXISTS (SELECT * FROM spatial_ref_sys WHERE srid=131467);
		RETURN 'Koordinatensystem '||id||' angelegt.';
	END IF;

	IF id=131468 THEN
		-- DE_DHDN_3GK4_BY120
		INSERT INTO spatial_ref_sys(srid,auth_name,auth_srid,srtext,proj4text)
			SELECT
				131468,auth_name,131468
				,replace(replace(srtext,'PARAMETER["false_easting",4500000]','PARAMETER["false_easting",500000]'),'"EPSG","31468"','"EPSG","131468"')
				,replace(proj4text,'+x_0=4500000','+x_0=500000')
			FROM spatial_ref_sys
			WHERE srid=31468
			  AND NOT EXISTS (SELECT * FROM spatial_ref_sys WHERE srid=131468);
		RETURN 'Koordinatensystem '||id||' angelegt.';
	END IF;

	RAISE EXCEPTION 'Nicht erwartetes Koordinatensystem %.', id;
END;
$$ LANGUAGE plpgsql;

-- Alle ALKIS-Tabellen leeren
SELECT alkis_dropobject('alkis_delete');
CREATE FUNCTION alkis_delete() RETURNS varchar AS $$
DECLARE
	c RECORD;
	r varchar;
	d varchar;
BEGIN
	r := '';
	d := '';

	-- drop views
	FOR c IN
		SELECT table_name
		FROM information_schema.tables
		WHERE table_schema='public' AND table_type='BASE TABLE'
		  AND ( substr(table_name,1,3) IN ('ax_','ap_','ks_')
			OR table_name IN ('alkis_beziehungen','delete') )
	LOOP
		r := r || d || c.table_name || ' wurde geleert.';
		EXECUTE 'DELETE FROM '||c.table_name;
		d := E'\n';
	END LOOP;

	RETURN r;
END;
$$ LANGUAGE plpgsql;

-- Übersicht erzeugen, die alle alkis_beziehungen mit den Typen der beteiligen ALKIS-Objekte versieht
SELECT alkis_dropobject('alkis_mviews');
CREATE FUNCTION alkis_mviews() RETURNS varchar AS $$
DECLARE
	sql TEXT;
	delim TEXT;
	c RECORD;
BEGIN
	SELECT alkis_dropobject('vbeziehungen') INTO sql;
	SELECT alkis_dropobject('vobjekte') INTO sql;

	delim := '';
	sql := 'CREATE VIEW vobjekte AS ';

	FOR c IN SELECT table_name FROM information_schema.columns WHERE column_name='gml_id' AND substr(table_name,1,3) IN ('ax_','ap_','ks_') AND NOT table_name IN ('ax_tatsaechlichenutzung','ax_klassifizierung','ax_ausfuehrendestellen') LOOP
		sql := sql || delim || 'SELECT DISTINCT gml_id,beginnt,''' || c.table_name || ''' AS table_name FROM ' || c.table_name;
		delim := ' UNION ';
	END LOOP;

	EXECUTE sql;

--	CREATE UNIQUE INDEX vobjekte_gmlid ON vobjekte(gml_id,beginnt);
--	CREATE INDEX vobjekte_table ON vobjekte(table_name);

	CREATE VIEW vbeziehungen AS
		SELECT beziehung_von,(SELECT DISTINCT table_name FROM vobjekte WHERE gml_id=beziehung_von) AS typ_von
			,beziehungsart
			,beziehung_zu,(SELECT DISTINCT table_name FROM vobjekte WHERE gml_id=beziehung_zu) AS typ_zu
		FROM alkis_beziehungen;

--	CREATE INDEX vbeziehungen_von    ON vbeziehungen(beziehung_von);
--	CREATE INDEX vbeziehungen_vontyp ON vbeziehungen(typ_von);
--	CREATE INDEX vbeziehungen_art    ON vbeziehungen(beziehungsart);
--	CREATE INDEX vbeziehungen_zu     ON vbeziehungen(beziehung_zu);
--	CREATE INDEX vbeziehungen_zutyp  ON vbeziehungen(typ_zu);

	RETURN 'ALKIS-Views erzeugt.';
END;
$$ LANGUAGE plpgsql;

-- Indizes erzeugen
SELECT alkis_dropobject('alkis_update_schema');
CREATE FUNCTION alkis_update_schema() RETURNS varchar AS $$
DECLARE
	sql TEXT;
	c RECORD;
	i RECORD;
	n INTEGER;
BEGIN
	-- Spalten in delete ergänzen
	SELECT count(*) INTO n FROM information_schema.columns WHERE table_schema='public' AND table_name='delete' AND column_name='ignored';
	IF n=0 THEN
		ALTER TABLE "delete" ADD ignored BOOLEAN;
	END IF;

	SELECT count(*) INTO n FROM information_schema.columns WHERE table_schema='public' AND table_name='delete' AND column_name='context';
	IF n=0 THEN
		ALTER TABLE "delete" ADD context VARCHAR;
	END IF;

	SELECT count(*) INTO n FROM information_schema.columns WHERE table_schema='public' AND table_name='delete' AND column_name='safetoignore';
	IF n=0 THEN
		ALTER TABLE "delete" ADD safetoignore VARCHAR;
	END IF;

	SELECT count(*) INTO n FROM information_schema.columns WHERE table_schema='public' AND table_name='delete' AND column_name='replacedby';
	IF n=0 THEN
		ALTER TABLE "delete" ADD replacedBy VARCHAR;
	END IF;

	-- Spalte identifier ergänzen, wo sie fehlt
	FOR c IN SELECT table_name FROM information_schema.columns a WHERE a.column_name='gml_id'
		AND     EXISTS (SELECT * FROM information_schema.columns b WHERE b.column_name='beginnt'    AND a.table_catalog=b.table_catalog AND a.table_schema=b.table_schema AND a.table_name=b.table_name)
		AND NOT EXISTS (SELECT * FROM information_schema.columns b WHERE b.column_name='identifier' AND a.table_catalog=b.table_catalog AND a.table_schema=b.table_schema AND a.table_name=b.table_name)
	LOOP
		EXECUTE 'ALTER TABLE ' || c.table_name || ' ADD identifier character(44)';
	END LOOP;

	-- Spalte endet ergänzen, wo sie fehlt
	FOR c IN SELECT table_name FROM information_schema.columns a WHERE a.column_name='gml_id'
		AND     EXISTS (SELECT * FROM information_schema.columns b WHERE b.column_name='beginnt' AND a.table_catalog=b.table_catalog AND a.table_schema=b.table_schema AND a.table_name=b.table_name)
		AND NOT EXISTS (SELECT * FROM information_schema.columns b WHERE b.column_name='endet'   AND a.table_catalog=b.table_catalog AND a.table_schema=b.table_schema AND a.table_name=b.table_name)
	LOOP
		EXECUTE 'ALTER TABLE ' || c.table_name || ' ADD endet character(20) CHECK (endet>beginnt)';
	END LOOP;

	-- Lebensdauer-Constraint ergänzen
	FOR c IN SELECT table_name FROM information_schema.columns a WHERE a.column_name='gml_id'
		AND EXISTS (SELECT * FROM information_schema.columns b WHERE b.column_name='beginnt' AND a.table_catalog=b.table_catalog AND a.table_schema=b.table_schema AND a.table_name=b.table_name)
		AND EXISTS (SELECT * FROM information_schema.columns b WHERE b.column_name='endet'   AND a.table_catalog=b.table_catalog AND a.table_schema=b.table_schema AND a.table_name=b.table_name)
	LOOP
		SELECT alkis_dropobject(c.table_name||'_lebensdauer');
		EXECUTE 'ALTER TABLE ' || c.table_name || ' ADD CONSTRAINT ' || c.table_name || '_lebensdauer CHECK (beginnt IS NOT NULL AND endet>beginnt)';
	END LOOP;

	-- Indizes aktualisieren
	FOR c IN SELECT table_name FROM information_schema.columns a WHERE a.column_name='gml_id'
		AND EXISTS (SELECT * FROM information_schema.columns b WHERE b.column_name='beginnt' AND a.table_catalog=b.table_catalog AND a.table_schema=b.table_schema AND a.table_name=b.table_name)
	LOOP
		-- Vorhandene Indizes droppen (TODO: Löscht auch die Sonderfälle - entfernen)
		FOR i IN EXECUTE 'SELECT indexname FROM pg_indexes WHERE NOT indexname LIKE ''%_pk'' AND schemaname=''public'' AND tablename='''||c.table_name||'''' LOOP
			EXECUTE 'DROP INDEX ' || i.indexname;
		END LOOP;

		-- Indizes erzeugen
		EXECUTE 'CREATE UNIQUE INDEX ' || c.table_name || '_id ON ' || c.table_name || '(gml_id,beginnt)';
		EXECUTE 'CREATE UNIQUE INDEX ' || c.table_name || '_ident ON ' || c.table_name || '(identifier)';
		EXECUTE 'CREATE INDEX ' || c.table_name || '_gmlid ON ' || c.table_name || '(gml_id)';
		EXECUTE 'CREATE INDEX ' || c.table_name || '_beginnt ON ' || c.table_name || '(beginnt)';
		EXECUTE 'CREATE INDEX ' || c.table_name || '_endet ON ' || c.table_name || '(endet)';
	END LOOP;

	-- Geometrieindizes aktualisieren
	FOR c IN SELECT table_name FROM information_schema.columns a WHERE a.column_name='gml_id'
		AND EXISTS (SELECT * FROM information_schema.columns b WHERE b.column_name='wkb_geometry' AND a.table_catalog=b.table_catalog AND a.table_schema=b.table_schema AND a.table_name=b.table_name)
	LOOP
		EXECUTE 'CREATE INDEX ' || c.table_name || '_geom ON ' || c.table_name || ' USING GIST (wkb_geometry)';
	END LOOP;

	RETURN 'Schema aktualisiert.';
END;
$$ LANGUAGE plpgsql;

-- Im Trigger 'delete_feature_trigger' muss eine dieser beiden Funktionen
-- (delete_feature_hist oder delete_feature_kill) verlinkt werden, je nachdem ob nur
-- aktuelle oder auch historische Objekte in der Datenbank geführt werden sollen.

-- Löschsatz verarbeiten (MIT Historie)
-- context='update'        => "endet" auf übergebene Zeit setzen und anlass festhalten
-- context='delete'        => "endet" auf aktuelle Zeit setzen
-- context='replace'       => "endet" des ersetzten auf "beginnt" des neuen Objekts setzen
CREATE OR REPLACE FUNCTION delete_feature_hist() RETURNS TRIGGER AS $$
DECLARE
	s TEXT;
	alt_id TEXT;
	neu_id TEXT;
	beginnt TEXT;
	endete TEXT;
	n INTEGER;
BEGIN
	NEW.context := lower(NEW.context);
	IF NEW.context IS NULL THEN
		NEW.context := 'delete';
	END IF;

	-- TIMESTAMP weder in gml_id noch identifier verläßlich.
	-- also ggf. aus Datenbank holen

	IF length(NEW.featureid)=32 THEN
		alt_id  := substr(NEW.featureid, 1, 16);

		IF NEW.featureid<>NEW.replacedBy THEN
			-- Beginnt-Datum aus Timestamp
			beginnt := substr(NEW.featureid, 17, 4) || '-'
				|| substr(NEW.featureid, 21, 2) || '-'
				|| substr(NEW.featureid, 23, 2) || 'T'
				|| substr(NEW.featureid, 26, 2) || ':'
				|| substr(NEW.featureid, 28, 2) || ':'
				|| substr(NEW.featureid, 30, 2) || 'Z'
				;
		END IF;
	ELSIF length(NEW.featureid)=16 THEN
		alt_id  := NEW.featureid;
	ELSE
		RAISE EXCEPTION '%: Länge 16 oder 32 statt % erwartet.', NEW.featureid, length(NEW.featureid);
	END IF;

	IF beginnt IS NULL THEN
		-- Beginnt-Datum des ältesten Eintrag, der nicht untergegangen ist
		-- => der Satz dessen 'endet' gesetzt werden muß
		EXECUTE 'SELECT min(beginnt) FROM ' || NEW.typename
			|| ' WHERE gml_id=''' || alt_id || ''''
			|| ' AND endet IS NULL'
			INTO beginnt;
	END IF;

	IF beginnt IS NULL THEN
		IF NEW.context = 'delete' OR NEW.safetoignore = 'true' THEN
			RAISE NOTICE 'Kein Beginndatum für Objekt % gefunden - ignoriert.', alt_id;
			NEW.ignored := true;
			RETURN NEW;
		ELSE
			RAISE EXCEPTION 'Kein Beginndatum für Objekt % gefunden.', alt_id;
		END IF;
	END IF;

	IF NEW.context='delete' THEN
		endete := to_char(CURRENT_TIMESTAMP AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS"Z"');

	ELSIF NEW.context='replace' THEN
		NEW.safetoignore := lower(NEW.safetoignore);

		IF NEW.safetoignore IS NULL THEN
			RAISE EXCEPTION '%: safeToIgnore nicht gesetzt.', NEW.featureid;
		ELSIF NEW.safetoignore<>'true' AND NEW.safetoignore<>'false' THEN
			RAISE EXCEPTION '%: safeToIgnore ''%'' ungültig (''true'' oder ''false'' erwartet).', NEW.featureid, NEW.safetoignore;
		END IF;

		IF length(NEW.replacedBy)=32 THEN
			-- Beginnt-Datum aus Timestamp
			IF NEW.featureid<>NEW.replacedBy THEN
				endete  := substr(NEW.replacedBy, 17, 4) || '-'
					|| substr(NEW.replacedBy, 21, 2) || '-'
					|| substr(NEW.replacedBy, 23, 2) || 'T'
					|| substr(NEW.replacedBy, 26, 2) || ':'
					|| substr(NEW.replacedBy, 28, 2) || ':'
					|| substr(NEW.replacedBy, 30, 2) || 'Z'
					;
			END IF;
		ELSIF length(NEW.replacedBy)<>16 THEN
			RAISE EXCEPTION '%: Länge 16 oder 32 statt % erwartet.', NEW.replacedBy, length(NEW.replacedBy);
		END IF;

		neu_id := NEW.replacedBy;
		IF endete IS NULL THEN
			-- Beginnt-Datum des neuesten Eintrag, der nicht untergegangen ist
			-- => Enddatum für vorherigen Satz
			EXECUTE 'SELECT max(beginnt) FROM ' || NEW.typename
				|| ' WHERE gml_id=''' || NEW.replacedBy || ''''
				|| ' AND beginnt>''' || beginnt || ''''
				|| ' AND endet IS NULL'
				INTO endete;
			IF endete IS NULL AND length(NEW.replacedBy)=32 THEN
				EXECUTE 'SELECT max(beginnt) FROM ' || NEW.typename
					|| ' WHERE gml_id=''' || substr(NEW.replacedBy, 1, 16) || ''''
					|| ' AND beginnt>''' || beginnt || ''''
					|| ' AND endet IS NULL'
				INTO endete;
				neu_id := substr(NEW.replacedBy, 1, 16);
			END IF;
		END IF;

		IF alt_id<>substr(neu_id, 1, 16) THEN
			RAISE NOTICE 'Objekt % wird durch Objekt % ersetzt.', alt_id, neu_id;
		END IF;

		IF endete IS NULL THEN
			RAISE NOTICE 'Kein Beginndatum für Objekt % gefunden.', NEW.replacedBy;
		END IF;

		IF endete IS NULL OR beginnt=endete THEN
			RAISE EXCEPTION 'Objekt % wird durch Objekt % ersetzt (leere Lebensdauer?).', alt_id, neu_id;
		END IF;
	ELSIF NEW.context='update' THEN
		endete := NEW.endet;
	ELSE
		RAISE EXCEPTION '%: Ungültiger Kontext % (''delete'', ''replace'' oder ''update'' erwartet).', NEW.featureid, NEW.context;
	END IF;

	s   := 'UPDATE ' || NEW.typename
	    || ' SET endet=''' || endete || ''''
	    || ',anlass=''' || coalesce(NEW.anlass,'000000') || ''''
	    || ' WHERE gml_id=''' || NEW.featureid || ''''
	    || ' AND beginnt=''' || beginnt || ''''
	    || ' AND endet IS NULL';
	EXECUTE s;
	GET DIAGNOSTICS n = ROW_COUNT;
	IF n=0 AND alt_id<>NEW.featureid THEN
		s   := 'UPDATE ' || NEW.typename
		    || ' SET endet=''' || endete || ''''
		    || ',anlass=''' || coalesce(NEW.anlass,'000000') || ''''
		    || ' WHERE gml_id=''' || alt_id || ''''
		    || ' AND beginnt=''' || beginnt || ''''
		    || ' AND endet IS NULL';
		EXECUTE s;
		GET DIAGNOSTICS n = ROW_COUNT;
	END IF;

	IF n<>1 THEN
		RAISE NOTICE 'SQL[%<>1]: %', n, s;
		IF NEW.context = 'delete' OR NEW.safetoignore = 'true' THEN
			RAISE NOTICE '%: Untergangsdatum von % Objekten statt einem auf % gesetzt - ignoriert', NEW.featureid, n, endete;
			NEW.ignored := true;
			RETURN NEW;
		ELSIF n=0 THEN
			EXECUTE 'SELECT endet FROM ' || NEW.typename ||
				' WHERE gml_id=''' || alt_id || '''' ||
				' AND beginnt=''' || beginnt || ''''
				INTO endete;

			IF NOT endete IS NULL THEN
				RAISE NOTICE '%: Objekt bereits % untergegangen - ignoriert', NEW.featureid, endete;
			ELSE
				RAISE NOTICE '%: Objekt nicht gefunden - ignoriert', NEW.featureid;
			END IF;

			NEW.ignored := true;
			RETURN NEW;
		ELSE
			RAISE EXCEPTION '%: Untergangsdatum von % Objekten statt einem auf % gesetzt - Abbruch', NEW.featureid, n, endete;
		END IF;
	END IF;

	NEW.ignored := false;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- Beziehungssätze aufräumen
CREATE OR REPLACE FUNCTION alkis_beziehung_inserted() RETURNS TRIGGER AS $$
BEGIN
	DELETE FROM alkis_beziehungen WHERE ogc_fid<NEW.ogc_fid AND beziehung_von=NEW.beziehung_von AND beziehungsart=NEW.beziehungsart AND beziehung_zu=NEW.beziehung_zu;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Wenn die Datenbank MIT Historie angelegt wurde, kann nach dem Laden hiermit aufgeräumt werden.
CREATE OR REPLACE FUNCTION alkis_delete_all_endet() RETURNS void AS $$
DECLARE
	c RECORD;
BEGIN
	-- In allen Tabellen die Objekte löschen, die ein Ende-Datum haben
	FOR c IN
		SELECT table_name
		FROM information_schema.columns a
		WHERE a.column_name='endet'
		ORDER BY table_name
	LOOP
		EXECUTE 'DELETE FROM ' || c.table_name || ' WHERE NOT endet IS NULL';
		-- RAISE NOTICE 'Lösche ''endet'' in: %', c.table_name;
	END LOOP;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION alkis_exception() RETURNS void AS $$
BEGIN
	RAISE EXCEPTION 'raising deliberate exception';
END;
$$ LANGUAGE plpgsql;

\unset ON_ERROR_STOP
CREATE OR REPLACE FUNCTION alkis_set_comments() RETURNS void AS $$
BEGIN
	-- 8.3 hatte noch keine CTE
	RAISE NOTICE 'Keine Datenbankkommentare bei PostgreSQL 8.3';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION alkis_set_comments() RETURNS void AS $$
DECLARE
	c RECORD;
BEGIN
	FOR c IN
		SELECT table_name,definition,replace(table_type,'BASE TABLE','TABLE') AS table_type
		FROM alkis_elemente
		JOIN information_schema.tables ON lower(name)=table_name
		WHERE table_type IN ('BASE TABLE','VIEW') AND NOT definition IS NULL
	LOOP
		EXECUTE 'COMMENT ON '||c.table_type||' "'||c.table_name||'" IS '''||replace(c.definition,'''','''''')||'''';
	END LOOP;

	FOR c IN
		SELECT table_name,column_name
		FROM alkis_elemente
		JOIN information_schema.columns ON lower(name)=table_name AND 'gml_id'=column_name
	LOOP
		EXECUTE 'COMMENT ON COLUMN '||c.table_name||'.gml_id IS ''Identifikator, global eindeutig''';
	END LOOP;

	FOR c IN
		WITH RECURSIVE
			element(name,base) AS (
				SELECT name,unnest(name||abgeleitet_aus) AS base
				FROM alkis_elemente
			UNION
				SELECT a.name,unnest(b.abgeleitet_aus) AS base
				FROM element a
				JOIN alkis_elemente b ON a.base=b.name
			),
			typ(element,bezeichnung,datentyp,kardinalitaet,kennung,definition) AS (
				SELECT element,bezeichnung,datentyp,kardinalitaet,kennung,definition FROM alkis_attributart
				UNION
				SELECT b.element,a.bezeichnung,a.datentyp,a.kardinalitaet,a.kennung,a.definition FROM alkis_attributart a JOIN typ b ON a.element=lower(b.datentyp)
                                -- FIXME: kommen unterschiedliche Kardinalitäten bei Element und Attribut vor?
		        )
		SELECT col.table_name,col.column_name,a.definition,a.datentyp,a.kardinalitaet,a.kennung
		FROM element t
		JOIN typ a ON t.base=a.element
		JOIN information_schema.columns col ON lower(t.name)=col.table_name AND lower(a.bezeichnung)=col.column_name
		WHERE NOT a.definition IS NULL
	LOOP
		EXECUTE 'COMMENT ON COLUMN "'||c.table_name||'"."'||c.column_name||'" IS '''||c.kennung||'['||c.datentyp||CASE WHEN c.kardinalitaet='1' THEN '' ELSE ' '||c.kardinalitaet END||'] '||replace(c.definition,'''','''''')||'''';
	END LOOP;

	FOR c IN
		SELECT table_name,column_name,zielobjektart,kardinalitaet,anmerkung
		FROM alkis_relationsart
		JOIN information_schema.columns ON lower(element)=table_name AND lower(bezeichnung)=column_name
		WHERE NOT anmerkung IS NULL
	LOOP
		EXECUTE 'COMMENT ON COLUMN "'||c.table_name||'"."'||c.column_name||'" IS ''Beziehung zu '||c.zielobjektart||' ('||c.kardinalitaet||'): '||replace(c.anmerkung,'''','''''')||'''';
	END LOOP;

	FOR c IN
		SELECT table_name,column_name,bezeichnung,element,kardinalitaet FROM alkis_relationsart
		JOIN information_schema.columns ON lower(zielobjektart)=table_name AND lower(inv__relation)=column_name
	LOOP
		EXECUTE 'COMMENT ON COLUMN "'||c.table_name||'"."'||c.column_name||'" IS ''Inverse Beziehung zu '||c.element||'.'||c.bezeichnung||'.''';
	END LOOP;
END;
$$ LANGUAGE plpgsql;

\set ON_ERROR_STOP
