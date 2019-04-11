SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Einrichtungen im öffentlichen Bereichen (59102; NRW)
--

SELECT 'Einrichtungen im öffentlichen Bereichen werden verarbeitet (NWDKOMK/HBDKOM).';

-- Punkte
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	o.gml_id,
	'Verkehr' AS thema,
	'ks_einrichtunginoeffentlichenbereichen' AS layer,
	st_multi(wkb_geometry) AS point,
	0 AS drehwinkel,
	CASE
	WHEN art='1100' THEN 'KS_1014'
	WHEN art='1200' THEN 'KS_1002'
	WHEN art='1300' THEN 'KS_1003'
	WHEN art='1400' THEN 'KS_1004'
	WHEN art='1500' THEN 'KS_1005'
	WHEN art='1600' THEN 'KS_1006'
	WHEN art='1700' THEN 'KS_1027'
	ELSE 'KS_1001'
	END AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ks_einrichtunginoeffentlichenbereichen o
WHERE geometrytype(wkb_geometry) IN ('POINT','MULTIPOINT') AND endet IS NULL;

-- Linien
INSERT INTO po_lines(gml_id,thema,layer,line,signaturnummer,modell)
SELECT
	o.gml_id,
	'Verkehr' AS thema,
	'ks_einrichtunginoeffentlichenbereichen' AS layer,
	st_multi(wkb_geometry) AS point,
	'KS_2001' AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ks_einrichtunginoeffentlichenbereichen o
WHERE geometrytype(wkb_geometry) IN ('LINESTRING','MULTILINESTRING') AND endet IS NULL;

INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	gml_id,
	'Verkehr' AS thema,
	'ks_einrichtunginoeffentlichenbereichen' AS layer,
	st_multi( st_lineinterpolatepoint(line,o.offset) ) AS point,
	0.5*pi()-st_azimuth( st_lineinterpolatepoint(line,o.offset*0.9999), st_lineinterpolatepoint(line,CASE WHEN o.offset=0 THEN 0.001 WHEN o.offset*1.0001>1 THEN 1 ELSE o.offset*1.0001 END) ) AS drehwinkel,
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		o.line AS line,
		generate_series(125,trunc(st_length(o.line)*1000.0-125)::int,250) / 1000.0 / st_length(o.line) AS offset,
		'KS_1003' AS signaturnummer,
		modell
	FROM (
		SELECT
			gml_id,
			(st_dump(st_multi(wkb_geometry))).geom AS line,
			advstandardmodell||sonstigesmodell AS modell
		FROM ks_einrichtunginoeffentlichenbereichen
		WHERE geometrytype(wkb_geometry) IN ('LINESTRING','MULTILINESTRING') AND endet IS NULL AND art='1300'
	) AS o
) AS o
WHERE NOT signaturnummer IS NULL;


-- Flächen
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	o.gml_id,
	'Verkehr' AS thema,
	'ks_einrichtunginoeffentlichenbereichen' AS layer,
	st_multi(wkb_geometry) AS polygon,
	'KS_3001' AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ks_einrichtunginoeffentlichenbereichen o
WHERE geometrytype(wkb_geometry) IN ('POLYGON','MULTIPOLYGON') AND endet IS NULL;
