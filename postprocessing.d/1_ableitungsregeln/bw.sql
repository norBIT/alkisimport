SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- TNA BW
--

SELECT 'TNA BW wird verarbeitet.';

INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
	SELECT
		gml_id,
		'Friedhöfe' AS thema,
		'ax_friedhof' AS layer,
		point,
		text,
		signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
	FROM (
		SELECT
			o.gml_id,
			coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
			t.schriftinhalt AS text,
			coalesce(d.signaturnummer,t.signaturnummer,'4208') AS signaturnummer,
			drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
			coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
		FROM ax_friedhof o
		JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='TNA' AND t.endet IS NULL
		LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='TNA' AND d.endet IS NULL
		WHERE o.gml_id LIKE 'DEBW%' AND o.endet IS NULL AND NOT schriftinhalt IS NULL
	) AS n;


INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
	SELECT
		gml_id,
		'Gewässer' AS thema,
		'ax_fliessgewaesser' AS layer,
		point,
		text,
		signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
	FROM (
		SELECT
			o.gml_id,
			coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
			t.schriftinhalt AS text,
			coalesce(d.signaturnummer,t.signaturnummer,'4208') AS signaturnummer,
			drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
			coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
		FROM ax_fliessgewaesser o
		JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='TNA' AND t.endet IS NULL
		LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='TNA' AND d.endet IS NULL
		WHERE o.gml_id LIKE 'DEBW%' AND o.endet IS NULL AND NOT schriftinhalt IS NULL
	) AS n;


INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
	SELECT
		gml_id,
		'Gewässer' AS thema,
		'ax_stehendesgewaesser' AS layer,
		point,
		text,
		signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
	FROM (
		SELECT
			o.gml_id,
			coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
			t.schriftinhalt AS text,
			coalesce(d.signaturnummer,t.signaturnummer,'4208') AS signaturnummer,
			drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
			coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
		FROM ax_stehendesgewaesser o
		JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='TNA' AND t.endet IS NULL
		LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='TNA' AND d.endet IS NULL
		WHERE o.gml_id LIKE 'DEBW%' AND o.endet IS NULL AND NOT schriftinhalt IS NULL
	) AS n;


INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
	SELECT
		gml_id,
		'Industrie und Gewerbe' AS thema,
		'ax_flaechebesondererfunktionalerpraegung' AS layer,
		point,
		text,
		signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
	FROM (
		SELECT
			o.gml_id,
			coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
			t.schriftinhalt AS text,
			coalesce(d.signaturnummer,t.signaturnummer,'4208') AS signaturnummer,
			drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
			coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
		FROM ax_flaechebesondererfunktionalerpraegung o
		JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='TNA' AND t.endet IS NULL
		LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='TNA' AND d.endet IS NULL
		WHERE o.gml_id LIKE 'DEBW%' AND o.endet IS NULL AND NOT schriftinhalt IS NULL
	) AS n;


INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
	SELECT
		gml_id,
		'Industrie und Gewerbe' AS thema,
		'ax_flaechegemischternutzung' AS layer,
		point,
		text,
		signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
	FROM (
		SELECT
			o.gml_id,
			coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
			t.schriftinhalt AS text,
			coalesce(d.signaturnummer,t.signaturnummer,'4208') AS signaturnummer,
			drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
			coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
		FROM ax_flaechegemischternutzung o
		JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='TNA' AND t.endet IS NULL
		LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='TNA' AND d.endet IS NULL
		WHERE o.gml_id LIKE 'DEBW%' AND o.endet IS NULL AND NOT schriftinhalt IS NULL
	) AS n;


INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
	SELECT
		gml_id,
		'Industrie und Gewerbe' AS thema,
		'ax_industrieundgewerbeflaeche' AS layer,
		point,
		text,
		signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
	FROM (
		SELECT
			o.gml_id,
			coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
			t.schriftinhalt AS text,
			coalesce(d.signaturnummer,t.signaturnummer,'4208') AS signaturnummer,
			drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
			coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
		FROM ax_industrieundgewerbeflaeche o
		JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='TNA' AND t.endet IS NULL
		LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='TNA' AND d.endet IS NULL
		WHERE o.gml_id LIKE 'DEBW%' AND o.endet IS NULL AND NOT schriftinhalt IS NULL
	) AS n;


INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
	SELECT
		gml_id,
		'Industrie und Gewerbe' AS thema,
		'ax_tagebaugrubesteinbruch' AS layer,
		point,
		text,
		signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
	FROM (
		SELECT
			o.gml_id,
			coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
			t.schriftinhalt AS text,
			coalesce(d.signaturnummer,t.signaturnummer,'4208') AS signaturnummer,
			drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
			coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
		FROM ax_tagebaugrubesteinbruch o
		JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='TNA' AND t.endet IS NULL
		LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='TNA' AND d.endet IS NULL
		WHERE o.gml_id LIKE 'DEBW%' AND o.endet IS NULL AND NOT schriftinhalt IS NULL
	) AS n;


INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
	SELECT
		gml_id,
		'Sport und Freizeit' AS thema,
		'ax_sportfreizeitunderholungsflaeche' AS layer,
		point,
		text,
		signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
	FROM (
		SELECT
			o.gml_id,
			coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
			t.schriftinhalt AS text,
			coalesce(d.signaturnummer,t.signaturnummer,'4208') AS signaturnummer,
			drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
			coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
		FROM ax_sportfreizeitunderholungsflaeche o
		JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='TNA' AND t.endet IS NULL
		LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='TNA' AND d.endet IS NULL
		WHERE o.gml_id LIKE 'DEBW%' AND o.endet IS NULL AND NOT schriftinhalt IS NULL
	) AS n;


INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
	SELECT
		gml_id,
		'Vegetation' AS thema,
		'ax_gehoelz' AS layer,
		point,
		text,
		signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
	FROM (
		SELECT
			o.gml_id,
			coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
			t.schriftinhalt AS text,
			coalesce(d.signaturnummer,t.signaturnummer,'4208') AS signaturnummer,
			drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
			coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
		FROM ax_gehoelz o
		JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='TNA' AND t.endet IS NULL
		LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='TNA' AND d.endet IS NULL
		WHERE o.gml_id LIKE 'DEBW%' AND o.endet IS NULL AND NOT schriftinhalt IS NULL
	) AS n;


INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
	SELECT
		gml_id,
		'Vegetation' AS thema,
		'ax_landwirtschaft' AS layer,
		point,
		text,
		signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
	FROM (
		SELECT
			o.gml_id,
			coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
			t.schriftinhalt AS text,
			coalesce(d.signaturnummer,t.signaturnummer,'4208') AS signaturnummer,
			drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
			coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
		FROM ax_landwirtschaft o
		JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='TNA' AND t.endet IS NULL
		LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='TNA' AND d.endet IS NULL
		WHERE o.gml_id LIKE 'DEBW%' AND o.endet IS NULL AND NOT schriftinhalt IS NULL
	) AS n;


INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
	SELECT
		gml_id,
		'Vegetation' AS thema,
		'ax_unlandvegetationsloseflaeche' AS layer,
		point,
		text,
		signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
	FROM (
		SELECT
			o.gml_id,
			coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
			t.schriftinhalt AS text,
			coalesce(d.signaturnummer,t.signaturnummer,'4208') AS signaturnummer,
			drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
			coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
		FROM ax_unlandvegetationsloseflaeche o
		JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='TNA' AND t.endet IS NULL
		LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='TNA' AND d.endet IS NULL
		WHERE o.gml_id LIKE 'DEBW%' AND o.endet IS NULL AND NOT schriftinhalt IS NULL
	) AS n;


INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
	SELECT
		gml_id,
		'Vegetation' AS thema,
		'ax_wald' AS layer,
		point,
		text,
		signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
	FROM (
		SELECT
			o.gml_id,
			coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
			t.schriftinhalt AS text,
			coalesce(d.signaturnummer,t.signaturnummer,'4208') AS signaturnummer,
			drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
			coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
		FROM ax_wald o
		JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='TNA' AND t.endet IS NULL
		LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='TNA' AND d.endet IS NULL
		WHERE o.gml_id LIKE 'DEBW%' AND o.endet IS NULL AND NOT schriftinhalt IS NULL
	) AS n;


INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
	SELECT
		gml_id,
		'Verkehr' AS thema,
		'ax_bahnverkehr' AS layer,
		point,
		text,
		signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
	FROM (
		SELECT
			o.gml_id,
			coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
			t.schriftinhalt AS text,
			coalesce(d.signaturnummer,t.signaturnummer,'4208') AS signaturnummer,
			drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
			coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
		FROM ax_bahnverkehr o
		JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='TNA' AND t.endet IS NULL
		LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='TNA' AND d.endet IS NULL
		WHERE o.gml_id LIKE 'DEBW%' AND o.endet IS NULL AND NOT schriftinhalt IS NULL
	) AS n;


INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
	SELECT
		gml_id,
		'Verkehr' AS thema,
		'ax_platz' AS layer,
		point,
		text,
		signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
	FROM (
		SELECT
			o.gml_id,
			coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
			t.schriftinhalt AS text,
			coalesce(d.signaturnummer,t.signaturnummer,'4208') AS signaturnummer,
			drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
			coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
		FROM ax_platz o
		JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='TNA' AND t.endet IS NULL
		LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='TNA' AND d.endet IS NULL
		WHERE o.gml_id LIKE 'DEBW%' AND o.endet IS NULL AND NOT schriftinhalt IS NULL
	) AS n;


INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
	SELECT
		gml_id,
		'Verkehr' AS thema,
		'ax_strassenverkehr' AS layer,
		point,
		text,
		signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
	FROM (
		SELECT
			o.gml_id,
			coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
			t.schriftinhalt AS text,
			coalesce(d.signaturnummer,t.signaturnummer,'4208') AS signaturnummer,
			drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
			coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
		FROM ax_strassenverkehr o
		JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='TNA' AND t.endet IS NULL
		LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='TNA' AND d.endet IS NULL
		WHERE o.gml_id LIKE 'DEBW%' AND o.endet IS NULL AND NOT schriftinhalt IS NULL
	) AS n;


INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
	SELECT
		gml_id,
		'Verkehr' AS thema,
		'ax_weg' AS layer,
		point,
		text,
		signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
	FROM (
		SELECT
			o.gml_id,
			coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
			t.schriftinhalt AS text,
			coalesce(d.signaturnummer,t.signaturnummer,'4208') AS signaturnummer,
			drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
			coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
		FROM ax_weg o
		JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='TNA' AND t.endet IS NULL
		LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='TNA' AND d.endet IS NULL
		WHERE o.gml_id LIKE 'DEBW%' AND o.endet IS NULL AND NOT schriftinhalt IS NULL
	) AS n;


INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
	SELECT
		gml_id,
		'Wohnbauflächen' AS thema,
		'ax_wohnbauflaeche' AS layer,
		point,
		text,
		signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
	FROM (
		SELECT
			o.gml_id,
			coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
			t.schriftinhalt AS text,
			coalesce(d.signaturnummer,t.signaturnummer,'4208') AS signaturnummer,
			drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
			coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
		FROM ax_wohnbauflaeche o
		JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='TNA' AND t.endet IS NULL
		LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='TNA' AND d.endet IS NULL
		WHERE o.gml_id LIKE 'DEBW%' AND o.endet IS NULL AND NOT schriftinhalt IS NULL
	) AS n;

