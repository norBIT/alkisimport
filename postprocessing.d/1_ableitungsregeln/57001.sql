SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Wasserspiegelhöhe (57001)
--

SELECT 'Wasserspiegelhöhen werden verarbeitet.';

-- Symbol
INSERT INTO po_points(gml_id,gml_ids,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	o.gml_id,
	ARRAY[o.gml_id, p.gml_id, d.gml_id] AS gml_ids,
	'Gewässer' AS thema,
	'ax_wasserspiegelhoehe' AS layer,
	st_multi(coalesce(p.wkb_geometry,o.wkb_geometry)) AS point,
	coalesce(p.drehwinkel,0) AS drehwinkel,
	coalesce(d.signaturnummer,p.signaturnummer,'3623') AS signaturnummer,
	coalesce(p.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM po_lastrun, ax_wasserspiegelhoehe o
LEFT OUTER JOIN po_ppo p ON o.gml_id=p.dientzurdarstellungvon AND p.art='SYMBOL'
LEFT OUTER JOIN po_darstellung d ON o.gml_id=d.dientzurdarstellungvon AND d.art='SYMBOL'
WHERE o.endet IS NULL AND NOT hoehedeswasserspiegels IS NULL AND greatest(o.beginnt, p.beginnt, d.beginnt)>lastrun;

-- Wasserspiegeltext
INSERT INTO po_labels(gml_id,gml_ids,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	o.gml_id,
	ARRAY[o.gml_id, t.gml_id, d.gml_id] AS gml_ids,
	'Gewässer' AS thema,
	'ax_wasserspiegelhoehe' AS layer,
	coalesce(t.wkb_geometry,st_translate(st_centroid(o.wkb_geometry),-3.5,0)) AS point,
	hoehedeswasserspiegels AS text,
	coalesce(d.signaturnummer,t.signaturnummer,'4102') AS signaturnummer,
	drehwinkel,
	coalesce(horizontaleausrichtung,'rechtsbündig'::text) AS horizontaleausrichtung,
	vertikaleausrichtung,skalierung,fontsperrung,
	coalesce(t.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM po_lastrun, ax_wasserspiegelhoehe o
LEFT OUTER JOIN po_pto t ON o.gml_id=t.dientzurdarstellungvon AND t.art='HWS'
LEFT OUTER JOIN po_darstellung d ON o.gml_id=d.dientzurdarstellungvon AND d.art='HWS'
WHERE o.endet IS NULL AND NOT hoehedeswasserspiegels IS NULL AND greatest(o.beginnt, t.beginnt, d.beginnt)>lastrun;
