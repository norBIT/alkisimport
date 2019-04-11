SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Sonstiges Bauwerk (59109)
--

SELECT 'Sonstige Bauwerke werden verarbeitet (NWDKOMK/HBDKOM).';

-- Punkte
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	o.gml_id,
	'Gebäude' AS thema,
	'ks_sonstigesbauwerk' AS layer,
	st_multi(wkb_geometry) AS point,
	0 AS drehwinkel,
	'KS_1012' AS signaturnummer,
	advstandardmodell||sonstigesmodell AS modell
FROM ks_sonstigesbauwerk o
WHERE geometrytype(wkb_geometry) IN ('POINT','MULTIPOINT') AND endet IS NULL AND bauwerksfunktion='4000';

-- Linien
INSERT INTO po_lines(gml_id,thema,layer,line,signaturnummer,modell)
SELECT
	o.gml_id,
	'Gebäude' AS thema,
	'ks_sonstigesbauwerk' AS layer,
	st_multi(wkb_geometry) AS point,
	'KS_2001' AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ks_sonstigesbauwerk o
WHERE geometrytype(wkb_geometry) IN ('LINESTRING','MULTILINESTRING') AND endet IS NULL AND bauwerksfunktion='3000';

-- Punktförmige Begleitsignaturen an Linien
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	gml_id,
	'Gebäude' AS thema,
	'ks_sonstigesbauwerk' AS layer,
	st_multi( st_lineinterpolatepoint(line,o.offset) ) AS point,
	winkel-st_azimuth( st_lineinterpolatepoint(line,o.offset*0.9999), st_lineinterpolatepoint(line,CASE WHEN o.offset=0 THEN 0.001 WHEN o.offset*1.0001>1 THEN 1 ELSE o.offset*1.0001 END) ) AS drehwinkel,
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		line,
		generate_series(1000, trunc(st_length(line)*1000.0)::int, 2000) / 1000.0 / st_length(line) AS offset,
		0.5*pi() AS winkel,
		'KS_1026' AS  signaturnummer,
		modell
	FROM (
		SELECT
			gml_id,
			(st_dump(st_multi(wkb_geometry))).geom AS line,
			advstandardmodell||sonstigesmodell AS modell
		FROM ks_sonstigesbauwerk
		WHERE geometrytype(wkb_geometry) IN ('LINESTRING','MULTILINESTRING') AND endet IS NULL AND bauwerksfunktion='3000'
	) AS o
	UNION
	SELECT
		o.gml_id,
		line,
		generate_series(2000, trunc(st_length(line)*1000.0)::int, 2000) / 1000.0 / st_length(line) AS offset,
		1.5*pi() AS winkel,
		'KS_1026' AS  signaturnummer,
		modell
	FROM (
		SELECT
			gml_id,
			(st_dump(st_multi(wkb_geometry))).geom AS line,
			advstandardmodell||sonstigesmodell AS modell
		FROM ks_sonstigesbauwerk
		WHERE geometrytype(wkb_geometry) IN ('LINESTRING','MULTILINESTRING') AND endet IS NULL AND bauwerksfunktion='3000'
	) AS o
) AS o
WHERE NOT signaturnummer IS NULL;

-- Flächen
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	o.gml_id,
	'Gebäude' AS thema,
	'ks_sonstigesbauwerk' AS layer,
	st_multi(wkb_geometry) AS polygon,
	'KS_2001' AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ks_sonstigesbauwerk o
WHERE geometrytype(wkb_geometry) IN ('POLYGON','MULTIPOLYGON') AND endet IS NULL AND bauwerksfunktion IN (1100, 5000);
