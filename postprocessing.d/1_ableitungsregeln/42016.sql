SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Schiffsverkehr (42016)
--

SELECT 'Schiffsverkehr wird verarbeitet.';

-- Schiffsverkehr, Fläche
INSERT INTO po_polygons(gml_id,gml_ids,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	ARRAY[gml_id] AS gml_id,
	'Verkehr' AS thema,
	'ax_schiffsverkehr' AS layer,
	st_multi(wkb_geometry) AS polygon,
	CASE WHEN zustand=4000 THEN 2516 ELSE 2515 END AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM po_lastrun, ax_schiffsverkehr
WHERE endet IS NULL AND beginnt>lastrun;

-- Schiffsverkehr, Name
INSERT INTO po_labels(gml_id,gml_ids,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	gml_ids,
	'Verkehr' AS thema,
	'ax_schiffsverkehr' AS layer,
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
			o.unverschluesselt,
			(SELECT bezeichnung FROM ax_lagebezeichnungkatalogeintrag WHERE schluesselgesamt=to_char(o.land::int,'fm00')||coalesce(o.regierungsbezirk,'0')||to_char(o.kreis::int,'fm00')||to_char(o.gemeinde::int,'fm000')||o.lage ORDER BY beginnt DESC LIMIT 1)
		) AS text,
		coalesce(d.signaturnummer,t.signaturnummer,'4141') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM po_lastrun, ax_schiffsverkehr o
	LEFT OUTER JOIN po_pto t ON o.gml_id=t.dientzurdarstellungvon AND t.art='NAM'
	LEFT OUTER JOIN po_darstellung d ON o.gml_id=d.dientzurdarstellungvon AND d.art='NAM'
	WHERE o.endet IS NULL AND greatest(o.beginnt, t.beginnt, d.beginnt)>lastrun
) AS n
WHERE text IS NOT NULL;

-- Hafenanlage (RP)
INSERT INTO po_labels(gml_id,gml_ids,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	gml_ids,
	'Verkehr' AS thema,
	'ax_schiffsverkehr' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel, horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung, modell
FROM (
	SELECT
		o.gml_id,
		ARRAY[o.gml_id, t.gml_id] AS gml_ids,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(
			t.schriftinhalt,
			CASE
			WHEN funktion=5610 THEN 'Hafenanlage'
			WHEN funktion IN (5630,5640) THEN
				(SELECT beschreibung FROM ax_funktion_schiffsverkehr WHERE wert=funktion)
			END
		) AS text,
		coalesce(t.signaturnummer,'4140') AS signaturnummer,
		drehwinkel, horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung,
		coalesce(t.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM po_lastrun, ax_schiffsverkehr o
	JOIN po_pto t ON o.gml_id=t.dientzurdarstellungvon AND t.art='FKT' AND t.gml_id<>'TRIGGER'
	WHERE o.endet IS NULL AND o.gml_id LIKE 'DERP%' AND greatest(o.beginnt, t.beginnt)>lastrun
) AS i WHERE NOT text IS NULL;
