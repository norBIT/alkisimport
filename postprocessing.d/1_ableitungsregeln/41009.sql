SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Friedhof (41009)
--

SELECT 'Friedhöfe werden verarbeitet.';

-- Fläche, Friedhof
INSERT INTO po_polygons(gml_id,gml_ids,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	ARRAY[gml_id] AS gml_ids,
	'Friedhöfe' AS thema,
	'ax_friedhof' AS layer,
	st_multi(wkb_geometry) AS polygon,
	25151405 AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM po_lastrun, ax_friedhof
WHERE endet IS NULL AND beginnt>lastrun;

-- Text, Friedhof
INSERT INTO po_labels(gml_id,gml_ids,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	gml_ids,
	'Friedhöfe' AS thema,
	'ax_friedhof' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		ARRAY[o.gml_id, t.gml_id, n.gml_id, d.gml_id] AS gml_ids,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(t.schriftinhalt,o.name) AS text,
		coalesce(d.signaturnummer,t.signaturnummer,n.signaturnummer,'4140') AS signaturnummer,
		t.drehwinkel,t.horizontaleausrichtung,t.vertikaleausrichtung,t.skalierung,t.fontsperrung,
		coalesce(t.modelle, n.modelle, o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM po_lastrun, ax_friedhof o
	LEFT OUTER JOIN po_pto t ON o.gml_id=t.dientzurdarstellungvon AND t.art='Friedhof'
	LEFT OUTER JOIN po_pto n ON o.gml_id=n.dientzurdarstellungvon AND n.art='NAM'
	LEFT OUTER JOIN po_darstellung d ON o.gml_id=d.dientzurdarstellungvon AND d.art IN ('NAM','Friedhof')
	WHERE name IS NULL AND n.schriftinhalt IS NULL AND o.endet IS NULL AND greatest(o.beginnt, t.beginnt, n.beginnt, d.beginnt)>lastrun
) AS n WHERE NOT text IS NULL;

-- Name, Friedhof
INSERT INTO po_labels(gml_id,gml_ids,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	gml_ids,
	'Friedhöfe' AS thema,
	'ax_friedhof' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		ARRAY[o.gml_id, t.gml_id, d.gml_id] AS gml_ids,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(t.schriftinhalt,o.name) AS text,
		coalesce(d.signaturnummer,t.signaturnummer,'4141') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM po_lastrun, ax_friedhof o
	LEFT OUTER JOIN po_pto t ON o.gml_id=t.dientzurdarstellungvon AND t.art='NAM'
	LEFT OUTER JOIN po_darstellung d ON o.gml_id=d.dientzurdarstellungvon AND d.art='NAM'
	WHERE NOT name IS NULL OR NOT t.schriftinhalt IS NULL AND o.endet IS NULL AND greatest(o.beginnt, t.beginnt, d.beginnt)>lastrun
) AS n;
