SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Klassifizierungen nach Natur-, Umwelt- oder Bodenschutzrecht (71006)
--

SELECT 'Klassifizierungen nach Natur-, Umwelt und Bodenschutzrecht werden verarbeitet.';

INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	o.gml_id,
	'Rechtliche Festlegungen' AS thema,
	'ax_naturumweltoderbodenschutzrecht' AS layer,
	st_multi(wkb_geometry) AS polygon,
	CASE
	WHEN o.gml_id LIKE 'DERP%' THEN
		CASE
		WHEN artderfestlegung IN (1610,1612,1621,1622,1642,1653,1656) THEN 1703
		WHEN artderfestlegung IN (1632,1634,1641,1655,1662) THEN 1704
		END
	ELSE 1703
	END AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ax_naturumweltoderbodenschutzrecht o
WHERE (artderfestlegung=1621 OR (o.gml_id LIKE 'DERP%' AND artderfestlegung IN (1610,1612,1621,1622,1632,1634,1641,1642,1653,1655,1656,1662))) AND endet IS NULL
  AND geometrytype(wkb_geometry) IN ('POLYGON','MULTIPOLYGON');

INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Rechtliche Festlegungen' AS thema,
	'ax_naturumweltoderbodenschutzrecht' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		t.wkb_geometry AS point,
		CASE
		WHEN o.gml_id LIKE 'DERP%' THEN
			coalesce(
				t.schriftinhalt,
				CASE
				WHEN artderfestlegung=1610 THEN 'Schutzfläche'
				WHEN artderfestlegung=1656 THEN 'Ausgleichsfläche'
				WHEN artderfestlegung IN (1612,1621,1622,1632,1634,1641,1642,1653,1655,1662) THEN
					(SELECT beschreibung FROM ax_artderfestlegung_naturumweltoderbodenschutzrecht WHERE wert=artderfestlegung)
				END
			)
		ELSE
			(SELECT beschreibung FROM ax_artderfestlegung_naturumweltoderbodenschutzrecht WHERE wert=artderfestlegung)
		END AS text,
		coalesce(
			t.signaturnummer,
			CASE
			WHEN o.gml_id LIKE 'DERP%' THEN
				CASE
				WHEN artderfestlegung IN (1610,1612,1621,1622,1642) THEN '4143'
				WHEN artderfestlegung IN (1632,1634,1641) THEN '4144'
				WHEN artderfestlegung IN (1655,1662) THEN 'RP4075'
				WHEN artderfestlegung=1656 THEN 'RP4076'
				END
			ELSE '4143'
			END
		) AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_naturumweltoderbodenschutzrecht o
	JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='ADF' AND t.endet IS NULL
	WHERE (artderfestlegung=1621 OR (o.gml_id LIKE 'DERP%' AND artderfestlegung IN (1610,1612,1621,1622,1632,1634,1641,1642,1653,1655,1656,1662))) AND o.endet IS NULL
) AS o
WHERE NOT text IS NULL;

-- Namen
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Rechtliche Festlegungen' AS thema,
	'ax_naturumweltoderbodenschutzrecht' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		'"' || coalesce(t.schriftinhalt,name) || '"' AS text,
		coalesce(d.signaturnummer,t.signaturnummer,'4143') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_naturumweltoderbodenschutzrecht o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='NAM' AND t.endet IS NULL
	LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='NAM' AND d.endet IS NULL
	WHERE o.endet IS NULL AND (NOT name IS NULL OR NOT t.schriftinhalt IS NULL)
) AS n WHERE NOT text IS NULL;
