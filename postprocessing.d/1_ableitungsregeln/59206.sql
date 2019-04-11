SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Einrichtung im Bahnverkehr (59206)
--

SELECT 'Einrichtungen im Bahnverkehr werden verarbeitet (NWDKOMK).';

-- Punkte
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	o.gml_id,
	'Verkehr' AS thema,
	'ks_einrichtungimbahnverkehr' AS layer,
	st_multi(wkb_geometry) AS point,
	0 AS drehwinkel,
	CASE
	WHEN art=1100 THEN 'KS_1012'
	WHEN art=1200 THEN 'KS_1020'
	END AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ks_einrichtungimbahnverkehr o
WHERE geometrytype(wkb_geometry) IN ('POINT','MULTIPOINT') AND endet IS NULL AND art IN (1100,1200);

-- Linien
INSERT INTO po_lines(gml_id,thema,layer,line,signaturnummer,modell)
SELECT
	o.gml_id,
	'Verkehr' AS thema,
	'ks_einrichtungimbahnverkehr' AS layer,
	st_multi(wkb_geometry) AS line,
	'KS_2001' AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ks_einrichtungimbahnverkehr o
WHERE geometrytype(wkb_geometry) IN ('LINESTRING','MULTILINESTRING') AND endet IS NULL AND art=1100;
