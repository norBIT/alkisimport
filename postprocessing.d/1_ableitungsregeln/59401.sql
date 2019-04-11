SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Bau-, Raum- oder Bodenordnungsrecht (59401; NRW)
--

SELECT 'Bau-, Raum- oder Bodenordnungsrecht wird verarbeitet (NWDKOMK).';

INSERT INTO po_lines(gml_id,thema,layer,line,signaturnummer,modell)
SELECT
	o.gml_id,
	'Rechtliche Festlegungen' AS thema,
	'ks_bauraumoderbodenordnungsrecht' AS layer,
	st_multi(wkb_geometry) AS line,
	'KS_2001' AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ks_bauraumoderbodenordnungsrecht o
WHERE geometrytype(wkb_geometry) IN ('LINESTRING','MULTILINESTRING') AND endet IS NULL;

-- Flächen
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	o.gml_id,
	'Rechtliche Festlegungen' AS thema,
	'ks_bauraumoderbodenordnungsrecht' AS layer,
	st_multi(wkb_geometry) AS polygon,
	'KS_3002' AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ks_bauraumoderbodenordnungsrecht o
WHERE geometrytype(wkb_geometry) IN ('POLYGON','MULTIPOLYGON') AND endet IS NULL;
