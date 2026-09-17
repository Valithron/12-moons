# Louie Mantia hanafuda card art provenance

- Upstream repository: https://github.com/game-prototypes/hanafuda
- Exact commit: `170082cc3dc928987c04b1abbed6145331f72034`
- Source directory: `assets/cards/`
- Vendored: 2026-09-17
- Artist: Louie Mantia
- License: CC BY-SA 4.0
- License URL: https://creativecommons.org/licenses/by-sa/4.0/
- Upstream attribution: the repository README identifies the card images as
  CC BY-SA 4.0 by Louie Mantia, sourced from Wikimedia/Wikipedia.

12 Moons copied only the manifest-referenced PNG card-face assets. The upstream
GPL game code and Godot `.import` files were not copied. The source asset set
provides one November Kasu face, so that texture is intentionally mapped to
both November Chaff physical cards in the current canonical manifest. The
source November Tanzaku image is not vendored because it has no corresponding
12 Moons card ID.

The mapping from stable card IDs to textures is data-driven in
`data/hanafuda/cards.json`. This directory is provenance and licensing
documentation; it is not a runtime dependency.
