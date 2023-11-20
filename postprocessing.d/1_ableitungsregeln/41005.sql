SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Tagebau (41005)
--

SELECT 'Tagebaue werden verarbeitet.';

-- Tagebau, Flächen
INSERT INTO po_polygons(gml_id,gml_ids,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	ARRAY[gml_id] AS gml_ids,
	'Industrie und Gewerbe' AS thema,
	'ax_tagebaugrubesteinbruch' AS layer,
	st_multi(wkb_geometry) AS polygon,
	CASE WHEN abbaugut=4010 THEN 25151404 ELSE 25151403 END AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM po_lastrun, ax_tagebaugrubesteinbruch
WHERE endet IS NULL AND beginnt>lastrun;


-- Tagebau, Anschrieb Abbaugut
INSERT INTO po_labels(gml_id,gml_ids,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	gml_ids,
	'Industrie und Gewerbe' AS thema,
	'ax_tagebaugrubesteinbruch' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel, horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung, modell
FROM (
	SELECT
		o.gml_id,
		ARRAY[o.gml_id, t.gml_id, d.gml_id] AS gml_ids,
		coalesce(t.wkb_geometry,st_translate(st_centroid(o.wkb_geometry),0,-7)) AS point,
		coalesce(
		schriftinhalt,
		E'(' || (SELECT beschreibung FROM ax_abbaugut_tagebaugrubesteinbruch WHERE wert=abbaugut) ||')',
		CASE WHEN abbaugut=4100 THEN '(Torfstich)' ELSE NULL END
		) AS text,
		coalesce(d.signaturnummer,t.signaturnummer,'4141') AS signaturnummer,
		drehwinkel, horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung,
		coalesce(t.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM po_lastrun, ax_tagebaugrubesteinbruch o
	LEFT OUTER JOIN po_pto t ON o.gml_id=t.dientzurdarstellungvon AND t.art='AGT'
	LEFT OUTER JOIN po_darstellung d ON o.gml_id=d.dientzurdarstellungvon AND d.art='AGT'
	WHERE NOT abbaugut IS NULL AND o.endet IS NULL AND greatest(o.beginnt, t.beginnt, d.beginnt)>lastrun
) AS b
WHERE NOT text IS NULL;

-- Tagebau, Symbol
INSERT INTO po_points(gml_id,gml_ids,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	o.gml_id,
	ARRAY[o.gml_id, p.gml_id, d.gml_id] AS gml_ids,
	'Industrie und Gewerbe' AS thema,
	'ax_tagebaugrubesteinbruch' AS layer,
	st_multi(coalesce(p.wkb_geometry,st_centroid(o.wkb_geometry))) AS point,
	coalesce(p.drehwinkel,0) AS drehwinkel,
	coalesce(d.signaturnummer,p.signaturnummer,'3407') AS signaturnummer,
	coalesce(p.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM po_lastrun, ax_tagebaugrubesteinbruch o
LEFT OUTER JOIN po_ppo p ON o.gml_id=p.dientzurdarstellungvon AND p.art='FKT'
LEFT OUTER JOIN po_darstellung d ON o.gml_id=d.dientzurdarstellungvon AND d.art='FKT'
WHERE o.endet IS NULL AND greatest(o.beginnt, p.beginnt, d.beginnt)>lastrun;

-- Tagebau, Namen
INSERT INTO po_labels(gml_id,gml_ids,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	gml_ids,
	'Industrie und Gewerbe' AS thema,
	'ax_tagebaugrubesteinbruch' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel, horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung,
	modell
FROM (
	SELECT
		o.gml_id,
		ARRAY[o.gml_id,t.gml_id,d.gml_id] AS gml_ids,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(t.schriftinhalt,o.name) AS text,
		coalesce(d.signaturnummer,t.signaturnummer,'4141') AS signaturnummer,
		drehwinkel, horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung,
		coalesce(t.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM po_lastrun, ax_tagebaugrubesteinbruch o
	LEFT OUTER JOIN po_pto t ON o.gml_id=t.dientzurdarstellungvon AND t.art='NAM'
	LEFT OUTER JOIN po_darstellung d ON o.gml_id=d.dientzurdarstellungvon AND d.art='NAM'
	WHERE o.endet IS NULL AND greatest(o.beginnt, t.beginnt, d.beginnt)>lastrun
) AS o
WHERE NOT text IS NULL;
