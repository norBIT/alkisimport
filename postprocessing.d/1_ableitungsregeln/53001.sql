SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Bauwerk im Verkehrsbereich (53001)
--

SELECT 'Bauwerke in Verkehrsbereich werden verarbeitet.';

-- Flächen
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	'Verkehr' AS thema,
	'ax_bauwerkimverkehrsbereich' AS layer,
	polygon,
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		st_multi(wkb_geometry) AS polygon,
		CASE
		WHEN bauwerksfunktion IN (1800,1801,1802,1803,1804,1805,1806,1807,1808,1810,1830) THEN 1530
		WHEN bauwerksfunktion=1840                                                        THEN 1531
		WHEN bauwerksfunktion=1850                                                        THEN 1532
		WHEN bauwerksfunktion=1870                                                        THEN 1533
		WHEN bauwerksfunktion=1880                                                        THEN 1534
		WHEN bauwerksfunktion=1890                                                        THEN 1535
		WHEN bauwerksfunktion=1900                                                        THEN 2305
		WHEN bauwerksfunktion=9999                                                        THEN 1536
		END AS signaturnummer,
		advstandardmodell||sonstigesmodell AS modell
	FROM ax_bauwerkimverkehrsbereich o
	WHERE geometrytype(wkb_geometry) IN ('POLYGON','MULTIPOLYGON') AND endet IS NULL
) AS o
WHERE NOT signaturnummer IS NULL;

-- Linien
INSERT INTO po_lines(gml_id,thema,layer,line,signaturnummer,modell)
SELECT
	gml_id,
	'Verkehr' AS thema,
	'ax_bauwerkimverkehrsbereich' AS layer,
	st_multi(line),
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		wkb_geometry AS line,
		CASE
		WHEN bauwerksfunktion=1820 THEN 2530
		WHEN bauwerksfunktion=1845 THEN 2533
		WHEN bauwerksfunktion=1900 THEN 2505
		END AS signaturnummer,
		advstandardmodell||sonstigesmodell AS modell
	FROM ax_bauwerkimverkehrsbereich o
	WHERE geometrytype(wkb_geometry) IN ('LINESTRING','MULTILINESTRING') AND endet IS NULL
) AS o
WHERE NOT signaturnummer IS NULL;

-- Steg
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
        o.gml_id,
        'Verkehr' AS thema,
        'ax_bauwerkimverkehrsbereich' AS layer,
        st_multi(
		unnest(
			ARRAY[
				st_startpoint(o.line),
				st_endpoint(o.line)
			]
		)
        ) AS point,
        unnest(
                ARRAY[
                        st_azimuth(st_startpoint(o.line), st_lineinterpolatepoint(o.line, 0.001)),
                        st_azimuth(st_endpoint(o.line), st_lineinterpolatepoint(o.line, 0.999))
                ]
        ) AS drehwinkel,
        '3637' AS signaturnummer,
        modell
FROM (
        SELECT
                gml_id,
                (st_dump(st_multi(wkb_geometry))).geom AS line,
                advstandardmodell||sonstigesmodell AS modell
	FROM ax_bauwerkimverkehrsbereich o
        WHERE geometrytype(wkb_geometry) IN ('LINESTRING','MULTILINESTRING')
          AND endet IS NULL
          AND bauwerksfunktion=1820
) AS o;


-- Punkte
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	gml_id,
	'Verkehr' AS thema,
	'ax_bauwerkimverkehrsbereich' AS layer,
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
		WHEN bauwerksfunktion=1840 THEN 3572
		END AS signaturnummer,
		advstandardmodell||sonstigesmodell AS modell
	FROM ax_bauwerkimverkehrsbereich o
	WHERE geometrytype(wkb_geometry) IN ('POINT','MULTIPOINT') AND endet IS NULL
) AS o
WHERE NOT signaturnummer IS NULL;

-- Schutzgalerieanschrieb
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Verkehr' AS thema,
	'ax_bauwerkimverkehrsbereich' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(t.schriftinhalt,'Schutzgalerie') AS text,
		coalesce(d.signaturnummer,t.signaturnummer,'4070') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_bauwerkimverkehrsbereich o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='BWF' AND t.endet IS NULL
	LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='BWF' AND d.endet IS NULL
	WHERE o.endet IS NULL AND bauwerksfunktion=1880
) AS n;

-- Anflugbefeuerung
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	o.gml_id,
	'Verkehr' AS thema,
	'ax_bauwerkimverkehrsbereich' AS layer,
	st_multi(coalesce(p.wkb_geometry,o.wkb_geometry)) AS point,
	coalesce(p.drehwinkel,0) AS drehwinkel,
	coalesce(d.signaturnummer,p.signaturnummer,'3573') AS signaturnummer,
	coalesce(p.advstandardmodell||p.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM ax_bauwerkimverkehrsbereich o
LEFT OUTER JOIN ap_ppo p ON ARRAY[o.gml_id] <@ p.dientzurdarstellungvon AND p.art='BWF' AND p.endet IS NULL
LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='BWF' AND d.endet IS NULL
WHERE o.endet IS NULL AND bauwerksfunktion=1910 AND geometrytype(o.wkb_geometry) IN ('POINT','MULTIPOINT');

-- Namen
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Verkehr' AS thema,
	'ax_bauwerkimverkehrsbereich' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(t.schriftinhalt,o.name) AS text,
		coalesce(d.signaturnummer,t.signaturnummer,'4107') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_bauwerkimverkehrsbereich o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='NAM' AND t.endet IS NULL
	LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='NAM' AND d.endet IS NULL
	WHERE o.endet IS NULL AND NOT name IS NULL
) AS n;

-- Außer Betrieb
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Verkehr' AS thema,
	'ax_bauwerkimverkehrsbereich' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		'(außer Betrieb)'::text AS text,
		coalesce(d.signaturnummer,t.signaturnummer,'4070') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_bauwerkimverkehrsbereich o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='NAM' AND t.endet IS NULL
	LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='NAM' AND d.endet IS NULL
	WHERE o.endet IS NULL AND zustand=2100
) AS n;
