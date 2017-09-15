SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Vegetationsmerkmal (59301; NRW)
--

SELECT 'Vegetationsmerkmale (NRW) werden bearbeitet.';

-- Punkte
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	o.gml_id,
	'Vegetation' AS thema,
	'ks_vegetationsmerkmal' AS layer,
	st_multi(wkb_geometry) AS point,
	0 AS drehwinkel,
	CASE
	WHEN bewuchs=1013 THEN 'KS_1023'
	WHEN bewuchs=2100 THEN 'KS_1024'
	WHEN bewuchs=2200 THEN 'KS_1025'
	END AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ks_vegetationsmerkmal o
WHERE geometrytype(wkb_geometry) IN ('POINT','MULTIPOINT') AND endet IS NULL AND bewuchs IN (1013,2100,2200);

-- Flächen
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	o.gml_id,
	'Vegetation' AS thema,
	'ks_vegetationsmerkmal' AS layer,
	st_multi(wkb_geometry) AS polygon,
	'KS_2001' AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ks_vegetationsmerkmal o
WHERE geometrytype(wkb_geometry) IN ('POLYGON','MULTIPOLYGON') AND endet IS NULL AND bewuchs IN (1100,3100);
