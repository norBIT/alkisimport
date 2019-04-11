SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Klassifizierungen nach Straßenrecht (71001)
--

SELECT 'Klassifizierungen nach Straßenrecht werden verarbeitet.';

INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	'Rechtliche Festlegungen' AS thema,
	'ax_klassifizierungnachstrassenrecht' AS layer,
	st_multi(wkb_geometry) AS polygon,
	CASE
	WHEN artderfestlegung IN (1110,1120) THEN 1701
	WHEN artderfestlegung=1130 THEN 1702
	END AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ax_klassifizierungnachstrassenrecht
WHERE artderfestlegung IN (1110,1120,1130)
  AND endet IS NULL
  AND geometrytype(wkb_geometry) IN ('POLYGON','MULTIPOLYGON');

INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Rechtliche Festlegungen' AS thema,
	'ax_klassifizierungnachstrassenrecht' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		t.wkb_geometry AS point,
		bezeichnung AS text,
		coalesce(t.signaturnummer,'4140') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_klassifizierungnachstrassenrecht o
	JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='BEZ' AND t.endet IS NULL
	WHERE o.endet IS NULL
) AS o
WHERE NOT text IS NULL;
