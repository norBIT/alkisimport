SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Wasserspiegelhöhe (57001)
--

SELECT 'Wasserspiegelhöhen werden verarbeitet.';

-- Symbol
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	o.gml_id,
	'Gewässer' AS thema,
	'ax_wasserspiegelhoehe' AS layer,
	st_multi(coalesce(p.wkb_geometry,o.wkb_geometry)) AS point,
	coalesce(p.drehwinkel,0) AS drehwinkel,
	coalesce(d.signaturnummer,p.signaturnummer,'3623') AS signaturnummer,
	coalesce(p.advstandardmodell||p.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM ax_wasserspiegelhoehe o
LEFT OUTER JOIN ap_ppo p ON ARRAY[o.gml_id] <@ p.dientzurdarstellungvon AND p.art='SYMBOL' AND p.endet IS NULL
LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='SYMBOL' AND d.endet IS NULL
WHERE o.endet IS NULL AND NOT hoehedeswasserspiegels IS NULL;

-- Wasserspiegeltext
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	o.gml_id,
	'Gewässer' AS thema,
	'ax_wasserspiegelhoehe' AS layer,
	coalesce(t.wkb_geometry,st_translate(st_centroid(o.wkb_geometry),-3.5,0)) AS point,
	hoehedeswasserspiegels AS text,
	coalesce(d.signaturnummer,t.signaturnummer,'4102') AS signaturnummer,
	drehwinkel,
	coalesce(horizontaleausrichtung,'rechtsbündig'::text) AS horizontaleausrichtung,
	vertikaleausrichtung,skalierung,fontsperrung,
	coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM ax_wasserspiegelhoehe o
LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='HWS' AND t.endet IS NULL
LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='HWS' AND d.endet IS NULL
WHERE o.endet IS NULL AND NOT hoehedeswasserspiegels IS NULL;
