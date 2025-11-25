#!/usr/bin/env bash

set -eu

nixfiles=()
jsonfiles=()
fail=0
if (( 0 == $# )); then
	readarray -d "" nixfiles < <(find . -type f -iname '*.nix' -print0)
	readarray -d "" jsonfiles < <(find . -type f -iname '*.json' -print0)
	readarray -d "" shfiles < <(find . -type f -iname '*.sh' -print0)
fi
while (( $# )); do
	case "$1" in
		*.nix)
			nixfiles+=("$1")
			;;
		*.json)
			jsonfiles+=("$1")
			;;
		*.sh)
			shfiles+=("$1")
			;;	esac
	shift 1
done

checkGrepPattern() {
	local pattern="$1" errorType="$2"
	shift 2
	(( $# )) || return 1
	local matches="$(grep "$pattern" "$@" || true)"
	if [[ -n "$matches" ]]; then
		echo "$errorType:" >&2
		echo "$matches" >&2
		return 0
	fi
	return 1
}
checkLongLines() {
	checkGrepPattern '.\{101\}' "Long lines detected" "$@"
}
checkTabs() {
	checkGrepPattern $'\t' "Tabs detected" "$@"
}
checkTrailingSpace() {
	checkGrepPattern '[[:space:]]$' "Trailing space detected" "$@"
}
checkNixpkgsFmt() {
	(( $# )) || return 1
	local matches="$(nixpkgs-fmt --check "${nixfiles[@]}" |&
		grep -v '^0 /' 2>&1 || true)"
	if [[ -n "$matches" ]]; then
		echo "nixpkgs-fmt would reformat:" >&2
		echo "$matches" >&2
		printf '%s\n' "nixfmt failed:" "$matches"
		echo "try find . -name '*.nix' -exec nixpkgs-fmt '{}' +"
		return 0
	fi
	return 1
}
checkJSON() {
	local ret=1
	for file in "$@"; do
		if diff -u <(cat "$file") <(jq . "$file"); then continue; fi
		echo "${file@Q} not formatted with jq"
		echo 'try jq . "${file@Q}" > temp && mv temp "$file"'
		ret=0
	done
	return "$ret"
}

if checkTabs "${nixfiles[@]}"; then
	(( ++fail ))
fi
if checkLongLines "${nixfiles[@]}"; then
	(( ++fail ))
fi
if checkTrailingSpace "${nixfiles[@]}"; then
	(( ++fail ))
fi
if checkNixpkgsFmt "${nixfiles[@]}"; then
	(( ++fail ))
fi

if checkJSON "${jsonfiles[@]}"; then
	(( ++fail ))
fi

if checkTrailingSpace "${shfiles[@]}"; then
	(( ++fail ))
fi

if (( fail )); then
	echo "$fail failure categories detected."
	exit 1
fi
exit 0
