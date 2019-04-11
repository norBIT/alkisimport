SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Bauwerk im Gewässerbereich (59207; NRW/HB)
--

SELECT 'Bauwerke im Gewässerbereich werden verarbeitet (NWDKOMK/HBDKOM).';

-- Punkte
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	o.gml_id,
	'Gewässer' AS thema,
	'ks_bauwerkimgewaesserbereich' AS layer,
	st_multi(wkb_geometry) AS point,
	0 AS drehwinkel,
	'KS_1022' AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ks_bauwerkimgewaesserbereich o
WHERE geometrytype(wkb_geometry) IN ('POINT','MULTIPOINT') AND endet IS NULL AND bauwerksfunktion=1200;

-- Linien
INSERT INTO po_lines(gml_id,thema,layer,line,signaturnummer,modell)
SELECT
	o.gml_id,
	'Gewässer' AS thema,
	'ks_bauwerkimgewaesserbereich' AS layer,
	st_multi(wkb_geometry) AS line,
	CASE
	WHEN bauwerksfunktion=1100 THEN 'KS_2001'
	WHEN bauwerksfunktion=1200 THEN 'KS_2002'
	END AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ks_bauwerkimgewaesserbereich o
WHERE geometrytype(wkb_geometry) IN ('LINESTRING','MULTILINESTRING') AND endet IS NULL AND bauwerksfunktion IN (1100,1200);
