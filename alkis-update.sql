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

	IF ver>4 THEN
		RAISE EXCEPTION 'ALKIS-PO-Schema % nicht unterstützt (bis 4).', ver;
	END IF;

	RETURN r;
END;
$$ LANGUAGE plpgsql;

SET search_path = :"alkis_schema", :"postgis_schema", public;
SELECT pg_temp.alkis_update_schema();
