SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Bauwerk oder Anlage für Sport, Freizeit und Erholung (51006)
--

SELECT 'Bauwerke oder Anlagen für Sport, Freizeit und Erholung werden verarbeitet.';

-- Bauwerk oder Anlage für Sport, Freizeit und Erholung, Flächen
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	'Sport und Freizeit' AS thema,
	'ax_bauwerkoderanlagefuersportfreizeitunderholung' AS layer,
	st_multi(wkb_geometry) AS polygon,
	CASE
	WHEN bauwerksfunktion IN (1410,1411,1412)                          THEN 1520
	WHEN bauwerksfunktion=1420                                         THEN 1521
	WHEN bauwerksfunktion IN (1430,1432,1460,1470,1480,1490,1510,9999) THEN 1524
	WHEN bauwerksfunktion=1431                                         THEN 1519
	WHEN bauwerksfunktion=1440                                         THEN 1522
	WHEN bauwerksfunktion=1450                                         THEN 1526
	END AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ax_bauwerkoderanlagefuersportfreizeitunderholung
WHERE geometrytype(wkb_geometry) IN ('POLYGON','MULTIPOLYGON') AND endet IS NULL;

-- Bauwerk oder Anlage für Sport, Freizeit und Erholung, Texte
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Sport und Freizeit' AS thema,
	'ax_bauwerkoderanlagefuersportfreizeitunderholung' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		CASE
		WHEN bauwerksfunktion IN (1430,1431,1432) THEN 'Tribüne'
		WHEN bauwerksfunktion=1460 THEN 'Liegewiese'
		WHEN bauwerksfunktion=1470 THEN 'Sprungschanze'
		WHEN bauwerksfunktion=1510 THEN 'Wildgehege'
		WHEN bauwerksfunktion=1450 THEN
			coalesce(
				t.schriftinhalt,
				(SELECT beschreibung FROM ax_bauwerksfunktion_bauwerkoderanlagefuersportfreizeitunde WHERE wert=bauwerksfunktion)
			)
		WHEN o.gml_id LIKE 'DERP%' AND bauwerksfunktion=1410 THEN
			coalesce(
				t.schriftinhalt,
				'Sportplatz'
			)
		END AS text,
		coalesce(d.signaturnummer,t.signaturnummer,'4100') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_bauwerkoderanlagefuersportfreizeitunderholung o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='BWF' AND t.endet IS NULL
	LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='BWF' AND d.endet IS NULL
	WHERE o.endet IS NULL
 ) AS o
WHERE NOT text IS NULL;

-- Bauwerk oder Anlage für Sport, Freizeit und Erholung, Symbole
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	gml_id,
	'Sport und Freizeit' AS thema,
	'ax_bauwerkoderanlagefuersportfreizeitunderholung' AS layer,
	st_multi(point),
	drehwinkel,
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		coalesce(p.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(p.drehwinkel,0) AS drehwinkel,
		coalesce(
			d.signaturnummer,
			p.signaturnummer,
			CASE
			WHEN bauwerksfunktion=1480 THEN '3524'
			WHEN bauwerksfunktion=1490 THEN '3525'
			END
		) AS signaturnummer,
		coalesce(p.advstandardmodell||p.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_bauwerkoderanlagefuersportfreizeitunderholung o
	LEFT OUTER JOIN ap_ppo p ON ARRAY[o.gml_id] <@ p.dientzurdarstellungvon AND p.art='BWF' AND p.endet IS NULL
	LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='BWF' AND d.endet IS NULL
	WHERE o.endet IS NULL
) AS o
WHERE NOT signaturnummer IS NULL;

-- Bauwerk oder Anlage für Sport, Freizeit und Erholung, Name
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Sport und Freizeit' AS thema,
	'ax_bauwerkoderanlagefuersportfreizeitunderholung' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
	modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(t.schriftinhalt,o.name) AS text,
		coalesce(d.signaturnummer,t.signaturnummer,'4141') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_bauwerkoderanlagefuersportfreizeitunderholung o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='NAM' AND t.endet IS NULL
	LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='NAM' AND d.endet IS NULL
	WHERE o.endet IS NULL AND NOT name IS NULL
) AS n;

-- Bauwerk oder Anlage für Sport, Freizeit und Erholung, Sportart
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Sport und Freizeit' AS thema,
	'ax_bauwerkoderanlagefuersportfreizeitunderholung' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		CASE
		WHEN sportart IN (1010,1020) THEN 'Sportplatz'
		WHEN sportart=1030           THEN 'Tennisplatz'
		WHEN sportart=1040           THEN 'Reitplatz'
		WHEN sportart=1060           THEN 'Skisportanlage'
		WHEN sportart=1070           THEN 'Eis-, Rollschuhbahn'
		WHEN sportart=1071           THEN 'Eisbahn'
		WHEN sportart=1072           THEN 'Rollschuhbahn'
		WHEN sportart=1090           THEN 'Motorrennbahn'
		WHEN sportart=1100           THEN 'Radrennbahn'
		WHEN sportart=1110           THEN 'Pferderennbahn'
		END AS text,
		coalesce(d.signaturnummer,t.signaturnummer,'4100') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_bauwerkoderanlagefuersportfreizeitunderholung o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='SPO' AND t.endet IS NULL
	LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='SPO' AND d.endet IS NULL
	WHERE o.endet IS NULL AND NOT sportart IS NULL
) AS n WHERE NOT text IS NULL;

-- Bauwerk oder Anlage für Sport, Freizeit und Erholung, Symbole
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	o.gml_id,
	'Sport und Freizeit' AS thema,
	'ax_bauwerkoderanlagefuersportfreizeitunderholung' AS layer,
	st_multi(coalesce(p.wkb_geometry,st_centroid(o.wkb_geometry))) AS point,
	coalesce(p.drehwinkel,0) AS drehwinkel,
	coalesce(d.signaturnummer,p.signaturnummer,'3409') AS signaturnummer,
	coalesce(p.advstandardmodell||p.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM ax_bauwerkoderanlagefuersportfreizeitunderholung o
LEFT OUTER JOIN ap_ppo p ON ARRAY[o.gml_id] <@ p.dientzurdarstellungvon AND p.art='SPO' AND p.endet IS NULL
LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='SPO' AND d.endet IS NULL
WHERE o.endet IS NULL AND sportart=1080;
