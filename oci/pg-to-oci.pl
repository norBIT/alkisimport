#!/usr/bin/perl

#############################################################################
#    pg-to-oci.pl - ALKIS-PostgreSQL-Schema für Oracle vorbereiten
#    ---------------------
#    begin                : 2013-01-18
#    copyright            : (C) 2013 by Jürgen E. Fischer, norBIT GmbH
#    email                : jef at norbit dot de
#############################################################################
#                                                                         
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.
#                                                                         
#############################################################################

open I, "../alkis-schema.sql";
open O, ">alkis-schema.sql";

$i = 0;
print O "-- Automatisch mit pg-to-oci.pl konvertiert.\n---\n---\n\n";

while(<I>) {
	# Kommentare entfernen
	s/,\s*--.*$/,/;
	s/;\s*--.*$/;/;
	s/\s*--.*$//;

	s/^\s+SET client_encoding = 'UTF8';/set serveroutput on\nset autocommit on\nset feedback off\nset verify off\n/;
	s/^\s+SET default_with_oids = false;/define alkis_epsg=\&1/;
	s/\\set ON_ERROR_STOP/whenever sqlerror exit 1/;

	# Funktionsinclude überspringen
	next if /\\i\s+alkis-functions/;
	
	# Includes umwandeln
	s/\\i /@@ /;

	# Datentypen abbilden
	s/varchar\s+default\s+false/varchar2(5) default 'false'/i;
	s/varchar\s+default\s+'false'/varchar2(5) default 'false'/i;
	s/boolean\s+default\s+false/varchar2(5) default 'false'/i;
	s/\bvarchar\[\]/varchar2(2047)/;
	s/\binteger\[\]/varchar2(2047)/;
	s/\bvarchar\b,/varchar2(2047),/;
	s/\bdouble precision\[\]/varchar2(2047)/;
	s/serial/integer/;
	s/boolean/varchar2(5)/;

	# Feldnamen auf OCI Defaults abbilden
	s/wkb_geometry/ora_geometry/;
	s/ogc_fid/ogr_fid/;

	s/USING btree //;

	s/SELECT alkis_drop\(\);/-- $1/;

	# Indexnamen ersetzen
	if( /CREATE( UNIQUE)? INDEX (\S+)/ ) {
		s/INDEX \S+/INDEX ALKIS_$i/;
		$i++;
	}

	# Constraintnamen ersetzen
	if( /CONSTRAINT (\S+)/ ) {
		s/CONSTRAINT \S+/CONSTRAINT ALKIS_$i/;
		$i++;
	}

	# Räumliche Indizes konvertieren
	s/CREATE\s+INDEX\s+(\S+)\s+ON\s+(\S+)\s+USING\s+gist\s*\((\S+)\);/CREATE INDEX \U$1\E ON \U$2\E(\U$3\E) INDEXTYPE IS MDSYS.SPATIAL_INDEX PARALLEL;/i;

	# Tabelle ggf. vor dem Anlegen droppen und aus den Metadaten löschen
	s/CREATE TABLE (\S+)/DELETE FROM user_sdo_geom_metadata WHERE upper(table_name)='\U$1\E';\nBEGIN EXECUTE IMMEDIATE 'DROP TABLE \U$1\E CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;\n\/\nCREATE TABLE \U$1/;

	# Anlegen der Geometriespalte anpassen und für Metadateneintrag sorgen
	s/SELECT AddGeometryColumn\('([^']+)','([^']+)',:alkis_epsg,'[^']+',2\);.*$/ALTER TABLE \U$1\E ADD \U$2\E MDSYS.SDO_GEOMETRY;\nINSERT INTO user_sdo_geom_metadata\(table_name,column_name,srid,diminfo\) VALUES \('\U$1\E','\U$2\E',&&alkis_epsg,mdsys.sdo_dim_array\(mdsys.sdo_dim_element\('X',200000,800000,0.001\),mdsys.sdo_dim_element\('Y',5200000,6100000,0.001\)\)\);/;
	s/SELECT AddGeometryColumn\('([^']+)','([^']+)',:alkis_epsg,'[^']+',3\);.*$/ALTER TABLE \U$1\E ADD \U$2\E MDSYS.SDO_GEOMETRY;\nINSERT INTO user_sdo_geom_metadata\(table_name,column_name,srid,diminfo\) VALUES \('\U$1\E','\U$2\E',&&alkis_epsg,mdsys.sdo_dim_array\(mdsys.sdo_dim_element\('X',200000,800000,0.001\),mdsys.sdo_dim_element\('Y',5200000,6100000,0.001\),mdsys.sdo_dim_element\('Z',-50,3000,0.001\)\)\);/;

	# DELETE-Schlüsselwort quoten
	s/"delete"/"DELETE"/;
	s/ALTER TABLE DELETE/ALTER TABLE "DELETE"/;
	s/'"DELETE"'/'DELETE'/g;
	s/COMMENT ON COLUMN delete/COMMENT ON COLUMN "DELETE"/;

	# Oracle kennt keine Indexkommentare
	s/COMMENT ON INDEX .*$//;

	# Überlange Bezeichner kürzen und in Großbuchstaben wandeln
	s/([A-Z_]{30})[A-Z_]+/\U$1/gi;

	next if /^COMMENT ON TABLE (geometry_columns|spatial_ref_sys)/;

	next if /^\s*$/;

	print O;
}

print O "purge recyclebin;\nQUIT;\n";
close O;

close I;

# vim: set nowrap :
