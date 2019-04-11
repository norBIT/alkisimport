SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Schutzgebiet nach Natur-, Umwelt- oder Bodenschutzrecht (71007)
--

SELECT 'Schutzgebiete nach Natur-, Umwelt und Bodenschutzrecht werden verarbeitet.';

INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	o.gml_id,
	'Rechtliche Festlegungen' AS thema,
	'ax_schutzgebietnachnaturumweltoderbodenschutzrecht' AS layer,
	st_multi(z.wkb_geometry) AS polygon,
	1703 AS signaturnummer,
	o.advstandardmodell||o.sonstigesmodell
FROM ax_schutzgebietnachnaturumweltoderbodenschutzrecht o
JOIN ax_schutzzone z ON ARRAY[o.gml_id] <@ z.istteilvon AND z.endet IS NULL
WHERE o.artderfestlegung=1621 AND o.endet IS NULL;

INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Rechtliche Festlegungen' AS thema,
	'ax_schutzgebietnachnaturumweltoderbodenschutzrecht' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
	modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(z.wkb_geometry)) AS point,
		(SELECT beschreibung FROM ax_artderfestlegung_schutzgebietnachnaturumweltoderbodensc WHERE wert=artderfestlegung) AS text,
		coalesce(t.signaturnummer,'4143') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_schutzgebietnachnaturumweltoderbodenschutzrecht o
	LEFT OUTER JOIN ax_schutzzone z ON ARRAY[o.gml_id] <@ z.istteilvon AND z.endet IS NULL
	JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='ADF' AND t.endet IS NULL
	WHERE o.endet IS NULL
) AS o
WHERE NOT text IS NULL;

-- Namen
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Rechtliche Festlegungen' AS thema,
	'ax_schutzgebietnachnaturumweltoderbodenschutzrecht' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
	modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(z.wkb_geometry)) AS point,
		'"' || name || '"' AS text,
		coalesce(d.signaturnummer,t.signaturnummer,'4143') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_schutzgebietnachnaturumweltoderbodenschutzrecht o
	LEFT OUTER JOIN ax_schutzzone z ON ARRAY[o.gml_id] <@ z.istteilvon AND z.endet IS NULL
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='NAM' AND t.endet IS NULL
	LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='NAM' AND d.endet IS NULL
	WHERE o.endet IS NULL AND NOT name IS NULL
) AS n WHERE NOT text IS NULL;
