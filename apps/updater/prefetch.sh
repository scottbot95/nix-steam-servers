#!/usr/bin/env bash

# Mostly copied from https://github.com/nix-community/steam-fetcher/blob/2033f99c7aee506f5af18026a3cab1c93bd0439f/fetch-steam/builder.sh

set -e

# Redirect all stdout to stderr, but save reference to original stdout
exec 3>&1 >&2

# Enable new nix features
export NIX_CONFIG="experimental-features = nix-command"

downloadDir=$(mktemp -d /tmp/steam-dl.XXXXX)

args=(
	-app "${appId:?}"
	-depot "${depotId:?}"
	-manifest "${manifestId:?}"
)

if [ -n "$branch" ]; then
	args+=(-beta "$branch")
fi

if [ -n "$debug" ]; then
	args+=(-debug)
fi

echo "DepotDownloader ${args[*]} -dir ${downloadDir}"
DepotDownloader \
	"${args[@]}" \
	-dir "${downloadDir}"

if [ -n "$addToStore" ]; then
    echo "Adding depot to store"
    nix store add-path --name "${name:?}" "${downloadDir}"
fi

nix hash path "${downloadDir}" >&3

rm -rf "${downloadDir}"