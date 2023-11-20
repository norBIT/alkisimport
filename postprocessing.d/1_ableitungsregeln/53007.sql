SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Flugverkehrsanlage (53007)
--

SELECT 'Flugverkehrsanlagen werden verarbeitet.';

-- Flächen
INSERT INTO po_polygons(gml_id,gml_ids,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	ARRAY[gml_id] AS gml_ids,
	'Verkehr' AS thema,
	'ax_flugverkehrsanlage' AS layer,
	st_multi(wkb_geometry) AS polygon,
	1808 AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM po_lastrun, ax_flugverkehrsanlage o
WHERE o.endet IS NULL AND o.art IN (1310,1320,1330,5531) AND geometrytype(o.wkb_geometry) IN ('POLYGON','MULTIPOLYGON') AND beginnt>lastrun;

-- Hubschrauberlandeplatz
INSERT INTO po_points(gml_id,gml_ids,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	o.gml_id,
	ARRAY[o.gml_id,p.gml_id] AS gml_ids,
	'Verkehr' AS thema,
	'ax_flugverkehrsanlage' AS layer,
	st_multi(coalesce(p.wkb_geometry,st_centroid(o.wkb_geometry))) AS point,
	coalesce(p.drehwinkel,0) AS drehwinkel,
	coalesce(p.signaturnummer,'3588') AS signaturnummer,
	coalesce(p.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM po_lastrun, ax_flugverkehrsanlage o
JOIN po_ppo p ON o.gml_id=p.dientzurdarstellungvon AND p.art='ART' AND p.gml_id<>'TRIGGER'
WHERE o.endet IS NULL AND o.art=5531 AND greatest(o.beginnt, p.beginnt)>lastrun;

-- Bake/Leuchtfeuer/Kilometerstein
INSERT INTO po_points(gml_id,gml_ids,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	o.gml_id,
	ARRAY[o.gml_id,p.gml_id] AS gml_ids,
	'Verkehr' AS thema,
	'ax_flugverkehrsanlage' AS layer,
	st_multi(coalesce(p.wkb_geometry,o.wkb_geometry)) AS point,
	coalesce(p.drehwinkel,0) AS drehwinkel,
	coalesce(
		p.signaturnummer,
		CASE
		WHEN o.art=1410 THEN '3589'
		WHEN o.art=1420 THEN '3590'
		WHEN o.art=1430 THEN '3556'
		END
	) AS signaturnummer,
	coalesce(p.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM po_lastrun, ax_flugverkehrsanlage o
JOIN po_ppo p ON o.gml_id=p.dientzurdarstellungvon AND p.art='ART' AND p.gml_id<>'TRIGGER'
WHERE o.endet IS NULL AND o.art IN (1410,1420,1430) AND geometrytype(o.wkb_geometry) IN ('POINT','MULTIPOINT') AND greatest(o.beginnt, p.beginnt)>lastrun;

-- Namen
INSERT INTO po_labels(gml_id,gml_ids,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	gml_ids,
	'Verkehr' AS thema,
	'ax_flugverkehrsanlage' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		ARRAY[o.gml_id,t.gml_id,d.gml_id] AS gml_ids,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(t.schriftinhalt,name) AS text,
		coalesce(d.signaturnummer,t.signaturnummer,'4107') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM po_lastrun, ax_flugverkehrsanlage o
	LEFT OUTER JOIN po_pto t ON o.gml_id=t.dientzurdarstellungvon AND t.art='NAM'
	LEFT OUTER JOIN po_darstellung d ON o.gml_id=d.dientzurdarstellungvon AND d.art='NAM'
	WHERE o.endet IS NULL AND NOT name IS NULL OR NOT t.schriftinhalt IS NULL AND greatest(o.beginnt, t.beginnt, d.beginnt)>lastrun
) AS n WHERE NOT text IS NULL;
