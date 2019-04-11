SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Gebäudeteil (31002)
--

SELECT 'Gebäudeteile werden verarbeitet.';

-- Gebäudeteile (Bauteil)
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	'Gebäude' AS thema,
	'ax_bauteil' AS layer,
	polygon,
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
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
		FROM ax_bauteil
		WHERE geometrytype(wkb_geometry) IN ('POLYGON','MULTIPOLYGON') AND endet IS NULL
	) AS o
) AS o
WHERE NOT signaturnummer IS NULL;

-- Gebäudeteilsymbole
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	o.gml_id,
	'Gebäude' AS thema,
	'ax_bauteil_funktion' AS layer,
	st_multi(coalesce(p.wkb_geometry,st_centroid(o.wkb_geometry))) AS point,
	coalesce(p.drehwinkel,0) AS drehwinkel,
	coalesce(d.signaturnummer,p.signaturnummer,'3336') AS signaturnummer,
	coalesce(p.advstandardmodell||p.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM ax_bauteil o
LEFT OUTER JOIN ap_ppo p ON ARRAY[o.gml_id] <@ p.dientzurdarstellungvon AND p.art='BAT' AND p.endet IS NULL
LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='BAT' AND d.endet IS NULL
WHERE bauart=2100 AND o.endet IS NULL;

-- Gebäudeteildachform
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	o.gml_id,
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
	coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM ax_bauteil o
LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='DAF' AND t.endet IS NULL
LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='DAF' AND d.endet IS NULL
WHERE NOT dachform IS NULL AND o.endet IS NULL;

-- Gebäudeteil, oberirdische Geschosse
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	o.gml_id,
	'Gebäude' AS thema,
	'ax_bauteil_geschosse' AS layer,
	coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
	trim(to_char(o.anzahlderoberirdischengeschosse,'RN')) AS text,
	coalesce(d.signaturnummer,t.signaturnummer,'4070') AS signaturnummer,
	drehwinkel, horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung,
	coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM ax_bauteil o
LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='AOG' AND t.endet IS NULL
LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='AOG' AND d.endet IS NULL
WHERE NOT anzahlderoberirdischengeschosse IS NULL AND o.endet IS NULL;

-- Besondere Gebäudelinien
INSERT INTO po_lines(gml_id,thema,layer,line,signaturnummer,modell)
SELECT
	gml_id,
	'Gebäude' AS thema,
	'ax_besonderegebaeudelinie' AS layer,
	st_multi(wkb_geometry) AS line,
	2305 AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ax_besonderegebaeudelinie
WHERE ARRAY[1000] <@ beschaffenheit AND endet IS NULL;

INSERT INTO po_lines(gml_id,thema,layer,line,signaturnummer,modell)
SELECT
	gml_id,
	'Gebäude' AS thema,
	'ax_besonderegebaeudelinie' AS layer,
	st_multi(wkb_geometry) AS line,
	2302 AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ax_besonderegebaeudelinie
WHERE ARRAY[4000] <@ beschaffenheit AND endet IS NULL;

INSERT INTO po_lines(gml_id,thema,layer,line,signaturnummer,modell)
SELECT
	gml_id,
	'Gebäude' AS thema,
	'ax_firstlinie' AS layer,
	st_multi(wkb_geometry) AS line,
	2303 AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ax_firstlinie
WHERE endet IS NULL;
