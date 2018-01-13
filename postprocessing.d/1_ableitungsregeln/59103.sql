SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Bauwerk, Anlagen für Ver- und Entsorgen (59103; NRW)
--

SELECT 'Bauwerke und Anlagen für Ver- und Entsorgen (NRW) werden verarbeitet.';

-- Punkte
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	o.gml_id,
	'Verkehr' AS thema,
	'ks_bauwerkanlagenfuerverundentsorgung' AS layer,
	st_multi(wkb_geometry) AS point,
	0 AS drehwinkel,
	CASE
	WHEN art='1200' THEN 'KS_1007'
	WHEN art='1300' THEN 'KS_1008'
	WHEN art IN ('1400', '2100', '2200') THEN 'KS_1009'
	WHEN art='1500' THEN 'KS_1010'
	WHEN art IN ('3100', '3200', '3300', '3400') THEN 'KS_1011'
	END AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ks_bauwerkanlagenfuerverundentsorgung o
WHERE geometrytype(wkb_geometry) IN ('POINT','MULTIPOINT') AND endet IS NULL;

-- Linien
INSERT INTO po_lines(gml_id,thema,layer,line,signaturnummer,modell)
SELECT
	o.gml_id,
	'Verkehr' AS thema,
	'ks_bauwerkanlagenfuerverundentsorgung' AS layer,
	st_multi(wkb_geometry) AS point,
	'KS_2002' AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ks_bauwerkanlagenfuerverundentsorgung o
WHERE geometrytype(wkb_geometry) IN ('LINESTRING','MULTILINESTRING') AND endet IS NULL AND art='1100';

-- Flächen
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	o.gml_id,
	'Verkehr' AS thema,
	'ks_bauwerkanlagenfuerverundentsorgung' AS layer,
	st_multi(wkb_geometry) AS polygon,
	'KS_3001' AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ks_bauwerkanlagenfuerverundentsorgung o
WHERE geometrytype(wkb_geometry) IN ('POLYGON','MULTIPOLYGON') AND endet IS NULL AND art='1100';
