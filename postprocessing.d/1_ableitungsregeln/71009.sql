SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Denkmalschutzrecht (71009; RP)
--

SELECT 'Denkmalschutzrecht wird verarbeitet.';

INSERT INTO po_polygons(gml_id,gml_ids,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	ARRAY[gml_id] AS gml_ids,
	'Rechtliche Festlegungen' AS thema,
	'ax_denkmalschutzrecht' AS layer,
	st_multi(wkb_geometry) AS polygon,
	'1704' AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM po_lastrun, ax_denkmalschutzrecht o
WHERE endet IS NULL AND gml_id LIKE 'DERP%' AND geometrytype(wkb_geometry) IN ('POLYGON', 'MULTIPOLYGON') AND beginnt>lastrun;

INSERT INTO po_labels(gml_id,gml_ids,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	gml_ids,
	'Rechtliche Festlegungen' AS thema,
	'ax_denkmalschutzrecht' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		ARRAY[o.gml_id, t.gml_id] AS gml_ids,
		t.wkb_geometry AS point,
		CASE
		WHEN artderfestlegung=2910 THEN 'DZ'
		WHEN artderfestlegung=2930 THEN 'GSG'
		END AS text,
		coalesce(t.signaturnummer,'RP4144') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM po_lastrun, ax_denkmalschutzrecht o
	JOIN po_pto t ON o.gml_id=t.dientzurdarstellungvon AND t.art='ADF' AND t.gml_id<>'TRIGGER'
	WHERE o.endet IS NULL AND o.gml_id LIKE 'DERP%' AND greatest(o.beginnt, t.beginnt)>lastrun
) AS o
WHERE NOT text IS NULL;
