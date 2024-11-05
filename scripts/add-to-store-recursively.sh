#!/usr/bin/env bash

set -eu

cleanup() {
	if [[ -n "${stateDir:-}" ]]; then
		rm -f -- "$stateDir/o" "$stateDir/args"
		rmdir "$stateDir"
	fi
}
trap cleanup EXIT

die() {
	printf '%s\n' "$@" >&2
	exit 1
}
jqEscape() {
	if [[ "$1" =~ ^[a-zA-Z0-9/.-]+$ ]]; then
		printf '"%s"' "$1"
	else
		printf "%s" "$linkTarget" | jq -s -R .
	fi
}

if [[ 0 == "$#" ]]; then
	die "usage $0 <dir> [output name] [build name]"
fi

saveDir="${1:-}"
[[ -d "$saveDir" ]] || die "dir '$1' does not exist or is not a directory"
relOutName="${2:-out}"
outName="$(readlink -f "$relOutName")"
defaultBuildName="$(basename "$saveDir")"
buildName="${3:-$defaultBuildName}"

stateDir="$(mktemp -d)"

cd "$saveDir"
readarray -d "" links < <(find -type l -print0)
readarray -d "" linkTargets < <(printf '%s\0' "${links[@]}" | xargs -r -0 readlink -z --)
[[ "${#links[@]}" == "${#linkTargets[@]}" ]]

args="{"
for (( i=0; i < ${#links[@]}; i++ )); do
	link="${links[i]}"
	linkTarget="${linkTargets[i]}"
	[[ "$linkTarget" =~ /nix/store/.* ]] || continue
	args+=$'\n'"$(jqEscape "$link"): $(jqEscape "$linkTarget"),"
done
args="${args%,}"
args+=$'\n'"}"$'\n'

printf '%s' "$args" > "$stateDir/args"
nix-build --expr '
{ argsFile }:
	let
		pkgs = import <nixpkgs> {};
		lib = pkgs.lib;
		args = lib.importJSON (/. + argsFile);
		listArgs = lib.mapAttrsToList (n: v: "rm $out/${lib.escapeShellArg n}; ln -sf ${builtins.storePath v} $out/${lib.escapeShellArg n}") args;
	in pkgs.runCommandLocal
		"'"$buildName"'"
		{}
		"cp -r ${./.} $out; chmod -R u+w $out; ${builtins.concatStringsSep "\n" listArgs}"
' --argstr argsFile "$stateDir/args" --out-link "$stateDir/o"

storeName="$(readlink -f "$stateDir/o")"
if [[ -d "$outName" ]]; then
	outName+="/$(basename "$storeName")"
fi
nix-store --add-root "$outName" -r "$storeName" > /dev/null
