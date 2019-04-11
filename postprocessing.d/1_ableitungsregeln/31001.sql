SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Gebäude (31001)
--

SELECT 'Gebäude werden verarbeitet.';

-- Gebäudeflächen (Signaturnummer = 2XXX oder 2XXX1XXX)
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	'Gebäude' AS thema,
	'ax_gebaeude' AS layer,
	polygon,
	signaturnummer,
	modell
FROM (
	SELECT
		gml_id,
		st_multi(wkb_geometry) AS polygon,
		CASE
		WHEN gfk='1XXX' THEN
			CASE
			WHEN NOT hoh AND NOT verfallen AND ofl=0           THEN 25051301
			WHEN     hoh AND NOT verfallen AND ofl=0           THEN 26231301
			WHEN     hoh AND     verfallen AND ofl IN (0,1400) THEN 2030
			WHEN     hoh AND NOT verfallen AND ofl=1400        THEN 20301301
			WHEN NOT hoh AND     verfallen AND ofl IN (0,1400) THEN 2031
			WHEN NOT hoh AND NOT verfallen AND ofl=1400        THEN 20311301
			WHEN NOT hoh                   AND ofl=1200        THEN 2032
			END
		WHEN gfk='2XXX' THEN
			CASE
			WHEN NOT hoh AND NOT verfallen AND ofl=0 THEN
				CASE
				WHEN baw=0     THEN 25051304
				WHEN baw<>4000 THEN 25051304
				WHEN baw=4000  THEN 20311304
				END
			WHEN     hoh AND NOT verfallen AND ofl=0           THEN 26231304
			WHEN     hoh AND     verfallen AND ofl IN (0,1400) THEN 2030
			WHEN     hoh AND NOT verfallen AND ofl=1400        THEN 20301304
			WHEN     hoh AND     verfallen AND ofl IN (0,1400) THEN 2031
			WHEN NOT hoh AND NOT verfallen AND ofl=1400        THEN 20311304
			WHEN NOT hoh                   AND ofl=1200        THEN 2032
			END
		WHEN gfk='3XXX' THEN
			CASE
			WHEN NOT hoh AND NOT verfallen AND ofl=0 THEN
				CASE
				WHEN baw=0     THEN 25051309
				WHEN baw<>4000 THEN 25051309
				WHEN baw=4000  THEN 20311309
				END
			WHEN     hoh AND NOT verfallen AND ofl=0           THEN 26231309
			WHEN     hoh AND     verfallen AND ofl IN (0,1400) THEN 2030
			WHEN     hoh AND NOT verfallen AND ofl=1400        THEN 20301309
			WHEN NOT hoh AND     verfallen AND ofl IN (0,1400) THEN 2031
			WHEN NOT hoh AND NOT verfallen AND ofl=1400        THEN 20311309
			WHEN NOT hoh                   AND ofl=1200        THEN 2032
			END
		WHEN gfk='9998' THEN
			CASE
			WHEN NOT hoh AND NOT verfallen AND ofl=0           THEN 25051304
			WHEN     hoh AND NOT verfallen AND ofl=0           THEN 26231304
			WHEN     hoh AND     verfallen AND ofl IN (0,1400) THEN 2030
			WHEN     hoh AND NOT verfallen AND ofl=1400        THEN 20301304
			WHEN NOT hoh AND     verfallen AND ofl IN (0,1400) THEN 2031
			WHEN NOT hoh AND NOT verfallen AND ofl=1400        THEN 20311304
			WHEN NOT hoh                   AND ofl=1200        THEN 2032
			END
		END AS signaturnummer,
		modell
	FROM (
		SELECT
			o.gml_id,
			CASE
			WHEN gebaeudefunktion BETWEEN 1000 AND 1999 THEN '1XXX'
			WHEN gebaeudefunktion BETWEEN 2000 AND 2999 THEN '2XXX'
			WHEN gebaeudefunktion BETWEEN 3000 AND 3999 THEN '3XXX'
			ELSE gebaeudefunktion::text
			END AS gfk,
			coalesce(hochhaus,'false')='true' AS hoh,
			coalesce(zustand,0) IN (2200,2300,3000,4000) AS verfallen,
			coalesce(lagezurerdoberflaeche,0) AS ofl,
			coalesce(bauweise,0) AS baw,
			wkb_geometry,
			o.advstandardmodell||o.sonstigesmodell AS modell
		FROM ax_gebaeude o
		WHERE o.endet IS NULL AND geometrytype(wkb_geometry) IN ('POLYGON','MULTIPOLYGON')
	) AS o
) AS o
WHERE NOT signaturnummer IS NULL;

-- Punktsymbole für Gebäude
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	o.gml_id,
	'Gebäude' AS thema,
	'ax_gebaeude_funktion' AS layer,
	st_multi(coalesce(p.wkb_geometry,st_centroid(o.wkb_geometry))) AS point,
	coalesce(p.drehwinkel,0) AS drehwinkel,
	coalesce(d.signaturnummer,p.signaturnummer,o.signaturnummer) AS signaturnummer,
	coalesce(p.advstandardmodell||p.sonstigesmodell||d.advstandardmodell||d.sonstigesmodell,o.modell) AS modell
FROM (
	SELECT
		gml_id,
		wkb_geometry,
		CASE gebaeudefunktion
		WHEN 2030 THEN '3300'
		WHEN 2056 THEN '3338'
		WHEN 2071 THEN '3302'
		WHEN 2072 THEN '3303'
		WHEN 2081 THEN '3305'
		WHEN 2092 THEN '3306'
		WHEN 2094 THEN '3308'
		WHEN 2461 THEN '3309' WHEN 2462 THEN '3309'
		WHEN 2465 THEN '3336'
		WHEN 2523 THEN CASE WHEN gml_id LIKE 'DERP%' THEN 'RP3521' ELSE '3521' END
		WHEN 2612 THEN '3311'
		WHEN 3013 THEN '3312'
		WHEN 3032 THEN '3314'
		WHEN 3037 THEN '3315'
		WHEN 3041 THEN '3316' -- TODO: PNR 1113?
		WHEN 3042 THEN '3317'
		WHEN 3043 THEN '3318' -- TODO: PNR 1113?
		WHEN 3046 THEN '3319'
		WHEN 3047 THEN '3320'
		WHEN 3051 THEN '3321' WHEN 3052 THEN '3321'
		WHEN 3065 THEN '3323'
		WHEN 3071 THEN '3324'
		WHEN 3072 THEN '3326'
		WHEN 3094 THEN '3328'
		WHEN 3095 THEN '3330'
		WHEN 3097 THEN '3332'
		WHEN 3221 THEN '3334'
		WHEN 3290 THEN '3340'
		END AS signaturnummer,
		advstandardmodell||sonstigesmodell AS modell
	FROM ax_gebaeude
	WHERE endet IS NULL
) AS o
LEFT OUTER JOIN ap_ppo p ON ARRAY[o.gml_id] <@ p.dientzurdarstellungvon AND p.art='GFK' AND p.endet IS NULL
LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='GFK' AND d.endet IS NULL
WHERE NOT o.signaturnummer IS NULL;

-- Gebäudebeschriftungen
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Gebäude' AS thema,
	'ax_gebaeude_funktion' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel, horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung, modell
FROM (
	SELECT
		o.gml_id,
		coalesce(n.wkb_geometry,t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(
			n.schriftinhalt,
			t.schriftinhalt,
			o.name,
			CASE
			WHEN gebaeudefunktion=3012                                              THEN 'Rathaus'  -- TODO: 31001 GFK [3012]?
			WHEN gebaeudefunktion=3014                                              THEN 'Zoll'
			WHEN gebaeudefunktion=3015 AND name IS NULL AND n.schriftinhalt IS NULL THEN 'Gericht'  -- TODO: 31001 GFK [3015]?
			WHEN gebaeudefunktion=3021 AND name IS NULL AND n.schriftinhalt IS NULL THEN 'Schule'
			WHEN gebaeudefunktion=3034 AND name IS NULL AND n.schriftinhalt IS NULL THEN 'Museum'   -- TODO: 31001 GFK [3034]?
			WHEN gebaeudefunktion=3091 AND name IS NULL AND n.schriftinhalt IS NULL THEN 'Bahnhof'
			WHEN gebaeudefunktion=9998                                              THEN 'oF'
			WHEN o.gml_id LIKE 'DERP%' THEN
				CASE
				WHEN gebaeudefunktion=2513 THEN 'Wbh'
				WHEN gebaeudefunktion IN (3011,3016,3017,3019,3024,3031,3033,3035,3036,3061,3062,3073,3074,3075,3080,3081,3092,3242) THEN
					(SELECT beschreibung FROM ax_gebaeudefunktion WHERE wert=gebaeudefunktion)
				WHEN gebaeudefunktion=3022 THEN 'Schule'
				WHEN gebaeudefunktion=3023 THEN 'Hochschule'
				WHEN gebaeudefunktion=3038 THEN 'Burg'
				WHEN gebaeudefunktion=3211 THEN 'Sporthalle'
				END
			END
		) AS text,
		coalesce(d.signaturnummer,CASE WHEN name IS NULL AND n.schriftinhalt IS NULL THEN t.signaturnummer ELSE n.signaturnummer END,'4070') AS signaturnummer,
		CASE WHEN name IS NULL AND n.schriftinhalt IS NULL THEN t.drehwinkel ELSE n.drehwinkel END AS drehwinkel,
		CASE WHEN name IS NULL AND n.schriftinhalt IS NULL THEN t.horizontaleausrichtung ELSE n.horizontaleausrichtung END AS horizontaleausrichtung,
		CASE WHEN name IS NULL AND n.schriftinhalt IS NULL THEN t.vertikaleausrichtung ELSE n.vertikaleausrichtung END AS vertikaleausrichtung,
		CASE WHEN name IS NULL AND n.schriftinhalt IS NULL THEN t.skalierung ELSE n.skalierung END AS skalierung,
		CASE WHEN name IS NULL AND n.schriftinhalt IS NULL THEN t.fontsperrung ELSE n.fontsperrung END AS fontsperrung,
		coalesce(
			t.advstandardmodell||t.sonstigesmodell||n.advstandardmodell||n.sonstigesmodell,
			o.modell
		) AS modell
	FROM (
		SELECT gml_id, wkb_geometry, gebaeudefunktion, unnest(coalesce(name,ARRAY[NULL])) AS name,advstandardmodell||sonstigesmodell AS modell
		FROM ax_gebaeude
		WHERE endet IS NULL
	) AS o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='GFK' AND t.endet IS NULL
	LEFT OUTER JOIN ap_pto n ON ARRAY[o.gml_id] <@ n.dientzurdarstellungvon AND n.art='NAM' AND n.endet IS NULL
	LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art IN ('GFK','NAM') AND d.endet IS NULL
) AS o
WHERE NOT text IS NULL;

-- Weitere Gebäudefunktion
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	o.gml_id,
	'Gebäude' AS thema,
	'ax_gebaeude_funktion' AS layer,
	st_multi(coalesce(p.wkb_geometry,st_centroid(o.wkb_geometry))) AS point,
	p.drehwinkel,
	coalesce(d.signaturnummer,p.signaturnummer,o.signaturnummer) AS signaturnummer,
	coalesce(p.advstandardmodell||p.sonstigesmodell,o.modell) AS modell
FROM (
	SELECT
		o.gml_id,
		wkb_geometry,
		CASE gebaeudefunktion
		WHEN 1000 THEN '3300'
		WHEN 1010 THEN '3302'
		WHEN 1020 THEN '3303'
		WHEN 1030 THEN '3305'
		WHEN 1040 THEN '3306'
		WHEN 1050 THEN '3308'
		WHEN 1060 THEN '3336'
		WHEN 1070 THEN '3309'
		WHEN 1080 THEN '3311'
		WHEN 1090 THEN '3112'
		WHEN 1110 THEN '3314'
		WHEN 1130 THEN '3315'
		WHEN 1140 THEN '3318'  -- TODO: Kapelle PNR 1113?
		WHEN 1150 THEN '3319'
		WHEN 1160 THEN '3320'
		WHEN 1170 THEN '3338'
		WHEN 1180 THEN '3324'
		WHEN 1190 THEN '3321'
		WHEN 1200 THEN '3340'
		WHEN 1210 THEN '3323'
		WHEN 1220 THEN '3324'
		END AS signaturnummer,
		modell
	FROM (
		SELECT
			gml_id,
			wkb_geometry,
			unnest(weiteregebaeudefunktion) AS gebaeudefunktion,
			advstandardmodell||sonstigesmodell AS modell
		FROM ax_gebaeude
		WHERE NOT weiteregebaeudefunktion IS NULL AND endet IS NULL
	) AS o
) AS o
LEFT OUTER JOIN ap_ppo p ON ARRAY[o.gml_id] <@ p.dientzurdarstellungvon AND p.art='GFK' AND p.endet IS NULL
LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='GFK' AND d.endet IS NULL
WHERE NOT o.signaturnummer IS NULL;

-- Weitere Gebäudefunktionsbeschriftungen
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	o.gml_id,
	'Gebäude' AS thema,
	'ax_gebaeude_funktion' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel, horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung, modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		CASE
		WHEN gebaeudefunktion=1100 AND coalesce(name,n.schriftinhalt) IS NULL THEN 'Zoll'
		WHEN gebaeudefunktion=1129 AND coalesce(name,n.schriftinhalt) IS NULL THEN 'Museum'   -- TODO: 31001 GFK [3034]?
		END AS text,
		CASE WHEN name IS NULL AND n.schriftinhalt IS NULL THEN t.drehwinkel ELSE n.drehwinkel END AS drehwinkel,
		coalesce(d.signaturnummer,CASE WHEN name IS NULL AND n.schriftinhalt IS NULL THEN t.signaturnummer ELSE n.signaturnummer END,'4070') AS signaturnummer,
		CASE WHEN name IS NULL AND n.schriftinhalt IS NULL THEN t.horizontaleausrichtung ELSE n.horizontaleausrichtung END AS horizontaleausrichtung,
		CASE WHEN name IS NULL AND n.schriftinhalt IS NULL THEN t.vertikaleausrichtung ELSE n.vertikaleausrichtung END AS vertikaleausrichtung,
		CASE WHEN name IS NULL AND n.schriftinhalt IS NULL THEN t.skalierung ELSE n.skalierung END AS skalierung,
		CASE WHEN name IS NULL AND n.schriftinhalt IS NULL THEN t.fontsperrung ELSE n.fontsperrung END AS fontsperrung,
		coalesce(
			t.advstandardmodell||t.sonstigesmodell||n.advstandardmodell||n.sonstigesmodell,
			o.modell
		) AS modell
	FROM (
		SELECT
			gml_id,
			wkb_geometry,
			unnest(coalesce(name,ARRAY[NULL])) AS name,
			unnest(weiteregebaeudefunktion) AS gebaeudefunktion,
			advstandardmodell||sonstigesmodell AS modell
		FROM ax_gebaeude o
		WHERE endet IS NULL
	) AS o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='GFK' AND t.endet IS NULL
	LEFT OUTER JOIN ap_pto n ON ARRAY[o.gml_id] <@ n.dientzurdarstellungvon AND n.art='NAM' AND n.endet IS NULL
	LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art IN ('NAM','GFK') AND d.endet IS NULL
	WHERE NOT gebaeudefunktion IS NULL
) AS o
WHERE NOT text IS NULL;

/*
-- TODO: Gebäudenamen für weitere Funktionen  (Mehrere Namen? Und Funktionen? Gleich viele oder wie ist das zu kombinieren?)
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	o.gml_id,
	'Gebäude' AS thema,
	'ax_gebaeude' AS layer,
	unnest(coalesce(name,ARRAY[NULL])),
	coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry))  AS point,
	coalesce(t.schriftinhalt,o.zaehler||'/'||o.nenner,o.zaehler::text) AS text,
	coalesce(t.signaturnummer,CASE WHEN o.abweichenderrechtszustand='true' THEN 4112 ELSE 4111 END) AS signaturnummer,
	drehwinkel, horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung,
	coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM ax_gebaeude o
LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='ZAE_NEN' AND (t.signaturnummer IS NULL OR t.signaturnummer IN ('4122','4123')) AND t.endet IS NULL
WHERE NOT name IS NULL AND o.endet IS NULL;
*/

-- Geschosszahl
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	o.gml_id,
	'Gebäude' AS thema,
	'ax_gebaeude_geschosse' AS layer,
	coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
	coalesce(
		trim(to_char(o.anzahlderoberirdischengeschosse,'RN'))||' / -'||trim(to_char(o.anzahlderunterirdischengeschosse,'RN')),
		trim(to_char(o.anzahlderoberirdischengeschosse,'RN')),
		'-'||trim(to_char(o.anzahlderunterirdischengeschosse,'RN'))
	) AS text,
	coalesce(d.signaturnummer,t.signaturnummer,'4070') AS signaturnummer,
	drehwinkel, horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung,
	coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM ax_gebaeude o
LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='AOG_AUG' AND t.endet IS NULL
LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='AOG_AUG' AND d.endet IS NULL
WHERE (NOT anzahlderoberirdischengeschosse IS NULL OR NOT anzahlderunterirdischengeschosse IS NULL) AND o.endet IS NULL;

-- Dachform
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	o.gml_id,
	'Gebäude' AS thema,
	'ax_gebaeude_dachform' AS layer,
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
FROM ax_gebaeude o
LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='DAF' AND t.endet IS NULL
LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='DAF' AND d.endet IS NULL
WHERE NOT dachform IS NULL AND o.endet IS NULL;

-- Gebäudezustände
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	o.gml_id,
	'Gebäude' AS thema,
	'ax_gebaeude_zustand' AS layer,
	coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
	coalesce(
		t.schriftinhalt,
		CASE zustand
		WHEN 2200 THEN '(zerstört)'
		WHEN 2300 THEN '(teilweise zerstört)'
		WHEN 3000 THEN '(geplant)'
		WHEN 4000 THEN '(im Bau)'
		END) AS text,
	coalesce(d.signaturnummer,t.signaturnummer,'4070') AS signaturnummer,
	drehwinkel, horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung,
	coalesce(o.advstandardmodell||o.sonstigesmodell,t.advstandardmodell||t.sonstigesmodell) AS modell
FROM ax_gebaeude o
LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='ZUS' AND t.endet IS NULL
LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='ZUS' AND d.endet IS NULL
WHERE zustand IN (2200,2300,3000,4000) AND o.endet IS NULL;
