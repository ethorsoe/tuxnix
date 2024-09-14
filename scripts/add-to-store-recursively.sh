#!/usr/bin/env bash

set -eu

cleanup() {
	if [[ -n "${stateDir:-}" ]]; then
		rm -f -- "$stateDir/o"
		rmdir "$stateDir"
	fi
}
trap cleanup EXIT

die() {
	printf '%s\n' "$@" >&2
	exit 1
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
args=()
for i in "${links[@]}"; do
	linkTarget="$(readlink -f "$i")"
	[[ "$linkTarget" =~ /nix/store/.* ]] || continue
	args+=(--argstr "$i" "$linkTarget")
done

nix-build --expr '
{ ... }@args:
	let
		pkgs = import <nixpkgs> {};
		lib = pkgs.lib;
		listArgs = lib.mapAttrsToList (n: v: "rm $out/${lib.escapeShellArg n}; ln -sf ${builtins.storePath v} $out/${lib.escapeShellArg n}") args;
	in pkgs.runCommand
		"'"$buildName"'"
		{}
		"cp -r ${./.} $out; chmod -R u+w $out; ${builtins.concatStringsSep "\n" listArgs}"
' "${args[@]}" --out-link "$stateDir/o"

if [[ -d "$outName" ]]; then
	storeName="$(readlink -f "$stateDir/o")"
	outName+="/$(basename "$storeName")"
fi
nix-store --add-root "$outName" -r "$storeName" > /dev/null
