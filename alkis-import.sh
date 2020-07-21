#!/bin/bash
############################################################################
#
# Project:  norGIS ALKIS Import
# Purpose:  Shellscript zum ALKIS-Import
# Author:   Jürgen E. Fischer <jef@norbit.de>
#
############################################################################
# Copyright (c) 2012-2020, Jürgen E. Fischer <jef@norbit.de>
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

# Verhindern, das der GML-Treiber übernimmt
export OGR_SKIP=GML,SEGY

# Headerkennungen die NAS-Daten identifizieren
export NAS_INDICATOR="NAS-Operationen;AAA-Fachschema;aaa.xsd;aaa-suite;adv/gid/6.0"
export NAS_SKIP_CORRUPTED_FEATURES=YES
export LIST_ALL_TABLES=YES
export TABLES="aa_aktivitaet,aa_antrag,aa_antragsgebiet,aa_meilenstein,aa_projektsteuerung,aa_vorgang,ap_darstellung,ap_fpo,ap_kpo_3d,ap_lpo,ap_lto,ap_ppo,ap_pto,au_koerperobjekt_3d,au_mehrfachlinienobjekt_3d,au_punkthaufenobjekt_3d,au_trianguliertesoberflaechenobjekt_3d,au_umringobjekt_3d,ax_abgeleitetehoehenlinie,ax_abschlussflaeche3d,ax_abschnitt,ax_anderefestlegungnachstrassenrecht,ax_anderefestlegungnachwasserrecht,ax_anschrift,ax_ast,ax_aufnahmepunkt,ax_bahnstrecke,ax_bahnverkehr,ax_bahnverkehrsanlage,ax_baublock,ax_bauraumoderbodenordnungsrecht,ax_bauraumoderbodenordnungsrechtgrundbuch,ax_bauteil,ax_bauteil3d,ax_bauwerk3d,ax_bauwerkimgewaesserbereich,ax_bauwerkimverkehrsbereich,ax_bauwerkoderanlagefuerindustrieundgewerbe,ax_bauwerkoderanlagefuersportfreizeitunderholung,ax_benutzer,ax_benutzergruppemitzugriffskontrolle,ax_benutzergruppenba,ax_bergbaubetrieb,ax_besondereflurstuecksgrenze,ax_besonderegebaeudelinie,ax_besondererbauwerkspunkt,ax_besonderergebaeudepunkt,ax_besonderertopographischerpunkt,ax_bewertung,ax_bodenflaeche3d,ax_bodenschaetzung,ax_boeschungkliff,ax_boeschungsflaeche,ax_buchungsblatt,ax_buchungsblattbezirk,ax_buchungsstelle,ax_bundesland,ax_dachflaeche3d,ax_dammwalldeich,ax_denkmalschutzrecht,ax_dhmgitter,ax_dienststelle,ax_duene,ax_einrichtungenfuerdenschiffsverkehr,ax_einrichtunginoeffentlichenbereichen,ax_einschnitt,ax_fahrbahnachse,ax_fahrwegachse,ax_felsenfelsblockfelsnadel,ax_fenster3d,ax_firstlinie,ax_flaeche3d,ax_flaechebesondererfunktionalerpraegung,ax_flaechegemischternutzung,ax_fliessgewaesser,ax_flugverkehr,ax_flugverkehrsanlage,ax_flurstueck,ax_flurstueckgrundbuch,ax_forstrecht,ax_fortfuehrungsfall,ax_fortfuehrungsfallgrundbuch,ax_fortfuehrungsnachweisdeckblatt,ax_friedhof,ax_gebaeude,ax_gebaeudeausgestaltung,ax_gebaeudeinstallation3d,ax_gebiet_bundesland,ax_gebiet_kreis,ax_gebiet_nationalstaat,ax_gebiet_regierungsbezirk,ax_gebiet_verwaltungsgemeinschaft,ax_gebietsgrenze,ax_gehoelz,ax_gemarkung,ax_gemarkungsteilflur,ax_gemeinde,ax_gemeindeteil,ax_georeferenziertegebaeudeadresse,ax_gewaesserachse,ax_gewaessermerkmal,ax_gewaesserstationierungsachse,ax_gewann,ax_gleis,ax_grablochderbodenschaetzung,ax_grenzpunkt,ax_grenzuebergang,ax_hafen,ax_hafenbecken,ax_halde,ax_heide,ax_heilquellegasquelle,ax_historischesbauwerkoderhistorischeeinrichtung,ax_historischesflurstueck,ax_historischesflurstueckalb,ax_historischesflurstueckohneraumbezug,ax_hoehenfestpunkt,ax_hoehenlinie,ax_hoehleneingang,ax_industrieundgewerbeflaeche,ax_insel,ax_kanal,ax_klassifizierungnachstrassenrecht,ax_klassifizierungnachwasserrecht,ax_kleinraeumigerlandschaftsteil,ax_kommunalesgebiet,ax_kommunalesteilgebiet,ax_kondominium,ax_kreisregion,ax_lagebezeichnungkatalogeintrag,ax_lagebezeichnungmithausnummer,ax_lagebezeichnungmitpseudonummer,ax_lagebezeichnungohnehausnummer,ax_lagefestpunkt,ax_landschaft,ax_landwirtschaft,ax_leitung,ax_material3d,ax_meer,ax_moor,ax_musterundvergleichsstueck,ax_namensnummer,ax_nationalstaat,ax_naturumweltoderbodenschutzrecht,ax_netzknoten,ax_nullpunkt,ax_ortslage,ax_person,ax_personengruppe,ax_platz,ax_polder,ax_punkt3d,ax_punktkennunguntergegangen,ax_punktkennungvergleichend,ax_punktortag,ax_punktortau,ax_punktortta,ax_punktwolke3d,ax_referenzstationspunkt,ax_regierungsbezirk,ax_reservierung,ax_schifffahrtsliniefaehrverkehr,ax_schiffsverkehr,ax_schleuse,ax_schutzgebietnachnaturumweltoderbodenschutzrecht,ax_schutzgebietnachwasserrecht,ax_schutzzone,ax_schwere,ax_schwerefestpunkt,ax_seilbahnschwebebahn,ax_sicherungspunkt,ax_sickerstrecke,ax_siedlungsflaeche,ax_skizze,ax_soll,ax_sonstigervermessungspunkt,ax_sonstigesbauwerkodersonstigeeinrichtung,ax_sonstigesrecht,ax_sportfreizeitunderholungsflaeche,ax_stehendesgewaesser,ax_strasse,ax_strassenachse,ax_strassenverkehr,ax_strassenverkehrsanlage,ax_strukturlinie3d,ax_sumpf,ax_tagebaugrubesteinbruch,ax_tagesabschnitt,ax_testgelaende,ax_textur3d,ax_topographischelinie,ax_transportanlage,ax_tuer3d,ax_turm,ax_unlandvegetationsloseflaeche,ax_untergeordnetesgewaesser,ax_vegetationsmerkmal,ax_verband,ax_vertretung,ax_verwaltung,ax_verwaltungsgemeinschaft,ax_vorratsbehaelterspeicherbauwerk,ax_wald,ax_wandflaeche3d,ax_wasserlauf,ax_wasserspiegelhoehe,ax_weg,ax_wegpfadsteig,ax_wirtschaftlicheeinheit,ax_wohnbauflaeche,ax_wohnplatz,ks_bauraumoderbodenordnungsrecht,ks_bauwerkanlagenfuerverundentsorgung,ks_bauwerkimgewaesserbereich,ks_bauwerkoderanlagefuerindustrieundgewerbe,ks_einrichtungenundanlageninoeffentlichenbereichen,ks_einrichtungimbahnverkehr,ks_einrichtungimstrassenverkehr,ks_einrichtunginoeffentlichenbereichen,ks_kommunalerbesitz,ks_sonstigesbauwerk,ks_sonstigesbauwerkodersonstigeeinrichtung,ks_strassenverkehrsanlage,ks_topographischeauspraegung,ks_vegetationsmerkmal,ks_verkehrszeichen,lb_binnengewaesser,lb_eis,lb_festgestein,lb_hochbauundbaulichenebenflaeche,lb_holzigevegetation,lb_krautigevegetation,lb_lockermaterial,lb_meer,lb_tiefbau,ln_abbau,ln_aquakulturundfischereiwirtschaft,ln_bahnverkehr,ln_bestattung,ln_flugverkehr,ln_forstwirtschaft,ln_freiluftundnaherholung,ln_freizeitanlage,ln_gewerblichedienstleistungen,ln_industrieundverarbeitendesgewerbe,ln_kulturundunterhaltung,ln_lagerung,ln_landwirtschaft,ln_oeffentlicheeinrichtungen,ln_ohnenutzung,ln_schiffsverkehr,ln_schutzanlage,ln_sportanlage,ln_strassenundwegeverkehr,ln_versorgungundentsorgung,ln_wasserwirtschaft,ln_wohnnutzung"

export PGCLIENTENCODING=UTF8

export EPSG=25832
export CRS="-a_srs EPSG:$EPSG"
export FNBRUCH=true
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

	OCI:*)
		DST=$src
		DB=${src#OCI:}
		user=${DB%%/*}
		DRIVER=OCI
		sql() {
			local r
			pushd "$B/oci" >/dev/null
			if [ -f "$1" ]; then
				sqlplus "$DB" @$1 $EPSG
				r=$?
			else
				echo "$1 not found"
				return 1
			fi
			popd >/dev/null
			return $?
		}
		export -f sql
		runsql() {
			sqlplus "$DB" <<EOF
whenever sqlerror exit 1
$1;
commit;
quit;
EOF
		}
		export -f runsql
		dump() {
			exp "$DB" file=$1.dmp log=$1-export.log owner=$user statistics=none
		}
		restore() {
			if ! [ -f "$1.dmp" -a -r "$1.dmp" ]; then
				echo "$P: $1.dmp nicht gefunden oder nicht lesbar." >&2
				return 1
			fi

			imp "$DB" file=$1.dmp log=$1-import.log fromuser=$user touser=$user
		}
		continue
		;;

	"pgschema "*)
		PGSCHEMA=${src#pgschema }
		DST="${DST/ active_schema=*/} active_schema=$SCHEMA','$PGSCHEMA"
		continue
		;;

	"schema "*)
		SCHEMA=${src#schema }
		DST="${DST/ active_schema=*/} active_schema=$SCHEMA','$PGSCHEMA"
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
		rund preupdate
		sql alkis-update.sql
		rund postupdate
		popd >/dev/null

		continue
		;;

	"temp "*)
		TEMP=${src#temp }
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
