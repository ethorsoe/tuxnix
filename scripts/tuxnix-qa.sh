#!/usr/bin/env bash

set -eu

nixfiles="$(find . -iname '*.nix')"
fail=""
newFail=""
knownFail="some text needed here to avoid match"

for i in $nixfiles; do
	if grep $'\t' $i; then
		echo "$i has tabs"
		fail+=" tabs_${i}"
	fi
	if egrep '.{101}' $i | grep -v 0; then
		echo "$i has long lines"
		fail+=" long_lines_${i}"
	fi
	if egrep ' $' $i | grep -v 0; then
		echo "$i has trailing spaces"
		fail+=" trailing_space_${i}"
	fi
done

for i in $fail; do
	if ! echo "$i" | egrep -q "$knownFail"; then
		newFail+=" $i"
	fi
done
if [ "" != "$newFail" ]; then
	echo $'\n'"New failures: $newFail"
	exit 1
fi

nixfmtOut="$(find . -name '*.nix' -exec nixpkgs-fmt --check '{}' + |& grep -v '^0 /' 2>&1)" || true
if [[ -n "$nixfmtOut" ]]; then
	printf '%s\n' "nixfmt failed:" "$nixfmtOut"
	echo "try find . -name '*.nix' -exec nixpkgs-fmt '{}' +"
	exit 1
fi
exit 0
