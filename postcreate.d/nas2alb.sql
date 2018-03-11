/***************************************************************************
 *                                                                         *
 * Project:  norGIS ALKIS Import                                           *
 * Purpose:  ALB-Daten in norBIT WLDGE-Strukturen aus ALKIS-Daten füllen   *
 * Author:   Jürgen E. Fischer <jef@norbit.de>                             *
 *                                                                         *
 ***************************************************************************
 * Copyright (c) 2012-2018, Jürgen E. Fischer <jef@norbit.de>              *
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

SELECT alkis_dropobject('alb_version');
CREATE TABLE alb_version(version integer);
INSERT INTO alb_version(version) VALUES (1);

-- Sichten löschen, die von alkis_toint abhängen
SELECT alkis_dropobject('ax_tatsaechlichenutzung');
SELECT alkis_dropobject('ax_klassifizierung');
SELECT alkis_dropobject('ax_ausfuehrendestellen');

SELECT alkis_dropobject('v_eigentuemer');
SELECT alkis_dropobject('v_haeuser');

SELECT alkis_dropobject('alkis_toint');
CREATE OR REPLACE FUNCTION alkis_toint(v anyelement) RETURNS integer AS $$
DECLARE
        res integer;
BEGIN
        SELECT v::int INTO res;
        RETURN res;
EXCEPTION WHEN OTHERS THEN
        RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION alkis_flsnrk(f ax_flurstueck) RETURNS varchar AS $$
BEGIN
	RETURN
		CASE
		WHEN f.gml_id LIKE 'DESL%' THEN
			to_char(f.zaehler,'fm0000') || '/' || to_char(coalesce(alkis_toint(f.nenner),0),'fm0000')
		WHEN f.gml_id LIKE 'DESN%' THEN
			to_char(f.zaehler,'fm00000') || '/' || substring(f.flurstueckskennzeichen,15,4)
		ELSE
			to_char(f.zaehler,'fm00000') || '/' || to_char(coalesce(mod(alkis_toint(f.nenner),1000)::int,0),'fm000')
		END;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION alkis_flsnr(f ax_flurstueck) RETURNS varchar AS $$
BEGIN
	RETURN
		to_char(alkis_toint(f.land),'fm00') || to_char(alkis_toint(f.gemarkungsnummer),'fm0000') ||
		'-' || to_char(coalesce(f.flurnummer,0),'fm000') ||
		'-' || alkis_flsnrk(f);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

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

SELECT alkis_dropobject('flurst');
CREATE TABLE flurst (
	flsnr varchar NOT NULL,
	flsnrk varchar,
	gemashl character(6),
	flr character(3),
	entst character(13),
	fortf character(13),
	flsfl varchar,
	amtlflsfl double precision,
	gemflsfl double precision,
	af character(2),
	flurknr character(14),
	baublock character(12),
	flskoord character(18),
	fora character(4),
	fina character(4),
	h1shl character(2),
	h2shl character(2),
	hinwshl character(59),
	strshl character(32),
	gemshl character(32),
	hausnr character(8),
	lagebez varchar,
	k_anlverm character(1),
	anl_verm character(27),
	blbnr character(200),
	n_flst character(22),
	ff_entst integer NOT NULL,
	ff_stand integer,
	ff_datum character(8),
	primary key (flsnr)
) WITH OIDS;

SELECT alkis_dropobject('ax_flurstueck_flsnr');
CREATE INDEX ax_flurstueck_flsnr ON ax_flurstueck USING btree (alkis_flsnr(ax_flurstueck));

CREATE INDEX flurst_idx0 ON flurst(oid);
CREATE INDEX flurst_idx1 ON flurst(h1shl);
CREATE INDEX flurst_idx2 ON flurst(gemashl);
CREATE INDEX flurst_idx3 ON flurst(strshl);
CREATE INDEX flurst_idx4 ON flurst(lagebez);
CREATE INDEX flurst_idx5 ON flurst(ff_stand);
CREATE INDEX flurst_idx6 ON flurst(ff_entst);
CREATE INDEX flurst_idx7 ON flurst(lagebez);
CREATE INDEX flurst_idx8 ON flurst(flsnr);

SELECT alkis_dropobject('str_shl');
CREATE TABLE str_shl (
	strshl character(32) NOT NULL PRIMARY KEY,
	strname varchar(200),
	gemshl character(32)
);

CREATE INDEX str_shl_idx0 ON str_shl(strshl);
CREATE INDEX str_shl_idx1 ON str_shl(gemshl);

SELECT alkis_dropobject('strassen');
CREATE TABLE strassen (
	flsnr character(21),
	pk character(8) NOT NULL,
	strshl character(32),
	hausnr character(8),
	ff_entst integer,
	ff_stand integer,
	primary key (pk)
);

CREATE INDEX strassen_idx1 ON strassen(flsnr);
CREATE INDEX strassen_idx2 ON strassen(strshl);
CREATE INDEX strassen_ff_entst ON strassen(ff_entst);
CREATE INDEX strassen_ff_stand ON strassen(ff_stand);

SELECT alkis_dropobject('gem_shl');
CREATE TABLE gem_shl (
	gemshl character(32) NOT NULL,
	gemname character(100),
	primary key (gemshl)
);

CREATE INDEX gem_shl_idx0 ON gem_shl(gemshl);

SELECT alkis_dropobject('gema_shl');
CREATE TABLE gema_shl (
	gemashl character(6) NOT NULL,
	gemarkung character(50),
	gemshl character(30),
	ag_shl character(4),
	primary key (gemashl)
);

CREATE INDEX gema_shl_gemshl ON gema_shl(gemshl);
CREATE INDEX gema_shl_ag_shl ON gema_shl(ag_shl);

SELECT alkis_dropobject('eignerart');
CREATE TABLE eignerart (
	flsnr character(21) NOT NULL,
	bestdnr character(16) NOT NULL,
	bvnr character(4) NOT NULL,
	b character(4),
	anteil character(24),
	auftlnr character(12),
	sa character(2),
	ff_entst integer NOT NULL,
	ff_stand integer,
	lkfs character(4),
	primary key (flsnr, bestdnr, bvnr)
);

CREATE INDEX eignerart_idx1 ON eignerart(b);
CREATE INDEX eignerart_idx2 ON eignerart(flsnr);
CREATE INDEX eignerart_idx3 ON eignerart(bestdnr);
CREATE INDEX eignerart_idx4 ON eignerart(sa);
CREATE INDEX eignerart_ff_entst ON eignerart(ff_entst);
CREATE INDEX eignerart_ff_stand ON eignerart(ff_stand);

SELECT alkis_dropobject('bem_best');
CREATE TABLE bem_best (
	bestdnr character(16),
	pk character(8) NOT NULL,
	sa character(1),
	lnr character(4),
	text varchar,
	ff_entst integer,
	ff_stand integer,
	primary key (pk)
);

CREATE INDEX bem_best_idx1 ON bem_best(bestdnr);

SELECT alkis_dropobject('bestand');
CREATE TABLE bestand (
	bestdnr character(16) NOT NULL,
	gbbz character(4),
	gbblnr character(7),
	anteil character(24),
	auftlnr character(12),
	bestfl varchar,
	amtlbestfl double precision,
	ff_entst integer NOT NULL,
	ff_stand integer,
	pz character(1),
	PRIMARY KEY (bestdnr)
);
CREATE INDEX bestand_bestdnr ON bestand(bestdnr);
CREATE INDEX bestand_ff_entst ON bestand(ff_entst);
CREATE INDEX bestand_ff_stand ON bestand(ff_stand);

SELECT alkis_dropobject('eigner');
CREATE TABLE eigner (
	bestdnr character(16),
	pk character(8) NOT NULL,
	ab character(4),
	namensnr character(16),
	ea character(2),
	antverh varchar,

	name character(4),
	name1 varchar(200),
	name2 varchar(200),
	name3 varchar(200),
	name4 varchar(200),
	name5 varchar(200),
	name6 varchar(200),
	name7 varchar(200),
	name8 varchar(200),

	anrede character(20),
	vorname varchar(200),
	nachname varchar(200),
	namensteile character(200),
	ak_grade character(200),
	geb_name varchar(200),
	geb_datum character(10),
	str_hnr varchar(200),
	plz_pf character(20),
	postfach character(20),
	plz character(20),
	ort character(200),
	land character(100),
	ff_entst integer,
	ff_stand integer,

	primary key (pk)
);
CREATE INDEX eigner_idx1 ON eigner(bestdnr);
CREATE INDEX eigner_idx2 ON eigner(name);
CREATE INDEX eigner_ff_entst ON eigner(ff_entst);
CREATE INDEX eigner_ff_stand ON eigner(ff_stand);

--
--
--

SELECT alkis_dropobject('eign_shl');
CREATE TABLE eign_shl (
    b character(4) NOT NULL,
    eignerart character(60),
    primary key (b)
);
CREATE INDEX eign_shl_idx0 ON eign_shl(b);

SELECT alkis_dropobject('hinw_shl');
CREATE TABLE hinw_shl (
	shl character(2) NOT NULL,
	hinw_txt character(50),
	PRIMARY KEY (shl)
);

SELECT alkis_dropobject('sonderbaurecht');
CREATE TABLE sonderbaurecht (
	bestdnr character(16),
	pk character(8) NOT NULL,
	lnr character(2),
	text varchar,
	ff_entst integer,
	ff_stand integer,
	PRIMARY KEY (pk)
);

CREATE INDEX sonderbaurecht_idx1 ON sonderbaurecht(bestdnr);

SELECT alkis_dropobject('klas_3x');
CREATE TABLE klas_3x (
	flsnr character(21),
	pk character(8) NOT NULL,
	klf character(32),
	fl character(16),
	gemfl double precision,
	klz character(10),
	wertz1 character(10),
	wertz2 character(10),
	bem character(5),
	unf_anm character(20),
	ff_entst integer,
	ff_stand integer,
	primary key (pk)
);
CREATE INDEX klas_3x_idx1 ON klas_3x(flsnr);
CREATE INDEX klas_3x_idx2 ON klas_3x(klf);


SELECT alkis_dropobject('kls_shl');
CREATE TABLE kls_shl (
	klf character(32) NOT NULL,
	klf_text character(200),
	primary key (klf)
);

SELECT alkis_dropobject('bem_fls');
CREATE TABLE bem_fls (
	flsnr character(21) NOT NULL,
	lnr character(2) NOT NULL,
	text character(52),
	ff_entst INTEGER NOT NULL ,
	ff_stand INTEGER,
	primary key (flsnr, lnr)
);
CREATE INDEX bem_fls_idx1 ON bem_fls(flsnr);

SELECT alkis_dropobject('erbbaurecht');
CREATE TABLE erbbaurecht(
	bestdnr character(16),
	pk character(8) NOT NULL,
	lnr character(2),
	text character(59),
	ff_entst integer,
	ff_stand integer,
	PRIMARY KEY (pk)
);
CREATE INDEX erbbaurecht_idx1 ON erbbaurecht(bestdnr);

SELECT alkis_dropobject('nutz_21');
CREATE TABLE nutz_21 (
	flsnr varchar,
	pk character(8) NOT NULL,
	nutzsl character(32),
	fl character(16),
	gemfl double precision,
	ff_entst INTEGER,
	ff_stand INTEGER,
	primary key (pk)
);
CREATE INDEX nutz_21_idx1 ON nutz_21(flsnr);
CREATE INDEX nutz_21_idx2 ON nutz_21(nutzsl);

SELECT alkis_dropobject('nutz_shl');
CREATE TABLE nutz_shl (
	nutzshl character(32) NOT NULL,
	nutzung character(200),
	primary key (nutzshl)
);
CREATE INDEX nutz_shl_idx0 ON nutz_shl(nutzshl);

SELECT alkis_dropobject('verf_shl');
CREATE TABLE verf_shl (
	verfshl character(2) NOT NULL,
	verf_txt character(50),
	PRIMARY KEY (verfshl)
);
CREATE INDEX verf_shl_idx0 ON verf_shl(verfshl);

SELECT alkis_dropobject('vor_flst');
CREATE TABLE vor_flst(
	flsnr varchar,
	pk character(8) NOT NULL,
	v_flsnr varchar,
	ff_entst integer,
	ff_stand integer,
	PRIMARY KEY (pk)
);
CREATE INDEX vor_flst_idx1 ON vor_flst(flsnr);
CREATE INDEX vor_flst_idx2 ON vor_flst(v_flsnr);

SELECT alkis_dropobject('best_lkfs');
CREATE TABLE best_lkfs (
	bestdnr character(16) NOT NULL,
	lkfs character(4) NOT NULL,
	PRIMARY KEY (bestdnr,lkfs)
);
CREATE INDEX best_lkfs_idx0 ON best_lkfs(bestdnr);

SELECT alkis_dropobject('flurst_lkfs');
CREATE TABLE flurst_lkfs (
	flsnr varchar NOT NULL,
	lkfs character(4) NOT NULL,
	PRIMARY KEY (flsnr,lkfs)
);
CREATE INDEX flurst_lkfs_idx0 ON flurst_lkfs(flsnr);

SELECT alkis_dropobject('fortf');
CREATE TABLE fortf (
	ffnr integer NOT NULL,
	auftragsnr character(9),
	lkfs character(4),
	antragsnr character(10),
	daa character(2),
	datum character(10),
	beschreibung character(250),
	anford character(250),
	datei character(250),
	PRIMARY KEY (ffnr)
);

SELECT alkis_dropobject('fina');
CREATE TABLE fina(
	fina_nr character(6) NOT NULL,
	fina_name character(200),
	PRIMARY KEY (fina_nr)
);
CREATE INDEX fina_idx0 ON fina(fina_nr);

SELECT alkis_dropobject('fs');
CREATE TABLE fs(
	fs_key integer,
	fs_obj varchar,
	alb_key varchar
);

CREATE INDEX fs_obj ON fs(fs_obj);
CREATE INDEX fs_alb ON fs(alb_key);

SELECT alkis_dropobject('ausfst');
CREATE TABLE ausfst (
	flsnr varchar,
	pk character(8) NOT NULL,
	ausf_st varchar,
	verfnr character(6),
	verfshl character(2),
	ff_entst integer,
	ff_stand integer,
	primary key (pk)
);
CREATE INDEX ausfst_idx1 ON ausfst(flsnr);
CREATE INDEX ausfst_idx2 ON ausfst(ausf_st);

SELECT alkis_dropobject('afst_shl');
CREATE TABLE afst_shl (
	ausf_st varchar NOT NULL,
	afst_txt character(200),
	PRIMARY KEY (ausf_st)
);

CREATE INDEX afst_shl_idx0 ON afst_shl(ausf_st);

--
-- Sicht für Flurstückseigentümer (inkl. ggf. mehrzeiliger Flurstücksadresse und mehrzeiliger Eigentümer)
--

CREATE VIEW v_eigentuemer AS
  SELECT
    f.ogc_fid,f.gml_id,f.wkb_geometry
    ,fs.flsnr
    ,fs.amtlflsfl
    ,(SELECT gemarkung FROM gema_shl WHERE gema_shl.gemashl=fs.gemashl) AS gemarkung
    ,(SELECT array_to_string( array_agg( DISTINCT str_shl.strname || coalesce(' '||strassen.hausnr,'') ) || CASE WHEN lagebez IS NULL THEN ARRAY[lagebez] ELSE '{}'::text[] END, E'\n')
      FROM strassen
      LEFT OUTER JOIN str_shl ON strassen.strshl=str_shl.strshl
      WHERE strassen.flsnr=fs.flsnr AND strassen.ff_stand=0
     ) AS adressen
    ,(SELECT array_to_string( array_agg( DISTINCT ea.bestdnr ), E'\n')
      FROM eignerart ea
      WHERE ea.flsnr=fs.flsnr AND ea.ff_stand=0
     ) AS bestaende
    ,(SELECT array_to_string( array_agg( DISTINCT e.name1 || coalesce(', ' || e.name2, '') || coalesce(', ' || e.name3, '') || coalesce(', ' || e.name4, '') ), E'\n')
      FROM eignerart ea
      JOIN eigner e ON ea.bestdnr=e.bestdnr AND e.ff_stand=0
      WHERE ea.flsnr=fs.flsnr AND ea.ff_stand=0
     ) AS eigentuemer
  FROM ax_flurstueck f
  JOIN flurst fs ON fs.ff_stand=0 AND alkis_flsnr(f)=fs.flsnr
  WHERE f.endet IS NULL
  GROUP BY f.ogc_fid,f.gml_id,f.wkb_geometry,fs.flsnr,fs.gemashl,fs.lagebez,fs.amtlflsfl;

--
-- Sicht mit Gebäudepunkten inkl. Straße/Hausnummer
--

CREATE VIEW v_haeuser AS
  SELECT
    ogc_fid,
    point AS wkb_geometry,
    st_x(point) AS x_coord,
    st_y(point) AS y_coord,
    strshl,
    ha_nr
  FROM (
    SELECT
      g.ogc_fid * 268435456::bigint + o.ogc_fid AS ogc_fid,
      st_centroid(g.wkb_geometry) AS point,
      to_char(alkis_toint(o.land),'fm00')||o.regierungsbezirk||to_char(alkis_toint(o.kreis),'fm00')||to_char(alkis_toint(o.gemeinde),'fm000')||'    '||trim(o.lage) AS strshl,
      hausnummer AS ha_nr
    FROM ax_lagebezeichnungmithausnummer o
    JOIN ax_gebaeude g ON ARRAY[o.gml_id] <@ g.zeigtauf AND g.endet IS NULL
    WHERE o.endet IS NULL
  ) AS foo;

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
        fk VARCHAR;
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
		     WHEN 'ax_halde'					THEN 'lagergut'
		     WHEN 'ax_bergbaubetrieb'				THEN 'abbaugut'
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

		fk := CASE r.name
		     WHEN 'ax_halde'					THEN ', '
		     WHEN 'ax_bergbaubetrieb'				THEN ' von '
		     WHEN 'ax_heide'					THEN ''
		     WHEN 'ax_moor'					THEN ''
		     WHEN 'ax_sumpf'					THEN ''
		     WHEN 'ax_wohnbauflaeche'				THEN ' mit Art der Bebauung '
		     WHEN 'ax_industrieundgewerbeflaeche'		THEN ', '
		     WHEN 'ax_tagebaugrubesteinbruch'			THEN ' von '
		     WHEN 'ax_flaechegemischternutzung'			THEN ', '
		     WHEN 'ax_flaechebesondererfunktionalerpraegung'	THEN ', '
		     WHEN 'ax_sportfreizeitunderholungsflaeche'		THEN ', '
		     WHEN 'ax_friedhof'					THEN ', '
		     WHEN 'ax_strassenverkehr'				THEN ', '
		     WHEN 'ax_weg'					THEN ', '
		     WHEN 'ax_platz'					THEN ', '
		     WHEN 'ax_bahnverkehr'				THEN ', '
		     WHEN 'ax_flugverkehr'				THEN ', '
		     WHEN 'ax_schiffsverkehr'				THEN ', '
		     WHEN 'ax_gehoelz'					THEN ', '
		     WHEN 'ax_unlandvegetationsloseflaeche'		THEN ', '
		     WHEN 'ax_fliessgewaesser'				THEN ', '
		     WHEN 'ax_hafenbecken'				THEN ', '
		     WHEN 'ax_stehendesgewaesser'			THEN ', '
		     WHEN 'ax_meer'					THEN ', '
		     WHEN 'ax_landwirtschaft'				THEN ', '
		     WHEN 'ax_wald'					THEN ', '
		     ELSE NULL
		     END;
		IF fk IS NULL THEN
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
		     WHEN 'ax_flaechebesondererfunktionalerpraegung'	THEN 'Fläche besonderer funktionaler Prägung'
		     WHEN 'ax_sportfreizeitunderholungsflaeche'		THEN 'Sport-, Freizeit- und Erholungsfläche'
		     WHEN 'ax_friedhof'					THEN 'Friedhof'
		     WHEN 'ax_strassenverkehr'				THEN 'Straßenverkehr'
		     WHEN 'ax_weg'					THEN 'Weg'
		     WHEN 'ax_platz'					THEN 'Platz'
		     WHEN 'ax_bahnverkehr'				THEN 'Bahnverkehr'
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
		   || alkis_toint(r.kennung) || ' AS kennung,'
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
			   || ' UNION SELECT ''' || r.kennung || ':''||k AS nutzung,'''
			   || coalesce(n,'') || coalesce(fk,'') || '''|| v AS name'
			   || ' FROM alkis_wertearten WHERE element=''' || r.name || ''' AND bezeichnung=''' || f || ''''
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
		   || alkis_toint(r.kennung) || ' AS kennung,'
		   || p || ' AS artderfestlegung,'
		   || CASE WHEN r.name='ax_bodenschaetzung'
		      THEN 'bodenzahlodergruenlandgrundzahl AS bodenzahl,ackerzahlodergruenlandzahl AS ackerzahl,'
		      ELSE 'NULL::varchar AS bodenzahl,NULL::varchar AS ackerzahl,'
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
		WHERE false;

	CREATE INDEX v_schutzgebietnachwasserrechtgeom_idx ON v_schutzgebietnachwasserrecht USING GIST(wkb_geometry);

	PERFORM alkis_dropobject('v_schutzgebietnachnaturumweltoderbodenschutzrecht');
	CREATE TABLE v_schutzgebietnachnaturumweltoderbodenschutzrecht AS
		SELECT z.ogc_fid,z.gml_id,'ax_schutzzone'::varchar AS name,s.land,s.stelle,z.wkb_geometry,NULL::text AS endet
		FROM ax_schutzgebietnachnaturumweltoderbodenschutzrecht s
		JOIN ax_schutzzone z ON z.istteilvon=s.gml_id AND z.endet IS NULL
		WHERE false;

	CREATE INDEX v_schutzgebietnachnaturumweltoderbodenschutzrecht_geom_idx ON v_schutzgebietnachnaturumweltoderbodenschutzrecht USING GIST(wkb_geometry);

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
		  || 'to_char(alkis_toint(land),''fm00'') || stelle AS ausfuehrendestelle,'
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
