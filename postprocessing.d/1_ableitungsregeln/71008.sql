SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Bauraum- oder Bauordnungsrecht (71008)
--

SELECT 'Bauraum und Bauordnungsrecht wird verarbeitet.';

INSERT INTO po_polygons(gml_id,gml_ids,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	ARRAY[gml_id] AS gml_ids,
	'Rechtliche Festlegungen' AS thema,
	'ax_bauraumoderbodenordnungsrecht' AS layer,
	st_multi(wkb_geometry) AS polygon,
	1704 AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM po_lastrun, ax_bauraumoderbodenordnungsrecht o
WHERE endet IS NULL AND beginnt>lastrun;

INSERT INTO po_labels(gml_id,gml_ids,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	gml_ids,
	'Rechtliche Festlegungen' AS thema,
	'ax_bauraumoderbodenordnungsrecht' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		ARRAY[o.gml_id, t.gml_id, d.gml_id] AS gml_ids,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(
			t.schriftinhalt,
			CASE
			WHEN artderfestlegung=1750 THEN 'Umlegung'
			WHEN artderfestlegung=1840 THEN 'Sanierung'
			WHEN artderfestlegung IN (2100,2110,2120,2130,2140,2150) THEN 'Flurbereinigung'
			WHEN o.gml_id LIKE 'DERP%' THEN
				CASE
				WHEN artderfestlegung IN (1760,2610) THEN
					(SELECT beschreibung FROM ax_artderfestlegung_bauraumoderbodenordnungsrecht WHERE wert=artderfestlegung)
				WHEN artderfestlegung=1810 THEN 'Entwickungsbereich'
				END
			END
		) AS text,
		coalesce(
			d.signaturnummer,
			t.signaturnummer,
			CASE
			WHEN o.gml_id LIKE 'DERP%' AND artderfestlegung IN (1760,2610)
			THEN 'RP4075'
			ELSE '4144'
			END
		) AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM po_lastrun, ax_bauraumoderbodenordnungsrecht o
	LEFT OUTER JOIN po_pto t ON o.gml_id=t.dientzurdarstellungvon AND t.art='ADF'
	LEFT OUTER JOIN po_darstellung d ON o.gml_id=d.dientzurdarstellungvon AND d.art='ADF'
	WHERE o.endet IS NULL AND greatest(o.beginnt, t.beginnt, d.beginnt)>lastrun
) AS o
WHERE NOT text IS NULL;

-- Namen
INSERT INTO po_labels(gml_id,gml_ids,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	gml_ids,
	'Rechtliche Festlegungen' AS thema,
	'ax_bauraumoderbodenordnungsrecht' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		ARRAY[o.gml_id, t.gml_id, d.gml_id] AS gml_ids,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		CASE
		WHEN artderfestlegung=1750 THEN 'Umlegung'
		WHEN artderfestlegung=1840 THEN 'Sanierung'
		WHEN artderfestlegung IN (2100,2110,2120,2130,2140,2150) THEN 'Flurbereinigung'
		END
		|| ' "' || name || '"' AS text,
		coalesce(d.signaturnummer,t.signaturnummer,'4144') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM po_lastrun, ax_bauraumoderbodenordnungsrecht o
	LEFT OUTER JOIN po_pto t ON o.gml_id=t.dientzurdarstellungvon AND t.art='NAM'
	LEFT OUTER JOIN po_darstellung d ON o.gml_id=d.dientzurdarstellungvon AND d.art='NAM'
	WHERE o.endet IS NULL AND NOT name IS NULL AND artderfestlegung IN (1750,1840,2100,2110,2120,2130,2140,2150) AND greatest(o.beginnt, t.beginnt, d.beginnt)>lastrun
) AS n WHERE NOT text IS NULL;
