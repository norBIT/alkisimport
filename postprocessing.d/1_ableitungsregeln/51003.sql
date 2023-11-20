SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Vorratsbehälter, Speicherbauwerk (51003)
--

SELECT 'Vorratsbehälter, Speicherbauwerke werden verarbeitet.';

-- Vorratsbehälter, Speicherbauwerk, Flächen
INSERT INTO po_polygons(gml_id,gml_ids,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	ARRAY[gml_id] AS gml_ids,
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
	FROM po_lastrun, ax_vorratsbehaelterspeicherbauwerk
	WHERE geometrytype(wkb_geometry) IN ('POLYGON','MULTIPOLYGON') AND endet IS NULL AND beginnt>lastrun
) AS o;

-- Vorratsbehälter, Speicherbauwerk, Symbole
INSERT INTO po_points(gml_id,gml_ids,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	gml_id,
	gml_ids,
	'Industrie und Gewerbe' AS thema,
	'ax_vorratsbehaelterspeicherbauwerk' AS layer,
	point,
	drehwinkel,
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		ARRAY[o.gml_id, p.gml_id, d.gml_id] AS gml_ids,
		st_multi(coalesce(
			p.wkb_geometry,
			CASE
			WHEN geometrytype(o.wkb_geometry) IN ('POINT','MULTIPOINT')     THEN o.wkb_geometry
			WHEN geometrytype(o.wkb_geometry) IN ('POLYGON','MULTIPOLYGON') THEN st_centroid(o.wkb_geometry)
			END
		)) AS point,
		coalesce(p.drehwinkel,0) AS drehwinkel,
		coalesce(d.signaturnummer,p.signaturnummer,'3522') AS signaturnummer,
		coalesce(p.modelle, d.modelle, o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM po_lastrun, ax_vorratsbehaelterspeicherbauwerk o
	LEFT OUTER JOIN po_ppo p ON o.gml_id=p.dientzurdarstellungvon AND p.art='Vorratsbehaelter'
	LEFT OUTER JOIN po_darstellung d ON o.gml_id=d.dientzurdarstellungvon AND d.art='Vorratsbehaelter'
	WHERE o.endet IS NULL AND greatest(o.beginnt, p.beginnt, d.beginnt)>lastrun
) AS o;

-- Vorratsbehälter, Speicherbauwerk, Name
INSERT INTO po_labels(gml_id,gml_ids,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	gml_ids,
	'Industrie und Gewerbe' AS thema,
	'ax_vorratsbehaelterspeicherbauwerk' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		ARRAY[o.gml_id, t.gml_id, d.gml_id] AS gml_ids,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(t.schriftinhalt,name) AS text,
		coalesce(d.signaturnummer,t.signaturnummer,'4107') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM po_lastrun, ax_vorratsbehaelterspeicherbauwerk o
	LEFT OUTER JOIN po_pto t ON o.gml_id=t.dientzurdarstellungvon AND t.art='NAM'
	LEFT OUTER JOIN po_darstellung d ON o.gml_id=d.dientzurdarstellungvon AND d.art='NAM'
	WHERE o.endet IS NULL AND NOT name IS NULL AND greatest(o.beginnt, t.beginnt, d.beginnt)>lastrun
) AS n;
