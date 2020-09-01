SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Besonderer Höhenpunkt (62090)
--

SELECT 'Besondere Höhenpunkte werden verarbeitet (BE).';

INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	gml_id,
	'Topographie' AS thema,
	'ax_besondererhoehenpunkt' AS layer,
	st_multi(wkb_geometry) AS point,
	0 AS drehwinkel,
	'BE3000' AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ax_besondererhoehenpunkt
WHERE endet IS NULL AND gml_id LIKE 'DEBE%';
