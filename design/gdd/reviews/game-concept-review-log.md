# Review Log: game-concept.md

## Review — 2026-10-31 — Verdict: NEEDS REVISION
Review mode: full · Workflow: full
Scope signal: S (concept revision); L for the committed Tier −1 → Tier 1 path; XL for Tier 2
Specialists: game-designer, systems-designer, qa-lead, network-programmer, godot-specialist; senior: creative-director
Blocking items: 4 | Recommended: 6
Summary: The vision is coherent — fantasy, hook, pillars, anti-pillars and visual anchor point the same way, and the tier plan is honest for a solo developer. It lacks a few concept-level decisions that /map-systems needs to know which systems exist: a counterplay floor that survives the cut order, anti-stall systems, and the Ultimate resource. Balance problems (snowball, kiting, turtling) belong in the system GDDs.
Prior verdict resolved: First review
Note: the 8-section GDD standard was not applied — this is a concept document; it was reviewed against the concept template.
Findings:
- [BLOCKING] Game Pillars / MVP Definition: Pillar 2 counterplay promise contradicts the cut order (Perfect Guard and Dodge are first cuts); no uncuttable counterplay floor is named.
- [BLOCKING] Risks and Open Questions: no anti-stall decision — throws/guard-break, timeout resolution, comeback mechanic are not decided yes/no.
- [BLOCKING] Core Mechanics: the Ultimate has no defined resource.
- [BLOCKING] Technical Considerations / Open Questions / Next Steps: engine still "undecided" (lines 318, 380, 446); "no GC stutter" should read "zero per-tick allocation"; line 448 mislabels pillars as a separate doc; line 450 orders /map-systems after the prototype while the project is about to map first.
- [RECOMMENDED] Core Fantasy / Pillar 2: state whether speed or hit weight wins when they conflict.
- [RECOMMENDED] MVP Definition: measurable core hypothesis and pre-registered Tier −1 PROCEED/PIVOT/KILL rule; Tier −1 PROCEED means "foundation viable", not "hypothesis proven".
- [RECOMMENDED] Scope Tiers: Defensive SP is riskiest and tested last; move a data-only Defensive variant earlier.
- [RECOMMENDED] Scope Risks: LAN spike likely ~2 weeks with a measurement harness; test Radmin as well as Hamachi.
- [RECOMMENDED] Technical Considerations: FPS target and minimum hardware belong in project.yaml; replace the 500 draw-call budget with a frame-time budget.
- [RECOMMENDED] Visual Identity Anchor: red (danger) vs Vanguard red-orange — for /art-bible.
Disagreements: float vs fixed-point (TD: controlled float; network-programmer, godot-specialist, systems-designer: integer fixed-point) — creative-director asks TD to re-decide the ADR on the new evidence; all gameplay resources and timers are integers either way. Pillar priority 1>3>2>4 kept, with counterplay split out as a hard constraint. Roster wording: reword, not blocking.
Reviewed-Content-Hash: design/gdd/game-concept.md c1b3d2cb7d3f4e6e355841784875af37e95ce7c5
Reviewed-Content-Hash: design/registry/entities.yaml dfeacb02917f751cb1dfd88cf490c7ec3d8d2d0f
Reviewed-Content-Hash: .claude/skills/design-review/SKILL.md a63d8fba9b7142eeb43791f061e2e1533c429b43

## Review — 2026-10-31 — Verdict: APPROVED
Review mode: full · Workflow: full
Scope signal: S (concept revision); L for the committed Tier −1 → Tier 1 path
Specialists: game-designer, systems-designer, qa-lead, network-programmer, godot-specialist; senior: creative-director (synthesis + re-verification)
Blocking items: 2 (resolved in-session) | Recommended: 6 (4 applied)
Summary: All 4 prior blockers were resolved. The re-review found two concept-level contradictions — Throw had no counter, and the Ultimate's freeze conflicted with the hard counterplay constraint — both resolved in the concept: a Throw triangle with throw tech and no throw loops, and an Ultimate that can be interrupted, blocked and punished, with no invulnerability and a freeze only on hit. Senior re-verification found 4 small consistency edits, applied; numbers, tie rules and implementation detail are routed to the system GDDs, ADRs and the Tier −1 prototype plan.
Prior verdict resolved: Yes
Note: concept document, reviewed against the concept template (not the 8-section GDD standard).
Findings:
- [BLOCKING] Core Mechanics / MVP Definition: Throw beats Block but nothing beat Throw — fixed (strike/movement beat Throw, throw tech, punishable whiff, no loops).
- [BLOCKING] Core Mechanics / Pillar 3 / MVP HUD: Ultimate freeze vs the hard counterplay constraint; opponent Ultimate gauge not readable — fixed (gauge spent on activation, visible startup, no invulnerability, freeze only on hit, punishable; gauge in Pillar 3 and HUD).
- [RECOMMENDED] MVP Definition: measurable core hypothesis — applied (≥4 of 6 testers rematch unprompted, end of Tier 0).
- [RECOMMENDED] MVP Definition: Tier −1 PROCEED = foundation works, not hypothesis proven — applied.
- [RECOMMENDED] MVP Definition: fallback cut nothing; Throw animations outside budget — applied (cut order Perfect Guard/Dodge → Air; Throw in 10–12).
- [RECOMMENDED] Design Risks: kiting under the HP% timeout gated as a Combat GDD acceptance criterion before Amiya is built — applied.
- [RECOMMENDED] MVP Definition: add Throw + one SP type with a timed skill to Tier −1 — not applied (user scope call).
- [RECOMMENDED] MVP Definition: measurable cut trigger for Perfect Guard/Dodge — not applied.
Routed: Combat GDD (HP% tie rule via integer cross-multiplication, timers during hit-stop/freeze, interrupt threshold and what counts as a hit, kiting/arena walls); SP/Ultimate GDD (gain per hit type, per-combo cap, round reset, snowball intent); numeric ADR (fixed-point vs float, no Vector2/3 or trig in the sim, rounding rule, hitbox format); netcode ADR (input delay, stall policy, redundant inputs, desync checksum, versioned input record); Tier −1 /prototype plan (measurable pass condition, snapshot round-trip, zero-allocation and GDScript benchmark gates, LAN spike criteria incl. Radmin, PROCEED/PIVOT/KILL).
Disagreements: kiting + HP% (game-designer/systems-designer: concept blocker; creative-director: gate on the Combat GDD); Throw vs Defender fantasy (game-designer yes; creative-director no — SP GDD rule); pillar order / speed vs weight (creative-director: no contradiction). Specialist errors corrected: qa-lead ("finished" undefined — defined at Long-Term Progression; tick rate unstated — 60 Hz), network-programmer (60 vs 150 tick is Tier 0 vs Tier 1), godot-specialist (unverified against the 4.7 engine reference).
Reviewed-Content-Hash: design/gdd/game-concept.md ec225adddc8b912b7666cba8db67944947db7b43
Reviewed-Content-Hash: design/registry/entities.yaml dfeacb02917f751cb1dfd88cf490c7ec3d8d2d0f
Reviewed-Content-Hash: .claude/skills/design-review/SKILL.md a63d8fba9b7142eeb43791f061e2e1533c429b43

## Review — 2026-11-01 — Verdict: NEEDS REVISION
Review mode: full · Workflow: full
Scope signal: S (concept revision); L for the Tier −1 → Combat Slice path
Specialists: game-designer, systems-designer, qa-lead, godot-specialist; senior: creative-director
Blocking items: 7 (all revised in-session) | Recommended: 8 (none applied)
Summary: Vision, pillars and hypothesis hold. The Combat Slice paragraph (added 2026-11-01) and the Adjustment E cut order were not propagated: "slice" meant three things, the HIGH RISK line contradicted the plan, the slice gate had no criteria, Perfect Guard/Dodge had three statuses, the Amiya kiting gate was unmeetable, numeric-model text was stale vs ADR-0001, and bloom wording contradicted art bible §8.9. All 7 revised in-session; re-review needed for APPROVED.
Prior verdict resolved: Yes (prior APPROVED superseded by post-approval edits)
Note: concept document, reviewed against the concept template. Prototype mirror-feel PASS is user-declared with no evidence on file — must not be cited as validated feel (CD ruling).
Findings:
- [BLOCKING] Technical Risks / Scope Tiers / Next Steps: "slice" ambiguity, HIGH RISK line vs Combat Slice — revised (staged slice, Tier 0a row, Next Steps).
- [BLOCKING] MVP Definition: Combat Slice gate undefined — revised (10–14 wk timebox, PASS ≥4/6 Rematch with ≥3 new, FAIL branch, owner user, honesty clause).
- [BLOCKING] MVP Definition: Perfect Guard/Dodge three statuses — revised (out of slice, decided at slice gate, first cut).
- [BLOCKING] Design Risks: Amiya kiting gate timing — revised (before the slice's Amiya work).
- [BLOCKING] Technical Considerations / Open Questions: stale numeric-model text — revised (ADR-0001 fixed-point int).
- [BLOCKING] Open Questions: feel question pointed at Tier −1 — revised (Combat Slice; prototype not evidenced).
- [BLOCKING] Technical Considerations: bloom vs art bible §8.9 — revised.
- [RECOMMENDED] Core Fantasy: name counter-burst tools without PG/Dodge — not applied.
- [RECOMMENDED] Technical Considerations: drop "GDScript đếm tham chiếu, không có GC" justification — not applied.
- [RECOMMENDED] MVP Definition: gamepads in the slice — not applied.
- [RECOMMENDED] MVP Definition: slice gate date as fallback-cut trigger — not applied.
- [RECOMMENDED] Playtest plan: Rematch protocol + telemetry — not applied.
- [RECOMMENDED] Core Identity: Estimated Scope mentions the slice — not applied.
- [RECOMMENDED] MVP Definition: Tier −1 checksum N and ≥2 machines — not applied.
- [RECOMMENDED] MVP Definition: Challenge-side observation beside the Rematch metric — not applied.
Disagreements (CD rulings): feel criteria at Tier −1 — keep "foundation only"; tie rule / timers in hit-stop / throw-strike same tick / one-hit-kite — stay routed to the Combat GDD, which must exist before the slice starts; pillar tests subjective — fine at concept level. Specialist error: godot-specialist "Packed arrays copy-on-write" — contradicted by ADR-0002 test (alias) and ADR-0001 R7.
Receipt note: the concept hash is deliberately omitted (receipt would be of the post-revision text), so the next run reads the concept as changed and reviews in full.
Reviewed-Content-Hash: design/registry/entities.yaml dfeacb02917f751cb1dfd88cf490c7ec3d8d2d0f
Reviewed-Content-Hash: .claude/skills/design-review/SKILL.md a63d8fba9b7142eeb43791f061e2e1533c429b43
Reviewed-Content-Hash: design/art/art-bible.md 9334f0772a5357a8a05af1b1ebcafac94ba36ff4
Reviewed-Content-Hash: docs/architecture/adr-0001-sim-numeric-model.md bcfec2506c072e8d63542e7eaabcae08008c4e0c

## Review — 2026-11-01 (2) — Verdict: NEEDS REVISION
Review mode: full · Workflow: full
Scope signal: S (concept revision); L for the Tier −1 → Combat Slice path
Specialists: game-designer, systems-designer, qa-lead, godot-specialist; senior: creative-director
Blocking items: 5 (all revised in-session) | Recommended: 14 (none applied)
Summary: Vision, pillars, staged plan and tick arithmetic hold. The document disagreed with itself — stale APPROVED lines, line 354 contradicting ADR-0001/0002, a fantasy peak ("counter-attack") with no tool in the slice — and the Combat Slice gate could not be scored (one shared Rematch button per pair). All five were text fixes, applied; mechanical depth is routed to the Combat GDD and networking ADR.
Prior verdict resolved: Yes (all 7 prior blockers confirmed landed)
Note: concept document, reviewed against the concept template. User decisions: counter-attack = existing punishes (blocked/whiffed Ultimate, whiffed Throw) + skill interrupt; unprompted Rematch = within 10 s of Victory.
Findings:
- [BLOCKING] Game Pillars / Next Steps: stale APPROVED status, /art-bible unchecked, "slice" ambiguous, no Combat GDD step before the slice — revised.
- [BLOCKING] MVP Definition: Combat Slice gate unscorable (shared Rematch button), "unprompted" undefined, no crash rule, timebox unanchored, hypothesis gate duplicated — revised (per-pair ≥2/3 incl. ≥1 novice+novice pair, 10 s, replay crashed pairs, start at Tier −1 PASS + week-7 checkpoint, slice gate = hypothesis gate, Tier 0 end = confirmation).
- [BLOCKING] Core Fantasy: counter-attack peak had no slice mechanic — revised (named existing punishes + skill interrupt).
- [BLOCKING] Design Risks: Auto-SP earns Ultimate passively; Amiya gate covered SP only — revised (gate covers Ultimate gauge).
- [BLOCKING] Technical Considerations: snapshot <1 ms / no-GC / no-alloc line vs ADR-0001 (≤0.25 ms/tick, V5 unmeasured) and ADR-0002 (alias, explicit copy) — revised.
- [RECOMMENDED] Elevator Pitch / Design Risks: comeback stance (pitch "lật ngược", line "no comeback", Defensive Ultimate on hit) — not applied.
- [RECOMMENDED] MVP Definition: animation budget ~15 per Operator — not applied.
- [RECOMMENDED] MVP Definition: hypothesis covers 2/3 SP types, or data-only Defensive variant in slice — not applied.
- [RECOMMENDED] Flow State Design: onboarding fallback when AI Normal is cut — not applied.
- [RECOMMENDED] Scope Risks: Tier −1 timebox vs 3–6 wk engine learning — not applied.
- [RECOMMENDED] Core Mechanics: one line of Throw-tech intent (tech never makes Throw dead vs Block) — not applied.
- [RECOMMENDED] Game Pillars: counterplay floor verified by scripted defender bot — not applied.
- [RECOMMENDED] Open Questions / Technical Risks: operational tests for "nhanh và mượt", "Ch'en khối hộp chạy ổn", "nền móng dùng được" — not applied.
- [RECOMMENDED] Core Mechanics / Pillars: counterplay floor defined three ways — not applied.
- [RECOMMENDED] Core Identity / Core Loop: session length 30–60 vs 30–120 — not applied.
- [RECOMMENDED] Inspiration: SF6 Drive Parry reference points at a cut system — not applied.
- [RECOMMENDED] Open Questions: ADR-0001 "đã chọn" vs Proposed — not applied.
- [RECOMMENDED] Technical Considerations / Risks: cite ADR-0002; add GDScript sim-perf risk and peer build/move-data hash handshake — not applied.
- [RECOMMENDED] Technical Considerations: PacketPeerUDP behavior unverified in engine reference; loss/reorder handling — not applied.
Routed: Combat GDD acceptance gates (throw-tech window < reaction ~15–20 ticks with thrower advantage, simultaneous throws, prejump < throw startup, combo escape/cap, interrupt counts distinct hit events, Auto gauge bound, HP% rule hp_a*max_b > hp_b*max_a + leading-player wait-out); networking ADR / ADR-0001 (8-tick rollback < 9.6-tick Hamachi RTT, delay >3 frames feel risk, RTT vs one-way, build/data-hash handshake, halo if emissive VFX, RefCounted cycles / Variant allocations).
Disagreements (CD rulings): line 354 → required (unapplied twice, contradicts ADRs); slice gate is the hypothesis gate, Tier 0 end only confirms; Auto Ultimate → required as gate-widening only; throw tech → Combat GDD, concept gets intent line; counter-burst → raised from recommended to required.
Receipt note: the concept hash is deliberately omitted (receipt would be of the post-revision text), so the next run reviews in full.
Reviewed-Content-Hash: design/registry/entities.yaml dfeacb02917f751cb1dfd88cf490c7ec3d8d2d0f
Reviewed-Content-Hash: .claude/skills/design-review/SKILL.md a63d8fba9b7142eeb43791f061e2e1533c429b43
Reviewed-Content-Hash: design/art/art-bible.md 9334f0772a5357a8a05af1b1ebcafac94ba36ff4
Reviewed-Content-Hash: docs/architecture/adr-0001-sim-numeric-model.md bcfec2506c072e8d63542e7eaabcae08008c4e0c
Reviewed-Content-Hash: docs/architecture/adr-0002-sim-view-split.md 9cccc79f279cab7c5e2a891facc9d908230fc618

## Review — 2026-11-01 (3) — Verdict: NEEDS REVISION
Review mode: full · Workflow: full
Scope signal: S (concept revision); L for the Tier −1 → Combat Slice path
Specialists: game-designer, systems-designer, qa-lead, godot-specialist; senior: creative-director
Blocking items: 4 (all revised in-session) | Recommended: 6 groups (routed, none applied)
Summary: Vision, pillars, staged plan and tick arithmetic hold; all 5 prior blockers landed. Three gaps broke the concept's own promises — the Ultimate had no way to land, the Combat Slice timebox could not contain its own animation estimate, and the FAIL branch allowed unlimited re-runs — plus stale lines. All fixed in ~5 lines; CD rules a confirmation pass is enough, not a fourth full round.
Prior verdict resolved: Yes (all 5 prior blockers confirmed landed)
Note: concept document, reviewed against the concept template. User decisions: Ultimate cancels from a confirmed hit (guaranteed) or punishes a whiff; slice gate runs on blockout (stage (c) art/cinematic may land after the gate); FAIL = one retune ≤4 weeks + one re-run with 3 new pairs, second FAIL → pivot.
Findings:
- [BLOCKING] Core Mechanics: Ultimate had no stated way to land — revised (cancel from confirmed hit, hitstun > startup; numbers → Combat GDD).
- [BLOCKING] MVP Definition: 20–24 animations × 1–3 days inside a 10–14 wk slice — revised (gate independent of stage (c), blockout counts).
- [BLOCKING] MVP Definition: FAIL branch "tinh chỉnh lại một lần" unbounded — revised (≤4 wk, one re-run with new pairs, 2nd FAIL → pivot).
- [BLOCKING] Open Questions / Game Pillars / Next Steps: rigid-vs-skinned still "decide with /art-bible"; status lines stale — revised (art bible §8.4; status updated).
- [RECOMMENDED] Design Risks: Amiya gate should also require skill-state interrupt reachable vs Amiya with PG/Dodge absent — routed to Combat GDD.
- [RECOMMENDED] Design Risks: "Throw chống chơi thủ" overstated vs HP%-lead turtling with throw tech — routed to Combat GDD.
- [RECOMMENDED] MVP Definition: Tier −1 PROCEED/PIVOT/KILL, defined pass terms, ADR-0001 V1–V5 + Accepted ADRs in PASS, LAN spike ~2 wk — routed to /prototype plan.
- [RECOMMENDED] MVP Definition: playtest protocol (6 distinct people, ≥1 Ch'en vs Amiya match, recording, 10 s clock start, novice replay rule) — routed to /playtest-report protocol.
- [RECOMMENDED] MVP Definition: week-7 checkpoint criterion/action — routed to sprint plan.
- [RECOMMENDED] Technical Considerations / Risks: PacketPeerUDP "chưa kiểm", gdUnit4 evidence, catch-up cap, halo without WorldEnvironment glow, GDScript sim-perf risk, ADRs still Proposed; MVP range ~4.5–9.1 mo vs ~6.5 expected — routed to ADR / spike; optional clauses.
Disagreements (CD rulings): FAIL branch blocker (systems-designer) vs none (qa-lead) → blocker, /gate-check reads the gate as written; comeback stance → L390 holds (Defensive gauge = class identity); rejected as specialist errors: counterplay floor "3 ways" (consistent), session length 30–120 (template heading), Mudrock in Core Fantasy (full vision), ghosting/gamepad in slice (supervised local test).
Receipt note: the concept hash is deliberately omitted (receipt would be of the post-revision text), so the next run reviews in full.
Reviewed-Content-Hash: design/registry/entities.yaml dfeacb02917f751cb1dfd88cf490c7ec3d8d2d0f
Reviewed-Content-Hash: .claude/skills/design-review/SKILL.md a63d8fba9b7142eeb43791f061e2e1533c429b43
Reviewed-Content-Hash: design/art/art-bible.md 9334f0772a5357a8a05af1b1ebcafac94ba36ff4
Reviewed-Content-Hash: docs/architecture/adr-0001-sim-numeric-model.md bcfec2506c072e8d63542e7eaabcae08008c4e0c
Reviewed-Content-Hash: docs/architecture/adr-0002-sim-view-split.md 9cccc79f279cab7c5e2a891facc9d908230fc618

## Review — 2026-11-09 (4) — Verdict: APPROVED (after 3 in-session line fixes; review verdict NEEDS REVISION → CD: approve on landing, no 5th round)
Review mode: full · Workflow: full
Scope signal: S (concept revision)
Specialists: game-designer, systems-designer, qa-lead, godot-specialist; senior: creative-director
Blocking items: 3 (all revised in-session) | Recommended: ~20 (routed, none applied)
Summary: All 4 round-3 blockers landed. Three one-line defects remained: the Ultimate "no exceptions" counterplay claim contradicted the guaranteed combo-Ultimate; the gate's "≥30 phút" session contradicted "chơi bao lâu tùy thích" and would taint the unprompted-Rematch measure; a blockout with no hit feedback could fail the gate for reasons outside the hypothesis. Fixed; CD rules the user may record APPROVED.
Prior verdict resolved: Yes (all 4 round-3 blockers confirmed landed)
Note: concept document, reviewed against the concept template.
Findings:
- [BLOCKING] Core Mechanics L127/L139: counterplay floor scoped to raw Ultimate; cancel only from an unblocked confirmed hit; combo-Ultimate counterplay = block/avoid the opener — revised.
- [BLOCKING] MVP Definition L467: session = 30 min reserved, not mandatory — revised.
- [BLOCKING] MVP Definition L476: blockout gate requires hit-stop + placeholder SFX on hit — revised.
- [RECOMMENDED] Combat GDD: combo-Ultimate damage bound; Throw as confirmed hit (cancel / interrupt count); freeze/hit-stop vs round clock + skill timers, resolution at tick 5940; draw / double-KO rule so Bo3 terminates; Auto Ultimate rate cap; Amiya skill spec as kiting-gate input; Throw-vs-kiting wording (L392) — routed.
- [RECOMMENDED] /playtest-report protocol: novice definition + record, Rematch unit (which Victory, ≥10 s screen, log-timed), crash replay cap / crash after min 30 / "desync" offline; pillar design tests as metrics — routed.
- [RECOMMENDED] /prototype plan: Tier −1 PASS record (who/where/commit/≥3 replays ≥2 machines); LAN spike in PASS?; PASS ⇒ ADR-0001/0002 Accepted; L361 wording (gdUnit4 saved run, PacketPeerUDP caveat, CI same-machine only, hot reload recomputes move-data hash, catch-up cap, "(ADR Proposed)") — routed.
- [RECOMMENDED] Sprint plan: slice overrun past week 14; retune inside/outside timebox — routed.
- [RECOMMENDED] Optional: Tier 0 Ultimate label; weight source in Core Fantasy — not applied.
Disagreements (CD rulings): L392 Throw wording (GD blocking) → not blocking, already gated L394–398; sensation peak at Tier 0 end → recommended only; qa-lead Q2–Q5 → protocol detail, not concept; systems-designer L526 LAN order → rejected (consistent).
Receipt note: concept hash is of the post-revision text the CD approved, so an unchanged re-run can reuse this verdict.
Reviewed-Content-Hash: design/gdd/game-concept.md 8e35cb2ebc896d0b0b7513c170df648804328f64
Reviewed-Content-Hash: design/registry/entities.yaml dfeacb02917f751cb1dfd88cf490c7ec3d8d2d0f
Reviewed-Content-Hash: .claude/skills/design-review/SKILL.md a63d8fba9b7142eeb43791f061e2e1533c429b43
Reviewed-Content-Hash: design/art/art-bible.md 9334f0772a5357a8a05af1b1ebcafac94ba36ff4
Reviewed-Content-Hash: docs/architecture/adr-0001-sim-numeric-model.md bcfec2506c072e8d63542e7eaabcae08008c4e0c
Reviewed-Content-Hash: docs/architecture/adr-0002-sim-view-split.md 9cccc79f279cab7c5e2a891facc9d908230fc618
