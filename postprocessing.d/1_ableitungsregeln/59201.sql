SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Einrichtung im Straßenverkehr (59201; NRW)
--

SELECT 'Einrichtung im Straßenverkehr werden verarbeitet (NWDKOMK/HBDKOM).';

-- Punkte (Radarkontrollgerät)
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	gml_id,
	'Verkehr' AS thema,
	'ks_einrichtungimstrassenverkehr' AS layer,
	st_multi(wkb_geometry) AS point,
	drehwinkel,
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		wkb_geometry,
		0 AS drehwinkel,
		CASE
		WHEN 'HBDKOM' = ANY(sonstigesmodell) THEN
			CASE
			WHEN o.art=4100 THEN '3570'
			END
		WHEN 'NWDKOMK' = ANY(sonstigesmodell) THEN
			CASE
			WHEN o.art=4100 THEN 'KS_1013'
			ELSE 'KS_1001'
			END
		END AS signaturnummer,
		advstandardmodell||sonstigesmodell AS modell
	FROM ks_einrichtungimstrassenverkehr o
	WHERE geometrytype(wkb_geometry) IN ('POINT','MULTIPOINT')
          AND endet IS NULL
) AS o
WHERE signaturnummer IS NOT NULL;

-- Linien (Rinne)
INSERT INTO po_lines(gml_id,thema,layer,line,signaturnummer,modell)
SELECT
	gml_id,
	'Verkehr' AS thema,
	'ks_einrichtungimstrassenverkehr' AS layer,
	line,
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		st_multi(wkb_geometry) AS line,
		CASE
		WHEN 'HBDKOM' = ANY(sonstigesmodell) THEN
			CASE
			WHEN o.art='2100' THEN '2527'
			WHEN o.art='2200' THEN '2512'
			WHEN o.art IN ('3100','3120','3140') THEN '2535'
			END
		WHEN 'NWDKOMK' = ANY(sonstigesmodell) THEN
			CASE
			WHEN o.art='2200' THEN 'KS_2002'
			ELSE 'KS_2001'
			END
		END AS signaturnummer,
		advstandardmodell||sonstigesmodell AS modell
	FROM ks_einrichtungimstrassenverkehr o
	WHERE geometrytype(wkb_geometry) IN ('LINESTRING','MULTILINESTRING') AND endet IS NULL
) AS o
WHERE signaturnummer IS NOT NULL;

-- Flächen
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	'Verkehr' AS thema,
	'ks_einrichtungimstrassenverkehr' AS layer,
	st_multi(polygon) AS polygon,
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		wkb_geometry AS polygon,
		CASE
		WHEN 'HBDKOM' = ANY(sonstigesmodell) THEN
			CASE
			WHEN o.art IN (1100,3500) THEN '2527'
			END
		WHEN 'NWDKOMK' = ANY(sonstigesmodell) THEN
			'KS_3001'
		END AS signaturnummer,
		advstandardmodell||sonstigesmodell AS modell
	FROM ks_einrichtungimstrassenverkehr o
	WHERE geometrytype(wkb_geometry) IN ('POLYGON','MULTIPOLYGON')
	  AND endet IS NULL
) AS o
WHERE signaturnummer IS NOT NULL;
