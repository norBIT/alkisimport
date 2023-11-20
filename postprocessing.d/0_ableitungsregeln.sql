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

BEGIN;

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

-- Präsentationsobjekte?

\if :alkis_rebuildmap
SELECT 'Karte wird zur Neuerzeugung geleert.';
DELETE FROM po_points;
DELETE FROM po_lines;
DELETE FROM po_polygons;
DELETE FROM po_labels;
DELETE FROM po_darstellung;
DELETE FROM po_ppo;
DELETE FROM po_lpo;
DELETE FROM po_fpo;
DELETE FROM po_pto;
DELETE FROM po_lto;
UPDATE po_lastrun SET lastrun='', npoints=0, nlines=0, npolygons=0, nlabels=0;
\endif

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

-- Initialwert, falls nicht gesetzt
UPDATE po_lastrun SET lastrun=(SELECT min(beginnt) FROM alkis_po_objekte) WHERE lastrun IS NULL;

SELECT 'Kartenerzeugung ab ' || lastrun FROM po_lastrun;

SELECT 'Geänderte Darstellungsobjekte werden gelöscht.';

WITH
  -- Alle neuen Objekte und alle die erst seit dem letzten Lauf nicht mehr aktuell sind
  alkis_changed AS (
    SELECT gml_id FROM po_lastrun, alkis_po_objekte WHERE beginnt>lastrun
  UNION
    SELECT gml_id FROM po_lastrun, alkis_po_objekte WHERE beginnt<=lastrun AND endet>=lastrun
  ),
  delete_points   AS (DELETE FROM po_points   a USING alkis_changed b WHERE ARRAY[b.gml_id]<@a.gml_ids RETURNING a.gml_id),
  delete_lines    AS (DELETE FROM po_lines    a USING alkis_changed b WHERE ARRAY[b.gml_id]<@a.gml_ids RETURNING a.gml_id),
  delete_polygons AS (DELETE FROM po_polygons a USING alkis_changed b WHERE ARRAY[b.gml_id]<@a.gml_ids RETURNING a.gml_id),
  delete_labels   AS (DELETE FROM po_labels   a USING alkis_changed b WHERE ARRAY[b.gml_id]<@a.gml_ids RETURNING a.gml_id)
  SELECT
    sum(n) || ' Darstellungsobjekte gelöscht.'
  FROM (      SELECT count(*) AS n FROM delete_points
    UNION ALL SELECT count(*) AS n FROM delete_lines
    UNION ALL SELECT count(*) AS n FROM delete_polygons
    UNION ALL SELECT count(*) AS n FROM delete_labels
  ) AS a;

SELECT 'Aktualisiere po_darstellung...';

-- Alle po_darstellung löschen, die zu untergegangenen ap_darstellung gehören oder
-- komplementär zum Darstellung des gleichen Objekts dienen
DELETE FROM po_darstellung a
  USING ap_darstellung b, po_lastrun
  WHERE b.beginnt<=lastrun AND b.endet>lastrun AND (a.gml_id=b.gml_id OR (a.gml_id='KOMPLEMENTÄR' AND ARRAY[a.dientzurdarstellungvon]<@b.dientzurdarstellungvon));

-- po_darstellung zu neuen ap_darstellung ergänzen
INSERT INTO po_darstellung(gml_id,beginnt,dientzurdarstellungvon,modelle,art,darstellungsprioritaet,signaturnummer)
  SELECT
     gml_id,
     beginnt,
     unnest(dientzurdarstellungvon) AS dientzurdarstellungvon,
     advstandardmodell||sonstigesmodell AS modelle,
     art,
     darstellungsprioritaet,
     signaturnummer
  FROM po_lastrun, ap_darstellung
  WHERE beginnt>lastrun AND endet IS NULL;

-- Komplementäre po_darstellung erzeugen, die dafür sorgen, dass
-- für die nicht per ap_darstellung übersteuerten Modelle eines jeden
-- Fachobjekts Kartendarstellung mit Defaults erzeugt werden
INSERT INTO po_darstellung(gml_id,beginnt,dientzurdarstellungvon,art,modelle)
  WITH
    a AS (
      SELECT unnest(advstandardmodell) AS modell FROM ap_darstellung
    UNION
      SELECT unnest(sonstigesmodell) AS modell FROM ap_darstellung
    )
  SELECT
    *
  FROM (
    SELECT
      'KOMPLEMENTÄR' AS gml_id,
      max(beginnt) AS beginnt,
      dientzurdarstellungvon,
      art,
      array_agg(a.modell) AS modelle
    FROM (
      SELECT
        dientzurdarstellungvon,
        max(beginnt) AS beginnt,
        art,
	array_agg(modell) AS modelle
      FROM (
        SELECT
          dientzurdarstellungvon,
          beginnt,
	  art,
	  unnest(modelle) AS modell
        FROM po_darstellung
      ) AS po_darstellung
      GROUP BY dientzurdarstellungvon,art
    ) AS po_darstellung
    JOIN a ON NOT a.modell=ANY(modelle)
    GROUP BY dientzurdarstellungvon, art
  ) AS a
  WHERE array_length(modelle,1)>0;

-- Für alle untergegangenen ap_darstellung für die es keine neuen po_darstellung gibt
-- ein "Trigger"-po_darstellung erzeugen, dass dafür sorgt, dass die Fachobjekte
-- mit Defaults neugezeichnet werden
INSERT INTO po_darstellung(gml_id,beginnt,dientzurdarstellungvon,art)
  WITH
    a AS (
      SELECT unnest(advstandardmodell) AS modell FROM ap_darstellung
    UNION
      SELECT unnest(sonstigesmodell) AS modell FROM ap_darstellung
    )
  SELECT
    'TRIGGER' AS gml_id,
    beginnt,
    dientzurdarstellungvon,
    art
  FROM (
    SELECT
      to_char(to_timestamp(lastrun, 'YYYY-MM-DD"T"HH24:MI:SS"Z"')+INTERVAL '1 seconds', 'YYYY-MM-DD"T"HH24:MI:SS"Z"') AS beginnt,
      unnest(dientzurdarstellungvon) AS dientzurdarstellungvon,
      art
    FROM po_lastrun, ap_darstellung
    WHERE beginnt<=lastrun AND endet>lastrun
  ) AS ap_darstellung
  WHERE NOT EXISTS (
    SELECT 1 FROM po_darstellung WHERE po_darstellung.dientzurdarstellungvon=ap_darstellung.dientzurdarstellungvon
  );

UPDATE po_darstellung SET modelle=(SELECT array_agg(modell) FROM (SELECT DISTINCT unnest(modelle) AS modell ORDER BY modell) AS foo WHERE modell IS NOT NULL);

SELECT 'Aktualisiere po_ppo...';

-- Alle po_ppo löschen, die zu untergegangenen ap_ppo gehören oder
-- komplementär zum Darstellung des gleichen Objekts dienen
DELETE FROM po_ppo a
  USING ap_ppo b, po_lastrun
  WHERE b.beginnt<=lastrun AND b.endet>lastrun AND (a.gml_id=b.gml_id OR (a.gml_id='KOMPLEMENTÄR' AND ARRAY[a.dientzurdarstellungvon]<@b.dientzurdarstellungvon));

-- po_ppo zu neuen ap_ppo ergänzen
INSERT INTO po_ppo(gml_id,beginnt,dientzurdarstellungvon,modelle,art,darstellungsprioritaet,drehwinkel,signaturnummer,wkb_geometry)
  SELECT
     gml_id,
     beginnt,
     unnest(dientzurdarstellungvon) AS dientzurdarstellungvon,
     advstandardmodell||sonstigesmodell AS modelle,
     art,
     darstellungsprioritaet,
     drehwinkel,
     signaturnummer,
     wkb_geometry
  FROM po_lastrun, ap_ppo
  WHERE beginnt>lastrun AND endet IS NULL;

-- Komplementäre po_ppo erzeugen, die dafür sorgen, dass
-- für die nicht per ap_ppo übersteuerten Modelle eines jeden
-- Fachobjekts Kartendarstellung mit Defaults erzeugt werden
INSERT INTO po_ppo(gml_id,beginnt,dientzurdarstellungvon,art,modelle)
  WITH
    a AS (
      SELECT unnest(advstandardmodell) AS modell FROM ap_ppo
    UNION
      SELECT unnest(sonstigesmodell) AS modell FROM ap_ppo
    )
  SELECT
    *
  FROM (
    SELECT
      'KOMPLEMENTÄR' AS gml_id,
      max(beginnt) AS beginnt,
      dientzurdarstellungvon,
      art,
      array_agg(a.modell) AS modelle
    FROM (
      SELECT
        dientzurdarstellungvon,
        max(beginnt) AS beginnt,
        art,
	array_agg(modell) AS modelle
      FROM (
        SELECT
          dientzurdarstellungvon,
          beginnt,
	  art,
	  unnest(modelle) AS modell
        FROM po_ppo
      ) AS po_ppo
      GROUP BY dientzurdarstellungvon,art
    ) AS po_ppo
    JOIN a ON NOT a.modell=ANY(modelle)
    GROUP BY dientzurdarstellungvon, art
  ) AS a
  WHERE array_length(modelle,1)>0;

-- Für alle untergegangenen ap_ppo für die es keine neuen po_ppo gibt
-- ein "Trigger"-po_ppo erzeugen, dass dafür sorgt, dass die Fachobjekte
-- mit Defaults neugezeichnet werden
INSERT INTO po_ppo(gml_id,beginnt,dientzurdarstellungvon,art)
  WITH
    a AS (
      SELECT unnest(advstandardmodell) AS modell FROM ap_ppo
    UNION
      SELECT unnest(sonstigesmodell) AS modell FROM ap_ppo
    )
  SELECT
    'TRIGGER' AS gml_id,
    beginnt,
    dientzurdarstellungvon,
    art
  FROM (
    SELECT
      'TRIGGER' AS gml_id,
      to_char(to_timestamp(lastrun, 'YYYY-MM-DD"T"HH24:MI:SS"Z"')+INTERVAL '1 seconds', 'YYYY-MM-DD"T"HH24:MI:SS"Z"') AS beginnt,
      unnest(dientzurdarstellungvon) AS dientzurdarstellungvon,
      art
    FROM po_lastrun, ap_ppo
    WHERE beginnt<=lastrun AND endet>lastrun
  ) AS ap_ppo
  WHERE NOT EXISTS (
    SELECT 1 FROM po_ppo WHERE po_ppo.dientzurdarstellungvon=ap_ppo.dientzurdarstellungvon
  );

UPDATE po_ppo SET modelle=(SELECT array_agg(modell) FROM (SELECT DISTINCT unnest(modelle) AS modell ORDER BY modell) AS foo WHERE modell IS NOT NULL);

SELECT 'Aktualisiere po_lpo...';

-- Alle po_lpo löschen, die zu untergegangenen ap_lpo gehören oder
-- komplementär zum Darstellung des gleichen Objekts dienen
DELETE FROM po_lpo a
  USING ap_lpo b, po_lastrun
  WHERE b.beginnt<=lastrun AND b.endet>lastrun AND (a.gml_id=b.gml_id OR (a.gml_id='KOMPLEMENTÄR' AND ARRAY[a.dientzurdarstellungvon]<@b.dientzurdarstellungvon));

-- po_lpo zu neuen ap_lpo ergänzen
INSERT INTO po_lpo(gml_id,beginnt,dientzurdarstellungvon,modelle,art,darstellungsprioritaet,signaturnummer,wkb_geometry)
  SELECT
    gml_id,
    beginnt,
    unnest(dientzurdarstellungvon) AS dientzurdarstellungvon,
    advstandardmodell||sonstigesmodell AS modelle,
    art,
    darstellungsprioritaet,
    signaturnummer,
    wkb_geometry
  FROM po_lastrun, ap_lpo
  WHERE beginnt>lastrun AND endet IS NULL;

-- Komplementäre po_lpo erzeugen, die dafür sorgen, dass
-- für die nicht per ap_lpo übersteuerten Modelle eines jeden
-- Fachobjekts Kartendarstellung mit Defaults erzeugt werden
INSERT INTO po_lpo(gml_id,beginnt,dientzurdarstellungvon,art,modelle)
  WITH
    a AS (
      SELECT unnest(advstandardmodell) AS modell FROM ap_lpo
    UNION
      SELECT unnest(sonstigesmodell) AS modell FROM ap_lpo
    )
  SELECT
    *
  FROM (
    SELECT
      'KOMPLEMENTÄR' AS gml_id,
      max(beginnt) AS beginnt,
      dientzurdarstellungvon,
      art,
      array_agg(a.modell) AS modelle
    FROM (
      SELECT
        dientzurdarstellungvon,
        max(beginnt) AS beginnt,
        art,
	array_agg(modell) AS modelle
      FROM (
        SELECT
          dientzurdarstellungvon,
          beginnt,
	  art,
	  unnest(modelle) AS modell
        FROM po_lpo
      ) AS po_lpo
      GROUP BY dientzurdarstellungvon,art
    ) AS po_lpo
    JOIN a ON NOT a.modell=ANY(modelle)
    GROUP BY dientzurdarstellungvon, art
  ) AS a
  WHERE array_length(modelle,1)>0;

-- Für alle untergegangenen ap_lpo für die es keine neuen po_lpo gibt
-- ein "Trigger"-po_lpo erzeugen, dass dafür sorgt, dass die Fachobjekte
-- mit Defaults neugezeichnet werden
INSERT INTO po_lpo(gml_id,beginnt,dientzurdarstellungvon,art)
  WITH
    a AS (
      SELECT unnest(advstandardmodell) AS modell FROM ap_lpo
    UNION
      SELECT unnest(sonstigesmodell) AS modell FROM ap_lpo
    )
  SELECT
    'TRIGGER' AS gml_id,
    beginnt,
    dientzurdarstellungvon,
    art
  FROM (
    SELECT
      to_char(to_timestamp(lastrun, 'YYYY-MM-DD"T"HH24:MI:SS"Z"')+INTERVAL '1 seconds', 'YYYY-MM-DD"T"HH24:MI:SS"Z"') AS beginnt,
      unnest(dientzurdarstellungvon) AS dientzurdarstellungvon,
      art
    FROM po_lastrun, ap_lpo
    WHERE beginnt<=lastrun AND endet>lastrun
  ) AS ap_lpo
  WHERE NOT EXISTS (
    SELECT 1 FROM po_lpo WHERE po_lpo.dientzurdarstellungvon=ap_lpo.dientzurdarstellungvon
  );

UPDATE po_lpo SET modelle=(SELECT array_agg(modell) FROM (SELECT DISTINCT unnest(modelle) AS modell ORDER BY modell) AS foo WHERE modell IS NOT NULL);

SELECT 'Aktualisiere po_fpo...';

-- Alle po_fpo löschen, die zu untergegangenen ap_fpo gehören oder
-- komplementär zum Darstellung des gleichen Objekts dienen
DELETE FROM po_fpo a
  USING ap_fpo b, po_lastrun
  WHERE b.beginnt<=lastrun AND b.endet>lastrun AND (a.gml_id=b.gml_id OR (a.gml_id='KOMPLEMENTÄR' AND ARRAY[a.dientzurdarstellungvon]<@b.dientzurdarstellungvon));

-- po_fpo zu neuen ap_fpo ergänzen
INSERT INTO po_fpo(gml_id,beginnt,dientzurdarstellungvon,modelle,art,darstellungsprioritaet,signaturnummer,wkb_geometry)
  SELECT
    gml_id,
    beginnt,
    unnest(dientzurdarstellungvon) AS dientzurdarstellungvon,
    advstandardmodell||sonstigesmodell AS modelle,
    art,
    darstellungsprioritaet,
    signaturnummer,
    wkb_geometry
  FROM po_lastrun, ap_fpo
  WHERE beginnt>lastrun AND endet IS NULL;

-- Komplementäre po_fpo erzeugen, die dafür sorgen, dass
-- für die nicht per ap_fpo übersteuerten Modelle eines jeden
-- Fachobjekts Kartendarstellung mit Defaults erzeugt werden
INSERT INTO po_fpo(gml_id,beginnt,dientzurdarstellungvon,art,modelle)
  WITH
    a AS (
      SELECT unnest(advstandardmodell) AS modell FROM ap_fpo
    UNION
      SELECT unnest(sonstigesmodell) AS modell FROM ap_fpo
    )
  SELECT
    *
  FROM (
    SELECT
      'KOMPLEMENTÄR' AS gml_id,
      max(beginnt) AS beginnt,
      dientzurdarstellungvon,
      art,
      array_agg(a.modell) AS modelle
    FROM (
      SELECT
        dientzurdarstellungvon,
        max(beginnt) AS beginnt,
        art,
	array_agg(modell) AS modelle
      FROM (
        SELECT
          dientzurdarstellungvon,
          beginnt,
	  art,
	  unnest(modelle) AS modell
        FROM po_fpo
      ) AS po_fpo
      GROUP BY dientzurdarstellungvon,art
    ) AS po_fpo
    JOIN a ON NOT a.modell=ANY(modelle)
    GROUP BY dientzurdarstellungvon, art
  ) AS a
  WHERE array_length(modelle,1)>0;

-- Für alle untergegangenen ap_fpo für die es keine neuen po_fpo gibt
-- ein "Trigger"-po_fpo erzeugen, dass dafür sorgt, dass die Fachobjekte
-- mit Defaults neugezeichnet werden
INSERT INTO po_fpo(gml_id,beginnt,dientzurdarstellungvon,art)
  WITH
    a AS (
      SELECT unnest(advstandardmodell) AS modell FROM ap_fpo
    UNION
      SELECT unnest(sonstigesmodell) AS modell FROM ap_fpo
    )
  SELECT
    'TRIGGER' AS gml_id,
    beginnt,
    dientzurdarstellungvon,
    art
  FROM (
    SELECT
      to_char(to_timestamp(lastrun, 'YYYY-MM-DD"T"HH24:MI:SS"Z"')+INTERVAL '1 seconds', 'YYYY-MM-DD"T"HH24:MI:SS"Z"') AS beginnt,
      unnest(dientzurdarstellungvon) AS dientzurdarstellungvon,
      art
    FROM po_lastrun, ap_fpo
    WHERE beginnt<=lastrun AND endet>lastrun
  ) AS ap_fpo
  WHERE NOT EXISTS (
    SELECT 1 FROM po_fpo WHERE po_fpo.dientzurdarstellungvon=ap_fpo.dientzurdarstellungvon
  );

UPDATE po_fpo SET modelle=(SELECT array_agg(modell) FROM (SELECT DISTINCT unnest(modelle) AS modell ORDER BY modell) AS foo WHERE modell IS NOT NULL);

SELECT 'Aktualisiere po_pto...';

-- Alle po_pto löschen, die zu untergegangenen ap_pto gehören oder
-- komplementär zum Darstellung des gleichen Objekts dienen
DELETE FROM po_pto a
  USING ap_pto b, po_lastrun
  WHERE b.beginnt<=lastrun AND b.endet>lastrun AND (a.gml_id=b.gml_id OR (a.gml_id='KOMPLEMENTÄR' AND ARRAY[a.dientzurdarstellungvon]<@b.dientzurdarstellungvon));

-- po_pto zu neuen ap_pto ergänzen
INSERT INTO po_pto(gml_id,beginnt,dientzurdarstellungvon,modelle,art,darstellungsprioritaet,drehwinkel,fontsperrung,horizontaleausrichtung,schriftinhalt,signaturnummer,skalierung,vertikaleausrichtung,wkb_geometry)
  SELECT
    gml_id,
    beginnt,
    unnest(dientzurdarstellungvon) AS dientzurdarstellungvon,
    advstandardmodell||sonstigesmodell AS modelle,
    art,
    darstellungsprioritaet,
    drehwinkel,
    fontsperrung,
    horizontaleausrichtung,
    schriftinhalt,
    signaturnummer,
    skalierung,
    vertikaleausrichtung,
    wkb_geometry
  FROM po_lastrun, ap_pto
  WHERE beginnt>lastrun AND endet IS NULL;

-- Komplementäre po_pto erzeugen, die dafür sorgen, dass
-- für die nicht per ap_pto übersteuerten Modelle eines jeden
-- Fachobjekts Kartendarstellung mit Defaults erzeugt werden
INSERT INTO po_pto(gml_id,beginnt,dientzurdarstellungvon,art,modelle)
  WITH
    a AS (
      SELECT unnest(advstandardmodell) AS modell FROM ap_pto
    UNION
      SELECT unnest(sonstigesmodell) AS modell FROM ap_pto
    )
  SELECT
    *
  FROM (
    SELECT
      'KOMPLEMENTÄR' AS gml_id,
      max(beginnt) AS beginnt,
      dientzurdarstellungvon,
      art,
      array_agg(a.modell) AS modelle
    FROM (
      SELECT
        dientzurdarstellungvon,
        max(beginnt) AS beginnt,
        art,
	array_agg(modell) AS modelle
      FROM (
        SELECT
          dientzurdarstellungvon,
          beginnt,
	  art,
	  unnest(modelle) AS modell
        FROM po_pto
      ) AS po_pto
      GROUP BY dientzurdarstellungvon,art
    ) AS po_pto
    JOIN a ON NOT a.modell=ANY(modelle)
    GROUP BY dientzurdarstellungvon, art
  ) AS a
  WHERE array_length(modelle,1)>0;

-- Für alle untergegangenen ap_pto für die es keine neuen po_pto gibt
-- ein "Trigger"-po_pto erzeugen, dass dafür sorgt, dass die Fachobjekte
-- mit Defaults neugezeichnet werden
INSERT INTO po_pto(gml_id,beginnt,dientzurdarstellungvon,art)
  WITH
    a AS (
      SELECT unnest(advstandardmodell) AS modell FROM ap_pto
    UNION
      SELECT unnest(sonstigesmodell) AS modell FROM ap_pto
    )
  SELECT
    'TRIGGER' AS gml_id,
    beginnt,
    dientzurdarstellungvon,
    art
  FROM (
    SELECT
      to_char(to_timestamp(lastrun, 'YYYY-MM-DD"T"HH24:MI:SS"Z"')+INTERVAL '1 seconds', 'YYYY-MM-DD"T"HH24:MI:SS"Z"') AS beginnt,
      unnest(dientzurdarstellungvon) AS dientzurdarstellungvon,
      art
    FROM po_lastrun, ap_pto
    WHERE beginnt<=lastrun AND endet>lastrun
  ) AS ap_pto
  WHERE NOT EXISTS (
    SELECT 1 FROM po_pto WHERE po_pto.dientzurdarstellungvon=ap_pto.dientzurdarstellungvon
  );

UPDATE po_pto SET modelle=(SELECT array_agg(modell) FROM (SELECT DISTINCT unnest(modelle) AS modell ORDER BY modell) AS foo WHERE modell IS NOT NULL);

SELECT 'Aktualisiere po_lto...';

-- Alle po_lto löschen, die zu untergegangenen ap_pto gehören oder
-- komplementär zum Darstellung des gleichen Objekts dienen
DELETE FROM po_lto a
  USING ap_lto b, po_lastrun
  WHERE b.beginnt<=lastrun AND b.endet>lastrun AND (a.gml_id=b.gml_id OR (a.gml_id='KOMPLEMENTÄR' AND ARRAY[a.dientzurdarstellungvon]<@b.dientzurdarstellungvon));

-- po_lto zu neuen ap_pto ergänzen
INSERT INTO po_lto(gml_id,beginnt,dientzurdarstellungvon,modelle,art,darstellungsprioritaet,fontsperrung,horizontaleausrichtung,schriftinhalt,signaturnummer,skalierung,vertikaleausrichtung,wkb_geometry)
  SELECT
    gml_id,
    beginnt,
    unnest(dientzurdarstellungvon) AS dientzurdarstellungvon,
    advstandardmodell||sonstigesmodell AS modelle,
    art,
    darstellungsprioritaet,
    fontsperrung,
    horizontaleausrichtung,
    schriftinhalt,
    signaturnummer,
    skalierung,
    vertikaleausrichtung,
    wkb_geometry
  FROM po_lastrun, ap_lto
  WHERE beginnt>lastrun AND endet IS NULL;

-- Komplementäre po_lto erzeugen, die dafür sorgen, dass
-- für die nicht per ap_pto übersteuerten Modelle eines jeden
-- Fachobjekts Kartendarstellung mit Defaults erzeugt werden
INSERT INTO po_lto(gml_id,beginnt,dientzurdarstellungvon,art,modelle)
  WITH
    a AS (
      SELECT unnest(advstandardmodell) AS modell FROM ap_lto
    UNION
      SELECT unnest(sonstigesmodell) AS modell FROM ap_lto
    )
  SELECT
    *
  FROM (
    SELECT
      'KOMPLEMENTÄR' AS gml_id,
      max(beginnt) AS beginnt,
      dientzurdarstellungvon,
      art,
      array_agg(a.modell) AS modelle
    FROM (
      SELECT
        dientzurdarstellungvon,
        max(beginnt) AS beginnt,
        art,
	array_agg(modell) AS modelle
      FROM (
        SELECT
          dientzurdarstellungvon,
          beginnt,
	  art,
	  unnest(modelle) AS modell
        FROM po_lto
      ) AS po_lto
      GROUP BY dientzurdarstellungvon,art
    ) AS po_lto
    JOIN a ON NOT a.modell=ANY(modelle)
    GROUP BY dientzurdarstellungvon, art
  ) AS a
  WHERE array_length(modelle,1)>0;

-- Für alle untergegangenen ap_pto für die es keine neuen po_lto gibt
-- ein "Trigger"-po_lto erzeugen, dass dafür sorgt, dass die Fachobjekte
-- mit Defaults neugezeichnet werden
INSERT INTO po_lto(gml_id,beginnt,dientzurdarstellungvon,art)
  WITH
    a AS (
      SELECT unnest(advstandardmodell) AS modell FROM ap_lto
    UNION
      SELECT unnest(sonstigesmodell) AS modell FROM ap_lto
    )
  SELECT
    'TRIGGER' AS gml_id,
    beginnt,
    dientzurdarstellungvon,
    art
  FROM (
    SELECT
      to_char(to_timestamp(lastrun, 'YYYY-MM-DD"T"HH24:MI:SS"Z"')+INTERVAL '1 seconds', 'YYYY-MM-DD"T"HH24:MI:SS"Z"') AS beginnt,
      unnest(dientzurdarstellungvon) AS dientzurdarstellungvon,
      art
    FROM po_lastrun, ap_lto
    WHERE beginnt<=lastrun AND endet>lastrun
  ) AS ap_lto
  WHERE NOT EXISTS (
    SELECT 1 FROM po_lto WHERE po_lto.dientzurdarstellungvon=ap_lto.dientzurdarstellungvon
  );

UPDATE po_lto SET modelle=(SELECT array_agg(modell) FROM (SELECT DISTINCT unnest(modelle) AS modell ORDER BY modell) AS foo WHERE modell IS NOT NULL);

END;
