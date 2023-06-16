#!/usr/bin/env bash

set -e

GODOT_VER="4.0.4"

function _init() {
	local godot_version

	if ! command -v godot > /dev/null; then
		echo "error: command 'godot' not found" 1>&2
		exit 1
	elif ! godot_version=$(godot --version); then
		echo "error: command 'godot --version' failed" 1>&2
		exit 1
	elif [[ "${godot_version}" != ${GODOT_VER:?}* ]]; then
		echo "error: wrong Godot version '${godot_version}'. Required version: ${GODOT_VER:?}" 1>&2
		exit 1
	fi
	f=$(mktemp)
	trap 'rm $f' EXIT
	cd dmcetraceGUI || exit 1
}

function _export() {
	local err

	err=0
	echo "$1"
	for _ in 1 2; do
		godot --export-release "$1" --headless |& tee "$f"
		if ! grep -q -i "error" "$f"; then
			# no errors
			return 0
		fi

		err=$((err + 1))
		if [ $err -eq 2 ]; then
			echo "error: export '$1' failed two times in a row - check log" 1>&2
			return 1
		fi
	done
}

_init
_export "Linux"
_export "Windows"
du --time -hs dmce-gui*
