SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Lagebezeichnung ohne Hausnummer (12001)
--

SELECT 'Lagebezeichnungen ohne Hausnummer werden verarbeitet.';

-- Flurnummer
INSERT INTO po_labels(gml_id,gml_ids,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	o.gml_id,
	ARRAY[o.gml_id, t.gml_id] AS gml_ids,
	'Lagebezeichnungen' AS thema,
	'ax_gemarkungsteilflur' AS layer,
	t.wkb_geometry AS point,
	coalesce(schriftinhalt,CASE WHEN bezeichnung LIKE 'Flur %' THEN bezeichnung ELSE 'Flur '||bezeichnung END) AS text,
	coalesce(t.signaturnummer,'4200') AS signaturnummer,
	t.drehwinkel, t.horizontaleausrichtung, t.vertikaleausrichtung, t.skalierung, t.fontsperrung,
	coalesce(t.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM po_lastrun, ax_gemarkungsteilflur o
JOIN po_pto t ON o.gml_id=t.dientzurdarstellungvon AND t.art='BEZ' AND t.gml_id<>'TRIGGER'
WHERE coalesce(t.schriftinhalt,'')<>'Flur 0' AND o.endet IS NULL AND greatest(o.beginnt, t.beginnt)>lastrun;

-- Gemarkungsnamen (RP)
INSERT INTO po_labels(gml_id,gml_ids,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	o.gml_id,
	ARRAY[o.gml_id, t.gml_id] AS gml_ids,
	'Lagebezeichnungen' AS thema,
	'ax_gemarkung' AS layer,
	t.wkb_geometry AS point,
	coalesce(t.schriftinhalt,o.bezeichnung) AS text,
	coalesce(t.signaturnummer,'4200') AS signaturnummer,
	t.drehwinkel, t.horizontaleausrichtung, t.vertikaleausrichtung, t.skalierung, t.fontsperrung,
	coalesce(t.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM po_lastrun, ax_gemarkung o
JOIN po_pto t ON o.gml_id=t.dientzurdarstellungvon AND t.art='BEZ' AND schriftinhalt IS NOT NULL
WHERE o.endet IS NULL AND o.gml_id LIKE 'DERP%' AND greatest(o.beginnt, t.beginnt)>lastrun;

-- Gemarkungsnamen (RP)
INSERT INTO po_labels(gml_id,gml_ids,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	o.gml_id,
	ARRAY[o.gml_id, t.gml_id] AS gml_ids,
	'Lagebezeichnungen' AS thema,
	'ax_gemeinde' AS layer,
	t.wkb_geometry AS point,
	coalesce(t.schriftinhalt,o.bezeichnung) AS text,
	coalesce(t.signaturnummer,'4200') AS signaturnummer,
	t.drehwinkel, t.horizontaleausrichtung, t.vertikaleausrichtung, t.skalierung, t.fontsperrung,
	coalesce(t.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM po_lastrun, ax_gemeinde o
JOIN po_pto t ON o.gml_id=t.dientzurdarstellungvon AND t.art='BEZ' AND schriftinhalt IS NOT NULL
WHERE o.endet IS NULL AND o.gml_id LIKE 'DERP%' AND greatest(o.beginnt, t.beginnt)>lastrun;

-- Lagebezeichnung Ortsteil
INSERT INTO po_labels(gml_id,gml_ids,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	o.gml_id,
	ARRAY[o.gml_id, t.gml_id] AS gml_id,
	'Lagebezeichnungen' AS thema,
	'ax_lagebezeichnungohnehausnummer' AS layer,
	t.wkb_geometry AS point,
	schriftinhalt AS text,
	coalesce(t.signaturnummer,'4160') AS signaturnummer,
	drehwinkel, horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung,
	coalesce(t.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM po_lastrun, ax_lagebezeichnungohnehausnummer o
JOIN po_pto t ON o.gml_id=t.dientzurdarstellungvon AND t.art='Ort' AND t.gml_id<>'TRIGGER'
WHERE coalesce(schriftinhalt,'')<>'' AND o.endet IS NULL AND greatest(o.beginnt, t.beginnt)>lastrun;

-- Lagebezeichnungen
-- ohne Hausnummer bei Punkt
-- Gewanne
INSERT INTO po_labels(gml_id,gml_ids,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	o.gml_id,
	ARRAY[o.gml_id, t.gml_id] AS gml_ids,
	'Lagebezeichnungen' AS thema,
	'ax_lagebezeichnungohnehausnummer' AS layer,
	t.wkb_geometry AS point,
	coalesce(
		schriftinhalt,
		unverschluesselt,
		(SELECT bezeichnung FROM ax_lagebezeichnungkatalogeintrag WHERE schluesselgesamt=to_char(o.land::int,'fm00')||coalesce(o.regierungsbezirk,'0')||to_char(o.kreis::int,'fm00')||to_char(o.gemeinde::int,'fm000')||o.lage ORDER BY beginnt DESC LIMIT 1),
		'(Lagebezeichnung zu '''||to_char(o.land::int,'fm00')||coalesce(o.regierungsbezirk,'0')||to_char(o.kreis::int,'fm00')||to_char(o.gemeinde::int,'fm000')||o.lage||''' fehlt)'
	) AS text,
	coalesce(t.signaturnummer,'4206') AS signaturnummer,
	drehwinkel, horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung,
	coalesce(t.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM po_lastrun, ax_lagebezeichnungohnehausnummer o
JOIN po_pto t ON o.gml_id=t.dientzurdarstellungvon AND t.art='Gewanne' AND t.gml_id<>'TRIGGER'
WHERE o.endet IS NULL AND greatest(o.beginnt, t.beginnt)>lastrun;

-- Straße/Weg
INSERT INTO po_labels(gml_id,gml_ids,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	o.gml_id,
	ARRAY[o.gml_id, t.gml_id] AS gml_ids,
	'Lagebezeichnungen' AS thema,
	'ax_lagebezeichnungohnehausnummer' AS layer,
	t.wkb_geometry AS point,
	coalesce(
		schriftinhalt,
		unverschluesselt,
		(SELECT bezeichnung FROM ax_lagebezeichnungkatalogeintrag WHERE schluesselgesamt=to_char(o.land::int,'fm00')||coalesce(o.regierungsbezirk,'0')||to_char(o.kreis::int,'fm00')||to_char(o.gemeinde::int,'fm000')||o.lage ORDER BY beginnt DESC LIMIT 1),
		'(Lagebezeichnung zu '''||to_char(o.land::int,'fm00')||coalesce(o.regierungsbezirk,'0')||to_char(o.kreis::int,'fm00')||to_char(o.gemeinde::int,'fm000')||o.lage||''' fehlt)'
	) AS text,
	coalesce(t.signaturnummer,'4107') AS signaturnummer,
	drehwinkel, horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung,
	coalesce(t.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM po_lastrun, ax_lagebezeichnungohnehausnummer o
JOIN po_pto t ON o.gml_id=t.dientzurdarstellungvon AND t.art IN ('Strasse','Weg') AND t.gml_id<>'TRIGGER'
WHERE o.endet IS NULL AND greatest(o.beginnt, t.beginnt)>lastrun;

-- Platz/Bahnverkehr
INSERT INTO po_labels(gml_id,gml_ids,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	o.gml_id,
	ARRAY[o.gml_id, t.gml_id] AS gml_ids,
	'Lagebezeichnungen' AS thema,
	'ax_lagebezeichnungohnehausnummer' AS layer,
	t.wkb_geometry AS point,
	coalesce(
		schriftinhalt,
		unverschluesselt,
		(SELECT bezeichnung FROM ax_lagebezeichnungkatalogeintrag WHERE schluesselgesamt=to_char(o.land::int,'fm00')||coalesce(o.regierungsbezirk,'0')||to_char(o.kreis::int,'fm00')||to_char(o.gemeinde::int,'fm000')||o.lage ORDER BY beginnt DESC LIMIT 1),
		'(Lagebezeichnung zu '''||to_char(o.land::int,'fm00')||coalesce(o.regierungsbezirk,'0')||to_char(o.kreis::int,'fm00')||to_char(o.gemeinde::int,'fm000')||o.lage||''' fehlt)'
	) AS text,
	coalesce(t.signaturnummer,'4141') AS signaturnummer,
	drehwinkel, horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung,
	coalesce(t.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM po_lastrun, ax_lagebezeichnungohnehausnummer o
JOIN po_pto t ON o.gml_id=t.dientzurdarstellungvon AND t.art IN ('Platz','Bahnverkehr') AND t.gml_id<>'TRIGGER'
WHERE o.endet IS NULL AND greatest(o.beginnt, t.beginnt)>lastrun;

-- Fließgewässer/Stehendes Gewässer
INSERT INTO po_labels(gml_id,gml_ids,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	o.gml_id,
	ARRAY[o.gml_id, t.gml_id] AS gml_ids,
	'Gewässer' AS thema,
	'ax_lagebezeichnungohnehausnummer' AS layer,
	t.wkb_geometry AS point,
	coalesce(
		schriftinhalt,
		unverschluesselt,
		(SELECT bezeichnung FROM ax_lagebezeichnungkatalogeintrag WHERE schluesselgesamt=to_char(o.land::int,'fm00')||coalesce(o.regierungsbezirk,'0')||to_char(o.kreis::int,'fm00')||to_char(o.gemeinde::int,'fm000')||o.lage ORDER BY beginnt DESC LIMIT 1),
		'(Lagebezeichnung zu '''||to_char(o.land::int,'fm00')||coalesce(o.regierungsbezirk,'0')||to_char(o.kreis::int,'fm00')||to_char(o.gemeinde::int,'fm000')||o.lage||''' fehlt)'
	) AS text,
	coalesce(signaturnummer,'4117') AS signaturnummer,
	drehwinkel, horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung,
	coalesce(t.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM po_lastrun, ax_lagebezeichnungohnehausnummer o
JOIN po_pto t ON o.gml_id=t.dientzurdarstellungvon AND t.art IN ('Fliessgewaesser','StehendesGewaesser') AND t.gml_id<>'TRIGGER'
WHERE o.endet IS NULL AND greatest(o.beginnt, t.beginnt)>lastrun;

-- ohne Hausnummer auf Linie
-- Straße/Weg, Text auf Linie
INSERT INTO po_labels(gml_id,gml_ids,thema,layer,line,text,signaturnummer,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	o.gml_id,
	ARRAY[o.gml_id, t.gml_id] AS gml_ids,
	'Lagebezeichnungen' AS thema,
	'ax_lagebezeichnungohnehausnummer' AS layer,
	t.wkb_geometry AS line,
	coalesce(
		schriftinhalt,
		unverschluesselt,
		(SELECT bezeichnung FROM ax_lagebezeichnungkatalogeintrag WHERE schluesselgesamt=to_char(o.land::int,'fm00')||coalesce(o.regierungsbezirk,'0')||to_char(o.kreis::int,'fm00')||to_char(o.gemeinde::int,'fm000')||o.lage ORDER BY beginnt DESC LIMIT 1),
		'(Lagebezeichnung zu '''||to_char(o.land::int,'fm00')||coalesce(o.regierungsbezirk,'0')||to_char(o.kreis::int,'fm00')||to_char(o.gemeinde::int,'fm000')||o.lage||''' fehlt)'
	) AS text,
	4107 AS signaturnummer,
	horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung,
	coalesce(t.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM po_lastrun, ax_lagebezeichnungohnehausnummer o
JOIN po_lto t ON o.gml_id=t.dientzurdarstellungvon AND t.art IN ('Strasse','Weg') AND coalesce(t.signaturnummer,'')<>'6000' AND t.gml_id<>'TRIGGER'
WHERE o.endet IS NULL AND greatest(o.beginnt, t.beginnt)>lastrun;

-- Platz/Bahnverkehr, Text auf Linien
INSERT INTO po_labels(gml_id,gml_ids,thema,layer,line,text,signaturnummer,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	o.gml_id,
	ARRAY[o.gml_id, t.gml_id] AS gml_ids,
	'Lagebezeichnungen' AS thema,
	'ax_lagebezeichnungohnehausnummer' AS layer,
	t.wkb_geometry AS line,
	coalesce(
		schriftinhalt,
		unverschluesselt,
		(SELECT bezeichnung FROM ax_lagebezeichnungkatalogeintrag WHERE schluesselgesamt=to_char(o.land::int,'fm00')||coalesce(o.regierungsbezirk,'0')||to_char(o.kreis::int,'fm00')||to_char(o.gemeinde::int,'fm000')||o.lage ORDER BY beginnt DESC LIMIT 1),
		'(Lagebezeichnung zu '''||to_char(o.land::int,'fm00')||coalesce(o.regierungsbezirk,'0')||to_char(o.kreis::int,'fm00')||to_char(o.gemeinde::int,'fm000')||o.lage||''' fehlt)'
	) AS text,
	4141 AS signaturnummer,
	horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung,
	coalesce(t.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM po_lastrun, ax_lagebezeichnungohnehausnummer o
JOIN po_lto t ON o.gml_id=t.dientzurdarstellungvon AND t.art IN ('Platz','Bahnverkehr') AND coalesce(t.signaturnummer,'')<>'6000' AND t.gml_id<>'TRIGGER'
WHERE o.endet IS NULL AND greatest(o.beginnt, t.beginnt)>lastrun;

-- Fließgewässer/Stehendes Gewässer, Text auf Linien
INSERT INTO po_labels(gml_id,gml_ids,thema,layer,line,text,signaturnummer,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	o.gml_id,
	ARRAY[o.gml_id, t.gml_id] AS gml_ids,
	'Gewässer' AS thema,
	'ax_lagebezeichnungohnehausnummer' AS layer,
	t.wkb_geometry AS line,
	coalesce(
		schriftinhalt,
		unverschluesselt,
		(SELECT bezeichnung FROM ax_lagebezeichnungkatalogeintrag WHERE schluesselgesamt=to_char(o.land::int,'fm00')||coalesce(o.regierungsbezirk,'0')||to_char(o.kreis::int,'fm00')||to_char(o.gemeinde::int,'fm000')||o.lage ORDER BY beginnt DESC LIMIT 1),
		'(Lagebezeichnung zu '''||to_char(o.land::int,'fm00')||coalesce(o.regierungsbezirk,'0')||to_char(o.kreis::int,'fm00')||to_char(o.gemeinde::int,'fm000')||o.lage||''' fehlt)'
	) AS text,
	coalesce(t.signaturnummer,'4117') AS signaturnummer,
	horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung,
	coalesce(t.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM po_lastrun, ax_lagebezeichnungohnehausnummer o
JOIN po_lto t ON o.gml_id=t.dientzurdarstellungvon AND t.art IN ('Fliessgewaesser','StehendesGewaesser') AND t.gml_id<>'TRIGGER'
WHERE o.endet IS NULL AND greatest(o.beginnt, t.beginnt)>lastrun;
