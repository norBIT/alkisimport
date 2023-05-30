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

SELECT alkis_dropobject('alb_version');
CREATE TABLE alb_version(version integer);
INSERT INTO alb_version(version) VALUES (4);

-- Sichten löschen, die von alkis_toint abhängen
SELECT alkis_dropobject('ax_tatsaechlichenutzung');
SELECT alkis_dropobject('ax_klassifizierung');
SELECT alkis_dropobject('ax_ausfuehrendestellen');

SELECT alkis_dropobject('v_eigentuemer');
SELECT alkis_dropobject('v_haeuser');

\i nas2alb-functions.sql

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
	oid SERIAL,
	primary key (flsnr)
) WITHOUT OIDS;
COMMENT ON TABLE flurst IS 'BASE: Flurstücke';

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
COMMENT ON TABLE str_shl IS 'BASE: Straßenschlüssel';

CREATE INDEX str_shl_idx0 ON str_shl(strshl);
CREATE INDEX str_shl_idx1 ON str_shl(gemshl);

SELECT alkis_dropobject('strassen');
CREATE TABLE strassen (
	flsnr character(21),
	pk character(8) NOT NULL,
	strshl character(32),
	hausnr varchar,
	ff_entst integer,
	ff_stand integer,
	primary key (pk)
);
COMMENT ON TABLE strassen IS 'BASE: Straßenzuordnungen';

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
COMMENT ON TABLE gem_shl IS 'BASE: Gemeindeschlüssel';


CREATE INDEX gem_shl_idx0 ON gem_shl(gemshl);

SELECT alkis_dropobject('gema_shl');
CREATE TABLE gema_shl (
	gemashl character(6) NOT NULL,
	gemarkung character(50),
	gemshl character(30),
	ag_shl character(4),
	primary key (gemashl)
);
COMMENT ON TABLE gema_shl IS 'BASE: Gemarkungsschlüssel';

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
COMMENT ON TABLE eignerart IS 'BASE: Eigentümerarten';

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
COMMENT ON TABLE bem_best IS 'BASE: Bestandsbemerkung';

CREATE INDEX bem_best_idx1 ON bem_best(bestdnr);

SELECT alkis_dropobject('bestand');
CREATE TABLE bestand (
	bestdnr character(16) NOT NULL,
	gbbz character(4),
	gbblnr varchar,
	anteil character(24),
	auftlnr character(12),
	bestfl varchar,
	amtlbestfl double precision,
	ff_entst integer NOT NULL,
	ff_stand integer,
	pz character(1),
	PRIMARY KEY (bestdnr)
);
COMMENT ON TABLE bestand IS 'BASE: Bestände';

CREATE INDEX bestand_bestdnr ON bestand(bestdnr);
CREATE INDEX bestand_ff_entst ON bestand(ff_entst);
CREATE INDEX bestand_ff_stand ON bestand(ff_stand);

SELECT alkis_dropobject('eigner');
CREATE TABLE eigner (
	bestdnr character(16),
	pk character(8) NOT NULL,
	ab character(4),
	namensnr varchar,
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
COMMENT ON TABLE eigner IS 'BASE: Eigentümer';

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
COMMENT ON TABLE eign_shl IS 'BASE: Eigentumsarten';

CREATE INDEX eign_shl_idx0 ON eign_shl(b);

SELECT alkis_dropobject('hinw_shl');
CREATE TABLE hinw_shl (
	shl character(2) NOT NULL,
	hinw_txt character(50),
	PRIMARY KEY (shl)
);
COMMENT ON TABLE hinw_shl IS 'BASE: Hinweise';

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
COMMENT ON TABLE sonderbaurecht IS 'BASE: Sonderbaurecht';

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
COMMENT ON TABLE klas_3x IS 'BASE: Klassifizierungen';

CREATE INDEX klas_3x_idx1 ON klas_3x(flsnr);
CREATE INDEX klas_3x_idx2 ON klas_3x(klf);


SELECT alkis_dropobject('kls_shl');
CREATE TABLE kls_shl (
	klf character(32) NOT NULL,
	klf_text character(200),
	primary key (klf)
);
COMMENT ON TABLE kls_shl IS 'BASE: Klassifiziersschlüssel';

SELECT alkis_dropobject('bem_fls');
CREATE TABLE bem_fls (
	flsnr character(21) NOT NULL,
	lnr character(2) NOT NULL,
	text character(52),
	ff_entst INTEGER NOT NULL ,
	ff_stand INTEGER,
	primary key (flsnr, lnr)
);
COMMENT ON TABLE bem_fls IS 'BASE: Flurstücksbemerkungen';

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
COMMENT ON TABLE erbbaurecht IS 'BASE: Erbbaurecht';

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
COMMENT ON TABLE nutz_21 IS 'BASE: Nutzungen';

CREATE INDEX nutz_21_idx1 ON nutz_21(flsnr);
CREATE INDEX nutz_21_idx2 ON nutz_21(nutzsl);

SELECT alkis_dropobject('nutz_shl');
CREATE TABLE nutz_shl (
	nutzshl character(32) NOT NULL,
	nutzung character(200),
	primary key (nutzshl)
);
COMMENT ON TABLE nutz_shl IS 'BASE: Nutzungsschlüssel';

CREATE INDEX nutz_shl_idx0 ON nutz_shl(nutzshl);

SELECT alkis_dropobject('verf_shl');
CREATE TABLE verf_shl (
	verfshl character(2) NOT NULL,
	verf_txt character(50),
	PRIMARY KEY (verfshl)
);
COMMENT ON TABLE verf_shl IS 'BASE: Verfahrensschlüssel';

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
COMMENT ON TABLE vor_flst IS 'BASE: Vorgängerflurstücke';

CREATE INDEX vor_flst_idx1 ON vor_flst(flsnr);
CREATE INDEX vor_flst_idx2 ON vor_flst(v_flsnr);

SELECT alkis_dropobject('best_lkfs');
CREATE TABLE best_lkfs (
	bestdnr character(16) NOT NULL,
	lkfs character(4) NOT NULL,
	PRIMARY KEY (bestdnr,lkfs)
);
COMMENT ON TABLE best_lkfs IS 'BASE: Bestandsführende Stelle';

CREATE INDEX best_lkfs_idx0 ON best_lkfs(bestdnr);

SELECT alkis_dropobject('flurst_lkfs');
CREATE TABLE flurst_lkfs (
	flsnr varchar NOT NULL,
	lkfs character(4) NOT NULL,
	PRIMARY KEY (flsnr,lkfs)
);
COMMENT ON TABLE flurst_lkfs IS 'BASE: Flurstücksführende Stelle';

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
COMMENT ON TABLE fortf IS 'BASE: Fortführungen';

SELECT alkis_dropobject('fina');
CREATE TABLE fina(
	fina_nr character(6) NOT NULL,
	fina_name character(200),
	PRIMARY KEY (fina_nr)
);
COMMENT ON TABLE fina IS 'BASE: Finanzämter';

CREATE INDEX fina_idx0 ON fina(fina_nr);

SELECT alkis_dropobject('fs');
CREATE TABLE fs(
	fs_key integer,
	fs_obj varchar,
	alb_key varchar
);
COMMENT ON TABLE fs IS 'BASE: Flurstücksverknüpfungen';

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
COMMENT ON TABLE ausfst IS 'BASE: Ausführende Stellen';
CREATE INDEX ausfst_idx1 ON ausfst(flsnr);
CREATE INDEX ausfst_idx2 ON ausfst(ausf_st);

SELECT alkis_dropobject('afst_shl');
CREATE TABLE afst_shl (
	ausf_st varchar NOT NULL,
	afst_txt character(200),
	PRIMARY KEY (ausf_st)
);
COMMENT ON TABLE afst_shl IS 'BASE: Schlüssel ausführender Stellen';

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
    ,(SELECT array_to_string( array_agg( DISTINCT str_shl.strname || coalesce(' '||strassen.hausnr,'') ) || CASE WHEN lagebez IS NOT NULL THEN ARRAY[lagebez] ELSE '{}'::text[] END, E'\n')
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
    strname,
    ha_nr,
    gemshl,
    gemname
  FROM (
    SELECT
      g.ogc_fid * 268435456::bigint + o.ogc_fid AS ogc_fid,
      st_centroid(g.wkb_geometry) AS point,
      to_char(alkis_toint(o.land),'fm00')||o.regierungsbezirk||to_char(alkis_toint(o.kreis),'fm00')||to_char(alkis_toint(o.gemeinde),'fm000')||'    '||trim(o.lage) AS strshl,
      hausnummer AS ha_nr
    FROM ax_lagebezeichnungmithausnummer o
    JOIN ax_gebaeude g ON ARRAY[o.gml_id] <@ g.zeigtauf AND g.endet IS NULL
    WHERE o.endet IS NULL
  ) AS foo
  LEFT OUTER JOIN str_shl USING (strshl)
  LEFT OUTER JOIN gem_shl USING (gemshl)
;
