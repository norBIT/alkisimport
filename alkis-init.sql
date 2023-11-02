/***************************************************************************
 *                                                                         *
 * Projekt:  norGIS ALKIS Import                                           *
 * Zweck:    Initialisierung des ALKIS-Schema                              *
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

-- Damit die Includes (\i) funktionieren muß psql im Verzeichnis ausgeführt
-- werden in dem das Skript liegt. Z.B. per
-- (cd /pfad/zu/postnas; psql -f alkis-init.sql)

-- Variable für das Koordinatensystem übergeben mit "psql .. -v alkis_epsg=25832 -v alkis-schema=public"

SET client_encoding = 'UTF8';
SET default_with_oids = false;
SET search_path = :"alkis_schema", public;

-- Stored Procedures laden
\i alkis-functions.sql

-- Alle Tabellen löschen
SELECT alkis_drop();

CREATE TABLE alkis_version(version integer);
INSERT INTO alkis_version(version) VALUES (19);
COMMENT ON TABLE alkis_version IS 'ALKIS: Schemaversion';

-- BW/BY-Koordinatensystem anlegen
SELECT alkis_create_bsrs(:alkis_epsg);

\i alkis-trigger.sql
\i alkis-schema.sql
\i alkis-wertearten.sql
-- \i alkis-wertearten-nrw.sql

\i alkis-compat.sql
\i alkis-po-tables.sql
