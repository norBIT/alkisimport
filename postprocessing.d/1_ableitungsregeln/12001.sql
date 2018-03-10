SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Lagebezeichnung ohne Hausnummer (12001)
--

SELECT 'Lagebezeichnungen ohne Hausnummer werden verarbeitet.';

-- Flurnummer
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	o.gml_id,
	'Lagebezeichnungen' AS thema,
	'ax_gemarkungsteilflur' AS layer,
	t.wkb_geometry AS point,
	coalesce(schriftinhalt,CASE WHEN bezeichnung LIKE 'Flur %' THEN bezeichnung ELSE 'Flur '||bezeichnung END) AS text,
	coalesce(t.signaturnummer,'4200') AS signaturnummer,
	t.drehwinkel, t.horizontaleausrichtung, t.vertikaleausrichtung, t.skalierung, t.fontsperrung,
	coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM ax_gemarkungsteilflur o
JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='BEZ' AND t.endet IS NULL
WHERE coalesce(t.schriftinhalt,'')<>'Flur 0' AND o.endet IS NULL;

-- Gemarkungsnamen (RP)
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	o.gml_id,
	'Lagebezeichnungen' AS thema,
	'ax_gemarkung' AS layer,
	t.wkb_geometry AS point,
	coalesce(t.schriftinhalt,o.bezeichnung) AS text,
	coalesce(t.signaturnummer,'4200') AS signaturnummer,
	t.drehwinkel, t.horizontaleausrichtung, t.vertikaleausrichtung, t.skalierung, t.fontsperrung,
	coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM ax_gemarkung o
JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='BEZ' AND t.endet IS NULL AND schriftinhalt IS NOT NULL
WHERE o.endet IS NULL AND o.gml_id LIKE 'DERP%';

-- Gemarkungsnamen (RP)
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	o.gml_id,
	'Lagebezeichnungen' AS thema,
	'ax_gemeinde' AS layer,
	t.wkb_geometry AS point,
	coalesce(t.schriftinhalt,o.bezeichnung) AS text,
	coalesce(t.signaturnummer,'4200') AS signaturnummer,
	t.drehwinkel, t.horizontaleausrichtung, t.vertikaleausrichtung, t.skalierung, t.fontsperrung,
	coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM ax_gemeinde o
JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='BEZ' AND t.endet IS NULL AND schriftinhalt IS NOT NULL
WHERE o.endet IS NULL AND o.gml_id LIKE 'DERP%';

-- Lagebezeichnung Ortsteil
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	o.gml_id,
	'Lagebezeichnungen' AS thema,
	'ax_lagebezeichnungohnehausnummer' AS layer,
	t.wkb_geometry AS point,
	schriftinhalt AS text,
	coalesce(t.signaturnummer,'4160') AS signaturnummer,
	drehwinkel, horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung,
	coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM ax_lagebezeichnungohnehausnummer o
JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='Ort' AND t.endet IS NULL
WHERE coalesce(schriftinhalt,'')<>'' AND o.endet IS NULL;

-- Lagebezeichnungen
-- ohne Hausnummer bei Punkt
-- Gewanne
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	o.gml_id,
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
	coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM ax_lagebezeichnungohnehausnummer o
JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='Gewanne' AND t.endet IS NULL
WHERE o.endet IS NULL;

-- Straße/Weg
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	o.gml_id,
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
	coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM ax_lagebezeichnungohnehausnummer o
JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art IN ('Strasse','Weg') AND t.endet IS NULL
WHERE o.endet IS NULL;

-- Platz/Bahnverkehr
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	o.gml_id,
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
	coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM ax_lagebezeichnungohnehausnummer o
JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art IN ('Platz','Bahnverkehr') AND t.endet IS NULL
WHERE o.endet IS NULL;

-- Fließgewässer/Stehendes Gewässer
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	o.gml_id,
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
	coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM ax_lagebezeichnungohnehausnummer o
JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art IN ('Fliessgewaesser','StehendesGewaesser') AND t.endet IS NULL
WHERE o.endet IS NULL;

-- ohne Hausnummer auf Linie
-- Straße/Weg, Text auf Linie
INSERT INTO po_labels(gml_id,thema,layer,line,text,signaturnummer,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	o.gml_id,
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
	coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM ax_lagebezeichnungohnehausnummer o
JOIN ap_lto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art IN ('Strasse','Weg') AND t.endet IS NULL AND coalesce(t.signaturnummer,'')<>'6000'
WHERE o.endet IS NULL;

-- Platz/Bahnverkehr, Text auf Linien
INSERT INTO po_labels(gml_id,thema,layer,line,text,signaturnummer,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	o.gml_id,
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
	coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM ax_lagebezeichnungohnehausnummer o
JOIN ap_lto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art IN ('Platz','Bahnverkehr') AND t.endet IS NULL AND coalesce(t.signaturnummer,'')<>'6000'
WHERE o.endet IS NULL;

-- Fließgewässer/Stehendes Gewässer, Text auf Linien
INSERT INTO po_labels(gml_id,thema,layer,line,text,signaturnummer,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	o.gml_id,
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
	coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM ax_lagebezeichnungohnehausnummer o
JOIN ap_lto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art IN ('Fliessgewaesser','StehendesGewaesser') AND t.endet IS NULL
WHERE o.endet IS NULL;
