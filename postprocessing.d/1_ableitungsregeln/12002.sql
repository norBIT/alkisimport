SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Lagebezeichnung mit Hausnummer (12002)
--

SELECT 'Lagebezeichnungen mit Hausnummer werden verarbeitet.';

-- mit Hausnummer, Ortsteil
SELECT ' Ortsteil verarbeitet.';
INSERT INTO po_labels(gml_id,gml_ids,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	o.gml_id,
	ARRAY[o.gml_id, t.gml_id] AS gml_ids,
	'Gebäude' AS thema,
	'ax_lagebezeichnungmithausnummer' AS layer,
	t.wkb_geometry AS point,
	schriftinhalt AS text,
	coalesce(t.signaturnummer,'4160') AS signaturnummer,
	drehwinkel, horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung,
	coalesce(t.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM po_lastrun, ax_lagebezeichnungmithausnummer o
JOIN po_pto t ON o.gml_id=t.dientzurdarstellungvon AND t.art='Ort' AND t.gml_id<>'TRIGGER'
WHERE coalesce(schriftinhalt,'')<>'' AND o.endet IS NULL AND greatest(o.beginnt, t.beginnt)>lastrun;

ANALYZE ax_lagebezeichnungmithausnummer;
ANALYZE ax_lagebezeichnungohnehausnummer;

-- mit Hausnummer (bezieht sich auf Gebäude, Turm oder Flurstück)
SELECT ' Gebäudehausnummern werden verarbeitet.';

CREATE TEMPORARY TABLE po_zeigtauf_hausnummer(
	gml_ids character(16)[],
	beginnt character(20),
	zeigtauf character(16),
	wkb_geometry GEOMETRY,
	prefix varchar
);

CREATE INDEX po_zeigtauf_hausnummer_zeigtauf ON po_zeigtauf_hausnummer(zeigtauf);

INSERT INTO po_zeigtauf_hausnummer
	SELECT
		gml_ids, beginnt, zeigtauf, wkb_geometry, prefix
	FROM (
		SELECT
			ARRAY[z.gml_id, lmh.gml_id] AS gml_ids,
			greatest(z.beginnt, lmh.beginnt) AS beginnt,
			unnest(zeigtauf) AS zeigtauf,
			wkb_geometry,
			'' AS prefix
		FROM ax_turm z
		JOIN ax_lagebezeichnungmithausnummer lmh ON ARRAY[lmh.gml_id] <@ z.zeigtAuf AND lmh.endet IS NULL
		WHERE z.endet IS NULL
	) AS z;

ANALYZE po_zeigtauf_hausnummer;

INSERT INTO po_zeigtauf_hausnummer
	SELECT
		gml_ids, beginnt, zeigtauf, wkb_geometry, prefix
	FROM (
		SELECT
			ARRAY[z.gml_id, lmh.gml_id] AS gml_ids,
			greatest(z.beginnt, lmh.beginnt) AS beginnt,
			unnest(zeigtauf) AS zeigtauf,
			wkb_geometry,
			'' AS prefix
		FROM ax_gebaeude z
		JOIN ax_lagebezeichnungmithausnummer lmh ON ARRAY[lmh.gml_id] <@ z.zeigtAuf AND lmh.endet IS NULL
		WHERE z.endet IS NULL
	) AS z
	WHERE NOT EXISTS (SELECT h.zeigtauf FROM po_zeigtauf_hausnummer h WHERE h.zeigtauf=z.zeigtauf);

ANALYZE po_zeigtauf_hausnummer;

INSERT INTO po_zeigtauf_hausnummer
	SELECT
		gml_ids, beginnt, zeigtauf, wkb_geometry, prefix
	FROM (
		SELECT
			ARRAY[z.gml_id, lmh.gml_id] AS gml_ids,
			greatest(z.beginnt, lmh.beginnt) AS beginnt,
			unnest(zeigtauf) AS zeigtauf,
			wkb_geometry,
			 'HsNr. ' AS prefix
		FROM ax_flurstueck z
		JOIN ax_lagebezeichnungmithausnummer lmh ON ARRAY[lmh.gml_id] <@ z.zeigtAuf AND lmh.endet IS NULL
		WHERE z.endet IS NULL
	) AS z
	WHERE NOT EXISTS (SELECT h.zeigtauf FROM po_zeigtauf_hausnummer h WHERE h.zeigtauf=z.zeigtauf);

ANALYZE po_zeigtauf_hausnummer;

CREATE TEMPORARY TABLE pna(p geometry, a double precision);

-- Normalerweise nur zeigtAuf Turm/Gebäude/Flurstück (kommt aber zumindest in Bayern und NRW auch ohne vor)
-- PNR 3002 (s. auch 12003.sql)
INSERT INTO po_labels(gml_id,gml_ids,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	gml_ids,
	'Gebäude' AS thema,
	'ax_lagebezeichnungmithausnummer' AS layer,
	coalesce(wkb_geometry, (p).p) AS point,
	text,
	signaturnummer,
	coalesce(drehwinkel, (p).a) AS drehwinkel,
	horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung, modell
FROM (
	SELECT
		gml_id,
		gml_ids || fs_gml_id AS gml_ids,
		wkb_geometry, drehwinkel, text, signaturnummer,
		horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung,
		modell,
		p,
		row_number() OVER (PARTITION BY gml_ids ORDER BY st_distance((p).p, fs_geom) ASC) AS i
	FROM (
		SELECT
			o.gml_id,
			ARRAY[o.gml_id, t.gml_id, d.gml_id, loh.gml_id] || g.gml_ids AS gml_ids,
			t.wkb_geometry,
			t.drehwinkel,
			coalesce(schriftinhalt,coalesce(g.prefix, '')||o.hausnummer) AS text,
			coalesce(d.signaturnummer,t.signaturnummer,'4070') AS signaturnummer,
			horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung,
			coalesce(t.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell,
			(
				SELECT
					row(
						p,
						CASE
						WHEN a BETWEEN 0.5*pi() AND pi() THEN a+pi()
						WHEN a BETWEEN pi() AND 1.5*pi() THEN a-pi()
						ELSE a
						END
					)::pna AS a
				FROM (
					SELECT
						p,
						CASE WHEN a<0 THEN 2*pi() + a ELSE a END AS a
					FROM (
						SELECT
							p,
							a-floor(a/2*pi())*2*pi() AS a
						FROM  (
							SELECT
								st_lineinterpolatepoint(seg, 0.5) AS p,
								0.5*pi()-st_azimuth(st_startpoint(seg), st_endpoint(seg)) AS a
							FROM (
								SELECT
									st_makeline(st_pointn(g,i), st_pointn(g,i+1)) AS seg
								FROM (
									SELECT
										generate_series(1,st_npoints(g)-1) AS i,
										g
									FROM (
										SELECT (st_dump(g)).geom AS g
										FROM (
											SELECT (st_dump(st_multi(f.wkb_geometry))).geom AS fs_geom, g
											FROM (
												-- Wenn es Multilinestrings sind
												SELECT g
												FROM (
													-- 2. Davon nur die Umringe
													SELECT st_multi(st_union(st_exteriorring((g).geom))) g
													FROM (
														-- 1. Bezuggeometrie (Turm/Gebäude/Flurstück) nach innen versetzen
														SELECT st_dump(g) AS g
														FROM st_multi(st_buffer(g.wkb_geometry, -1.9)) AS g
														WHERE geometrytype(g)='MULTIPOLYGON' AND st_numgeometries(g)>0
													) AS a
												) AS a
												WHERE geometrytype(g)='MULTILINESTRING'
											) AS a
										) AS a
										ORDER BY st_distance(fs_geom, g) ASC
										LIMIT 1
									) AS a
								) AS a
							) AS a
							WHERE st_length(seg)>1.5
							ORDER BY st_distance(f.wkb_geometry,st_lineinterpolatepoint(seg,0.5)) ASC, st_length(seg)
							LIMIT 1
						) AS a
					) AS a
				) AS a
			) AS p,
			f.gml_id AS fs_gml_id,
			f.wkb_geometry AS fs_geom
		FROM po_lastrun, ax_lagebezeichnungmithausnummer o
		LEFT OUTER JOIN po_pto t ON o.gml_id=t.dientzurdarstellungvon AND t.art='HNR'
		LEFT OUTER JOIN po_darstellung d ON o.gml_id=d.dientzurdarstellungvon AND d.art='HNR'
		LEFT OUTER JOIN po_zeigtauf_hausnummer g ON o.gml_id=g.zeigtauf AND (t.drehwinkel IS NULL OR t.wkb_geometry IS NULL)			     -- nur wenn es kein pto gibt
		LEFT OUTER JOIN ax_lagebezeichnungohnehausnummer loh USING (land,regierungsbezirk,kreis,gemeinde,lage)
		LEFT OUTER JOIN ax_flurstueck f ON ARRAY[loh.gml_id] <@ f.zeigtAuf AND f.endet IS NULL AND (t.drehwinkel IS NULL OR t.wkb_geometry IS NULL)  -- nur wenn es kein pto gibt
		WHERE o.endet IS NULL
		  AND loh.endet IS NULL AND loh.unverschluesselt IS NULL
		  AND greatest(o.beginnt, t.beginnt, d.beginnt, g.beginnt, loh.beginnt, f.beginnt)>lastrun
	) AS a
) AS a
WHERE i=1 AND text IS NOT NULL;
