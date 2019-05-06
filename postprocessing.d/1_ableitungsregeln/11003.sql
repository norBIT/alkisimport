SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Grenzpunkte (11003)
--

SELECT 'Grenzpunkte werden verarbeitet.';

CREATE TEMPORARY TABLE po_punktortta_istteilvon(gml_id character(16), istteilvon character(16));
INSERT INTO po_punktortta_istteilvon(gml_id, istteilvon)
	SELECT gml_id, unnest(istteilvon)
	FROM ax_punktortta
	WHERE endet IS NULL;
CREATE INDEX po_punktortta_istteilvon_itv ON po_punktortta_istteilvon(istteilvon);
ANALYZE po_punktortta_istteilvon;

INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	p.gml_id,
	'Flurstücke' AS thema,
	'ax_grenzpunkt' AS layer,
	st_multi(o.wkb_geometry) AS point,
	0 AS drehwinkel,
	CASE
	WHEN abmarkung_marke=1700 AND p.gml_id LIKE 'DENW%' THEN 3024
	WHEN abmarkung_marke=9500 AND p.gml_id LIKE 'DENW%' THEN 3024
	WHEN abmarkung_marke=9600 THEN 3022
	WHEN abmarkung_marke=9998 THEN 3024
	ELSE 3020
	END AS signaturnummer,
	o.advstandardmodell||o.sonstigesmodell||p.advstandardmodell||p.sonstigesmodell AS modell
FROM ax_grenzpunkt p
JOIN po_punktortta_istteilvon itv ON p.gml_id=itv.istteilvon
JOIN ax_punktortta o ON itv.gml_id=o.gml_id AND o.endet IS NULL
WHERE (abmarkung_marke<>9500 OR (abmarkung_marke = 9500 AND p.gml_id LIKE 'DENW%')) AND p.endet IS NULL;

/*
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	p.gml_id,
	'Flurstücke' AS thema,
	'ax_grenzpunkt' AS layer,
	st_multi(st_force2d(o.wkb_geometry)) AS point,
	0 AS drehwinkel,
	CASE abmarkung_marke
	WHEN 9600 THEN 3022
	WHEN 9998 THEN 3024
	ELSE 3020
	END AS signaturnummer,
	o.advstandardmodell||o.sonstigesmodell||
	p.advstandardmodell||p.sonstigesmodell AS modell
FROM ax_grenzpunkt p
JOIN ax_punktortau o ON ARRAY[p.gml_id] <@ o.istteilvon AND o.endet IS NULL
WHERE abmarkung_marke<>9500 AND p.endet IS NULL;
*/

UPDATE po_points
	SET signaturnummer=CASE signaturnummer
		WHEN '3022' THEN '3023'
		WHEN '3024' THEN '3025'
		ELSE '3021'
		END
	FROM ax_flurstueck f
	WHERE layer='ax_grenzpunkt'
	  AND f.endet IS NULL
	  AND f.abweichenderrechtszustand='true'
	  AND po_points.point && f.wkb_geometry
	  AND st_intersects(po_points.point,f.wkb_geometry);

-- Grenzpunktnummern
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	p.gml_id,
	'Flurstücke' AS thema,
	'ax_grenzpunkt' AS layer,
	coalesce(t.wkb_geometry,st_translate(o.wkb_geometry,1.06,1.06)) AS point,
	besonderePunktnummer AS text,
	coalesce(
		d.signaturnummer,
		t.signaturnummer,
		CASE
		WHEN NOT EXISTS (SELECT * FROM po_points f WHERE f.point=o.wkb_geometry AND layer='ax_grenzpunkt' AND signaturnummer IN ('3021','3023','3025'))
		THEN '4071'
		ELSE '4072'
		END
	) AS signaturnummer,
	t.drehwinkel,
	coalesce(t.horizontaleausrichtung,'linksbündig'::text),
	coalesce(t.vertikaleausrichtung, 'Basis'::text),
	t.skalierung, t.fontsperrung,
	coalesce(t.advstandardmodell||t.sonstigesmodell,p.advstandardmodell||p.sonstigesmodell||o.advstandardmodell||o.sonstigesmodell) AS modell
FROM ax_grenzpunkt p
JOIN po_punktortta_istteilvon itv ON p.gml_id=itv.istteilvon
JOIN ax_punktortta o ON itv.gml_id=o.gml_id AND o.endet IS NULL
LEFT OUTER JOIN ap_pto t ON ARRAY[p.gml_id] <@ t.dientzurdarstellungvon AND t.endet IS NULL
LEFT OUTER JOIN ap_darstellung d ON ARRAY[p.gml_id] <@ d.dientzurdarstellungvon AND d.endet IS NULL
WHERE coalesce(besonderePunktnummer,'')<>'' AND p.endet IS NULL;
