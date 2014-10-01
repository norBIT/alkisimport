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
			r := coalesce(r||E'\n','') || 'Sicht ' || c.relname || ' gelöscht.';
			EXECUTE 'DROP VIEW ' || c.relname || ' CASCADE';
		ELSIF c.relkind = 'r' THEN
			r := coalesce(r||E'\n','') || 'Tabelle ' || c.relname || ' gelöscht.';
			EXECUTE 'DROP TABLE ' || c.relname || ' CASCADE';
		ELSIF c.relkind = 'S' THEN
			r := coalesce(r||E'\n','') || 'Sequenz ' || c.relname || ' gelöscht.';
			EXECUTE 'DROP SEQUENCE ' || c.relname;
		ELSIF c.relkind <> 'i' THEN
			r := coalesce(r||E'\n','') || 'Typ ' || c.table_type || '.' || c.table_name || ' unerwartet.';
		END IF;
	END LOOP;

	FOR c IN SELECT indexname FROM pg_indexes WHERE schemaname='public' AND indexname=t
	LOOP
		r := coalesce(r||E'\n','') || 'Index ' || c.indexname || ' gelöscht.';
		EXECUTE 'DROP INDEX ' || c.indexname;
	END LOOP;

	FOR c IN SELECT proname,proargtypes
		FROM pg_proc
		JOIN pg_namespace ON pg_proc.pronamespace=pg_namespace.oid
		WHERE pg_namespace.nspname='public' AND pg_proc.proname=t
	LOOP
		r := coalesce(r||E'\n','')|| 'Funktion ' || c.proname || ' gelöscht.';

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
		r := coalesce(r||E'\n','') || 'Constraint ' || c.conname || ' von ' || c.relname || ' gelöscht.';
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
	FOR c IN SELECT table_type,table_name FROM information_schema.tables WHERE table_schema='public' AND ( substr(table_name,1,3) IN ('ax_','ap_','ks_') OR table_name IN ('alkis_beziehungen','delete','alkis_version')) ORDER BY table_type DESC LOOP
		IF c.table_type = 'VIEW' THEN
			r := coalesce(r||E'\n','') || 'Sicht ' || c.table_name || ' gelöscht.';
			EXECUTE 'DROP VIEW ' || c.table_name || ' CASCADE';
		ELSIF c.table_type = 'BASE TABLE' THEN
			r := coalesce(r||E'\n','') || 'Tabelle ' || c.table_name || ' gelöscht.';
			EXECUTE 'DROP TABLE ' || c.table_name || ' CASCADE';
		ELSE
			r := coalesce(r||E'\n','') || 'Typ ' || c.table_type || '.' || c.table_name || ' unerwartet.';
		END IF;
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
BEGIN
	-- drop views
	FOR c IN
		SELECT table_name
		FROM information_schema.tables
		WHERE table_schema='public' AND table_type='BASE TABLE'
		  AND ( substr(table_name,1,3) IN ('ax_','ap_','ks_')
			OR table_name IN ('alkis_beziehungen','delete') )
	LOOP
		r := coalesce(r||E'\n','') || c.table_name || ' wurde geleert.';
		EXECUTE 'DELETE FROM '||c.table_name;
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

	IF NEW.anlass IS NULL THEN
		NEW.anlass := '';
	END IF;

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

	s := 'UPDATE ' || NEW.typename
	  || ' SET endet=''' || NEW.endet || ''''
	  || ',anlass=''' || NEW.anlass || ''''
	  || ' WHERE gml_id=''' || substr(NEW.featureid, 1, 16) || ''''
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
	FOR c IN SELECT table_name FROM information_schema.tables WHERE table_schema='public' AND substr(table_name,1,3) IN ('ax_','ap_','ks_') AND table_type='BASE TABLE'
	LOOP
		EXECUTE 'SELECT count(*) FROM ' || c.table_name || ' WHERE endet IS NULL GROUP BY gml_id HAVING count(*)>1' INTO n;
		IF n>1 THEN
			r := coalesce(r||E'\n','') || c.table_name || ': ' || n || ' Objekte, die in mehreren Versionen nicht beendet sind.';
		END IF;

		EXECUTE 'SELECT count(*) FROM ' || c.table_name || ' WHERE beginnt>=endet' INTO n;
		IF n>1 THEN
			r := coalesce(r||E'\n','') || c.table_name || ': ' || n || ' Objekte mit ungültiger Lebensdauer.';
		END IF;

		EXECUTE 'SELECT count(*)'
			|| ' FROM ' || c.table_name || ' a'
			|| ' JOIN ' || c.table_name || ' b ON a.gml_id=b.gml_id AND a.ogc_fid<>b.ogc_fid AND a.beginnt<b.endet AND a.endet>b.beginnt'
			INTO n;
		IF n>0 THEN
			r := coalesce(r||E'\n','') || c.table_name || ': ' || n || ' Lebensdauerüberschneidungen.';
		END IF;
	END LOOP;

	RETURN coalesce(r,'Keine Fehler gefunden.');
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

	BEGIN
		SELECT version INTO v FROM alkis_version;

	EXCEPTION WHEN OTHERS THEN
		v := 0;
		CREATE TABLE alkis_version(version INTEGER);
		INSERT INTO alkis_version(version) VALUES (v);
	END;

	IF v<1 THEN
		PERFORM alkis_dropobject('ax_tatsaechlichenutzung');
		PERFORM alkis_dropobject('ax_klassifizierung');
		PERFORM alkis_dropobject('ax_ausfuehrendestellen');

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
			r := coalesce(r||E'\n','') || i || ' Tabellen mit ' || s || ' lange AAA-Identifikatoren geändert.';
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
			r := coalesce(r||E'\n','') || i || ' Spalten angepaßt (integer->character varying).';
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
			r := coalesce(r||E'\n','') || i || ' Spalten angepaßt (varchar->character(16)).';
		END IF;

		UPDATE alkis_version SET version=1;
	END IF;

	IF v<2 THEN
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
			r := coalesce(r||E'\n','') || i || ' identifier-Spalten gelöscht.';
		END IF;

		UPDATE alkis_version SET version=2;
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

\set ON_ERROR_STOP
