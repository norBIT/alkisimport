SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Industrie- und Gewerbefläche (41002)
--

SELECT 'Industrie- und Gewerbeflächen werden verarbeitet.';

-- Industrie- und Gewerbefläche, Flächen
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	'Industrie und Gewerbe' AS thema,
	'ax_industrieundgewerbeflaeche' AS layer,
	st_multi(wkb_geometry) AS polygon,
	25151403 AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ax_industrieundgewerbeflaeche
WHERE endet IS NULL;

-- Industrie- und Gewerbefläche, Namen
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Industrie und Gewerbe' AS thema,
	'ax_industrieundgewerbeflaeche' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel, horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung, modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(t.schriftinhalt,o.name) AS text,
		coalesce(d.signaturnummer,t.signaturnummer,'4141') AS signaturnummer,
		drehwinkel, horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_industrieundgewerbeflaeche o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='NAM' AND t.endet IS NULL
	LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='NAM' AND d.endet IS NULL
	WHERE o.endet IS NULL
) AS i WHERE NOT text IS NULL;

-- Industrie- und Gewerbefläche, Funktionen
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Industrie und Gewerbe' AS thema,
	'ax_industrieundgewerbeflaeche' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel, horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung, modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_translate(st_centroid(o.wkb_geometry),0,-7)) AS point,
		CASE
		WHEN funktion=1740 THEN
			CASE
			WHEN coalesce(lagergut,0) IN (0,9999) THEN
				coalesce(
					schriftinhalt,
					(select beschreibung from ax_funktion_industrieundgewerbeflaeche where wert=funktion)
				)
			ELSE
				coalesce(
					schriftinhalt,
					(select beschreibung from ax_funktion_industrieundgewerbeflaeche where wert=funktion)
					|| E'\n('
					|| (select beschreibung from ax_lagergut_industrieundgewerbeflaeche where wert=lagergut)
					|| ')',
					(select beschreibung from ax_funktion_industrieundgewerbeflaeche where wert=funktion)
				)
			END
		WHEN o.gml_id LIKE 'DERP%' AND funktion=2502 THEN 'Versorgungsanlage'
		WHEN o.gml_id LIKE 'DERP%' AND funktion=2602 THEN 'Entsorgungsanlage'
		WHEN o.gml_id LIKE 'DERP%' AND funktion=2623 THEN 'Schlamm'
		WHEN funktion IN (2520,2522, 2550,2552, 2560,2562, 2580.2582, 2610,2612, 2620,2622, 2630, 2640 ) THEN
			coalesce(
				schriftinhalt,
				(SELECT beschreibung FROM ax_funktion_industrieundgewerbeflaeche WHERE wert=funktion)
			)
		WHEN funktion IN (2530,2532) THEN
			coalesce(
				schriftinhalt,
				'(' || (SELECT beschreibung FROM ax_primaerenergie_industrieundgewerbeflaeche WHERE wert=primaerenergie) || ')'
			)
		WHEN funktion IN (2570,2572) THEN
			CASE
			WHEN primaerenergie IS NULL THEN
				coalesce(
					schriftinhalt,
					(SELECT beschreibung FROM ax_funktion_industrieundgewerbeflaeche WHERE wert=funktion)
				)
			ELSE
				coalesce(
					schriftinhalt,
					(SELECT beschreibung FROM ax_funktion_industrieundgewerbeflaeche WHERE wert=funktion)
					|| E'\n('
					|| (SELECT beschreibung FROM ax_primaerenergie_industrieundgewerbeflaeche WHERE wert=primaerenergie)
					|| ')',
					(SELECT beschreibung FROM ax_funktion_industrieundgewerbeflaeche WHERE wert=funktion)
				)
			END
		END AS text,
		coalesce(d.signaturnummer,t.signaturnummer,'4140') AS signaturnummer,
		drehwinkel, horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_industrieundgewerbeflaeche o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='FKT' AND t.endet IS NULL
	LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='FKT' AND d.endet IS NULL
	WHERE o.endet IS NULL
) AS i WHERE NOT text IS NULL;

-- Industrie- und Gewerbefläche, Funktionssymbole
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	gml_id,
	'Industrie und Gewerbe' AS thema,
	'ax_industrieundgewerbeflaeche' AS layer,
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
			WHEN funktion=1730           THEN '3401'
			WHEN funktion=2510           THEN '3402'
			WHEN funktion IN (2530,2432) THEN '3403'
			WHEN funktion=2540           THEN '3404'
			END
		) AS signaturnummer,
		coalesce(
			p.advstandardmodell||p.sonstigesmodell||d.advstandardmodell||d.sonstigesmodell,
			o.advstandardmodell||o.sonstigesmodell
		) AS modell
	FROM ax_industrieundgewerbeflaeche o
	LEFT OUTER JOIN ap_ppo p ON ARRAY[o.gml_id] <@ p.dientzurdarstellungvon AND p.art='FKT' AND p.endet IS NULL
	LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='FKT' AND d.endet IS NULL
	WHERE o.endet IS NULL
) AS o
WHERE NOT signaturnummer IS NULL;
