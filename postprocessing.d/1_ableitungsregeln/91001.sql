SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Migrationsobjekt: Gebäudeausgestaltung (91001)
--

SELECT 'Migrationsobjekte werden verarbeitet.';

INSERT INTO po_lines(gml_id,thema,layer,line,signaturnummer,modell)
SELECT
	gml_id,
	'Gebäude' AS thema,
	'ax_gebaeudeausgestaltung' AS layer,
	st_multi(wkb_geometry) AS line,
	CASE
	WHEN darstellung=1012 THEN 2030 -- öffentliches Gebäude
	WHEN darstellung=1013 THEN 2031 -- nicht öffentliches Gebäude
	WHEN darstellung=1014 THEN 2305 -- Offene Begrenzungslinie eines Gebäude
	END AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ax_gebaeudeausgestaltung
WHERE endet IS NULL AND darstellung IN (1012,1013,1014);

SELECT
	darstellung AS "Migrationsobjekte ohne Signatur",
	count(*) AS "Anzahl"
FROM ax_gebaeudeausgestaltung
WHERE NOT darstellung IN (1012,1013,1014)
GROUP BY darstellung;
