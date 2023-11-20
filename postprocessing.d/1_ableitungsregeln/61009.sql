SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Besonderer topographischer Punkt (61009)
--

SELECT 'Besondere topographische Punkte werden verarbeitet.';

INSERT INTO po_points(gml_id,gml_ids,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	o.gml_id,
	ARRAY[o.gml_id, p.gml_id] AS gml_ids,	
	'Topographie' AS thema,
	'ax_besonderertopographischerpunkt' AS layer,
	st_multi(st_force2d(p.wkb_geometry)) AS point,
	0 AS drehwinkel,
	3629 AS signaturnummer,
	coalesce(p.advstandardmodell||p.sonstigesmodell||o.advstandardmodell||o.sonstigesmodell) AS modell
FROM po_lastrun, ax_besonderertopographischerpunkt o
JOIN ax_punktortau p ON ARRAY[o.gml_id] <@ p.istteilvon AND p.endet IS NULL
WHERE o.endet IS NULL AND greatest(o.beginnt, p.beginnt)>lastrun;

-- Text
-- TODO: 14003 [UPO] steht für welches Beschriftungsfeld?
INSERT INTO po_labels(gml_id,gml_ids,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	o.gml_id,
	ARRAY[o.gml_id, t.gml_id] AS gml_ids,
	'Topographie' AS thema,
	'ax_besonderertopographischerpunkt' AS layer,
	t.wkb_geometry AS point,
	coalesce(schriftinhalt,punktkennung) AS text,
	coalesce(t.signaturnummer,'4104') AS signaturnummer,
	drehwinkel,
	horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
	coalesce(t.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM po_lastrun, ax_besonderertopographischerpunkt o
JOIN po_pto t ON o.gml_id=t.dientzurdarstellungvon AND t.art='UPO' AND t.gml_id<>'TRIGGER'
WHERE o.endet IS NULL AND greatest(o.beginnt, t.beginnt)>lastrun;
