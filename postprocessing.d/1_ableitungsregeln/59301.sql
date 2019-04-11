SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Vegetationsmerkmal (59301; NRW/HB)
--

SELECT 'Vegetationsmerkmale werden verarbeitet (NWDKOMK/HBDKOM).';

-- Punkte
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	o.gml_id,
	'Vegetation' AS thema,
	'ks_vegetationsmerkmal' AS layer,
	st_multi(wkb_geometry) AS point,
	drehwinkel,
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		wkb_geometry,
		0 AS drehwinkel,
		CASE
		WHEN 'HBDKOM' = ANY(sonstigesmodell) THEN
			CASE bewuchs
			WHEN 1011 THEN '3597'
			WHEN 1012 THEN '3599'
			END
		WHEN 'NWDKOMK' = ANY(sonstigesmodell) THEN
			CASE bewuchs
			WHEN 1013 THEN 'KS_1023'
			WHEN 2100 THEN 'KS_1024'
			WHEN 2200 THEN 'KS_1025'
			END
		END AS signaturnummer,
		advstandardmodell||sonstigesmodell AS modell
	FROM ks_vegetationsmerkmal o
	WHERE geometrytype(wkb_geometry) IN ('POINT','MULTIPOINT') AND endet IS NULL
) AS o
WHERE signaturnummer IS NOT NULL;

-- Flächen
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	o.gml_id,
	'Vegetation' AS thema,
	'ks_vegetationsmerkmal' AS layer,
	st_multi(wkb_geometry) AS polygon,
	'KS_2001' AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ks_vegetationsmerkmal o
WHERE geometrytype(wkb_geometry) IN ('POLYGON','MULTIPOLYGON')
  AND endet IS NULL
  AND 'NWKOM' = ANY(sonstigesmodell)
  AND bewuchs IN (1100,3100);

-- Punktförmige Begleitsignaturen an Linien
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	gml_id,
	'Vegetation' AS thema,
	'ks_vegetationsmerkmal' AS layer,
	st_multi(st_collect(st_lineinterpolatepoint(line,CASE WHEN a.offset<0 THEN 0 WHEN a.offset>1 THEN 1 ELSE a.offset END))) AS point,
	0 AS drehwinkel,
	signaturnummer,
	modell
FROM (
	SELECT
		gml_id,
		signaturnummer,
		line,
		generate_series(einzug,trunc(st_length(line)*1000.0)::int,abstand)/100.0/st_length(line) AS offset,
		modell
	FROM (
		SELECT
			gml_id,
			bewuchs,
			einzug,
			abstand,
			(st_dump(st_multi(line))).geom AS line,
			signaturnummer,
			modell
		FROM (
			SELECT
				gml_id,
				bewuchs,
				unnest(
					CASE bewuchs
					WHEN 1101 THEN ARRAY[0]
					WHEN 1102 THEN ARRAY[300]
					WHEN 1103 THEN ARRAY[300,600]
					END
				) AS einzug,
				unnest(
					CASE bewuchs
					WHEN 1101 THEN ARRAY[600]
					WHEN 1102 THEN ARRAY[600]
					WHEN 1103 THEN ARRAY[1200,1200]
					END
				) AS abstand,
				unnest(
					CASE bewuchs
					WHEN 1101 THEN ARRAY[st_reverse(alkis_safe_offsetcurve(wkb_geometry,-0.11,''::text))]
					WHEN 1102 THEN ARRAY[alkis_safe_offsetcurve(wkb_geometry,0.11,''::text)]
					WHEN 1103 THEN
						ARRAY[
							st_reverse(alkis_safe_offsetcurve(wkb_geometry,-0.11,''::text)),
							alkis_safe_offsetcurve(wkb_geometry,0.11,'')
						]
					END
				) AS line,
				3601 AS signaturnummer,
				modell
			FROM (
				SELECT
					gml_id,
					(st_dump(st_multi(wkb_geometry))).geom AS wkb_geometry,
					bewuchs,
					advstandardmodell||sonstigesmodell AS modell
				FROM ks_vegetationsmerkmal o
				WHERE o.endet IS NULL
				  AND geometrytype(o.wkb_geometry) IN ('LINESTRING','MULTILINESTRING')
				  AND 'HBDKOM' = ANY(sonstigesmodell)
				  AND bewuchs IN (1101,1102,1103)
			) AS o
		) AS a
	) AS a
) AS a
GROUP BY gml_id,signaturnummer,modell;
