#!/bin/bash
############################################################################
#
# Project:  norGIS ALKIS Import
# Purpose:  Shellscript zum ALKIS-Import
# Author:   Jürgen E. Fischer <jef@norbit.de>
#
############################################################################
# Copyright (c) 2012-2023, Jürgen E. Fischer <jef@norbit.de>
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
set -o noclobber

# Felder als String interpretieren (führende Nullen nicht abschneiden)
export GML_FIELDTYPES=ALWAYS_STRING

# Warnen, wenn numerische Felder mit alphanumerischen Werten gefüllt werden sollen
export OGR_SETFIELD_NUMERIC_WARNING=ON

# Mindestlänge für Kreisbogensegmente
export OGR_ARC_MINLENGTH=0.1

# ogc_fid bei Einfügungen nicht abfragen
export OGR_PG_RETRIEVE_FID=NO

# Headerkennungen die NAS-Daten identifizieren
export NAS_INDICATOR="NAS-Operationen;AAA-Fachschema;aaa.xsd;aaa-suite;adv/gid/7.1"
export NAS_SKIP_CORRUPTED_FEATURES=YES
export LIST_ALL_TABLES=YES

export PGCLIENTENCODING=UTF8

export EPSG=25832
export CRS="-a_srs EPSG:$EPSG"
export FNBRUCH=true
export AVOIDDUPES=false
export HISTORIE=true
export QUITTIERUNG=false
export PGVERDRAENGEN=false
export SCHEMA=public
export PARENTSCHEMA=
export PGSCHEMA=public
export USECOPY=YES

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
export TABLES=$(<$B/tables.lst)

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
	python3 $B/refilter.py | tee $1
	unlock
}
export -f log

lock() {
	exec 99>$lock
	flock 99
}
export -f lock

unlock() {
	exec 99>&-
}
export -f unlock

rund() {
	local dir=$1

	if [ -d "$dir.d" ]; then
		for i in $(ls -1d ${dir}.d/* 2>|/dev/null | sort); do
			if [ -d "$i" ]; then
				ls -1 $i/*.sql 2>|/dev/null | sort | parallel --line-buffer --halt soon,fail=1 --jobs=$JOBS sql
			elif [[ -f "$i" && -r "$i" && "$i" =~ \.sql$ ]]; then
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

	case "${src,,}" in
	*.zip)
		dst=${src%.???}.xml
		dst="$tmpdir/${dst//\//_}"
		echo "DECOMPRESS $(bdate): $src"
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

		dst=${src%.??}
		dst="$tmpdir/${dst//\//_}"
		echo "DECOMPRESS $(bdate): $src"
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

	[ -f "${dst%.???}.gfs" ] && rm -v "${dst%.???}.gfs"

	if ! [ -f "$dst" -a -r "$dst" ]; then
		echo "$src => $dst"
		return 1
	fi

	trap "echo '$P: Fehler bei $src' >&2; src=error" EXIT

	s=$(stat -c %s "$dst")

	echo "IMPORT $(bdate): $dst $(memunits $s)"

	if [ -n "$sfre" ] && eval [[ "$src" =~ "$sfre" ]]; then
		echo "WARNING: Importfehler werden ignoriert"
		opt="$opt -skipfailures"
	fi
	opt="$opt -ds_transaction --config PG_USE_COPY $USECOPY -nlt CONVERT_TO_LINEAR"

	case "$MACHTYPE" in
	*-cygwin|*msys)
		dst1=$(cygpath -m "$dst")
		;;
	*)
		dst1=$dst
		;;
	esac

	if ffdate=$(python3 $B/ffdate.py "$dst1"); then
		opt="$opt -doo \"PRELUDE_STATEMENTS=CREATE TEMPORARY TABLE deletedate AS SELECT '$ffdate'::character(20) AS endet\""
	elif (( $? == 2 )); then
		:
	else
		echo "Konnte Portionsdatum nicht bestimmen"
		return 1
	fi

	echo "RUNNING: ogr2ogr -f $DRIVER $opt $sf_opt -update -append \"$DST\" $CRS \"$dst1\"" | sed -Ee 's/password=\S+/password=*removed*/'
	eval ogr2ogr -f $DRIVER $opt $sf_opt -update -append \"$DST\" $CRS \"$dst1\"
	local r=$?
	t1=$(bdate +%s)

	progress "$dst" "$dst1" $s $t0 $t1 $r

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
			pushd "$B" >|/dev/null
			preprocessed=1
			rund preprocessing
			r=$?
			popd >|/dev/null
			if [ "$r" -ne 0 ]; then
				return $r
			fi

			if [ "$QUITTIERUNG" = "true" ]; then
				n=$(psql -X -t -c "SELECT count(*) FROM pg_catalog.pg_sequences WHERE schemaname='${SCHEMA//\'/\'\'}' AND sequencename='alkis_quittierungen_seq'" "$DB")
				n=${n//[	 ]}
				if [ $n -eq 0 ]; then
					runsql "CREATE SEQUENCE $SCHEMA.alkis_quittierungen_seq"
				fi

				quittierungsnr=$(psql -A -X -t -c "SELECT nextval('$SCHEMA.alkis_quittierungen_seq')" "$DB")
				quittierungsnr=${quittierungsnr//[	 ]}
				export quittierungsnr
				export quittierungsi=0
			fi
		fi

		export job
		export progress
		parallel --tag --line-buffer --halt soon,fail=1 --jobs=$JOBS import <$job
		r=$?
		rm $job
	fi
	return $r
}

progress() {
	local file=$1
	local dst=$2
	local size=$3
	local t0=$4
	local t1=$5
	local r=$6
	local elapsed
	local total_elapsed
	local total_size
	local remaining_size
	local errors=0

	lock
	[ -f $progress ] && . $progress

	start_time=${start_time:-$t0}
	elapsed=$(( t1 - t0 ))
	total_elapsed=$(( t1 - start_time ))
	(( remaining_size -= size ))
	done_size=$(( total_size - remaining_size ))
	remaining_time=$(( remaining_size * total_elapsed / done_size ))
	eta=$(( t1 + remaining_time ))

	if [ -n "$quittierungsnr" ]; then
		if [ $r == 0 ]; then
			success=true
		else
			success=false
		fi
		python3 $B/quittierung.py . "$dst" "$(printf "ID_%08d" $quittierungsi)" $quittierungsnr $success
		(( ++quittierungsi ))
	fi


	if [ $r -ne 0 ]; then
		(( errors++ )) || true
		echo "ERROR: Ergebnis $r bei $file (bislang $errors Fehler)"
	fi

	if (( elapsed > 0 )); then
		throughput=$(( size / elapsed ))
		total_throughput=$(( done_size / total_elapsed ))

		if (( t0 < t1 )); then
			echo "TIME: $file mit $(memunits $size) in $(timeunits $t0 $t1) importiert ($(memunits $throughput)/s; Gesamt:$(memunits $total_throughput)/s)."
			echo "REMAINING: $(memunits $remaining_size) $(( remaining_size * 100 / total_size ))% $(timeunits $remaining_time) ETA:$(date --date="@$eta")"
		else
			echo "TIME: $file mit $(memunits $size) in 0,nichts (Gesamt $(memunits $total_throughput)/s)."
		fi
	else
		echo "TIME: $file mit $(memunits $size) in 0,nichts importiert."
	fi

	cat <<EOF >|$progress
start_time=$start_time
total_size=$total_size
remaining_size=$remaining_size
last_time=$t1
errors=$errors
quittierungsnr=$quittierungsnr
quittierungsi=$quittierungsi
EOF

	unlock
}
export -f progress

final() {
	lock
	start_time=0
	last_time=0
	! [ -f $progress ] || . $progress
	total_elapsed=$(( last_time - start_time ))
	if (( total_elapsed > 0 )); then
		echo "FINAL: $(memunits $total_size) in $(timeunits $start_time $last_time) ($(memunits $(( total_size / total_elapsed )))/s)"
	fi
	rm -f $progress
	unlock
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
if [ $major -lt 3 ] || [ $major -eq 3 -a $minor -lt 8 ]; then
	echo "$P: erfordert GDAL >=3.8" >&2
	exit 1
fi

# Verhindern, dass der GML-Treiber übernimmt
export OGR_SKIP=GML

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
	case "${src,,}" in
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

				case "${file,,}" in
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
					continue
					;;

				esac

				(( S += s )) || true
			done <"$F"

			cat <<EOF >|$progress
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
			pushd "$B" >|/dev/null
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
			popd >|/dev/null
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
			pg_dump -Fc -f "$1.backup" -n "$SCHEMA" "$DB"
		}
		restore() {
			if ! [ -f "$1.backup" -a -r "$1.backup" ]; then
				echo "$P: $1.backup nicht gefunden oder nicht lesbar." >&2
				return 1
			fi
			pg_restore -Fc --if-exists -c -d "$DB" "$1.backup"
		}
		export DB
		log() {
			export SCHEMAL="'${SCHEMA//\'/\'\'}'"
			export SCHEMAI="\"${SCHEMA//\"/\"\"}\""
			n=$(psql -X -t -c "SELECT count(*) FROM pg_catalog.pg_namespace WHERE nspname=$SCHEMAL" "$DB")
			n=${n//[	 ]}
			if [ $n -eq 0 ]; then
				psql -X -q -c "CREATE SCHEMA $SCHEMAI" "$DB"
			fi

			n=$(psql -X -t -c "SELECT count(*) FROM pg_catalog.pg_namespace WHERE nspname=$SCHEMAL" "$DB")
			n=${n//[	 ]}
			if [ $n -eq 0 ]; then
				echo "Schema $SCHEMA nicht erzeugt" >&2
				exit 1
			fi

			n=$(psql -X -t -c "SELECT count(*) FROM pg_catalog.pg_tables WHERE schemaname=$SCHEMAL AND tablename='alkis_importlog'" "$DB")
			n=${n//[	 ]}
			if [ $n -eq 0 ]; then
				psql -X -q -c "CREATE TABLE $SCHEMAI.alkis_importlog(n SERIAL PRIMARY KEY, ts timestamp default now(), msg text)" "$DB"
			fi

			unlock

			local log=$1
			export log
			(
				IFS=
				exec 5> >(python3 $B/refilter.py | tee $log >&3)
				while read m; do
					echo "$m" >&5
					m=${m//\'/\'\'}
					echo "INSERT INTO $SCHEMAI.alkis_importlog(msg) VALUES (E'${m//\'/\'\'}');"
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

	"quittierung "*)
		QUITTIERUNG=${src#quittierung }
		case "$QUITTIERUNG" in
		an|on|true|an)
			QUITTIERUNG=true
			;;
		aus|off|false)
			QUITTIERUNG=false
			;;
		*)
			echo "$P: Ungültiger Wert $QUITTIERUNG (true oder false erwartet)"
			exit 1
			;;
		esac
		continue
		;;


	"historie "*)
		HISTORIE=${src#historie }
		case "${HISTORIE,,}" in
		an|on|true|an)
			HISTORIE=true
			;;
		aus|off|false)
			HISTORIE=false
			;;
		*)
			echo "$P: Ungültiger Wert $HISTORIE (true oder false erwartet)"
			exit 1
			;;
		esac

		continue
		;;

	"avoiddupes "*)
		AVOIDDUPES=${src#avoiddupes }
		case "${AVOIDDUPES,,}" in
		an|on|true|an)
			AVOIDDUPES=true
			;;
		aus|off|false)
			AVOIDDUPES=false
			;;
		*)
			echo "$P: Ungültiger Wert $AVOIDDUPES (true oder false erwartet)"
			exit 1
			;;
		esac

		continue
		;;

	"usecopy "*)
		USECOPY=${src#usecopy }
		case "${USECOPY,,}" in
		an|on|true|an)
			USECOPY=ON
			;;
		aus|off|false)
			USECOPY=OFF
			;;
		*)
			echo "$P: Ungültiger Wert $USECOPY (true oder false erwartet)"
			exit 1
			;;
		esac

		continue
		;;

	"fnbruch "*)
		FNBRUCH=${src#fnbruch }
		case "${FNBRUCH,,}" in
		an|on|true|an)
			FNBRUCH=true
			;;
		aus|off|false)
			FNBRUCH=false
			;;
		*)
			echo "$P: Ungültiger Wert $FNBRUCH (true oder false erwartet)"
			exit 1
			;;
		esac

		continue
		;;

	"pgverdraengen "*)
		PGVERDRAENGEN=${src#pgverdraengen }
		case "${PGVERDRAENGEN,,}" in
		an|on|true|an)
			PGVERDRAENGEN=true
			;;
		aus|off|false)
			PGVERDRAENGEN=false
			;;
		*)
			echo "$P: Ungültiger Wert $PGVERDRAENGEN (true oder false erwartet)"
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
				export CRS="-a_srs $B/$EPSG.prj"
				;;
			13068)
				export CRS="-ct '+proj=pipeline +step +inv +proj=utm +zone=33 +ellps=GRS80 +step +inv +proj=hgridshift +grids=ntv2berlin20130508.GSB +step +proj=cass +lat_0=52.4186482777778 +lon_0=13.6272036666667 +x_0=40000 +y_0=10000 +ellps=bessel +step +proj=axisswap +order=2' -a_srs EPSG:3068"
				;;
			3146[678])
				export CRS="-s_srs $B/1$EPSG.prj -t_srs EPSG:$EPSG"
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
		pushd "$B" >|/dev/null
		rund preinherit
		sql alkis-inherit.sql
		rund postinherit
		popd >|/dev/null

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
		pushd "$B" >|/dev/null
		rund prepare
		rund precreate
		sql alkis-init.sql
		rund postcreate
		popd >|/dev/null

		continue
		;;

	clean)
		if [ -z "$DB" ]; then
			echo "$P: Keine Datenbankverbindungsdaten angegeben" >&2
			exit 1
		fi

		echo "CLEAN $(bdate)"
		pushd "$B" >|/dev/null
		rund prepare
		rund preclean
		sql alkis-clean.sql
		rund postclean
		popd >|/dev/null

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
		pushd "$B" >|/dev/null
		rund prepare
		rund preupdate
		sql alkis-update.sql
		rund postupdate
		popd >|/dev/null

		continue
		;;

	"temp "*)
		TEMP=${src#temp }
		tmpdir=$TEMP
		if ! [ -d "$TEMP" ]
		then
			mkdir -p "$TEMP"
		else
			rm -f $TEMP/*
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
		lock
		exec 3>&1 4>&2 > >(log $log) 2>&1
		lock
		unlock

		echo "LOG $(bdate)"
		if ! [ -e "$B/.git" ]; then
			echo 'Import-Version: $Format:%h$'
		else
			if type -p git >/dev/null; then
				git log -1 --pretty='Import-Version: %h'
			else
				echo 'Import-Version: unbekannt'
			fi
		fi
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
	pushd "$B" >|/dev/null

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

	popd >|/dev/null
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

echo
