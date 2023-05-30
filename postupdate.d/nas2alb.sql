/***************************************************************************
 *                                                                         *
 * Project:  norGIS ALKIS Import                                           *
 * Purpose:  Migration des ALB-Schemas                                     *
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
SET application_name='ALKIS-Import - Liegenschaftsbuchmigration';
SET client_min_messages TO notice;
\set ON_ERROR_STOP

SET search_path = :"alkis_schema", :"postgis_schema", public;

CREATE FUNCTION pg_temp.alb_update_schema() RETURNS varchar AS $$
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
	END IF;

	IF v<2 THEN
		RAISE NOTICE 'Migriere auf Schema-Version 2';

		ALTER TABLE eigner ALTER namensnr TYPE varchar;
	END IF;

	IF v<3 THEN
		RAISE NOTICE 'Migriere auf Schema-Version 3';

		COMMENT ON TABLE flurst IS 'BASE: Flurstücke';
		COMMENT ON TABLE strassen IS 'BASE: Straßenzuordnungen';
		COMMENT ON TABLE gem_shl IS 'BASE: Gemeindeschlüssel';
		COMMENT ON TABLE gema_shl IS 'BASE: Gemarkungsschlüssel';
		COMMENT ON TABLE eignerart IS 'BASE: Eigentümerarten';
		COMMENT ON TABLE bem_best IS 'BASE: Bestandsbemerkung';
		COMMENT ON TABLE bestand IS 'BASE: Bestände';
		COMMENT ON TABLE eigner IS 'BASE: Eigentümer';
		COMMENT ON TABLE eign_shl IS 'BASE: Eigentumsarten';
		COMMENT ON TABLE hinw_shl IS 'BASE: Hinweise';
		COMMENT ON TABLE sonderbaurecht IS 'BASE: Sonderbaurecht';
		COMMENT ON TABLE klas_3x IS 'BASE: Klassifizierungen';
		COMMENT ON TABLE bem_fls IS 'BASE: Flurstücksbemerkungen';
		COMMENT ON TABLE erbbaurecht IS 'BASE: Erbbaurecht';
		COMMENT ON TABLE nutz_21 IS 'BASE: Nutzungen';
		COMMENT ON TABLE nutz_shl IS 'BASE: Nutzungsschlüssel';
		COMMENT ON TABLE verf_shl IS 'BASE: Verfahrensschlüssel';
		COMMENT ON TABLE vor_flst IS 'BASE: Vorgängerflurstücke';
		COMMENT ON TABLE best_lkfs IS 'BASE: Bestandsführende Stelle';
		COMMENT ON TABLE flurst_lkfs IS 'BASE: Flurstücksführende Stelle';
		COMMENT ON TABLE fortf IS 'BASE: Fortführungen';
		COMMENT ON TABLE fina IS 'BASE: Finanzämter';
		COMMENT ON TABLE fs IS 'BASE: Flurstücksverknüpfungen';
		COMMENT ON TABLE ausfst IS 'BASE: Ausführende Stellen';
		COMMENT ON TABLE afst_shl IS 'BASE: Schlüssel ausführender Stellen';
		COMMENT ON TABLE str_shl IS 'BASE: Straßenschlüssel';
		COMMENT ON TABLE kls_shl IS 'BASE: Klassifiziersschlüssel';

		ALTER TABLE strassen ALTER hausnr TYPE varchar;
	END IF;

	IF v<4 THEN
		RAISE NOTICE 'Migriere auf Schema-Version 4';

		ALTER TABLE bestand ALTER gbblnr TYPE varchar;

		UPDATE alb_version SET version=4;

		r := coalesce(r||E'\n','') || 'ALB-Schema migriert';
	END IF;

	RETURN r;
END;
$$ LANGUAGE plpgsql;

SELECT pg_temp.alb_update_schema();
