SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Lagebezeichnung mit Pseudonummer (12003)
--

SELECT 'Lagebezeichnungen mit Pseudonummer werden verarbeitet.';

CREATE TEMPORARY TABLE pna(p geometry, a double precision);

-- PNR 3002 (s. auch 12002.sql)
INSERT INTO po_labels(gml_id,gml_ids,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	gml_ids,
	thema,
	'ax_lagebezeichnungmitpseudonummer' AS layer,
	coalesce(wkb_geometry, (p).p) AS point,
	text,
	signaturnummer,
	coalesce(drehwinkel, (p).a) AS drehwinkel,
	horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung, modell
FROM (
	SELECT
		gml_id,
		gml_ids || fs_gml_id AS gml_ids,
		thema,
		wkb_geometry,
		drehwinkel,
		text,
		signaturnummer,
		horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung,
		modell,
		p,
		row_number() OVER (PARTITION BY gml_ids ORDER BY st_distance((p).p, fs_geom) ASC) AS i
	FROM (
		SELECT
			o.gml_id,
			ARRAY[o.gml_id, t.gml_id, d.gml_id, loh.gml_id, g.gml_id] AS gml_ids,
			CASE WHEN laufendenummer IS NULL THEN 'Lagebezeichnungen' ELSE 'Gebäude' END AS thema,
			t.wkb_geometry,
			t.drehwinkel,
			coalesce('('||laufendenummer||')','P'||pseudonummer) AS text,
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
						FROM (
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
												SELECT g
												FROM (
													SELECT st_multi(st_union(st_exteriorring((g).geom))) g
													FROM (
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
		FROM po_lastrun, ax_lagebezeichnungmitpseudonummer o
		LEFT OUTER JOIN po_pto t ON o.gml_id=t.dientzurdarstellungvon AND t.art='PNR'
		LEFT OUTER JOIN po_darstellung d ON o.gml_id=d.dientzurdarstellungvon AND d.art='PNR'
		JOIN ax_gebaeude g ON ARRAY[o.gml_id] <@ g.gehoertzu AND g.endet IS NULL AND (t.drehwinkel IS NULL OR t.wkb_geometry IS NULL)                -- nur wenn es kein pto gibt
		LEFT OUTER JOIN ax_lagebezeichnungohnehausnummer loh USING (land,regierungsbezirk,kreis,gemeinde,lage)
		LEFT OUTER JOIN ax_flurstueck f ON ARRAY[loh.gml_id] <@ f.zeigtAuf AND f.endet IS NULL AND (t.drehwinkel IS NULL OR t.wkb_geometry IS NULL)  -- nur wenn es kein pto gibt
		WHERE o.endet IS NULL
		  AND loh.endet IS NULL AND loh.unverschluesselt IS NULL
		  AND greatest(o.beginnt, t.beginnt, d.beginnt, g.beginnt, loh.beginnt, f.beginnt)>lastrun
	) AS a
) AS a
WHERE i=0 AND text IS NOT NULL;

-- Lagebezeichnung mit Pseudonummer, Ortsteil
INSERT INTO po_labels(gml_id,gml_ids,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	o.gml_id,
	ARRAY[o.gml_id, t.gml_id] AS gml_ids,
	'Lagebezeichnungen' AS thema,
	'ax_lagebezeichnungmitpseudonummer' AS layer,
	t.wkb_geometry AS point,
	schriftinhalt AS text,
	coalesce(t.signaturnummer,'4160') AS signaturnummer,
	drehwinkel, horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung,
	coalesce(t.modelle,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM po_lastrun, ax_lagebezeichnungmitpseudonummer o
JOIN po_pto t ON o.gml_id=t.dientzurdarstellungvon AND t.art='Ort' AND schriftinhalt IS NOT NULL
WHERE o.endet IS NULL AND greatest(o.beginnt, t.beginnt)>lastrun;
