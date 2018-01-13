/******************************************************************************
 *
 * Projekt:  norGIS ALKIS Import
 * Zweck:    Vererbung von einem ALKIS-Schema
 * Author:   Jürgen E. Fischer <jef@norbit.de>
 *
 ******************************************************************************/

SET client_encoding = 'UTF8';
SET default_with_oids = false;
SET search_path = :"alkis_schema", public;

-- Stored Procedures laden
\i alkis-functions.sql

-- Alle Tabellen erben
SELECT alkis_inherit(:'parent_schema');
