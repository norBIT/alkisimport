/****************************************************************************
 *
 * Project:  norGIS ALKIS Import
 * Purpose:  SQL-Funktionen für ALKIS
 * Author:   Jürgen E. Fischer <jef@norbit.de>
 *
 ****************************************************************************
 * Copyright (c) 2012-2014, Jürgen E. Fischer <jef@norbit.de>
 *
 *   This program is free software; you can redistribute it and/or modify
 *   it under the terms of the GNU General Public License as published by
 *   the Free Software Foundation; either version 2 of the License, or
 *   (at your option) any later version.
 *
 ****************************************************************************/

SELECT alkis_dropobject('alkis_string_append');
CREATE OR REPLACE FUNCTION alkis_string_append(r varchar, m varchar) RETURNS varchar AS $$
	SELECT CASE WHEN r='' OR r LIKE E'%\n' THEN r ELSE coalesce(r||E'\n','') END || coalesce(m, '');
$$ LANGUAGE 'sql' IMMUTABLE;

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
	-- drop objects
	FOR c IN SELECT relkind,relname
		FROM pg_class
		JOIN pg_namespace ON pg_class.relnamespace=pg_namespace.oid
		WHERE pg_namespace.nspname='public' AND pg_class.relname=t
		ORDER BY relkind
	LOOP
		IF c.relkind = 'v' THEN
			r := alkis_string_append(r, 'Sicht ' || c.relname || ' gelöscht.');
			EXECUTE 'DROP VIEW ' || c.relname || ' CASCADE';
		ELSIF c.relkind = 'r' THEN
			r := alkis_string_append(r, 'Tabelle ' || c.relname || ' gelöscht.');
			EXECUTE 'DROP TABLE ' || c.relname || ' CASCADE';
		ELSIF c.relkind = 'S' THEN
			r := alkis_string_append(r, 'Sequenz ' || c.relname || ' gelöscht.');
			EXECUTE 'DROP SEQUENCE ' || c.relname;
		ELSIF c.relkind <> 'i' THEN
			r := alkis_string_append(r, 'Typ ' || c.table_type || '.' || c.table_name || ' unerwartet.');
		END IF;
	END LOOP;

	FOR c IN SELECT indexname FROM pg_indexes WHERE schemaname='public' AND indexname=t
	LOOP
		r := alkis_string_append(r, 'Index ' || c.indexname || ' gelöscht.');
		EXECUTE 'DROP INDEX ' || c.indexname;
	END LOOP;

	FOR c IN SELECT proname,proargtypes
		FROM pg_proc
		JOIN pg_namespace ON pg_proc.pronamespace=pg_namespace.oid
		WHERE pg_namespace.nspname='public' AND pg_proc.proname=t
	LOOP
		r := alkis_string_append(r, 'Funktion ' || c.proname || ' gelöscht.');

		s := 'DROP FUNCTION ' || c.proname || '(';
		d := '';

		FOR i IN array_lower(c.proargtypes,1)..array_upper(c.proargtypes,1) LOOP
			SELECT typname INTO tn FROM pg_type WHERE oid=c.proargtypes[i];
			s := s || d || tn;
			d := ',';
		END LOOP;

		s := s || ')';

		EXECUTE s;
	END LOOP;

	FOR c IN SELECT relname,conname
		FROM pg_constraint
		JOIN pg_class ON pg_constraint.conrelid=pg_constraint.oid
		JOIN pg_namespace ON pg_constraint.connamespace=pg_namespace.oid
		WHERE pg_namespace.nspname='public' AND pg_constraint.conname=t
	LOOP
		r := alkis_string_append(r, 'Constraint ' || c.conname || ' von ' || c.relname || ' gelöscht.');
		EXECUTE 'ALTER TABLE ' || c.relname || ' DROP CONSTRAINT ' || c.conname;
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
BEGIN
	-- drop tables & views
	FOR c IN SELECT table_type,table_name FROM information_schema.tables
		   WHERE table_schema='public'
		     AND ( substr(table_name,1,3) IN ('ax_','ap_','ks_','aa_')
			   OR table_name IN ('alkis_beziehungen','delete','alkis_version') )
		   ORDER BY table_type DESC LOOP
		IF c.table_type = 'VIEW' THEN
			r := alkis_string_append(r, 'Sicht ' || c.table_name || ' gelöscht.');
			EXECUTE 'DROP VIEW ' || c.table_name || ' CASCADE';
		ELSIF c.table_type = 'BASE TABLE' THEN
			r := alkis_string_append(r, 'Tabelle ' || c.table_name || ' gelöscht.');
			EXECUTE 'DROP TABLE ' || c.table_name || ' CASCADE';
		ELSE
			r := alkis_string_append(r, 'Typ ' || c.table_type || '.' || c.table_name || ' unerwartet.');
		END IF;
	END LOOP;

	-- clean geometry_columns
	DELETE FROM geometry_columns
		WHERE f_table_schema='public'
		AND ( substr(f_table_name,1,2) IN ('ax_','ap_','ks_','aa_')
		 OR f_table_name IN ('alkis_beziehungen','delete') );

	RETURN r;
END;
$$ LANGUAGE plpgsql;

-- Alle ALKIS-Tabellen leeren
SELECT alkis_dropobject('alkis_clean');
CREATE FUNCTION alkis_clean() RETURNS varchar AS $$
DECLARE
	c RECORD;
	r VARCHAR;
BEGIN
	-- clean tables
	FOR c IN SELECT table_name FROM information_schema.tables
		   WHERE table_schema='public' AND table_type='BASE TABLE'
		     AND ( substr(table_name,1,3) IN ('ax_','ap_','ks_','aa_')
			   OR table_name IN ('alkis_beziehungen','delete') )
		   ORDER BY table_type DESC LOOP
		r := alkis_string_append(r, 'Tabelle ' || c.table_name || ' geleert.');
		EXECUTE 'DELETE FROM ' || c.table_name;
	END LOOP;

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
BEGIN
	-- drop views
	FOR c IN
		SELECT table_name
		FROM information_schema.tables
		WHERE table_schema='public' AND table_type='BASE TABLE'
		  AND ( substr(table_name,1,3) IN ('ax_','ap_','ks_','aa_')
			OR table_name IN ('alkis_beziehungen','delete') )
	LOOP
		r := alkis_string_append(r, c.table_name || ' wurde geleert.');
		EXECUTE 'TRUNCATE '||c.table_name;
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

	FOR c IN SELECT table_name FROM information_schema.columns
		   WHERE column_name='gml_id'
		     AND substr(table_name,1,3) IN ('ax_','ap_','ks_','aa_')
		     AND NOT table_name IN ('ax_tatsaechlichenutzung','ax_klassifizierung','ax_ausfuehrendestellen') LOOP
		sql := sql || delim || 'SELECT gml_id,beginnt,endet,''' || c.table_name || ''' AS table_name FROM ' || c.table_name;
		delim := ' UNION ';
	END LOOP;

	EXECUTE sql;

	CREATE VIEW vbeziehungen AS
		SELECT beziehung_von,(SELECT DISTINCT table_name FROM vobjekte WHERE gml_id=beziehung_von) AS typ_von
			,beziehungsart
			,beziehung_zu,(SELECT DISTINCT table_name FROM vobjekte WHERE gml_id=beziehung_zu) AS typ_zu
		FROM alkis_beziehungen;

	RETURN 'ALKIS-Views erzeugt.';
END;
$$ LANGUAGE plpgsql;

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
		WHERE a.column_name='endet' AND a.is_updatable='YES'
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

CREATE OR REPLACE FUNCTION alkis_hist_check() RETURNS varchar AS $$
DECLARE
	c RECORD;
	n INTEGER;
	r VARCHAR;
BEGIN
	FOR c IN SELECT table_name FROM information_schema.tables WHERE table_schema='public' AND substr(table_name,1,3) IN ('ax_','ap_','ks_','aa_') AND table_type='BASE TABLE'
	LOOP
		EXECUTE 'SELECT count(*) FROM ' || c.table_name || ' WHERE endet IS NULL GROUP BY gml_id HAVING count(*)>1' INTO n;
		IF n>1 THEN
			r := alkis_string_append(r, c.table_name || ': ' || n || ' Objekte, die in mehreren Versionen nicht beendet sind.');
		END IF;

		EXECUTE 'SELECT count(*) FROM ' || c.table_name || ' WHERE beginnt>=endet' INTO n;
		IF n>1 THEN
			r := alkis_string_append(r, c.table_name || ': ' || n || ' Objekte mit ungültiger Lebensdauer.');
		END IF;

		EXECUTE 'SELECT count(*)'
			|| ' FROM ' || c.table_name || ' a'
			|| ' JOIN ' || c.table_name || ' b ON a.gml_id=b.gml_id AND a.ogc_fid<>b.ogc_fid AND a.beginnt<b.endet AND a.endet>b.beginnt'
			INTO n;
		IF n>0 THEN
			r := alkis_string_append(r, c.table_name || ': ' || n || ' Lebensdauerüberschneidungen.');
		END IF;
	END LOOP;

	RETURN coalesce(r,'Keine Fehler gefunden.');
END;
$$ LANGUAGE plpgsql;

SELECT alkis_dropobject('alkis_bufferline');
CREATE FUNCTION alkis_bufferline(g geometry,offs float8) RETURNS geometry AS $$
BEGIN
	BEGIN
		RETURN st_buffer(g,offs,'endcap=flat');
	EXCEPTION WHEN OTHERS THEN
		IF geometrytype(g) = 'LINESTRING' THEN
			DECLARE
				g0 GEOMETRY;
				g1 GEOMETRY;
				g2 GEOMETRY;
			BEGIN
				SELECT alkis_offsetcurve(g,offs,'') INTO g0;
				SELECT st_reverse( alkis_offsetcurve(g,-offs,'') ) INTO g1;

				g2 := st_makepolygon( st_linemerge( st_collect(
					ARRAY[
						g0, st_makeline( st_endpoint(g0), st_startpoint(g1) ),
						g1, st_makeline( st_endpoint(g1), st_startpoint(g0) )
					]
				) ) );

				IF geometrytype(g2) <> 'POLYGON' THEN
					RAISE EXCEPTION 'alkis_bufferline: POLYGON expected, % found', geometrytype(g2);
				END IF;

				RETURN g2;
			END;
		ELSE
			RAISE EXCEPTION 'alkis_bufferline: LINESTRING expected, % found', geometrytype(g);
		END IF;
	END;
END;
$$ LANGUAGE plpgsql;

\unset ON_ERROR_STOP

-- 8.3 hatte noch keine CTE => Funktionen mit WITH RECURSIVE werden nicht definiert.

--
-- Datenbankmigration
--

SELECT alkis_dropobject('alkis_update_schema');
CREATE OR REPLACE FUNCTION alkis_update_schema() RETURNS varchar AS $$
BEGIN
	RETURN 'Keine Datenbankmigration bei PostgreSQL 8.3';
END;
$$ LANGUAGE plpgsql;

SELECT alkis_dropobject('alkis_rename_table');
CREATE OR REPLACE FUNCTION alkis_rename_table(t TEXT) RETURNS varchar AS $$
BEGIN
	PERFORM alkis_dropobject(t || '_');

	EXECUTE 'ALTER TABLE ' || t || ' RENAME TO ' || t || '_';

	PERFORM alkis_dropobject(t || '_geom_idx');		   -- < GDAL 1.11
	PERFORM alkis_dropobject(t || '_wkb_geometry_geom_idx');   -- >= GDAL 1.11

	RETURN t || ' umbenannt - INHALT MANUELL MIGRIEREN.';
EXCEPTION WHEN OTHERS THEN
	RETURN '';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION alkis_update_schema() RETURNS varchar AS $$
DECLARE
	c RECORD;
	s INTEGER;
	n INTEGER;
	i INTEGER;
	v INTEGER;
	r TEXT;
BEGIN
	r := NULL;

	--
	-- ALKIS-Schema
	--
	SELECT count(*) INTO n FROM information_schema.columns
		WHERE table_schema='public'
		  AND table_name='ax_flurstueck'
		  AND column_name='sonstigesmodell';
	IF n=0 THEN
		RAISE EXCEPTION 'Modell zu alt für Migration.';
	END IF;

	BEGIN
		SELECT version INTO v FROM alkis_version;

	EXCEPTION WHEN OTHERS THEN
		v := 0;
		CREATE TABLE alkis_version(version INTEGER);
		INSERT INTO alkis_version(version) VALUES (v);

		BEGIN ALTER TABLE ax_schutzgebietnachnaturumweltoderbodenschutzrecht ADD name varchar; EXCEPTION WHEN OTHERS THEN END;
	END;

	RAISE NOTICE 'ALKIS-Schema-Version: %', v;

	IF v<1 THEN
		RAISE NOTICE 'Migriere auf Schema-Version 1';

		PERFORM alkis_dropobject('ax_tatsaechlichenutzung');
		PERFORM alkis_dropobject('ax_klassifizierung');
		PERFORM alkis_dropobject('ax_ausfuehrendestellen');
		PERFORM alkis_dropobject('v_eigentuemer');
		PERFORM alkis_dropobject('v_haeuser');
		PERFORM alkis_dropobject('v_schutzgebietnachwasserrecht');
		PERFORM alkis_dropobject('v_schutzgebietnachnaturumweltoderbodenschutzrecht');

		ALTER TABLE ax_flurstueck ALTER angabenzumabschnittnummeraktenzeichen TYPE varchar[];
		ALTER TABLE ax_georeferenziertegebaeudeadresse ALTER ortsteil TYPE varchar;
		ALTER TABLE ax_historischesflurstueck ALTER zaehler TYPE varchar;
		ALTER TABLE ax_historischesflurstueckohneraumbezug ALTER zaehler TYPE varchar;
		ALTER TABLE ax_historischesflurstueckohneraumbezug ALTER rechtsbehelfsverfahren TYPE varchar;
		ALTER TABLE ax_gebaeude ALTER geschossflaeche TYPE double precision;
		ALTER TABLE ax_gebaeude ALTER grundflaeche TYPE double precision;
		ALTER TABLE ax_gebaeude ALTER umbauterraum TYPE double precision;
		ALTER TABLE ax_bodenschaetzung ALTER bodenzahlodergruenlandgrundzahl TYPE varchar;
		ALTER TABLE ax_bodenschaetzung ALTER ackerzahlodergruenlandzahl TYPE varchar;
		ALTER TABLE ax_grablochderbodenschaetzung ALTER bodenzahlodergruenlandgrundzahl TYPE varchar;
		ALTER TABLE ax_gemarkungsteilflur ADD gehoertzu character(16)[];
		CREATE INDEX ax_gemarkungsteilflur_ghz ON ax_gemarkungsteilflur USING gin (gehoertzu);
		ALTER TABLE ax_dienststelle ADD kennung varchar;
		ALTER TABLE ax_wohnplatz ADD zweitname varchar;
		ALTER TABLE ax_baublock ADD art integer;

		-- gml_id: varchar => character(16)
		s := 0;
		i := 0;
		FOR c IN
			SELECT table_name
			FROM information_schema.columns a
			WHERE a.table_schema='public'
			  AND (a.table_name LIKE 'ax_%' OR a.table_name LIKE 'ap_%')
			  AND a.column_name='gml_id'
			  AND a.data_type='character varying'
		LOOP
			-- RAISE NOTICE '%', 'UPDATE ' || c.table_name || ' SET gml_id=substring(gml_id,1,16) WHERE length(gml_id)>16';
			EXECUTE 'UPDATE ' || c.table_name || ' SET gml_id=substring(gml_id,1,16) WHERE length(gml_id)>16';
			GET DIAGNOSTICS n = ROW_COUNT;
			s := s + n;

			-- RAISE NOTICE '%', 'ALTER TABLE ' || c.table_name || ' ALTER COLUMN gml_id TYPE character(16)';
			EXECUTE 'ALTER TABLE ' || c.table_name || ' ALTER COLUMN gml_id TYPE character(16)';
			i := i + 1;
		END LOOP;

		IF i > 0 OR s > 0 THEN
			r := alkis_string_append(r, i || ' Tabellen mit ' || s || ' lange AAA-Identifikatoren geändert.');
		END IF;

		-- land, gemarkungsnummer, gemeinde, regierungsbezirk, bezirk, kreis, schluesselgesamt: integer => varchar
		i := 0;
		FOR c IN
			SELECT table_name, column_name
			FROM information_schema.columns a
			WHERE a.table_schema='public'
			  AND a.table_name LIKE 'ax_%'
			  AND a.column_name IN ('land','gemarkungsnummer','gemeinde','regierungsbezirk','bezirk','kreis','schluesselgesamt')
			  AND a.data_type='integer'
		LOOP
			-- RAISE NOTICE '%', 'ALTER TABLE ' || c.table_name || ' ALTER COLUMN ' || c.column_name || ' TYPE character varying';
			EXECUTE 'ALTER TABLE ' || c.table_name || ' ALTER COLUMN ' || c.column_name || ' TYPE character varying';
			i := i + 1;
		END LOOP;

		IF i > 0 THEN
			r := alkis_string_append(r, i || ' Spalten angepaßt (integer->character varying).');
		END IF;

		-- Relationen: varchar => character(16) bzw. varchar[] => character(16)[]
		i := 0;
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
				relation(element,bezeichnung,kennung) AS (
					SELECT element,bezeichnung,kennung FROM alkis_relationsart
					UNION
					SELECT b.element,a.bezeichnung,a.kennung FROM alkis_relationsart a JOIN relation b ON a.element=lower(b.bezeichnung)
				)
			SELECT col.table_name,col.column_name,col.udt_name
			FROM element t
			JOIN relation a ON t.base=a.element
			JOIN information_schema.columns col ON lower(t.name)=col.table_name AND lower(a.bezeichnung)=col.column_name
			WHERE col.udt_name IN ('_varchar','varchar')
		LOOP
			IF c.udt_name='_varchar' THEN
				-- RAISE NOTICE '%', 'ALTER TABLE ' || c.table_name || ' ALTER COLUMN ' || c.column_name || ' TYPE character(16)[]';
				EXECUTE 'ALTER TABLE ' || c.table_name || ' ALTER COLUMN ' || c.column_name || ' TYPE character(16)[]';
				i := i + 1;
			ELSE
				-- RAISE NOTICE '%', 'UPDATE ' || c.table_name || ' SET ' || c.column_name || '=' || 'substring('||c.column_name||',1,16) WHERE length('||c.column_name||')>16';
				EXECUTE 'UPDATE ' || c.table_name || ' SET ' || c.column_name || '=' || 'substring('||c.column_name||',1,16) WHERE length('||c.column_name||')>16';

				-- RAISE NOTICE '%', 'ALTER TABLE ' || c.table_name || ' ALTER COLUMN ' || c.column_name || ' TYPE character(16)';
				EXECUTE 'ALTER TABLE ' || c.table_name || ' ALTER COLUMN ' || c.column_name || ' TYPE character(16)';
				i := i + 1;
			END IF;
		END LOOP;

		IF i > 0 THEN
			r := alkis_string_append(r, i || ' Spalten angepaßt (varchar->character(16)).');
		END IF;

		UPDATE alkis_version SET version=1;
	END IF;

	IF v<2 THEN
		RAISE NOTICE 'Migriere auf Schema-Version 2';

		-- Indizes ergänzen
		CREATE UNIQUE INDEX ax_sicherungspunkt_gmlid ON ax_sicherungspunkt USING btree (gml_id,beginnt);
		CREATE INDEX ax_sicherungspunkt_bsa ON ax_sicherungspunkt USING btree (beziehtsichauf);
		CREATE INDEX ax_sicherungspunkt_ghz ON ax_sicherungspunkt USING btree (gehoertzu);

		-- drop identifier
		i := 0;
		FOR c IN
			SELECT table_name
			FROM information_schema.columns a
			WHERE a.table_schema='public'
			  AND (a.table_name LIKE 'ax_%' OR a.table_name LIKE 'ap_%')
			  AND a.column_name='identifier'
		LOOP
			-- RAISE NOTICE '%', 'ALTER TABLE ' || c.table_name || ' DROP COLUMN identifier';
			EXECUTE 'ALTER TABLE ' || c.table_name || ' DROP COLUMN identifier';
			i := i + 1;
		END LOOP;

		IF i > 0 THEN
			r := alkis_string_append(r, i || ' identifier-Spalten gelöscht.');
		END IF;

		UPDATE alkis_version SET version=2;
	END IF;

	IF v<3 THEN
		RAISE NOTICE 'Migriere auf Schema-Version 3';

		ALTER TABLE ax_fortfuehrungsfall ALTER zeigtaufaltesflurstueck TYPE character(20)[];
		ALTER TABLE ax_fortfuehrungsfall ALTER zeigtaufneuesflurstueck TYPE character(20)[];

		UPDATE alkis_version SET version=3;
	END IF;

	IF v<4 THEN
		RAISE NOTICE 'Migriere auf Schema-Version 4';

		BEGIN
			ALTER TABLE ax_lagebezeichnungmithausnummer ADD unverschluesselt varchar;
			ALTER TABLE ax_lagebezeichnungmitpseudonummer ADD unverschluesselt varchar;
		EXCEPTION WHEN OTHERS THEN
			--
		END;

		UPDATE alkis_version SET version=4;
	END IF;

	IF v<5 THEN
		RAISE NOTICE 'Migriere auf Schema-Version 5';

		DROP INDEX delete_fid;
		CREATE INDEX delete_fid ON "delete"(featureid);

		UPDATE alkis_version SET version=5;
	END IF;

	IF v<6 THEN
		RAISE NOTICE 'Migriere auf Schema-Version 6';

		CREATE INDEX ap_ppo_art ON ap_ppo USING btree (art);
		CREATE INDEX ap_lpo_art ON ap_lpo USING btree (art);

		UPDATE alkis_version SET version=6;
	END IF;

	IF v<7 THEN
		RAISE NOTICE 'Migriere auf Schema-Version 7';

		ALTER TABLE ax_gebaeude ADD gebaeudekennzeichen varchar;
		ALTER TABLE ax_gebaeude RENAME baujahr TO baujahr_;
		ALTER TABLE ax_gebaeude ADD baujahr integer[];
		UPDATE ax_gebaeude SET baujahr=ARRAY[baujahr_];
		ALTER TABLE ax_gebaeude DROP baujahr_;

		UPDATE alkis_version SET version=7;
	END IF;

	IF v<8 THEN
		RAISE NOTICE 'Migriere auf Schema-Version 8';

		BEGIN
			ALTER TABLE ax_tagesabschnitt DROP CONSTRAINT enforce_geotype_wkb_geometry;
		EXCEPTION WHEN OTHERS THEN
			ALTER TABLE ax_tagesabschnitt RENAME wkb_geometry TO wkb_geometry_;
			PERFORM AddGeometryColumn('ax_tagesabschnitt','wkb_geometry',find_srid('','ax_flurstueck','wkb_geometry'),'GEOMETRY',2);
			UPDATE ax_tagesabschnitt SET wkb_geometry=wkb_geometry_;
			ALTER TABLE ax_tagesabschnitt DROP wkb_geometry_;

			CREATE INDEX ax_tagesabschnitt_geom_idx ON ax_tagesabschnitt USING gist(wkb_geometry);
		END;

		UPDATE alkis_version SET version=8;
	END IF;

	IF v<9 THEN
		RAISE NOTICE 'Migriere auf Schema-Version 9';

		BEGIN
			ALTER TABLE ax_topographischelinie DROP CONSTRAINT enforce_geotype_wkb_geometry;
		EXCEPTION WHEN OTHERS THEN
			ALTER TABLE ax_topographischelinie RENAME wkb_geometry TO wkb_geometry_;
			PERFORM AddGeometryColumn('ax_topographischelinie','wkb_geometry',find_srid('','ax_flurstueck','wkb_geometry'),'GEOMETRY',2);
			UPDATE ax_topographischelinie SET wkb_geometry=wkb_geometry_;
			ALTER TABLE ax_topographischelinie DROP wkb_geometry_;

			CREATE INDEX ax_topographischelinie_geom_idx ON ax_topographischelinie USING gist(wkb_geometry);
		END;

		UPDATE alkis_version SET version=9;
	END IF;

	IF v<10 THEN
		RAISE NOTICE 'Migriere auf Schema-Version 10';

		i := 0;
		FOR c IN
			SELECT table_name
			FROM information_schema.columns a
			WHERE a.table_schema='public'
			  AND (a.table_name LIKE 'ax_%' OR a.table_name LIKE 'ap_%' OR a.table_name LIKE 'ks_%')
			  AND a.column_name='anlass'
			  AND a.data_type='character varying'
		LOOP
			EXECUTE 'ALTER TABLE ' || c.table_name || ' RENAME anlass TO anlass_';
			EXECUTE 'ALTER TABLE ' || c.table_name || ' ADD anlass varchar[]';
			EXECUTE 'UPDATE ' || c.table_name || ' SET anlass=ARRAY[anlass_]';
			EXECUTE 'ALTER TABLE ' || c.table_name || ' DROP anlass_';
			i := i + 1;
		END LOOP;

		IF i > 0 THEN
			r := alkis_string_append(r, i || ' anlass-Spalten angepaßt (character varying->character varying[])');
		END IF;

		UPDATE alkis_version SET version=10;
	END IF;

	IF v<11 THEN
		RAISE NOTICE 'Migriere auf Schema-Version 11';

		EXECUTE 'ALTER TABLE "delete" RENAME anlass TO anlass_';
		EXECUTE 'ALTER TABLE "delete" ADD anlass varchar[]';
		EXECUTE 'UPDATE "delete" SET anlass=ARRAY[anlass_]';
		EXECUTE 'ALTER TABLE "delete" DROP anlass_';

		IF i > 0 THEN
			r := alkis_string_append(r, 'Spalte delete.anlass angepaßt (character varying->character varying[])');
		END IF;

		UPDATE alkis_version SET version=11;
	END IF;

	IF v<12 THEN
		RAISE NOTICE 'Migriere auf Schema-Version 12';

		ALTER TABLE ks_einrichtunginoeffentlichenbereichen ADD oberflaechenmaterial integer;
		ALTER TABLE ks_einrichtunginoeffentlichenbereichen ADD material integer[];
		ALTER TABLE ks_einrichtunginoeffentlichenbereichen ADD bezeichnung varchar;
		ALTER TABLE ks_einrichtunginoeffentlichenbereichen ADD zustand integer;

		CREATE INDEX ks_einrichtunginoeffentlichenbereichen_geom_idx ON ks_einrichtunginoeffentlichenbereichen USING gist (wkb_geometry);

		r := alkis_string_append(r, alkis_rename_table('ks_bauwerkanlagenfuerverundentsorgung'));

		CREATE TABLE ks_bauwerkanlagenfuerverundentsorgung (
			ogc_fid                 serial NOT NULL,
			gml_id                  character(16) NOT NULL,
			beginnt                 character(20),
			endet                   character(20),
			advstandardmodell       varchar[],
			sonstigesmodell         varchar[],
			anlass                  varchar[],
			art                     integer,
			bezeichnung             varchar,
			zustand                 integer,
			PRIMARY KEY (ogc_fid)
		);

		PERFORM AddGeometryColumn('ks_bauwerkanlagenfuerverundentsorgung','wkb_geometry',find_srid('','ax_flurstueck','wkb_geometry'),'POINT',2);

		CREATE INDEX ks_bauwerkanlagenfuerverundentsorgung_geom_idx ON ks_bauwerkanlagenfuerverundentsorgung USING gist (wkb_geometry);

		ALTER TABLE ks_sonstigesbauwerk ADD advstandardmodell varchar[];
		ALTER TABLE ks_sonstigesbauwerk ADD bezeichnung varchar;

		r := alkis_string_append(r, alkis_rename_table('ks_einrichtungimstrassenverkehr'));

		CREATE TABLE ks_einrichtungimstrassenverkehr(
			ogc_fid                 serial NOT NULL,
			gml_id                  character(16) NOT NULL,
			beginnt                 character(20),
			endet                   character(20),
			advstandardmodell       varchar[],
			sonstigesmodell         varchar[],
			anlass                  varchar[],
			art                     integer,
			oberflaechenmaterial    integer,
			bezeichnung             varchar,
			zustand                 integer,
			PRIMARY KEY (ogc_fid)
		);

		PERFORM AddGeometryColumn('ks_einrichtungimstrassenverkehr','wkb_geometry',find_srid('','ax_flurstueck','wkb_geometry'),'GEOMETRY',2);

		CREATE INDEX ks_einrichtungimstrassenverkehr_geom_idx ON ks_einrichtungimstrassenverkehr USING gist (wkb_geometry);

		ALTER TABLE ks_verkehrszeichen ADD gefahrzeichen integer[];
		ALTER TABLE ks_verkehrszeichen ADD vorschriftzeichen integer[];
		ALTER TABLE ks_verkehrszeichen ADD richtzeichen integer[];

		ALTER TABLE ks_verkehrszeichen RENAME verkehrseinrichtung TO verkehrseinrichtung_;
		ALTER TABLE ks_verkehrszeichen ADD verkehrseinrichtung integer[];
		UPDATE ks_verkehrszeichen SET verkehrseinrichtung=ARRAY[verkehrseinrichtung_];
		ALTER TABLE ks_verkehrszeichen DROP verkehrseinrichtung_;

		ALTER TABLE ks_verkehrszeichen ADD zusatzzeichen integer[];
		ALTER TABLE ks_verkehrszeichen ADD bezeichnung varchar;

		r := alkis_string_append(r, alkis_rename_table('ks_einrichtungimbahnverkehr'));

		CREATE TABLE ks_einrichtungimbahnverkehr(
			ogc_fid                 serial NOT NULL,
			gml_id                  character(16) NOT NULL,
			beginnt                 character(20),
			endet                   character(20),
			advstandardmodell       varchar[],
			sonstigesmodell         varchar[],
			anlass                  varchar[],
			art                     integer,
			bezeichnung             varchar,
			PRIMARY KEY (ogc_fid)
		);

		PERFORM AddGeometryColumn('ks_einrichtungimbahnverkehr','wkb_geometry',find_srid('','ax_flurstueck','wkb_geometry'),'GEOMETRY',2);

		CREATE INDEX ks_einrichtungimbahnverkehr_geom_idx ON ks_einrichtungimbahnverkehr USING gist (wkb_geometry);

		r := alkis_string_append(r, alkis_rename_table('ks_bauwerkimgewaesserbereich'));

		CREATE TABLE ks_bauwerkimgewaesserbereich (
			ogc_fid                 serial NOT NULL,
			gml_id                  character(16) NOT NULL,
			beginnt                 character(20),
			endet                   character(20),
			advstandardmodell       varchar[],
			sonstigesmodell         varchar[],
			anlass                  varchar[],
			bauwerksfunktion        integer,
			bezeichnung             varchar,
			zustand                 integer,
			PRIMARY KEY (ogc_fid)
		);

		PERFORM AddGeometryColumn('ks_bauwerkimgewaesserbereich','wkb_geometry',find_srid('','ax_flurstueck','wkb_geometry'),'LINESTRING',2);

		CREATE INDEX ks_bauwerkimgewaesserbereich_geom_idx ON ks_bauwerkimgewaesserbereich USING gist (wkb_geometry);

		r := alkis_string_append(r, alkis_rename_table('ks_vegetationsmerkmal'));

		CREATE TABLE ks_vegetationsmerkmal (
			ogc_fid                 serial NOT NULL,
			gml_id                  character(16) NOT NULL,
			beginnt                 character(20),
			endet                   character(20),
			advstandardmodell       varchar[],
			sonstigesmodell         varchar[],
			anlass                  varchar[],
			bewuchs                 integer,
			zustand                 integer,
			breitedesobjekts        double precision,
			name                    varchar,
			bezeichnung             varchar,
			PRIMARY KEY (ogc_fid)
		);

		PERFORM AddGeometryColumn('ks_vegetationsmerkmal','wkb_geometry',find_srid('','ax_flurstueck','wkb_geometry'),'GEOMETRY',2);

		CREATE INDEX ks_vegetationsmerkmal_geom_idx ON ks_vegetationsmerkmal USING gist (wkb_geometry);

		r := alkis_string_append(r, alkis_rename_table('ks_bauraumoderbodenordnungsrecht'));

		CREATE TABLE ks_bauraumoderbodenordnungsrecht (
			ogc_fid                 serial NOT NULL,
			gml_id                  character(16) NOT NULL,
			beginnt                 character(20),
			endet                   character(20),
			advstandardmodell       varchar[],
			sonstigesmodell         varchar[],
			anlass                  varchar[],
			artderfestlegung        integer,
			bezeichnung             varchar,
			PRIMARY KEY (ogc_fid)
		);

		PERFORM AddGeometryColumn('ks_bauraumoderbodenordnungsrecht','wkb_geometry',find_srid('','ax_flurstueck','wkb_geometry'),'GEOMETRY',2);

		CREATE INDEX ks_bauraumoderbodenordnungsrecht_geom_idx ON ks_vegetationsmerkmal USING gist (wkb_geometry);

		r := alkis_string_append(r, alkis_rename_table('ks_kommunalerbesitz'));

		CREATE TABLE ks_kommunalerbesitz (
			ogc_fid                 serial NOT NULL,
			gml_id                  character(16) NOT NULL,
			beginnt                 character(20),
			endet                   character(20),
			advstandardmodell       varchar[],
			sonstigesmodell         varchar[],
			anlass                  varchar[],
			zustaendigkeit          varchar,
			nutzung                 varchar,
			PRIMARY KEY (ogc_fid)
		);

		PERFORM AddGeometryColumn('ks_kommunalerbesitz','wkb_geometry',find_srid('','ax_flurstueck','wkb_geometry'),'GEOMETRY',2);

		CREATE INDEX ks_kommunalerbesitz_geom_idx ON ks_vegetationsmerkmal USING gist (wkb_geometry);

		UPDATE alkis_version SET version=12;
	END IF;

	IF v<13 THEN
		RAISE NOTICE 'Migriere auf Schema-Version 13';

		r := alkis_string_append(r, alkis_rename_table('ax_landschaft'));

		CREATE TABLE ax_landschaft(
			ogc_fid                 serial NOT NULL,
			gml_id                  character(16) NOT NULL,
			beginnt                 character(20),
			endet                   character(20),
			advstandardmodell       varchar[],
			sonstigesmodell         varchar[],
			anlass                  varchar[],
			landschaftstyp          integer,
			name                    varchar,
			PRIMARY KEY (ogc_fid)
		);

		PERFORM AddGeometryColumn('ax_landschaft','wkb_geometry',find_srid('','ax_flurstueck','wkb_geometry'),'GEOMETRY',2); -- POINT/LINESTRING

		CREATE INDEX ax_landschaft_geom_idx   ON ax_landschaft USING gist (wkb_geometry);
		CREATE UNIQUE INDEX ax_landschaft_gml ON ax_landschaft USING btree (gml_id,beginnt);

		UPDATE alkis_version SET version=13;
	END IF;

	IF v<14 THEN
		RAISE NOTICE 'Migriere auf Schema-Version 14';

		PERFORM alkis_dropobject('ks_bauraumoderbodenordnungsrecht_geom_idx');
		CREATE INDEX ks_bauraumoderbodenordnungsrecht_geom_idx ON ks_bauraumoderbodenordnungsrecht USING gist (wkb_geometry);

		PERFORM alkis_dropobject('ks_kommunalerbesitz_geom_idx');
		CREATE INDEX ks_kommunalerbesitz_geom_idx ON ks_kommunalerbesitz USING gist (wkb_geometry);

		UPDATE alkis_version SET version=14;

		r := alkis_string_append(r, 'ALKIS-Schema migriert');
	END IF;

	--
	-- ALKIS-Präsentationstabellen
	--
	BEGIN
		SELECT version INTO v FROM alkis_po_version;

	EXCEPTION WHEN OTHERS THEN
		v := 0;
		CREATE TABLE alkis_po_version(version INTEGER);
		INSERT INTO alkis_po_version(version) VALUES (v);
	END;

	RAISE NOTICE 'ALKIS-PO-Schema-Version %', v;

	IF v<1 THEN
		RAISE NOTICE 'Migriere auf Schema-Version 1';

		PERFORM alkis_dropobject('alkis_konturen');

		CREATE TABLE alkis_signaturkataloge(id INTEGER PRIMARY KEY, name VARCHAR);
		INSERT INTO alkis_signaturkataloge(id, name) VALUES (1, 'Farbe');

		CREATE TABLE alkis_punkte(katalog integer,signaturnummer varchar,x0 double precision,y0 double precision,x1 double precision,y1 double precision,primary key (katalog,signaturnummer),FOREIGN KEY (katalog) REFERENCES alkis_signaturkataloge(id));

		BEGIN ALTER TABLE po_labels DROP CONSTRAINT po_labels_signaturnummer_fkey; EXCEPTION WHEN OTHERS THEN END;
		BEGIN ALTER TABLE po_lines DROP CONSTRAINT po_lines_signaturnummer_fkey; EXCEPTION WHEN OTHERS THEN END;
		BEGIN ALTER TABLE po_polygons DROP CONSTRAINT po_polygons_sn_randlinie_fkey; EXCEPTION WHEN OTHERS THEN END;
		BEGIN ALTER TABLE po_polygons DROP CONSTRAINT po_polygons_sn_flaeche_fkey; EXCEPTION WHEN OTHERS THEN END;

		BEGIN ALTER TABLE alkis_linie DROP CONSTRAINT alkis_linie_signaturnummer_fkey; EXCEPTION WHEN OTHERS THEN END;
		BEGIN ALTER TABLE alkis_linie DROP CONSTRAINT alkis_linie_strichart_fkey; EXCEPTION WHEN OTHERS THEN END;

		ALTER TABLE po_points ALTER gml_id TYPE character(16);
		ALTER TABLE po_lines ALTER gml_id TYPE character(16);
		ALTER TABLE po_polygons ALTER gml_id TYPE character(16);
		ALTER TABLE po_labels ALTER gml_id TYPE character(16);

		-- Vorhandene Tabellen migrieren
		FOR c IN
			SELECT a.table_name
			FROM information_schema.tables a
			JOIN (SELECT 1 AS o,'alkis_schriften' AS table_name
			UNION SELECT 2 AS o,'alkis_linien'
			UNION SELECT 3 AS o,'alkis_linie'
			UNION SELECT 4 AS o,'alkis_flaechen'
			UNION SELECT 9 AS o,'po_labels'
			) AS b ON a.table_name=b.table_name
			WHERE a.table_schema='public'
			ORDER BY b.o
		LOOP

			IF c.table_name = 'alkis_schriften' THEN
				-- CREATE TABLE alkis_schriften(katalog INTEGER,signaturnummer VARCHAR,            darstellungsprioritaet INTEGER,name VARCHAR[],seite INTEGER,art VARCHAR,stil VARCHAR,grad_pt INTEGER,horizontaleausrichtung VARCHAR,vertikaleausrichtung VARCHAR,farbe INTEGER,alignment_umn CHAR(2),alignment_dxf INTEGER,sperrung_pt INTEGER,effekt VARCHAR,position TEXT,PRIMARY KEY (katalog,signaturnummer),FOREIGN KEY (katalog) REFERENCES alkis_signaturkataloge(id),FOREIGN KEY (farbe) REFERENCES alkis_farben(id));
				-- CREATE TABLE alkis_schriften(                signaturnummer VARCHAR PRIMARY KEY,darstellungsprioritaet INTEGER,name VARCHAR[],seite INTEGER,art VARCHAR,stil VARCHAR,grad_pt INTEGER,horizontaleausrichtung VARCHAR,vertikaleausrichtung VARCHAR,farbe INTEGER,alignment_umn CHAR(2),alignment_dxf INTEGER,sperrung_pt INTEGER,effekt VARCHAR,position TEXT,FOREIGN KEY (farbe) REFERENCES alkis_farben(id));
				ALTER TABLE alkis_schriften ADD katalog INTEGER;
				UPDATE alkis_schriften SET katalog=1;
				ALTER TABLE alkis_schriften DROP CONSTRAINT alkis_schriften_pkey;
				ALTER TABLE alkis_schriften ADD PRIMARY KEY (katalog,signaturnummer);
				ALTER TABLE alkis_schriften ADD FOREIGN KEY (katalog) REFERENCES alkis_signaturkataloge(id);
			END IF;

			IF c.table_name = 'alkis_linien' THEN
				-- CREATE TABLE alkis_linien(                signaturnummer VARCHAR PRIMARY KEY,darstellungsprioritaet INTEGER,farbe INTEGER,name VARCHAR[],seite INTEGER,FOREIGN KEY (farbe) REFERENCES alkis_farben(id));
				-- CREATE TABLE alkis_linien(katalog INTEGER,signaturnummer VARCHAR            ,darstellungsprioritaet INTEGER,              name VARCHAR[],seite INTEGER,PRIMARY KEY (katalog,signaturnummer),FOREIGN KEY (katalog) REFERENCES alkis_signaturkataloge(id));
				ALTER TABLE alkis_linien ADD katalog INTEGER;
				UPDATE alkis_linien SET katalog=1;
				ALTER TABLE alkis_linien DROP CONSTRAINT alkis_linien_pkey;
				ALTER TABLE alkis_linien ADD PRIMARY KEY (katalog,signaturnummer);
				ALTER TABLE alkis_linien ADD FOREIGN KEY (katalog) REFERENCES alkis_signaturkataloge(id);
				ALTER TABLE alkis_linien DROP farbe;
			END IF;

			IF c.table_name = 'alkis_linie' THEN
				-- CREATE TABLE alkis_linie(id INTEGER PRIMARY KEY,i INTEGER NOT NULL,                signaturnummer VARCHAR,strichart INTEGER,kontur INTEGER,abschluss VARCHAR,scheitel VARCHAR,strichstaerke DOUBLE PRECISION,pfeilhoehe DOUBLE PRECISION,pfeillaenge DOUBLE PRECISION,              position TEXT,FOREIGN KEY (        signaturnummer) REFERENCES alkis_linien(signaturnummer),        FOREIGN KEY (strichart) REFERENCES alkis_stricharten(id),FOREIGN KEY (kontur) REFERENCES alkis_konturen(id));
				-- CREATE TABLE alkis_linie(id INTEGER PRIMARY KEY,i INTEGER NOT NULL,katalog INTEGER,signaturnummer VARCHAR,strichart INTEGER               ,abschluss VARCHAR,scheitel VARCHAR,strichstaerke DOUBLE PRECISION,pfeilhoehe DOUBLE PRECISION,pfeillaenge DOUBLE PRECISION,farbe INTEGER,position TEXT,FOREIGN KEY (katalog,signaturnummer) REFERENCES alkis_linien(katalog,signaturnummer),FOREIGN KEY (strichart) REFERENCES alkis_stricharten(id)                                                   ,FOREIGN KEY (farbe) REFERENCES alkis_farben(id));
				ALTER TABLE alkis_linie ADD katalog INTEGER;
				ALTER TABLE alkis_linie ADD farbe INTEGER;
				ALTER TABLE alkis_linie DROP kontur;
				UPDATE alkis_linie SET katalog=1,farbe=(SELECT farbe FROM alkis_linien WHERE alkis_linien.signaturnummer=alkis_linie.signaturnummer);
				ALTER TABLE alkis_linie ADD FOREIGN KEY (katalog,signaturnummer) REFERENCES alkis_linien(katalog,signaturnummer);
				DELETE FROM alkis_linie l WHERE NOT EXISTS (SELECT * FROM alkis_stricharten a WHERE l.strichart=a.id);
				ALTER TABLE alkis_linie ADD FOREIGN KEY (strichart) REFERENCES alkis_stricharten(id);
				ALTER TABLE alkis_linie ADD FOREIGN KEY (farbe) REFERENCES alkis_farben(id);
			END IF;

			IF c.table_name = 'alkis_flaechen' THEN
				-- CREATE TABLE alkis_flaechen(                signaturnummer VARCHAR PRIMARY KEY,darstellungsprioritaet INTEGER,name VARCHAR[],seite INTEGER,farbe INTEGER,randlinie INTEGER,                                                                                                 FOREIGN KEY (farbe) REFERENCES alkis_farben(id),FOREIGN KEY (randlinie) REFERENCES alkis_randlinie(id));
				-- CREATE TABLE alkis_flaechen(katalog INTEGER,signaturnummer VARCHAR            ,darstellungsprioritaet INTEGER,name VARCHAR[],seite INTEGER,farbe INTEGER,randlinie INTEGER,PRIMARY KEY (katalog,signaturnummer),FOREIGN KEY (katalog) REFERENCES alkis_signaturkataloge(id),FOREIGN KEY (farbe) REFERENCES alkis_farben(id),FOREIGN KEY (randlinie) REFERENCES alkis_randlinie(id));
				ALTER TABLE alkis_flaechen ADD katalog INTEGER;
				UPDATE alkis_flaechen SET katalog=1;
				ALTER TABLE alkis_flaechen DROP CONSTRAINT alkis_flaechen_pkey;
				ALTER TABLE alkis_flaechen ADD PRIMARY KEY (katalog,signaturnummer);
				ALTER TABLE alkis_flaechen ADD FOREIGN KEY (katalog) REFERENCES alkis_signaturkataloge(id);
			END IF;

			IF c.table_name = 'po_labels' THEN
				ALTER TABLE po_labels DROP alignment_dxf;
				ALTER TABLE po_labels DROP color_umn;
				ALTER TABLE po_labels DROP font_umn;
				ALTER TABLE po_labels DROP size_umn;
				ALTER TABLE po_labels DROP darstellungsprioritaet;
			END IF;
		END LOOP;

		UPDATE alkis_po_version SET version=1;

		r := coalesce(r||E'\n','') || 'ALKIS-PO-Schema migriert';
	END IF;

	RETURN r;
END;
$$ LANGUAGE plpgsql;

--
-- Datenbankkommentare
--

SELECT alkis_dropobject('alkis_set_comments');
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

DROP AGGREGATE IF EXISTS array_accum(anyarray);

CREATE AGGREGATE array_accum (anyarray) (
	sfunc = array_cat,
	stype = anyarray,
	initcond = '{}'
);

\set ON_ERROR_STOP
