SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

SELECT 'Nachbearbeitung läuft...';

-- Polygonsignaturen aufteilen (1XXX = Fläche, 2XXX = Linie)
UPDATE po_polygons SET
	sn_flaeche=CASE
	WHEN signaturnummer::int BETWEEN 1000 AND 1999 THEN signaturnummer
	WHEN signaturnummer::int>10000 THEN
		CASE
		WHEN signaturnummer::int%10000 BETWEEN 1000 AND 1999 THEN (signaturnummer::int%10000)::text
		WHEN signaturnummer::int/10000 BETWEEN 1000 AND 1999 THEN (signaturnummer::int/10000)::text
		END
	WHEN signaturnummer::int BETWEEN 2000 AND 2999 AND EXISTS (SELECT * FROM alkis_flaechen f WHERE po_polygons.signaturnummer=f.signaturnummer) THEN signaturnummer
	END,
	sn_randlinie=CASE
	WHEN signaturnummer::int BETWEEN 2000 AND 2999 THEN signaturnummer
	WHEN signaturnummer::int>10000 THEN
		CASE
		WHEN signaturnummer::int%10000 BETWEEN 2000 AND 2999 THEN (signaturnummer::int%10000)::text
		WHEN signaturnummer::int/10000 BETWEEN 2000 AND 2999 THEN (signaturnummer::int/10000)::text
		END
	END
WHERE signaturnummer ~ E'^[0-9]+$';

--
-- Randlinien als 'normale' Linien ergänzen
--

DELETE FROM alkis_linie WHERE signaturnummer LIKE 'rn%';
DELETE FROM alkis_linien WHERE signaturnummer LIKE 'rn%';

CREATE TEMPORARY SEQUENCE rnstrichart0_seq;
SELECT setval('rnstrichart0_seq',max(id)+1) FROM alkis_stricharten;
CREATE TEMPORARY SEQUENCE rnstrichart_seq;

CREATE TEMPORARY SEQUENCE rnstricharteni_seq;
SELECT setval('rnstricharteni_seq',max(id)+1) FROM alkis_stricharten_i;

CREATE TEMPORARY SEQUENCE rnlinie_seq;
SELECT setval('rnlinie_seq',max(id)+1) FROM alkis_linie;

SELECT setval('rnstrichart_seq',currval('rnstrichart0_seq'));
INSERT INTO alkis_stricharten(id)
	SELECT nextval('rnstrichart_seq')
		FROM alkis_flaechen f
		JOIN alkis_randlinie r ON f.randlinie=r.id
		ORDER BY f.katalog,f.signaturnummer,r.id;

SELECT setval('rnstrichart_seq',currval('rnstrichart0_seq'));
INSERT INTO alkis_stricharten_i(id,stricharten,i,strichart)
	SELECT nextval('rnstricharteni_seq'), nextval('rnstrichart_seq'),0,strichart
		FROM alkis_flaechen f
		JOIN alkis_randlinie r ON f.randlinie=r.id
		ORDER BY f.katalog,f.signaturnummer,r.id;

INSERT INTO alkis_linien(katalog,signaturnummer,darstellungsprioritaet,name,seite)
	SELECT katalog,'rn'||signaturnummer,darstellungsprioritaet,name,seite
		FROM alkis_flaechen f
		JOIN alkis_randlinie r ON f.randlinie=r.id
		ORDER BY f.katalog,f.signaturnummer,r.id;

SELECT setval('rnstrichart_seq',currval('rnstrichart0_seq'));
INSERT INTO alkis_linie(id,i,katalog,signaturnummer,strichart,abschluss,scheitel,strichstaerke,farbe)
	SELECT nextval('rnlinie_seq'),0,katalog,'rn'||signaturnummer,nextval('rnstrichart_seq'),abschluss,scheitel,strichstaerke,r.farbe
		FROM alkis_flaechen f
		JOIN alkis_randlinie r ON f.randlinie=r.id
		ORDER BY f.katalog,f.signaturnummer,r.id;

DROP SEQUENCE rnstrichart0_seq;
DROP SEQUENCE rnstrichart_seq;
DROP SEQUENCE rnstricharteni_seq;
DROP SEQUENCE rnlinie_seq;

-- Array -> Set
UPDATE po_points   SET modell=(SELECT array_agg(modell) FROM (SELECT DISTINCT unnest(modell) AS modell ORDER BY modell) AS foo WHERE modell IS NOT NULL),drehwinkel_grad=degrees(drehwinkel);
UPDATE po_lines    SET modell=(SELECT array_agg(modell) FROM (SELECT DISTINCT unnest(modell) AS modell ORDER BY modell) AS foo WHERE modell IS NOT NULL);
UPDATE po_polygons SET modell=(SELECT array_agg(modell) FROM (SELECT DISTINCT unnest(modell) AS modell ORDER BY modell) AS foo WHERE modell IS NOT NULL);
UPDATE po_labels   SET modell=(SELECT array_agg(modell) FROM (SELECT DISTINCT unnest(modell) AS modell ORDER BY modell) AS foo WHERE modell IS NOT NULL),drehwinkel_grad=degrees(drehwinkel);

SELECT
	modell AS "ALKIS-Modellart",
	count(*) AS "#Objekte"
FROM (
	SELECT unnest(modell) AS modell FROM po_points   UNION ALL
	SELECT unnest(modell) AS modell FROM po_lines    UNION ALL
	SELECT unnest(modell) AS modell FROM po_polygons UNION ALL
	SELECT unnest(modell) AS modell from po_lines    UNION ALL
	SELECT unnest(modell) AS modell from po_labels
) AS foo
GROUP BY modell
ORDER BY "#Objekte" DESC;

SELECT
	modell AS "ALKIS-Modellart",
	count(*) AS "#Objekte"
FROM (
	SELECT modell FROM po_points   UNION ALL
	SELECT modell FROM po_lines    UNION ALL
	SELECT modell FROM po_polygons UNION ALL
	SELECT modell from po_lines    UNION ALL
	SELECT modell from po_labels
) AS foo
GROUP BY modell
ORDER BY "#Objekte" DESC;

-- Unerwünschte Modelle löschen
-- DELETE FROM po_points   WHERE NOT :alkis_modelle::varchar[] && modell;
-- DELETE FROM po_lines    WHERE NOT :alkis_modelle::varchar[] && modell;
-- DELETE FROM po_polygons WHERE NOT :alkis_modelle::varchar[] && modell;
-- DELETE FROM po_labels   WHERE NOT :alkis_modelle::varchar[] && modell;

-- 'Randsignatur' für Flächen mit Umrandung eintragen
UPDATE po_polygons
	SET sn_randlinie='rn'||po_polygons.signaturnummer
	FROM alkis_flaechen
	WHERE alkis_flaechen.signaturnummer=po_polygons.signaturnummer AND NOT alkis_flaechen.randlinie IS NULL;

-- Skalierung setzen
UPDATE po_labels SET skalierung=1 WHERE skalierung IS NULL;

-- Zeilenumbrüche austauschen
UPDATE po_labels SET text=replace(text,E'\\n',E'\n') WHERE text LIKE E'%\\n%';

-- Pfeilspitzen
INSERT INTO po_lines(gml_id,thema,layer,line,signaturnummer,modell)
	SELECT
		gml_id,
		thema,
		layer,
		st_setsrid(
				st_multi(
					st_linemerge(
						st_collect(
							st_translate( st_rotate( st_makeline( st_point(0,0), st_point( h,l) ), -st_azimuth( p0, p1 ) ), st_x(p0), st_y(p0) ),
							st_translate( st_rotate( st_makeline( st_point(0,0), st_point(-h,l) ), -st_azimuth( p0, p1 ) ), st_x(p0), st_y(p0) )
							)
						)
					),
				srid
			  ),
		signaturnummer,
		modell
	FROM (
		SELECT
			l.gml_id,
			l.thema,
			l.layer /* || '_pfeil' */ AS layer,
			l.signaturnummer,
			st_srid(l.line) AS srid,
			st_pointn( st_geometryn( l.line, 1 ), 1 ) AS p0,
			st_pointn( st_geometryn( l.line, 1 ), 2 ) AS p1,
			s.pfeillaenge*0.01 AS l,
			s.pfeilhoehe*0.005 AS h,
			l.modell
		FROM po_lines l
		JOIN alkis_linie s ON s.abschluss='Pfeil' AND l.signaturnummer=s.signaturnummer
	) AS pfeile;

-- RP-Gruppensignaturen
UPDATE po_points
	SET
		point=st_collect(ARRAY[
			st_translate(st_geometryn(point,1), -10,  0 ),
			st_translate(st_geometryn(point,1),  -5,  5 ),
			st_translate(st_geometryn(point,1),  -5, -5 ),
			st_translate(st_geometryn(point,1),   0,  0 ),
			st_translate(st_geometryn(point,1),   5,  5 ),
			st_translate(st_geometryn(point,1),   5, -5 ),
			st_translate(st_geometryn(point,1),  10,  0 )
			]),
		signaturnummer=substring(signaturnummer,3)
	WHERE
		signaturnummer IN (
			'RP3413','RP3415','RP3421','RP3442','RP3444','RP3448','RP3474','RP3476','RP3478','RP3480','RP3481','RP3484','RP3490',
			-- TODO: Folgende mit Strichstärke 18
			'RP3440','RP3441','RP3446','RP3450','RP3452','RP3454','RP3456','RP3458','RP3460', 'RP3462','RP3470'
		);

-- RP-Flurstücksnummern mit ap_pto.art=NULL mit Bruchstrich 3m nach Norden schieben
UPDATE po_labels
	SET
		layer='ax_flurstueck_nummer_rpnoart',
		point=st_translate(point,0,3)
	FROM ap_pto t
	WHERE po_labels.gml_id LIKE 'DERP%'
		AND layer='ax_flurstueck_nummer'
		AND ARRAY[po_labels.gml_id] <@ t.dientzurdarstellungvon AND t.endet IS NULL AND t.art IS NULL;

UPDATE po_lines
	SET
		layer='ax_flurstueck_nummer_rpnoart',
		line=st_translate(line,0,3)
	FROM ap_pto t
	WHERE po_lines.gml_id LIKE 'DERP%'
	  AND layer='ax_flurstueck_nummer'
	  AND ARRAY[po_lines.gml_id] <@ t.dientzurdarstellungvon AND t.endet IS NULL AND t.art IS NULL;

SELECT 'Lösche nicht darzustellende Signaturen...';

DELETE FROM po_points WHERE signaturnummer IS NULL OR signaturnummer IN ('6000','RP6000');
DELETE FROM po_lines WHERE signaturnummer IS NULL OR signaturnummer IN ('6000','RP6000');
DELETE FROM po_polygons WHERE signaturnummer IS NULL OR signaturnummer IN ('6000','RP6000');
DELETE FROM po_labels WHERE signaturnummer IS NULL OR signaturnummer IN ('6000','RP6000') OR text IS NULL;

DELETE FROM alkis_linie WHERE signaturnummer IN ('6000','RP6000');
DELETE FROM alkis_linien WHERE signaturnummer IN ('6000','RP6000');
DELETE FROM alkis_flaechen WHERE signaturnummer IN ('6000','RP6000');
DELETE FROM alkis_schriften WHERE signaturnummer IN ('6000','RP6000');

SELECT 'Punkt' AS "Fehlende Signaturen",count(*) AS "Anzahl",array_agg(distinct signaturnummer) AS "Signaturen"
	FROM po_points o
	WHERE NOT EXISTS (SELECT * FROM alkis_punkte s WHERE o.signaturnummer=s.signaturnummer)
	HAVING count(*)>0
UNION SELECT 'Linien',count(*),array_agg(distinct signaturnummer)
	FROM po_lines o
	WHERE NOT EXISTS (SELECT * FROM alkis_linien s WHERE o.signaturnummer=s.signaturnummer)
	HAVING count(*)>0
UNION SELECT 'Flächen',count(*),array_agg(distinct sn_flaeche)
	FROM po_polygons o
	WHERE sn_flaeche IS NOT NULL AND NOT EXISTS (SELECT * FROM alkis_flaechen s WHERE o.sn_flaeche=s.signaturnummer)
	HAVING count(*)>0
UNION SELECT 'Randlinien',count(*),array_agg(distinct sn_randlinie)
	FROM po_polygons o
	WHERE sn_randlinie IS NOT NULL AND NOT EXISTS (SELECT * FROM alkis_linien s WHERE o.sn_randlinie=s.signaturnummer)
	HAVING count(*)>0
UNION SELECT 'Beschriftungen',count(*),array_agg(distinct signaturnummer)
	FROM po_labels o
	WHERE NOT EXISTS (SELECT * FROM alkis_schriften s WHERE o.signaturnummer=s.signaturnummer)
	HAVING count(*)>0;

SELECT alkis_dropobject('alkis_flaechenfuellung');
SELECT alkis_dropobject('alkis_pnr3002');

DELETE FROM po_modelle;
INSERT INTO po_modelle(modell,n)
	SELECT modell,count(*) AS n FROM (
		SELECT unnest(modell) AS modell FROM po_points	 UNION ALL
		SELECT unnest(modell) AS modell FROM po_lines	 UNION ALL
		SELECT unnest(modell) AS modell FROM po_polygons UNION ALL
		SELECT unnest(modell) AS modell FROM po_labels
	) AS foo
	GROUP BY modell;

-- vim: foldmethod=marker
