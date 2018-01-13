/***************************************************************************
 *                                                                         *
 * Projekt:  norGIS ALKIS Import                                           *
 * Purpose:  ALKIS-Schema ggf. migrieren                                   *
 * Author:   Jürgen E. Fischer <jef@norbit.de>                             *
 *                                                                         *
 ***************************************************************************
 * Copyright (c) 2012-2017, Jürgen E. Fischer <jef@norbit.de>              *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/

SET client_encoding = 'UTF8';
SET search_path = :"postgis_schema", public;

\i alkis-compat.sql

-- Stored Procedures laden
\i alkis-functions.sql

-- Schema migrieren
SELECT alkis_update_schema();
