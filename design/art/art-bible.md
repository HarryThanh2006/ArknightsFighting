# Art Bible: Arknights – Operator Clash: Tactical Deployment

> **Status**: **Needs revision for 2D (2026-11-10)** — was Approved. The user decided the game is a **2D sprite fighting game** (replacing 2.5D / 3D chibi). Until the 2D revision (a separate task), read this file as follows:
> - **Superseded (3D-specific):** §3.3 environment geometry as 3D modules; §5.1 rigid-part construction; §5.5 camera yaw / 3D facing / LOD; §6.2 texturing of 3D surfaces; §8.1 file formats for meshes (glTF); §8.2 mesh / material naming; §8.4 geometry budgets and construction; §8.5 draw calls / materials / shaders; §8.6 3D texture import and VRAM; §8.7 Blender export and authoring; §8.8 AnimationPlayer keys on 3D rigs; §8.9 toon shader, inverted-hull outline, bloom / glow and backend; all lighting / key-light directions on 3D models.
> - **Still valid:** §1 identity and the one-line rule; §2 saturation budget and per-state targets; §3.1–3.2 silhouette and class shape language, §3.4–3.5; §4 colour system (palette, class colours, P1 / P2 by frame not colour, colourblind backups); §5.2–5.4 and §5.6 (costume value structure, telling fighters apart, pose style, original designs of canon Operators); §6.1, §6.3–6.5 as layout and mood intent; §7 UI / HUD in full (text floor, layer order, typography, VI + EN); §8.10 UI assets; §8.11 provenance and originality; §9 references and reference hygiene (no copied or AI-generated official art).
> **Owned By**: art-director
> **Last Updated**: 2026-11-01
> **Art Director Sign-Off (AD-ART-BIBLE)**: REVISED 2026-11-01 — review returned CONCERNS (3 must-fix: emissive hue clipping, Tier 0 floor-line contrast, UI clamp; 7 clarifications); all 10 re-drafted by art-director / technical-artist and approved by the user
> **Provisional values**: §7 text sizes and photosensitivity limits (pending `design/accessibility-requirements.md`); §8 VRAM / GPU-time numbers (pending memory ceiling and min-spec GPU); §8 [M] engine items (verify in the 4.7.2 editor / Tier −1 spike)

`/art-bible` writes these nine sections in this order and replaces each
section's `[To be designed]` line as that section is approved. A section still
holding its placeholder is incomplete; a later run fills only those.

## 1. Visual Identity Statement

*Built directly from the concept's Visual Identity Anchor, "Tactical Dossier +
Silhouette Doctrine" (AD-CONCEPT-VISUAL: STRONG). The core rule is unchanged.*

### 1.1 The one-line rule

> **Color is information. The world is black, bronze-gold and ivory-white; only
> gameplay state is allowed to have color. And every class must be identifiable
> by silhouette alone, in a black-and-white screenshot.**

The rule has two clauses. Clause A (color) governs what a pixel may be; Clause B
(shape) governs what a form may be. Together they settle most visual decisions.

**Applying it to an ambiguous decision**, in order:

1. Does it carry gameplay information (class, state, danger, side)? Then it may
   use color, and must *also* be readable by shape or position.
2. If it carries no information, it is neutral: black, ivory, or bronze-gold, at
   reduced saturation.
3. If it is neutral and still competes with a character or the HUD, reduce it or
   cut it.

**Rationale.** In a 1v1 fighter at 60 Hz the eye has a fraction of a second to
parse two characters, two sets of resources and a hitbox-relevant pose. Making
color scarce makes it a signal. This is Pillar 3 (Readable Mastery) applied to
the art itself, not only the HUD. It also protects Pillar 1 (Class Is Identity):
a class recognizable without color cannot be confused with another, even in a
mirror match.

### 1.2 Supporting principles

#### Principle A — Rhodes Island operations feed (serves Pillar 4, bounded by Pillar 3)

The UI and arena read as a military-tech tactical dossier. The vocabulary:
bracket frames, 45° chamfered rectangles, chevrons, hex cells, monospace type,
hazard stripes, and a light scanline on scene transitions. The arena is
desaturated by about 30% and slightly soft, so characters are the sharpest,
highest-contrast thing on screen.

**Design test:** *When a decorative detail is ambiguous, choose the version that
competes less with the characters and the HUD. If it competes at all, reduce or
remove it.*

**Rationale.** This is what makes a Doctor recognize the game — Pillar 4's
presentation promise. Pillar 4 leads only where HUD legibility is untouched, so
the dossier language may dress the frame (bracket corners, panel chrome, menus,
transitions) but may not sit behind or inside the values a player reads
mid-fight: SP, SP type, Ultimate gauge, skill timer.

**Fan-game originality.** The vocabulary is built from generic geometric
primitives — common military-UI tropes, not any publisher's artwork. We author
every instance ourselves:

- Draw our own icons, frames, emblems and logos.
- Use an open-license, non-Arknights typeface, or draw one.
- Never trace, screenshot-sample or palette-pick from the original game's UI.
- Do not reuse the Rhodes Island logo or its distinctive marks.
- "Recognizable" means the same language and discipline, not the same artwork.

#### Principle B — Silhouette doctrine (serves Pillar 1, with Pillar 3)

Class is encoded in shape first; color only confirms it. The class shape language
is mandatory for Operators **and** their VFX:

| Class | Shape language |
|---|---|
| Defender | square block, wall |
| Guard | blade arc |
| Vanguard | forward-pointing chevron |
| Sniper | long thin line, reticle |
| Caster | circle, rune ring |
| Medic | soft cross |
| Supporter | hex lattice |
| Specialist | hook, diagonal zigzag |

Each Operator carries one oversized class prop (shield, staff, bow…) as its
silhouette key. Models are chamfered-block, rigid-part chibi at about **3 heads**,
with a toon shader and an inverted-hull outline. Hit trails show the move's true
range.

**Design test:** *When a character or effect shape is ambiguous, desaturate a
screenshot to black and white. If the class is not identifiable, change the
shape — never the color.*

**Rationale.** Pillar 1 says class defines how an Operator plays, so a player
must know at a glance which rule set they face — and read range and threat before
checking the SP bar. Three technical choices support it:

- 3-head proportion, not 2, so limb length and reach stay legible.
- Chamfered rigid parts give hard-edged silhouettes and suit a solo pipeline.
- Consistent outline weight reinforces the silhouette; the outline must not merge
  with the dark arena.

VFX follow the same language: a Guard's slash is a blade arc, a Caster's burst is
a ring. Effects reinforce class identity instead of becoming generic glow.

**Fan-game originality.** The class-shape system is our own abstraction over
Operator concepts. Original models express these shapes through original
designs; a design that reads as a close copy of canon artwork is a risk and gets
redesigned. The oversized prop is the main lever for making each character
clearly ours.

#### Principle C — Controlled escalation (serves Pillar 2, protected by Pillar 3)

When a skill activates, that Operator's class color spreads into trails and the
screen border, then returns to neutral when the skill ends. Screen shake and
slow-motion affect the world layer only, never the HUD. In a burst the screen
gets louder only in the lane the player needs: whose skill, how long, where the
hits are.

**Design test:** *When a burst effect is ambiguous, choose the version that
leaves the opponent's HUD fully readable during it.*

**Rationale.** Pillar 2 wants Burst to feel explosive, with weight from speed,
hit-stop and sound rather than long recovery — so presentation carries most of
the feeling and effects must be strong. Pillar 3 says clear beats grand. The
resolution is a layering rule:

- The world layer may shake, slow, bloom and tint.
- The HUD layer is never shaken, slowed, tinted over or occluded.
- Escalation is reversible: color returns to neutral on skill end, so "colored"
  always means "active", never permanent decoration.

Slow-mo and hit-stop here are presentation; the simulation owns the real freeze
frames (see the concept's Technical Considerations), so this principle does not
constrain the sim.

### 1.3 Priority and conflict rules

- **HUD readability beats Pillar 4 and beats spectacle** (pillar order: Pillar 3
  beats Pillar 4 for HUD). Where Principle A or C would reduce HUD legibility,
  the HUD wins.
- **Presentation outside the HUD:** Pillar 4 leads (names, menus, language);
  Principle A applies freely there.
- **Counterplay floor:** no visual effect may hide information the player needs
  to Block, move or interrupt.
- **Originality is non-negotiable:** every asset is original or an explicit
  placeholder; no copied, traced or sampled Hypergryph/Yostar material.

### 1.4 Rulings recorded with this section (2026-11-01)

- **Vanguard vs danger red:** Vanguard's class color shifts to clear **orange**;
  red is reserved for danger and incoming damage only, and danger also carries a
  non-color cue.
- **Arena color:** arenas keep a **muted palette of their own (~30%
  desaturated) but never use class or state colors.** "The world is black,
  bronze, ivory" governs frames, HUD and neutral world elements, not a literal
  three-color arena.

**Carried to Section 4 (Color System):** a measurable saturation gap between
neutral bronze-gold, Guard amber and P2's copper frame; minimum hue separation
between Caster purple and Specialist pink-purple; and a non-color backup channel
for every HUD state (SP type, skill timer) for colorblind players.

## 2. Mood & Atmosphere

*Every state is built from the same small kit: the Section 1 neutrals, one arena
palette, and class color that appears only as gameplay state. States are told
apart by **light temperature, contrast, saturation budget and energy**, not by
new hues, so the mood system can never pollute the color-as-information rule.*

### 2.1 The saturation budget (the governing idea)

Each state gets a **saturation budget**: the share of the screen that may carry
class or state color. The budget rises with gameplay tension and peaks at the
Ultimate, so the player learns that "more color on screen" means "more is
happening right now". This is Principle C (Controlled escalation) spread across
the whole game, not just the burst.

| State | Energy (1–5) | Key temperature | Contrast | Saturation budget |
|---|---|---|---|---|
| Main menu / dossier | 1 | Cool, low-key | Medium | Bronze chrome only, plus one class tab on dossier |
| Character select | 3 | Neutral (~5000K feel) | Medium-high | All 8 class accents, small, as tabs |
| LAN lobby | 1–2 | Cool | Low | None except danger red on failure |
| Pre-round intro | 3 → 4 | Cool scan → arena key | Rising | Player frames only |
| Neutral combat | 3 | Arena's own key | Characters high, arena low | Class emblems and SP bars only |
| Skill-active window | 4 | Arena key + class-tinted edge | High | Owner's class color in trails, border, prop |
| Ultimate cinematic | 5 | Single class-colored key, near-black world | Maximum | Owner's class color owns the world layer |
| KO / round end | 5 → 1 | Ivory flash, then colorless | Spike, then flat | Zero (world goes monochrome) |
| Victory | 3–4 | Warm, low side light | Medium-high | Winner's class color as rim, bronze at area scale |
| Defeat | 1–2 | Cool, flat, overhead | Low | Zero |
| Pause / training | 1 | Neutral, flat | Low | Training overlays only |

### 2.2 Per-state targets

#### Main menu and dossier screens

- **Emotional target:** quiet competence. The player is a Doctor at a terminal
  late at night, reviewing files before an operation. Calm, not idle.
- **Lighting character:** cool, low-key, night interior. Light comes from
  screens, not a sun: monitor glow lights panels from the front and below;
  bronze-gold chrome catches a thin highlight on its top edges.
- **Descriptors:** archival, hushed, orderly, nocturnal, attentive.
- **Energy:** 1. Motion is limited to a cursor blink and the feed header typing
  in (≤ 300 ms). *(Amended by §7, 2026-11-01: the slow scanline drift is removed;
  scanlines follow §7.8.)*
- **Mood carrier:** the **operations-feed panel** — a graphite panel with
  bracket corners and a monospace header line that types itself in. On dossier
  screens the Operator model is lit like a file photo: one hard neutral key from
  45° above, a dark background, an ivory rim. The **class tab** is the only
  saturated element on screen.
- **Rationale:** Pillar 4's strongest moment. The menu has no gameplay to
  protect, so Principle A applies freely. Holding saturation near zero here makes
  the first burst of color at character select feel like information arriving.

#### Character select

- **Emotional target:** anticipation and choice — "who am I deploying?" The
  player should feel the eight classes as eight distinct rule sets.
- **Lighting character:** neutral, brighter than the menu, medium-high contrast.
  A clean studio light (~5000K feel) so every class color reads true. The hovered
  Operator gets a rim light in its class color; unhovered Operators are lit
  neutral.
- **Descriptors:** expectant, crisp, comparative, deliberate.
- **Energy:** 3. Hover and confirm get snappy feedback; the background stays
  still.
- **Mood carrier:** the **class roster strip** — the first screen where all
  eight class accents appear together, each small, as a tab beside its silhouette
  emblem, so this screen teaches the color-to-shape pairing. On confirm, a
  bracket snaps closed around the pick (P1 ivory, P2 copper).
- **Rationale:** Pillar 1. This is where class becomes identity, and the one
  place where showing every class color at once is the point.

#### LAN lobby

- **Emotional target:** procedural trust — "is the link up? are we ready?"
  Informed and unhurried, never anxious.
- **Lighting character:** cool, low contrast, flat. A comms room with no
  dramatic light.
- **Descriptors:** procedural, steady, transparent, terminal-like.
- **Energy:** 1–2. The only motion is a signal-status animation.
- **Mood carrier:** **signal-status brackets**. Connected peer: filled ivory
  bracket. Pending: hatched, animated bracket (horizontal hatch, not 45° — *amended by §7*).
  Failure: danger red **plus** a
  broken-bracket shape and a text label. No other color.
- **Rationale:** Pillar 3 applied to networking. Connection state must be
  readable without color, because this is where players troubleshoot.

#### Pre-round intro

- **Emotional target:** deployment tension. Two Operators are being placed on a
  field; something is about to start.
- **Lighting character:** a transition. Opens on a cool scanline wipe (the feed
  acquiring the arena), then settles into the arena's key light. Contrast rises
  as the wipe resolves.
- **Descriptors:** tightening, ceremonial, focused, primed.
- **Energy:** 3, rising to 4 at the round call.
- **Mood carrier:** the **deployment scan**. A horizontal scanline reveals the
  arena; each Operator materializes inside its player frame (P1 ivory brackets,
  P2 copper brackets, with side markers). The round call ("ROUND 1", then the go
  command) is ivory monospace in a chamfered plate.
- **Rationale:** Pillar 4 framing and Pillar 3. Each side's identity markers
  show before any action, so the player knows who is who before the first frame
  of play.

#### Neutral combat

- **Emotional target:** focused calm with live tension — spacing, reading,
  waiting for an opening. Chess played at speed.
- **Lighting character:** the arena's own key and fill (§4.6). Contrast is split
  by design: **characters carry the full value range; the arena is held to a
  compressed mid band**. The two characters are the sharpest, highest-contrast
  objects on screen.
- **Descriptors:** poised, legible, grounded, watchful.
- **Energy:** 3.
- **Mood carrier:** **the quiet arena** — desaturated, slightly soft, low-detail
  in the fight band; no bloom except on gameplay emissives. The only color is the
  class emblem on each Operator's prop and the two SP bars.
- **Rationale:** Pillar 3. Neutral is where reading the opponent matters most,
  so it holds the lowest in-match saturation budget; every later state gets
  louder against this baseline.

#### Skill-active window

- **Emotional target:** surge and pressure — "the clock is running." The owner
  feels power; the opponent feels a threat they can still answer.
- **Lighting character:** the arena key stays. The owner's class color enters as
  an **edge light**: a band along that player's side of the screen border, a
  class-colored rim on the owner, emissive bloom on the owner's prop and trails.
  High contrast.
- **Descriptors:** charged, urgent, directional, contestable.
- **Energy:** 4.
- **Mood carrier:** the **class-colored side border** plus the draining skill
  timer in the HUD. The border sits on the owner's side only (P1 left, P2 right),
  so it is a side cue as well as a mood cue. *(Amended by §7: width ≥ 24 px,
  steady, inside the HUD margin — see §7.2.)*
- **Rationale:** Principle C and Pillar 2. The burst feels explosive, and the
  color sits in lanes that tell the opponent whose skill it is, where the hits
  are and how long it lasts — serving the counterplay floor.
- **World tint (ruling 2026-11-01):** an optional owner-accent world tint is a
  Presentation & Feel tuning knob, **off by default**, at most 12% opacity,
  decided in playtest (§4.5). The side border carries the cue without it.
- **Edge case:** when both players have skills active at once, each side border
  carries its own color and **no world-wide tint is applied**, whatever the knob
  says. Two tints would mix into mud and blur ownership.

#### Ultimate cinematic (≤ 2.5 s, never covers the HUD)

- **Emotional target:** peak spectacle — a short, earned "this is my moment". A
  punctuation mark, not a cutscene.
- **Lighting character:** the world layer drops toward Ops Black. One hard key
  in the owner's class color from a low dramatic angle. The opponent stays
  visible, lit only by neutral fill. Maximum contrast.
- **Descriptors:** decisive, concentrated, theatrical, brief.
- **Energy:** 5.
- **Mood carrier:** a **class-shape title card** inside the world viewport
  (Caster: rune ring; Guard: blade arc; and so on). The world camera pushes in
  and vignettes to near black. **The HUD layer is not darkened, tinted, shaken or
  letterboxed, and no cinematic element overlaps the HUD safe zones.** No
  letterbox bars — they would compete with the HUD.
- **Rationale:** Pillar 2 is why it exists; the anti-pillar caps it at 2.5 s;
  Pillar 3 overrides its framing, so both HUDs stay fully readable.

#### KO / round end

- **Emotional target:** impact, then stillness. One frame of "it landed", then a
  held breath.
- **Lighting character:** an ivory flash on the final hit, timed with the sim's
  hit-stop; the world layer then **drains to full grayscale over ~0.3 s**. Light
  becomes flat and colorless. The KO'd character's black outline is kept so the
  silhouette of the fall stays legible.
- **Descriptors:** stark, suspended, final, quiet.
- **Energy:** spike to 5, then drop to 1.
- **Mood carrier:** the **monochrome freeze** and a "K.O." stamp — ivory,
  chamfered plate, bracket-framed.
- **Rationale:** draining to monochrome literally removes gameplay color because
  gameplay has stopped — Clause A of the one-line rule used as drama. Red is
  **not** used: a KO is a result, not incoming danger.

#### Victory

- **Emotional target:** earned pride, warm and generous. The winner is honored
  like an Operator after a successful operation.
- **Lighting character:** warm key from a low side angle (golden-hour
  direction), medium-high contrast. The warmest state in the game.
- **Descriptors:** proud, warm, commemorative, resolved.
- **Energy:** 3–4.
- **Mood carrier:** the winner's **dossier card sliding into the feed**.
  Bronze-gold chrome is used at area scale here — the only state where bronze
  leaves the edges. The winner gets a class-colored rim as information: who won,
  with what class.
- **Local versus:** both players share one screen. The loser's half gets the
  defeat treatment (desaturated portrait, cool flat light) at reduced size, so
  the screen honors one player without humiliating the other.

#### Defeat

- **Emotional target:** sober debrief, not punishment — "I can read what
  happened", and want to rematch. Pillar 3's learning loop.
- **Lighting character:** cool, flat, overhead, low contrast. The coolest and
  flattest state in the game.
- **Descriptors:** sober, analytical, respectful, open.
- **Energy:** 1–2.
- **Mood carrier:** a **debrief panel** in graphite and ivory: monospace stats,
  the rematch prompt given the most visual weight, and no red (red means danger,
  and defeat is not danger).
- **Rationale:** a defeat screen that shames the player fights the learning
  loop. Coolness and flatness say "the operation is over" without hostility.

#### Pause and training mode

- **Emotional target:** time held, inspection. Pause says "nothing is moving;
  take your time". Training says "this is a lab".
- **Lighting character:** neutral and flat. On pause the world freezes, darkens
  to ~40% value, desaturates by ~60% and gets a light scanline. **The HUD stays
  fully visible and undimmed**, so the game state is readable while paused.
  Training uses a dedicated neutral room: grid floor, flat ~5000K-feel light, the
  lowest atmosphere in the game.
- **Descriptors:** suspended, clinical, measurable, patient.
- **Energy:** 1.
- **Mood carrier:** for pause, the **frozen dimmed world** behind a chamfered
  menu plate; for training, the **diagnostic overlay layer** (rules in §4.8).

## 3. Shape Language

*Shape carries identity; color only confirms it (Section 1, Principle B). This
section defines the shape vocabulary for characters, effects, arena and UI, and
the hierarchy among them. The ruling that ties it together: **the eight class
primitives are reserved.** Each belongs to one class and appears at gameplay
scale only on that class's Operator and effects.*

### 3.1 Character silhouette philosophy

**The thumbnail test (mandatory).** Every Operator must pass it in its idle, a
light attack and its skill pose:

- At **64 px tall**, as a solid black fill with no interior detail, the class is
  identifiable.
- The **oversized class prop extends the silhouette's bounding box by at least
  25% on at least one axis** compared with the body alone. The prop is the
  silhouette key, so it must change the outline, not sit inside it.
- The silhouette contains **at least one class-specific negative-space shape**
  (a gap or hole that reads as the class). Negative space survives scaling better
  than interior detail.

**Proportion.** About 3 heads tall, per Section 1. The 3-head body leaves room
for readable limbs, so reach — the most important tactical fact in a fighter —
shows in the outline. A 2-head chibi hides arm length inside the head mass.

**Edges.** Chamfered rigid parts with 45° bevels at block corners. Hard planes
give the toon shader clean light/shadow breaks and the inverted-hull outline a
continuous contour. Avoid organic noise (fur, frills, loose cloth) that breaks
the outline into fragments at thumbnail size.

**Per-class distinguishing traits.**

| Class | Primary shape | Prop silhouette key | Stance / mass | Negative-space trait | Emotional read |
|---|---|---|---|---|---|
| Defender | Square block, wall | Tower shield, about body height, held forward | Wide, low, planted; mass in front | Rectangular notch between shield and body | Stability, defiance; "you go through me" |
| Guard | Blade arc | Long curved blade sweeping past the head line | Forward-weighted, coiled; an S-curve through the body | Crescent gap under the blade's curve | Momentum, mastery, the duel |
| Vanguard | Forward chevron | Spear or banner pole angled forward, leading the body | Leaning in; the silhouette points at the opponent | V-shaped gap between front leg and pole | Initiative, aggression, "first in" |
| Sniper | Long thin line, reticle | Bow or long rifle, longest horizontal line in the roster | Upright, narrow, side-on | Long slit between the line and the body | Distance, precision, patience |
| Caster | Circle, rune ring | Staff topped with a ring or orbiting circular focus | Centered, upright, symmetrical | Circular hole in the ring | Gathered power, mystery |
| Medic | Soft cross | Staff or device with a rounded cross head | Upright, open arms, gentle | Rounded cross gaps (corners filleted, never sharp) | Care, steadiness |
| Supporter | Hex lattice | Hex-paneled device or banner, a flat plane of cells | Balanced, slightly back-weighted | Hex cut-outs in the prop plane | Structure, network, control |
| Specialist | Hook, diagonal zigzag | Hook, chain-blade or grapnel with a diagonal break | Asymmetric, twisted, off-balance on purpose | Hook-shaped gap; a zigzag in the outline | Unpredictability, trickery |

**Pillar link:** Pillar 1 (Class Is Identity). Each class is told apart three
ways — shape, stance, negative space — before color is involved. The "emotional
read" column matters because the opponent should *feel* the rule set they face:
you play around a square differently than around a hook.

**Original-design note:** these traits are shape abstractions, not canon
character designs. Each Operator expresses them through its own prop and costume
(Section 5 owns that).

### 3.2 Effects follow the owner's class shape

VFX use the **owner's class primitive**: a Guard slash is a blade arc, a Defender
block flash is a rectangular wall, a Caster burst is a ring, a Specialist trail
zigzags. Generic radial glow is not allowed as a primary effect shape.

- **Hit trails show the move's true range.** A trail's extent matches the hitbox
  reach to within the outline width at default camera distance. An effect that
  looks longer than the hit misleads the counterplay floor.
- **Hit sparks** are the one shared effect shape: a short ivory four-point flash
  at the contact point. Contact is the same information for every class, so it
  uses one shape and one color (§4.4).
- **Four-point spark geometry (binding; the hit spark and the Offensive SP icon):**
  pointed tips (≤ 30° tip angle), **concave sides** curving in between the tips, a
  center no wider than ⅓ of the tip-to-tip span, and **never filleted or
  rounded**. It is drawn **rotated 45° (an X)**, so its arms never sit on the
  vertical/horizontal axes of the Medic soft cross. A shape with straight parallel
  arms, blunt ends or soft corners is a cross and is not allowed.

**Pillar link:** Pillars 1 and 3. Effects add a second class signal exactly where
the player is looking, so even a glance at a burst tells the opponent which rule
set fired it.

### 3.3 Environment geometry

The arena is the **quietest shape layer**: it holds the floor line, sets place,
then gets out of the way.

- **Horizontal emphasis.** Long, low planes, platforms and rails. The fight reads
  along one horizontal lane, and horizontal masses reinforce it.
- **Large masses, low frequency.** Big chamfered blocks with 45° bevels, in the
  same family as characters and UI, at **lower detail density**: no repeated
  detail smaller than one character head width within the fight band.
- **The fight band.** From the floor line to **1.5 character heights**, across
  the full playable width, background geometry stays low-contrast and low-detail.
  Taller or busier elements (towers, skyline, machinery) belong above the band or
  outside the playable width.
- **The floor line** is always a clear, unbroken value edge; the player reads
  airborne state and jumps against it.
- **No class primitives as dominant arena forms.** An arena may not use rings,
  hex lattices, crosses, chevron rows or hooks as large, repeated or focal
  features. A giant hex wall reads as "Supporter" in a black-and-white screenshot
  and breaks the silhouette doctrine. Incidental geometry (a round bolt head) is
  fine; motifs are not.

**Pillar link:** Pillar 3, bounded by Pillar 4. Rhodes Island military-industrial
architecture is the vocabulary (Pillar 4), but the fight band and the primitive
ban keep it from competing with the characters (Pillar 3, Principle A's design
test). Horizontal low masses read as solid ground, which gives the characters'
sharper, more diagonal shapes room to look dynamic.

### 3.4 UI shape grammar

**Ruling: the UI shares the world's edge family but has its own flat language.**
The 45° chamfer is the shared gene — characters, arena blocks and UI plates all
bevel at 45° — so the game reads as one design. Otherwise the UI is flat 2D: no
lighting, no outline shader, no perspective.

| Element | Shape | Used for | Rationale |
|---|---|---|---|
| Container | 45° chamfered rectangle (one or two opposite corners cut) | Panels, plates, gauges, buttons | The dossier signature (Pillar 4); a chamfer also points the eye along a gauge |
| Frame | Bracket corners (L-shaped, open sides) | Player frames, selection, focus | An open bracket "targets" without boxing; reads tactical |
| Divider | Thin ruled line with a small end tick | Separating data rows | Monospace-document feel |
| Warning | Hazard stripe at 45° | Danger only (§4.4) | Stripes are the non-color half of danger |
| Navigation | Chevron | Menu arrows, page turns | Menus only (quarantine below) |
| Data cell | Hex cell | Menu and dossier decoration, stat grids | Menus only (quarantine below) |

**The HUD class-primitive quarantine.** The concept lists chevrons and hex cells
as UI vocabulary, but chevron is Vanguard's primitive and hex is Supporter's. To
keep the silhouette doctrine intact during combat:

- **In menus and dossier screens**, chevrons and hex cells may be used freely as
  chrome; there is no live gameplay to confuse. **Exception — character select**
  *(amended by §7, 2026-11-01)*: that screen teaches the color-to-shape pairing,
  so it follows the HUD quarantine — class primitives only as class emblems;
  paging uses plain solid triangles or brackets.
- **In the combat HUD**, class primitives appear **only as each player's own
  class emblem**. Gauges, frames and timers use chamfered rectangles, brackets and
  ruled lines only: no circular gauges (Caster), no plus/cross shapes (Medic), no
  hex-segmented bars (Supporter), no chevron fill marks (Vanguard).

**SP type icons** come from a separate, non-class vocabulary so they never read
as a class (§4.9): an hourglass, a four-point impact spark (§3.2 geometry:
pointed, concave, 45°-rotated, never filleted — never a cross), and a notched
"incoming" bar.

**Pillar link:** Pillar 4 leads in menus; Pillar 3 wins in the HUD (Section 1.3).
The chamfered, bracketed UI reads as competent, military and precise; the
quarantine keeps that precision from turning into ambiguity.

### 3.5 Hero versus supporting shapes (the shape hierarchy)

| Rank | Layer | Edge quality | Contrast | Detail | Outline |
|---|---|---|---|---|---|
| 1 | **Operators** | Hardest, chamfered | Full value range | Medium, concentrated on the prop | Black inverted-hull, target 2–3 px at 1080p default camera |
| 2 | **Gameplay VFX** | Crisp class primitives | High, may bloom | Low, simple shapes | None (additive or emissive) |
| 3 | **HUD** | Crisp flat vector | High against its backplate | Minimal | Flat strokes |
| 4 | **Arena** | Chamfered, softened by slight blur and haze | Compressed mid band | Lowest in the fight band | None, or a lighter outline that never matches the character outline |

**Rule:** a lower rank may never out-contrast or out-detail a higher rank where
they overlap. Ranks 1 and 3 rarely collide — the HUD lives in the screen-edge
safe zones, characters in the fight band. If they overlap (a character jumps
under a HUD plate), the HUD wins for legibility, per Section 1.3.

**Pillar link:** Pillar 3. The hierarchy fixes the reading order: who and where
(Operators), what is happening (VFX), the numbers (HUD), the place (arena).

## 4. Color System

*Color is information (Section 1.1). This section gives every color a job, a hex
value and a measurable boundary against its neighbors, and resolves the three
items carried over from Section 1.4.*

**Measurement convention.** Hue (H, degrees), saturation (S, %) and value (V, %)
are **HSV computed directly from the hex**, so anyone can check them exactly.
Luminance (L) is WCAG relative luminance. Contrast ratios are WCAG against the
HUD backplate Graphite #2B2D30 (L ≈ 0.026). All HSV, L and contrast figures in
this section were script-verified on 2026-11-01. Perceptual (OKLCH) checks are
listed in §4.10 for the technical-artist to verify with a tool.

### 4.1 Primary palette (neutrals and semantic anchors)

| # | Name | Hex | H / S / V | Contrast on Graphite | Role |
|---|---|---|---|---|---|
| 1 | **Ops Black** | #121212 | — / 0 / 7 | — | World base, character outline, Ultimate world drop, deepest UI |
| 2 | **Graphite** | #2B2D30 | 216 / 10 / 19 | — | HUD and menu plates. *Amended by §7:* information plates, gauge wells and the strip under frame strokes are **opaque**; 85% opacity only for decorative chrome |
| 3 | **Steel Grey** | #6E7378 | 210 / 8 / 47 | 2.9 : 1 | Inactive/disabled UI, dividers, decorative labels. **Never readable text** |
| 4 | **Light Steel** | #9A9FA4 | 210 / 6 / 64 | 5.2 : 1 | Secondary readable text, including secondary gameplay text |
| 5 | **Ivory** | #EDE6D6 | 42 / 10 / 93 | 11.1 : 1 | Primary text, P1 frame, hit-spark core, "ready" and confirmation |
| 6 | **Bronze-Gold** | #A69468 | 43 / 37 / 65 | 4.6 : 1 | Rhodes Island chrome: menu headings, bracket trim, round-timer frame. **Never information** |
| 7 | **P2 Copper** | #A8673F | 23 / 62 / 66 | 3.1 : 1 | P2 frame and P2 side marker **only** |
| 8 | **Danger Red** | #E8283A | 354 / 83 / 91 | 3.2 : 1 | Danger and incoming damage **only** (§4.4) |

Ops Black, Graphite, the two greys, Ivory and Bronze-Gold are the "black,
bronze-gold, ivory-white" world of the one-line rule (Light Steel added
2026-11-01 because Steel Grey fails 4.5 : 1 for text). Copper and red are
semantic colors placed in the primary palette because they are constant across
every state and every Operator.

### 4.2 Class accent colors

| Class | Name | Hex | H / S / V | L | Contrast on Graphite | Primitive (backup) |
|---|---|---|---|---|---|---|
| Vanguard | Clear Orange | #FF8A1F | 29 / 88 / 100 | 0.395 | 5.9 : 1 | Forward chevron |
| Guard | Amber | #FFC61A | 45 / 90 / 100 | 0.617 | 8.8 : 1 | Blade arc |
| Defender | Steel Blue | #5A83B8 | 214 / 51 / 72 | 0.219 | 3.5 : 1 | Square block |
| Sniper | Green | #5CC24A | 111 / 62 / 76 | 0.414 | 6.1 : 1 | Long line, reticle |
| Caster | Violet | #9257FF | 261 / 66 / 100 | 0.201 | 3.3 : 1 | Ring |
| Medic | Pale Blue | #8FD6F0 | 196 / 40 / 94 | 0.602 | 8.6 : 1 | Soft cross |
| Supporter | Teal | #1FB5A6 | 174 / 83 / 71 | 0.361 | 5.4 : 1 | Hex lattice |
| Specialist | Orchid | #F06ED6 | 312 / 54 / 94 | 0.345 | 5.2 : 1 | Hook, zigzag |

**Floor rule:** every class accent must reach at least **3 : 1** against Graphite
(the WCAG non-text minimum), because it is used on SP bars and timers. Caster
(3.3 : 1) and Defender (3.5 : 1) sit nearest the floor; any retune of those two
must be re-checked.

**Where class color may appear:** SP bar fill, skill-active aura and trails,
impact flashes of that Operator's moves, the owner's side border during a skill,
the Ultimate key light, the class tab and emblem in menus, and a small emblem
area on the Operator's prop (Section 5 sets the area limit; recommended ≤ ~10% of
the silhouette, non-emissive outside skills). **Nowhere else.**

**Vanguard:** per the Section 1.4 ruling, Vanguard is clear orange at H 29°,
**35° from Danger Red (H 354°)**. Red also always carries a non-color cue (§4.4).
Guard amber sits at H 45°, nudged toward yellow so it stays 16° from Vanguard.

### 4.3 Carried item 1: bronze-gold vs Guard amber vs P2 copper

All three are warm metal-yellows and can share a screen (a P2 Guard has a copper
frame and an amber SP bar inside a HUD with bronze timer trim). They are
separated on **three axes at once**:

| | Bronze-Gold (neutral) | P2 Copper (side) | Guard Amber (class) |
|---|---|---|---|
| Hex | #A69468 | #A8673F | #FFC61A |
| H | 43° | 23° | 45° |
| S | 37% | 62% | 90% |
| V | 65% | 66% | 100% |

**Binding tolerance bands** (for future retunes, not just these hexes):

- **Bronze-Gold:** S ≤ 40%, V ≤ 70%, H 38–48°.
- **P2 Copper:** S 55–65%, V 60–70%, H 18–26°.
- **Guard Amber:** S ≥ 85%, V ≥ 95%, H 42–48°.

**Minimum gaps:**

- Bronze → Copper: ≥ **20 S-points** (now 25) **and** ≥ **15° hue** (now 20°).
- Copper → Amber: ≥ **20 S-points** (now 28) **and** ≥ **25 V-points** (now 34).
- Bronze → Amber: ≥ **45 S-points** (now 53) **and** ≥ **30 V-points** (now 35).
  They share a hue on purpose — amber reads as "bronze turned on", which suits a
  class whose identity is blade mastery; the S and V gap keeps it unmistakably
  information.

**Adjacency rule:** bronze-gold never directly touches a class-colored gauge; a
Graphite gap of at least 2 px at 1080p separates them.

**Copper vs Vanguard orange** (the other risky pair, in a P2 Vanguard mirror): H
23° vs 29° is close, but S 62 vs 88 and V 66 vs 100 separate them. More
importantly, copper only ever appears as a **frame stroke and side marker**,
never a fill, while class color only ever appears as a **fill**. They are
separated by shape role.

### 4.4 Semantic color usage

| Color | Meaning in this world | Why | Non-color partner |
|---|---|---|---|
| **Danger Red** #E8283A | Incoming harm only: recent-damage chip on the HP bar, unblockable or throw warnings, critical lobby/system warnings | The most urgent warm signal culturally and physiologically; single-purpose means it never has to be interpreted | 45° hazard stripe pattern, a pulse cadence (smooth 2 Hz opacity 100% → 40%, never steady, never a hard on-off strobe — *amended by §7*), and an audio cue (requested from audio-director) |
| **Ivory** #EDE6D6 | Neutral truth: text, P1, contact, readiness — HP fill, hit-spark core, the "SKILL READY" label, the full Ultimate gauge flare | The brightest neutral; white-hot reads as "contact" and "confirmed" without belonging to any class | Text labels, bracket animation, spark shape |
| **Bronze-Gold** #A69468 | Rhodes Island itself: the institution, the frame around the game | Dresses the world (Pillar 4) but carries no gameplay meaning, so it can decorate without lying | — (decorative by definition) |
| **P2 Copper** #A8673F | "This is Player 2" | A warm metal beside ivory as its natural pair: polished vs oxidized | Frame shape and side marker (§4.7) |
| **Class accents** | "This class's rule set is active or shown here" | One color per class, constant everywhere | Class primitive (shape) and emblem |
| **Blue (generic)** | **No generic meaning** — blue belongs to Defender, Medic and Supporter | A generic "info/selection blue" would collide with three classes; menu focus uses ivory brackets | — |
| **Gold (generic)** | **No generic "gold = special" meaning** | Would collide with Guard amber and bronze chrome | — |
| **Green (generic)** | **No "green = good" meaning**, even in the lobby | Would collide with Sniper; "connected" uses a filled ivory bracket | Bracket fill state |

### 4.5 Per-state color behavior (ties to Section 2)

- **Menus, lobby, defeat:** Graphite, Ivory, the greys and Bronze, plus Danger
  Red only on failure. A dossier shows one class accent, as a tab.
- **Character select:** all eight accents at tab scale, each paired with its
  emblem.
- **Neutral combat:** class accents only on SP bars and prop emblems.
- **Skill-active:** the owner's accent spreads to side border, rim light, trails
  and prop emissive. A world tint in the owner's accent is a **Presentation & Feel
  tuning knob, off by default** (range 0–12% opacity), decided in playtest. When
  on, it applies only while exactly one skill is active and reverts on skill end
  (§2.2).
- **Ultimate:** the world drops ~85% toward Ops Black; the owner's accent is the
  key light; the HUD is not touched.
- **KO:** world goes to 0% saturation; the HUD keeps its colors (state is still
  state). The one HUD change is the KO'd player's portrait going grayscale, as a
  state signal (§7.3).
- **Victory:** Bronze at area scale; the winner's accent as rim.

### 4.6 Arena color and temperature rules

Section 1.4 ruled that arenas keep their own muted palette (~30% desaturated) and
never use class or state colors. The measurable versions:

1. **Saturation ceiling:** no arena surface larger than 2% of the screen exceeds
   **S 35%**.
2. **Class-hue exclusion:** within **±15° of any class accent hue or Danger Red's
   hue**, arena surfaces are capped at **S 25%**. With the current accents, the
   free bands where arenas may reach S 35% are about 9–14°, 60–96°, 126–159°,
   229–246°, 276–297° and 327–339°. Warm browns and cool steels remain available
   at S ≤ 25%, reading as "warm" or "cool" without competing with any class.
3. **Value band:** arena surfaces behind the fight band stay within **V 20–60%**.
   The floor keeps the Ops Black outline (V 7%) separated from the background
   (Section 1: the outline must not merge with the dark arena); the ceiling keeps
   Ivory highlights and class accents the brightest things in the fight band.
4. **Only gameplay blooms.** Arena materials have no emissive above the bloom
   threshold. Lamps, screens and signs read as lit through value and soft glow
   sprites, not engine bloom.
5. **One temperature per arena.** Each arena declares **warm key / cool fill** or
   **cool key / warm fill** — never mixed keys.
6. **Operator light is arena-independent.** The ivory rim light on Operators is
   identical in every arena; arena fill may tint the toon shadow band by **≤ 15%**.
   An Operator must look like itself everywhere so the learned read carries over.

**Temperature and class contrast:** in warm-key arenas, orange, amber and green
stand out less against ambient light, so warm-class silhouettes lean on the ivory
rim; in cool-key arenas the same is true for blue, teal and violet. Rule 6 covers
both cases.

### 4.7 P1 / P2 distinction (not by color)

| Channel | P1 | P2 |
|---|---|---|
| Screen side (HUD) | Left | Right |
| Frame stroke | Ivory #EDE6D6, **solid single** bracket | Copper #A8673F, **double-line** bracket (two parallel strokes) |
| Overhead side marker | Solid down-pointing triangle with "1P" | Hollow rhombus with "2P" |
| Skill side border | Left screen edge | Right screen edge |

*Amended by §7:* HUD frame strokes are **≥ 3 px** at 1080p, and the two lines of
P2's double bracket have a **≥ 3 px gap**, so the single/double distinction
survives downscaling to 720p.

Stroke style, marker shape and side all differ independently of color. A mirror
match (same Operator, same class color) stays readable: bars on opposite sides,
frames differ by shape, overhead markers differ by shape. Color adds only a
fourth confirming channel.

### 4.8 UI palette and where it diverges from the world

- **The HUD uses full-strength accents.** The world palette is desaturated, but
  HUD class colors are never desaturated, never tinted by escalation and never
  dimmed by pause or KO. The HUD is the reference; everything else moves around
  it.
- **Menus use Bronze freely.** The HUD uses Bronze only on the round-timer frame,
  never adjacent to a gauge.
- **Text:** Ivory on Graphite (11.1 : 1) for primary text; **Light Steel on
  Graphite (5.2 : 1) for secondary text**, including secondary gameplay text.
  Steel Grey (2.9 : 1) is for disabled states, dividers and decorative labels
  only, **never for readable text or gameplay numbers**.
- **Training overlays** (a diagnostic layer, not world): hitboxes in Danger Red
  at 40% fill with a solid stroke (an active hitbox is danger), hurtboxes as an
  Ivory hollow outline, throwboxes as an **Ivory dot grid** *(amended by §7: 45°
  hatching is danger-only)* — distinguished by fill pattern, not hue.

### 4.9 Carried item 3: non-color backup for every HUD state

| HUD state | Color channel | Non-color backup (mandatory) |
|---|---|---|
| Class of each player | Class accent on the SP bar | Class emblem (primitive) beside the portrait |
| **SP type: Auto** (time-based) | — (all SP types use the class accent fill) | **Hourglass icon**; **smooth continuous** fill |
| **SP type: Offensive** (on hit dealt) | — | **Four-point impact-spark icon**; **stepped segment** fill that jumps on each hit |
| **SP type: Defensive** (on hit taken) | — | **Notched "incoming" bar icon**; **vertical notch ticks** fill texture (*amended by §7*: 45° hatching is reserved for danger — hazard stripes and the damage chip) |
| SP full, skill ready | Bar brightens | "READY" label in Ivory; brackets snap around the bar |
| **Skill timer** | Draining bar in class accent | **Numeric countdown** in monospace (whole seconds, from sim ticks); bar drains toward the portrait; the side border's presence shows the skill is active; last 2 s: status-plate bracket pulses at 2 Hz (§7.6) |
| Ultimate gauge | Ivory fill | Segment count; "full" shows a bracket animation plus a text label |
| Recent damage | Danger Red chip | Chip drains with a visible delay; hazard-hatch texture on the chip |
| Danger warning | Danger Red | Hazard stripes, pulse cadence, audio cue (requested from audio-director) |
| P1 / P2 | Ivory / Copper | Frame stroke style, side, marker shape (§4.7) |

**Rule:** SP type is never encoded by color — all three types share the owner's
class accent; icon and fill texture carry it entirely. A grayscale screenshot of
the HUD must show every state in this table.

### 4.10 Carried item 2 and colorblind safety

**Caster vs Specialist (carried item 2):**

- Caster Violet: H 261°, L 0.201. Specialist Orchid: H 312°, L 0.345.
- **Binding minimum: ≥ 40° HSV hue separation (now 51°) and a luminance ratio
  ≥ 1.4 : 1 (now 1.57 : 1).**
- The luminance gap matters because tritan vision collapses these hues. Caster is
  darker and Specialist lighter in grayscale — a separation that survives every
  form of color vision deficiency.
- OKLCH hue separation should be ≥ 35° (to be verified with a tool).

**Expected confusion pairs.** From standard dichromacy models. Only two Operators
are ever on screen at once, so the worst case is one pair plus Danger Red. Every
pair must be confirmed by running real in-engine screenshots through a simulator.

| Deficiency | Likely confusion pairs | Backup that resolves it |
|---|---|---|
| **Protan** (red-weak) | Vanguard / Guard / Sniper (orange, amber, green collapse to yellow-olive); Danger Red / Vanguard (red darkens); Caster / Defender (violet goes blue) | Chevron / arc / line silhouettes; hazard stripes and pulse on danger; ring / block silhouettes |
| **Deutan** (green-weak) | Vanguard / Sniper / Guard; Danger Red / Vanguard orange; Supporter teal / Medic / Steel Grey; Specialist / Medic | Silhouettes and emblems; danger stripes and pulse; hex vs soft cross vs block emblems |
| **Tritan** (blue-weak) | Caster / Specialist; Supporter / Sniper; Defender / Supporter / Medic; Guard amber / Ivory and Specialist | Ring vs hook silhouettes plus the luminance gap; hex vs line; the cool-trio luminance ladder; Guard bars always carry the class emblem, and Ivory is never a fill on SP bars |

**Cool-trio ladder (binding):** Defender, Supporter and Medic sit within 40° of
hue, so they must keep **adjacent luminance ratios ≥ 1.4 : 1**, ordered Defender
darkest, Medic lightest. Defender → Supporter is 1.53 : 1; Supporter → Medic is
1.59 : 1.

**OKLCH and simulator checks for technical-artist** (not yet computed):

- Chroma order Bronze < Copper < Amber, with steps ≥ 0.04.
- Caster → Specialist hue gap ≥ 35°.
- All eight accents distinct under Color Oracle (or equivalent) at protan, deutan
  and tritan settings, with the backups above.

## 5. Character Design Direction

*Every Operator is playable; there is no single hero. This section defines the
shared archetype all Operators are built on, how two fighters stay distinct on
screen (including mirror matches), how pose and face carry expression on
rigid-part models, how much detail survives at the fighting camera, and how
canon Operators become original designs that are recognisable but not copies.
Sections 1–4 are binding here.*

### 5.1 The Operator archetype

**"A deployed Operator in field kit."** Every Operator is drawn as a specialist
who has just arrived for an operation: equipped, ready to move, carrying one
oversized tool of their trade. Nobody is shown in casual dress or at rest. This
reads as a Rhodes Island personnel file (Pillar 4) and gives every design the
same base before class and character set it apart.

**The shared body template:**

| Part | Rule |
|---|---|
| Proportion | About 3 heads tall (Section 1). The head is the single largest block. Torso and legs together make up about 2 heads, with legs long enough that the gap between the feet shows stance width. |
| Construction | Chamfered rigid blocks with 45° bevels at the corners (§3.1). No skinning. Each limb segment is one rigid part. |
| Joints | The pivot sits inside the parent block and the child part overlaps it (a sleeve over the forearm, a boot cuff over the shin), so a rotation of up to ~90° never opens a visible gap. Exposed ball joints are not allowed — they read as a toy or a robot. |
| Hands | A simplified mitten block plus a separate thumb block. Two or three hand poses per Operator (grip, open, fist), swapped as parts, never deformed. |
| Feet | Heavy, slightly oversized boot blocks. They anchor the figure to the floor line (§3.3); the player reads airborne state from the gap under them. |
| Hair and cloth | A few large rigid clumps per mass: 3–6 for hair, 2–3 hinged plates for a coat tail or cape. No strands, frills or fur (§3.1). |
| Prop | One oversized class prop — the silhouette key (25% bounding-box rule, §3.1). Any secondary item (a sheathed sidearm, a pouch) must sit inside the body silhouette. |

**Shared rig.** One rig is shared by all Operators. The template above is that
rig's art contract: every Operator's parts attach to the same joint hierarchy.
Silhouette differences come from part shape and prop, not a different skeleton.
Any exception (a tail, ears, an extra prop joint) is an added child node, never a
reworked hierarchy.

**Pillar link:** Pillars 1–3. One shared template makes class differences the
only differences that matter, so the eye learns that a change in outline means a
change in rule set.

### 5.2 Costume palette and value structure (the legibility contract with the arena)

Characters are rank 1 in the shape hierarchy (§3.5). They win against the arena
through **value and outline, not saturation**. Clause A still holds: costume is
not gameplay information, so costume is muted.

1. **Saturation.** Any costume, hair or skin mass covering more than 5% of the
   silhouette stays at **S ≤ 35%**, and **S ≤ 25%** within ±15° of any class
   accent hue or Danger Red's hue (the same bands as §4.6). Small details (eyes,
   piping, buckles) may reach **S ≤ 50%**, outside those bands only.
2. **Class accent appears only in the emblem area** (§4.2). Hair, eyes and trim
   are never the Operator's own class color — a violet-eyed Caster would turn its
   face into a state signal.
3. **Reserved hues stay reserved.** No costume trim may read as a P2 Copper
   stroke (H 18–26° above S 25% in a line-like shape), and no costume mass falls
   in Danger Red's band above S 25%.
4. **Three-mass value plan.** Each Operator is designed as one dark, one mid and
   one light mass. The face/head region is the lightest large area, so the eye
   lands on the face and the prop first.
5. **Value bracketing against the arena (binding).** At least **60% of the
   silhouette's area lies outside V 20–60%** — darker or lighter than the band
   arenas are held to (§4.6.3). A character built mostly in the arena's band
   would rely on the outline alone. This rule guarantees characters read against
   the texture density Section 6 defines.
   **Dark-mass floor (ruling 2026-11-01):** dark masses stay at **V ≥ 14** in the
   lit toon band and **V ≥ 11** in the shadow band, at least 7 V-points above the
   Ops Black outline (V 7). This keeps per-part joint lines visible on dark coats
   such as Ch'en's. The dark side of the bracket is therefore V 14–19; bracketing
   that cannot fit there goes to the light side (V > 60).
6. **No readable text on character models.** Glyph-like marks only. Text breaks
   when the model is mirrored for facing (§5.5), and canon lettering is an
   originality risk.

### 5.3 Telling the two fighters apart

There are no NPCs in a match. Exactly two Operators share the fight band, so
every rule here covers one case: two silhouettes, one glance.

**Different classes:** already solved by §3.1 — shape, stance and negative space,
then color.

**Same class, different Operators** (Ch'en and Surtr are both Guards). They share
the blade-arc primitive and must still read as different people:

- They must differ on **at least two of** four axes: prop length and grip
  (one-hand / two-hand), stance height (low and coiled / tall and upright), head
  silhouette (horns, ears, hood, hair mass), and mass distribution (front-heavy /
  back-heavy).
- **Test:** both idle silhouettes side by side at 64 px. A player who knows both
  names each correctly every time. If the only difference is interior detail, the
  test fails and the shape changes.

**Mirror match (same Operator on both sides).** §4.7 already gives four
color-independent channels (HUD side, frame stroke, overhead marker, skill border
side). The costume adds one more, in the world itself:

- **Ruling (2026-11-01): the P2 alternate costume swaps costume neutral values.**
  The dark and light masses trade places (a dark coat becomes light; light trim
  becomes dark). Hue moves only within the §5.2 limits.
- **Never changes:** class accent, emblem, prop shape, silhouette, face decals,
  skin and hair. Those carry class and identity, and §4.6.6 requires an Operator
  to look like itself everywhere.
- **Why values, not hues:** a value swap survives a grayscale screenshot and
  every form of color vision deficiency. A hue shift of muted neutrals at
  S ≤ 35% is nearly invisible in grayscale — exactly the condition the silhouette
  doctrine tests against.
- The alternate must still pass §5.2 rule 5 and must not use copper on the
  costume (copper stays a frame signal only).
- **Assignment (Tier 0):** P2 gets the alternate automatically, only in a mirror
  match. Player-chosen costumes are a later feature.

**Training dummy (training mode).** The one non-Operator figure: built from the
shared template in Steel-Grey-family values (V 40–55, S ≤ 10%), with a flat,
featureless face plate, **no prop, no emblem and no class primitive** — it fails
the thumbnail test on purpose. When training uses an Operator as the opponent,
that Operator appears in its P2 alternate costume.

**Pillar link:** Pillar 3. Ownership is never in doubt, and the costume channel
doubles the grayscale signal without spending any color budget.

### 5.4 Expression and pose style

**Target: exaggerated poses, snappy timing, a restrained face.** Rigid parts
cannot squash, stretch or deform, so expression lives in three places, in order:
**pose → prop → face decal**. The style is closer to stop-motion figure animation
than smooth deforming animation: held key poses and fast transitions. Stiff
in-betweens are accepted as long as the keys are clear.

**Pose rules:**

1. **Line of action.** Every key pose has one clear line of action through the
   body and into the prop. The class stance from §3.1 is the default line; each
   Operator's personality bends it.
2. **The pose tells the truth about the hitbox.** On active frames the attacking
   limb or prop points along the hitbox direction and reaches its extent (matches
   §3.2's true-range trails). Animation is presentation only, but must never
   contradict the data.
3. **Anticipation shows early.** The wind-up key (prop drawn back, weight
   shifted) appears no later than the second frame of startup. The counterplay
   floor depends on reacting to that shape change.
4. **Block and hit are opposites in silhouette.** Block is compact — prop or arms
   forward, head down behind them. Hitstun is open — head thrown back, limbs flung
   away from the hit. "Blocked" vs "got hit" must be tellable in a black-and-white
   thumbnail.
5. **Secondary motion never fakes reach.** Hair, tails and coat plates may swing
   but never extend forward of the leading edge of the active hitbox.
6. **No mesh scaling for impact.** Smears and impact stretch come from VFX trails
   (§3.2), not part scaling, so the silhouette always matches the body's true
   volume.
7. **Personality goes into the neutral beats.** Idle, walk, round-start and
   victory carry character (Ch'en's impatience, Amiya's composure). Attacks
   follow the class stance; idles follow the person.

**Face decals.** A flat, swappable texture set on the face plate, swapped on
animation keys. No lip sync, no blend shapes. Tier 0 set per Operator: **neutral,
focused (combat default), attack shout, hurt, KO, victory, blink** (7 states).

- Shapes are simple and bold: eyes use 2–3 values and no detail below the §5.5
  minimum feature size at the default camera.
- Close-up states (victory, Ultimate cut-in, dossier) may use a richer variant of
  the same decal.
- Faces are drawn in our own eye and mouth style, not modelled on canon portrait
  art (§5.6).

**Pillar link:** Pillar 2 (speed beats weight; weight comes from hit-stop and
sound, which suits a held-pose style) and Pillar 3 (pose rules 2–5 serve the
counterplay floor).

### 5.5 Camera, facing and detail levels (LOD philosophy)

**Default framing (art target, to be confirmed by the camera GDD).** A 2.5D side
view with a long-lens perspective camera to keep distortion low:

- Each character is about **300 ± 40 px tall at 1080p** at mid range, and **no
  smaller than ~220 px** at the widest zoom-out.
- Models are turned about **20–30° toward the camera**, so face, chest and the
  prop's emblem face stay visible and the figure never reads as a flat profile.

**No geometric LOD meshes.** At most two characters are on screen, always near
the camera, so one mesh set per Operator is enough. *(Amended by §8: "one mesh"
means one `.glb` scene with one rigid part per pivot and no LOD variants — §8.4.)* "LOD" here means *which detail is
authored for which viewing distance*:

| Tier | Viewing distance | What must read | Where it lives |
|---|---|---|---|
| **L0: Silhouette** | 64 px (the thumbnail test) | Class, stance, negative-space trait, prop | Geometry outline |
| **L1: Fight** | Default camera, ~220–340 px | The three value masses, face decal, emblem, the prop's main sub-shapes, joint breaks | Geometry plus flat palette color |
| **L2: Close-up** | Ultimate push-in, victory, dossier (~2–3× larger) | Trim lines, small decals, insignia-free badges, richer face decals, painted edge wear | Texture only, never geometry |

- **Minimum feature size at L1:** no shape or color break smaller than **~6 px at
  1080p** (~2% of character height) on the body; face decals are the one
  exception. Anything smaller is L2 detail and must be texture, so it disappears
  cleanly at fight distance instead of becoming noise.
- The outline stays 2–3 px at all tiers (§3.5). Interior lines are not drawn as
  outlines, only as the toon shadow break — *except (amended by §8):* the per-part
  inverted hull also draws a line where one part overlaps another, and those
  part-contour lines are accepted as joint breaks (§8.9).

**Facing — ruling (2026-11-01): mirror the model** (scale −1 on the facing
axis), so the prop always leads toward the opponent. Every Operator is designed
**facing-agnostic**: no readable text, asymmetry that still reads when mirrored,
emblem visible from either side. *Technical-artist to confirm implementation
(outline and lighting under negative scale).*

**The emblem on the prop:**

- **Size:** **2% to 10% of the silhouette area at the default camera.** The 10%
  ceiling keeps class color within the §2.1 neutral-combat budget; the 2% floor
  (~16 px across at 300 px height) is the smallest size at which the primitive
  still reads as its class.
- **Placement:** one placement per Operator, on the prop, visible from both
  facings — a two-sided plate or an edge-on face, never hidden behind the body.
- **Emission:** non-emissive outside skills (flat accent, no bloom). During the
  skill-active window and the Ultimate it goes emissive and may bloom, because it
  is then gameplay state (§2.2, §4.5).

### 5.6 Original designs of canon Operators: recognisable, not copied

**Method: anchors from the text, artwork from us.**

1. **Write the anchor list from a written description, not a picture.** At most
   **three recognition anchors** per Operator, at concept level (species trait,
   signature weapon type, hair color family, role) — e.g. "dragon horns and tail;
   a sword; a city-police officer". An idea is not artwork.
2. **Translate each anchor into our grammar:** the 3-head template, chamfered
   blocks, the class primitive, the §5.2 palette. The anchor survives; its canon
   drawing does not.
3. **Rebuild everything else from our own kit vocabulary.** Costume cut, panel
   layout, accessories and badges are new. No canon logos, insignia, patterns,
   lettering or distinctive garment cuts.
4. **Reference hygiene.** Canon art may be looked at to confirm an anchor, but it
   is never on screen while blocking the silhouette, and never traced, overlaid,
   color-picked or proportion-matched.
5. **Distance check before sign-off.** Our silhouette beside a canon image: each
   anchor recognisable, but the overall silhouette composition (prop shape,
   costume masses, pose) clearly different. If our silhouette could be traced over
   the canon art, redesign it (§1.3).

**Tier 0 briefs:**

- **Ch'en (Guard, blade arc, Offensive SP).**
  - Anchors: swept-back dragon horns, a dragon tail, a sword-wielding city
    officer.
  - Prop — **ruling (2026-11-01): one oversized curved blade** sweeping past the
    head line, with the crescent negative space under its curve. Her canon second
    blade becomes a **short sheathed blade on the hip**, inside the body
    silhouette, so it never competes as a second prop.
  - Horns sweep back and taper, never curling into a hook (Specialist). The tail
    is 3 rigid segments with a gentle curve and no curled tip, for the same
    reason.
  - Hair: dark slate-navy family (H ~220°, inside Defender's band, so S ≤ 25%) —
    reads as dark blue-grey, not a class blue.
  - Costume: an original long field coat over fitted kit; the dark coat is the
    dominant mass.
  - Stance: low, coiled, forward-weighted. Personality: impatient, precise; the
    idle taps the blade guard with her thumb.
- **Amiya (Caster, ring, Auto SP).**
  - Anchors: long rabbit-like ears, an oversized hooded jacket, rings as the focus
    of her Arts.
  - Prop: the ring motif enlarged into an original **hand-held ring focus** about
    one head across, held out from the casting hand. It extends the bounding box
    forward by ≥ 25%, and its hole is the circular negative space. Not a canon
    item.
  - Ears are tall, closed shapes with rounded tips; they never loop into a ring (a
    second Caster primitive on the head) or bend into a hook.
  - The oversized jacket is a main mass built from 2–3 hinged rigid plates. Hair:
    warm brown family at S ≤ 25%.
  - Stance: centered, upright, symmetrical. Personality: calm, earnest; the idle
    has a small steadying breath and the ring turns slowly.

**Later Operators (notes only, Tier 1+):**

- **Mudrock (Defender) — deferred to Tier 1 pre-production (2026-11-01).** Her
  canon anchor is a huge hammer, while §3.1 gives Defenders a body-height tower
  shield. A slab-headed maul held forward as a wall would satisfy the *square
  block, wall* primitive but requires amending §3.1. Decide before Tier 1
  modelling.
- **Surtr (Guard).** Same class as Ch'en, so the §5.3 same-class rule applies:
  two-handed greatsword vs Ch'en's one-handed blade; tall and upright vs low and
  coiled; large flowing hair mass vs a compact head. Her canon red hair sits next
  to Danger Red — use a deep rust family in the free 9–14° band at S ≤ 35%, with
  recognition carried by the hair's mass rather than its hue. Her fire skill is
  **Guard amber**, not fire orange; "fire" is expressed through motion and shape
  (rising tongues drawn as blade arcs).

**Pillar link:** Pillar 4 (a Doctor recognises the Operator from the anchors),
bounded by §1.3 originality; Pillar 1 (the class primitive outranks canon
fidelity whenever the two conflict).

## 6. Environment Design Language

*The arena is rank 4 in the shape hierarchy (§3.5): it sets the place, holds the
floor line and gets out of the way. §3.3 (fight band, primitive ban, horizontal
emphasis) and §4.6 (S ≤ 35%, ≤ 25% near class hues, V 20–60%, no arena bloom, one
temperature per arena, arena-independent ivory rim) are binding.*

### 6.1 Architectural style: "Plate and Track"

Terra's cities move. They are built on mobile platforms rolling across a hostile
land, and Originium is both their fuel and their plague. Our architecture
expresses that through original geometry:

- **Deck plates.** Large, chamfered, modular plates — the ground is a
  *platform*, not soil. Plate seams run horizontally and far apart: at least 2
  character heights between joints in the fight band.
- **Tread and machinery at the edges.** Track housings, pistons and
  plate-coupling machinery appear above the fight band or on the far horizon,
  reminding the player that the city is a vehicle.
- **Stacked, retrofit construction.** Buildings bolted onto platforms in layers —
  overhangs, balconies, add-on boxes. The culture of a city that must fold up and
  move.
- **Originium as a contained hazard.** Dark, faceted, low-saturation crystal
  growths, always shown *contained or cordoned*. They glow through value only
  (lighter seams), never bloom (§4.6.4). They sit in compact clusters, never in
  rows (a row of shards becomes a zigzag — the Specialist primitive), and only
  above the fight band or in the background.
- **Rhodes Island presence** is shown through deployment logistics (transport
  containers, comms masts, field equipment), never the Rhodes Island logo or
  canon marks (Principle A). UI Bronze-Gold #A69468 exceeds the arena ceiling
  (S 37% vs 35%), so arena "bronze" is a darker, more muted relative at S ≤ 30%.

**Each arena has a regional accent.** Every arena keeps the Plate-and-Track base
and adds one regional skin (Lungmen urban density, wasteland, landship deck…).
The regional skin changes materials, signage and silhouettes above the band,
never the fight-band rules.

**Banned as arena motifs in the fight band:**

- class primitives (§3.3);
- **45° hazard stripes** — the non-color half of the danger signal (§4.4); use
  plain banded barriers instead;
- **medical crosses** — the Medic primitive; crates are marked with blocky glyph
  labels.

**Pillar link:** Pillar 4 (a Doctor recognises Terra's mobile-city logic),
bounded by Pillar 3 through the fight band and the reserved-shape bans.

### 6.2 Texture philosophy: painted flat color, no PBR

**Ruling: stylised, hand-painted flat color driven by the toon shader. No PBR, no
normal maps, no photographic textures.**

Why, for this game and a solo pipeline:

- **The toon shader discards most of what PBR provides.** Roughness and metalness
  barely change a two- or three-band toon ramp; authoring them is wasted time.
- **Value control.** §4.6 caps arena value and saturation numerically. Painted
  flat values can be checked against those caps with a color picker; PBR
  responses vary with lighting and cannot.
- **Consistency with the characters.** Both layers share one rendering language,
  so the hierarchy is set by detail and contrast budgets, not a clash of styles.
- **Solo throughput.** Flat palettes and reusable trim sheets are far cheaper
  than baked material sets.

**Characters:**

- A **palette atlas**: UVs map to flat color swatches; face decals and L2 trim
  live in a separate small texture.
- The **P2 alternate costume (§5.3) is a palette-atlas swap** — no new mesh or
  UVs.
- Metal props get one hard toon specular band; no other highlight.

**Arenas:**

- Painted **trim sheets** and a few large painted surfaces, with wear and grime
  painted as large, soft shapes.
- A gentle vertical value gradient on tall surfaces (darker at the base) helps
  the floor line separate.
- Depth comes from per-layer fog and haze rather than texture contrast.

**Texture contrast budget (binding; the V spread inside one surface at the
default camera):**

| Zone | Max internal V spread | Note |
|---|---|---|
| Fight-band backdrop | **≤ 10 V-points** | Large, soft shapes only, never repeated below one head width (§3.3) |
| Above the band | ≤ 20 V-points | Where regional identity lives |
| Far background | ≤ 15 V-points, plus haze | Silhouettes, not surfaces |
| Characters (for comparison) | ≥ 30 V-points between adjacent masses | The §5.2 three-mass plan |

Characters always carry at least three times the internal contrast of the
surface behind them. That gap, plus value bracketing (§5.2) and the 2–3 px
outline, is the legibility contract.

### 6.3 Prop density by zone

| Zone | Where | Density rule | Value / contrast |
|---|---|---|---|
| **Play plane** | Character depth, floor to top of screen | **No props.** Nothing stands between or around the fighters at their depth; nothing breaks the floor line. | Floor surface only |
| **Foreground** | Between camera and play plane | **None in Tier 0** — it would hide characters and fight the HUD safe zones. | — |
| **Fight-band backdrop** | Behind the play plane, floor to 1.5 character heights | **The quiet wall.** At most **3 discrete props per screen width**, each at least one head width, flat-faced, low relief, no repeated detail below head width. | V 25–50 (a tighter subset of §4.6's 20–60, keeping ≥ 18 V-points between the Ops Black outline and the darkest backdrop); spread ≤ 10 |
| **Above the band** | 1.5 character heights to top of frame | **Medium density.** Detail may cover up to ~40% of the zone: signage, overhangs, cables (sagging curves, never long straight lines — the Sniper primitive), machinery. One focal storytelling element per arena. | V 20–60; spread ≤ 20 |
| **Far background** | Skyline, horizon | **Silhouette layer.** Large masses, low frequency, haze-softened. | Spread ≤ 15; lowest contrast in the scene |

**Floor line.** One unbroken value edge (a curb or plate edge), at least 20
V-points from both the floor and the backdrop above it (§3.3).

**Stage ends.** A quiet, consistent visual end at each wall (a barrier block or
building corner), so players can see a corner coming. Stays within fight-band
rules.

**Arenas are static and never break.** No arena element is destroyed, moved or
made to react by hits, throws, wall contact or Ultimates. The floor line and
stage ends must read the same on the last frame as on the first. Ambient motion
(§6.4.7) is the only arena movement.

**"Slightly soft"** (Principle A) comes from haze and the reduced contrast budget
first. A blur pass is optional; the technical-artist judges it for cost.

### 6.4 Environmental storytelling

The arena tells a story through **arrangement and state, never text**:

1. **A moment interrupted.** Each arena shows a place in the instant after people
   left — evacuation in progress, work stopped mid-task. The fighters own the
   space because everyone else just cleared out; this also explains the empty
   fight band.
2. **Mobility is visible.** Coupling joints, track housing, folded or extended
   sections show that this city moves. One clear mobility tell per arena, above
   the band or on the horizon.
3. **Originium means danger, contained.** Cordoned growths and warning lights
   state the world's central threat without a word. Never in the fight band, where
   it would read as a gameplay hazard.
4. **Rhodes Island is a guest.** Presence through deployed equipment and
   transport, never a logo. A Doctor reads "we're here on an operation".
5. **Story budget per arena:** **one focal beat** (above the band) plus **2–3
   secondary tells**. More competes with the fight (Principle A's design test).
6. **Signage uses invented glyphs.** Blocky pseudo-script with no legible words in
   any real language, no real brands, no canon logos. Reads as "a dense city"
   without being read as text.
7. **Ambient motion is slow and away from the fight.** Allowed: a sign flickering
   at ≤ 0.5 Hz, drifting steam, a swaying lamp — all above the band, all without
   bloom. Nothing in the fight band moves except the fighters and their effects.
   The slow cadence also keeps the arena photosensitivity-safe.

### 6.5 Tier 0 arena: Lungmen Street, "Evacuated Night Market"

**Concept.** A night-market street on a Lungmen city plate, evacuated minutes ago
after an Originium alert. Stalls are shuttered, a police cordon blocks the far
end, and the city skyline and plate edge stand behind. Ch'en's home ground, which
gives the Tier 0 matchup an implied stake without text.

**Light temperature — ruling (2026-11-01): warm key / cool fill.**

- The Tier 0 pair is Guard Amber (H 45°, L 0.617) and Caster Violet (H 261°,
  L 0.201). Under a cool key, violet — already the darkest accent and nearest the
  3:1 floor — also loses hue contrast against the ambient: a double loss on the
  weakest color. Under a warm key, amber loses hue contrast instead, but its very
  high luminance keeps it standing out, and violet gains hue contrast. Warm key
  protects the weaker accent.
- It fits the fiction: warm low-saturation street and shopfront lamps form the
  key; a cool night sky forms the fill.
- Cool key / warm fill is kept for a later arena (e.g. a Defender/Supporter
  pairing).
- Application: key tint at S ≤ 20%. Per §4.6.6, Operators receive a neutral key
  and the constant ivory rim; the arena's cool fill tints their toon shadow band
  by ≤ 15%.

**Key direction.** High from stage left (~50° up), from the overhead lamp line
above the band. Fill from above and behind (the sky), lifting the skyline
silhouettes.

**Palette (HSV script-verified 2026-11-01):**

| Role | Hex | H / S / V | Rule checked |
|---|---|---|---|
| Floor deck plate | #3D3E47 | 234 / 14 / 28 | Free cool band, inside the V band |
| Curb / floor line | #7E7F8C | 236 / 10 / 55 | Floor line (§6.3): 27 V-points above the floor (V 28), 21 above the shutters (V 34) |
| Shutters, fight-band backdrop | #574F48 | 28 / 17 / 34 | Inside Vanguard/Guard bands, so S ≤ 25; fight band V 25–50; 21 V-points below the curb. Painted bands vary **downward only** (V 25–34), keeping the curb gap and spread ≤ 10 (§6.2). *Revised 2026-11-01 (was #615850, failed the curb gap).* |
| Upper facades (above band) | #5C5D73 | 237 / 20 / 45 | Free cool band, S ≤ 35 |
| Far skyline | #36363D | 240 / 11 / 24 | Lowest-contrast layer |
| Lamp and sign panels (lit by value, no bloom) | #996F64 | 12 / 35 / 60 | Free 9–14° band; at the V ceiling |
| Originium body | #38312D | 22 / 20 / 22 | Inside class bands, S ≤ 25 |
| Originium seam | #736557 | 30 / 24 / 45 | S ≤ 25; value glow only |

**Layout by zone:**

- **Floor.** Large deck plates with a horizontal seam at most every 2 character
  heights. A recessed, low-contrast tram rail may run along the plane. The curb
  behind the play plane is the floor line.
- **Fight-band backdrop.** Closed roll-down stall shutters drawn as **large flat
  panels with 2–3 broad horizontal bands each**, not fine slats (fine slats break
  the head-width rule). At most three stall counters per screen width with covered
  pots, all flat-faced.
- **Above the band.** Stacked overhangs and balconies, signboards with invented
  glyphs, sagging power cables, air-conditioner boxes, and the overhead lamp line
  (the key light source). **Focal beat:** a cracked deck plate at upper stage
  right with a contained Originium cluster behind plain banded barricades.
- **Far background.** Lungmen tower silhouettes in haze, and the city plate edge
  with tread housing on the horizon (the mobility tell).
- **Secondary tells (pick 2–3):** steam rising from a covered pot above the
  counter line (slow); a dropped tray on a counter top; a cordon of original,
  insignia-free barriers at the far end; a sign flickering at ≤ 0.5 Hz above the
  band.

**Legibility check (acceptance test for this arena):**

1. Capture in-engine screenshots of Ch'en and Amiya in idle, light-attack and
   skill poses at three stage positions (left corner, center, right corner).
2. Desaturate, downscale to 64 px character height, blur by 1 px.
3. Both classes must be identifiable and the floor line must read in every shot.
4. At least 60% of each silhouette sits outside V 20–60.

**Pillar link:** Pillar 3 (the quiet wall, the contrast budget, the warm key
chosen to protect the weakest accent) and Pillar 4 (Lungmen, Originium and Rhodes
Island logistics read instantly to a Doctor).

## 7. UI/HUD Visual Direction

*The HUD's job is the Pillar 3 promise: SP, SP type, the Ultimate gauge and
skill time left can be read **for both players** at a glance, even when the two
fighters are not trading hits. Everything else — the dossier look, the Rhodes
Island language, motion — is allowed only where that job is unaffected (§1.3).
All pixel figures are at 1920×1080; all frame counts at 60 Hz.*

> **Status: every text size and photosensitivity number in this section is a
> PROVISIONAL baseline**, pending `design/accessibility-requirements.md`
> (`/ux-design accessibility`). Where that document sets a stricter value, it
> wins and this section is updated.

**Authorship and conflict record (2026-11-01).** Drafted by art-director with a
ux-designer alignment review. Four conflicts were surfaced and decided by the
user, all in the ux-designer's favour: (1) one top-corner cluster per player
holding all four resources, instead of the Ultimate in a bottom band; (2) a
24 px text floor everywhere, instead of 20 px HUD / 18 px elsewhere; (3)
Defensive SP fill uses vertical notch ticks, not 45° hatching; (4) the
class-primitive quarantine extends to character select. The ux-designer's
stricter values were also adopted for the danger pulse, scanlines, side-border
width, opaque gauge wells, typing duration and scale options. A fighter jumping
under a cluster gets **no fade** — the HUD wins (art-director position, user
ruling).

**Amendments to locked sections (applied in place, marked "amended by §7"):**
§2.2 (menu scanline drift removed; header typing ≤ 300 ms; skill side border
per §7.2) · §3.4 (quarantine covers character select) · §4.1 / §4.8 (information
plates opaque) · §4.4 (danger pulse smooth) · §4.7 (strokes ≥ 3 px, P2 gap ≥ 3 px)
· §4.8 (throwbox uses an Ivory dot grid) · §4.9 (Defensive SP = vertical notch
ticks; 45° hatching = danger only).

### 7.1 Diegetic versus screen-space: the ruling

**Ruling: the combat HUD is screen-space.** In the fiction it is the Doctor's
operations feed — an overlay on a tactical terminal — so it is screen-space on
screen and diegetic in spirit. Only three kinds of element live in the world,
each anchored to an Operator:

| Element | Space | Why |
|---|---|---|
| HP, SP, SP type, skill timer, Ultimate, round timer, round slots, portraits | **Screen-space HUD layer** | Must never shake, slow, be tinted or be covered (Principle C); fixed places so both players learn where to look. |
| Overhead side marker (1P triangle / 2P rhombus, §4.7) | World-anchored, drawn flat | Must follow its Operator, including during shake. Drawn **under** the HUD if the Operator jumps into a cluster. |
| Prop emblem, skill aura, trails | World (Sections 3, 5) | Class state *on the body* is the silhouette doctrine's job, not the HUD's. |

**Rejected alternatives:**

- **Fully diegetic gauges** (on the Operator's back or prop): the world layer
  shakes, slows and goes near-black during the Ultimate, so they would break
  Principle C exactly when they matter most; at ~300 px character height they are
  too small to read.
- **SP bars anchored under each fighter:** they overlap the fight band, clash
  with hit sparks and move with the fighter. Reading the opponent's SP would mean
  tracking a moving target — fails Pillar 3.

### 7.2 Layer order (binding)

From back to front:

1. **World** (arena, Operators) — may shake, slow, tint, go to black.
2. **World VFX and overhead side markers.**
3. **Ultimate title card** — clipped to the fight viewport (§7.3); never drawn
   inside a HUD cluster.
4. **Skill side border.**
   - At least **24 px wide**, steady class color, on the owner's side only.
   - Sits **inside the HUD margin**, between the screen edge and the cluster's
     outer edge, with ≥ 16 px clear gap to the cluster (default inset: x 16–40
     for P1, mirrored for P2). Never under cluster text.
   - Steady while the skill runs; its only motion is the last-2-s cue (§7.6),
     pulsing in sync with the timer bracket.
5. **HUD layer** — never moved or altered by camera, shake, slow-motion, pause
   dim, KO grayscale or Ultimate darkening (§4.8). The single state change is the
   KO'd player's own portrait turning grayscale (§7.3).
6. **Announcer plates** ("ROUND 1", the go call, "K.O.") — outside live play
   only, inside the fight viewport.
7. **Pause and menu plates.**

**Timing rule.** HUD animation runs on **unscaled presentation time**. HUD values
always come from the simulation; presentation slow-motion never slows a gauge.

### 7.3 Layout: one corner cluster per player

**Safe inset:** 64 px left/right, 40 px top, 48 px bottom; a **TV-safe slider**
(0–5%) adds to it. **16:9 box:** on ultrawide and 16:10 screens the HUD stays in a
centered 16:9 box, so eye travel between clusters never grows. **Fight viewport:**
x 64–1856, y 230–1032 (announcer plates and the Ultimate title card only).

**Bar direction:** every bar is **anchored at the portrait, with its moving fill
edge facing the screen center** — HP, SP, skill timer and Ultimate alike.

**P1 cluster:** x 64–840, y 40–220 (~180 px tall including the frame, starting at the 40 px top inset). P2 is
mirrored around x = 960.

| Row | Element | Placement | Size | Notes |
|---|---|---|---|---|
| Frame | Player bracket | Around the whole cluster | ≥ 3 px stroke | P1: Ivory solid single. P2: Copper double, ≥ 3 px gap. Opaque Graphite strip under the stroke. |
| Left | Portrait | x 64–184, y 52–172 | 120 × 120, chamfered | Flat cel bust rendered from the Operator's own model. Static in combat. On KO, **only the KO'd player's portrait** turns grayscale — a state signal driven by the simulation, not the world's KO grayscale. Nothing else in either cluster changes. |
| Left | Class emblem | x 64–104, y 176–216 | 40 px | The class primitive — the only class primitive in the combat HUD (§3.4). |
| 1 | HP bar | x 200–840, y 52–84 | 640 × 32 | Ivory fill in an opaque Ops Black well. Danger Red chip with 45° hazard hatching (§4.9). |
| 2 | Name | x 200–600, y 92–124 | 24 px | Light Steel caps; room for 16 characters, no auto-shrink below the floor. On LAN the local cluster adds an Ivory **"YOU"** tag at 24 px. |
| 3 | SP type icon | x 200–232, y 134–166 | 32 px | Ivory on Graphite, never class-colored (§7.5). |
| 3 | **SP bar = skill timer** | x 244–704, y 138–162 | 460 × 24 | Class accent fill in an opaque well; fill texture shows SP type. While a skill is active, this same bar drains. |
| 3 | Status plate | x 716–840, y 130–170 | 124 × 40, opaque | The one place to read skill state. |
| 4 | Ultimate label | x 200–316, y 178–210 | 24 px | `ULTIMATE` in Light Steel; Ivory when full. |
| 4 | Ultimate gauge | x 324–704, y 184–204 | 380 × 20 | Ivory fill in an opaque well; segments separated by **vertical gaps ≥ 4 px** (45° is danger-only). Art supports 1–5 segments; count per combat GDD. |
| 4 | Ultimate count | x 716–840, y 178–210 | 24 px mono | `2/3`, or `FULL` in Ivory. |

**Center column:**

- **Round timer:** x 880–1040, y 40–120, opaque Graphite plate, Bronze-Gold
  frame (bronze's only HUD use). **56 px mono bold** Ivory numerals. At ≤ 10 s
  the frame turns Ivory — a static change, **not red** (time running out is not
  incoming harm).
- **Round slots:** y 128–144, growing outward from center, one row per side;
  28 × 16 chamfered slots. Filled Ivory = won; Steel Grey outline = not won.
  Slots, because circles are Caster's and squares Defender's.

**SP type fill textures (amends §4.9):**

| SP type | Fill behavior and texture |
|---|---|
| Auto | Smooth, continuous, plain fill. |
| Offensive | Fills in steps; each block separated by a **full-height** 3 px Ops Black gap. |
| Defensive | Plain fill with **vertical notch ticks**: 2 px Graphite ticks, 40% of bar height, rising from the bottom edge every 12 px. Short, so they never read as Offensive gaps or Ultimate segments; < 15% of the fill area, so weak accents keep their contrast. |

**Status plate states:**

| State | SP bar | Plate shows |
|---|---|---|
| Charging | Fills toward center | Current/needed SP in Light Steel 24 px mono (e.g. `18/30`) — whether SP is numeric is per combat GDD; otherwise the type: `AUTO`, `OFF.`, `DEF.` (full names in the dossier). |
| Ready | Full, brightened | `READY` in Ivory 24 px bold; bracket cue (§7.6). |
| Active | Drains linearly toward the portrait | Whole-second countdown, **32 px mono bold** Ivory, then `s` at 24 px. Last 2 s: the plate bracket pulses (§7.6). |

**Transient elements:**

- **Combo counter** — attacker's side, x 64–360, y 240–340, just below the
  cluster (a cornered victim is always on the far side). 56 px mono bold
  numerals, 24 px `HITS` label, no backing, 3 px Ops Black outline.
- **Training input display** — P1 x 64–260, y 260–880 (mirrored for P2). Up to
  12 rows at 24 px mono: direction arrow with a shaft (not a chevron), button
  keycap, frame count.
- **Training data panel** — bottom center, x 600–1320, y 936–1032, opaque
  Graphite. Startup / active / recovery / advantage at 24 px mono with true minus
  signs (`+3`, `−5`). The round timer shows `--` in training, never ∞ (a ring is
  Caster's).
- **Pre-round intro** — for **≥ 1.5 s (90 f)** each side shows its **class
  emblem and SP type icon at ≥ 64 px** beside its frame, so each player sees the
  opponent's rule set before the first frame of play.

**Jump-under rule:** when a fighter jumps under a cluster, the cluster stays
fully drawn and **does not fade**. The HUD wins (§3.5).

### 7.4 Typography

**Personality:** engineered, calm, condensed — a field manual set by a careful
clerk, not a sci-fi poster.

**Two faces:** a **proportional technical sans** for words and all multi-line
text; a **monospace for numbers and short labels only** (timers, counts, SP
values, frame data, IP addresses, file IDs, feed header lines). Paragraphs are
never monospace.

**Candidate typefaces** — SIL Open Font License 1.1 as far as known; **verify
each licence file at its source before locking.** Under OFL the font may be
bundled with a free or commercial game, the OFL text ships with the build, and a
modified font is renamed if the original uses a Reserved Font Name.

| Role | First choice | Alternative | Why |
|---|---|---|---|
| Sans | **Barlow / Barlow Semi Condensed** (Jeremy Tribby) | Saira (Omnibus-Type) | Wide weight range; low-contrast strokes survive small sizes; condensed widths fit long bars. |
| Mono | **JetBrains Mono** | IBM Plex Mono | Clear 0/O and 1/l/I (LAN IP entry); fixed digit widths so timers never jitter. |

**Font requirements (binding):**

- Full **Vietnamese diacritics** support, including stacked marks on capitals.
- All text boxes reserve **line height ≥ 1.4×** the font size.
- Acceptance string **`ĐƯỢC ẤN ỔN`** at 24 px, caps, in every weight used: no
  mark clips at plate edges or collides between lines.

**Originality:** do not choose a typeface because it matches the original game's
UI or wordmark; check both candidates against it and drop any close match. The
game logo is drawn from our own letterforms.

**Size hierarchy at 1080p, 100% scale (PROVISIONAL):**

| Level | Size | Face and weight | Use |
|---|---|---|---|
| Display | 96–128 | Sans Bold, caps, +4% tracking | ROUND, K.O., VICTORY, DEFEAT, MATCH VOID |
| HUD timer / combo | 56 | Mono Bold | Round timer (floor 48), combo count |
| H1 | 48 | Sans SemiBold, caps | Menu titles |
| H2 | 32 | Sans SemiBold, caps | Panel headers, dossier sections |
| Skill countdown | 32 | Mono Bold | Status plate during a skill |
| Body | 24 | Sans Regular, sentence case | Menu and dossier text |
| HUD and menu labels | 24 | Sans SemiBold caps / Mono Medium | READY, names, YOU, SP value, gauge labels |
| Caption / secondary | 24 | Sans Regular, Light Steel | Secondary text, hints, disabled-reason text |

**Floors (binding, PROVISIONAL):**

- **24 px minimum for any readable text, anywhere.** Steel Grey decorative
  labels that carry no information may be smaller; anything a player must read is
  never Steel Grey (§4.8).
- No Light or Thin weights below 32 px. Semi Condensed, not Condensed, at
  24–28 px.
- Caps only for labels of three words or fewer; body text is sentence case.
- **Disabled but readable labels** use Light Steel plus a **lock glyph**, never
  Steel Grey alone.

**Numerals:** mono for every changing number; tabular lining figures wherever the
sans shows numbers; slashed or dotted zero wherever 0 and O can meet; true minus
(−), not a hyphen.

**No text is ever baked into an image.** All text is live, so it scales,
localises and is exposed to AccessKit (Godot 4.5+). Icons and emblems carry
accessible names. *ui-programmer to confirm against the 4.7 API.*

### 7.5 Iconography

**Style:** flat, solid shapes with one interior cut, built on 45° chamfers. No
illustration in the HUD. Solid shapes survive small sizes and grayscale better
than line icons. **Filled vs outlined is a state code:** filled = available or
active; outlined = empty or unavailable (round slots and menu actions follow it).

| Spec | Value |
|---|---|
| Authoring grid | 48 px, vector (SVG) |
| Display sizes | 32 / 40 / 48 / 64 / 96 px in combat and menus; menu emblems up to 128 px. 24 px icons are retired, so an icon never sits below the text it labels. |
| Live area | 28 of 32 px (2 px padding) |
| Stroke (outlined states) | ≥ 3 px at 1080p, at any display size |
| Corners | 45° chamfer; no rounded corners except the Medic emblem's soft cross |
| Color | Ivory on Graphite by default. Class emblems are the only class-colored icons. Danger icons are Danger Red **plus** hazard stripes. |

**Families:** class emblems (8) — the only class shapes in the combat HUD and
character select; SP type (3) — hourglass (Auto), four-point impact spark
(Offensive; §3.2 spark geometry, so it never reads as the Medic soft cross),
notched "incoming" bar (Defensive); system — pause, settings, input
keycaps, lock, shafted arrows, signal brackets. Bare chevrons only outside combat
and character select.

**Why the SP type icon is Ivory:** SP type is never shown by color (§4.9). Ivory
on Graphite holds 11.1 : 1 for every class, including Caster (3.3 : 1) and
Defender (3.5 : 1).

**Acceptance check:** every icon is identifiable at 32 px in grayscale with a
1 px blur; no two icons share an outline.

### 7.6 UI animation feel

**Combat HUD rules:**

1. **A gauge's motion tells the truth.** Quantities move instantly or linearly;
   easing is only for brackets and labels.
2. **No ambient motion inside a HUD cluster.** Nothing moves unless a value or
   state just changed.
3. **Event cues last ≥ 250 ms (15 f), then hold steady.**
4. **Only two loops exist:** the **danger pulse** and the **skill-ending cue** —
   the only non-danger loop in the game. Both are smooth 2 Hz opacity pulses.
   Danger is always red with hazard stripes; the skill-ending cue is always the
   owner's status-plate bracket (and side border), never red, never striped.

| Event | Timing (60 Hz) | Easing | Notes |
|---|---|---|---|
| HP loss | Instant | — | Real HP is never animated |
| Damage chip | Hold 30–45 f, then drain ~20 f | Ease-in | Hazard hatch on the chip |
| SP fill, Auto | Every sim tick | Linear | Smooth |
| SP fill, Offensive / Defensive | Step over 3 f per hit dealt / taken | Ease-out | Block steps / notch ticks |
| READY | Bracket snaps in 6 f, highlight held to 15 f, then steady | Ease-out | One-shot |
| Skill active drain | Continuous | **Linear** | Easing would misstate time |
| Skill ending (last 2 s) | Plate bracket + side border pulse at 2 Hz, opacity 100% → 40% | Sine | Only non-danger loop |
| Ultimate full | Bracket sweep over 15 f, then steady | Ease-out | Label and count turn Ivory |
| Danger pulse | 2 Hz, opacity 100% → 40% | Sine | Amends §4.4 "on-off" |
| Combo count | Punch 115% → 100% over 4 f; fades over 10 f after 60 f idle | Ease-out | Number stays up > 250 ms |
| Round slot won | Fills over 15 f | Ease-out | During KO, not live play |
| Pre-round emblem + SP icon | ≥ 90 f on screen | Fade in 8 f | ≥ 64 px |

**Never in combat:** shake, scale or slow-motion on any HUD element; tint from
escalation, dim from pause or KO, darkening from the Ultimate; any transition that
removes the HUD before the result is decided. **During any skill window or
Ultimate, nothing enters a HUD cluster.**

**Photosensitivity (PROVISIONAL):**

- No flash covering more than ~10% of the screen repeats more than 3 times per
  second.
- Hit sparks stay ≤ ~5% of the screen.
- The KO flash is a **single** flash with a rise of ≥ 2 frames.
- Both 2 Hz pulses fade smoothly, with no hard flash edge.
- Verify with a flash-analysis tool (e.g. PEAT) on captured footage.

**Menus:**

| Event | Timing | Easing |
|---|---|---|
| Panel enter | 180–250 ms, slide ≤ 24 px with fade | Ease-out cubic |
| Panel exit | 120 ms | Ease-in |
| Focus move | Bracket slides to target over 80 ms | Ease-out |
| Confirm | Bracket snaps closed, held to 250 ms | Ease-out |
| Header typing | ≤ 300 ms total; **any input completes it instantly**; **never on lobby or result status text** | Linear |
| Scene transition | Scanline wipe ≤ 400 ms (§7.8) | Ease-in-out |

- Input is never blocked by an animation; a press during a transition jumps to
  the end state.
- **Destructive actions** (leave lobby, forfeit, quit to desktop) need a
  **500 ms hold**, shown as a bracket filling around the button.

### 7.7 Options that shape the visuals

| Option | Values | Notes |
|---|---|---|
| Screen shake | 0–100% | World layer only; the HUD never shakes. |
| Flash | Full / Reduced / Off | Reduced: KO flash becomes a 100 ms value fade, hit sparks lose bloom. Off: no full-screen flashes. |
| Reduced motion | On / Off | Removes scanlines, header typing, combo punch and bracket overshoot. Keeps every state change and both 2 Hz cues (they carry information). |
| Solid HUD backing | On / Off | Makes decorative chrome opaque too; information plates are always opaque. |
| HUD scale | 80–120%, 10% steps | Geometry scales around cluster anchors. **Text never renders below the 24 px-equivalent floor** — at 80% text stays 24 px and the bars shrink. |
| Menu text scale | 100 / 125 / 150% | Plates grow to fit their text and **never clip it**. |
| TV-safe inset | 0–5% slider | Added to the default inset; the side border moves inward with it. |
| Hit-stop | **Not optional** | Hit-stop is gameplay (simulation), not presentation. The menu says so. |

### 7.8 Menu, dossier and system screen styling

Principle A applies freely here (§1.3); Pillar 4 leads.

**Layout and surfaces:**

- **Grid:** 12 columns, 64 px margins, 24 px gutters, 8 px baseline.
- **Panels:** Graphite with 45° chamfered corners (one, or two opposite) and
  bracket corners; a Bronze-Gold header rule with an end tick. Text plates are
  opaque; only decorative chrome may be translucent.
- **Scanlines:** only in **scene transitions (≤ 400 ms)** and the **static pause
  overlay**; pitch **≥ 4 px**, brightness modulation **≤ 10%**, native
  resolution. Never over the HUD or a text plate. Off under Reduced motion.
- **Chevrons and hex cells:** allowed in the main menu, dossier and settings.
  **Not allowed on character select** (amends §3.4); character select pages with
  plain solid triangles or brackets.

**Buttons:** chamfered, ≥ 56 px tall, 24 px caps.

| State | Look |
|---|---|
| Default | Graphite with Ivory text |
| Focus | Ivory bracket corners, not a fill; no generic blue (§4.4) |
| Pressed | Ivory fill with Ops Black text |
| Disabled | Light Steel text plus a lock glyph, with the reason as a 24 px caption |

**Local 2P:**

- **Nested cursors on character select:** P1 Ivory solid bracket inside, P2
  Copper double bracket outside; neither hides the other.
- **Pause has an owner:** the plate carries the owner's tag and bracket style
  (`PAUSED — 1P`); only the owner navigates and resumes; the HUD stays visible
  and undimmed (§2.2).
- **Rematch needs both players to confirm.**
- **Two players on one keyboard:** separate bindings with conflict detection;
  menus accept each player's own confirm/back keys; the Controls screen reserves
  room for an input-test panel showing held keys (ghosting check before a match).

**Dossier layout:** left 5 columns — the Operator "file photo" (lighting per
§2.2) and the class tab, the screen's only accent color; right 7 columns — H2
sections for profile, SP type (icon, label, one-line rule), skill and Ultimate,
plus a mono stat block.

**Originality:** keep the language (brackets, feed lines, file numbers) but not
the original game's screen layouts. If a screen reads as a recreation of a
specific canon screen, change its composition.

**LAN lobby:**

- **Every connection state has a text label plus a bracket state**, never color
  alone: `CONNECTED` — filled Ivory bracket; `WAITING` — hatched bracket
  (horizontal hatch, not 45°); `FAILED` — Danger Red plus a broken bracket.
- **Host address:** IP and port in mono at ≥ 32 px, with a Copy action.
- **Ping:** mono number (`42 ms`) **and** 1–4 brackets; thresholds per netcode
  GDD. No green.
- **Fixed sides:** P1 always left, P2 always right, **on both machines**; HOST =
  1P, CLIENT = 2P; the local player is marked only by the **YOU** tag.
- **Status text never types in** — it appears whole.

### 7.9 Result screens (ruling)

**Local versus: one shared result screen.** The winner gets the §2.2 Victory
treatment; the loser's half gets the defeat treatment at reduced size.

**LAN: per-machine framing on a shared, identical layout and data block.**

- **Per-machine framing:** the winner's machine shows Victory framing (warm
  light, bronze at area scale); the loser's machine shows the Defeat debrief
  framing (cool, flat, rematch prompt given the most visual weight).
- **Identical on both machines:** the layout; both Operator cards in their fixed
  sides; the outcome in neutral terms (`1P WINS 2–1`), never only "you"; class
  emblems, rounds and stats; the YOU tag on each machine's own player. Only
  lighting, bronze and emphasis change, so a screenshot from either machine states
  the same facts.
- **Rematch:** both players must confirm; each side's state uses the lobby's
  labelled signal brackets. If one player leaves, the other sees "Opponent left"
  and returns to the lobby.
- **Disconnect:** mid-match, the world freezes under a `LINK LOST —
  reconnecting` plate (text + hazard stripe) for up to 10 s. On failure, a **void
  screen** reading `MATCH VOID — CONNECTION LOST`, with a text label and a broken
  bracket — no victory or defeat framing, no result recorded.

**Why per machine:** on LAN each player sits at their own screen, so the reason
for the shared local screen (honour the winner without humiliating the loser on
the same screen) does not apply. The loser gets the debrief that serves Pillar
3's learning loop; the shared block keeps the facts identical.

### 7.10 Readability tests (acceptance)

1. **Grayscale HUD test:** in a desaturated 1080p screenshot, both clusters show
   every §4.9 state, including the three SP fill textures, told apart without
   color.
2. **Glance test:** a mid-match screenshot shown for 0.5 s; using only the two
   clusters, a tester names, for both players, rough HP, skill state (charging /
   ready / active with seconds left) and Ultimate state (count or FULL). Run once
   with one skill active and once with both.
3. **Burst test:** during an Ultimate and a double skill window, no pixel inside
   either cluster changes except the values and the 2 Hz cues.
4. **Floor test:** at HUD scale 80% and menu scale 150%, no readable text renders
   below 24 px and nothing clips; `ĐƯỢC ẤN ỔN` renders cleanly in every plate.
5. **Distance test:** at HUD 120%, menu 150% and TV-safe 5%, on a 55" TV from
   2.5 m, every piece of text is readable.
6. **Mirror test:** in a grayscale mirror-match screenshot, the HUD alone shows
   which side is which.
7. **Photosensitivity test:** captured footage of an Ultimate, a KO and a long
   danger pulse passes flash analysis (§7.6).

### 7.11 Open tensions (to watch in playtest)

- **Two pulses, one rhythm.** The skill-ending cue and the danger pulse are both
  2 Hz; color, stripes and location separate them. Worst case: a protan player at
  a Vanguard skill end next to a danger warning. If it confuses, change the
  skill-ending tempo first (e.g. 1.5 Hz).
- **Taller opaque cluster, no fade.** High jumps disappear behind the ~180 px
  cluster more often. Escalate to creative-director if playtests object.
- **HUD at 80%.** Text holds at 24 px while bars shrink; the name row and
  Ultimate label crowd. The 80% layout needs its own check; long names may need a
  short display name.
- **Cluster height budget.** A fourth row later (e.g. a guard meter) would push
  the cluster past 220 px.
- **Two 24 px side borders** during a double skill window frame the whole screen;
  test this case.
- **Defensive ticks vs Offensive gaps** differ only by tick height (40% vs full);
  must pass test 1 at HUD scale 80%.

**Pillar link:** Pillar 3 decides the HUD (placement, motion, type floors).
Pillar 4 decides the frame and menus. Where they conflict inside the HUD, §1.3
rules in the HUD's favour.

## 8. Asset Standards

*Merged from an art-director draft (ideal standards) and a technical-artist
draft (Godot 4.7.2 hard limits), 2026-11-01. Where they disagreed, both
positions and the user's ruling are recorded in §8.12.*

**Governing rule.** Every standard here protects one of three things: the
silhouette doctrine (L0), the flat-palette value checks (§4.6, §5.2, §6.2) or
solo throughput. When a technical limit forces a cut, cut L2 detail first, then
L1 texture resolution. Never cut silhouette geometry or the palette's exact
values.

**Provenance tags** (technical claims): **[V]** verified against
`docs/engine-reference/godot/`; **[M]** from model memory, check in the 4.7.2
editor before relying on it; **[E]** an estimate or proposal, not an engine
limit.

> **Placeholder warning.** `project.yaml` has no `performance:` or `platform:`
> block; budgets fall back to `.claude/docs/technical-preferences.md` (60 FPS,
> 16.6 ms, 500 draw calls). **No memory ceiling and no min-spec GPU are set**, so
> every VRAM and GPU-time figure below is a placeholder [E] until they are.

### 8.1 File formats

| Asset | Source (authoring) | Export (what Godot imports) |
|---|---|---|
| Characters, props, arena geometry | `.blend` | glTF 2.0 binary `.glb`, no embedded images, placeholder materials only; the toon `ShaderMaterial` lives on the Godot side. Direct `.blend` import is fine for local iteration but **never** the committed pipeline (every machine and headless CI would need the same Blender). No FBX path (the importer is `EditorSceneFormatImporterFBX2GLTF` [V], an extra conversion step). |
| Animations | Actions in the Operator's `.blend` | Inside that Operator's `.glb`, extracted to a Godot `AnimationLibrary` (a separate animation `.glb` per Operator is acceptable if file size slows iteration) |
| Character and arena textures | `.kra` / `.psd` / `.blend` paint sources | 8-bit sRGB `.png`, no embedded ICC profile |
| VFX masks and flipbooks | Paint source or rendered from Blender | `.png` — grayscale masks (non-color data), RGBA flipbooks |
| UI art | `.svg` | `.svg` imported directly; `.png` only for painted or raster art (dossier portraits). *ui-programmer: confirm 4.7 SVG import scale 1080p→4K.* |
| Fonts | — | `.ttf` / `.otf`, licence file committed beside them |
| Audio | Out of scope (audio-director) | — |

Binary sources are tracked with Git LFS (*producer / devops to confirm*).

### 8.2 Naming convention

**Ruling (2026-11-01): category prefixes with size suffix** (art-director
proposal). Pattern: `[category]_[id]_[part-or-name]_[variant]_[size].[ext]` —
lowercase snake_case (matches `naming.files` / `naming.scenes` in
`project.yaml`), ASCII only: no apostrophes, spaces or diacritics. Not
negotiable: the naming rule keeps lookup and validation scripts simple.

| Prefix | Covers |
|---|---|
| `char_` | Operator meshes, palettes, face and detail textures, the training dummy |
| `env_` | Arena geometry, trim sheets, painted panels, far-layer cards |
| `vfx_` | Effect meshes, masks, flipbooks |
| `ui_` | Icons, panels, frames, portraits |
| `fnt_` | Fonts — original file name kept after the prefix so the licence trail stays readable |

**IDs** are stable for the project's lifetime and identical to the IDs in game
data: Operators `chen`, `amiya`, `mudrock`, `surtr`…; training dummy `dummy`;
arenas `<region>_<place>` (e.g. `lungmen_street`); cross-asset `shared`.
**Size suffix** on textures only, in pixels: `_1024`, or `_2048x512` when
non-square. Meshes and scenes carry no size suffix.

**Examples:** `char_chen.glb` · `char_chen_palette_p1_256.png` /
`char_chen_palette_p2_256.png` (identical layout) · `char_chen_face_1024.png` ·
`char_chen_detail_512.png` · `env_lungmen_street_shutter_panel_2048x1024.png` ·
`env_lungmen_street_skyline_far_2048x512.png` · `env_shared_trim_industrial_2048.png`
· `vfx_guard_arc_mask_512.png` · `vfx_shared_hitspark_mask_256.png` ·
`ui_icon_class_caster.svg` · `ui_panel_dossier_frame.svg`.

**Inside the `.glb`:**

- **Rigid part = mesh node = joint name**, from one canonical list shared by every
  Operator, because shared animations bind by node path. Draft list (the
  technical-artist owns it once the rig exists):
  - Body: `root`, `pelvis`, `spine`, `chest`, `neck`, `head`, `face`
  - Arms and hands: `upper_arm_l` / `_r`, `forearm_l` / `_r`, `hand_l` / `_r`,
    `thumb_l` / `_r`
  - Legs: `thigh_l` / `_r`, `shin_l` / `_r`, `foot_l` / `_r`
  - Prop: `prop`, `prop_emblem`
  - Hair and cloth: `hair_01`…`hair_06`, `cloth_01`…`cloth_03`
- **§5.1 exceptions** are added child nodes with an `ext_` prefix (`ext_tail_01`…,
  `ext_ear_l`); the core hierarchy is never renamed or reordered.
- **Hand-pose variants** are sibling meshes `hand_l_grip`, `hand_l_open`,
  `hand_l_fist`; exactly one visible at a time.
- **Side suffix** `_l` / `_r`, not Blender's `.L` / `.R` (`.` is not usable in
  Godot node names). *TA: confirm Blender's mirror tools accept `_l` / `_r`; if
  not, author with `.L` / `.R` and rename on export.*
- **Animation names** equal the move / state IDs in move data, snake_case
  (`idle`, `walk_fwd`, `light_atk`, `skill`, `ultimate`, `hitstun`, `block`,
  `ko`, `victory`, `round_start`). The combat GDD's move IDs are the source; the
  art bible does not invent the list.

### 8.3 Folder layout under `assets/`

```
assets/
  art/
    _source/            .gdignore — .blend/.kra/.psd sources, never imported
      characters/<id>/  arenas/<id>/  vfx/  ui/
    characters/
      _shared/          rig reference .glb, palette slot template
      <id>/             char_<id>.glb, palettes, face, detail textures
    arenas/
      _shared/          cross-arena trim sheets
      <arena_id>/       geometry, unique panels, far-layer cards
    ui/
      icons/  panels/  portraits/
    fonts/              fnt_* files + their LICENSE / OFL.txt
  vfx/
    _shared/            hit spark, generic dust / steam
    <class>/            guard/, caster/, … — one folder per class primitive
  shaders/              owned by technical-artist
  PROVENANCE.csv        the ledger for §8.11 (one row per shipped asset)
```

The `.gdignore` in `_source/` is load-bearing: without it Godot tries to import
every `.blend`, which needs Blender on every machine and in CI.

### 8.4 Geometry budgets and construction

| Category | Art target | Hard cap (TA) [E] | Note |
|---|---|---|---|
| Operator incl. prop | 3–6k tris | **15k** (8k soft target) | Chamfered blocks across the 32-node canonical list (§8.2): 31 meshes (`root` is an empty pivot), so ~100–200 tris per part at the art target and ≤ ~480 average at the cap. Draw headroom is in §8.5. The outline pass draws vertices a second time, so effective cost is 2×. |
| Hand-pose variants | — | Inside the Operator cap | Hidden variants cost memory, not draw time |
| VFX mesh (slash arc, ribbon, shockwave) | Simple | ≤ 500 each; ≤ 3k on screen | |
| Arena, fight-band floor + backdrop | — | ≤ 40k | |
| Arena, above the band | — | ≤ 40k | |
| Arena, far background | — | ≤ 20k | Silhouette cards encouraged |
| Arena total | — | **≤ 100k** | |
| UI 3D (select, dossier) | — | Reuses the Operator `.glb` | Rendered in a SubViewport on those screens only |

Peak scene ≈ 2 × 15k × 2 (outline) + 100k + VFX ≈ 165k tris — easy for a desktop
GPU; the real limits are draw calls and overdraw.

**Construction rules:**

- **Character construction (clarifies §5.5):** one `.glb` scene per Operator; one
  rigid MeshInstance3D per part (pivot) under the shared node hierarchy; no
  skinning; no LOD variants.
- **Merge rule:** every sub-part that moves with the same pivot is one mesh (a
  boot plus its cuff, the torso plus its straps). Each pivot ends up as one draw.
- **Chamfers:** a single 45° bevel segment with hard edges, not rounded bevels.
- **Smoothed-normal bake (mandatory export step):** hard edges split vertices and
  an inverted hull tears open at every 45° bevel. Bake smoothed (averaged) normals
  into vertex color (glTF `COLOR_0`) — e.g. Blender Data Transfer or a script. The
  outline extrudes along that attribute; shading keeps the split normals. The toon
  material must **not** use vertex color as albedo. [M: `COLOR_0` → `COLOR`
  mapping and its precision.]
- **Godot import-time automatic LOD generation: off** for characters and arenas.
  Simplified meshes would destroy the chamfers.
- **Arena detail is authored per layer:** play plane and fight band = full modular
  geometry; above the band = same modules with fewer bevels; far layers = flat or
  low-relief cards or very low-poly silhouettes, never distant copies of full
  geometry. A far skyline baked to a card is an accepted compromise if far 3D
  layers prove costly (loses parallax, not legibility).

### 8.5 Draw calls, materials and shaders [E; 500 total from project config]

| Owner | Draw-call cap | Material slots |
|---|---|---|
| Per Operator | **≤ 80** (count below) | **≤ 2**: toon base (+ its outline `next_pass`; `prop_emblem` uses it too, switched by the `emblem_emission` instance uniform, §8.9), one alpha decal material (face, L2 trim). The emblem halo uses a shared VFX material (§8.9). |
| Two Operators | ≤ 160 | |
| Arena | **≤ 200** | ≤ 8 per arena: trim sheet, large painted surfaces, haze cards, glow sprites |
| VFX | ≤ 60 | ≤ 4 shared VFX materials project-wide |
| UI / HUD | ≤ 60 | |
| Headroom | ≥ 20 | Total 500 |

**Per-Operator draw count [E]** *(revised 2026-11-01 after AD-ART-BIBLE)*. 31 base
meshes + 30 outline hulls (`face` is a decal, no hull) = 61. Hand-pose variants
add 0 (one visible per hand replaces `hand_*`). Add the blob shadow (1) and the
emblem halo (1, always budgeted) = **63**, leaving **17 draws** for `ext_` nodes
(2 each: base + hull) and L2 trim decal surfaces (+1 each, only at L2). [M] The
Forward+ depth prepass may raise the monitor count; the Tier −1 spike measures one
Operator in the Performance monitor and this count is re-based on that number.

**Over 80, merge in this order.** Each merged node stays as an empty Node3D, so
shared animation paths still bind (§8.2):

1. `thumb_l` / `_r` into the hand-pose meshes (−4; the poses already carry the
   thumb).
2. Hair strands sharing a parent pivot, `hair_01`…`_06` down to no fewer than 2
   (up to −8; those strands lose their own swing).
3. `cloth_*` that do not swing independently (−2 each).
4. `neck` into `chest` (−2).

Never merge limb segments, `head`, `prop` or `prop_emblem` (silhouette doctrine;
the emblem needs its own toggle). The 80 cap is not raised per Operator; the
binding number is 160 for both Operators together, and taking draws from the ≥ 20
headroom needs technical-director sign-off.

- **Project-wide shader count ≤ 6:** character toon, outline, arena painted,
  VFX additive / emissive, unshaded glow sprite, UI. Enable the **Shader Baker**
  (4.5+ [V]) to avoid first-use compile hitches, which matter more on D3D12 (the
  Windows default since 4.6 [V]).
- **Shadows — ruling (2026-11-01): blob / decal contact shadow** under each
  Operator; **no real-time directional shadows** on characters. Saves ~25–50
  draws per Operator, reads floor contact and airborne state, fits the flat
  painted look.
- **P2 palette swap (§5.3):** a palette-row offset `instance uniform` in one
  shared material — no duplicate material, no extra texture [M: instance-uniform
  limit per material, believed 16].
- **Per-layer haze (§6.2):** Godot's depth / height fog is global, so haze is a
  per-layer uniform in the arena shader (lerp toward the haze color by layer). No
  volumetric fog [E].

### 8.6 Textures, import settings and VRAM

| Texture | Size | Import | Mipmaps | Filter | Note |
|---|---|---|---|---|---|
| **Character palette atlas** (P1 and P2 share one layout) | **256²**, 16×16 grid of 16 px swatches (64² with 4 px swatches as the floor; 512² hard cap) | **Lossless** | **Off** | **Nearest** | Fixed slot layout for all Operators: dark / mid / light masses, skin, hair, metal + specular band, emblem accent, emblem emissive, spares. UV islands collapse to swatch centres so neither filtering nor compression can bleed. Keeps §5.2 / §6.5 hex values exact for color-picker checks. **Not negotiable.** |
| **Face decal atlas** — *ruling 2026-11-01: 1024²* | **1024²**, 4×4 grid of 256 px cells, 8 px gutter: the 7 Tier 0 states, up to 3 richer close-up variants, spares | **Lossless** | On | Linear | Ultimate push-in puts characters at ~600–900 px tall; 256 px cells stay sharp. Gutter stops mip bleed. |
| L2 detail texture | 512² (256² floor, or merged into the face atlas) | Lossless | On | Linear | *TA: likely a UV2 overlay on the palette, fading out below L2 distance.* |
| Shared arena trim sheet (all 7 arenas) | 2048² (1024² floor) | VRAM Compressed (BC7) | On | Linear + anisotropic | Arena value caps are verified on in-engine screenshots, not hex |
| Per-arena trim + unique panels | 1 trim 2048², ≤ 4 panels at 2048×1024 | VRAM Compressed | On | Linear | |
| Far-layer cards | 2048×512 RGBA (1024×256 floor) | VRAM Compressed | On | Linear | Low-frequency silhouettes |
| VFX masks | 512² per primitive (256² floor), single channel R | VRAM Compressed | On | Linear | |
| VFX flipbooks (secondary only, §8.9) | 1024² at 8×8 (512² at 4×4 floor) | VRAM Compressed | On | Linear | |
| UI | SVG; raster authored at 2× the 1080p display size | Lossless | Off | Linear | |

- **Texel density, fight band:** ~1 texel per screen pixel at the default camera
  (0.5 accepted — painted shapes are large and soft, §6.2).
- **Color:** all color textures sRGB 8-bit; all masks imported as non-color.
- Import modes, BC7 under "high quality", mipmap and filter options are **[M]** —
  the reference docs do not cover the texture importer. 4.7 moved `get_format()`
  to `Texture2D` [V].
- **VRAM per match (2 Operators + 1 arena) [E, placeholder]:** characters ≤ 8 MB
  (raised slightly by the 1024² face atlases), arena ≤ 64 MB (a 2048² BC7 with
  mips ≈ 5.3 MB), VFX ≤ 16 MB, UI ≤ 32 MB → textures ≤ 128 MB; total VRAM incl.
  1080p render targets ≤ 512 MB. Load only the match's Operators and arena, never
  all 10 and 7.

### 8.7 Export and authoring settings

- **Scale:** 1 Blender unit = 1 m; transforms applied (object scale 1, rotation
  0); rest transform is identity.
- **Operator height:** a standing Operator (excluding ears, horns, prop) sits in
  one shared band, proposed **~1.2 m ± 0.1 m**. **The visual scale must match the
  unit of the sim's hitbox data** — gameplay and TA own the conversion; art
  conforms.
- **Axes and facing:** author in Blender Z-up; the glTF exporter converts to +Y
  up. Author facing glTF +Z (Blender −Y). Yaw (the 20–30° camera turn) and the
  facing mirror are applied by a parent node at runtime, never baked.
- **Pivots:** character root on the floor, centred between the feet at idle (the
  point the sim position maps to); each rigid part at its joint pivot, inside the
  parent block (§5.1); prop at the grip point; arena root at centre stage on the
  floor line; arena modules at bottom centre, snapped to a 0.25 m grid.

### 8.8 Animation

- **60 fps, one key per sim tick.** Keys on integer frames only. Frame 0 is the
  move's first startup tick; animation length equals the move's total tick count;
  active-frame keys land on the move data's active ticks (§5.4 rule 2, made
  checkable).
- **Import:** set the glTF importer's animation FPS to 60 [M: believed to
  default to 30 and resample]; animation compression **off** (or confirmed
  lossless) so poses are exact on the frame.
- **Channels:** rotation and translation only on part nodes. **No scale keys**
  (§5.4 rule 6) — a validation script checks this. No Skeleton3D, no skin, no
  blend shapes. Interpolation is free (Bezier for fast transitions, constant for
  holds); the exporter samples every frame.
- **Playback:** import into an `AnimationLibrary` (one shared library for common
  moves — valid because node paths are identical — plus one per Operator), played
  through `AnimationPlayer` (extends `AnimationMixer` [V]). The presentation layer
  **seeks to `tick / 60.0`** with a manual process callback, never wall-clock time
  [M: exact property name], so hit-stop and slow-mo never touch
  `Engine.time_scale`.
- **Face decal and hand-pose swaps — ruling (2026-11-01): a per-move
  tick → state table in presentation data**, not visibility keys in the `.glb`.
  Deterministic, editable without re-exporting, and avoids relying on glTF
  visibility animation.
- **Shared reaction animations — ruling (2026-11-01): allowed for Tier 0.**
  Hitstun, block and KO are shared across Operators through the shared rig and
  can be overridden per Operator later. Idles, walks, attacks and victories stay
  per Operator (§5.4 rule 7).
- **Placeholders** use the same names and pivots, so swapping in final art is a
  file replacement.

### 8.9 VFX, outline, bloom and backend

**VFX assets**

- **Primary effects are meshes, not flipbooks:** each class primitive (blade arc,
  ring, wall, zigzag…) is one simple mesh with a grayscale mask, animated in the
  shader (UV scroll, dissolve, wipe). Crisp at any zoom; makes the true-range rule
  (§3.2) exact.
- **Hit-trail and arc meshes are authored at unit length** (1 m along +X from the
  origin) so code scales them to the hitbox reach from move data. Not negotiable.
- **No class color baked into VFX textures:** masks are grayscale; color comes
  from the class palette as a shader parameter. One asset per primitive serves
  every Operator of that class.
- **The shared hit spark** (ivory four-point flash) is one asset in
  `vfx/_shared/`.
- **Flipbooks only for secondary, non-gameplay motion** (dust, steam, debris, the
  §6.5 pot steam); none may carry a class primitive or gameplay meaning. No generic
  radial-glow sprite as a primary effect (§3.2).
- **Particles [E]:** `GPUParticles3D` by default; `CPUParticles3D` only for
  emitters under 50 particles that need per-particle scripting. ≤ 2,000 live
  particles total, ≤ 300 per effect, ≤ 8 active emitters, arena ambient ≤ 200.
  Additive sprites average ≤ 64 px on screen, ≤ 3 stacked large layers. Over
  budget, reduce in this order: emission rate → per-effect cap → sprite size →
  flipbook resolution.
- **Replay / rollback safety:** VFX re-spawn reproducibly with
  `restart(keep_seed)` (4.4+ [V]); nothing in VFX ever reads back into the sim.

**Outline — ruling (2026-11-01): option A, per-part inverted hull.**

- **Cost:** one extra draw per part plus a second vertex pass (~2× character
  draws, already budgeted); < 0.5 ms GPU at 1080p [E].
- **Constant 2–3 px:** extrude in clip space scaled by `w`, so width stays in
  pixels at every zoom including the Ultimate push-in. Width is a uniform in
  pixels referenced to 1080p, scaled by viewport height.
- **Material:** `render_mode cull_front, unshaded`; color Ops Black #121212
  (§4.1); does not write to the glow mask. Extrudes along the baked smoothed
  normals (§8.4).
- **Consequence (amends §5.5):** per-part hulls also draw a line where one part
  overlaps another (an arm across the torso). These **part-contour lines are
  accepted as joint breaks**; no other interior lines are drawn.
- **Mirroring under scale −1 [M]:** Forward+ is believed to flip the front face
  for negative-determinant transforms, keeping both the base pass and the
  `cull_front` hull correct. **Not in the reference docs — must be proven by a
  Tier −1 spike screenshot in `production/qa/evidence/`** showing outline and
  lighting correct on both facings, before production art starts. Mirror on the
  world X axis only, at the Operator root (keeps the 20–30° turn). Lights are in
  world space and nothing lighting-related is baked into textures, so mirroring is
  otherwise safe. No physics body under the mirrored root (Jolt dislikes negative
  scale; the sim uses no physics anyway). **Fallback if the spike fails:** a
  silhouette-only post outline (stencil, 4.5+ [V], or a depth-based
  CompositorEffect [V]), ~0.5–1 ms [E].

**Emissive-only bloom (§4.6) — hue-preserving rule** *(revised 2026-11-01 after
AD-ART-BIBLE)*

- **Why this rule exists:** under the Linear tonemapper (white 1.0) each channel
  clips on its own, so scaling an accent above 1.0 shifts its hue. Vanguard
  #FF8A1F ×2 linear shows as ≈ #FFBD2E (H ≈ 41°, 4° from Guard Amber, against
  §4.2's 16°). Caster Violet drifts ≈ 261° → 276°, under §4.10's ≥ 40° gap.
  **Since 4.6 glow runs before tonemapping with screen blending [V]**, so
  threshold glow fed by > 1.0 values cannot fix this.
- **Emissive core = the exact §4.2 accent hex, never above 1.0 in any channel.**
  Gameplay emissive (skill-active emblem, VFX primitives) is unshaded at the
  accent value. Intensity animates only through alpha or coverage (wipe,
  dissolve, mask), never by multiplying color. Cores blend with alpha (mix), not
  additively, so overlapping cores and bright backgrounds cannot add up past 1.0.
- **The emblem** switches through the instance uniform `emblem_emission` in the
  shared toon material (§8.5). At 1 it outputs the palette's emblem-emissive
  swatch unlit (albedo, rim and specular off, swatch through EMISSION [M]); at 0
  it shows the lit emblem-accent swatch.
- **Glow is a separate layer, not post-processing:** a soft halo from the
  unshaded glow-sprite shader (one of the six, §8.5) — a falloff card or expanded
  shell behind the core, additive, in the same accent at ≤ 1.0 × falloff alpha,
  never covering the core's centre pixels. Cost: 1 draw per emblem (inside the
  Operator cap, §8.5); VFX halos count toward the VFX cap. Halo overdraw follows
  the particle rules above (≤ 64 px average, ≤ 3 stacked layers) [E].
- **WorldEnvironment glow: off for Tier 0.** Nothing in gameplay goes above 1.0,
  so threshold glow would have nothing to bloom, and turning it off saves a
  full-screen pass. Any later ambient-only use (arena signage) needs art-director
  and technical-artist sign-off, with its threshold above every gameplay value.
- **Lit surfaces (character toon, arena)** clamp their final color to ≤ 1.0 per
  channel (`clamp(color, 0.0, 1.0)`), which leaves palette hexes exact. Rim and
  specular bands are authored so no channel exceeds 1.0 before the clamp. Arena
  light energy must not push lit surfaces above 1.0 linear.
- **2D UI (CanvasItem) is exempt from every clamp in this section.** It is
  composited after the 3D tonemap and never enters the glow path [M], so the
  §4.2 / §4.8 hexes (255 channels included) and the §4.2 contrast table pass
  through unchanged. Conditions: HDR 2D stays off [M: `use_hdr_2d` /
  `rendering/viewport/hdr_2d`] and 4.7 HDR output stays off (feature [V]; setting
  name [M]).
- **Select and dossier SubViewports:** only the Operator model renders in 3D,
  under the in-game toon rules and Linear (white 1.0). Frame, tabs, class emblems
  and text are 2D CanvasItems outside the SubViewport and are never tonemapped.
  The only emblem inside it is the 3D `prop_emblem`, which follows the emissive
  rule above.
- **Emissive hue acceptance (Tier −1 spike; blocks production VFX).** Two retained
  screenshots in `production/qa/evidence/`:
  `emissive_hue_vanguard_guard_<date>.png` and
  `emissive_hue_caster_specialist_<date>.png`. Each shows both Operators' emblems
  skill-active plus their primary VFX, on the Tier 0 arena at the default camera,
  on D3D12 and Vulkan. Measure the median of a 5×5 px patch at each core centre
  and record the values beside the image. **Pass:** Vanguard → Guard ≥ 16° H
  (§4.2); Guard Amber cores inside the §4.3 band (H 42–48°, S ≥ 85, V ≥ 95);
  Caster → Specialist ≥ 40° HSV hue **and** luminance ratio ≥ 1.4 : 1 (§4.10);
  each core within ±2° H and ±3 S/V points of its §4.2 hex (diagnostic).
  Art-director signs off on the halo look on the same images.
- **Tonemapper: Linear (white 1.0).** AgX and Filmic would shift painted values
  and break §4.6's numeric S and V caps, which are checked with a color picker.
  [V: AgX gained controls in 4.6; the color-shift claim is a technical
  judgement.]
- **AA: SMAA 1x** (4.5+ [V]) keeps the 2–3 px outline crisp. No TAA (ghosts on
  fast motion [V]) and no FXAA (softens thin outlines).

**Backend.** D3D12 is the Windows default since 4.6 [V]; keep it, QA on both
D3D12 and Vulkan, and document a launch fallback to Vulkan [M: `--rendering-driver
vulkan` / project setting name].

### 8.10 UI assets and frame budget

**UI assets**

- **Chamfered panels and frames come from Godot styleboxes before any texture:**
  `StyleBoxFlat` with corner radius and `corner_detail = 1` should give a straight
  45° cut with no file to author (*ui-programmer: verify in 4.7*). SVG or
  nine-slice only for shapes a stylebox cannot draw.
- **Icons:** SVG on a 48 px grid (§7.5); class icons are our own primitives, no
  canon class icons. Each icon is drawn at its smallest display size first and
  must pass the §4.9 non-color check there.
- **No text baked into UI images** (§7.4).
- **Fonts:** SIL OFL or equally permissive; no canon Arknights fonts, logos or
  lettering. **UI languages — ruling (2026-11-01): Vietnamese + English from the
  start**, so every font must cover full Vietnamese diacritics and pass the §7.4
  `ĐƯỢC ẤN ỔN` test. MSDF rendering for large display type (*ui-programmer*).

**Frame-time budget (60 FPS, 16.6 ms) [E]**

| Slice | Budget | Note |
|---|---|---|
| Sim (pure GDScript, 60 Hz) | ≤ 2.0 ms | Listed so rendering does not spend it; future rollback re-simulation comes out of this slice |
| Render CPU (culling, submission, AnimationPlayer, particles) | ≤ 5.0 ms | |
| Render GPU at 1080p | ≤ 10.0 ms | Arena opaque 3.0, Operators + outline 1.5, VFX + overdraw 2.0, glow 1.0, AA 0.7, UI 1.0, headroom 0.8 |
| Headroom (OS, audio, frame pacing) | ≥ 1.6 ms | |

GPU numbers cannot be checked until a min-spec GPU is set.

### 8.11 Asset provenance and originality checklist (per asset)

Each shipped asset gets one row in `assets/PROVENANCE.csv`. **An asset with an
empty row does not merge.**

1. **Name and path**, per §8.2.
2. **Origin:** original (made for this project) or third-party.
3. **Author, date and tool** (e.g. "Blender 4.x", "Krita"), plus **references
   consulted** (R1–R5 from §9, or none) — *column added by §9, 2026-11-01*, so the
   §9.5.6 distance check is auditable.
4. **If third-party:** source URL; licence (CC0, OFL…) with the licence text
   committed; attribution required or not; modified or not. **Third-party is
   allowed only for fonts and utility textures (noise, masks)** — no third-party
   character, prop or arena art.
5. **AI-generated content — ruling (2026-11-01): banned for shipped art.** No
   AI-generated image, model, texture, icon or animation ships in the game. AI may
   be used for written ideation only.
6. **Canon check (characters, props, emblems, UI icons)** — each item ticked, not
   assumed:
   - □ The anchor list was written from text, at most 3 anchors (§5.6.1).
   - □ The silhouette was blocked with canon art off-screen (§5.6.4).
   - □ No tracing, overlays, color-picking or proportion-matching from canon art
     (§5.6.4).
   - □ No canon logos, insignia, patterns, lettering or distinctive garment cuts
     (§5.6.3).
   - □ Distance check passed: recognisable, not traceable (§5.6.5); reviewer and
     date recorded.
7. **Text check:** no readable text on models (§5.2.6); invented glyphs only,
   including signage (§6.4).
8. **Real-world marks:** no real-world brands, logos or trademarks anywhere,
   environment included.
9. **Sign-off:** art-director initials and date.

> **Open (user / producer):** the concept says to check Hypergryph's fan-content
> rules before distribution. They may add asset constraints (e.g. forbidding the
> official logo or any commercial use); fold any into this checklist when checked.

### 8.12 Conflict record (art-director vs technical-artist, 2026-11-01)

| Topic | Art-director | Technical-artist | Ruling |
|---|---|---|---|
| Naming prefixes | `char_` / `env_` / `vfx_` / `ui_` / `fnt_` + size suffix | `op_` / `arena_` / `vfx_` | **AD** |
| Face decal atlas | 1024² lossless, 256 px cells | 512² (1024² cap), lossless or BC7 | **AD** (1024² lossless) |
| Face / hand-pose swaps | Per-tick table in presentation data | Visibility tracks in the `AnimationLibrary` | **AD** (tick table) |
| Outline method | — (aesthetic call deferred to user) | A: per-part hull (cheap, part-overlap lines) or B: silhouette post outline (~0.5–1 ms) | **A**, with B as the fallback if the mirroring spike fails |
| Character shadows | — | Real directional (≈ +25–50 draws / Operator) or blob / decal | **Blob / decal** |
| Triangle budget | 3–6k ideal, accept ≥ 4k cap | 8k target, 15k hard cap | No conflict — art target inside TA cap |
| Material slots | ≤ 2 surfaces (body + emblem) | ≤ 3 (toon + outline `next_pass`, decal) | Merged: ≤ 3 (§8.5) |
| "One mesh per Operator" (§5.5) | Rigid part = mesh object | One mesh contradicts rigid parts without skinning | Clarified: one `.glb`, one rigid part per pivot (§8.4; §5.5 amended) |

**Still to verify in the 4.7.2 editor before relying on them:** every **[M]**
item above — notably negative-scale culling, texture-importer options, glTF
animation FPS default, the `AnimationMixer` manual-seek property, the
instance-uniform limit and `COLOR_0` precision.

## 9. Reference Direction

*Five references, all from the concept's Inspiration table and its non-game
inspirations. Each has a **lane** — one specific job, tied to the section it
serves — and may shape work only inside it. None may shape character, prop or
arena artwork directly; that comes from §3, §5 and §6, built from text anchors
(§5.6). §1.3 is binding: originality is non-negotiable.*

### 9.1 Summary

| # | Reference | Kind | Lane (what we take) | Serves |
|---|---|---|---|---|
| R1 | Arknights | Game (source IP) | **Language only:** class taxonomy, SP-type taxonomy, timed skills, the restraint of military-tech UI | Pillar 4; §1.2 A, §3.1, §4.9, §7.3 |
| R2 | Military operations dossiers and command screens | Non-game | **Document and terminal grammar:** file header, ruled data rows, mono stat blocks, status stamps, tracking brackets | §7.1, §7.4, §7.8, §2.2 (K.O. stamp) |
| R3 | Street Fighter 6 | Game | **HUD reading discipline:** fixed mirrored placement; every resource readable by shape as well as color; gauges that do not lie | §7.3, §7.6, §4.9 |
| R4 | Dragon Ball FighterZ | Game | **Ultimate world-layer choreography:** camera cuts landing on held key poses, light dropping to black, a hard snap back to the fight | §2.2 Ultimate, §5.4, §7.2, §8.8 |
| R5 | Anime action cut-ins and speed lines | Non-game (2D animation and comics tradition) | **The flat graphic layer of the title card:** diagonal panel split, face close-up panel, speed lines as a backdrop, used sparingly | §2.2 Ultimate title card, §5.4 face decals |

### 9.2 The references

#### R1 — Arknights (the language, never the artwork)

**What we take — concepts and discipline, never pixels:**

1. **The class system as an identity system.** Eight classes, each a distinct
   rule set, re-encoded as our own shape primitives (§1.2 B, §3.1). Canon class
   icons are not used and not echoed.
2. **The SP-type taxonomy** (auto / offensive / defensive charge) and **timed
   skills** as a state the player must read — expressed through our own non-class
   icon set (hourglass, impact spark, notched bar; §3.4) and fill textures (§7.3).
3. **Military-tech UI restraint as an attitude:** a dark, near-monochrome base
   where accent color is scarce and meaningful. Only the principle is borrowed;
   the palette comes from §4 and the vocabulary (brackets, chamfers, ruled lines)
   is generic geometry (§1.2 A).
4. **The Doctor's point of view:** the player as commander reading an operations
   feed. That sets the HUD's framing (§7.1), not its look.

**What we avoid (binding; repeats §1.2 A, §5.6, §7.8, §8.11 for anyone reading
only this section):**

- No canon artwork of any kind — character art, portraits, splash art,
  backgrounds, icons, emblems, UI frames — whether traced, overlaid,
  colour-picked, proportion-matched or screenshot-sampled (§1.2 A, §5.6.4).
- No canon **screen layouts.** If a menu, dossier, squad or result screen reads
  as a recreation of a specific canon screen, change its composition (§7.8).
- No **Rhodes Island logo**, faction marks, insignia, canon lettering or **canon
  fonts**; typefaces are open-licence, non-Arknights, chosen on their own merits
  (§7.4, §8.10).
- No canon **costume cuts or garment details** — at most three text-derived
  anchors per Operator (§5.6.1–3).
- No colors sampled from canon art to make an Operator "feel right"; recognition
  comes from the anchors' *mass and shape*, not hue matching (see Surtr, §5.6).
- **Fan art of Arknights is not a reference** — it belongs to its own artists and
  adds a second rights holder.

**The test:** a Doctor should say "this speaks Arknights"; nobody should be able
to say "this *is* that screen or that drawing" (§5.6.5).

#### R2 — Military operations dossiers and command screens (non-game)

**What we take — the grammar of documents and terminals, built from generic
forms:**

1. **The file header:** a top band with a file number, a section name and a
   ruled line with an end tick (§3.4 divider; §7.8 Bronze-Gold header rule). Every
   dossier screen starts with one.
2. **Tabular data discipline:** left-aligned labels, monospace values, aligned
   columns, no decoration inside a data row (§7.4, §7.8). Numbers sit on a grid.
3. **The photo-plus-record composition:** a fixed "file photo" on one side,
   structured fields on the other (§7.8: 5 + 7 columns) — a general document
   convention, not one specific form.
4. **The status stamp:** one word, all caps, boxed, applied once and left there
   (`READY`, `K.O.`, `PAUSED — 1P`; §2.2, §7.3). A stamp *lands*; it never types
   in letter by letter (§7.8).
5. **Command-screen tracking:** open brackets around a tracked object instead of
   a closed box (§3.4); a monochrome display where one alert color carries all
   urgency (§4.4).

**What we avoid:**

- **Real-world marks:** national flags, unit insignia, real organisation seals,
  real classification banners, real military map symbology. Our 1P triangle and
  2P rhombus (§4.7) are our own and must not be drawn or described as real
  symbology (§8.11.8).
- **Camouflage, rank chevrons, medal ribbons** (rank chevrons also collide with
  the Vanguard primitive, §3.4).
- **Green-phosphor CRT and blue-hologram clichés** — green and blue would occupy
  class hues as decoration, and §4.4 bans generic blue.
- **Redaction bars over readable information** — they read as "hidden",
  contradicting Pillar 3. Allowed only as non-text chrome in menus, never in the
  combat HUD.
- **Weapons realism and propaganda styling** — the dossier is a field operations
  record, which also suits Rhodes Island as a medical company.

#### R3 — Street Fighter 6 (HUD reading discipline)

**What we take — rules of reading, not visuals:**

1. **Fixed, mirrored placement:** each player's resources sit in the same place
   every match, mirrored across the centre, so the eye learns one path per side
   (§7.3).
2. **Each resource is readable without its color:** a depleted or locked state
   changes the gauge's *shape or texture*, not just its hue. We go further — SP
   type is a fill texture, Ultimate segments are vertical gaps, danger is hazard
   stripes plus a pulse (§4.9, §7.3, §7.6).
3. **Size equals priority:** HP is the largest, longest bar; secondary resources
   get thinner bars nearby (§7.3: 32 px HP, 24 px SP, 20 px Ultimate).
4. **A gauge's motion tells the truth** (§7.6 rule 1).

**What we avoid:**

- **Its graffiti, paint-splash and street-art identity**, including paint-burst
  VFX and spray-style UI ornament — the opposite of our flat chamfered language
  (§3.4), and multi-hue splashes break Clause A (§1.1).
- **Its layout geometry.** We use one top-corner cluster per player (§7
  conflict record); do not "correct" our layout toward a top/bottom split.
- **Its colors, fonts and gauge frames.**
- **Decorative color on the HUD** — every colored HUD pixel is a class accent on
  an SP bar or a state signal.

#### R4 — Dragon Ball FighterZ (Ultimate world-layer choreography)

**What we take — timing and camera grammar of a 2.5D super, world layer only:**

1. **Cuts land on held key poses:** the camera may move; the character *holds* a
   strong key pose through the cut, then snaps to the next (§5.4 held-pose style,
   §8.8 constant holds on integer ticks). No floaty in-between drift.
2. **Light as punctuation:** the world drops toward Ops Black and the owner is
   lit by one hard class-colored key from a low angle, while the opponent stays
   readable under neutral fill (§2.2). The darkening is the drama.
3. **A hard return:** the cinematic snaps back to the gameplay camera with no
   ease-out drift, so the player re-acquires the fight immediately.
4. **Shot budget — ruling (2026-11-01): at most three shots** in the ≤ 2.5 s
   (150 f) cinematic, each starting on a held pose.

**What we avoid:**

- **Length** beyond the ≤ 2.5 s cap (§2.2, concept).
- **Hiding, darkening or letterboxing the HUD** (§7.2 layer 5, §2.2).
- **Aura glow, screen-filling beams, environmental destruction** — radial glow is
  banned as a primary effect (§3.2), only gameplay blooms (§4.6.4), and arenas
  never break (§6.3).
- **Its rendering pipeline** — no hand-edited normals or high-detail anime faces;
  we are chamfered rigid-part chibi with a palette atlas and face decals (§5.4,
  §6.2, §8.4).
- **Its proportions, character designs and saturated sky palettes.**

#### R5 — Anime action cut-ins and speed lines (non-game)

**What we take — the flat 2D graphic layer of the Ultimate title card (§2.2,
§7.2 layer 3):**

1. **The diagonal panel split:** one or two flat panels cut on a strong diagonal
   across the fight viewport, following the 45° chamfer family (§3.4), clipped to
   the fight viewport (§7.3).
2. **The face close-up panel:** one panel shows the owner's face using the richer
   close-up face decal (§5.4) — the "eyes before the strike" beat.
3. **The class primitive is the hero shape of the card** (§2.2); panel edges and
   speed lines support it and never out-contrast it (§3.5).
4. **Speed lines — ruling (2026-11-01): parallel only, Ultimate title card only.**
   Straight lines drawn **behind** the class primitive, running along the owner's
   action direction, in the owner's class accent or Ivory at reduced opacity.
   Motion is a steady scroll at most — no flicker, no alternating-frame strobe;
   §7.6 photosensitivity limits apply in full. Not on skill activation, normal
   hits, K.O. (monochrome stillness, §2.2), victory, menus or character select.

**What we avoid:**

- **Radial focus lines converging on a centre** — at thumbnail size they form a
  ring or burst, reading as the Caster primitive or banned radial glow (§3.2,
  §3.3).
- **Speed lines outside the title card** — long thin lines are the Sniper
  primitive (§3.1); the card is a non-gameplay moment, so the conflict is
  contained there.
- **Big kanji or lettering splashes and onomatopoeia** — card text is limited to
  the Operator name and Ultimate name in §7.4 typefaces.
- **Imitating any particular studio's, series' or artist's cut-in look** — the
  tradition supplies devices; the compositions are ours, built from §3 primitives.
- **Screen tone, halftone dots, hand-inked line weight** — halftone collides with
  the Ivory dot grid for throwboxes (§4.8); inked line weight clashes with our
  uniform outline (§3.5).

### 9.3 How the references divide the work

| Visual question | Answered by | Not answered by |
|---|---|---|
| What concepts must a Doctor recognise? | R1 | R2–R5 |
| How does a menu or dossier screen organise information? | R2 | R1 (layouts), R3 |
| How does the combat HUD stay readable? | R3 | R1, R2 (chrome stays out of the HUD, §1.2 A) |
| How does the 3D world move and light during an Ultimate? | R4 | R5 |
| What does the flat 2D title card look like? | R5 | R4 |
| What do Operators, props and arenas look like? | **None** — §3, §5, §6 and text anchors (§5.6) only | Every reference |

No two references answer the same row. A new reference that would duplicate a
lane is not added.

### 9.4 Considered and excluded as visual references

- **Granblue Fantasy Versus** — cited by the concept for its input model and
  accessibility, not its look; its lush painterly arenas and tall anime
  proportions run against §3.1 and §6.
- **Under Night In-Birth** — cited for action-charged resources (GRD), a mechanic
  rather than a visual.

Both remain design references, not visual reference boards.

### 9.5 Reference hygiene (binding for every asset)

1. **Write the takeaway before you look:** one sentence naming the reference, its
   lane and the section it serves (e.g. "R4: cut on a held pose, §5.4"). Look,
   close the reference, then work from the sentence (§5.6.1 applied to every
   reference).
2. **References are on screen only during ideation and review**, never during
   production. **Never during blocking:** Operator and prop silhouettes (§5.6.4),
   emblem and icon drawing, HUD and screen wireframes, arena layout and title-card
   composition are all done with every reference closed. Animation timing may be
   studied by counting frames and noting numbers; video is never onion-skinned,
   rotoscoped or overlaid.
3. **No color from references** — no eyedropper on any reference image. Every hex
   comes from §4 or §6.5, every value from the §4.6 and §6.2 budgets.
4. **No tracing, overlays or proportion matching** from any reference, canon or
   not (§5.6.4).
5. **A reference is used only inside its lane** — R3 never informs a character,
   R4 never informs the HUD, nothing in §9 informs Operator, prop or arena artwork
   (§9.3).
6. **The distance check covers every referenced asset.** Before sign-off, put the
   asset beside each reference it drew on; if a viewer would name that reference
   for that asset, change the composition (§5.6.5, §7.8). Record the reviewer,
   date and **references consulted** in the asset's §8.11 row.
7. **Reference images stay out of the project** — no screenshots, captures or
   downloads in `assets/`, the build or version control. Reference boards stay
   local and outside the repository.
8. **No AI anywhere in the reference path** — no image generation from reference
   images or "in the style of" prompts, no AI upscaling or editing of captures
   (§8.11.5).
9. **Placeholders follow the same rules** — never a reference image or a canon
   asset dropped in temporarily (§1.3).

> **Open (user):** Hypergryph's fan-content rules are still unchecked (§8.11).
> Any constraint they add, e.g. on logos or commercial use, may tighten R1's
> avoid list.
