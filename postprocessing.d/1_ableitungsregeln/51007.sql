SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Historisches Bauwerk oder historische Einrichtung (51007)
--

SELECT 'Historische Bauwerke oder Einrichtungen werden verarbeitet.';

-- Historisches Bauwerk oder historische Einrichtung, Flächen
INSERT INTO po_polygons(gml_id,gml_ids,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	ARRAY[gml_id] AS gml_ids,
	'Gebäude' AS thema,
	'ax_historischesbauwerkoderhistorischeeinrichtung' AS layer,
	st_multi(wkb_geometry) AS polygon,
	CASE
	WHEN archaeologischertyp IN (1000,1100,1020,1100,1110,1200,1210,9999) THEN 1330
	WHEN archaeologischertyp IN (1400,1410,1420,1430)                     THEN 1317
	WHEN archaeologischertyp IN (1500,1510,1520)                          THEN 1305
	END AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM po_lastrun, ax_historischesbauwerkoderhistorischeeinrichtung
WHERE geometrytype(wkb_geometry) IN ('POLYGON','MULTIPOLYGON') AND endet IS NULL AND beginnt>lastrun;

-- Historisches Bauwerk oder historische Einrichtung, Linien
INSERT INTO po_polygons(gml_id,gml_ids,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	gml_ids,
	'Gebäude' AS thema,
	'ax_historischesbauwerkoderhistorischeeinrichtung' AS layer,
	st_multi(polygon),
	signaturnummer,
	modell
FROM (
	SELECT
		gml_id,
		ARRAY[gml_id] AS gml_ids,
		alkis_bufferline(wkb_geometry,0.5) AS polygon,
		CASE
		WHEN archaeologischertyp IN (1500,1520,1510) THEN 2510
		END AS signaturnummer,
		advstandardmodell||sonstigesmodell AS modell
	FROM po_lastrun, ax_historischesbauwerkoderhistorischeeinrichtung
	WHERE geometrytype(wkb_geometry) IN ('LINESTRING','MULTILINESTRING') AND endet IS NULL AND beginnt>lastrun
) AS o
WHERE NOT signaturnummer IS NULL;


-- Historisches Bauwerk oder historische Einrichtung, Symbol
INSERT INTO po_points(gml_id,gml_ids,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	gml_id,
	gml_ids,
	'Gebäude' AS thema,
	'ax_historischesbauwerkoderhistorischeeinrichtung' AS layer,
	point, drehwinkel, signaturnummer, modell
FROM (
	SELECT
		o.gml_id,
		ARRAY[o.gml_id, p.gml_id, d.gml_id] AS gml_ids,
		st_multi(coalesce(
			p.wkb_geometry,
			CASE
			WHEN geometrytype(o.wkb_geometry) IN ('POINT','MULTIPOINT')     THEN o.wkb_geometry
			WHEN geometrytype(o.wkb_geometry) IN ('POLYGON','MULTIPOLYGON') THEN st_centroid(o.wkb_geometry)
			END
		)) AS point,
		coalesce(p.drehwinkel,0) AS drehwinkel,
		coalesce(
			d.signaturnummer,
			p.signaturnummer,
			CASE
			WHEN archaeologischertyp=1010 THEN '3526'
			WHEN archaeologischertyp=1020 THEN '3527'
			WHEN archaeologischertyp=1300 THEN '3528'
			END
		) AS signaturnummer,
		coalesce(p.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM po_lastrun, ax_historischesbauwerkoderhistorischeeinrichtung o
	LEFT OUTER JOIN po_ppo p ON o.gml_id=p.dientzurdarstellungvon AND p.art='ATP'
	LEFT OUTER JOIN po_darstellung d ON o.gml_id=d.dientzurdarstellungvon AND d.art='ATP'
	WHERE o.endet IS NULL AND greatest(o.beginnt, p.beginnt, d.beginnt)>lastrun
) AS o
WHERE NOT signaturnummer IS NULL;

-- Historisches Bauwerk oder historische Einrichtung, Texte
INSERT INTO po_labels(gml_id,gml_ids,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	gml_ids,
	'Gebäude' AS thema,
	'ax_historischesbauwerkoderhistorischeeinrichtung' AS layer,
	point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		ARRAY[o.gml_id, t.gml_id, n.gml_id, d.gml_id] AS gml_ids,
		coalesce(
			t.wkb_geometry,
			CASE
			WHEN geometrytype(o.wkb_geometry) IN ('POINT','MULTIPOINT')     THEN o.wkb_geometry
			WHEN geometrytype(o.wkb_geometry) IN ('POLYGON','MULTIPOLYGON') THEN st_centroid(o.wkb_geometry)
			WHEN geometrytype(o.wkb_geometry)='LINESTRING'                  THEN st_lineinterpolatepoint(o.wkb_geometry,0.5)
			END
		) AS point,
		CASE
		WHEN
			archaeologischertyp IN (1000,1110)
			OR (archaeologischertyp=1420 AND coalesce(name,n.schriftinhalt) IS NULL)
		THEN
			(SELECT beschreibung FROM ax_archaeologischertyp_historischesbauwerkoderhistorischee WHERE wert=archaeologischertyp)
		WHEN archaeologischertyp=1100 THEN
			coalesce(t.schriftinhalt, 'Historische Wasserleitung')
		WHEN archaeologischertyp=1210 THEN
			coalesce(t.schriftinhalt, 'Römischer Wachturm')
		WHEN archaeologischertyp=1400 AND coalesce(name,n.schriftinhalt) IS NULL THEN
			'Ruine'
		WHEN archaeologischertyp IN (1200,1410,1500,1510,1520)
			OR (archaeologischertyp=1430 AND coalesce(name,n.schriftinhalt) IS NULL)
		THEN
			coalesce(
				t.schriftinhalt,
				(SELECT beschreibung FROM ax_archaeologischertyp_historischesbauwerkoderhistorischee WHERE wert=archaeologischertyp)
			)
		END AS text,
		coalesce(d.signaturnummer,t.signaturnummer,n.signaturnummer,'4070') AS signaturnummer,
		t.drehwinkel,t.horizontaleausrichtung,t.vertikaleausrichtung,t.skalierung,t.fontsperrung,
		coalesce(t.modelle, n.modelle, o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM po_lastrun, ax_historischesbauwerkoderhistorischeeinrichtung o
	LEFT OUTER JOIN po_pto t ON o.gml_id=t.dientzurdarstellungvon AND t.art='ATP'
	LEFT OUTER JOIN po_pto n ON o.gml_id=n.dientzurdarstellungvon AND n.art='NAM'
	LEFT OUTER JOIN po_darstellung d ON o.gml_id=d.dientzurdarstellungvon AND d.art IN ('ATP','NAM')
	WHERE o.endet IS NULL AND greatest(o.beginnt, t.beginnt, n.beginnt, d.beginnt)>lastrun
) AS o
WHERE NOT text IS NULL;

-- Historisches Bauwerk oder historische Einrichtung, Name
INSERT INTO po_labels(gml_id,gml_ids,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	gml_ids,
	'Gebäude' AS thema,
	'ax_historischesbauwerkoderhistorischeeinrichtung' AS layer,
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
	FROM po_lastrun, ax_historischesbauwerkoderhistorischeeinrichtung o
	LEFT OUTER JOIN po_pto t ON o.gml_id=t.dientzurdarstellungvon AND t.art='NAM'
	LEFT OUTER JOIN po_darstellung d ON o.gml_id=d.dientzurdarstellungvon AND d.art='NAM'
	WHERE o.endet IS NULL AND NOT name IS NULL AND greatest(o.beginnt, t.beginnt, d.beginnt)>lastrun
) AS n;
