# Hit Detection & Damage

**Status: Draft (reverse-documented from code at commit `43bc718`; code-chosen rules decided 2026-11-11 by the user, H2/H3 implemented at layout 5; not yet design-reviewed).** Foundation · systems index #6. Drafted by Codex 2026-11-10, checked against code 2026-11-11. Tier −1 covers two grounded mirror-kit fighters using Light, Heavy and Block (code unchanged since `ed6568f`, layout 4). Design review and ADR-0001/0002 acceptance are pending.

## Overview

Once per live combat tick, resolve both fighters' active strike boxes against the opponent's hurtboxes. The output is a contact result per attacker, HP loss where applicable, and personal hit-stop. Movement applies the resulting stun and displacement. Round & Match reads the resulting HP after both contacts have resolved.

## Player Fantasy

A Heavy that just misses the opponent's coat should whiff every time at that spacing. If both blades connect on the same frame, both fighters take the hit. A clean hit should read differently from a guard through the HP change, reaction and length of the pause.

## Detailed Rules

1. **Sample.** Use the state after Movement, Attack advance and Defense. Read each fighter's own move ID, one-based frame, feet position and facing. The neutral pose uses frame 1. Move Data supplies read-only hitbox and hurtbox lists for that frame. Personal hit-stop suppresses a fighter's own strike check. Global freeze skips the whole slot.
2. **Gather.** For each attacker, take the first overlapping strike/hurt pair. Resolve one outcome per swing in this mirror kit. Multiple overlapping boxes still produce one contact. A prior miss leaves the remaining active frames eligible. Attack start, cancellation or round reset clears the contact latch for the next move.
3. **Classify.** Read both guard flags before mutating either fighter. No overlap gives a whiff. Overlap against guard gives Block. Other overlap gives Hit. Gather both attackers' outcomes first, then write records in player order. An interruption on this tick cannot erase an opposing strike already gathered.
4. **Apply.** A hit consumes the swing, subtracts HP, interrupts the defender's active attack, clears blockstun and requests hitstun and defender knockback. A block consumes the swing, deals zero chip in the current kit, sets blockstun and requests attacker recoil. A whiff produces neither damage nor a new stop. Defense specifies guard eligibility and frame advantage in [Defense](defense.md).
5. **Time.** Hit Detection decrements an existing personal stop once in the hit-resolution slot on a live combat tick, before applying new contacts. On the contact tick, install the new stop at full length for both participants. If multiple contacts request stop, keep the largest applicable remaining duration. Movement and Attack resume their own advance on the tick after the last stopped tick. Personal stop holds hitstun/blockstun and knockback advance. The round clock still advances. Global freeze holds all these counters and the clock.
6. **Publish.** Layout 4 reserves six records × eight words: two character sources and four future projectile sources. The slice uses the first word of each character record: zero for no contact, positive move ID for Hit, negative move ID for Block. The defender is the opposite slot. Consumers obtain reaction values from the same hashed move table. Hit resolution overwrites both character records each live combat tick. Reactions and round checks see this tick's outcomes. Attack and Defense see the previous live tick's records until overwrite, including on the first tick after global freeze (Sim Core EC-30).

**Events (Decided 2026-11-11, user; implemented).** `HIT` / `BLOCK` (critical): a0 = attacker + 2 × move ID (defender = other slot), a1 = HP actually removed (0 on block), a2 = contact point, the centre of the first contacting hitbox ∩ hurtbox overlap rectangle in half-su, packed with x and y ([Sim Core](sim-core.md) Events note). `ATTACK_START` and `WHIFF` (observation) are defined there too: WHIFF is once per attack on the first tick after its active window ends with no `HIT`/`BLOCK`; blocked or interrupted attacks never whiff.

**Later-tier contract [Proposed].** For `ULTIMATE_HIT`, propose the same arguments as `HIT`. Tick and type come from the event header. Character contacts are critical; projectile contact cues are observational. I5 permits one character contact event per attacking character per tick. I2 substitutes `ULTIMATE_HIT` for the first clean character hit of an activation, once per activation. A blocked or missed Ultimate never starts cinematic freeze. SP owns the activation/charge and freeze request. Keep presentation events separate from gameplay hit records (Sim Core rules 18–19).

## Formulas

- All geometry uses signed integer sim units (10,000 su/m). For either box, world centre is `(feet_x + facing × local_x, feet_y + local_y)`. Overlap requires **both** `abs(ax − bx) < a_hw + b_hw` and `abs(ay − by) < a_hh + b_hh`. Edge or corner contact alone is a miss.
- Mirror-kit damage on a clean hit: `hp_after = max(0, hp_before − base_damage)`. Applied damage is `hp_before − hp_after`. At 40 HP, a 60-damage Light removes 40 HP. Hit-stop equals the move's stop value on Hit and `div_floor(stop, 2)` on Block.
- **Combo scaling [Proposed, Tier 0].** Represent a per-hit multiplier in permille. Compute `scaled_damage = SimMath.mul_permille(base_damage, scale)` before the HP clamp. The slice is equivalent to scale 1000 for every hit. For a future combo readout, sum applied HP loss and count clean hits while the defender remains in the same combo. Review reset timing, scaling curve, minimum damage and combo-Ultimate damage bound together before introducing combo state.

## Edge Cases

| Situation | Expected outcome |
|---|---|
| Defender changes hurtbox on the contact frame | Sample that frame on both sides. A miss on frame 6 can become a hit on frame 7. |
| Hit and KO on the last clock tick | Resolve all contact and HP changes first. Round & Match owns KO, timeout, double-KO draw and score. |
| One player in personal stop | The other can still advance on a live tick. Stop itself grants no invulnerability. |
| No active boxes or both fighters separated | Write zero for each attacker that whiffs. No stale contact may repeat damage. |
| Round restarts after a draw | Restore kit HP, clear contact records, latches and combat timers; Round & Match retains the score. |

## Dependencies

| Owner | Contract |
|---|---|
| [Sim Core](sim-core.md), Move Data Pipeline | Fixed slot order, integer buffer and replay checksum; validated frame tracks and replay-header data hash before match start. |
| Attack / [Defense](defense.md) | Attack advances the move and owns cancellation. Defense supplies this tick's guard flag before gather. A future confirmed cancel consumes a clean-hit record on the next live tick. |
| [Character Movement](character-movement.md) | Movement owns positions/facing, applies hitstun and knockback in reactions (M16/F7), then resolves bounds. Block pushes the attacker away. |
| Round & Match, SP, Presentation | Round owns KO and wins. SP will consume contact outcomes for charging and skill interrupts. Presentation will read critical events via SimView; audiovisual feedback never changes overlap. |

## Tuning Knobs

Current integer values come from the [mirror kit](../../data/moves/tier_minus_one.cfg). They describe executable behavior; balance and feel are provisional.

| Move | Active frames / total | Damage | Stop hit / block | Hitstun / blockstun | Initial hit KB / block recoil (su/tick) |
|---|---|---:|---|---|---|
| Light | 6–8 / 16 | 60 | 6 / 3 | 15 / 8 | 600 / 800 |
| Heavy | 12–15 / 29 | 140 | 12 / 6 | 22 / 6 | 1,400 / 400 |

Heavy also has an arm hurtbox on frames 12–29: centre (6,000, 9,750), half-size 2,000 × 2,750 su (H3, provisional; safe range: forward edge 6,000–9,000 su, beyond Heavy's own 16,500 reach it would make Heavy trade badly). Input buffer `Combat.BUFFER_TICKS` = 6 live ticks (H2, provisional; safe range 3–8: lower drops presses, higher causes unwanted delayed attacks).

Start HP is 1,000. KB deceleration is 100 su/tick. Changing tuning or frame geometry changes the move-data hash; regenerate the fixture when the kit changes. Tune hit-stop with input responsiveness and hit/guard recognition in a two-player playtest.

## Rules chosen in code — decided 2026-11-11 (user)

User decision 2026-11-11: change H2 and H3, keep every other row. Before that, no approved doc (concept, systems-index briefs, Sim Core, Movement GDD, ADRs) decided these. The code chose them. Cite: `combat.gd` = `src/sim/combat.gd`, `round_flow.gd` = `src/sim/round_flow.gd`, `movement.gd` = `src/sim/movement.gd`, kit = `data/moves/tier_minus_one.cfg`.

| # | Rule | What code did at `43bc718` | Conflict with a decided rule? | Decision 2026-11-11 (user) |
|---|---|---|---|---|
| H1 | Same-tick trade | Both contacts gathered before any write; both take full damage and both get stop (`combat.gd:resolve`). | None. | **Decided: keep.** |
| H2 | No input buffer | A press counts only as a fresh edge on a tick where `attack()` runs. Presses during hit-stop, stun, an active move or held Block are dropped (`combat.gd:attack`). | **Yes, soft:** concept lists "input buffer" among combat features. | **Decided: change → 6-tick buffer (layout 5).** A fresh Light/Heavy press edge (Heavy wins a same-tick press; the newest press replaces an older one) is stored with age 0 in the player's own region (`PF_BUF_MOVE`, `PF_BUF_AGE`, sim-core rule 5) on every live tick, including hit-stop, stun and an active move. Age +1 per live tick; it expires when age > 6 (usable on the press tick and the next 6). It is consumed on the first tick the character can act (no hit-stop, move finished, hitstun = blockstun = 0): the move starts on frame 1, or the press is **dropped** if Block is held that tick. Block is a held state, never buffered. Global freeze does not age it (`combat.gd:_buffer_press`, `attack`). |
| H3 | Attack hurtbox = idle hurtbox | Light/Heavy hurtbox is the neutral box on every frame (kit `hurtboxes`). Whiffs can only be punished at the body. | None, but weakens "whiff = punishable". | **Decided: change → Heavy arm hurtbox, frames 12–29 (active + recovery),** centre (6,000, 9,750) su facing-local, half-size 2,000 × 2,750 (provisional). Heavy whiffs at ≥ 16,500 su; a Light now reaches the arm at < 18,500 su (6,500 + 4,000 + 6,000 + 2,000). Window at 17,000 su: Light pressed 4–23 ticks after the Heavy press connects (on Heavy frames 12–29) (kit `heavy.hurtboxes`). |
| H4 | Damage | Light 60, Heavy 140, start HP 1,000, no scaling (kit). | None. | **Decided: keep.** |
| H5 | Chip damage | Zero; Block loses no HP (`combat.gd:apply_hit`). | None (Throw is the anti-turtle tool). | **Decided: keep.** |
| H6 | Hit-stop | Same length on **both** fighters: Light 6 / Heavy 12 on hit, `div_floor(stop, 2)` = 3 / 6 on block. Round clock keeps running (`combat.gd:apply_hit`, `round_flow.gd:check`). | None. | **Decided: keep.** |
| H7 | Hitstun | Light 15, Heavy 22, overwritten (not added) on re-hit (`movement.gd:reactions`). Derived on-hit advantage Light +5…+7, Heavy +5…+8. | None. | **Decided: keep.** |
| H8 | Knockback | Defender pushed along the attacker's facing: Light 600, Heavy 1,400 su/tick, −100 per moving tick (≈2,100 / 10,500 su total); clamped at the wall, no transfer (`movement.gd:reactions`). | None. | **Decided: keep.** |
| H9 | Hit interrupts | A clean hit cancels the defender's move on any frame (no armor) and clears blockstun (`combat.gd:apply_hit`). | None (matches counterplay floor). | **Decided: keep.** |
| H10 | One contact per swing | Contact latch per move; multiple boxes/frames hit once (`combat.gd:contact`). | None. | **Decided: keep.** |
| H11 | Facing during stun | Facing is locked only while attacking or airborne; it may turn during hitstun/blockstun (`movement.gd:_next_facing`). Movement open question. | None. Moot in Tier −1: no jump, pushboxes block passing. | **Decided: keep.** |
| R1 | Tie / double KO | Equal HP at timeout or double KO → replay the same round number, no point (`round_flow.gd:check`). | None (concept only says higher HP% wins). | **Decided: keep.** |
| R2 | Match and round shape | First to 2 wins (Bo3); 5,940-tick clock (99 s); 90-tick interval; spawn at ±15,000 su (3 m apart) (`round_flow.gd`, `movement.gd:init`). | Matches Bo3 + "higher HP% wins". | **Decided: keep.** |
| R3 | KO timing | KO and timeout checked after hit resolution and reactions each live tick; HP floors at 0. | None. | **Decided: keep.** |

## Acceptance Criteria

| ID | Independent oracle | Evidence at draft |
|---|---|---|
| HD1 | From neutral, two point-blank Lights leave both at 1,000 HP through tick 5 and at 940 with 6 stop ticks on tick 6. | Covered by `test_light_trade_connects_on_sixth_tick_for_both_players`. |
| HD2 | Heavy at 16,500 su centre distance just touches and misses. At 16,499 su it deals 140 in either facing. | Covered by `test_heavy_mirrors_and_exact_edge_whiffs`. |
| HD3 | Moving Heavy's hurtbox out of Light range on frame 6 alone delays contact to frame 7 and changes data compatibility. | Covered by `test_one_hurtbox_frame_changes_contact_and_refuses_old_replay`. |
| HD4 | Restore a snapshot during hit-stop and replay the same words. Every subsequent checksum matches. | Covered by `test_snapshot_during_hitstop_resumes_identically`. Cross-machine layout-4 verification remains open. |
| HD5 | Two lethal Lights on the last clock tick produce a draw, then replay the round at full HP with unchanged scores. | Covered by `test_final_tick_trade_double_ko_replays_same_round`. |
| HD6 | Multiple boxes or multiple active frames from one swing deal damage once. Freeze for N ticks across a contact preserves the records through the next live tick's early slots. | [Unverified] Add direct multi-box and EC-30 integration oracles. |
| HD8 | H2: whiffed Light (16 frames) pressed again at tick 10 starts on tick 16 (first actionable tick); pressed at tick 9 (age 7) it does not. Defender of a blocked Heavy pressing Light 6 ticks before its first actionable tick T (while in stop or blockstun) starts Light on T, not before; 7 ticks before, nothing starts. With Block still held on T the press is dropped. | Covered by `combat_decisions_test.gd` (3 buffer tests). |
| HD9 | H3: Heavy at 17,000 su never connects; a Light pressed k ticks after the Heavy press hits exactly for k = 4…23, for both player slots. | Covered by `test_whiffed_heavy_is_punished_by_light_in_frame_window`. |
| HD7 | Future event drain reports one critical character contact per attacker, including simultaneous hits; the first Ultimate hit generates exactly one critical event for that contact. | BLOCKED on SimEvents and the combat Ultimate. |

Evidence sources: [combat tests](../../tests/unit/movement/tier_minus_one_combat_test.gd), [replay tests](../../tests/integration/sim_core/sim_core_replay_test.gd), [hit resolution](../../src/sim/combat.gd).

