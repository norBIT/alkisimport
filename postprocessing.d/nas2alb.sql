/***************************************************************************
 *                                                                         *
 * Project:  norGIS ALKIS Import                                           *
 * Purpose:  ALB-Daten in norBIT WLDGE-Strukturen aus ALKIS-Daten füllen   *
 * Author:   Jürgen E. Fischer <jef@norbit.de>                             *
 *                                                                         *
 ***************************************************************************
 * Copyright (c) 2012-2017, Jürgen E. Fischer <jef@norbit.de>              *
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

--
-- ALKIS:
-- ax_gebaeudeausgestaltung | zeigtAuf               | ax_gebaeude                                        |  43882
-- ax_gebaeude              | zeigtAuf               | ax_lagebezeichnungmithausnummer                    |  19229
-- ax_flurstueck            | weistAuf               | ax_lagebezeichnungmithausnummer                    |  20481
-- ax_flurstueck            | zeigtAuf               | ax_lagebezeichnungohnehausnummer                   |  11596
-- ax_flurstueck            | istGebucht             | ax_buchungsstelle                                  |  27128
-- ax_buchungsstelle        | an                     | ax_buchungsstelle                                  |  13832
-- ax_buchungsstelle        | istBestandteilVon      | ax_buchungsblatt                                   |  33633
-- ax_namensnummer          | istBestandteilVon      | ax_buchungsblatt                                   |  43780
-- ax_namensnummer          | benennt                | ax_person                                          |  42681
-- ax_person                | hat                    | ax_anschrift                                       |  42616

-- ALKIS => ALB
-- ax_flurstueck				=> FLURST
-- ax_lagebezeichnungmithausnummer		=> STRASSEN
-- ax_lagebezeichnungohnehausnummer		=> STRASSEN
-- ax_lagebezeichnungkatalogeintrag		=> STR_SHL
-- ax_buchungsstelle				=> EIGNERART
-- ax_buchungsblatt				=> BESTAND
-- ax_namensnummer & ax_person & ax_anschrift	=> EIGNER

-- ax_flurstueck => flurst

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

SELECT alkis_dropobject('alkis_fixgeometry');
CREATE FUNCTION alkis_fixgeometry(t TEXT) RETURNS VARCHAR AS $$
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
			EXECUTE 'CREATE TABLE ' || t || '_defekt AS SELECT gml_id,beginnt,wkb_geometry FROM ' || t || ' WHERE NOT st_isvalid(wkb_geometry)';
		EXCEPTION WHEN OTHERS THEN
			EXECUTE 'INSERT INTO ' || t || '_defekt(gml_id,beginnt,wkb_geometry) SELECT gml_id,beginnt,wkb_geometry FROM ' || t || ' WHERE NOT st_isvalid(wkb_geometry)';
		END;

		EXECUTE 'UPDATE ' || t || ' SET wkb_geometry=st_makevalid(wkb_geometry) WHERE NOT st_isvalid(wkb_geometry)';
		GET DIAGNOSTICS n = ROW_COUNT;
		IF n > 0 THEN
			RAISE NOTICE '% Geometrien in % korrigiert.', n, t;
		END IF;

		RETURN t || ' geprüft (' || n || ' ungültige Geometrien in ' || t || '_defekt gesichert und korrigiert).';
	EXCEPTION WHEN OTHERS THEN
		m := SQLERRM;

		BEGIN
			EXECUTE 'SELECT count(*) FROM ' || t || ' WHERE NOT st_isvalid(wkb_geometry)' INTO n;
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

SELECT alkis_dropobject('alkis_nutzungen');
CREATE TABLE alkis_nutzungen(
	element VARCHAR PRIMARY KEY,
	funktionsfeld VARCHAR,
	relationstext VARCHAR,
	elementtext VARCHAR,
	enumeration VARCHAR
);

INSERT INTO alkis_nutzungen(element, funktionsfeld, relationstext, elementtext, enumeration) VALUES
	('ax_bahnverkehr',				'funktion',		', ',				'Bahnverkehr',					'ax_funktion_bahnverkehr'),
	('ax_bergbaubetrieb',				'abbaugut',		' von ',			'Bergbaubetrieb',				'ax_abbaugut_bergbaubetrieb'),
	('ax_flaechebesondererfunktionalerpraegung',	'funktion',		', ',				'Fläche besonderer funktionaler Prägung',	'ax_funktion_flaechebesondererfunktionalerpraegung'),
	('ax_flaechegemischternutzung',			'funktion',		', ',				'Fläche gemischter Nutzung',			'ax_funktion_flaechegemischternutzung'),
	('ax_fliessgewaesser',				'funktion',		', ',				'Fließgewässer',				'ax_funktion_fliessgewaesser'),
	('ax_flugverkehr', 				'funktion',		', ', 				'Flugverkehr',					'ax_funktion_flugverkehr'),
	('ax_friedhof',					'funktion',		', ',				'Friedhof',					'ax_funktion_friedhof'),
	('ax_gehoelz',					'funktion',		', ',				'Gehölz',					'ax_funktion_gehoelz'),
	('ax_hafenbecken',				'funktion',		', ',				'Hafenbecken',					'ax_funktion_hafenbecken'),
	('ax_halde',					'lagergut',		', ',				'Halde',					'ax_lagergut_halde'),
	('ax_heide',					'NULL',			'',				'Heide',					NULL),
	('ax_industrieundgewerbeflaeche',		'funktion',		', ', 				'Industrie- und Gewerbefläche',			'ax_funktion_industrieundgewerbeflaeche'),
	('ax_landwirtschaft', 				'vegetationsmerkmal',	', ',				'Landwirtschaft',				'ax_vegetationsmerkmal_landwirtschaft'),
	('ax_meer',					'funktion',		', ',				'Meer',						'ax_funktion_meer'),
	('ax_moor',					'NULL',			'',				'Moor',						NULL),
	('ax_platz',					'funktion',		', ',				'Platz',					'ax_funktion_platz'),
	('ax_schiffsverkehr',				'funktion',		', ',				'Schiffsverkehr',				'ax_funktion_schiffsverkehr'),
	('ax_sportfreizeitunderholungsflaeche',		'funktion',		', ',				'Sport-, Freizeit- und Erholungsfläche',	'ax_funktion_sportfreizeitunderholungsflaeche'),
	('ax_stehendesgewaesser',			'funktion',		', ',				'Stehendes Gewässer',				'ax_funktion_stehendesgewaesser'),
	('ax_strassenverkehr',				'funktion',		', ',				'Straßenverkehr',				'ax_funktion_strasse'),
	('ax_sumpf',					'NULL',			'',				'Sumpf',					NULL),
	('ax_tagebaugrubesteinbruch',			'abbaugut',		' von ',			'Tagebau, Grube, Steinbruch',			'ax_abbaugut_tagebaugrubesteinbruch'),
	('ax_unlandvegetationsloseflaeche',		'funktion',		', ',				'Unland, vegetationslose Fläche',		'ax_funktion_unlandvegetationsloseflaeche'),
	('ax_wald',					'vegetationsmerkmal',	', ',				'Wald',						'ax_vegetationsmerkmal_wald'),
	('ax_weg',					'funktion',		', ',				'Weg',						'ax_funktion_weg'),
	('ax_wohnbauflaeche',				'artderbebauung',	' mit Art der Bebauung ',	'Wohnbaufläche',				'ax_artderbebauung_wohnbauflaeche');

SELECT alkis_dropobject('alkis_createnutzung');
CREATE OR REPLACE FUNCTION alkis_createnutzung() RETURNS varchar AS $$
DECLARE
	r  RECORD;
	nv VARCHAR;
	kv VARCHAR;
	d  VARCHAR;
	i  INTEGER;
	res VARCHAR;
	invalid INTEGER;
BEGIN
	nv := E'CREATE VIEW ax_tatsaechlichenutzung AS\n  ';
	kv := E'CREATE VIEW ax_tatsaechlichenutzungsschluessel AS\n  ';
	d := '';

	i := 0;
	FOR r IN
		SELECT
			name,
			kennung,
			funktionsfeld,
			relationstext,
			elementtext,
			enumeration
		FROM alkis_elemente
		JOIN alkis_nutzungen ON alkis_elemente.name=alkis_nutzungen.element
		WHERE 'ax_tatsaechlichenutzung' = ANY (abgeleitet_aus)
	LOOP
		res := alkis_string_append(res, alkis_fixgeometry(r.name));

		nv := nv
		   || d
		   || 'SELECT '
		   || 'ogc_fid*32+' || i ||' AS ogc_fid,'
		   || '''' || r.name || '''::text AS name,'
		   || 'gml_id,'
		   || alkis_toint(r.kennung) || ' AS kennung,'
		   || r.funktionsfeld  || '::text AS funktion,'
		   || '''' || r.kennung || '''||coalesce('':''||' || r.funktionsfeld || ','''')::text AS nutzung,'
		   || 'wkb_geometry'
		   || ' FROM ' || r.name
		   || ' WHERE endet IS NULL AND hatdirektunten IS NULL'
		   ;

		kv := kv
		   || d
		   || 'SELECT ''' || r.kennung || ''' AS nutzung,''' || r.elementtext ||''' AS name'
		   ;

		IF r.funktionsfeld<>'NULL' THEN
			kv := kv
			   || ' UNION SELECT ''' || r.kennung || ':''|| wert AS nutzung,'''
			   || coalesce(r.elementtext,'') || coalesce(r.relationstext,'') || '''|| beschreibung AS name'
			   || ' FROM ' || r.enumeration
			   ;
		END IF;

		d := E' UNION ALL\n  ';
		i := i + 1;
	END LOOP;

	PERFORM alkis_dropobject('ax_tatsaechlichenutzung');
	EXECUTE nv;

	PERFORM alkis_dropobject('ax_tatsaechlichenutzungsschluessel');
	EXECUTE kv;

	RETURN alkis_string_append(res, 'ax_tatsaechlichenutzung und ax_tatsaechlichenutzungsschluessel erzeugt.');
END;
$$ LANGUAGE plpgsql;

SELECT alkis_dropobject('alkis_klassifizierungen');
CREATE TABLE alkis_klassifizierungen(
	element VARCHAR PRIMARY KEY,
	funktionsfeld VARCHAR,
	prefix VARCHAR,
	ackerzahl VARCHAR,
	bodenzahl VARCHAR,
	enumeration VARCHAR
);

INSERT INTO alkis_klassifizierungen(element, prefix, funktionsfeld, bodenzahl, ackerzahl, enumeration) VALUES
	('ax_bodenschaetzung',			'b', 'kulturart',		'bodenzahlodergruenlandgrundzahl',	'ackerzahlodergruenlandzahl',	'ax_kulturart_bodenschaetzung'),
	('ax_bewertung',			'B', 'klassifizierung',		'NULL::varchar',			'NULL::varchar',		'ax_klassifizierung_bewertung'),
	('ax_klassifizierungnachwasserrecht',	'W', 'artderfestlegung',	'NULL::varchar',			'NULL::varchar',		'ax_artderfestlegung_klassifizierungnachwasserrecht'),
	('ax_klassifizierungnachstrassenrecht',	'S', 'artderfestlegung',	'NULL::varchar',			'NULL::varchar',		'ax_artderfestlegung_klassifizierungnachstrassenrecht');

SELECT alkis_dropobject('alkis_createklassifizierung');
CREATE FUNCTION alkis_createklassifizierung() RETURNS varchar AS $$
DECLARE
	r  RECORD;
	nv VARCHAR;
	kv VARCHAR;
	d  VARCHAR;
	i  INTEGER;
	res VARCHAR;
	invalid INTEGER;
BEGIN
	nv := E'CREATE VIEW ax_klassifizierung AS\n  ';
	kv := E'CREATE VIEW ax_klassifizierungsschluessel AS\n  ';
	d := '';

	i := 0;
	FOR r IN
		SELECT
			name,
			kennung,
			funktionsfeld,
			prefix,
			bodenzahl,
			ackerzahl,
			enumeration
		FROM alkis_elemente
		JOIN alkis_klassifizierungen ON alkis_elemente.name=alkis_klassifizierungen.element
	LOOP
		res := alkis_string_append(res, alkis_fixgeometry(r.name));

		nv := nv
		   || d
		   || 'SELECT '
		   || 'ogc_fid*4+' || i || ' AS ogc_fid,'
		   || '''' || r.name    || '''::text AS name,'
		   || 'gml_id,'
		   || alkis_toint(r.kennung) || ' AS kennung,'
		   || r.funktionsfeld || ' AS artderfestlegung,'
		   || r.bodenzahl || ' AS bodenzahl,'
		   || r.ackerzahl || ' AS ackerzahl,'
		   || '''' || r.prefix || ':''||' || r.funktionsfeld || ' AS klassifizierung,'
		   || 'wkb_geometry'
		   || ' FROM ' || r.name
		   || ' WHERE endet IS NULL'
		   ;

		IF r.enumeration IS NOT NULL THEN
			kv := kv
			   || d
			   || 'SELECT '
			   || '''' || r.prefix || ':''|| wert AS klassifizierung, beschreibung AS name'
			   || '  FROM ' || r.enumeration
			   ;
		END IF;

		d := E' UNION\n  ';
		i := i + 1;
	END LOOP;

	PERFORM alkis_dropobject('ax_klassifizierung');
	EXECUTE nv;

	PERFORM alkis_dropobject('ax_klassifizierungsschluessel');
	EXECUTE kv;

	RETURN alkis_string_append(res, 'ax_klassifizierung und ax_klassifizierungsschluessel erzeugt.');
END;
$$ LANGUAGE plpgsql;

SELECT alkis_dropobject('alkis_createausfuehrendestellen');
CREATE FUNCTION alkis_createausfuehrendestellen() RETURNS varchar AS $$
DECLARE
	c RECORD;
	r VARCHAR[];
	v VARCHAR;
	d VARCHAR;
	f VARCHAR;
	p VARCHAR;
	i INTEGER;
	res VARCHAR;
	invalid INTEGER;
BEGIN
	PERFORM alkis_dropobject('ax_ausfuehrendestellen');

	PERFORM alkis_dropobject('v_schutzgebietnachwasserrecht');
	CREATE TABLE v_schutzgebietnachwasserrecht AS
		SELECT z.ogc_fid,z.gml_id,'ax_schutzzone'::varchar AS name,s.land,s.stelle,z.wkb_geometry,NULL::text AS endet, hatdirektunten
		FROM ax_schutzgebietnachwasserrecht s
		JOIN ax_schutzzone z ON ARRAY[s.gml_id] <@ z.istteilvon AND z.endet IS NULL
		WHERE false;
	CREATE INDEX v_schutzgebietnachwasserrecht_wkb_geometry_idx ON v_schutzgebietnachwasserrecht USING gist(wkb_geometry);

	PERFORM alkis_dropobject('v_schutzgebietnachnaturumweltoderbodenschutzrecht');
	CREATE TABLE v_schutzgebietnachnaturumweltoderbodenschutzrecht AS
		SELECT z.ogc_fid,z.gml_id,'ax_schutzzone'::varchar AS name,s.land,s.stelle,z.wkb_geometry,NULL::text AS endet, hatdirektunten
		FROM ax_schutzgebietnachnaturumweltoderbodenschutzrecht s
		JOIN ax_schutzzone z ON ARRAY[s.gml_id] <@ z.istteilvon AND z.endet IS NULL
		WHERE false;
	CREATE INDEX v_schutzgebietnachnuobr_wkb_geometry_idx ON v_schutzgebietnachnaturumweltoderbodenschutzrecht USING gist(wkb_geometry);

	v := E'CREATE VIEW ax_ausfuehrendestellen AS\n  ';
	d := '';

	i := 1;
	FOR c IN SELECT table_name FROM information_schema.tables WHERE table_schema=current_schema() AND table_name IN (
			'v_schutzgebietnachwasserrecht',
			'v_schutzgebietnachnaturumweltoderbodenschutzrecht',
			'ax_naturumweltoderbodenschutzrecht',
			'ax_forstrecht',
			'ax_bauraumoderbodenordnungsrecht',
			'ax_klassifizierungnachstrassenrecht',
			'ax_denkmalschutzrecht',
			'ax_anderefestlegungnachwasserrecht',
			'ax_anderefestlegungnachstrassenrecht',
			'ax_sonstigesrecht',
			'ax_klassifizierungnachwasserrecht'
		)
	LOOP
		res := alkis_string_append(res, alkis_fixgeometry(c.table_name));

		v := v
		  || d
		  || 'SELECT '
		  || 'ogc_fid*16+' || i || ' AS ogc_fid,'
		  || '''' || c.table_name || '''::text AS name,'
		  || 'gml_id,'
		  || 'to_char(alkis_toint(land),''fm00'') || stelle AS ausfuehrendestelle,'
		  || 'wkb_geometry'
		  || ' FROM ' || c.table_name
		  || ' WHERE endet IS NULL AND hatdirektunten IS NULL'
		  ;

		d := E' UNION ALL\n  ';
		i := i + 1;
	END LOOP;

	EXECUTE v;

	RETURN alkis_string_append(res, 'ax_ausfuehrendestellen erzeugt.');
END;
$$ LANGUAGE plpgsql;

SELECT 'Prüfe Flurstücksgeometrien...';
SELECT alkis_fixgeometry('ax_flurstueck');

DELETE FROM flurst;
INSERT INTO flurst(flsnr,flsnrk,gemashl,flr,entst,fortf,flsfl,amtlflsfl,gemflsfl,af,flurknr,baublock,flskoord,fora,fina,h1shl,h2shl,hinwshl,strshl,gemshl,hausnr,lagebez,k_anlverm,anl_verm,blbnr,n_flst,ff_entst,ff_stand,ff_datum)
   SELECT
     alkis_flsnr(a) AS flsnr,
     alkis_flsnrk(a) AS flsnrk,
     to_char(alkis_toint(a.land),'fm00') || to_char(alkis_toint(a.gemarkungsnummer),'fm0000') AS gemashl,
     to_char(coalesce(a.flurnummer,0),'fm000') AS flr,
     to_char(date_part('year', a.zeitpunktderentstehung), 'fm0000') || '/     -  ' AS entst,
     NULL AS fortf,
     amtlicheflaeche::int AS flsfl,
     amtlicheflaeche AS amtlflsfl,
     st_area(wkb_geometry) AS gemflsfl,
     '01' AS af,
     NULL AS flurknr,
     NULL AS baublock,
     alkis_flskoord(a) AS flskoord,
     NULL AS fora,
     NULL AS fina,
     NULL AS h1shl,
     NULL AS h2shl,
     NULL AS hinwshl,
     NULL AS strshl,
     to_char(alkis_toint(a.gemeindezugehoerigkeit_land),'fm00')||a.gemeindezugehoerigkeit_regierungsbezirk||to_char(alkis_toint(a.gemeindezugehoerigkeit_kreis),'fm00')||to_char(alkis_toint(a.gemeindezugehoerigkeit_gemeinde),'fm000') AS gemshl,
     NULL AS hausnr,
     (
      SELECT array_to_string(array_agg(DISTINCT unverschluesselt),E'\n')
      FROM ax_lagebezeichnungohnehausnummer l
      WHERE l.endet IS NULL AND l.gml_id=ANY(a.zeigtauf)
     ) AS lagebez,
     NULL AS k_anlverm,
     NULL AS anl_verm,
     NULL AS blbnr,
     NULL AS n_flst,
     0 AS ff_entst,
     0 AS ff_stand,
     NULL AS ff_datum
   FROM ax_flurstueck a
   WHERE a.endet IS NULL
     -- Workaround für gleiche Bestände von mehrere Katasterämtern
     AND NOT EXISTS (
	SELECT *
	FROM ax_flurstueck b
	WHERE b.endet IS NULL
	  AND alkis_flsnr(a)=alkis_flsnr(b)
	  AND b.beginnt<a.beginnt
	  AND a.ogc_fid<>b.ogc_fid
	)
     ;

DELETE FROM str_shl;
INSERT INTO str_shl(strshl,strname,gemshl)
	SELECT DISTINCT
		to_char(alkis_toint(land),'fm00')||regierungsbezirk||to_char(alkis_toint(kreis),'fm00')||to_char(alkis_toint(gemeinde),'fm000')||'    '||trim(lage) AS strshl,
		regexp_replace(bezeichnung,' H$','') AS strname,	-- RP: Historische Straßennamen mit H am Ende
		to_char(alkis_toint(land),'fm00')||regierungsbezirk||to_char(alkis_toint(kreis),'fm00')||to_char(alkis_toint(gemeinde),'fm000') AS gemshl
	FROM ax_lagebezeichnungkatalogeintrag a
	WHERE endet IS NULL
	  -- Nur nötig, weil Kataloge nicht vernünfigt geführt werden und doppelte Einträge vorkommen
	  AND NOT EXISTS (SELECT * FROM ax_lagebezeichnungkatalogeintrag b WHERE b.endet IS NULL AND a.schluesselgesamt=b.schluesselgesamt AND b.beginnt<a.beginnt);

SELECT alkis_dropobject('strassen_pk_seq');
CREATE SEQUENCE strassen_pk_seq;

DELETE FROM strassen;
INSERT INTO strassen(flsnr,pk,strshl,hausnr,ff_entst,ff_stand)
	SELECT
		flsnr,
		to_hex(nextval('strassen_pk_seq'::regclass)) AS pk,
		strshl,
		hausnr,
		0,
		0
	FROM (
		SELECT
			alkis_flsnr(f) AS flsnr,
			to_char(alkis_toint(l.land),'fm00')||l.regierungsbezirk||to_char(alkis_toint(l.kreis),'fm00')||to_char(alkis_toint(l.gemeinde),'fm000')||'    '||trim(lage) AS strshl,
			hausnummer AS hausnr
		FROM ax_lagebezeichnungmithausnummer l
		JOIN ax_flurstueck f ON ARRAY[l.gml_id] <@ f.weistauf AND f.endet IS NULL
		WHERE NOT l.lage IS NULL AND l.endet IS NULL
	UNION
		SELECT
			alkis_flsnr(f) AS flsnr,
			to_char(alkis_toint(l.land),'fm00')||l.regierungsbezirk||to_char(alkis_toint(l.kreis),'fm00')||to_char(alkis_toint(l.gemeinde),'fm000')||'    '||trim(lage) AS strshl,
			'' AS hausnr
		FROM ax_lagebezeichnungohnehausnummer l
		JOIN ax_flurstueck f ON ARRAY[l.gml_id] <@ f.zeigtauf AND f.endet IS NULL
		WHERE NOT l.lage IS NULL AND l.endet IS NULL
	) AS foo;

DELETE FROM gem_shl;
INSERT INTO gem_shl(gemshl,gemname)
	SELECT
		to_char(alkis_toint(schluesselgesamt),'fm00000000') AS gemshl,
		min(bezeichnung) AS gemname
	FROM ax_gemeinde a
	WHERE endet IS NULL
	GROUP BY to_char(alkis_toint(schluesselgesamt),'fm00000000');

DELETE FROM gema_shl;
INSERT INTO gema_shl(gemashl,gemarkung)
	SELECT
		to_char(alkis_toint(land),'fm00')||to_char(alkis_toint(gemarkungsnummer),'fm0000') AS gemashl,
		MIN(bezeichnung) AS gemarkung
	FROM ax_gemarkung
	WHERE endet IS NULL
	GROUP BY to_char(alkis_toint(land),'fm00')||to_char(alkis_toint(gemarkungsnummer),'fm0000');

DELETE FROM eignerart;
INSERT INTO eignerart(flsnr,bestdnr,bvnr,b,anteil,auftlnr,sa,ff_entst,ff_stand,lkfs)
	SELECT
		alkis_flsnr(f) AS flsnr,
		to_char(alkis_toint(bb.land),'fm00') || to_char(alkis_toint(bb.bezirk),'fm0000') || '-' || trim(bb.buchungsblattnummermitbuchstabenerweiterung) AS bestdnr,
		lpad(substr(laufendenummer,length(laufendenummer)-3),4,'0') AS bvnr,
		buchungsart AS b,
		coalesce(bs.zaehler || '/' || bs.nenner,bs.zaehler::text) AS anteil,
		laufendenummer AS auftrlnr,
		NULL AS sa,
		0 AS ff_entst,
		0 AS ff_stand,
		NULL AS lkfs
	FROM ax_flurstueck f
	JOIN ax_buchungsstelle bs ON bs.gml_id=f.istgebucht AND bs.endet IS NULL
	JOIN ax_buchungsblatt bb ON bb.gml_id=bs.istbestandteilvon AND bb.endet IS NULL
	WHERE f.endet IS NULL
	UNION
	SELECT
		alkis_flsnr(f) AS flsnr,
		to_char(alkis_toint(bb.land),'fm00') || to_char(alkis_toint(bb.bezirk),'fm0000') || '-' || trim(bb.buchungsblattnummermitbuchstabenerweiterung) AS bestdnr,
		lpad(substr(bs.laufendenummer,length(bs.laufendenummer)-3),4,'0') AS bvnr,
		bs.buchungsart AS b,
		coalesce(bs.zaehler || '/' || bs.nenner, bs.zaehler::text) AS anteil,
		-- bs.nummerimaufteilungsplan AS auftrlnr,
		bs.laufendenummer AS auftrlnr,
		NULL AS sa,
		0 AS ff_entst,
		0 AS ff_stand,
		NULL AS lkfs
	FROM ax_flurstueck f
	JOIN ax_buchungsstelle bs0 ON bs0.gml_id=f.istgebucht AND bs0.endet IS NULL
	JOIN ax_buchungsstelle bs  ON ARRAY[bs0.gml_id] <@ bs.an AND bs.endet IS NULL
	JOIN ax_buchungsblatt bb ON bb.gml_id=bs.istbestandteilvon AND bb.endet IS NULL
	WHERE f.endet IS NULL
	;

SELECT alkis_dropobject('bem_best_pk_seq');
CREATE SEQUENCE bem_best_pk_seq;

DELETE FROM bem_best;
INSERT INTO bem_best(bestdnr,pk,lnr,text,ff_entst,ff_stand)
	SELECT
		to_char(alkis_toint(bb.land),'fm00') || to_char(alkis_toint(bb.bezirk),'fm0000') || '-' || trim(bb.buchungsblattnummermitbuchstabenerweiterung) AS bestdnr,
		to_hex(nextval('bem_best_pk_seq'::regclass)) AS pk,
		laufendenummer AS lnr,
		beschreibungdessondereigentums AS text,
		0 AS ff_entst,
		0 AS ff_stand
	FROM ax_buchungsstelle bs
	JOIN ax_buchungsblatt bb ON bb.gml_id=bs.istbestandteilvon AND bb.endet IS NULL
	WHERE bs.beschreibungdessondereigentums IS NOT NULL AND bs.endet IS NULL;

DELETE FROM bestand;
INSERT INTO bestand(bestdnr,gbbz,gbblnr,anteil,auftlnr,bestfl,ff_entst,ff_stand,pz)
	SELECT
		to_char(alkis_toint(land),'fm00') || to_char(alkis_toint(bezirk),'fm0000') || '-' || trim(buchungsblattnummermitbuchstabenerweiterung) AS bestdnr,
		to_char(alkis_toint(bezirk),'fm0000') AS gbbz,
		to_char(to_number(buchungsblattnummermitbuchstabenerweiterung,'0000000')::int,'fm0000000') AS gbblnr,
		NULL AS anteil,
		NULL AS auftrlnr,
		NULL AS bestfl,
		0 AS ff_entst,
		0 AS ff_stand,
		NULL AS pz
	FROM ax_buchungsblatt bb
	WHERE bb.endet IS NULL
	  -- Workaround für gleiche Bestände von mehrere Katasterämtern
	  AND NOT EXISTS (
		SELECT *
		FROM ax_buchungsblatt bb2
		WHERE bb2.endet IS NULL
		  AND bb.land=bb2.land AND bb.bezirk=bb2.bezirk AND trim(bb.buchungsblattnummermitbuchstabenerweiterung)=trim(bb2.buchungsblattnummermitbuchstabenerweiterung)
	          AND bb2.beginnt<bb.beginnt
	          AND bb2.ogc_fid<>bb.ogc_fid
	  )
	;

SELECT alkis_dropobject('eigner_pk_seq');
CREATE SEQUENCE eigner_pk_seq;

DELETE FROM eigner;
INSERT INTO eigner(bestdnr,pk,ab,namensnr,ea,antverh,name,name1,name2,name3,name4,name5,name6,name7,name8,anrede,vorname,nachname,namensteile,ak_grade,geb_name,geb_datum,str_hnr,plz_pf,postfach,plz,ort,land,ff_entst,ff_stand)
	SELECT
		to_char(alkis_toint(bb.land),'fm00') || to_char(alkis_toint(bb.bezirk),'fm0000') || '-' || trim(bb.buchungsblattnummermitbuchstabenerweiterung) AS bestdnr,
		to_hex(nextval('eigner_pk_seq'::regclass)) AS pk,
		NULL AS ab,
		laufendenummernachdin1421 AS namensnr,
		NULL AS ea,
		zaehler||'/'||nenner AS antverh,
		substr( coalesce( p.nachnameoderfirma, '(' || (SELECT beschreibung FROM ax_artderrechtsgemeinschaft_namensnummer WHERE wert=artderrechtsgemeinschaft) || ')' ), 1, 4 ) AS name,
		coalesce( p.nachnameoderfirma || coalesce(', ' || p.vorname, ''), '(' || (SELECT beschreibung FROM ax_artderrechtsgemeinschaft_namensnummer WHERE wert=artderrechtsgemeinschaft) || ')', '(Verschiedene)' ) AS name1,
		coalesce('geb. '||p.geburtsname||', ','') || '* ' || p.geburtsdatum AS name2,
		an.strasse || coalesce(' ' || an.hausnummer,'') AS name3,
		coalesce(an.postleitzahlpostzustellung||' ','')||an.ort_post AS name4,
		bestimmungsland AS name5,
		NULL AS name6,
		NULL AS name7,
		NULL AS name8,
		(SELECT beschreibung FROM ax_anrede_person WHERE wert=p.anrede) AS anrede,
		p.vorname AS vorname,
		p.nachnameoderfirma AS nachname,
		p.namensbestandteil AS namensteile,
		p.akademischergrad AS ak_grade,
		p.geburtsname AS geb_name,
		p.geburtsdatum AS geb_datum,
		an.strasse || coalesce(' ' || an.hausnummer,'') AS str_hnr,
		NULL AS plz_pf,
		NULL AS postfach,
		an.postleitzahlpostzustellung AS plz,
		an.ort_post AS ort,
		bestimmungsland AS land,
		0 AS ff_entst,
		0 AS ff_fortf
	FROM ax_namensnummer nn
	JOIN ax_buchungsblatt bb ON bb.gml_id=nn.istbestandteilvon AND bb.endet IS NULL
	LEFT OUTER JOIN ax_person p ON p.gml_id=nn.benennt AND p.endet IS NULL
	LEFT OUTER JOIN ax_anschrift an ON an.gml_id = ANY (p.hat) AND an.endet IS NULL
	WHERE nn.endet IS NULL;

UPDATE eigner SET name1=regexp_replace(name1, E'\\s\\s+', ' ');

INSERT INTO eigner(bestdnr,pk,name1,ff_entst,ff_stand)
	SELECT
		bestdnr,
		to_hex(nextval('eigner_pk_seq'::regclass)) AS pk,
		'(mehrere)' AS name1,
		0 AS ff_entst,
		0 AS ff_fortf
	FROM bestand
	WHERE NOT EXISTS (SELECT * FROM eigner WHERE eigner.bestdnr=bestand.bestdnr);

DELETE FROM str_shl WHERE NOT EXISTS (SELECT * FROM strassen WHERE str_shl.strshl=strassen.strshl);
DELETE FROM gema_shl
	WHERE NOT EXISTS (SELECT * FROM flurst WHERE flurst.gemashl=gema_shl.gemashl)
	  AND NOT EXISTS (SELECT * FROM bestand WHERE substr(bestdnr,1,6)=gema_shl.gemashl);

UPDATE gema_shl SET gemshl=(SELECT gemshl FROM flurst WHERE flurst.gemashl=gema_shl.gemashl LIMIT 1);

DELETE FROM gem_shl
  WHERE NOT EXISTS (SELECT * FROM gema_shl WHERE gema_shl.gemshl=gem_shl.gemshl)
    AND NOT EXISTS (SELECT * FROM str_shl WHERE str_shl.gemshl=gem_shl.gemshl)
    AND NOT EXISTS (SELECT * FROM flurst WHERE flurst.gemshl=gem_shl.gemshl);

UPDATE str_shl SET strname=trim(regexp_replace(strname,' H$','')) WHERE strshl LIKE '07%'; -- RP: H-Suffix für historische Straßen entfernen

--
--
--

DELETE FROM eign_shl;
INSERT INTO eign_shl(b,eignerart)
	SELECT
		wert AS b,
		beschreibung AS eignerart
	FROM ax_buchungsart_buchungsstelle;

DELETE FROM fortf;
INSERT INTO fortf(ffnr,beschreibung) VALUES (1, 'Aus ALKIS übernommen: '||to_char(CURRENT_TIMESTAMP AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS"Z"'));

DELETE FROM fs;
INSERT INTO fs(fs_key,fs_obj,alb_key)
  SELECT ogc_fid,gml_id,alkis_flsnr(ax_flurstueck) FROM ax_flurstueck WHERE endet IS NULL;

CREATE TEMPORARY TABLE amtlbestfl AS
	SELECT
		bestdnr,
		SUM(
			amtlflsfl*
			CASE
			WHEN anteil IS NULL OR split_part(anteil,'/',2)::float8=0 THEN 1.0
			ELSE split_part(anteil,'/',1)::float8 / split_part(anteil,'/',2)::float8
			END
		) AS amtlbestfl
	FROM flurst
	JOIN eignerart ON flurst.flsnr=eignerart.flsnr
	GROUP BY bestdnr;

CREATE UNIQUE INDEX amtlbestfl_idx ON amtlbestfl(bestdnr);

UPDATE bestand SET amtlbestfl=(SELECT amtlbestfl FROM amtlbestfl WHERE amtlbestfl.bestdnr=bestand.bestdnr);

UPDATE bestand SET bestfl=amtlbestfl::int WHERE amtlbestfl<=2147483647; -- maxint

SELECT "Buchdaten","Anzahl" FROM (
  SELECT 1 AS o, 'Bestände' AS "Buchdaten", count(*) AS "Anzahl" FROM bestand UNION
  SELECT 2, 'Bestände ohne Eigentümerart', count(*) FROM bestand WHERE NOT EXISTS (SELECT * FROM eignerart WHERE eignerart.bestdnr=bestand.bestdnr) UNION
  SELECT 3, 'Bestände ohne Eigentümer', count(*) FROM bestand WHERE NOT EXISTS (SELECT * FROM eigner WHERE eigner.bestdnr=bestand.bestdnr) UNION
  SELECT 4, 'Flurstücke', count(*) FROM flurst UNION
  SELECT 5, 'Flurstücke ohne Eigentümerart', count(*) FROM flurst WHERE NOT EXISTS (SELECT * FROM eignerart WHERE eignerart.flsnr=flurst.flsnr)
) AS stat ORDER BY o;

DELETE FROM v_schutzgebietnachwasserrecht;
INSERT INTO v_schutzgebietnachwasserrecht
    SELECT z.ogc_fid,z.gml_id,'ax_schutzzone'::varchar AS name,s.land,s.stelle,z.wkb_geometry,NULL::text AS endet
    FROM ax_schutzgebietnachwasserrecht s
    JOIN ax_schutzzone z ON ARRAY[s.gml_id] <@ z.istteilvon AND z.endet IS NULL
    WHERE s.endet IS NULL;
CREATE TEMP SEQUENCE a;
UPDATE v_schutzgebietnachwasserrecht SET ogc_fid=nextval('a');

DELETE FROM v_schutzgebietnachnaturumweltoderbodenschutzrecht;
INSERT INTO v_schutzgebietnachnaturumweltoderbodenschutzrecht
    SELECT z.ogc_fid,z.gml_id,'ax_schutzzone'::varchar AS name,s.land,s.stelle,z.wkb_geometry,NULL::text AS endet
    FROM ax_schutzgebietnachnaturumweltoderbodenschutzrecht s
    JOIN ax_schutzzone z ON ARRAY[s.gml_id] <@ z.istteilvon AND z.endet IS NULL
    WHERE s.endet IS NULL;
DROP SEQUENCE a;
CREATE TEMP SEQUENCE a;
UPDATE v_schutzgebietnachwasserrecht SET ogc_fid=nextval('a');

SELECT 'Erzeuge Sicht für Klassifizierungen...';
SELECT alkis_createklassifizierung();

DELETE FROM kls_shl;
INSERT INTO kls_shl(klf,klf_text)
  SELECT klassifizierung,name FROM ax_klassifizierungsschluessel;

SELECT 'Bestimme Flurstücksklassifizierungen...';

SELECT alkis_dropobject('klas_3x_pk_seq');
CREATE SEQUENCE klas_3x_pk_seq;

DELETE FROM klas_3x;
INSERT INTO klas_3x(flsnr,pk,klf,wertz1,wertz2,gemfl,fl,ff_entst,ff_stand)
  SELECT
    alkis_flsnr(f) AS flsnr,
    to_hex(nextval('klas_3x_pk_seq'::regclass)) AS pk,
    k.klassifizierung AS klf,
    k.bodenzahl,
    k.ackerzahl,
     sum(st_area(alkis_intersection(f.wkb_geometry,k.wkb_geometry,'ax_flurstueck:'||f.gml_id||'<=>'||k.name||':'||k.gml_id))) AS gemfl,
    (sum(st_area(alkis_intersection(f.wkb_geometry,k.wkb_geometry,'ax_flurstueck:'||f.gml_id||'<=>'||k.name||':'||k.gml_id)))*amtlicheflaeche/st_area(f.wkb_geometry))::int AS fl,
    0 AS ff_entst,
    0 AS ff_stand
  FROM ax_flurstueck f
  JOIN ax_klassifizierung k
      ON f.wkb_geometry && k.wkb_geometry
      AND alkis_relate(f.wkb_geometry,k.wkb_geometry,'2********','ax_flurstueck:'||f.gml_id||'<=>'||k.name||':'||k.gml_id)
  WHERE f.endet IS NULL
  GROUP BY alkis_flsnr(f), f.amtlicheflaeche, f.wkb_geometry, k.klassifizierung, k.bodenzahl, k.ackerzahl;

SELECT 'Bestimme Flurstücksnutzungen...';

SELECT alkis_dropobject('nutz_shl_pk_seq');
CREATE SEQUENCE nutz_shl_pk_seq;

DELETE FROM nutz_21;
INSERT INTO nutz_21(flsnr,pk,nutzsl,gemfl,fl,ff_entst,ff_stand)
  SELECT
    alkis_flsnr(f) AS flsnr,
    to_hex(nextval('nutz_shl_pk_seq'::regclass)) AS pk,
    n.nutzung AS nutzsl,
     sum(st_area(alkis_intersection(f.wkb_geometry,n.wkb_geometry,'ax_flurstueck:'||f.gml_id||'<=>'||n.name||':'||n.gml_id))) AS gemfl,
    (sum(st_area(alkis_intersection(f.wkb_geometry,n.wkb_geometry,'ax_flurstueck:'||f.gml_id||'<=>'||n.name||':'||n.gml_id))*amtlicheflaeche/st_area(f.wkb_geometry)))::int AS fl,
    0 AS ff_entst,
    0 AS ff_stand
  FROM ax_flurstueck f
  JOIN ax_tatsaechlichenutzung n
      ON f.wkb_geometry && n.wkb_geometry
      AND alkis_relate(f.wkb_geometry,n.wkb_geometry,'2********','ax_flurstueck:'||f.gml_id||'<=>'||n.name||':'||n.gml_id)
  WHERE f.endet IS NULL
  GROUP BY alkis_flsnr(f), f.wkb_geometry, n.nutzung;

SELECT 'Erzeuge Sicht für ausführende Stellen...';
SELECT alkis_createausfuehrendestellen();

SELECT 'Bestimme ausführende Stellen für Flurstücke...';

SELECT alkis_dropobject('ausfst_pk_seq');
CREATE SEQUENCE ausfst_pk_seq;

DELETE FROM ausfst;
INSERT INTO ausfst(flsnr,pk,ausf_st,verfnr,verfshl,ff_entst,ff_stand)
  SELECT
    alkis_flsnr(f) AS flsnr,
    to_hex(nextval('ausfst_pk_seq'::regclass)) AS pk,
    s.ausfuehrendestelle AS ausf_st,
    NULL AS verfnr,
    NULL AS verfshl,
    0 AS ff_entst,
    0 AS ff_stand
  FROM ax_flurstueck f
  JOIN ax_ausfuehrendestellen s
    ON f.wkb_geometry && s.wkb_geometry
    AND alkis_relate(f.wkb_geometry,s.wkb_geometry,'2********','ax_flurstueck:'||f.gml_id||'<=>'||s.name||':'||s.gml_id)
  WHERE f.endet IS NULL
  GROUP BY alkis_flsnr(f), s.ausfuehrendestelle;

DELETE FROM afst_shl;
INSERT INTO afst_shl(ausf_st,afst_txt)
  SELECT
    schluesselgesamt,
    MIN(bezeichnung)
  FROM ax_dienststelle d
  JOIN ausfst ON ausf_st=schluesselgesamt
  GROUP BY schluesselgesamt;

SELECT 'Belege Baulastenblattnummer...';

SELECT alkis_dropobject('bblnr_temp');
CREATE TEMPORARY TABLE bblnr_temp AS
  SELECT
    alkis_flsnr(f) AS flsnr,
    b.bezeichnung
  FROM ax_flurstueck f
  JOIN ax_bauraumoderbodenordnungsrecht b
    ON b.endet IS NULL
    AND b.artderfestlegung=2610
    AND f.wkb_geometry && b.wkb_geometry
    AND alkis_relate(f.wkb_geometry,b.wkb_geometry,'2********','ax_flurstueck:'||f.gml_id||'<=>ax_bauraumoderbodenordnungsrecht:'||b.gml_id)
  WHERE f.endet IS NULL;

CREATE INDEX bblnr_temp_flsnr ON bblnr_temp(flsnr);

UPDATE flurst SET blbnr=(SELECT regexp_replace(array_to_string(array_agg(DISTINCT b.bezeichnung),','),E'\(.{196}\).+',E'\\1 ...') FROM bblnr_temp b WHERE flurst.flsnr=b.flsnr);
