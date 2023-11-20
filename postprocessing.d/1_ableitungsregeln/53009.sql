SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Bauwerk im Gewässerbereich (53009)
--

SELECT 'Bauwerke im Gewässerbereich werden verarbeitet.';

-- Linien
INSERT INTO po_polygons(gml_id,gml_ids,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	ARRAY[gml_id] AS gml_ids,
	'Gewässer' AS thema,
	'ax_bauwerkimgewaesserbereich' AS layer,
	st_multi(polygon),
	signaturnummer,
	modell
FROM (
	SELECT
		gml_id,
		alkis_bufferline(line,0.5) AS polygon,
		CASE
		WHEN bauwerksfunktion=2136 THEN 2510
		WHEN bauwerksfunktion=2060 THEN 2526
		END AS signaturnummer,
		modell
	FROM (
		SELECT
			gml_id,
			(st_dump(st_multi(wkb_geometry))).geom AS line,
			bauwerksfunktion,
			advstandardmodell||sonstigesmodell AS modell
		FROM po_lastrun, ax_bauwerkimgewaesserbereich
		WHERE geometrytype(wkb_geometry) IN ('LINESTRING','MULTILINESTRING')
		  AND endet IS NULL AND beginnt>lastrun
	) AS o
) AS o
WHERE NOT signaturnummer IS NULL;

INSERT INTO po_lines(gml_id,gml_ids,thema,layer,line,signaturnummer,modell)
SELECT
	gml_id,
	ARRAY[gml_id] AS gml_ids,
	'Gewässer' AS thema,
	'ax_bauwerkimgewaesserbereich' AS layer,
	st_multi(line),
	signaturnummer,
	modell
FROM (
	SELECT
		gml_id,
		wkb_geometry AS line,
		CASE
		WHEN bauwerksfunktion IN (2010,2011,2070) THEN 2560
		WHEN bauwerksfunktion=2012 THEN 2561
		WHEN bauwerksfunktion=2050 THEN 2003 -- 20033650
		WHEN bauwerksfunktion=2080 THEN 2003 -- 20033593
		WHEN bauwerksfunktion=2090 THEN 2003 -- 20033594
		WHEN bauwerksfunktion=2132 THEN 2003 -- 20033638
		WHEN bauwerksfunktion=9999 THEN 2003
		END AS signaturnummer,
		advstandardmodell||sonstigesmodell AS modell
	FROM po_lastrun, ax_bauwerkimgewaesserbereich o
	WHERE geometrytype(o.wkb_geometry) IN ('LINESTRING','MULTILINESTRING') AND endet IS NULL AND beginnt>lastrun
) AS o
WHERE NOT signaturnummer IS NULL;

-- TODO: Linienbegleitende Signaturen

-- Flächen
INSERT INTO po_polygons(gml_id,gml_ids,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	ARRAY[gml_id] AS gml_ids,
	'Gewässer' AS thema,
	'ax_bauwerkimgewaesserbereich' AS layer,
	polygon,
	signaturnummer,
	modell
FROM (
	SELECT
		gml_id,
		st_multi(wkb_geometry) AS polygon,
		CASE
		WHEN bauwerksfunktion IN (2010,2011,2070) THEN 1550
		WHEN bauwerksfunktion=2020 THEN 1551
		WHEN bauwerksfunktion=2030 THEN
			CASE WHEN zustand=4000 THEN 1552 ELSE 1305 END
		WHEN bauwerksfunktion=2040 THEN
			CASE WHEN zustand=4000 THEN 1552 ELSE 1551 END
		WHEN bauwerksfunktion IN (2050,2060,2080,2110,9999) THEN 1548
		WHEN bauwerksfunktion=2090 THEN 1305
		WHEN bauwerksfunktion IN (2131,2133) THEN 1308
		END AS signaturnummer,
		advstandardmodell||sonstigesmodell AS modell
	FROM po_lastrun, ax_bauwerkimgewaesserbereich o
	WHERE geometrytype(o.wkb_geometry) IN ('POLYGON','MULTIPOLYGON') AND endet IS NULL AND beginnt>lastrun
) AS o
WHERE NOT signaturnummer IS NULL;

-- Symbole
INSERT INTO po_points(gml_id,gml_ids,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	gml_id,
	gml_ids,
	'Gewässer' AS thema,
	'ax_bauwerkimgewaesserbereich' AS layer,
	st_multi(point),
	drehwinkel,
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		ARRAY[o.gml_id,p.gml_id] AS gml_ids,
		coalesce(p.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(p.drehwinkel,0) AS drehwinkel,
		coalesce(
			p.signaturnummer,
			CASE
			WHEN o.gml_id LIKE 'DEHB%' THEN
				CASE bauwerksfunktion
				WHEN 1200 THEN '3529'
				END
			ELSE
				CASE bauwerksfunktion
				WHEN 2050 THEN '3653'
				WHEN 2060 THEN '3592'
				WHEN 2080 THEN '3593'
				WHEN 2090 THEN '3594'
				WHEN 2110 THEN '3595'
				WHEN 2131 THEN '3482'
				END
			END
		) AS signaturnummer,
		coalesce(p.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM po_lastrun, ax_bauwerkimgewaesserbereich o
	JOIN po_ppo p ON o.gml_id=p.dientzurdarstellungvon AND p.art='BWF' AND p.gml_id<>'TRIGGER'
	WHERE o.endet IS NULL AND geometrytype(o.wkb_geometry) IN ('POLYGON','MULTIPOLYGON') AND greatest(o.beginnt,p.beginnt)>lastrun
) AS o
WHERE signaturnummer IS NOT NULL;

-- Punkte
INSERT INTO po_points(gml_id,gml_ids,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	gml_id,
	ARRAY[gml_id] AS gml_id,
	'Gewässer' AS thema,
	'ax_bauwerkimgewaesserbereich' AS layer,
	st_multi(point),
	drehwinkel,
	signaturnummer,
	modell
FROM (
	SELECT
		gml_id,
		wkb_geometry AS point,
		0 AS drehwinkel,
		CASE
		WHEN bauwerksfunktion=2120 THEN 3596
		END AS signaturnummer,
		advstandardmodell||sonstigesmodell AS modell
	FROM po_lastrun, ax_bauwerkimgewaesserbereich o
	WHERE geometrytype(o.wkb_geometry) IN ('POINT','MULTIPOINT') AND endet IS NULL AND beginnt>lastrun
) AS o
WHERE NOT signaturnummer IS NULL;

-- Texte
INSERT INTO po_labels(gml_id,gml_ids,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	gml_ids,
	'Gewässer' AS thema,
	'ax_bauwerkimgewaesserbereich' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		ARRAY[o.gml_id,t.gml_id,d.gml_id] AS gml_ids,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		(SELECT beschreibung FROM ax_bauwerksfunktion_bauwerkimgewaesserbereich WHERE wert=o.bauwerksfunktion) AS text,
		coalesce(d.signaturnummer,t.signaturnummer,'4105') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM po_lastrun, ax_bauwerkimgewaesserbereich o
	LEFT OUTER JOIN po_pto t ON o.gml_id=t.dientzurdarstellungvon AND t.art='BWF'
	LEFT OUTER JOIN po_darstellung d ON o.gml_id=d.dientzurdarstellungvon AND d.art='BWF'
	WHERE o.endet IS NULL AND bauwerksfunktion=2020 AND greatest(o.beginnt,t.beginnt,d.beginnt)>lastrun
) AS n WHERE NOT text IS NULL;

-- Zustand
INSERT INTO po_labels(gml_id,gml_ids,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	gml_ids,
	'Gewässer' AS thema,
	'ax_bauwerkimgewaesserbereich' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		ARRAY[o.gml_id,t.gml_id,d.gml_id] AS gml_ids,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		CASE
		WHEN zustand=2100 THEN '(außer Betrieb)'
		WHEN zustand=4000 THEN
			(SELECT beschreibung FROM ax_bauwerksfunktion_bauwerkimgewaesserbereich WHERE wert=o.bauwerksfunktion)
			|| E' (im Bau)'
		END AS text,
		coalesce(d.signaturnummer,t.signaturnummer,'4070') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM po_lastrun, ax_bauwerkimgewaesserbereich o
	LEFT OUTER JOIN po_pto t ON o.gml_id=t.dientzurdarstellungvon AND t.art='ZUS'
	LEFT OUTER JOIN po_darstellung d ON o.gml_id=d.dientzurdarstellungvon AND d.art='ZUS'
	WHERE o.endet IS NULL AND bauwerksfunktion IN (2030,2040) AND NOT zustand IS NULL AND greatest(o.beginnt,t.beginnt,d.beginnt)>lastrun
) AS n WHERE NOT text IS NULL;

-- Namen
INSERT INTO po_labels(gml_id,gml_ids,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	gml_ids,
	'Gewässer' AS thema,
	'ax_bauwerkimgewaesserbereich' AS layer,
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
	FROM po_lastrun, ax_bauwerkimgewaesserbereich o
	LEFT OUTER JOIN po_pto t ON o.gml_id=t.dientzurdarstellungvon AND t.art='NAM'
	LEFT OUTER JOIN po_darstellung d ON o.gml_id=d.dientzurdarstellungvon AND d.art='NAM'
	WHERE o.endet IS NULL AND (NOT name IS NULL OR NOT t.schriftinhalt IS NULL) AND greatest(o.beginnt,t.beginnt,d.beginnt)>lastrun
) AS n WHERE NOT text IS NULL;
