/***************************************************************************
 *                                                                         *
 * Project:  norGIS ALKIS Import                                           *
 * Purpose:  Transformation der Daten in ein einheitliches KBS             *
 * Author:   Jürgen E. Fischer <jef@norbit.de>                             *
 *                                                                         *
 ***************************************************************************
 * Copyright (c) 2024, Jürgen E. Fischer <jef@norbit.de>                   *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/

\if :alkis_transform

SET search_path TO :"alkis_schema",:"postgis_schema",public;

SELECT 'Eingabedaten werde in ' || :'alkis_epsg' || ' transformiert.';

SELECT '
CREATE OR REPLACE FUNCTION inplace_transform() RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF substr(NEW.gml_id, 3, 2) IN (''BW'',''BY'',''HB'',''HE'',''HH'',''NI'',''NW'',''RP'',''SH'',''SL'',''ST'',''TH'') THEN
    NEW.wkb_geometry := st_transform(st_setsrid(NEW.wkb_geometry, 25832), ' || :'alkis_epsg' || ');
  ELSE
    NEW.wkb_geometry := st_transform(st_setsrid(NEW.wkb_geometry, 25833), ' || :'alkis_epsg' || ');
  END IF;
  RETURN NEW;
END;
$$ SET search_path TO ' || quote_ident(:'alkis_schema') || ',' || quote_ident(:'postgis_schema') || ';
';
\gexec

SELECT
	'SELECT alkis_dropobject(' || quote_literal(a.table_name || '_transform') || E');\n' ||
	'CREATE TRIGGER ' || quote_ident(a.table_name || '_transform') || ' BEFORE INSERT ON ' || quote_ident(a.table_schema) || '.' || quote_ident(a.table_name) || ' FOR EACH ROW EXECUTE PROCEDURE inplace_transform();'
FROM information_schema.columns a
JOIN information_schema.columns b ON a.table_schema=b.table_schema AND a.table_name=b.table_name AND b.column_name='wkb_geometry'
JOIN information_schema.tables c ON b.table_schema=c.table_schema AND b.table_name=c.table_name AND c.table_type='BASE TABLE'
WHERE a.table_schema=:'alkis_schema'
	AND substr(a.table_name,1,3) IN ('ax_','ap_','ln_','lb_','au_','aa_')
	AND a.column_name='gml_id';
\gexec

\endif
