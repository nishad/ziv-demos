#!/usr/bin/env bash
#
# Regenerates every demo in this repository from its published IDR source.
#
# The demos are committed, so this script is not run to serve the site: it is run to rebuild it
# after a ziv change, and it is the record of exactly how each demo was produced.
#
# The --id passed to each export is baked into every info.json that export writes. It must be the
# URL the demo is actually served from, or IIIF clients will resolve tiles against the wrong
# origin. That is why moving a demo to a different repository means re-exporting it, not copying
# the files.
#
# Usage:
#   scripts/build-demos.sh              # all demos
#   scripts/build-demos.sh brain        # just the ones whose name matches
#   ZIV=/path/to/ziv scripts/build-demos.sh
#   THUMBS_ONLY=1 scripts/build-demos.sh   # regenerate thumbnails without re-exporting
set -euo pipefail

BASE_URL="${BASE_URL:-https://nishad.github.io/ziv-demos}"
IDR="https://uk1s3.embassy.ebi.ac.uk/idr/zarr/v0.4"
ZIV="${ZIV:-$(cd "$(dirname "$0")/../../zarr-lab" && pwd)/target/release/ziv}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FILTER="${1:-}"

if [ ! -x "$ZIV" ]; then
  echo "no ziv binary at $ZIV" >&2
  echo "build one with: cargo build --release -p ziv" >&2
  exit 1
fi

# name | source store | export flags
#
# Why the flags differ per demo:
#   nuclear-segmentation  236 z-planes at 275x271, so --planes --labels is cheap and shows the
#                         z slider, the label picker and the distinct-colour default at once.
#   whole-brain           19120x13350 but 91 z-planes: --planes would write 91 full pyramids
#                         (several GB). One plane is the deep-zoom demo; the rest is not.
#   genome-seq            the int64 label ziv silently dropped until the dtype fix. 12 z-planes.
#   condensin-map         declares two labels (Cell, Chromosomes), so the picker has a choice.
DEMOS=(
  "nuclear-segmentation|$IDR/idr0062A/6001240.zarr|--planes --labels"
  "whole-brain|$IDR/idr0048A/9846152.zarr|"
  "genome-seq|$IDR/idr0101A/13457537.zarr|--planes --labels"
  "condensin-map|$IDR/idr0052A/5514375.zarr|--planes --labels"
)

for entry in "${DEMOS[@]}"; do
  [ -n "${THUMBS_ONLY:-}" ] && break
  IFS='|' read -r name src flags <<<"$entry"
  if [ -n "$FILTER" ] && [[ "$name" != *"$FILTER"* ]]; then
    continue
  fi
  out="$ROOT/$name"
  echo "=== $name"
  echo "    src   $src"
  echo "    id    $BASE_URL/$name"
  rm -rf "$out"
  # shellcheck disable=SC2086
  "$ZIV" export "$src" "$out" --id "$BASE_URL/$name" $flags
  echo "    size  $(du -sh "$out" | cut -f1)  files $(find "$out" -type f | wc -l | tr -d ' ')"
done

# Landing-page thumbnails, one `ziv render` per demo.
#
# Each shows a view the demo itself contains: the default timepoint the export used, a plane the
# export wrote, and the export's own overlay opacity (DEFAULT_OVERLAY_OPACITY, 0.6). A thumbnail of a
# nicer timepoint the export never wrote would advertise something a visitor cannot open.
#
#   nuclear-segmentation  z=118 is the plane the demo opens on; the overlay shows the distinct
#                         colours that replace the image's 61 identical declared ones.
#   whole-brain           the default plane, downscaled to 640 px wide.
#   genome-seq            the int64 label, the one ziv used to drop.
#   condensin-map         the Cell label reads as an object; Chromosomes is a speck at this
#                         timepoint.
THUMBS=(
  "nuclear-segmentation|$IDR/idr0062A/6001240.zarr|@z=118,overlay=0:distinct:0.6|max"
  "whole-brain|$IDR/idr0048A/9846152.zarr|default|640,"
  "genome-seq|$IDR/idr0101A/13457537.zarr|@z=6,overlay=0:distinct:0.6|max"
  "condensin-map|$IDR/idr0052A/5514375.zarr|@z=15,overlay=Cell:distinct:0.6|max"
)

mkdir -p "$ROOT/thumbs"
for entry in "${THUMBS[@]}"; do
  IFS='|' read -r name src at size <<<"$entry"
  if [ -n "$FILTER" ] && [[ "$name" != *"$FILTER"* ]]; then
    continue
  fi
  echo "=== thumbnail $name"
  "$ZIV" render "$src" "$ROOT/thumbs/$name.jpg" --at "$at" --size "$size" --quality 88
done

echo
echo "total: $(du -sh "$ROOT" --exclude=.git 2>/dev/null | cut -f1 || du -sh "$ROOT" | cut -f1)"
