SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Vegetationsmerkmale (54001)
--

SELECT 'Vegetationsmerkmale werden verarbeitet.';

-- Punkte
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	gml_id,
	'Vegetation' AS thema,
	'ax_vegetationsmerkmal' AS layer,
	st_multi(point),
	drehwinkel,
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		wkb_geometry AS point,
		0 AS drehwinkel,
		CASE
		WHEN bewuchs=1011 THEN 3597
		WHEN bewuchs=1012 THEN 3599
		WHEN bewuchs=1400 THEN 3603
		WHEN bewuchs=1700 THEN 3607
		END AS signaturnummer,
		advstandardmodell||sonstigesmodell AS modell
	FROM ax_vegetationsmerkmal o
	WHERE geometrytype(o.wkb_geometry) IN ('POINT','MULTIPOINT') AND endet IS NULL
) AS o WHERE NOT signaturnummer IS NULL;

-- Punktförmige Begleitsignaturen an Linien
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	gml_id,
	'Vegetation' AS thema,
	'ax_vegetationsmerkmal' AS layer,
	st_multi(st_collect(st_lineinterpolatepoint(line,CASE WHEN a.offset<0 THEN 0 WHEN a.offset>1 THEN 1 ELSE a.offset END))) AS point,
	0 AS drehwinkel,
	signaturnummer,
	modell
FROM (
	SELECT
		gml_id,
		signaturnummer,
		line,
		generate_series(einzug,trunc(st_length(line)*1000.0)::int,abstand)/100.0/st_length(line) AS offset,
		modell
	FROM (
		SELECT
			gml_id,
			bewuchs,
			einzug,
			abstand,
			CASE geometrytype(line) WHEN 'MULTILINESTRING' THEN (st_dump(line)).geom ELSE line END AS line,
			signaturnummer,
			modell
		FROM (
			SELECT
				gml_id,
				bewuchs,
				CASE
				WHEN bewuchs IN (1100,1230,1260) THEN 0
				WHEN bewuchs IN (1101,1102) THEN 300
				WHEN bewuchs=1103 THEN unnest(ARRAY[300,600])
				WHEN bewuchs IN (1210,1220) THEN 186
				WHEN bewuchs=1230 THEN unnest(ARRAY[1000,2000])
				END AS einzug,
				CASE
				WHEN bewuchs IN (1100,1101,1102,1210,1220,1260) THEN 600
				WHEN bewuchs=1103 THEN unnest(ARRAY[1200,1200])
				WHEN bewuchs=1210 THEN 1000
				WHEN bewuchs=1230 THEN unnest(ARRAY[2000,2000])
				END AS abstand,
				CASE
				WHEN bewuchs IN (1100,1210,1220,1260) THEN wkb_geometry
				WHEN bewuchs=1101 THEN st_reverse(alkis_safe_offsetcurve(wkb_geometry,-0.11,''::text))
				WHEN bewuchs=1102 THEN alkis_safe_offsetcurve(wkb_geometry,0.11,''::text)
				WHEN bewuchs=1103 THEN
					unnest(ARRAY[
						st_reverse(alkis_safe_offsetcurve(wkb_geometry,-0.11,''::text)),
						alkis_safe_offsetcurve(wkb_geometry,0.11,'')
					])
				WHEN bewuchs=1230 THEN
					unnest(ARRAY[
						wkb_geometry,
						wkb_geometry
					])
				END AS line,
				CASE
				WHEN bewuchs IN (1100,1101,1102,1103) THEN 3601
				WHEN bewuchs=1210 THEN 3458
				WHEN bewuchs=1220 THEN 3460
				WHEN bewuchs=1230 THEN unnest(ARRAY[3458,3460])
				WHEN bewuchs=1260 THEN 3601
				WHEN bewuchs=1700 THEN 3607
				END AS signaturnummer,
				advstandardmodell||sonstigesmodell AS modell
			FROM ax_vegetationsmerkmal o
			WHERE o.endet IS NULL
			AND geometrytype(o.wkb_geometry) IN ('LINESTRING','MULTILINESTRING')
		) AS a
	) AS a
) AS a
GROUP BY gml_id,signaturnummer,modell;

-- Flächen
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	'Vegetation' AS thema,
	'ax_vegetationsmerkmal' AS layer,
	polygon,
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		st_multi(wkb_geometry) AS polygon,
		CASE
		WHEN bewuchs IN (1021,1022,1023,1050,1260,1400,1500,1510,1600,1700,1800) THEN 1560
		WHEN bewuchs=1300                                                        THEN 1561
		END AS signaturnummer,
		advstandardmodell||sonstigesmodell AS modell
	FROM ax_vegetationsmerkmal o
	WHERE geometrytype(o.wkb_geometry) IN ('POLYGON','MULTIPOLYGON') AND endet IS NULL
) AS o WHERE NOT signaturnummer IS NULL;

-- Flächensymbole
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	gml_id,
	'Vegetation' AS thema,
	'ax_vegetationsmerkmal' AS layer,
	st_multi(point),
	0 AS drehwinkel,
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		coalesce(p.wkb_geometry,alkis_flaechenfuellung(o.wkb_geometry,d.positionierungsregel),st_centroid(o.wkb_geometry)) AS point,
		coalesce(p.drehwinkel,0) AS drehwinkel,
		coalesce(
			d.signaturnummer,
			p.signaturnummer,
			CASE
			WHEN bewuchs=1021           THEN '3458'
			WHEN bewuchs=1022           THEN '3460'
			WHEN bewuchs=1023           THEN '3462'
			WHEN bewuchs=1050           THEN '3470'
			WHEN bewuchs=1260           THEN '3601'
			WHEN bewuchs=1400           THEN '3603'
			WHEN bewuchs IN (1500,1510) THEN '3413'
			WHEN bewuchs=1600           THEN '3605'
			WHEN bewuchs=1700           THEN '3607'
			WHEN bewuchs=1800           THEN '3609'
			END
		) AS signaturnummer,
		coalesce(
			p.advstandardmodell||p.sonstigesmodell||d.advstandardmodell||d.sonstigesmodell,
			o.advstandardmodell||o.sonstigesmodell
		) AS modell
	FROM ax_vegetationsmerkmal o
	LEFT OUTER JOIN ap_ppo p ON ARRAY[o.gml_id] <@ p.dientzurdarstellungvon AND p.art='BWS' AND p.endet IS NULL
	LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='BWS' AND d.endet IS NULL
	WHERE o.endet IS NULL AND geometrytype(o.wkb_geometry) IN ('POLYGON','MULTIPOLYGON')
) AS o WHERE NOT signaturnummer IS NULL;

-- Zustand nass, Flächen
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	o.gml_id,
	'Vegetation' AS thema,
	'ax_vegetationsmerkmal' AS layer,
	st_multi(wkb_geometry) AS polygon,
	1563 AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ax_vegetationsmerkmal o
WHERE geometrytype(o.wkb_geometry) IN ('POLYGON','MULTIPOLYGON') AND zustand=5000;

-- Zustand nass, Symbol
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	o.gml_id,
	'Vegetation' AS thema,
	'ax_vegetationsmerkmal' AS layer,
	st_multi(coalesce(p.wkb_geometry,st_centroid(o.wkb_geometry))) AS point,
	coalesce(p.drehwinkel,0) AS drehwinkel,
	coalesce(p.signaturnummer,'3478') AS signaturnummer,
	coalesce(p.advstandardmodell||p.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM ax_vegetationsmerkmal o
JOIN ap_ppo p ON ARRAY[o.gml_id] <@ p.dientzurdarstellungvon AND p.art='ZUS' AND p.endet IS NULL
WHERE o.endet IS NULL AND geometrytype(o.wkb_geometry) IN ('POLYGON','MULTIPOLYGON') AND zustand=5000;

-- Schneise, Text
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	o.gml_id,
	'Vegetation' AS thema,
	'ax_vegetationsmerkmal' AS layer,
	coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
	'Schneise' AS text,
	coalesce(d.signaturnummer,t.signaturnummer,'4070') AS signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
	coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM ax_vegetationsmerkmal o
LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='BWS' AND t.endet IS NULL
LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='BWS' AND d.endet IS NULL
WHERE o.endet IS NULL AND geometrytype(o.wkb_geometry) IN ('POLYGON','MULTIPOLYGON') AND bewuchs=1300;

-- Namen
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Vegetation' AS thema,
	'ax_vegetationsmerkmal' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(t.schriftinhalt,name) AS text,
		coalesce(d.signaturnummer,t.signaturnummer,'4074') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_vegetationsmerkmal o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='NAM' AND t.endet IS NULL
	LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='NAM' AND d.endet IS NULL
	WHERE o.endet IS NULL AND (NOT name IS NULL OR NOT t.schriftinhalt IS NULL)
) AS n WHERE NOT text IS NULL;
