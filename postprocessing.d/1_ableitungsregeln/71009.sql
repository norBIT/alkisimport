SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Denkmalschutzrecht (71009; RP)
--

SELECT 'Denkmalschutzrecht wird verarbeitet.';

INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	'Rechtliche Festlegungen' AS thema,
	'ax_denkmalschutzrecht' AS layer,
	st_multi(wkb_geometry) AS polygon,
	'1704' AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ax_denkmalschutzrecht o
WHERE endet IS NULL AND gml_id LIKE 'DERP%' AND geometrytype(wkb_geometry) IN ('POLYGON', 'MULTIPOLYGON');

INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Rechtliche Festlegungen' AS thema,
	'ax_denkmalschutzrecht' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		t.wkb_geometry AS point,
		CASE
		WHEN artderfestlegung=2910 THEN 'DZ'
		WHEN artderfestlegung=2930 THEN 'GSG'
		END AS text,
		coalesce(t.signaturnummer,'RP4144') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_denkmalschutzrecht o
	JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='ADF' AND t.endet IS NULL
	WHERE o.endet IS NULL AND o.gml_id LIKE 'DERP%'
) AS o
WHERE NOT text IS NULL;
