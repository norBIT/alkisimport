SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Unland/vegetationslose Fläche (43007)
--

SELECT 'Unland/vegetationslose Flächen werden verarbeitet.';

-- Unland, Flächen
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	'Vegetation' AS thema,
	'ax_unlandvegetationsloseflaeche' AS layer,
	polygon,
	signaturnummer,
	modell
FROM (
	SELECT
		gml_id,
		st_multi(wkb_geometry) AS polygon,
		CASE
		WHEN coalesce(funktion,1000)=1000 THEN
		  CASE
		  WHEN coalesce(oberflaechenmaterial,0) IN (0,1010,1020,1030,1040) THEN 2515
		  WHEN oberflaechenmaterial IN (1110,1120)                         THEN 2518
		  END
		ELSE 25151406
		END AS signaturnummer,
		advstandardmodell||sonstigesmodell AS modell
	FROM ax_unlandvegetationsloseflaeche o
	WHERE coalesce(funktion,1000) IN (1000,1100,1110,1120,1200) AND endet IS NULL
) AS o
WHERE NOT signaturnummer IS NULL;

-- Unland, Symbole
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	gml_id,
	'Vegetation' AS thema,
	'ax_unlandvegetationsloseflaeche' AS layer,
	st_multi(point),
	drehwinkel,
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		coalesce(p.wkb_geometry,alkis_flaechenfuellung(o.wkb_geometry,d.positionierungsregel),st_centroid(o.wkb_geometry)) AS point,
		coalesce(p.drehwinkel,0) AS drehwinkel,
		coalesce(
			d.signaturnummer,
			p.signaturnummer,
			CASE
			WHEN coalesce(funktion,1000)=1000 THEN
				CASE
				WHEN oberflaechenmaterial IS NULL        THEN '3480'
				WHEN oberflaechenmaterial=1010           THEN '3481'
				WHEN oberflaechenmaterial=1020           THEN '3482'
				WHEN oberflaechenmaterial=1030           THEN '3483'
				WHEN oberflaechenmaterial=1040           THEN '3484'
				WHEN oberflaechenmaterial IN (1110,1120) THEN '3486'
				END
			END
		) AS signaturnummer,
		coalesce(
			p.advstandardmodell||p.sonstigesmodell||d.advstandardmodell||d.sonstigesmodell,
			o.advstandardmodell||o.sonstigesmodell
		) AS modell
	FROM ax_unlandvegetationsloseflaeche o
	LEFT OUTER JOIN ap_ppo p ON ARRAY[o.gml_id] <@ p.dientzurdarstellungvon AND p.art='OFM' AND p.endet IS NULL
	LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='OFM' AND d.endet IS NULL
	WHERE o.endet IS NULL
) AS o
WHERE NOT signaturnummer IS NULL;

-- Unland, Namen
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Vegetation' AS thema,
	'ax_unlandvegetationsloseflaeche' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(t.schriftinhalt,o.name) AS text,
		coalesce(
			d.signaturnummer,
			t.signaturnummer,
			CASE WHEN oberflaechenmaterial IN (1110,1120) THEN '4151' ELSE '4150' END
		) AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(
			t.advstandardmodell||t.sonstigesmodell||d.advstandardmodell||d.sonstigesmodell,
			o.advstandardmodell||o.sonstigesmodell
		) AS modell
	FROM ax_unlandvegetationsloseflaeche o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='NAM' AND t.endet IS NULL
	LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='NAM' AND d.endet IS NULL
) AS n WHERE NOT text IS NULL;
