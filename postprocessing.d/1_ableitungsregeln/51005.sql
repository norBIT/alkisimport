SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Leitung (51005)
--

SELECT 'Leitungen werden verarbeitet.';

-- Leitungsverlauf
INSERT INTO po_lines(gml_id,gml_ids,thema,layer,line,signaturnummer,modell)
SELECT
	gml_id,
	ARRAY[gml_id] AS gml_ids,
	'Industrie und Gewerbe' AS thema,
	'ax_leitung' AS layer,
	st_multi(wkb_geometry) AS line,
	CASE
	WHEN bauwerksfunktion=1110 THEN 2524
	WHEN bauwerksfunktion=1111 THEN 2523
	END AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM po_lastrun, ax_leitung
WHERE bauwerksfunktion IN (1110,1111) AND endet IS NULL AND beginnt>lastrun;

-- Anschrieb Erdkabel
INSERT INTO po_labels(gml_id,gml_ids,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	o.gml_id,
	ARRAY[o.gml_id, t.gml_id, d.gml_id] AS gml_ids,
	'Industrie und Gewerbe' AS thema,
	'ax_leitung' AS layer,
	coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
	'Erdkabel' AS text,
	coalesce(d.signaturnummer,t.signaturnummer,'4070') AS signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
	coalesce(t.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM po_lastrun, ax_leitung o
LEFT OUTER JOIN po_pto t ON o.gml_id=t.dientzurdarstellungvon AND t.art='BWF'
LEFT OUTER JOIN po_darstellung d ON o.gml_id=d.dientzurdarstellungvon AND d.art='BWF'
WHERE bauwerksfunktion=1111 AND o.endet IS NULL AND greatest(o.beginnt, t.beginnt, d.beginnt)>lastrun;

-- Anschrieb Spannungsebene
INSERT INTO po_labels(gml_id,gml_ids,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	o.gml_id,
	ARRAY[o.gml_id, t.gml_id, d.gml_id] AS gml_ids,
	'Industrie und Gewerbe' AS thema,
	'ax_leitung' AS layer,
	coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
	spannungsebene || CASE WHEN o.gml_id LIKE 'DERP%' THEN ' kV' ELSE ' KV' END AS text,
	coalesce(d.signaturnummer,t.signaturnummer,'4070') AS signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
	coalesce(t.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM po_lastrun, ax_leitung o
LEFT OUTER JOIN po_pto t ON o.gml_id=t.dientzurdarstellungvon AND t.art='SPG'
LEFT OUTER JOIN po_darstellung d ON o.gml_id=d.dientzurdarstellungvon AND d.art='SPG'
WHERE o.endet IS NULL AND NOT spannungsebene IS NULL AND greatest(o.beginnt, t.beginnt, d.beginnt)>lastrun;
