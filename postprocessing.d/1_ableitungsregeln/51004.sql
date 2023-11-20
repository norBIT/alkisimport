SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Transportanlage (51004)
--

SELECT 'Transportanlagen werden verarbeitet.';

-- Transportanlage, Linie
INSERT INTO po_polygons(gml_id,gml_ids,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	ARRAY[gml_id] AS gml_ids,
	'Industrie und Gewerbe' AS thema,
	'ax_transportanlage' AS layer,
	polygon,
	signaturnummer,
	modell
FROM (
	SELECT
		gml_id,
		st_multi(alkis_bufferline(wkb_geometry,0.5)) AS polygon,
		CASE
		WHEN coalesce(lagezurerdoberflaeche,1400)=1400 THEN 2521
		WHEN lagezurerdoberflaeche IN (1200,1700)      THEN 2504
		END AS signaturnummer,
		advstandardmodell||sonstigesmodell AS modell
	FROM po_lastrun, ax_transportanlage
	WHERE bauwerksfunktion=1102 AND endet IS NULL AND beginnt>lastrun
) AS t WHERE signaturnummer IS NOT NULL;

INSERT INTO po_lines(gml_id,gml_ids,thema,layer,line,signaturnummer,modell)
SELECT
	gml_id,
	ARRAY[gml_id] AS gml_ids,
	'Industrie und Gewerbe' AS thema,
	'ax_transportanlage' AS layer,
	line,
	signaturnummer,
	modell
FROM (
	SELECT
		gml_id,
		st_multi(wkb_geometry) AS line,
		CASE
		WHEN coalesce(lagezurerdoberflaeche,1400)=1400 THEN 2002
		WHEN lagezurerdoberflaeche IN (1200,1700)      THEN 2523
		END AS signaturnummer,
		advstandardmodell||sonstigesmodell AS modell
	FROM po_lastrun, ax_transportanlage
	WHERE bauwerksfunktion=1101 AND endet IS NULL AND geometrytype(wkb_geometry) IN ('LINESTRING','MULTILINESTRING') AND beginnt>lastrun
) AS t WHERE signaturnummer IS NOT NULL;

-- Transportanlage, Symbole
INSERT INTO po_points(gml_id,gml_ids,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	gml_id,
	ARRAY[gml_id] AS gml_ids,
	'Industrie und Gewerbe' AS thema,
	'ax_transportanlage' AS layer,
	st_multi(wkb_geometry) AS point,
	0 AS drehwinkel,
	3523 AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM po_lastrun, ax_transportanlage
WHERE bauwerksfunktion=1103 AND geometrytype(wkb_geometry) IN ('POINT','MULTIPOINT') AND lagezurerdoberflaeche IS NULL AND endet IS NULL AND beginnt>lastrun;

-- Transportanlage, Anschrieb Produkt
-- TODO: welche Text sind NULL?
INSERT INTO po_labels(gml_id,gml_ids,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	gml_ids,
	'Industrie und Gewerbe' AS thema,
	'ax_transportanlage' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		ARRAY[o.gml_id, t.gml_id, d.gml_id] AS gml_ids,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		(SELECT beschreibung FROM ax_produkt_transportanlage WHERE wert=produkt) AS text,
		coalesce(d.signaturnummer,t.signaturnummer,'4070') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM po_lastrun, ax_transportanlage o
	LEFT OUTER JOIN po_pto t ON o.gml_id=t.dientzurdarstellungvon AND t.art='PRO'
	LEFT OUTER JOIN po_darstellung d ON o.gml_id=d.dientzurdarstellungvon AND d.art='PRO'
	WHERE o.endet IS NULL AND NOT produkt IS NULL AND greatest(o.beginnt, t.beginnt, d.beginnt)>lastrun
) AS n
WHERE NOT text IS NULL;
