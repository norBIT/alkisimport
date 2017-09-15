SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Sonstiges Recht (71011)
--

SELECT 'Sonstiges Recht wird verarbeitet.';

INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	'Rechtliche Festlegungen' AS thema,
	'ax_sonstigesrecht' AS layer,
	st_multi(wkb_geometry) AS polygon,
	1704 AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ax_sonstigesrecht o
WHERE artderfestlegung=1740 AND endet IS NULL;

INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Rechtliche Festlegungen' AS thema,
	'ax_sonstigesrecht' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		CASE
		WHEN o.gml_id LIKE 'DERP%' THEN
			coalesce(
				t.schriftinhalt,
				CASE
				WHEN artderfestlegung=4720 THEN 'MÜG'
				WHEN artderfestlegung=7000 THEN 'WLG'
				WHEN artderfestlegung=7100 THEN 'STL'
				WHEN artderfestlegung=7300 THEN 'SSL'
				END
			)
		ELSE 'Truppenübungsplatz'::text
		END AS text,
		coalesce(d.signaturnummer,t.signaturnummer,'4144') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_sonstigesrecht o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='ART' AND t.endet IS NULL
	LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='ART' AND d.endet IS NULL
	WHERE o.endet IS NULL AND (NOT name IS NULL AND artderfestlegung=4720)
) AS n WHERE NOT text IS NULL;

-- Namen
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Rechtliche Festlegungen' AS thema,
	'ax_sonstigesrecht' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		'Truppenübungsplatz "' || name || '"' AS text,
		coalesce(d.signaturnummer,t.signaturnummer,'4144') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_sonstigesrecht o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='NAM' AND t.endet IS NULL
	LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='NAM' AND d.endet IS NULL
	WHERE o.endet IS NULL AND (NOT name IS NULL AND artderfestlegung=4720)
) AS n WHERE NOT text IS NULL;
