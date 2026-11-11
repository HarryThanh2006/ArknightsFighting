# 2D Sprite Spec (Tier −1 art spike)

**Status: Draft — spike (2026-11-11).** Owner: art-director (pending review).
Proves the 2D sprite pipeline with a code-drawn PLACEHOLDER blockout of a
generic Guard-class melee fighter. No character design is made here: final
frames are drawn by hand over the template sheets (art bible §8.11, §9: no
AI-generated or copied official art). Which Operator is drawn first is an open
question (Tier 0 roster in the concept is Ch'en + Amiya).

## 1. Scale (derived from sim units)

| Quantity | Sim | Art |
|---|---|---|
| Art density | 10,000 su = 1 m | **256 px / m** (0.0256 px / su) |
| Body (neutral hurtbox) | 5,000 × 12,000 su | 128 × 307 px (≈ 3 heads of ~102 px, art bible §3.1) |
| Longest reach (Heavy hitbox front) | 14,000 su | 358 px forward of the feet anchor |
| Canvas per frame | 2 m × 1.5 m | **512 × 384 px** |
| Feet anchor (pivot) | x 0, y 0 (floor) | **(128, 368)**: 0.5 m behind, 16 px floor margin |
| On screen, placeholder scene | 100 px / m | drawn at scale 100 / 256 = 0.39 (body 120 px tall) |

Art is authored at 256 px/m so a later camera that shows ~5 m of a 10 m stage
at 1280×720 (256 px/m) is 1:1. Canvas width covers 0.5 m behind the body and
1.5 m in front (Heavy front edge 1.4 m).

## 2. Anchor, facing, layering

- Every frame is drawn **facing right** with the feet on the anchor point.
  The view flips by `scale.x = facing` around the anchor; never draw a left set.
- Sim position (`pos_x_su`, `pos_y_su`) is the anchor; nothing in the art may
  shift the anchor between frames (a lunge is drawn, not offset).
- Weapon and limbs that carry a hitbox must cover that hitbox on its active
  frames; the template sheet draws each active frame's hitbox (gold) and the
  hurtboxes (green) so the artist draws inside them.

## 3. Animations and frame budget (tied to `data/moves/tier_minus_one.cfg`)

A *drawing* is one unique image; it is held for a range of sim ticks. Ranges
are data in `assets/characters/guard_blockout/frames.cfg`.

| Anim | Driver (read from `SimView`) | Ticks | Drawings | Tick ranges per drawing |
|---|---|---|---|---|
| idle | `state_ticks` (loop) | 32 loop | 4 | 8 each |
| walk | `state_ticks` while walking (loop) | 30 loop | 6 | 5 each |
| light | `move_frame` 1–16 | 16 | 6 | 1–2, 3–5 · **6–8 active** · 9–11, 12–14, 15–16 |
| heavy | `move_frame` 1–29 | 29 | 7 | 1–4, 5–8, 9–11 · **12–15 active** · 16–20, 21–25, 26–29 |
| block | ticks since guard began | hold | 2 | 0–2 enter, 3+ hold |
| hit | ticks since hitstun began | ≤ 22 | 3 | 0–3, 4–9, 10+ |
| ko | ticks since KO | hold | 4 | 0–5, 6–11, 12–19, 20+ |

Total **32 drawings** per character for the Tier −1 kit. Active frames get
exactly one drawing that matches the hitbox; startup must telegraph (the
blade moves before frame 6 / 12), recovery returns to guard.

## 4. Tick → drawing (view only, ADR-0002)

- The view reads `stance`, `move_id`, `move_frame`, `hitstun`, `blockstun`,
  `blocking`, `walking`, `state_ticks`, `facing`, position from `SimView`, and
  never writes to the sim.
- Priority: KO (HP 0) → hit (hitstun > 0) → block (blockstun > 0 or guard flag)
  → light / heavy (active move) → walk → idle.
- `move_frame` and `state_ticks` do not advance during hit-stop, so the drawing
  **holds through hit-stop** with no extra code. KO uses the sim tick (the
  round interval stops the movement counter).
- "Ticks since X began" is the `state_ticks` value when the view saw the
  change, subtracted from the current one.

## 5. Files and naming

```
assets/characters/<char>/frames.cfg            # canvas + tick ranges (data)
assets/characters/<char>/<char>_<anim>.png     # horizontal strip, 512×384 per drawing
assets/characters/<char>/template/<char>_<anim>_template.png  # draw-over sheet
```

`<char>` is snake_case (`guard_blockout` for this spike). Strips are PNG,
RGBA, transparent background, frames left to right in drawing order, no
padding. Godot imports them as 2D textures with filter Linear, mipmaps off.

## 6. Readability rules kept from the art bible (2D)

- §3.1 thumbnail test at 64 px tall, solid fill: class readable; the prop
  extends the bounding box ≥ 25 %; one class negative-space shape (Guard:
  crescent gap under the blade).
- §3.2 effects follow the class shape; §4.2 Guard accent **#FFC61A** only on
  the prop emblem area (≤ ~10 % of silhouette), impact flashes and skill aura.
- §4 P1 / P2 are told apart by frame / side marker, not by recolouring the
  sprite; both players may use the same character.
- §5.2–5.4 costume value structure and pose style; §2 saturation budget per
  state; §7 HUD rules unchanged.
- Outline: a 3 px dark outline (Graphite family) on the outer silhouette at
  256 px/m, so the shape survives the 0.39 placeholder scale; no inner lines
  thinner than 2 px.

## 7. Supersedes in the art bible (for 2D, until its revision)

§5.1 rigid-part construction, §5.5 camera yaw / 3D facing / LOD, §8.1–8.2
file formats and naming for meshes, §8.4 geometry budgets, §8.7 Blender
export, §8.8 AnimationPlayer on 3D rigs, §8.9 toon shader / inverted-hull
outline (replaced by the drawn outline in §6 here). Everything listed as
"still valid" in the art bible banner stays in force.

## 8. Must be hand-drawn

All 32 drawings per character, plus effects art later. The blockout strips
are scaffolding only: flat shapes, a PLACEHOLDER watermark, never shipped.
Regenerate them with `python tools/art/make_blockout_sprites.py` after any
change to move data or `frames.cfg`.
