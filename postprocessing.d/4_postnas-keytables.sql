/***************************************************************************
 *                                                                         *
 * Project:  norGIS ALKIS Import                                           *
 * Purpose:  PostNAS-Kompatibilitätssichten auf alkis_wertearten           *
 * Author:   Jürgen E. Fischer <jef@norbit.de>                             *
 *                                                                         *
 ***************************************************************************
 * Copyright (c) 2014-2023, Jürgen E. Fischer <jef@norbit.de>              *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/

SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

-- TODO: Sichten mit Nutzungdaten (nutzung*)

SELECT alkis_dropobject('v_geb_bauweise');
CREATE VIEW v_geb_bauweise AS
	SELECT wert::int AS bauweise_id, beschreibung AS bauweise_beschreibung, dokumentation AS bauweise_erklaerung FROM ax_bauweise_gebaeude;

SELECT alkis_dropobject('v_geb_funktion');
CREATE VIEW v_geb_funktion AS
	SELECT wert::int AS wert, beschreibung AS bezeichner, dokumentation AS erklaer FROM ax_gebaeudefunktion;

SELECT alkis_dropobject('v_geb_weiterefkt');
CREATE VIEW v_geb_weiterefkt AS
	SELECT wert::int AS wert, beschreibung AS bezeichner, dokumentation AS erklaer FROM ax_weitere_gebaeudefunktion;

SELECT alkis_dropobject('v_geb_dachform');
CREATE VIEW v_geb_dachform AS
	SELECT wert::int AS wert, beschreibung AS bezeichner, dokumentation AS erklaer FROM ax_dachform;

SELECT alkis_dropobject('v_geb_zustand');
CREATE VIEW v_geb_zustand AS
	SELECT wert::int AS wert, beschreibung AS bezeichner, dokumentation AS erklaer FROM ax_zustand_gebaeude;

SELECT alkis_dropobject('v_geb_lagezeo');
CREATE VIEW v_geb_lagezeo AS
	SELECT wert::int AS wert, beschreibung AS bezeichner, dokumentation AS erklaer FROM ax_lagezurerdoberflaeche_gebaeude;

SELECT alkis_dropobject('v_geb_dachgeschossausbau');
CREATE VIEW v_geb_dachgeschossausbau AS
	SELECT wert::int AS wert, beschreibung AS bezeichner, dokumentation AS erklaer FROM ax_dachgeschossausbau_gebaeude;

SELECT alkis_dropobject('v_bs_buchungsart');
CREATE VIEW v_bs_buchungsart AS
	SELECT wert::int AS wert, beschreibung AS bezeichner, dokumentation AS erklaer FROM ax_buchungsart_buchungsstelle;

SELECT alkis_dropobject('v_bs_buchungsart');
CREATE VIEW v_bs_buchungsart AS
	SELECT wert::int AS wert, beschreibung AS bezeichner, dokumentation AS erklaer FROM ax_buchungsart_buchungsstelle;

SELECT alkis_dropobject('v_namnum_eigart');
CREATE VIEW v_namnum_eigart AS
	SELECT wert::int AS wert, beschreibung AS bezeichner, dokumentation AS erklaer FROM ax_eigentuemerart_namensnummer;

SELECT alkis_dropobject('v_baurecht_adf');
CREATE VIEW v_baurecht_adf AS
	SELECT wert::int AS wert, beschreibung AS bezeichner, dokumentation AS erklaer FROM ax_artderfestlegung_bauraumoderbodenordnungsrecht;

SELECT alkis_dropobject('v_bschaetz_kulturart');
CREATE VIEW v_bschaetz_kulturart AS
	SELECT
		wert::int AS wert
		,regexp_replace( beschreibung, E'^.*\\((.*)\\)$', E'\\1') AS kurz
		,beschreibung AS bezeichner
	FROM ax_nutzungsart_bodenschaetzung;

SELECT alkis_dropobject('v_bschaetz_bodenart');
CREATE VIEW v_bschaetz_bodenart AS
	SELECT
		wert::int AS wert
		,regexp_replace(beschreibung, E'^[^(]*\\("?([^"]*)"?\\)$', E'\\1') AS kurz
		,beschreibung AS bezeichner
	FROM ax_bodenart_bodenschaetzung;

SELECT alkis_dropobject('v_bschaetz_zustandsstufe');
CREATE VIEW v_bschaetz_zustandsstufe AS
	SELECT
		wert::int AS wert
		,regexp_replace( beschreibung, E'^.*\\((.*)\\)$', E'\\1') AS kurz
		,beschreibung AS bezeichner
	FROM ax_zustandsstufe;

SELECT alkis_dropobject('v_bschaetz_entsteh_klima');
CREATE VIEW v_bschaetz_entsteh_klima AS
	SELECT
		wert::int AS wert
		,regexp_replace( beschreibung, E'^.*\\((.*)\\)$', E'\\1') AS kurz
		,beschreibung AS bezeichner
	FROM ax_bodenart_bodenschaetzung;

SELECT alkis_dropobject('v_muster_merkmal');
CREATE VIEW v_muster_merkmal AS
	SELECT
		wert::int AS wert
		,regexp_replace( beschreibung, E'^.*\\((.*)\\)$', E'\\1') AS kurz
		,beschreibung AS bezeichner
	FROM ax_merkmal_musterundvergleichsstueck;

SELECT alkis_dropobject('v_grabloch_bedeutg');
CREATE VIEW v_grabloch_bedeutg AS
	SELECT wert::int AS wert, beschreibung AS bezeichner FROM ax_bedeutung_grablochderbodenschaetzung;

SELECT alkis_dropobject('v_bschaetz_sonst');
CREATE VIEW v_bschaetz_sonst AS
	SELECT
		wert::int AS wert
		,regexp_replace( beschreibung, E'^.*\\((.*)\\)$', E'\\1') AS kurz
		,beschreibung AS bezeichner
	FROM ax_sonstigeangaben_bodenschaetzung;

SELECT alkis_dropobject('v_bewertg_klass');
CREATE VIEW v_bewertg_klass AS
	SELECT wert::int AS wert, beschreibung AS bezeichner, dokumentation AS erklaer FROM ax_klassifizierung_bewertung;

SELECT alkis_dropobject('v_forstrecht_adf');
CREATE VIEW v_forstrecht_adf AS
	SELECT wert::int AS wert, beschreibung AS bezeichner FROM ax_artderfestlegung_forstrecht;

SELECT alkis_dropobject('v_forstrecht_besfkt');
CREATE VIEW v_forstrecht_besfkt AS
	SELECT wert::int AS wert, beschreibung AS bezeichner FROM ax_besonderefunktion_forstrecht;

SELECT alkis_dropobject('v_datenerhebung');
CREATE VIEW v_datenerhebung AS
	SELECT wert::int AS wert, beschreibung AS bezeichner FROM ax_datenerhebung;

SELECT alkis_dropobject('v_sbauwerk_bwfkt');
CREATE VIEW v_sbauwerk_bwfkt AS
	SELECT
		wert::int AS wert,
		beschreibung AS bezeichner
	FROM ax_bauwerksfunktion_sonstigesbauwerkodersonstigeeinrichtun;

SELECT alkis_dropobject('v_bauteil_bauart');
CREATE VIEW v_bauteil_bauart AS
	SELECT
		wert::int AS wert
		,beschreibung AS bezeichner
		,'31002'::text AS kennung
		,'ax_bauteil'::text AS objektart
	FROM ax_bauart_bauteil;

SELECT alkis_dropobject('v_klass_strass_adf');
CREATE VIEW v_klass_strass_adf AS
	SELECT
		wert::int AS wert
		,beschreibung AS bezeichner
		,'71001'::text AS kennung
		,'ax_klassifizierungnachstrassenrecht'::text AS objektart
	FROM ax_artderfestlegung_klassifizierungnachstrassenrecht;

SELECT alkis_dropobject('v_klass_wasser_adf');
CREATE VIEW v_klass_wasser_adf AS
	SELECT
		wert::int AS wert
		,beschreibung AS bezeichner
		,'71003'::text AS kennung
		,'ax_klassifizierungnachwasserrecht'::text AS objektart
	FROM ax_artderfestlegung_klassifizierungnachwasserrecht;

SELECT alkis_dropobject('v_andstrass_adf');
CREATE VIEW v_andstrass_adf AS
	SELECT
		wert::int AS wert
		,beschreibung AS bezeichner
		,'71002'::text AS kennung
		,'ax_anderefestlegungnachstrassenrecht'::text AS objektart
	FROM ax_artderfestlegung_anderefestlegungnachstrassenrecht;

SELECT alkis_dropobject('v_umweltrecht_adf');
CREATE VIEW v_umweltrecht_adf AS
	SELECT
		wert::int AS wert
		,beschreibung AS bezeichner
		,'71006'::text AS kennung
		,'ax_naturumweltoderbodenschutzrecht'::text AS objektart
	FROM ax_artderfestlegung_naturumweltoderbodenschutzrecht;

SELECT alkis_dropobject('v_denkmal_adf');
CREATE VIEW v_denkmal_adf AS
	SELECT
		wert::int AS wert
		,beschreibung AS bezeichner
		,'71009'AS kennung
		,'ax_denkmalschutzrecht'::text AS objektart
	FROM ax_artderfestlegung_denkmalschutzrecht;

SELECT alkis_dropobject('v_sonstrecht_adf');
CREATE VIEW v_sonstrecht_adf AS
	SELECT
		wert::int AS wert
		,beschreibung AS bezeichner
		,'71011'::text AS kennung
		,'ax_sonstigesrecht'::text AS objektart
	FROM ax_artderfestlegung_sonstigesrecht;
