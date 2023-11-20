SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Landwirtschaftliche Nutzung (72004; RP)
--

SELECT 'Landwirtschaftliche Nutzung (RP) wird verarbeitet.';

INSERT INTO po_polygons(gml_id,gml_ids,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	ARRAY[gml_id] AS gml_ids,
	'Landwirtschaftliche Nutzung' AS thema,
	'ax_bewertung' AS layer,
	st_multi(wkb_geometry) AS polygon,
	1704 AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM po_lastrun, ax_bewertung
WHERE gml_id LIKE 'DERP%' AND endet IS NULL AND geometrytype(wkb_geometry) IN ('POLYGON','MULTIPOLYGON') AND beginnt>lastrun;

INSERT INTO po_labels(gml_id,gml_ids,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	o.gml_id,
	ARRAY[o.gml_id, t.gml_id] AS gml_ids,
	'Landwirtschaftliche Nutzung' AS thema,
	'ax_bewertung' AS layer,
	t.wkb_geometry AS point,
	t.schriftinhalt AS text,
	4107 AS signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
	coalesce(t.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM po_lastrun, ax_bewertung o
JOIN po_pto t ON o.gml_id=t.dientzurdarstellungvon AND t.art='KLA' AND t.schriftinhalt IS NOT NULL
WHERE o.gml_id LIKE 'DERP%' AND o.endet IS NULL AND greatest(o.beginnt, t.beginnt)>lastrun;
