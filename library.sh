#!/bin/sh

set -e

VDIR="/usr/lib/debtarget/versions"

download_versions() {
	db_progress START 0 110 debtarget-chooser/downloading
	wget -q --show-progress --progress=dot -O "/tmp/versions.tar.gz" "https://github.com/Debianissimo/debtarget-chooser/releases/latest/download/versions.tar.gz" 2>&1 | while read line; do
		percent=$(echo "$line" | awk '{print $7}')
		#speed=$(echo "$line" | awk '{print $8}')
		case "$percent" in
			*%)
				db_progress SET "$(echo $percent | sed 's/%//')" || true
			;;
		esac
	done || return 1
	mv "$VDIR" "$VDIR.bak"
	mkdir "$VDIR"
	tar -C "$VDIR" -xzf /tmp/versions.tar.gz
	db_progress SET 110
	db_progress STOP
}

get_working_versions() {
	local vlen
	local myarch
	VERSIONS=""
	vlen=0
	myarch="$(udpkg --print-architecture)"
	for f in $(ls $VDIR); do
		dir="$VDIR/$f"
		if [ ! -d "$dir" ]; then
			continue
		fi
		if [ "$(cat $dir/arch)" != "$myarch" ]; then
			continue
		fi
		if [ -z "$VERSIONS" ]; then
			VERSIONS="$f"
		else
			if [ "$1" ]; then
				VERSIONS="$VERSIONS,$f"
			else
				VERSIONS="$VERSIONS $f"
			fi
		fi
		vlen=$(( vlen + 1 ))
	done
	return $vlen
}

get_versions_descriptions() {
	local versions
	local dir
	local vn
	local desc
	VERSION_DESCS=""
	for v in "$@"; do
		dir="$VDIR/$v"
		if [ ! -d "$dir" ]; then
			continue
		fi
		vn="$(cat $dir/ver_no)"
		desc="Ordissimo v$vn ($v)"
		if [ -z "$VERSION_DESCS" ]; then
			VERSION_DESCS="$desc"
		else
			VERSION_DESCS="$VERSION_DESCS,$desc"
		fi
	done
}

get_model_name() {
	local ver
	local path
	local data
	local INFO
	local model
	ver="$1"
	model="$2"
	path="$VDIR/$ver"
	if [ ! -d "$path" ]; then
		return 2
	fi
	path="$path/$model"
	if [ ! -f "$path" ]; then
		return 1
	fi

	BRAND=""
	MODEL="Unknown"
	ADDIT="$model)"
	data="$(cat $path)"
	eval "$data"
	if [ ! -z "$INFO" ]; then
		ADDIT="$INFO, $ADDIT"
	fi
	ADDIT="($ADDIT"
	if [ ! -z "$BRAND" ]; then
		BRAND="$BRAND "
	fi

	echo -n "$BRAND$MODEL $ADDIT" | sed 's/\,/\\,/g'
}

get_all_models() {
	local ver
	local dir
	local file
	local path
	ver="$1"
	dir="$VDIR/$ver"
	NAMES=""
	MODELS=""
	for file in $(ls "$dir"); do
		if [ "$file" = "ver_no" ]; then continue; fi
		if [ "$file" = "arch" ]; then continue; fi

		path="$dir/$file"
		name="$(get_model_name $ver $file)"
		if [ -z "$NAMES" ]; then
			MODELS="$file"
			NAMES="$name"
		else
			MODELS="$MODELS,$file"
			NAMES="$NAMES,$name"
		fi
	done
}
