/*
	1XXX = Fläche
	2XXX = Linie
	3XXX = Symbol
	4XXX = Schrift

Linien-Signaturen mit Konturen:
	2504
		51004 ax_transportanlage
			Förderband, unterirsch (BWF 1102, OFL 1200/1700)

	2510
		51007 ax_historischesbauwerkoderhistorischeeinrichtung
			Historische Mauer (ATP 1500/1520)
			Stadtmauer (ATP 1510)

		51009 ax_sonstigesbauwerkodersonstigeeinrichtung
			Mauerkante, rechts (BWF 1710/1721)
			Mauerkante, links (BWF 1702/1722)
			Mauermitte (BWF 1703/1723)

		53009 ax_bauwerkimgewaesserbereich
			Ufermauer (BWF 2136)

	2521
		51004 ax_transportanlage
			Förderband (BWF 1102, OFL -/1400)

		51010 ax_einrichtunginoeffentlichenbereichen
			Tor (ART 1510)

	2526
		53009 ax_bauwerkimgewaesserbereich
			Sicherheitstor (BWF 2060)

Links/Rechts:
	51009 ax_sonstigesbauwerkodersonstigeeinrichtung	Mauerkante, -mitte
	54001 ax_vegetationsmerkmal				Heckenkante, -mitte
	55002 ax_untergeordnetesgewaesser			Grabenkante, -nmitte
	61003 ax_dammwalldeich					Wall-, Knick kante

Länder:
BW	Baden-Württemberg
NI	Niedersachsen
NW	Nordrhein-Westfalen
RP	Rheinland-Pfalz
TH	Thüringen
*/

SET client_encoding TO 'UTF8';

\unset ON_ERROR_STOP
SET application_name='ALKIS-Import - Ableitungsregeln';
\set ON_ERROR_STOP

\i alkis-wertearten.sql

SELECT 'Koordinatensystem: ' || :alkis_epsg;
-- SELECT 'Aktive Modelle: ' || array_to_string(:alkis_modelle,', ');

SELECT alkis_dropobject('alkis_positionierungsregeln');
CREATE TABLE alkis_positionierungsregeln(
	id INTEGER PRIMARY KEY,
	abstand DOUBLE PRECISION,
	zeilenabstand DOUBLE PRECISION,
	versatz DOUBLE PRECISION,
	dichte INTEGER);

INSERT INTO alkis_positionierungsregeln(id,abstand,zeilenabstand,versatz,dichte) VALUES (1100,7,3.5,3.5,100);
INSERT INTO alkis_positionierungsregeln(id,abstand,zeilenabstand,versatz,dichte) VALUES (1101,7,3.5,3.5,20);
INSERT INTO alkis_positionierungsregeln(id,abstand,zeilenabstand,versatz,dichte) VALUES (1102,18,10,9,100);
INSERT INTO alkis_positionierungsregeln(id,abstand,zeilenabstand,versatz,dichte) VALUES (1103,18,10,9,20);
INSERT INTO alkis_positionierungsregeln(id,abstand,zeilenabstand,versatz,dichte) VALUES (1104,24,22,12,100);
INSERT INTO alkis_positionierungsregeln(id,abstand,zeilenabstand,versatz,dichte) VALUES (1105,24,22,12,20);
INSERT INTO alkis_positionierungsregeln(id,abstand,zeilenabstand,versatz,dichte) VALUES (1106,10,3,5,100);
INSERT INTO alkis_positionierungsregeln(id,abstand,zeilenabstand,versatz,dichte) VALUES (1107,10,3,5,20);
INSERT INTO alkis_positionierungsregeln(id,abstand,zeilenabstand,versatz,dichte) VALUES (1108,8,7,4,100);
INSERT INTO alkis_positionierungsregeln(id,abstand,zeilenabstand,versatz,dichte) VALUES (1109,8,7,4,20);
INSERT INTO alkis_positionierungsregeln(id,abstand,zeilenabstand,versatz,dichte) VALUES (1110,7,6,3.5,100);
INSERT INTO alkis_positionierungsregeln(id,abstand,zeilenabstand,versatz,dichte) VALUES (1111,7,6,3.5,20);
INSERT INTO alkis_positionierungsregeln(id,abstand,zeilenabstand,versatz,dichte) VALUES (1112,3,1.5,1.5,100);

SELECT alkis_dropobject('alkis_flaechenfuellung');
CREATE OR REPLACE FUNCTION alkis_flaechenfuellung(g0 GEOMETRY, regelid INTEGER) RETURNS GEOMETRY AS $$
DECLARE
	xmin DOUBLE PRECISION;
	ymin DOUBLE PRECISION;
	xmax DOUBLE PRECISION;
	ymax DOUBLE PRECISION;
	x0 DOUBLE PRECISION;
	x DOUBLE PRECISION;
	y DOUBLE PRECISION;
	r GEOMETRY[];
	p GEOMETRY;
	srid INTEGER;
	g GEOMETRY;
	regel RECORD;
BEGIN
	IF regelid IS NULL OR geometrytype(g)<>'POLYGON' THEN
		RETURN NULL;
	END IF;

	SELECT * INTO regel FROM alkis_positionierungsregeln WHERE id=regelid;

	g := st_buffer(g0, -0.5);
	xmin := floor(st_xmin(g)/regel.abstand)*regel.abstand;
	ymin := floor(st_ymin(g)/regel.zeilenabstand)*regel.zeilenabstand;
	xmax := ceil(st_xmax(g)/regel.abstand)*regel.abstand;
	ymax := ceil(st_ymax(g)/regel.zeilenabstand)*regel.zeilenabstand;

	SELECT st_srid(g) INTO srid;

	x0 := xmin;
	y  := ymin;

--	RAISE NOTICE 'w:% h:% cols:% rows:% n:%',
--		xmax-xmin, ymax-ymin,
--		(xmax-xmin)/abstand,
--		(ymax-ymin)/zeilenabstand,
--		((xmax-xmin)/abstand) * ((ymax-ymin)/zeilenabstand);

	FOR i IN 0..1 LOOP
		WHILE y<ymax LOOP
			x := x0;
			WHILE x<xmax LOOP
				p := st_setsrid(st_point( x, y ), srid );
				IF st_intersects( g, p ) THEN
				  r := array_append( r, p );
				END IF;
				x := x + regel.abstand;
			END LOOP;
			y := y + 2*regel.zeilenabstand;
		END LOOP;

		y  := ymin + regel.zeilenabstand;
		x0 := x0 + regel.versatz;
	END LOOP;

	IF regel.dichte<100 THEN
		SELECT st_collect(geom) INTO g
		FROM (
			SELECT random() AS rand,geom
			FROM unnest(r) AS geom
			ORDER BY rand
		) AS a WHERE rand*100<=regel.dichte;
	ELSE
		g := st_collect(r);
	END IF;

	RETURN st_multi(g);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION alkis_besondereflurstuecksgrenze() RETURNS varchar AS $$
DECLARE
	r0 RECORD;
	r1 RECORD;
	r2 RECORD;
	r VARCHAR;
	adf INTEGER;
	sn VARCHAR;
	m VARCHAR[];
	p0 GEOMETRY;
	p1 GEOMETRY;
	l GEOMETRY;
	n INTEGER;
	np INTEGER;
	i INTEGER;
	j INTEGER;
	adfs INTEGER[];
	sns VARCHAR[];
	c refcursor;
BEGIN
	adfs := ARRAY[ 2500,   3000,   7003,   7101,   7102,   7103,   7104,   7106,   7107,   7108];
	sns  := ARRAY['2010', '2012', '2014', '2016', '2018', '2020', '2010', '2022', '2024', '2026'];
	DELETE FROM po_lines WHERE layer='ax_besondereflurstuecksgrenze' AND signaturnummer = ANY (sns);

	FOR i IN array_lower(adfs,1)..array_upper(adfs,1)
	LOOP
		adf := adfs[i];
		sn  := sns[i];

		INSERT INTO alkis_joinlines(ogc_fid,gml_id,line,visited,modell)
			SELECT ogc_fid,gml_id,wkb_geometry AS line,false AS visited,advstandardmodell||sonstigesmodell
			FROM ax_besondereflurstuecksgrenze
			WHERE ARRAY[adf] <@ artderflurstuecksgrenze AND endet IS NULL;

		GET DIAGNOSTICS n = ROW_COUNT;

		RAISE NOTICE 'adf:% sn:% n:%', adf, sn, n;

		WHILE n>0
		LOOP
			SELECT ogc_fid,gml_id,line,modell INTO r0 FROM alkis_joinlines WHERE NOT visited LIMIT 1;
--			RAISE NOTICE 'START %:		von:%	nach:%)',
--						r0.ogc_fid,
--						st_astext(st_startpoint(r0.line)),
--						st_astext(st_endpoint(r0.line));
			UPDATE alkis_joinlines SET visited=true WHERE alkis_joinlines.ogc_fid=r0.ogc_fid;
			n  := n - 1;

			l := r0.line;
			m := r0.modell;

			<<joinlines>> WHILE n>0
			LOOP
				np := st_numpoints(l);
				p0 := st_startpoint(l);
				p1 := st_endpoint(l);

				FOR i IN 0..3
				LOOP
					IF i=0 THEN
						OPEN c FOR SELECT ogc_fid,line,visited FROM alkis_joinlines WHERE p0 && line AND p0=st_endpoint(line) AND st_equals(p0,st_endpoint(line)) AND NOT p1=st_startpoint(line) ORDER BY visited LIMIT 2;
					ELSIF i=1 THEN
						OPEN c FOR SELECT ogc_fid,st_reverse(line) AS line,visited FROM alkis_joinlines WHERE p0 && line AND p0=st_startpoint(line) AND st_equals(p0,st_startpoint(line)) AND NOT p1=st_endpoint(line) ORDER BY visited LIMIT 2;
					ELSIF i=2 THEN
						OPEN c FOR SELECT ogc_fid,line AS line,visited FROM alkis_joinlines WHERE p1 && line AND p1=st_startpoint(line) AND st_equals(p1,st_startpoint(line)) AND NOT p0=st_endpoint(line) ORDER BY visited LIMIT 2;
					ELSIF i=3 THEN
						OPEN c FOR SELECT ogc_fid,st_reverse(line) AS line,visited FROM alkis_joinlines WHERE p1 && line AND p1=st_endpoint(line) AND st_equals(p1,st_endpoint(line)) AND NOT p0=st_startpoint(line) ORDER BY visited LIMIT 2;
					END IF;

					FETCH c INTO r1;
					IF FOUND AND NOT r1.visited THEN
						FETCH c INTO r2;
						IF NOT FOUND THEN
							-- unique hit found
							EXIT;
						END IF;
					END IF;

					CLOSE c;
					IF i=3 THEN
						EXIT joinlines;
					END IF;
				END LOOP;

				IF r1.visited THEN
					RAISE EXCEPTION '%: bereits besucht (von:% nach:%)
bei von:% bis:%',
						r1.ogc_fid,
						st_astext(st_startpoint(r1.line)),
						st_astext(st_endpoint(r1.line)),
						st_astext(p0),
						st_astext(p1);
--				ELSE
--					RAISE NOTICE 'WEITER %:		von:%	nach:%)',
--						r1.ogc_fid,
--						st_astext(st_startpoint(r1.line)),
--						st_astext(st_endpoint(r1.line));
				END IF;

				l := st_setsrid(st_linemerge(st_collect(l,r1.line)),st_srid(l));

				IF geometrytype(l)='MULTILINESTRING' THEN
					RAISE EXCEPTION 'MULTILINESTRING after merge: %', st_astext(l);
				ELSIF st_numpoints(l)=np THEN
					RAISE EXCEPTION 'merge failed: % with %',
						st_astext(l),
						st_astext(r1.line);
				END IF;

				UPDATE alkis_joinlines SET visited=true WHERE alkis_joinlines.ogc_fid=r1.ogc_fid;
				CLOSE c;
				n  := n - 1;
			END LOOP joinlines;

			-- RAISE NOTICE 'insert line (n:%)', n;

			INSERT
				INTO po_lines(gml_id,thema,layer,line,signaturnummer,modell)
				VALUES (r0.gml_id,'Politische Grenzen','ax_besondereflurstuecksgrenze',st_multi(l),sn,m);
		END LOOP;

		SELECT COUNT(*) INTO n FROM alkis_joinlines WHERE NOT visited;
		IF n>0 THEN
			RAISE NOTICE 'adf:% sn:%: % verbliebene Linien', adf, sn, n;
		END IF;
		DELETE FROM alkis_joinlines;
	END LOOP;

	SELECT alkis_dropobject('alkis_joinlines') INTO r;

	RETURN 'Politische Grenze verschmolzen';
END;
$$ LANGUAGE plpgsql;

-- Präsentationsobjekte?

SELECT 'Präsentationstabellen werden erzeugt.';

-- Punkte
SELECT alkis_dropobject('po_points');
CREATE TABLE po_points(
	ogc_fid serial PRIMARY KEY,
	gml_id varchar NOT NULL,
	thema varchar NOT NULL,
	layer varchar NOT NULL,
	signaturnummer varchar,
	drehwinkel double precision DEFAULT 0,
	modell varchar[] CHECK (array_length(modell,1)>0),
	drehwinkel_grad double precision
);

SELECT AddGeometryColumn('po_points','point', :alkis_epsg, 'MULTIPOINT', 2);

-- Linien
SELECT alkis_dropobject('po_lines');
CREATE TABLE po_lines(
	ogc_fid serial PRIMARY KEY,
	gml_id varchar NOT NULL,
	thema varchar NOT NULL,
	layer varchar NOT NULL,
	signaturnummer varchar REFERENCES alkis_linien(signaturnummer),
	modell varchar[] CHECK (array_length(modell,1)>0)
);

SELECT AddGeometryColumn('po_lines','line', :alkis_epsg, 'MULTILINESTRING', 2);

-- Polygone
SELECT alkis_dropobject('po_polygons');
CREATE TABLE po_polygons(
	ogc_fid serial PRIMARY KEY,
	gml_id varchar NOT NULL,
	thema varchar NOT NULL,
	layer varchar NOT NULL,
	signaturnummer varchar,
	sn_flaeche varchar REFERENCES alkis_flaechen(signaturnummer),
	sn_randlinie varchar REFERENCES alkis_linien(signaturnummer),
	modell varchar[] CHECK (array_length(modell,1)>0)
);

SELECT AddGeometryColumn('po_polygons','polygon', :alkis_epsg, 'MULTIPOLYGON', 2);

-- Beschriftungen
SELECT alkis_dropobject('po_labels');
CREATE TABLE po_labels(
	ogc_fid serial PRIMARY KEY,
	gml_id varchar NOT NULL,
	thema varchar NOT NULL,
	layer varchar NOT NULL,
	signaturnummer varchar REFERENCES alkis_schriften(signaturnummer),
	text varchar NOT NULL,
	drehwinkel double precision DEFAULT 0,
	drehwinkel_grad double precision,
	fontsperrung double precision,
	skalierung double precision,
	horizontaleausrichtung varchar,
	vertikaleausrichtung varchar,
	alignment_dxf integer,
	color_umn varchar,
	font_umn varchar,
	size_umn integer,
	darstellungsprioritaet integer,
	modell varchar[] CHECK (array_length(modell,1)>0)
);

SELECT AddGeometryColumn('po_labels','point', :alkis_epsg, 'POINT', 2);
SELECT AddGeometryColumn('po_labels','line', :alkis_epsg, 'LINESTRING', 2);


-- Nichtdarzustellende Signaturnummer ergänzen
-- (um sie am Ende inkl. der betreffenden Signaturen wieder zu entfernen)
DELETE FROM alkis_linien WHERE signaturnummer='6000';
DELETE FROM alkis_flaechen WHERE signaturnummer='6000';
DELETE FROM alkis_schriften WHERE signaturnummer='6000';
INSERT INTO alkis_linien(signaturnummer) VALUES ('6000');
INSERT INTO alkis_flaechen(signaturnummer) VALUES ('6000');
INSERT INTO alkis_schriften(signaturnummer) VALUES ('6000');

-- Leere Signaturnummern ersetzen
UPDATE ap_ppo SET signaturnummer=NULL WHERE signaturnummer='';
UPDATE ap_lpo SET signaturnummer=NULL WHERE signaturnummer='';
UPDATE ap_pto SET signaturnummer=NULL WHERE signaturnummer='';
UPDATE ap_lto SET signaturnummer=NULL WHERE signaturnummer='';


--
-- Flurstücke (11001)
--

SELECT 'Flurstücke werden verarbeitet.';

-- Flurstücke
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	'Flurstücke' AS thema,
	'ax_flurstueck' AS layer,
	st_multi(wkb_geometry) AS polygon,
	2028 AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ax_flurstueck
WHERE endet IS NULL;

SELECT alkis_dropobject('ax_flurstueck_arz');
UPDATE ax_flurstueck SET abweichenderrechtszustand='false' WHERE abweichenderrechtszustand IS NULL;
CREATE INDEX ax_flurstueck_arz ON ax_flurstueck(abweichenderrechtszustand);

SELECT count(*) || ' Flurstücke mit abweichendem Rechtszustand.' FROM ax_flurstueck WHERE abweichenderrechtszustand='true';

-- Flurstücksgrenzen mit abweichendem Rechtszustand
SELECT 'Bestimme Grenzen mit abweichendem Rechtszustand';
INSERT INTO po_lines(gml_id,thema,layer,line,signaturnummer,modell)
SELECT
	a.gml_id,
	'Flurstücke' AS thema,
	'ax_flurstueck' AS layer,
	st_multi( (SELECT st_collect(geom) FROM st_dump( st_intersection(a.wkb_geometry,b.wkb_geometry) ) WHERE geometrytype(geom)='LINESTRING') ) AS line,
	2029 AS signaturnummer,
	a.advstandardmodell||a.sonstigesmodell||b.advstandardmodell||b.sonstigesmodell AS modell
FROM ax_flurstueck a, ax_flurstueck b
WHERE a.ogc_fid<b.ogc_fid
  AND a.abweichenderrechtszustand='true' AND b.abweichenderrechtszustand='true'
  AND a.wkb_geometry && b.wkb_geometry AND st_intersects(a.wkb_geometry,b.wkb_geometry)
  AND a.endet IS NULL AND b.endet IS NULL;

SELECT 'Erzeuge Flurstücksnummern.';

-- Flurstücksnummern
-- Schrägstrichdarstellung, wo erzwungen
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	o.gml_id,
	'Flurstücke' AS thema,
	'ax_flurstueck_nummer' AS layer,
	coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
	coalesce(replace(t.schriftinhalt,'-','/'),o.zaehler||'/'||o.nenner,o.zaehler::text) AS text,
	t.signaturnummer AS signaturnummer,
	t.drehwinkel, t.horizontaleausrichtung, t.vertikaleausrichtung, t.skalierung, t.fontsperrung,
        coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM ax_flurstueck o
JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='ZAE_NEN' AND t.endet IS NULL AND t.signaturnummer IN ('4113','4122','6000')
WHERE o.endet IS NULL;

-- Zähler
-- Bruchdarstellung, wo nicht Schrägstrichdarstellung erzwungen
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	o.gml_id,
	'Flurstücke' AS thema,
	'ax_flurstueck_nummer' AS layer,
	st_translate(coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)), 0, 0.40) AS point,
	coalesce(split_part(replace(t.schriftinhalt,'-','/'),'/',1),o.zaehler::text) AS text,
	coalesce(t.signaturnummer,CASE WHEN o.abweichenderrechtszustand='true' THEN '4112' ELSE '4111' END) AS signaturnummer,
	t.drehwinkel, 'zentrisch'::text AS horizontaleausrichtung, 'Basis'::text AS vertikaleausrichtung, t.skalierung, t.fontsperrung,
	coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell)
FROM ax_flurstueck o
LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.endet IS NULL
WHERE o.endet IS NULL AND NOT coalesce(t.signaturnummer,'4111') IN ('4113','4122','6000');

-- Nenner
-- Bruchdarstellung, wo nicht Schrägstrichdarstellung erzwungen
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Flurstücke' AS thema,
	'ax_flurstueck_nummer' AS layer,
	point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		st_translate(coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)), 0, -0.40) AS point,
		coalesce(split_part(replace(t.schriftinhalt,'-','/'),'/',2)::text,o.nenner::text) AS text,
		coalesce(t.signaturnummer,CASE WHEN o.abweichenderrechtszustand='true' THEN '4112' ELSE '4111' END) AS signaturnummer,
		0 AS drehwinkel, 'zentrisch'::text AS horizontaleausrichtung, 'oben'::text AS vertikaleausrichtung, t.skalierung, t.fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_flurstueck o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.endet IS NULL
	WHERE o.endet IS NULL AND NOT coalesce(t.signaturnummer,'4111') IN ('4113','4122','6000')
) AS foo
WHERE NOT text IS NULL;

-- Bruchstrich
INSERT INTO po_lines(gml_id,thema,layer,line,signaturnummer,modell)
SELECT
	gml_id,
	'Flurstücke' AS thema,
	'ax_flurstueck_nummer' AS layer,
	st_multi(st_makeline(st_translate(point, -len, 0.0), st_translate(point, len, 0.0))) AS line,
	2001 AS signaturnummer,
	modell
FROM (
	SELECT
		gml_id,
		point,
		CASE WHEN lenn>lenz THEN lenn ELSE lenz END AS len,
		modell
	FROM (
		SELECT
			o.gml_id,
			coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
			length(coalesce(split_part(replace(t.schriftinhalt,'-','/'),'/',1),o.zaehler::text)) AS lenn,
			length(coalesce(split_part(replace(t.schriftinhalt,'-','/'),'/',2),o.nenner::text)) AS lenz,
			coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
		FROM ax_flurstueck o
		LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.endet IS NULL
		WHERE o.endet IS NULL AND NOT coalesce(t.signaturnummer,'4111') IN ('4113','4122','6000')
	) AS bruchstrich0 WHERE lenz>0 AND lenn>0
) AS bruchstrich1;

-- Zuordnungspfeile
INSERT INTO po_lines(gml_id,thema,layer,line,signaturnummer,modell)
SELECT
	o.gml_id,
	'Flurstücke' AS thema,
	'ax_flurstueck_zuordnung' AS layer,
	st_multi(l.wkb_geometry) AS line,
	CASE WHEN o.abweichenderrechtszustand='true' THEN 2005 ELSE 2004 END AS signaturnummer,
	coalesce(l.advstandardmodell||l.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM ax_flurstueck o
JOIN ap_lpo l ON ARRAY[o.gml_id] <@ l.dientzurdarstellungvon AND l.endet IS NULL -- AND l.art='Pfeil' -- art in RP nicht immer gesetzt
WHERE o.endet IS NULL;

-- Überhaken
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	o.gml_id,
	'Flurstücke' AS thema,
	'ax_flurstueck' AS layer,
	st_multi(p.wkb_geometry) AS point,
	coalesce(p.drehwinkel,0) AS drehwinkel,
	CASE WHEN o.abweichenderrechtszustand='true' THEN 3011 ELSE 3010 END AS signaturnummer,
	coalesce(p.advstandardmodell||p.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM ax_flurstueck o
JOIN ap_ppo p ON ARRAY[o.gml_id] <@ p.dientzurdarstellungvon AND p.art='Haken' AND p.endet IS NULL
WHERE o.endet IS NULL;

--
-- Besondere Flurstücksgrenzen (11002)
--

SELECT 'Besondere Flurstücksgrenzen werden verarbeitet.';

-- Strittige Grenze
INSERT INTO po_lines(gml_id,thema,layer,line,signaturnummer,modell)
SELECT
	o.gml_id AS gml_id,
	'Flurstücke' AS thema,
	'ax_besondereflurstuecksgrenze' AS layer,
	st_multi(o.wkb_geometry) AS line,
	CASE
	WHEN a.abweichenderrechtszustand='true' AND b.abweichenderrechtszustand='true' THEN 2007
	ELSE 2006 END AS signaturnummer,
	coalesce(
		o.advstandardmodell||o.sonstigesmodell,
		a.advstandardmodell||a.sonstigesmodell||b.advstandardmodell||b.sonstigesmodell
	) AS modell
FROM ax_besondereflurstuecksgrenze o
JOIN ax_flurstueck a ON o.wkb_geometry && a.wkb_geometry AND st_intersects(o.wkb_geometry,a.wkb_geometry) AND a.endet IS NULL
JOIN ax_flurstueck b ON o.wkb_geometry && b.wkb_geometry AND st_intersects(o.wkb_geometry,b.wkb_geometry) AND b.endet IS NULL
WHERE ARRAY[1000] <@ artderflurstuecksgrenze AND a.ogc_fid<b.ogc_fid AND o.endet IS NULL;

-- Nicht festgestellte Grenze
INSERT INTO po_lines(gml_id,thema,layer,line,signaturnummer,modell)
SELECT
	o.gml_id AS gml_id,
	'Flurstücke' AS thema,
	'ax_besondereflurstuecksgrenze' AS layer,
	st_multi(o.wkb_geometry) AS line,
	CASE
	WHEN a.abweichenderrechtszustand='true' AND b.abweichenderrechtszustand='true' THEN 2009
	ELSE 2008
	END AS signaturnummer,
	coalesce(
		o.advstandardmodell||o.sonstigesmodell,
		a.advstandardmodell||a.sonstigesmodell||b.advstandardmodell||b.sonstigesmodell
	) AS modell
FROM ax_besondereflurstuecksgrenze o
JOIN ax_flurstueck a ON o.wkb_geometry && a.wkb_geometry AND st_intersects(o.wkb_geometry,a.wkb_geometry) AND a.endet IS NULL
JOIN ax_flurstueck b ON o.wkb_geometry && b.wkb_geometry AND st_intersects(o.wkb_geometry,b.wkb_geometry) AND b.endet IS NULL
WHERE ARRAY[2001,2003,2004] && artderflurstuecksgrenze AND a.ogc_fid<b.ogc_fid AND o.endet IS NULL;

SELECT alkis_dropobject('alkis_joinlines');
CREATE TABLE alkis_joinlines(
	ogc_fid integer PRIMARY KEY,
	gml_id varchar,
	visited boolean,
	modell varchar[]
);
SELECT AddGeometryColumn('alkis_joinlines','line',(SELECT srid FROM geometry_columns WHERE f_table_name='po_lines' AND f_geometry_column='line'),'LINESTRING',2);
CREATE INDEX alkis_joinlines_line ON alkis_joinlines USING GIST (line);
CREATE INDEX alkis_joinlines_visited ON alkis_joinlines(visited);

SELECT 'Politische Grenze werden verschmolzen';
SELECT alkis_besondereflurstuecksgrenze();

SELECT alkis_dropobject('alkis_joinlines');

--
-- Grenzpunkte (11003)
--

SELECT 'Grenzpunkte werden verarbeitet.';

INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	p.gml_id,
	'Flurstücke' AS thema,
	'ax_grenzpunkt' AS layer,
	st_multi(o.wkb_geometry) AS point,
	0 AS drehwinkel,
	CASE abmarkung_marke
	WHEN 9600 THEN 3022
	WHEN 9998 THEN 3024
	ELSE 3020
	END AS signaturnummer,
	o.advstandardmodell||o.sonstigesmodell||p.advstandardmodell||p.sonstigesmodell AS modell
FROM ax_grenzpunkt p
JOIN ax_punktortta o ON p.gml_id=o.istteilvon AND o.endet IS NULL
WHERE abmarkung_marke<>9500 AND p.endet IS NULL;

/*
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	p.gml_id,
	'Flurstücke' AS thema,
	'ax_grenzpunkt' AS layer,
	st_multi(st_force_2d(o.wkb_geometry)) AS point,
	0 AS drehwinkel,
	CASE abmarkung_marke
	WHEN 9600 THEN 3022
	WHEN 9998 THEN 3024
	ELSE 3020
	END AS signaturnummer,
	o.advstandardmodell||o.sonstigesmodell||
	p.advstandardmodell||p.sonstigesmodell AS modell
FROM ax_grenzpunkt p
JOIN ax_punktortau o ON p.gml_id=o.istteilvon AND o.endet IS NULL
WHERE abmarkung_marke<>9500 AND p.endet IS NULL;
*/

CREATE INDEX po_points_temp0 ON po_points(layer,signaturnummer);
CREATE INDEX po_points_temp1 ON po_points USING gist (point);

UPDATE po_points
	SET signaturnummer=CASE signaturnummer
		WHEN '3022' THEN '3023'
		WHEN '3024' THEN '3025'
		ELSE '3021'
		END
	WHERE layer='ax_grenzpunkt'
	  AND EXISTS (
		SELECT *
		FROM ax_flurstueck f
		WHERE f.endet IS NULL
		  AND f.abweichenderrechtszustand='true'
		  AND po_points.point && f.wkb_geometry
		  AND st_intersects(po_points.point,f.wkb_geometry));

-- Grenzpunktnummern
-- TODO: 4071/2 PNR 3001
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	p.gml_id,
	'Flurstücke' AS thema,
	'ax_grenzpunkt' AS layer,
	coalesce(t.wkb_geometry,o.wkb_geometry) AS point,
	besonderePunktnummer AS text,
	coalesce(
		t.signaturnummer,
		CASE
		WHEN NOT EXISTS (SELECT * FROM po_points f WHERE f.point=o.wkb_geometry AND layer='ax_grenzpunkt' AND signaturnummer IN ('3021','3023','3025'))
		THEN '4071'
		ELSE '4072'
		END
	) AS signaturnummer,
	t.drehwinkel, t.horizontaleausrichtung, t.vertikaleausrichtung, t.skalierung, t.fontsperrung,
	coalesce(t.advstandardmodell||t.sonstigesmodell,p.advstandardmodell||p.sonstigesmodell||o.advstandardmodell||o.sonstigesmodell) AS modell
FROM ax_grenzpunkt p
JOIN ax_punktortta o ON p.gml_id=o.istteilvon AND o.endet IS NULL
LEFT OUTER JOIN ap_pto t ON ARRAY[p.gml_id] <@ t.dientzurdarstellungvon AND t.endet IS NULL
WHERE coalesce(besonderePunktnummer,'')<>'' AND p.endet IS NULL;

DROP INDEX po_points_temp0;
DROP INDEX po_points_temp1;

--
-- Lagebezeichnung ohne Hausnummer (12001)
--

SELECT 'Lagebezeichnungen werden verarbeitet.';

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

SELECT 'Lagebezeichnungen ohne Hausnummer werden verarbeitet.';

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
JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND art='Ort' AND t.endet IS NULL
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
		(SELECT bezeichnung FROM ax_lagebezeichnungkatalogeintrag WHERE schluesselgesamt=to_char(o.land,'fm00')||o.regierungsbezirk||to_char(o.kreis,'fm00')||to_char(o.gemeinde,'fm000')||o.lage ORDER BY beginnt DESC LIMIT 1),
		'(Lagebezeichnung zu '''||to_char(o.land,'fm00')||o.regierungsbezirk||to_char(o.kreis,'fm00')||to_char(o.gemeinde,'fm000')||o.lage||''' fehlt)'
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
		(SELECT bezeichnung FROM ax_lagebezeichnungkatalogeintrag WHERE schluesselgesamt=to_char(o.land,'fm00')||o.regierungsbezirk||to_char(o.kreis,'fm00')||to_char(o.gemeinde,'fm000')||o.lage ORDER BY beginnt DESC LIMIT 1),
		'(Lagebezeichnung zu '''||to_char(o.land,'fm00')||o.regierungsbezirk||to_char(o.kreis,'fm00')||to_char(o.gemeinde,'fm000')||o.lage||''' fehlt)'
	) AS text,
	coalesce(t.signaturnummer,'4107') AS signaturnummer,
	drehwinkel, horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung,
	coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM ax_lagebezeichnungohnehausnummer o
JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art IN ('Strasse','Weg','Straße') AND t.endet IS NULL  -- Straße wird in TH verwendet
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
		(SELECT bezeichnung FROM ax_lagebezeichnungkatalogeintrag WHERE schluesselgesamt=to_char(o.land,'fm00')||o.regierungsbezirk||to_char(o.kreis,'fm00')||to_char(o.gemeinde,'fm000')||o.lage ORDER BY beginnt DESC LIMIT 1),
		'(Lagebezeichnung zu '''||to_char(o.land,'fm00')||o.regierungsbezirk||to_char(o.kreis,'fm00')||to_char(o.gemeinde,'fm000')||o.lage||''' fehlt)'
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
		(SELECT bezeichnung FROM ax_lagebezeichnungkatalogeintrag WHERE schluesselgesamt=to_char(o.land,'fm00')||o.regierungsbezirk||to_char(o.kreis,'fm00')||to_char(o.gemeinde,'fm000')||o.lage ORDER BY beginnt DESC LIMIT 1),
		'(Lagebezeichnung zu '''||to_char(o.land,'fm00')||o.regierungsbezirk||to_char(o.kreis,'fm00')||to_char(o.gemeinde,'fm000')||o.lage||''' fehlt)'
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
		(SELECT bezeichnung FROM ax_lagebezeichnungkatalogeintrag WHERE schluesselgesamt=to_char(o.land,'fm00')||o.regierungsbezirk||to_char(o.kreis,'fm00')||to_char(o.gemeinde,'fm000')||o.lage ORDER BY beginnt DESC LIMIT 1),
		'(Lagebezeichnung zu '''||to_char(o.land,'fm00')||o.regierungsbezirk||to_char(o.kreis,'fm00')||to_char(o.gemeinde,'fm000')||o.lage||''' fehlt)'
	) AS text,
	4107 AS signaturnummer,
	horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung,
	coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM ax_lagebezeichnungohnehausnummer o
JOIN ap_lto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art IN ('Strasse','Weg','Straße') AND t.endet IS NULL AND coalesce(t.signaturnummer,'')<>'6000' -- Straße wird in TH verwendet
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
		(SELECT bezeichnung FROM ax_lagebezeichnungkatalogeintrag WHERE schluesselgesamt=to_char(o.land,'fm00')||o.regierungsbezirk||to_char(o.kreis,'fm00')||to_char(o.gemeinde,'fm000')||o.lage ORDER BY beginnt DESC LIMIT 1),
		'(Lagebezeichnung zu '''||to_char(o.land,'fm00')||o.regierungsbezirk||to_char(o.kreis,'fm00')||to_char(o.gemeinde,'fm000')||o.lage||''' fehlt)'
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
		(SELECT bezeichnung FROM ax_lagebezeichnungkatalogeintrag WHERE schluesselgesamt=to_char(o.land,'fm00')||o.regierungsbezirk||to_char(o.kreis,'fm00')||to_char(o.gemeinde,'fm000')||o.lage ORDER BY beginnt DESC LIMIT 1),
		'(Lagebezeichnung zu '''||to_char(o.land,'fm00')||o.regierungsbezirk||to_char(o.kreis,'fm00')||to_char(o.gemeinde,'fm000')||o.lage||''' fehlt)'
	) AS text,
	coalesce(t.signaturnummer,'4117') AS signaturnummer,
	horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung,
	coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM ax_lagebezeichnungohnehausnummer o
JOIN ap_lto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art IN ('Fliessgewaesser','StehendesGewaesser') AND t.endet IS NULL
WHERE o.endet IS NULL;


--
-- Lagebezeichnung mit Hausnummer (12002)
--

SELECT 'Lagebezeichnungen mit Hausnummer werden verarbeitet.';

-- mit Hausnummer, Ortsteil
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	o.gml_id,
	'Gebäude' AS thema,
	'ax_lagebezeichnungmithausnummer' AS layer,
	t.wkb_geometry AS point,
	schriftinhalt AS text,
	coalesce(t.signaturnummer,'4160') AS signaturnummer,
	drehwinkel, horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung,
	coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM ax_lagebezeichnungmithausnummer o
JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND art='Ort' AND t.endet IS NULL
WHERE coalesce(schriftinhalt,'')<>'' AND o.endet IS NULL;

-- mit Hausnummer (bezieht sich auf Gebäude, Turm oder Flurstück)
-- TODO: 4070 PNR 3002
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	o.gml_id,
	'Gebäude' AS thema,
	'ax_lagebezeichnungmithausnummer' AS layer,
	tx.wkb_geometry AS point,
	CASE
	WHEN f.ogc_fid IS NULL THEN coalesce(tx.schriftinhalt,o.hausnummer)
	ELSE coalesce(tx.schriftinhalt,'HsNr. '||hausnummer)
	END AS text,
	coalesce(tx.signaturnummer,'4070') AS signaturnummer,
	drehwinkel, horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung,
	coalesce(tx.advstandardmodell||tx.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM ax_lagebezeichnungmithausnummer o
JOIN ap_pto tx ON ARRAY[o.gml_id] <@ tx.dientzurdarstellungvon AND tx.art='HNR'
LEFT OUTER JOIN ax_turm     t   ON o.gml_id=t.zeigtauf AND NOT t.endet IS NULL
LEFT OUTER JOIN ax_gebaeude g   ON ARRAY[o.gml_id] <@ g.zeigtauf AND NOT g.endet IS NULL
LEFT OUTER JOIN ax_flurstueck f ON ARRAY[o.gml_id] <@ f.zeigtauf AND NOT f.endet IS NULL
WHERE o.endet IS NULL;


--
-- Lagebezeichnung mit Pseudonummer (12003)
--

SELECT 'Lagebezeichnungen mit Pseudonummer werden verarbeitet.';

-- TODO: 4070 PNR 3002
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	o.gml_id,
	'Straßen' AS thema,
	'ax_lagebezeichnungmitpseudonummer' AS layer,
	t.wkb_geometry AS point,
	coalesce('('||laufendenummer||')','P'||pseudonummer) AS text,
	coalesce(t.signaturnummer,'4070') AS signaturnummer,
	drehwinkel, horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung,
	coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM ax_lagebezeichnungmitpseudonummer o
JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='PNR' AND t.endet IS NULL
WHERE o.endet IS NULL;

-- Lagebezeichnung mit Pseudonummer, Ortsteil
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	o.gml_id,
	'Ortsteil' AS thema,
	'ax_lagebezeichnungmitpseudonummer' AS layer,
	t.wkb_geometry AS point,
	schriftinhalt AS text,
	coalesce(t.signaturnummer,'4160') AS signaturnummer,
	drehwinkel, horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung,
	coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM ax_lagebezeichnungmitpseudonummer o
JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='Ort' AND t.endet IS NULL AND schriftinhalt IS NOT NULL
WHERE o.endet IS NULL;


--
-- Gebäude (31001)
--

SELECT 'Gebäude werden verarbeitet.';

-- Gebäudeflächen (Signaturnummer = 2XXX oder 2XXX1XXX)
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	'Gebäude' AS thema,
	'ax_gebaeude' AS layer,
	polygon,
	signaturnummer,
	modell
FROM (
	SELECT
		gml_id,
		st_multi(wkb_geometry) AS polygon,
		CASE
		WHEN gfk='1XXX' THEN
			CASE
			WHEN NOT hoh AND NOT verfallen AND ofl=0           THEN 25051301
			WHEN     hoh AND NOT verfallen AND ofl=0           THEN 26231301
			WHEN     hoh AND     verfallen AND ofl IN (0,1400) THEN 2030
			WHEN     hoh AND NOT verfallen AND ofl=1400        THEN 20301301
			WHEN NOT hoh AND     verfallen AND ofl IN (0,1400) THEN 2031
			WHEN NOT hoh AND NOT verfallen AND ofl=1400        THEN 20311301
			WHEN NOT hoh                   AND ofl=1200        THEN 2032
			END
		WHEN gfk='2XXX' THEN
			CASE
			WHEN NOT hoh AND NOT verfallen AND ofl=0 THEN
				CASE
				WHEN baw=0     THEN 25051304
				WHEN baw<>4000 THEN 25051304
				WHEN baw=4000  THEN 20311304
				END
			WHEN     hoh AND NOT verfallen AND ofl=0           THEN 26231304
			WHEN     hoh AND     verfallen AND ofl IN (0,1400) THEN 2030
			WHEN     hoh AND NOT verfallen AND ofl=1400        THEN 20301304
			WHEN     hoh AND     verfallen AND ofl IN (0,1400) THEN 2031
			WHEN NOT hoh AND NOT verfallen AND ofl=1400        THEN 20311304
			WHEN NOT hoh                   AND ofl=1200        THEN 2032
			END
		WHEN gfk='3XXX' THEN
			CASE
			WHEN NOT hoh AND NOT verfallen AND ofl=0 THEN
				CASE
				WHEN baw=0     THEN 25051309
				WHEN baw<>4000 THEN 25051309
				WHEN baw=4000  THEN 20311309
				END
			WHEN     hoh AND NOT verfallen AND ofl=0           THEN 26231309
			WHEN     hoh AND     verfallen AND ofl IN (0,1400) THEN 2030
			WHEN     hoh AND NOT verfallen AND ofl=1400        THEN 20301309
			WHEN NOT hoh AND     verfallen AND ofl IN (0,1400) THEN 2031
			WHEN NOT hoh AND NOT verfallen AND ofl=1400        THEN 20311309
			WHEN NOT hoh                   AND ofl=1200        THEN 2032
			END
		WHEN gfk='9998' THEN
			CASE
			WHEN NOT hoh AND NOT verfallen AND ofl=0           THEN 25051304
			WHEN     hoh AND NOT verfallen AND ofl=0           THEN 26231304
			WHEN     hoh AND     verfallen AND ofl IN (0,1400) THEN 2030
			WHEN     hoh AND NOT verfallen AND ofl=1400        THEN 20301304
			WHEN NOT hoh AND     verfallen AND ofl IN (0,1400) THEN 2031
			WHEN NOT hoh AND NOT verfallen AND ofl=1400        THEN 20311304
			WHEN NOT hoh                   AND ofl=1200        THEN 2032
			END
		END AS signaturnummer,
		modell
	FROM (
		SELECT
			o.gml_id,
			CASE
			WHEN gebaeudefunktion BETWEEN 1000 AND 1999 THEN '1XXX'
			WHEN gebaeudefunktion BETWEEN 2000 AND 2999 THEN '2XXX'
			WHEN gebaeudefunktion BETWEEN 3000 AND 3999 THEN '3XXX'
			ELSE gebaeudefunktion::text
			END AS gfk,
			coalesce(hochhaus,'false')='true' AS hoh,
			coalesce(zustand,0) IN (2200,2300,3000,4000) AS verfallen,
			coalesce(lagezurerdoberflaeche,0) AS ofl,
			coalesce(bauweise,0) AS baw,
			wkb_geometry,
			o.advstandardmodell||o.sonstigesmodell AS modell
		FROM ax_gebaeude o
		WHERE o.endet IS NULL AND geometrytype(wkb_geometry) IN ('POLYGON','MULTIPOLYGON')
	) AS o
) AS o
WHERE NOT signaturnummer IS NULL;

-- Punktsymbole für Gebäude
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	o.gml_id,
	'Gebäude' AS thema,
	'ax_gebaeude' AS layer,
	st_multi(coalesce(p.wkb_geometry,st_centroid(o.wkb_geometry))) AS point,
	coalesce(p.drehwinkel,0) AS drehwinkel,
	coalesce(d.signaturnummer,p.signaturnummer,o.signaturnummer) AS signaturnummer,
	coalesce(p.advstandardmodell||p.sonstigesmodell||d.advstandardmodell||d.sonstigesmodell,o.modell) AS modell
FROM (
	SELECT
		gml_id,
		wkb_geometry,
		CASE gebaeudefunktion
		WHEN 2030 THEN '3300'
		WHEN 2056 THEN '3338'
		WHEN 2071 THEN '3302'
		WHEN 2072 THEN '3303'
		WHEN 2081 THEN '3305'
		WHEN 2092 THEN '3306'
		WHEN 2094 THEN '3308'
		WHEN 2461 THEN '3309' WHEN 2462 THEN '3309'
		WHEN 2465 THEN '3336'
		WHEN 2523 THEN CASE WHEN gml_id LIKE 'DERP%' THEN 'RP3521' ELSE '3521' END
		WHEN 2612 THEN '3311'
		WHEN 3013 THEN '3312'
		WHEN 3032 THEN '3314'
		WHEN 3037 THEN '3315'
		WHEN 3041 THEN '3316' -- TODO: PNR 1113?
		WHEN 3042 THEN '3317'
		WHEN 3043 THEN '3318' -- TODO: PNR 1113?
		WHEN 3046 THEN '3319'
		WHEN 3047 THEN '3320'
		WHEN 3051 THEN '3321' WHEN 3052 THEN '3321'
		WHEN 3065 THEN '3323'
		WHEN 3071 THEN '3324'
		WHEN 3072 THEN '3326'
		WHEN 3094 THEN '3328'
		WHEN 3095 THEN '3330'
		WHEN 3097 THEN '3332'
		WHEN 3221 THEN '3334'
		WHEN 3290 THEN '3340'
		END AS signaturnummer,
		advstandardmodell||sonstigesmodell AS modell
	FROM ax_gebaeude
	WHERE endet IS NULL
) AS o
LEFT OUTER JOIN ap_ppo p ON ARRAY[o.gml_id] <@ p.dientzurdarstellungvon AND p.art='GFK' AND p.endet IS NULL
LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='GFK' AND d.endet IS NULL
WHERE NOT o.signaturnummer IS NULL;

-- Gebäudebeschriftungen
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Gebäude' AS thema,
	'ax_gebaeude' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel, horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung, modell
FROM (
	SELECT
		o.gml_id,
		coalesce(n.wkb_geometry,t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(
			n.schriftinhalt,
			t.schriftinhalt,
			o.name,
			CASE
			WHEN gebaeudefunktion=3012                                              THEN 'Rathaus'  -- TODO: 31001 GFK [3012]?
			WHEN gebaeudefunktion=3014                                              THEN 'Zoll'
			WHEN gebaeudefunktion=3015 AND name IS NULL AND n.schriftinhalt IS NULL THEN 'Gericht'  -- TODO: 31001 GFK [3015]?
			WHEN gebaeudefunktion=3021 AND name IS NULL AND n.schriftinhalt IS NULL THEN 'Schule'
			WHEN gebaeudefunktion=3034 AND name IS NULL AND n.schriftinhalt IS NULL THEN 'Museum'   -- TODO: 31001 GFK [3034]?
			WHEN gebaeudefunktion=3091 AND name IS NULL AND n.schriftinhalt IS NULL THEN 'Bahnhof'
			WHEN gebaeudefunktion=9998                                              THEN 'oF'
			WHEN o.gml_id LIKE 'DERP%' THEN
				CASE
				WHEN gebaeudefunktion=2513 THEN 'Wbh'
				WHEN gebaeudefunktion IN (3011,3016,3017,3019,3024,3031,3033,3035,3036,3061,3062,3073,3074,3075,3080,3081,3092,3242) THEN
					(select v from alkis_wertearten where element='ax_gebaeude' AND bezeichnung='gebaeudefunktion' AND k=gebaeudefunktion::text)
				WHEN gebaeudefunktion=3022 THEN 'Schule'
				WHEN gebaeudefunktion=3023 THEN 'Hochschule'
				WHEN gebaeudefunktion=3038 THEN 'Burg'
				WHEN gebaeudefunktion=3211 THEN 'Sporthalle'
				END
			END
		) AS text,
		coalesce(CASE WHEN name IS NULL AND n.schriftinhalt IS NULL THEN t.signaturnummer ELSE n.signaturnummer END,'4070') AS signaturnummer,
		CASE WHEN name IS NULL AND n.schriftinhalt IS NULL THEN t.drehwinkel ELSE n.drehwinkel END AS drehwinkel,
		CASE WHEN name IS NULL AND n.schriftinhalt IS NULL THEN t.horizontaleausrichtung ELSE n.horizontaleausrichtung END AS horizontaleausrichtung,
		CASE WHEN name IS NULL AND n.schriftinhalt IS NULL THEN t.vertikaleausrichtung ELSE n.vertikaleausrichtung END AS vertikaleausrichtung,
		CASE WHEN name IS NULL AND n.schriftinhalt IS NULL THEN t.skalierung ELSE n.skalierung END AS skalierung,
		CASE WHEN name IS NULL AND n.schriftinhalt IS NULL THEN t.fontsperrung ELSE n.fontsperrung END AS fontsperrung,
		coalesce(
			t.advstandardmodell||t.sonstigesmodell||n.advstandardmodell||n.sonstigesmodell,
			o.modell
		) AS modell
	FROM (
		SELECT gml_id, wkb_geometry, gebaeudefunktion, unnest(coalesce(name,ARRAY[NULL])) AS name,advstandardmodell||sonstigesmodell AS modell
		FROM ax_gebaeude
		WHERE endet IS NULL
	) AS o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='GFK' AND t.endet IS NULL
	LEFT OUTER JOIN ap_pto n ON ARRAY[o.gml_id] <@ n.dientzurdarstellungvon AND n.art='NAM' AND n.endet IS NULL
) AS o WHERE NOT text IS NULL;

-- Weitere Gebäudefunktion
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	o.gml_id,
	'Gebäude' AS thema,
	'ax_gebaeude' AS layer,
	st_multi(coalesce(p.wkb_geometry,st_centroid(o.wkb_geometry))) AS point,
	p.drehwinkel,
	coalesce(p.signaturnummer,o.signaturnummer) AS signaturnummer,
	coalesce(p.advstandardmodell||p.sonstigesmodell,o.modell) AS modell
FROM (
	SELECT
		o.gml_id,
		wkb_geometry,
		CASE gebaeudefunktion
		WHEN 1000 THEN '3300'
		WHEN 1010 THEN '3302'
		WHEN 1020 THEN '3303'
		WHEN 1030 THEN '3305'
		WHEN 1040 THEN '3306'
		WHEN 1050 THEN '3308'
		WHEN 1060 THEN '3336'
		WHEN 1070 THEN '3309'
		WHEN 1080 THEN '3311'
		WHEN 1090 THEN '3112'
		WHEN 1110 THEN '3314'
		WHEN 1130 THEN '3315'
		WHEN 1140 THEN '3318'  -- TODO: Kapelle PNR 1113?
		WHEN 1150 THEN '3319'
		WHEN 1160 THEN '3320'
		WHEN 1170 THEN '3338'
		WHEN 1180 THEN '3324'
		WHEN 1190 THEN '3321'
		WHEN 1200 THEN '3340'
		WHEN 1210 THEN '3323'
		WHEN 1220 THEN '3324'
		END AS signaturnummer,
		modell
	FROM (
		SELECT
			gml_id,
			wkb_geometry,
			unnest(weiteregebaeudefunktion) AS gebaeudefunktion,
			advstandardmodell||sonstigesmodell AS modell
		FROM ax_gebaeude
		WHERE NOT weiteregebaeudefunktion IS NULL AND endet IS NULL
	) AS o
) AS o
LEFT OUTER JOIN ap_ppo p ON ARRAY[o.gml_id] <@ p.dientzurdarstellungvon AND p.art='GFK' AND p.endet IS NULL
WHERE NOT o.signaturnummer IS NULL;

-- Weitere Gebäudefunktionsbeschriftungen
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	o.gml_id,
	'Gebäude' AS thema,
	'ax_gebaeude' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel, horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung, modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		CASE
		WHEN gebaeudefunktion=1100 AND coalesce(name,n.schriftinhalt) IS NULL THEN 'Zoll'
		WHEN gebaeudefunktion=1129 AND coalesce(name,n.schriftinhalt) IS NULL THEN 'Museum'   -- TODO: 31001 GFK [3034]?
		END AS text,
		CASE WHEN name IS NULL AND n.schriftinhalt IS NULL THEN t.drehwinkel ELSE n.drehwinkel END AS drehwinkel,
		coalesce(CASE WHEN name IS NULL AND n.schriftinhalt IS NULL THEN t.signaturnummer ELSE n.signaturnummer END,'4070') AS signaturnummer,
		CASE WHEN name IS NULL AND n.schriftinhalt IS NULL THEN t.horizontaleausrichtung ELSE n.horizontaleausrichtung END AS horizontaleausrichtung,
		CASE WHEN name IS NULL AND n.schriftinhalt IS NULL THEN t.vertikaleausrichtung ELSE n.vertikaleausrichtung END AS vertikaleausrichtung,
		CASE WHEN name IS NULL AND n.schriftinhalt IS NULL THEN t.skalierung ELSE n.skalierung END AS skalierung,
		CASE WHEN name IS NULL AND n.schriftinhalt IS NULL THEN t.fontsperrung ELSE n.fontsperrung END AS fontsperrung,
		coalesce(
			t.advstandardmodell||t.sonstigesmodell||n.advstandardmodell||n.sonstigesmodell,
			o.modell
		) AS modell
	FROM  (
		SELECT
			gml_id,
			wkb_geometry,
			unnest(coalesce(name,ARRAY[NULL])) AS name,
			unnest(weiteregebaeudefunktion) AS gebaeudefunktion,
			advstandardmodell||sonstigesmodell AS modell
		FROM ax_gebaeude o
		WHERE endet IS NULL
	) AS o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='GFK' AND t.endet IS NULL
	LEFT OUTER JOIN ap_pto n ON ARRAY[o.gml_id] <@ n.dientzurdarstellungvon AND n.art='NAM' AND n.endet IS NULL
	WHERE NOT gebaeudefunktion IS NULL
) AS o
WHERE NOT text IS NULL;

/*
-- TODO: Gebäudenamen für weitere Funktionen  (Mehrere Namen? Und Funktionen? Gleich viele oder wie ist das zu kombinieren?)
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	o.gml_id,
	'Gebäude' AS thema,
	'ax_gebaeude' AS layer,
	unnest(coalesce(name,ARRAY[NULL])),
	coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry))  AS point,
	coalesce(t.schriftinhalt,o.zaehler||'/'||o.nenner,o.zaehler::text) AS text,
	coalesce(t.signaturnummer,CASE WHEN o.abweichenderrechtszustand='true' THEN 4112 ELSE 4111 END) AS signaturnummer,
	drehwinkel, horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung,
	coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM ax_gebaeude o
LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='ZAE_NEN' AND (t.signaturnummer IS NULL OR t.signaturnummer IN ('4122','4123')) AND t.endet IS NULL
WHERE NOT name IS NULL AND o.endet IS NULL;
*/

-- Geschosszahl
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	o.gml_id,
	'Gebäude' AS thema,
	'ax_gebaeude' AS layer,
	coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
	coalesce(o.anzahlderoberirdischengeschosse::text||' / -'||o.anzahlderunterirdischengeschosse::text,o.anzahlderoberirdischengeschosse::text,'-'||o.anzahlderunterirdischengeschosse::text) AS text,
	coalesce(t.signaturnummer,'4070') AS signaturnummer,
	drehwinkel, horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung,
	coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM ax_gebaeude o
LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='AOG_AUG' AND t.endet IS NULL
WHERE (NOT anzahlderoberirdischengeschosse IS NULL OR NOT anzahlderunterirdischengeschosse IS NULL) AND o.endet IS NULL;

-- Dachform
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	o.gml_id,
	'Gebäude' AS thema,
	'ax_gebaeude' AS layer,
	coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
	CASE dachform
	WHEN 1000 THEN 'F'
	WHEN 2100 THEN 'P'
	WHEN 2200 THEN 'VP'
	WHEN 3100 THEN 'S'
	WHEN 3200 THEN 'W'
	WHEN 3300 THEN 'KW'
	WHEN 3400 THEN 'M'
	WHEN 3500 THEN 'Z'
	WHEN 3600 THEN 'KE'
	WHEN 3700 THEN 'KU'
	WHEN 3800 THEN 'SH'
	WHEN 3900 THEN 'B'
	WHEN 4000 THEN 'T'
	WHEN 5000 THEN 'MD'
	WHEN 9999 THEN 'SD'
	END AS text,
	coalesce(t.signaturnummer,'4070') AS signaturnummer,
	drehwinkel, horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung,
	coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM ax_gebaeude o
LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='DAF' AND t.endet IS NULL
WHERE NOT dachform IS NULL AND o.endet IS NULL;

-- Gebäudezustände
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	o.gml_id,
	'Gebäude' AS thema,
	'ax_gebaeude' AS layer,
	coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
	coalesce(
		t.schriftinhalt,
		CASE zustand
		WHEN 2200 THEN '(zerstört)'
		WHEN 2300 THEN '(teilweise zerstört)'
		WHEN 3000 THEN '(geplant)'
		WHEN 4000 THEN '(im Bau)'
		END) AS text,
	coalesce(t.signaturnummer,'4070') AS signaturnummer,
	drehwinkel, horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung,
	coalesce(o.advstandardmodell||o.sonstigesmodell,t.advstandardmodell||t.sonstigesmodell) AS modell
FROM ax_gebaeude o
LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='ZUS' AND t.endet IS NULL
WHERE zustand IN (2200,2300,3000,4000) AND o.endet IS NULL;


--
-- Gebäudeteil (31002)
--

SELECT 'Gebäudeteile werden verarbeitet.';

-- Gebäudeteile (Bauteil)
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	'Gebäude' AS thema,
	'ax_bauteil' AS layer,
	polygon,
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		st_multi(wkb_geometry) AS polygon,
		CASE
		WHEN bat=1100 AND ofl=0      THEN 2507
		WHEN bat=1100 AND ofl=1400   THEN 2508
		WHEN bat=1200 AND ofl=0      THEN 2507
		WHEN bat=1200 AND ofl=1400   THEN 2508
		WHEN bat=1300 AND ofl=0      THEN 2509
		WHEN bat=1300 AND ofl=1400   THEN 2511
		WHEN bat=1400 AND ofl=0      THEN 2507
		WHEN bat=1400 AND ofl=1400   THEN 2508
		WHEN bat=2000 AND ofl=0      THEN 2507
		WHEN bat=2000 AND ofl=1200   THEN 2512
		WHEN bat=2100 AND ofl=0      THEN 2507
		WHEN bat=2100 AND ofl=1200   THEN 2512
		WHEN bat IN (2300,2350,2400,2500,2510,2520,2610,2620) THEN 2507
		WHEN bat=2710                THEN 2513
		WHEN bat=2720                THEN 2514
		WHEN bat=9999 AND ofl=0      THEN 2507
		WHEN bat=9999 AND ofl=1400   THEN 2508
		END AS signaturnummer,
		modell
	FROM (
		SELECT
			gml_id,
			bauart AS bat,
			coalesce(lagezurerdoberflaeche,0) AS ofl,
			wkb_geometry,
			advstandardmodell||sonstigesmodell AS modell
		FROM ax_bauteil
		WHERE endet IS NULL
	) AS o
) AS o WHERE NOT signaturnummer IS NULL;

-- Gebäudeteilsymbole
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	o.gml_id,
	'Gebäude' AS thema,
	'ax_bauteil' AS layer,
	st_multi(coalesce(p.wkb_geometry,st_centroid(o.wkb_geometry))) AS point,
	coalesce(p.drehwinkel,0) AS drehwinkel,
	coalesce(p.signaturnummer,'3336') AS signaturnummer,
	coalesce(p.advstandardmodell||p.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM ax_bauteil o
LEFT OUTER JOIN ap_ppo p ON ARRAY[o.gml_id] <@ p.dientzurdarstellungvon AND p.art='BAT' AND p.endet IS NULL
WHERE bauart=2100 AND o.endet IS NULL;

-- Gebäudeteildachform
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	o.gml_id,
	'Gebäude' AS thema,
	'ax_bauteil' AS layer,
	coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
	CASE dachform
	WHEN 1000 THEN 'F'
	WHEN 2100 THEN 'P'
	WHEN 2200 THEN 'VP'
	WHEN 3100 THEN 'S'
	WHEN 3200 THEN 'W'
	WHEN 3300 THEN 'KW'
	WHEN 3400 THEN 'M'
	WHEN 3500 THEN 'Z'
	WHEN 3600 THEN 'KE'
	WHEN 3700 THEN 'KU'
	WHEN 3800 THEN 'SH'
	WHEN 3900 THEN 'B'
	WHEN 4000 THEN 'T'
	WHEN 5000 THEN 'MD'
	WHEN 9999 THEN 'SD'
	END AS text,
	coalesce(t.signaturnummer,'4070') AS signaturnummer,
	drehwinkel, horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung,
	coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM ax_bauteil o
LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='DAF' AND t.endet IS NULL
WHERE NOT dachform IS NULL AND o.endet IS NULL;

-- Gebäudeteil, oberirdische Geschosse
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	o.gml_id,
	'Gebäude' AS thema,
	'ax_bauteil' AS layer,
	coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
	o.anzahlderoberirdischengeschosse::text AS text,
	coalesce(t.signaturnummer,'4070') AS signaturnummer,
	drehwinkel, horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung,
	coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM ax_bauteil o
LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='AOG' AND t.endet IS NULL
WHERE NOT anzahlderoberirdischengeschosse IS NULL AND o.endet IS NULL;

-- Besondere Gebäudelinien
INSERT INTO po_lines(gml_id,thema,layer,line,signaturnummer,modell)
SELECT
	gml_id,
	'Gebäude' AS thema,
	'ax_besonderegebaeudelinie' AS layer,
	st_multi(wkb_geometry) AS line,
	2305 AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ax_besonderegebaeudelinie
WHERE ARRAY[1000] <@ beschaffenheit AND endet IS NULL;

INSERT INTO po_lines(gml_id,thema,layer,line,signaturnummer,modell)
SELECT
	gml_id,
	'Gebäude' AS thema,
	'ax_besonderegebaeudelinie' AS layer,
	st_multi(wkb_geometry) AS line,
	2302 AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ax_besonderegebaeudelinie
WHERE ARRAY[4000] <@ beschaffenheit AND endet IS NULL;

INSERT INTO po_lines(gml_id,thema,layer,line,signaturnummer,modell)
SELECT
	gml_id,
	'Gebäude' AS thema,
	'ax_firstlinie' AS layer,
	st_multi(wkb_geometry) AS line,
	2303 AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ax_firstlinie
WHERE endet IS NULL;


--
-- Tatsächliche Nutzung (41008)
--

SELECT 'Tatsächliche Nutzungen werden verarbeitet.';

--
-- Wohnbauflächen
--

-- Wohnbauflächen, Flächen
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	'Wohnbauflächen' AS thema,
	'ax_wohnbauflaeche' AS layer,
	st_multi(wkb_geometry) AS polygon,
	25151401 AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ax_wohnbauflaeche
WHERE endet IS NULL;

INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Wohnbauflächen' AS thema,
	'ax_wohnbauflaeche' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel, horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung, modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(t.schriftinhalt,o.name) AS text,
		coalesce(t.signaturnummer,'4141') AS signaturnummer,
		drehwinkel, horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_wohnbauflaeche o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='NAM' AND t.endet IS NULL
	WHERE o.endet IS NULL
) AS n WHERE NOT text IS NULL;


--
-- Industrie- und Gewerbefläche (41002)
--

-- Industrie- und Gewerbefläche, Flächen
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	'Industrie und Gewerbe' AS thema,
	'ax_industrieundgewerbeflaeche' AS layer,
	st_multi(wkb_geometry) AS polygon,
	25151403 AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ax_industrieundgewerbeflaeche
WHERE endet IS NULL;

-- Industrie- und Gewerbefläche, Namen
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Industrie und Gewerbe' AS thema,
	'ax_industrieundgewerbeflaeche' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel, horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung, modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(t.schriftinhalt,o.name) AS text,
		coalesce(t.signaturnummer,'4141') AS signaturnummer,
		drehwinkel, horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_industrieundgewerbeflaeche o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='NAM' AND t.endet IS NULL
	WHERE o.endet IS NULL
) AS i WHERE NOT text IS NULL;

-- Industrie- und Gewerbefläche, Funktionen
-- TODO: Förderanlage/Kraftwerk/Bergbaubetrieb 4140 (PNR 3003)
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Industrie und Gewerbe' AS thema,
	'ax_industrieundgewerbeflaeche' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel, horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung, modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		CASE
		WHEN funktion=1740 THEN
			CASE
			WHEN coalesce(lagergut,0) IN (0,9999) THEN
				coalesce(
					schriftinhalt,
					(select v from alkis_wertearten where element='ax_industrieundgewerbeflaeche' AND bezeichnung='funktion' AND k=funktion::text)
				)
			ELSE
				coalesce(
					schriftinhalt,
					(select v from alkis_wertearten where element='ax_industrieundgewerbeflaeche' AND bezeichnung='funktion' AND k=funktion::text)
					|| E'\n('
					||(select v from alkis_wertearten where element='ax_industrieundgewerbeflaeche' AND bezeichnung='lagergut' AND k=lagergut::text)
					||')',
					(select v from alkis_wertearten where element='ax_industrieundgewerbeflaeche' AND bezeichnung='funktion' AND k=funktion::text)
				)
			END
		WHEN o.gml_id LIKE 'DERP%' AND funktion=2502 THEN 'Versorgungsanlage'
		WHEN o.gml_id LIKE 'DERP%' AND funktion=2602 THEN 'Entsorgungsanlage'
		WHEN o.gml_id LIKE 'DERP%' AND funktion=2623 THEN 'Schlamm'
		WHEN funktion IN (2520,2522, 2550,2552, 2560,2562, 2580.2582, 2610,2612, 2620,2622, 2630, 2640 ) THEN
			coalesce(
				schriftinhalt,
				(select v from alkis_wertearten where element='ax_industrieundgewerbeflaeche' AND bezeichnung='funktion' AND k=funktion::text)
			)
		WHEN funktion IN (2530,2532) THEN
			coalesce(
				schriftinhalt,
				'(' || (select v from alkis_wertearten where element='ax_industrieundgewerbeflaeche' AND bezeichnung='primaerenergie' AND k=primaerenergie::text) || ')'
			)
		WHEN funktion IN (2570,2572) THEN
			CASE
			WHEN primaerenergie IS NULL THEN
				coalesce(
					schriftinhalt,
					(select v from alkis_wertearten where element='ax_industrieundgewerbeflaeche' AND bezeichnung='funktion' AND k=funktion::text)
				)
			ELSE
				coalesce(
					schriftinhalt,
					(select v from alkis_wertearten where element='ax_industrieundgewerbeflaeche' AND bezeichnung='funktion' AND k=funktion::text)
					|| E'\n('
					|| (select v from alkis_wertearten where element='ax_industrieundgewerbeflaeche' AND bezeichnung='primaerenergie' AND k=primaerenergie::text)
					|| ')',
					(select v from alkis_wertearten where element='ax_industrieundgewerbeflaeche' AND bezeichnung='funktion' AND k=funktion::text)
				)
			END
		END AS text,
		coalesce(t.signaturnummer,'4140') AS signaturnummer,
		drehwinkel, horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_industrieundgewerbeflaeche o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='FKT' AND t.endet IS NULL
	WHERE o.endet IS NULL
) AS i WHERE NOT text IS NULL;

-- Industrie- und Gewerbefläche, Funktionssymbole
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	gml_id,
	'Industrie und Gewerbe' AS thema,
	'ax_industrieundgewerbeflaeche' AS layer,
	st_multi(point),
	drehwinkel,
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		coalesce(p.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(p.drehwinkel,0) AS drehwinkel,
		coalesce(
			p.signaturnummer,
			CASE
			WHEN funktion=1730           THEN '3401'
			WHEN funktion=2510           THEN '3402'
			WHEN funktion IN (2530,2432) THEN '3403'
			WHEN funktion=2540           THEN '3404'
			END
		) AS signaturnummer,
		coalesce(
			p.advstandardmodell||p.sonstigesmodell||d.advstandardmodell||d.sonstigesmodell,
			o.advstandardmodell||o.sonstigesmodell
		) AS modell
	FROM ax_industrieundgewerbeflaeche o
	LEFT OUTER JOIN ap_ppo p ON ARRAY[o.gml_id] <@ p.dientzurdarstellungvon AND p.art='FKT' AND p.endet IS NULL
	LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='FKT' AND d.endet IS NULL
	WHERE o.endet IS NULL
) AS o
WHERE NOT signaturnummer IS NULL;

--
-- Halde (41003)
--

-- Halde, Flächen
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	'Industrie und Gewerbe' AS thema,
	'ax_halde' AS layer,
	st_multi(wkb_geometry) AS polygon,
	25151403 AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ax_halde
WHERE endet IS NULL;

-- Halde, Texte
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Industrie und Gewerbe' AS thema,
	'ax_halde' AS layer,
	point,
	text,
	4140 AS signaturnummer,
	drehwinkel, horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung,
	modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(
			schriftinhalt,
			E'Halde\n(' || (select v from alkis_wertearten where element='ax_halde' AND bezeichnung='lagergut' AND k=lagergut::text) ||')',
			'Halde'
		) AS text,
		drehwinkel, horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_halde o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='Halde_LGT' AND t.endet IS NULL
	WHERE o.endet IS NULL
) AS o
WHERE NOT text IS NULL;

-- Halde, Namen
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Industrie und Gewerbe' AS thema,
	'ax_halde' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel, horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung, modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(t.schriftinhalt,o.name) AS text,
		coalesce(t.signaturnummer,'4141') AS signaturnummer,
		drehwinkel, horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_halde o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='NAM' AND t.endet IS NULL
	WHERE o.endet IS NULL
) AS o WHERE NOT text IS NULL;

--
-- Bergbaubetrieb (41004)
--

-- Bergbaubetrieb, Flächen
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	'Industrie und Gewerbe' AS thema,
	'ax_bergbaubetrieb' AS layer,
	st_multi(wkb_geometry) AS polygon,
	25151403 AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ax_bergbaubetrieb
WHERE endet IS NULL;

-- Bergbaubetrieb, Zustandssymbole
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	gml_id,
	'Industrie und Gewerbe' AS thema,
	'ax_bergbaubetrieb' AS layer,
	st_multi(point),
	drehwinkel,
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		coalesce(p.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(p.drehwinkel,0) AS drehwinkel,
		coalesce(p.signaturnummer,CASE WHEN zustand=2100 THEN '3406' ELSE '3505' END) AS signaturnummer,
		coalesce(p.advstandardmodell||p.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_bergbaubetrieb o
	LEFT OUTER JOIN ap_ppo p ON ARRAY[o.gml_id] <@ p.dientzurdarstellungvon AND p.art='ZUS' AND p.endet IS NULL
	WHERE o.endet IS NULL
) AS b;

-- Bergbaubetrieb, Anschrieb Abbaugut
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Industrie und Gewerbe' AS thema,
	'ax_bergbaubetrieb' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel, horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung,
	modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(
			schriftinhalt,
			E'(' || (select v from alkis_wertearten where element='ax_bergbaubetrieb' AND bezeichnung='abbaugut' AND k=abbaugut::text) ||')'
		) AS text,
		coalesce(t.signaturnummer,'4141') AS signaturnummer,
		drehwinkel, horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_bergbaubetrieb o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='AGT' AND t.endet IS NULL
	WHERE NOT abbaugut IS NULL AND o.endet IS NULL
) AS b
WHERE NOT text IS NULL;

-- Bergbaubetrieb, Namen
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Industrie und Gewerbe' AS thema,
	'ax_bergbaubetrieb' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel, horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung, modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(t.schriftinhalt,o.name) AS text,
		coalesce(t.signaturnummer,'4141') AS signaturnummer,
		drehwinkel, horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_bergbaubetrieb o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='NAM' AND t.endet IS NULL
	WHERE o.endet IS NULL
) AS h WHERE NOT text IS NULL;


--
-- Tagebau (41005)
--

-- Tagebau, Flächen
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	'Industrie und Gewerbe' AS thema,
	'ax_tagebaugrubesteinbruch' AS layer,
	st_multi(wkb_geometry) AS polygon,
	CASE WHEN abbaugut=4010 THEN 25151404 ELSE 25151403 END AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ax_tagebaugrubesteinbruch
WHERE endet IS NULL;


-- Tagebau, Anschrieb Abbaugut
-- TODO: 4140 (PNR 3003)
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Industrie und Gewerbe' AS thema,
	'ax_tagebaugrubesteinbruch' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel, horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung, modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(
		schriftinhalt,
		E'(' || (select v from alkis_wertearten where element='ax_tagebaugrubesteinbruch' AND bezeichnung='abbaugut' AND k=abbaugut::text) ||')',
		CASE WHEN abbaugut=4100 THEN '(Torfstich)' ELSE NULL END
		) AS text,
		coalesce(t.signaturnummer,'4141') AS signaturnummer,
		drehwinkel, horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_tagebaugrubesteinbruch o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='AGT' AND t.endet IS NULL
	WHERE NOT abbaugut IS NULL AND o.endet IS NULL
) AS b
WHERE NOT text IS NULL;

-- Tagebau, Symbol
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	o.gml_id,
	'Industrie und Gewerbe' AS thema,
	'ax_tagebaugrubesteinbruch' AS layer,
	st_multi(coalesce(p.wkb_geometry,st_centroid(o.wkb_geometry))) AS point,
	coalesce(p.drehwinkel,0) AS drehwinkel,
	coalesce(p.signaturnummer,'3407') AS signaturnummer,
	coalesce(p.advstandardmodell||p.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM ax_tagebaugrubesteinbruch o
LEFT OUTER JOIN ap_ppo p ON ARRAY[o.gml_id] <@ p.dientzurdarstellungvon AND p.art='FKT' AND p.endet IS NULL
WHERE o.endet IS NULL;

-- Tagebau, Namen
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Industrie und Gewerbe' AS thema,
	'ax_tagebaugrubesteinbruch' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel, horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung,
	modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(t.schriftinhalt,o.name) AS text,
		coalesce(t.signaturnummer,'4141') AS signaturnummer,
		drehwinkel, horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_tagebaugrubesteinbruch o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='NAM' AND t.endet IS NULL
	WHERE o.endet IS NULL
) AS o WHERE NOT text IS NULL;


--
-- Fläche gemischter Nutzung (41006)
--

-- Fläche gemischter Nutzung
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	'Industrie und Gewerbe' AS thema,
	'ax_flaechegemischternutzung' AS layer,
	st_multi(wkb_geometry) AS polygon,
	25151401 AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ax_flaechegemischternutzung;

-- Name, Fläche gemischter Nutzung
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Industrie und Gewerbe' AS thema,
	'ax_flaechegemischternutzung' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel, horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung,
	modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(t.schriftinhalt,o.name) AS text,
		coalesce(t.signaturnummer,'4141') AS signaturnummer,
		drehwinkel, horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_flaechegemischternutzung o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='NAM' AND t.endet IS NULL
	WHERE o.endet IS NULL
) AS n WHERE NOT text IS NULL;


--
-- Fläche besonderer funktionaler Prägung (41007)
--

-- Fläche besonderer funktionaler Prägung
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	'Industrie und Gewerbe' AS thema,
	'ax_flaechebesondererfunktionalerpraegung' AS layer,
	st_multi(wkb_geometry) AS polygon,
	25151401 AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ax_flaechebesondererfunktionalerpraegung
WHERE endet IS NULL;

-- Name, Fläche besonderer funktionaler Prägung
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Industrie und Gewerbe' AS thema,
	'ax_flaechebesondererfunktionalerpraegung' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel, horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung, modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(t.schriftinhalt,o.name) AS text,
		coalesce(t.signaturnummer,'4141') AS signaturnummer,
		drehwinkel, horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_flaechebesondererfunktionalerpraegung o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='NAM' AND t.endet IS NULL
	WHERE o.endet IS NULL
) AS o WHERE NOT text IS NULL;

-- Historische Anlagen (RP)
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Industrie und Gewerbe' AS thema,
	'ax_flaechebesondererfunktionalerpraegung' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel, horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung, modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(
			t.schriftinhalt,
			(select v from alkis_wertearten where element='ax_flaechebesondererfunktionalerpraegung' AND bezeichnung='funktion' AND k=funktion::text)
		) AS text,
		coalesce(t.signaturnummer,'4070') AS signaturnummer,
		drehwinkel, horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_industrieundgewerbeflaeche o
	JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='FKT' AND t.endet IS NULL
	WHERE o.endet IS NULL AND funktion=1300 AND o.gml_id LIKE 'DERP%'
) AS i WHERE NOT text IS NULL;

--
-- Sport-, Freizeit- und Erholungsfläche (41008)
--

-- Sport-, Freizeit- und Erholungsfläche
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	'Sport und Freizeit' AS thema,
	'ax_sportfreizeitunderholungsflaeche' AS layer,
	st_multi(wkb_geometry) AS polygon,
	25151405 AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ax_sportfreizeitunderholungsflaeche
WHERE endet IS NULL;


-- Anschrieb, Sport-, Freizeit- und Erholungsfläche
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Sport und Freizeit' AS thema,
	'ax_sportfreizeitunderholungsflaeche' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(
			t.schriftinhalt,
			CASE
			WHEN funktion IN (4100,4101) THEN 'Sportanlage'
			WHEN funktion IN (4300,4301) THEN 'Erholungsfläche'
			WHEN funktion IN (4320,4321) THEN 'Bad'
			WHEN funktion IN (4110,4200,4230,4240,4250,4260,4270,4280,4290,4310,4450) THEN
				(select v from alkis_wertearten where element='ax_sportfreizeitunderholungsflaeche' AND bezeichnung='funktion' AND k=funktion::text)
			WHEN o.gml_id LIKE 'DERP%' THEN
				CASE
				WHEN funktion IN (4120,4130,4140,4150,4160,4170,4230) THEN
					(select v from alkis_wertearten where element='ax_sportfreizeitunderholungsflaeche' AND bezeichnung='funktion' AND k=funktion::text)
				WHEN funktion IS NULL THEN 'Sportfläche'
				END
			END
		) AS text,
		coalesce(t.signaturnummer,n.signaturnummer,'4140') AS signaturnummer,
		t.drehwinkel,t.horizontaleausrichtung,t.vertikaleausrichtung,t.skalierung,t.fontsperrung,
		coalesce(
			t.advstandardmodell||t.sonstigesmodell||n.advstandardmodell||n.sonstigesmodell,
			o.advstandardmodell||o.sonstigesmodell
		) AS modell
	FROM ax_sportfreizeitunderholungsflaeche o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='FKT' AND t.endet IS NULL
	LEFT OUTER JOIN ap_pto n ON ARRAY[o.gml_id] <@ n.dientzurdarstellungvon AND n.art='NAM' AND n.endet IS NULL
	WHERE name IS NULL AND n.schriftinhalt IS NULL AND o.endet IS NULL
) AS o
WHERE NOT text IS NULL;

-- Symbol, Sport-, Freizeit- und Erholungsfläche
-- TODO: 3413/5, 3421 + PNR 1100 v 1101
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	gml_id,
	'Sport und Freizeit' AS thema,
	'ax_sportfreizeitunderholungsflaeche' AS layer,
	st_multi(point),
	drehwinkel,
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		coalesce(p.wkb_geometry,alkis_flaechenfuellung(o.wkb_geometry,d.positionierungsregel),st_centroid(o.wkb_geometry)) AS point,
		coalesce(p.drehwinkel,0) AS drehwinkel,
		coalesce(
			p.signaturnummer,
			CASE
			WHEN funktion IN (4210,4211) THEN '3410'
			WHEN funktion=4220           THEN '3411'
			WHEN funktion IN (4330,4331) THEN '3412'
			WHEN funktion IN (4400,4410) THEN '3413'
			WHEN funktion=4420           THEN '3415'
			WHEN funktion IN (4430,4431) THEN '3417'
			WHEN funktion=4440           THEN '3419'
			WHEN funktion=4460           THEN '3421'
			WHEN funktion=4470           THEN '3423'
			END
		) AS signaturnummer,
		coalesce(
			p.advstandardmodell||p.sonstigesmodell||d.advstandardmodell||d.sonstigesmodell,
			o.advstandardmodell||o.sonstigesmodell
		) AS modell
	FROM ax_sportfreizeitunderholungsflaeche o
	LEFT OUTER JOIN ap_ppo p ON ARRAY[o.gml_id] <@ p.dientzurdarstellungvon AND p.art='FKT' AND p.endet IS NULL
	LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='FKT' AND d.endet IS NULL
	WHERE o.endet IS NULL
) AS o WHERE NOT signaturnummer IS NULL;

-- Name, Sport-, Freizeit- und Erholungsfläche
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Sport und Freizeit' AS thema,
	'ax_sportfreizeitunderholungsflaeche' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(t.schriftinhalt,o.name) AS text,
		coalesce(t.signaturnummer,'4141') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_sportfreizeitunderholungsflaeche o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='NAM' AND t.endet IS NULL
	WHERE o.endet IS NULL
) AS n WHERE NOT text IS NULL;

--
-- Friedhof (41009)
--

-- Fläche, Friedhof
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	'Friedhöfe' AS thema,
	'ax_friedhof' AS layer,
	st_multi(wkb_geometry) AS polygon,
	25151405 AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ax_friedhof;

-- Text, Friedhof
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Friedhöfe' AS thema,
	'ax_friedhof' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(t.schriftinhalt,o.name) AS text,
		coalesce(t.signaturnummer,n.signaturnummer,'4140') AS signaturnummer,
		t.drehwinkel,t.horizontaleausrichtung,t.vertikaleausrichtung,t.skalierung,t.fontsperrung,
		coalesce(
			t.advstandardmodell||t.sonstigesmodell||n.advstandardmodell||n.sonstigesmodell,
			o.advstandardmodell||o.sonstigesmodell
		) AS modell
	FROM ax_friedhof o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='Friedhof' AND t.endet IS NULL
	LEFT OUTER JOIN ap_pto n ON ARRAY[o.gml_id] <@ n.dientzurdarstellungvon AND n.art='NAM' AND n.endet IS NULL
	WHERE name IS NULL AND n.schriftinhalt IS NULL AND o.endet IS NULL
) AS n WHERE NOT text IS NULL;

-- Name, Friedhof
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Friedhöfe' AS thema,
	'ax_friedhof' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(t.schriftinhalt,o.name) AS text,
		coalesce(t.signaturnummer,'4141') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_friedhof o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='NAM' AND t.endet IS NULL
	WHERE NOT name IS NULL OR NOT t.schriftinhalt IS NULL AND o.endet IS NULL
) AS n;


--
-- Straßenverkehr (41001)
--

-- Straßenverkehr, Fläche
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	'Verkehr' AS thema,
	'ax_strassenverkehr' AS layer,
	st_multi(wkb_geometry) AS polygon,
	CASE
	WHEN coalesce(zustand,0)<>4000 THEN 25150000
	ELSE 25160000
	END
	+
	CASE
	WHEN funktion IN (2312,2313) AND coalesce(zustand,0)<>4000 THEN 1406
	WHEN funktion=5130           AND coalesce(zustand,0)<>4000 THEN 1414
	ELSE 0
	END AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ax_strassenverkehr;

-- Straßenverkehr, Funktion
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Verkehr' AS thema,
	'ax_strassenverkehr' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(
			t.schriftinhalt,
			(select v from alkis_wertearten where element='ax_strassenverkehr' AND bezeichnung='funktion' AND k=funktion::text)
		) AS text,
		coalesce(t.signaturnummer,'4100') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_strassenverkehr o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='FKT' AND t.endet IS NULL
	WHERE  funktion=4130 AND o.endet IS NULL
) AS n WHERE NOT text IS NULL;

-- Straßenverkehr, Zweitname
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Verkehr' AS thema,
	'ax_strassenverkehr' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(t.schriftinhalt,o.zweitname) AS text,
		coalesce(t.signaturnummer,'4141') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_strassenverkehr o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='ZNM' AND t.endet IS NULL
	WHERE o.endet IS NULL
) AS n WHERE NOT text IS NULL;


--
-- Weg (42006)
--

-- Flächen
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	'Verkehr' AS thema,
	'ax_weg' AS layer,
	st_multi(wkb_geometry) AS polygon,
	2515 AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ax_weg;

-- Symbol
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	gml_id,
	'Verkehr' AS thema,
	'ax_weg' AS layer,
	st_multi(point),
	drehwinkel,
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		coalesce(p.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(p.drehwinkel,0) AS drehwinkel,
		coalesce(
			d.signaturnummer,
			p.signaturnummer,
			CASE
			WHEN funktion IN (5220,5230) THEN '3424'
			WHEN funktion=5240           THEN '3426'
			WHEN funktion=5250           THEN '3428'
			WHEN funktion=5260           THEN '3430'
			END
		) AS signaturnummer,
		coalesce(
			p.advstandardmodell||p.sonstigesmodell||d.advstandardmodell||d.sonstigesmodell,
			o.advstandardmodell||o.sonstigesmodell
		) AS modell
	FROM ax_weg o
	LEFT OUTER JOIN ap_ppo p ON ARRAY[o.gml_id] <@ p.dientzurdarstellungvon AND p.art='FKT' AND p.endet IS NULL
	LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='FKT' AND d.endet IS NULL
	WHERE o.endet IS NULL
) AS o WHERE NOT signaturnummer IS NULL;


--
-- Platz (42009)
--

-- Flächen
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	'Verkehr' AS thema,
	'ax_platz' AS layer,
	st_multi(wkb_geometry) AS polygon,
	1414 AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ax_platz WHERE funktion=5130;

-- Symbol
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	gml_id,
	'Verkehr' AS thema,
	'ax_platz' AS layer,
	st_multi(point),
	drehwinkel,
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		coalesce(p.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(p.drehwinkel,0) AS drehwinkel,
		coalesce(
			p.signaturnummer,
			CASE
			WHEN funktion=5310 THEN '3432'
			WHEN funktion=5320 THEN '3434'
			WHEN funktion=5330 THEN '3436'
			END
		) AS signaturnummer,
		coalesce(p.advstandardmodell||p.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_platz o
	LEFT OUTER JOIN ap_ppo p ON ARRAY[o.gml_id] <@ p.dientzurdarstellungvon AND p.art='FKT' AND p.endet IS NULL
	WHERE o.endet IS NULL
) AS o
WHERE NOT signaturnummer IS NULL;

-- Platz, Funktion
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Verkehr' AS thema,
	'ax_platz' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
	modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(
			t.schriftinhalt,
			(select v from alkis_wertearten where element='ax_platz' AND bezeichnung='funktion' AND k=funktion::text)
		) AS text,
		coalesce(t.signaturnummer,'4140') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_platz o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.endet IS NULL -- AND t.art='FKT' -- fehlt in RP
	WHERE o.endet IS NULL -- AND funktion IN (5340,5350)
) AS n WHERE NOT text IS NULL;

-- Platz, Zweitname
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Verkehr' AS thema,
	'ax_platz' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(t.schriftinhalt,o.zweitname) AS text,
		coalesce(t.signaturnummer,'4141') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_platz o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='ZNM' AND t.endet IS NULL
	WHERE o.endet IS NULL
) AS n WHERE NOT text IS NULL;


--
-- Bahnverkehr (42010)
--

-- Bahnverkehr, Fläche
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	'Verkehr' AS thema,
	'ax_bahnverkehr' AS layer,
	st_multi(wkb_geometry) AS polygon,
	CASE
	WHEN coalesce(zustand,0)<>4000 THEN 25150000
	ELSE 25160000
	END
	+
	CASE
	WHEN funktion=2322 AND coalesce(zustand,0)<>4000 THEN 1406
	ELSE 0
	END AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ax_bahnverkehr
WHERE endet IS NULL;

-- Bahnverkehr, Zweitname
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Verkehr' AS thema,
	'ax_bahnverkehr' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(t.schriftinhalt,o.zweitname) AS text,
		coalesce(t.signaturnummer,'4141') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_bahnverkehr o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='ZNM' AND t.endet IS NULL
	WHERE o.endet IS NULL
) AS n WHERE NOT text IS NULL;


--
-- Flugverkehr (42015)
--

-- Flugverkehr, Fläche
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	'Verkehr' AS thema,
	'ax_flugverkehr' AS layer,
	st_multi(wkb_geometry) AS polygon,
	CASE
	WHEN zustand=4000 THEN 2516 ELSE 25151406 END AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ax_flugverkehr;

-- Flugverkehr, Symbol
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	gml_id,
	'Verkehr' AS thema,
	'ax_flugverkehr' AS layer,
	st_multi(point),
	drehwinkel,
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		coalesce(p.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(p.drehwinkel,0) AS drehwinkel,
		coalesce(
			p.signaturnummer,
			CASE
			WHEN funktion=5530 THEN '3438'
			WHEN funktion=5550 THEN '3439'
			END
		) AS signaturnummer,
		coalesce(p.advstandardmodell||p.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_flugverkehr o
	LEFT OUTER JOIN ap_ppo p ON ARRAY[o.gml_id] <@ p.dientzurdarstellungvon AND p.art='ART' AND p.endet IS NULL
	WHERE o.endet IS NULL
) AS o
WHERE NOT signaturnummer IS NULL;

-- Flugverkehr, Name
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Verkehr' AS thema,
	'ax_flugverkehr' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(t.schriftinhalt,o.name) AS text,
		coalesce(t.signaturnummer,'4200') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_flugverkehr o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='NAM' AND t.endet IS NULL
	WHERE o.endet IS NULL AND NOT name IS NULL
) AS n;


--
-- Schiffsverkehr (42016)
--

-- Schiffsverkehr, Fläche
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	'Verkehr' AS thema,
	'ax_schiffsverkehr' AS layer,
	st_multi(wkb_geometry) AS polygon,
	CASE WHEN zustand=4000 THEN 2516 ELSE 2515 END AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ax_schiffsverkehr
WHERE endet IS NULL;

-- Schiffsverkehr, Name
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Verkehr' AS thema,
	'ax_schiffsverkehr' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(t.schriftinhalt,o.name) AS text,
		coalesce(t.signaturnummer,'4141') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_schiffsverkehr o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='NAM' AND t.endet IS NULL
	WHERE o.endet IS NULL AND NOT name IS NULL
) AS n;

-- Hafenanlage (RP)
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Verkehr' AS thema,
	'ax_schiffsverkehr' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel, horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung, modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(
			t.schriftinhalt,
			CASE
			WHEN funktion=5610 THEN 'Hafenanlage'
			WHEN funktion IN (5630,5640) THEN
				(select v from alkis_wertearten where element='ax_schiffsverkehr' AND bezeichnung='funktion' AND k=funktion::text)
			END
		) AS text,
		coalesce(t.signaturnummer,'4140') AS signaturnummer,
		drehwinkel, horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_schiffsverkehr o
	JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='FKT' AND t.endet IS NULL
	WHERE o.endet IS NULL AND o.gml_id LIKE 'DERP%'
) AS i WHERE NOT text IS NULL;


--
-- Landwirtschaft (43001)
--

-- Landwirtschaft, Fläche
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	'Vegetation' AS thema,
	'ax_landwirtschaft' AS layer,
	polygon,
	signaturnummer,
	modell
FROM (
	SELECT
		gml_id,
		st_multi(wkb_geometry) AS polygon,
		CASE
		WHEN coalesce(vegetationsmerkmal,0) IN (0,1100,1101,1012,1013) THEN 25151409
		WHEN vegetationsmerkmal IN (1020,1021,1030,1031,1040,1050,1051,1052) THEN 25151406
		WHEN vegetationsmerkmal=1200 THEN 25151404
		END AS signaturnummer,
		advstandardmodell||sonstigesmodell AS modell
	FROM ax_landwirtschaft
	WHERE endet IS NULL
) AS o WHERE NOT signaturnummer IS NULL;

-- Landwirtschaft, Symbole
-- TODO:
-- 3440/2    + PNR 1104 v 1105
-- 3442/3444 + PNR 1102 v 1103
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	gml_id,
	'Vegetation' AS thema,
	'ax_landwirtschaft' AS layer,
	st_multi(point),
	drehwinkel,
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		coalesce(p.wkb_geometry,alkis_flaechenfuellung(o.wkb_geometry,d.positionierungsregel),st_centroid(o.wkb_geometry)) AS point,
		coalesce(p.drehwinkel,0) AS drehwinkel,
		coalesce(
			d.signaturnummer,
			p.signaturnummer,
			CASE
			WHEN vegetationsmerkmal=1011 THEN '3440'
			WHEN vegetationsmerkmal=1012 THEN '3442'
			WHEN vegetationsmerkmal=1013 THEN '3444'
			WHEN vegetationsmerkmal=1020 THEN '3413'
			WHEN vegetationsmerkmal=1021 THEN '3441'
			WHEN vegetationsmerkmal=1030 THEN '3421'
			WHEN vegetationsmerkmal=1031 THEN '3446'
			WHEN vegetationsmerkmal=1040 THEN '3448'
			WHEN vegetationsmerkmal=1050 THEN '3450'
			WHEN vegetationsmerkmal=1051 THEN '3452'
			WHEN vegetationsmerkmal=1052 THEN '3454'
			END
		) AS signaturnummer,
		coalesce(
			p.advstandardmodell||p.sonstigesmodell||d.advstandardmodell||d.sonstigesmodell,
			o.advstandardmodell||o.sonstigesmodell
		) AS modell
	FROM ax_landwirtschaft o
	LEFT OUTER JOIN ap_ppo p ON ARRAY[o.gml_id] <@ p.dientzurdarstellungvon AND p.art='VEG' AND p.endet IS NULL
	LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='VEG' AND d.endet IS NULL
	WHERE o.endet IS NULL
) AS o WHERE NOT signaturnummer IS NULL;

-- Landwirtschaft, Name
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Vegetation' AS thema,
	'ax_landwirtschaft' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(t.schriftinhalt,o.name) AS text,
		coalesce(t.signaturnummer,'4208') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_landwirtschaft o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='NAM' AND t.endet IS NULL
	WHERE o.endet IS NULL AND NOT name IS NULL
) AS n;


--
-- Wald (43002)
--

-- Wald, Flächen
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	'Vegetation' AS thema,
	'ax_wald' AS layer,
	st_multi(wkb_geometry) AS polygon,
	25171414 AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ax_wald;

-- Wald, Symbole
-- TODO: PNR?
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	gml_id,
	'Vegetation' AS thema,
	'ax_wald' AS layer,
	st_multi(point),
	drehwinkel,
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		coalesce(p.wkb_geometry,alkis_flaechenfuellung(o.wkb_geometry,d.positionierungsregel),st_centroid(o.wkb_geometry)) AS point,
		coalesce(p.drehwinkel,0) AS drehwinkel,
		coalesce(
			d.signaturnummer,
			p.signaturnummer,
			CASE
			WHEN vegetationsmerkmal IS NULL             THEN '3456'
			WHEN vegetationsmerkmal=1100                THEN '3458'
			WHEN vegetationsmerkmal=1200                THEN '3460'
			WHEN vegetationsmerkmal IN (1300,1310,1320) THEN '3462'
			END
		) AS signaturnummer,
		coalesce(
			p.advstandardmodell||p.sonstigesmodell||d.advstandardmodell||d.sonstigesmodell,
			o.advstandardmodell||o.sonstigesmodell
		) AS modell
	FROM ax_wald o
	LEFT OUTER JOIN ap_ppo p ON ARRAY[o.gml_id] <@ p.dientzurdarstellungvon AND p.art='VEG' AND p.endet IS NULL
	LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='VEG' AND d.endet IS NULL
	WHERE o.endet IS NULL
) AS o
WHERE NOT signaturnummer IS NULL;

-- Wald, Namen
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Vegetation' AS thema,
	'ax_wald' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(t.schriftinhalt,o.name) AS text,
		coalesce(t.signaturnummer,'4209') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_wald o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='NAM' AND t.endet IS NULL
	WHERE o.endet IS NULL AND NOT name IS NULL
) AS n;

--
-- Gehölz (43003)
--

-- Gehölz, Flächen
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	'Vegetation' AS thema,
	'ax_gehoelz' AS layer,
	st_multi(wkb_geometry) AS polygon,
	25171414 AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ax_gehoelz
WHERE endet IS NULL;

-- Gehölz, Symbole
-- TODO: PNR?
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	gml_id,
	'Vegetation' AS thema,
	'ax_gehoelz' AS layer,
	st_multi(point),
	drehwinkel,
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		coalesce(p.wkb_geometry,alkis_flaechenfuellung(o.wkb_geometry,d.positionierungsregel),st_centroid(o.wkb_geometry)) AS point,
		coalesce(p.drehwinkel,0) AS drehwinkel,
		coalesce(
			d.signaturnummer,
			p.signaturnummer,
			CASE
			WHEN vegetationsmerkmal IS NULL             THEN '3470'
			WHEN vegetationsmerkmal=1400                THEN '3472'
			END
		) AS signaturnummer,
		coalesce(
			p.advstandardmodell||p.sonstigesmodell||d.advstandardmodell||d.sonstigesmodell,
			o.advstandardmodell||o.sonstigesmodell
		) AS modell
	FROM ax_gehoelz o
	LEFT OUTER JOIN ap_ppo p ON ARRAY[o.gml_id] <@ p.dientzurdarstellungvon AND p.art='VEG' AND p.endet IS NULL
	LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='VEG' AND d.endet IS NULL
	WHERE o.endet IS NULL
) AS o
WHERE NOT signaturnummer IS NULL;

-- Gehölz, Namen
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Vegetation' AS thema,
	'ax_gehoelz' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(t.schriftinhalt,o.name) AS text,
		coalesce(t.signaturnummer,'4209') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_gehoelz o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='NAM' AND t.endet IS NULL
	WHERE o.endet IS NULL AND NOT name IS NULL
) AS n;


--
-- Heide (43004)
--

-- Heide, Flächen
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	'Vegetation' AS thema,
	'ax_heide' AS layer,
	st_multi(wkb_geometry) AS polygon,
	25171404 AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ax_heide;

-- Heide, Symbole
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	o.gml_id,
	'Vegetation' AS thema,
	'ax_heide' AS layer,
	st_multi(coalesce(p.wkb_geometry,alkis_flaechenfuellung(o.wkb_geometry,d.positionierungsregel),st_centroid(o.wkb_geometry))) AS point,
	coalesce(p.drehwinkel,0) AS drehwinkel,
	coalesce(d.signaturnummer,'3474') AS signaturnummer,
	coalesce(
		p.advstandardmodell||p.sonstigesmodell||d.advstandardmodell||d.sonstigesmodell,
		o.advstandardmodell||o.sonstigesmodell
	) AS modell
FROM ax_heide o
LEFT OUTER JOIN ap_ppo p ON ARRAY[o.gml_id] <@ p.dientzurdarstellungvon AND p.art='Heide' AND p.endet IS NULL
LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='Heide' AND d.endet IS NULL
WHERE o.endet IS NULL;

-- Heide, Namen
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Vegetation' AS thema,
	'ax_heide' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(t.schriftinhalt,o.name) AS text,
		coalesce(t.signaturnummer,'4209') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_heide o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='NAM' AND t.endet IS NULL
	WHERE o.endet IS NULL AND NOT name IS NULL
) AS n;


--
-- Moor (43005)
--

-- Moor, Flächen
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	'Vegetation' AS thema,
	'ax_moor' AS layer,
	st_multi(wkb_geometry) AS polygon,
	25171404 AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ax_moor
WHERE endet IS NULL;

-- Moor, Symbole
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	o.gml_id,
	'Vegetation' AS thema,
	'ax_moor' AS layer,
	st_multi(coalesce(p.wkb_geometry,alkis_flaechenfuellung(o.wkb_geometry,d.positionierungsregel),st_centroid(o.wkb_geometry))) AS point,
	coalesce(p.drehwinkel,0) AS drehwinkel,
	coalesce(d.signaturnummer,p.signaturnummer,'3476') AS signaturnummer,
	coalesce(
		p.advstandardmodell||p.sonstigesmodell||d.advstandardmodell||d.sonstigesmodell,
		o.advstandardmodell||o.sonstigesmodell
	) AS modell
FROM ax_moor o
LEFT OUTER JOIN ap_ppo p ON ARRAY[o.gml_id] <@ p.dientzurdarstellungvon AND p.art='Moor' AND p.endet IS NULL
LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='Moor' AND d.endet IS NULL
WHERE o.endet IS NULL;

-- Moor, Namen
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Vegetation' AS thema,
	'ax_moor' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(t.schriftinhalt,o.name) AS text,
		coalesce(t.signaturnummer,'4209') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_moor o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='NAM' AND t.endet IS NULL
	WHERE o.endet IS NULL AND NOT name IS NULL
) AS n;


--
-- Sumpf (43006)
--

-- Sumpf, Flächen
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	'Vegetation' AS thema,
	'ax_sumpf' AS layer,
	st_multi(wkb_geometry) AS polygon,
	25171404 AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ax_sumpf;

-- Sumpf, Symbole
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	o.gml_id,
	'Vegetation' AS thema,
	'ax_sumpf' AS layer,
	st_multi(coalesce(p.wkb_geometry,alkis_flaechenfuellung(o.wkb_geometry,d.positionierungsregel),st_centroid(o.wkb_geometry))) AS point,
	coalesce(p.drehwinkel,0) AS drehwinkel,
	coalesce(d.signaturnummer,p.signaturnummer,'3478') AS signaturnummer,
	coalesce(
		p.advstandardmodell||p.sonstigesmodell||d.advstandardmodell||d.sonstigesmodell,
		o.advstandardmodell||o.sonstigesmodell
	) AS modell
FROM ax_sumpf o
LEFT OUTER JOIN ap_ppo p ON ARRAY[o.gml_id] <@ p.dientzurdarstellungvon AND p.art='Sumpf' AND p.endet IS NULL
LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='Sumpf' AND d.endet IS NULL
WHERE o.endet IS NULL;

-- Sumpf, Namen
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Vegetation' AS thema,
	'ax_sumpf' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(t.schriftinhalt,o.name) AS text,
		coalesce(t.signaturnummer,'4209') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_sumpf o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='NAM' AND t.endet IS NULL
	WHERE o.endet IS NULL AND NOT name IS NULL
) AS n;


--
-- Unland/Vegetationslosefläche (43007)
--

-- Unland, Flächen
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	'Vegetation' AS thema,
	'ax_unlandvegetationsloseflaeche' AS layer,
	polygon,
	signaturnummer,
	modell
FROM (
	SELECT
		gml_id,
		st_multi(wkb_geometry) AS polygon,
		CASE
		WHEN coalesce(oberflaechenmaterial,0) IN (0,1010,1020,1030,1040) THEN 2515
		WHEN oberflaechenmaterial IN (1110,1120)                         THEN 2518
		WHEN oberflaechenmaterial IN (1100,1110,1120,1200)               THEN 25151405
		END AS signaturnummer,
		advstandardmodell||sonstigesmodell AS modell
	FROM ax_unlandvegetationsloseflaeche o
	WHERE coalesce(funktion,1000)=1000 AND endet IS NULL
) AS o WHERE NOT signaturnummer IS NULL;

-- Unland, Symbole
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	gml_id,
	'Vegetation' AS thema,
	'ax_unlandvegetationsloseflaeche' AS layer,
	st_multi(point),
	drehwinkel,
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		coalesce(p.wkb_geometry,alkis_flaechenfuellung(o.wkb_geometry,d.positionierungsregel),st_centroid(o.wkb_geometry)) AS point,
		coalesce(p.drehwinkel,0) AS drehwinkel,
		coalesce(
			d.signaturnummer,
			p.signaturnummer,
			CASE
			WHEN coalesce(funktion,1000)=1000 THEN
				CASE
				WHEN oberflaechenmaterial IS NULL        THEN '3480'
				WHEN oberflaechenmaterial=1010           THEN '3481'
				WHEN oberflaechenmaterial=1020           THEN '3482'
				WHEN oberflaechenmaterial=1030           THEN '3483'
				WHEN oberflaechenmaterial=1040           THEN '3484'
				WHEN oberflaechenmaterial IN (1110,1120) THEN '3486'
				END
			END
		) AS signaturnummer,
		coalesce(
			p.advstandardmodell||p.sonstigesmodell||d.advstandardmodell||d.sonstigesmodell,
			o.advstandardmodell||o.sonstigesmodell
		) AS modell
	FROM ax_unlandvegetationsloseflaeche o
	LEFT OUTER JOIN ap_ppo p ON ARRAY[o.gml_id] <@ p.dientzurdarstellungvon AND p.art='OFM' AND p.endet IS NULL
	LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='OFM' AND d.endet IS NULL
	WHERE o.endet IS NULL
) AS o WHERE NOT signaturnummer IS NULL;

-- Unland, Namen
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Vegetation' AS thema,
	'ax_unlandvegetationsloseflaeche' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(t.schriftinhalt,o.name) AS text,
		coalesce(
			d.signaturnummer,
			t.signaturnummer,
			CASE WHEN oberflaechenmaterial IN (1110,1120) THEN '4151' ELSE '4150' END
		) AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(
			t.advstandardmodell||t.sonstigesmodell||d.advstandardmodell||d.sonstigesmodell,
			o.advstandardmodell||o.sonstigesmodell
		) AS modell
	FROM ax_unlandvegetationsloseflaeche o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='NAM' AND t.endet IS NULL
	LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='NAM' AND d.endet IS NULL
) AS n WHERE NOT text IS NULL;


--
-- Fließgewässer (44001)
--

-- Fließgewässer, Flächen
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	'Gewässer' AS thema,
	'ax_fliessgewaesser' AS layer,
	st_multi(wkb_geometry) AS polygon,
	CASE
	WHEN zustand=4000 THEN 2519
	ELSE 25181410
	END AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ax_fliessgewaesser
WHERE endet IS NULL;

-- Fließgewäesser, Pfeil
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	o.gml_id,
	'Gewässer' AS thema,
	'ax_fliessgewaesser' AS layer,
	st_multi(coalesce(p.wkb_geometry,st_centroid(o.wkb_geometry))) AS point,
	coalesce(p.drehwinkel,0) AS drehwinkel,
	coalesce(p.signaturnummer,'3488') AS signaturnummer,
	coalesce(p.advstandardmodell||p.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM ax_fliessgewaesser o
JOIN ap_ppo p ON ARRAY[o.gml_id] <@ p.dientzurdarstellungvon AND p.art='Fließpfeil' AND p.endet IS NULL
WHERE o.endet IS NULL AND coalesce(zustand,0)<>4000;

-- Fließgewäesser, Symbol
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	o.gml_id,
	'Gewässer' AS thema,
	'ax_fliessgewaesser' AS layer,
	st_multi(coalesce(p.wkb_geometry,alkis_flaechenfuellung(o.wkb_geometry,d.positionierungsregel),st_centroid(o.wkb_geometry))) AS point,
	coalesce(p.drehwinkel,0) AS drehwinkel,
	coalesce(d.signaturnummer,p.signaturnummer,'3490') AS signaturnummer,
	coalesce(
		p.advstandardmodell||p.sonstigesmodell||d.advstandardmodell||d.sonstigesmodell,
		o.advstandardmodell||o.sonstigesmodell
	) AS modell
FROM ax_fliessgewaesser o
LEFT OUTER JOIN ap_ppo p ON ARRAY[o.gml_id] <@ p.dientzurdarstellungvon AND p.art='FKT' AND p.endet IS NULL
LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='FKT' AND d.endet IS NULL
WHERE o.endet IS NULL AND funktion=8300 AND zustand=4000;


--
-- Hafenbecken (44005)
--

-- Hafenbecken, Flächen
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	'Gewässer' AS thema,
	'ax_hafenbecken' AS layer,
	st_multi(wkb_geometry) AS polygon,
	25181410 AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ax_hafenbecken
WHERE endet IS NULL;

-- Hafenbecken, Symbol
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	o.gml_id,
	'Gewässer' AS thema,
	'ax_hafenbecken' AS layer,
	st_multi(coalesce(p.wkb_geometry,st_centroid(o.wkb_geometry))) AS point,
	coalesce(p.drehwinkel,0) AS drehwinkel,
	coalesce(p.signaturnummer,'3490') AS signaturnummer,
	coalesce(p.advstandardmodell||p.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM ax_hafenbecken o
LEFT OUTER JOIN ap_ppo p ON ARRAY[o.gml_id] <@ p.dientzurdarstellungvon AND p.art='FKT' AND p.endet IS NULL
WHERE o.endet IS NULL;

-- Hafenbecken, Namen
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Gewässer' AS thema,
	'ax_hafenbecken' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(t.schriftinhalt,o.name) AS text,
		coalesce(t.signaturnummer,'4211') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_hafenbecken o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='NAM' AND t.endet IS NULL
	WHERE o.endet IS NULL AND NOT name IS NULL
) AS n;


--
-- Stehendes Gewässer (44006)
--

-- Stehendes Gewässer, Flächen
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	'Gewässer' AS thema,
	'ax_stehendesgewaesser' AS layer,
	st_multi(wkb_geometry) AS polygon,
	CASE
	WHEN hydrologischesmerkmal IS NULL THEN 25181410
	WHEN hydrologischesmerkmal=2000    THEN 25201410
	END AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ax_stehendesgewaesser
WHERE endet IS NULL;

-- Stehendes Gewässer, Symbol
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	o.gml_id,
	'Gewässer' AS thema,
	'ax_stehendesgewaesser' AS layer,
	st_multi(coalesce(p.wkb_geometry,alkis_flaechenfuellung(o.wkb_geometry,d.positionierungsregel),st_centroid(o.wkb_geometry))) AS point,
	coalesce(p.drehwinkel,0) AS drehwinkel,
	coalesce(d.signaturnummer,p.signaturnummer,'3490') AS signaturnummer,
	coalesce(
		p.advstandardmodell||p.sonstigesmodell||d.advstandardmodell||d.sonstigesmodell,
		o.advstandardmodell||o.sonstigesmodell
	) AS modell
FROM ax_stehendesgewaesser o
LEFT OUTER JOIN ap_ppo p ON ARRAY[o.gml_id] <@ p.dientzurdarstellungvon AND p.art='FKT' AND p.endet IS NULL
LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='FKT' AND d.endet IS NULL
WHERE o.endet IS NULL;


--
-- Meer (44007)
--

-- Meer, Flächen
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	'Gewässer' AS thema,
	'ax_meer' AS layer,
	st_multi(wkb_geometry) AS polygon,
	25181410 AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ax_meer
WHERE endet IS NULL;

-- Meer, Symbol
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	o.gml_id,
	'Gewässer' AS thema,
	'ax_meer' AS layer,
	st_multi(coalesce(p.wkb_geometry,alkis_flaechenfuellung(o.wkb_geometry,d.positionierungsregel),st_centroid(o.wkb_geometry))) AS point,
	coalesce(p.drehwinkel,0) AS drehwinkel,
	coalesce(d.signaturnummer,p.signaturnummer,'3490') AS signaturnummer,
	coalesce(
		p.advstandardmodell||p.sonstigesmodell||d.advstandardmodell||d.sonstigesmodell,
		o.advstandardmodell||o.sonstigesmodell
	) AS modell
FROM ax_meer o
LEFT OUTER JOIN ap_ppo p ON ARRAY[o.gml_id] <@ p.dientzurdarstellungvon AND p.art='FKT' AND p.endet IS NULL
LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='FKT' AND d.endet IS NULL
WHERE o.endet IS NULL;

-- Meer, Namen
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Gewässer' AS thema,
	'ax_meer' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(t.schriftinhalt,o.name) AS text,
		coalesce(t.signaturnummer,'4286') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_meer o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='NAM' AND t.endet IS NULL
	WHERE o.endet IS NULL AND NOT name IS NULL
) AS n;


--
-- Turm (55001)
--

-- Turm, Flächen
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	'Gebäude' AS thema,
	'ax_turm' AS layer,
	st_multi(wkb_geometry) AS polygon,
	CASE WHEN zustand=2200 THEN 1502 ELSE 1501 END AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ax_turm
WHERE endet IS NULL;

-- Turm, Texte
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Gebäude' AS thema,
	'ax_turm' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(
			t.schriftinhalt,
			CASE
			WHEN bauwerksfunktion IN (1000,1010,1011) THEN
				(select v from alkis_wertearten where element='ax_turm' AND bezeichnung='bauwerksfunktion' AND k=bauwerksfunktion::text)
				|| CASE WHEN zustand=2100 THEN E'\n(außer Betrieb)' WHEN zustand=2200 THEN E'\n(zerstört)' ELSE '' END
			WHEN bauwerksfunktion IN (1000,1009,1012,9998) THEN
				CASE WHEN zustand=2100 THEN '(außer Betrieb)' WHEN zustand=2200 THEN '(zerstört)' END
			END
		) AS text,
		coalesce(t.signaturnummer,'4070') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_turm o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='BWF_ZUS' AND t.endet IS NULL
	WHERE o.endet IS NULL
) AS n WHERE NOT text IS NULL;

-- Turm, Name
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Gebäude' AS thema,
	'ax_turm' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(t.schriftinhalt,o.name) AS text,
		coalesce(t.signaturnummer,'4074') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_turm o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='NAM' AND t.endet IS NULL
	WHERE o.endet IS NULL AND NOT name IS NULL
) AS n;


--
-- Bauwerk- oder Anlage für Industrie und Gewerbe (51002)
--

-- Bauwerk- oder Anlage für Industrie und Gewerbe, Flächen
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	'Industrie und Gewerbe' AS thema,
	'ax_bauwerkoderanlagefuerindustrieundgewerbe' AS layer,
	st_multi(wkb_geometry) AS polygon,
	CASE
	WHEN bauwerksfunktion=1210                                    THEN 1510
	WHEN bauwerksfunktion IN (1215,1220,1230,1240,1260,1270,1280,1320,1330,1331,1332,1333,1340,1350,1390,9999) THEN 1305
	WHEN bauwerksfunktion=1250                                    THEN 1306
	WHEN bauwerksfunktion=1290                                    THEN 1501
	END AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ax_bauwerkoderanlagefuerindustrieundgewerbe
WHERE geometrytype(wkb_geometry) IN ('POLYGON','MULTIPOLYGON')
  AND endet IS NULL
  AND bauwerksfunktion IN (1210,1215,1220,1230,1240,1250,1260,1270,1280,1290,1320,1330,1331,1332,1333,1340,1350,1390,9999);

-- Bauwerk- oder Anlage für Industrie und Gewerbe, Symbole
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	gml_id,
	'Industrie und Gewerbe' AS thema,
	'ax_bauwerkoderanlagefuerindustrieundgewerbe' AS layer,
	st_multi(point),
	drehwinkel,
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		coalesce(
			p.wkb_geometry,
			CASE
			WHEN geometrytype(o.wkb_geometry) IN ('POINT','MULTIPOINT')     THEN o.wkb_geometry
			WHEN geometrytype(o.wkb_geometry) IN ('POLYGON','MULTIPOLYGON') THEN st_centroid(o.wkb_geometry)
			END
		) AS point,
		coalesce(p.drehwinkel,0) AS drehwinkel,
		coalesce(
			p.signaturnummer,
			CASE
			WHEN bauwerksfunktion=1220           THEN '3501'
			WHEN bauwerksfunktion=1230           THEN '3502'
			WHEN bauwerksfunktion=1240           THEN '3503'
			WHEN bauwerksfunktion=1250           THEN '3504'
			WHEN bauwerksfunktion IN (1260,1270) THEN '3506'
			WHEN bauwerksfunktion=1280           THEN '3507'
			WHEN bauwerksfunktion=1290           THEN '3508'
			WHEN bauwerksfunktion=1310           THEN '3509'
			WHEN bauwerksfunktion=1320           THEN '3510'
			WHEN bauwerksfunktion=1330           THEN '3511'
			WHEN bauwerksfunktion=1331           THEN '3512'
			WHEN bauwerksfunktion=1332           THEN '3513'
			WHEN bauwerksfunktion=1333           THEN '3514'
			WHEN bauwerksfunktion=1350           THEN '3515'
			WHEN bauwerksfunktion=1360           THEN '3516'
			WHEN bauwerksfunktion IN (1370,1371) THEN '3517'
			WHEN bauwerksfunktion=1372           THEN '3518'
			WHEN bauwerksfunktion=1380           THEN '3519'
			WHEN bauwerksfunktion=1390           THEN '3520'
			WHEN bauwerksfunktion=1400           THEN '3521'
			END
		) AS signaturnummer,
		coalesce(p.advstandardmodell||p.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_bauwerkoderanlagefuerindustrieundgewerbe o
	LEFT OUTER JOIN ap_ppo p ON ARRAY[o.gml_id] <@ p.dientzurdarstellungvon AND p.art='FKT' AND p.endet IS NULL
	WHERE o.endet IS NULL
) AS o WHERE NOT signaturnummer IS NULL AND NOT point IS NULL;

-- Bauwerk- oder Anlage für Industrie und Gewerbe, Texte
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Industrie und Gewerbe' AS thema,
	'ax_bauwerkoderanlagefuerindustrieundgewerbe' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(
			t.schriftinhalt,
			(select v from alkis_wertearten where element='ax_bauwerkoderanlagefuerindustrieundgewerbe' AND bezeichnung='bauwerksfunktion' AND k=bauwerksfunktion::text)
		) AS text,
		coalesce(
			t.signaturnummer,
			CASE
			WHEN bauwerksfunktion IN (1210,1215) THEN '4100'
			WHEN bauwerksfunktion=1340           THEN '4140'
			END
		) AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_bauwerkoderanlagefuerindustrieundgewerbe o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='BWF' AND t.endet IS NULL
	WHERE o.endet IS NULL
) AS n WHERE NOT signaturnummer IS NULL AND text IS NULL;

-- Bauwerk- oder Anlage für Industrie und Gewerbe, Name
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Industrie und Gewerbe' AS thema,
	'ax_bauwerkoderanlagefuerindustrieundgewerbe' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(t.schriftinhalt,o.name) AS text,
		coalesce(t.signaturnummer,'4141') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_bauwerkoderanlagefuerindustrieundgewerbe o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='NAM' AND t.endet IS NULL
	WHERE o.endet IS NULL AND NOT name IS NULL
) AS n;

-- Bauwerk- oder Anlage für Industrie und Gewerbe, Zustandstext
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Industrie und Gewerbe' AS thema,
	'ax_bauwerkoderanlagefuerindustrieundgewerbe' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		CASE zustand
		WHEN 2100 THEN '(außer Betrieb)'
		WHEN 2200 THEN '(zerstört)'
		WHEN 4200 THEN '(verschlossen)'
		END AS text,
		coalesce(t.signaturnummer,'4070') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_bauwerkoderanlagefuerindustrieundgewerbe o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='ZUS' AND t.endet IS NULL
	WHERE o.endet IS NULL AND zustand IN (2100,2200,4200)
) AS n;


--
-- Vorratsbehälter, Speicherbauwerk (51003)
--

-- Vorratsbehälter, Speicherbauwerk, Flächen
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	'Industrie und Gewerbe' AS thema,
	'ax_vorratsbehaelterspeicherbauwerk' AS layer,
	polygon,
	signaturnummer,
	modell
FROM (
	SELECT
		gml_id,
		st_multi(wkb_geometry) AS polygon,
		CASE
		WHEN lagezurerdoberflaeche IS NULL THEN 1305
		WHEN lagezurerdoberflaeche=1200    THEN 1321
		WHEN lagezurerdoberflaeche=1400    THEN 20311304
		END AS signaturnummer,
		advstandardmodell||sonstigesmodell AS modell
	FROM ax_vorratsbehaelterspeicherbauwerk
	WHERE geometrytype(wkb_geometry) IN ('POLYGON','MULTIPOLYGON')
) AS o;

-- Vorratsbehälter, Speicherbauwerk, Symbole
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	gml_id,
	'Industrie und Gewerbe' AS thema,
	'ax_vorratsbehaelterspeicherbauwerk' AS layer,
	point,
	drehwinkel,
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		st_multi(coalesce(
			p.wkb_geometry,
			CASE
			WHEN geometrytype(o.wkb_geometry) IN ('POINT','MULTIPOINT')     THEN o.wkb_geometry
			WHEN geometrytype(o.wkb_geometry) IN ('POLYGON','MULTIPOLYGON') THEN st_centroid(o.wkb_geometry)
			END
		)) AS point,
		coalesce(p.drehwinkel,0) AS drehwinkel,
		coalesce(d.signaturnummer,p.signaturnummer,'3522') AS signaturnummer,
		coalesce(
			p.advstandardmodell||p.sonstigesmodell||d.advstandardmodell||d.sonstigesmodell,
			o.advstandardmodell||o.sonstigesmodell
		) AS modell
	FROM ax_vorratsbehaelterspeicherbauwerk o
	LEFT OUTER JOIN ap_ppo p ON ARRAY[o.gml_id] <@ p.dientzurdarstellungvon AND p.art='Vorratsbehaelter' AND p.endet IS NULL
	LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='Vorratsbehaelter' AND d.endet IS NULL
	WHERE o.endet IS NULL
) AS o;

-- Vorratsbehälter, Speicherbauwerk, Name
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Industrie und Gewerbe' AS thema,
	'ax_vorratsbehaelterspeicherbauwerk' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(t.schriftinhalt,name) AS text,
		coalesce(t.signaturnummer,'4107') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_vorratsbehaelterspeicherbauwerk o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='NAM' AND t.endet IS NULL
	WHERE o.endet IS NULL AND NOT name IS NULL
) AS n;


--
-- Transportanlage (51004)
--

-- Transportanlage, Linie
INSERT INTO po_lines(gml_id,thema,layer,line,signaturnummer,modell)
SELECT
	gml_id,
	'Industrie und Gewerbe' AS thema,
	'ax_transportanlage' AS layer,
	st_multi(wkb_geometry) AS line,
	CASE
	WHEN bauwerksfunktion=1101 THEN
		CASE
		WHEN coalesce(lagezurerdoberflaeche,1400)=1400 THEN 2002
		WHEN lagezurerdoberflaeche IN (1200,1700)      THEN 2523
		END
	WHEN bauwerksfunktion=1102 THEN
		CASE
		WHEN coalesce(lagezurerdoberflaeche,1400)=1400 THEN 2521
		WHEN lagezurerdoberflaeche IN (1200,1700)      THEN 2504
		END
	END AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ax_transportanlage
WHERE bauwerksfunktion IN (1101,1102) AND endet IS NULL;

-- Transportanlage, Symbole
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	gml_id,
	'Industrie und Gewerbe' AS thema,
	'ax_transportanlage' AS layer,
	st_multi(wkb_geometry) AS point,
	0 AS drehwinkel,
	3523 AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ax_transportanlage
WHERE bauwerksfunktion=1103 AND lagezurerdoberflaeche IS NULL AND endet IS NULL;

-- Transportanlage, Anschrieb Produkt
-- TODO: welche Text sind NULL?
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Industrie und Gewerbe' AS thema,
	'ax_transportanlage' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		(select v from alkis_wertearten where element='ax_vorratsbehaelterspeicherbauwerk' AND bezeichnung='produkt' AND k=produkt::text) AS text,
		coalesce(t.signaturnummer,'4070') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_transportanlage o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='PRO' AND t.endet IS NULL
	WHERE o.endet IS NULL AND NOT produkt IS NULL
) AS n
WHERE NOT text IS NULL;


--
-- Leitung (51005)
--

-- Leitungsverlauf
INSERT INTO po_lines(gml_id,thema,layer,line,signaturnummer,modell)
SELECT
	gml_id,
	'Industrie und Gewerbe' AS thema,
	'ax_leitung' AS layer,
	st_multi(wkb_geometry) AS line,
	CASE
	WHEN bauwerksfunktion=1110 THEN 2524
	WHEN bauwerksfunktion=1111 THEN 2523
	END AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ax_leitung
WHERE bauwerksfunktion IN (1110,1111) AND endet IS NULL;

-- Anschrieb Erdkabel
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	o.gml_id,
	'Industrie und Gewerbe' AS thema,
	'ax_leitung' AS layer,
	coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
	'Erdkabel' AS text,
	coalesce(t.signaturnummer,'4070') AS signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
	coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM ax_leitung o
LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='BWF' AND t.endet IS NULL
WHERE bauwerksfunktion=1111 AND o.endet IS NULL;

-- Anschrieb Spannungsebene
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	o.gml_id,
	'Industrie und Gewerbe' AS thema,
	'ax_leitung' AS layer,
	coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
	spannungsebene || CASE WHEN o.gml_id LIKE 'DERP%' THEN ' kV' ELSE ' KV' END AS text,
	coalesce(t.signaturnummer,'4070') AS signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
	coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM ax_leitung o
LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='SPG' AND t.endet IS NULL
WHERE o.endet IS NULL AND NOT spannungsebene IS NULL;


--
-- Bauwerk oder Anlage für Sport, Freizeit und Erholung (51006)
--

-- Bauwerk oder Anlage für Sport, Freizeit und Erholung, Flächen
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	'Sport und Freizeit' AS thema,
	'ax_bauwerkoderanlagefuersportfreizeitunderholung' AS layer,
	st_multi(wkb_geometry) AS polygon,
	CASE
	WHEN bauwerksfunktion IN (1410,1411,1412)                          THEN 1520
	WHEN bauwerksfunktion=1420                                         THEN 1521
	WHEN bauwerksfunktion IN (1430,1432,1460,1470,1480,1490,1510,9999) THEN 1524
	WHEN bauwerksfunktion=1431                                         THEN 1519
	WHEN bauwerksfunktion=1440                                         THEN 1522
	WHEN bauwerksfunktion=1450                                         THEN 1526
	END AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ax_bauwerkoderanlagefuersportfreizeitunderholung
WHERE geometrytype(wkb_geometry) IN ('POLYGON','MULTIPOLYGON') AND endet IS NULL;

-- Bauwerk oder Anlage für Sport, Freizeit und Erholung, Texte
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Sport und Freizeit' AS thema,
	'ax_bauwerkoderanlagefuersportfreizeitunderholung' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		CASE
		WHEN bauwerksfunktion IN (1430,1431,1432) THEN 'Tribüne'
		WHEN bauwerksfunktion=1460 THEN 'Liegewiese'
		WHEN bauwerksfunktion=1470 THEN 'Sprungschanze'
		WHEN bauwerksfunktion=1510 THEN 'Wildgehege'
		WHEN bauwerksfunktion=1450 THEN
			coalesce(
				t.schriftinhalt,
				(select v from alkis_wertearten where element='ax_bauwerkoderanlagefuersportfreizeitunderholung' AND bezeichnung='bauwerksfunktion' AND k=bauwerksfunktion::text)
			)
		WHEN o.gml_id LIKE 'DERP%' AND bauwerksfunktion=1410 THEN
			coalesce(
				t.schriftinhalt,
				'Sportplatz'
			)
		END AS text,
		coalesce(t.signaturnummer,'4100') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_bauwerkoderanlagefuersportfreizeitunderholung o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='BWF' AND t.endet IS NULL
	WHERE o.endet IS NULL
 ) AS o WHERE NOT text IS NULL;

-- Bauwerk oder Anlage für Sport, Freizeit und Erholung, Symbole
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	gml_id,
	'Sport und Freizeit' AS thema,
	'ax_bauwerkoderanlagefuersportfreizeitunderholung' AS layer,
	st_multi(point),
	drehwinkel,
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		coalesce(p.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(p.drehwinkel,0) AS drehwinkel,
		coalesce(
			p.signaturnummer,
			CASE
			WHEN bauwerksfunktion=1480 THEN '3524'
			WHEN bauwerksfunktion=1490 THEN '3525'
			END
		) AS signaturnummer,
		coalesce(p.advstandardmodell||p.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_bauwerkoderanlagefuersportfreizeitunderholung o
	LEFT OUTER JOIN ap_ppo p ON ARRAY[o.gml_id] <@ p.dientzurdarstellungvon AND p.art='BWF' AND p.endet IS NULL
	WHERE o.endet IS NULL
) AS o WHERE NOT signaturnummer IS NULL;

-- Bauwerk oder Anlage für Sport, Freizeit und Erholung, Name
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Sport und Freizeit' AS thema,
	'ax_bauwerkoderanlagefuersportfreizeitunderholung' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
	modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(t.schriftinhalt,o.name) AS text,
		coalesce(t.signaturnummer,'4141') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_bauwerkoderanlagefuersportfreizeitunderholung o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='NAM' AND t.endet IS NULL
	WHERE o.endet IS NULL AND NOT name IS NULL
) AS n;

-- Bauwerk oder Anlage für Sport, Freizeit und Erholung, Sportart
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Sport und Freizeit' AS thema,
	'ax_bauwerkoderanlagefuersportfreizeitunderholung' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		CASE
		WHEN sportart IN (1010,1020) THEN 'Sportplatz'
		WHEN sportart=1030           THEN 'Tennisplatz'
		WHEN sportart=1040           THEN 'Reitplatz'
		WHEN sportart=1060           THEN 'Skisportanlage'
		WHEN sportart=1070           THEN 'Eis-, Rollschuhbahn'
		WHEN sportart=1071           THEN 'Eisbahn'
		WHEN sportart=1072           THEN 'Rollschuhbahn'
		WHEN sportart=1090           THEN 'Motorrennbahn'
		WHEN sportart=1100           THEN 'Radrennbahn'
		WHEN sportart=1110           THEN 'Pferderennbahn'
		END AS text,
		coalesce(t.signaturnummer,'4100') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_bauwerkoderanlagefuersportfreizeitunderholung o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='SPO' AND t.endet IS NULL
	WHERE o.endet IS NULL AND NOT sportart IS NULL
) AS n WHERE NOT text IS NULL;

-- Bauwerk oder Anlage für Sport, Freizeit und Erholung, Symbole
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	o.gml_id,
	'Sport und Freizeit' AS thema,
	'ax_bauwerkoderanlagefuersportfreizeitunderholung' AS layer,
	st_multi(coalesce(p.wkb_geometry,st_centroid(o.wkb_geometry))) AS point,
	coalesce(p.drehwinkel,0) AS drehwinkel,
	coalesce(p.signaturnummer,'3409') AS signaturnummer,
	coalesce(p.advstandardmodell||p.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM ax_bauwerkoderanlagefuersportfreizeitunderholung o
LEFT OUTER JOIN ap_ppo p ON ARRAY[o.gml_id] <@ p.dientzurdarstellungvon AND p.art='SPO' AND p.endet IS NULL
WHERE o.endet IS NULL AND sportart=1080;


--
-- Historisches Bauwerk oder historische Einrichtung (51007)
--


-- Historisches Bauwerk oder historische Einrichtung, Flächen
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	'Gebäude' AS thema,
	'ax_historischesbauwerkoderhistorischeeinrichtung' AS layer,
	st_multi(wkb_geometry) AS polygon,
	CASE
	WHEN archaeologischertyp IN (1000,1100,1020,1100,1110,1200,1210,9999) THEN 1330
	WHEN archaeologischertyp IN (1400,1410,1420,1430)                     THEN 1317
	WHEN archaeologischertyp IN (1500,1510,1520)                          THEN 1305
	END AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ax_historischesbauwerkoderhistorischeeinrichtung
WHERE geometrytype(wkb_geometry) IN ('POLYGON','MULTIPOLYGON') AND endet IS NULL;

-- Historisches Bauwerk oder historische Einrichtung, Linien
INSERT INTO po_lines(gml_id,thema,layer,line,signaturnummer,modell)
SELECT
	gml_id,
	'Gebäude' AS thema,
	'ax_historischesbauwerkoderhistorischeeinrichtung' AS layer,
	st_multi(line),
	signaturnummer,
	modell
FROM (
	SELECT
		gml_id,
		wkb_geometry AS line,
		CASE
		WHEN archaeologischertyp IN (1500,1520) THEN 2510
		WHEN archaeologischertyp=1510           THEN 2510
		END AS signaturnummer,
		advstandardmodell||sonstigesmodell AS modell
	FROM ax_historischesbauwerkoderhistorischeeinrichtung
	WHERE geometrytype(wkb_geometry) IN ('LINESTRING','MULTILINESTRING') AND endet IS NULL
) AS o WHERE NOT signaturnummer IS NULL;


-- Historisches Bauwerk oder historische Einrichtung, Symbol
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	gml_id,
	'Gebäude' AS thema,
	'ax_historischesbauwerkoderhistorischeeinrichtung' AS layer,
	point, drehwinkel, signaturnummer, modell
FROM (
	SELECT
		o.gml_id,
		st_multi(coalesce(
			p.wkb_geometry,
			CASE
			WHEN geometrytype(o.wkb_geometry) IN ('POINT','MULTIPOINT')     THEN o.wkb_geometry
			WHEN geometrytype(o.wkb_geometry) IN ('POLYGON','MULTIPOLYGON') THEN st_centroid(o.wkb_geometry)
			END
		)) AS point,
		coalesce(p.drehwinkel,0) AS drehwinkel,
		coalesce(
			p.signaturnummer,
			CASE
			WHEN archaeologischertyp=1010 THEN '3526'
			WHEN archaeologischertyp=1020 THEN '3527'
			WHEN archaeologischertyp=1300 THEN '3528'
			END
		) AS signaturnummer,
		coalesce(p.advstandardmodell||p.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_historischesbauwerkoderhistorischeeinrichtung o
	LEFT OUTER JOIN ap_ppo p ON ARRAY[o.gml_id] <@ p.dientzurdarstellungvon AND p.art='ATP' AND p.endet IS NULL
	WHERE o.endet IS NULL
) AS o WHERE NOT signaturnummer IS NULL;

-- Historisches Bauwerk oder historische Einrichtung, Texte
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Gebäude' AS thema,
	'ax_historischesbauwerkoderhistorischeeinrichtung' AS layer,
	point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		coalesce(
			t.wkb_geometry,
			CASE
			WHEN geometrytype(o.wkb_geometry) IN ('POINT','MULTIPOINT')     THEN o.wkb_geometry
			WHEN geometrytype(o.wkb_geometry) IN ('POLYGON','MULTIPOLYGON') THEN st_centroid(o.wkb_geometry)
			WHEN geometrytype(o.wkb_geometry)='LINESTRING'                  THEN st_lineinterpolatepoint(o.wkb_geometry,0.5)
			END
		) AS point,
		CASE
		WHEN
			archaeologischertyp IN (1000,1110)
			OR (archaeologischertyp=1420 AND coalesce(name,n.schriftinhalt) IS NULL)
		THEN
			(select v from alkis_wertearten where element='ax_historischesbauwerkoderhistorischeeinrichtung' AND bezeichnung='archaeologischertyp' AND k=archaeologischertyp::text)
		WHEN archaeologischertyp=1100 THEN
			coalesce(t.schriftinhalt, 'Historische Wasserleitung')
		WHEN archaeologischertyp=1210 THEN
			coalesce(t.schriftinhalt, 'Römischer Wachturm')
		WHEN archaeologischertyp=1400 AND coalesce(name,n.schriftinhalt) IS NULL THEN
			'Ruine'
		WHEN archaeologischertyp IN (1200,1410,1500,1510,1520)
			OR (archaeologischertyp=1430 AND coalesce(name,n.schriftinhalt) IS NULL)
		THEN
			coalesce(
				t.schriftinhalt,
				(select v from alkis_wertearten where element='ax_historischesbauwerkoderhistorischeeinrichtung' AND bezeichnung='archaeologischertyp' AND k=archaeologischertyp::text)
			)
		END AS text,
		coalesce(t.signaturnummer,n.signaturnummer,'4070') AS signaturnummer,
		t.drehwinkel,t.horizontaleausrichtung,t.vertikaleausrichtung,t.skalierung,t.fontsperrung,
		coalesce(
			t.advstandardmodell||t.sonstigesmodell||n.advstandardmodell||n.sonstigesmodell,
			o.advstandardmodell||o.sonstigesmodell
		) AS modell
	FROM ax_historischesbauwerkoderhistorischeeinrichtung o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='ATP' AND t.endet IS NULL
	LEFT OUTER JOIN ap_pto n ON ARRAY[o.gml_id] <@ n.dientzurdarstellungvon AND n.art='NAM' AND n.endet IS NULL
	WHERE o.endet IS NULL
) AS o WHERE NOT text IS NULL;

-- Historisches Bauwerk oder historische Einrichtung, Name
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Gebäude' AS thema,
	'ax_historischesbauwerkoderhistorischeeinrichtung' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(t.schriftinhalt,o.name) AS text,
		coalesce(t.signaturnummer,'4074') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_historischesbauwerkoderhistorischeeinrichtung o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='NAM' AND t.endet IS NULL
	WHERE o.endet IS NULL AND NOT name IS NULL
) AS n;


--
-- Heilquelle (51008)
--

-- Symbole
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	gml_id,
	'Gewässer' AS thema,
	'ax_heilquellegasquelle' AS layer,
	st_multi(wkb_geometry),
	0 AS drehwinkel,
	3529 AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ax_heilquellegasquelle;

-- Texte
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Gewässer' AS thema,
	'ax_heilquellegasquelle' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,o.wkb_geometry) AS point,
		CASE
		WHEN o.art=4010 THEN 'Hqu'
		WHEN o.art=4020 THEN 'Gqu'
		END AS text,
		coalesce(t.signaturnummer,'4073') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_heilquellegasquelle o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='ART' AND t.endet IS NULL
	WHERE o.endet IS NULL
) AS n;

-- Namen
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Gewässer' AS thema,
	'ax_heilquellegasquelle' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(t.schriftinhalt,o.name) AS text,
		coalesce(t.signaturnummer,'4108') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_heilquellegasquelle o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='NAM' AND t.endet IS NULL
	WHERE o.endet IS NULL AND NOT name IS NULL
) AS n;


--
-- Sonstiges Bauwerk oder sonstige Einrichtung (51009)
--

-- Flächen
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	'Gebäude' AS thema,
	'ax_sonstigesbauwerkodersonstigeeinrichtung' AS layer,
	polygon,
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		st_multi(wkb_geometry) AS polygon,
		CASE
		WHEN bauwerksfunktion IN (1610,1611)                          THEN 20311304
		WHEN bauwerksfunktion IN (1620,1621,1622,1650,1670,1700,1720) THEN     1305
		WHEN bauwerksfunktion IN (1750,9999)                          THEN     1330
		WHEN bauwerksfunktion IN (1780,1782)                          THEN     1525
		END AS signaturnummer,
		advstandardmodell||sonstigesmodell AS modell
	FROM ax_sonstigesbauwerkodersonstigeeinrichtung o
	WHERE geometrytype(wkb_geometry) IN ('POLYGON','MULTIPOLYGON') AND endet IS NULL
) AS o WHERE NOT signaturnummer IS NULL;

-- Linien
INSERT INTO po_lines(gml_id,thema,layer,line,signaturnummer,modell)
SELECT
	gml_id,
	'Gebäude' AS thema,
	'ax_sonstigesbauwerkodersonstigeeinrichtung' AS layer,
	st_multi(line),
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		wkb_geometry AS line,
		CASE
		WHEN bauwerksfunktion=1630                               THEN 2507
		WHEN bauwerksfunktion IN (1701,1702,1703,1721,1722,1723) THEN 2510
		WHEN bauwerksfunktion=1740                               THEN 2507 -- 25073580
		WHEN bauwerksfunktion=1790                               THEN 2519
		WHEN bauwerksfunktion=1791                               THEN 2002
		END AS signaturnummer,
		advstandardmodell||sonstigesmodell AS modell
	FROM ax_sonstigesbauwerkodersonstigeeinrichtung o
	WHERE geometrytype(wkb_geometry) IN ('LINESTRING','MULTILINESTRING') AND endet IS NULL
) AS o WHERE NOT signaturnummer IS NULL;

-- Symbole
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	gml_id,
	'Gebäude' AS thema,
	'ax_sonstigesbauwerkodersonstigeeinrichtung' AS layer,
	st_multi(point),
	drehwinkel,
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		coalesce(
			p.wkb_geometry,
			CASE
			WHEN geometrytype(o.wkb_geometry) IN ('POINT','MULTIPOINT')     THEN o.wkb_geometry
			WHEN geometrytype(o.wkb_geometry) IN ('POLYGON','MULTIPOLYGON') THEN st_centroid(o.wkb_geometry)
			END
		) AS point,
		coalesce(p.drehwinkel,0) AS drehwinkel,
		coalesce(
			p.signaturnummer,
			CASE
			WHEN bauwerksfunktion=1640                                                            THEN '3531'
			WHEN bauwerksfunktion=1750                                                            THEN '3532'
			WHEN bauwerksfunktion=1760                                                            THEN '3533'
			WHEN bauwerksfunktion=1761                                                            THEN '3534'
			WHEN bauwerksfunktion IN (1762,1763)                                                  THEN '3535'
			WHEN bauwerksfunktion=1770                                                            THEN '3536'
			WHEN bauwerksfunktion=1780 AND geometrytype(o.wkb_geometry) IN ('POINT','MULTIPOINT') THEN '3529'
			WHEN bauwerksfunktion=1781                                                            THEN '3537'
			WHEN bauwerksfunktion=1782                                                            THEN '3539'
			WHEN bauwerksfunktion=1783                                                            THEN '3540'
			END
		) AS signaturnummer,
		coalesce(p.advstandardmodell||p.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_sonstigesbauwerkodersonstigeeinrichtung o
	LEFT OUTER JOIN ap_ppo p ON ARRAY[o.gml_id] <@ p.dientzurdarstellungvon AND p.art='BWF' AND p.endet IS NULL
	WHERE o.endet IS NULL
) AS o WHERE NOT signaturnummer IS NULL;

-- Texte
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Gebäude' AS thema,
	'ax_sonstigesbauwerkodersonstigeeinrichtung' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		coalesce(
			t.wkb_geometry,
			CASE
			WHEN geometrytype(o.wkb_geometry) IN ('POINT','MULTIPOINT')     THEN o.wkb_geometry
			WHEN geometrytype(o.wkb_geometry) IN ('POLYGON','MULTIPOLYGON') THEN st_centroid(o.wkb_geometry)
			WHEN geometrytype(o.wkb_geometry)='LINESTRING'                  THEN st_lineinterpolatepoint(o.wkb_geometry,0.5)
			END
		) AS point,
		CASE
		WHEN bauwerksfunktion IN (1650,1670) THEN
			coalesce(
				t.schriftinhalt,
				(select v from alkis_wertearten where element='ax_sonstigesbauwerkodersonstigeeinrichtung' AND bezeichnung='bauwerksfunktion' AND k=bauwerksfunktion::text)
			)
		END AS text,
		coalesce(
			t.signaturnummer,
			CASE
			WHEN bauwerksfunktion IN (1650,1670) THEN '4070'
			WHEN bauwerksfunktion IN (1780)      THEN '4073'
			END
		) AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_sonstigesbauwerkodersonstigeeinrichtung o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='BWF' AND t.endet IS NULL
	WHERE o.endet IS NULL
) AS n WHERE NOT text IS NULL AND NOT signaturnummer IS NULL;

-- Namen
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Gebäude' AS thema,
	'ax_sonstigesbauwerkodersonstigeeinrichtung' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		coalesce(
			t.wkb_geometry,
			CASE
			WHEN geometrytype(o.wkb_geometry) IN ('POINT','MULTIPOINT')     THEN o.wkb_geometry
			WHEN geometrytype(o.wkb_geometry) IN ('POLYGON','MULTIPOLYGON') THEN st_centroid(o.wkb_geometry)
			WHEN geometrytype(o.wkb_geometry)='LINESTRING'                  THEN st_lineinterpolatepoint(o.wkb_geometry,0.5)
			END
		) AS point,
		coalesce(t.schriftinhalt,o.name) AS text,
		coalesce(t.signaturnummer,'4107') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_sonstigesbauwerkodersonstigeeinrichtung o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='NAM' AND t.endet IS NULL
	WHERE o.endet IS NULL AND NOT name IS NULL
) AS n;


--
-- Einrichtung in öffentlichen Bereichen (51010)
-- TODO: 1500 Bahnschranke?
--

-- Flächen
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	'Verkehr' AS thema,
	'ax_einrichtunginoeffentlichenbereichen' AS layer,
	polygon,
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		st_multi(wkb_geometry) AS polygon,
		CASE
		WHEN o.art=1110 THEN 1330
		WHEN o.art=1510 THEN 2521
		WHEN o.art=9999 THEN 1330
		END AS signaturnummer,
		advstandardmodell||sonstigesmodell AS modell
	FROM ax_einrichtunginoeffentlichenbereichen o
	WHERE geometrytype(wkb_geometry) IN ('POLYGON','MULTIPOLYGON') AND endet IS NULL
) AS o WHERE NOT signaturnummer IS NULL;

-- Punktsymbole
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	gml_id,
	'Verkehr' AS thema,
	'ax_einrichtunginoeffentlichenbereichen' AS layer,
	st_multi(wkb_geometry) AS point,
	0 AS drehwinkel,
	CASE
	WHEN art=1100                THEN 3541
	WHEN art=1110                THEN 3542
	WHEN art=1120                THEN 3544
	WHEN art=1130                THEN 3545
	WHEN art=1140                THEN 3546
	WHEN art=1150                THEN 3547
	WHEN art=1200                THEN 3548
	WHEN art=1300                THEN 3549
	WHEN art=1310                THEN 3550
	WHEN art=1320                THEN 3551
	WHEN art=1330                THEN 3552
	WHEN art=1340                THEN 3553
	WHEN art=1350                THEN 3554
	WHEN art IN (1400,1410,1420) THEN 3556
	WHEN art=1600                THEN 3557
	WHEN art=1610                THEN 3558
	WHEN art=1620                THEN 3559
	WHEN art=1630                THEN 3560
	WHEN art=1640                THEN 3561
	WHEN art=1650                THEN 3562
	WHEN art=1700                THEN 3563
	WHEN art=1710                THEN 3564
	WHEN art=1910                THEN 3565
	WHEN art=2100                THEN 3566
	WHEN art=2200                THEN 3567
	WHEN art=2300                THEN 3568
	WHEN art=2400                THEN 3569
	WHEN art=2500                THEN 3570
	WHEN art=2600                THEN 3571
	END AS signaturnummer,
	advstandardmodell||sonstigesmodell AS modell
FROM ax_einrichtunginoeffentlichenbereichen
WHERE geometrytype(wkb_geometry) IN ('POINT','MULTIPOINT') AND endet IS NULL;

-- Flächensymbole
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	gml_id,
	'Verkehr' AS thema,
	'ax_einrichtunginoeffentlichenbereichen' AS layer,
	st_multi(point),
	drehwinkel,
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		coalesce(
			p.wkb_geometry,
			st_centroid(o.wkb_geometry)
		) AS point,
		coalesce(p.drehwinkel,0) AS drehwinkel,
		coalesce(
			p.signaturnummer,
			CASE
			WHEN o.art=1110 THEN '3543'
			WHEN o.art=2200 THEN '3567'
			END
		) AS signaturnummer,
		coalesce(p.advstandardmodell||p.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_einrichtunginoeffentlichenbereichen o
	LEFT OUTER JOIN ap_ppo p ON ARRAY[o.gml_id] <@ p.dientzurdarstellungvon AND p.art='ART' AND p.endet IS NULL
	WHERE o.endet IS NULL AND geometrytype(o.wkb_geometry) IN ('POLYGON','MULTIPOLYGON')
) AS o WHERE NOT signaturnummer IS NULL;

-- Linien
INSERT INTO po_lines(gml_id,thema,layer,line,signaturnummer,modell)
SELECT
	gml_id,
	'Verkehr' AS thema,
	'ax_einrichtunginoeffentlichenbereichen' AS layer,
	st_multi(line),
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		wkb_geometry AS line,
		CASE WHEN o.art=1650 THEN 2002 END AS signaturnummer,
		advstandardmodell||sonstigesmodell AS modell
	FROM ax_einrichtunginoeffentlichenbereichen o
	WHERE geometrytype(wkb_geometry) IN ('LINESTRING','MULTILINESTRING') AND endet IS NULL
) AS o WHERE NOT signaturnummer IS NULL;

-- Texte Ortsdurchfahrtstein
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	o.gml_id,
	'Verkehr' AS thema,
	'ax_einrichtunginoeffentlichenbereichen' AS layer,
	coalesce(t.wkb_geometry,o.wkb_geometry) AS point,
	'OD' AS text,
	coalesce(t.signaturnummer,'4070') AS signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
	coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM ax_einrichtunginoeffentlichenbereichen o
LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='ART' AND t.endet IS NULL
WHERE o.endet IS NULL AND o.art=1420;

-- Texte
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	o.gml_id,
	'Verkehr' AS thema,
	'ax_einrichtunginoeffentlichenbereichen' AS layer,
	coalesce(t.wkb_geometry,o.wkb_geometry) AS point,
	kilometerangabe AS text,
	coalesce(t.signaturnummer,'4070') AS signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
	coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM ax_einrichtunginoeffentlichenbereichen o
LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='KMA' AND t.endet IS NULL
WHERE o.endet IS NULL AND NOT kilometerangabe IS NULL;


--
-- Bauwerk im Verkehrsbereich (53001)
-- TODO: Ausrichtung Symbol am Steg 1820?
--

-- Flächen
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	'Verkehr' AS thema,
	'ax_bauwerkimverkehrsbereich' AS layer,
	polygon,
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		st_multi(wkb_geometry) AS polygon,
		CASE
		WHEN bauwerksfunktion IN (1800,1801,1802,1803,1804,1805,1806,1807,1808,1810,1830) THEN 1530
		WHEN bauwerksfunktion=1840                                                        THEN 1531
		WHEN bauwerksfunktion=1850                                                        THEN 1532
		WHEN bauwerksfunktion=1870                                                        THEN 1533
		WHEN bauwerksfunktion=1880                                                        THEN 1534
		WHEN bauwerksfunktion=1890                                                        THEN 1535
		WHEN bauwerksfunktion=1900                                                        THEN 2305
		WHEN bauwerksfunktion=9999                                                        THEN 1536
		END AS signaturnummer,
		advstandardmodell||sonstigesmodell AS modell
	FROM ax_bauwerkimverkehrsbereich o
	WHERE geometrytype(wkb_geometry) IN ('POLYGON','MULTIPOLYGON') AND endet IS NULL
) AS o WHERE NOT signaturnummer IS NULL;

-- Linien
INSERT INTO po_lines(gml_id,thema,layer,line,signaturnummer,modell)
SELECT
	gml_id,
	'Verkehr' AS thema,
	'ax_bauwerkimverkehrsbereich' AS layer,
	st_multi(line),
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		wkb_geometry AS line,
		CASE
		WHEN bauwerksfunktion=1820 THEN 2530
		WHEN bauwerksfunktion=1845 THEN 2533
		WHEN bauwerksfunktion=1900 THEN 2505
		END AS signaturnummer,
		advstandardmodell||sonstigesmodell AS modell
	FROM ax_bauwerkimverkehrsbereich o
	WHERE geometrytype(wkb_geometry) IN ('LINESTRING','MULTILINESTRING') AND endet IS NULL
) AS o WHERE NOT signaturnummer IS NULL;

-- Punkte
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	gml_id,
	'Verkehr' AS thema,
	'ax_bauwerkimverkehrsbereich' AS layer,
	st_multi(point),
	drehwinkel,
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		wkb_geometry AS point,
		0 AS drehwinkel,
		CASE
		WHEN bauwerksfunktion=1840 THEN 3572
		END AS signaturnummer,
		advstandardmodell||sonstigesmodell AS modell
	FROM ax_bauwerkimverkehrsbereich o
	WHERE geometrytype(wkb_geometry) IN ('POINT','MULTIPOINT') AND endet IS NULL
) AS o WHERE NOT signaturnummer IS NULL;

-- Schutzgalerieanschrieb
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Verkehr' AS thema,
	'ax_bauwerkimverkehrsbereich' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(t.schriftinhalt,'Schutzgalerie') AS text,
		coalesce(t.signaturnummer,'4070') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_bauwerkimverkehrsbereich o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='BWF' AND t.endet IS NULL
	WHERE o.endet IS NULL AND bauwerksfunktion=1880
) AS n;

-- Anflugbefeuerung
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	o.gml_id,
	'Verkehr' AS thema,
	'ax_bauwerkimverkehrsbereich' AS layer,
	st_multi(coalesce(p.wkb_geometry,o.wkb_geometry)) AS point,
	coalesce(p.drehwinkel,0) AS drehwinkel,
	coalesce(p.signaturnummer,'3573') AS signaturnummer,
	coalesce(p.advstandardmodell||p.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM ax_bauwerkimverkehrsbereich o
LEFT OUTER JOIN ap_ppo p ON ARRAY[o.gml_id] <@ p.dientzurdarstellungvon AND p.art='BWF' AND p.endet IS NULL
WHERE o.endet IS NULL AND bauwerksfunktion=1910;

-- Namen
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Verkehr' AS thema,
	'ax_bauwerkimverkehrsbereich' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(t.schriftinhalt,o.name) AS text,
		coalesce(t.signaturnummer,'4107') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_bauwerkimverkehrsbereich o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='NAM' AND t.endet IS NULL
	WHERE o.endet IS NULL AND NOT name IS NULL
) AS n;

-- Außer Betrieb
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Verkehr' AS thema,
	'ax_bauwerkimverkehrsbereich' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		'(außer Betrieb)'::text AS text,
		coalesce(t.signaturnummer,'4070') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_bauwerkimverkehrsbereich o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='NAM' AND t.endet IS NULL
	WHERE o.endet IS NULL AND zustand=2100
) AS n;


--
-- Straßenverkehrsanlage (53002)
--

-- Flächen
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	'Verkehr' AS thema,
	'ax_strassenverkehrsanlage' AS layer,
	polygon,
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		st_multi(wkb_geometry) AS polygon,
		CASE
		WHEN o.art=1000 THEN 1540
		WHEN o.art=2000 THEN 1320
		WHEN o.art=9999 THEN 1548
		END AS signaturnummer,
		advstandardmodell||sonstigesmodell AS modell
	FROM ax_strassenverkehrsanlage o
	WHERE geometrytype(wkb_geometry) IN ('POLYGON','MULTIPOLYGON') AND endet IS NULL
) AS o WHERE NOT signaturnummer IS NULL;

-- Linien
INSERT INTO po_lines(gml_id,thema,layer,line,signaturnummer,modell)
SELECT
	gml_id,
	'Verkehr' AS thema,
	'ax_strassenverkehrsanlage' AS layer,
	st_multi(line),
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		wkb_geometry AS line,
		CASE
		WHEN o.art=1010 THEN 2527
		WHEN o.art=1011 THEN 2506
		END AS signaturnummer,
		advstandardmodell||sonstigesmodell AS modell
	FROM ax_strassenverkehrsanlage o
	WHERE geometrytype(wkb_geometry) IN ('LINESTRING','MULTILINESTRING') AND endet IS NULL
) AS o WHERE NOT signaturnummer IS NULL;

-- Bezeichnungen
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	o.gml_id,
	'Verkehr' AS thema,
	'ax_strassenverkehrsanlage' AS layer,
	st_multi(coalesce(p.wkb_geometry,st_centroid(o.wkb_geometry))) AS point,
	coalesce(p.drehwinkel,0) AS drehwinkel,
	coalesce(p.signaturnummer,'3574') AS signaturnummer,
	coalesce(p.advstandardmodell||p.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM ax_strassenverkehrsanlage o
LEFT OUTER JOIN ap_ppo p ON ARRAY[o.gml_id] <@ p.dientzurdarstellungvon AND p.art='BEZ' AND p.endet IS NULL
WHERE o.endet IS NULL AND NOT bezeichnung IS NULL;

INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	o.gml_id,
	'Verkehr' AS thema,
	'ax_strassenverkehrsanlage' AS layer,
	coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
	bezeichnung AS text,
	coalesce(t.signaturnummer,'4052') AS signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
	coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM ax_strassenverkehrsanlage o
LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='BEZ_TEXT' AND t.endet IS NULL
WHERE o.endet IS NULL AND NOT bezeichnung IS NULL;

-- Furt Texte
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Verkehr' AS thema,
	'ax_strassenverkehrsanlage' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		(select v from alkis_wertearten where element='ax_strassenverkehrsanlage' AND bezeichnung='art' AND k=o.art::text) AS text,
		coalesce(t.signaturnummer,'4100') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_strassenverkehrsanlage o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='ART' AND t.endet IS NULL
	WHERE o.endet IS NULL AND o.art=2000
) AS n WHERE NOT text IS NULL;

-- Namen
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Verkehr' AS thema,
	'ax_strassenverkehrsanlage' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(t.schriftinhalt,name) AS text,
		coalesce(t.signaturnummer,'4141') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_strassenverkehrsanlage o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='NAM' AND t.endet IS NULL
	WHERE o.endet IS NULL AND NOT name IS NULL OR NOT t.schriftinhalt IS NULL
) AS n WHERE NOT text IS NULL;

--
-- Weg, Pfad, Steig (53003)
--

-- Linien
INSERT INTO po_lines(gml_id,thema,layer,line,signaturnummer,modell)
SELECT
	gml_id,
	'Verkehr' AS thema,
	'ax_wegpfadsteig' AS layer,
	st_multi(line),
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		wkb_geometry AS line,
		CASE
		WHEN o.art IN (1103,1105,1106,1107,1110,1111) THEN 2535
		WHEN o.art=1108                               THEN 2537
		WHEN o.art=1109                               THEN 2539
		END AS signaturnummer,
		advstandardmodell||sonstigesmodell AS modell
	FROM ax_wegpfadsteig o
	WHERE geometrytype(wkb_geometry) IN ('LINESTRING','MULTILINESTRING') AND endet IS NULL
) AS o WHERE NOT signaturnummer IS NULL;

-- Flächen
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	'Verkehr' AS thema,
	'ax_wegpfadsteig' AS layer,
	polygon,
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		st_multi(wkb_geometry) AS polygon,
		CASE
		WHEN o.art IN (1103,1105,1106,1107,1110,1111) THEN 1542
		WHEN o.art=1108                               THEN 1543
		END AS signaturnummer,
		advstandardmodell||sonstigesmodell AS modell
	FROM ax_wegpfadsteig o
	WHERE geometrytype(wkb_geometry) IN ('POLYGON','MULTIPOLYGON') AND endet IS NULL
) AS o WHERE NOT signaturnummer IS NULL;

-- Symbole
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	gml_id,
	'Verkehr' AS thema,
	'ax_wegpfadsteig' AS layer,
	st_multi(point),
	drehwinkel,
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		coalesce(
			p.wkb_geometry,
			CASE
			WHEN geometrytype(o.wkb_geometry) IN ('POINT','MULTIPOINT')     THEN o.wkb_geometry
			WHEN geometrytype(o.wkb_geometry) IN ('POLYGON','MULTIPOLYGON') THEN st_centroid(o.wkb_geometry)
			WHEN geometrytype(o.wkb_geometry)='LINESTRING'                  THEN st_lineinterpolatepoint(o.wkb_geometry,0.5)
			END
		) AS point,
		coalesce(p.drehwinkel,0) AS drehwinkel,
		coalesce(
			p.signaturnummer,
			CASE
			WHEN o.art=1106 THEN '3426'
			WHEN o.art=1107 THEN '3420'
			WHEN o.art=1110 THEN '3428'
			WHEN o.art=1111 THEN '3576'
			END
		) AS signaturnummer,
		coalesce(p.advstandardmodell||p.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_wegpfadsteig o
	LEFT OUTER JOIN ap_ppo p ON ARRAY[o.gml_id] <@ p.dientzurdarstellungvon AND p.art='ART' AND p.endet IS NULL
	WHERE o.endet IS NULL
) AS o WHERE NOT signaturnummer IS NULL;

-- Namen
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Verkehr' AS thema,
	'ax_wegpfadsteig' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(t.schriftinhalt,name) AS text,
		coalesce(t.signaturnummer,'4109') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_wegpfadsteig o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='NAM' AND t.endet IS NULL
	WHERE o.endet IS NULL AND (NOT name IS NULL OR NOT t.schriftinhalt IS NULL)
) AS n WHERE NOT text IS NULL;

-- Name
INSERT INTO po_labels(gml_id,thema,layer,line,text,signaturnummer,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Verkehr' AS thema,
	'ax_wegpfadsteig' AS layer,
	line,
	text,
	4109 AS signaturnummer,
	horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		t.wkb_geometry AS line,
		coalesce(t.schriftinhalt,name) AS text,
		horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_wegpfadsteig o
	LEFT OUTER JOIN ap_lto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='NAM' AND t.endet IS NULL
	WHERE o.endet IS NULL AND (NOT name IS NULL OR NOT t.schriftinhalt IS NULL)
) AS n WHERE NOT text IS NULL;


--
-- Bahnverkehrsanlage (53004)
--

-- Bauwerksfunktion, Anschrieb
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Verkehr' AS thema,
	'ax_bahnverkehrsanlage' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		coalesce(
			t.wkb_geometry,
			CASE
			WHEN geometrytype(o.wkb_geometry) IN ('POINT','MULTIPOINT')     THEN o.wkb_geometry
			WHEN geometrytype(o.wkb_geometry) IN ('POLYGON','MULTIPOLYGON') THEN st_centroid(o.wkb_geometry)
			WHEN geometrytype(o.wkb_geometry)='LINESTRING'                  THEN st_lineinterpolatepoint(o.wkb_geometry,0.5)
			END
		) AS point,
		CASE
		WHEN bahnhofskategorie=1010 THEN
			CASE
			WHEN name IS NULL AND n.schriftinhalt IS NULL THEN
				-- WHEN bahnkategorie IN (1100,1102,1104,1200,1201,1202,1300,1301,1400,1500,1600,9999) THEN 'Bahnhof'
				'Bahnhof'
			ELSE
				coalesce(n.schriftinhalt,name)
			END
		WHEN bahnhofskategorie IN (1020,1030) THEN
			coalesce(n.schriftinhalt,name)
		END AS text,
		coalesce(
			t.signaturnummer,
			CASE
			WHEN bahnhofskategorie=1010 THEN
				CASE
				WHEN name IS NULL AND n.schriftinhalt IS NULL THEN '4141' ELSE '4140' END
			ELSE
				'4107'
			END
		) AS signaturnummer,
		CASE WHEN name IS NULL AND n.schriftinhalt IS NULL THEN t.drehwinkel ELSE n.drehwinkel END AS drehwinkel,
		CASE WHEN name IS NULL AND n.horizontaleausrichtung IS NULL THEN t.horizontaleausrichtung ELSE n.horizontaleausrichtung END AS horizontaleausrichtung,
		CASE WHEN name IS NULL AND n.vertikaleausrichtung IS NULL THEN t.vertikaleausrichtung ELSE n.vertikaleausrichtung END AS vertikaleausrichtung,
		CASE WHEN name IS NULL AND n.skalierung IS NULL THEN t.skalierung ELSE n.skalierung END AS skalierung,
		CASE WHEN name IS NULL AND n.fontsperrung IS NULL THEN t.fontsperrung ELSE n.fontsperrung END AS fontsperrung,
		coalesce(
			t.advstandardmodell||t.sonstigesmodell||n.advstandardmodell||n.sonstigesmodell,
			o.advstandardmodell||o.sonstigesmodell
		) AS modell
	FROM ax_bahnverkehrsanlage o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='BFK' AND t.endet IS NULL
	LEFT OUTER JOIN ap_pto n ON ARRAY[o.gml_id] <@ n.dientzurdarstellungvon AND n.art='NAM' AND n.endet IS NULL
	WHERE o.endet IS NULL
) AS n WHERE NOT text IS NULL;

-- Flächen
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	'Verkehr' AS thema,
	'ax_bahnverkehrsanlage' AS layer,
	st_multi(wkb_geometry) AS polygon,
	1541 AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ax_bahnverkehrsanlage o
WHERE geometrytype(wkb_geometry) IN ('POLYGON','MULTIPOLYGON');

-- Symbole
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	gml_id,
	'Verkehr' AS thema,
	'ax_bahnverkehrsanlage' AS layer,
	st_multi(point),
	drehwinkel,
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		coalesce(
			p.wkb_geometry,
			CASE
			WHEN geometrytype(o.wkb_geometry) IN ('POINT','MULTIPOINT')     THEN o.wkb_geometry
			WHEN geometrytype(o.wkb_geometry) IN ('POLYGON','MULTIPOLYGON') THEN st_centroid(o.wkb_geometry)
			WHEN geometrytype(o.wkb_geometry)='LINESTRING'                  THEN st_lineinterpolatepoint(o.wkb_geometry,0.5) END
		) AS point,
		coalesce(p.drehwinkel,0) AS drehwinkel,
		coalesce(
			p.signaturnummer,
			CASE
			WHEN bahnhofskategorie=1010 THEN
				CASE
				WHEN bahnkategorie=1104 THEN '3330'
				WHEN bahnkategorie=1200 THEN '3343'
				WHEN bahnkategorie=1201 THEN '3554'
				WHEN bahnkategorie=1202 THEN '3328'
				END
			WHEN bahnhofskategorie IN (1020,1030) THEN
				CASE
				WHEN bahnkategorie IN (1100,1102,1300,1301,1400,1500,1600,9999) THEN '3578'
				WHEN bahnkategorie=1104 THEN '3330'
				WHEN bahnkategorie=1200 THEN '3343'
				WHEN bahnkategorie=1201 THEN '3554'
				WHEN bahnkategorie=1202 THEN '3328'
				END
			END
		) AS signaturnummer,
		coalesce(p.advstandardmodell||p.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_bahnverkehrsanlage o
	LEFT OUTER JOIN ap_ppo p ON ARRAY[o.gml_id] <@ p.dientzurdarstellungvon AND p.art='BKT' AND p.endet IS NULL
	WHERE o.endet IS NULL
) AS o WHERE NOT signaturnummer IS NULL;



--
-- Seilbahn, Schwebebahn (53006)
--

INSERT INTO po_lines(gml_id,thema,layer,line,signaturnummer,modell)
SELECT
	gml_id,
	'Verkehr' AS thema,
	'ax_seilbahnschwebebahn' AS layer,
	st_multi(wkb_geometry) AS line,
	CASE
	WHEN bahnkategorie IN (2100,2200) THEN 20013642
	WHEN bahnkategorie IN (2300,2400) THEN 20013643
	WHEN bahnkategorie=2500           THEN 20013644
	WHEN bahnkategorie=2600           THEN 20013645
	END AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ax_seilbahnschwebebahn o
WHERE endet IS NULL;

-- Namen
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Verkehr' AS thema,
	'ax_seilbahnschwebebahn' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(t.signaturnummer,'4107') AS signaturnummer,
		coalesce(t.schriftinhalt,name) AS text,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_seilbahnschwebebahn o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='NAM' AND t.endet IS NULL
	WHERE o.endet IS NULL AND (NOT name IS NULL OR NOT t.schriftinhalt IS NULL)
) AS n WHERE NOT text IS NULL;

--
-- Gleis (55006)
--

-- Drehscheibe, Fläche
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	'Verkehr' AS thema,
	'ax_gleis' AS layer,
	st_multi(wkb_geometry) AS polygon,
	1541 AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ax_gleis o
WHERE geometrytype(wkb_geometry) IN ('POLYGON','MULTIPOLYGON') AND NOT bahnkategorie IS NULL AND o.art=1200 AND endet IS NULL;

-- Drehscheibe, Symbol
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	o.gml_id,
	'Verkehr' AS thema,
	'ax_gleis' AS layer,
	st_multi(coalesce(p.wkb_geometry,st_centroid(o.wkb_geometry))) AS point,
	coalesce(p.drehwinkel,0) AS drehwinkel,
	coalesce(p.signaturnummer,'3587') AS signaturnummer,
	coalesce(p.advstandardmodell||p.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM ax_gleis o
JOIN ap_ppo p ON ARRAY[o.gml_id] <@ p.dientzurdarstellungvon AND p.art='ART' AND p.endet IS NULL
WHERE o.endet IS NULL AND geometrytype(o.wkb_geometry) IN ('POLYGON','MULTIPOLYGON') AND NOT bahnkategorie IS NULL AND o.art=1200;

-- Gleis, Linien
-- TODO: Mischsignaturen
INSERT INTO po_lines(gml_id,thema,layer,line,signaturnummer,modell)
SELECT
	gml_id,
	'Verkehr' AS thema,
	'ax_gleis' AS layer,
	st_multi(line),
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		wkb_geometry AS line,
		CASE
		WHEN bahnkategorie IN (1100,1102,1104,1200,1202,1400,1500,9999) THEN
			CASE
			WHEN lagezuroberflaeche IS NULL THEN 2525
			WHEN lagezuroberflaeche=1200    THEN 2300
			WHEN lagezuroberflaeche=1400    THEN 2301
			END
		WHEN bahnkategorie=1201 THEN
			CASE
			WHEN lagezuroberflaeche IS NULL THEN 2525 -- 3646
			WHEN lagezuroberflaeche=1200    THEN 2300 -- 3636
			WHEN lagezuroberflaeche=1400    THEN 2301 -- 3646
			END
		WHEN bahnkategorie IN (1300,1301) THEN
			CASE
			WHEN lagezuroberflaeche IS NULL THEN 2525 -- 3647
			WHEN lagezuroberflaeche=1200    THEN 2300 -- 3647
			WHEN lagezuroberflaeche=1400    THEN 2301 -- 3647
			END
		WHEN bahnkategorie=1302 THEN
			CASE
			WHEN lagezuroberflaeche IS NULL THEN 2525 -- 3648
			WHEN lagezuroberflaeche=1200    THEN 2300 -- 3648
			WHEN lagezuroberflaeche=1400    THEN 2301 -- 3648
			END
		WHEN bahnkategorie=1600 THEN
			CASE
			WHEN lagezuroberflaeche IS NULL THEN 2525 -- 3649
			WHEN lagezuroberflaeche=1200    THEN 2300 -- 3649
			WHEN lagezuroberflaeche=1400    THEN 2301 -- 3649
			END
		END AS signaturnummer,
		advstandardmodell||sonstigesmodell AS modell
	FROM ax_gleis o
	WHERE geometrytype(wkb_geometry) IN ('LINESTRING','MULTILINESTRING') AND endet IS NULL
) AS o WHERE NOT signaturnummer IS NULL;

-- Namen
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Verkehr' AS thema,
	'ax_gleis' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(t.schriftinhalt,name) AS text,
		coalesce(t.signaturnummer,'4107') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_gleis o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='NAM' AND t.endet IS NULL
	WHERE o.endet IS NULL AND (NOT name IS NULL OR NOT t.schriftinhalt IS NULL)
) AS n WHERE NOT text IS NULL;


--
-- Flugverkehrsanlage (53007)
--

-- Flächen
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	'Verkehr' AS thema,
	'ax_flugverkehrsanlage' AS layer,
	st_multi(wkb_geometry) AS polygon,
	1808 AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ax_flugverkehrsanlage o
WHERE endet IS NULL;

-- Hubschrauberlandeplatz
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	o.gml_id,
	'Verkehr' AS thema,
	'ax_flugverkehrsanlage' AS layer,
	st_multi(coalesce(p.wkb_geometry,st_centroid(o.wkb_geometry))) AS point,
	coalesce(p.drehwinkel,0) AS drehwinkel,
	coalesce(p.signaturnummer,'3588') AS signaturnummer,
	coalesce(p.advstandardmodell||p.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM ax_flugverkehrsanlage o
JOIN ap_ppo p ON ARRAY[o.gml_id] <@ p.dientzurdarstellungvon AND p.art='ART' AND p.endet IS NULL
WHERE o.endet IS NULL AND o.art=5531;

-- Namen
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Verkehr' AS thema,
	'ax_flugverkehrsanlage' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(t.schriftinhalt,name) AS text,
		coalesce(t.signaturnummer,'4107') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_flugverkehrsanlage o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='NAM' AND t.endet IS NULL
	WHERE o.endet IS NULL AND NOT name IS NULL OR NOT t.schriftinhalt IS NULL
) AS n WHERE NOT text IS NULL;


--
-- Einrichtungen für den Schiffsverkehr (53008)
--

-- Symbole
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	gml_id,
	'Verkehr' AS thema,
	'ax_einrichtungenfuerdenschiffsverkehr' AS layer,
	st_multi(wkb_geometry) AS point,
	0 AS drehwinkel,
	CASE
	WHEN art=1420 THEN 3590
	WHEN art=1430 THEN 3556
	WHEN art=1440 THEN 3583
	WHEN art=1450 THEN 3584
	WHEN art=9999 THEN 3640
	END AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ax_einrichtungenfuerdenschiffsverkehr o
WHERE geometrytype(o.wkb_geometry) IN ('POINT','MULTIPOINT') AND endet IS NULL;

-- Flächen
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	'Verkehr' AS thema,
	'ax_einrichtungenfuerdenschiffsverkehr' AS layer,
	st_multi(wkb_geometry) AS polygon,
	1544 AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ax_einrichtungenfuerdenschiffsverkehr
WHERE geometrytype(wkb_geometry) IN ('POLYGON','MULTIPOLYGON') AND endet IS NULL;

-- Kilometerangaben
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	o.gml_id,
	'Verkehr' AS thema,
	'ax_einrichtungenfuerdenschiffsverkehr' AS layer,
	coalesce(t.wkb_geometry,o.wkb_geometry) AS point,
	kilometerangabe AS text,
	coalesce(t.signaturnummer,'4101') AS signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
	coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM ax_einrichtungenfuerdenschiffsverkehr o
LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='KMA' AND t.endet IS NULL
WHERE o.endet IS NULL AND NOT kilometerangabe IS NULL;

-- Namen
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Verkehr' AS thema,
	'ax_einrichtungenfuerdenschiffsverkehr' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(t.schriftinhalt,name) AS text,
		coalesce(t.signaturnummer,'4081') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_einrichtungenfuerdenschiffsverkehr o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='NAM' AND t.endet IS NULL
	WHERE o.endet IS NULL AND (NOT name IS NULL OR NOT t.schriftinhalt IS NULL)
) AS n WHERE NOT text IS NULL;

--
-- Bauwerk im Gewässerbereich (53009)
--

-- Linien
INSERT INTO po_lines(gml_id,thema,layer,line,signaturnummer,modell)
SELECT
	gml_id,
	'Gewässer' AS thema,
	'ax_bauwerkimgewaesserbereich' AS layer,
	st_multi(line),
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		wkb_geometry AS line,
		CASE
		WHEN bauwerksfunktion IN (2010,2011,2070) THEN 2560
		WHEN bauwerksfunktion=2012 THEN 2561
		WHEN bauwerksfunktion=2050 THEN 2003 -- 20033650
		WHEN bauwerksfunktion=2060 THEN 2526
		WHEN bauwerksfunktion=2080 THEN 2003 -- 20033593
		WHEN bauwerksfunktion=2090 THEN 2003 -- 20033594
		WHEN bauwerksfunktion=2132 THEN 2003 -- 20033638
		WHEN bauwerksfunktion=2136 THEN 2510
		WHEN bauwerksfunktion=9999 THEN 2003
		END AS signaturnummer,
		advstandardmodell||sonstigesmodell AS modell
	FROM ax_bauwerkimgewaesserbereich o
	WHERE geometrytype(o.wkb_geometry) IN ('LINESTRING','MULTILINESTRING') AND endet IS NULL
) AS o WHERE NOT signaturnummer IS NULL;

-- TODO: Linienbegleitende Signaturen

-- Flächen
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	'Gewässer' AS thema,
	'ax_bauwerkimgewaesserbereich' AS layer,
	polygon,
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		st_multi(wkb_geometry) AS polygon,
		CASE
		WHEN bauwerksfunktion IN (2010,2011,2070) THEN 1550
		WHEN bauwerksfunktion=2020 THEN 1551
		WHEN bauwerksfunktion=2030 THEN
			CASE WHEN zustand=4000 THEN 1552 ELSE 1305 END
		WHEN bauwerksfunktion=2040 THEN
			CASE WHEN zustand=4000 THEN 1552 ELSE 1551 END
		WHEN bauwerksfunktion IN (2050,2060,2080,2110,9999) THEN 1548
		WHEN bauwerksfunktion=2090 THEN 1305
		WHEN bauwerksfunktion IN (2131,2133) THEN 1308
		END AS signaturnummer,
		advstandardmodell||sonstigesmodell AS modell
	FROM ax_bauwerkimgewaesserbereich o
	WHERE geometrytype(o.wkb_geometry) IN ('POLYGON','MULTIPOLYGON') AND endet IS NULL
) AS o WHERE NOT signaturnummer IS NULL;

-- Symbole
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	gml_id,
	'Gewässer' AS thema,
	'ax_bauwerkimgewaesserbereich' AS layer,
	st_multi(point),
	drehwinkel,
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		coalesce(p.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(p.drehwinkel,0) AS drehwinkel,
		coalesce(
			p.signaturnummer,
			CASE
			WHEN bauwerksfunktion=2050 THEN '3653'
			WHEN bauwerksfunktion=2060 THEN '3692'
			WHEN bauwerksfunktion=2080 THEN '3693'
			WHEN bauwerksfunktion=2090 THEN '3594'
			WHEN bauwerksfunktion=2110 THEN '3695'
			WHEN bauwerksfunktion=2131 THEN '3482'
			END
		) AS signaturnummer,
		coalesce(p.advstandardmodell||p.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_bauwerkimgewaesserbereich o
	JOIN ap_ppo p ON ARRAY[o.gml_id] <@ p.dientzurdarstellungvon AND p.art='BWF' AND p.endet IS NULL
	WHERE o.endet IS NULL AND geometrytype(o.wkb_geometry) IN ('POLYGON','MULTIPOLYGON')
) AS o WHERE NOT signaturnummer IS NULL;

-- Punkte
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	gml_id,
	'Gewässer' AS thema,
	'ax_bauwerkimgewaesserbereich' AS layer,
	st_multi(point),
	drehwinkel,
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		wkb_geometry AS point,
		0 AS drehwinkel,
		CASE
		WHEN bauwerksfunktion=2120 THEN 3896
		END AS signaturnummer,
		advstandardmodell||sonstigesmodell AS modell
	FROM ax_bauwerkimgewaesserbereich o
	WHERE geometrytype(o.wkb_geometry) IN ('POINT','MULTIPOINT') AND endet IS NULL
) AS o WHERE NOT signaturnummer IS NULL;

-- Texte
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Gewässer' AS thema,
	'ax_bauwerkimgewaesserbereich' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		(select v from alkis_wertearten where element='ax_bauwerkimgewaesserbereich' AND bezeichnung='bauwerksfunktion' AND k=o.bauwerksfunktion::text) AS text,
		coalesce(t.signaturnummer,'4105') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_bauwerkimgewaesserbereich o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='BWF' AND t.endet IS NULL
	WHERE o.endet IS NULL AND bauwerksfunktion=2020
) AS n WHERE NOT text IS NULL;

-- Zustand
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Gewässer' AS thema,
	'ax_bauwerkimgewaesserbereich' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		CASE
		WHEN zustand=2100 THEN '(außer Betrieb)'
		WHEN zustand=4000 THEN
			(select v from alkis_wertearten where element='ax_bauwerkimgewaesserbereich' AND bezeichnung='bauwerksfunktion' AND k=o.bauwerksfunktion::text)
			|| E' (im Bau)'
		END AS text,
		coalesce(t.signaturnummer,'4070') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_bauwerkimgewaesserbereich o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='ZUS' AND t.endet IS NULL
	WHERE o.endet IS NULL AND bauwerksfunktion IN (2030,2040) AND NOT zustand IS NULL
) AS n WHERE NOT text IS NULL;

-- Namen
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Gewässer' AS thema,
	'ax_bauwerkimgewaesserbereich' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(t.schriftinhalt,name) AS text,
		coalesce(t.signaturnummer,'4074') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_bauwerkimgewaesserbereich o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='NAM' AND t.endet IS NULL
	WHERE o.endet IS NULL AND (NOT name IS NULL OR NOT t.schriftinhalt IS NULL)
) AS n WHERE NOT text IS NULL;


--
-- Vegetationsmerkmale (54001)
--

SELECT 'Vegetationsmerkmale werden verarbeitet.';

-- Punkte
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	gml_id,
	'Vegetation' AS thema,
	'ax_vegetationsmerkmal' AS layer,
	st_multi(point),
	drehwinkel,
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		wkb_geometry AS point,
		0 AS drehwinkel,
		CASE
		WHEN bewuchs=1011 THEN 3597
		WHEN bewuchs=1012 THEN 3599
		WHEN bewuchs=1400 THEN 3603
		WHEN bewuchs=1700 THEN 3607
		END AS signaturnummer,
		advstandardmodell||sonstigesmodell AS modell
	FROM ax_vegetationsmerkmal o
	WHERE geometrytype(o.wkb_geometry) IN ('POINT','MULTIPOINT') AND endet IS NULL
) AS o WHERE NOT signaturnummer IS NULL;

-- Punktförmige Begleitsignaturen an Linien
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	gml_id,
	'Vegetation' AS thema,
	'ax_vegetationsmerkmal' AS layer,
	st_multi(st_collect(st_lineinterpolatepoint(line,CASE WHEN a.offset<0 THEN 0 WHEN a.offset>1 THEN 1 ELSE a.offset END))) AS point,
	0 AS drehwinkel,
	signaturnummer,
	modell
FROM (
	SELECT
		gml_id,
		signaturnummer,
		line,
		generate_series(einzug,(st_length(line)*1000)::int,abstand)/100.0/st_length(line) AS offset,
		modell
	FROM (
		SELECT
			gml_id,
			bewuchs,
			einzug,
			abstand,
			CASE geometrytype(line)
			WHEN 'MULTILINESTRING' THEN (st_dump(line)).geom
			ELSE line
			END AS line,
			signaturnummer,
			modell
		FROM (
			SELECT
				gml_id,
				bewuchs,
				CASE
				WHEN bewuchs IN (1100,1230,1260) THEN 0
				WHEN bewuchs IN (1101,1102) THEN 300
				WHEN bewuchs=1103 THEN unnest(ARRAY[300,600])
				WHEN bewuchs IN (1210,1220) THEN 186
				WHEN bewuchs=1230 THEN unnest(ARRAY[1000,2000])
				END AS einzug,
				CASE
				WHEN bewuchs IN (1100,1101,1102,1210,1220,1260) THEN 600
				WHEN bewuchs=1103 THEN unnest(ARRAY[1200,1200])
				WHEN bewuchs=1210 THEN 1000
				WHEN bewuchs=1230 THEN unnest(ARRAY[2000,2000])
				END AS abstand,
				CASE
				WHEN bewuchs IN (1100,1210,1220,1260) THEN wkb_geometry
				WHEN bewuchs=1101 THEN st_reverse(st_offsetcurve(wkb_geometry,-0.11,''::text))
				WHEN bewuchs=1102 THEN st_offsetcurve(wkb_geometry,0.11,''::text)
				WHEN bewuchs=1103 THEN
					unnest(ARRAY[
						st_reverse(st_offsetcurve(wkb_geometry,-0.11,''::text)),
						st_offsetcurve(wkb_geometry,0.11,'')
					])
				WHEN bewuchs=1230 THEN
					unnest(ARRAY[
						wkb_geometry,
						wkb_geometry
					])
				END AS line,
				CASE
				WHEN bewuchs IN (1100,1101,1102,1103) THEN 3601
				WHEN bewuchs=1210 THEN 3458
				WHEN bewuchs=1220 THEN 3460
				WHEN bewuchs=1230 THEN unnest(ARRAY[3458,3460])
				WHEN bewuchs=1260 THEN 3601
				WHEN bewuchs=1700 THEN 3607
				END AS signaturnummer,
				advstandardmodell||sonstigesmodell AS modell
			FROM ax_vegetationsmerkmal o
			WHERE o.endet IS NULL
			AND geometrytype(o.wkb_geometry) IN ('LINESTRING','MULTILINESTRING')
		) AS a
	) AS a
) AS a
GROUP BY gml_id,signaturnummer,modell;

-- Flächen
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	'Vegetation' AS thema,
	'ax_vegetationsmerkmal' AS layer,
	polygon,
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		st_multi(wkb_geometry) AS polygon,
		CASE
		WHEN bewuchs IN (1021,1022,1023,1050,1260,1400,1500,1510,1600,1700,1800) THEN 1560
		WHEN bewuchs=1300                                                        THEN 1561
		END AS signaturnummer,
		advstandardmodell||sonstigesmodell AS modell
	FROM ax_vegetationsmerkmal o
	WHERE geometrytype(o.wkb_geometry) IN ('POLYGON','MULTIPOLYGON') AND endet IS NULL
) AS o WHERE NOT signaturnummer IS NULL;

-- Flächensymbole
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	gml_id,
	'Vegetation' AS thema,
	'ax_vegetationsmerkmal' AS layer,
	st_multi(point),
	0 AS drehwinkel,
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		coalesce(p.wkb_geometry,alkis_flaechenfuellung(o.wkb_geometry,d.positionierungsregel),st_centroid(o.wkb_geometry)) AS point,
		coalesce(p.drehwinkel,0) AS drehwinkel,
		coalesce(
			p.signaturnummer,
			CASE
			WHEN bewuchs=1021          THEN '3458'
			WHEN bewuchs=1022          THEN '3460'
			WHEN bewuchs=1023          THEN '3462'
			WHEN bewuchs=1050          THEN '3470'
			WHEN bewuchs=1260          THEN '3601'
			WHEN bewuchs=1400          THEN '3603'
			WHEN bewuchs IN(1500,1510) THEN '3613'
			WHEN bewuchs=1600          THEN '3605'
			WHEN bewuchs=1700          THEN '3607'
			WHEN bewuchs=1800          THEN '3609'
			END
		) AS signaturnummer,
		coalesce(
			p.advstandardmodell||p.sonstigesmodell||d.advstandardmodell||d.sonstigesmodell,
			o.advstandardmodell||o.sonstigesmodell
		) AS modell
	FROM ax_vegetationsmerkmal o
	LEFT OUTER JOIN ap_ppo p ON ARRAY[o.gml_id] <@ p.dientzurdarstellungvon AND p.art='BWS' AND p.endet IS NULL
	LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='BWS' AND d.endet IS NULL
	WHERE o.endet IS NULL AND geometrytype(o.wkb_geometry) IN ('POLYGON','MULTIPOLYGON')
) AS o WHERE NOT signaturnummer IS NULL;

-- Zustand nass, Flächen
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	o.gml_id,
	'Vegetation' AS thema,
	'ax_vegetationsmerkmal' AS layer,
	st_multi(wkb_geometry) AS polygon,
	1563 AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ax_vegetationsmerkmal o
WHERE geometrytype(o.wkb_geometry) IN ('POLYGON','MULTIPOLYGON') AND zustand=5000;

-- Zustand nass, Symbol
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	o.gml_id,
	'Vegetation' AS thema,
	'ax_vegetationsmerkmal' AS layer,
	st_multi(coalesce(p.wkb_geometry,st_centroid(o.wkb_geometry))) AS point,
	coalesce(p.drehwinkel,0) AS drehwinkel,
	coalesce(p.signaturnummer,'3478') AS signaturnummer,
	coalesce(p.advstandardmodell||p.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM ax_vegetationsmerkmal o
JOIN ap_ppo p ON ARRAY[o.gml_id] <@ p.dientzurdarstellungvon AND p.art='ZUS' AND p.endet IS NULL
WHERE o.endet IS NULL AND geometrytype(o.wkb_geometry) IN ('POLYGON','MULTIPOLYGON') AND zustand=5000;

-- Schneise, Text
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	o.gml_id,
	'Vegetation' AS thema,
	'ax_vegetationsmerkmal' AS layer,
	coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
	'Schneise' AS text,
	coalesce(t.signaturnummer,'4070') AS signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
	coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM ax_vegetationsmerkmal o
LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='BWS' AND t.endet IS NULL
WHERE o.endet IS NULL AND geometrytype(o.wkb_geometry) IN ('POLYGON','MULTIPOLYGON') AND bewuchs=1300;

-- Namen
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Vegetation' AS thema,
	'ax_vegetationsmerkmal' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(t.schriftinhalt,name) AS text,
		coalesce(t.signaturnummer,'4074') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_vegetationsmerkmal o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='NAM' AND t.endet IS NULL
	WHERE o.endet IS NULL AND (NOT name IS NULL OR NOT t.schriftinhalt IS NULL)
) AS n WHERE NOT text IS NULL;


--
-- Gewässermerkmal (55001)
--

SELECT 'Gewässermerkmale werden verarbeitet.';

-- Punkte
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	gml_id,
	'Gewässer' AS thema,
	'ax_gewaessermerkmal' AS layer,
	st_multi(point),
	0 AS drehwinkel,
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		wkb_geometry AS point,
		CASE
		WHEN o.art=1610 THEN 3613
		END AS signaturnummer,
		advstandardmodell||sonstigesmodell AS modell
	FROM ax_gewaessermerkmal o
	WHERE geometrytype(o.wkb_geometry) IN ('POINT','MULTIPOINT') AND endet IS NULL
) AS o WHERE NOT signaturnummer IS NULL;


/*
-- Linien
-- TODO: Zickzacklinie - Wasserfall
INSERT INTO po_lines(gml_id,thema,layer,line,signaturnummer,modell)
SELECT
	gml_id,
	'Gewässer' AS thema,
	'ax_gewaessermerkmal' AS layer,
	st_multi(line),
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		wkb_geometry AS line,
		CASE
		WHEN o.art=1620 THEN 3651
		END AS signaturnummer,
		advstandardmodell||sonstigesmodell AS modell
	FROM ax_gewaessermerkmal o
	WHERE geometrytype(o.wkb_geometry) IN ('LINESTRING','MULTILINESTRING') AND endet IS NULL
) AS o WHERE NOT signaturnummer IS NULL;
*/

-- Flächen
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	'Gewässer' AS thema,
	'ax_gewaessermerkmal' AS layer,
	polygon,
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		st_multi(wkb_geometry) AS polygon,
		CASE
		WHEN o.art IN (1610,1620) THEN 1562
		WHEN o.art=1630 THEN 1562
		WHEN o.art=1640 THEN 1570
		WHEN o.art=1650 THEN 1571
		WHEN o.art=1660 THEN 1523
		WHEN o.art=9999 THEN 1551
		END AS signaturnummer,
		advstandardmodell||sonstigesmodell AS modell
	FROM ax_gewaessermerkmal o
	WHERE geometrytype(o.wkb_geometry) IN ('POLYGON','MULTIPOLYGON') AND endet IS NULL
) AS o WHERE NOT signaturnummer IS NULL;

-- Flächensymbole
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	gml_id,
	'Gewässer' AS thema,
	'ax_gewaessermerkmal' AS layer,
	st_multi(point),
	drehwinkel,
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		coalesce(p.wkb_geometry,alkis_flaechenfuellung(o.wkb_geometry,d.positionierungsregel),st_centroid(o.wkb_geometry)) AS point,
		coalesce(p.drehwinkel,0) AS drehwinkel,
		coalesce(
			p.signaturnummer,
			CASE
			WHEN o.art=1620 THEN '3615'
			WHEN o.art=1630 THEN '3617'
			WHEN o.art=1640 THEN '3484'
			WHEN o.art=1660 THEN '3490'
			END
		) AS signaturnummer,
		coalesce(
			p.advstandardmodell||p.sonstigesmodell||d.advstandardmodell||d.sonstigesmodell,
			o.advstandardmodell||o.sonstigesmodell
		)  AS modell
	FROM ax_gewaessermerkmal o
	LEFT OUTER JOIN ap_ppo p ON ARRAY[o.gml_id] <@ p.dientzurdarstellungvon AND p.art='ART' AND p.endet IS NULL
	LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='ART' AND d.endet IS NULL
	WHERE o.endet IS NULL AND geometrytype(o.wkb_geometry) IN ('POLYGON','MULTIPOLYGON')
) AS o WHERE NOT signaturnummer IS NULL;

-- Texte
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Gewässer' AS thema,
	'ax_gewaessermerkmal' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		coalesce(
			t.wkb_geometry,
			CASE
			WHEN geometrytype(o.wkb_geometry) IN ('POINT','MULTIPOINT') THEN o.wkb_geometry
			WHEN geometrytype(o.wkb_geometry) IN ('POLYGON','MULTIPOLYGON') THEN st_centroid(o.wkb_geometry)
			END
		) AS point,
		'Qu'::text AS text,
		coalesce(t.signaturnummer,'4103') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_gewaessermerkmal o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='ART' AND t.endet IS NULL
	WHERE o.endet IS NULL AND o.art=1610
) AS n WHERE NOT text IS NULL;

-- Namen
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Gewässer' AS thema,
	'ax_gewaessermerkmal' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(t.schriftinhalt,name) AS text,
		coalesce(
			t.signaturnummer,
			CASE
			WHEN o.art IN (1610,1620,1630,1660) THEN '4117'
			WHEN o.art IN (1640,1650,9999)      THEN '4116'
			END
		)AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_gewaessermerkmal o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='NAM' AND t.endet IS NULL
	WHERE o.endet IS NULL AND (NOT name IS NULL OR NOT t.schriftinhalt IS NULL)
) AS n WHERE NOT text IS NULL AND NOT signaturnummer IS NULL;


--
-- Untergeordnetes Gewässer (55002)
--

SELECT 'Untergeordnete Gewässer werden verarbeitet.';

-- Linien
INSERT INTO po_lines(gml_id,thema,layer,line,signaturnummer,modell)
SELECT
	gml_id,
	'Gewässer' AS thema,
	'ax_untergeordnetesgewaesser' AS layer,
	st_multi(line),
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		wkb_geometry AS line,
		CASE
		WHEN coalesce(funktion,0) IN (0,1010,1011,1012,1013,1020,1030) THEN
			CASE
			WHEN lagezurerdoberflaeche IS NULL AND hydrologischesmerkmal IS NULL THEN 2592
			WHEN lagezurerdoberflaeche IN (1800,1810)                            THEN 2560
			WHEN lagezurerdoberflaeche IS NULL AND hydrologischesmerkmal=2000    THEN 2593
			WHEN lagezurerdoberflaeche IS NULL AND hydrologischesmerkmal=3000    THEN 2595
			END
		END AS signaturnummer,
		advstandardmodell||sonstigesmodell AS modell
	FROM ax_untergeordnetesgewaesser o
	WHERE geometrytype(o.wkb_geometry) IN ('LINESTRING','MULTILINESTRING') AND endet IS NULL
) AS o WHERE NOT signaturnummer IS NULL;

-- Flächen
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	'Gewässer' AS thema,
	'ax_untergeordnetesgewaesser' AS layer,
	polygon,
	signaturnummer,
	modell
FROM (
	SELECT
		gml_id,
		st_multi(wkb_geometry) AS polygon,
		CASE
		WHEN coalesce(funktion,0) IN (0,1010,1011,1012,1013,1020,1030) THEN
			CASE
			WHEN lagezurerdoberflaeche IS NULL AND hydrologischesmerkmal IS NULL THEN 1523
			WHEN lagezurerdoberflaeche IN (1800,1810)                            THEN 1550
			WHEN lagezurerdoberflaeche IS NULL AND hydrologischesmerkmal=2000    THEN 1572
			WHEN lagezurerdoberflaeche IS NULL AND hydrologischesmerkmal=3000    THEN 1573
			END
		WHEN funktion=1040 THEN
			CASE
			WHEN hydrologischesmerkmal IS NULL THEN 1523
			WHEN hydrologischesmerkmal=2000    THEN 1572
			WHEN hydrologischesmerkmal=3000    THEN 1573
			END
		END AS signaturnummer,
		advstandardmodell||sonstigesmodell AS modell
	FROM ax_untergeordnetesgewaesser o
	WHERE geometrytype(o.wkb_geometry) IN ('POLYGON','MULTIPOLYGON') AND endet IS NULL
) AS o WHERE NOT signaturnummer IS NULL;

-- Symbole
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	gml_id,
	'Gewässer' AS thema,
	'ax_untergeordnetesgewaesser' AS layer,
	st_multi(point),
	drehwinkel,
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		coalesce(
			p.wkb_geometry,
			CASE
			WHEN geometrytype(o.wkb_geometry) IN ('POLYGON','MULTIPOLYGON') THEN coalesce(alkis_flaechenfuellung(o.wkb_geometry,d.positionierungsregel),st_centroid(o.wkb_geometry))
			WHEN geometrytype(o.wkb_geometry)='LINESTRING'                  THEN st_lineinterpolatepoint(o.wkb_geometry,0.5)
			END
		) AS point,
		coalesce(p.drehwinkel,0) AS drehwinkel,
		coalesce(
			p.signaturnummer,
			CASE
			WHEN coalesce(funktion,0) IN (0,1040) THEN '3490'
			WHEN funktion IN (1010,1011,1012,1013,1020,1030) THEN
				CASE
				WHEN lagezurerdoberflaeche IS NULL AND hydrologischesmerkmal IS NULL THEN '3488'
				WHEN lagezurerdoberflaeche IN (1800,1810)                            THEN '3619'
				WHEN lagezurerdoberflaeche IS NULL AND hydrologischesmerkmal=2000    THEN '3621'
				END
			END
		) AS signaturnummer,
		coalesce(
			p.advstandardmodell||p.sonstigesmodell||d.advstandardmodell||d.sonstigesmodell,
			o.advstandardmodell||o.sonstigesmodell
		) AS modell
	FROM ax_untergeordnetesgewaesser o
	LEFT OUTER JOIN ap_ppo p ON ARRAY[o.gml_id] <@ p.dientzurdarstellungvon AND p.art='FKT' AND p.endet IS NULL
	LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='FKT' AND d.endet IS NULL
	WHERE o.endet IS NULL
) AS o WHERE NOT point IS NULL;

-- Texte, Lage zur Oberfläche
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Gewässer' AS thema,
	'ax_untergeordnetesgewaesser' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		coalesce(
			t.wkb_geometry,
			CASE
			WHEN geometrytype(o.wkb_geometry) IN ('POINT','MULTIPOINT') THEN o.wkb_geometry
			WHEN geometrytype(o.wkb_geometry) IN ('POLYGON','MULTIPOLYGON') THEN st_centroid(o.wkb_geometry)
			END
		) AS point,
		(select v from alkis_wertearten where element='ax_untergeordnetesgewaesser' AND bezeichnung='lagezurerdoberflaeche' AND k=lagezurerdoberflaeche::text) AS text,
		coalesce(t.signaturnummer,'4070') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_untergeordnetesgewaesser o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='OFL' AND t.endet IS NULL
	WHERE o.endet IS NULL AND lagezurerdoberflaeche IN (1800,1810)
) AS o WHERE NOT text IS NULL;

-- Texte, Graben
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Gewässer' AS thema,
	'ax_untergeordnetesgewaesser' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		coalesce(
			t.wkb_geometry,
			st_centroid(o.wkb_geometry)
		) AS point,
		'Graben'::text AS text,
		coalesce(t.signaturnummer,'4070') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_untergeordnetesgewaesser o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='FKT' AND t.endet IS NULL
	WHERE o.endet IS NULL AND funktion=1013 AND lagezurerdoberflaeche IS NULL AND hydrologischesmerkmal=3000
) AS o WHERE NOT text IS NULL;

-- Namen
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Gewässer' AS thema,
	'ax_untergeordnetesgewaesser' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(t.schriftinhalt,o.name) AS text,
		coalesce(t.signaturnummer,'4117') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_untergeordnetesgewaesser o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='NAM' AND t.endet IS NULL
	WHERE o.endet IS NULL
) AS o WHERE NOT text IS NULL;

--
-- Wasserspiegelhöhe (57001)
--

SELECT 'Wasserspiegelhöhen werden verarbeitet.';

-- Symbol
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	o.gml_id,
	'Gewässer' AS thema,
	'ax_wasserspiegelhoehe' AS layer,
	st_multi(coalesce(p.wkb_geometry,o.wkb_geometry)) AS point,
	coalesce(p.drehwinkel,0) AS drehwinkel,
	coalesce(p.signaturnummer,'3623') AS signaturnummer,
	coalesce(p.advstandardmodell||p.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM ax_wasserspiegelhoehe o
LEFT OUTER JOIN ap_ppo p ON ARRAY[o.gml_id] <@ p.dientzurdarstellungvon AND p.art='SYMBOL' AND p.endet IS NULL
WHERE o.endet IS NULL AND NOT hoehedeswasserspiegels IS NULL;

-- Wasserspiegeltext
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	o.gml_id,
	'Gewässer' AS thema,
	'ax_wasserspiegelhoehe' AS layer,
	coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
	hoehedeswasserspiegels AS text,
	coalesce(t.signaturnummer,'4102') AS signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
	coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM ax_wasserspiegelhoehe o
LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='HWS' AND t.endet IS NULL
WHERE o.endet IS NULL AND NOT hoehedeswasserspiegels IS NULL;

--
-- Schifffahrtslinie, Fährverkehr (57002)
--

SELECT 'Schifffahrtslinien werden verarbeitet.';

-- Linien
INSERT INTO po_lines(gml_id,thema,layer,line,signaturnummer,modell)
SELECT
	o.gml_id,
	'Verkehr' AS thema,
	'ax_schifffahrtsliniefaehrverkehr' AS layer,
	st_multi(coalesce(l.wkb_geometry,o.wkb_geometry)) AS line,
	CASE
	WHEN o.art=ARRAY[1740] THEN 2592
	ELSE 2609
	END AS signaturnummer,
	coalesce(l.advstandardmodell||l.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM ax_schifffahrtsliniefaehrverkehr o
LEFT OUTER JOIN ap_lpo l ON ARRAY[o.gml_id] <@ l.dientzurdarstellungvon AND l.art='Schifffahrtslinie' AND l.endet IS NULL
WHERE o.endet IS NULL AND o.art IS NULL;

-- Texte
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Verkehr' AS thema,
	'ax_schifffahrtsliniefaehrverkehr' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(
			t.schriftinhalt,
			CASE
			WHEN o.art IN (ARRAY[1710], ARRAY[1710,1730]) THEN 'Autofähre'
			WHEN o.art=ARRAY[1710,1720]                   THEN 'Auto- und Eisenbahnfähre'
			WHEN o.art IN (ARRAY[1720], ARRAY[1720,1730]) THEN 'Eisenbahnfähre'
			WHEN o.art=ARRAY[1730]                        THEN 'Personenfähre'
			END
		) AS text,
		coalesce(t.signaturnummer,'4103') AS signaturnummer,
	        drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_schifffahrtsliniefaehrverkehr o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='ART' AND t.endet IS NULL
	WHERE o.endet IS NULL
) AS a WHERE NOT text IS NULL;

-- Namen
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Verkehr' AS thema,
	'ax_schifffahrtsliniefaehrverkehr' AS layer,
	point,
	text,
	signaturnummer,
        drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(t.schriftinhalt,o.name) AS text,
		coalesce(t.signaturnummer,'4107') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_schifffahrtsliniefaehrverkehr o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='NAM' AND t.endet IS NULL
	WHERE o.endet IS NULL AND (NOT name IS NULL OR NOT t.schriftinhalt IS NULL)
) AS n WHERE NOT text IS NULL;

/*
--
-- Böschungslinie, Kliff (61001)
-- TODO: geometrielos?
--

SELECT 'Böschungen und Kliffe werden verarbeitet.';

INSERT INTO po_lines(gml_id,thema,layer,line,signaturnummer,modell)
SELECT
	gml_id,
	'Topographie' AS thema,
	'ax_boeschungsliniekliff' AS layer,
	st_multi(wkb_geometry) AS line,
	2531 AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ax_boeschungsliniekliff
WHERE endet IS NULL;

-- Namen
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Topographie' AS thema,
	'ax_boeschungsliniekliff' AS layer,
	point,
	text,
	signaturnummer,
	modell
FROM (
	SELECT
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(t.schriftinhalt,name) AS text,
		coalesce(t.signaturnummer,'4118') AS signaturnummer,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_boeschungsliniekliff o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='NAM' AND t.endet IS NULL
	WHERE o.endet IS NULL AND (NOT name IS NULL OR NOT t.schriftinhalt IS NULL)
) AS n WHERE NOT text IS NULL;
*/

--
-- Damm, Wall, Deich (61003)
--

SELECT 'Dämme, Walle und Deiche werden verarbeitet.';

-- TODO: PNR
INSERT INTO po_lines(gml_id,thema,layer,line,signaturnummer,modell)
SELECT
	o.gml_id,
	'Topographie' AS thema,
	'ax_dammwalldeich' AS layer,
	st_multi(wkb_geometry) AS line,
	2620 AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ax_dammwalldeich o
WHERE geometrytype(wkb_geometry) IN ('LINESTRING','MULTILINESTRING') AND endet IS NULL;

INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	o.gml_id,
	'Topographie' AS thema,
	'ax_dammwalldeich' AS layer,
	st_multi(wkb_geometry) AS polygon,
	1551 AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ax_dammwalldeich o
WHERE geometrytype(wkb_geometry) IN ('POLYGON','MULTIPOLYGON') AND endet IS NULL;

-- Namen
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Topographie' AS thema,
	'ax_dammwalldeich' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(t.schriftinhalt,name) AS text,
		coalesce(t.signaturnummer,'4109') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_dammwalldeich o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='NAM' AND t.endet IS NULL
	WHERE o.endet IS NULL AND (NOT name IS NULL OR NOT t.schriftinhalt IS NULL)
) AS n WHERE NOT text IS NULL;

--
-- Höhleneingang (61005)
--

SELECT 'Höhleneingänge werden verarbeitet.';

INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	gml_id,
	'Topographie' AS thema,
	'ax_hoehleneingang' AS layer,
	st_multi(wkb_geometry) AS point,
	0 AS drehwinkel,
	3625 AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ax_hoehleneingang
WHERE endet IS NULL;

-- Namen
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Topographie' AS thema,
	'ax_hoehleneingang' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(t.signaturnummer,'4118') AS signaturnummer,
		coalesce(t.schriftinhalt,name) AS text,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_hoehleneingang o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='NAM' AND t.endet IS NULL
	WHERE o.endet IS NULL AND (NOT name IS NULL OR NOT t.schriftinhalt IS NULL)
) AS n WHERE NOT text IS NULL;

--
-- Felsen, Felsblock, Felsnadel (61006)
--

SELECT 'Felsen werden verarbeitet.';

INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	o.gml_id,
	'Topographie' AS thema,
	'ax_felsenfelsblockfelsnadel' AS layer,
	st_multi(wkb_geometry) AS point,
	0 AS drehwinkel,
	3627 AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ax_felsenfelsblockfelsnadel o
WHERE geometrytype(wkb_geometry) IN ('POINT','MULTIPOINT') AND endet IS NULL;

-- Punktförmige Begleitsignaturen an Linien
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	gml_id,
	'Topographie' AS thema,
	'ax_felsenfelsblockfelsnadel' AS layer,
	st_multi(st_collect(st_lineinterpolatepoint(line,CASE WHEN a.offset<0 THEN 0 WHEN a.offset>1 THEN 1 ELSE a.offset END))) AS point,
	0 AS drehwinkel,
	signaturnummer,
	modell
FROM (
	SELECT
		gml_id,
		signaturnummer,
		line,
		generate_series(einzug,(st_length(line)*1000)::int,abstand)/100.0/st_length(line) AS offset,
		modell
	FROM (
		SELECT
			gml_id,
			einzug,
			abstand,
			CASE geometrytype(line)
			WHEN 'MULTILINESTRING' THEN (st_dump(line)).geom
			ELSE line
			END AS line,
			signaturnummer,
			modell
		FROM (
			SELECT
				gml_id,
				710 AS einzug,
				800 AS abstand,
				wkb_geometry AS line,
				3634 AS signaturnummer,
				advstandardmodell||sonstigesmodell AS modell
			FROM ax_felsenfelsblockfelsnadel o
			WHERE o.endet IS NULL
			AND geometrytype(o.wkb_geometry) IN ('LINESTRING','MULTILINESTRING')
		) AS a
	) AS a
) AS a
GROUP BY gml_id,signaturnummer,modell;

-- Flächen
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	o.gml_id,
	'Topographie' AS thema,
	'ax_felsenfelsblockfelsnadel' AS layer,
	st_multi(wkb_geometry) AS polygon,
	1551 AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ax_felsenfelsblockfelsnadel o
WHERE geometrytype(wkb_geometry) IN ('POLYGON','MULTIPOLYGON') AND endet IS NULL;

-- Flächensymbole
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	o.gml_id,
	'Topographie' AS thema,
	'ax_felsenfelsblockfelsnadel' AS layer,
	st_multi(coalesce(p.wkb_geometry,alkis_flaechenfuellung(o.wkb_geometry,d.positionierungsregel),st_centroid(o.wkb_geometry))) AS point,
	coalesce(p.drehwinkel,0) AS drehwinkel,
	coalesce(p.signaturnummer,'3627') AS signaturnummer,
	coalesce(
		p.advstandardmodell||p.sonstigesmodell||d.advstandardmodell||d.sonstigesmodell,
		o.advstandardmodell||o.sonstigesmodell
	) AS modell
FROM ax_felsenfelsblockfelsnadel o
LEFT OUTER JOIN ap_ppo p ON ARRAY[o.gml_id] <@ p.dientzurdarstellungvon AND p.art='Felsen' AND p.endet IS NULL
LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='Felsen' AND d.endet IS NULL
WHERE o.endet IS NULL AND geometrytype(o.wkb_geometry) IN ('POLYGON','MULTIPOLYGON');

-- Namen
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Topographie' AS thema,
	'ax_felsenfelsblockfelsnadel' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(t.schriftinhalt,name) AS text,
		coalesce(t.signaturnummer,'4118') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_felsenfelsblockfelsnadel o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='NAM' AND t.endet IS NULL
	WHERE o.endet IS NULL AND (NOT name IS NULL OR NOT t.schriftinhalt IS NULL)
) AS n WHERE NOT text IS NULL;

--
-- Düne (61007)
--

SELECT 'Dünen werden verarbeitet.';

-- Flächen
INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	'Topographie' AS thema,
	'ax_duene' AS layer,
	st_multi(wkb_geometry) AS polygon,
	1570 AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ax_duene
WHERE endet IS NULL;

-- Flächensymbole
INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	o.gml_id,
	'Topographie' AS thema,
	'ax_duene' AS layer,
	st_multi(coalesce(p.wkb_geometry,alkis_flaechenfuellung(o.wkb_geometry,d.positionierungsregel),st_centroid(o.wkb_geometry))) AS point,
	coalesce(p.drehwinkel,0) AS drehwinkel,
	coalesce(p.signaturnummer,'3484') AS signaturnummer,
	coalesce(
		p.advstandardmodell||p.sonstigesmodell||d.advstandardmodell||d.sonstigesmodell,
		o.advstandardmodell||o.sonstigesmodell
	) AS modell
FROM ax_duene o
LEFT OUTER JOIN ap_ppo p ON ARRAY[o.gml_id] <@ p.dientzurdarstellungvon AND p.art='Duene' AND p.endet IS NULL
LEFT OUTER JOIN ap_darstellung d ON ARRAY[o.gml_id] <@ d.dientzurdarstellungvon AND d.art='Duene' AND d.endet IS NULL
WHERE o.endet IS NULL;

-- Namen
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Topographie' AS thema,
	'ax_duene' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(t.signaturnummer,'4118') AS signaturnummer,
		coalesce(t.schriftinhalt,name) AS text,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_duene o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='NAM' AND t.endet IS NULL
	WHERE o.endet IS NULL AND (NOT name IS NULL OR NOT t.schriftinhalt IS NULL)
) AS n WHERE NOT text IS NULL;

--
-- Höhenlinien (61008)
--

SELECT 'Höhenlinien werden verarbeitet.';

-- TODO: Ob das wohl stimmt?
INSERT INTO po_lines(gml_id,thema,layer,line,signaturnummer,modell)
SELECT
	gml_id,
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
FROM ax_hoehenlinie
WHERE endet IS NULL;

-- Namen
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	o.gml_id,
	'Topographie' AS thema,
	'ax_hoehenlinie' AS layer,
	coalesce(t.wkb_geometry,st_lineinterpolatepoint(o.wkb_geometry,0.5)) AS point,
	hoehevonhoehenlinie AS text,
	coalesce(t.signaturnummer,'4104') AS signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
	coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM ax_hoehenlinie o
LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='HHL' AND t.endet IS NULL
WHERE o.endet IS NULL AND NOT hoehevonhoehenlinie IS NULL;

--
-- Besonderer topographischer Punkt (61009)
--

SELECT 'Besondere topographische Punkte verarbeitet.';

INSERT INTO po_points(gml_id,thema,layer,point,drehwinkel,signaturnummer,modell)
SELECT
	o.gml_id,
	'Topographie' AS thema,
	'ax_besonderertopographischerpunkt' AS layer,
	st_multi(st_force_2d(p.wkb_geometry)) AS point,
	0 AS drehwinkel,
	3629 AS signaturnummer,
	coalesce(p.advstandardmodell||p.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM ax_besonderertopographischerpunkt o
JOIN ax_punktortau p ON o.gml_id=p.istteilvon AND p.endet IS NULL
WHERE o.endet IS NULL;

-- Text
-- TODO: 14003 [UPO] steht für welches Beschriftungsfeld?
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	o.gml_id,
	'Topographie' AS thema,
	'ax_besonderertopographischerpunkt' AS layer,
	t.wkb_geometry AS point,
	coalesce(schriftinhalt,punktkennung) AS text,
	coalesce(t.signaturnummer,'4104') AS signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
	coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM ax_besonderertopographischerpunkt o
JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='UPO' AND t.endet IS NULL
WHERE o.endet IS NULL;

--
-- Geländekante (62040)
--

SELECT 'Geländekanten werden verarbeitet.';

INSERT INTO po_lines(gml_id,thema,layer,line,signaturnummer,modell)
SELECT
	gml_id,
	'Topographie' AS thema,
	'ax_besonderertopographischerpunkt' AS layer,
	st_multi(wkb_geometry) AS line,
	CASE
	WHEN art IN (1220,1230,1240) THEN 2531
	WHEN art=1210 THEN 2622
	END AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ax_gelaendekante WHERE art IN (1210,1220,1230,1240) AND endet IS NULL;


--
-- Klassifizierungen nach Straßenrecht (71001)
--

SELECT 'Klassifizierungen nach Straßenrecht werden verarbeitet.';

INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	'Rechtliche Festlegungen' AS thema,
	'ax_klassifizierungnachstrassenrecht' AS layer,
	st_multi(wkb_geometry) AS polygon,
	CASE
	WHEN artderfestlegung IN (1110,1120) THEN 1701
	WHEN artderfestlegung=1130 THEN 1702
	END AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ax_klassifizierungnachstrassenrecht
WHERE artderfestlegung IN (1110,1120,1130)
  AND endet IS NULL
  AND geometrytype(wkb_geometry) IN ('POLYGON','MULTIPOLYGON');

INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Rechtliche Festlegungen' AS thema,
	'ax_klassifizierungnachstrassenrecht' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		t.wkb_geometry AS point,
		bezeichnung AS text,
		coalesce(t.signaturnummer,'4140') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_klassifizierungnachstrassenrecht o
	JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='BEZ' AND t.endet IS NULL
	WHERE o.endet IS NULL
) AS o WHERE NOT text IS NULL;

--
-- Klassifizierungen nach Wasserrecht (71003)
-- (kommt in SK nicht vor)
--

SELECT 'Klassifizierungen nach Wasserrecht werden verarbeitet.';

INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Rechtliche Festlegungen' AS thema,
	'ax_klassifizierungnachwasserrecht' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		t.wkb_geometry AS point,
		schriftinhalt AS text,
		coalesce(t.signaturnummer,'4140') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_klassifizierungnachwasserrecht o
	JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.endet IS NULL
	WHERE o.endet IS NULL
) AS o WHERE NOT text IS NULL;

-- TODO: Kam noch nicht vor
-- RP: ax_andereklassifizierungnachwasserecht (71004)
-- RP: ax_anderefestlegungnachwasserecht (71005)

--
-- Klassifizierungen nach Natur-, Umwelt- oder Bodenschutzrecht (71006)
--

SELECT 'Klassifizierungen nach Natur-, Umwelt und Bodenschutzrecht werden verarbeitet.';

INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	o.gml_id,
	'Rechtliche Festlegungen' AS thema,
	'ax_naturumweltoderbodenschutzrecht' AS layer,
	st_multi(wkb_geometry) AS polygon,
	CASE
	WHEN o.gml_id LIKE 'DERP%' THEN
		CASE
		WHEN artderfestlegung IN (1610,1612,1621,1622,1642,1653,1656) THEN 1703
		WHEN artderfestlegung IN (1632,1634,1641,1655,1662) THEN 1704
		END
	ELSE 1703
	END AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ax_naturumweltoderbodenschutzrecht o
WHERE (artderfestlegung=1621 OR (o.gml_id LIKE 'DERP%' AND artderfestlegung IN (1610,1612,1621,1622,1632,1634,1641,1642,1653,1655,1656,1662))) AND endet IS NULL
  AND geometrytype(wkb_geometry) IN ('POLYGON','MULTIPOLYGON');

INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Rechtliche Festlegungen' AS thema,
	'ax_naturumweltoderbodenschutzrecht' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		t.wkb_geometry AS point,
		CASE
		WHEN o.gml_id LIKE 'DERP%' THEN
			coalesce(
				t.schriftinhalt,
				CASE
				WHEN artderfestlegung=1610 THEN 'Schutzfläche'
				WHEN artderfestlegung=1656 THEN 'Ausgleichsfläche'
				WHEN artderfestlegung IN (1612,1621,1622,1632,1634,1641,1642,1653,1655,1662) THEN
					(select v from alkis_wertearten where element='ax_naturumweltoderbodenschutzrecht' AND bezeichnung='artderfestlegung' AND k=artderfestlegung::text)
				END
			)
		ELSE
			(select v from alkis_wertearten where element='ax_naturumweltoderbodenschutzrecht' AND bezeichnung='artderfestlegung' AND k=artderfestlegung::text)
		END AS text,
		coalesce(
			t.signaturnummer,
			CASE
			WHEN o.gml_id LIKE 'DERP%' THEN
				CASE
				WHEN artderfestlegung IN (1610,1612,1621,1622,1642) THEN '4143'
				WHEN artderfestlegung IN (1632,1634,1641) THEN '4144'
				WHEN artderfestlegung IN (1655,1662) THEN 'RP4075'
				WHEN artderfestlegung=1656 THEN 'RP4076'
				END
			ELSE '4143'
			END
		) AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_naturumweltoderbodenschutzrecht o
	JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='ADF' AND t.endet IS NULL
	WHERE (artderfestlegung=1621 OR (o.gml_id LIKE 'DERP%' AND artderfestlegung IN (1610,1612,1621,1622,1632,1634,1641,1642,1653,1655,1656,1662))) AND o.endet IS NULL
) AS o WHERE NOT text IS NULL;

-- Namen
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Rechtliche Festlegungen' AS thema,
	'ax_naturumweltoderbodenschutzrecht' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		'"' || coalesce(t.schriftinhalt,name) || '"' AS text,
		coalesce(t.signaturnummer,'4143') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_naturumweltoderbodenschutzrecht o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='NAM' AND t.endet IS NULL
	WHERE o.endet IS NULL AND (NOT name IS NULL OR NOT t.schriftinhalt IS NULL)
) AS n WHERE NOT text IS NULL;

/*
--
-- Schutzgebiet nach Natur-, Umwelt- oder Bodenschutzrecht (71007)
-- TODO: Keine Geometrie?
--

SELECT 'Schutzgebiete nach Natur-, Umwelt und Bodenschutzrecht werden verarbeitet.';

INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	'Rechtliche Festlegungen' AS thema,
	'ax_schutzgebietnachnaturumweltoderbodenschutzrecht' AS layer,
	st_multi(wkb_geometry) AS polygon,
	1703 AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ax_schutzgebietnachnaturumweltoderbodenschutzrecht o
WHERE artderfestlegung=1621 AND endet IS NULL;

INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Rechtliche Festlegungen' AS thema,
	'ax_schutzgebietnachnaturumweltoderbodenschutzrecht' AS layer,
	point,
	text,
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		t.wkb_geometry AS point,
		(select v from alkis_wertearten where element='ax_schutzgebietnachnaturumweltoderbodenschutzrecht ' AND bezeichnung='artderfestlegung' AND k=artderfestlegung::text) AS text,
		coalesce(t.signaturnummer,'4143') AS signaturnummer,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_schutzgebietnachnaturumweltoderbodenschutzrecht o
	JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='ADF' AND t.endet IS NULL
	WHERE o.endet IS NULL
) AS o WHERE NOT text IS NULL;

-- Namen
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Rechtliche Festlegungen' AS thema,
	'ax_schutzgebietnachnaturumweltoderbodenschutzrecht' AS layer,
	point,
	text,
	signaturnummer,
	modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		'"' || name || '"' AS text,
		coalesce(t.signaturnummer,'4143') AS signaturnummer,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_schutzgebietnachnaturumweltoderbodenschutzrecht o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='NAM' AND t.endet IS NULL
	WHERE o.endet IS NULL AND NOT name IS NULL
) AS n WHERE NOT text IS NULL;
*/

--
-- Bauraum- oder Bauordnungsrecht (71008)
--

SELECT 'Bauraum und Bauordnungsrecht wird verarbeitet.';

INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	'Rechtliche Festlegungen' AS thema,
	'ax_bauraumoderbodenordnungsrecht' AS layer,
	st_multi(wkb_geometry) AS polygon,
	1704 AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ax_bauraumoderbodenordnungsrecht o
WHERE endet IS NULL;

INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Rechtliche Festlegungen' AS thema,
	'ax_bauraumoderbodenordnungsrecht' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		coalesce(
			t.schriftinhalt,
			CASE
			WHEN artderfestlegung=1750 THEN 'Umlegung'
			WHEN artderfestlegung=1840 THEN 'Sanierung'
			WHEN artderfestlegung IN (2100,2110,2120,2130,2140,2150) THEN 'Flurbereinigung'
			WHEN o.gml_id LIKE 'DERP%' THEN
				CASE
				WHEN artderfestlegung IN (1760,2610) THEN
					(select v from alkis_wertearten where element='ax_bauraumoderbodenordnungsrecht' AND bezeichnung='artderfestlegung' AND k=artderfestlegung::text)
				WHEN artderfestlegung=1810 THEN 'Entwickungsbereich'
				END
			END
		) AS text,
		coalesce(
			t.signaturnummer,
			CASE
			WHEN o.gml_id LIKE 'DERP%' AND artderfestlegung IN (1760,2610)
			THEN 'RP4075'
			ELSE '4144'
			END
		) AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_bauraumoderbodenordnungsrecht o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='ADF' AND t.endet IS NULL
	WHERE o.endet IS NULL
) AS o WHERE NOT text IS NULL;

-- Namen
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Rechtliche Festlegungen' AS thema,
	'ax_bauraumoderbodenordnungsrecht' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		CASE
		WHEN artderfestlegung=1750 THEN 'Umlegung'
		WHEN artderfestlegung=1840 THEN 'Sanierung'
		WHEN artderfestlegung IN (2100,2110,2120,2130,2140,2150) THEN 'Flurbereinigung'
		END
		|| ' "' || name || '"' AS text,
		coalesce(t.signaturnummer,'4144') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_bauraumoderbodenordnungsrecht o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='NAM' AND t.endet IS NULL
	WHERE o.endet IS NULL AND NOT name IS NULL AND artderfestlegung IN (1750,1840,2100,2110,2120,2130,2140,2150)
) AS n WHERE NOT text IS NULL;

--
-- Denkmalschutzrecht (71009; RP)
--

SELECT 'Denkmalschutzrecht wird verarbeitet.';

INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	'Rechtliche Festlegungen' AS thema,
	'ax_denkmalschutzrecht' AS layer,
	st_multi(wkb_geometry) AS polygon,
	'1704' AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ax_denkmalschutzrecht o
WHERE endet IS NULL AND gml_id LIKE 'DERP%';

INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Rechtliche Festlegungen' AS thema,
	'ax_denkmalschutzrecht' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		t.wkb_geometry AS point,
		CASE
		WHEN artderfestlegung=2910 THEN 'DZ'
		WHEN artderfestlegung=2930 THEN 'GSG'
		END AS text,
		coalesce(t.signaturnummer,'RP4144') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_denkmalschutzrecht o
	JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='ADF' AND t.endet IS NULL
	WHERE o.endet IS NULL AND o.gml_id LIKE 'DERP%'
) AS o WHERE NOT text IS NULL;

--
-- Sonstiges Recht (71011)
--

SELECT 'Sonstiges Recht wird verarbeitet.';

INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	gml_id,
	'Rechtliche Festlegungen' AS thema,
	'ax_sonstigesrecht' AS layer,
	st_multi(wkb_geometry) AS polygon,
	1704 AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ax_sonstigesrecht o
WHERE artderfestlegung=1740 AND endet IS NULL;

INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Rechtliche Festlegungen' AS thema,
	'ax_sonstigesrecht' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		CASE
		WHEN o.gml_id LIKE 'DERP%' THEN
			coalesce(
				t.schriftinhalt,
				CASE
				WHEN artderfestlegung=4720 THEN 'MÜG'
				WHEN artderfestlegung=7000 THEN 'WLG'
				WHEN artderfestlegung=7100 THEN 'STL'
				WHEN artderfestlegung=7300 THEN 'SSL'
				END
			)
		ELSE 'Truppenübungsplatz'::text
		END AS text,
		coalesce(t.signaturnummer,'4144') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_sonstigesrecht o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='ART' AND t.endet IS NULL
	WHERE o.endet IS NULL AND (NOT name IS NULL AND artderfestlegung=4720)
) AS n WHERE NOT text IS NULL;

-- Namen
INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Rechtliche Festlegungen' AS thema,
	'ax_sonstigesrecht' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		'Truppenübungsplatz "' || name || '"' AS text,
		coalesce(t.signaturnummer,'4144') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_sonstigesrecht o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='NAM' AND t.endet IS NULL
	WHERE o.endet IS NULL AND (NOT name IS NULL AND artderfestlegung=4720)
) AS n WHERE NOT text IS NULL;

--
-- Landwirtschaftliche Nutzung (72004; RP)
--

INSERT INTO po_polygons(gml_id,thema,layer,polygon,signaturnummer,modell)
SELECT
	o.gml_id,
	'Landwirtschaftliche Nutzung' AS thema,
	'ax_bewertung' AS layer,
	st_multi(wkb_geometry) AS polygon,
	1704 AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ax_bewertung o
WHERE gml_id LIKE 'DERP%' AND endet IS NULL AND geometrytype(wkb_geometry) IN ('POLYGON','MULTIPOLYGON');

INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	o.gml_id,
	'Landwirtschaftliche Nutzung' AS thema,
	'ax_bewertung' AS layer,
	t.wkb_geometry AS point,
	t.schriftinhalt AS text,
	4107 AS signaturnummer,
	drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
	coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
FROM ax_bewertung o
JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='KLA' AND t.endet IS NULL AND t.schriftinhalt IS NOT NULL
WHERE o.gml_id LIKE 'DERP%' AND o.endet IS NULL;

--
-- Wohnplatz (74005)
--

SELECT 'Wohnplätze werden verarbeitet.';

INSERT INTO po_labels(gml_id,thema,layer,point,text,signaturnummer,drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,modell)
SELECT
	gml_id,
	'Flurstücke' AS thema,
	'ax_wohnplatz' AS layer,
	point,
	text,
	signaturnummer,
	drehwinkel, horizontaleausrichtung, vertikaleausrichtung, skalierung, fontsperrung, modell
FROM (
	SELECT
		o.gml_id,
		coalesce(t.wkb_geometry,st_centroid(o.wkb_geometry)) AS point,
		name AS text,
		coalesce(t.signaturnummer,'4200') AS signaturnummer,
		drehwinkel,horizontaleausrichtung,vertikaleausrichtung,skalierung,fontsperrung,
		coalesce(t.advstandardmodell||t.sonstigesmodell,o.advstandardmodell||o.sonstigesmodell) AS modell
	FROM ax_wohnplatz o
	LEFT OUTER JOIN ap_pto t ON ARRAY[o.gml_id] <@ t.dientzurdarstellungvon AND t.art='NAM' AND t.endet IS NULL
	WHERE o.endet IS NULL AND NOT name IS NULL
) AS n WHERE NOT text IS NULL;

--
-- Migrationsobjekt: Gebäudeausgestaltung (91001)
--

SELECT 'Migrationsobjekte werden verarbeitet.';

INSERT INTO po_lines(gml_id,thema,layer,line,signaturnummer,modell)
SELECT
	gml_id,
	'Gebäude' AS thema,
	'ax_gebaeudeausgestaltung' AS layer,
	st_multi(wkb_geometry) AS line,
	CASE
	WHEN darstellung=1012 THEN 2030 -- öffentliches Gebäude
	WHEN darstellung=1013 THEN 2031 -- nicht öffentliches Gebäude
	WHEN darstellung=1014 THEN 2305 -- Offene Begrenzungslinie eines Gebäude
	END AS signaturnummer,
	advstandardmodell||sonstigesmodell
FROM ax_gebaeudeausgestaltung
WHERE endet IS NULL AND darstellung IN (1012,1013,1014);

SELECT
	darstellung AS "Migrationsobjekte ohne Signatur",
	count(*) AS "Anzahl"
FROM ax_gebaeudeausgestaltung
WHERE NOT darstellung IN (1012,1013,1014)
GROUP BY darstellung;

--
--
--

SELECT 'Nachbearbeitung läuft...';

-- Polygonsignaturen aufteilen (1XXX = Fläche, 2XXX = Linie)
UPDATE po_polygons SET
	sn_flaeche=CASE
	           WHEN signaturnummer::int%10000 BETWEEN 1000 AND 1999 THEN signaturnummer::int%10000
	           WHEN signaturnummer::int/10000 BETWEEN 1000 AND 1999 THEN signaturnummer::int/10000
		   ELSE NULL
		   END,
	sn_randlinie=CASE
	           WHEN signaturnummer::int%10000 BETWEEN 2000 AND 2999 THEN signaturnummer::int%10000
	           WHEN signaturnummer::int/10000 BETWEEN 2000 AND 2999 THEN signaturnummer::int/10000
		   END
	WHERE signaturnummer ~ E'^[0-9]+$';

--
-- Randlinien als 'normale' Linien ergänzen
--

DELETE FROM alkis_linie WHERE signaturnummer LIKE 'rn%';
DELETE FROM alkis_linien WHERE signaturnummer LIKE 'rn%';

INSERT INTO alkis_linien(signaturnummer,darstellungsprioritaet,farbe,name,seite)
        SELECT 'rn'||signaturnummer,darstellungsprioritaet,alkis_randlinie.farbe,name,seite
                FROM alkis_flaechen
                JOIN alkis_randlinie ON alkis_flaechen.randlinie=alkis_randlinie.id;

CREATE TEMPORARY SEQUENCE rnlinie_seq;
SELECT setval('rnlinie_seq',max(id)+1) FROM alkis_linie;

INSERT INTO alkis_linie(signaturnummer,id,i,strichart,abschluss,scheitel,strichstaerke)
        SELECT 'rn'||signaturnummer,nextval('rnlinie_seq'),0,strichart,abschluss,scheitel,strichstaerke
                FROM alkis_flaechen
                JOIN alkis_randlinie ON alkis_flaechen.randlinie=alkis_randlinie.id;

DROP SEQUENCE rnlinie_seq;

-- Array -> Set
UPDATE po_points   SET modell=(SELECT array_agg(modell) FROM (SELECT DISTINCT unnest(modell) AS modell ORDER BY modell) AS foo);
UPDATE po_lines    SET modell=(SELECT array_agg(modell) FROM (SELECT DISTINCT unnest(modell) AS modell ORDER BY modell) AS foo);
UPDATE po_polygons SET modell=(SELECT array_agg(modell) FROM (SELECT DISTINCT unnest(modell) AS modell ORDER BY modell) AS foo);
UPDATE po_labels   SET modell=(SELECT array_agg(modell) FROM (SELECT DISTINCT unnest(modell) AS modell ORDER BY modell) AS foo);


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
        SELECT modell AS modell FROM po_points   UNION ALL
	SELECT modell AS modell FROM po_lines    UNION ALL
        SELECT modell AS modell FROM po_polygons UNION ALL
        SELECT modell AS modell from po_lines    UNION ALL
        SELECT modell AS modell from po_labels
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
	SET sn_randlinie='rn'||signaturnummer
	WHERE EXISTS (SELECT * FROM alkis_flaechen WHERE alkis_flaechen.signaturnummer=po_polygons.signaturnummer AND NOT alkis_flaechen.randlinie IS NULL);

-- Winkel in Grad berechnen
UPDATE po_points SET drehwinkel_grad=degrees(drehwinkel);

-- Winkel in Grad und Ausrichtung belegen
UPDATE po_labels SET skalierung=1 WHERE skalierung IS NULL;
UPDATE po_labels
	SET
		drehwinkel_grad=degrees(drehwinkel),
		color_umn=(SELECT alkis_farben.umn FROM alkis_farben JOIN alkis_schriften ON alkis_schriften.farbe=alkis_farben.id WHERE alkis_schriften.signaturnummer=po_labels.signaturnummer),
		font_umn=(
			SELECT
				CASE
				WHEN art = 'Arial' AND effekt IS NULL AND coalesce(fontsperrung,0)=0 THEN
					CASE
					WHEN sperrung_pt IS NULL THEN
						CASE
						WHEN stil='Normal' THEN 'arial'
						WHEN stil='Kursiv' THEN 'arial-italic'
						WHEN stil='Fett' THEN 'arial-bold'
						WHEN stil='Fett, Kursiv' THEN 'arial-bold-italic'
						END
					WHEN sperrung_pt=10 THEN 'arial-spaced-10'
					END
				END
			FROM alkis_schriften
			WHERE alkis_schriften.signaturnummer=po_labels.signaturnummer
		),
		size_umn=0.25/0.0254*skalierung*(SELECT grad_pt FROM alkis_schriften WHERE alkis_schriften.signaturnummer=po_labels.signaturnummer),
		alignment_dxf=coalesce(
			CASE
			WHEN horizontaleausrichtung='linksbündig' THEN
				CASE
				WHEN vertikaleausrichtung='oben' THEN 1
				WHEN vertikaleausrichtung='Mitte' THEN 4
				WHEN vertikaleausrichtung='Basis' THEN 7
				END
			WHEN horizontaleausrichtung='zentrisch' THEN
				CASE
				WHEN vertikaleausrichtung='oben' THEN 2
				WHEN vertikaleausrichtung='Mitte' THEN 5
				WHEN vertikaleausrichtung='Basis' THEN 8
				END
			WHEN horizontaleausrichtung='rechtsbündig' THEN
				CASE
				WHEN vertikaleausrichtung='oben' THEN 3
				WHEN vertikaleausrichtung='Mitte' THEN 6
				WHEN vertikaleausrichtung='Basis' THEN 9
				END
			END,
			(SELECT alignment_dxf FROM alkis_schriften WHERE alkis_schriften.signaturnummer=po_labels.signaturnummer)
		),
		darstellungsprioritaet=(SELECT darstellungsprioritaet FROM alkis_schriften WHERE alkis_schriften.signaturnummer=po_labels.signaturnummer);

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
			l.layer || '_pfeil' AS layer,
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
	WHERE gml_id LIKE 'DERP%'
	  AND layer='ax_flurstueck_nummer'
	  AND EXISTS (SELECT * FROM ap_pto t WHERE ARRAY[po_labels.gml_id] <@ t.dientzurdarstellungvon AND t.endet IS NULL AND t.art IS NULL);

UPDATE po_lines
	SET
		layer='ax_flurstueck_nummer_rpnoart',
		line=st_translate(line,0,3)
	WHERE gml_id LIKE 'DERP%'
	  AND layer='ax_flurstueck_nummer'
	  AND EXISTS (SELECT * FROM ap_pto t WHERE ARRAY[po_lines.gml_id] <@ t.dientzurdarstellungvon AND t.endet IS NULL AND t.art IS NULL);

--
-- Indizes
--

SELECT 'Indizierung Punkte...';
CREATE INDEX po_points_point_idx ON po_points USING gist (point);
CREATE INDEX po_points_gmlid_idx ON po_points(gml_id);
CREATE INDEX po_points_thema_idx ON po_points(thema);
CREATE INDEX po_points_layer_idx ON po_points(layer);
CREATE INDEX po_points_sn_idx ON po_points(signaturnummer);
CREATE INDEX po_points_modell_idx ON po_points USING gin (modell);

SELECT 'Indizierung Linien...';
CREATE INDEX po_lines_line_idx ON po_lines USING gist (line);
CREATE INDEX po_lines_gmlid_idx ON po_lines(gml_id);
CREATE INDEX po_lines_thema_idx ON po_lines(thema);
CREATE INDEX po_lines_layer_idx ON po_lines(layer);
CREATE INDEX po_lines_sn_idx ON po_lines(signaturnummer);
CREATE INDEX po_lines_modell_idx ON po_lines USING gin (modell);

SELECT 'Indizierung Flächen...';
CREATE INDEX po_polygons_polygons_idx ON po_polygons USING gist (polygon);
CREATE INDEX po_polygons_gmlid_idx ON po_polygons(gml_id);
CREATE INDEX po_polygons_thema_idx ON po_polygons(thema);
CREATE INDEX po_polygons_layer_idx ON po_polygons(layer);
CREATE INDEX po_polygons_snf_idx ON po_polygons(sn_flaeche);
CREATE INDEX po_polygons_snr_idx ON po_polygons(sn_randlinie);
CREATE INDEX po_polygons_modell_idx ON po_polygons USING gin (modell);

SELECT 'Indizierung Beschriftungen...';
CREATE INDEX po_labels_point_idx ON po_labels USING gist (point);
CREATE INDEX po_labels_line_idx ON po_labels USING gist (line);
CREATE INDEX po_labels_gmlid_idx ON po_labels(gml_id);
CREATE INDEX po_labels_thema_idx ON po_labels(thema);
CREATE INDEX po_labels_layer_idx ON po_labels(layer);
CREATE INDEX po_labels_text_idx ON po_labels(text);
CREATE INDEX po_labels_sn_idx ON po_labels(signaturnummer);
CREATE INDEX po_labels_modell_idx ON po_labels USING gin (modell);

SELECT 'Lösche nicht darzustellende Signaturen...';

/*
SELECT
	signaturnummer,thema,layer,count(*)
	FROM po_points
	WHERE signaturnummer IS NULL OR signaturnummer='6000'
	GROUP BY signaturnummer,thema,layer
	ORDER BY count(*) DESC;
*/

DELETE FROM po_points WHERE signaturnummer IS NULL OR signaturnummer='6000';
DELETE FROM po_lines WHERE signaturnummer IS NULL OR signaturnummer='6000';
DELETE FROM po_polygons WHERE signaturnummer IS NULL OR signaturnummer='6000';

DELETE FROM po_labels WHERE signaturnummer IS NULL OR signaturnummer='6000' OR text IS NULL;

DELETE FROM alkis_linien WHERE signaturnummer='6000';
DELETE FROM alkis_flaechen WHERE signaturnummer='6000';
DELETE FROM alkis_schriften WHERE signaturnummer='6000';
