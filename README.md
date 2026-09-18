# ziv-demos

Static IIIF demos of published OME-Zarr microscopy images, built with
[ziv](https://github.com/nishad/ziv) and served by GitHub Pages at
<https://nishad.github.io/ziv-demos/>.

Each demo is a complete [IIIF Image API 3.0](https://iiif.io/api/image/3.0/) Level 0 tile tree:
every file a IIIF client will ever request, written ahead of time, with a bundled OpenSeadragon
viewer. No server runs here.

## The demos

| Directory | Image | Demonstrates |
| --- | --- | --- |
| `nuclear-segmentation/` | IDR 6001240 | 236 z-planes with a segmentation overlay on each, in distinct colours |
| `whole-brain/` | IDR 9846152 | 255 megapixels, nine pyramid levels, deep zoom |
| `genome-seq/` | IDR 13457537 | a 64-bit integer label image |
| `condensin-map/` | IDR 5514375 | two separate label images on one image |

Every image is published in the [Image Data Resource](https://idr.openmicroscopy.org/) and remains
the work of its authors. `index.html` credits each one with its IDR study and primary publication;
please cite those rather than this site.

## Rebuilding

```sh
cargo build --release -p ziv          # in a ziv checkout beside this one
./scripts/build-demos.sh              # all demos
./scripts/build-demos.sh brain        # just the matching ones
```

The tiles are committed, so the script is not needed to serve the site. It is how the site is
regenerated after a ziv change, and it is the record of exactly how each demo was produced.

### The hosting URL is baked in

`ziv export --id <url>` writes that URL into every `info.json` as the IIIF service's identity. It
must be the URL the demo is actually served from, or a IIIF client will resolve tiles against the
wrong origin. Two consequences:

- moving a demo to a different repository, user or domain means **re-exporting** it, not copying the
  files;
- `BASE_URL` in `scripts/build-demos.sh` is the single place that URL is defined.

### Why the flags differ per demo

`whole-brain` is exported without `--planes`. It has 91 z-planes at 19 120 × 13 350, so exporting
them all would write 91 full pyramids and several gigabytes, against a GitHub Pages soft limit of
1 GB per site. One plane is the deep-zoom demo; the rest is not. The other three are small enough in
XY that every plane and every label overlay is cheap.

## Licence

The code in this repository is MIT. The images are not ours: they are published in IDR by their
authors under the terms stated on each study's IDR page, and are included here for demonstration
with attribution.
