## Gate Check: Concept → Systems Design

**Date**: 2026-10-31
**Checked by**: gate-check skill
**Workflow**: full · **Review mode**: full · **Panel**: 4 of 4 directors

### Required Artifacts: 3/3 present
- [x] `design/gdd/game-concept.md` — exists, 456 lines, real content
- [x] Game pillars — in the concept: 4 pillars with design tests, priority order, anti-pillars
- [x] Visual Identity Anchor — in the concept: one-line rule + 3 supporting principles

Recommended (not blocking):
- [ ] Concept prototype with `REPORT.md` PROCEED — absent (`prototypes/` does not exist)

Observation: `artifact-check.sh --phase concept` also lists `art-bible` and `map-systems`
as required concept-phase steps (both ABSENT). This gate's definition does not list them,
so they are not counted as blockers here; the mismatch between the two sources is recorded.

### Quality Checks: 4/5 passing
- [x] Core loop described (`## Core Loop`)
- [x] Target audience identified (`## Target Player Profile`)
- [x] Visual Identity Anchor has a one-line rule and ≥2 principles
- [x] Tests — gdUnit4 6.2.2, `framework_sanity_test.gd`: 2/2 PASSED, exit 0 (run during this gate)
- [ ] Concept reviewed by `/design-review` — never run

### Director Panel Assessment

Creative Director:  CONCERNS
  Pillars and core fantasy are sound and all four CD-PILLARS fixes are in the text. Run
  `/design-review` before `/map-systems`. The SP system GDD must define all three SP types
  (incl. Defensive turtling risk). Each Tier 0 skill must be answerable with Block + movement
  alone, since Perfect Guard/Dodge are first cuts. The Ultimate has no defined resource.

Technical Director: CONCERNS
  Concept is viable on Godot 4.7.2 / GDScript (pure-GDScript sim, refcounted no-GC snapshots,
  PacketPeerUDP, 64-bit float determinism on one Windows build). Concept text still says the
  engine is undecided. Combat GDDs must express time in ticks, keep hitbox data external and
  RNG seeded in sim state. CI has not run on GitHub yet.
  (Two TD findings were checked against the repo and removed as incorrect: CLAUDE.md already
  shows Godot 4.7.2 / GDScript; `Godot/*.exe` and `.godot/*` are gitignored and `Godot/.gdignore` exists.
  One valid addition: the `commands` TODO comment in project.yaml still says "not installed yet".)

Producer:           CONCERNS
  The concept's own plan puts the Tier −1 prototype before `/map-systems`; entering Systems
  Design now reverses that. Time-box Systems Design (2–3 weeks, counted against the Tier −1
  window), write full GDDs only for what Tier −1 needs, mark other formulas provisional.
  The float vs fixed-point ADR must land before combat formulas are finalised.

Art Director:       CONCERNS
  Anchor is strong. Red is reserved for danger but Vanguard's accent is red-orange; class
  palette has no hex values or colourblind check; P2's bronze frame reuses a world neutral.
  Run `/art-bible` early in Systems Design, before HUD/SP/VFX GDDs.

### Blockers
None.

### Recommendations
1. Run `/design-review design/gdd/game-concept.md`; fix the stale engine text (Technical
   Considerations, Open Questions, Next Steps) in the same pass.
2. Re-run `/gate-check` after the review.
3. Carry into `/map-systems` as requirements: all three SP types defined; Ultimate resource
   decided; Block-and-movement counter for each Tier 0 skill; time in ticks.
4. Run `/art-bible` early in Systems Design to settle the red / Vanguard conflict, class hex
   values with a colourblind check, and the P2 marker.
5. Consider building the Tier −1 slice (`/prototype`) in parallel; mark formulas provisional until it reports.

### Verdict: CONCERNS

Chain-of-Verification: 5 questions checked (3 by tool action: test re-run, CLAUDE.md grep,
gitignore check) — verdict unchanged.

### Stage
**Not advanced.** The user chose to stay at `Concept` and re-run the gate after `/design-review`.
`project.yaml` `project.stage` and `production/stage.txt` remain `Concept`.
