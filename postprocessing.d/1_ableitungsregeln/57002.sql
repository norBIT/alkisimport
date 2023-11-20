SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Schifffahrtslinie, Fährverkehr (57002)
--

SELECT 'Schifffahrtslinien werden verarbeitet.';

-- Linien
INSERT INTO po_lines(gml_id,gml_ids,thema,layer,line,signaturnummer,modell)
SELECT
	o.gml_id,
	ARRAY[o.gml_id, l.gml_id, d.gml_id] AS gml_ids,
	'Verkehr' AS thema,
	'ax_schifffahrtsliniefaehrverkehr' AS layer,
	st_multi(coalesce(l.wkb_geometry,o.wkb_geometry)) AS line,
	coalesce(
		d.signaturnummer,
		l.signaturnummer,
		CASE
		WHEN o.art=ARRAY[1740] THEN '2592'
		ELSE '2609'
		END
	) AS signaturnummer,
	coalesce(l.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM po_lastrun, ax_schifffahrtsliniefaehrverkehr o
LEFT OUTER JOIN po_lpo l ON o.gml_id=l.dientzurdarstellungvon AND l.art='Schifffahrtslinie'
LEFT OUTER JOIN po_darstellung d ON o.gml_id=d.dientzurdarstellungvon AND d.art='Schifffahrtslinie'
WHERE o.endet IS NULL AND o.art IS NULL AND greatest(o.beginnt, l.beginnt, d.beginnt)>lastrun;

-- Texte
INSERT INTO po_labels(gml_id,gml_ids,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	gml_ids,
	'Verkehr' AS thema,
	'ax_schifffahrtsliniefaehrverkehr' AS layer,
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
			WHEN o.art IN (ARRAY[1710], ARRAY[1710,1730]) THEN 'Autofähre'
			WHEN o.art=ARRAY[1710,1720]                   THEN 'Auto- und Eisenbahnfähre'
			WHEN o.art IN (ARRAY[1720], ARRAY[1720,1730]) THEN 'Eisenbahnfähre'
			WHEN o.art=ARRAY[1730]                        THEN 'Personenfähre'
			END
		) AS text,
		coalesce(d.signaturnummer,t.signaturnummer,'4103') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM po_lastrun, ax_schifffahrtsliniefaehrverkehr o
	LEFT OUTER JOIN po_pto t ON o.gml_id=t.dientzurdarstellungvon AND t.art='ART'
	LEFT OUTER JOIN po_darstellung d ON o.gml_id=d.dientzurdarstellungvon AND d.art='ART'
	WHERE o.endet IS NULL AND greatest(o.beginnt, t.beginnt, d.beginnt)>lastrun
) AS a WHERE NOT text IS NULL;

-- Namen
INSERT INTO po_labels(gml_id,gml_ids,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	gml_ids,
	'Verkehr' AS thema,
	'ax_schifffahrtsliniefaehrverkehr' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		ARRAY[o.gml_id, t.gml_id, d.gml_id] AS gml_ids,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(t.schriftinhalt,o.name) AS text,
		coalesce(d.signaturnummer,t.signaturnummer,'4107') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM po_lastrun, ax_schifffahrtsliniefaehrverkehr o
	LEFT OUTER JOIN po_pto t ON o.gml_id=t.dientzurdarstellungvon AND t.art='NAM'
	LEFT OUTER JOIN po_darstellung d ON o.gml_id=d.dientzurdarstellungvon AND d.art='NAM'
	WHERE o.endet IS NULL AND (NOT name IS NULL OR NOT t.schriftinhalt IS NULL) AND greatest(o.beginnt, t.beginnt, d.beginnt)>lastrun
) AS n WHERE NOT text IS NULL;
