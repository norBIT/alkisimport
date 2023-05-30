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

\unset ON_ERROR_STOP
SET application_name='ALKIS-Import - Liegenschaftsbuchübernahme';
SET client_min_messages TO notice;
\set ON_ERROR_STOP

SET search_path = :"alkis_schema", :"postgis_schema", public;

CREATE OR REPLACE FUNCTION alkis_toint(v anyelement) RETURNS integer AS $$
DECLARE
        res integer;
BEGIN
        SELECT v::int INTO res;
        RETURN res;
EXCEPTION WHEN OTHERS THEN
        RETURN NULL;
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION alkis_round(double precision) RETURNS varchar AS $$
        SELECT regexp_replace(regexp_replace(round($1::numeric,9)::text, E'(\\.\\d*[1-9])0+$', E'\\1'), E'\\.0+$', '');
$$ LANGUAGE 'sql' IMMUTABLE;

CREATE OR REPLACE FUNCTION alkis_flsnrk(f ax_flurstueck) RETURNS varchar AS $$
BEGIN
	RETURN
		CASE
		WHEN f.gml_id LIKE 'DESL%' THEN
			to_char(alkis_toint(f.zaehler),'fm0000') || '/' || to_char(coalesce(alkis_toint(f.nenner),0),'fm0000')
		WHEN f.gml_id LIKE 'DETH%' THEN
			to_char(alkis_toint(f.zaehler),'fm00000') || '/' || to_char(coalesce(alkis_toint(f.nenner),0),'fm0000')
		WHEN f.gml_id LIKE 'DESN%' OR f.gml_id LIKE 'DETH%' THEN
			to_char(alkis_toint(f.zaehler),'fm00000') || '/' || substring(f.flurstueckskennzeichen,15,4)
		ELSE
			to_char(alkis_toint(f.zaehler),'fm00000') || '/' || to_char(coalesce(mod(alkis_toint(f.nenner),1000)::int,0),'fm000')
		END;
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT SET search_path = :"alkis_schema", :"postgis_schema", public;

CREATE OR REPLACE FUNCTION alkis_flsnr(f ax_flurstueck) RETURNS varchar AS $$
BEGIN
	RETURN
		to_char(alkis_toint(f.land),'fm00') || to_char(alkis_toint(f.gemarkungsnummer),'fm0000') ||
		'-' || to_char(coalesce(f.flurnummer,0),'fm000') ||
		'-' || alkis_flsnrk(f);
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT SET search_path = :"alkis_schema", :"postgis_schema", public;

CREATE OR REPLACE FUNCTION alkis_flskoord(f ax_flurstueck) RETURNS varchar AS $$
DECLARE
        g GEOMETRY;
BEGIN
	BEGIN
		SELECT st_pointonsurface(f.wkb_geometry) INTO g;
	EXCEPTION WHEN OTHERS THEN
		RAISE NOTICE 'st_pointonsurface-Ausnahme bei %', alkis_flsnr(f);
		BEGIN
			SELECT st_centroid(f.wkb_geometry) INTO g;
		EXCEPTION WHEN OTHERS THEN
			RAISE NOTICE 'st_centroid-Ausnahme bei %', alkis_flsnr(f);
			RETURN NULL;
		END;
	END;

	RETURN to_char(st_x(g)*10::int,'fm00000000') ||' '|| to_char(st_y(g)*10::int,'fm00000000');
END;
$$ LANGUAGE plpgsql IMMUTABLE;

SELECT alkis_dropobject('alkis_truncate');
CREATE OR REPLACE FUNCTION alkis_truncate(s0 varchar, l integer) RETURNS varchar AS $$
DECLARE
	s VARCHAR := trim(s0);
BEGIN
	IF length(s)>l THEN
		IF l>3 THEN
			RETURN substr(s, 1, l-3) || '...';
		ELSE
			RETURN substr(s, 1, l);
		END IF;
	ELSE
		RETURN s;
	END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;
