/***************************************************************************
 *                                                                         *
 * Projekt:  norGIS ALKIS Import                                           *
 * Purpose:  ALKIS-Schema leeren                                           *
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

-- Abbruch bei Fehlern
\set ON_ERROR_STOP

-- Stored Procedures laden
\i alkis-functions.sql

-- Schema leeren
SELECT alkis_clean();
