SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Sonstiges Bauwerk oder sonstige Einrichtung (51009)
--

SELECT 'Sonstige Bauwerke oder Einrichtungen werden verarbeitet.';

-- Flächen
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	'Gebäude' AS thema,
	'ax_sonstigesbauwerkodersonstigeeinrichtung' AS layer,
	polygon,
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		st_multi(wkb_geometry) AS polygon,
		CASE
		WHEN bauwerksfunktion IN (1610,1611)                          THEN 20311304
		WHEN bauwerksfunktion IN (1620,1621,1622,1650,1670,1700,1720) THEN     1305
		WHEN bauwerksfunktion IN (1750,9999)                          THEN     1330
		WHEN bauwerksfunktion IN (1780,1782)                          THEN     1525
		END AS signaturnummer,
		advstandardmodell||sonstigesmodell AS modell
	FROM ax_sonstigesbauwerkodersonstigeeinrichtung o
	WHERE geometrytype(wkb_geometry) IN ('POLYGON','MULTIPOLYGON') AND endet IS NULL
) AS o WHERE NOT signaturnummer IS NULL;

-- Linien
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	'Gebäude' AS thema,
	'ax_sonstigesbauwerkodersonstigeeinrichtung' AS layer,
	st_multi(polygon),
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		alkis_bufferline(wkb_geometry,0.5) AS polygon,
		CASE
		WHEN bauwerksfunktion IN (1701,1702,1703,1721,1722,1723) THEN 2510
		END AS signaturnummer,
		advstandardmodell||sonstigesmodell AS modell
	FROM ax_sonstigesbauwerkodersonstigeeinrichtung o
	WHERE geometrytype(wkb_geometry) IN ('LINESTRING','MULTILINESTRING') AND endet IS NULL
) AS o WHERE NOT signaturnummer IS NULL;

INSERT INTO po_lines(gml_id,thema,layer,line,signaturnummer,modell)
SELECT
	gml_id,
	'Gebäude' AS thema,
	'ax_sonstigesbauwerkodersonstigeeinrichtung' AS layer,
	st_multi(line),
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		wkb_geometry AS line,
		CASE
		WHEN bauwerksfunktion=1630                               THEN 2507
		WHEN bauwerksfunktion=1740                               THEN 2507 -- 25073580
		WHEN bauwerksfunktion=1790                               THEN 2519
		WHEN bauwerksfunktion=1791                               THEN 2002
		END AS signaturnummer,
		advstandardmodell||sonstigesmodell AS modell
	FROM ax_sonstigesbauwerkodersonstigeeinrichtung o
	WHERE geometrytype(wkb_geometry) IN ('LINESTRING','MULTILINESTRING') AND endet IS NULL
) AS o WHERE NOT signaturnummer IS NULL;

-- Symbole
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	gml_id,
	'Gebäude' AS thema,
	'ax_sonstigesbauwerkodersonstigeeinrichtung' AS layer,
	st_multi(point),
	drehwinkel,
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		coalesce(
			p.wkb_geometry,
			CASE
			WHEN geometrytype(o.wkb_geometry) IN ('POINT','MULTIPOINT')     THEN o.wkb_geometry
			WHEN geometrytype(o.wkb_geometry) IN ('POLYGON','MULTIPOLYGON') THEN st_centroid(o.wkb_geometry)
			END
		) AS point,
		coalesce(p.drehwinkel,0) AS drehwinkel,
		coalesce(
			d.signaturnummer,
			p.signaturnummer,
			CASE
			WHEN bauwerksfunktion=1640                                                            THEN '3531'
			WHEN bauwerksfunktion=1750                                                            THEN '3532'
			WHEN bauwerksfunktion=1760                                                            THEN '3533'
			WHEN bauwerksfunktion=1761                                                            THEN '3534'
			WHEN bauwerksfunktion IN (1762,1763)                                                  THEN '3535'
			WHEN bauwerksfunktion=1770                                                            THEN '3536'
			WHEN bauwerksfunktion=1780 AND geometrytype(o.wkb_geometry) IN ('POINT','MULTIPOINT') THEN '3529'
			WHEN bauwerksfunktion=1781                                                            THEN '3537'
			WHEN bauwerksfunktion=1782                                                            THEN '3539'
			WHEN bauwerksfunktion=1783                                                            THEN '3540'
			END
		) AS signaturnummer,
		coalesce(p.advstandardmodell||p.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_sonstigesbauwerkodersonstigeeinrichtung o
	LEFT OUTER JOIN ap_ppo p ON ARRAY[o.gml_id] <@ p.dientzurdarstellungvon AND p.art='BWF' AND p.endet IS NULL
	LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='BWF' AND d.endet IS NULL
	WHERE o.endet IS NULL
) AS o WHERE NOT signaturnummer IS NULL;

-- Texte
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Gebäude' AS thema,
	'ax_sonstigesbauwerkodersonstigeeinrichtung' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		coalesce(
			t.wkb_geometry,
			CASE
			WHEN geometrytype(o.wkb_geometry) IN ('POINT','MULTIPOINT')     THEN o.wkb_geometry
			WHEN geometrytype(o.wkb_geometry) IN ('POLYGON','MULTIPOLYGON') THEN st_centroid(o.wkb_geometry)
			WHEN geometrytype(o.wkb_geometry)='LINESTRING'                  THEN st_lineinterpolatepoint(o.wkb_geometry,0.5)
			END
		) AS point,
		CASE
		WHEN bauwerksfunktion IN (1650,1670) THEN
			coalesce(
				t.schriftinhalt,
				(SELECT beschreibung FROM ax_bauwerksfunktion_sonstigesbauwerkodersonstigeeinrichtun WHERE wert=bauwerksfunktion)
			)
		END AS text,
		coalesce(
			d.signaturnummer,
			t.signaturnummer,
			CASE
			WHEN bauwerksfunktion IN (1650,1670) THEN '4070'
			WHEN bauwerksfunktion IN (1780)      THEN '4073'
			END
		) AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_sonstigesbauwerkodersonstigeeinrichtung o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='BWF' AND t.endet IS NULL
	LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='BWF' AND d.endet IS NULL
	WHERE o.endet IS NULL
) AS n WHERE NOT text IS NULL AND NOT signaturnummer IS NULL;

-- Namen
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Gebäude' AS thema,
	'ax_sonstigesbauwerkodersonstigeeinrichtung' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		coalesce(
			t.wkb_geometry,
			CASE
			WHEN geometrytype(o.wkb_geometry) IN ('POINT','MULTIPOINT')     THEN o.wkb_geometry
			WHEN geometrytype(o.wkb_geometry) IN ('POLYGON','MULTIPOLYGON') THEN st_centroid(o.wkb_geometry)
			WHEN geometrytype(o.wkb_geometry)='LINESTRING'                  THEN st_lineinterpolatepoint(o.wkb_geometry,0.5)
			END
		) AS point,
		coalesce(t.schriftinhalt,o.name) AS text,
		coalesce(d.signaturnummer,t.signaturnummer,'4107') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_sonstigesbauwerkodersonstigeeinrichtung o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='NAM' AND t.endet IS NULL
	LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='NAM' AND d.endet IS NULL
	WHERE o.endet IS NULL AND NOT name IS NULL
) AS n;
