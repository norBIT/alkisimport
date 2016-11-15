/******************************************************************************
 *
 * Project:  norGIS ALKIS Import
 * Purpose:  ALB-Daten in norBIT WLDGE-Strukturen aus ALKIS-Daten füllen
 * Author:   Jürgen E. Fischer <jef@norbit.de>
 *
 ******************************************************************************
 * Copyright (c) 2012-2014, Jürgen E. Fischer <jef@norbit.de>
 *
 *   This program is free software; you can redistribute it and/or modify
 *   it under the terms of the GNU General Public License as published by
 *   the Free Software Foundation; either version 2 of the License, or
 *   (at your option) any later version.
 *
 ****************************************************************************/

\unset ON_ERROR_STOP
SET application_name='ALKIS-Import - Liegenschaftsbuchübernahme';
SET client_min_messages TO notice;
\set ON_ERROR_STOP

DELETE FROM flurst;
DELETE FROM str_shl;
DELETE FROM strassen;
DELETE FROM gem_shl;
DELETE FROM gema_shl;
DELETE FROM eignerart;
DELETE FROM bem_best;
DELETE FROM bestand;
DELETE FROM eigner;
DELETE FROM eign_shl;
DELETE FROM hinw_shl;
DELETE FROM sonderbaurecht;
DELETE FROM klas_3x;
DELETE FROM kls_shl;
DELETE FROM bem_fls;
DELETE FROM erbbaurecht;
DELETE FROM nutz_21;
DELETE FROM nutz_shl;
DELETE FROM verf_shl;
DELETE FROM vor_flst;
DELETE FROM best_lkfs;
DELETE FROM flurst_lkfs;
DELETE FROM fortf;
DELETE FROM fina;
DELETE FROM fs;
DELETE FROM ausfst;
DELETE FROM afst_shl;

DELETE FROM v_schutzgebietnachwasserrecht;
DELETE FROM v_schutzgebietnachnaturumweltoderbodenschutzrecht;
