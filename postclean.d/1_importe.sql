/***************************************************************************
 *                                                                         *
 * Project:  norGIS ALKIS Import                                           *
 * Purpose:  Zeitstempel der importierten Daten aufzeichnen                *
 * Author:   Jürgen E. Fischer <jef@norbit.de>                             *
 *                                                                         *
 ***************************************************************************
 * Copyright (c) 2025, Jürgen E. Fischer <jef@norbit.de>                   *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/

SET search_path TO :"alkis_schema",:"postgis_schema",public;

SELECT count(*)>0 AS exists FROM information_schema.tables WHERE table_schema=:'alkis_schema' AND table_name='alkis_importe';
\gset

\if :exists
TRUNCATE alkis_importe;
\else
\ir ../postcreate.d/1_importe.sql
\endif
