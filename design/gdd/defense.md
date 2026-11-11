# Defense

**Status: Draft (reverse-documented from code at commit `43bc718`, not yet reviewed).** Foundation · systems index #8. Drafted by Codex 2026-11-10, checked against code 2026-11-11. Tier −1 implements held Block against grounded Light and Heavy. The approved concept also requires movement, Throw/throw tech and skill interruption for the combat slice at Tier 0. Those interactions are specified here for their future owners. Prototype animation alone does not satisfy a gameplay criterion.

## Overview

Defense decides whether a fighter is guarding when a strike lands. A well-timed hold should absorb the strike, cost the defender time in blockstun, and eventually give back enough space to act. At Tier 0, committing to guard exposes the defender to a close Throw. See the [contact contract](hit-detection-damage.md) for damage, hit-stop and same-tick trades.

## Player Fantasy

“I saw the swing and had an answer.” The player can hold through a Heavy, release and contest its recovery. Against repeated Lights, the attacker recoils until another attempt needs a step forward. At Tier 0 the defender also has a reason to move or challenge before the opponent gets into Throw range.

## Detailed Rules

1. **Guard input.** Sample the held Block bit from this tick's input word. The mirror kit has one direction-independent, grounded guard. Block plus a direction suppresses voluntary walking. Block plus an attack press on the same free tick selects guard; that press is dropped, not buffered. Holding Block does not cancel an attack already in progress.
2. **Slot and eligibility.** Confirm Sim Core rule 10a: Defense runs after attack advance, before projectiles and hit resolution. On each live combat tick outside personal stop, set the guard flag if Block is held, no attack is active and hitstun is zero. During personal stop retain the previous flag; during global freeze the entire slot is skipped. Input history still records the raw words. Defense owns the guard flag and will own the throw-tech window.
3. **On a blocked strike.** Hit Detection reads this tick's flag, records Block, leaves HP unchanged, installs blockstun and sets personal stop on both fighters. Movement applies recoil to the attacker. Blockstun prevents new attacks and voluntary movement. In layout 4 the flag is sampled during blockstun: releasing Block can expose the defender to a later strike before they can act. Whether the final kit should retain guard through blockstun remains a review decision.
4. **Pressure and punishment.** The decided design bound is Light ≤ 0 on block, Heavy and Specials negative. The fastest defending Light can contest a repeated Light if in range. A negative move becomes punishable by a particular move only when its startup and reach fit the opening. Full-combo punishment is required for blocked Ultimate or whiffed Throw.
5. **Counterplay floor, Tier 0.** Walking or jumping out of range makes a Throw whiff. Throw bypasses guard at short range, starts slower than the fastest Light and has no invulnerable startup. A clean strike during startup interrupts it. A target in hitstun, blockstun or airborne cannot be thrown. A caught defender can press Throw within a short tech window; on tech, neither loses HP and both separate to neutral. A successful Throw also separates to neutral and cannot continue a combo.
6. **Skill and Ultimate answers, Tier 0.** Defense defines Block, movement and clean-hit interruption as the floor for every Operator. SP/Skills owns each active skill's clean-hit threshold. A raw Ultimate starts slower than Heavy, is vulnerable throughout, can be blocked or spaced, and loses the spent gauge on startup interruption. Only a clean character hit starts its freeze. A confirmed clean-hit cancel may combo into Ultimate; guarding the opener denies that route. Perfect Guard and Dodge are optional, cut-first additions. They are unnecessary for any baseline counterplay test.

## Formulas

**On-block advantage in actionable live ticks.** Let `D` be move duration, `f` the one-based contact frame and `B` blockstun. The attacker has `D − f` further attack frames. Both players take the same contact stop, so attacker advantage is `B − (D − f)`. Positive means the attacker can start the next attack first. Measure with fresh input edges, stationary players and no cancels.

| Blocked move | First active frame | Last active frame | Consequence |
|---|---:|---:|---|
| Light (D=16, B=8) | 8 − (16 − 6) = −2 | 8 − (16 − 8) = 0 | Late contact gives a simultaneous first actionable tick. |
| Heavy (D=29, B=6) | 6 − (29 − 12) = −11 | 6 − (29 − 15) = −8 | Check spacing before committing to the punish. |

**Escape from repeated Lights [derived from current kit].** On open ground each blocked Light requests recoil of 800 su/tick, decaying by 100 to zero. Over eight movable ticks the attacker retreats `800 + 700 + … + 100 = 3,600 su`. At minimum centre distance 5,000 su, Light reaches strictly below 13,000 su (6,500 centre offset + 4,000 strike half-width + 2,500 hurt half-width). Without approach inputs or wall clipping, three blocks give distances 8,600 → 12,200 → 15,800 su. Thus **N = 3** at closest spacing for this kit. Fresh approaches and future kits require their own bound.

## Edge Cases

| Situation | Ruling |
|---|---|
| Block pressed on an otherwise free tick when contact is gathered | Guard applies on that tick. Pressing it after contact cannot undo HP loss. |
| Release during hit-stop | Existing flag persists through the stopped ticks. First eligible defense slot samples the current held word. No attack is queued by holding Block. |
| Defender's back at wall | Attacker recoils toward open space. Verify the same three-block bound with both player slots and both stage orientations. |
| Attacker's back at wall | Current Movement clamps attacker recoil. At point blank the open-ground bound can fail. **[Proposed]** Transfer only the clipped recoil to the defender in the opposite direction, up to available space, then resolve pushboxes. Movement owns the displacement. This needs design review and a regression test before claiming universal escape. |
| Throw and strike on the same tick | A strike hitting Throw startup interrupts. **Open:** arbitrate already-active Throw versus strike and simultaneous active Throws symmetrically before Tier 0. Resolve both candidates before writes. |
| Hit-confirm or tech across a freeze | Early slots read the last live tick's contact records (EC-30). **[Proposed]** Count the tech window in live ticks and define how buffered Throw presses are consumed with Input/Attack before implementing it. |

## Dependencies

- **Input and Attack** provide current held/pressed words and attack state. Attack owns move startup, recovery and cancels. Defense consumes previous live-tick records only if needed for an early-slot decision.
- **[Hit Detection & Damage](hit-detection-damage.md)** classifies guard at contact. Under Sim Core I5, a character contact resolves to one of `HIT`, `BLOCK`, or `THROW_CONNECT`. For a future Throw connect, propose attacker slot, defender slot and move ID as the event's three arguments. Tech outcome and event timing still require agreement with Attack and SimEvents.
- **[Movement](character-movement.md)** owns voluntary motion, facing, bounds and recoil in reactions. **SP/Skills** consumes distinct Hit/Block results for charge and skill interruption. **Presentation** needs distinct guard pose, impact cue and release; its animation cannot grant guard.
- **[Sim Core](sim-core.md)** owns freeze gating, slot order and replay checksum. Round setup clears guard, stop and stun. Throw/tech state will need explicit layout fields, a layout bump and regenerated fixture when implemented.

## Tuning Knobs

| Knob | Tier −1 baseline / decision owner |
|---|---|
| Blockstun / block stop | Light 8 / 3 ticks; Heavy 6 / 6 ticks. Frame data and hit-stop tuning live in the [mirror kit](../../data/moves/tier_minus_one.cfg). |
| Attacker recoil | Initial Light 800, Heavy 400 su/tick. Movement deceleration 100 su/tick. Recalculate escape after changing reach, width, recoil or deceleration. |
| Throw and tech | Range, startup, whiff recovery, tech window and separation are open Tier 0 tuning. Test against fastest Light, walking escape and a full punish at the actual spacing. |
| Skill interruption | Threshold is per skill. Review each Operator's answer with SP/Skills. Keep optional Perfect Guard/Dodge outside this budget. |

## Rules chosen in code, awaiting user approval

Code: `src/sim/combat.gd` (`attack`, `defense`, `apply_hit`), `src/sim/movement.gd` (`step`, `reactions`, bounds), kit `data/moves/tier_minus_one.cfg`. Conflicts first.

| # | Rule | What code does today | Conflict with a decided rule? | Recommendation |
|---|---|---|---|---|
| D1 | Pushback escape in the corner | Recoil is clamped at the attacker's wall and not transferred. With the attacker backed to a wall, 4 of 4 Lights were blocked (DF4). | **Yes:** systems-index "after at most N blocked Lights the attacker is out of reach" fails. | Change: transfer clipped recoil to the defender (Edge Cases, Proposed); add a regression test. |
| D2 | Throw | Not implemented. | **Yes, scheduled:** concept Throw triangle is "never cut". | Implement at Tier 0 (rule 5); keep out of Tier −1. |
| D3 | Guard during blockstun | Guard is re-sampled every free tick from the held bit, so releasing Block during blockstun leaves the defender hittable (`combat.gd:defense`). | None decided. | Change: keep guard on for the whole blockstun (standard; removes an invisible trap). |
| D4 | Block input | Separate button (bit 16), direction-independent, no high/low; blocks Light and Heavy alike (`movement.gd:INPUT_BLOCK`). | None (Input GDD not written). | Keep for Tier −1; Input GDD confirms. |
| D5 | Block vs walk / attack | Holding Block stops voluntary walking and ignores attack presses; it does not cancel a move already started (`movement.gd:step`, `combat.gd:attack`). | None. | Keep. |
| D6 | Light on block | −2 (first active frame) to 0 (last active frame), measured (DF3). | Matches "Light ≤ 0". | Keep. At 0 both may press Light on the same tick: symmetric trade (TD tie-break note; see [H1](hit-detection-damage.md)). |
| D7 | Heavy on block | −11 to −8, measured (DF3). | Matches "Heavy minus". | Keep. Whiff-punish depends on [H3](hit-detection-damage.md). |
| D8 | Blockstun / recoil | Light 8 / 800, Heavy 6 / 400 su/tick, −100 per moving tick; N = 3 open ground, whole su (Formulas). | Matches escape rule mid-screen. | Keep. |

## Acceptance Criteria

| ID | Independent oracle | Evidence at draft |
|---|---|---|
| DF1 | Hold Block before a point-blank Light connects. HP stays 1,000, blockstun starts at 8, stop at 3. First mobile recoil tick moves the attacker back 800 su. | Covered by `test_block_stops_damage_and_held_light_does_not_retrigger`. |
| DF2 | Swap player slots and mirror positions/inputs through hit and block. HP and counters agree; X positions have opposite sign. | Covered by `test_swapping_players_mirrors_hit_block_recoil_and_hp`. |
| DF3 | For earliest/latest Light and Heavy contact, count the first fresh attack accepted on each side. Differences equal −2/0 and −11/−8 respectively. | [Measured] Godot 4.7.2, Windows Debug. On each tick after contact, restore a scratch snapshot and press fresh Light on both sides. First accepted offsets (attacker, defender): (14,12), (12,12), (24,13), (21,13). |
| DF4 | Start at 5,000 su separation, hold guard and repeat Lights without walking. The fourth Light whiffs on open ground and with defender at either wall. Repeat with attacker backed to a wall. | PARTIAL [Measured]. Four fresh Lights spaced 40 ticks apart, held Block, no movement input: block/block/block/whiff at centre and defender wall in both orientations. At the attacker wall all four were blocked. The proposed recoil transfer is pending review. |
| DF5 | Release during blockstun while another strike becomes active. Record whether guard holds on each tick, including personal stop. | [Unverified] Current sampling rule documented; final behavior pending review. |
| DF6 | Tier 0 Throw beats stationary guard, loses to an interrupt in startup, whiffs against retreat/jump; throw tech deals zero damage and restores neutral. | BLOCKED on Attack/Defense Throw and tech implementation. |
| DF7 | For each skill demonstrate a clean-hit interrupt. Raw Ultimate can be interrupted, blocked or spaced; only a clean hit freezes. Demonstrate a full punish after block/whiff using legal inputs. | BLOCKED on gameplay skills/Ultimate and cancel data. |

Evidence sources: [combat tests](../../tests/unit/movement/tier_minus_one_combat_test.gd), [guard sampling](../../src/sim/combat.gd), [reaction and wall handling](../../src/sim/movement.gd), [approved counterplay rules](game-concept.md).

