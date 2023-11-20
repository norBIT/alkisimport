SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Klassifizierungen nach Natur-, Umwelt- oder Bodenschutzrecht (71006)
--

SELECT 'Klassifizierungen nach Natur-, Umwelt und Bodenschutzrecht werden verarbeitet.';

INSERT INTO po_polygons(gml_id,gml_ids,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	ARRAY[gml_id] AS gml_ids,
	'Rechtliche Festlegungen' AS thema,
	'ax_naturumweltoderbodenschutzrecht' AS layer,
	st_multi(wkb_geometry) AS polygon,
	CASE
	WHEN gml_id LIKE 'DERP%' THEN
		CASE
		WHEN artderfestlegung IN (1610,1612,1621,1622,1642,1653,1656) THEN 1703
		WHEN artderfestlegung IN (1632,1634,1641,1655,1662) THEN 1704
		END
	ELSE 1703
	END AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM po_lastrun, ax_naturumweltoderbodenschutzrecht
WHERE (artderfestlegung=1621 OR (gml_id LIKE 'DERP%' AND artderfestlegung IN (1610,1612,1621,1622,1632,1634,1641,1642,1653,1655,1656,1662))) AND endet IS NULL
  AND geometrytype(wkb_geometry) IN ('POLYGON','MULTIPOLYGON')
  AND beginnt>lastrun;

INSERT INTO po_labels(gml_id,gml_ids,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	gml_ids,
	'Rechtliche Festlegungen' AS thema,
	'ax_naturumweltoderbodenschutzrecht' AS layer,
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
		coalesce(t.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM po_lastrun, ax_naturumweltoderbodenschutzrecht o
	JOIN po_pto t ON o.gml_id=t.dientzurdarstellungvon AND t.art='ADF' AND t.gml_id<>'TRIGGER'
	WHERE (artderfestlegung=1621 OR (o.gml_id LIKE 'DERP%' AND artderfestlegung IN (1610,1612,1621,1622,1632,1634,1641,1642,1653,1655,1656,1662)))
	  AND o.endet IS NULL
	  AND greatest(o.beginnt, t.beginnt)>lastrun
) AS o
WHERE NOT text IS NULL;

-- Namen
INSERT INTO po_labels(gml_id,gml_ids,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	gml_ids,
	'Rechtliche Festlegungen' AS thema,
	'ax_naturumweltoderbodenschutzrecht' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		ARRAY[o.gml_id, t.gml_id, d.gml_id] AS gml_ids,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		'"' || coalesce(t.schriftinhalt,name) || '"' AS text,
		coalesce(d.signaturnummer,t.signaturnummer,'4143') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM po_lastrun, ax_naturumweltoderbodenschutzrecht o
	LEFT OUTER JOIN po_pto t ON o.gml_id=t.dientzurdarstellungvon AND t.art='NAM'
	LEFT OUTER JOIN po_darstellung d ON o.gml_id=d.dientzurdarstellungvon AND d.art='NAM'
	WHERE o.endet IS NULL AND (NOT name IS NULL OR NOT t.schriftinhalt IS NULL) AND greatest(o.beginnt, t.beginnt, d.beginnt)>lastrun
) AS n WHERE NOT text IS NULL;
