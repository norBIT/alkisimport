SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Höhenlinien (61008)
--

SELECT 'Höhenlinien werden verarbeitet.';

-- TODO: Ob das wohl stimmt?
INSERT INTO po_lines(gml_id,gml_ids,thema,layer,line,signaturnummer,modell)
SELECT
	gml_id,
	ARRAY[gml_id] AS gml_ids,
	'Topographie' AS thema,
	'ax_hoehenlinie' AS layer,
	st_multi(wkb_geometry) AS line,
	CASE
	WHEN hoehevonhoehenlinie::int%20=0	THEN 2670
	WHEN hoehevonhoehenlinie::int%10=0	THEN 2672
	WHEN (hoehevonhoehenlinie*2)::int%10=0  THEN 2674
	WHEN (hoehevonhoehenlinie*4)::int%10=0  THEN 2676
	WHEN (hoehevonhoehenlinie*20)::int%10=0 THEN 2676
	WHEN (hoehevonhoehenlinie*40)::int%10=0 THEN 2676
	END AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM po_lastrun, ax_hoehenlinie
WHERE endet IS NULL AND beginnt>lastrun;

-- Namen
INSERT INTO po_labels(gml_id,gml_ids,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	o.gml_id,
	ARRAY[o.gml_id, t.gml_id, d.gml_id] AS gml_ids,
	'Topographie' AS thema,
	'ax_hoehenlinie' AS layer,
	coalesce(t.wkb_geometry,st_lineinterpolatepoint(o.wkb_geometry,0.5)) AS point,
	hoehevonhoehenlinie AS text,
	coalesce(d.signaturnummer,t.signaturnummer,'4104') AS signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
	coalesce(t.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM po_lastrun, ax_hoehenlinie o
LEFT OUTER JOIN po_pto t ON o.gml_id=t.dientzurdarstellungvon AND t.art='HHL'
LEFT OUTER JOIN po_darstellung d ON o.gml_id=d.dientzurdarstellungvon AND d.art='HHL'
WHERE o.endet IS NULL AND NOT hoehevonhoehenlinie IS NULL AND greatest(o.beginnt, t.beginnt, d.beginnt)>lastrun;
