SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Bahnverkehrsanlage (53004)
--

SELECT 'Bahnverkehrsanlagen werden verarbeitet.';

-- Bauwerksfunktion, Anschrieb
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Verkehr' AS thema,
	'ax_bahnverkehrsanlage' AS layer,
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
		WHEN bahnhofskategorie=1010 THEN
			CASE
			WHEN name IS NULL AND n.schriftinhalt IS NULL THEN
				-- WHEN bahnkategorie IN (1100,1102,1104,1200,1201,1202,1300,1301,1400,1500,1600,9999) THEN 'Bahnhof'
				'Bahnhof'
			ELSE
				coalesce(n.schriftinhalt,name)
			END
		WHEN bahnhofskategorie IN (1020,1030) THEN
			coalesce(n.schriftinhalt,name)
		END AS text,
		coalesce(
			d.signaturnummer,
			t.signaturnummer,
			n.signaturnummer,
			CASE
			WHEN bahnhofskategorie=1010 THEN
				CASE
				WHEN name IS NULL AND n.schriftinhalt IS NULL THEN '4141'
				ELSE '4140'
				END
			ELSE
				'4107'
			END
		) AS signaturnummer,
		CASE WHEN name IS NULL AND n.schriftinhalt IS NULL THEN t.drehwinkel ELSE n.drehwinkel END AS drehwinkel,
		CASE WHEN name IS NULL AND n.horizontaleausrichtung IS NULL THEN t.horizontaleausrichtung ELSE n.horizontaleausrichtung END AS horizontaleausrichtung,
		CASE WHEN name IS NULL AND n.vertikaleausrichtung IS NULL THEN t.vertikaleausrichtung ELSE n.vertikaleausrichtung END AS vertikaleausrichtung,
		CASE WHEN name IS NULL AND n.skalierung IS NULL THEN t.skalierung ELSE n.skalierung END AS skalierung,
		CASE WHEN name IS NULL AND n.fontsperrung IS NULL THEN t.fontsperrung ELSE n.fontsperrung END AS fontsperrung,
		coalesce(
			t.advstandardmodell||t.sonstigesmodell||n.advstandardmodell||n.sonstigesmodell,
			o.advstandardmodell||o.sonstigesmodell
		) AS modell
	FROM ax_bahnverkehrsanlage o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='BFK' AND t.endet IS NULL
	LEFT OUTER JOIN ap_pto n ON ARRAY[o.gml_id] <@ n.dientzurdarstellungvon AND n.art='NAM' AND n.endet IS NULL
	LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art IN ('BFK','NAM') AND d.endet IS NULL
	WHERE o.endet IS NULL
) AS n WHERE NOT text IS NULL;

-- Flächen
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	'Verkehr' AS thema,
	'ax_bahnverkehrsanlage' AS layer,
	st_multi(wkb_geometry) AS polygon,
	1541 AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ax_bahnverkehrsanlage o
WHERE geometrytype(wkb_geometry) IN ('POLYGON','MULTIPOLYGON');

-- Symbole
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	gml_id,
	'Verkehr' AS thema,
	'ax_bahnverkehrsanlage' AS layer,
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
			WHEN geometrytype(o.wkb_geometry)='LINESTRING'                  THEN st_lineinterpolatepoint(o.wkb_geometry,0.5)
			END
		) AS point,
		coalesce(p.drehwinkel,0) AS drehwinkel,
		coalesce(
			d.signaturnummer,
			p.signaturnummer,
			CASE
			WHEN bahnhofskategorie=1010 THEN
				CASE
				WHEN 1104 = ANY(bahnkategorie) THEN '3330'
				WHEN 1200 = ANY(bahnkategorie) THEN '3343'
				WHEN 1201 = ANY(bahnkategorie) THEN '3554'
				WHEN 1201 = ANY(bahnkategorie) THEN '3328'
				END
			WHEN bahnhofskategorie IN (1020,1030) THEN
				CASE
				WHEN bahnkategorie && ARRAY[1100,1102,1300,1301,1400,1500,1600,9999] THEN '3578'
				WHEN 1104 = ANY(bahnkategorie) THEN '3330'
				WHEN 1200 = ANY(bahnkategorie) THEN '3343'
				WHEN 1201 = ANY(bahnkategorie) THEN '3554'
				WHEN 1201 = ANY(bahnkategorie) THEN '3328'
				END
			END
		) AS signaturnummer,
		coalesce(p.advstandardmodell||p.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_bahnverkehrsanlage o
	LEFT OUTER JOIN ap_ppo p ON ARRAY[o.gml_id] <@ p.dientzurdarstellungvon AND p.art='BKT' AND p.endet IS NULL
	LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='BKT' AND d.endet IS NULL
	WHERE o.endet IS NULL
) AS o
WHERE NOT signaturnummer IS NULL;
