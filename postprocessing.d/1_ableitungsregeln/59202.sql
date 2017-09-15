SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Verkehrszeichen (59202; NRW)
--

SELECT 'Verkehrszeichen (NRW) werden bearbeitet.';

-- Punkte
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	o.gml_id,
	'Verkehr' AS thema,
	'ks_verkehrszeichen' AS layer,
	st_multi(wkb_geometry) AS point,
	0 AS drehwinkel,
	CASE
	WHEN gefahrzeichen IS NOT NULL OR vorschriftzeichen IS NOT NULL OR zusatzzeichen IS NOT NULL THEN 'KS_1015'
	WHEN 1200 = ANY(richtzeichen) THEN 'KS_1016'
	WHEN 1100 = ANY(verkehrseinrichtung) THEN 'KS_1017'
	WHEN ARRAY[1210,1220] && verkehrseinrichtung THEN 'KS_1018'
	WHEN 1400 = ANY(verkehrseinrichtung) THEN 'KS_1019'
	END AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ks_verkehrszeichen o
WHERE geometrytype(wkb_geometry) IN ('POINT','MULTIPOINT') AND endet IS NULL;

-- Linien
INSERT INTO po_lines(gml_id,thema,layer,line,signaturnummer,modell)
SELECT
	o.gml_id,
	'Verkehr' AS thema,
	'ks_verkehrszeichen' AS layer,
	st_multi(wkb_geometry) AS line,
	CASE
	WHEN 1111 = ANY(richtzeichen) THEN 'KS_2002'
	WHEN ARRAY[1110,1199] && verkehrseinrichtung THEN 'KS_2003'
	WHEN 1600 = ANY(verkehrseinrichtung) THEN 'KS_2004'
	ELSE 'KS_2001'
	END AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ks_verkehrszeichen o
WHERE geometrytype(wkb_geometry) IN ('LINESTRING','MULTILINESTRING') AND endet IS NULL;

-- Flächen
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	o.gml_id,
	'Verkehr' AS thema,
	'ks_verkehrszeichen' AS layer,
	st_multi(wkb_geometry) AS polygon,
	'KS_3001' AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ks_verkehrszeichen o
WHERE geometrytype(wkb_geometry) IN ('POLYGON','MULTIPOLYGON') AND endet IS NULL;
