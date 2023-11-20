/***************************************************************************
 *                                                                         *
 * Project:  norGIS ALKIS Import                                           *
 * Purpose:  Erzeugung der Präsentationstabellen                           *
 * Author:   Jürgen E. Fischer jef@norbit.de                               *
 *                                                                         *
 ***************************************************************************
 * Copyright (c) 2013-2023 Juergen E. Fischer (jef@norbit.de)              *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/

SET search_path = :"alkis_schema", :"postgis_schema", public;

SELECT 'Präsentationstabellen werden erzeugt.';

SELECT alkis_dropobject('alkis_po_version');
CREATE TABLE alkis_po_version(version integer);
INSERT INTO alkis_po_version(version) VALUES (5);

--
-- Präsentationstabellen
--

-- Punkte
SELECT alkis_dropobject('po_points');
CREATE TABLE po_points(
	ogc_fid serial PRIMARY KEY,
	gml_id character(16) NOT NULL,
	gml_ids character(16)[] NOT NULL,
	thema varchar NOT NULL,
	layer varchar NOT NULL,
	signaturnummer varchar,
	drehwinkel double precision DEFAULT 0,
	modell varchar[] CHECK (array_length(modell,1)>0),
	drehwinkel_grad double precision
);
COMMENT ON TABLE po_points IS 'BASE: Punktobjekte';

SELECT AddGeometryColumn('po_points','point', :alkis_epsg, 'MULTIPOINT', 2);

-- Linien
SELECT alkis_dropobject('po_lines');
CREATE TABLE po_lines(
	ogc_fid serial PRIMARY KEY,
	gml_id character(16) NOT NULL,
	gml_ids character(16)[] NOT NULL,
	thema varchar NOT NULL,
	layer varchar NOT NULL,
	signaturnummer varchar,
	modell varchar[] CHECK (array_length(modell,1)>0)
);
COMMENT ON TABLE po_points IS 'BASE: Linienobjekte';

SELECT AddGeometryColumn('po_lines','line', :alkis_epsg, 'MULTILINESTRING', 2);

-- Polygone
SELECT alkis_dropobject('po_polygons');
CREATE TABLE po_polygons(
	ogc_fid serial PRIMARY KEY,
	gml_id character(16) NOT NULL,
	gml_ids character(16)[] NOT NULL,
	thema varchar NOT NULL,
	layer varchar NOT NULL,
	signaturnummer varchar,
	sn_flaeche varchar,
	sn_randlinie varchar,
	modell varchar[] CHECK (array_length(modell,1)>0)
);
COMMENT ON TABLE po_points IS 'BASE: Flächenobjekte';

SELECT AddGeometryColumn('po_polygons','polygon', :alkis_epsg, 'MULTIPOLYGON', 2);

--- Beschriftungen
SELECT alkis_dropobject('po_labels');
CREATE TABLE po_labels(
	ogc_fid serial PRIMARY KEY,
	gml_id character(16) NOT NULL,
	gml_ids character(16)[] NOT NULL,
	thema varchar NOT NULL,
	layer varchar NOT NULL,
	signaturnummer varchar,
	text varchar NOT NULL,
	drehwinkel double precision DEFAULT 0,
	drehwinkel_grad double precision,
	fontsperrung double precision,
	skalierung double precision,
	horizontaleausrichtung varchar,
	vertikaleausrichtung varchar,
	modell varchar[] CHECK (array_length(modell,1)>0)
);
COMMENT ON TABLE po_points IS 'BASE: Beschriftungsobjekte';

SELECT AddGeometryColumn('po_labels','point', :alkis_epsg, 'POINT', 2);
SELECT AddGeometryColumn('po_labels','line', :alkis_epsg, 'LINESTRING', 2);

-- Verwendete Modelle
SELECT alkis_dropobject('po_modelle');
CREATE TABLE po_modelle(modell varchar, n INTEGER);
COMMENT ON TABLE po_modelle IS 'BASE: Verwendete Modelle';

--
-- Indizes
--

CREATE INDEX po_points_point_idx ON po_points USING gist (point);
CREATE INDEX po_points_gmlid_idx ON po_points(gml_id);
CREATE INDEX po_points_thema_idx ON po_points(thema);
CREATE INDEX po_points_layer_idx ON po_points(layer);
CREATE INDEX po_points_sn_idx ON po_points(signaturnummer);
CREATE INDEX po_points_modell_idx ON po_points USING gin (modell);
CREATE INDEX po_points_gmlids_idx ON po_points USING gin (gml_ids);

CREATE INDEX po_lines_line_idx ON po_lines USING gist (line);
CREATE INDEX po_lines_gmlid_idx ON po_lines(gml_id);
CREATE INDEX po_lines_thema_idx ON po_lines(thema);
CREATE INDEX po_lines_layer_idx ON po_lines(layer);
CREATE INDEX po_lines_sn_idx ON po_lines(signaturnummer);
CREATE INDEX po_lines_modell_idx ON po_lines USING gin (modell);
CREATE INDEX po_lines_gmlids_idx ON po_lines USING gin (gml_ids);

CREATE INDEX po_polygons_polygons_idx ON po_polygons USING gist (polygon);
CREATE INDEX po_polygons_gmlid_idx ON po_polygons(gml_id);
CREATE INDEX po_polygons_thema_idx ON po_polygons(thema);
CREATE INDEX po_polygons_layer_idx ON po_polygons(layer);
CREATE INDEX po_polygons_snf_idx ON po_polygons(sn_flaeche);
CREATE INDEX po_polygons_snr_idx ON po_polygons(sn_randlinie);
CREATE INDEX po_polygons_modell_idx ON po_polygons USING gin (modell);
CREATE INDEX po_polygons_gmlids_idx ON po_polygons USING gin (gml_ids);

CREATE INDEX po_labels_point_idx ON po_labels USING gist (point);
CREATE INDEX po_labels_line_idx ON po_labels USING gist (line);
CREATE INDEX po_labels_gmlid_idx ON po_labels(gml_id);
CREATE INDEX po_labels_thema_idx ON po_labels(thema);
CREATE INDEX po_labels_layer_idx ON po_labels(layer);
CREATE INDEX po_labels_text_idx ON po_labels(text);
CREATE INDEX po_labels_sn_idx ON po_labels(signaturnummer);
CREATE INDEX po_labels_modell_idx ON po_labels USING gin (modell);
CREATE INDEX po_labels_gmlids_idx ON po_labels USING gin (gml_ids);

--
-- Signaturkataloge
--
SELECT alkis_dropobject('alkis_flaechen');
SELECT alkis_dropobject('alkis_linie');
SELECT alkis_dropobject('alkis_konturen');
SELECT alkis_dropobject('alkis_linien');
SELECT alkis_dropobject('alkis_randlinie');
SELECT alkis_dropobject('alkis_schriften');
SELECT alkis_dropobject('alkis_stricharten_i');
SELECT alkis_dropobject('alkis_stricharten');
SELECT alkis_dropobject('alkis_strichart');
SELECT alkis_dropobject('alkis_farben');
SELECT alkis_dropobject('alkis_punkte');
SELECT alkis_dropobject('alkis_signaturkataloge');
CREATE TABLE alkis_signaturkataloge(id INTEGER PRIMARY KEY, name VARCHAR);
CREATE TABLE alkis_strichart(id INTEGER PRIMARY KEY,laenge DOUBLE PRECISION,einzug DOUBLE PRECISION,abstand DOUBLE PRECISION[]);
CREATE TABLE alkis_stricharten(id INTEGER PRIMARY KEY);
CREATE TABLE alkis_stricharten_i(id INTEGER PRIMARY KEY,stricharten INTEGER,i INTEGER,strichart INTEGER,FOREIGN KEY (stricharten) REFERENCES alkis_stricharten(id),FOREIGN KEY (strichart) REFERENCES alkis_strichart(id));
CREATE TABLE alkis_farben(id INTEGER PRIMARY KEY,name VARCHAR,c INTEGER,y INTEGER,m INTEGER,k INTEGER,r INTEGER,g INTEGER,b INTEGER,umn VARCHAR);
CREATE TABLE alkis_randlinie(id INTEGER PRIMARY KEY,farbe INTEGER,strichart INTEGER,strichstaerke DOUBLE PRECISION,abschluss VARCHAR,scheitel VARCHAR,FOREIGN KEY (farbe) REFERENCES alkis_farben(id),FOREIGN KEY (strichart) REFERENCES alkis_strichart(id));
CREATE TABLE alkis_schriften(katalog INTEGER,signaturnummer VARCHAR,darstellungsprioritaet INTEGER,name VARCHAR[],seite INTEGER,art VARCHAR,stil VARCHAR,grad_pt INTEGER,horizontaleausrichtung VARCHAR,vertikaleausrichtung VARCHAR,farbe INTEGER,alignment_umn CHAR(2),alignment_dxf INTEGER,sperrung_pt INTEGER,effekt VARCHAR,position TEXT,PRIMARY KEY (katalog,signaturnummer),FOREIGN KEY (katalog) REFERENCES alkis_signaturkataloge(id),FOREIGN KEY (farbe) REFERENCES alkis_farben(id));
CREATE TABLE alkis_linien(katalog INTEGER,signaturnummer VARCHAR,darstellungsprioritaet INTEGER,name VARCHAR[],seite INTEGER,PRIMARY KEY (katalog,signaturnummer),FOREIGN KEY (katalog) REFERENCES alkis_signaturkataloge(id));
CREATE TABLE alkis_linie(id INTEGER PRIMARY KEY,i INTEGER NOT NULL,katalog INTEGER,signaturnummer VARCHAR,strichart INTEGER,abschluss VARCHAR,scheitel VARCHAR,strichstaerke DOUBLE PRECISION,pfeilhoehe DOUBLE PRECISION,pfeillaenge DOUBLE PRECISION,farbe INTEGER,position TEXT,FOREIGN KEY (katalog,signaturnummer) REFERENCES alkis_linien(katalog,signaturnummer),FOREIGN KEY (strichart) REFERENCES alkis_stricharten(id),FOREIGN KEY (farbe) REFERENCES alkis_farben(id));
CREATE TABLE alkis_flaechen(katalog INTEGER,signaturnummer VARCHAR,darstellungsprioritaet INTEGER,name VARCHAR[],seite INTEGER,farbe INTEGER,randlinie INTEGER,PRIMARY KEY (katalog,signaturnummer),FOREIGN KEY (katalog) REFERENCES alkis_signaturkataloge(id),FOREIGN KEY (farbe) REFERENCES alkis_farben(id),FOREIGN KEY (randlinie) REFERENCES alkis_randlinie(id));
CREATE TABLE alkis_punkte(katalog integer,signaturnummer varchar,x0 double precision,y0 double precision,x1 double precision,y1 double precision,PRIMARY KEY (katalog,signaturnummer),FOREIGN KEY (katalog) REFERENCES alkis_signaturkataloge(id));

--
-- Gesamtview der ALKIS-Objekte
--

SELECT alkis_dropobject('alkis_po_objekte');
SELECT
  E'CREATE VIEW alkis_po_objekte AS\n  ' ||
  array_to_string(
    array_agg(
      format('SELECT gml_id,beginnt,endet,%L AS table_name FROM %I', table_name, table_name)
    ),
    E' UNION ALL\n  '
  )
FROM (
  SELECT
    table_name
  FROM information_schema.columns
  WHERE table_schema=:'alkis_schema' AND column_name IN ('gml_id', 'beginnt', 'endet')
  GROUP BY table_name
  HAVING count(*)=3
) AS t
\gexec

SELECT alkis_dropobject('po_lastrun');
CREATE TABLE po_lastrun(
	lastrun character(20),
	npoints INTEGER,
	nlines INTEGER,
	npolygons INTEGER,
	nlabels INTEGER
);
INSERT INTO po_lastrun(lastrun,npoints,nlines,npolygons,nlabels) VALUES (NULL, 0, 0, 0, 0);

SELECT alkis_dropobject('po_darstellung');
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

SELECT alkis_dropobject('po_ppo');
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

SELECT AddGeometryColumn('po_ppo','wkb_geometry', :alkis_epsg, 'GEOMETRY', 2);

CREATE INDEX po_ppo_gml_id ON po_ppo(gml_id);
CREATE INDEX po_ppo_dzv ON po_ppo(dientzurdarstellungvon);
CREATE INDEX po_ppo_art ON po_ppo(art);

SELECT alkis_dropobject('po_lpo');
CREATE TABLE po_lpo (
  gml_id character(16),
  beginnt character(20),
  dientzurdarstellungvon character(16),
  modelle character varying[],
  art character varying,
  darstellungsprioritaet integer,
  signaturnummer character varying
);

SELECT AddGeometryColumn('po_lpo','wkb_geometry', :alkis_epsg, 'GEOMETRY', 2);

CREATE INDEX po_lpo_gml_id ON po_lpo(gml_id);
CREATE INDEX po_lpo_dzv ON po_lpo(dientzurdarstellungvon);
CREATE INDEX po_lpo_art ON po_lpo(art);

SELECT alkis_dropobject('po_fpo');
CREATE TABLE po_fpo (
  gml_id character(16),
  beginnt character(20),
  dientzurdarstellungvon character(16),
  modelle character varying[],
  art character varying,
  darstellungsprioritaet integer,
  signaturnummer character varying
);

SELECT AddGeometryColumn('po_fpo','wkb_geometry', :alkis_epsg, 'GEOMETRY', 2);

CREATE INDEX po_fpo_gml_id ON po_fpo(gml_id);
CREATE INDEX po_fpo_dzv ON po_fpo(dientzurdarstellungvon);
CREATE INDEX po_fpo_art ON po_fpo(art);

SELECT alkis_dropobject('po_pto');
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

SELECT AddGeometryColumn('po_pto','wkb_geometry', :alkis_epsg, 'GEOMETRY', 2);

CREATE INDEX po_pto_gml_id ON po_pto(gml_id);
CREATE INDEX po_pto_dzv ON po_pto(dientzurdarstellungvon);
CREATE INDEX po_pto_art ON po_pto(art);

SELECT alkis_dropobject('po_lto');
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

SELECT AddGeometryColumn('po_lto','wkb_geometry', :alkis_epsg, 'GEOMETRY', 2);

CREATE INDEX po_lto_gml_id ON po_lto(gml_id);
CREATE INDEX po_lto_dzv ON po_lto(dientzurdarstellungvon);
CREATE INDEX po_lto_art ON po_lto(art);
