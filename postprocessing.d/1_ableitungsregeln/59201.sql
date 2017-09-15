SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Einrichtung im Straßenverkehr (59201; NRW)
--

SELECT 'Einrichtung im Straßenverkehr (NRW) werden bearbeitet.';

-- Punkte
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	o.gml_id,
	'Verkehr' AS thema,
	'ks_einrichtungimstrassenverkehr' AS layer,
	st_multi(wkb_geometry) AS point,
	0 AS drehwinkel,
	CASE
	WHEN art='4100' THEN 'KS_1013'
	ELSE 'KS_1001'
	END AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ks_einrichtungimstrassenverkehr o
WHERE geometrytype(wkb_geometry) IN ('POINT','MULTIPOINT') AND endet IS NULL;

-- Linien
INSERT INTO po_lines(gml_id,thema,layer,line,signaturnummer,modell)
SELECT
	o.gml_id,
	'Verkehr' AS thema,
	'ks_einrichtungimstrassenverkehr' AS layer,
	st_multi(wkb_geometry) AS line,
	CASE
	WHEN art='2200' THEN 'KS_2002'
	ELSE 'KS_2001'
	END AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ks_einrichtungimstrassenverkehr o
WHERE geometrytype(wkb_geometry) IN ('LINESTRING','MULTILINESTRING') AND endet IS NULL;

-- Flächen
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	o.gml_id,
	'Verkehr' AS thema,
	'ks_einrichtungimstrassenverkehr' AS layer,
	st_multi(wkb_geometry) AS polygon,
	'KS_3001' AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ks_einrichtungimstrassenverkehr o
WHERE geometrytype(wkb_geometry) IN ('POLYGON','MULTIPOLYGON') AND endet IS NULL;
