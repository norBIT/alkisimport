SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Bauwerk oder Anlage für Industrie und Gewerbe (51102)
--

SELECT 'Bauwerke oder Anlagen für Industrie und Gewerbe werden verarbeitet (HBDKOM).';

-- Bauwerk- oder Anlage für Industrie und Gewerbe, Flächen
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	'Industrie und Gewerbe' AS thema,
	'ks_bauwerkoderanlagefuerindustrieundgewerbe' AS layer,
	st_multi(wkb_geometry) AS polygon,
	1306 AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ks_bauwerkoderanlagefuerindustrieundgewerbe
WHERE geometrytype(wkb_geometry) IN ('POLYGON','MULTIPOLYGON')
  AND endet IS NULL
  AND bauwerksfunktion=1250
  AND 'HBDKOM' = ANY(sonstigesmodell);

-- Bauwerk- oder Anlage für Industrie und Gewerbe, Symbole
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	gml_id,
	'Industrie und Gewerbe' AS thema,
	'ks_bauwerkoderanlagefuerindustrieundgewerbe' AS layer,
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
			END
		) AS point,
		coalesce(p.drehwinkel,0) AS drehwinkel,
		coalesce(
			d.signaturnummer,
			p.signaturnummer,
			CASE
			WHEN bauwerksfunktion=1250           THEN '3504'
			WHEN bauwerksfunktion IN (1370,1371) THEN '3517'
			WHEN bauwerksfunktion=1372           THEN '3518'
			WHEN bauwerksfunktion=1380	     THEN '3519'
			WHEN bauwerksfunktion=1390           THEN '3520'
			END
		) AS signaturnummer,
		coalesce(
			p.advstandardmodell||p.sonstigesmodell,
			d.advstandardmodell||d.sonstigesmodell,
			o.advstandardmodell||o.sonstigesmodell
                ) AS modell
	FROM ks_bauwerkoderanlagefuerindustrieundgewerbe o
	LEFT OUTER JOIN ap_ppo p ON ARRAY[o.gml_id] <@ p.dientzurdarstellungvon AND p.art='BWF' AND p.endet IS NULL
	LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='BWF' AND d.endet IS NULL
	WHERE o.endet IS NULL
	  AND 'HBDKOM' = ANY(o.sonstigesmodell||p.sonstigesmodell||d.sonstigesmodell)
) AS o
WHERE NOT signaturnummer IS NULL
  AND NOT point IS NULL;
