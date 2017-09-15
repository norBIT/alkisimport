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
	b1l DOUBLE PRECISION[];
	r0 RECORD;
	r1 RECORD;
BEGIN
	DELETE FROM po_lines WHERE layer='ax_boeschungkliff';

	FOR r0 IN SELECT gml_id, advstandardmodell||sonstigesmodell AS modell FROM ax_boeschungkliff WHERE endet IS NULL
	LOOP
		-- RAISE NOTICE 'gml_id:%', r0.gml_id;

		SELECT st_linemerge(st_collect(wkb_geometry)) INTO uk FROM ax_gelaendekante WHERE ARRAY[r0.gml_id] <@ istteilvon AND artdergelaendekante=1230 AND endet IS NULL;

		-- RAISE NOTICE 'Unterkante:%', st_astext(uk);

		SELECT st_union(wkb_geometry) INTO sk FROM ax_gelaendekante WHERE ARRAY[r0.gml_id] <@ istteilvon AND artdergelaendekante=1240 AND endet IS NULL;
		IF uk IS NOT NULL AND sk IS NOT NULL THEN
			sk := st_union(uk, sk);
		END IF;

		IF sk IS NULL THEN
			RAISE NOTICE '%: Keine Schnittkante', r0.gml_id;
			CONTINUE;
		END IF;

		SELECT st_maxdistance(sk, ok)*1.1 INTO maxdistance;

		-- RAISE NOTICE 'Schnittkanten:%', st_astext(sk);

		FOR r1 IN
			SELECT (st_dump(st_multi(st_linemerge(st_collect(wkb_geometry))))).geom
			FROM ax_gelaendekante
			WHERE ARRAY[r0.gml_id] <@ istteilvon
			  AND artdergelaendekante=1220
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

			s := CASE WHEN st_distance( alkis_safe_offsetcurve(ok, -0.001, ''::text), uk ) > st_distance( alkis_safe_offsetcurve(ok, 0.001, ''::text), uk ) THEN -1 ELSE 1 END;

			o := 0.0;
			ol := st_length(ok);
			WHILE o < ol-3 LOOP
				-- RAISE NOTICE '1 %: %', r0.gml_id, o;

				p0 := st_lineinterpolatepoint(ok, o/ol);
				p1 := st_lineinterpolatepoint(ok, (o+0.001)/ol);
				l := st_distance(p0, p1);

				dx := (st_x(p1) - st_x(p0)) / l;
				dy := (st_y(p1) - st_y(p0)) / l;

				b := st_makeline(
					p0,
					st_translate(p0, s * dy * maxdistance, -s * dx * maxdistance)
				);

				int := st_intersection(b, sk);

				IF int IS NOT NULL AND NOT st_isempty(int) THEN
					IF geometrytype(int) = 'POINT' THEN
						b := st_makeline(p0, int);
					ELSE
						b := (SELECT st_makeline(p0, (SELECT * FROM (SELECT (st_dump(int)).geom AS pi) AS pi ORDER BY st_distance(p0, pi) LIMIT 1)));
					END IF;

					b1 := array_append(b1, b);
					b1l := array_append(b1l, st_length(b));
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

						IF int IS NULL OR st_isempty(int) THEN
							CONTINUE;
						ELSIF geometrytype(int) = 'POINT' THEN
							b := st_makeline(p0, int);
						ELSE
							b := (SELECT st_makeline(p0, (SELECT * FROM (SELECT (st_dump(int)).geom AS pi) AS pi ORDER BY st_distance(p0, pi) LIMIT 1)));
						END IF;

						b1[i] := b;
						b1l[i] := st_length(b);
					END LOOP;
				END;
			END IF;

			i := 2;
			o := 3.0;
			WHILE o < ol-3 LOOP
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

				o := o + 6.0;
				i := i + 1;
			END LOOP;

			IF b1 IS NOT NULL AND array_length(b1,1)>0 THEN
				INSERT INTO po_lines(
					gml_id, thema, layer, line, signaturnummer, modell
				) VALUES (
					r0.gml_id, 'Topographie', 'ax_boeschungkliff', st_multi(st_collect(b1)), '2531', r0.modell
				);
			ELSE
				RAISE NOTICE '%: Böschungsgeometrie leer', r0.gml_id;
			END IF;


			b1l := ARRAY[]::double precision[];
			b1 := ARRAY[]::GEOMETRY[];
		END LOOP;
	END LOOP;

	RETURN 'Böschungen berechnet.';
END;
$$ LANGUAGE plpgsql;

SELECT pg_temp.alkis_boeschung();
