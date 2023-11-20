SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Flugverkehr (42015)
--

SELECT 'Flugverkehr wird verarbeitet.';

-- Flugverkehr, Fläche
INSERT INTO po_polygons(gml_id,gml_ids,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	ARRAY[gml_id] AS gml_ids,
	'Verkehr' AS thema,
	'ax_flugverkehr' AS layer,
	st_multi(wkb_geometry) AS polygon,
	CASE
	WHEN zustand=4000 THEN 2516 ELSE 25151406 END AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM po_lastrun, ax_flugverkehr
WHERE endet IS NULL AND beginnt>lastrun;

-- Flugverkehr, Symbol
INSERT INTO po_points(gml_id,gml_ids,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	gml_id,
	gml_ids,
	'Verkehr' AS thema,
	'ax_flugverkehr' AS layer,
	st_multi(point),
	drehwinkel,
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		ARRAY[o.gml_id, p.gml_id, d.gml_id] AS gml_ids,
		coalesce(p.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(p.drehwinkel,0) AS drehwinkel,
		coalesce(
			d.signaturnummer,
			p.signaturnummer,
			CASE
			WHEN funktion=5530 THEN '3438'
			WHEN funktion=5550 THEN '3439'
			END
		) AS signaturnummer,
		coalesce(p.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM po_lastrun, ax_flugverkehr o
	LEFT OUTER JOIN po_ppo p ON o.gml_id=p.dientzurdarstellungvon AND p.art='ART'
	LEFT OUTER JOIN po_darstellung d ON o.gml_id=d.dientzurdarstellungvon AND d.art='ART'
	WHERE o.endet IS NULL AND greatest(o.beginnt, p.beginnt, d.beginnt)>lastrun
) AS o
WHERE NOT signaturnummer IS NULL;

-- Flugverkehr, Name
INSERT INTO po_labels(gml_id,gml_ids,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	gml_ids,
	'Verkehr' AS thema,
	'ax_flugverkehr' AS layer,
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
		coalesce(d.signaturnummer,t.signaturnummer,'4200') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM po_lastrun, ax_flugverkehr o
	LEFT OUTER JOIN po_pto t ON o.gml_id=t.dientzurdarstellungvon AND t.art='NAM'
	LEFT OUTER JOIN po_darstellung d ON o.gml_id=d.dientzurdarstellungvon AND d.art='NAM'
	WHERE o.endet IS NULL AND greatest(o.beginnt, t.beginnt, d.beginnt)>lastrun
) AS n
WHERE text IS NOT NULL;
