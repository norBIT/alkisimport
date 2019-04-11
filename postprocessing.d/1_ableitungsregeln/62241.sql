SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Topographische Ausprägung (62241; HBDKOM)
--

SELECT 'Topographische Ausprägungen werden verarbeitet (HBDKOM).';

-- Linien
INSERT INTO po_lines(gml_id,thema,layer,line,signaturnummer,modell)
SELECT
	o.gml_id,
	'Topographie' AS thema,
	'ks_topographischeauspraegung' AS layer,
	st_multi(wkb_geometry) AS line,
	2506 AS signaturnummer,
	advstandardmodell||sonstigesmodell AS modell
FROM ks_topographischeauspraegung o
WHERE geometrytype(o.wkb_geometry) IN ('LINESTRING','MULTILINESTRING')
  AND endet IS NULL
  AND 'HBDKOM' = ANY(sonstigesmodell)
  AND objektart='9000';
