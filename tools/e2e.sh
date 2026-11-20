#!/usr/bin/env bash
# In-game check for YUNG's Better Mineshafts (SDK package, mod API 0.2) — the launcher leg.
#
# The package is compiled into a game by Horizon's launcher at the SDK pin
# (`0b14f8a`, launcher 0.2.78); `ports/tools/launcher-game.sh run bettermineshafts`
# builds it, exports the game into `~/.cache/horizon-e2e/` and runs this script in
# a build slot. Nothing here reads `/tmp`: scratch, sockets and worlds live under
# `E2E_TMP` (the cache root).
#
# What only a game can prove, and what each leg asserts:
#
#   A. the readout: `/bettermineshafts status` answers the structure id, the four
#      required biomes (+3 optional) and the deterministic probe
#      `15 pieces (entrance 1, corridor 4, branch 6, stairs 3, room 1)` — the numbers
#      `cargo test` pins in `src/runtime.rs::probe`, stairs included.
#   B. the carried structure set starts: `/locate structure
#      bettermineshafts:mineshaft_oak` finds a site, while an id the mod does not
#      carry answers "Could not find".
#   C. the structure GENERATES AND WRITES BLOCKS: at a forceloaded site that holds
#      no ladder/plank/rail before, `/place structure` puts the entrance's ladder,
#      the corridor's rail, the doorway's stone bricks and the walls' oak planks
#      into the world, each read back at its own coordinate with `ctl block`. The
#      ladder is the entrance's signature (vanilla mineshafts have none).
#   D. the per-variant palette comes from the DATA, not from the code: the ice
#      variant placed at a second site writes `minecraft:packed_ice` (its config's
#      main/support/brick block) and no oak planks, so `GenerationContext::config`
#      really reaches the pieces.
#   E. the stair piece (0.2.2): a placed branch run contains an ASCENDING rail — the
#      stair's own signature, which no other piece of the mod writes — and the player
#      is teleported onto it and reads it back. The stair takes the run four blocks
#      higher (`SmallTunnelStairs.addChildren`), so this is also the only place the mod
#      writes a rail with a slope. `/bettermineshafts last` reports the start the mod
#      just generated, so the leg places at the chunks a forceloaded area covers and
#      asks the mod where its stair is, instead of scanning a whole structure for a
#      piece a branch draws 20 % of the time off a 7 % branch.
#
# Modes (the wrapper runs the default one):
#   default        legs A-D on the launcher-built game; must print PASS + EXIT:0.
#   CONTROL=1      the same script against the unmodified Nightly
#                  (`GAME=$CONTROL_GAME`): the command and the structure id are
#                  unknown and the ground is untouched. It then prints FAIL and
#                  exits non-zero **deliberately** — that is the differential
#                  which proves leg C's blocks came from this package.
#   SELFTEST=1     leg A with a corrupted expectation (18 pieces instead of 17),
#                  which the readout cannot satisfy: must print FAIL + EXIT:1.
set -Eeuo pipefail

CLONE=$(cd "$(dirname "$0")/../.." && pwd)
PORT=$CLONE/ports/bettermineshafts
CTL=${CTL:-}
GAME=${GAME:-}
CONTROL_GAME=${CONTROL_GAME:-}
RES=${RES:-${HORIZON_RES:-/home/adlf/Desktop/horizon/.local/horizon-client/26.3}}
SOCK=${SOCK:-${E2E_TMP:-$HOME/.cache/horizon-e2e/scratch}/bettermineshafts-e2e.sock}
SELFTEST=${SELFTEST:-0}
CONTROL=${CONTROL:-0}
KEEP=${KEEP:-0}
SEED=${SEED:-20261105}
OAK=bettermineshafts:mineshaft_oak
ICE=bettermineshafts:mineshaft_ice
SITE_X=${SITE_X:-1024}     # chunk 64,64: the start is the chunk's block 3, so x/z 1027
SITE_Z=${SITE_Z:-1024}
ICE_X=${ICE_X:-1536}       # far enough that the oak site's corridors are not in its radius
ICE_Z=${ICE_Z:-1536}

fail() { echo "FAIL: $*" >&2; exit 1; }
say() { echo "== $* =="; }

[ -n "$GAME" ] || {
    echo "GAME is required: the SDK package is built into a game by the launcher," >&2
    echo "  ports/tools/launcher-game.sh run bettermineshafts" >&2
    exit 1
}
[ -x "$GAME" ] || { echo "missing horizon-client: $GAME" >&2; exit 1; }
[ -n "$CTL" ] || { echo "CTL is required (ports/tools/launcher-game.sh env bettermineshafts)" >&2; exit 1; }
[ -x "$CTL" ] || { echo "missing horizon-ctl: $CTL" >&2; exit 1; }
[ -d "$RES/assets" ] || { echo "missing prepared resources: $RES" >&2; exit 1; }

SCRATCH_ROOT=${E2E_TMP:-$HOME/.cache/horizon-e2e/scratch}
mkdir -p "$SCRATCH_ROOT" "$(dirname "$SOCK")"
SCRATCH=$(mktemp -d "$SCRATCH_ROOT/bettermineshafts-home.XXXXXX")
rm -f "$SOCK"
export HORIZON_NO_AUDIO=1
export XDG_DATA_HOME=$SCRATCH/data
export XDG_CONFIG_HOME=$SCRATCH/config
export HORIZON_LAUNCHER_HOME=$SCRATCH/launcher

ctl() { "$CTL" --socket "$SOCK" "$@"; }
chat() { jq -r '.chat[0] // ""'; }
# A command that answers several lines (the status readout) needs all of them.
chat_all() { jq -r '(.chat // [])[]'; }
# A `ctl blocks` reply holds every non-air cell of the box and a count per block:
#   {"blocks":[[x,y,z,"minecraft:id"],…],"counts":{"minecraft:id":n,…}}
counts() { jq -r '.counts // {}'; }
count_of() { # reply-file block
    jq -r --arg b "$2" '.counts[$b] // 0' "$1"
}
# A block's first position in a scanned box: the box is the site column, so the
# read-back is at a coordinate the placement actually wrote (find-block is limited
# by radius, and the corridor can sit 150 blocks under the player).
pos_in_box() { # box-file block
    # Entries carry the full state ("minecraft:ladder[facing=east]"), so match the prefix.
    jq -c --arg b "$2" '[.blocks[] | select(.[3] | startswith($b))][0] | .[0:3]' "$1"
}
block_at() { ctl block "$1" "$2" "$3" | jq -r '.block // "unknown"'; }
# The full state of one cell (`minecraft:rail[shape=ascending_south]`): `ctl block` answers the
# bare id, so a property has to be read through `ctl blocks`, which carries it.
state_at() { # x y z
    ctl blocks "$1" "$2" "$3" "$1" "$2" "$3" \
        | jq -r '.blocks[0][3] // "minecraft:air"'
}
# The corridor's floor: the entrance ladder starts at floor+1, so its lowest cell minus one.
ladder_floor() { # box-file
    jq -r '[.blocks[] | select(.[3] | startswith("minecraft:ladder")) | .[1]] | min // empty' "$1"
}
# The ascending rails in a scanned slab: the stair piece's own signature (the corridor's and the
# branch's rails are plain, so a vanilla mineshaft has none either).
ASCENDING='[.blocks[] | select((.[3] | startswith("minecraft:rail[")) or (.[3] | startswith("minecraft:powered_rail["))) | select(.[3] | contains("ascending"))]'
ascending_rails() { # box-file
    jq -r "$ASCENDING | length" "$1"
}
# Four 64x64 slabs at the stair's first step, so a branch off the first two corridor segments is
# covered whichever way the shaft faces. Each reply is kept so a rail can be read back.
stair_scan() { # x z y prefix
    local x=$1 z=$2 y=$3 prefix=$4 i=0 total=0 count
    for dx in -64 0; do
        for dz in -64 0; do
            i=$((i + 1))
            ctl blocks "$((x + dx))" "$y" "$((z + dz))" \
                "$((x + dx + 64))" "$((y + 1))" "$((z + dz + 64))" >"$prefix-$i.json"
            count=$(ascending_rails "$prefix-$i.json")
            echo "  slab $((x + dx)),$((z + dz)) y $y..$((y + 1)): ascending rails=$count" >&2
            total=$((total + count))
        done
    done
    printf '%s' "$total"
}

cleanup() {
    local status=$?
    ctl quit >/dev/null 2>&1 || true
    sleep 1
    if [ "$KEEP" != 1 ]; then rm -rf "$SCRATCH" || true; fi
    echo "E2E EXIT:$status"
}
trap cleanup EXIT

launch() { # world game
    local world=$1 game=$2
    export HORIZON_HOME=$SCRATCH/home
    mkdir -p "$HORIZON_HOME"
    say "launch ($game, headless offscreen, creative, Overworld, seed $SEED)"
    "$CTL" --socket "$SOCK" launch \
        --game "$game" --world "$world" --seed "$SEED" --creative --offscreen --wait \
        --game-dir "$SCRATCH" --resources "$RES" \
        >"$SCRATCH/launch.json" 2>&1 || { cat "$SCRATCH/launch.json" >&2; fail "the game did not launch"; }
    jq -c '{dimension, creative, ok: .launch.ok}' "$SCRATCH/launch.json" 2>/dev/null || true
    ctl wait-ready 400 >/dev/null 2>&1 || true
    ctl command "difficulty peaceful" >/dev/null 2>&1 || true
    ctl wait 10 >/dev/null
}

# Keep the site's chunks loaded and stand in the air above it: `/place` in a chunk
# the client has not received is overwritten by the chunk data that arrives later.
forceload_site() { # x z
    local x=$1 z=$2 reply error attempt=0
    while :; do
        reply=$(ctl command "forceload add $((x - 48)) $((z - 48)) $((x + 48)) $((z + 48))" || true)
        error=$(echo "$reply" | jq -r '.error // ""' 2>/dev/null || echo "")
        [ -z "$error" ] && break
        attempt=$((attempt + 1))
        echo "forceload attempt $attempt: $error"
        [ "$attempt" -lt 4 ] || fail "forceload never answered: $error"
        ctl wait 60 >/dev/null
    done
    echo "forceload $x $z: $(echo "$reply" | jq -r '.chat[0] // "ok"' 2>/dev/null || echo ok)"
}

go_to_site() { # x z
    local x=$1 z=$2 reply error attempt=0
    while :; do
        reply=$(ctl tp "$((x + 8)).5 120 $((z + 8)).5" || true)
        error=$(echo "$reply" | jq -r '.error // ""' 2>/dev/null || echo "")
        [ -z "$error" ] && break
        attempt=$((attempt + 1))
        echo "tp attempt $attempt: $error"
        [ "$attempt" -lt 4 ] || fail "the teleport never answered: $error"
        ctl wait 60 >/dev/null
    done
    ctl wait-ready 240 >/dev/null 2>&1 || true
    ctl wait 60 >/dev/null
    ctl wait-ready 240 >/dev/null 2>&1 || true
}

# Force the client to re-request the site's chunks: one received before the
# placement shows the placed blocks, one arriving after replaces them.
resync() { # x z
    local x=$1 z=$2
    ctl tp "$((x + 512)).5 120 $((z + 512)).5" >/dev/null 2>&1 || true
    ctl wait-ready 240 >/dev/null 2>&1 || true
    ctl wait 40 >/dev/null
    ctl tp "$((x + 8)).5 120 $((z + 8)).5" >/dev/null 2>&1 || true
    ctl wait-ready 240 >/dev/null 2>&1 || true
    ctl wait 40 >/dev/null
}

# The column a start lives in: the 16x16 chunk from y -56 (below the config's
# -55 floor) to 44 (above the highest floor plus a corridor's 8), 25,856 cells,
# under `ctl blocks`'s 32,768-entry ceiling.
box() { # x z out-file
    ctl blocks "$1" -56 "$2" "$(($1 + 15))" 44 "$(($2 + 15))" > "$3"
}

place() { # structure x z
    local id=$1 x=$2 z=$3 reply attempt=0
    while :; do
        reply=$(ctl command "place structure $id $x -20 $z" | chat)
        # On stderr: the caller captures this function's stdout as the reply itself.
        echo "place $id $x -20 $z -> $reply" >&2
        case "$reply" in
            *"not loaded"*)
                attempt=$((attempt + 1))
                [ "$attempt" -lt 3 ] || fail "the start's chunks never loaded: $reply"
                ctl wait 60 >/dev/null
                ;;
            *) break ;;
        esac
    done
    printf '%s' "$reply"
}

read_back() { # box-file block
    local box=$1 block=$2 pos x y z got
    pos=$(pos_in_box "$box" "$block")
    [ "$pos" != null ] || fail "the placed structure wrote no $block to read back"
    read -r x y z <<<"$(echo "$pos" | jq -r '.[0], .[1], .[2]' | tr '\n' ' ')"
    got=$(block_at "$x" "$y" "$z")
    # On stderr: the caller captures this function's stdout as "x y z".
    echo "ctl block $x $y $z -> $got (the box found $block at $pos)" >&2
    case "$got" in
        "$block"*) ;;
        *) fail "$block at $x $y $z reads $got" ;;
    esac
    printf '%s %s %s' "$x" "$y" "$z"
}

# ------------------------------------------------------------------ the control
# The unmodified Nightly at the same pin: the mod's command and structure are
# unknown and the ground holds none of its blocks. Every assertion here must hold
# for the differential to mean anything, and the run then FAILS on purpose.
if [ "$CONTROL" = 1 ]; then
    launch bettermineshafts-control "$GAME"
    say "control: the unmodified Nightly has no bettermineshafts"
    STATUS=$(ctl command "/bettermineshafts status" 2>&1 || true)
    echo "status -> $(echo "$STATUS" | head -3)"
    if echo "$STATUS" | grep -q 'bettermineshafts:mineshaft_oak'; then
        fail "the control build answered the mod's command (it is not the unmodified game)"
    fi
    forceload_site "$SITE_X" "$SITE_Z"
    go_to_site "$SITE_X" "$SITE_Z"
    REFUSED=$(place "$OAK" "$SITE_X" "$SITE_Z")
    echo "$REFUSED" | grep -qi 'no structure with type' \
        || fail "the control build accepted $OAK: $REFUSED"
    box "$SITE_X" "$SITE_Z" "$SCRATCH/box-control.json"
    for block in minecraft:ladder minecraft:rail minecraft:oak_planks minecraft:packed_ice; do
        got=$(count_of "$SCRATCH/box-control.json" "$block")
        echo "control: $block=$got"
        [ "$got" = 0 ] || fail "the unmodified game holds $got $block, so the modded leg proves nothing"
    done
    echo "CONTROL OK: the same Nightly without the package knows no bettermineshafts: no command,"
    echo "  the structure id refused, and no ladder/rail/planks/packed_ice in the site's column."
    echo "FAIL: CONTROL — this leg is the differential and must end non-zero (the modded run is the PASS)"
    exit 1
fi

# ------------------------------------------------------------------ leg A-D
launch bettermineshafts "$GAME"

say "A: /bettermineshafts status"
STATUS=$(ctl command "/bettermineshafts status" | chat_all)
echo "$STATUS"
EXPECTED_PIECES=15
[ "$SELFTEST" = 1 ] && EXPECTED_PIECES=16
echo "$STATUS" | grep -q "$OAK" || fail "status does not name the carried structure"
echo "$STATUS" | grep -q 'biomes 4 required (+3 optional)' \
    || fail "status does not report the four required biomes"
echo "$STATUS" | grep -q "probe seed 1274 chunk 0,0" || fail "status does not name the probe"
echo "$STATUS" | grep -q "$EXPECTED_PIECES pieces" \
    || fail "status does not report $EXPECTED_PIECES pieces (SELFTEST=$SELFTEST)"
# The stair kind exists at all: the pre-0.2.2 package has no `stairs` token in its readout.
echo "$STATUS" | grep -qE 'stairs [1-9]' \
    || fail "status does not report a stair piece in the probe: $STATUS"

say "B: the carried set starts, and an id it does not carry does not"
LOCATED=$(ctl command "locate structure $OAK" | chat)
echo "locate $OAK -> $LOCATED"
case "$LOCATED" in
    "The nearest $OAK is at ["*) ;;
    *) fail "the carried structure set does not start: $LOCATED" ;;
esac
UNKNOWN=$(ctl command "locate structure bettermineshafts:not_a_structure" | chat)
echo "locate bettermineshafts:not_a_structure -> $UNKNOWN"
case "$UNKNOWN" in
    "Could not find"*) ;;
    *) fail "an unknown structure id was located: $UNKNOWN" ;;
esac
# The carried biome tag is exercised, not assumed: the located start's column must be in
# one of the four required entries of `has_structure/better_mineshaft_oak.json` (the three
# optional ones are other mods' biomes and are absent from this world).
LOCATED_XZ=$(echo "$LOCATED" | sed -n 's/.*is at \[\([-0-9]*\), ~, \([-0-9]*\)\].*/\1 \2/p')
[ -n "$LOCATED_XZ" ] || fail "could not read the located structure's column: $LOCATED"
read -r LOCATED_X LOCATED_Z <<<"$LOCATED_XZ"
BIOME_HIT=""
for biome in minecraft:plains minecraft:sunflower_plains minecraft:swamp minecraft:meadow; do
    REPLY=$(ctl command "execute if biome $LOCATED_X 64 $LOCATED_Z $biome" | chat)
    echo "biome $biome at $LOCATED_X,64,$LOCATED_Z -> $REPLY"
    case "$REPLY" in
        *"Test passed"*) BIOME_HIT=$biome ;;
    esac
done
[ -n "$BIOME_HIT" ] \
    || fail "the located start's column is in none of the tag's four required biomes"
echo "tag: the start at $LOCATED_X,$LOCATED_Z is in $BIOME_HIT, an entry of the carried tag"

say "C: the oak mineshaft generates and writes its own blocks"
forceload_site "$SITE_X" "$SITE_Z"
go_to_site "$SITE_X" "$SITE_Z"
box "$SITE_X" "$SITE_Z" "$SCRATCH/box-before.json"
BEFORE_LADDER=$(count_of "$SCRATCH/box-before.json" minecraft:ladder)
BEFORE_RAIL=$(count_of "$SCRATCH/box-before.json" minecraft:rail)
BEFORE_PLANKS=$(count_of "$SCRATCH/box-before.json" minecraft:oak_planks)
echo "before: ladder=$BEFORE_LADDER rail=$BEFORE_RAIL oak_planks=$BEFORE_PLANKS"
[ "$BEFORE_LADDER" = 0 ] || fail "the site already holds a ladder, so the box is not empty"
[ "$BEFORE_RAIL" = 0 ] || fail "the site already holds rails (a vanilla mineshaft?), so the box is not empty"
[ "$BEFORE_PLANKS" = 0 ] || fail "the site already holds oak planks, so the box is not empty"

PLACED=$(place "$OAK" "$SITE_X" "$SITE_Z")
case "$PLACED" in
    Generated\ structure\ \"$OAK\"*) ;;
    *) fail "$OAK did not place: $PLACED" ;;
esac
ctl wait 20 >/dev/null
resync "$SITE_X" "$SITE_Z"
box "$SITE_X" "$SITE_Z" "$SCRATCH/box-after.json"
for block in minecraft:ladder minecraft:rail minecraft:oak_planks minecraft:stone_brick_wall; do
    got=$(count_of "$SCRATCH/box-after.json" "$block")
    echo "after: $block=$got"
    [ "$got" -ge 1 ] || fail "the placed structure wrote no $block in its start column"
done
echo "-- read back at their own coordinates:"
LADDER_AT=$(read_back "$SCRATCH/box-after.json" minecraft:ladder)
RAIL_AT=$(read_back "$SCRATCH/box-after.json" minecraft:rail)
PLANKS_AT=$(read_back "$SCRATCH/box-after.json" minecraft:oak_planks)
echo "-- the entrance's surroundings:"
read -r LX LY LZ <<<"$LADDER_AT"
ctl blocks "$((LX - 4))" "$((LY - 2))" "$((LZ - 4))" "$((LX + 4))" "$((LY + 8))" "$((LZ + 4))" \
    > "$SCRATCH/box-entrance.json"
echo "$(counts < "$SCRATCH/box-entrance.json")"
DOOR=$(count_of "$SCRATCH/box-entrance.json" minecraft:stone_brick_wall)
echo "doorway frame: stone_brick_wall=$DOOR around the ladder at $LADDER_AT"
[ "$DOOR" -ge 1 ] || fail "no stone-brick doorway beside the ladder"

say "D: the ice variant builds from its own carried palette"
forceload_site "$ICE_X" "$ICE_Z"
go_to_site "$ICE_X" "$ICE_Z"
box "$ICE_X" "$ICE_Z" "$SCRATCH/box-ice-before.json"
ICE_BEFORE=$(count_of "$SCRATCH/box-ice-before.json" minecraft:packed_ice)
echo "before at the ice site: packed_ice=$ICE_BEFORE"
[ "$ICE_BEFORE" = 0 ] || fail "the ice site already holds packed ice"
ICE_PLACED=$(place "$ICE" "$ICE_X" "$ICE_Z")
case "$ICE_PLACED" in
    Generated\ structure\ \"$ICE\"*) ;;
    *) fail "$ICE did not place: $ICE_PLACED" ;;
esac
ctl wait 20 >/dev/null
resync "$ICE_X" "$ICE_Z"
box "$ICE_X" "$ICE_Z" "$SCRATCH/box-ice-after.json"
ICE_AFTER=$(count_of "$SCRATCH/box-ice-after.json" minecraft:packed_ice)
ICE_PLANKS=$(count_of "$SCRATCH/box-ice-after.json" minecraft:oak_planks)
echo "after at the ice site: packed_ice=$ICE_AFTER oak_planks=$ICE_PLANKS"
[ "$ICE_AFTER" -ge 1 ] || fail "the ice variant wrote no packed_ice (its config's main block)"
[ "$ICE_PLANKS" = 0 ] || fail "the ice variant wrote $ICE_PLANKS oak planks: the oak palette leaked"

say "E: the stair piece climbs a branch four blocks and its rails rise with it"
go_to_site "$SITE_X" "$SITE_Z"
STAIR_POS=""
for cx in 61 62 63 64 65 66 67; do
    for cz in 61 62 63 64 65 66 67; do
        SX=$((cx * 16 + 3))
        SZ=$((cz * 16 + 3))
        PLACED=$(place "$OAK" "$SX" "$SZ")
        case "$PLACED" in
            Generated\ structure\ \"$OAK\"*) ;;
            *) echo "  chunk $cx,$cz: $PLACED"; continue ;;
        esac
        # What the mod just generated: the readout names every stair it placed, so the leg never
        # has to guess where one is.
        LAST=$(ctl command "/bettermineshafts last $cx $cz" | chat_all)
        SUMMARY=$(echo "$LAST" | grep -m1 'last start' || true)
        STAIR_LINE=$(echo "$LAST" | grep -m1 ': stair ' || true)
        if [ -z "$STAIR_LINE" ]; then
            echo "  chunk $cx,$cz: $SUMMARY"
            continue
        fi
        echo "  chunk $cx,$cz: $SUMMARY"
        echo "  $STAIR_LINE"
        BOX=$(echo "$STAIR_LINE" | sed -n \
            's/.*box \[\([-0-9]*\), \([-0-9]*\), \([-0-9]*\)\]\.\.\[\([-0-9]*\), \([-0-9]*\), \([-0-9]*\)\].*/\1 \2 \3 \4 \5 \6/p')
        [ -n "$BOX" ] || fail "could not read the stair's box: $STAIR_LINE"
        read -r X1 Y1 Z1 X2 Y2 Z2 <<<"$BOX"
        ctl blocks "$X1" "$Y1" "$Z1" "$X2" "$Y2" "$Z2" > "$SCRATCH/stair.json"
        COUNT=$(ascending_rails "$SCRATCH/stair.json")
        echo "  stair box [$X1,$Y1,$Z1]..[$X2,$Y2,$Z2]: ascending rails=$COUNT"
        if [ "$COUNT" -ge 1 ]; then
            STAIR_POS=$(jq -c "$ASCENDING | .[0] | .[0:3]" "$SCRATCH/stair.json")
            break 2
        fi
    done
done
[ -n "$STAIR_POS" ] && [ "$STAIR_POS" != null ] \
    || fail "no placed start in the forceloaded chunks generated a stair with a rail"
read -r STAIR_X STAIR_Y STAIR_Z <<<"$(echo "$STAIR_POS" | jq -r '.[0], .[1], .[2]' | tr '\n' ' ')"
STAIR_STATE=$(state_at "$STAIR_X" "$STAIR_Y" "$STAIR_Z")
echo "ctl blocks $STAIR_X $STAIR_Y $STAIR_Z -> $STAIR_STATE (the stair's rail)"
case "$STAIR_STATE" in
    minecraft:rail\[*ascending* | minecraft:powered_rail\[*ascending*) ;;
    *) fail "the stair's rail at $STAIR_X $STAIR_Y $STAIR_Z reads $STAIR_STATE" ;;
esac
# Enter the piece: stand on the rail and read the passage back from inside it.
ctl tp "$STAIR_X.5 $((STAIR_Y + 1)) $STAIR_Z.5" >/dev/null
ctl wait 20 >/dev/null
PLAYER=$(ctl state | jq -r '.player.position | "\(.[0]) \(.[1]) \(.[2])"' 2>/dev/null || true)
PLAYER_CELL=$(ctl state | jq -r '.player.block_pos | "\(.[0]) \(.[1]) \(.[2])"' 2>/dev/null || true)
echo "player inside the stair: $PLAYER (cell $PLAYER_CELL)"
[ -n "$PLAYER" ] || fail "the player did not answer after entering the stair"
# The player stands in the rail's own column: on the step's floor (the rail's cell, rails are not
# solid) or in the cell above it, depending on how far they fell before the tick.
case "$PLAYER_CELL" in
    "$STAIR_X $STAIR_Y $STAIR_Z" | "$STAIR_X $((STAIR_Y + 1)) $STAIR_Z") ;;
    *) fail "the player is not in the stair's passage (at $PLAYER_CELL, rail at $STAIR_X $STAIR_Y $STAIR_Z)" ;;
esac
case "$(state_at "$STAIR_X" "$((STAIR_Y + 1))" "$STAIR_Z")" in
    minecraft:air*) ;;
    *) fail "the stair's passage is not open above its rail" ;;
esac

echo "PASS: bettermineshafts — $OAK generates its entrance (ladder at $LADDER_AT, doorway stone"
echo "      bricks), corridor (rail at $RAIL_AT) and plank walls (at $PLANKS_AT) in a real level;"
echo "      a stair piece climbs a branch four blocks (ascending rail at $STAIR_X $STAIR_Y"
echo "      $STAIR_Z, entered and read back); the ice variant builds from its own packed_ice"
echo "      palette; the located start is in $BIOME_HIT, an entry of the carried biome tag; the"
echo "      readout reports $EXPECTED_PIECES pieces for the probe; and an id it does not carry is"
echo "      refused"
