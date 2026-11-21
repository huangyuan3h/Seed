# Seed — Decisions

> Locked decisions are not up for silent re-litigation. If a decision changes,
> add a new row and mark the old one **Superseded**. Cite the owning doc so agents
> can find the details.

## 1. Locked

| ID | Decision | Rationale | Source |
|----|----------|-----------|--------|
| D001 | The game takes place in **SEED-2338**, on its **third planet** (`SEED-2338 III`). | Concrete system/planet identity; title is a designation, not a metaphor. | `story.md` §3 |
| D002 | The first phase is **food**, not power. | The commander must survive before fixing the ship; power is the second target. | `first-phase-food.md` |
| D003 | Early power bootstrap is a **thermal generator**; solar/wind come after. | Thermal is the startup source that charges the ship enough to wake one person. | `story.md` §9–10, `thermal-power.md` |
| D004 | Colonist roster is **5 core + 1 optional doctor**: geneticist, construction engineer, materials scientist, robotics engineer, weapons specialist (+ doctor). | Small roster; each owns a pillar; no redundant comms/geologist. | `colonist-wake-chain.md` §5 |
| D005 | The player controls **only the Commander**. Other colonists are autonomous **NPC experts**. | The game is about command and delegation, not switching characters. | `colonist-wake-chain.md` §2 |
| D006 | Each expert owns **3+ tech branches**; **2+ experts** unlock **shared tech**. | Fewer people, deeper trees, combinatorial progression. | `colonist-wake-chain.md` §5, `design.md` §6.3 |
| D007 | The tech tree is a **physical archive of glass slides** in a cargo hold; the most important cargo was **discarded mid-journey to limit other star systems' development**. | Turns tech progression into exploration + politics; ties to the coup. | `story.md` §5, `tech-archive.md` |
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

## 2. Superseded / refined

| ID | Old decision | Replaced by | Why |
|----|--------------|-------------|-----|
| S001 | First phase = basic power. | D002 (food first) | The commander needs food before repairs. |
| S002 | Each colonist = one tech node. | D006 (branch groups + shared tech) | A single node per person was too thin and made the roster bloated. |
| S003 | Geneticist has 3 branches (plants/animals/microbes). | 4 branches (+ ecology) | P8 ecology is its own branch; satisfies “>3”. |
| S004 | Early power = solar/wind first. | D003 (thermal bootstrap, then solar/wind) | Thermal is the emergency source that charges the ship for the first wake. |
| S005 | Single tech tree percentage menu. | D007 (physical archive fragments) + D006 (expert ownership) | Tech should be found, reconstructed, and shared by people. |
| S006 | Some core colonists may be coup participants; the player doesn't know who to trust. | D015 (reliable squad) | Turned the cast into a whodunit and undermined the companion/colony tone. |
| S007 | A 100-year trip implies a multi-generational colony; the original crew cannot arrive. | D017 (near-immortality) | Near-immortal crew + hibernation means the same people can arrive after 100 years; no generation ship required. |

## 3. How to change a decision

1. Add a new row with a new ID.
2. Mark the old row **Superseded by Dxxx**.
3. Update the owning doc(s).
4. Update `STATE.md` / `ROADMAP.md` if behavior changes.
5. Mention it in the commit message.
