SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Weg, Pfad, Steig (53003)
--

SELECT 'Wege, Pfade und Steige werden verarbeitet.';

-- Linien
INSERT INTO po_lines(gml_id,gml_ids,thema,layer,line,signaturnummer,modell)
SELECT
	gml_id,
	ARRAY[gml_id] AS gml_ids,
	'Verkehr' AS thema,
	'ax_wegpfadsteig' AS layer,
	st_multi(line),
	signaturnummer,
	modell
FROM (
	SELECT
		gml_id,
		wkb_geometry AS line,
		CASE
		WHEN o.art IS NULL OR o.art IN (1103,1105,1106,1107,1110,1111) THEN 2535
		WHEN o.art=1108                                                THEN 2537
		WHEN o.art=1109                                                THEN 2539
		END AS signaturnummer,
		advstandardmodell||sonstigesmodell AS modell
	FROM po_lastrun, ax_wegpfadsteig o
	WHERE geometrytype(wkb_geometry) IN ('LINESTRING','MULTILINESTRING') AND endet IS NULL AND beginnt>lastrun
) AS o
WHERE NOT signaturnummer IS NULL;

-- Flächen
INSERT INTO po_polygons(gml_id,gml_ids,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	ARRAY[gml_id] AS gml_ids,
	'Verkehr' AS thema,
	'ax_wegpfadsteig' AS layer,
	polygon,
	signaturnummer,
	modell
FROM (
	SELECT
		gml_id,
		st_multi(wkb_geometry) AS polygon,
		CASE
		WHEN o.art IS NULL OR o.art IN (1103,1105,1106,1107,1110,1111) THEN 1542
		WHEN o.art=1108                                                THEN 1543
		END AS signaturnummer,
		advstandardmodell||sonstigesmodell AS modell
	FROM po_lastrun, ax_wegpfadsteig o
	WHERE geometrytype(wkb_geometry) IN ('POLYGON','MULTIPOLYGON') AND endet IS NULL AND beginnt>lastrun
) AS o
WHERE NOT signaturnummer IS NULL;

-- Symbole
INSERT INTO po_points(gml_id,gml_ids,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	gml_id,
	gml_ids,
	'Verkehr' AS thema,
	'ax_wegpfadsteig' AS layer,
	st_multi(point),
	drehwinkel,
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		ARRAY[o.gml_id,p.gml_id,d.gml_id] AS gml_ids,
		coalesce(
			p.wkb_geometry,
			CASE
			WHEN geometrytype(o.wkb_geometry) IN ('POINT','MULTIPOINT')     THEN o.wkb_geometry
			WHEN geometrytype(o.wkb_geometry) IN ('POLYGON','MULTIPOLYGON') THEN st_centroid(o.wkb_geometry)
			WHEN geometrytype(o.wkb_geometry)='LINESTRING'                  THEN st_lineinterpolatepoint(o.wkb_geometry,0.5)
			END
		) AS point,
		coalesce(p.drehwinkel,0) AS drehwinkel,
		coalesce(
			d.signaturnummer,
			p.signaturnummer,
			CASE
			WHEN o.art=1106 THEN '3426'
			WHEN o.art=1107 THEN '3430'
			WHEN o.art=1110 THEN '3428'
			WHEN o.art=1111 THEN '3576'
			END
		) AS signaturnummer,
		coalesce(p.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM po_lastrun, ax_wegpfadsteig o
	LEFT OUTER JOIN po_ppo p ON o.gml_id=p.dientzurdarstellungvon AND p.art='ART'
	LEFT OUTER JOIN po_darstellung d ON o.gml_id=d.dientzurdarstellungvon AND d.art='ART'
	WHERE o.endet IS NULL AND greatest(o.beginnt,p.beginnt,d.beginnt)>lastrun
) AS o
WHERE NOT signaturnummer IS NULL;

-- Namen
INSERT INTO po_labels(gml_id,gml_ids,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	gml_ids,
	'Verkehr' AS thema,
	'ax_wegpfadsteig' AS layer,
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
		coalesce(d.signaturnummer,t.signaturnummer,'4109') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM po_lastrun, ax_wegpfadsteig o
	LEFT OUTER JOIN po_pto t ON o.gml_id=t.dientzurdarstellungvon AND t.art='NAM'
	LEFT OUTER JOIN po_darstellung d ON o.gml_id=d.dientzurdarstellungvon AND d.art='NAM'
	WHERE o.endet IS NULL AND (NOT name IS NULL OR NOT t.schriftinhalt IS NULL) AND greatest(o.beginnt,t.beginnt,o.beginnt)>lastrun
) AS n WHERE NOT text IS NULL;

-- Name
INSERT INTO po_labels(gml_id,gml_ids,thema,layer,line,text,signaturnummer,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	gml_ids,
	'Verkehr' AS thema,
	'ax_wegpfadsteig' AS layer,
	line,
	text,
	signaturnummer,
	horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		ARRAY[o.gml_id,t.gml_id,d.gml_id] AS gml_ids,
		t.wkb_geometry AS line,
		coalesce(d.signaturnummer,t.signaturnummer,'4109') AS signaturnummer,
		coalesce(t.schriftinhalt,name) AS text,
		horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM po_lastrun, ax_wegpfadsteig o
	LEFT OUTER JOIN po_lto t ON o.gml_id=t.dientzurdarstellungvon AND t.art='NAM'
	LEFT OUTER JOIN po_darstellung d ON o.gml_id=d.dientzurdarstellungvon AND d.art='NAM'
	WHERE o.endet IS NULL AND (NOT name IS NULL OR NOT t.schriftinhalt IS NULL) AND greatest(o.beginnt,t.beginnt,d.beginnt)>lastrun
) AS n WHERE NOT text IS NULL;
