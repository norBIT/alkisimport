SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Untergeordnetes Gewässer (55002)
--

SELECT 'Untergeordnete Gewässer werden verarbeitet.';

-- Linien
INSERT INTO po_lines(gml_id,gml_ids,thema,layer,line,signaturnummer,modell)
SELECT
	gml_id,
	ARRAY[gml_id] AS gml_ids,
	'Gewässer' AS thema,
	'ax_untergeordnetesgewaesser' AS layer,
	st_multi(line),
	signaturnummer,
	modell
FROM (
	SELECT
		gml_id,
		wkb_geometry AS line,
		CASE
		WHEN coalesce(funktion,0) IN (0,1010,1011,1012,1013,1020,1030) THEN
			CASE
			WHEN lagezurerdoberflaeche IS NULL AND hydrologischesmerkmal IS NULL THEN 2592
			WHEN lagezurerdoberflaeche IN (1800,1810)                            THEN 2560
			WHEN lagezurerdoberflaeche IS NULL AND hydrologischesmerkmal=2000    THEN 2593
			WHEN lagezurerdoberflaeche IS NULL AND hydrologischesmerkmal=3000    THEN 2595
			END
		END AS signaturnummer,
		advstandardmodell||sonstigesmodell AS modell
	FROM po_lastrun, ax_untergeordnetesgewaesser o
	WHERE geometrytype(o.wkb_geometry) IN ('LINESTRING','MULTILINESTRING') AND endet IS NULL AND beginnt>lastrun
) AS o
WHERE NOT signaturnummer IS NULL;

-- Flächen
INSERT INTO po_polygons(gml_id,gml_ids,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	ARRAY[gml_id] AS gml_ids,
	'Gewässer' AS thema,
	'ax_untergeordnetesgewaesser' AS layer,
	polygon,
	signaturnummer,
	modell
FROM (
	SELECT
		gml_id,
		st_multi(wkb_geometry) AS polygon,
		CASE
		WHEN coalesce(funktion,0) IN (0,1010,1011,1012,1013,1020,1030) THEN
			CASE
			WHEN lagezurerdoberflaeche IS NULL AND hydrologischesmerkmal IS NULL THEN 1523
			WHEN lagezurerdoberflaeche IN (1800,1810)                            THEN 1550
			WHEN lagezurerdoberflaeche IS NULL AND hydrologischesmerkmal=2000    THEN 1572
			WHEN lagezurerdoberflaeche IS NULL AND hydrologischesmerkmal=3000    THEN 1573
			END
		WHEN funktion=1040 THEN
			CASE
			WHEN hydrologischesmerkmal IS NULL THEN 1523
			WHEN hydrologischesmerkmal=2000    THEN 1572
			WHEN hydrologischesmerkmal=3000    THEN 1573
			END
		END AS signaturnummer,
		advstandardmodell||sonstigesmodell AS modell
	FROM po_lastrun, ax_untergeordnetesgewaesser o
	WHERE geometrytype(o.wkb_geometry) IN ('POLYGON','MULTIPOLYGON') AND endet IS NULL AND beginnt>lastrun
) AS o
WHERE NOT signaturnummer IS NULL;

-- Symbole
INSERT INTO po_points(gml_id,gml_ids,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	gml_id,
	gml_ids,
	'Gewässer' AS thema,
	'ax_untergeordnetesgewaesser' AS layer,
	st_multi(point),
	drehwinkel,
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		ARRAY[o.gml_id, p.gml_id, d.gml_id] AS gml_ids,
		coalesce(
			p.wkb_geometry,
			CASE
			WHEN geometrytype(o.wkb_geometry) IN ('POLYGON','MULTIPOLYGON') THEN coalesce(alkis_flaechenfuellung(o.wkb_geometry,d.positionierungsregel),st_centroid(o.wkb_geometry))
			WHEN geometrytype(o.wkb_geometry)='LINESTRING'                  THEN st_lineinterpolatepoint( alkis_safe_offsetcurve( o.wkb_geometry, 0.8,''::text ), 0.5 )
			END
		) AS point,
		coalesce(p.drehwinkel,
			CASE
			WHEN geometrytype(o.wkb_geometry)='LINESTRING'
			THEN 0.5*pi()-st_azimuth( st_lineinterpolatepoint( o.wkb_geometry, 0.501), st_lineinterpolatepoint( o.wkb_geometry, 0.499) )
			ELSE 0
			END
		) AS drehwinkel,
		coalesce(
			d.signaturnummer,
			p.signaturnummer,
			CASE
			WHEN coalesce(funktion,0) IN (0,1040) THEN '3490'
			WHEN funktion IN (1010,1011,1012,1013,1020,1030) THEN
				CASE
				WHEN lagezurerdoberflaeche IS NULL AND hydrologischesmerkmal IS NULL THEN '3488'
				WHEN lagezurerdoberflaeche IN (1800,1810)                            THEN '3619'
				WHEN lagezurerdoberflaeche IS NULL AND hydrologischesmerkmal=2000    THEN '3621'
				END
			END
		) AS signaturnummer,
		coalesce(p.modelle, d.modelle, o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM po_lastrun, ax_untergeordnetesgewaesser o
	LEFT OUTER JOIN po_ppo p ON o.gml_id=p.dientzurdarstellungvon AND p.art='FKT'
	LEFT OUTER JOIN po_darstellung d ON o.gml_id=d.dientzurdarstellungvon AND d.art='FKT'
	WHERE o.endet IS NULL AND greatest(o.beginnt, p.beginnt, d.beginnt)>lastrun
) AS o
WHERE NOT point IS NULL;

-- Texte, Lage zur Oberfläche
INSERT INTO po_labels(gml_id,gml_ids,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	gml_ids,
	'Gewässer' AS thema,
	'ax_untergeordnetesgewaesser' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		ARRAY[o.gml_id, t.gml_id, d.gml_id] AS gml_ids,
		coalesce(
			t.wkb_geometry,
			CASE
			WHEN geometrytype(o.wkb_geometry) IN ('POINT','MULTIPOINT') THEN o.wkb_geometry
			WHEN geometrytype(o.wkb_geometry) IN ('POLYGON','MULTIPOLYGON') THEN st_centroid(o.wkb_geometry)
			END
		) AS point,
		(SELECT beschreibung FROM ax_lagezurerdoberflaeche_untergeordnetesgewaesser WHERE wert=lagezurerdoberflaeche) AS text,
		coalesce(d.signaturnummer,t.signaturnummer,'4070') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM po_lastrun, ax_untergeordnetesgewaesser o
	LEFT OUTER JOIN po_pto t ON o.gml_id=t.dientzurdarstellungvon AND t.art='OFL'
	LEFT OUTER JOIN po_darstellung d ON o.gml_id=d.dientzurdarstellungvon AND d.art='OFL'
	WHERE o.endet IS NULL AND lagezurerdoberflaeche IN (1800,1810) AND greatest(o.beginnt, t.beginnt, d.beginnt)>lastrun
) AS o
WHERE NOT text IS NULL;

-- Texte, Graben
INSERT INTO po_labels(gml_id,gml_ids,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	gml_ids,
	'Gewässer' AS thema,
	'ax_untergeordnetesgewaesser' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		ARRAY[o.gml_id, t.gml_id, d.gml_id] AS gml_ids,
		coalesce(
			t.wkb_geometry,
			st_centroid(o.wkb_geometry)
		) AS point,
		'Graben'::text AS text,
		coalesce(d.signaturnummer,t.signaturnummer,'4070') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM po_lastrun, ax_untergeordnetesgewaesser o
	LEFT OUTER JOIN po_pto t ON o.gml_id=t.dientzurdarstellungvon AND t.art='FKT'
	LEFT OUTER JOIN po_darstellung d ON o.gml_id=d.dientzurdarstellungvon AND d.art='FKT'
	WHERE o.endet IS NULL AND funktion=1013 AND lagezurerdoberflaeche IS NULL AND hydrologischesmerkmal=3000 AND greatest(o.beginnt, t.beginnt, d.beginnt)>lastrun
) AS o
WHERE NOT text IS NULL;

-- Namen
INSERT INTO po_labels(gml_id,gml_ids,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	gml_ids,
	'Gewässer' AS thema,
	'ax_untergeordnetesgewaesser' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		ARRAY[o.gml_id, t.gml_id, d.gml_id] AS gml_ids,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(t.schriftinhalt,o.name) AS text,
		coalesce(d.signaturnummer,t.signaturnummer,'4117') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM po_lastrun, ax_untergeordnetesgewaesser o
	LEFT OUTER JOIN po_pto t ON o.gml_id=t.dientzurdarstellungvon AND t.art='NAM'
	LEFT OUTER JOIN po_darstellung d ON o.gml_id=d.dientzurdarstellungvon AND d.art='NAM'
	WHERE o.endet IS NULL AND greatest(o.beginnt, t.beginnt, d.beginnt)>lastrun
) AS o
WHERE NOT text IS NULL;
