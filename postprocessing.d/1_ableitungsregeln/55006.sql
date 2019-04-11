SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Gleis (55006)
--

SELECT 'Gleise werden verarbeitet.';

-- Drehscheibe, Fläche
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	'Verkehr' AS thema,
	'ax_gleis' AS layer,
	st_multi(wkb_geometry) AS polygon,
	1541 AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ax_gleis o
WHERE geometrytype(wkb_geometry) IN ('POLYGON','MULTIPOLYGON') AND NOT bahnkategorie IS NULL AND o.art=1200 AND endet IS NULL;

-- Drehscheibe, Symbol
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	o.gml_id,
	'Verkehr' AS thema,
	'ax_gleis' AS layer,
	st_multi(coalesce(p.wkb_geometry,st_centroid(o.wkb_geometry))) AS point,
	coalesce(p.drehwinkel,0) AS drehwinkel,
	coalesce(p.signaturnummer,'3587') AS signaturnummer,
	coalesce(p.advstandardmodell||p.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM ax_gleis o
JOIN ap_ppo p ON ARRAY[o.gml_id] <@ p.dientzurdarstellungvon AND p.art='ART' AND p.endet IS NULL
WHERE o.endet IS NULL AND geometrytype(o.wkb_geometry) IN ('POLYGON','MULTIPOLYGON') AND NOT bahnkategorie IS NULL AND o.art=1200;

-- Gleis, Punktsignaturen auf Linien
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	gml_id,
	'Verkehr' AS thema,
	'ax_gleis' AS layer,
	st_multi( st_lineinterpolatepoint(line,o.offset) ) AS point,
	0.5*pi()-st_azimuth( st_lineinterpolatepoint(line,o.offset*0.9999), st_lineinterpolatepoint(line,CASE WHEN o.offset=0 THEN 0.001 WHEN o.offset*1.0001>1 THEN 1 ELSE o.offset*1.0001 END) ) AS drehwinkel,
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		line,
		generate_series(0,trunc(st_length(line)*1000.0)::int,
			CASE
			WHEN bahnkategorie && ARRAY[1201,1300,1302]      THEN 16000
			WHEN 1301 = ANY(bahnkategorie)                   THEN 8000
			WHEN 1600 = ANY(bahnkategorie)                   THEN 20000
			END
		) / 1000.0 / st_length(line) AS offset,
		CASE
		WHEN 1201 = ANY(bahnkategorie)         THEN 3646
		WHEN bahnkategorie && ARRAY[1300,1301] THEN 3647
		WHEN 1302 = ANY(bahnkategorie)         THEN 3648
		WHEN 1600 = ANY(bahnkategorie)         THEN 3649
		END AS signaturnummer,
		modell
	FROM (
		SELECT
			gml_id,
			(st_dump(st_multi(wkb_geometry))).geom AS line,
			bahnkategorie,
			advstandardmodell||sonstigesmodell AS modell
		FROM ax_gleis
		WHERE geometrytype(wkb_geometry) IN ('LINESTRING','MULTILINESTRING')
		  AND endet IS NULL
	) AS o
) AS o
WHERE NOT signaturnummer IS NULL;

-- Gleis, Linien
INSERT INTO po_lines(gml_id,thema,layer,line,signaturnummer,modell)
SELECT
	gml_id,
	'Verkehr' AS thema,
	'ax_gleis' AS layer,
	st_multi(line),
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		wkb_geometry AS line,
		CASE
		WHEN lagezuroberflaeche IS NULL THEN 2525
		WHEN lagezuroberflaeche=1200    THEN 2300
		WHEN lagezuroberflaeche=1400    THEN 2301
		END AS signaturnummer,
		advstandardmodell||sonstigesmodell AS modell
	FROM ax_gleis o
	WHERE geometrytype(wkb_geometry) IN ('LINESTRING','MULTILINESTRING') AND endet IS NULL
) AS o
WHERE NOT signaturnummer IS NULL;

-- Namen
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Verkehr' AS thema,
	'ax_gleis' AS layer,
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
	FROM ax_gleis o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='NAM' AND t.endet IS NULL
	LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='NAM' AND d.endet IS NULL
	WHERE o.endet IS NULL AND (NOT name IS NULL OR NOT t.schriftinhalt IS NULL)
) AS n WHERE NOT text IS NULL;
