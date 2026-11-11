# Surtr — hand-drawn sprite strips (drop-in)

First character to draw (user decision 2026-11-11). This folder holds only
**original, hand-drawn** frames made in Krita (see `design/art/krita-workflow.md`).

- Put one PNG strip per animation here: `surtr_<anim>.png`
  (`idle`, `walk`, `light`, `heavy`, `block`, `hit`, `ko`), 512×384 per drawing,
  drawings left to right, transparent background.
- Any animation without a strip falls back to the PLACEHOLDER blockout in
  `../guard_blockout/` automatically, so you can add one animation at a time.
- `frames.cfg` here is a copy of the blockout's; edit the tick ranges here if
  your drawing count changes (the sprite test checks attack ranges against the
  move data).
- Draw from scratch. Do not trace, crop, recolour or paste official Arknights
  sprites or art, and never put official art in this repository (art bible
  §8.11, §9).
- See it in game: run the match, press **F2** for sprites, **F4** for boxes.
