SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Geländekante (62040)
--

SELECT 'Geländekanten werden verarbeitet.';

INSERT INTO po_lines(gml_id,thema,layer,line,signaturnummer,modell)
SELECT
	gml_id,
	'Topographie' AS thema,
	'ax_gelaendekante' AS layer,
	st_multi(wkb_geometry) AS line,
	CASE
	WHEN artdergelaendekante IN (1220,1230) AND gml_id LIKE 'DENW%' THEN
		CASE erfassung_identifikation
		WHEN 5400 THEN 2531
		WHEN 5410 THEN 8223
		END
	WHEN artdergelaendekante IN (1220,1230,1240) THEN 2531
	WHEN artdergelaendekante=1210 THEN 2622
	END AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ax_gelaendekante WHERE artdergelaendekante IN (1210,1220,1230,1240) AND endet IS NULL;
