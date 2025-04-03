/***************************************************************************
 *                                                                         *
 * Project:  norGIS ALKIS Import                                           *
 * Purpose:  Duplikate ignorieren                                          *
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

\if :alkis_avoiddupes

SELECT 'Mehrfach vorkommende Objekte werden ignoriert.';

SET search_path TO :"alkis_schema",public;

CREATE OR REPLACE FUNCTION ignore_duplicate() RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
  i INTEGER;
BEGIN
  EXECUTE 'SELECT count(*) FROM ' || quote_ident(TG_TABLE_SCHEMA) || '.' || quote_ident(TG_TABLE_NAME) || ' WHERE gml_id=' || quote_literal(NEW.gml_id) || ' AND beginnt=' || quote_literal(NEW.beginnt) INTO i;
  IF i>0 THEN
    RETURN NULL;
  ELSE
    RETURN NEW;
  END IF;
END;
$$ SET search_path TO :"alkis_schema";

SELECT
	'SELECT alkis_dropobject(' || quote_literal(a.table_name || '_insert') || E');\n' ||
	'CREATE TRIGGER ' || quote_ident(a.table_name || '_insert') || ' BEFORE INSERT ON ' || quote_ident(a.table_schema) || '.' || quote_ident(a.table_name) || ' FOR EACH ROW EXECUTE PROCEDURE ignore_duplicate();'
FROM information_schema.columns a
JOIN information_schema.columns b ON a.table_schema=b.table_schema AND a.table_name=b.table_name AND b.column_name='beginnt'
WHERE a.table_schema=:'alkis_schema'
  AND substr(a.table_name,1,3) IN ('ax_','ap_','ks_','aa_','au_','ta_')
  AND a.column_name='gml_id';
\gexec

\endif
