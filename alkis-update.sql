/***************************************************************************
 *                                                                         *
 * Projekt:  norGIS ALKIS Import                                           *
 * Purpose:  ALKIS-Schema ggf. migrieren                                   *
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

SET client_encoding = 'UTF8';
SET search_path = :"postgis_schema", public;

\i alkis-compat.sql

-- Stored Procedures laden
\i alkis-functions.sql

--
-- Datenbankmigration
--

CREATE FUNCTION pg_temp.alkis_rename_table(t TEXT) RETURNS varchar AS $$
BEGIN
	PERFORM alkis_dropobject(t || '_');

	EXECUTE 'ALTER TABLE ' || t || ' RENAME TO ' || t || '_';

	PERFORM alkis_dropobject(t || '_geom_idx');                -- < GDAL 1.11
	PERFORM alkis_dropobject(t || '_wkb_geometry_geom_idx');   -- >= GDAL 1.11

	RETURN t || ' umbenannt - INHALT MANUELL MIGRIEREN.';
EXCEPTION WHEN OTHERS THEN
	RETURN '';
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION pg_temp.alkis_update_schema() RETURNS varchar AS $$
DECLARE
	c RECORD;
	s INTEGER;
	v_n INTEGER;
	i INTEGER;
	ver INTEGER;
	r TEXT;
BEGIN
	r := NULL;

	--
	-- ALKIS-Schema
	--
	SELECT count(*) INTO v_n FROM information_schema.columns
		WHERE table_schema=current_schema()
		  AND table_name='ax_flurstueck'
		  AND column_name='sonstigesmodell';
	IF v_n=0 THEN
		RAISE EXCEPTION 'Modell zu alt für Migration.';
	END IF;

	BEGIN
		SELECT version INTO ver FROM alkis_version;

	EXCEPTION WHEN OTHERS THEN
		RAISE EXCEPTION 'Modell zu alt für Migration.';
	END;

	RAISE NOTICE 'ALKIS-Schema-Version: %', ver;

	IF ver<101 THEN
		RAISE EXCEPTION 'Migration von Schema-Version vor GID 7.1.2 wird nicht unterstützt.';
	END IF;

	IF ver=100 THEN
		RAISE NOTICE 'Migriere auf Schema-Version 101 (GID 7.1.2)';

		UPDATE alkis_version SET version=101;
	END IF;

	IF ver>101 THEN
		RAISE EXCEPTION 'ALKIS-Schema % nicht unterstützt (bis 101).', ver;
	END IF;

	--
	-- ALKIS-Präsentationstabellen
	--
	BEGIN
		SELECT version INTO ver FROM alkis_po_version;

	EXCEPTION WHEN OTHERS THEN
		RAISE NOTICE 'Migration von ALKIS-PO-Schema vor GID7 nicht unterstützt';
	END;

	RAISE NOTICE 'ALKIS-PO-Schema-Version %', ver;


	IF ver<4 THEN
		RAISE NOTICE 'Migration von ALKIS-PO-Schema-Versionen vor GID7 nicht unterstützt.';

	END IF;

	IF ver>5 THEN
		RAISE EXCEPTION 'ALKIS-PO-Schema % nicht unterstützt (bis 4).', ver;
	END IF;

	IF ver=4 THEN
		TRUNCATE po_points;
		TRUNCATE po_lines;
		TRUNCATE po_polygons;
		TRUNCATE po_labels;

		ALTER TABLE po_points ADD gml_ids character(16)[] NOT NULL;
		ALTER TABLE po_lines ADD gml_ids character(16)[] NOT NULL;
		ALTER TABLE po_polygons ADD gml_ids character(16)[] NOT NULL;
		ALTER TABLE po_labels ADD gml_ids character(16)[] NOT NULL;

		CREATE INDEX po_points_gmlids_ids ON po_points USING gin (gml_ids);
		CREATE INDEX po_lines_gmlids_ids ON po_lines USING gin (gml_ids);
		CREATE INDEX po_polygons_gmlids_ids ON po_polygons USING gin (gml_ids);
		CREATE INDEX po_labels_gmlids_ids ON po_labels USING gin (gml_ids);

		CREATE TABLE po_lastrun(lastrun character(20), npoints INTEGER, nlines INTEGER, npolygons INTEGER, nlabels INTEGER);
		INSERT INTO po_lastrun(lastrun, npoints, nlines, npolygons, nlabels) VALUES (NULL, 0, 0, 0, 0);

		UPDATE alkis_po_version SET version=5;
	END IF;

	RETURN r;
END;
$$ LANGUAGE plpgsql;

SET search_path = :"alkis_schema", :"postgis_schema", public;
SELECT pg_temp.alkis_update_schema();
