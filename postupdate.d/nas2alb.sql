/***************************************************************************
 *                                                                         *
 * Project:  norGIS ALKIS Import                                           *
 * Purpose:  Migration des ALB-Schemas                                     *
 * Author:   Jürgen E. Fischer <jef@norbit.de>                             *
 *                                                                         *
 ***************************************************************************
 * Copyright (c) 2012-2018, Jürgen E. Fischer <jef@norbit.de>              *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/

\unset ON_ERROR_STOP
SET application_name='ALKIS-Import - Liegenschaftsbuchmigration';
SET client_min_messages TO notice;
\set ON_ERROR_STOP

SELECT alkis_dropobject('alb_update_schema');
CREATE FUNCTION alb_update_schema() RETURNS varchar AS $$
DECLARE
	v INTEGER;
	r TEXT;
BEGIN
	r := NULL;

	BEGIN
		SELECT version INTO v FROM alb_version;
        EXCEPTION WHEN OTHERS THEN
                v := 0;
                CREATE TABLE alb_version(version INTEGER);
                INSERT INTO alb_version(version) VALUES (v);
        END;

        RAISE NOTICE 'ALB-Schema-Version %', v;

        IF v<1 THEN
                RAISE NOTICE 'Migriere auf Schema-Version 1';

		ALTER TABLE bestand ALTER gbblnr TYPE character(7);

		UPDATE alb_version SET version=1;

		r := coalesce(r||E'\n','') || 'ALB-Schema migriert';
	END IF;

	RETURN r;
END;
$$ LANGUAGE plpgsql;

SELECT alb_update_schema();
