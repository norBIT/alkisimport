SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Migrationsobjekt: Gebäudeausgestaltung (91001)
--

SELECT 'Migrationsobjekte werden verarbeitet.';

INSERT INTO po_lines(gml_id,gml_ids,thema,layer,line,signaturnummer,modell)
SELECT
	gml_id,
	ARRAY[gml_id] AS gml_ids,
	'Gebäude' AS thema,
	'ax_gebaeudeausgestaltung' AS layer,
	st_multi(wkb_geometry) AS line,
	CASE
	WHEN darstellung=1012 THEN 2030 -- öffentliches Gebäude
	WHEN darstellung=1013 THEN 2031 -- nicht öffentliches Gebäude
	WHEN darstellung=1014 THEN 2305 -- Offene Begrenzungslinie eines Gebäude
	END AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM po_lastrun, ax_gebaeudeausgestaltung
WHERE endet IS NULL AND darstellung IN (1012,1013,1014) AND beginnt>lastrun;

SELECT
	darstellung AS "Neue Migrationsobjekte ohne Signatur",
	count(*) AS "Anzahl"
FROM po_lastrun, ax_gebaeudeausgestaltung
WHERE NOT darstellung IN (1012,1013,1014) AND endet IS NOT NULL AND beginnt>lastrun
GROUP BY darstellung;
