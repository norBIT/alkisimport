#!/bin/bash

set -e

# Felder als String interpretieren (führende Nullen nicht abschneiden)
export GML_FIELDTYPES=ALWAYS_STRING

# Warnen, wenn numerische Felder mit alphanumerischen Werten gefüllt werden sollen
export OGR_SETFIELD_NUMERIC_WARNING=ON

# Mindestlänge für Kreisbogensegmente
export OGR_ARC_MINLENGTH=0.1

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

export LC_CTYPE=de_DE.UTF-8

if [ -d "$PWD/gdal-dev" ]; then
	export PATH=$PWD/gdal-dev/bin:$PATH
	export GDAL_DATA=$PWD/gdal-dev/share/gdal
elif [ -d "$HOME/src/gdal/apps/.libs" ]; then
	export PATH=$HOME/src/gdal/apps/.libs:$PATH
	export LD_LIBRARY_PATH=$HOME/src/gdal/.libs
	export GDAL_DATA=/usr/share/gdal/1.9
fi

B=${0%/*}   # BASEDIR
if [ "$0" = "$B" ]; then
	B=.
fi
P=${0##*/}  # PROGNAME

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

export CPL_DEBUG

opt=
log=
gdb=

T0=

S1=0

while read src
do
	if ! [ -r "$src" ]; then
		continue
	fi

	case $src in
	*.zip)
		s=$(unzip -qql "$src" "${src%.zip}.xml"|sed -e "s/^ *//" -e "s/ .*$//")
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

echo "$P: Unkomprimierte Gesamtgröße: $(memunits $S1)"

while read src
do
	case $src in
	""|"#"*)
		# Leerzeilen und Kommentare ignorieren
		continue
		;;

	PG:*)
		DB=${src#PG:}
		continue
		;;

	create)
		if [ -z "$DB" ]; then
			echo "$P: Keine Datenbankverbindungsdaten angegeben" >&2
			exit 1
		fi

		echo "CREATE $(bdate)"
		pushd "$B" >/dev/null
		psql -q -f alkis-schema.sql "$DB"
		psql -q -f alkis-compat.sql "$DB"
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
		continue
		;;

	"execute "*)
		if [ -z "$DB" ]; then
			echo "$P: Keine Datenbankverbindungsdaten angegeben" >&2
			exit 1
		fi

		src=${src#execute }
		echo "EXECUTE $src $(bdate)"
		psql -q -c "$src" "$DB"
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
		exec 3>&1 4>&2 > >(tee $log) 2>&1

		continue
		;;

	dump|"dump "*)
		if [ -z "$DB" ]; then
			echo "$P: Keine Datenbankverbindungsdaten angegeben" >&2
			exit 1
		fi

		if [ "$src" = "dump" ]; then
			src="alkis-%Y-%m-%d-%H-%M.cpgdmp"
		else
			src=${src#dump }
		fi

		src=$(bdate +$src)

		echo "DUMPING $(bdate)"
		pg_dump -Fc -f "$src" "$DB"

		continue
		;;

	"restore "*)
		if [ -z "$DB" ]; then
			echo "$P: Keine Datenbankverbindungsdaten angegeben" >&2
			exit 1
		fi

		src=${src#restore }
		if ! [ -r "$src" ]; then
			echo "$P: $src nicht gefunden oder nicht lesbar." >&2
			exit 1
		fi

		echo "RESTORING $(bdate)"
		pg_restore -Fc -c "$src" | psql "$DB"
		continue
		;;

	exit)
		break
		;;

	*.zip)
		dst=/tmp/$(basename $src .zip).xml
		echo "DECOMPRESS $(bdate): $src"
		zcat "$src" >"$dst"
		rm=1
		;;

	*.xml.gz)
		if ! [ -r "$src" ]; then
			echo "$P: $src nicht gefunden oder nicht lesbar." >&2
			exit 1
		fi

		dst=/tmp/$(basename $src .gz)
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

	echo "IMPORT $(bdate): $dst"

	echo RUNNING: ogr2ogr -f PostgreSQL $opt -append -update "PG:$DB" -a_srs EPSG:25832 "$dst"
	t0=$(bdate +%s)
	if [ -z "$T0" ]; then T0=$t0; fi
	if [ -n "$GDB" ]; then
		gdb --args ogr2ogr -f PostgreSQL $opt -append -update "PG:$DB" -a_srs EPSG:25832 "$dst" </dev/tty >/dev/tty 2>&1
	else
		ogr2ogr -f PostgreSQL $opt -append -update "PG:$DB" -a_srs EPSG:25832 "$dst"
	fi
	t1=$(bdate +%s)

	s=$(stat -c %s "$dst")
	(( S += s ))

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

	for i in alkis-signaturen.sql alkis-ableitungsregeln.sql nas2alb.sql
	do
		if [ -r "$i" ]; then
			echo "SQL RUNNING: $i $(bdate)"
			psql -q -f $i "$DB"
		fi
	done

	popd >/dev/null
fi

echo "END $(bdate)"

if [ -n "$log" ]; then
	exec 1>&3 2>&4 3>/dev/null 4>/dev/null
	python "$B/refilter.py" $log
	echo "LOG: $log"
fi
