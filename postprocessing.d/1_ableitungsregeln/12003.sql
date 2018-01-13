SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Lagebezeichnung mit Pseudonummer (12003)
--

SELECT 'Lagebezeichnungen mit Pseudonummer werden verarbeitet.';

INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	thema,
	'ax_lagebezeichnungmitpseudonummer' AS layer,
	(po).p AS point,
	text,
	signaturnummer,
	(po).a AS drehwinkel,
	horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung, modell
FROM (
	SELECT
		o.gml_id,
		CASE WHEN laufendenummer IS NULL THEN 'Lagebezeichnungen' ELSE 'Gebäude' END AS thema,
		alkis_pnr3002(o.gml_id, t.wkb_geometry, drehwinkel, o.land, o.regierungsbezirk, o.kreis, o.gemeinde, o.lage, g.wkb_geometry) AS po,
		coalesce('('||laufendenummer||')','P'||pseudonummer) AS text,
		coalesce(d.signaturnummer,t.signaturnummer,'4070') AS signaturnummer,
		horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_lagebezeichnungmitpseudonummer o
	JOIN ax_gebaeude g ON g.gehoertzu=o.gml_id AND g.endet IS NULL
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.endet IS NULL AND t.art='PNR'
	LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.endet IS NULL AND d.art='PNR'
	WHERE o.endet IS NULL
) AS foo;

-- Lagebezeichnung mit Pseudonummer, Ortsteil
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	o.gml_id,
	'Lagebezeichnungen' AS thema,
	'ax_lagebezeichnungmitpseudonummer' AS layer,
	t.wkb_geometry AS point,
	schriftinhalt AS text,
	coalesce(t.signaturnummer,'4160') AS signaturnummer,
	drehwinkel, horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung,
	coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM ax_lagebezeichnungmitpseudonummer o
JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.endet IS NULL AND t.art='Ort' AND schriftinhalt IS NOT NULL
WHERE o.endet IS NULL;

