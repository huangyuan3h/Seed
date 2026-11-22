# Seed — Decisions

> Locked decisions are not up for silent re-litigation. If a decision changes,
> add a new row and mark the old one **Superseded**. Cite the owning doc so agents
> can find the details.
>
> §1 is locked canon. §2 is **proposed** and waiting for author confirmation; do not
> treat proposals as canon, but do not contradict them silently either.

## 1. Locked

| ID | Decision | Rationale | Source |
|----|----------|-----------|--------|
| D001 | The game takes place in **SEED-2338**, on its **third planet** (`SEED-2338 III`). | Concrete system/planet identity; title is a designation, not a metaphor. | `story.md` §3 |
| D002 | The first phase is **food**, not power. | The commander must survive before fixing the ship; power is the second target. | `first-phase-food.md` |
| D003 | Early power bootstrap is a **thermal generator**; solar/wind come after. | Thermal is the startup source that charges the ship enough to wake one person. | `story.md` §9–10, `thermal-power.md` |
| D004 | Colonist roster is **5 core + 1 optional doctor**: geneticist, construction engineer, materials scientist, robotics engineer, weapons specialist (+ doctor). | Small roster; each owns a pillar; no redundant comms/geologist. | `colonist-wake-chain.md` §5 |
| D005 | The player controls **only the Commander**. Other colonists are autonomous **NPC experts**. | The game is about command and delegation, not switching characters. | `colonist-wake-chain.md` §2 |
| D006 | Each expert owns **3+ tech branches**; **2+ experts** unlock **shared tech**. | Fewer people, deeper trees, combinatorial progression. | `colonist-wake-chain.md` §5, `design.md` §6.3 |
| D007 | The tech tree is a **physical archive of glass slides** in a cargo hold. The archive was **not deliberately discarded**; the suppression faction broke the relay road instead, and the crash damaged the cargo hold. **Superseded by D021** for the discard detail. | Turns tech progression into exploration + politics; ties to the coup. | `story.md` §5, `tech-archive.md` |
| D008 | The crash is a **coup**, hidden as background; the player does not hear the word early. | Survival first; the truth is discovered through anomalies, logs, and the AI. | `story.md` §5 |
| D009 | The map is a **4 km × 4 km continent** surrounded by shallow/deep ocean; the far boundary is a **giant octopus territory**, not an invisible wall. | Readable world boundary; exploration and dread. | `story.md` §4 |
| D010 | No colored science-pack grind. Progression is **tech tree + milestones + patterns + samples + people**. | Avoid Factorio busywork; keep survival/colony focus. | `design.md` §6 |
| D011 | Early AI is **voice-only**, with compute tied to power; it gains capabilities as the ship is repaired. | Companion intimacy + diegetic limits. | `story.md` §5, `design.md` §5 |
| D012 | The first anomaly is **Pod 07**: empty pod, `OCCUPIED` status, missing Security Officer Vale, data chip. | Concrete mystery; teaches “records are unreliable.” | `anomaly-01-empty-pod.md`, `dialogue-pod-07.md` |
| D013 | The ship is **very large**; the hibernation bay is a small part. Energy bay, cargo holds, bridge, engineering, etc. are future unlock space. | Supports the ship-as-dungeon and later tech archive. | `story.md` §5 |
| D014 | Build sites are currently **one-shot flag setters** (shelter, thermal generator). | Graybox milestone; real fuel/charge simulation is T2.1. | `STATE.md`, `ROADMAP.md` |
| D015 | Every wakeable core colonist is a **reliable squad member**. No betrayal among the core cast; the hidden coup is about the ship's past, the AI, and the previous crew. | Keeps the colony/companion tone; mystery without “who is the traitor” paranoia. | `story.md`, `cast.md` |
| D016 | Habitable worlds are ~**40 ly** apart; ships cruise at ~**0.4c**, so a trip is ~**100 years**; light-speed comms are too slow, so ships physically carry **seeds, colonists, knowledge**. | Hard-SF isolation; no real-time rescue; the archive is a physical time capsule. | `story.md` §3.6, `story-spine.md` |
| D017 | Gene engineering makes human lifespan **nearly unlimited**; apparent age 30–50, chronological age 120–350, core elites 500+. Longevity/genetic tech is part of the archive; the suppression faction fears its spread. | 100-year trips and 200-year returns are personal, not generational; gives the coup a visceral motive. | `story.md` §3.7, `cast.md` |
| D018 | Interstellar propulsion is the **beam road** (launch array + relay chain + destination brake). The ship also carries an **antimatter emergency reserve** (spent in the coup/crash) and **reverse propulsion** (assist/attitude). The **fusion reactor** is main onboard power, not the 0.4c drive. | Onboard fuel for 0.4c is energetically impossible; the spent antimatter explains why the ship cannot leave. | `ship-energy.md` |
| D019 | The seeding mission is a **fleet**, not one ship. A partial relay failure splits it: some ships reach the target, some do not. The player's ship crashes at **SEED-2338 III**, a forward colony/relay waypoint; the target system is beyond it (placeholder `SEED-2419`). | Explains the fleet link, the stranded ships, and why the colony must build a new fleet instead of just repairing one ship. | `story-timeline.md`, `story-spine.md` |
| D020 | The endgame is **not a return home**. The player repairs the seeding ship, rebuilds the relay road, and builds a new fleet **in orbit**, then continues to the target system. Returning home is at most an optional contrast. | A 4 km landing region cannot build a fleet; orbit + the ship's industry + the relay make continuation credible, and “seed forward” fits the title. | `materials-and-industry.md`, `story-spine.md` |
| D021 | The archive was **not deliberately discarded**. The suppression faction's goal was achieved by **breaking the relay road**; the crash damaged the cargo hold and scattered the slides. **Mira did not execute a discard order**; her guilt is about another order/choice (e.g. prioritizing the ship, cutting the relay, spending the antimatter). | Keeps the archive as recoverable cargo, makes the road the political object, and gives Mira a more nuanced arc. | `story.md` §5, `tech-archive.md`, `cast.md` |
| D022 | The player was **not awake during the coup**. Memory gaps come from Eden/hibernation, not from witnessing the coup. | Keeps the player as the investigator of the aftermath, not a hidden participant. | `story-timeline.md` |
| D023 | The ship's **fusion reactor** remains offline for the first several chapters. Early/mid power is thermal bootstrap → solar/wind → **coal/oil steam** → nuclear/fusion late. | The reactor is the ship's heart, but restoring it is a late-game milestone; early gameplay must stand on local power. | `ship-energy.md`, `materials-and-industry.md` |
| D024 | The thermal generator's **20 units** are a **bootstrap key** that starts the tech cycle (printer, lights, med bay, AI, basic tools), not a full power plant. | Prevents “20 power = factory” and keeps the first generator narratively meaningful. | `thermal-power.md`, `ship-energy.md` |
| D025 | The planet **has coal and oil**. | The colony needs a playable industrial base; fossil fuels make the mid-game industrial chain feasible. | `materials-and-industry.md` |
| D026 | The first local iron source is **hematite**, not bog iron. | Matches the author's choice; supports a more conventional mining/smelting chain. | `materials-and-industry.md` |
| D027 | The air is **directly breathable**; the suit is for temperature, weather, and initial protection, not because the atmosphere is toxic. | Terraforming worked; the danger is survival and ecology, not suffocation. | `story.md` §4 |
| D028 | The **giant octopus** and **deep-sea squid** are products of the **seeding experiment** (biological boundary/guard). | Makes the ocean boundary part of the seeding plan, not an unrelated monster. | `story.md` §4 |
| D029 | 200 years after departure, the home civilization is still ruled by the **same near-immortal elites**; the **suppression faction is in power**. | Makes “home” a political disappointment and sharpens the choice to continue rather than return. | `story-timeline.md`, `story-spine.md` |
| D030 | There is **no “seed tower” setting**. Use **relay stations**, **old seeding facilities**, or **orbital infrastructure** instead. | Avoids inventing a landmark the author did not define. | `story.md`, `ship-energy.md` |
| D031 | Factory logistics uses **roads + autonomous transport fleets**, not belts. Factories are separate sites (mining, smelting, fabrication, research) connected by a road graph; players build roads/routes and assign trucks; AI suggests routes later. | Fits the colony/commander fantasy, avoids belt spaghetti, scales to the 4 km map, and matches the “player sets goals, AI executes” pillar. | `factory-loop.md` |
| D032 | Transport vehicles progress in three stages: **steam fuel truck** → **electric truck that returns to a charging station** → **field-charged truck** that recharges inside an area power field. | Gives logistics a visible tech arc tied to the power ladder; each stage changes route planning. | `factory-loop.md` §7.4 |
| D033 | Roads are **grid-based with 90° turns**; **one route carries one item type**; routes are **manual first**, with AI suggestions later. | Keeps the first implementation readable and testable; avoids mixed-cargo routing and freeform spline complexity. | `factory-loop.md` §7.2–§7.5 |
| D034 | One local day is **30 real minutes / 24 in-game hours**. Sleep is **optional**, never forced; the player can sleep 1h, 2h, 4h, or until dawn. | Keeps a readable day/night loop without punishing players who stay up; sleep is a convenience/time-skip, not a survival requirement. | `ui-hud.md` §6 |
| D035 | Actions become **tool-driven** (axe → chop, pickaxe → mine, build tool → build); **1–8 are the hotbar**. | Frees the standard number keys and matches the power-suit/tool fantasy. | `ui-hud.md` §15 |
| D036 | Opening **PACK / ARCHIVE / COLONY** pauses gameplay and the world clock. | Prevents starvation/decay while reading long panels; keeps UI reading time separate from survival time. | `ui-hud.md` §6.4, §15 |

## 2. Proposed (awaiting confirmation)

These are written down so agents do not accidentally contradict them, but the author
has not locked them yet. Confirm or change them before treating them as canon.

| ID | Proposal | Why it matters | Source |
|----|----------|----------------|--------|
| P005 | Chapter 1 has **no mining, smelting, or refiner**; the “ore” of chapter 1 is **ship salvage**. Ore processing starts in Act 2–3 with power and experts. | Keeps the survival focus; avoids a fake single-machine refinery. | `chapter-1-tools.md`, `materials-and-industry.md` |
| P006 | The **wrist printer is starting survival equipment**, not craftable; it prints small precision parts, while full tools are **printed head + local handle**. | Makes 3D printing diegetic and limited; supports tool progression. | `chapter-1-tools.md` |
| P007 | Wood splits into **wood** (branches/fuel) and **timber** (structural logs, axe-gated); the generator needs timber, water, and a mallet. | Makes the axe a real gate without blocking the first-night lean-to. | `chapter-1-tools.md` |
| P008 | The playable **4 km region is a landing peninsula/island** of a larger planet; only this region is in scope. | Keeps the map readable while avoiding “the whole planet is 4 km.” | `story-timeline.md` |
| P009 | The first factory slice uses **9 materials, 2 research inputs (mechanical/electrical), 6 tech nodes**, and **grid roads + one truck** before any fleet automation. | Keeps the first playable loop small enough to implement and test. | `factory-loop.md` |
| P010 | The tech tree uses **5 phases × 7 UI branches**, split into **18 spine nodes** (3–5 per phase) and **~64 branch nodes**. Spine nodes only depend on earlier spine nodes, milestones, facilities, or expert wake conditions; branch nodes may depend on spine, but spine never depends on branch. | Keeps the main line 20–30 h and soft-lock free while still giving every expert >3 branches. | `tech-tree.md` §3, §4.8 |
| P011 | Progress is **weighted sources summing to 100**; no global passive research. Expert progress requires awake + assigned + facility + power; shared nodes use `owners` / `shared` / `min_owners` / `fallback_owners`. | Makes every percentage explainable and prevents idle/AFK progression. | `tech-tree.md` §4 |
| P012 | **Critical-path slides are guaranteed** by deterministic points (main quest / fixed section / old facility). Missing slides can be rebuilt by experts at reduced speed; no RNG hard lock. | Keeps the archive central without letting a bad seed block the main line. | `tech-tree.md` §4.8–§8 |

> P001 (beam road) and P002 (coup timing) were confirmed as **D018** and **D019**.
> P003 (return-by-refit) was replaced by **D020** (continue forward).
> P004 (no coal/oil, bog iron) was replaced by **D025/D026** (coal/oil exist, hematite).

## 3. Superseded / refined

| ID | Old decision | Replaced by | Why |
|----|--------------|-------------|-----|
| S001 | First phase = basic power. | D002 (food first) | The commander needs food before repairs. |
| S002 | Each colonist = one tech node. | D006 (branch groups + shared tech) | A single node per person was too thin and made the roster bloated. |
| S003 | Geneticist has 3 branches (plants/animals/microbes). | 4 branches (+ ecology) | P8 ecology is its own branch; satisfies “>3”. |
| S004 | Early power = solar/wind first. | D003 (thermal bootstrap, then solar/wind) | Thermal is the emergency source that charges the ship for the first wake. |
| S005 | Single tech tree percentage menu. | D007 (physical archive fragments) + D006 (expert ownership) | Tech should be found, reconstructed, and shared by people. |
| S006 | Some core colonists may be coup participants; the player doesn't know who to trust. | D015 (reliable squad) | Turned the cast into a whodunit and undermined the companion/colony tone. |
| S007 | A 100-year trip implies a multi-generational colony; the original crew cannot arrive. | D017 (near-immortality) | Near-immortal crew + hibernation means the same people can arrive after 100 years; no generation ship required. |
| S008 | The archive was deliberately discarded mid-journey. | D021 (relay sabotage, archive damaged in crash) | The suppression faction broke the road instead; the cargo stayed aboard. |
| S009 | The endgame is returning home with a refitted ship. | D020 (continue to the target system) | The story is about carrying the seed forward, not going back; the fleet is built in orbit. |
| S010 | The planet has no coal/oil; early iron is bog iron. | D025/D026 (coal/oil exist; hematite) | The author wants a playable industrial base and chose hematite. |

## 4. How to change a decision

1. Add a new row with a new ID.
2. Mark the old row **Superseded by Dxxx**.
3. Update the owning doc(s).
4. Update `STATE.md` / `ROADMAP.md` if behavior changes.
5. Mention it in the commit message.
