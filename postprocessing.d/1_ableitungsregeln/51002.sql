SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Bauwerk oder Anlage für Industrie und Gewerbe (51002)
--

SELECT 'Bauwerke oder Anlagen für Industrie und Gewerbe werden verarbeitet.';

-- Bauwerk- oder Anlage für Industrie und Gewerbe, Flächen
INSERT INTO po_polygons(gml_id,gml_ids,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	ARRAY[gml_id] AS gml_ids,
	'Industrie und Gewerbe' AS thema,
	'ax_bauwerkoderanlagefuerindustrieundgewerbe' AS layer,
	st_multi(wkb_geometry) AS polygon,
	CASE
	WHEN bauwerksfunktion=1210                                    THEN 1510
	WHEN bauwerksfunktion IN (1215,1220,1230,1240,1260,1270,1280,1320,1330,1331,1332,1333,1340,1350,1390,9999) THEN 1305
	WHEN bauwerksfunktion=1250                                    THEN 1306
	WHEN bauwerksfunktion=1290                                    THEN 1501
	END AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM po_lastrun, ax_bauwerkoderanlagefuerindustrieundgewerbe
WHERE geometrytype(wkb_geometry) IN ('POLYGON','MULTIPOLYGON')
  AND endet IS NULL
  AND bauwerksfunktion IN (1210,1215,1220,1230,1240,1250,1260,1270,1280,1290,1320,1330,1331,1332,1333,1340,1350,1390,9999)
  AND beginnt>lastrun;

-- Bauwerk- oder Anlage für Industrie und Gewerbe, Symbole
INSERT INTO po_points(gml_id,gml_ids,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	gml_id,
	gml_ids,
	'Industrie und Gewerbe' AS thema,
	'ax_bauwerkoderanlagefuerindustrieundgewerbe' AS layer,
	st_multi(point),
	drehwinkel,
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		ARRAY[o.gml_id, p.gml_id, d.gml_id] AS gml_ids,
		coalesce(
			p.wkb_geometry,
			CASE
			WHEN geometrytype(o.wkb_geometry) IN ('POINT','MULTIPOINT')     THEN o.wkb_geometry
			WHEN geometrytype(o.wkb_geometry) IN ('POLYGON','MULTIPOLYGON') THEN st_centroid(o.wkb_geometry)
			END
		) AS point,
		coalesce(p.drehwinkel,0) AS drehwinkel,
		coalesce(
			d.signaturnummer,
			p.signaturnummer,
			CASE
			WHEN bauwerksfunktion=1220           THEN '3501'
			WHEN bauwerksfunktion=1230           THEN '3502'
			WHEN bauwerksfunktion=1240           THEN '3503'
			WHEN bauwerksfunktion=1250           THEN '3504'
			WHEN bauwerksfunktion IN (1260,1270) THEN '3506'
			WHEN bauwerksfunktion=1280           THEN '3507'
			WHEN bauwerksfunktion=1290           THEN '3508'
			WHEN bauwerksfunktion=1310           THEN '3509'
			WHEN bauwerksfunktion=1320           THEN '3510'
			WHEN bauwerksfunktion=1330           THEN '3511'
			WHEN bauwerksfunktion=1331           THEN '3512'
			WHEN bauwerksfunktion=1332           THEN '3513'
			WHEN bauwerksfunktion=1333           THEN '3514'
			WHEN bauwerksfunktion=1350           THEN '3515'
			WHEN bauwerksfunktion=1360           THEN '3516'
			WHEN bauwerksfunktion IN (1370,1371) THEN '3517'
			WHEN bauwerksfunktion=1372           THEN '3518'
			WHEN bauwerksfunktion=1380           THEN '3519'
			WHEN bauwerksfunktion=1390           THEN '3520'
			WHEN bauwerksfunktion=1400           THEN '3521'
			END
		) AS signaturnummer,
		coalesce(p.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM po_lastrun, ax_bauwerkoderanlagefuerindustrieundgewerbe o
	LEFT OUTER JOIN po_ppo p ON o.gml_id=p.dientzurdarstellungvon AND p.art='FKT'
	LEFT OUTER JOIN po_darstellung d ON o.gml_id=d.dientzurdarstellungvon AND d.art='FKT'
	WHERE o.endet IS NULL AND greatest(o.beginnt, p.beginnt, d.beginnt)>lastrun
) AS o
WHERE NOT signaturnummer IS NULL
  AND NOT point IS NULL;

-- Bauwerk- oder Anlage für Industrie und Gewerbe, Texte
INSERT INTO po_labels(gml_id,gml_ids,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	gml_ids,
	'Industrie und Gewerbe' AS thema,
	'ax_bauwerkoderanlagefuerindustrieundgewerbe' AS layer,
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
			(SELECT beschreibung FROM ax_bauwerksfunktion_bauwerkoderanlagefuerindustrieundgewer WHERE wert=bauwerksfunktion)
		) AS text,
		coalesce(
			d.signaturnummer,
			t.signaturnummer,
			CASE
			WHEN bauwerksfunktion IN (1210,1215) THEN '4100'
			WHEN bauwerksfunktion=1340           THEN '4140'
			END
		) AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM po_lastrun, ax_bauwerkoderanlagefuerindustrieundgewerbe o
	LEFT OUTER JOIN po_pto t ON o.gml_id=t.dientzurdarstellungvon AND t.art='BWF'
	LEFT OUTER JOIN po_darstellung d ON o.gml_id=d.dientzurdarstellungvon AND d.art='BWF'
	WHERE o.endet IS NULL AND greatest(o.beginnt, t.beginnt, d.beginnt)>lastrun
) AS n WHERE NOT signaturnummer IS NULL AND text IS NOT NULL;

-- Bauwerk- oder Anlage für Industrie und Gewerbe, Name
INSERT INTO po_labels(gml_id,gml_ids,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	gml_ids,
	'Industrie und Gewerbe' AS thema,
	'ax_bauwerkoderanlagefuerindustrieundgewerbe' AS layer,
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
	FROM po_lastrun, ax_bauwerkoderanlagefuerindustrieundgewerbe o
	LEFT OUTER JOIN po_pto t ON o.gml_id=t.dientzurdarstellungvon AND t.art='NAM'
	LEFT OUTER JOIN po_darstellung d ON o.gml_id=d.dientzurdarstellungvon AND d.art='NAM'
	WHERE o.endet IS NULL AND NOT name IS NULL AND greatest(o.beginnt, t.beginnt, d.beginnt)>lastrun
) AS n;

-- Bauwerk- oder Anlage für Industrie und Gewerbe, Zustandstext
INSERT INTO po_labels(gml_id,gml_ids,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	gml_ids,
	'Industrie und Gewerbe' AS thema,
	'ax_bauwerkoderanlagefuerindustrieundgewerbe' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		ARRAY[o.gml_id, t.gml_id, d.gml_id] AS gml_ids,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		CASE zustand
		WHEN 2100 THEN '(außer Betrieb)'
		WHEN 2200 THEN '(zerstört)'
		WHEN 4200 THEN '(verschlossen)'
		END AS text,
		coalesce(d.signaturnummer,t.signaturnummer,'4070') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM po_lastrun, ax_bauwerkoderanlagefuerindustrieundgewerbe o
	LEFT OUTER JOIN po_pto t ON o.gml_id=t.dientzurdarstellungvon AND t.art='ZUS'
	LEFT OUTER JOIN po_darstellung d ON o.gml_id=d.dientzurdarstellungvon AND d.art='ZUS'
	WHERE o.endet IS NULL AND zustand IN (2100,2200,4200) AND greatest(o.beginnt, t.beginnt, d.beginnt)>lastrun
) AS n;
