/******************************************************************************
 *
 * Project:  norGIS ALKIS Import
 * Purpose:  Erzeugung der Präsentationstabellen
 * Author:   Jürgen E. Fischer jef@norbit.de
 *
 ***************************************************************************
 * Copyright (c) 2013-2014 Juergen E. Fischer (jef@norbit.de)              *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/

SELECT 'Präsentationstabellen werden erzeugt.';

-- Punkte
SELECT alkis_dropobject('po_points');
CREATE TABLE po_points(
	ogc_fid serial PRIMARY KEY,
	gml_id character(16) NOT NULL,
	thema varchar NOT NULL,
	layer varchar NOT NULL,
	signaturnummer varchar,
	drehwinkel double precision DEFAULT 0,
	modell varchar[] CHECK (array_length(modell,1)>0),
	drehwinkel_grad double precision
);

SELECT AddGeometryColumn('po_points','point', :alkis_epsg, 'MULTIPOINT', 2);

-- Linien
SELECT alkis_dropobject('po_lines');
CREATE TABLE po_lines(
	ogc_fid serial PRIMARY KEY,
	gml_id character(16) NOT NULL,
	thema varchar NOT NULL,
	layer varchar NOT NULL,
	signaturnummer varchar REFERENCES alkis_linien(signaturnummer),
	modell varchar[] CHECK (array_length(modell,1)>0)
);

SELECT AddGeometryColumn('po_lines','line', :alkis_epsg, 'MULTILINESTRING', 2);

-- Polygone
SELECT alkis_dropobject('po_polygons');
CREATE TABLE po_polygons(
	ogc_fid serial PRIMARY KEY,
	gml_id character(16) NOT NULL,
	thema varchar NOT NULL,
	layer varchar NOT NULL,
	signaturnummer varchar,
	sn_flaeche varchar REFERENCES alkis_flaechen(signaturnummer),
	sn_randlinie varchar REFERENCES alkis_linien(signaturnummer),
	modell varchar[] CHECK (array_length(modell,1)>0)
);

SELECT AddGeometryColumn('po_polygons','polygon', :alkis_epsg, 'MULTIPOLYGON', 2);

--- Beschriftungen
SELECT alkis_dropobject('po_labels');
CREATE TABLE po_labels(
	ogc_fid serial PRIMARY KEY,
	gml_id character(16) NOT NULL,
	thema varchar NOT NULL,
	layer varchar NOT NULL,
	signaturnummer varchar REFERENCES alkis_schriften(signaturnummer),
	text varchar NOT NULL,
	drehwinkel double precision DEFAULT 0,
	drehwinkel_grad double precision,
	fontsperrung double precision,
	skalierung double precision,
	horizontaleausrichtung varchar,
	vertikaleausrichtung varchar,
	alignment_dxf integer,
	color_umn varchar,
	font_umn varchar,
	size_umn integer,
	darstellungsprioritaet integer,
	modell varchar[] CHECK (array_length(modell,1)>0)
);

SELECT AddGeometryColumn('po_labels','point', :alkis_epsg, 'POINT', 2);
SELECT AddGeometryColumn('po_labels','line', :alkis_epsg, 'LINESTRING', 2);

--
-- Indizes
--

CREATE INDEX po_points_point_idx ON po_points USING gist (point);
CREATE INDEX po_points_gmlid_idx ON po_points(gml_id);
CREATE INDEX po_points_thema_idx ON po_points(thema);
CREATE INDEX po_points_layer_idx ON po_points(layer);
CREATE INDEX po_points_sn_idx ON po_points(signaturnummer);
CREATE INDEX po_points_modell_idx ON po_points USING gin (modell);

CREATE INDEX po_lines_line_idx ON po_lines USING gist (line);
CREATE INDEX po_lines_gmlid_idx ON po_lines(gml_id);
CREATE INDEX po_lines_thema_idx ON po_lines(thema);
CREATE INDEX po_lines_layer_idx ON po_lines(layer);
CREATE INDEX po_lines_sn_idx ON po_lines(signaturnummer);
CREATE INDEX po_lines_modell_idx ON po_lines USING gin (modell);

CREATE INDEX po_polygons_polygons_idx ON po_polygons USING gist (polygon);
CREATE INDEX po_polygons_gmlid_idx ON po_polygons(gml_id);
CREATE INDEX po_polygons_thema_idx ON po_polygons(thema);
CREATE INDEX po_polygons_layer_idx ON po_polygons(layer);
CREATE INDEX po_polygons_snf_idx ON po_polygons(sn_flaeche);
CREATE INDEX po_polygons_snr_idx ON po_polygons(sn_randlinie);
CREATE INDEX po_polygons_modell_idx ON po_polygons USING gin (modell);

CREATE INDEX po_labels_point_idx ON po_labels USING gist (point);
CREATE INDEX po_labels_line_idx ON po_labels USING gist (line);
CREATE INDEX po_labels_gmlid_idx ON po_labels(gml_id);
CREATE INDEX po_labels_thema_idx ON po_labels(thema);
CREATE INDEX po_labels_layer_idx ON po_labels(layer);
CREATE INDEX po_labels_text_idx ON po_labels(text);
CREATE INDEX po_labels_sn_idx ON po_labels(signaturnummer);
CREATE INDEX po_labels_modell_idx ON po_labels USING gin (modell);
