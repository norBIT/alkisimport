SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Vegetationsmerkmale (54001)
--

SELECT 'Vegetationsmerkmale werden verarbeitet.';

-- Punkte
INSERT INTO po_points(gml_id,gml_ids,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	gml_id,
	ARRAY[gml_id] AS gml_ids,
	'Vegetation' AS thema,
	'ax_vegetationsmerkmal' AS layer,
	st_multi(point),
	drehwinkel,
	signaturnummer,
	modell
FROM (
	SELECT
		gml_id,
		wkb_geometry AS point,
		0 AS drehwinkel,
		CASE bewuchs
		WHEN 1011 THEN 3597
		WHEN 1012 THEN 3599
		WHEN 1400 THEN 3603
		WHEN 1700 THEN 3607
		END AS signaturnummer,
		advstandardmodell||sonstigesmodell AS modell
	FROM ax_vegetationsmerkmal o
	WHERE geometrytype(o.wkb_geometry) IN ('POINT','MULTIPOINT') AND endet IS NULL
) AS o
WHERE NOT signaturnummer IS NULL;

-- Punktförmige Begleitsignaturen an Linien
INSERT INTO po_points(gml_id,gml_ids,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	gml_id,
	ARRAY[gml_id] AS gml_ids,
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
			(st_dump(st_multi(line))).geom AS line,
			signaturnummer,
			modell
		FROM (
			SELECT
				gml_id,
				bewuchs,
				unnest(
					CASE
					WHEN bewuchs IN (1100,1230,1260) THEN ARRAY[0]
					WHEN bewuchs IN (1101,1102) THEN ARRAY[300]
					WHEN bewuchs=1103 THEN ARRAY[300,600]
					WHEN bewuchs IN (1210,1220) THEN ARRAY[186]
					WHEN bewuchs=1230 THEN ARRAY[1000,2000]
					END
				) AS einzug,
				unnest(
					CASE
					WHEN bewuchs IN (1100,1101,1102,1210,1220,1260) THEN ARRAY[600]
					WHEN bewuchs=1103 THEN ARRAY[1200,1200]
					WHEN bewuchs=1210 THEN ARRAY[1000]
					WHEN bewuchs=1230 THEN ARRAY[2000,2000]
					END
				) AS abstand,
				unnest(
					CASE
					WHEN bewuchs IN (1100,1210,1220,1260) THEN ARRAY[wkb_geometry]
					WHEN bewuchs=1101 THEN ARRAY[st_reverse(alkis_safe_offsetcurve(wkb_geometry,-0.11,''::text))]
					WHEN bewuchs=1102 THEN ARRAY[alkis_safe_offsetcurve(wkb_geometry,0.11,''::text)]
					WHEN bewuchs=1103 THEN
						ARRAY[
							st_reverse(alkis_safe_offsetcurve(wkb_geometry,-0.11,''::text)),
							alkis_safe_offsetcurve(wkb_geometry,0.11,'')
						]
					WHEN bewuchs=1230 THEN
						ARRAY[
							wkb_geometry,
							wkb_geometry
						]
					END
				) AS line,
				unnest(
					CASE
					WHEN bewuchs IN (1100,1101,1102,1103) THEN ARRAY[3601]
					WHEN bewuchs=1210 THEN ARRAY[3458]
					WHEN bewuchs=1220 THEN ARRAY[3460]
					WHEN bewuchs=1230 THEN ARRAY[3458,3460]
					WHEN bewuchs=1260 THEN ARRAY[3601]
					WHEN bewuchs=1700 THEN ARRAY[3607]
					END
				) AS signaturnummer,
				modell
			FROM (
				SELECT
					gml_id,
					(st_dump(st_multi(wkb_geometry))).geom AS wkb_geometry,
					bewuchs,
					advstandardmodell||sonstigesmodell AS modell
				FROM ax_vegetationsmerkmal o
				WHERE o.endet IS NULL
				  AND geometrytype(o.wkb_geometry) IN ('LINESTRING','MULTILINESTRING')
			) AS o
		) AS a
	) AS a
) AS a
GROUP BY gml_id,signaturnummer,modell;

-- Flächen
INSERT INTO po_polygons(gml_id,gml_ids,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	ARRAY[gml_id] AS gml_ids,
	'Vegetation' AS thema,
	'ax_vegetationsmerkmal' AS layer,
	polygon,
	signaturnummer,
	modell
FROM (
	SELECT
		gml_id,
		st_multi(wkb_geometry) AS polygon,
		CASE
		WHEN bewuchs IN (1021,1022,1023,1050,1260,1400,1500,1510,1600,1700,1800) THEN 1560
		WHEN bewuchs=1300                                                        THEN 1561
		END AS signaturnummer,
		advstandardmodell||sonstigesmodell AS modell
	FROM ax_vegetationsmerkmal o
	WHERE geometrytype(o.wkb_geometry) IN ('POLYGON','MULTIPOLYGON') AND endet IS NULL
) AS o
WHERE NOT signaturnummer IS NULL;

-- Flächensymbole
INSERT INTO po_points(gml_id,gml_ids,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	gml_id,
	gml_ids,
	'Vegetation' AS thema,
	'ax_vegetationsmerkmal' AS layer,
	st_multi(point),
	0 AS drehwinkel,
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		ARRAY[o.gml_id,p.gml_id,d.gml_id] AS gml_ids,
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
		coalesce(p.modelle, d.modelle, o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM po_lastrun, ax_vegetationsmerkmal o
	LEFT OUTER JOIN po_ppo p ON o.gml_id=p.dientzurdarstellungvon AND p.art='BWS'
	LEFT OUTER JOIN po_darstellung d ON o.gml_id=d.dientzurdarstellungvon AND d.art='BWS'
	WHERE o.endet IS NULL AND geometrytype(o.wkb_geometry) IN ('POLYGON','MULTIPOLYGON') AND greatest(o.beginnt, p.beginnt, d.beginnt)>lastrun
) AS o
WHERE NOT signaturnummer IS NULL;

-- Zustand nass, Flächen
INSERT INTO po_polygons(gml_id,gml_ids,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	ARRAY[gml_id] AS gml_ids,
	'Vegetation' AS thema,
	'ax_vegetationsmerkmal' AS layer,
	st_multi(wkb_geometry) AS polygon,
	1563 AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ax_vegetationsmerkmal o
WHERE geometrytype(o.wkb_geometry) IN ('POLYGON','MULTIPOLYGON') AND zustand=5000;

-- Zustand nass, Symbol
INSERT INTO po_points(gml_id,gml_ids,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	o.gml_id,
	ARRAY[o.gml_id,p.gml_id] AS gml_ids,
	'Vegetation' AS thema,
	'ax_vegetationsmerkmal' AS layer,
	st_multi(coalesce(p.wkb_geometry,st_centroid(o.wkb_geometry))) AS point,
	coalesce(p.drehwinkel,0) AS drehwinkel,
	coalesce(p.signaturnummer,'3478') AS signaturnummer,
	coalesce(p.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM po_lastrun, ax_vegetationsmerkmal o
JOIN po_ppo p ON o.gml_id=p.dientzurdarstellungvon AND p.art='ZUS' AND p.gml_id<>'TRIGGER'
WHERE o.endet IS NULL AND geometrytype(o.wkb_geometry) IN ('POLYGON','MULTIPOLYGON') AND zustand=5000 AND greatest(o.beginnt, p.beginnt)>lastrun;

-- Schneise, Text
INSERT INTO po_labels(gml_id,gml_ids,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	o.gml_id,
	ARRAY[o.gml_id,t.gml_id,d.gml_id] AS gml_ids,
	'Vegetation' AS thema,
	'ax_vegetationsmerkmal' AS layer,
	coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
	'Schneise' AS text,
	coalesce(d.signaturnummer,t.signaturnummer,'4070') AS signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
	coalesce(t.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM po_lastrun, ax_vegetationsmerkmal o
LEFT OUTER JOIN po_pto t ON o.gml_id=t.dientzurdarstellungvon AND t.art='BWS'
LEFT OUTER JOIN po_darstellung d ON o.gml_id=d.dientzurdarstellungvon AND d.art='BWS'
WHERE o.endet IS NULL AND geometrytype(o.wkb_geometry) IN ('POLYGON','MULTIPOLYGON') AND bewuchs=1300 AND greatest(o.beginnt, t.beginnt, d.beginnt)>lastrun;

-- Namen
INSERT INTO po_labels(gml_id,gml_ids,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	gml_ids,
	'Vegetation' AS thema,
	'ax_vegetationsmerkmal' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		ARRAY[o.gml_id,t.gml_id,d.gml_id] AS gml_ids,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(t.schriftinhalt,name) AS text,
		coalesce(d.signaturnummer,t.signaturnummer,'4074') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM po_lastrun, ax_vegetationsmerkmal o
	LEFT OUTER JOIN po_pto t ON o.gml_id=t.dientzurdarstellungvon AND t.art='NAM'
	LEFT OUTER JOIN po_darstellung d ON o.gml_id=d.dientzurdarstellungvon AND d.art='NAM'
	WHERE o.endet IS NULL AND (NOT name IS NULL OR NOT t.schriftinhalt IS NULL) AND greatest(o.beginnt, t.beginnt, d.beginnt)>lastrun
) AS n WHERE NOT text IS NULL;
