SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Landwirtschaft (43001)
--

SELECT 'Landwirtschaft wird verarbeitet.';

-- Landwirtschaft, Fläche
INSERT INTO po_polygons(gml_id,gml_ids,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	ARRAY[gml_id] AS gml_ids,
	'Vegetation' AS thema,
	'ax_landwirtschaft' AS layer,
	polygon,
	signaturnummer,
	modell
FROM (
	SELECT
		gml_id,
		st_multi(wkb_geometry) AS polygon,
		CASE
		WHEN coalesce(vegetationsmerkmal,0) IN (0,1010,1011,1012,1013) THEN 25151409
		WHEN vegetationsmerkmal IN (1020,1021,1030,1031,1040,1050,1051,1052) THEN 25151406
		WHEN vegetationsmerkmal=1200 THEN 25151404
		END AS signaturnummer,
		advstandardmodell||sonstigesmodell AS modell
	FROM po_lastrun, ax_landwirtschaft
	WHERE endet IS NULL AND beginnt>lastrun
) AS o
WHERE NOT signaturnummer IS NULL;

-- Landwirtschaft, Symbole
-- TODO:
-- 3440/2    + PNR 1104 v 1105
-- 3442/3444 + PNR 1102 v 1103
INSERT INTO po_points(gml_id,gml_ids,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	gml_id,
	gml_ids,
	'Vegetation' AS thema,
	'ax_landwirtschaft' AS layer,
	st_multi(point),
	drehwinkel,
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		ARRAY[o.gml_id, p.gml_id, d.gml_id] AS gml_ids,
		coalesce(p.wkb_geometry,alkis_flaechenfuellung(o.wkb_geometry,d.positionierungsregel),st_centroid(o.wkb_geometry)) AS point,
		coalesce(p.drehwinkel,0) AS drehwinkel,
		coalesce(
			d.signaturnummer,
			p.signaturnummer,
			CASE
			WHEN vegetationsmerkmal=1011 THEN '3440'
			WHEN vegetationsmerkmal=1012 THEN '3442'
			WHEN vegetationsmerkmal=1013 THEN '3444'
			WHEN vegetationsmerkmal=1020 THEN '3413'
			WHEN vegetationsmerkmal=1021 THEN '3441'
			WHEN vegetationsmerkmal=1030 THEN '3421'
			WHEN vegetationsmerkmal=1031 THEN '3446'
			WHEN vegetationsmerkmal=1040 THEN '3448'
			WHEN vegetationsmerkmal=1050 THEN '3450'
			WHEN vegetationsmerkmal=1051 THEN '3452'
			WHEN vegetationsmerkmal=1052 THEN '3454'
			END
		) AS signaturnummer,
		coalesce(p.modelle, d.modelle, o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM po_lastrun, ax_landwirtschaft o
	LEFT OUTER JOIN po_ppo p ON o.gml_id=p.dientzurdarstellungvon AND p.art='VEG'
	LEFT OUTER JOIN po_darstellung d ON o.gml_id=d.dientzurdarstellungvon AND d.art='VEG'
	WHERE o.endet IS NULL AND greatest(o.beginnt, p.beginnt, d.beginnt)>lastrun
) AS o
WHERE NOT signaturnummer IS NULL;

-- Landwirtschaft, Name
INSERT INTO po_labels(gml_id,gml_ids,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	gml_ids,
	'Vegetation' AS thema,
	'ax_landwirtschaft' AS layer,
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
		coalesce(d.signaturnummer,t.signaturnummer,'4208') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM po_lastrun, ax_landwirtschaft o
	LEFT OUTER JOIN po_pto t ON o.gml_id=t.dientzurdarstellungvon AND t.art='NAM'
	LEFT OUTER JOIN po_darstellung d ON o.gml_id=d.dientzurdarstellungvon AND d.art='NAM'
	WHERE o.endet IS NULL AND NOT name IS NULL AND greatest(o.beginnt, t.beginnt, d.beginnt)>lastrun
) AS n;
