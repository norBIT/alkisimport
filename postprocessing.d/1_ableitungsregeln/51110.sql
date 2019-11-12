SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Einrichtungen und Anlagen in öffentlichen Bereichen (51110)

SELECT 'Einrichtungen und Anlagen in öffentlichen Bereichen werden verarbeitet (HBDKOM)';

-- Punktsymbole
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	o.gml_id,
	'Verkehr' AS thema,
	'ks_einrichtungenundanlageninoeffentlichenbereichen' AS layer,
	coalesce(
		p.wkb_geometry,
		st_multi(o.wkb_geometry)
	) AS point,
	coalesce(p.drehwinkel,CASE WHEN o.art=2210 THEN 200 ELSE 0 END) AS drehwinkel,
	coalesce(
		d.signaturnummer,
		p.signaturnummer,
		CASE
		WHEN o.art=1100                THEN '3541'
		WHEN o.art=1110                THEN '3542'
		WHEN o.art=1120                THEN '3544'
		WHEN o.art=1130                THEN '3545'
		WHEN o.art=1140                THEN '3546'
		WHEN o.art=1150                THEN '3547'
		WHEN o.art=1160                THEN '3544'
		WHEN o.art=1200                THEN '8309'
		WHEN o.art=1300                THEN '3549'
		WHEN o.art=1310                THEN '3550'
		WHEN o.art=1320                THEN '3551'
		WHEN o.art=1340                THEN '3553'
		WHEN o.art=1360                THEN '3554'
		WHEN o.art IN (1400,1410)      THEN '3556'
		WHEN o.art=1620                THEN '3559'
		WHEN o.art=1700                THEN '3563'
		WHEN o.art=1710                THEN '3564'
		WHEN o.art=1910                THEN '3565'
		WHEN o.art IN (2100,2101,2102) THEN '8308'
		WHEN o.art=2200                THEN '3567'
		WHEN o.art=2210                THEN '3564'
		WHEN o.art=2400                THEN '3569'
		WHEN o.art=2600                THEN '3571'
		WHEN o.art=3100		       THEN 'KS_1014'
		WHEN o.art=3120		       THEN 'KS_1006'
		WHEN o.art=3200		       THEN 'KS_1002'
		WHEN o.art=3310		       THEN 'KS_1003'
		WHEN o.art=9001	               THEN 'KS_1021'
		WHEN o.art=9999                THEN '3585'
		END
	) AS signaturnummer,
	coalesce(
		p.advstandardmodell||p.sonstigesmodell,
		d.advstandardmodell||d.sonstigesmodell,
		o.advstandardmodell||o.sonstigesmodell
	) AS modell
FROM ks_einrichtungenundanlageninoeffentlichenbereichen o
LEFT OUTER JOIN ap_ppo p ON ARRAY[o.gml_id] <@ p.dientzurdarstellungvon AND p.art='ART' AND p.endet IS NULL
LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='ART' AND d.endet IS NULL
WHERE geometrytype(coalesce(p.wkb_geometry,o.wkb_geometry)) IN ('POINT','MULTIPOINT')
  AND o.endet IS NULL
  AND 'HBDKOM' = ANY(o.sonstigesmodell||p.sonstigesmodell||d.sonstigesmodell);


-- Flächen (Haltestelle/Müllbox)
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	'Verkehr' AS thema,
	'ks_einrichtungenundanlageninoeffentlichenbereichen' AS layer,
	polygon,
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		st_multi(wkb_geometry) AS polygon,
		CASE
		WHEN o.art=1360 THEN 2507
		WHEN o.art=2200 THEN 1330
		WHEN o.art=9999 THEN 1330
		END AS signaturnummer,
		advstandardmodell||sonstigesmodell AS modell
	FROM ks_einrichtungenundanlageninoeffentlichenbereichen o
	WHERE geometrytype(wkb_geometry) IN ('POLYGON','MULTIPOLYGON')
	  AND endet IS NULL
	  AND 'HBDKOM' = ANY(o.sonstigesmodell)
) AS o
WHERE NOT signaturnummer IS NULL;

-- Flächensymbole (Müllbox)
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	gml_id,
	'Verkehr' AS thema,
	'ks_einrichtungenundanlageninoeffentlichenbereichen' AS layer,
	st_multi(point),
	drehwinkel,
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		coalesce(
			p.wkb_geometry,
			st_centroid(o.wkb_geometry)
		) AS point,
		coalesce(p.drehwinkel,0) AS drehwinkel,
		coalesce(
			d.signaturnummer,
			p.signaturnummer,
			'3567'
		) AS signaturnummer,
		coalesce(
			p.advstandardmodell||p.sonstigesmodell,
			d.advstandardmodell||d.sonstigesmodell,
			o.advstandardmodell||o.sonstigesmodell
		) AS modell
	FROM ks_einrichtungenundanlageninoeffentlichenbereichen o
	LEFT OUTER JOIN ap_ppo p ON ARRAY[o.gml_id] <@ p.dientzurdarstellungvon AND p.art='ART' AND p.endet IS NULL
	LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='ART' AND d.endet IS NULL
	WHERE o.endet IS NULL
	  AND geometrytype(o.wkb_geometry) IN ('POLYGON','MULTIPOLYGON')
	  AND o.art=2200
	  AND 'HBDKOM' = ANY(o.sonstigesmodell)
) AS o
WHERE NOT signaturnummer IS NULL;

-- Bahnschranke
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	o.gml_id,
	'Verkehr' AS thema,
	'ks_einrichtungenundanlageninoeffentlichenbereichen' AS layer,
	st_multi(unnest(
		ARRAY[
			st_startpoint(o.line),
			st_endpoint(o.line)
		]
	)) AS point,
	unnest(
		ARRAY[
                        st_azimuth(st_startpoint(o.line), st_lineinterpolatepoint(o.line, 0.001)),
                        st_azimuth(st_endpoint(o.line), st_lineinterpolatepoint(o.line, 0.999))
		]
	) AS drehwinkel,
	'3586' AS signaturnummer,
	modell
FROM (
	SELECT
		gml_id,
		(st_dump(st_multi(wkb_geometry))).geom AS line,
                advstandardmodell||sonstigesmodell AS modell
	FROM ks_einrichtungenundanlageninoeffentlichenbereichen
        WHERE geometrytype(wkb_geometry) IN ('LINESTRING','MULTILINESTRING')
          AND endet IS NULL
          AND art=1500
	  AND 'HBDKOM' = ANY(sonstigesmodell)
) AS o;

-- Tor
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	'Verkehr' AS thema,
	'ks_einrichtungenundanlageninoeffentlichenbereichen' AS layer,
	st_multi(polygon),
	2521 AS signaturnummer,
	modell
FROM (
        SELECT
                o.gml_id,
                alkis_bufferline(line, 0.5) AS polygon,  -- TODO: verify
                modell
        FROM (
		SELECT
			gml_id,
			(st_dump(st_multi(wkb_geometry))).geom AS line,
                        advstandardmodell||sonstigesmodell AS modell
		FROM ks_einrichtungenundanlageninoeffentlichenbereichen o
		WHERE o.art=1501
		  AND geometrytype(wkb_geometry) IN ('LINESTRING','MULTILINESTRING')
		  AND endet IS NULL
	          AND 'HBDKOM' = ANY(sonstigesmodell)
	) AS o
) AS o;

-- Linien
INSERT INTO po_lines(gml_id,thema,layer,line,signaturnummer,modell)
SELECT
	gml_id,
	'Verkehr' AS thema,
	'ks_einrichtungenundanlageninoeffentlichenbereichen' AS layer,
	st_multi(line),
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		wkb_geometry AS line,
		CASE
		WHEN o.art=1500 THEN '2002'
		WHEN o.art=2105 THEN '2305'
		WHEN o.art=3310 THEN 'KS_2001'
		WHEN o.art=9999 THEN '2515'
		END AS signaturnummer,
		advstandardmodell||sonstigesmodell AS modell
	FROM ks_einrichtungenundanlageninoeffentlichenbereichen o
	WHERE geometrytype(wkb_geometry) IN ('LINESTRING','MULTILINESTRING')
	  AND endet IS NULL
	  AND 'HBDKOM' = ANY(sonstigesmodell)
) AS o
WHERE NOT signaturnummer IS NULL;

INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
        gml_id,
        'Verkehr' AS thema,
        'ks_einrichtungenundanlageninoeffentlichenbereichen' AS layer,
        st_multi( st_lineinterpolatepoint(line,o.offset) ) AS point,
        0.5*pi()-st_azimuth( st_lineinterpolatepoint(line,o.offset*0.9999), st_lineinterpolatepoint(line,CASE WHEN o.offset=0 THEN 0.001 WHEN o.offset*1.0001>1 THEN 1 ELSE o.offset*1.0001 END) ) AS drehwinkel,
        signaturnummer,
        modell
FROM (
        SELECT
                o.gml_id,
                o.line AS line,
                generate_series(125,trunc(st_length(o.line)*1000.0-125)::int,250) / 1000.0 / st_length(o.line) AS offset,
                'KS_1003' AS signaturnummer,
                modell
        FROM (
                SELECT
                        gml_id,
                        (st_dump(st_multi(wkb_geometry))).geom AS line,
                        advstandardmodell||sonstigesmodell AS modell
	        FROM ks_einrichtungenundanlageninoeffentlichenbereichen o
                WHERE geometrytype(o.wkb_geometry) IN ('LINESTRING','MULTILINESTRING')
		  AND endet IS NULL
		  AND art='3310'
        ) AS o
) AS o
WHERE NOT signaturnummer IS NULL;
