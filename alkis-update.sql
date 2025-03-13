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

	IF ver<100 THEN
		RAISE EXCEPTION 'Migration von Schema-Version vor GID 7.1.2 wird nicht unterstützt.';
	END IF;

	IF ver<101 THEN
		RAISE NOTICE 'Migriere auf Schema-Version 101 (GID 7.1.2)';

		UPDATE alkis_version SET version=101;
	END IF;

	IF ver<102 THEN
		RAISE NOTICE 'Migriere auf Schema-Version 102';

		FOR c IN
			SELECT table_name
			FROM information_schema.columns a
			WHERE a.table_schema=current_schema()
			  AND (substr(a.table_name,1,3) IN ('ax_','ap_','ln_','lb_','au_','aa_') OR a.table_name='delete')
			  AND a.column_name='endet'
		LOOP
			EXECUTE 'UPDATE ' || c.table_name || ' SET endet=substr(endet,1,4)||''-''||substr(endet,5,2)||''-''||substr(endet,7,5)||'':''||substr(endet,12,2)||'':''||substr(endet,14,3) WHERE length(endet)=16';
		END LOOP;

		UPDATE alkis_version SET version=102;

		r := alkis_string_append(r, 'ALKIS-Schema migriert');
	END IF;

	IF ver>102 THEN
		RAISE EXCEPTION 'ALKIS-Schema % nicht unterstützt (bis 102).', ver;
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

		DECLARE
			sql text;
		BEGIN
			SELECT
				E'CREATE VIEW alkis_po_objekte AS\n  ' ||
				array_to_string(
					array_agg(
						format('SELECT gml_id,beginnt,endet,%L AS table_name FROM %I', table_name, table_name)
					),
				E' UNION ALL\n  '
				)
			INTO sql
			FROM (
				SELECT
					table_name
				FROM information_schema.columns
				WHERE table_schema=current_schema AND column_name IN ('gml_id', 'beginnt', 'endet')
				GROUP BY table_name
				HAVING count(*)=3
			) AS t;

			EXECUTE sql;
		END;

		CREATE TABLE po_darstellung (
			gml_id character(16),
			beginnt character(20),
			dientzurdarstellungvon character(16),
			modelle character varying[],
			art character varying,
			darstellungsprioritaet integer,
			positionierungsregel character varying,
			signaturnummer character varying
		);

		CREATE INDEX po_darstellung_gml_id ON po_darstellung(gml_id);
		CREATE INDEX po_darstellung_dzv ON po_darstellung(dientzurdarstellungvon);
		CREATE INDEX po_darstellung_art ON po_darstellung(art);

		CREATE TABLE po_ppo (
			gml_id character(16),
			beginnt character(20),
			dientzurdarstellungvon character(16),
			modelle character varying[],
			art character varying,
			darstellungsprioritaet integer,
			drehwinkel double precision,
			signaturnummer character varying,
			skalierung double precision
		);

		PERFORM AddGeometryColumn('po_ppo','wkb_geometry', find_srid(current_schema::text, 'ax_flurstueck', 'wkb_geometry'), 'GEOMETRY', 2);

		CREATE INDEX po_ppo_gml_id ON po_ppo(gml_id);
		CREATE INDEX po_ppo_dzv ON po_ppo(dientzurdarstellungvon);
		CREATE INDEX po_ppo_art ON po_ppo(art);

		CREATE TABLE po_lpo (
			gml_id character(16),
			beginnt character(20),
			dientzurdarstellungvon character(16),
			modelle character varying[],
			art character varying,
			darstellungsprioritaet integer,
			signaturnummer character varying
		);

		PERFORM AddGeometryColumn('po_lpo','wkb_geometry', find_srid(current_schema::text, 'ax_flurstueck', 'wkb_geometry'), 'GEOMETRY', 2);

		CREATE INDEX po_lpo_gml_id ON po_lpo(gml_id);
		CREATE INDEX po_lpo_dzv ON po_lpo(dientzurdarstellungvon);
		CREATE INDEX po_lpo_art ON po_lpo(art);

		CREATE TABLE po_fpo (
			gml_id character(16),
			beginnt character(20),
			dientzurdarstellungvon character(16),
			modelle character varying[],
			art character varying,
			darstellungsprioritaet integer,
			signaturnummer character varying
		);

		PERFORM AddGeometryColumn('po_fpo','wkb_geometry', find_srid(current_schema::text, 'ax_flurstueck', 'wkb_geometry'), 'GEOMETRY', 2);

		CREATE INDEX po_fpo_gml_id ON po_fpo(gml_id);
		CREATE INDEX po_fpo_dzv ON po_fpo(dientzurdarstellungvon);
		CREATE INDEX po_fpo_art ON po_fpo(art);

		CREATE TABLE po_pto(
			gml_id character(16),
			beginnt character(20),
			dientzurdarstellungvon character(16),
			modelle character varying[],
			art varchar,
			darstellungsprioritaet integer,
			drehwinkel double precision,
			fontsperrung double precision,
			horizontaleausrichtung character varying,
			schriftinhalt character varying,
			signaturnummer character varying,
			skalierung double precision,
			vertikaleausrichtung character varying
		);

		PERFORM AddGeometryColumn('po_pto','wkb_geometry', find_srid(current_schema::text, 'ax_flurstueck', 'wkb_geometry'), 'GEOMETRY', 2);

		CREATE INDEX po_pto_gml_id ON po_pto(gml_id);
		CREATE INDEX po_pto_dzv ON po_pto(dientzurdarstellungvon);
		CREATE INDEX po_pto_art ON po_pto(art);

		CREATE TABLE po_lto (
			gml_id character(16),
			beginnt character(20),
			dientzurdarstellungvon character(16),
			modelle character varying[],
			art character varying,
			darstellungsprioritaet integer,
			fontsperrung double precision,
			horizontaleausrichtung character varying,
			schriftinhalt character varying,
			signaturnummer character varying,
			skalierung double precision,
			vertikaleausrichtung character varying
		);

		PERFORM AddGeometryColumn('po_lto','wkb_geometry', find_srid(current_schema::text, 'ax_flurstueck', 'wkb_geometry'), 'GEOMETRY', 2);

		CREATE INDEX po_lto_gml_id ON po_lto(gml_id);
		CREATE INDEX po_lto_dzv ON po_lto(dientzurdarstellungvon);
		CREATE INDEX po_lto_art ON po_lto(art);

		UPDATE alkis_po_version SET version=5;
	END IF;

	IF ver>5 THEN
		RAISE EXCEPTION 'ALKIS-PO-Schema % nicht unterstützt (bis 5).', ver;
	END IF;

	RETURN r;
END;
$$ LANGUAGE plpgsql;

SET search_path = :"alkis_schema", :"postgis_schema", public;
SELECT pg_temp.alkis_update_schema();
