#!/usr/bin/env bash
# Keeps biome.json's $schema pinned to the installed @biomejs/biome version.
#
# Why: Renovate bumps the @biomejs/biome devDependency and rewrites pnpm-lock.yaml,
# but biome.json still points at the previous schema URL. `pnpm check` then prints
# "The configuration schema version does not match the CLI version" on every CI run,
# and future keys get validated against a stale schema.
#
# Intended for Renovate branches: run it after `pnpm install` on the PR branch so the
# schema bump lands in the same commit as the dependency bump. Safe to run by hand:
#   bash scripts/renovate-sync-biome-schema.sh
set -euo pipefail

config="${1:-biome.json}"
[ -f "$config" ] || {
	echo "renovate-sync-biome-schema: $config not found" >&2
	exit 1
}

version="$(node -p "require('./node_modules/@biomejs/biome/package.json').version")"
schema="https://biomejs.dev/schemas/${version}/schema.json"

current="$(grep -o 'https://biomejs.dev/schemas/[^"]*/schema.json' "$config" | head -1 || true)"
if [ "$current" = "$schema" ]; then
	echo "renovate-sync-biome-schema: $config already pinned to ${version}"
	exit 0
fi

# Only the $schema line is touched; everything else in biome.json stays byte-identical.
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
sed -e "s#https://biomejs.dev/schemas/[^\"]*/schema.json#${schema}#" "$config" >"$tmp"
mv "$tmp" "$config"
trap - EXIT

echo "renovate-sync-biome-schema: $config -> ${schema}"
