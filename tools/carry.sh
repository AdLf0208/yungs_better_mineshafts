#!/usr/bin/env bash
# Reproduce the carried content from the ATM10 1.21.1 jar, at the campaign pin.
#
# 1. verify/fetch the jar by its SHA-1 (the pack's own `modrinthHash`);
# 2. `horizon-port-pack carry` with the pin's tool into a scratch work tree;
# 3. copy the carried folder into the package root (`assets/`, `data/`) and restore
#    the two fields the carry drops for this jar (`tools/restore_jar_fields.py`);
#    the carried folder's own copy is kept under `content/` as carry evidence.
#
# The carry tool is built from the pin once and kept outside the port:
#   cargo build --locked -p horizon-port-pack   (in a build slot)
# Point CARRY at the binary (default: the mvs work tree's copy, same pin).
#
#   ports/tools/build-slot.sh run --job bms-carry --port ports/bettermineshafts \
#       --step stage -- env CARRY=<path>/horizon-port-pack bash tools/carry.sh
set -euo pipefail

PORT=$(cd "$(dirname "$0")/.." && pwd)
CAMPAIGN=$(cd "$PORT/../.." && pwd)
JAR_NAME=YungsBetterMineshafts-1.21.1-NeoForge-5.1.1.jar
JAR_SHA1=6a14e1d8201f068ca87ef8333e471c5378955906
JAR_URL=https://cdn.modrinth.com/data/HjmxVlSr/versions/Go3nbneL/YungsBetterMineshafts-1.21.1-NeoForge-5.1.1.jar
CACHE=$CAMPAIGN/ports/_shared/licence-cache
JAR=$CACHE/$JAR_NAME
CARRY=${CARRY:-$CAMPAIGN/ports/_shared/carry-work/mvs/bin/horizon-port-pack}
RES=${RES:-${HORIZON_RES:-/home/adlf/Desktop/horizon/.local/horizon-client/26.3}}
WORK=${WORK:-/tmp/opencode/bettermineshafts-carry}

[ -x "$CARRY" ] || { echo "missing horizon-port-pack: $CARRY" >&2; exit 1; }

if [ ! -f "$JAR" ]; then
    echo "fetching $JAR_NAME"
    curl -sSL -o "$JAR" "$JAR_URL"
fi
got=$(sha1sum "$JAR" | cut -d' ' -f1)
[ "$got" = "$JAR_SHA1" ] || { echo "jar sha1 $got, expected $JAR_SHA1" >&2; exit 1; }
echo "jar $JAR_NAME sha1=$got (the pack's modrinthHash)"

rm -rf "$WORK"
mkdir -p "$WORK/jars" "$WORK/mods"
cp "$JAR" "$WORK/jars/$JAR_NAME"
cp "$PORT/patches/inventory.json" "$WORK/inventory.json"
"$CARRY" carry "$WORK" --resources "$RES" bettermineshafts

rm -rf "$PORT/content/data" "$PORT/content/assets" "$PORT/content/outside"
cp -a "$WORK/mods/bettermineshafts/carry/." "$PORT/content/"
cp "$WORK/mods/bettermineshafts/carry-report.json" "$PORT/content/carry-report.json"
python3 "$PORT/tools/restore_jar_fields.py" --jar "$JAR" --content "$PORT/content"
# The SDK package reads `assets/` and `data/` at its root; the carried copy stays in `content/`.
rm -rf "$PORT/assets" "$PORT/data"
cp -a "$PORT/content/assets" "$PORT/content/data" "$PORT/"
python3 "$PORT/tools/verify_content.py" --content "$PORT" --resources "$RES"
echo "carry reproduced; prove it unchanged with tools/carry_proof.py, then build with tools/check.sh"
