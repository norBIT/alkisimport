SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Stehendes Gewässer (44006)
--

SELECT 'Stehende Gewässer werden verarbeitet.';

-- Stehendes Gewässer, Flächen
INSERT INTO po_polygons(gml_id,gml_ids,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	ARRAY[gml_id] AS gml_ids,
	'Gewässer' AS thema,
	'ax_stehendesgewaesser' AS layer,
	st_multi(wkb_geometry) AS polygon,
	CASE
	WHEN hydrologischesmerkmal IS NULL THEN 25181410
	WHEN hydrologischesmerkmal=2000    THEN 25201410
	END AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM po_lastrun, ax_stehendesgewaesser
WHERE endet IS NULL AND beginnt>lastrun;

-- Stehendes Gewässer, Symbol
INSERT INTO po_points(gml_id,gml_ids,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	o.gml_id,
	ARRAY[o.gml_id, p.gml_id, d.gml_id] AS gml_ids,
	'Gewässer' AS thema,
	'ax_stehendesgewaesser' AS layer,
	st_multi(coalesce(p.wkb_geometry,alkis_flaechenfuellung(o.wkb_geometry,d.positionierungsregel),st_centroid(o.wkb_geometry))) AS point,
	coalesce(p.drehwinkel,0) AS drehwinkel,
	coalesce(d.signaturnummer,p.signaturnummer,'3490') AS signaturnummer,
	coalesce(p.modelle, d.modelle, o.advstandardmodell||o.sonstigesmodell) AS modell
FROM po_lastrun, ax_stehendesgewaesser o
LEFT OUTER JOIN po_ppo p ON o.gml_id=p.dientzurdarstellungvon AND p.art='FKT'
LEFT OUTER JOIN po_darstellung d ON o.gml_id=d.dientzurdarstellungvon AND d.art='FKT'
WHERE o.endet IS NULL AND greatest(o.beginnt, p.beginnt, d.beginnt)>lastrun;
