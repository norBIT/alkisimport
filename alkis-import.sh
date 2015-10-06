#!/bin/bash
################################################################################
#
# Project:  norGIS ALKIS Import
# Purpose:  Shellscript zum ALKIS-Import
# Author:   Jürgen E. Fischer <jef@norbit.de>
#
################################################################################
# Copyright (c) 2012-2014, Jürgen E. Fischer <jef@norbit.de>
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
################################################################################


set -e

# Felder als String interpretieren (führende Nullen nicht abschneiden)
export GML_FIELDTYPES=ALWAYS_STRING

# Warnen, wenn numerische Felder mit alphanumerischen Werten gefüllt werden sollen
export OGR_SETFIELD_NUMERIC_WARNING=ON

# Mindestlänge für Kreisbogensegmente
export OGR_ARC_MINLENGTH=0.1

# Verhindern, das der GML-Treiber übernimmt
export OGR_SKIP=GML,SEGY

# Headerkennungen die NAS-Daten identifizieren
export NAS_INDICATOR="NAS-Operationen.xsd;NAS-Operationen_optional.xsd;AAA-Fachschema.xsd;ASDKOM-NAS-Operationen_1_1_NRW.xsd"

export EPSG=25832
export CRS=EPSG:$EPSG
export FNBRUCH=true

bdate() {
	local t=$1
	if [ -z "$t" ]; then
		t="+%F %T"
	fi

	date "$t"
}

memunits() {
	local s=$1
	local u=" Bytes"

	if (( s > 10240 )); then (( s /= 1024 )); u="kiB"; fi
	if (( s > 10240 )); then (( s /= 1024 )); u="MiB"; fi
	if (( s > 10240 )); then (( s /= 1024 )); u="GiB"; fi

	echo "$s$u"
}

timeunits() {
	local t=$1
	local t1=$2

	if [ -n "$t1" ]; then t=$(( t1 - t )); fi

	s=$(( t % 60 ))
	m=$(( (t / 60) % 60 ))
	h=$(( (t / 60 / 60) % 24 ))
	d=$(( t / 60 / 60 / 24 ))

	local r=
	if (( d > 0 )); then r="$r${d}d"; fi
	if (( h > 0 )); then r="$r${h}h"; fi
	if (( m > 0 )); then r="$r${m}m"; fi
	if (( s > 0 )); then r="$r${s}s"; fi

	echo $r
}

log() {
	tee $1 | python $B/refilter.py
}

B=${0%/*}   # BASEDIR
if [ "$0" = "$B" ]; then
	B=.
fi
P=${0##*/}  # PROGNAME

export LC_CTYPE=de_DE.UTF-8
export TEMP=${TEMP:-/tmp}

F=$1
if [ -z "$F" ]; then
	echo "usage: $P file"
	exit 1
elif ! [ -r "$F" ]; then
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
ogr2ogr --utility_version

export CPL_DEBUG
export B

opt=
log=
gdb=

T0=

S1=0

case "$GDAL_VERSION" in
"GDAL 2."*)
	CONVERT_TO_LINEAR=" -nlt CONVERT_TO_LINEAR"
	opt="$opt$CONVERT_TO_LINEAR"
	;;
*)
	CONVERT_TO_LINEAR=""
	;;
esac

while read src
do
	if ! [ -r "$src" ]; then
		continue
	fi

	case "$src" in
	*.xml.zip)
		s=$(unzip -qql "$src" "$(basename "$src" .xml.zip).xml"|sed -e "s/^ *//" -e "s/ .*$//")
		;;

	*.zip)
		s=$(unzip -qql "$src" "$(basename "$src" .zip).xml"|sed -e "s/^ *//" -e "s/ .*$//")
		;;

	*.xml.gz)
		s=$(gzip -ql "$src" | tr -s " " | cut -d" " -f3)
		;;

	*.xml)
		s=$(stat -c %s "$src")
		;;

	*)
		echo "$P: Nicht unterstützte Datei $src" >&2
		continue
		;;
	esac

	(( S1 += s ))
done <$F

if (( S1 > 0 )); then
	echo "$P: Unkomprimierte Gesamtgröße: $(memunits $S1)"
fi

while read src
do
	case $src in
	""|"#"*)
		# Leerzeilen und Kommentare ignorieren
		continue
		;;

	PG:*)
		DST=$src
		DB=${src#PG:}
		DRIVER=PostgreSQL
		sql() {
			pushd "$B" >/dev/null
			psql -P pager=off -v alkis_fnbruch=$FNBRUCH -v alkis_epsg=$EPSG -q -f "$1" "$DB"
			popd >/dev/null
		}
		runsql() {
			psql -P pager=off -c "$1" "$DB"
		}
		dump() {
			pg_dump -Fc -f "$1.cpgdmp" "$DB"
		}
		restore() {
			if ! [ -r "$1.cpgdmp" ]; then
				echo "$P: $1.cpgdmp nicht gefunden oder nicht lesbar." >&2
				exit 1
			fi
			pg_restore -Fc -c "$1.cpgdmp" | psql "$DB"
		}
		export DB
		log() {
			n=$(psql -t -c "SELECT count(*) FROM information_schema.tables WHERE table_name='alkis_importlog'" "$DB")
			n=${n//[	 ]/}
			if [ $n -eq 0 ]; then
				psql -q -c "CREATE TABLE alkis_importlog(n SERIAL PRIMARY KEY, ts timestamp default now(), msg text)" "$DB"
			fi

			tee $1 |
			(
				IFS=
				exec 5> >(python $B/refilter.py >&3)
				while read m; do
					echo "$m" >&5
					m=${m//\'/\'\'}
					echo "INSERT INTO alkis_importlog(msg) VALUES (E'${m//\'/\'\'}');"
				done
				echo "\\q"
			) |
			psql -q "$DB"
		}
		continue
		;;

	OCI:*)
		DST=$src
		DB=${src#OCI:}
		user=${DB%%/*}
		DRIVER=OCI
		sql() {
			pushd "$B/oci" >/dev/null
			if [ -f "$1" ]; then
				sqlplus "$DB" @$1 $EPSG
			else
				echo "$1 not found"
				exit 1
			fi
			popd >/dev/null
		}
		runsql() {
			sqlplus "$DB" <<EOF
whenever sqlerror exit 1
$1;
commit;
quit;
EOF
		}
		dump() {
			exp "$DB" file=$1.dmp log=$1-export.log owner=$user statistics=none
		}
		restore() {
			if ! [ -r "$1.dmp" ]; then
				echo "$P: $1.dmp nicht gefunden oder nicht lesbar." >&2
				exit 1
			fi

			imp "$DB" file=$1.dmp log=$1-import.log fromuser=$user touser=$user
		}
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
		;;

	"epsg "*)
		EPSG=${src#epsg }

		case "$EPSG" in
		13146[67])
			export PROJ_LIB=$B CRS=+init=custom:$EPSG
			;;
		*)
			;;
		esac

		continue
		;;

	create)
		if [ -z "$DB" ]; then
			echo "$P: Keine Datenbankverbindungsdaten angegeben" >&2
			exit 1
		fi

		echo "CREATE $(bdate)"
		pushd "$B/$sql" >/dev/null
		sql alkis-schema.sql
		sql alkis-compat.sql
		sql alkis-po-tables.sql
		popd >/dev/null

		continue
		;;

	update)
		if [ -z "$DB" ]; then
			echo "$P: Keine Datenbankverbindungsdaten angegeben" >&2
			exit 1
		fi

		echo "UPDATE $(bdate)"
		pushd "$B/$sql" >/dev/null
		sql alkis-compat.sql
		sql alkis-update.sql
		popd >/dev/null

		continue
		;;

	"gdb")
		if [ -n "$log" ]; then
			echo "$P: gdb und log schließen sich aus" >&2
			exit 1
		fi

		GDB=ON
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

	options|"options"*)
		opt=${src#options}
		opt=${opt# }
		if [ "$DRIVER" = OCI ]; then
			opt="$opt -relaxedFieldNameMatch"
		fi
		opt="$opt$CONVERT_TO_LINEAR"
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
		if [ -n "$GDB" ]; then
			echo "$P: gdb und log schließen sich aus" >&2
			exit 1
		fi

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

	*.zip)
		dst="$TEMP/$(basename "$src" .zip).xml"
		echo "DECOMPRESS $(bdate): $src"
		zcat "$src" >"$dst"
		rm=1
		;;

	*.xml.gz)
		if ! [ -r "$src" ]; then
			echo "$P: $src nicht gefunden oder nicht lesbar." >&2
			exit 1
		fi

		dst="$TEMP/$(basename "$src" .gz)"
		echo "DECOMPRESS $(bdate): $src"
		zcat "$src" >"$dst"
		rm=1
		;;

	*.xml)
		if ! [ -r "$src" ]; then
			echo "$P: $src nicht gefunden oder nicht lesbar." >&2
			exit 1
		fi

		dst="$src"
		rm=0
		;;

	esac

	if [ -z "$DB" ]; then
		echo "$P: Keine Datenbankverbindungsdaten angegeben" >&2
		exit 1
	fi

	[ -f "${dst%.xml}.gfs" ] && rm -v "${dst%.xml}.gfs"

	if ! [ -r "$dst" ]; then
		echo "$src => $dst"
		exit 1
	fi

	trap "echo '$P: Fehler bei $src' >&2; src=error" EXIT

	s=$(stat -c %s "$dst")
#	if (( s == 623 || s == 712 )); then
#		echo "SKIP $(bdate): $dst zu kurz - übersprungen"
#		continue
#	fi

	(( S += s ))

	echo "IMPORT $(bdate): $dst $(memunits $s)"

	echo RUNNING: ogr2ogr -f $DRIVER $opt -append -update "$DST" -a_srs $CRS "$dst"
	t0=$(bdate +%s)
	if [ -z "$T0" ]; then T0=$t0; fi
	if [ -n "$GDB" ]; then
		gdb --args ogr2ogr -f $DRIVER $opt -append -update "$DST" -a_srs $CRS "$dst" </dev/tty >/dev/tty 2>&1
	else
		ogr2ogr -f $DRIVER $opt -append -update "$DST" -a_srs $CRS "$dst"
	fi
	t1=$(bdate +%s)

	elapsed=$(( t1 - T0 ))

	if (( elapsed > 0 )); then
		throughput=$(( S / elapsed ))

		if (( t0 < t1 )); then
			echo "TIME: $(memunits $s) in $(timeunits $t0 $t1) importiert ($(memunits $(( s / (t1-t0) )))/s; Gesamt:$(memunits $throughput)/s)."

			remaining_data=$(( S1-S ))
			remaining_time=$(( remaining_data * elapsed / S ))
			eta=$(( t1 + remaining_time ))

			echo "REMAINING: $(memunits $remaining_data) $(( remaining_data * 100 / S1 ))% $(timeunits $remaining_time) ETA:$(date --date="1970-01-01 $eta seconds UTC")"
		else
			echo "TIME: $(memunits $s) in 0,nichts (Gesamt $(memunits $(( S / elapsed )))/s)."
		fi
	else
		echo "TIME: $(memunits $s) in 0,nichts importiert."
	fi

	[ $rm == 1 ] && rm -v "$dst"
	trap "" EXIT
done <$F

if (( T0 < t1 )); then
	echo "FINAL: $(memunits $S) in $(timeunits $T0 $t1) ($(memunits $(( S / elapsed )))/s)"
fi

if [ "$src" != "exit" -a "$src" != "error" ]; then
	pushd "$B" >/dev/null

	for i in alkis-signaturen.sql alkis-ableitungsregeln.sql postprocessing.d/*.sql
	do
		if [ -r "$i" ]; then
			echo "SQL RUNNING: $i $(bdate)"
			sql $i
		fi
	done

	popd >/dev/null
fi

echo "END $(bdate)"

if [ -n "$log" ]; then
	echo "LOG: $log"
fi
