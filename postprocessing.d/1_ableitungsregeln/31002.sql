SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Gebäudeteil (31002)
--

SELECT 'Gebäudeteile werden verarbeitet.';

-- Gebäudeteile (Bauteil)
INSERT INTO po_polygons(gml_id,gml_ids,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	ARRAY[gml_id] AS gml_ids,
	'Gebäude' AS thema,
	'ax_bauteil' AS layer,
	polygon,
	signaturnummer,
	modell
FROM (
	SELECT
		gml_id,
		st_multi(wkb_geometry) AS polygon,
		CASE
		WHEN bat=1100 AND ofl=0      THEN 2507
		WHEN bat=1100 AND ofl=1400   THEN 2508
		WHEN bat=1200 AND ofl=0      THEN 2507
		WHEN bat=1200 AND ofl=1400   THEN 2508
		WHEN bat=1300 AND ofl=0      THEN 2509
		WHEN bat=1300 AND ofl=1400   THEN 2511
		WHEN bat=1400 AND ofl=0      THEN 2507
		WHEN bat=1400 AND ofl=1400   THEN 2508
		WHEN bat=2000 AND ofl=0      THEN 2507
		WHEN bat=2000 AND ofl=1200   THEN 2512
		WHEN bat=2100 AND ofl=0      THEN 2507
		WHEN bat=2100 AND ofl=1200   THEN 2512
		WHEN bat IN (2300,2350,2400,2500,2510,2520,2610,2620) THEN 2507
		WHEN bat=2710                THEN 2513
		WHEN bat=2720                THEN 2514
		WHEN bat=9999 AND ofl=0      THEN 2507
		WHEN bat=9999 AND ofl=1400   THEN 2508
		END AS signaturnummer,
		modell
	FROM (
		SELECT
			gml_id,
			bauart AS bat,
			coalesce(lagezurerdoberflaeche,0) AS ofl,
			wkb_geometry,
			advstandardmodell||sonstigesmodell AS modell
		FROM po_lastrun, ax_bauteil
		WHERE geometrytype(wkb_geometry) IN ('POLYGON','MULTIPOLYGON') AND endet IS NULL AND beginnt>lastrun
	) AS o
) AS o
WHERE NOT signaturnummer IS NULL;

-- Gebäudeteilsymbole
INSERT INTO po_points(gml_id,gml_ids,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	o.gml_id,
	ARRAY[o.gml_id, p.gml_id, d.gml_id] AS gml_ids,
	'Gebäude' AS thema,
	'ax_bauteil_funktion' AS layer,
	st_multi(coalesce(p.wkb_geometry,st_centroid(o.wkb_geometry))) AS point,
	coalesce(p.drehwinkel,0) AS drehwinkel,
	coalesce(d.signaturnummer,p.signaturnummer,'3336') AS signaturnummer,
	coalesce(p.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM po_lastrun, ax_bauteil o
LEFT OUTER JOIN po_ppo p ON o.gml_id=p.dientzurdarstellungvon AND p.art='BAT'
LEFT OUTER JOIN po_darstellung d ON o.gml_id=d.dientzurdarstellungvon AND d.art='BAT'
WHERE bauart=2100 AND o.endet IS NULL AND greatest(o.beginnt, p.beginnt, d.beginnt)>lastrun;

-- Gebäudeteildachform
INSERT INTO po_labels(gml_id,gml_ids,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	o.gml_id,
	ARRAY[o.gml_id, t.gml_id, d.gml_id] AS gml_ids,
	'Gebäude' AS thema,
	'ax_bauteil_dachform' AS layer,
	coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
	CASE dachform
	WHEN 1000 THEN 'F'
	WHEN 2100 THEN 'P'
	WHEN 2200 THEN 'VP'
	WHEN 3100 THEN 'S'
	WHEN 3200 THEN 'W'
	WHEN 3300 THEN 'KW'
	WHEN 3400 THEN 'M'
	WHEN 3500 THEN 'Z'
	WHEN 3600 THEN 'KE'
	WHEN 3700 THEN 'KU'
	WHEN 3800 THEN 'SH'
	WHEN 3900 THEN 'B'
	WHEN 4000 THEN 'T'
	WHEN 5000 THEN 'MD'
	WHEN 9999 THEN 'SD'
	END AS text,
	coalesce(d.signaturnummer,t.signaturnummer,'4070') AS signaturnummer,
	drehwinkel, horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung,
	coalesce(t.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM po_lastrun, ax_bauteil o
LEFT OUTER JOIN po_pto t ON o.gml_id=t.dientzurdarstellungvon AND t.art='DAF'
LEFT OUTER JOIN po_darstellung d ON o.gml_id=d.dientzurdarstellungvon AND d.art='DAF'
WHERE NOT dachform IS NULL AND o.endet IS NULL AND greatest(o.beginnt, t.beginnt, d.beginnt)>lastrun;

-- Gebäudeteil, oberirdische Geschosse
INSERT INTO po_labels(gml_id,gml_ids,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	o.gml_id,
	ARRAY[o.gml_id, t.gml_id, d.gml_id] AS gml_ids,
	'Gebäude' AS thema,
	'ax_bauteil_geschosse' AS layer,
	coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
	trim(to_char(o.anzahlderoberirdischengeschosse,'RN')) AS text,
	coalesce(d.signaturnummer,t.signaturnummer,'4070') AS signaturnummer,
	drehwinkel, horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung,
	coalesce(t.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM po_lastrun, ax_bauteil o
LEFT OUTER JOIN po_pto t ON o.gml_id=t.dientzurdarstellungvon AND t.art='AOG'
LEFT OUTER JOIN po_darstellung d ON o.gml_id=d.dientzurdarstellungvon AND d.art='AOG'
WHERE NOT anzahlderoberirdischengeschosse IS NULL AND o.endet IS NULL AND greatest(o.beginnt, t.beginnt, d.beginnt)>lastrun;

-- Besondere Gebäudelinien
INSERT INTO po_lines(gml_id,gml_ids,thema,layer,line,signaturnummer,modell)
SELECT
	gml_id,
	ARRAY[gml_id] AS gml_ids,
	'Gebäude' AS thema,
	'ax_besonderegebaeudelinie' AS layer,
	st_multi(wkb_geometry) AS line,
	2305 AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM po_lastrun, ax_besonderegebaeudelinie
WHERE ARRAY[1000] <@ beschaffenheit AND endet IS NULL AND beginnt>lastrun;

INSERT INTO po_lines(gml_id,gml_ids,thema,layer,line,signaturnummer,modell)
SELECT
	gml_id,
	ARRAY[gml_id] AS gml_ids,
	'Gebäude' AS thema,
	'ax_besonderegebaeudelinie' AS layer,
	st_multi(wkb_geometry) AS line,
	2302 AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM po_lastrun, ax_besonderegebaeudelinie
WHERE ARRAY[4000] <@ beschaffenheit AND endet IS NULL AND beginnt>lastrun;

INSERT INTO po_lines(gml_id,gml_ids,thema,layer,line,signaturnummer,modell)
SELECT
	gml_id,
	ARRAY[gml_id] AS gml_id,
	'Gebäude' AS thema,
	'ax_firstlinie' AS layer,
	st_multi(wkb_geometry) AS line,
	2303 AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM po_lastrun, ax_firstlinie
WHERE endet IS NULL AND beginnt>lastrun;
