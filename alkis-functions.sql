/***************************************************************************
 *                                                                         *
 * Project:  norGIS ALKIS Import                                           *
 * Purpose:  SQL-Funktionen für ALKIS                                      *
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

CREATE FUNCTION pg_temp.alkis_set_schema(t TEXT) RETURNS varchar AS $$
DECLARE
	i integer;
BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_namespace WHERE nspname=t) THEN
		BEGIN
			EXECUTE 'CREATE SCHEMA ' || quote_ident(t);
			RAISE NOTICE 'Schema % angelegt.', t;
		EXCEPTION WHEN duplicate_schema OR unique_violation THEN
			-- skip
		END;
	END IF;

	PERFORM set_config('search_path', quote_ident(t) || ', ' || current_setting('search_path'), false);

	IF t <> current_schema() THEN
		RAISE EXCEPTION 'Nicht in Schema % gewechselt.', t;
	END IF;

	RETURN 'Aktuelles Schema ' || t || '.';
END
$$ LANGUAGE plpgsql;

SET search_path = :"parent_schema", :"postgis_schema", public;
SELECT pg_temp.alkis_set_schema(:'alkis_schema');

-- Table/View/Sequence löschen, wenn vorhanden
CREATE OR REPLACE FUNCTION :"parent_schema".alkis_dropobject(t TEXT) RETURNS varchar AS $$
DECLARE
	c RECORD;
	s varchar;
	r varchar;
	d varchar;
	i integer;
	tn varchar;
BEGIN
	-- drop objects
	FOR c IN SELECT relkind,relname
		FROM pg_catalog.pg_class
		JOIN pg_catalog.pg_namespace ON pg_class.relnamespace=pg_namespace.oid
		WHERE pg_catalog.pg_namespace.nspname=current_schema() AND pg_class.relname=t
		ORDER BY relkind
	LOOP
		IF c.relkind = 'v' THEN
			r := alkis_string_append(r, 'Sicht ' || c.relname || ' gelöscht.');
			EXECUTE 'DROP VIEW ' || c.relname || ' CASCADE';
		ELSIF c.relkind = 'r' THEN
			r := alkis_string_append(r, 'Tabelle ' || c.relname || ' gelöscht.');
			EXECUTE 'DROP TABLE ' || c.relname || ' CASCADE';
		ELSIF c.relkind = 'S' THEN
			r := alkis_string_append(r, 'Sequenz ' || c.relname || ' gelöscht.');
			EXECUTE 'DROP SEQUENCE ' || c.relname;
		ELSIF c.relkind <> 'i' THEN
			r := alkis_string_append(r, 'Typ ' || c.table_type || '.' || c.table_name || ' unerwartet.');
		END IF;
	END LOOP;

	FOR c IN SELECT indexname FROM pg_catalog.pg_indexes WHERE schemaname=current_schema() AND indexname=t
	LOOP
		r := alkis_string_append(r, 'Index ' || c.indexname || ' gelöscht.');
		EXECUTE 'DROP INDEX ' || c.indexname;
	END LOOP;

	FOR c IN SELECT proname,proargtypes
		FROM pg_catalog.pg_proc
		JOIN pg_catalog.pg_namespace ON pg_proc.pronamespace=pg_namespace.oid
		WHERE pg_namespace.nspname=current_schema() AND pg_proc.proname=t
	LOOP
		r := alkis_string_append(r, 'Funktion ' || c.proname || ' gelöscht.');

		s := 'DROP FUNCTION ' || c.proname || '(';
		d := '';

		FOR i IN array_lower(c.proargtypes,1)..array_upper(c.proargtypes,1) LOOP
			SELECT typname INTO tn FROM pg_catalog.pg_type WHERE oid=c.proargtypes[i];
			s := s || d || tn;
			d := ',';
		END LOOP;

		s := s || ')';

		EXECUTE s;
	END LOOP;

	FOR c IN SELECT relname,conname
		FROM pg_catalog.pg_constraint
		JOIN pg_catalog.pg_class ON pg_constraint.conrelid=pg_constraint.oid
		JOIN pg_catalog.pg_namespace ON pg_constraint.connamespace=pg_namespace.oid
		WHERE pg_namespace.nspname=current_schema() AND pg_constraint.conname=t
	LOOP
		r := alkis_string_append(r, 'Constraint ' || c.conname || ' von ' || c.relname || ' gelöscht.');
		EXECUTE 'ALTER TABLE ' || c.relname || ' DROP CONSTRAINT ' || c.conname;
	END LOOP;

	RETURN r;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION :"parent_schema".alkis_string_append(varchar, varchar) RETURNS varchar AS $$
	SELECT CASE WHEN $1='' OR $1 LIKE E'%\n' THEN $1 ELSE coalesce($1||E'\n','') END || coalesce($2, '');
$$ LANGUAGE 'sql' IMMUTABLE;

-- Alle ALKIS-Tabellen löschen
CREATE OR REPLACE FUNCTION :"parent_schema".alkis_drop() RETURNS varchar AS $$
DECLARE
	c RECORD;
	r VARCHAR;
BEGIN
	-- drop tables & views
	FOR c IN SELECT table_type,table_name FROM information_schema.tables
		   WHERE table_schema=current_schema()
		     AND ( substr(table_name,1,3) IN ('ax_','ap_','ks_','aa_','au_','ta_')
			   OR table_name IN ('alkis_beziehungen','alkis_wertearten','delete','alkis_version','nas_filter_capabilities','operation') )
		   ORDER BY table_type DESC LOOP
		IF c.table_type = 'VIEW' THEN
			r := alkis_string_append(r, 'Sicht ' || c.table_name || ' gelöscht.');
			EXECUTE 'DROP VIEW ' || c.table_name || ' CASCADE';
		ELSIF c.table_type = 'BASE TABLE' THEN
			r := alkis_string_append(r, 'Tabelle ' || c.table_name || ' gelöscht.');
			EXECUTE 'DROP TABLE ' || c.table_name || ' CASCADE';
		ELSE
			r := alkis_string_append(r, 'Typ ' || c.table_type || '.' || c.table_name || ' unerwartet.');
		END IF;
	END LOOP;

	-- clean geometry_columns
	DELETE FROM geometry_columns
		WHERE f_table_schema=current_schema()
		AND ( substr(f_table_name,1,2) IN ('ax_','ap_','ks_','aa_')
		 OR f_table_name IN ('alkis_beziehungen','delete') );

	RETURN r;
END;
$$ LANGUAGE plpgsql;

-- Alle ALKIS-Tabellen leeren
CREATE OR REPLACE FUNCTION :"parent_schema".alkis_clean() RETURNS varchar AS $$
DECLARE
	c RECORD;
	r VARCHAR;
BEGIN
	-- clean tables
	FOR c IN SELECT table_name FROM information_schema.tables
		   WHERE table_schema=current_schema() AND table_type='BASE TABLE'
		     AND ( substr(table_name,1,3) IN ('ax_','ap_','ks_','aa_') OR table_name IN ('alkis_beziehungen','delete') )
		     AND table_name NOT IN ('aa_advstandardmodell','aa_anlassart','aa_art_themendefinition','aa_nas_ausgabeform','aa_themendimension','ap_dateityp_3d','ap_horizontaleausrichtung','ap_vertikaleausrichtung','ax_abbaugut_bergbaubetrieb','ax_abbaugut_tagebaugrubesteinbruch','ax_administrative_funktion','ax_anrede_person','ax_anzahlderstreckengleise','ax_archaeologischertyp_historischesbauwerkoderhistorischee','ax_art_adressat_auszug','ax_art_baublock','ax_art_bereichzeitlich','ax_art_dammwalldeich','ax_art_einrichtungenfuerdenschiffsverkehr','ax_art_einrichtunginoeffentlichenbereichen','ax_art_flugverkehr','ax_art_flugverkehrsanlage','ax_art_gebaeudepunkt','ax_art_gewaessermerkmal','ax_art_gleis','ax_art_heilquellegasquelle','ax_art_punktkennung','ax_art_reservierung','ax_art_schifffahrtsliniefaehrverkehr','ax_art_strassenverkehrsanlage','ax_art_verband','ax_art_verbandsgemeinde','ax_art_wegpfadsteig','ax_artderaussparung','ax_artderbebauung_flaechebesondererfunktionalerpraegung','ax_artderbebauung_flaechegemischternutzung','ax_artderbebauung_siedlungsflaeche','ax_artderbebauung_wohnbauflaeche','ax_artderfestlegung_anderefestlegungnachstrassenrecht','ax_artderfestlegung_anderefestlegungnachwasserrecht','ax_artderfestlegung_bauraumoderbodenordnungsrecht','ax_artderfestlegung_denkmalschutzrecht','ax_artderfestlegung_forstrecht','ax_artderfestlegung_klassifizierungnachstrassenrecht','ax_artderfestlegung_klassifizierungnachwasserrecht','ax_artderfestlegung_naturumweltoderbodenschutzrecht','ax_artderfestlegung_schutzgebietnachnaturumweltoderbodensc','ax_artderfestlegung_schutzgebietnachwasserrecht','ax_artderfestlegung_sonstigesrecht','ax_artderflurstuecksgrenze_besondereflurstuecksgrenze','ax_artdergebietsgrenze_gebietsgrenze','ax_artdergelaendekante','ax_artdergeripplinie','ax_artdergewaesserachse','ax_artdernichtgelaendepunkte','ax_artderrechtsgemeinschaft_namensnummer','ax_artderstrukturierung','ax_artdesmarkantengelaendepunktes','ax_artdesnullpunktes_nullpunkt','ax_artdespolders','ax_ausgabemedium_benutzer','ax_bahnhofskategorie_bahnverkehrsanlage','ax_bahnkategorie','ax_bahnkategorie_gleis','ax_bahnkategorie_seilbahnschwebebahn','ax_bauart_bauteil','ax_bauweise_gebaeude','ax_bauwerksfunktion_bauwerkimgewaesserbereich','ax_bauwerksfunktion_bauwerkimverkehrsbereich','ax_bauwerksfunktion_bauwerkoderanlagefuerindustrieundgewer','ax_bauwerksfunktion_bauwerkoderanlagefuersportfreizeitunde','ax_bauwerksfunktion_leitung','ax_bauwerksfunktion_sonstigesbauwerkodersonstigeeinrichtun','ax_bauwerksfunktion_transportanlage','ax_bauwerksfunktion_turm','ax_bauwerksfunktion_vorratsbehaelterspeicherbauwerk','ax_bedeutung_grablochderbodenschaetzung','ax_befestigung_fahrwegachse','ax_befestigung_wegpfadsteig','ax_behoerde','ax_bemerkungzurabmarkung_grenzpunkt','ax_berechnungsmethode','ax_berechnungsmethodehoehenlinie','ax_beschaffenheit_besonderegebaeudelinie','ax_besondereartdergewaesserbegrenzung','ax_besonderebedeutung','ax_besonderefahrstreifen','ax_besonderefunktion_forstrecht','ax_bewuchs_vegetationsmerkmal','ax_bezeichnung_verwaltungsgemeinschaft','ax_blattart_buchungsblatt','ax_blattart_historischesflurstueck','ax_bodenart_bodenschaetzung','ax_bodenart_musterlandesmusterundvergleichsstueck','ax_buchungsart_buchungsstelle','ax_dachform','ax_dachgeschossausbau_gebaeude','ax_darstellung_gebaeudeausgestaltung','ax_datenerhebung','ax_datenerhebung_punktort','ax_datenerhebung_schwere','ax_datenformat_benutzer','ax_dqerfassungsmethode','ax_dqerfassungsmethodebesondererhoehenpunkt','ax_dqerfassungsmethodegewaesserbegrenzung','ax_dqerfassungsmethodemarkantergelaendepunkt','ax_dqerfassungsmethodesekundaeresdgm','ax_dqerfassungsmethodestrukturiertegelaendepunkte','ax_eigentuemerart_namensnummer','ax_elektrifizierung','ax_entstehungsartoderklimastufewasserverhaeltnisse_bodensc','ax_entstehungsartoderklimastufewasserverhaeltnisse_musterl','ax_fahrbahntrennung_strasse','ax_foerdergut_industrieundgewerbeflaeche','ax_funktion_bahnverkehr','ax_funktion_bauwerk','ax_funktion_dammwalldeich','ax_funktion_einschnitt','ax_funktion_fahrbahnachse','ax_funktion_flaechebesondererfunktionalerpraegung','ax_funktion_flaechegemischternutzung','ax_funktion_fliessgewaesser','ax_funktion_flugverkehr','ax_funktion_friedhof','ax_funktion_gehoelz','ax_funktion_gewaesserachse','ax_funktion_hafenbecken','ax_funktion_industrieundgewerbeflaeche','ax_funktion_lagefestpunkt','ax_funktion_meer','ax_funktion_platz','ax_funktion_polder','ax_funktion_referenzstationspunkt','ax_funktion_schiffsverkehr','ax_funktion_schutzgebietnachwasserrecht','ax_funktion_schwerefestpunkt','ax_funktion_sportfreizeitunderholungsflaeche','ax_funktion_stehendesgewaesser','ax_funktion_strasse','ax_funktion_strassenachse','ax_funktion_unlandvegetationsloseflaeche','ax_funktion_untergeordnetesgewaesser','ax_funktion_vegetationsmerkmal','ax_funktion_weg','ax_funktion_wegachse','ax_funktionhgr_k_tnhgr','ax_funktionoa_k_tnfl','ax_funktionoa_k_tngr_all','ax_funktionoa_k_tngrerweitert_all','ax_gebaeudefunktion','ax_genauigkeitsstufe_punktort','ax_genauigkeitsstufe_schwere','ax_gnsstauglichkeit','ax_gruendederausgesetztenabmarkung_grenzpunkt','ax_hafenkategorie_hafen','ax_horizontfreiheit_grenzpunkt','ax_horizontfreiheit_netzpunkt','ax_hydrologischesmerkmal_fliessgewaesser','ax_hydrologischesmerkmal_gewaesserachse','ax_hydrologischesmerkmal_gewaessermerkmal','ax_hydrologischesmerkmal_heilquellegasquelle','ax_hydrologischesmerkmal_sonstigesbauwerkodersonstigeeinri','ax_hydrologischesmerkmal_stehendesgewaesser','ax_hydrologischesmerkmal_untergeordnetesgewaesser','ax_identifikation','ax_internationalebedeutung_strasse','ax_k_zeile_punktart','ax_klassifikation_hierarchiestufe3d_lagefestpunkt','ax_klassifikation_ordnung_lagefestpunkt','ax_klassifikation_wertigkeit_lagefestpunkt','ax_klassifizierung_bewertung','ax_klassifizierunggr_k_bewgr','ax_klassifizierungobg_k_bewfl','ax_konstruktionsmerkmalbauart_schleuse','ax_koordinatenstatus_punktort','ax_kulturart_bodenschaetzung','ax_kulturart_musterlandesmusterundvergleichsstueck','ax_lagergut_halde','ax_lagergut_industrieundgewerbeflaeche','ax_lagezurerdoberflaeche_bauteil','ax_lagezurerdoberflaeche_gebaeude','ax_lagezurerdoberflaeche_transportanlage','ax_lagezurerdoberflaeche_untergeordnetesgewaesser','ax_lagezurerdoberflaeche_vorratsbehaelterspeicherbauwerk','ax_lagezuroberflaeche_gleis','ax_landschaftstyp','ax_letzteabgabeart','ax_li_processstep_mitdatenerhebung_description','ax_li_processstep_ohnedatenerhebung_description','ax_li_processstep_punktort_description','ax_liniendarstellung_topographischelinie','ax_marke','ax_markierung_wegachse','ax_markierung_wegpfadsteig','ax_merkmal_musterlandesmusterundvergleichsstueck','ax_messmethode_schwere','ax_nutzung','ax_nutzung_flugverkehr','ax_nutzung_hafen','ax_nutzung_hafenbecken','ax_oberflaechenmaterial_flugverkehrsanlage','ax_oberflaechenmaterial_strasse','ax_oberflaechenmaterial_unlandvegetationsloseflaeche','ax_ordnung_hoehenfestpunkt','ax_ordnung_schwerefestpunkt','ax_primaerenergie_industrieundgewerbeflaeche','ax_produkt_transportanlage','ax_punktart_k_punkte','ax_punktstabilitaet','ax_punktstabilitaet_hoehenfestpunkt_geologischestabilitaet','ax_punktstabilitaet_hoehenfestpunkt_grundwasserschwankung','ax_punktstabilitaet_hoehenfestpunkt_grundwasserstand','ax_punktstabilitaet_hoehenfestpunkt_guetedesbaugrundes','ax_punktstabilitaet_hoehenfestpunkt_guetedesvermarkungstra','ax_punktstabilitaet_hoehenfestpunkt_hoehenstabilitaetauswi','ax_punktstabilitaet_hoehenfestpunkt_topographieundumwelt','ax_punktstabilitaet_hoehenfestpunkt_vermutetehoehenstabili','ax_qualitaet_hauskoordinate','ax_rechtszustand_schutzzone','ax_schifffahrtskategorie','ax_schifffahrtskategorie_kanal','ax_schwereanomalie_schwere_art','ax_schwerestatus_schwere','ax_schweresystem_schwere','ax_skizzenart_skizze','ax_sonstigeangaben_bodenschaetzung','ax_sonstigeangaben_musterlandesmusterundvergleichsstueck','ax_speicherinhalt_vorratsbehaelterspeicherbauwerk','ax_sportart_bauwerkoderanlagefuersportfreizeitunderholung','ax_spurweite','ax_tidemerkmal_meer','ax_ursprung','ax_vegetationsmerkmal_gehoelz','ax_vegetationsmerkmal_landwirtschaft','ax_vegetationsmerkmal_wald','ax_verkehrsbedeutunginneroertlich','ax_verkehrsbedeutungueberoertlich','ax_vertrauenswuerdigkeit_punktort','ax_vertrauenswuerdigkeit_schwere','ax_verwendeteobjekte','ax_weitere_gebaeudefunktion','ax_widmung_kanal','ax_widmung_stehendesgewaesser','ax_widmung_strasse','ax_widmung_wasserlauf','ax_wirtschaftsart','ax_zone_schutzzone','ax_zustand','ax_zustand_bahnverkehr','ax_zustand_bahnverkehrsanlage','ax_zustand_bauwerkimgewaesserbereich','ax_zustand_bauwerkimverkehrsbereich','ax_zustand_bauwerkoderanlagefuerindustrieundgewerbe','ax_zustand_bergbaubetrieb','ax_zustand_boeschungkliff','ax_zustand_flaechebesondererfunktionalerpraegung','ax_zustand_flaechegemischternutzung','ax_zustand_flugverkehr','ax_zustand_friedhof','ax_zustand_gebaeude','ax_zustand_halde','ax_zustand_hoehleneingang','ax_zustand_industrieundgewerbeflaeche','ax_zustand_kanal','ax_zustand_naturumweltoderbodenschutzrecht','ax_zustand_schiffsverkehr','ax_zustand_schleuse','ax_zustand_sportfreizeitunderholungsflaeche','ax_zustand_strasse','ax_zustand_tagebaugrubesteinbruch','ax_zustand_turm','ax_zustand_vegetationsmerkmal','ax_zustand_wohnbauflaeche','ax_zustandsstufeoderbodenstufe_bodenschaetzung','ax_zustandsstufeoderbodenstufe_musterlandesmusterundvergle','ks_art_bauwerkanlagenfuerverundentsorgung','ks_art_einrichtungenundanlageninoeffentlichenbereichen','ks_art_einrichtungimbahnverkehr','ks_art_einrichtungimstrassenverkehr','ks_art_einrichtunginoeffentlichenbereichen','ks_art_strassenverkehrsanlage','ks_artderfestlegung_bauraumoderbauordnungsrecht','ks_bauwerksfunktion_bauwerkimgewaesserbereich','ks_bauwerksfunktion_bauwerkoderanlagefuerindustrieundgewerbe','ks_bauwerksfunktion_sonstigesbauwerk','ks_bauwerksfunktion_sonstigesbauwerkodersonstigeeinrichtung','ks_bewuchs_vegetationsmerkmal','ks_gefahrzeichen_verkehrszeichen','ks_material_einrichtunginoeffentlichenbereichen','ks_oberflaechenmaterial_kommunalebauwerkeeinrichtungen','ks_objektart_topographischeauspraegung','ks_richtzeichen_verkehrszeichen','ks_verkehrseinrichtung_verkehrszeichen','ks_vorschriftzeichen_verkehrszeichen','ks_zusatzzeichen_verkehrszeichen','ks_zustand_bauwerkimgewaesserbereich','ks_zustand_bauwerkoderanlagefuerverundentsorgung','ks_zustand_kommunalebauwerkeeinrichtungen','ks_zustand_vegetationsmerkmal','nas_filter_capabilities','operation')
		   ORDER BY table_type DESC LOOP
		r := alkis_string_append(r, 'Tabelle ' || c.table_name || ' geleert.');
		EXECUTE 'DELETE FROM ' || c.table_name;
	END LOOP;

	RETURN r;
END;
$$ LANGUAGE plpgsql;

-- Alle ALKIS-Tabellen erben
CREATE OR REPLACE FUNCTION :"parent_schema".alkis_inherit(parent varchar) RETURNS varchar AS $$
DECLARE
	tab RECORD;
	ind RECORD;
	r VARCHAR;
	nt INTEGER;
	ni INTEGER;
	nv INTEGER;
BEGIN
	nt := 0;
	ni := 0;
	nv := 0;

	-- inherit tables
	FOR tab IN
		SELECT c.oid, c.relname, obj_description(c.oid) AS description
		FROM pg_catalog.pg_class c
		JOIN pg_catalog.pg_namespace n ON n.oid=c.relnamespace AND n.nspname=parent
		WHERE pg_get_userbyid(c.relowner)=current_user AND c.relkind='r'
		  AND NOT EXISTS (
			SELECT *
			FROM pg_catalog.pg_class c1
			JOIN pg_catalog.pg_namespace n1 ON n1.oid=c1.relnamespace AND n1.nspname=current_schema()
			WHERE c1.relname=c.relname
		  )
	LOOP
		IF tab.description LIKE 'FeatureType:%' OR tab.description LIKE 'BASE:%' THEN
			nt := nt + 1;
			EXECUTE 'CREATE TABLE ' || quote_ident(tab.relname) || '() INHERITS (' || quote_ident(parent) || '.' || quote_ident(tab.relname) || ')';
			RAISE NOTICE 'Tabelle % abgeleitet.', tab.relname;

			FOR ind IN
				SELECT c.relname, replace(pg_get_indexdef(i.indexrelid), 'ON '||quote_ident(parent)||'.', 'ON ') AS sql
				FROM pg_catalog.pg_index i
				JOIN pg_catalog.pg_class c ON c.oid=i.indexrelid
				WHERE i.indrelid=tab.oid
			LOOP
				ni := ni + 1;
				EXECUTE ind.sql;
			END LOOP;
		ELSE
			nv := nv + 1;
			EXECUTE 'CREATE VIEW ' || quote_ident(tab.relname) || ' AS SELECT * FROM ' || quote_ident(parent) || '.' || quote_ident(tab.relname);
		END IF;
	END LOOP;

	RETURN nt || ' Tabellen mit ' || ni || ' Indizes abgeleitet und ' || nv || ' Sichten erzeugt.';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION :"parent_schema".alkis_create_bsrs(id INTEGER) RETURNS varchar AS $$
DECLARE
	n INTEGER;
BEGIN
	SELECT count(*) INTO n FROM spatial_ref_sys WHERE srid=id;
	IF n=1 THEN
		RETURN NULL;
	END IF;

	IF NOT has_table_privilege('spatial_ref_sys', 'INSERT') THEN
		RAISE EXCEPTION 'Darf fehlendes Koordinatensystem % nicht einfügen.', id;
	END IF;

	IF id=131466 THEN
		-- DE_DHDN_3GK2_BW100
		INSERT INTO spatial_ref_sys(srid,auth_name,auth_srid,srtext,proj4text)
			SELECT
				131466,auth_name,131466
				,replace(replace(srtext,'PARAMETER["false_easting",2500000]','PARAMETER["false_easting",500000]'),'"EPSG","31466"','"EPSG","131466"')
				,replace(proj4text,'+x_0=2500000','+x_0=500000')
			FROM spatial_ref_sys
			WHERE srid=31466
			  AND NOT EXISTS (SELECT * FROM spatial_ref_sys WHERE srid=131466);
		RETURN 'Koordinatensystem '||id||' angelegt.';
	END IF;

	IF id=131467 THEN
		-- DE_DHDN_3GK3_BW100
		INSERT INTO spatial_ref_sys(srid,auth_name,auth_srid,srtext,proj4text)
			SELECT
				131467,auth_name,131467
				,replace(replace(srtext,'PARAMETER["false_easting",3500000]','PARAMETER["false_easting",500000]'),'"EPSG","31467"','"EPSG","131467"')
				,replace(proj4text,'+x_0=3500000','+x_0=500000')
			FROM spatial_ref_sys
			WHERE srid=31467
			  AND NOT EXISTS (SELECT * FROM spatial_ref_sys WHERE srid=131467);
		RETURN 'Koordinatensystem '||id||' angelegt.';
	END IF;

	IF id=131468 THEN
		-- DE_DHDN_3GK4_BY120
		INSERT INTO spatial_ref_sys(srid,auth_name,auth_srid,srtext,proj4text)
			SELECT
				131468,auth_name,131468
				,replace(replace(srtext,'PARAMETER["false_easting",4500000]','PARAMETER["false_easting",500000]'),'"EPSG","31468"','"EPSG","131468"')
				,replace(proj4text,'+x_0=4500000','+x_0=500000')
			FROM spatial_ref_sys
			WHERE srid=31468
			  AND NOT EXISTS (SELECT * FROM spatial_ref_sys WHERE srid=131468);
		RETURN 'Koordinatensystem '||id||' angelegt.';
	END IF;

	RAISE EXCEPTION 'Nicht erwartetes Koordinatensystem %.', id;
END;
$$ LANGUAGE plpgsql;

-- Alle ALKIS-Tabellen leeren
CREATE OR REPLACE FUNCTION :"parent_schema".alkis_delete() RETURNS varchar AS $$
DECLARE
	c RECORD;
	r varchar;
BEGIN
	-- drop views
	FOR c IN
		SELECT table_name
		FROM information_schema.tables
		WHERE table_schema=current_schema() AND table_type='BASE TABLE'
		  AND ( substr(table_name,1,3) IN ('ax_','ap_','ks_','aa_')
			OR table_name IN ('alkis_beziehungen','delete') )
	LOOP
		r := alkis_string_append(r, c.table_name || ' wurde geleert.');
		EXECUTE 'TRUNCATE '||c.table_name;
	END LOOP;

	RETURN r;
END;
$$ LANGUAGE plpgsql;

-- Übersicht erzeugen, die alle alkis_beziehungen mit den Typen der beteiligen ALKIS-Objekte versieht
CREATE OR REPLACE FUNCTION :"parent_schema".alkis_mviews() RETURNS varchar AS $$
DECLARE
	sql TEXT;
	delim TEXT;
	c RECORD;
BEGIN
	SELECT alkis_dropobject('vbeziehungen') INTO sql;
	SELECT alkis_dropobject('vobjekte') INTO sql;

	delim := '';
	sql := 'CREATE VIEW vobjekte AS ';

	FOR c IN SELECT table_name FROM information_schema.columns
		   WHERE column_name='gml_id'
		     AND substr(table_name,1,3) IN ('ax_','ap_','ks_','aa_')
		     AND NOT table_name IN ('ax_tatsaechlichenutzung','ax_klassifizierung','ax_ausfuehrendestellen')
		     AND table_schema=current_schema
	LOOP
		sql := sql || delim || 'SELECT gml_id,beginnt,endet,''' || c.table_name || ''' AS table_name FROM ' || c.table_name;
		delim := ' UNION ';
	END LOOP;

	EXECUTE sql;

	CREATE VIEW vbeziehungen AS
		SELECT beziehung_von,(SELECT DISTINCT table_name FROM vobjekte WHERE gml_id=beziehung_von) AS typ_von
			,beziehungsart
			,beziehung_zu,(SELECT DISTINCT table_name FROM vobjekte WHERE gml_id=beziehung_zu) AS typ_zu
		FROM alkis_beziehungen;

	RETURN 'ALKIS-Views erzeugt.';
END;
$$ LANGUAGE plpgsql;

-- Wenn die Datenbank MIT Historie angelegt wurde, kann nach dem Laden hiermit aufgeräumt werden.
CREATE OR REPLACE FUNCTION :"parent_schema".alkis_delete_all_endet() RETURNS void AS $$
DECLARE
	c RECORD;
BEGIN
	-- In allen Tabellen die Objekte löschen, die ein Ende-Datum haben
	FOR c IN
		SELECT table_name
		FROM information_schema.columns a
		WHERE a.column_name='endet' AND a.is_updatable='YES' AND table_schema=current_schema()
		ORDER BY table_name
	LOOP
		EXECUTE 'DELETE FROM ' || c.table_name || ' WHERE NOT endet IS NULL';
		-- RAISE NOTICE 'Lösche ''endet'' in: %', c.table_name;
	END LOOP;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION :"parent_schema".alkis_exception() RETURNS void AS $$
BEGIN
	RAISE EXCEPTION 'raising deliberate exception';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION :"parent_schema".alkis_hist_check() RETURNS varchar AS $$
DECLARE
	c RECORD;
	n INTEGER;
	r VARCHAR;
BEGIN
	FOR c IN SELECT table_name FROM information_schema.tables WHERE table_schema=current_schema() AND substr(table_name,1,3) IN ('ax_','ap_','ks_','aa_') AND table_type='BASE TABLE'
	LOOP
		EXECUTE 'SELECT count(*) FROM ' || c.table_name || ' WHERE endet IS NULL GROUP BY gml_id HAVING count(*)>1' INTO n;
		IF n>1 THEN
			r := alkis_string_append(r, c.table_name || ': ' || n || ' Objekte, die in mehreren Versionen nicht beendet sind.');
		END IF;

		EXECUTE 'SELECT count(*) FROM ' || c.table_name || ' WHERE beginnt>=endet' INTO n;
		IF n>1 THEN
			r := alkis_string_append(r, c.table_name || ': ' || n || ' Objekte mit ungültiger Lebensdauer.');
		END IF;

		EXECUTE 'SELECT count(*)'
			|| ' FROM ' || c.table_name || ' a'
			|| ' JOIN ' || c.table_name || ' b ON a.gml_id=b.gml_id AND a.ogc_fid<>b.ogc_fid AND a.beginnt<b.endet AND a.endet>b.beginnt'
			INTO n;
		IF n>0 THEN
			r := alkis_string_append(r, c.table_name || ': ' || n || ' Lebensdauerüberschneidungen.');
		END IF;
	END LOOP;

	RETURN coalesce(r,'Keine Fehler gefunden.');
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION :"parent_schema".alkis_bufferline(g geometry,offs float8) RETURNS geometry AS $$
BEGIN
	BEGIN
		RETURN st_buffer(g,offs,'endcap=flat');
	EXCEPTION WHEN OTHERS THEN
		IF geometrytype(g) = 'LINESTRING' THEN
			DECLARE
				g0 GEOMETRY;
				g1 GEOMETRY;
				g2 GEOMETRY;
			BEGIN
				SELECT alkis_offsetcurve(g,offs,'') INTO g0;
				SELECT st_reverse( alkis_offsetcurve(g,-offs,'') ) INTO g1;

				g2 := st_makepolygon( st_linemerge( st_collect(
					ARRAY[
						g0, st_makeline( st_endpoint(g0), st_startpoint(g1) ),
						g1, st_makeline( st_endpoint(g1), st_startpoint(g0) )
					]
				) ) );

				IF geometrytype(g2) <> 'POLYGON' THEN
					RAISE EXCEPTION 'alkis_bufferline: POLYGON expected, % found', geometrytype(g2);
				END IF;

				RETURN g2;
			END;
		ELSE
			RAISE EXCEPTION 'alkis_bufferline: LINESTRING expected, % found', geometrytype(g);
		END IF;
	END;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION pg_temp.create_accum() RETURNS void AS $$
BEGIN
  CREATE AGGREGATE alkis_accum (anycompatiblearray) (
    sfunc = array_cat,
    stype = anycompatiblearray,
    initcond = '{}'
  );
EXCEPTION
  WHEN duplicate_function THEN
    -- pass
  WHEN OTHERS THEN
    BEGIN
      CREATE AGGREGATE alkis_accum (anyarray) (
        sfunc = array_cat,
        stype = anyarray,
        initcond = '{}'
      );
    EXCEPTION
      WHEN duplicate_function THEN
        -- pass
    END;
END;
$$ LANGUAGE plpgsql;

SELECT pg_temp.create_accum();
