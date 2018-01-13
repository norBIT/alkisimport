SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Schifffahrtslinie, Fährverkehr (57002)
--

SELECT 'Schifffahrtslinien werden verarbeitet.';

-- Linien
INSERT INTO po_lines(gml_id,thema,layer,line,signaturnummer,modell)
SELECT
	o.gml_id,
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
	coalesce(l.advstandardmodell||l.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM ax_schifffahrtsliniefaehrverkehr o
LEFT OUTER JOIN ap_lpo l ON ARRAY[o.gml_id] <@ l.dientzurdarstellungvon AND l.art='Schifffahrtslinie' AND l.endet IS NULL
LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='Schifffahrtslinie' AND d.endet IS NULL
WHERE o.endet IS NULL AND o.art IS NULL;

-- Texte
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Verkehr' AS thema,
	'ax_schifffahrtsliniefaehrverkehr' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
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
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_schifffahrtsliniefaehrverkehr o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='ART' AND t.endet IS NULL
	LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='ART' AND d.endet IS NULL
	WHERE o.endet IS NULL
) AS a WHERE NOT text IS NULL;

-- Namen
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Verkehr' AS thema,
	'ax_schifffahrtsliniefaehrverkehr' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(t.schriftinhalt,o.name) AS text,
		coalesce(d.signaturnummer,t.signaturnummer,'4107') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_schifffahrtsliniefaehrverkehr o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='NAM' AND t.endet IS NULL
	LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='NAM' AND d.endet IS NULL
	WHERE o.endet IS NULL AND (NOT name IS NULL OR NOT t.schriftinhalt IS NULL)
) AS n WHERE NOT text IS NULL;
