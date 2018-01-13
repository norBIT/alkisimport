SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Vorratsbehälter, Speicherbauwerk (51003)
--

SELECT 'Vorratsbehälter, Speicherbauwerke werden verarbeitet.';

-- Vorratsbehälter, Speicherbauwerk, Flächen
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	'Industrie und Gewerbe' AS thema,
	'ax_vorratsbehaelterspeicherbauwerk' AS layer,
	polygon,
	signaturnummer,
	modell
FROM (
	SELECT
		gml_id,
		st_multi(wkb_geometry) AS polygon,
		CASE
		WHEN lagezurerdoberflaeche IS NULL THEN 1305
		WHEN lagezurerdoberflaeche=1200    THEN 1321
		WHEN lagezurerdoberflaeche=1400    THEN 20311304
		END AS signaturnummer,
		advstandardmodell||sonstigesmodell AS modell
	FROM ax_vorratsbehaelterspeicherbauwerk
	WHERE geometrytype(wkb_geometry) IN ('POLYGON','MULTIPOLYGON')
) AS o;

-- Vorratsbehälter, Speicherbauwerk, Symbole
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	gml_id,
	'Industrie und Gewerbe' AS thema,
	'ax_vorratsbehaelterspeicherbauwerk' AS layer,
	point,
	drehwinkel,
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		st_multi(coalesce(
			p.wkb_geometry,
			CASE
			WHEN geometrytype(o.wkb_geometry) IN ('POINT','MULTIPOINT')     THEN o.wkb_geometry
			WHEN geometrytype(o.wkb_geometry) IN ('POLYGON','MULTIPOLYGON') THEN st_centroid(o.wkb_geometry)
			END
		)) AS point,
		coalesce(p.drehwinkel,0) AS drehwinkel,
		coalesce(d.signaturnummer,p.signaturnummer,'3522') AS signaturnummer,
		coalesce(
			p.advstandardmodell||p.sonstigesmodell||d.advstandardmodell||d.sonstigesmodell,
			o.advstandardmodell||o.sonstigesmodell
		) AS modell
	FROM ax_vorratsbehaelterspeicherbauwerk o
	LEFT OUTER JOIN ap_ppo p ON ARRAY[o.gml_id] <@ p.dientzurdarstellungvon AND p.art='Vorratsbehaelter' AND p.endet IS NULL
	LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='Vorratsbehaelter' AND d.endet IS NULL
	WHERE o.endet IS NULL
) AS o;

-- Vorratsbehälter, Speicherbauwerk, Name
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Industrie und Gewerbe' AS thema,
	'ax_vorratsbehaelterspeicherbauwerk' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(t.schriftinhalt,name) AS text,
		coalesce(d.signaturnummer,t.signaturnummer,'4107') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_vorratsbehaelterspeicherbauwerk o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='NAM' AND t.endet IS NULL
	LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='NAM' AND d.endet IS NULL
	WHERE o.endet IS NULL AND NOT name IS NULL
) AS n;
