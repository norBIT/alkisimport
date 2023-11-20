SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Straßenverkehr (42001)
--

-- Straßenverkehr, Fläche
INSERT INTO po_polygons(gml_id,gml_ids,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	ARRAY[gml_id] AS gml_ids,
	'Verkehr' AS thema,
	'ax_strassenverkehr' AS layer,
	st_multi(wkb_geometry) AS polygon,
	CASE
	WHEN coalesce(zustand,0)<>4000 THEN 25150000
	ELSE 25160000
	END
	+
	CASE
	WHEN funktion IN (2312,2313) AND coalesce(zustand,0)<>4000 THEN 1406
	WHEN funktion=5130           AND coalesce(zustand,0)<>4000 THEN 1414
	ELSE 0
	END AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM po_lastrun, ax_strassenverkehr
WHERE endet IS NULL AND beginnt>lastrun;

-- Straßenverkehr, Funktion
INSERT INTO po_labels(gml_id,gml_ids,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	gml_ids,
	'Verkehr' AS thema,
	'ax_strassenverkehr' AS layer,
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
			(SELECT beschreibung FROM ax_funktion_strasse WHERE wert=funktion)
		) AS text,
		coalesce(d.signaturnummer,t.signaturnummer,'4100') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM po_lastrun, ax_strassenverkehr o
	LEFT OUTER JOIN po_pto t ON o.gml_id=t.dientzurdarstellungvon AND t.art='FKT'
	LEFT OUTER JOIN po_darstellung d ON o.gml_id=d.dientzurdarstellungvon AND d.art='FKT'
	WHERE  funktion=4130 AND o.endet IS NULL AND greatest(o.beginnt, t.beginnt, d.beginnt)>lastrun
) AS n WHERE NOT text IS NULL;

-- Straßenverkehr, Zweitname
INSERT INTO po_labels(gml_id,gml_ids,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	gml_ids,
	'Verkehr' AS thema,
	'ax_strassenverkehr' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		ARRAY[o.gml_id, t.gml_id, d.gml_id] AS gml_ids,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(t.schriftinhalt,o.zweitname) AS text,
		coalesce(d.signaturnummer,t.signaturnummer,'4141') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM po_lastrun, ax_strassenverkehr o
	LEFT OUTER JOIN po_pto t ON o.gml_id=t.dientzurdarstellungvon AND t.art='ZNM'
	LEFT OUTER JOIN po_darstellung d ON o.gml_id=d.dientzurdarstellungvon AND d.art='ZNM'
	WHERE o.endet IS NULL AND greatest(o.beginnt, t.beginnt, d.beginnt)>lastrun
) AS n WHERE NOT text IS NULL;
