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
  EXECUTE format('SELECT count(*) FROM %I.%I WHERE gml_id=%L AND beginnt=%L', TG_TABLE_SCHEMA, TG_TABLE_NAME, NEW.gml_id, NEW.beginnt) INTO i;
  IF i>0 THEN
    RETURN NULL;
  ELSE
    RETURN NEW;
  END IF;
END;
$$ SET search_path TO :"alkis_schema";

SELECT format(E'DROP TRIGGER IF EXISTS %I ON %I.%I;\nCREATE TRIGGER %I BEFORE INSERT ON %I.%I FOR EACH ROW EXECUTE PROCEDURE ignore_duplicate();',
        a.table_name || '_insert', a.table_schema, a.table_name,
        a.table_name || '_insert', a.table_schema, a.table_name)
    FROM information_schema.columns a
    JOIN information_schema.columns b ON a.table_schema=b.table_schema AND a.table_name=b.table_name AND b.column_name='beginnt'
    WHERE a.table_schema=:'alkis_schema'
      AND substr(a.table_name,1,3) IN ('ax_','ap_','ks_','aa_','au_','ta_')
      AND a.column_name='gml_id';
\gexec

\endif
