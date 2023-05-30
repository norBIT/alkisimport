/***************************************************************************
 *                                                                         *
 * Project:  norGIS ALKIS Import                                           *
 * Purpose:  Regeln zur Ableitung von Darstellungstabellen aus den         *
 *           GDAL/OGR NAS Tabellen                                         *
 * Author:   Jürgen E. Fischer jef@norbit.de                               *
 *                                                                         *
 ***************************************************************************
 * Copyright (c) 2013-2023 Jürgen E. Fischer (jef@norbit.de)               *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/

-- %s/ARRAY\[\([^]]*\)\] <@ \([^ ;]*\)/\1 = ANY(\2)/
-- \timing
-- \set ECHO queries

--
-- Variablen:
-- alkis_epsg		Koordinatensystem
-- alkis_fnbruch	Bruchstrichdarstellung für Flurstücksnummern voreinstellen
-- alkis_pgverdraengen	Niederwertige zu höherwertige politischen Grenzen NICHT erzeugen
-- alkis_modelle	Zu verwendende Modelle
--

/*
	1XXX = Fläche
	2XXX = Linie
	3XXX = Symbol
	4XXX = Schrift

Linien-Signaturen mit Konturen:
	2504
		51004 ax_transportanlage
			Förderband, unterirdisch (BWF 1102, OFL 1200/1700)

	2510
		51007 ax_historischesbauwerkoderhistorischeeinrichtung
			Historische Mauer (ATP 1500/1520)
			Stadtmauer (ATP 1510)

		51009 ax_sonstigesbauwerkodersonstigeeinrichtung
			Mauerkante, rechts (BWF 1710/1721)
			Mauerkante, links (BWF 1702/1722)
			Mauermitte (BWF 1703/1723)

		53009 ax_bauwerkimgewaesserbereich
			Ufermauer (BWF 2136)

	2521
		51004 ax_transportanlage
			Förderband (BWF 1102, OFL -/1400)

		51010 ax_einrichtunginoeffentlichenbereichen
			Tor (ART 1510)

	2526
		53009 ax_bauwerkimgewaesserbereich
			Sicherheitstor (BWF 2060)

Links/Rechts:
	51009 ax_sonstigesbauwerkodersonstigeeinrichtung	Mauerkante, -mitte
	54001 ax_vegetationsmerkmal				Heckenkante, -mitte
	55002 ax_untergeordnetesgewaesser			Grabenkante, -nmitte
	61003 ax_dammwalldeich					Wall-, Knick kante

Länder:
BB	Brandenburg			12
BE	Berlin				11
BW	Baden-Württemberg		08
BY	Bayern				09
HB	Bremen				04
HE	Hessen				06
HH	Hamburg				02
MV	Mecklenburg-Vorpommern		13
NI	Niedersachsen			03
NW	Nordrhein-Westfalen		05
RP	Rheinland-Pfalz			07
SH	Schleswig-Holstein		01
SL	Saarland			10
SN	Sachsen				14
ST	Sachsen-Anhalt			15
TH	Thüringen			16
*/

SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

\unset ON_ERROR_STOP
SET application_name='ALKIS-Import - Ableitungsregeln';
SET client_min_messages TO notice;
\set ON_ERROR_STOP

SELECT 'Koordinatensystem: ' || :alkis_epsg;
SELECT 'Bruchstrichvoreinstellung: ' || CASE WHEN :alkis_fnbruch THEN 'Bruchstrich' ELSE 'Schrägstrich' END;
SELECT 'Niederwertige politische Grenzen verdrängen: ' || CASE WHEN :alkis_pgverdraengen THEN 'Ja' ELSE 'Nein' END;
-- SELECT 'Aktive Modelle: ' || array_to_string(:alkis_modelle,', ');

SELECT alkis_dropobject('alkis_positionierungsregeln');
CREATE TABLE alkis_positionierungsregeln(
	id INTEGER PRIMARY KEY,
	abstand DOUBLE PRECISION,
	zeilenabstand DOUBLE PRECISION,
	versatz DOUBLE PRECISION,
	dichte INTEGER);

INSERT INTO alkis_positionierungsregeln(id,abstand,zeilenabstand,versatz,dichte) VALUES (1100,7,3.5,3.5,100);
INSERT INTO alkis_positionierungsregeln(id,abstand,zeilenabstand,versatz,dichte) VALUES (1101,7,3.5,3.5,20);
INSERT INTO alkis_positionierungsregeln(id,abstand,zeilenabstand,versatz,dichte) VALUES (1102,18,10,9,100);
INSERT INTO alkis_positionierungsregeln(id,abstand,zeilenabstand,versatz,dichte) VALUES (1103,18,10,9,20);
INSERT INTO alkis_positionierungsregeln(id,abstand,zeilenabstand,versatz,dichte) VALUES (1104,24,22,12,100);
INSERT INTO alkis_positionierungsregeln(id,abstand,zeilenabstand,versatz,dichte) VALUES (1105,24,22,12,20);
INSERT INTO alkis_positionierungsregeln(id,abstand,zeilenabstand,versatz,dichte) VALUES (1106,10,3,5,100);
INSERT INTO alkis_positionierungsregeln(id,abstand,zeilenabstand,versatz,dichte) VALUES (1107,10,3,5,20);
INSERT INTO alkis_positionierungsregeln(id,abstand,zeilenabstand,versatz,dichte) VALUES (1108,8,7,4,100);
INSERT INTO alkis_positionierungsregeln(id,abstand,zeilenabstand,versatz,dichte) VALUES (1109,8,7,4,20);
INSERT INTO alkis_positionierungsregeln(id,abstand,zeilenabstand,versatz,dichte) VALUES (1110,7,6,3.5,100);
INSERT INTO alkis_positionierungsregeln(id,abstand,zeilenabstand,versatz,dichte) VALUES (1111,7,6,3.5,20);
INSERT INTO alkis_positionierungsregeln(id,abstand,zeilenabstand,versatz,dichte) VALUES (1112,3,1.5,1.5,100);

SELECT alkis_dropobject('alkis_flaechenfuellung');
CREATE OR REPLACE FUNCTION alkis_flaechenfuellung(g0 GEOMETRY, regelid varchar) RETURNS GEOMETRY AS $$
DECLARE
	xmin DOUBLE PRECISION;
	ymin DOUBLE PRECISION;
	xmax DOUBLE PRECISION;
	ymax DOUBLE PRECISION;
	x0 DOUBLE PRECISION;
	x DOUBLE PRECISION;
	y DOUBLE PRECISION;
	r GEOMETRY[];
	p GEOMETRY;
	srid INTEGER;
	g GEOMETRY;
	regel RECORD;
BEGIN
	IF regelid IS NULL OR geometrytype(g)<>'POLYGON' THEN
		RETURN NULL;
	END IF;

	SELECT * INTO regel FROM alkis_positionierungsregeln WHERE id=regelid::int;

	g := st_buffer(g0, -0.5);
	xmin := floor(st_xmin(g)/regel.abstand)*regel.abstand;
	ymin := floor(st_ymin(g)/regel.zeilenabstand)*regel.zeilenabstand;
	xmax := ceil(st_xmax(g)/regel.abstand)*regel.abstand;
	ymax := ceil(st_ymax(g)/regel.zeilenabstand)*regel.zeilenabstand;

	SELECT st_srid(g) INTO srid;

	x0 := xmin;
	y  := ymin;

--	RAISE NOTICE 'w:% h:% cols:% rows:% n:%',
--		xmax-xmin, ymax-ymin,
--		(xmax-xmin)/abstand,
--		(ymax-ymin)/zeilenabstand,
--		((xmax-xmin)/abstand) * ((ymax-ymin)/zeilenabstand);

	FOR i IN 0..1 LOOP
		WHILE y<ymax LOOP
			x := x0;
			WHILE x<xmax LOOP
				p := st_setsrid(st_point( x, y ), srid );
				IF st_intersects( g, p ) THEN
					r := array_append( r, p );
				END IF;
				x := x + regel.abstand;
			END LOOP;
			y := y + 2*regel.zeilenabstand;
		END LOOP;

		y  := ymin + regel.zeilenabstand;
		x0 := x0 + regel.versatz;
	END LOOP;

	IF regel.dichte<100 THEN
		SELECT st_collect(geom) INTO g
		FROM (
			SELECT random() AS rand,geom
			FROM unnest(r) AS geom
			ORDER BY rand
		) AS a WHERE rand*100<=regel.dichte;
	ELSE
		g := st_collect(r);
	END IF;

	RETURN st_multi(g);
END;
$$ LANGUAGE plpgsql IMMUTABLE;


SELECT alkis_dropobject('alkis_safe_offsetcurve');
CREATE OR REPLACE FUNCTION alkis_safe_offsetcurve(g0 geometry,offs float8,params text) RETURNS geometry AS $$
DECLARE
	res GEOMETRY;
	r VARCHAR;
BEGIN
	r := '';

	IF g0 IS NULL OR offs=0 THEN
		RETURN g0;
	END IF;

	BEGIN
		SELECT st_offsetcurve(g0,offs,params) INTO res;
		IF geometrytype(res)='LINESTRING' THEN
			RETURN res;
		END IF;
		r := alkis_string_append(r, 'st_offsetcurve returned ' || geometrytype(res));
	EXCEPTION WHEN OTHERS THEN
		r := alkis_string_append(r, 'st_offsetcurve failed: ' || SQLERRM);
	END;

	BEGIN
		SELECT alkis_offsetcurve(g0,offs,params) INTO res;
		IF geometrytype(res)='LINESTRING' THEN
			RETURN res;
		END IF;
		r := alkis_string_append(r, 'alkis_offsetcurve returned ' || geometrytype(res));
	EXCEPTION WHEN OTHERS THEN
		r := alkis_string_append(r, 'alkis_offsetcurve failed: ' || SQLERRM);
	END;

	RAISE NOTICE '%', alkis_string_append(r, 'alkis_safe_offsetcurve ' || st_astext(g0) || ' by ' || offs || ' with ''' || params || ''' failed');

	RETURN g0;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

SELECT alkis_dropobject('alkis_pnr3002');
CREATE OR REPLACE FUNCTION alkis_pnr3002(
	p_gmlid varchar,
	p_p GEOMETRY,
	p_a double precision,
	p_land varchar,
	p_regierungsbezirk varchar,
	p_kreis varchar,
	p_gemeinde varchar,
	p_lage varchar,
	p_g GEOMETRY,
	OUT p GEOMETRY,
	OUT a DOUBLE PRECISION
) AS $$
DECLARE
	f GEOMETRY;
	g GEOMETRY;
	b double precision;
BEGIN
	IF p_p IS NOT NULL THEN
		p := p_p;
		a := p_a;
		RETURN;
	END IF;

	g := st_multi(st_buffer(p_g,-1.9));
	IF geometrytype(g)<>'MULTIPOLYGON' OR st_numgeometries(g)=0 THEN
		-- RAISE NOTICE '%: buffered %', p_gmlid, st_astext(g);
		RETURN;
	END IF;

	SELECT st_multi(st_union(st_exteriorring(geom))) FROM st_dump(g) INTO g;
	IF geometrytype(g)<>'MULTILINESTRING' THEN
		RAISE NOTICE '%: exterior %', p_gmlid, st_astext(g);
		RETURN;
	END IF;

	-- Nächstes Flurstückspolygon bestimmen
	SELECT
		fs.geom
	INTO f
	FROM (
		SELECT
			(st_dump(st_multi(ax_flurstueck.wkb_geometry))).geom
		FROM ax_flurstueck
		JOIN ax_lagebezeichnungohnehausnummer loh ON ARRAY[loh.gml_id] <@ ax_flurstueck.zeigtAuf
		WHERE loh.land=p_land AND loh.regierungsbezirk=p_regierungsbezirk AND loh.kreis=p_kreis AND loh.gemeinde=p_gemeinde AND loh.lage=p_lage
		  AND loh.unverschluesselt IS NULL
	) AS fs
	ORDER BY st_distance(fs.geom,g) ASC
	LIMIT 1;

	IF f IS NULL THEN
		-- RAISE NOTICE '%: empty fs geom', p_gmlid;
		RETURN;
	END IF;

	-- Nächste Kante des Eingabepolygons bestimmen
	SELECT
		geom
	INTO
		g
	FROM (
		SELECT
			st_makeline(st_pointn(geom,i), st_pointn(geom,i+1)) AS geom
		FROM (
			SELECT
				generate_series(1,st_npoints(geom)-1) AS i,
				geom
			FROM st_dump(g)
		) AS indexes
	) AS segments
	WHERE st_length(geom)>1.5
	ORDER BY st_distance(f,st_lineinterpolatepoint(geom,0.5)) ASC,st_length(geom) DESC
	LIMIT 1;

	IF g IS NULL THEN
		-- RAISE NOTICE '%: empty edge', p_gmlid;
		RETURN;
	END IF;

	-- Mitte/Winkel an der nächsten Kante
	p := st_lineinterpolatepoint(g, 0.5);
	b := 0.5*pi()-st_azimuth(st_startpoint(g), st_endpoint(g));
	WHILE b < 0 LOOP
		b := b + 2*pi();
	END LOOP;
	WHILE b > 2*pi() LOOP
		b := b - 2*pi();
	END LOOP;

	IF b BETWEEN 0.5*pi() AND pi() THEN
		b := b + pi();
	ELSIF b BETWEEN pi() AND 1.5*pi() THEN
		b := b - pi();
	END IF;

	IF b IS NULL THEN
		RAISE EXCEPTION E'%: p:% a:%\n\ng:%\nf:%', p_gmlid, st_astext(p), b, st_astext(g), st_astext(f);
	END IF;

	a := b;
END;
$$ LANGUAGE plpgsql;


-- Präsentationsobjekte?

-- BEGIN;

SELECT 'Präsentationstabellen werden geleert.';
DELETE FROM po_points;
DELETE FROM po_lines;
DELETE FROM po_polygons;
DELETE FROM po_labels;

-- Nichtdarzustellende Signaturnummer ergänzen
-- (um sie am Ende inkl. der betreffenden Signaturen wieder zu entfernen)
DELETE FROM alkis_linie WHERE signaturnummer IN ('6000','RP6000');
DELETE FROM alkis_linien WHERE signaturnummer IN ('6000','RP6000');
DELETE FROM alkis_flaechen WHERE signaturnummer IN ('6000','RP6000');
DELETE FROM alkis_schriften WHERE signaturnummer IN ('6000','RP6000');

INSERT INTO alkis_linien(katalog,signaturnummer) VALUES (1,'6000');
INSERT INTO alkis_flaechen(katalog,signaturnummer) VALUES (1,'6000');
INSERT INTO alkis_schriften(katalog,signaturnummer) VALUES (1,'6000');
INSERT INTO alkis_linien(katalog,signaturnummer) VALUES (1,'RP6000');
INSERT INTO alkis_flaechen(katalog,signaturnummer) VALUES (1,'RP6000');
INSERT INTO alkis_schriften(katalog,signaturnummer) VALUES (1,'RP6000');

INSERT INTO alkis_linien(katalog,signaturnummer) VALUES (2,'6000');
INSERT INTO alkis_flaechen(katalog,signaturnummer) VALUES (2,'6000');
INSERT INTO alkis_schriften(katalog,signaturnummer) VALUES (2,'6000');
INSERT INTO alkis_linien(katalog,signaturnummer) VALUES (2,'RP6000');
INSERT INTO alkis_flaechen(katalog,signaturnummer) VALUES (2,'RP6000');
INSERT INTO alkis_schriften(katalog,signaturnummer) VALUES (2,'RP6000');

-- Leere Signaturnummern ersetzen
UPDATE ap_ppo SET signaturnummer=NULL WHERE signaturnummer='';
UPDATE ap_lpo SET signaturnummer=NULL WHERE signaturnummer='';
UPDATE ap_pto SET signaturnummer=NULL WHERE signaturnummer='';
UPDATE ap_lto SET signaturnummer=NULL WHERE signaturnummer='';
UPDATE ap_pto SET art='Strasse' WHERE art='Straße';  -- Straße wird z.B. in TH verwendet

-- Leere Geschosszahlen korrigieren (sonst to_char(0,'RN') => '###############')
UPDATE ax_gebaeude SET anzahlderoberirdischengeschosse=NULL WHERE anzahlderoberirdischengeschosse=0;
UPDATE ax_gebaeude SET anzahlderunterirdischengeschosse=NULL WHERE anzahlderunterirdischengeschosse=0;

ANALYZE ax_flurstueck;
ANALYZE ax_gebaeude;
ANALYZE ax_turm;

ANALYZE ap_ppo;
ANALYZE ap_lpo;
ANALYZE ap_pto;
ANALYZE ap_lto;
ANALYZE ap_darstellung;
