SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Schutzgebiet nach Natur-, Umwelt- oder Bodenschutzrecht (71007)
--

SELECT 'Schutzgebiete nach Natur-, Umwelt und Bodenschutzrecht werden verarbeitet.';

INSERT INTO po_polygons(gml_id,gml_ids,thema,layer,polygon,signaturnummer,modell)
SELECT
	o.gml_id,
	ARRAY[o.gml_id, z.gml_id] AS gml_ids,
	'Rechtliche Festlegungen' AS thema,
	'ax_schutzgebietnachnaturumweltoderbodenschutzrecht' AS layer,
	st_multi(z.wkb_geometry) AS polygon,
	1703 AS signaturnummer,
	o.advstandardmodell||o.sonstigesmodell
FROM po_lastrun, ax_schutzgebietnachnaturumweltoderbodenschutzrecht o
JOIN ax_schutzzone z ON ARRAY[o.gml_id] <@ z.istteilvon AND z.endet IS NULL
WHERE o.artderfestlegung=1621 AND o.endet IS NULL AND greatest(o.beginnt, z.beginnt)>lastrun;

INSERT INTO po_labels(gml_id,gml_ids,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	gml_ids,
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
		ARRAY[o.gml_id, z.gml_id, t.gml_id] AS gml_ids,
		coalesce(t.wkb_geometry,st_centroid(z.wkb_geometry)) AS point,
		(SELECT beschreibung FROM ax_artderfestlegung_schutzgebietnachnaturumweltoderbodensc WHERE wert=artderfestlegung) AS text,
		coalesce(t.signaturnummer,'4143') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM po_lastrun, ax_schutzgebietnachnaturumweltoderbodenschutzrecht o
	LEFT OUTER JOIN ax_schutzzone z ON ARRAY[o.gml_id] <@ z.istteilvon AND z.endet IS NULL
	JOIN po_pto t ON o.gml_id=t.dientzurdarstellungvon AND t.art='ADF' AND t.gml_id<>'TRIGGER'
	WHERE o.endet IS NULL AND greatest(o.beginnt, z.beginnt, t.beginnt)>lastrun
) AS o
WHERE NOT text IS NULL;

-- Namen
INSERT INTO po_labels(gml_id,gml_ids,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	gml_ids,
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
		ARRAY[o.gml_id, z.gml_id, t.gml_id, d.gml_id] AS gml_ids,
		coalesce(t.wkb_geometry,st_centroid(z.wkb_geometry)) AS point,
		'"' || name || '"' AS text,
		coalesce(d.signaturnummer,t.signaturnummer,'4143') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM po_lastrun, ax_schutzgebietnachnaturumweltoderbodenschutzrecht o
	LEFT OUTER JOIN ax_schutzzone z ON ARRAY[o.gml_id] <@ z.istteilvon AND z.endet IS NULL
	LEFT OUTER JOIN po_pto t ON o.gml_id=t.dientzurdarstellungvon AND t.art='NAM'
	LEFT OUTER JOIN po_darstellung d ON o.gml_id=d.dientzurdarstellungvon AND d.art='NAM'
	WHERE o.endet IS NULL AND NOT name IS NULL AND greatest(o.beginnt, z.beginnt, t.beginnt, d.beginnt)>lastrun
) AS n WHERE NOT text IS NULL;
