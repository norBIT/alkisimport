SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Sport-, Freizeit- und Erholungsfläche (41008)
--

SELECT 'Sport-, Freizeit- und Erholungsflächen werden verarbeitet.';

-- Sport-, Freizeit- und Erholungsfläche
INSERT INTO po_polygons(gml_id,gml_ids,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	ARRAY[gml_id] AS gml_ids,
	'Sport und Freizeit' AS thema,
	'ax_sportfreizeitunderholungsflaeche' AS layer,
	st_multi(wkb_geometry) AS polygon,
	25151405 AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM po_lastrun, ax_sportfreizeitunderholungsflaeche
WHERE endet IS NULL AND beginnt>lastrun;


-- Anschrieb, Sport-, Freizeit- und Erholungsfläche
INSERT INTO po_labels(gml_id,gml_ids,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	gml_ids,
	'Sport und Freizeit' AS thema,
	'ax_sportfreizeitunderholungsflaeche' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		ARRAY[o.gml_id, t.gml_id, n.gml_id, d.gml_id] AS gml_ids,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(
			t.schriftinhalt,
			CASE
			WHEN funktion IN (4100,4101) THEN 'Sportanlage'
			WHEN funktion IN (4300,4301) THEN 'Erholungsfläche'
			WHEN funktion IN (4320,4321) THEN 'Bad'
			WHEN funktion IN (4110,4200,4230,4240,4250,4260,4270,4280,4290,4310,4450) THEN
				(SELECT beschreibung FROM ax_funktion_sportfreizeitunderholungsflaeche WHERE wert=funktion)
			WHEN o.gml_id LIKE 'DERP%' THEN
				CASE
				WHEN funktion IN (4120,4130,4140,4150,4160,4170,4230) THEN
					(SELECT beschreibung FROM ax_funktion_sportfreizeitunderholungsflaeche WHERE wert=funktion)
				WHEN funktion IS NULL THEN 'Sportfläche'
				END
			END
		) AS text,
		coalesce(d.signaturnummer,t.signaturnummer,n.signaturnummer,'4140') AS signaturnummer,
		t.drehwinkel,t.horizontaleausrichtung,t.vertikaleausrichtung,t.skalierung,t.fontsperrung,
		coalesce(t.modelle, n.modelle,n.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM po_lastrun, ax_sportfreizeitunderholungsflaeche o
	LEFT OUTER JOIN po_pto t ON o.gml_id=t.dientzurdarstellungvon AND t.art='FKT'
	LEFT OUTER JOIN po_pto n ON o.gml_id=n.dientzurdarstellungvon AND n.art='NAM'
	LEFT OUTER JOIN po_darstellung d ON o.gml_id=d.dientzurdarstellungvon AND d.art IN ('NAM','FKT')
	WHERE name IS NULL AND n.schriftinhalt IS NULL AND o.endet IS NULL AND greatest(o.beginnt, t.beginnt, n.beginnt, d.beginnt)>lastrun
) AS o
WHERE NOT text IS NULL;

-- Symbol, Sport-, Freizeit- und Erholungsfläche
INSERT INTO po_points(gml_id,gml_ids,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	gml_id,
	gml_ids,
	'Sport und Freizeit' AS thema,
	'ax_sportfreizeitunderholungsflaeche' AS layer,
	st_multi(point),
	drehwinkel,
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		ARRAY[o.gml_id, p.gml_id, d.gml_id] AS gml_ids,
		coalesce(p.wkb_geometry,alkis_flaechenfuellung(o.wkb_geometry,d.positionierungsregel),st_centroid(o.wkb_geometry)) AS point,
		coalesce(p.drehwinkel,0) AS drehwinkel,
		coalesce(
			d.signaturnummer,
			p.signaturnummer,
			CASE
			WHEN funktion IN (4210,4211) THEN '3410'
			WHEN funktion=4220           THEN '3411'
			WHEN funktion IN (4330,4331) THEN '3412'
			WHEN funktion IN (4400,4410) THEN '3413'
			WHEN funktion=4420           THEN '3415'
			WHEN funktion IN (4430,4431) THEN '3417'
			WHEN funktion=4440           THEN '3419'
			WHEN funktion=4460           THEN '3421'
			WHEN funktion=4470           THEN '3423'
			END
		) AS signaturnummer,
		coalesce(p.modelle, p.modelle, d.modelle, o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM po_lastrun, ax_sportfreizeitunderholungsflaeche o
	LEFT OUTER JOIN po_ppo p ON o.gml_id=p.dientzurdarstellungvon AND p.art='FKT'
	LEFT OUTER JOIN po_darstellung d ON o.gml_id=d.dientzurdarstellungvon AND d.art='FKT'
	WHERE o.endet IS NULL AND greatest(o.beginnt, p.beginnt, d.beginnt)>lastrun
) AS o
WHERE NOT signaturnummer IS NULL;

-- Name, Sport-, Freizeit- und Erholungsfläche
INSERT INTO po_labels(gml_id,gml_ids,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	gml_ids,
	'Sport und Freizeit' AS thema,
	'ax_sportfreizeitunderholungsflaeche' AS layer,
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
	FROM po_lastrun, ax_sportfreizeitunderholungsflaeche o
	LEFT OUTER JOIN po_pto t ON o.gml_id=t.dientzurdarstellungvon AND t.art='NAM'
	LEFT OUTER JOIN po_darstellung d ON o.gml_id=d.dientzurdarstellungvon AND d.art='NAM'
	WHERE o.endet IS NULL AND greatest(o.beginnt, t.beginnt, d.beginnt)>lastrun
) AS n WHERE NOT text IS NULL;
