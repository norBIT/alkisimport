SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- TNA BW
--

SELECT 'TNA BW wird verarbeitet.';

INSERT INTO po_labels(gml_id,gml_ids,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
	SELECT
		gml_id,
		gml_ids,
		'Friedhöfe' AS thema,
		'ax_friedhof' AS layer,
		point,
		text,
		signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
	FROM (
		SELECT
			o.gml_id,
			ARRAY[o.gml_id, t.gml_id, d.gml_id] AS gml_ids,
			coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
			t.schriftinhalt AS text,
			coalesce(d.signaturnummer,t.signaturnummer,'4208') AS signaturnummer,
			drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
			coalesce(t.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
		FROM po_lastrun, ax_friedhof o
		JOIN po_pto t ON o.gml_id=t.dientzurdarstellungvon AND t.art='TNA' AND t.schriftinhalt IS NOT NULL
		LEFT OUTER JOIN po_darstellung d ON o.gml_id=d.dientzurdarstellungvon AND d.art='TNA'
		WHERE o.gml_id LIKE 'DEBW%' AND o.endet IS NULL AND NOT schriftinhalt IS NULL AND greatest(o.beginnt, t.beginnt, d.beginnt)>lastrun
	) AS n;


INSERT INTO po_labels(gml_id,gml_ids,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
	SELECT
		gml_id,
		gml_ids,
		'Gewässer' AS thema,
		'ax_fliessgewaesser' AS layer,
		point,
		text,
		signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
	FROM (
		SELECT
			o.gml_id,
			ARRAY[o.gml_id, t.gml_id, d.gml_id] AS gml_ids,
			coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
			t.schriftinhalt AS text,
			coalesce(d.signaturnummer,t.signaturnummer,'4208') AS signaturnummer,
			drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
			coalesce(t.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
		FROM po_lastrun, ax_fliessgewaesser o
		JOIN po_pto t ON o.gml_id=t.dientzurdarstellungvon AND t.art='TNA' AND t.schriftinhalt IS NOT NULL
		LEFT OUTER JOIN po_darstellung d ON o.gml_id=d.dientzurdarstellungvon AND d.art='TNA'
		WHERE o.gml_id LIKE 'DEBW%' AND o.endet IS NULL AND NOT schriftinhalt IS NULL AND greatest(o.beginnt, t.beginnt, d.beginnt)>lastrun
	) AS n;


INSERT INTO po_labels(gml_id,gml_ids,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
	SELECT
		gml_id,
		gml_ids,
		'Gewässer' AS thema,
		'ax_stehendesgewaesser' AS layer,
		point,
		text,
		signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
	FROM (
		SELECT
			o.gml_id,
			ARRAY[o.gml_id, t.gml_id, d.gml_id] AS gml_ids,
			coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
			t.schriftinhalt AS text,
			coalesce(d.signaturnummer,t.signaturnummer,'4208') AS signaturnummer,
			drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
			coalesce(t.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
		FROM po_lastrun, ax_stehendesgewaesser o
		JOIN po_pto t ON o.gml_id=t.dientzurdarstellungvon AND t.art='TNA' AND t.schriftinhalt IS NOT NULL
		LEFT OUTER JOIN po_darstellung d ON o.gml_id=d.dientzurdarstellungvon AND d.art='TNA'
		WHERE o.gml_id LIKE 'DEBW%' AND o.endet IS NULL AND NOT schriftinhalt IS NULL AND greatest(o.beginnt, t.beginnt, d.beginnt)>lastrun
	) AS n;


INSERT INTO po_labels(gml_id,gml_ids,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
	SELECT
		gml_id,
		gml_ids,
		'Industrie und Gewerbe' AS thema,
		'ax_flaechebesondererfunktionalerpraegung' AS layer,
		point,
		text,
		signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
	FROM (
		SELECT
			o.gml_id,
			ARRAY[o.gml_id, t.gml_id, d.gml_id] AS gml_ids,
			coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
			t.schriftinhalt AS text,
			coalesce(d.signaturnummer,t.signaturnummer,'4208') AS signaturnummer,
			drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
			coalesce(t.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
		FROM po_lastrun, ax_flaechebesondererfunktionalerpraegung o
		JOIN po_pto t ON o.gml_id=t.dientzurdarstellungvon AND t.art='TNA' AND t.schriftinhalt IS NOT NULL
		LEFT OUTER JOIN po_darstellung d ON o.gml_id=d.dientzurdarstellungvon AND d.art='TNA'
		WHERE o.gml_id LIKE 'DEBW%' AND o.endet IS NULL AND NOT schriftinhalt IS NULL AND greatest(o.beginnt, t.beginnt, d.beginnt)>lastrun
	) AS n;


INSERT INTO po_labels(gml_id,gml_ids,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
	SELECT
		gml_id,
		gml_ids,
		'Industrie und Gewerbe' AS thema,
		'ax_flaechegemischternutzung' AS layer,
		point,
		text,
		signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
	FROM (
		SELECT
			o.gml_id,
			ARRAY[o.gml_id, t.gml_id, d.gml_id] AS gml_ids,
			coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
			t.schriftinhalt AS text,
			coalesce(d.signaturnummer,t.signaturnummer,'4208') AS signaturnummer,
			drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
			coalesce(t.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
		FROM po_lastrun, ax_flaechegemischternutzung o
		JOIN po_pto t ON o.gml_id=t.dientzurdarstellungvon AND t.art='TNA' AND t.schriftinhalt IS NOT NULL
		LEFT OUTER JOIN po_darstellung d ON o.gml_id=d.dientzurdarstellungvon AND d.art='TNA'
		WHERE o.gml_id LIKE 'DEBW%' AND o.endet IS NULL AND NOT schriftinhalt IS NULL AND greatest(o.beginnt, t.beginnt, d.beginnt)>lastrun
	) AS n;


INSERT INTO po_labels(gml_id,gml_ids,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
	SELECT
		gml_id,
		gml_ids,
		'Industrie und Gewerbe' AS thema,
		'ax_industrieundgewerbeflaeche' AS layer,
		point,
		text,
		signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
	FROM (
		SELECT
			o.gml_id,
			ARRAY[o.gml_id, t.gml_id, d.gml_id] AS gml_ids,
			coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
			t.schriftinhalt AS text,
			coalesce(d.signaturnummer,t.signaturnummer,'4208') AS signaturnummer,
			drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
			coalesce(t.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
		FROM po_lastrun, ax_industrieundgewerbeflaeche o
		JOIN po_pto t ON o.gml_id=t.dientzurdarstellungvon AND t.art='TNA' AND t.schriftinhalt IS NOT NULL
		LEFT OUTER JOIN po_darstellung d ON o.gml_id=d.dientzurdarstellungvon AND d.art='TNA'
		WHERE o.gml_id LIKE 'DEBW%' AND o.endet IS NULL AND NOT schriftinhalt IS NULL AND greatest(o.beginnt, t.beginnt, d.beginnt)>lastrun
	) AS n;


INSERT INTO po_labels(gml_id,gml_ids,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
	SELECT
		gml_id,
		gml_ids,
		'Industrie und Gewerbe' AS thema,
		'ax_tagebaugrubesteinbruch' AS layer,
		point,
		text,
		signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
	FROM (
		SELECT
			o.gml_id,
			ARRAY[o.gml_id, t.gml_id, d.gml_id] AS gml_ids,
			coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
			t.schriftinhalt AS text,
			coalesce(d.signaturnummer,t.signaturnummer,'4208') AS signaturnummer,
			drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
			coalesce(t.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
		FROM po_lastrun, ax_tagebaugrubesteinbruch o
		JOIN po_pto t ON o.gml_id=t.dientzurdarstellungvon AND t.art='TNA' AND t.schriftinhalt IS NOT NULL
		LEFT OUTER JOIN po_darstellung d ON o.gml_id=d.dientzurdarstellungvon AND d.art='TNA'
		WHERE o.gml_id LIKE 'DEBW%' AND o.endet IS NULL AND NOT schriftinhalt IS NULL AND greatest(o.beginnt, t.beginnt, d.beginnt)>lastrun
	) AS n;


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
			t.schriftinhalt AS text,
			coalesce(d.signaturnummer,t.signaturnummer,'4208') AS signaturnummer,
			drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
			coalesce(t.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
		FROM po_lastrun, ax_sportfreizeitunderholungsflaeche o
		JOIN po_pto t ON o.gml_id=t.dientzurdarstellungvon AND t.art='TNA' AND t.schriftinhalt IS NOT NULL
		LEFT OUTER JOIN po_darstellung d ON o.gml_id=d.dientzurdarstellungvon AND d.art='TNA'
		WHERE o.gml_id LIKE 'DEBW%' AND o.endet IS NULL AND NOT schriftinhalt IS NULL AND greatest(o.beginnt, t.beginnt, d.beginnt)>lastrun
	) AS n;


INSERT INTO po_labels(gml_id,gml_ids,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
	SELECT
		gml_id,
		gml_ids,
		'Vegetation' AS thema,
		'ax_gehoelz' AS layer,
		point,
		text,
		signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
	FROM (
		SELECT
			o.gml_id,
			ARRAY[o.gml_id, t.gml_id, d.gml_id] AS gml_ids,
			coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
			t.schriftinhalt AS text,
			coalesce(d.signaturnummer,t.signaturnummer,'4208') AS signaturnummer,
			drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
			coalesce(t.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
		FROM po_lastrun, ax_gehoelz o
		JOIN po_pto t ON o.gml_id=t.dientzurdarstellungvon AND t.art='TNA' AND t.schriftinhalt IS NOT NULL
		LEFT OUTER JOIN po_darstellung d ON o.gml_id=d.dientzurdarstellungvon AND d.art='TNA'
		WHERE o.gml_id LIKE 'DEBW%' AND o.endet IS NULL AND NOT schriftinhalt IS NULL AND greatest(o.beginnt, t.beginnt, d.beginnt)>lastrun
	) AS n;


INSERT INTO po_labels(gml_id,gml_ids,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
	SELECT
		gml_id,
		gml_ids,
		'Vegetation' AS thema,
		'ax_landwirtschaft' AS layer,
		point,
		text,
		signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
	FROM (
		SELECT
			o.gml_id,
			ARRAY[o.gml_id, t.gml_id, d.gml_id] AS gml_ids,
			coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
			t.schriftinhalt AS text,
			coalesce(d.signaturnummer,t.signaturnummer,'4208') AS signaturnummer,
			drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
			coalesce(t.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
		FROM po_lastrun, ax_landwirtschaft o
		JOIN po_pto t ON o.gml_id=t.dientzurdarstellungvon AND t.art='TNA' AND t.schriftinhalt IS NOT NULL
		LEFT OUTER JOIN po_darstellung d ON o.gml_id=d.dientzurdarstellungvon AND d.art='TNA'
		WHERE o.gml_id LIKE 'DEBW%' AND o.endet IS NULL AND NOT schriftinhalt IS NULL AND greatest(o.beginnt, t.beginnt, d.beginnt)>lastrun
	) AS n;


INSERT INTO po_labels(gml_id,gml_ids,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
	SELECT
		gml_id,
		gml_ids,
		'Vegetation' AS thema,
		'ax_unlandvegetationsloseflaeche' AS layer,
		point,
		text,
		signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
	FROM (
		SELECT
			o.gml_id,
			ARRAY[o.gml_id, t.gml_id, d.gml_id] AS gml_ids,
			coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
			t.schriftinhalt AS text,
			coalesce(d.signaturnummer,t.signaturnummer,'4208') AS signaturnummer,
			drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
			coalesce(t.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
		FROM po_lastrun, ax_unlandvegetationsloseflaeche o
		JOIN po_pto t ON o.gml_id=t.dientzurdarstellungvon AND t.art='TNA' AND t.schriftinhalt IS NOT NULL
		LEFT OUTER JOIN po_darstellung d ON o.gml_id=d.dientzurdarstellungvon AND d.art='TNA'
		WHERE o.gml_id LIKE 'DEBW%' AND o.endet IS NULL AND NOT schriftinhalt IS NULL AND greatest(o.beginnt, t.beginnt, d.beginnt)>lastrun
	) AS n;


INSERT INTO po_labels(gml_id,gml_ids,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
	SELECT
		gml_id,
		gml_ids,
		'Vegetation' AS thema,
		'ax_wald' AS layer,
		point,
		text,
		signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
	FROM (
		SELECT
			o.gml_id,
			ARRAY[o.gml_id, t.gml_id, d.gml_id] AS gml_ids,
			coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
			t.schriftinhalt AS text,
			coalesce(d.signaturnummer,t.signaturnummer,'4208') AS signaturnummer,
			drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
			coalesce(t.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
		FROM po_lastrun, ax_wald o
		JOIN po_pto t ON o.gml_id=t.dientzurdarstellungvon AND t.art='TNA' AND t.schriftinhalt IS NOT NULL
		LEFT OUTER JOIN po_darstellung d ON o.gml_id=d.dientzurdarstellungvon AND d.art='TNA'
		WHERE o.gml_id LIKE 'DEBW%' AND o.endet IS NULL AND NOT schriftinhalt IS NULL AND greatest(o.beginnt, t.beginnt, d.beginnt)>lastrun
	) AS n;


INSERT INTO po_labels(gml_id,gml_ids,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
	SELECT
		gml_id,
		gml_ids,
		'Verkehr' AS thema,
		'ax_bahnverkehr' AS layer,
		point,
		text,
		signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
	FROM (
		SELECT
			o.gml_id,
			ARRAY[o.gml_id, t.gml_id, d.gml_id] AS gml_ids,
			coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
			t.schriftinhalt AS text,
			coalesce(d.signaturnummer,t.signaturnummer,'4208') AS signaturnummer,
			drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
			coalesce(t.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
		FROM po_lastrun, ax_bahnverkehr o
		JOIN po_pto t ON o.gml_id=t.dientzurdarstellungvon AND t.art='TNA' AND t.schriftinhalt IS NOT NULL
		LEFT OUTER JOIN po_darstellung d ON o.gml_id=d.dientzurdarstellungvon AND d.art='TNA'
		WHERE o.gml_id LIKE 'DEBW%' AND o.endet IS NULL AND NOT schriftinhalt IS NULL AND greatest(o.beginnt, t.beginnt, d.beginnt)>lastrun
	) AS n;


INSERT INTO po_labels(gml_id,gml_ids,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
	SELECT
		gml_id,
		gml_ids,
		'Verkehr' AS thema,
		'ax_platz' AS layer,
		point,
		text,
		signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
	FROM (
		SELECT
			o.gml_id,
			ARRAY[o.gml_id, t.gml_id, d.gml_id] AS gml_ids,
			coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
			t.schriftinhalt AS text,
			coalesce(d.signaturnummer,t.signaturnummer,'4208') AS signaturnummer,
			drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
			coalesce(t.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
		FROM po_lastrun, ax_platz o
		JOIN po_pto t ON o.gml_id=t.dientzurdarstellungvon AND t.art='TNA' AND t.schriftinhalt IS NOT NULL
		LEFT OUTER JOIN po_darstellung d ON o.gml_id=d.dientzurdarstellungvon AND d.art='TNA'
		WHERE o.gml_id LIKE 'DEBW%' AND o.endet IS NULL AND NOT schriftinhalt IS NULL AND greatest(o.beginnt, t.beginnt, d.beginnt)>lastrun
	) AS n;


INSERT INTO po_labels(gml_id,gml_ids,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
	SELECT
		gml_id,
		gml_ids,
		'Verkehr' AS thema,
		'ax_strassenverkehr' AS layer,
		point,
		text,
		signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
	FROM (
		SELECT
			o.gml_id,
			ARRAY[o.gml_id, t.gml_id, d.gml_id] AS gml_ids,
			coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
			t.schriftinhalt AS text,
			coalesce(d.signaturnummer,t.signaturnummer,'4208') AS signaturnummer,
			drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
			coalesce(t.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
		FROM po_lastrun, ax_strassenverkehr o
		JOIN po_pto t ON o.gml_id=t.dientzurdarstellungvon AND t.art='TNA' AND t.schriftinhalt IS NOT NULL
		LEFT OUTER JOIN po_darstellung d ON o.gml_id=d.dientzurdarstellungvon AND d.art='TNA'
		WHERE o.gml_id LIKE 'DEBW%' AND o.endet IS NULL AND NOT schriftinhalt IS NULL AND greatest(o.beginnt, t.beginnt, d.beginnt)>lastrun
	) AS n;


INSERT INTO po_labels(gml_id,gml_ids,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
	SELECT
		gml_id,
		gml_ids,
		'Verkehr' AS thema,
		'ax_weg' AS layer,
		point,
		text,
		signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
	FROM (
		SELECT
			o.gml_id,
			ARRAY[o.gml_id, t.gml_id, d.gml_id] AS gml_ids,
			coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
			t.schriftinhalt AS text,
			coalesce(d.signaturnummer,t.signaturnummer,'4208') AS signaturnummer,
			drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
			coalesce(t.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
		FROM po_lastrun, ax_weg o
		JOIN po_pto t ON o.gml_id=t.dientzurdarstellungvon AND t.art='TNA' AND t.schriftinhalt IS NOT NULL
		LEFT OUTER JOIN po_darstellung d ON o.gml_id=d.dientzurdarstellungvon AND d.art='TNA'
		WHERE o.gml_id LIKE 'DEBW%' AND o.endet IS NULL AND NOT schriftinhalt IS NULL AND greatest(o.beginnt, t.beginnt, d.beginnt)>lastrun
	) AS n;


INSERT INTO po_labels(gml_id,gml_ids,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
	SELECT
		gml_id,
		gml_ids,
		'Wohnbauflächen' AS thema,
		'ax_wohnbauflaeche' AS layer,
		point,
		text,
		signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
	FROM (
		SELECT
			o.gml_id,
			ARRAY[o.gml_id, t.gml_id, d.gml_id] AS gml_ids,
			coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
			t.schriftinhalt AS text,
			coalesce(d.signaturnummer,t.signaturnummer,'4208') AS signaturnummer,
			drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
			coalesce(t.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
		FROM po_lastrun, ax_wohnbauflaeche o
		JOIN po_pto t ON o.gml_id=t.dientzurdarstellungvon AND t.art='TNA' AND t.schriftinhalt IS NOT NULL
		LEFT OUTER JOIN po_darstellung d ON o.gml_id=d.dientzurdarstellungvon AND d.art='TNA'
		WHERE o.gml_id LIKE 'DEBW%' AND o.endet IS NULL AND NOT schriftinhalt IS NULL AND greatest(o.beginnt, t.beginnt, d.beginnt)>lastrun
	) AS n;
