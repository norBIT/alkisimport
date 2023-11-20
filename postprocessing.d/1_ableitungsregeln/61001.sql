SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--
-- Böschungslinie, Kliff (61001)
--

SELECT 'Böschungen und Kliffe werden verarbeitet.';

SELECT alkis_dropobject('alkis_boeschung');
CREATE OR REPLACE FUNCTION pg_temp.alkis_boeschung() RETURNS varchar AS $$
DECLARE
	ok GEOMETRY;
	uk GEOMETRY;
	sk GEOMETRY;
	fk GEOMETRY;
	maxdistance DOUBLE PRECISION;
	p0 GEOMETRY;
	p1 GEOMETRY;
	i INTEGER;
	dx DOUBLE PRECISION;
	dy DOUBLE PRECISION;
	s INTEGER;
	l DOUBLE PRECISION;
	ol DOUBLE PRECISION;
	o DOUBLE PRECISION;
	int GEOMETRY;
	b GEOMETRY;
	b1 GEOMETRY[];
	b1o DOUBLE PRECISION[];
	b1l DOUBLE PRECISION[];
	r0 RECORD;
	r1 RECORD;
	r2 RECORD;
	n INTEGER;
	kokn INTEGER;
	bgln INTEGER;
	kskn INTEGER;
BEGIN
	DELETE FROM po_lines WHERE layer='ax_boeschungkliff';

	kokn := 0;
	bgln := 0;
	kskn := 0;
	n := 0;
	FOR r0 IN SELECT gml_id, advstandardmodell||sonstigesmodell AS modell FROM ax_boeschungkliff WHERE endet IS NULL
	LOOP
		n := n + 1;
		-- RAISE NOTICE 'gml_id:% %', r0.gml_id, n;

		SELECT st_linemerge(st_collect(st_force2d(wkb_geometry))) INTO uk FROM ax_strukturlinie3d WHERE ARRAY[r0.gml_id] <@ istteilvon AND art=1230 AND endet IS NULL;

		-- RAISE NOTICE 'Unterkante:%', st_astext(uk);

		-- Alle Kanten sind Schnittkanten
		SELECT st_union(st_force2d(wkb_geometry)) INTO sk FROM ax_strukturlinie3d WHERE ARRAY[r0.gml_id] <@ istteilvon AND endet IS NULL;
		IF sk IS NULL THEN
			kskn := kskn + 1;
			-- RAISE NOTICE '%: Keine Schnittkante', r0.gml_id;
			CONTINUE;
		END IF;

		-- RAISE NOTICE 'Schnittkanten:%', st_astext(sk);

		-- Oberkante(n) iterieren (MULTILINESTRINGs ggf. zerlegen)
		FOR r1 IN
			SELECT (st_dump(st_multi(st_linemerge(st_collect(st_force2d(wkb_geometry)))))).geom
			FROM ax_strukturlinie3d
			WHERE ARRAY[r0.gml_id] <@ istteilvon
			  AND art=1220
			  AND endet IS NULL
		LOOP
			ok := r1.geom;
			-- RAISE NOTICE 'Oberkante:%', st_astext(ok);
			IF ok IS NULL THEN
				RAISE NOTICE '%: Oberkante fehlt', r0.gml_id;
				CONTINUE;
			END IF;

			IF geometrytype(ok) <> 'LINESTRING' THEN
				RAISE NOTICE '%: LINESTRING als Oberkante erwartet: %', r0.gml_id, st_astext(ok);
				CONTINUE;
			END IF;

			ol := st_length(ok);
			IF ol < 6.0 THEN
				-- RAISE NOTICE '%: Oberkante %m < 6m: %', r0.gml_id, ol, st_astext(ok);
				kokn := kokn + 1;
				CONTINUE;
			END IF;

			fk := sk;

			-- st_maxdistance braucht mind. 3 Punkte
			IF st_npoints(ok) = 2 THEN
				ok := st_makeline(ARRAY[
					st_startpoint(ok),
					st_lineinterpolatepoint(ok, 0.5),
					st_endpoint(ok)
				]);
			END IF;

			IF st_npoints(fk) = 2 THEN
				fk := st_makeline(ARRAY[
					st_startpoint(fk),
					st_lineinterpolatepoint(fk, 0.5),
					st_endpoint(fk)
				]);
			END IF;

			SELECT st_maxdistance(fk, ok)*1.1 INTO maxdistance;
			IF maxdistance IS NULL THEN
				maxdistance := 0;
				FOR r2 IN SELECT (st_dump(st_multi(fk))).geom
				LOOP
					maxdistance := greatest(
						maxdistance,
						st_distance(st_startpoint(r2.geom), st_startpoint(ok))*1.1,
						st_distance(st_endpoint(r2.geom), st_startpoint(ok))*1.1,
						st_distance(st_startpoint(r2.geom), st_endpoint(ok))*1.1,
						st_distance(st_endpoint(r2.geom), st_endpoint(ok))*1.1
					);
				END LOOP;

				IF maxdistance = 0 THEN
					RAISE NOTICE '%: Maximalabstand leer [ok:%; fk:%]', r0.gml_id, st_astext(ok), st_astext(fk);
					CONTINUE;
				END IF;
			END IF;

			s := CASE WHEN st_distance( alkis_safe_offsetcurve(ok, -0.001, ''::text), uk ) > st_distance( alkis_safe_offsetcurve(ok, 0.001, ''::text), uk ) THEN -1 ELSE 1 END;

			-- Schnittkante auf Oberkante verlängern
			p0 := st_startpoint(ok);
			p1 := (SELECT p FROM (SELECT st_pointn(uk,generate_series(1, st_npoints(uk))) AS p) AS p ORDER BY st_distance(p0,p) ASC LIMIT 1);
			IF NOT st_equals(p0, p1) THEN
				-- RAISE NOTICE '%: Verlängerung Anfang:% [snap % to %]', r0.gml_id, st_astext(st_makeline(p0, p1)), st_astext(st_startpoint(ok)), st_astext(uk);
				fk := st_union(fk, st_makeline(p0, p1));
			END IF;

			p0 := st_endpoint(ok);
			p1 := (SELECT p FROM (SELECT st_pointn(uk,generate_series(1, st_npoints(uk))) AS p) AS p ORDER BY st_distance(p0,p) ASC LIMIT 1);
			IF NOT st_equals(p0, p1) THEN
				-- RAISE NOTICE '%: Verlängerung Ende:% [snap % to %]', r0.gml_id, st_astext(st_makeline(p0, p1)), st_astext(st_endpoint(ok)), st_astext(uk);
				fk := st_union(fk, st_makeline(p0, p1));
			END IF;

			o := greatest((ol::numeric % 6.0) / 2.0, 0.01);
			WHILE o < ol-3 LOOP
				p0 := st_lineinterpolatepoint(ok, o/ol);
				p1 := st_lineinterpolatepoint(ok, (o+0.001)/ol);
				l := st_distance(p0, p1);

				dx := (st_x(p1) - st_x(p0)) / l;
				dy := (st_y(p1) - st_y(p0)) / l;

				b := st_makeline(
					p0,
					st_translate(p0, s * dy * maxdistance, -s * dx * maxdistance)
				);

				int := st_intersection(b, fk);

				IF int IS NOT NULL AND NOT st_isempty(int) THEN
					-- RAISE NOTICE '%: % : int % [%:%]', r0.gml_id, o, st_astext(int), st_astext(b), st_astext(fk);
					b := st_makeline(p0, (SELECT * FROM (SELECT (st_dump(st_multi(int))).geom AS pi) AS pi WHERE st_distance(p0, pi)>0.01 ORDER BY st_distance(p0, pi) ASC LIMIT 1));
					IF b IS NOT NULL THEN
						b1 := array_append(b1, b);
						b1l := array_append(b1l, st_length(b));
						b1o := array_append(b1o, o);
						-- INSERT INTO po_lines(gml_id, thema, layer, line, signaturnummer, modell) VALUES (r0.gml_id, 'Topographie', 'ax_boeschungkliff-t'||array_length(b1,1)||'-'||o, st_multi(b), '2531', r0.modell);
						-- RAISE NOTICE '%: % : % : %', r0.gml_id, o, array_length(b1,1), st_astext(b);
					END IF;
				END IF;

				o := o + 6.0;
			END LOOP;

			IF b1 IS NOT NULL AND array_length(b1,1)>1 THEN
				DECLARE
					idxs INTEGER[];
					j INTEGER;
					k INTEGER;
					b2 GEOMETRY[];
				BEGIN
					SELECT array_agg(g.idx) INTO idxs FROM (
						SELECT g.idx FROM (
							SELECT (g).path[1] AS idx,st_length((g).geom) AS len FROM (
								SELECT st_dump(st_collect(b1)) AS g
							) AS g
						) AS g ORDER BY g.len DESC
					) AS g;

					FOR j IN 1..array_upper(idxs, 1) LOOP
						i := idxs[j];

						b2 := ARRAY[]::GEOMETRY[];
						FOR k IN 1..array_upper(b1, 1) LOOP
							IF k<>i THEN
								b2 := array_append(b2, b1[k]);
							END IF;
						END LOOP;

						b := st_collect(b2);
						p0 := st_startpoint(b1[i]);
						int := st_intersection(b1[i], b);

						IF int IS NULL OR st_isempty(int) OR st_equals(int,p0) THEN
							CONTINUE;
						ELSIF geometrytype(int) = 'POINT' THEN
							b := st_makeline(p0, int);
						ELSE
							b := (SELECT st_makeline(p0, (SELECT * FROM (SELECT (st_dump(int)).geom AS pi) AS pi WHERE st_distance(p0,pi)>0.01 ORDER BY st_distance(p0, pi) LIMIT 1)));
						END IF;

						b1[i] := b;
						b1l[i] := st_length(b);
					END LOOP;
				END;
			END IF;

			IF array_length(b1o, 1) > 0 THEN
				FOR i IN 2..array_upper(b1o, 1) LOOP
					o := (b1o[i-1] + b1o[i]) / 2.0;

					p0 := st_lineinterpolatepoint(ok, o/ol);
					p1 := st_lineinterpolatepoint(ok, (o+0.001)/ol);
					l := st_distance(p0, p1);

					dx := (st_x(p1) - st_x(p0)) / l;
					dy := (st_y(p1) - st_y(p0)) / l;

					l := (b1l[i-1]+b1l[i])/4;

					b1 := array_append(
						b1,
						st_makeline(
							p0,
							st_translate(p0, s * dy * l, -s * dx * l)
						)
					);
				END LOOP;
			END IF;

			IF b1 IS NOT NULL AND array_length(b1,1)>0 THEN
				INSERT INTO po_lines(
					gml_id, gml_ids, thema, layer, line, signaturnummer, modell
				) VALUES (
					r0.gml_id, ARRAY[r0.gml_id], 'Topographie', 'ax_boeschungkliff', st_multi(st_collect(b1)), '2531', r0.modell
				);
			ELSE
				bgln := bgln + 1;
				-- RAISE NOTICE '%: Böschungsgeometrie leer [ol:%; md:% ok:%; fk:%]', r0.gml_id, ol, maxdistance, st_astext(ok), st_astext(fk);
			END IF;


			b1o := ARRAY[]::double precision[];
			b1l := ARRAY[]::double precision[];
			b1 := ARRAY[]::GEOMETRY[];
		END LOOP;
	END LOOP;

	RAISE NOTICE '% Böschungen', n;

	IF kokn > 0 THEN
		RAISE NOTICE '% Böschungen mit Oberkantelänge < 6m', bgln;
	END IF;

	IF bgln > 0 THEN
		RAISE NOTICE '% Böschungen mit leerer Geometrie', bgln;
	END IF;

	IF kskn > 0 THEN
		RAISE NOTICE '% Böschungen ohne Schnittkanten', kskn;
	END IF;

	RETURN 'Böschungen berechnet.';
END;
$$ LANGUAGE plpgsql;

SELECT pg_temp.alkis_boeschung();
