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
	'ax_strukturlinie3d' AS layer,
	st_multi(st_force2d(wkb_geometry)) AS line,
	CASE
	WHEN art IN (1220,1230,1240) THEN 2531
	WHEN art=1210 THEN 2622
	END AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ax_strukturlinie3d WHERE art IN (1210,1220,1230,1240) AND endet IS NULL;
