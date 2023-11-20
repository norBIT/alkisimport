SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Felsen, Felsblock, Felsnadel (61006)
--

SELECT 'Felsen werden verarbeitet.';

INSERT INTO po_points(gml_id,gml_ids,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	gml_id,
	ARRAY[gml_id] AS gml_ids,
	'Topographie' AS thema,
	'ax_felsenfelsblockfelsnadel' AS layer,
	st_multi(wkb_geometry) AS point,
	0 AS drehwinkel,
	3627 AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM po_lastrun, ax_felsenfelsblockfelsnadel o
WHERE geometrytype(wkb_geometry) IN ('POINT','MULTIPOINT') AND endet IS NULL AND beginnt>lastrun;

-- Punktförmige Begleitsignaturen an Linien
INSERT INTO po_points(gml_id,gml_ids,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	gml_id,
	ARRAY[gml_id] AS gml_ids,
	'Topographie' AS thema,
	'ax_felsenfelsblockfelsnadel' AS layer,
	st_multi(st_collect(st_lineinterpolatepoint(line,CASE WHEN a.offset<0 THEN 0 WHEN a.offset>1 THEN 1 ELSE a.offset END))) AS point,
	0 AS drehwinkel,
	signaturnummer,
	modell
FROM (
	SELECT
		gml_id,
		signaturnummer,
		line,
		generate_series(einzug,trunc(st_length(line)*1000)::int,abstand) / 1000.0 / st_length(line) AS offset,
		modell
	FROM (
		SELECT
			gml_id,
			einzug,
			abstand,
			(st_dump(st_multi(line))).geom AS line,
			signaturnummer,
			modell
		FROM (
			SELECT
				gml_id,
				1710 AS einzug,
				8000 AS abstand,
				wkb_geometry AS line,
				3634 AS signaturnummer,
				advstandardmodell||sonstigesmodell AS modell
			FROM po_lastrun, ax_felsenfelsblockfelsnadel
			WHERE endet IS NULL AND beginnt>lastrun
			AND geometrytype(wkb_geometry) IN ('LINESTRING','MULTILINESTRING')
		) AS a
	) AS a
) AS a
GROUP BY gml_id,signaturnummer,modell;

-- Flächen
INSERT INTO po_polygons(gml_id,gml_ids,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	ARRAY[gml_id] AS gml_ids,
	'Topographie' AS thema,
	'ax_felsenfelsblockfelsnadel' AS layer,
	st_multi(wkb_geometry) AS polygon,
	1551 AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM po_lastrun, ax_felsenfelsblockfelsnadel
WHERE geometrytype(wkb_geometry) IN ('POLYGON','MULTIPOLYGON') AND endet IS NULL AND beginnt>lastrun;

-- Flächensymbole
INSERT INTO po_points(gml_id,gml_ids,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	o.gml_id,
	ARRAY[o.gml_id, p.gml_id, d.gml_id] AS gml_ids,
	'Topographie' AS thema,
	'ax_felsenfelsblockfelsnadel' AS layer,
	st_multi(coalesce(p.wkb_geometry,alkis_flaechenfuellung(o.wkb_geometry,d.positionierungsregel),st_centroid(o.wkb_geometry))) AS point,
	coalesce(p.drehwinkel,0) AS drehwinkel,
	coalesce(d.signaturnummer,p.signaturnummer,'3627') AS signaturnummer,
	coalesce(p.modelle, d.modelle, o.advstandardmodell||o.sonstigesmodell) AS modell
FROM po_lastrun, ax_felsenfelsblockfelsnadel o
LEFT OUTER JOIN po_ppo p ON o.gml_id=p.dientzurdarstellungvon AND p.art='Felsen'
LEFT OUTER JOIN po_darstellung d ON o.gml_id=d.dientzurdarstellungvon AND d.art='Felsen'
WHERE o.endet IS NULL AND geometrytype(o.wkb_geometry) IN ('POLYGON','MULTIPOLYGON') AND greatest(o.beginnt, p.beginnt, d.beginnt)>lastrun;

-- Namen
INSERT INTO po_labels(gml_id,gml_ids,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	gml_ids,
	'Topographie' AS thema,
	'ax_felsenfelsblockfelsnadel' AS layer,
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
		coalesce(d.signaturnummer,t.signaturnummer,'4118') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM po_lastrun, ax_felsenfelsblockfelsnadel o
	LEFT OUTER JOIN po_pto t ON o.gml_id=t.dientzurdarstellungvon AND t.art='NAM'
	LEFT OUTER JOIN po_darstellung d ON o.gml_id=d.dientzurdarstellungvon AND d.art='NAM'
	WHERE o.endet IS NULL AND (NOT name IS NULL OR NOT t.schriftinhalt IS NULL) AND greatest(o.beginnt, t.beginnt, d.beginnt)>lastrun
) AS n WHERE NOT text IS NULL;
