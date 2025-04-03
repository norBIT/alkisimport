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

SELECT alkis_dropobject('alkis_importe');
CREATE TABLE alkis_importe(id SERIAL, filename varchar, importdate timestamp default now(), datadate character(20));
