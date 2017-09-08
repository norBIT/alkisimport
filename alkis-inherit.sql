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

-- Abbruch bei Fehlern
\set ON_ERROR_STOP

-- Stored Procedures laden
\i alkis-functions.sql

-- Alle Tabellen erben
SELECT alkis_inherit(:'parent_schema');
