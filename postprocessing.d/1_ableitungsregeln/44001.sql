SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Fließgewässer (44001)
--

SELECT 'Fließgewässer werden verarbeitet.';

-- Fließgewässer, Flächen
INSERT INTO po_polygons(gml_id,gml_ids,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	ARRAY[gml_id] AS gml_ids,
	'Gewässer' AS thema,
	'ax_fliessgewaesser' AS layer,
	st_multi(wkb_geometry) AS polygon,
	CASE
	WHEN zustand=4000 THEN 2519
	ELSE 25181410
	END AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM po_lastrun, ax_fliessgewaesser
WHERE endet IS NULL AND beginnt>lastrun;

-- Fließgewäesser, Pfeil
INSERT INTO po_points(gml_id,gml_ids,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	o.gml_id,
	ARRAY[o.gml_id, p.gml_id] AS gml_ids,
	'Gewässer' AS thema,
	'ax_fliessgewaesser' AS layer,
	st_multi(coalesce(p.wkb_geometry,st_centroid(o.wkb_geometry))) AS point,
	coalesce(p.drehwinkel,0) AS drehwinkel,
	coalesce(p.signaturnummer,'3488') AS signaturnummer,
	coalesce(p.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM po_lastrun, ax_fliessgewaesser o
JOIN po_ppo p ON o.gml_id=p.dientzurdarstellungvon AND p.art='Fließpfeil' AND p.gml_id<>'TRIGGER'
WHERE o.endet IS NULL AND coalesce(zustand,0)<>4000 AND greatest(o.beginnt, p.beginnt)>lastrun;

-- Fließgewäesser, Symbol
INSERT INTO po_points(gml_id,gml_ids,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	o.gml_id,
	ARRAY[o.gml_id, p.gml_id, d.gml_id] AS gml_ids,
	'Gewässer' AS thema,
	'ax_fliessgewaesser' AS layer,
	st_multi(coalesce(p.wkb_geometry,alkis_flaechenfuellung(o.wkb_geometry,d.positionierungsregel),st_centroid(o.wkb_geometry))) AS point,
	coalesce(p.drehwinkel,0) AS drehwinkel,
	coalesce(d.signaturnummer,p.signaturnummer,'3490') AS signaturnummer,
	coalesce(p.modelle, d.modelle, o.advstandardmodell||o.sonstigesmodell) AS modell
FROM po_lastrun, ax_fliessgewaesser o
LEFT OUTER JOIN po_ppo p ON o.gml_id=p.dientzurdarstellungvon AND p.art='FKT'
LEFT OUTER JOIN po_darstellung d ON o.gml_id=d.dientzurdarstellungvon AND d.art='FKT'
WHERE o.endet IS NULL AND funktion=8300 AND zustand=4000 AND greatest(o.beginnt, p.beginnt, d.beginnt)>lastrun;
