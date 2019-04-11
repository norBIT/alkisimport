SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Verkehrszeichen (59202; NRW/HB)
--

SELECT 'Verkehrszeichen werden verarbeitet (NWDKOMK/HBDKOM).';

-- Punkte
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	gml_id,
	'Verkehr' AS thema,
	'ks_verkehrszeichen' AS layer,
	st_multi(point) AS point,
	drehwinkel,
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		wkb_geometry AS point,
		0 AS drehwinkel,
		CASE
		WHEN 'HBDKOM' = ANY(sonstigesmodell) THEN
			CASE
			WHEN '1100' = ANY(verkehrseinrichtung) THEN '3579'
			WHEN '1210' = ANY(verkehrseinrichtung) THEN 'KS_1018'
			END
		WHEN 'NWDKOMK' = ANY(sonstigesmodell) THEN
			CASE
			WHEN gefahrzeichen IS NOT NULL OR vorschriftzeichen IS NOT NULL OR zusatzzeichen IS NOT NULL THEN 'KS_1015'
			WHEN 1200 = ANY(richtzeichen) THEN 'KS_1016'
			WHEN 1100 = ANY(verkehrseinrichtung) THEN 'KS_1017'
			WHEN ARRAY[1210,1220] && verkehrseinrichtung THEN 'KS_1018'
			WHEN 1400 = ANY(verkehrseinrichtung) THEN 'KS_1019'
			END
		END AS signaturnummer,
		advstandardmodell||sonstigesmodell AS modell
	FROM ks_verkehrszeichen o
	WHERE geometrytype(wkb_geometry) IN ('POINT','MULTIPOINT') AND endet IS NULL
) AS o
WHERE signaturnummer IS NOT NULL;

-- Leitplanke / Barriere/Sonstige Absperrung
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
        gml_id,
	'Verkehr' AS thema,
	'ks_verkehrszeichen' AS layer,
        st_multi( st_lineinterpolatepoint(line,o.offset) ) AS point,
        0 AS drehwinkel,
        signaturnummer,
        modell
FROM (
        SELECT
                o.gml_id,
                o.line AS line,
		CASE
		WHEN 'HBDKOM' = ANY(o.sonstigesmodell) THEN
			CASE
			WHEN '3310' = ANY(o.verkehrseinrichtung) THEN '3585'
			END
		WHEN 'NWDKOMK' = ANY(o.sonstigesmodell) THEN
			CASE
			WHEN ARRAY[1110,1199] && o.verkehrseinrichtung THEN 'KS_2003'
			WHEN 1600 = ANY(o.verkehrseinrichtung)         THEN 'KS_2004'
			END
		END AS signaturnummer,
                generate_series(300,trunc(st_length(o.line)*1000.0-300)::int,600) / 1000.0 / st_length(o.line) AS offset,  -- FIXME: 300/600 auch für NWDKOMK ok?
                advstandardmodell||sonstigesmodell AS modell
        FROM (
                SELECT
                        gml_id,
                        (st_dump(st_multi(wkb_geometry))).geom AS line,
			verkehrseinrichtung,
			advstandardmodell, sonstigesmodell
		FROM ks_verkehrszeichen o
                WHERE geometrytype(o.wkb_geometry) IN ('LINESTRING','MULTILINESTRING')
                  AND o.endet IS NULL
                  AND '3310' = ANY(o.verkehrseinrichtung)
		  AND 'HBDKOM' = ANY(o.sonstigesmodell)
        ) AS o
) AS o
WHERE signaturnummer IS NOT NULL;

-- Linien
INSERT INTO po_lines(gml_id,thema,layer,line,signaturnummer,modell)
SELECT
	gml_id,
	'Verkehr' AS thema,
	'ks_verkehrszeichen' AS layer,
	st_multi(line) AS line,
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		wkb_geometry AS line,
		CASE
		WHEN 'HBDKOM' = ANY(sonstigesmodell) THEN
			CASE
			WHEN 1110 = ANY(verkehrseinrichtung)         THEN '2623'
			WHEN 1600 = ANY(verkehrseinrichtung)         THEN '2002'
			END
		WHEN 'NWDKOMK' = ANY(sonstigesmodell) THEN
			CASE
			WHEN 1111 = ANY(richtzeichen)                THEN 'KS_2002'
			WHEN ARRAY[1110,1199] && verkehrseinrichtung THEN 'KS_2003'
			WHEN 1600 = ANY(verkehrseinrichtung)         THEN 'KS_2004'
			ELSE 'KS_2001'
			END
		END AS signaturnummer,
		advstandardmodell||sonstigesmodell AS modell
	FROM ks_verkehrszeichen o
	WHERE geometrytype(wkb_geometry) IN ('LINESTRING','MULTILINESTRING') AND endet IS NULL
) AS o
WHERE signaturnummer IS NOT NULL;

-- Flächen
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	o.gml_id,
	'Verkehr' AS thema,
	'ks_verkehrszeichen' AS layer,
	st_multi(wkb_geometry) AS polygon,
	'KS_3001' AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ks_verkehrszeichen o
WHERE geometrytype(wkb_geometry) IN ('POLYGON','MULTIPOLYGON')
  AND 'NWDKOMK' = ANY(sonstigesmodell)
  AND endet IS NULL;
