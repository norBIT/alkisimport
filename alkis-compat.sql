/***************************************************************************
 *                                                                         *
 * Project:  norGIS ALKIS Import                                           *
 * Purpose:  PostGIS-Vorwärtskompatibilitätsfunktionen                     *
 * Author:   Jürgen E. Fischer <jef@norbit.de>                             *
 *                                                                         *
 ***************************************************************************
 * Copyright (c) 2012-2023, Jürgen E. Fischer <jef@norbit.de>              *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/

\unset ON_ERROR_STOP
\unset ECHO

SET search_path = public;

CREATE FUNCTION unnest(anyarray) RETURNS SETOF anyelement AS $$
  SELECT $1[i] FROM generate_series(array_lower($1,1), array_upper($1,1)) i;
$$ LANGUAGE 'sql' IMMUTABLE;

SET search_path = :"postgis_schema", :"parent_schema", public;

CREATE FUNCTION st_snaptogrid(geometry,float8,float8) RETURNS geometry AS $$
  SELECT snaptogrid($1,$2,$3);
$$ LANGUAGE 'sql' IMMUTABLE;

CREATE FUNCTION st_geomfromtext(text,integer) RETURNS geometry AS $$
  SELECT geomfromtext($1,$2);
$$ LANGUAGE 'sql' IMMUTABLE;

CREATE FUNCTION st_geometryfromtext(text,integer) RETURNS geometry AS $$
  SELECT geometryfromtext($1,$2);
$$ LANGUAGE 'sql' IMMUTABLE;

CREATE FUNCTION st_geomfromewkt(text) RETURNS geometry AS $$
  SELECT geomfromewkt($1);
$$ LANGUAGE 'sql' IMMUTABLE;

CREATE FUNCTION st_multi(geometry) RETURNS geometry AS $$
  SELECT multi($1);
$$ LANGUAGE 'sql' IMMUTABLE;

CREATE FUNCTION st_intersection(geometry,geometry) RETURNS geometry AS $$
  SELECT intersection($1,$2);
$$ LANGUAGE 'sql' IMMUTABLE;

CREATE FUNCTION st_intersects(geometry,geometry) RETURNS BOOLEAN AS $$
  SELECT intersects($1,$2);
$$ LANGUAGE 'sql' IMMUTABLE;

CREATE FUNCTION st_contains(geometry,geometry) RETURNS BOOLEAN AS $$
  SELECT contains($1,$2);
$$ LANGUAGE 'sql' IMMUTABLE;

CREATE FUNCTION st_astext(geometry) RETURNS TEXT AS $$
  SELECT astext($1);
$$ LANGUAGE 'sql' IMMUTABLE;

CREATE FUNCTION st_numpoints(geometry) RETURNS INTEGER AS $$
  SELECT numpoints($1);
$$ LANGUAGE 'sql' IMMUTABLE;

CREATE FUNCTION st_startpoint(geometry) RETURNS geometry AS $$
  SELECT startpoint($1);
$$ LANGUAGE 'sql' IMMUTABLE;

CREATE FUNCTION st_endpoint(geometry) RETURNS geometry AS $$
  SELECT endpoint($1);
$$ LANGUAGE 'sql' IMMUTABLE;

CREATE FUNCTION st_equals(geometry,geometry) RETURNS BOOLEAN AS $$
  SELECT equals($1,$2);
$$ LANGUAGE 'sql' IMMUTABLE;

CREATE FUNCTION st_isvalid(geometry) RETURNS BOOLEAN AS $$
  SELECT isvalid($1);
$$ LANGUAGE 'sql' IMMUTABLE;

CREATE FUNCTION st_buffer(geometry,float8) RETURNS geometry AS $$
  SELECT buffer($1,$2);
$$ LANGUAGE 'sql' IMMUTABLE;

CREATE FUNCTION st_area(geometry) RETURNS float8 AS $$
  SELECT area($1);
$$ LANGUAGE 'sql' IMMUTABLE;

CREATE FUNCTION st_centroid(geometry) RETURNS geometry AS $$
  SELECT centroid($1);
$$ LANGUAGE 'sql' IMMUTABLE;

CREATE FUNCTION st_pointonsurface(geometry) RETURNS geometry AS $$
  SELECT pointonsurface($1);
$$ LANGUAGE 'sql' IMMUTABLE;

CREATE FUNCTION st_translate(geometry,float8,float8) RETURNS geometry AS $$
  SELECT translate($1,$2,$3);
$$ LANGUAGE 'sql' IMMUTABLE;

CREATE FUNCTION st_makeline(geometry,geometry) RETURNS geometry AS $$
  SELECT makeline($1,$2);
$$ LANGUAGE 'sql' IMMUTABLE;

CREATE FUNCTION st_makeline(geometry[]) RETURNS geometry AS $$
  SELECT makeline_garray($1);
$$ LANGUAGE 'sql' IMMUTABLE;

CREATE FUNCTION st_line_interpolate_point(geometry,float8) RETURNS geometry AS $$
  SELECT line_interpolate_point($1,$2);
$$ LANGUAGE 'sql' IMMUTABLE;

CREATE FUNCTION st_lineinterpolatepoint(geometry,float8) RETURNS geometry AS $$
  SELECT st_line_interpolate_point($1,$2);
$$ LANGUAGE 'sql' IMMUTABLE;

CREATE FUNCTION st_reverse(geometry) RETURNS geometry AS $$
  SELECT reverse($1);
$$ LANGUAGE 'sql' IMMUTABLE;

CREATE FUNCTION st_length(geometry) RETURNS float8 AS $$
  SELECT length($1);
$$ LANGUAGE 'sql' IMMUTABLE;

CREATE FUNCTION st_force_2d(geometry) RETURNS geometry AS $$
  SELECT force_2d($1);
$$ LANGUAGE 'sql' IMMUTABLE;

CREATE FUNCTION st_force2d(geometry) RETURNS geometry AS $$
  SELECT st_force_2d($1);
$$ LANGUAGE 'sql' IMMUTABLE;

CREATE FUNCTION st_srid(geometry) RETURNS integer AS $$
  SELECT srid($1);
$$ LANGUAGE 'sql' IMMUTABLE;

CREATE FUNCTION st_setsrid(geometry,integer) RETURNS geometry AS $$
  SELECT setsrid($1,$2);
$$ LANGUAGE 'sql' IMMUTABLE;

CREATE FUNCTION st_geometryn(geometry,integer) RETURNS geometry AS $$
  SELECT geometryn($1,$2);
$$ LANGUAGE 'sql' IMMUTABLE;

CREATE FUNCTION st_pointn(geometry,integer) RETURNS geometry AS $$
  SELECT pointn($1,$2);
$$ LANGUAGE 'sql' IMMUTABLE;

CREATE FUNCTION st_point(float8, float8) RETURNS geometry AS $$
  SELECT makepoint($1,$2);
$$ LANGUAGE 'sql' IMMUTABLE;

CREATE FUNCTION st_azimuth(geometry, geometry) RETURNS float8 AS $$
  SELECT azimuth($1,$2);
$$ LANGUAGE 'sql' IMMUTABLE;

CREATE FUNCTION st_rotate(geometry, float8) RETURNS geometry AS $$
  SELECT rotate($1,$2);
$$ LANGUAGE 'sql' IMMUTABLE;

CREATE FUNCTION st_rotate(geometry, float8, float8, float8) RETURNS geometry AS $$
  SELECT st_translate( st_rotate( st_translate($1,-$3,-$4), $2), $3, $4 );
$$ LANGUAGE 'sql' IMMUTABLE;

CREATE FUNCTION st_x(geometry) RETURNS float8 AS $$
  SELECT x($1);
$$ LANGUAGE 'sql' IMMUTABLE;

CREATE FUNCTION st_y(geometry) RETURNS float8 AS $$
  SELECT y($1);
$$ LANGUAGE 'sql' IMMUTABLE;

CREATE FUNCTION st_collect(geometry,geometry) RETURNS geometry AS $$
  SELECT collect($1,$2);
$$ LANGUAGE 'sql' IMMUTABLE;

CREATE FUNCTION st_collect(geometry[]) RETURNS geometry AS $$
  SELECT collect_garray($1);
$$ LANGUAGE 'sql' IMMUTABLE;

CREATE FUNCTION st_linemerge(geometry) RETURNS geometry AS $$
  SELECT linemerge($1);
$$ LANGUAGE 'sql' IMMUTABLE;

CREATE FUNCTION st_dump(geometry) RETURNS SETOF geometry_dump AS $$
  SELECT dump($1);
$$ LANGUAGE 'sql' IMMUTABLE;

\i cleanGeometry.sql
CREATE FUNCTION st_makevalid(geometry) RETURNS geometry AS $$
  SELECT cleanGeometry($1);
$$ LANGUAGE 'sql' IMMUTABLE;

CREATE FUNCTION st_xmin(box3d) RETURNS float8 AS $$
  SELECT xmin($1);
$$ LANGUAGE 'sql' IMMUTABLE;

CREATE FUNCTION st_ymin(box3d) RETURNS float8 AS $$
  SELECT ymin($1);
$$ LANGUAGE 'sql' IMMUTABLE;

CREATE FUNCTION st_xmax(box3d) RETURNS float8 AS $$
  SELECT xmax($1);
$$ LANGUAGE 'sql' IMMUTABLE;

CREATE FUNCTION st_ymax(box3d) RETURNS float8 AS $$
  SELECT ymax($1);
$$ LANGUAGE 'sql' IMMUTABLE;

CREATE FUNCTION st_distance(geometry,geometry) RETURNS float8 AS $$
  SELECT distance($1,$2);
$$ LANGUAGE 'sql' IMMUTABLE;

CREATE AGGREGATE st_collect (
        sfunc = geom_accum,
	basetype = geometry,
	stype = geometry[],
	finalfunc = collect_garray
);

CREATE AGGREGATE st_extent(
        sfunc = combine_bbox,
        basetype = geometry,
        stype = box2d
        );

CREATE AGGREGATE st_union (
        sfunc = geom_accum,
	basetype = geometry,
	stype = geometry[],
	finalfunc = unite_garray
);

SET search_path = :"parent_schema", :"postgis_schema", public;

CREATE FUNCTION alkis_intersect_lines( p0 geometry, p1 geometry, p2 geometry, p3 geometry ) RETURNS geometry AS $$
DECLARE
	d float8;
	dx float8;
	dy float8;
	vx float8;
	vy float8;
	wx float8;
	wy float8;
	k float8;
BEGIN
	vx := st_x(p1)-st_x(p0);
	vy := st_y(p1)-st_y(p0);

	wx := st_x(p3)-st_x(p2);
	wy := st_y(p3)-st_y(p2);

	d := vy*wx-vx*wy;

	IF d=0 THEN
		RETURN NULL;
	END IF;

	dx := st_x(p2)-st_x(p0);
	dy := st_y(p2)-st_y(p0);

	k := (dy*wx-dx*wy)/d;

	RETURN st_translate( p0, k*vx, k*vy );
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE FUNCTION alkis_offsetcurve(g0 geometry,offs float8,params text) RETURNS geometry AS $$
DECLARE
        i INTEGER;
	n INTEGER;
	p0 GEOMETRY;
	p1 GEOMETRY;
	p2 GEOMETRY;
	p00 GEOMETRY;
	p01 GEOMETRY;
	p10 GEOMETRY;
	p11 GEOMETRY;
	d0 float8;
	d1 float8;
	dx float8;
	dy float8;
	r GEOMETRY[];
	g GEOMETRY;
BEGIN
	IF params IS NULL OR params<>'' THEN
		RAISE EXCEPTION 'alkis_offsetcurve: params % nicht unterstützt.', params;
	END IF;

	IF geometrytype(g0)='MULTILINESTRING' THEN
		IF st_numgeometries(g0)<>1 THEN
			RETURN NULL;
		END IF;
		g := st_geometryn(g0,1);
	ELSIF geometrytype(g0)<>'LINESTRING' THEN
		RETURN NULL;
	ELSE
		g := g0;
	END IF;

	n := st_numpoints(g);
	IF n IS NULL OR n<2 THEN
		RAISE EXCEPTION '% too short', st_astext(g);
		RETURN NULL;
	END IF;

	BEGIN
		p2 := st_pointn(g,1);
	EXCEPTION WHEN OTHERS THEN
		RAISE NOTICE 'could not get first point from: %', st_astext(g);
	END;

	FOR i IN 2..n LOOP
		p0 := p1;
		p1 := p2;
		d0 := d1;

		IF i>2 THEN
			IF d0=0 THEN
				RAISE EXCEPTION 'alkis_offsetcurve: doppelter Punkt';
			END IF;
			dx := (st_y(p0)-st_y(p1)) * offs / d0;
			dy := (st_x(p1)-st_x(p0)) * offs / d0;
			p00 := st_translate( p0, dx, dy );
			p01 := st_translate( p1, dx, dy );
		END IF;

		BEGIN
			p2 := st_pointn(g,i);
		EXCEPTION WHEN OTHERS THEN
			RAISE EXCEPTION 'could not get point % from: %', i, st_astext(g);
		END;

		d1 := st_distance( p1, p2 );
		IF d1=0 THEN
			p2 := p1;
			p1 := p0;
			d1 := d0;
			CONTINUE;
		END IF;

		dx := (st_y(p1)-st_y(p2)) * offs / d1;
		dy := (st_x(p2)-st_x(p1)) * offs / d1;

		p10 := st_translate( p1, dx, dy );
		p11 := st_translate( p2, dx, dy );

		IF i=2 THEN
			r := ARRAY[ p10 ];
		ELSE
			r := array_append( r, coalesce( alkis_intersect_lines( p00, p01, p10, p11 ), p01 ) );
		END IF;

		IF i=n THEN
			r := array_append( r, p11 );
		END IF;
	END LOOP;

	IF offs<0 THEN
		RETURN st_reverse( st_makeline(r) );
	ELSE
		RETURN st_makeline(r);
	END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

SET search_path = :"postgis_schema", :"parent_schema", public;

CREATE FUNCTION st_offsetcurve(geometry,float8,text) RETURNS geometry AS $$
  SELECT alkis_offsetcurve($1,$2,$3);
$$ LANGUAGE 'sql' IMMUTABLE;

CREATE FUNCTION st_force_collection(geometry) RETURNS geometry AS $$
  SELECT force_collection($1);
$$ LANGUAGE 'sql' IMMUTABLE;

CREATE FUNCTION st_asbinary(geometry,text) RETURNS bytea AS $$
  SELECT asbinary($1,$2);
$$ LANGUAGE 'sql' IMMUTABLE;

CREATE FUNCTION st_ndims(geometry) RETURNS smallint AS $$
  SELECT ndims($1);
$$ LANGUAGE 'sql' IMMUTABLE;

SET search_path = public;

DROP AGGREGATE array_agg(anyelement);

CREATE FUNCTION array_length(anyarray,integer) RETURNS integer AS $$
DECLARE
  res integer;
BEGIN
  BEGIN
    IF $2=1 THEN
      SELECT count(*) INTO res FROM (SELECT unnest($1)) AS foo;
    ELSIF $2>1 THEN
      SELECT array_length($1[1],$2-1) INTO res;
    ELSE
      res := NULL;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      res := NULL;
  END;
  RETURN res;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

\set ON_ERROR_STOP
\set ECHO errors
