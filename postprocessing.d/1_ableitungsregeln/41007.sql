SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Fläche besonderer funktionaler Prägung (41007)
--

SELECT 'Flächen besonderer funktionaler Prägung werden verarbeitet.';

-- Fläche besonderer funktionaler Prägung
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	'Industrie und Gewerbe' AS thema,
	'ax_flaechebesondererfunktionalerpraegung' AS layer,
	st_multi(wkb_geometry) AS polygon,
	25151401 AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ax_flaechebesondererfunktionalerpraegung
WHERE endet IS NULL;

-- Name, Fläche besonderer funktionaler Prägung
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Industrie und Gewerbe' AS thema,
	'ax_flaechebesondererfunktionalerpraegung' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel, horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung, modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(t.schriftinhalt,o.name) AS text,
		coalesce(d.signaturnummer,t.signaturnummer,'4141') AS signaturnummer,
		drehwinkel, horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_flaechebesondererfunktionalerpraegung o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='NAM' AND t.endet IS NULL
	LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='NAM' AND d.endet IS NULL
	WHERE o.endet IS NULL
) AS o
WHERE NOT text IS NULL;

-- Historische Anlagen (RP)
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Industrie und Gewerbe' AS thema,
	'ax_flaechebesondererfunktionalerpraegung' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel, horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung, modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(
			t.schriftinhalt,
			(SELECT beschreibung FROM ax_funktion_flaechebesondererfunktionalerpraegung WHERE wert=funktion)
		) AS text,
		coalesce(t.signaturnummer,'4070') AS signaturnummer,
		drehwinkel, horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_industrieundgewerbeflaeche o
	JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='FKT' AND t.endet IS NULL
	WHERE o.endet IS NULL AND funktion=1300 AND o.gml_id LIKE 'DERP%'
) AS i WHERE NOT text IS NULL;
