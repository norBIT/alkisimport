SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Heide (43004)
--

SELECT 'Heide wird verarbeitet.';

-- Heide, Flächen
INSERT INTO po_polygons(gml_id,gml_ids,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	ARRAY[gml_id] AS gml_ids,
	'Vegetation' AS thema,
	'ax_heide' AS layer,
	st_multi(wkb_geometry) AS polygon,
	25171404 AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM po_lastrun, ax_heide
WHERE endet IS NULL AND beginnt>lastrun;

-- Heide, Symbole
INSERT INTO po_points(gml_id,gml_ids,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	o.gml_id,
	ARRAY[o.gml_id, p.gml_id, d.gml_id] AS gml_ids,
	'Vegetation' AS thema,
	'ax_heide' AS layer,
	st_multi(coalesce(p.wkb_geometry,alkis_flaechenfuellung(o.wkb_geometry,d.positionierungsregel),st_centroid(o.wkb_geometry))) AS point,
	coalesce(p.drehwinkel,0) AS drehwinkel,
	coalesce(d.signaturnummer,'3474') AS signaturnummer,
	coalesce(p.modelle, d.modelle, o.advstandardmodell||o.sonstigesmodell) AS modell
FROM po_lastrun, ax_heide o
LEFT OUTER JOIN po_ppo p ON o.gml_id=p.dientzurdarstellungvon AND p.art='Heide'
LEFT OUTER JOIN po_darstellung d ON o.gml_id=d.dientzurdarstellungvon AND d.art='Heide'
WHERE o.endet IS NULL AND greatest(o.beginnt, p.beginnt, d.beginnt)>lastrun;

-- Heide, Namen
INSERT INTO po_labels(gml_id,gml_ids,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	gml_ids,
	'Vegetation' AS thema,
	'ax_heide' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		ARRAY[o.gml_id, t.gml_id, d.gml_id] AS gml_ids,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(t.schriftinhalt,o.name) AS text,
		coalesce(d.signaturnummer,t.signaturnummer,'4209') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM po_lastrun, ax_heide o
	LEFT OUTER JOIN po_pto t ON o.gml_id=t.dientzurdarstellungvon AND t.art='NAM'
	LEFT OUTER JOIN po_darstellung d ON o.gml_id=d.dientzurdarstellungvon AND d.art='NAM'
	WHERE o.endet IS NULL AND NOT name IS NULL AND greatest(o.beginnt, t.beginnt, d.beginnt)>lastrun
) AS n;
