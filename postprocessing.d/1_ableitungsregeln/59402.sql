SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Kommunaler Besitz (59402; NRW)
--

SELECT 'Kommunaler Besitz wird verarbeitet (NWDKOMK).';

INSERT INTO po_lines(gml_id,thema,layer,line,signaturnummer,modell)
SELECT
	o.gml_id,
	'Flurstücke' AS thema,
	'ks_kommunalerbesitz' AS layer,
	st_multi(wkb_geometry) AS line,
	'KS_2001' AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ks_kommunalerbesitz o
WHERE geometrytype(wkb_geometry) IN ('LINESTRING','MULTILINESTRING') AND endet IS NULL;

-- Flächen
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	'Flurstücke' AS thema,
	'ks_kommunalerbesitz' AS layer,
	st_multi(wkb_geometry) AS polygon,
	'KS_3003' AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ks_kommunalerbesitz
WHERE geometrytype(wkb_geometry) IN ('POLYGON','MULTIPOLYGON') AND endet IS NULL;
