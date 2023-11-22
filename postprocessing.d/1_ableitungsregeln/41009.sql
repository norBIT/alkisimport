SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Friedhof (41009)
--

SELECT 'Friedhöfe werden verarbeitet.';

-- Fläche, Friedhof
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	'Friedhöfe' AS thema,
	'ax_friedhof' AS layer,
	st_multi(wkb_geometry) AS polygon,
	25151405 AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ax_friedhof
WHERE endet IS NULL;

-- Text, Friedhof
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Friedhöfe' AS thema,
	'ax_friedhof' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(t.schriftinhalt,o.name) AS text,
		coalesce(d.signaturnummer,t.signaturnummer,n.signaturnummer,'4140') AS signaturnummer,
		t.drehwinkel,t.horizontaleausrichtung,t.vertikaleausrichtung,t.skalierung,t.fontsperrung,
		coalesce(
			t.advstandardmodell||t.sonstigesmodell||n.advstandardmodell||n.sonstigesmodell,
			o.advstandardmodell||o.sonstigesmodell
		) AS modell
	FROM ax_friedhof o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='Friedhof' AND t.endet IS NULL
	LEFT OUTER JOIN ap_pto n ON ARRAY[o.gml_id] <@ n.dientzurdarstellungvon AND n.art='NAM' AND n.endet IS NULL
	LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art IN ('NAM','Friedhof') AND d.endet IS NULL
	WHERE name IS NULL AND n.schriftinhalt IS NULL AND o.endet IS NULL
) AS n WHERE NOT text IS NULL;

-- Name, Friedhof
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Friedhöfe' AS thema,
	'ax_friedhof' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(t.schriftinhalt,o.name) AS text,
		coalesce(d.signaturnummer,t.signaturnummer,'4141') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_friedhof o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='NAM' AND t.endet IS NULL
	LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='NAM' AND d.endet IS NULL
	WHERE NOT name IS NULL OR NOT t.schriftinhalt IS NULL AND o.endet IS NULL
) AS n;
