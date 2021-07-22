SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Flurstücke (11001)
--

SELECT 'Flurstücke werden verarbeitet.';

-- Flurstücke
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	'Flurstücke' AS thema,
	'ax_flurstueck' AS layer,
	st_multi(wkb_geometry) AS polygon,
	2028 AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ax_flurstueck
WHERE endet IS NULL;

UPDATE ax_flurstueck SET abweichenderrechtszustand='false' WHERE abweichenderrechtszustand IS NULL;

SELECT count(*) || ' Flurstücke mit abweichendem Rechtszustand.' FROM ax_flurstueck WHERE abweichenderrechtszustand='true';

-- Flurstücksgrenzen mit abweichendem Rechtszustand
SELECT 'Bestimme Grenzen mit abweichendem Rechtszustand';
INSERT INTO po_lines(gml_id,thema,layer,line,signaturnummer,modell)
SELECT
	a.gml_id,
	'Flurstücke' AS thema,
	'ax_flurstueck' AS layer,
	st_multi( (SELECT st_collect(geom) FROM st_dump( st_intersection(a.wkb_geometry,b.wkb_geometry) ) WHERE geometrytype(geom)='LINESTRING') ) AS line,
	2029 AS signaturnummer,
	a.advstandardmodell||a.sonstigesmodell||b.advstandardmodell||b.sonstigesmodell AS modell
FROM ax_flurstueck a, ax_flurstueck b
WHERE a.ogc_fid<b.ogc_fid
  AND a.abweichenderrechtszustand='true' AND b.abweichenderrechtszustand='true'
  AND a.wkb_geometry && b.wkb_geometry AND st_intersects(a.wkb_geometry,b.wkb_geometry)
  AND a.endet IS NULL AND b.endet IS NULL;


--                    ARZ
-- Schrägstrich: 4113 4122
-- Bruchstrich:  4115 4123

-- Flurstücksnummern
-- Schrägstrichdarstellung
SELECT 'Erzeuge Flurstücksnummern in Schrägstrichdarstellung...';
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	o.gml_id,
	'Flurstücke' AS thema,
	'ax_flurstueck_nummer' AS layer,
	coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
	coalesce(replace(t.schriftinhalt,'-','/'),o.zaehler||'/'||o.nenner,o.zaehler::text) AS text,
	coalesce(d.signaturnummer,t.signaturnummer,CASE WHEN o.abweichenderrechtszustand='true' THEN '4122' ELSE '4113' END) AS signaturnummer,
	t.drehwinkel, t.horizontaleausrichtung, t.vertikaleausrichtung, t.skalierung, t.fontsperrung,
	coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM ax_flurstueck o
LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='ZAE_NEN' AND t.endet IS NULL
LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='ZAE_NEN' AND d.endet IS NULL
WHERE o.endet IS NULL AND (
	CASE
	WHEN :alkis_fnbruch
	THEN coalesce(t.signaturnummer,'4115') IN ('4113','4122')
	ELSE coalesce(t.signaturnummer,'4113') NOT IN ('4115', '4123')
	END
	OR coalesce(o.nenner,'0')='0'
);

-- Zähler
-- Bruchdarstellung
SELECT 'Erzeuge Flurstückszähler...';
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Flurstücke' AS thema,
	'ax_flurstueck_nummer' AS layer,
	CASE
	WHEN horizontaleausrichtung='rechtsbündig' THEN st_translate(point, -len, 0.0)
	WHEN horizontaleausrichtung='linksbündig' THEN st_translate(point, len, 0.0)
	ELSE point
	END AS point,
	text,signaturnummer,drehwinkel,'zentrisch' AS horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		gml_id,
		point,
		greatest(lenz, lenn) AS len,
		text,
		signaturnummer,
		drehwinkel,
		horizontaleausrichtung,
		vertikaleausrichtung,
		skalierung,
		fontsperrung,
		modell
	FROM (
		SELECT
			o.gml_id,
			st_translate(coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)), 0, 0.40) AS point,
			length(coalesce(split_part(replace(t.schriftinhalt,'-','/'),'/',1),o.zaehler::text)) AS lenz,
			length(coalesce(split_part(replace(t.schriftinhalt,'-','/'),'/',2),o.nenner::text)) AS lenn,
			coalesce(split_part(replace(t.schriftinhalt,'-','/'),'/',1),o.zaehler::text) AS text,
			coalesce(d.signaturnummer,t.signaturnummer,CASE WHEN o.abweichenderrechtszustand='true' THEN '4123' ELSE '4115' END) AS signaturnummer,
			t.drehwinkel, t.horizontaleausrichtung, 'Basis'::text AS vertikaleausrichtung, t.skalierung, t.fontsperrung,
			coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
		FROM ax_flurstueck o
		LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.endet IS NULL
		LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.endet IS NULL
		WHERE o.endet IS NULL AND
			CASE
			WHEN :alkis_fnbruch
			THEN coalesce(t.signaturnummer,'4115') NOT IN ('4113','4122')
			ELSE coalesce(t.signaturnummer,'4113') IN ('4115', '4123')
			END
			AND coalesce(o.nenner,'0')<>'0'
	) AS foo
) AS foo;

-- Nenner
-- Bruchdarstellung
SELECT 'Erzeuge Flurstücksnenner...';
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Flurstücke' AS thema,
	'ax_flurstueck_nummer' AS layer,
	CASE
	WHEN horizontaleausrichtung='rechtsbündig' THEN st_translate(point, -len, 0.0)
	WHEN horizontaleausrichtung='linksbündig' THEN st_translate(point, len, 0.0)
	ELSE point
	END AS point,
	text,signaturnummer,drehwinkel,'zentrisch' AS horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		gml_id,
		point,
		greatest(lenz, lenn) AS len,
		text,
		signaturnummer,
		drehwinkel,
		horizontaleausrichtung,
		vertikaleausrichtung,
		skalierung,
		fontsperrung,
		modell
	FROM (
		SELECT
			o.gml_id,
			st_translate(coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)), 0, -0.40) AS point,
			length(coalesce(split_part(replace(t.schriftinhalt,'-','/'),'/',1),o.zaehler::text)) AS lenz,
			length(coalesce(split_part(replace(t.schriftinhalt,'-','/'),'/',2),o.nenner::text)) AS lenn,
			coalesce(split_part(replace(t.schriftinhalt,'-','/'),'/',2)::text,o.nenner::text) AS text,
			coalesce(d.signaturnummer,t.signaturnummer,CASE WHEN o.abweichenderrechtszustand='true' THEN '4123' ELSE '4115' END) AS signaturnummer,
			t.drehwinkel, t.horizontaleausrichtung, 'oben'::text AS vertikaleausrichtung, t.skalierung, t.fontsperrung,
			coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
		FROM ax_flurstueck o
		LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.endet IS NULL
		LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.endet IS NULL
		WHERE o.endet IS NULL AND
			CASE
			WHEN :alkis_fnbruch
			THEN coalesce(t.signaturnummer,'4115') NOT IN ('4113','4122')
			ELSE coalesce(t.signaturnummer,'4113') IN ('4115', '4123')
			END AND
			coalesce(o.nenner,'0')<>'0'
	) AS foo
	WHERE NOT text IS NULL
) AS foo;

-- Bruchstrich
SELECT 'Erzeuge Flurstücksbruchstriche...';
INSERT INTO po_lines(gml_id,thema,layer,line,signaturnummer,modell)
SELECT
	gml_id,
	'Flurstücke' AS thema,
	'ax_flurstueck_nummer' AS layer,
	CASE
	WHEN horizontaleausrichtung='rechtsbündig' THEN st_multi(st_rotate(st_makeline(st_translate(point, -(2*len), 0.0), st_translate(point, 0.0, 0.0)),drehwinkel,st_x(point),st_y(point)))
	WHEN horizontaleausrichtung='linksbündig' THEN st_multi(st_rotate(st_makeline(st_translate(point, 0.0, 0.0), st_translate(point, 2*len, 0.0)),drehwinkel,st_x(point),st_y(point)))
	ELSE st_multi(st_rotate(st_makeline(st_translate(point, -len, 0.0), st_translate(point, len, 0.0)),drehwinkel,st_x(point),st_y(point)))
	END AS line,
	signaturnummer,
	modell
FROM (
	SELECT
		gml_id,
		point,
		greatest(lenz, lenn) AS len,
		signaturnummer,
		modell,
		drehwinkel,
		horizontaleausrichtung
	FROM (
		SELECT
			o.gml_id,
			coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
			length(coalesce(split_part(replace(t.schriftinhalt,'-','/'),'/',1),o.zaehler::text)) AS lenn,
			length(coalesce(split_part(replace(t.schriftinhalt,'-','/'),'/',2),o.nenner::text)) AS lenz,
			coalesce(d.signaturnummer,'2001') AS signaturnummer,
			coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell,
			coalesce(t.drehwinkel,0) AS drehwinkel,
			t.horizontaleausrichtung
		FROM ax_flurstueck o
		LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.endet IS NULL
		LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.endet IS NULL
		WHERE o.endet IS NULL AND
			CASE
			WHEN :alkis_fnbruch
			THEN coalesce(t.signaturnummer,'4115') NOT IN ('4113','4122')
			ELSE coalesce(t.signaturnummer,'4113') IN ('4115', '4123')
			END AND
			coalesce(o.nenner,'0')<>'0'
	) AS bruchstrich0 WHERE lenz>0 AND lenn>0
) AS bruchstrich1;

-- Zuordnungspfeile
SELECT 'Erzeuge Zuordnungspfeile...';
INSERT INTO po_lines(gml_id,thema,layer,line,signaturnummer,modell)
SELECT
	o.gml_id,
	'Flurstücke' AS thema,
	'ax_flurstueck_zuordnung' AS layer,
	st_multi(l.wkb_geometry) AS line,
	CASE WHEN o.abweichenderrechtszustand='true' THEN 2005 ELSE 2004 END AS signaturnummer,
	coalesce(l.advstandardmodell||l.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM ax_flurstueck o
JOIN ap_lpo l ON ARRAY[o.gml_id] <@ l.dientzurdarstellungvon AND l.endet IS NULL
  -- AND l.art='Pfeil' -- art in RP nicht immer gesetzt
WHERE o.endet IS NULL;

-- Überhaken
SELECT 'Erzeuge Überhaken...';
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	o.gml_id,
	'Flurstücke' AS thema,
	'ax_flurstueck' AS layer,
	st_multi(p.wkb_geometry) AS point,
	coalesce(p.drehwinkel,0) AS drehwinkel,
	CASE WHEN o.abweichenderrechtszustand='true' THEN 3011 ELSE 3010 END AS signaturnummer,
	coalesce(p.advstandardmodell||p.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM ax_flurstueck o
JOIN ap_ppo p ON ARRAY[o.gml_id] <@ p.dientzurdarstellungvon AND p.art='Haken' AND p.endet IS NULL
WHERE o.endet IS NULL;
