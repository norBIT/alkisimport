SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Bergbaubetrieb (41004)
--

SELECT 'Bergbaubetriebe werden verarbeitet.';

-- Bergbaubetrieb, Flächen
INSERT INTO po_polygons(gml_id,gml_ids,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	ARRAY[gml_id] AS gml_id,
	'Industrie und Gewerbe' AS thema,
	'ax_bergbaubetrieb' AS layer,
	st_multi(wkb_geometry) AS polygon,
	25151403 AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM po_lastrun, ax_bergbaubetrieb
WHERE endet IS NULL AND beginnt>lastrun;

-- Bergbaubetrieb, Zustandssymbole
INSERT INTO po_points(gml_id,gml_ids,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	gml_id,
	gml_ids,
	'Industrie und Gewerbe' AS thema,
	'ax_bergbaubetrieb' AS layer,
	st_multi(point),
	drehwinkel,
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		ARRAY[o.gml_id, p.gml_id, d.gml_id] AS gml_ids,
		coalesce(p.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(p.drehwinkel,0) AS drehwinkel,
		coalesce(d.signaturnummer,p.signaturnummer,CASE WHEN zustand=2100 THEN '3406' ELSE '3505' END) AS signaturnummer,
		coalesce(p.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM po_lastrun, ax_bergbaubetrieb o
	LEFT OUTER JOIN po_ppo p ON o.gml_id=p.dientzurdarstellungvon AND p.art='ZUS'
	LEFT OUTER JOIN po_darstellung d ON o.gml_id=d.dientzurdarstellungvon AND d.art='ZUS'
	WHERE o.endet IS NULL AND greatest(o.beginnt, p.beginnt, d.beginnt)>lastrun
) AS b;

-- Bergbaubetrieb, Anschrieb Abbaugut
INSERT INTO po_labels(gml_id,gml_ids,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	gml_ids,
	'Industrie und Gewerbe' AS thema,
	'ax_bergbaubetrieb' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel, horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung,
	modell
FROM (
	SELECT
		o.gml_id,
		ARRAY[o.gml_id, t.gml_id, d.gml_id] AS gml_ids,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(
			schriftinhalt,
			E'(' || (SELECT beschreibung FROM ax_abbaugut_bergbaubetrieb WHERE wert=abbaugut) ||')'
		) AS text,
		coalesce(d.signaturnummer,t.signaturnummer,'4141') AS signaturnummer,
		drehwinkel, horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung,
		coalesce(t.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM po_lastrun, ax_bergbaubetrieb o
	LEFT OUTER JOIN po_pto t ON o.gml_id=t.dientzurdarstellungvon AND t.art='AGT'
	LEFT OUTER JOIN po_darstellung d ON o.gml_id=d.dientzurdarstellungvon AND d.art='AGT'
	WHERE NOT abbaugut IS NULL AND o.endet IS NULL AND greatest(o.beginnt, t.beginnt, d.beginnt)>lastrun
) AS b
WHERE NOT text IS NULL;

-- Bergbaubetrieb, Namen
INSERT INTO po_labels(gml_id,gml_ids,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	gml_ids,
	'Industrie und Gewerbe' AS thema,
	'ax_bergbaubetrieb' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel, horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung, modell
FROM (
	SELECT
		o.gml_id,
		ARRAY[o.gml_id, t.gml_id, d.gml_id] AS gml_ids,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(t.schriftinhalt,o.name) AS text,
		coalesce(d.signaturnummer,t.signaturnummer,'4141') AS signaturnummer,
		drehwinkel, horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung,
		coalesce(t.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM po_lastrun, ax_bergbaubetrieb o
	LEFT OUTER JOIN po_pto t ON o.gml_id=t.dientzurdarstellungvon AND t.art='NAM'
	LEFT OUTER JOIN po_darstellung d ON o.gml_id=d.dientzurdarstellungvon AND d.art='NAM'
	WHERE o.endet IS NULL AND greatest(o.beginnt, t.beginnt, d.beginnt)>lastrun
) AS h WHERE NOT text IS NULL;
