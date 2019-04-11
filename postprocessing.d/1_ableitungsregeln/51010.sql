SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Einrichtung in öffentlichen Bereichen (51010)
--

SELECT 'Einrichtungen in öffentlichen Bereichen werden verarbeitet.';

-- Flächen
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	'Verkehr' AS thema,
	'ax_einrichtunginoeffentlichenbereichen' AS layer,
	polygon,
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		st_multi(wkb_geometry) AS polygon,
		CASE o.art
		WHEN 1110 THEN 1330
		WHEN 1510 THEN 2521
		WHEN 9999 THEN 1330
		END AS signaturnummer,
		advstandardmodell||sonstigesmodell AS modell
	FROM ax_einrichtunginoeffentlichenbereichen o
	WHERE geometrytype(wkb_geometry) IN ('POLYGON','MULTIPOLYGON') AND endet IS NULL AND o.art IN (1110,1510,9999)
) AS o;

-- Punktsymbole
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	gml_id,
	'Verkehr' AS thema,
	'ax_einrichtunginoeffentlichenbereichen' AS layer,
	st_multi(point) AS point,
	drehwinkel,
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		coalesce(
			p.wkb_geometry,
			o.wkb_geometry
		) AS point,
		coalesce(p.drehwinkel,0) AS drehwinkel,
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
			WHEN o.art=1200                THEN '3548'
			WHEN o.art=1300                THEN '3549'
			WHEN o.art=1310                THEN '3550'
			WHEN o.art=1320                THEN '3551'
			WHEN o.art=1330                THEN '3552'
			WHEN o.art=1340                THEN '3553'
			WHEN o.art=1350                THEN '3554'
			WHEN o.art IN (1400,1410,1420) THEN '3556'
			WHEN o.art=1600                THEN '3557'
			WHEN o.art=1610                THEN '3558'
			WHEN o.art=1620                THEN '3559'
			WHEN o.art=1630                THEN '3560'
			WHEN o.art=1640                THEN '3561'
			WHEN o.art=1650                THEN '3562'
			WHEN o.art=1700                THEN '3563'
			WHEN o.art=1710                THEN '3564'
			WHEN o.art=1910                THEN '3565'
			WHEN o.art=2100                THEN '3566'
			WHEN o.art=2200                THEN '3567'
			WHEN o.art=2300                THEN '3568'
			WHEN o.art=2400                THEN '3569'
			WHEN o.art=2500                THEN '3570'
			WHEN o.art=2600                THEN '3571'
			END
		) AS signaturnummer,
		coalesce(p.advstandardmodell||p.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_einrichtunginoeffentlichenbereichen o
	LEFT OUTER JOIN ap_ppo p ON ARRAY[o.gml_id] <@ p.dientzurdarstellungvon AND p.art='ART' AND p.endet IS NULL
	LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='ART' AND d.endet IS NULL
	WHERE geometrytype(coalesce(p.wkb_geometry,o.wkb_geometry)) IN ('POINT','MULTIPOINT')
	  AND o.endet IS NULL
) AS o
WHERE signaturnummer IS NOT NULL;

-- Flächensymbole
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	o.gml_id,
	'Verkehr' AS thema,
	'ax_einrichtunginoeffentlichenbereichen' AS layer,
	st_multi(
		coalesce(
			p.wkb_geometry,
			st_centroid(o.wkb_geometry)
		)
	) AS point,
	coalesce(p.drehwinkel,0) AS drehwinkel,
	coalesce(
		d.signaturnummer,
		p.signaturnummer,
		CASE
		WHEN o.art=1110 THEN '3543'
		WHEN o.art=2200 THEN '3567'
		END
	) AS signaturnummer,
	coalesce(p.advstandardmodell||p.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM ax_einrichtunginoeffentlichenbereichen o
LEFT OUTER JOIN ap_ppo p ON ARRAY[o.gml_id] <@ p.dientzurdarstellungvon AND p.art='ART' AND p.endet IS NULL
LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='ART' AND d.endet IS NULL
WHERE o.endet IS NULL AND geometrytype(o.wkb_geometry) IN ('POLYGON','MULTIPOLYGON') AND o.art IN (1110,2200);

-- Linien
INSERT INTO po_lines(gml_id,thema,layer,line,signaturnummer,modell)
SELECT
	o.gml_id,
	'Verkehr' AS thema,
	'ax_einrichtunginoeffentlichenbereichen' AS layer,
	st_multi(wkb_geometry) AS line,
	2002 AS signaturnummer,
	advstandardmodell||sonstigesmodell AS modell
FROM ax_einrichtunginoeffentlichenbereichen o
WHERE geometrytype(wkb_geometry) IN ('LINESTRING','MULTILINESTRING') AND endet IS NULL AND o.art=1650;

-- Texte Ortsdurchfahrtstein
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	o.gml_id,
	'Verkehr' AS thema,
	'ax_einrichtunginoeffentlichenbereichen' AS layer,
	coalesce(t.wkb_geometry,o.wkb_geometry) AS point,
	'OD' AS text,
	coalesce(d.signaturnummer,t.signaturnummer,'4070') AS signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
	coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM ax_einrichtunginoeffentlichenbereichen o
LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='ART' AND t.endet IS NULL
LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='ART' AND d.endet IS NULL
WHERE o.endet IS NULL AND o.art=1420;

-- Texte
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	o.gml_id,
	'Verkehr' AS thema,
	'ax_einrichtunginoeffentlichenbereichen' AS layer,
	coalesce(t.wkb_geometry,o.wkb_geometry) AS point,
	kilometerangabe AS text,
	coalesce(d.signaturnummer,t.signaturnummer,'4070') AS signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
	coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM ax_einrichtunginoeffentlichenbereichen o
LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='KMA' AND t.endet IS NULL
LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='KMA' AND d.endet IS NULL
WHERE o.endet IS NULL AND NOT kilometerangabe IS NULL;

-- Bahnschranke
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	o.gml_id,
	'Verkehr' AS thema,
	'ax_einrichtunginoeffentlichenbereichen' AS layer,
	st_multi(
		unnest(
			ARRAY[
				st_startpoint(o.line),
				st_endpoint(o.line)
			]
		)
	) AS point,
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
	FROM ax_einrichtunginoeffentlichenbereichen
	WHERE geometrytype(wkb_geometry) IN ('LINESTRING','MULTILINESTRING')
          AND endet IS NULL
          AND art=1500
) AS o;

-- Tor
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	'Verkehr' AS thema,
	'ax_einrichtunginoeffentlichenbereichen' AS layer,
	st_multi(polygon),
	2521 AS signaturnummer,
	modell
FROM (
        SELECT
                o.gml_id,
                alkis_bufferline(line, 0.5) AS polygon,
                modell
        FROM (
		SELECT
			gml_id,
			(st_dump(st_multi(wkb_geometry))).geom AS line,
			advstandardmodell||sonstigesmodell AS modell
		FROM ax_einrichtunginoeffentlichenbereichen o
		WHERE o.art=1501
		  AND geometrytype(wkb_geometry) IN ('LINESTRING','MULTILINESTRING')
		  AND endet IS NULL
	) AS o
) AS o;
