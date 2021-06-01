#!/bin/bash
############################################################################
#
# Project:  norGIS ALKIS Import
# Purpose:  Shellscript zum ALKIS-Import
# Author:   Jürgen E. Fischer <jef@norbit.de>
#
############################################################################
# Copyright (c) 2012-2018, Jürgen E. Fischer <jef@norbit.de>
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
############################################################################

set -e
set -u
set -o pipefail

# Felder als String interpretieren (führende Nullen nicht abschneiden)
export GML_FIELDTYPES=ALWAYS_STRING

# Warnen, wenn numerische Felder mit alphanumerischen Werten gefüllt werden sollen
export OGR_SETFIELD_NUMERIC_WARNING=ON

# Mindestlänge für Kreisbogensegmente
export OGR_ARC_MINLENGTH=0.1

# Verhindern, dass der GML-Treiber übernimmt
export OGR_SKIP=GML,SEGY

# ogc_fid bei Einfügungen nicht abfragen
export OGR_PG_RETRIEVE_FID=NO

# Headerkennungen die NAS-Daten identifizieren
export NAS_INDICATOR="NAS-Operationen;AAA-Fachschema;aaa.xsd;aaa-suite;adv/gid/6.0"
export NAS_SKIP_CORRUPTED_FEATURES=YES
export LIST_ALL_TABLES=YES
export TABLES="aa_advstandardmodell,aa_nas_ausgabeform,nas_filter_capabilities,aa_themendimension,aa_art_themendefinition,operation,ap_horizontaleausrichtung,ap_vertikaleausrichtung,ap_dateityp_3d,ax_artdesnullpunktes_nullpunkt,ax_li_processstep_mitdatenerhebung_description,ax_datenerhebung,ax_sportart_bauwerkoderanlagefuersportfreizeitunderholung,ax_lagezurerdoberflaeche_transportanlage,ax_produkt_transportanlage,ax_bauwerksfunktion_turm,ax_hydrologischesmerkmal_sonstigesbauwerkodersonstigeeinri,ax_zustand_turm,ax_art_heilquellegasquelle,ax_bauwerksfunktion_transportanlage,ax_lagezurerdoberflaeche_vorratsbehaelterspeicherbauwerk,ax_speicherinhalt_vorratsbehaelterspeicherbauwerk,ax_bauwerksfunktion_bauwerkoderanlagefuerindustrieundgewer,ax_art_einrichtunginoeffentlichenbereichen,ax_bauwerksfunktion_bauwerkoderanlagefuersportfreizeitunde,ax_archaeologischertyp_historischesbauwerkoderhistorischee,ax_hydrologischesmerkmal_heilquellegasquelle,ax_zustand_bauwerkoderanlagefuerindustrieundgewerbe,ax_bauwerksfunktion_sonstigesbauwerkodersonstigeeinrichtun,ax_funktion_bauwerk,ax_bauwerksfunktion_leitung,ax_bauwerksfunktion_vorratsbehaelterspeicherbauwerk,ax_befestigung_wegpfadsteig,ax_oberflaechenmaterial_flugverkehrsanlage,ax_art_gleis,ax_bahnkategorie_gleis,ax_art_strassenverkehrsanlage,ax_markierung_wegpfadsteig,ax_bahnhofskategorie_bahnverkehrsanlage,ax_bahnkategorie_seilbahnschwebebahn,ax_zustand_bahnverkehrsanlage,ax_zustand_bauwerkimgewaesserbereich,ax_art_wegpfadsteig,ax_lagezuroberflaeche_gleis,ax_art_flugverkehrsanlage,ax_bauwerksfunktion_bauwerkimverkehrsbereich,ax_bauwerksfunktion_bauwerkimgewaesserbereich,ax_art_einrichtungenfuerdenschiffsverkehr,ax_zustand_bauwerkimverkehrsbereich,ax_artdergewaesserachse,ax_art_schifffahrtsliniefaehrverkehr,ax_zustand_schleuse,ax_nutzung_hafen,ax_konstruktionsmerkmalbauart_schleuse,ax_hafenkategorie_hafen,ax_art_gewaessermerkmal,ax_hydrologischesmerkmal_untergeordnetesgewaesser,ax_lagezurerdoberflaeche_untergeordnetesgewaesser,ax_artdespolders,ax_funktion_polder,ax_funktion_untergeordnetesgewaesser,ax_hydrologischesmerkmal_gewaessermerkmal,ax_funktion_vegetationsmerkmal,ax_zustand_vegetationsmerkmal,ax_bewuchs_vegetationsmerkmal,ax_eigentuemerart_namensnummer,ax_li_processstep_ohnedatenerhebung_description,ax_blattart_buchungsblatt,ax_anrede_person,ax_artderrechtsgemeinschaft_namensnummer,ax_buchungsart_buchungsstelle,ax_klassifikation_hierarchiestufe3d_lagefestpunkt,ax_punktstabilitaet,ax_punktstabilitaet_hoehenfestpunkt_geologischestabilitaet,ax_klassifikation_ordnung_lagefestpunkt,ax_punktstabilitaet_hoehenfestpunkt_guetedesvermarkungstra,ax_ordnung_schwerefestpunkt,ax_funktion_referenzstationspunkt,ax_funktion_lagefestpunkt,ax_skizzenart_skizze,ax_funktion_schwerefestpunkt,ax_punktstabilitaet_hoehenfestpunkt_hoehenstabilitaetauswi,ax_punktstabilitaet_hoehenfestpunkt_guetedesbaugrundes,ax_punktstabilitaet_hoehenfestpunkt_grundwasserschwankung,ax_punktstabilitaet_hoehenfestpunkt_topographieundumwelt,ax_klassifikation_wertigkeit_lagefestpunkt,ax_gnsstauglichkeit,ax_punktstabilitaet_hoehenfestpunkt_grundwasserstand,ax_punktstabilitaet_hoehenfestpunkt_vermutetehoehenstabili,ax_ordnung_hoehenfestpunkt,ax_horizontfreiheit_grenzpunkt,ax_gruendederausgesetztenabmarkung_grenzpunkt,ax_bemerkungzurabmarkung_grenzpunkt,ax_artderflurstuecksgrenze_besondereflurstuecksgrenze,ax_horizontfreiheit_netzpunkt,ax_marke,ax_genauigkeitsstufe_punktort,ax_messmethode_schwere,ax_koordinatenstatus_punktort,ax_datenerhebung_schwere,ax_vertrauenswuerdigkeit_schwere,ax_schwereanomalie_schwere_art,ax_vertrauenswuerdigkeit_punktort,ax_schwerestatus_schwere,ax_li_processstep_punktort_description,ax_genauigkeitsstufe_schwere,ax_datenerhebung_punktort,ax_schweresystem_schwere,ax_blattart_historischesflurstueck,ax_qualitaet_hauskoordinate,ax_art_punktkennung,ax_art_reservierung,ax_art_adressat_auszug,ax_lagezurerdoberflaeche_bauteil,ax_lagezurerdoberflaeche_gebaeude,ax_zustand_gebaeude,ax_dachgeschossausbau_gebaeude,ax_dachform,ax_bauweise_gebaeude,ax_gebaeudefunktion,ax_art_gebaeudepunkt,ax_weitere_gebaeudefunktion,ax_beschaffenheit_besonderegebaeudelinie,ax_bauart_bauteil,ax_nutzung,ax_art_verbandsgemeinde,ax_art_baublock,ax_artdergebietsgrenze_gebietsgrenze,ax_sonstigeangaben_bodenschaetzung,ax_kulturart_musterlandesmusterundvergleichsstueck,ax_entstehungsartoderklimastufewasserverhaeltnisse_bodensc,ax_sonstigeangaben_musterlandesmusterundvergleichsstueck,ax_kulturart_bodenschaetzung,ax_klassifizierung_bewertung,ax_merkmal_musterlandesmusterundvergleichsstueck,ax_zustandsstufeoderbodenstufe_bodenschaetzung,ax_bedeutung_grablochderbodenschaetzung,ax_zustandsstufeoderbodenstufe_musterlandesmusterundvergle,ax_entstehungsartoderklimastufewasserverhaeltnisse_musterl,ax_bodenart_bodenschaetzung,ax_bodenart_musterlandesmusterundvergleichsstueck,ax_landschaftstyp,ax_art_verband,ax_behoerde,ax_administrative_funktion,ax_bezeichnung_verwaltungsgemeinschaft,ax_funktion_schutzgebietnachwasserrecht,ax_artderfestlegung_schutzgebietnachnaturumweltoderbodensc,ax_artderfestlegung_anderefestlegungnachstrassenrecht,ax_artderfestlegung_schutzgebietnachwasserrecht,ax_besonderefunktion_forstrecht,ax_zone_schutzzone,ax_artderfestlegung_klassifizierungnachstrassenrecht,ax_artderfestlegung_denkmalschutzrecht,ax_artderfestlegung_klassifizierungnachwasserrecht,ax_rechtszustand_schutzzone,ax_artderfestlegung_bauraumoderbodenordnungsrecht,ax_artderfestlegung_anderefestlegungnachwasserrecht,ax_artderfestlegung_forstrecht,ax_zustand_naturumweltoderbodenschutzrecht,ax_artderfestlegung_sonstigesrecht,ax_artderfestlegung_naturumweltoderbodenschutzrecht,ax_liniendarstellung_topographischelinie,ax_darstellung_gebaeudeausgestaltung,ax_datenformat_benutzer,ax_art_bereichzeitlich,ax_letzteabgabeart,ax_ausgabemedium_benutzer,ax_identifikation,ax_dqerfassungsmethodemarkantergelaendepunkt,ax_dqerfassungsmethodestrukturiertegelaendepunkte,ax_dqerfassungsmethode,ax_besonderebedeutung,ax_dqerfassungsmethodebesondererhoehenpunkt,ax_artdergeripplinie,ax_artdergelaendekante,ax_artderstrukturierung,ax_dqerfassungsmethodegewaesserbegrenzung,ax_artdernichtgelaendepunkte,ax_artdesmarkantengelaendepunktes,ax_artderaussparung,ax_besondereartdergewaesserbegrenzung,ax_ursprung,ax_funktion_dammwalldeich,ax_art_dammwalldeich,ax_funktion_einschnitt,ax_zustand_boeschungkliff,ax_zustand_hoehleneingang,ax_berechnungsmethode,ax_verwendeteobjekte,ax_berechnungsmethodehoehenlinie,ax_dqerfassungsmethodesekundaeresdgm,ax_zustand_kanal,ax_funktion_stehendesgewaesser,ax_schifffahrtskategorie,ax_hydrologischesmerkmal_fliessgewaesser,ax_schifffahrtskategorie_kanal,ax_funktion_fliessgewaesser,ax_widmung_wasserlauf,ax_funktion_meer,ax_hydrologischesmerkmal_gewaesserachse,ax_tidemerkmal_meer,ax_nutzung_hafenbecken,ax_hydrologischesmerkmal_stehendesgewaesser,ax_widmung_stehendesgewaesser,ax_funktion_gewaesserachse,ax_funktion_hafenbecken,ax_widmung_kanal,ax_zustand_wohnbauflaeche,ax_artderbebauung_wohnbauflaeche,ax_zustand_flaechebesondererfunktionalerpraegung,ax_funktion_flaechegemischternutzung,ax_foerdergut_industrieundgewerbeflaeche,ax_artderbebauung_flaechegemischternutzung,ax_zustand_sportfreizeitunderholungsflaeche,ax_funktion_flaechebesondererfunktionalerpraegung,ax_funktion_sportfreizeitunderholungsflaeche,ax_lagergut_industrieundgewerbeflaeche,ax_zustand_halde,ax_zustand_bergbaubetrieb,ax_abbaugut_tagebaugrubesteinbruch,ax_primaerenergie_industrieundgewerbeflaeche,ax_abbaugut_bergbaubetrieb,ax_zustand_flaechegemischternutzung,ax_zustand_industrieundgewerbeflaeche,ax_funktion_friedhof,ax_zustand_friedhof,ax_lagergut_halde,ax_funktion_industrieundgewerbeflaeche,ax_zustand_tagebaugrubesteinbruch,ax_artderbebauung_siedlungsflaeche,ax_artderbebauung_flaechebesondererfunktionalerpraegung,ax_vegetationsmerkmal_gehoelz,ax_vegetationsmerkmal_wald,ax_vegetationsmerkmal_landwirtschaft,ax_oberflaechenmaterial_unlandvegetationsloseflaeche,ax_funktion_unlandvegetationsloseflaeche,ax_funktion_gehoelz,ax_bahnkategorie,ax_funktion_weg,ax_funktion_bahnverkehr,ax_verkehrsbedeutunginneroertlich,ax_internationalebedeutung_strasse,ax_besonderefahrstreifen,ax_zustand_bahnverkehr,ax_befestigung_fahrwegachse,ax_spurweite,ax_zustand_schiffsverkehr,ax_funktion_platz,ax_art_flugverkehr,ax_elektrifizierung,ax_zustand,ax_fahrbahntrennung_strasse,ax_funktion_fahrbahnachse,ax_oberflaechenmaterial_strasse,ax_funktion_flugverkehr,ax_funktion_wegachse,ax_zustand_strasse,ax_markierung_wegachse,ax_zustand_flugverkehr,ax_funktion_strassenachse,ax_verkehrsbedeutungueberoertlich,ax_nutzung_flugverkehr,ax_funktion_schiffsverkehr,ax_funktion_strasse,ax_widmung_strasse,ax_anzahlderstreckengleise,ax_funktionoa_k_tngr_all,ax_klassifizierunggr_k_bewgr,ax_funktionoa_k_tnfl,ax_klassifizierungobg_k_bewfl,ax_funktionoa_k_tngrerweitert_all,ax_funktionhgr_k_tnhgr,ax_wirtschaftsart,ax_punktart_k_punkte,ax_k_zeile_punktart,aa_besonderemeilensteinkategorie,aa_anlassart,aa_levelofdetail,aa_anlassart_benutzungsauftrag,aa_weiteremodellart,aa_instanzenthemen,ax_benutzer,ax_benutzergruppemitzugriffskontrolle,ax_benutzergruppenba,ap_darstellung,aa_projektsteuerung,aa_meilenstein,aa_antrag,aa_aktivitaet,aa_vorgang,ax_person,ax_namensnummer,ax_anschrift,ax_verwaltung,ax_buchungsstelle,ax_personengruppe,ax_buchungsblatt,ax_vertretung,ax_skizze,ax_schwere,ax_historischesflurstueckalb,ax_historischesflurstueckohneraumbezug,ax_lagebezeichnungohnehausnummer,ax_lagebezeichnungmithausnummer,ax_lagebezeichnungmitpseudonummer,ax_reservierung,ax_punktkennunguntergegangen,ax_punktkennungvergleichend,ax_fortfuehrungsnachweisdeckblatt,ax_fortfuehrungsfall,ax_gemeinde,ax_buchungsblattbezirk,ax_gemarkungsteilflur,ax_kreisregion,ax_bundesland,ax_regierungsbezirk,ax_gemeindeteil,ax_lagebezeichnungkatalogeintrag,ax_gemarkung,ax_dienststelle,ax_verband,ax_nationalstaat,ax_besondererbauwerkspunkt,ax_netzknoten,ax_referenzstationspunkt,ax_lagefestpunkt,ax_hoehenfestpunkt,ax_schwerefestpunkt,ax_grenzpunkt,ax_aufnahmepunkt,ax_sonstigervermessungspunkt,ax_sicherungspunkt,ax_besonderergebaeudepunkt,ax_wirtschaftlicheeinheit,ax_verwaltungsgemeinschaft,ax_schutzgebietnachnaturumweltoderbodenschutzrecht,ax_schutzgebietnachwasserrecht,ax_boeschungkliff,ax_besonderertopographischerpunkt,ax_kanal,ax_wasserlauf,ax_strasse,ap_fpo,aa_antragsgebiet,ax_polder,ax_historischesflurstueck,ax_kondominium,ax_baublock,ax_aussparungsflaeche,ax_soll,ax_duene,ax_transportanlage,ax_wegpfadsteig,ax_gleis,ax_bahnverkehrsanlage,ax_strassenverkehrsanlage,ax_einrichtungenfuerdenschiffsverkehr,ax_flugverkehrsanlage,ax_hafen,ax_testgelaende,ax_schleuse,ax_ortslage,ax_grenzuebergang,ax_gewaessermerkmal,ax_untergeordnetesgewaesser,ax_vegetationsmerkmal,ax_musterlandesmusterundvergleichsstueck,ax_insel,ax_gewann,ax_kleinraeumigerlandschaftsteil,ax_landschaft,ax_felsenfelsblockfelsnadel,ap_lto,ax_leitung,ax_abschnitt,ax_ast,ap_lpo,ax_seilbahnschwebebahn,ax_gebaeudeausgestaltung,ax_topographischelinie,ax_geripplinie,ax_gewaesserbegrenzung,ax_strukturierterfasstegelaendepunkte,ax_einschnitt,ax_hoehenlinie,ax_abgeleitetehoehenlinie,ap_pto,ax_heilquellegasquelle,ax_wasserspiegelhoehe,ax_nullpunkt,ax_punktortau,ax_georeferenziertegebaeudeadresse,ax_grablochderbodenschaetzung,ax_wohnplatz,ax_markantergelaendepunkt,ax_besondererhoehenpunkt,ax_hoehleneingang,ap_ppo,ax_sickerstrecke,ax_firstlinie,ax_besonderegebaeudelinie,ax_gelaendekante,ax_sonstigesbauwerkodersonstigeeinrichtung,ax_bauwerkoderanlagefuersportfreizeitunderholung,ax_bauwerkoderanlagefuerindustrieundgewerbe,ax_einrichtunginoeffentlichenbereichen,ax_historischesbauwerkoderhistorischeeinrichtung,ax_turm,ax_vorratsbehaelterspeicherbauwerk,ax_bauwerkimgewaesserbereich,ax_bauwerkimverkehrsbereich,ax_schifffahrtsliniefaehrverkehr,ax_gebaeude,ax_anderefestlegungnachstrassenrecht,ax_naturumweltoderbodenschutzrecht,ax_klassifizierungnachstrassenrecht,ax_sonstigesrecht,ax_denkmalschutzrecht,ax_dammwalldeich,ax_punktortag,ax_bauteil,ax_tagesabschnitt,ax_bewertung,ax_anderefestlegungnachwasserrecht,ax_klassifizierungnachwasserrecht,ax_forstrecht,ax_bauraumoderbodenordnungsrecht,ax_schutzzone,ax_boeschungsflaeche,ax_flurstueck,ax_gebiet_kreis,ax_gebiet_bundesland,ax_gebiet_regierungsbezirk,ax_gebiet_nationalstaat,ax_kommunalesgebiet,ax_gebiet_verwaltungsgemeinschaft,ax_bodenschaetzung,ax_gewaesserstationierungsachse,ax_besondereflurstuecksgrenze,ax_gebietsgrenze,ax_gewaesserachse,ax_strassenachse,ax_bahnstrecke,ax_fahrwegachse,ax_fahrbahnachse,ax_punktortta,ax_stehendesgewaesser,ax_meer,ax_fliessgewaesser,ax_hafenbecken,ax_bergbaubetrieb,ax_friedhof,ax_flaechegemischternutzung,ax_wohnbauflaeche,ax_flaechebesondererfunktionalerpraegung,ax_industrieundgewerbeflaeche,ax_siedlungsflaeche,ax_tagebaugrubesteinbruch,ax_sportfreizeitunderholungsflaeche,ax_halde,ax_flaechezurzeitunbestimmbar,ax_sumpf,ax_unlandvegetationsloseflaeche,ax_gehoelz,ax_wald,ax_heide,ax_moor,ax_landwirtschaft,ax_bahnverkehr,ax_weg,ax_schiffsverkehr,ax_flugverkehr,ax_platz,ax_strassenverkehr,ta_compositesolidcomponent_3d,ta_surfacecomponent_3d,ta_curvecomponent_3d,ta_pointcomponent_3d,au_trianguliertesoberflaechenobjekt_3d,au_mehrfachflaechenobjekt_3d,au_mehrfachlinienobjekt_3d,au_umringobjekt_3d,ap_kpo_3d,au_punkthaufenobjekt_3d,au_koerperobjekt_3d,au_geometrieobjekt_3d,ax_fortfuehrungsauftrag,ks_einrichtunginoeffentlichenbereichen,ks_bauwerkanlagenfuerverundentsorgung,ks_sonstigesbauwerk,ks_verkehrszeichen,ks_bauwerkimgewaesserbereich,ks_vegetationsmerkmal,ks_bauraumoderbodenordnungsrecht,ks_kommunalerbesitz"

export PGCLIENTENCODING=UTF8

export EPSG=25832
export CRS="-a_srs EPSG:$EPSG"
export FNBRUCH=true
export AVOIDDUPES=false
export HISTORIE=true
export PGVERDRAENGEN=false
export SCHEMA=public
export PARENTSCHEMA=
export PGSCHEMA=public

B=${0%/*}   # BASEDIR
if [ "$0" = "$B" ]; then
	B=.
fi
case "$MACHTYPE" in
*-cygwin|*msys)
       B=$(cygpath -m "$B")
       ;;
esac
export P=${0##*/}  # PROGNAME

export NAS_GFS_TEMPLATE=$B/alkis-schema.gfs
export NAS_NO_RELATION_LAYER=YES

bdate() {
	local t=${1:-+%F %T}
	date "$t"
}
export -f bdate

memunits() {
	local s=$1
	local u=" Bytes"

	if (( s > 10240 )); then (( s /= 1024 )); u="kiB"; fi
	if (( s > 10240 )); then (( s /= 1024 )); u="MiB"; fi
	if (( s > 10240 )); then (( s /= 1024 )); u="GiB"; fi

	echo "$s$u"
}
export -f memunits

timeunits() {
	local t=$1
	local t1=$2

	if [ -n "$t1" ]; then t=$(( t1 - t )); fi

	local s=$(( t % 60 ))
	local m=$(( (t / 60) % 60 ))
	local h=$(( (t / 60 / 60) % 24 ))
	local d=$(( t / 60 / 60 / 24 ))

	local r=
	if (( d > 0 )); then r="$r${d}d"; fi
	if (( h > 0 )); then r="$r${h}h"; fi
	if (( m > 0 )); then r="$r${m}m"; fi
	if (( s > 0 )); then r="$r${s}s"; fi

	[ -z "$r" ] && r="0,nichts"

	echo $r
}
export -f timeunits

log() {
	tee $1 | python3 $B/refilter.py
}
export -f log

rund() {
	local dir=$1

	if [ -d "$dir.d" ]; then
		for i in $(ls -1d ${dir}.d/* 2>/dev/null | sort); do
			if [ -d "$i" ]; then
				ls -1 $i/*.sql 2>/dev/null | sort | parallel --line-buffer --halt soon,fail=1 --jobs=$JOBS sql
			elif [ -f "$i" -a -r "$i" ]; then
				sql $i
			else
				continue
			fi
			r=$?
			if [ "$r" -ne 0 ]; then
				return $r
			fi
		done
	fi
}

import() {
	local src=$1
	local dst
	local elapsed
	local sf_opt
	local t0
	local t1

	t0=$(bdate +%s)

	case $src in
	*.zip)
		dst=${src%.zip}.xml
		dst="$tmpdir/${dst//\//_}"
		echo "DECOMPRESS $(bdate): $src"
		if [ -e "$dst" ]; then
			echo "$P: $dst bereits vorhanden." >&2
			return 1
		fi
		if ! zcat "$src" >"$dst"; then
			rm -v "$dst"
			echo "$P: $src konnte nicht extrahiert werden." >&2
			return 1
		fi
		rm=1
		;;

	*.xml.gz)
		if ! [ -f "$src" -a -r "$src" ]; then
			echo "$P: $src nicht gefunden oder nicht lesbar." >&2
			return 1
		fi

		dst=${src%.gz}
		dst="$tmpdir/${dst//\//_}"
		echo "DECOMPRESS $(bdate): $src"
		if [ -e "$dst" ]; then
			echo "$P: $dst bereits vorhanden." >&2
			return 1
		fi
		if ! zcat "$src" >"$dst"; then
			rm -v "$dst"
			echo "$P: $src konnte nicht extrahiert werden." >&2
			return 1
		fi
		rm=1
		;;

	*.xml)
		if ! [ -f "$src" -a -r "$src" ]; then
			echo "$P: $src nicht gefunden oder nicht lesbar." >&2
			return 1
		fi

		dst="$src"
		rm=0
		;;
	*)
		echo "UNKNOWN FILE $src"
		return 1
		;;
	esac

	[ -f "${dst%.xml}.gfs" ] && rm -v "${dst%.xml}.gfs"

	if ! [ -f "$dst" -a -r "$dst" ]; then
		echo "$src => $dst"
		return 1
	fi

	trap "echo '$P: Fehler bei $src' >&2; src=error" EXIT

	s=$(stat -c %s "$dst")

	echo "IMPORT $(bdate): $dst $(memunits $s)"

	if [ -n "$sfre" ] && eval [[ "$src" =~ "$sfre" ]]; then
		opt="$opt -skipfailures"
	fi
	opt="$opt -ds_transaction --config PG_USE_COPY YES -nlt CONVERT_TO_LINEAR"

	case "$MACHTYPE" in
	*-cygwin|*msys)
		dst1=$(cygpath -m "$dst")
		;;
	*)
		dst1=$dst
		;;
	esac

	echo "RUNNING: ogr2ogr -f $DRIVER $opt -update -append \"$DST\" $CRS \"$dst1\"" | sed -Ee 's/password=\S+/password=*removed*/'
	ogr2ogr -f $DRIVER $opt $sf_opt -update -append "$DST" $CRS "$dst1"
	local r=$?
	t1=$(bdate +%s)

	progress "$dst" $s $t0 $t1 $r

	[ $rm == 1 ] && rm -fv "$dst"
	trap "" EXIT

	return $r
}
export -f import

process() {
	local r=0
	if [ -f "$job" ]; then
		if [ -z "$DST" ]; then
			echo "$P: Keine Datenbankverbindungsdaten angegeben" >&2
			return 1
		fi

		if (( preprocessed == 0 )); then
			pushd "$B" >/dev/null
			preprocessed=1
			rund preprocessing
			r=$?
			popd >/dev/null
			if [ "$r" -ne 0 ]; then
				return $r
			fi
		fi

		export job
		export progress
		parallel --line-buffer --halt soon,fail=1 --jobs=$JOBS import <$job
		r=$?
		rm $job
	fi
	return $r
}

progress() {
	local file=$1
	local size=$2
	local t0=$3
	local t1=$4
	local r=$5
	local elapsed
	local total_elapsed
	local total_size
	local remaining_size
	local errors=0

	lockfile $lock
	[ -f $progress ] && . $progress

	start_time=${start_time:-$t0}
	elapsed=$(( t1 - t0 ))
	total_elapsed=$(( t1 - start_time ))
	(( remaining_size -= size ))
	done_size=$(( total_size - remaining_size ))
	remaining_time=$(( remaining_size * total_elapsed / done_size ))
	eta=$(( t1 + remaining_time ))

	if [ $r -ne 0 ]; then
		(( errors++ )) || true
		echo "ERROR: Ergebnis $r bei $file (bislang $errors Fehler)"
	fi

	if (( elapsed > 0 )); then
		throughput=$(( size / elapsed ))
		total_throughput=$(( done_size / total_elapsed ))

		if (( t0 < t1 )); then
			echo "TIME: $file mit $(memunits $size) in $(timeunits $t0 $t1) importiert ($(memunits $throughput)/s; Gesamt:$(memunits $total_throughput)/s)."
			echo "REMAINING: $(memunits $remaining_size) $(( remaining_size * 100 / total_size ))% $(timeunits $remaining_time) ETA:$(date --date="1970-01-01 $eta seconds UTC")"
		else
			echo "TIME: $file mit $(memunits $size) in 0,nichts (Gesamt $(memunits $total_throughput)/s)."
		fi
	else
		echo "TIME: $file mit $(memunits $size) in 0,nichts importiert."
	fi

	cat <<EOF >$progress
start_time=$start_time
total_size=$total_size
remaining_size=$remaining_size
last_time=$t1
errors=$errors
EOF

	rm -f $lock
}
export -f progress

final() {
	lockfile $lock
	start_time=0
	last_time=0
	! [ -f $progress ] || . $progress
	total_elapsed=$(( last_time - start_time ))
	if (( total_elapsed > 0 )); then
		echo "FINAL: $(memunits $total_size) in $(timeunits $start_time $last_time) ($(memunits $(( total_size / total_elapsed )))/s)"
	fi
	rm -rf $tmpdir
}

export LC_CTYPE=de_DE.UTF-8
export TEMP=${TEMP:-/tmp}
export TMPDIR=$TEMP

if [ "$#" -ne 1 ]; then
	echo "usage: $P file" >&2
	exit 1
fi

F=$1
if [ -z "$F" ]; then
	echo "usage: $P file"
	exit 1
elif ! [ -f "$F" -a -r "$F" ]; then
	echo "$P: $F nicht gefunden oder nicht lesbar." >&2
	exit 1
fi

if [ -z "$BASH_VERSION" ]; then
	echo "$P: erfordert bash" >&2
	exit 1
fi

echo "START $(bdate)"

GDAL_VERSION=$(unset CPL_DEBUG; ogr2ogr --version)
echo $GDAL_VERSION

major=${GDAL_VERSION#GDAL }
major=${major%%.*}
minor=${GDAL_VERSION#GDAL $major.}
minor=${minor%%.*}
if [ $major -lt 2 ] || [ $major -eq 2 -a $minor -lt 3 ]; then
	echo "$P: erfordert GDAL >=2.3" >&2
	exit 1
fi

export CPL_DEBUG
export B
export DRIVER
export DST
export JOBS=-1
export opt

opt=
log=
preprocessed=0
sfre=

export job=
export tmpdir=$(mktemp -d)
[ -d "$tmpdir" ] && trap "rm -rf '$tmpdir'" EXIT
export lock=$tmpdir/nas.lock
export progress=$tmpdir/nas.progress
export jobi=0

rm -f $lock
while read src
do
	case $src in
	""|"#"*)
		# Leerzeilen und Kommentare ignorieren
		continue
		;;

	*.zip|*.xml.gz|*.xml)
		if [ -z "$job" ]; then
			echo "$P: Bestimme unkomprimierte Gesamtgröße"

			S=0
			while read file
			do
				if [ "$file" = "exit" ]; then
					break
				elif ! [ -f "$file" -a -r "$file" ]; then
					continue
				fi

				case "$file" in
				*.xml.zip)
					if ! s=$(zcat "$file" | wc -c); then
						s=0
					fi
					;;

				*.zip)
					if ! s=$(zcat "$file" | wc -c); then
						s=0
					fi
					;;

				*.xml.gz)
					if ! s=$(gzip -ql "$file" | tr -s " " | cut -d" " -f3); then
						s=0
					fi
					;;

				*.xml)
					if ! s=$(stat -c %s "$file"); then
						s=0
					fi
					;;

				*)
					echo "$P: Nicht unterstützte Datei $file" >&2
					continue
					;;
				esac

				(( S += s )) || true
			done <"$F"

			cat <<EOF >$progress
total_size=$S
remaining_size=$S
EOF

			if (( S > 0 )); then
				echo "$P: Unkomprimierte Gesamtgröße: $(memunits $S)"
			fi

			export job=$tmpdir/$(( ++jobi )).lst
		fi

		echo $src >>$job
		continue
		;;
	esac

	process

	case $src in
	PG:*)
		DST=$src
		DB=${src#PG:}
		DRIVER=PostgreSQL
		sql() {
			local file=$1
			pushd "$B" >/dev/null
			local t0=$(bdate +%s)
			echo "SQL RUN: $file $(bdate)"
			psql -X -P pager=off \
				-v alkis_pgverdraengen=$PGVERDRAENGEN \
				-v alkis_fnbruch=$FNBRUCH \
				-v alkis_avoiddupes=$AVOIDDUPES \
				-v alkis_hist=$HISTORIE \
				-v alkis_epsg=$EPSG \
				-v alkis_schema=$SCHEMA \
				-v postgis_schema=$PGSCHEMA \
				-v parent_schema=${PARENTSCHEMA:-$SCHEMA} \
				-v ON_ERROR_STOP=1 \
				-v ECHO=errors \
				--quiet \
				-c "SET application_name='$file'" \
				-f "$file" \
				"$DB"
			local r=$?
			local t1=$(bdate +%s)
			echo "SQL DONE[$r]: $file $(bdate) in $(timeunits $t0 $t1)"
			popd >/dev/null
			return $r
		}
		export -f sql
		runsql() {
			psql -X -P pager=off \
				-v alkis_pgverdraengen=$PGVERDRAENGEN \
				-v alkis_fnbruch=$FNBRUCH \
				-v alkis_avoiddupes=$AVOIDDUPES \
				-v alkis_hist=$HISTORIE \
				-v alkis_epsg=$EPSG \
				-v alkis_schema=$SCHEMA \
				-v postgis_schema=$PGSCHEMA \
				-v parent_schema=${PARENTSCHEMA:-$SCHEMA} \
				-v ON_ERROR_STOP=1 \
				-v ECHO=errors \
				-c "$1" \
				"$DB"
		}
		export -f runsql
		dump() {
			pg_dump -Fc -f "$1.backup" "$DB"
		}
		restore() {
			if ! [ -f "$1.backup" -a -r "$1.backup" ]; then
				echo "$P: $1.backup nicht gefunden oder nicht lesbar." >&2
				return 1
			fi
			pg_restore -Fc -c "$1.backup" | psql -X "$DB"
		}
		export DB
		log() {
			n=$(psql -X -t -c "SELECT count(*) FROM pg_catalog.pg_namespace WHERE nspname='${SCHEMA//\'/\'\'}'" "$DB")
			n=${n//[	 ]}
			if [ $n -eq 0 ]; then
				psql -X -q -c "CREATE SCHEMA \"${SCHEMA//\"/\"\"}\"" "$DB"
			fi

			n=$(psql -X -t -c "SELECT count(*) FROM pg_catalog.pg_namespace WHERE nspname='${SCHEMA//\'/\'\'}'" "$DB")
			n=${n//[	 ]}
			if [ $n -eq 0 ]; then
				echo "Schema $SCHEMA nicht erzeugt" >&2
				exit 1
			fi

			n=$(psql -X -t -c "SELECT count(*) FROM pg_catalog.pg_tables WHERE schemaname='${SCHEMA//\'/\'\'}' AND tablename='alkis_importlog'" "$DB")
			n=${n//[	 ]}
			if [ $n -eq 0 ]; then
				psql -X -q -c "CREATE TABLE \"${SCHEMA//\"/\"\"}\".alkis_importlog(n SERIAL PRIMARY KEY, ts timestamp default now(), msg text)" "$DB"
			fi

			tee $1 |
			(
				IFS=
				exec 5> >(python3 $B/refilter.py >&3)
				while read m; do
					echo "$m" >&5
					m=${m//\'/\'\'}
					echo "INSERT INTO \"${SCHEMA//\"/\"\"}\".alkis_importlog(msg) VALUES (E'${m//\'/\'\'}');"
				done
				echo "\\q"
			) |
			psql -X -q "$DB"
		}
		continue
		;;

	"pgschema "*)
		PGSCHEMA=${src#pgschema }
		if [ $major -lt 3 ] || [ $major -eq 3 -a $minor -lt 1 ]; then
			DST="${DST/ active_schema=*/} active_schema=$SCHEMA','$PGSCHEMA"
		else
			DST="${DST/ active_schema=*/} active_schema=$SCHEMA schemas=$SCHEMA,$PGSCHEMA"
		fi
		continue
		;;

	"schema "*)
		SCHEMA=${src#schema }
		if [ $major -lt 3 ] || [ $major -eq 3 -a $minor -lt 1 ]; then
			DST="${DST/ active_schema=*/} active_schema=$SCHEMA','$PGSCHEMA"
		else
			DST="${DST/ active_schema=*/} active_schema=$SCHEMA schemas=$SCHEMA,$PGSCHEMA"
		fi
		continue
		;;

	"historie "*)
		HISTORIE=${src#historie }
		case "$HISTORIE" in
		an|on|true|an)
			HISTORIE=true
			;;
		aus|off|false)
			HISTORIE=false
			;;
		*)
			echo "$P: Ungültiger Wert $HISTORIE (true or false erwartet)"
			exit 1
			;;
		esac

		continue
		;;

	"avoiddupes "*)
		AVOIDDUPES=${src#avoiddupes }
		case "$AVOIDDUPES" in
		an|on|true|an)
			AVOIDDUPES=true
			;;
		aus|off|false)
			AVOIDDUPES=false
			;;
		*)
			echo "$P: Ungültiger Wert $AVOIDDUPES (true or false erwartet)"
			exit 1
			;;
		esac

		continue
		;;

	"fnbruch "*)
		FNBRUCH=${src#fnbruch }
		case "$FNBRUCH" in
		an|on|true|an)
			FNBRUCH=true
			;;
		aus|off|false)
			FNBRUCH=false
			;;
		*)
			echo "$P: Ungültiger Wert $FNBRUCH (true or false erwartet)"
			exit 1
			;;
		esac

		continue
		;;

	"pgverdraengen "*)
		PGVERDRAENGEN=${src#pgverdraengen }
		case "$PGVERDRAENGEN" in
		an|on|true|an)
			PGVERDRAENGEN=true
			;;
		aus|off|false)
			PGVERDRAENGEN=false
			;;
		*)
			echo "$P: Ungültiger Wert $PGVERDRAENGEN (true or false erwartet)"
			exit 1
			;;
		esac

		continue
		;;

	"epsg "*)
		EPSG=${src#epsg }

		if [ $major -ge 3 ]; then
			case "$EPSG" in
			13146[678]|3068)
				export CRS="-a_srs '$B/$EPSG.wkt2'"
				;;
			13068)
				export CRS="-ct '+proj=pipeline +step +inv +proj=utm +zone=33 +ellps=GRS80 +step +inv +proj=hgridshift +grids=ntv2berlin20130508.GSB +step +proj=cass +lat_0=52.4186482777778 +lon_0=13.6272036666667 +x_0=40000 +y_0=10000 +ellps=bessel +step +proj=axisswap +order=2' -a_srs EPSG:3068"
				;;
			3146[678])
				export CRS="-s_srs '$B/1$EPSG.wkt2' -t_srs 'EPSG:$EPSG"
				;;
			*)
				;;
			esac

		else
			case "$EPSG" in
			13146[678]|3068)
				export PROJ_LIB=$B CRS="-a_srs +init=custom:$EPSG"
				;;
			13068)
				export PROJ_LIB=$B CRS="-s_srs EPSG:25833 -t_srs +init=custom:3068"
				;;
			3146[678])
				export PROJ_LIB=$B CRS="-s_srs +init=custom:1$EPSG -t_srs EPSG:$EPSG"
				;;
			*)
				;;
			esac

		fi

		continue
		;;

	"inherit "*)
		PARENTSCHEMA=${src#inherit }
		if [ -z "$DB" ]; then
			echo "$P: Keine Datenbankverbindungsdaten angegeben" >&2
			exit 1
		fi

		echo "INHERIT $(bdate)"
		pushd "$B" >/dev/null
		rund preinherit
		sql alkis-inherit.sql
		rund postinherit
		popd >/dev/null

		continue
		;;

	"jobs "*)
		JOBS=${src#jobs }
		continue
		;;

	create)
		if [ -z "$DB" ]; then
			echo "$P: Keine Datenbankverbindungsdaten angegeben" >&2
			exit 1
		fi
		if [ -n "$PARENTSCHEMA" ]; then
			echo "$P: Elterschema $PARENTSCHEMA gesetzt!?" >&2
			exit 1
		fi

		echo "CREATE $(bdate)"
		pushd "$B" >/dev/null
		rund prepare
		rund precreate
		sql alkis-init.sql
		rund postcreate
		popd >/dev/null

		continue
		;;

	clean)
		if [ -z "$DB" ]; then
			echo "$P: Keine Datenbankverbindungsdaten angegeben" >&2
			exit 1
		fi

		echo "CLEAN $(bdate)"
		pushd "$B" >/dev/null
		rund prepare
		rund preclean
		sql alkis-clean.sql
		rund postclean
		popd >/dev/null

		continue
		;;

	update)
		if [ -z "$DB" ]; then
			echo "$P: Keine Datenbankverbindungsdaten angegeben" >&2
			exit 1
		fi
		if [ -n "$PARENTSCHEMA" ]; then
			echo "$P: Elterschema $PARENTSCHEMA gesetzt!?" >&2
			exit 1
		fi

		echo "UPDATE $(bdate)"
		pushd "$B" >/dev/null
		rund prepare
		rund preupdate
		sql alkis-update.sql
		rund postupdate
		popd >/dev/null

		continue
		;;

	"temp "*)
		TEMP=${src#temp }
		TMPDIR=$TEMP
		if ! [ -d "$TEMP" ]; then
			mkdir -p "$TEMP"
		fi
		continue
		;;

	"debug "*)
		export CPL_DEBUG=${src#debug }
		if [ -z "$CPL_DEBUG" ]; then
			unset CPL_DEBUG
		fi
		echo "DEBUG $CPL_DEBUG"
		ulimit -c unlimited
		continue
		;;

	"skipfailuresregex "*)
		export sfre=${src#skipfailuresregex }
		continue
		;;

	options|"options"*)
		opt=${src#options}
		opt=${opt# }
		if [ "$DRIVER" = OCI ]; then
			opt="$opt -relaxedFieldNameMatch"
		fi
		continue
		;;

	"execute "*)
		if [ -z "$DB" ]; then
			echo "$P: Keine Datenbankverbindungsdaten angegeben" >&2
			exit 1
		fi

		src=${src#execute }
		echo "EXECUTE $src $(bdate)"
		runsql "$src"
		continue
		;;

	"shell "*)
		eval "${src#shell }"
		continue
		;;

	log|"log "*)
		if [ "$src" = "log" ]; then
			src="${F%.*}-%Y-%m-%d-%H-%M.log"
		else
			src=${src#log }
		fi

		log=$(bdate +$src)

		echo "LOGGING TO $log $(bdate)"
		exec 3>&1 4>&2 > >(log $log) 2>&1

		echo "LOG $(bdate)"
		echo 'Import-Version: $Format:%h$'
		echo "GDAL-Version: $GDAL_VERSION"

		continue
		;;

	dump|"dump "*)
		if [ -z "$DB" ]; then
			echo "$P: Keine Datenbankverbindungsdaten angegeben" >&2
			exit 1
		fi

		if [ "$src" = "dump" ]; then
			src="alkis-%Y-%m-%d-%H-%M"
		else
			src=${src#dump }
		fi

		src=$(bdate +$src)

		echo "DUMPING $(bdate)"
		dump "$src"

		continue
		;;

	"restore "*)
		if [ -z "$DB" ]; then
			echo "$P: Keine Datenbankverbindungsdaten angegeben" >&2
			exit 1
		fi

		src=${src#restore }

		echo "RESTORING $(bdate)"
		restore "$src"
		continue
		;;

	exit|postprocess)
		break
		;;

	esac
done <"$F"

process

final

if [ "$src" = "error" ]; then
	echo "FEHLER BEIM IMPORT"
elif [ "$src" != "exit" ]; then
	pushd "$B" >/dev/null

	if (( preprocessed == 0 )); then
		if rund preprocessing; then
			preprocessed=1
		else
			echo "FEHLER BEIM PREPROCESSING"
			src=error
		fi
	fi

	if (( preprocessed != 0 )); then
		if ! rund postprocessing; then
			echo "FEHLER BEIM POSTPROCESSING"
			src=error
		fi
	fi

	popd >/dev/null
fi

echo "END $(bdate)"

if [ -n "$log" ]; then
	echo "LOG: $log"
fi

if [ "$src" == "error" ]; then
	trap "" EXIT
	echo "WARNUNG: VERZEICHNIS $tmpdir WIRD NACH FEHLER NICHT GELÖSCHT."
	exit 1
fi
