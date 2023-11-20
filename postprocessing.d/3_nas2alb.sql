/***************************************************************************
 *                                                                         *
 * Project:  norGIS ALKIS Import                                           *
 * Purpose:  ALB-Daten in norBIT WLDGE-Strukturen aus ALKIS-Daten füllen   *
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

\set nas2alb true
\ir ../config.sql

\if :nas2alb

\unset ON_ERROR_STOP
SET application_name='ALKIS-Import - Liegenschaftsbuchübernahme';
SET client_min_messages TO notice;
\set ON_ERROR_STOP

\i nas2alb-functions.sql

SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

SELECT alkis_dropobject('alkis_intersects');
CREATE FUNCTION alkis_intersects(g0 GEOMETRY, g1 GEOMETRY, error TEXT) RETURNS BOOLEAN AS $$
DECLARE
	res BOOLEAN;
BEGIN
	SELECT st_intersects(g0,g1) INTO res;
	RETURN res;
EXCEPTION WHEN OTHERS THEN
	RAISE NOTICE 'st_intersects-Ausnahme bei %: %', error, SQLERRM;
	RETURN NULL;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

SELECT alkis_dropobject('alkis_relate');
CREATE FUNCTION alkis_relate(g0 GEOMETRY, g1 GEOMETRY, m TEXT, error TEXT) RETURNS BOOLEAN AS $$
DECLARE
	res BOOLEAN;
BEGIN
	SELECT st_relate(g0,g1, m) INTO res;
	RETURN res;
EXCEPTION WHEN OTHERS THEN
	RAISE NOTICE 'st_relate-Ausnahme bei %: %', error, SQLERRM;
	RETURN NULL;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

SELECT alkis_dropobject('alkis_intersection');
CREATE FUNCTION alkis_intersection(g0 GEOMETRY, g1 GEOMETRY, error TEXT) RETURNS GEOMETRY AS $$
DECLARE
	res GEOMETRY;
BEGIN
	SELECT st_intersection(g0,g1) INTO res;
	RETURN res;
EXCEPTION WHEN OTHERS THEN
	RAISE NOTICE 'st_intersection-Ausnahme bei: %: %', error, SQLERRM;
	RETURN NULL;
END;
$$ LANGUAGE plpgsql IMMUTABLE;


SELECT alkis_dropobject('alkis_fixareas');
CREATE FUNCTION alkis_fixareas(t TEXT) RETURNS VARCHAR AS $$
DECLARE
	n INTEGER;
	m TEXT;
BEGIN
	BEGIN
		EXECUTE 'SELECT count(*) FROM ' || t || ' WHERE NOT st_isvalid(wkb_geometry)' INTO n;
		IF n = 0 THEN
			RETURN NULL;
		END IF;

		BEGIN
			EXECUTE 'CREATE TABLE ' || t || '_defekt AS SELECT gml_id,beginnt,wkb_geometry FROM ' || t || ' WHERE NOT st_isvalid(wkb_geometry) OR geometrytype(wkb_geometry)=''GEOMETRYCOLLECTION''';
		EXCEPTION WHEN OTHERS THEN
			EXECUTE 'INSERT INTO ' || t || '_defekt(gml_id,beginnt,wkb_geometry) SELECT gml_id,beginnt,wkb_geometry FROM ' || t || ' WHERE NOT st_isvalid(wkb_geometry) OR geometrytype(wkb_geometry)=''GEOMETRYCOLLECTION''';
		END;

		EXECUTE 'UPDATE ' || t || ' SET wkb_geometry=st_collectionextract(st_makevalid(wkb_geometry),3) WHERE NOT st_isvalid(wkb_geometry) OR geometrytype(wkb_geometry)=''GEOMETRYCOLLECTION''';
		GET DIAGNOSTICS n = ROW_COUNT;
		IF n > 0 THEN
			RAISE NOTICE '% Geometrien in % korrigiert.', n, t;
		END IF;

		RETURN t || ' geprüft (' || n || ' ungültige Geometrien in ' || t || '_defekt gesichert und korrigiert).';
	EXCEPTION WHEN OTHERS THEN
		m := SQLERRM;

		BEGIN
			EXECUTE 'SELECT count(*) FROM ' || t || ' WHERE NOT st_isvalid(wkb_geometry) OR geometrytype(wkb_geometry)=''GEOMETRYCOLLECTION''' INTO n;
			IF n > 0 THEN
				RAISE EXCEPTION '% defekte Geometrien in % gefunden - Ausnahme bei Korrektur: %', n, t, m;
			END IF;
		EXCEPTION WHEN OTHERS THEN
			RAISE EXCEPTION 'Ausnahme bei Bestimmung defekter Geometrien in %: %', t, SQLERRM;
		END;

		RETURN 'Ausnahme bei Korrektur: '||SQLERRM;
	END;
END;
$$ LANGUAGE plpgsql;

\endif
