SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Stehendes Gewässer (44006)
--

SELECT 'Stehende Gewässer werden verarbeitet.';

-- Stehendes Gewässer, Flächen
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	'Gewässer' AS thema,
	'ax_stehendesgewaesser' AS layer,
	st_multi(wkb_geometry) AS polygon,
	CASE
	WHEN hydrologischesmerkmal IS NULL THEN 25181410
	WHEN hydrologischesmerkmal=2000    THEN 25201410
	END AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ax_stehendesgewaesser
WHERE endet IS NULL;

-- Stehendes Gewässer, Symbol
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	o.gml_id,
	'Gewässer' AS thema,
	'ax_stehendesgewaesser' AS layer,
	st_multi(coalesce(p.wkb_geometry,alkis_flaechenfuellung(o.wkb_geometry,d.positionierungsregel),st_centroid(o.wkb_geometry))) AS point,
	coalesce(p.drehwinkel,0) AS drehwinkel,
	coalesce(d.signaturnummer,p.signaturnummer,'3490') AS signaturnummer,
	coalesce(
		p.advstandardmodell||p.sonstigesmodell||d.advstandardmodell||d.sonstigesmodell,
		o.advstandardmodell||o.sonstigesmodell
	) AS modell
FROM ax_stehendesgewaesser o
LEFT OUTER JOIN ap_ppo p ON ARRAY[o.gml_id] <@ p.dientzurdarstellungvon AND p.art='FKT' AND p.endet IS NULL
LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='FKT' AND d.endet IS NULL
WHERE o.endet IS NULL;
