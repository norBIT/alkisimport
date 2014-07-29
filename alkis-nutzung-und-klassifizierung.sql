/******************************************************************************
 *
 * Project:  norGIS ALKIS Import
 * Purpose:  Erzeugung der (ALB-)Flächen(inhalt)sdaten aus ALKIS durch
 *           Verschneidung mit PostGIS
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

\unset ON_ERROR_STOP
SET application_name='ALKIS-Import - Nutzungen & Klassifizierungen';
\set ON_ERROR_STOP

CREATE OR REPLACE FUNCTION alkis_intersects(g0 GEOMETRY, g1 GEOMETRY, error TEXT) RETURNS BOOLEAN AS $$
DECLARE
	res BOOLEAN;
BEGIN
	SELECT st_intersects(g0,g1) INTO res;
	RETURN res;
EXCEPTION WHEN OTHERS THEN
	RAISE NOTICE 'st_intersects-Ausnahme bei %', error;
	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION alkis_intersection(g0 GEOMETRY, g1 GEOMETRY, error TEXT) RETURNS GEOMETRY AS $$
DECLARE
	res GEOMETRY;
BEGIN
	SELECT st_intersection(g0,g1) INTO res;
	RETURN res;
EXCEPTION WHEN OTHERS THEN
	RAISE NOTICE 'st_intersection-Ausnahme bei: %', error;
	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION alkis_fixgeometry(t TEXT) RETURNS VARCHAR AS $$
DECLARE
	n INTEGER;
BEGIN
	BEGIN
		EXECUTE 'UPDATE '||t||' SET wkb_geometry=st_makevalid(wkb_geometry) WHERE NOT st_isvalid(wkb_geometry)';
		GET DIAGNOSTICS n = ROW_COUNT;
		IF n > 0 THEN
			RAISE NOTICE '% Geometrien in % korrigiert.', n, t;
		END IF;

		RETURN '% geprüft (% ungültige Geometrien).', t, n;
	EXCEPTION WHEN OTHERS THEN
		BEGIN
			EXECUTE 'SELECT count(*) FROM '||t||' WHERE NOT st_isvalid(wkb_geometry)' INTO n;
			IF n > 0 THEN
				RAISE EXCEPTION '% defekte Geometrien in % gefunden - Ausnahme bei Korrektur.', n, t;
			END IF;
		EXCEPTION WHEN OTHERS THEN
			RAISE EXCEPTION 'Ausnahme bei Bestimmung defekter Geometrien in %.', t;
		END;
	END;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION alkis_createnutzung() RETURNS varchar AS $$
DECLARE
        r  RECORD;
	nv VARCHAR;
	kv VARCHAR;
	d  VARCHAR;
        f  VARCHAR;
        n  VARCHAR;
        i  INTEGER;
	invalid INTEGER;
BEGIN
	nv := E'CREATE VIEW ax_tatsaechlichenutzung AS\n  ';
	kv := E'CREATE VIEW ax_tatsaechlichenutzungsschluessel AS\n  ';
	d := '';

        i := 0;
        FOR r IN
                SELECT
			name,
			kennung
                FROM alkis_elemente
                WHERE 'ax_tatsaechlichenutzung' = ANY (abgeleitet_aus)
        LOOP
		-- SELECT alkis_fixgeometry(r.name);

		f := CASE r.name
		     WHEN 'ax_halde'					THEN 'NULL'
		     WHEN 'ax_bergbaubetrieb'				THEN 'NULL'
		     WHEN 'ax_heide'					THEN 'NULL'
		     WHEN 'ax_moor'					THEN 'NULL'
		     WHEN 'ax_sumpf'					THEN 'NULL'
		     WHEN 'ax_wohnbauflaeche'				THEN 'artderbebauung'
		     WHEN 'ax_industrieundgewerbeflaeche'		THEN 'funktion'
		     WHEN 'ax_tagebaugrubesteinbruch'			THEN 'abbaugut'
		     WHEN 'ax_flaechegemischternutzung'			THEN 'funktion'
		     WHEN 'ax_flaechebesondererfunktionalerpraegung'	THEN 'funktion'
		     WHEN 'ax_sportfreizeitunderholungsflaeche'		THEN 'funktion'
		     WHEN 'ax_friedhof'					THEN 'funktion'
		     WHEN 'ax_strassenverkehr'				THEN 'funktion'
		     WHEN 'ax_weg'					THEN 'funktion'
		     WHEN 'ax_platz'					THEN 'funktion'
		     WHEN 'ax_bahnverkehr'				THEN 'funktion'
		     WHEN 'ax_flugverkehr'				THEN 'funktion'
		     WHEN 'ax_schiffsverkehr'				THEN 'funktion'
		     WHEN 'ax_gehoelz'					THEN 'funktion'
		     WHEN 'ax_unlandvegetationsloseflaeche'		THEN 'funktion'
		     WHEN 'ax_fliessgewaesser'				THEN 'funktion'
		     WHEN 'ax_hafenbecken'				THEN 'funktion'
		     WHEN 'ax_stehendesgewaesser'			THEN 'funktion'
		     WHEN 'ax_meer'					THEN 'funktion'
		     WHEN 'ax_landwirtschaft'				THEN 'vegetationsmerkmal'
		     WHEN 'ax_wald'					THEN 'vegetationsmerkmal'
		     ELSE NULL
		     END;
		IF f IS NULL THEN
			RAISE EXCEPTION 'Unerwartete Nutzungstabelle %', r.name;
		END IF;

		n := CASE r.name
		     WHEN 'ax_halde'					THEN 'Halde'
		     WHEN 'ax_bergbaubetrieb'				THEN 'Bergbaubetrieb'
		     WHEN 'ax_heide'					THEN 'Heide'
		     WHEN 'ax_moor'					THEN 'Moor'
		     WHEN 'ax_sumpf'					THEN 'Sumpf'
		     WHEN 'ax_wohnbauflaeche'				THEN 'Wohnbaufläche'
		     WHEN 'ax_industrieundgewerbeflaeche'		THEN 'Industrie- und Gewerbefläche'
		     WHEN 'ax_tagebaugrubesteinbruch'			THEN 'Tagebau, Grube, Steinbruch'
		     WHEN 'ax_flaechegemischternutzung'			THEN 'Fläche gemischter Nutzung'
		     WHEN 'ax_flaechebesondererfunktionalerpraegung'	THEN 'Fläche besonderer funktiononaler Prägung'
		     WHEN 'ax_sportfreizeitunderholungsflaeche'		THEN 'Sport-, Freizeit- und Erholungsfläche'
		     WHEN 'ax_friedhof'					THEN 'Friedhof'
		     WHEN 'ax_strassenverkehr'				THEN 'Straßenverkehr'
		     WHEN 'ax_weg'					THEN 'Weg'
		     WHEN 'ax_platz'					THEN 'Platz'
		     WHEN 'ax_bahnverkehr'				THEN 'Bahrverkehr'
		     WHEN 'ax_flugverkehr'				THEN 'Flugverkehr'
		     WHEN 'ax_schiffsverkehr'				THEN 'Schiffsverkehr'
		     WHEN 'ax_gehoelz'					THEN 'Gehölz'
		     WHEN 'ax_unlandvegetationsloseflaeche'		THEN 'Unland, vegetationslose Fläche'
		     WHEN 'ax_fliessgewaesser'				THEN 'Fließgewässer'
		     WHEN 'ax_hafenbecken'				THEN 'Hafenbecken'
		     WHEN 'ax_stehendesgewaesser'			THEN 'Stehendes Gewässer'
		     WHEN 'ax_meer'					THEN 'Meer'
		     WHEN 'ax_landwirtschaft'				THEN 'Landwirtschaft'
		     WHEN 'ax_wald'					THEN 'Wald'
		     ELSE NULL
		     END;

		IF n IS NULL THEN
			RAISE EXCEPTION 'Unerwartete Nutzungstabelle %', r.name;
		END IF;

		nv := nv
		   || d
		   || 'SELECT '
		   || 'ogc_fid*32+' || i ||' AS ogc_fid,'
		   || '''' || r.name || '''::text AS name,'
		   || 'gml_id,'
		   || r.kennung::int || ' AS kennung,'
		   || f || '::text AS funktion,'
		   || ''''||r.kennung|| '''||coalesce('':''||'||f||','''')::text AS nutzung,'
		   || 'wkb_geometry'
		   || ' FROM ' || r.name
		   || ' WHERE endet IS NULL'
		   ;

		kv := kv
		   || d
		   || 'SELECT '''||r.kennung||''' AS nutzung,'''||n||''' AS name'
		   ;

		IF f<>'NULL' THEN
			kv := kv
			   || ' UNION SELECT '''
			   || r.kennung||':''||k AS nutzung,v AS name'
			   || '  FROM alkis_wertearten WHERE element=''' || r.name || ''' AND bezeichnung=''' || f || ''''
			   ;
		END IF;

		d := E' UNION\n  ';
		i := i + 1;
        END LOOP;

	PERFORM alkis_dropobject('ax_tatsaechlichenutzung');
	EXECUTE nv;

	PERFORM alkis_dropobject('ax_tatsaechlichenutzungsschluessel');
	EXECUTE kv;

	RETURN 'ax_tatsaechlichenutzung und ax_tatsaechlichenutzungsschluessel erzeugt.';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION alkis_createklassifizierung() RETURNS varchar AS $$
DECLARE
        r  RECORD;
	nv VARCHAR;
	kv VARCHAR;
	d  VARCHAR;
        f  VARCHAR;
        p  VARCHAR;
	i  INTEGER;
	invalid INTEGER;
BEGIN
	nv := E'CREATE VIEW ax_klassifizierung AS\n  ';
	kv := E'CREATE VIEW ax_klassifizierungsschluessel AS\n  ';
	d := '';

	i := 0;
        FOR r IN
                SELECT
			name,
			kennung
                FROM alkis_elemente
                WHERE name IN ('ax_bodenschaetzung','ax_bewertung','ax_klassifizierungnachwasserrecht','ax_klassifizierungnachstrassenrecht')
        LOOP
		-- SELECT alkis_fixgeometry(r.name);

	        f := CASE r.name
		     WHEN 'ax_bodenschaetzung' THEN 'b'
		     WHEN 'ax_bewertung' THEN 'B'
		     WHEN 'ax_klassifizierungnachwasserrecht' THEN 'W'
		     WHEN 'ax_klassifizierungnachstrassenrecht' THEN 'S'
		     ELSE NULL
		     END;
		IF f IS NULL THEN
			RAISE EXCEPTION 'Unerwartete Tabelle %', r.name;
		END IF;

		p := CASE r.name
		     WHEN 'ax_bodenschaetzung' THEN 'kulturart'
		     WHEN 'ax_bewertung' THEN 'klassifizierung'
		     ELSE 'artderfestlegung'
		     END;

		nv := nv
		   || d
		   || 'SELECT '
		   || 'ogc_fid*4+' || i || ' AS ogc_fid,'
		   || '''' || r.name    || '''::text AS name,'
		   || 'gml_id,'
		   || r.kennung::int || ' AS kennung,'
		   || p || ' AS artderfestlegung,'
		   || CASE WHEN r.name='ax_bodenschaetzung'
		      THEN 'bodenzahlodergruenlandgrundzahl::int AS bodenzahl,ackerzahlodergruenlandzahl::int AS ackerzahl,'
		      ELSE 'NULL::int AS bodenzahl,NULL::int AS ackerzahl,'
		      END
		   || ''''||f||':''||'||p||' AS klassifizierung,'
		   || 'wkb_geometry'
		   || ' FROM ' || r.name
		   || ' WHERE endet IS NULL'
		   ;

		kv := kv
		   || d
		   || 'SELECT '
		   || '''' || f || ':''||k AS klassifizierung,v AS name'
		   || '  FROM alkis_wertearten WHERE element=''' || r.name || ''' AND bezeichnung='''||p||''''
		   ;

		d := E' UNION\n  ';
		i := i + 1;
        END LOOP;

	PERFORM alkis_dropobject('ax_klassifizierung');
	EXECUTE nv;

	PERFORM alkis_dropobject('ax_klassifizierungsschluessel');
	EXECUTE kv;

	RETURN 'ax_klassifizierung und ax_klassifizierungsschluessel erzeugt.';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION alkis_createausfuehrendestellen() RETURNS varchar AS $$
DECLARE
	r VARCHAR[];
	v VARCHAR;
	d VARCHAR;
	f VARCHAR;
	p VARCHAR;
	i INTEGER;
	n VARCHAR;
	invalid INTEGER;
BEGIN
	PERFORM alkis_dropobject('ax_ausfuehrendestellen');

	PERFORM alkis_dropobject('v_schutzgebietnachwasserrecht');
	CREATE TABLE v_schutzgebietnachwasserrecht AS
		SELECT z.ogc_fid,z.gml_id,'ax_schutzzone'::varchar AS name,s.land,s.stelle,z.wkb_geometry,NULL::text AS endet
		FROM ax_schutzgebietnachwasserrecht s
		JOIN ax_schutzzone z ON z.istteilvon=s.gml_id AND z.endet IS NULL
		WHERE s.endet IS NULL;
	CREATE TEMP SEQUENCE a;
	UPDATE v_schutzgebietnachwasserrecht SET ogc_fid=nextval('a');

	PERFORM alkis_dropobject('v_schutzgebietnachnaturumweltoderbodenschutzrecht');
	CREATE TABLE v_schutzgebietnachnaturumweltoderbodenschutzrecht AS
		SELECT z.ogc_fid,z.gml_id,'ax_schutzzone'::varchar AS name,s.land,s.stelle,z.wkb_geometry,NULL::text AS endet
		FROM ax_schutzgebietnachnaturumweltoderbodenschutzrecht s
		JOIN ax_schutzzone z ON z.istteilvon=s.gml_id AND z.endet IS NULL
		WHERE s.endet IS NULL;
	DROP SEQUENCE a;
	CREATE TEMP SEQUENCE a;
	UPDATE v_schutzgebietnachwasserrecht SET ogc_fid=nextval('a');

	r := ARRAY[
			'v_schutzgebietnachwasserrecht',
			'v_schutzgebietnachnaturumweltoderbodenschutzrecht',
			'ax_naturumweltoderbodenschutzrecht',
			'ax_forstrecht',
			'ax_bauraumoderbodenordnungsrecht',
			'ax_klassifizierungnachstrassenrecht',
			'ax_denkmalschutzrecht',
			'ax_anderefestlegungnachwasserrecht',
			-- 'ax_anderefestlegungnachstrassenrecht',
			'ax_sonstigesrecht',
			'ax_klassifizierungnachwasserrecht'
		];

	v := E'CREATE VIEW ax_ausfuehrendestellen AS\n  ';
	d := '';

	FOR i IN array_lower(r,1)..array_upper(r,1)
        LOOP
		n := r[i];

		-- SELECT alkis_fixgeometry(n);

		v := v
		  || d
		  || 'SELECT '
		  || 'ogc_fid*16+' || i || ' AS ogc_fid,'
		  || '''' || n || '''::text AS name,'
		  || 'gml_id,'
		  || 'to_char(land::int,''fm00'') || stelle AS ausfuehrendestelle,'
		  || 'wkb_geometry'
		  || ' FROM ' || n
		  || ' WHERE endet IS NULL'
		  ;

		d := E' UNION\n  ';
        END LOOP;

	EXECUTE v;
	RETURN 'ax_ausfuehrendestellen erzeugt.';
END;
$$ LANGUAGE plpgsql;

-- SELECT 'Prüfe Flurstücksgeometrien...';
-- SELECT alkis_fixgeometry('ax_flurstueck');

SELECT 'Erzeuge Sicht für Klassifizierungen...';
SELECT alkis_createklassifizierung();

SELECT 'Erzeuge Sicht für tatsächliche Nutzungen...';
SELECT alkis_createnutzung();

SELECT 'Erzeuge Sicht für ausführende Stellen...';
SELECT alkis_createausfuehrendestellen();

DELETE FROM kls_shl;
INSERT INTO kls_shl(klf,klf_text)
  SELECT klassifizierung,name FROM ax_klassifizierungsschluessel;

DELETE FROM nutz_shl;
INSERT INTO nutz_shl(nutzshl,nutzung)
  SELECT nutzung,name FROM ax_tatsaechlichenutzungsschluessel;

SELECT alkis_dropobject('klas_3x_pk_seq');
CREATE SEQUENCE klas_3x_pk_seq;

SELECT 'Bestimme Flurstücksklassifizierungen...';

DELETE FROM klas_3x;
INSERT INTO klas_3x(flsnr,pk,klf,wertz1,wertz2,gemfl,ff_entst,ff_stand)
  SELECT
    to_char(f.land::int,'fm00') || to_char(f.gemarkungsnummer::int,'fm0000') || '-' || to_char(coalesce(f.flurnummer,0),'fm000') || '-' || to_char(f.zaehler,'fm00000') || '/' || to_char(coalesce(f.nenner,0),'fm000') AS flsnr,
    to_hex(nextval('klas_3x_pk_seq'::regclass)) AS pk,
    k.klassifizierung AS klf,
    k.bodenzahl,
    k.ackerzahl,
    sum(st_area(alkis_intersection(f.wkb_geometry,k.wkb_geometry,'ax_flurstueck:'||f.gml_id||'<=>'||k.name||':'||k.gml_id))) AS gemfl,
    0 AS ff_entst,
    0 AS ff_stand
  FROM ax_flurstueck f
  JOIN ax_klassifizierung k ON f.wkb_geometry && k.wkb_geometry AND alkis_intersects(f.wkb_geometry,k.wkb_geometry,'ax_flurstueck:'||f.gml_id||'<=>'||k.name||':'||k.gml_id)
  WHERE f.endet IS NULL AND st_area(alkis_intersection(f.wkb_geometry,k.wkb_geometry,'ax_flurstueck:'||f.gml_id||'<=>'||k.name||':'||k.gml_id))::int>0
  GROUP BY
    f.land, f.gemarkungsnummer, f.flurnummer, f.zaehler, coalesce(f.nenner,0), k.klassifizierung, k.bodenzahl, k.ackerzahl;

UPDATE klas_3x SET fl=(gemfl*(SELECT flurst.amtlflsfl/flurst.gemflsfl FROM flurst WHERE flurst.flsnr=klas_3x.flsnr))::int;

SELECT alkis_dropobject('nutz_shl_pk_seq');
CREATE SEQUENCE nutz_shl_pk_seq;

SELECT 'Bestimme Flurstücksnutzungen...';

DELETE FROM nutz_21;
INSERT INTO nutz_21(flsnr,pk,nutzsl,gemfl,ff_entst,ff_stand)
  SELECT
    to_char(f.land::int,'fm00') || to_char(f.gemarkungsnummer::int,'fm0000') || '-' || to_char(coalesce(f.flurnummer,0),'fm000') || '-' || to_char(f.zaehler,'fm00000') || '/' || to_char(coalesce(f.nenner,0),'fm000') AS flsnr,
    to_hex(nextval('nutz_shl_pk_seq'::regclass)) AS pk,
    n.nutzung AS nutzsl,
    sum(st_area(alkis_intersection(f.wkb_geometry,n.wkb_geometry,'ax_flurstueck:'||f.gml_id||'<=>'||n.name||':'||n.gml_id))) AS gemfl,
    0 AS ff_entst,
    0 AS ff_stand
  FROM ax_flurstueck f
  JOIN ax_tatsaechlichenutzung n ON f.wkb_geometry && n.wkb_geometry AND alkis_intersects(f.wkb_geometry,n.wkb_geometry,'ax_flurstueck:'||f.gml_id||'<=>'||n.name||':'||n.gml_id)
  WHERE f.endet IS NULL AND st_area(alkis_intersection(f.wkb_geometry,n.wkb_geometry,'ax_flurstueck:'||f.gml_id||'<=>'||n.name||':'||n.gml_id))::int>0
  GROUP BY f.land, f.gemarkungsnummer, f.flurnummer, f.zaehler, coalesce(f.nenner,0), n.nutzung;

UPDATE nutz_21 SET fl=(gemfl*(SELECT flurst.amtlflsfl/flurst.gemflsfl FROM flurst WHERE flurst.flsnr=nutz_21.flsnr))::int;

SELECT alkis_dropobject('ausfst_pk_seq');
CREATE SEQUENCE ausfst_pk_seq;

SELECT 'Bestimme ausführende Stellen für Flurstücke...';

DELETE FROM ausfst;
INSERT INTO ausfst(flsnr,pk,ausf_st,verfnr,verfshl,ff_entst,ff_stand)
  SELECT
    to_char(f.land::int,'fm00') || to_char(f.gemarkungsnummer::int,'fm0000') || '-' || to_char(coalesce(f.flurnummer,0),'fm000') || '-' || to_char(f.zaehler,'fm00000') || '/' || to_char(coalesce(f.nenner,0),'fm000') AS flsnr,
    to_hex(nextval('ausfst_pk_seq'::regclass)) AS pk,
    s.ausfuehrendestelle AS ausf_st,
    NULL AS verfnr,
    NULL AS verfshl,
    0 AS ff_entst,
    0 AS ff_stand
  FROM ax_flurstueck f
  JOIN ax_ausfuehrendestellen s ON f.wkb_geometry && s.wkb_geometry AND alkis_intersects(f.wkb_geometry,s.wkb_geometry,'ax_flurstueck:'||f.gml_id||'<=>'||s.name||':'||s.gml_id)
  WHERE f.endet IS NULL AND st_area(alkis_intersection(f.wkb_geometry,s.wkb_geometry,'ax_flurstueck:'||f.gml_id||'<=>'||s.name||':'||s.gml_id))::int>0
  GROUP BY f.land, f.gemarkungsnummer, f.flurnummer, f.zaehler, coalesce(f.nenner,0), s.ausfuehrendestelle;

DELETE FROM afst_shl;
INSERT INTO afst_shl(ausf_st,afst_txt)
  SELECT
    to_char(d.land::int,'fm00') || d.stelle,
    MIN(bezeichnung)
  FROM ax_dienststelle d
  WHERE EXISTS (SELECT * FROM ausfst WHERE ausf_st=to_char(d.land::int,'fm00') || d.stelle)
  GROUP BY to_char(d.land::int,'fm00') || d.stelle;


SELECT 'Belege Baulastenblattnummer...';

SELECT alkis_dropobject('bblnr_temp');
CREATE TABLE bblnr_temp AS
	SELECT
		to_char(f.land::int,'fm00') || to_char(f.gemarkungsnummer::int,'fm0000') || '-' || to_char(coalesce(f.flurnummer,0),'fm000') || '-' || to_char(f.zaehler,'fm00000') || '/' || to_char(coalesce(f.nenner,0),'fm000') AS flsnr,
		b.bezeichnung
        FROM ax_flurstueck f
        JOIN ax_bauraumoderbodenordnungsrecht b ON b.endet IS NULL AND b.artderfestlegung=2610 AND f.wkb_geometry && b.wkb_geometry AND alkis_intersects(f.wkb_geometry,b.wkb_geometry,'ax_flurstueck:'||f.gml_id||'<=>ax_bauraumoderbodenordnungsrecht:'||b.gml_id)
        WHERE f.endet IS NULL AND st_area(alkis_intersection(f.wkb_geometry,b.wkb_geometry,'ax_flurstueck:'||f.gml_id||'<=>ax_bauraumoderbodenordnungsrecht:'||b.gml_id))::int>0;

CREATE INDEX bblnr_temp_flsnr ON bblnr_temp(flsnr);

UPDATE flurst SET blbnr=(SELECT regexp_replace(array_to_string(array_agg(DISTINCT b.bezeichnung),','),E'\(.{196}\).+',E'\\1 ...') FROM bblnr_temp b WHERE flurst.flsnr=b.flsnr);

DROP TABLE bblnr_temp;
