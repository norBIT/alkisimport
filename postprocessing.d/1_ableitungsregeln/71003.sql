SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Klassifizierungen nach Wasserrecht (71003)
-- (kommt in SK nicht vor)
--

SELECT 'Klassifizierungen nach Wasserrecht werden verarbeitet.';

INSERT INTO po_labels(gml_id,gml_ids,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	gml_ids,
	'Rechtliche Festlegungen' AS thema,
	'ax_klassifizierungnachwasserrecht' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		ARRAY[o.gml_id, t.gml_id] AS gml_ids,
		t.wkb_geometry AS point,
		schriftinhalt AS text,
		coalesce(t.signaturnummer,'4140') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM po_lastrun, ax_klassifizierungnachwasserrecht o
	JOIN po_pto t ON o.gml_id=t.dientzurdarstellungvon AND t.gml_id<>'TRIGGER'
	WHERE o.endet IS NULL AND greatest(o.beginnt, t.beginnt)>lastrun
) AS o
WHERE NOT text IS NULL;

-- TODO: Kam noch nicht vor
-- RP: ax_andereklassifizierungnachwasserrecht (71004)
-- RP: ax_anderefestlegungnachwasserrecht (71005)
