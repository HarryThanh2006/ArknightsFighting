# Krita workflow — hand-drawing sprite strips

**Status: Draft (2026-11-11).** For the first character, Surtr (user decision),
drawn by hand in Krita. Sizes and frame counts: `design/art/sprite-spec-2d.md`.

**Rule:** draw from scratch. Do not trace, crop, recolour or paste official
Arknights sprites or art, and never place official art in this repository
(art bible §8.11, §9). Your own design of the Operator, drawn by you, only.

## 1. New document (one per animation)

1. File → New → Custom Document.
2. Width = 512 × drawings (light 6 → **3072**, heavy 7 → **3584**, idle 4 →
   2048, walk 6 → 3072, block 2 → 1024, hit 3 → 1536, ko 4 → 2048);
   Height = **384**; Resolution irrelevant (72 ppi).
3. Colour: Model **RGB/Alpha**, Depth **8-bit integer**, Profile **sRGB**
   (built-in sRGB-elle-V2-srgbtrc). Background: **Transparent**.
4. View → Show Grid; Settings → Configure Krita → Grid: spacing **512 × 384**
   (frame cells). A second, finer grid isn't needed; the template has one.

## 2. Template as a locked reference layer

1. Layer → Import/Export → Import Layer… →
   `assets/characters/guard_blockout/template/guard_blockout_<anim>_template.png`.
2. Rename it `REF template`, set opacity ~40 %, click the lock icon.
3. The template shows per drawing: frame border, **blue floor line + feet
   tick** (anchor 128, 368), **green** hurtbox (stay inside it with the body),
   **gold** hitbox on the ACTIVE drawing (the weapon must cover it), and the
   tick range in the label.

## 3. Layers (top to bottom)

| Layer | Content |
|---|---|
| `REF template` | locked, hidden before export |
| `lines` | 3 px dark outline on the outer silhouette, ≥ 2 px inside |
| `color` | flat fills, 2–3 value steps (art bible §5.2) |
| `prop` | weapon; Guard accent #FFC61A only on the emblem area (§4.2) |

## 4. Drawing rules

- Face **right**. The game flips the sprite for the other side.
- Feet on the blue anchor in **every** drawing; never slide the body to
  fake a lunge (draw the lean instead).
- Body inside the green box; on the ACTIVE drawing, weapon covers the gold box.
- Startup drawings telegraph (weapon moves before the active one); recovery
  returns to guard. Thumbnail test (§3.1): at 64 px tall, solid black, the
  class still reads; the weapon extends the outline by ≥ 25 %.

## 5. Export

1. Hide `REF template`.
2. File → Export… → `assets/characters/surtr/surtr_<anim>.png` (PNG,
   "Store alpha channel" on, 8-bit, sRGB). Krita exports the merged visible
   layers.
3. Keep the `.kra` source **outside** the repo or under
   `assets/characters/surtr/source/` if you want it versioned (it can be large).
4. If your drawing count differs from the spec, edit the `[<anim>]` ranges in
   `assets/characters/surtr/frames.cfg` (one `[first, last]` per drawing);
   run the tests — attack ranges must still tile the move and isolate the
   active frames.

## 6. See it in the game

Open the project in Godot once (it imports the PNG), run the match, press
**F2** (sprites) and **F4** (hurt/hit boxes). Missing animations show the
grey PLACEHOLDER blockout, so you can work one animation at a time.

## 7. Timing the first Light (the spike's open measurement)

1. Note the start time; create the Light document (3072 × 384) and import the
   Light template.
2. Draw the 6 drawings (active one = drawing 3, ticks 6–8), export, check in
   game with F2 + F4, fix anything outside the boxes.
3. Note the end time and any breaks; record total hours and hours per drawing
   in `production/qa/evidence/2026-11-11-art-spike-2d.md` (replace the estimate).

*No `.kra` templates are provided: Krita is not installed on the build
machine, so a generated `.kra` could not be checked to open. Use the PNG
templates as described above.*
