SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Einrichtungen für den Schiffsverkehr (53008)
--

SELECT 'Einrichtungen für den Schiffsverkehr werden verarbeitet.';

-- Symbole
INSERT INTO po_points(gml_id,gml_ids,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	gml_id,
	ARRAY[gml_id] AS gml_ids,
	'Verkehr' AS thema,
	'ax_einrichtungenfuerdenschiffsverkehr' AS layer,
	st_multi(wkb_geometry) AS point,
	0 AS drehwinkel,
	CASE
	WHEN art=1420 THEN 3590
	WHEN art=1430 THEN 3556
	WHEN art=1440 THEN 3583
	WHEN art=1450 THEN 3584
	WHEN art=9999 THEN 3640
	END AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM po_lastrun, ax_einrichtungenfuerdenschiffsverkehr o
WHERE geometrytype(o.wkb_geometry) IN ('POINT','MULTIPOINT') AND endet IS NULL AND beginnt>lastrun;

-- Flächen
INSERT INTO po_polygons(gml_id,gml_ids,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	ARRAY[gml_id] AS gml_ids,
	'Verkehr' AS thema,
	'ax_einrichtungenfuerdenschiffsverkehr' AS layer,
	st_multi(wkb_geometry) AS polygon,
	1544 AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM po_lastrun, ax_einrichtungenfuerdenschiffsverkehr
WHERE geometrytype(wkb_geometry) IN ('POLYGON','MULTIPOLYGON') AND endet IS NULL AND beginnt>lastrun;

-- Kilometerangaben
INSERT INTO po_labels(gml_id,gml_ids,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	o.gml_id,
	ARRAY[o.gml_id,t.gml_id,d.gml_id] AS gml_ids,
	'Verkehr' AS thema,
	'ax_einrichtungenfuerdenschiffsverkehr' AS layer,
	coalesce(t.wkb_geometry,st_translate(o.wkb_geometry,5,0)) AS point,
	kilometerangabe AS text,
	coalesce(d.signaturnummer,t.signaturnummer,'4101') AS signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
	coalesce(t.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM po_lastrun, ax_einrichtungenfuerdenschiffsverkehr o
LEFT OUTER JOIN po_pto t ON o.gml_id=t.dientzurdarstellungvon AND t.art='KMA'
LEFT OUTER JOIN po_darstellung d ON o.gml_id=d.dientzurdarstellungvon AND d.art='KMA'
WHERE o.endet IS NULL AND NOT kilometerangabe IS NULL AND greatest(o.beginnt,t.beginnt,d.beginnt)>lastrun;

-- Namen
INSERT INTO po_labels(gml_id,gml_ids,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	gml_ids,
	'Verkehr' AS thema,
	'ax_einrichtungenfuerdenschiffsverkehr' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		ARRAY[o.gml_id,t.gml_id,d.gml_id] AS gml_ids,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(t.schriftinhalt,name) AS text,
		coalesce(d.signaturnummer,t.signaturnummer,'4081') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM po_lastrun, ax_einrichtungenfuerdenschiffsverkehr o
	LEFT OUTER JOIN po_pto t ON o.gml_id=t.dientzurdarstellungvon AND t.art='NAM'
	LEFT OUTER JOIN po_darstellung d ON o.gml_id=d.dientzurdarstellungvon AND d.art='NAM'
	WHERE o.endet IS NULL AND (NOT name IS NULL OR NOT t.schriftinhalt IS NULL) AND greatest(o.beginnt,t.beginnt,d.beginnt)>lastrun
) AS n WHERE NOT text IS NULL;
