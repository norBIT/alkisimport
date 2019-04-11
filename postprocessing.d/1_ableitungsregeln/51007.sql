SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Historisches Bauwerk oder historische Einrichtung (51007)
--

SELECT 'Historische Bauwerke oder Einrichtungen werden verarbeitet.';

-- Historisches Bauwerk oder historische Einrichtung, Flächen
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	'Gebäude' AS thema,
	'ax_historischesbauwerkoderhistorischeeinrichtung' AS layer,
	st_multi(wkb_geometry) AS polygon,
	CASE
	WHEN archaeologischertyp IN (1000,1100,1020,1100,1110,1200,1210,9999) THEN 1330
	WHEN archaeologischertyp IN (1400,1410,1420,1430)                     THEN 1317
	WHEN archaeologischertyp IN (1500,1510,1520)                          THEN 1305
	END AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ax_historischesbauwerkoderhistorischeeinrichtung
WHERE geometrytype(wkb_geometry) IN ('POLYGON','MULTIPOLYGON') AND endet IS NULL;

-- Historisches Bauwerk oder historische Einrichtung, Linien
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	'Gebäude' AS thema,
	'ax_historischesbauwerkoderhistorischeeinrichtung' AS layer,
	st_multi(polygon),
	signaturnummer,
	modell
FROM (
	SELECT
		gml_id,
		alkis_bufferline(wkb_geometry,0.5) AS polygon,
		CASE
		WHEN archaeologischertyp IN (1500,1520,1510) THEN 2510
		END AS signaturnummer,
		advstandardmodell||sonstigesmodell AS modell
	FROM ax_historischesbauwerkoderhistorischeeinrichtung
	WHERE geometrytype(wkb_geometry) IN ('LINESTRING','MULTILINESTRING') AND endet IS NULL
) AS o
WHERE NOT signaturnummer IS NULL;


-- Historisches Bauwerk oder historische Einrichtung, Symbol
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	gml_id,
	'Gebäude' AS thema,
	'ax_historischesbauwerkoderhistorischeeinrichtung' AS layer,
	point, drehwinkel, signaturnummer, modell
FROM (
	SELECT
		o.gml_id,
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
		coalesce(p.advstandardmodell||p.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_historischesbauwerkoderhistorischeeinrichtung o
	LEFT OUTER JOIN ap_ppo p ON ARRAY[o.gml_id] <@ p.dientzurdarstellungvon AND p.art='ATP' AND p.endet IS NULL
	LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='ATP' AND d.endet IS NULL
	WHERE o.endet IS NULL
) AS o
WHERE NOT signaturnummer IS NULL;

-- Historisches Bauwerk oder historische Einrichtung, Texte
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Gebäude' AS thema,
	'ax_historischesbauwerkoderhistorischeeinrichtung' AS layer,
	point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
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
		coalesce(
			t.advstandardmodell||t.sonstigesmodell||n.advstandardmodell||n.sonstigesmodell,
			o.advstandardmodell||o.sonstigesmodell
		) AS modell
	FROM ax_historischesbauwerkoderhistorischeeinrichtung o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='ATP' AND t.endet IS NULL
	LEFT OUTER JOIN ap_pto n ON ARRAY[o.gml_id] <@ n.dientzurdarstellungvon AND n.art='NAM' AND n.endet IS NULL
	LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art IN ('ATP','NAM') AND d.endet IS NULL
	WHERE o.endet IS NULL
) AS o
WHERE NOT text IS NULL;

-- Historisches Bauwerk oder historische Einrichtung, Name
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Gebäude' AS thema,
	'ax_historischesbauwerkoderhistorischeeinrichtung' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(t.schriftinhalt,o.name) AS text,
		coalesce(d.signaturnummer,t.signaturnummer,'4074') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_historischesbauwerkoderhistorischeeinrichtung o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='NAM' AND t.endet IS NULL
	LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='NAM' AND d.endet IS NULL
	WHERE o.endet IS NULL AND NOT name IS NULL
) AS n;
