/******************************************************************************
 *
 * Project:  norGIS ALKIS Import
 * Purpose:  PostNAS-Kompatibilitätssichten auf alkis_wertearten
 * Author:   Jürgen E. Fischer <jef@norbit.de>
 *
 ******************************************************************************
 * Copyright (c) 2014, Jürgen E. Fischer <jef@norbit.de>
 *
 *   This program is free software; you can redistribute it and/or modify
 *   it under the terms of the GNU General Public License as published by
 *   the Free Software Foundation; either version 2 of the License, or
 *   (at your option) any later version.
 *
 ****************************************************************************/

SET search_path = :"alkis_schema", :"postgis_schema", public;

-- TODO: Sichten mit Nutzungdaten (nutzung*)

SELECT alkis_dropobject('v_geb_bauweise');
CREATE VIEW v_geb_bauweise AS
	SELECT k::int AS bauweise_id, v AS bauweise_beschreibung, d AS bauweise_erklaerung FROM alkis_wertearten WHERE element='ax_gebaeude' AND bezeichnung='bauweise';

SELECT alkis_dropobject('v_geb_funktion');
CREATE VIEW v_geb_funktion AS
	SELECT k::int AS wert, v AS bezeichner, d AS erklaer FROM alkis_wertearten WHERE element='ax_gebaeude' AND bezeichnung='gebaeudefunktion';

SELECT alkis_dropobject('v_geb_weiterefkt');
CREATE VIEW v_geb_weiterefkt AS
	SELECT k::int AS wert, v AS bezeichner, d AS erklaer FROM alkis_wertearten WHERE element='ax_gebaeude' AND bezeichnung='weiteregebaeudefunktion';

SELECT alkis_dropobject('v_geb_dachform');
CREATE VIEW v_geb_dachform AS
	SELECT k::int AS wert, v AS bezeichner, d AS erklaer FROM alkis_wertearten WHERE element='ax_gebaeude' AND bezeichnung='dachform';

SELECT alkis_dropobject('v_geb_zustand');
CREATE VIEW v_geb_zustand AS
	SELECT k::int AS wert, v AS bezeichner, d AS erklaer FROM alkis_wertearten WHERE element='ax_gebaeude' AND bezeichnung='zustand';

SELECT alkis_dropobject('v_geb_lagezeo');
CREATE VIEW v_geb_lagezeo AS
	SELECT k::int AS wert, v AS bezeichner, d AS erklaer FROM alkis_wertearten WHERE element='ax_gebaeude' AND bezeichnung='lagezurerdoberflaeche';

SELECT alkis_dropobject('v_geb_dachgeschossausbau');
CREATE VIEW v_geb_dachgeschossausbau AS
	SELECT k::int AS wert, v AS bezeichner, d AS erklaer FROM alkis_wertearten WHERE element='ax_gebaeude' AND bezeichnung='dachgeschossausbau';

SELECT alkis_dropobject('v_bs_buchungsart');
CREATE VIEW v_bs_buchungsart AS
	SELECT k::int AS wert, v AS bezeichner, d AS erklaer FROM alkis_wertearten WHERE element='ax_buchungsstelle' AND bezeichnung='buchungsart';

SELECT alkis_dropobject('v_bs_buchungsart');
CREATE VIEW v_bs_buchungsart AS
	SELECT k::int AS wert, v AS bezeichner, d AS erklaer FROM alkis_wertearten WHERE element='ax_buchungsstelle' AND bezeichnung='buchungsart';

SELECT alkis_dropobject('v_namnum_eigart');
CREATE VIEW v_namnum_eigart AS
	SELECT k::int AS wert, v AS bezeichner, d AS erklaer FROM alkis_wertearten WHERE element='ax_namensnummer' AND bezeichnung='eigentuemerart';

SELECT alkis_dropobject('v_baurecht_adf');
CREATE VIEW v_baurecht_adf AS
	SELECT k::int AS wert, v AS bezeichner, d AS erklaer FROM alkis_wertearten WHERE element='ax_bauraumoderbodenordnungsrecht' and bezeichnung='artderfestlegung';

SELECT alkis_dropobject('v_bschaetz_kulturart');
CREATE VIEW v_bschaetz_kulturart AS
	SELECT
		k::int AS wert
		,regexp_replace( v , E'^.*\\((.*)\\)$', E'\\1') AS kurz
		,v AS bezeichner
	FROM alkis_wertearten WHERE element='ax_bodenschaetzung' and bezeichnung='kulturart';

SELECT alkis_dropobject('v_bschaetz_bodenart');
CREATE VIEW v_bschaetz_bodenart AS
	SELECT
		k::int AS wert
		,regexp_replace( v , E'^.*\\((.*)\\)$', E'\\1') AS kurz
		,v AS bezeichner
	FROM alkis_wertearten WHERE element='ax_bodenschaetzung' and bezeichnung='bodenart';

SELECT alkis_dropobject('v_bschaetz_zustandsstufe');
CREATE VIEW v_bschaetz_zustandsstufe AS
	SELECT
		k::int AS wert
		,regexp_replace( v , E'^.*\\((.*)\\)$', E'\\1') AS kurz
		,v AS bezeichner
	FROM alkis_wertearten WHERE element='ax_bodenschaetzung' and bezeichnung='zustandsstufeoderbodenstufe';

SELECT alkis_dropobject('v_muster_merkmal');
CREATE VIEW v_muster_merkmal AS
	SELECT
		k::int AS wert
		,regexp_replace( v , E'^.*\\((.*)\\)$', E'\\1') AS kurz
		,v AS bezeichner
	FROM alkis_wertearten WHERE element='ax_musterlandesmusterundvergleichsstueck' and bezeichnung='merkmal';

SELECT alkis_dropobject('v_grabloch_bedeutg');
CREATE VIEW v_grabloch_bedeutg AS
	SELECT k::int AS wert, v AS bezeichner FROM alkis_wertearten WHERE element='ax_grablochderbodenschaetzung' and bezeichnung='bedeutung';

SELECT alkis_dropobject('v_bschaetz_sonst');
CREATE VIEW v_bschaetz_sonst AS
	SELECT
		k::int AS wert
		,regexp_replace( v , E'^.*\\((.*)\\)$', E'\\1') AS kurz
		,v AS bezeichner
	FROM alkis_wertearten WHERE element='ax_bodenschaetzung' and bezeichnung='sonstigeangaben';

SELECT alkis_dropobject('v_bewertg_klass');
CREATE VIEW v_bewertg_klass AS
	SELECT k::int AS wert, v AS bezeichner, d AS erklaer FROM alkis_wertearten WHERE element='ax_bewertung' and bezeichnung='klassifizierung';

SELECT alkis_dropobject('v_forstrecht_adf');
CREATE VIEW v_forstrecht_adf AS
	SELECT k::int AS wert, v AS bezeichner FROM alkis_wertearten WHERE element='ax_forstrecht' and bezeichnung='artderfestlegung';

SELECT alkis_dropobject('v_forstrecht_besfkt');
CREATE VIEW v_forstrecht_besfkt AS
	SELECT k::int AS wert, v AS bezeichner FROM alkis_wertearten WHERE element='ax_forstrecht' and bezeichnung='besonderefunktion';

SELECT alkis_dropobject('v_datenerhebung');
CREATE VIEW v_datenerhebung AS
	SELECT k::int AS wert, v AS bezeichner FROM alkis_wertearten WHERE element='ax_li_source_mitdatenerhebung' and bezeichnung='description';

SELECT alkis_dropobject('v_sbauwerk_bwfkt');
CREATE VIEW v_sbauwerk_bwfkt AS
	SELECT k::int AS wert, v AS bezeichner FROM alkis_wertearten WHERE element='ax_sonstigesbauwerkodersonstigeeinrichtung' and bezeichnung='bauwerksfunktion';

SELECT alkis_dropobject('v_bauteil_bauart');
CREATE VIEW v_bauteil_bauart AS
	SELECT
		k::int AS wert
		,v AS bezeichner
		,(SELECT kennung FROM alkis_elemente WHERE name=element) AS kennung
		,element AS objektart
	FROM alkis_wertearten WHERE element='ax_bauteil' and bezeichnung='bauart';

SELECT alkis_dropobject('v_klass_strass_adf');
CREATE VIEW v_klass_strass_adf AS
	SELECT
		k::int AS wert
		,v AS bezeichner
		,(SELECT kennung FROM alkis_elemente WHERE name=element) AS kennung
		,element AS objektart
	FROM alkis_wertearten WHERE element='ax_klassifizierungnachstrassenrecht' and bezeichnung='artderfestlegung';

SELECT alkis_dropobject('v_klass_wasser_adf');
CREATE VIEW v_klass_wasser_adf AS
	SELECT
		k::int AS wert
		,v AS bezeichner
		,(SELECT kennung FROM alkis_elemente WHERE name=element) AS kennung
		,element AS objektart
	FROM alkis_wertearten WHERE element='ax_klassifizierungnachwasserrecht' and bezeichnung='artderfestlegung';

SELECT alkis_dropobject('v_andstrass_adf');
CREATE VIEW v_andstrass_adf AS
	SELECT
		k::int AS wert
		,v AS bezeichner
		,(SELECT kennung FROM alkis_elemente WHERE name=element) AS kennung
		,element AS objektart
	FROM alkis_wertearten WHERE element='ax_anderefestlegungnachstrassenrecht' and bezeichnung='artderfestlegung';

SELECT alkis_dropobject('v_umweltrecht_adf');
CREATE VIEW v_umweltrecht_adf AS
	SELECT
		k::int AS wert
		,v AS bezeichner
		,(SELECT kennung FROM alkis_elemente WHERE name=element) AS kennung
		,element AS objektart
	FROM alkis_wertearten WHERE element='ax_naturumweltoderbodenschutzrecht' and bezeichnung='artderfestlegung';

SELECT alkis_dropobject('v_denkmal_adf');
CREATE VIEW v_denkmal_adf AS
	SELECT
		k::int AS wert
		,v AS bezeichner
		,(SELECT kennung FROM alkis_elemente WHERE name=element) AS kennung
		,element AS objektart
	FROM alkis_wertearten WHERE element='ax_denkmalschutzrecht' and bezeichnung='artderfestlegung';

SELECT alkis_dropobject('v_sonstrecht_adf');
CREATE VIEW v_sonstrecht_adf AS
	SELECT
		k::int AS wert
		,v AS bezeichner
		,(SELECT kennung FROM alkis_elemente WHERE name=element) AS kennung
		,element AS objektart
	FROM alkis_wertearten WHERE element='ax_sonstigesrecht' and bezeichnung='artderfestlegung';
