SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

DELETE FROM alkis_schriften WHERE signaturnummer IN ('pg-flur','pg-gemarkung','pg-gemeinde','pg-kreis');
DELETE FROM alkis_linie WHERE signaturnummer IN ('pg-flur','pg-gemarkung','pg-gemeinde','pg-kreis');
DELETE FROM alkis_linien WHERE signaturnummer IN ('pg-flur','pg-gemarkung','pg-gemeinde','pg-kreis');

INSERT INTO alkis_linien(katalog,signaturnummer,darstellungsprioritaet,name)
	SELECT
		katalog,
		signaturnummer,
		'450' AS darstellungsprioritaet,
		ARRAY['norGIS: ' || CASE signaturnummer
		WHEN 'pg-flur' THEN 'Flurgrenze'
		WHEN 'pg-gemarkung' THEN 'Gemarkungsgrenze'
		WHEN 'pg-gemeinde' THEN 'Gemeindegrenze'
		WHEN 'pg-kreis' THEN 'Kreisgrenze'
		END] AS name
	FROM generate_series(1,2) AS katalog, unnest(ARRAY['pg-flur','pg-gemarkung','pg-gemeinde','pg-kreis']) AS signaturnummer;

INSERT INTO alkis_linie(id,i,katalog,signaturnummer,strichart,abschluss,scheitel,strichstaerke,pfeilhoehe,pfeillaenge,farbe,position)
	SELECT
		(SELECT max(id)+1 FROM alkis_linie)+row_number() OVER () AS id,
		0 AS i,
		katalog,
		signaturnummer,
		NULL AS strichart,
		/* abschluss */ 'Abgeschnitten',
		/* scheitel */ 'Spitz',
		CASE signaturnummer
		WHEN 'pg-flur' THEN -40
		WHEN 'pg-gemarkung' THEN -60
		WHEN 'pg-gemeinde' THEN -80
		WHEN 'pg-kreis' THEN -100
		END AS grad_pt,
		NULL AS pfeilhoehe,
		NULL AS pfeillaenge,
		(SELECT farbe FROM alkis_linie WHERE katalog=1 AND signaturnummer='2012' AND i=0) AS farbe, -- Farbe aus Flurgrenze 2028
		NULL as position
	FROM generate_series(1,2) AS katalog, unnest(ARRAY['pg-flur','pg-gemarkung','pg-gemeinde','pg-kreis']) AS signaturnummer;

INSERT INTO alkis_schriften(katalog,signaturnummer,darstellungsprioritaet,name,seite,art,stil,grad_pt,horizontaleausrichtung,vertikaleausrichtung,farbe,alignment_umn,alignment_dxf,sperrung_pt,effekt,position)
	SELECT
		katalog,
		signaturnummer,
		'450' AS darstellungsprioritaet,
		ARRAY['norGIS: ' || CASE signaturnummer
		WHEN 'pg-flur' THEN 'Flurgrenze'
		WHEN 'pg-gemarkung' THEN 'Gemarkungsgrenze'
		WHEN 'pg-gemeinde' THEN 'Gemeindegrenze'
		WHEN 'pg-kreis' THEN 'Kreisgrenze'
		END] AS name,
		NULL AS seite,
		'Arial' AS art,
		'Normal' AS stil,
		CASE signaturnummer
		WHEN 'pg-flur' THEN -6
		WHEN 'pg-gemarkung' THEN -10
		WHEN 'pg-gemeinde' THEN -12
		WHEN 'pg-kreis' THEN -14
		END AS grad_pt,
		'zentrisch' AS horizontaleausrichtung,
		'Mitte' AS vertikaleausrichtung,
		(SELECT farbe FROM alkis_linie WHERE katalog=1 AND signaturnummer='2012' and i=0) AS farbe, -- Farbe wie Grenze
		'CC' AS alignment_umn,
		5 AS alignment_dxf,
		NULL AS sperrung_pt,
		NULL AS effekt,
		NULL AS position
	FROM generate_series(1,2) AS katalog, unnest(ARRAY['pg-flur','pg-gemarkung','pg-gemeinde','pg-kreis']) AS signaturnummer;

DELETE FROM po_polygons WHERE sn_randlinie IN ('pg-flur','pg-gemarkung','pg-gemeinde','pg-kreis');
DELETE FROM po_labels WHERE signaturnummer IN ('pg-flur','pg-gemarkung','pg-gemeinde','pg-kreis');

CREATE TEMPORARY TABLE pp_gemarkungen AS
	SELECT
		gemeindezugehoerigkeit_land,
		coalesce(gemeindezugehoerigkeit_regierungsbezirk,'') AS gemeindezugehoerigkeit_regierungsbezirk,
		gemeindezugehoerigkeit_kreis,
		gemeindezugehoerigkeit_gemeinde,
		gemarkungsnummer,
		coalesce(
			(SELECT bezeichnung FROM ax_gemarkung b WHERE a.gemeindezugehoerigkeit_land=b.land AND a.gemarkungsnummer=b.gemarkungsnummer AND b.endet IS NULL LIMIT 1),
			'(Gemarkung '||gemeindezugehoerigkeit_land||gemarkungsnummer||')'
		) AS gemarkungsname
	FROM ax_flurstueck a
	WHERE endet IS NULL
	GROUP BY gemeindezugehoerigkeit_land, gemeindezugehoerigkeit_regierungsbezirk, gemeindezugehoerigkeit_kreis, gemeindezugehoerigkeit_gemeinde, gemarkungsnummer
	ORDER BY gemeindezugehoerigkeit_land, gemeindezugehoerigkeit_regierungsbezirk, gemeindezugehoerigkeit_kreis, gemeindezugehoerigkeit_gemeinde, gemarkungsnummer;

CREATE INDEX pp_gemarkungen_lrkg ON pp_gemarkungen(gemeindezugehoerigkeit_land, gemeindezugehoerigkeit_regierungsbezirk, gemeindezugehoerigkeit_kreis, gemeindezugehoerigkeit_gemeinde);
CREATE INDEX pp_gemarkungen_lg ON pp_gemarkungen(gemeindezugehoerigkeit_land, gemarkungsnummer);
ANALYZE pp_gemarkungen;

SELECT alkis_dropobject('ax_flurstueck_lgf');
CREATE INDEX ax_flurstueck_lgf ON ax_flurstueck(gemeindezugehoerigkeit_land,gemarkungsnummer,flurnummer);

CREATE TEMPORARY TABLE pp_gemeinden AS
	SELECT
		gemeindezugehoerigkeit_land,
		coalesce(gemeindezugehoerigkeit_regierungsbezirk,'') AS gemeindezugehoerigkeit_regierungsbezirk,
		gemeindezugehoerigkeit_kreis,
		gemeindezugehoerigkeit_gemeinde,
		coalesce(
			(SELECT bezeichnung FROM ax_gemeinde b WHERE a.gemeindezugehoerigkeit_land=b.land AND coalesce(a.gemeindezugehoerigkeit_regierungsbezirk,'')=coalesce(b.regierungsbezirk,'') AND a.gemeindezugehoerigkeit_kreis=b.kreis AND a.gemeindezugehoerigkeit_gemeinde=b.gemeinde AND b.endet IS NULL LIMIT 1),
			'(Gemeinde '||gemeindezugehoerigkeit_land||coalesce(gemeindezugehoerigkeit_regierungsbezirk,'')||gemeindezugehoerigkeit_kreis||gemeindezugehoerigkeit_gemeinde||')'
		) AS gemeindename
	FROM pg_temp.pp_gemarkungen a
	GROUP BY gemeindezugehoerigkeit_land, gemeindezugehoerigkeit_regierungsbezirk, gemeindezugehoerigkeit_kreis, gemeindezugehoerigkeit_gemeinde
	ORDER BY gemeindezugehoerigkeit_land, gemeindezugehoerigkeit_regierungsbezirk, gemeindezugehoerigkeit_kreis, gemeindezugehoerigkeit_gemeinde;

CREATE INDEX pp_gemeinden_lrkg ON pp_gemeinden(gemeindezugehoerigkeit_land, gemeindezugehoerigkeit_regierungsbezirk, gemeindezugehoerigkeit_kreis, gemeindezugehoerigkeit_gemeinde);
ANALYZE pp_gemeinden;

CREATE TEMPORARY TABLE pp_kreise AS
	SELECT
		gemeindezugehoerigkeit_land,
		coalesce(gemeindezugehoerigkeit_regierungsbezirk,'') AS gemeindezugehoerigkeit_regierungsbezirk,
		gemeindezugehoerigkeit_kreis,
		coalesce(
			(SELECT bezeichnung FROM ax_kreisregion b WHERE a.gemeindezugehoerigkeit_land=b.land AND coalesce(a.gemeindezugehoerigkeit_regierungsbezirk,'')=coalesce(b.regierungsbezirk,'') AND a.gemeindezugehoerigkeit_kreis=b.kreis AND b.endet IS NULL LIMIT 1),
			'(Kreis '||gemeindezugehoerigkeit_land||coalesce(gemeindezugehoerigkeit_regierungsbezirk,'')||gemeindezugehoerigkeit_kreis||')'
		) AS kreisname
	FROM pg_temp.pp_gemeinden a
	GROUP BY gemeindezugehoerigkeit_land, gemeindezugehoerigkeit_regierungsbezirk, gemeindezugehoerigkeit_kreis
	ORDER BY gemeindezugehoerigkeit_land, gemeindezugehoerigkeit_regierungsbezirk, gemeindezugehoerigkeit_kreis;

CREATE INDEX pp_kreise_lrk ON pp_kreise(gemeindezugehoerigkeit_land, gemeindezugehoerigkeit_regierungsbezirk, gemeindezugehoerigkeit_kreis);
ANALYZE pp_kreise;

\set flur_buffer 0.06
\set flur_simplify 0.5
\set gemarkung_simplify 2.2
\set gemeinde_simplify 5.0
\set kreis_simplify 7.0

CREATE FUNCTION pg_temp.pointonsurface(polygon GEOMETRY) RETURNS GEOMETRY AS $$
BEGIN
	BEGIN
		RETURN st_pointonsurface(polygon);
	EXCEPTION WHEN OTHERS THEN
		BEGIN
			RETURN st_centroid(polygon);
		EXCEPTION WHEN OTHERS THEN
			RETURN NULL;
		END;
	END;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

--
-- Flure
--
SELECT 'Flurgrenzen werden aufbereitet...';

INSERT INTO po_polygons(gml_id,thema,layer,signaturnummer,sn_randlinie,modell,polygon)
	SELECT
		min(gml_id) AS gml_id,
		'Politische Grenzen' AS thema,
		'ax_flurstueck_flur_'||gemeindezugehoerigkeit_land||gemarkungsnummer||coalesce(flurnummer,0) AS layer,
		'pg-flur' AS signaturnummer,
		'pg-flur' AS sn_randlinie,
		ARRAY['norGIS'] AS modell,
		st_multi(st_simplify(st_union(st_buffer(wkb_geometry,:flur_buffer)), :flur_simplify)) AS polygon
	FROM ax_flurstueck
	JOIN pg_temp.pp_gemarkungen USING (gemeindezugehoerigkeit_land,gemarkungsnummer)
	WHERE endet IS NULL
	GROUP BY gemeindezugehoerigkeit_land, gemarkungsnummer, flurnummer;

INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,modell)
	SELECT
		gml_id,
		'Politische Grenzen' AS thema,
		layer,
		pg_temp.pointonsurface(polygon) AS point,
		'Flur '||replace(layer, 'ax_flurstueck_flur_'||gemeindezugehoerigkeit_land||gemarkungsnummer, '') AS text,
		'pg-flur' AS signaturnummer,
		0 AS drehwinkel,
		ARRAY['norGIS'] AS modell
	FROM po_polygons
	JOIN pg_temp.pp_gemarkungen p ON layer LIKE 'ax_flurstueck_flur_'||gemeindezugehoerigkeit_land||gemarkungsnummer||'%' ESCAPE '?';

--
-- Gemarkungen
--
SELECT 'Gemarkungsgrenzen werden aufbereitet...';

INSERT INTO po_polygons(gml_id,thema,layer,signaturnummer,sn_randlinie,modell,polygon)
	SELECT
		min(gml_id) AS gml_id,
		'Politische Grenzen' AS thema,
		'ax_flurstueck_gemarkung_'||gemeindezugehoerigkeit_land||gemarkungsnummer AS layer,
		'pg-gemarkung' AS signaturnummer,
		'pg-gemarkung' AS sn_randlinie,
		ARRAY['norGIS'] AS modell,
		st_multi(st_simplify(st_union(st_buffer(polygon, 0.15)), :gemarkung_simplify)) AS polygon
	FROM po_polygons
	JOIN pg_temp.pp_gemarkungen p ON layer LIKE 'ax_flurstueck_flur_'||gemeindezugehoerigkeit_land||gemarkungsnummer||'%' ESCAPE '?'
	GROUP BY gemeindezugehoerigkeit_land, gemarkungsnummer;

INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,modell)
	SELECT
		gml_id,
		'Politische Grenzen' AS thema,
		layer,
		pg_temp.pointonsurface(polygon) AS point,
		gemarkungsname AS text,
		'pg-gemarkung' AS signaturnummer,
		0 AS drehwinkel,
		ARRAY['norGIS'] AS modell
	FROM po_polygons
	JOIN pp_gemarkungen p ON layer='ax_flurstueck_gemarkung_'||gemeindezugehoerigkeit_land||gemarkungsnummer;

--
-- Gemeinden
--
SELECT 'Gemeindegrenzen werden aufbereitet...';

INSERT INTO po_polygons(gml_id,thema,layer,signaturnummer,sn_randlinie,modell,polygon)
	SELECT
		min(gml_id) AS gml_id,
		'Politische Grenzen' AS thema,
		'ax_flurstueck_gemeinde_'||gemeindezugehoerigkeit_land||gemeindezugehoerigkeit_regierungsbezirk||gemeindezugehoerigkeit_kreis||gemeindezugehoerigkeit_gemeinde AS layer,
		'pg-gemeinde' AS signaturnummer,
		'pg-gemeinde' AS sn_randlinie,
		ARRAY['norGIS'] AS modell,
		st_multi(st_simplify(st_union(st_buffer(polygon,0.20)), :gemeinde_simplify)) AS polygon
	FROM po_polygons
	JOIN pg_temp.pp_gemarkungen ON layer='ax_flurstueck_gemarkung_'||gemeindezugehoerigkeit_land||gemarkungsnummer
	GROUP BY gemeindezugehoerigkeit_land, gemeindezugehoerigkeit_regierungsbezirk, gemeindezugehoerigkeit_kreis, gemeindezugehoerigkeit_gemeinde;

INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,modell)
	SELECT
		gml_id,
		'Politische Grenzen' AS thema,
		layer,
		pg_temp.pointonsurface(polygon) AS point,
		gemeindename AS text,
		'pg-gemeinde' AS signaturnummer,
		0 AS drehwinkel,
		ARRAY['norGIS'] AS modell
	FROM po_polygons
	JOIN pg_temp.pp_gemeinden p ON layer='ax_flurstueck_gemeinde_'||gemeindezugehoerigkeit_land||gemeindezugehoerigkeit_regierungsbezirk||gemeindezugehoerigkeit_kreis||gemeindezugehoerigkeit_gemeinde;

--
-- Kreise
--
SELECT 'Kreisgrenzen werden aufbereitet...';

INSERT INTO po_polygons(gml_id,thema,layer,signaturnummer,sn_randlinie,modell,polygon)
	SELECT
		min(gml_id) AS gml_id,
		'Politische Grenzen' AS thema,
		'ax_flurstueck_kreis_'||gemeindezugehoerigkeit_land||gemeindezugehoerigkeit_regierungsbezirk||gemeindezugehoerigkeit_kreis AS layer,
		'pg-kreis' AS signaturnummer,
		'pg-kreis' AS sn_randlinie,
		ARRAY['norGIS'] AS modell,
		st_multi(st_simplify(st_union(st_buffer(polygon,0.30)), :kreis_simplify)) AS polygon
	FROM po_polygons
	JOIN pg_temp.pp_kreise p ON layer LIKE 'ax_flurstueck_gemeinde_'||gemeindezugehoerigkeit_land||gemeindezugehoerigkeit_regierungsbezirk||gemeindezugehoerigkeit_kreis||'%'
	GROUP BY gemeindezugehoerigkeit_land, gemeindezugehoerigkeit_regierungsbezirk, gemeindezugehoerigkeit_kreis;

INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,modell)
	SELECT
		gml_id,
		'Politische Grenzen' AS thema,
		layer,
		pg_temp.pointonsurface(polygon) AS point,
		kreisname AS text,
		'pg-kreis' AS signaturnummer,
		0 AS drehwinkel,
		ARRAY['norGIS'] AS modell
	FROM po_polygons
	JOIN pg_temp.pp_kreise ON layer='ax_flurstueck_kreis_'||gemeindezugehoerigkeit_land||gemeindezugehoerigkeit_regierungsbezirk||gemeindezugehoerigkeit_kreis;

DELETE FROM po_polygons WHERE sn_randlinie='pg-flur' AND gml_id LIKE 'DEBW%';
DELETE FROM po_labels WHERE signaturnummer='pg-flur' AND gml_id LIKE 'DEBW%';
