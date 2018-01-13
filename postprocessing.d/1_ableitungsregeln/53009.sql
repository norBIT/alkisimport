SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Bauwerk im Gewässerbereich (53009)
--

SELECT 'Bauwerke im Gewässerbereich werden verarbeitet.';

-- Linien
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	'Gewässer' AS thema,
	'ax_bauwerkimgewaesserbereich' AS layer,
	st_multi(polygon),
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		alkis_bufferline(wkb_geometry,0.5) AS polygon,
		CASE
		WHEN bauwerksfunktion=2136 THEN 2510
		WHEN bauwerksfunktion=2060 THEN 2526
		END AS signaturnummer,
		advstandardmodell||sonstigesmodell AS modell
	FROM ax_bauwerkimgewaesserbereich o
	WHERE geometrytype(o.wkb_geometry) IN ('LINESTRING','MULTILINESTRING') AND endet IS NULL
) AS o WHERE NOT signaturnummer IS NULL;

INSERT INTO po_lines(gml_id,thema,layer,line,signaturnummer,modell)
SELECT
	gml_id,
	'Gewässer' AS thema,
	'ax_bauwerkimgewaesserbereich' AS layer,
	st_multi(line),
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
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
	FROM ax_bauwerkimgewaesserbereich o
	WHERE geometrytype(o.wkb_geometry) IN ('LINESTRING','MULTILINESTRING') AND endet IS NULL
) AS o WHERE NOT signaturnummer IS NULL;

-- TODO: Linienbegleitende Signaturen

-- Flächen
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	'Gewässer' AS thema,
	'ax_bauwerkimgewaesserbereich' AS layer,
	polygon,
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
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
	FROM ax_bauwerkimgewaesserbereich o
	WHERE geometrytype(o.wkb_geometry) IN ('POLYGON','MULTIPOLYGON') AND endet IS NULL
) AS o WHERE NOT signaturnummer IS NULL;

-- Symbole
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	gml_id,
	'Gewässer' AS thema,
	'ax_bauwerkimgewaesserbereich' AS layer,
	st_multi(point),
	drehwinkel,
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		coalesce(p.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(p.drehwinkel,0) AS drehwinkel,
		coalesce(
			p.signaturnummer,
			CASE
			WHEN bauwerksfunktion=2050 THEN '3653'
			WHEN bauwerksfunktion=2060 THEN '3592'
			WHEN bauwerksfunktion=2080 THEN '3593'
			WHEN bauwerksfunktion=2090 THEN '3594'
			WHEN bauwerksfunktion=2110 THEN '3595'
			WHEN bauwerksfunktion=2131 THEN '3482'
			END
		) AS signaturnummer,
		coalesce(p.advstandardmodell||p.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_bauwerkimgewaesserbereich o
	JOIN ap_ppo p ON ARRAY[o.gml_id] <@ p.dientzurdarstellungvon AND p.art='BWF' AND p.endet IS NULL
	WHERE o.endet IS NULL AND geometrytype(o.wkb_geometry) IN ('POLYGON','MULTIPOLYGON')
) AS o WHERE NOT signaturnummer IS NULL;

-- Punkte
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	gml_id,
	'Gewässer' AS thema,
	'ax_bauwerkimgewaesserbereich' AS layer,
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
		WHEN bauwerksfunktion=2120 THEN 3596
		END AS signaturnummer,
		advstandardmodell||sonstigesmodell AS modell
	FROM ax_bauwerkimgewaesserbereich o
	WHERE geometrytype(o.wkb_geometry) IN ('POINT','MULTIPOINT') AND endet IS NULL
) AS o WHERE NOT signaturnummer IS NULL;

-- Texte
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Gewässer' AS thema,
	'ax_bauwerkimgewaesserbereich' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		(SELECT beschreibung FROM ax_bauwerksfunktion_bauwerkimgewaesserbereich WHERE wert=o.bauwerksfunktion) AS text,
		coalesce(d.signaturnummer,t.signaturnummer,'4105') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_bauwerkimgewaesserbereich o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='BWF' AND t.endet IS NULL
	LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='BWF' AND d.endet IS NULL
	WHERE o.endet IS NULL AND bauwerksfunktion=2020
) AS n WHERE NOT text IS NULL;

-- Zustand
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Gewässer' AS thema,
	'ax_bauwerkimgewaesserbereich' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		CASE
		WHEN zustand=2100 THEN '(außer Betrieb)'
		WHEN zustand=4000 THEN
			(SELECT beschreibung FROM ax_bauwerksfunktion_bauwerkimgewaesserbereich WHERE wert=o.bauwerksfunktion)
			|| E' (im Bau)'
		END AS text,
		coalesce(d.signaturnummer,t.signaturnummer,'4070') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_bauwerkimgewaesserbereich o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='ZUS' AND t.endet IS NULL
	LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='ZUS' AND d.endet IS NULL
	WHERE o.endet IS NULL AND bauwerksfunktion IN (2030,2040) AND NOT zustand IS NULL
) AS n WHERE NOT text IS NULL;

-- Namen
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Gewässer' AS thema,
	'ax_bauwerkimgewaesserbereich' AS layer,
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
	FROM ax_bauwerkimgewaesserbereich o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='NAM' AND t.endet IS NULL
	LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='NAM' AND d.endet IS NULL
	WHERE o.endet IS NULL AND (NOT name IS NULL OR NOT t.schriftinhalt IS NULL)
) AS n WHERE NOT text IS NULL;
