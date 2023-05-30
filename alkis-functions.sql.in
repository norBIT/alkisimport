/***************************************************************************
 *                                                                         *
 * Project:  norGIS ALKIS Import                                           *
 * Purpose:  SQL-Funktionen für ALKIS                                      *
 * Author:   Jürgen E. Fischer <jef@norbit.de>                             *
 *                                                                         *
 ***************************************************************************
 * Copyright (c) 2012-2023, Jürgen E. Fischer <jef@norbit.de>              *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/

CREATE FUNCTION pg_temp.alkis_set_schema(t TEXT) RETURNS varchar AS $$
DECLARE
	i integer;
BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_namespace WHERE nspname=t) THEN
		BEGIN
			EXECUTE 'CREATE SCHEMA ' || quote_ident(t);
			RAISE NOTICE 'Schema % angelegt.', t;
		EXCEPTION WHEN duplicate_schema OR unique_violation THEN
			-- skip
		END;
	END IF;

	PERFORM set_config('search_path', quote_ident(t) || ', ' || current_setting('search_path'), false);

	IF t <> current_schema() THEN
		RAISE EXCEPTION 'Nicht in Schema % gewechselt.', t;
	END IF;

	RETURN 'Aktuelles Schema ' || t || '.';
END
$$ LANGUAGE plpgsql;

SET search_path = :"parent_schema", :"postgis_schema", public;
SELECT pg_temp.alkis_set_schema(:'alkis_schema');

-- Table/View/Sequence löschen, wenn vorhanden
CREATE OR REPLACE FUNCTION :"parent_schema".alkis_dropobject(t TEXT) RETURNS varchar AS $$
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
		FROM pg_catalog.pg_class
		JOIN pg_catalog.pg_namespace ON pg_class.relnamespace=pg_namespace.oid
		WHERE pg_catalog.pg_namespace.nspname=current_schema() AND pg_class.relname=t
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

	FOR c IN SELECT indexname FROM pg_catalog.pg_indexes WHERE schemaname=current_schema() AND indexname=t
	LOOP
		r := alkis_string_append(r, 'Index ' || c.indexname || ' gelöscht.');
		EXECUTE 'DROP INDEX ' || c.indexname;
	END LOOP;

	FOR c IN SELECT proname,proargtypes
		FROM pg_catalog.pg_proc
		JOIN pg_catalog.pg_namespace ON pg_proc.pronamespace=pg_namespace.oid
		WHERE pg_namespace.nspname=current_schema() AND pg_proc.proname=t
	LOOP
		r := alkis_string_append(r, 'Funktion ' || c.proname || ' gelöscht.');

		s := 'DROP FUNCTION ' || c.proname || '(';
		d := '';

		FOR i IN array_lower(c.proargtypes,1)..array_upper(c.proargtypes,1) LOOP
			SELECT typname INTO tn FROM pg_catalog.pg_type WHERE oid=c.proargtypes[i];
			s := s || d || tn;
			d := ',';
		END LOOP;

		s := s || ')';

		EXECUTE s;
	END LOOP;

	FOR c IN SELECT relname,conname
		FROM pg_catalog.pg_constraint
		JOIN pg_catalog.pg_class ON pg_constraint.conrelid=pg_constraint.oid
		JOIN pg_catalog.pg_namespace ON pg_constraint.connamespace=pg_namespace.oid
		WHERE pg_namespace.nspname=current_schema() AND pg_constraint.conname=t
	LOOP
		r := alkis_string_append(r, 'Constraint ' || c.conname || ' von ' || c.relname || ' gelöscht.');
		EXECUTE 'ALTER TABLE ' || c.relname || ' DROP CONSTRAINT ' || c.conname;
	END LOOP;

	RETURN r;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION :"parent_schema".alkis_string_append(varchar, varchar) RETURNS varchar AS $$
	SELECT CASE WHEN $1='' OR $1 LIKE E'%\n' THEN $1 ELSE coalesce($1||E'\n','') END || coalesce($2, '');
$$ LANGUAGE 'sql' IMMUTABLE;

-- Alle ALKIS-Tabellen löschen
CREATE OR REPLACE FUNCTION :"parent_schema".alkis_drop() RETURNS varchar AS $$
DECLARE
	c RECORD;
	r VARCHAR;
BEGIN
	-- drop tables & views
	FOR c IN SELECT table_type,table_name FROM information_schema.tables
		   WHERE table_schema=current_schema() AND table_type='BASE TABLE'
		     AND ( table_name IN @TABLES@
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
		WHERE f_table_schema=current_schema()
		AND ( f_table_name IN @TABLES@ OR f_table_name IN ('alkis_beziehungen','delete') );

	RETURN r;
END;
$$ LANGUAGE plpgsql;

-- Alle ALKIS-Tabellen leeren
CREATE OR REPLACE FUNCTION :"parent_schema".alkis_clean() RETURNS varchar AS $$
DECLARE
	c RECORD;
	r VARCHAR;
BEGIN
	-- clean tables
	FOR c IN SELECT table_name FROM information_schema.tables
		   WHERE table_schema=current_schema()
		     AND (table_name IN @DATATABLES@ OR table_name IN ('alkis_beziehungen','delete'))
		   ORDER BY table_type DESC LOOP
		r := alkis_string_append(r, 'Tabelle ' || c.table_name || ' geleert.');
		EXECUTE 'DELETE FROM ' || c.table_name;
	END LOOP;

	RETURN r;
END;
$$ LANGUAGE plpgsql;

-- Alle ALKIS-Tabellen erben
CREATE OR REPLACE FUNCTION :"parent_schema".alkis_inherit(parent varchar) RETURNS varchar AS $$
DECLARE
	tab RECORD;
	ind RECORD;
	r VARCHAR;
	nt INTEGER;
	ni INTEGER;
	nv INTEGER;
BEGIN
	nt := 0;
	ni := 0;
	nv := 0;

	-- inherit tables
	FOR tab IN
		SELECT c.oid, c.relname, obj_description(c.oid) AS description
		FROM pg_catalog.pg_class c
		JOIN pg_catalog.pg_namespace n ON n.oid=c.relnamespace AND n.nspname=parent
		WHERE pg_get_userbyid(c.relowner)=current_user AND c.relkind='r'
		  AND NOT EXISTS (
			SELECT *
			FROM pg_catalog.pg_class c1
			JOIN pg_catalog.pg_namespace n1 ON n1.oid=c1.relnamespace AND n1.nspname=current_schema()
			WHERE c1.relname=c.relname
		  )
	LOOP
		IF tab.description LIKE 'FeatureType:%' OR tab.description LIKE 'BASE:%' THEN
			nt := nt + 1;
			EXECUTE 'CREATE TABLE ' || quote_ident(tab.relname) || '() INHERITS (' || quote_ident(parent) || '.' || quote_ident(tab.relname) || ')';
			RAISE NOTICE 'Tabelle % abgeleitet.', tab.relname;

			FOR ind IN
				SELECT c.relname, replace(pg_get_indexdef(i.indexrelid), 'ON '||quote_ident(parent)||'.', 'ON ') AS sql
				FROM pg_catalog.pg_index i
				JOIN pg_catalog.pg_class c ON c.oid=i.indexrelid
				WHERE i.indrelid=tab.oid
			LOOP
				ni := ni + 1;
				EXECUTE ind.sql;
			END LOOP;
		ELSE
			nv := nv + 1;
			EXECUTE 'CREATE VIEW ' || quote_ident(tab.relname) || ' AS SELECT * FROM ' || quote_ident(parent) || '.' || quote_ident(tab.relname);
		END IF;
	END LOOP;

	RETURN nt || ' Tabellen mit ' || ni || ' Indizes abgeleitet und ' || nv || ' Sichten erzeugt.';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION :"parent_schema".alkis_create_bsrs(id INTEGER) RETURNS varchar AS $$
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
CREATE OR REPLACE FUNCTION :"parent_schema".alkis_delete() RETURNS varchar AS $$
DECLARE
	c RECORD;
	r varchar;
BEGIN
	-- drop views
	FOR c IN
		SELECT table_name
		FROM information_schema.tables
		WHERE table_schema=current_schema() AND table_type='BASE TABLE'
		  AND ( table_name IN @TABLES@
			OR table_name IN ('alkis_beziehungen','delete') )
	LOOP
		r := alkis_string_append(r, c.table_name || ' wurde geleert.');
		EXECUTE 'TRUNCATE '||c.table_name;
	END LOOP;

	RETURN r;
END;
$$ LANGUAGE plpgsql;

-- Übersicht erzeugen, die alle alkis_beziehungen mit den Typen der beteiligen ALKIS-Objekte versieht
CREATE OR REPLACE FUNCTION :"parent_schema".alkis_mviews() RETURNS varchar AS $$
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
		     AND table_name IN @TABLES@
		     AND table_schema=current_schema
	LOOP
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

-- Wenn die Datenbank MIT Historie angelegt wurde, kann nach dem Laden hiermit aufgeräumt werden.
CREATE OR REPLACE FUNCTION :"parent_schema".alkis_delete_all_endet() RETURNS void AS $$
DECLARE
	c RECORD;
BEGIN
	-- In allen Tabellen die Objekte löschen, die ein Ende-Datum haben
	FOR c IN
		SELECT table_name
		FROM information_schema.columns a
		WHERE a.column_name='endet' AND a.is_updatable='YES' AND table_schema=current_schema()
		ORDER BY table_name
	LOOP
		EXECUTE 'DELETE FROM ' || c.table_name || ' WHERE NOT endet IS NULL';
		-- RAISE NOTICE 'Lösche ''endet'' in: %', c.table_name;
	END LOOP;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION :"parent_schema".alkis_exception() RETURNS void AS $$
BEGIN
	RAISE EXCEPTION 'raising deliberate exception';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION :"parent_schema".alkis_hist_check() RETURNS varchar AS $$
DECLARE
	c RECORD;
	n INTEGER;
	r VARCHAR;
BEGIN
	FOR c IN SELECT table_name FROM information_schema.tables WHERE table_schema=current_schema() AND table_name IN @TABLES@
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

CREATE OR REPLACE FUNCTION :"parent_schema".alkis_bufferline(g geometry,offs float8) RETURNS geometry AS $$
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

CREATE OR REPLACE FUNCTION pg_temp.create_accum() RETURNS void AS $$
BEGIN
  CREATE AGGREGATE alkis_accum (anycompatiblearray) (
    sfunc = array_cat,
    stype = anycompatiblearray,
    initcond = '{}'
  );
EXCEPTION
  WHEN duplicate_function THEN
    -- pass
  WHEN OTHERS THEN
    BEGIN
      CREATE AGGREGATE alkis_accum (anyarray) (
        sfunc = array_cat,
        stype = anyarray,
        initcond = '{}'
      );
    EXCEPTION
      WHEN duplicate_function THEN
        -- pass
    END;
END;
$$ LANGUAGE plpgsql;

SELECT pg_temp.create_accum();
