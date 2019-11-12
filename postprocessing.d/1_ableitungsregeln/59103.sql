SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Bauwerk Anlagen für Ver- und Entsorgung (59103)
--

SELECT 'Bauwerke oder Anlagen für Ver- und Entsorgung werden verarbeitet (NWDKOMK/HBDKOM).';

-- Bauwerk- oder Anlagen für Ver- und Entsorgung
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	gml_id,
	'Industrie und Gewerbe' AS thema,
	'ks_bauwerkanlagenfuerverundentsorgung' AS layer,
	st_multi(point),
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
			WHEN 'HBDKOM' = ANY(o.sonstigesmodell||p.sonstigesmodell) THEN
				CASE
				WHEN o.art=1200                     THEN 'KS_1007'
				WHEN o.art=1500                     THEN '3520'
				WHEN o.art IN (2100,2200)           THEN '3519'
				END
			WHEN 'NWDKOMK' = ANY(o.sonstigesmodell||p.sonstigesmodell) THEN
				CASE
				WHEN o.art=1200                     THEN 'KS_1007'
				WHEN o.art=1300                     THEN 'KS_1008'
				WHEN o.art IN (1400,2100,2200)      THEN 'KS_1009'
				WHEN o.art=1500                     THEN 'KS_1010'
				WHEN o.art IN (3100,3200,3300,3400) THEN 'KS_1011'
				END
			END
		) AS signaturnummer,
		coalesce(
			p.advstandardmodell||p.sonstigesmodell,
			d.advstandardmodell||d.sonstigesmodell,
			o.advstandardmodell||o.sonstigesmodell
		) AS modell
	FROM ks_bauwerkanlagenfuerverundentsorgung o
	LEFT OUTER JOIN ap_ppo p ON ARRAY[o.gml_id] <@ p.dientzurdarstellungvon AND p.art='ART' AND p.endet IS NULL
	LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='ART' AND d.endet IS NULL
	WHERE o.endet IS NULL
	  AND geometrytype(o.wkb_geometry) IN ('POINT','MULTIPOINT')
) AS o
WHERE NOT signaturnummer IS NULL AND NOT point IS NULL;

-- Beschriftung
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
        o.gml_id,
	'Industrie und Gewerbe' AS thema,
        'ks_bauwerkanlagenfuerverundentsorgung' AS layer,
	st_translate(coalesce(t.wkb_geometry,o.wkb_geometry), 1.5, 0) AS point,
	coalesce(
		t.schriftinhalt,
		CASE o.art
		WHEN 2100 THEN 'G'
		WHEN 2200 THEN 'W'
		END
	) AS text,
        coalesce(d.signaturnummer,t.signaturnummer,'4070') AS signaturnummer,
        drehwinkel, horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung,
        coalesce(
		t.advstandardmodell||t.sonstigesmodell,
		d.advstandardmodell||d.sonstigesmodell,
		o.advstandardmodell||o.sonstigesmodell
	) AS modell
FROM ks_bauwerkanlagenfuerverundentsorgung o
LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='ART' AND t.endet IS NULL
LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='ART' AND d.endet IS NULL
WHERE o.endet IS NULL
  AND o.art IN (2100,2200)
  AND geometrytype(o.wkb_geometry) IN ('POINT','MULTIPOINT')
  AND 'HBDKOM' = ANY(o.sonstigesmodell||t.sonstigesmodell||d.sonstigesmodell);

-- Linien
INSERT INTO po_lines(gml_id,thema,layer,line,signaturnummer,modell)
SELECT
        gml_id,
        'Industrie und Gewerbe' AS thema,
        'ks_bauwerkanlagenfuerverundentsorgung' AS layer,
        st_multi(wkb_geometry) AS line,
	'KS_2002' AS signaturnummer,
	advstandardmodell||sonstigesmodell AS modell
FROM ks_bauwerkanlagenfuerverundentsorgung o
WHERE geometrytype(wkb_geometry) IN ('LINESTRING','MULTILINESTRING')
  AND o.endet IS NULL
  AND o.art=1100
  AND 'NWDKOMK' = ANY(sonstigesmodell);

-- Flächen
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
        gml_id,
        'Industrie und Gewerbe' AS thema,
        'ks_bauwerkanlagenfuerverundentsorgung' AS layer,
        st_multi(wkb_geometry) AS polygon,
	'KS_3001' AS signaturnummer,
        advstandardmodell||sonstigesmodell AS modell
FROM ks_bauwerkanlagenfuerverundentsorgung o
WHERE geometrytype(o.wkb_geometry) IN ('POLYGON','MULTIPOLYGON')
  AND o.endet IS NULL
  AND o.art=1100
  AND 'NWDKOMK' = ANY(o.sonstigesmodell);
