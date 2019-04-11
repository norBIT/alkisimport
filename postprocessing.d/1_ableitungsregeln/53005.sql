SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Seilbahn, Schwebebahn (53005)
--

SELECT 'Seil- und Schwebebahnen werden verarbeitet.';

INSERT INTO po_lines(gml_id,thema,layer,line,signaturnummer,modell)
SELECT
	gml_id,
	'Verkehr' AS thema,
	'ax_seilbahnschwebebahn' AS layer,
	st_multi(wkb_geometry) AS line,
	2001 AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ax_seilbahnschwebebahn o
WHERE endet IS NULL;

INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	gml_id,
	'Verkehr' AS thema,
	'ax_seilbahnschwebebahn' AS layer,
	st_multi( st_lineinterpolatepoint(line,o.offset) ) AS point,
	0.5*pi()-st_azimuth(st_lineinterpolatepoint(line,o.offset*0.9999), st_lineinterpolatepoint(line,CASE WHEN o.offset=0 THEN 0.001 WHEN o.offset*1.0001>1 THEN 1 ELSE o.offset*1.0001 END)) AS drehwinkel,
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		line,
		generate_series( 0, trunc(st_length(line)*1000.0)::int,
			CASE
			WHEN bahnkategorie IN (2100,2200,2300,2400,2600) THEN 16000
			WHEN bahnkategorie=2500                          THEN 20000
			END
		) / 1000.0 / st_length(line) AS offset,
		CASE
		WHEN bahnkategorie IN (2100,2200) THEN 3642
		WHEN bahnkategorie IN (2300,2400) THEN 3643
		WHEN bahnkategorie=2500           THEN 3644
		WHEN bahnkategorie=2600           THEN 3645
		END AS signaturnummer,
		modell
	FROM (
		SELECT
			gml_id,
			(st_dump(st_multi(wkb_geometry))).geom AS line,
			bahnkategorie,
			advstandardmodell||sonstigesmodell AS modell
		FROM ax_seilbahnschwebebahn o
		WHERE endet IS NULL
		  AND geometrytype(wkb_geometry) IN ('LINESTRING','MULTILINESTRING')
	) AS o
) AS o
WHERE NOT signaturnummer IS NULL;

-- Namen
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Verkehr' AS thema,
	'ax_seilbahnschwebebahn' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(d.signaturnummer,t.signaturnummer,'4107') AS signaturnummer,
		coalesce(t.schriftinhalt,name) AS text,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_seilbahnschwebebahn o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='NAM' AND t.endet IS NULL
	LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='NAM' AND d.endet IS NULL
	WHERE o.endet IS NULL AND (NOT name IS NULL OR NOT t.schriftinhalt IS NULL)
) AS n WHERE NOT text IS NULL;
