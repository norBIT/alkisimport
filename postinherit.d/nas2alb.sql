\set nas2alb true
\ir ../config.sql

\if :nas2alb

SET client_encoding TO 'UTF8';
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

\i nas2alb-functions.sql

\endif
