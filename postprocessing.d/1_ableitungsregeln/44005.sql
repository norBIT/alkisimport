SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Hafenbecken (44005)
--

SELECT 'Hafenbecken werden verarbeitet.';

-- Hafenbecken, Flächen
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	'Gewässer' AS thema,
	'ax_hafenbecken' AS layer,
	st_multi(wkb_geometry) AS polygon,
	25181410 AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ax_hafenbecken
WHERE endet IS NULL;

-- Hafenbecken, Symbol
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	o.gml_id,
	'Gewässer' AS thema,
	'ax_hafenbecken' AS layer,
	st_multi(coalesce(p.wkb_geometry,st_centroid(o.wkb_geometry))) AS point,
	coalesce(p.drehwinkel,0) AS drehwinkel,
	coalesce(d.signaturnummer,p.signaturnummer,'3490') AS signaturnummer,
	coalesce(p.advstandardmodell||p.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM ax_hafenbecken o
LEFT OUTER JOIN ap_ppo p ON ARRAY[o.gml_id] <@ p.dientzurdarstellungvon AND p.art='FKT' AND p.endet IS NULL
LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='FKT' AND d.endet IS NULL
WHERE o.endet IS NULL;

-- Hafenbecken, Namen
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Gewässer' AS thema,
	'ax_hafenbecken' AS layer,
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
			o.unverschluesselt,
			(SELECT bezeichnung FROM ax_lagebezeichnungkatalogeintrag WHERE schluesselgesamt=to_char(o.land::int,'fm00')||coalesce(o.regierungsbezirk,'0')||to_char(o.kreis::int,'fm00')||to_char(o.gemeinde::int,'fm000')||o.lage ORDER BY beginnt DESC LIMIT 1)
		) AS text,
		coalesce(d.signaturnummer,t.signaturnummer,'4211') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_hafenbecken o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='NAM' AND t.endet IS NULL
	LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='NAM' AND d.endet IS NULL
	WHERE o.endet IS NULL
) AS n
WHERE text IS NOT NULL;
