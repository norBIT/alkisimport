SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Damm, Wall, Deich (61003)
--

SELECT 'Dämme, Wälle und Deiche werden verarbeitet.';

-- Linien
INSERT INTO po_lines(gml_id,gml_ids,thema,layer,line,signaturnummer,modell)
SELECT
	gml_id,
	ARRAY[gml_id] AS gml_ids,
	'Topographie' AS thema,
	'ax_dammwalldeich' AS layer,
	st_multi(
		CASE
		WHEN art='1991' THEN alkis_safe_offsetcurve(line,-0.17,''::text)
		WHEN art='1992' THEN alkis_safe_offsetcurve(line, 0.17,''::text)
		ELSE line
		END
	) AS line,
	2620 AS signaturnummer,
	modell
FROM (
	SELECT
		gml_id,
		art,
		(st_dump(st_multi(wkb_geometry))).geom AS line,
		advstandardmodell||sonstigesmodell AS modell
	FROM po_lastrun, ax_dammwalldeich
	WHERE geometrytype(wkb_geometry) IN ('LINESTRING','MULTILINESTRING')
	  AND endet IS NULL
	  AND beginnt>lastrun
) AS o;

-- Punkte, Wall
INSERT INTO po_points(gml_id,gml_ids,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	gml_id,
	ARRAY[gml_id] AS gml_ids,
	'Topographie' AS thema,
	'ax_dammwalldeich' AS layer,
	st_multi( st_lineinterpolatepoint(line,o.offset) ) AS point,
	0.5*pi()-st_azimuth( st_lineinterpolatepoint(line,o.offset*0.9999), st_lineinterpolatepoint(line,CASE WHEN o.offset=0 THEN 0.001 WHEN o.offset*1.0001>1 THEN 1 ELSE o.offset*1.0001 END) ) AS drehwinkel,
	3632 AS signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		CASE
		WHEN art='1991'             THEN alkis_safe_offsetcurve(o.line,-0.17,''::text)
		WHEN art='1992'             THEN alkis_safe_offsetcurve(o.line, 0.17,''::text)
		WHEN art IN ('2010','2012') THEN alkis_safe_offsetcurve(o.line,-0.34,''::text)
		WHEN art IN ('2011','2013') THEN alkis_safe_offsetcurve(o.line, 0.34,''::text)
		ELSE o.line
		END AS line,
		generate_series(3650, trunc(st_length(line)*1000.0)::int, 6000) / 1000.0 / st_length(line) AS offset,
		modell
	FROM (
		SELECT
			gml_id,
			art,
			(st_dump(st_multi(wkb_geometry))).geom AS line,
			advstandardmodell||sonstigesmodell AS modell
		FROM po_lastrun, ax_dammwalldeich o
		WHERE geometrytype(wkb_geometry) IN ('LINESTRING','MULTILINESTRING')
		  AND endet IS NULL
		  AND art IN ('1910','1920','1930','1940','1950','1960','1970','1980','1990','1991','1992','2010','2011','2012','2013')
		  AND beginnt>lastrun
	) AS o
) AS o;

-- Punkte, Knick, Wall
INSERT INTO po_points(gml_id,gml_ids,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	gml_id,
	ARRAY[gml_id] AS gml_ids,
	'Topographie' AS thema,
	'ax_dammwalldeich' AS layer,
	st_multi( st_lineinterpolatepoint(line,o.offset) ) AS point,
	0.5*pi()-st_azimuth( st_lineinterpolatepoint(line,o.offset*0.9999), st_lineinterpolatepoint(line,CASE WHEN o.offset=0 THEN 0.001 WHEN o.offset*1.0001>1 THEN 1 ELSE o.offset*1.0001 END) ) AS drehwinkel,
	3632 AS signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		CASE
		WHEN art='2001' THEN alkis_safe_offsetcurve(o.line,-0.17,''::text)
		WHEN art='2002' THEN alkis_safe_offsetcurve(o.line, 0.17,''::text)
		ELSE line
		END AS line,
		generate_series( 5950, trunc(st_length(line)*1000.0)::int, 6000 ) / 1000.0 / st_length(line) AS offset,
		modell
	FROM (
		SELECT
			gml_id,
			art,
			(st_dump(st_multi(wkb_geometry))).geom AS line,
			advstandardmodell||sonstigesmodell AS modell
		FROM po_lastrun, ax_dammwalldeich o
		WHERE geometrytype(wkb_geometry) IN ('LINESTRING','MULTILINESTRING') AND endet IS NULL AND art IN ('2000','2001','2002','2003') AND beginnt>lastrun
	) AS o
) AS o;

-- Punkte, Knick, Bewuchs
INSERT INTO po_points(gml_id,gml_ids,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	gml_id,
	ARRAY[gml_id] AS gml_ids,
	'Topographie' AS thema,
	'ax_dammwalldeich' AS layer,
	st_multi( st_lineinterpolatepoint(line,o.offset) ) AS point,
	0.5*pi()-st_azimuth( st_lineinterpolatepoint(line,o.offset*0.9999), st_lineinterpolatepoint(line,CASE WHEN o.offset=0 THEN 0.001 WHEN o.offset*1.0001>1 THEN 1 ELSE o.offset*1.0001 END) ) AS drehwinkel,
	3601 AS signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		CASE
		WHEN art='2001' THEN alkis_safe_offsetcurve(o.line,-0.17,''::text)
		WHEN art='2002' THEN alkis_safe_offsetcurve(o.line, 0.17,''::text)
		ELSE line
		END AS line,
		generate_series( 2900, trunc(st_length(line)*1000.0)::int, 6000 ) / 1000.0 / st_length(line) AS offset,
		modell
	FROM (
		SELECT
			gml_id,
			art,
			(st_dump(st_multi(wkb_geometry))).geom AS line,
			advstandardmodell||sonstigesmodell AS modell
		FROM po_lastrun, ax_dammwalldeich o
		WHERE geometrytype(wkb_geometry) IN ('LINESTRING','MULTILINESTRING') AND endet IS NULL AND art IN ('2000','2001','2002','2003') AND beginnt>lastrun
	) AS o
) AS o;

-- Fläche
INSERT INTO po_polygons(gml_id,gml_ids,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	ARRAY[gml_id] AS gml_ids,
	'Topographie' AS thema,
	'ax_dammwalldeich' AS layer,
	st_multi(wkb_geometry) AS polygon,
	1551 AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM po_lastrun, ax_dammwalldeich o
WHERE geometrytype(wkb_geometry) IN ('POLYGON','MULTIPOLYGON') AND endet IS NULL AND art IN ('1910','1920','1930','1940','1950','1960','1970','1980','1990') AND beginnt>lastrun;

-- TODO mit Graben

-- Namen
INSERT INTO po_labels(gml_id,gml_ids,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	gml_ids,
	'Topographie' AS thema,
	'ax_dammwalldeich' AS layer,
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
		coalesce(d.signaturnummer,t.signaturnummer,'4109') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM po_lastrun, ax_dammwalldeich o
	LEFT OUTER JOIN po_pto t ON o.gml_id=t.dientzurdarstellungvon AND t.art='NAM'
	LEFT OUTER JOIN po_darstellung d ON o.gml_id=d.dientzurdarstellungvon AND d.art='NAM'
	WHERE o.endet IS NULL AND (NOT name IS NULL OR NOT t.schriftinhalt IS NULL) AND greatest(o.beginnt, t.beginnt, d.beginnt)>lastrun
) AS n WHERE NOT text IS NULL;
