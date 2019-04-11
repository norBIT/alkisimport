SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Straßenverkehrsanlage (53002)
--

SELECT 'Straßenverkehrsanlagen werden verarbeitet (HBDKOM).';


-- Linien
INSERT INTO po_lines(gml_id,thema,layer,line,signaturnummer,modell)
SELECT
	o.gml_id,
	'Verkehr' AS thema,
	'ks_strassenverkehrsanlage' AS layer,
	st_multi(wkb_geometry),
	2527 AS signaturnummer,
	advstandardmodell||sonstigesmodell AS modell
FROM ks_strassenverkehrsanlage o
WHERE geometrytype(wkb_geometry) IN ('LINESTRING','MULTILINESTRING')
  AND endet IS NULL
  AND o.art=1010
  AND 'HBDKOM' = ANY(sonstigesmodell);
