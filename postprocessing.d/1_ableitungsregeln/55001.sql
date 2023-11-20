SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Turm (55001)
--

SELECT 'Türme werden verarbeitet.';

-- Turm, Flächen
-- TODO: Punkte?
INSERT INTO po_polygons(gml_id,gml_ids,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	ARRAY[gml_id] AS gml_ids,
	'Gebäude' AS thema,
	'ax_turm' AS layer,
	st_multi(wkb_geometry) AS polygon,
	CASE WHEN zustand=2200 THEN 1502 ELSE 1501 END AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM po_lastrun, ax_turm
WHERE geometrytype(wkb_geometry) IN ('POLYGON','MULTIPOLYGON')
  AND endet IS NULL AND beginnt>lastrun;

-- Turm, Texte
INSERT INTO po_labels(gml_id,gml_ids,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	gml_ids,
	'Gebäude' AS thema,
	'ax_turm_funktion' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		ARRAY[o.gml_id, t.gml_id, d.gml_id] AS gml_ids,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(
			t.schriftinhalt,
			CASE
			WHEN bauwerksfunktion && ARRAY[1000,1010,1011] THEN
				(SELECT beschreibung FROM ax_bauwerksfunktion_turm WHERE ARRAY[wert] <@ bauwerksfunktion LIMIT 1) ||
				CASE
				WHEN zustand=2100 THEN E'\n(außer Betrieb)'
				WHEN zustand=2200 THEN E'\n(zerstört)'
				ELSE ''
				END
			WHEN bauwerksfunktion && ARRAY[1000,1009,1012,9998] THEN
				CASE
				WHEN zustand=2100 THEN '(außer Betrieb)'
				WHEN zustand=2200 THEN '(zerstört)'
				END
			END
		) AS text,
		coalesce(d.signaturnummer,t.signaturnummer,'4070') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM po_lastrun, ax_turm o
	LEFT OUTER JOIN po_pto t ON o.gml_id=t.dientzurdarstellungvon AND t.art='BWF_ZUS'
	LEFT OUTER JOIN po_darstellung d ON o.gml_id=d.dientzurdarstellungvon AND d.art='BWF_ZUS'
	WHERE o.endet IS NULL AND greatest(o.beginnt, t.beginnt, d.beginnt)>lastrun
) AS n WHERE NOT text IS NULL;

-- Turm, Name
INSERT INTO po_labels(gml_id,gml_ids,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	gml_ids,
	'Gebäude' AS thema,
	'ax_turm_funktion' AS layer,
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
		coalesce(d.signaturnummer,t.signaturnummer,'4074') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM po_lastrun, ax_turm o
	LEFT OUTER JOIN po_pto t ON o.gml_id=t.dientzurdarstellungvon AND t.art='NAM'
	LEFT OUTER JOIN po_darstellung d ON o.gml_id=d.dientzurdarstellungvon AND d.art='NAM'
	WHERE o.endet IS NULL AND NOT name IS NULL AND greatest(o.beginnt, t.beginnt, d.beginnt)>lastrun
) AS n;
