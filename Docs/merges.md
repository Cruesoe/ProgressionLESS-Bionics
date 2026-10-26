# ProgressionLESS: Bionics merges (applied 261015, regenerated from ferny's 23 Oct release 261023)

Plan file: `Projects\Tools\RimWorld\ProgressionLESS\Plans\Bionics.ps1`. The table below is generated from it; rows 87 to 93 are listed under the optional folds.

## Result

| | Original | Without the optional folds | Applied (all rows) |
|---|---|---|---|
| Research projects ferny adds | 562 | 86 | 79 |
| All projects the mod defines or rethemes | 644 | 164 | 157 |
| Projects in the Genesis pack (Core, DLCs, Dubs Bad Hygiene) | 61 | 38 | 37 |

## How the groups are built

- Ferny takes each original project (Bionics, Synthetic organs, Modular bionics, VE Genetics' Genetic compatibility...) and gives every item it unlocked a project of its own behind it. Each row here regroups those per-item projects by theme, behind the same original project and at the same stage.
- **New group**: the members become one project. It costs as much as its most expensive member and needs the strictest bench. It keeps only the prerequisites every member shares; a member's other prerequisites (an EPOE prosthetic, a Royalty project, a weapon tech) move onto that item's recipe, so nothing unlocks sooner.
- **Fold into existing**: the members join the project they sat behind, mostly other mods' own projects that ferny rethemed (Integrated Implants, EPOE, Die for me, Glittertech). The item keeps its era but unlocks one step earlier, as it did before ferny split it off.
- **↑** marks a member that needs another member of its row. Merging moves it one step earlier.
- Every row stays within one era and one tab (verified against the inventory). Rows tagged "(Anomaly)" are on the Anomaly tab and use knowledge instead of research points.
- A row exists when the mods every member needs are active and, if every member needs more, one of the rest. Each member's item still only exists with its own mod.

## Mod combinations

Most rows hold one mod's items. The rows that mix mods are 1, 8, 12, 13, 54, 59, 64, 65, 70, 73, 74, 76, 77, 79 and 86. Each has the same shape: the merged project loads when its members' mods allow (see above), and each item is gated by its own folder as before. Two cases need care:

- **Integrated Implants without Bionic modularity** (7 modules that exist only when Bionic modularity is off). They are left out of the merges, so the merged Integrated Implants rows never depend on that switch.
- **Bionic modularity + Integrated Implants**: ferny's seven ReplaceLib replacements stay as they are. The replaced Integrated Implants modules are among the seven above.

Medieval Overhaul: the original has no Medieval Overhaul support (no folder, patches or references), so no row affects it.

## Optional folds (single leftover projects)

| # | Project | Fold into | Mod |
|---|---|---|---|
| 87 | revenant vertebrae | Revenant invisibility (vanilla, which unlocks it without ferny) | Anomaly |
| 88 | neural receiver | Neural casting | Altered Carbon 2 |
| 89 | memory projector | Deep mind scanning | Ushanka Glittertech |
| 90 | advanced cyberlink | Advanced cybertech | Ushanka Hacking |
| 91 | growth stimulator | Questionable food production | War Crimes Expanded 2 |
| 92 | neutroamine incubator | Neutroamine incubation | War Crimes Expanded 2 |
| 93 | organ modification kit | Organ destabilization | War Crimes Expanded 2 |

Kept on their own: Animal prosthetics and Animal bionics (gates for whole rows), power arm, crypto claw module, arm incinerator module (Anomaly), repair probe (Archotech behind Ultra mechtech), the animal mind controller (VE Genetics - More Lab Stuff), and the seven Integrated Implants modules above.

## How it is implemented

All 93 rows, including the optional folds, are merged in place, as in the other forks: the repo's files hold the result and nothing is merged at load time.

- **`Merge-GeneratedResearch.ps1`** (Projects tools) reads the plan and rewrites every XML file under `Common`:
  - it removes the members' definitions, the patches that create them and every operation aimed at them;
  - it renames every remaining reference to the merged project, in values and xpaths, and drops duplicate list entries;
  - it writes each member's other prerequisites into the empty `researchPrerequisites` list ferny's patch gives that member's items, with the `MayRequire` ferny used for that link;
  - availability (`Research Availability/Missing Items`): ferny checks each item by defName and removes its project when the item is missing or replaced. For a merged project, each member's removal becomes a `ProgressionLESS_Missing` marker added to the merged project; one operation then removes it when every member is marked, and another removes the markers;
  - prerequisite resolution (`Research Availability/Resolve Prerequisites`): when a project is removed, its block hands its prerequisites to the projects that needed it. A merged project keeps one block, handing down its own prerequisites;
  - files the merge leaves empty are deleted, and folders left without files are removed with their LoadFolders entries.
- **New projects** are in `Common/Defs/ResearchProjectDefs/MergedResearch.xml`, each with `MayRequire` for the mods every member needs (its load folder's mods, or its own `MayRequire`) and `MayRequireAnyOf` for the rest when every member needs more. **Folds** into projects other mods own are in `Common/Patches/MergedResearch.xml`, targeted by defName. That file sets the label and description, raises cost and bench to the members', and, for the four members that are other mods' projects (three Integrated Implants projects and Die for me's antigrain switch), removes them and moves their prerequisite links.
- **Folders and load order:** ferny's `Mods and Shit` is `Common/Mods` here and `Conditional Research` is `Common/Mods/Conditional`, which keeps deployed paths under Windows' 260-character limit. LoadFolders follows ferny's order (the availability folders first, so they patch last; `Common` last), with empty conditions dropped: ferny's `IfModActiveAll=""` never matches in game, so 18 of his folders never load.
- **Layout:** `Tools/New-Layout.ps1` writes tab and position into every definition. That puts 74 projects on a new Bionics tab, in 11 columns in era order, at most 12 rows per column, Y 0 to 7.7, with prerequisites to the left and no overlaps. The 5 Anomaly projects go on the Anomaly tab at X 7.5 to 8.5, right of vanilla's last column.
- **Load cost:** 70,017 patch operations in 120 XML files against the original's 77,427 in 166.

**Checks.** `Tools/Test-All.ps1` runs on every deploy. It checks that:
- every XML file parses and holds something, and every Ferny_ project named anywhere is defined;
- no LoadFolders condition is empty, and every listed folder holds files;
- no list holds a duplicate;
- every project has a position, with no overlaps and prerequisites to the left;
- each of the 61 availability checks removes its project when none of its items exists, keeps it when one does, and leaves no markers. Golem modules and shoulder weapons have no check: some of their members' projects are only created when the item exists, so they always stay.

`Test-ResearchLinks.ps1` reports 0 links that can dangle and 0 loops, and the inventory shows 157 projects, 79 of them ferny's.
## Merge table

| # | Project | Era | Merge | Type | Mods | In Genesis | Members |
|---|---|---|---|---|---|---|---|
| 1 | golem modules | Medieval | 7 -> 1 | new group | Epochs Golems, Epochs Pyrinth | - | brain module, anima claw, attack booster, brick fist, sleep accelerator, speed enhancer, pyrinth talon |
| 2 | medieval prosthetics | Medieval | 2 -> 1 | new group | EPOE-Forked | - | hook hand, steel arm |
| 3 | cybertech kits | Industrial | 3 -> 1 | new group | Ushanka Hacking | - | jammer kit (standard), optimization module (standard), remote access port (standard) |
| 4 | animal combat implants | Industrial | 5 -> 1 | new group | Alpha Implants | - | animal painstopper, animal power claw, animal skin hardener, animal vacskin gland, animal venom fangs |
| 5 | animal prosthetic parts | Industrial | 20 -> 1 | new group | Alpha Implants | - | animal prosthetic beak, animal prosthetic blade, animal prosthetic gas bag, animal prosthetic heart, animal prosthetic horn, animal prosthetic jaw, animal prosthetic kidney, animal prosthetic leg, animal prosthetic liver, animal prosthetic lung, animal prosthetic shell, animal prosthetic spine, animal prosthetic stinger, animal prosthetic stomach, animal prosthetic tail, animal prosthetic tentacle, animal prosthetic wing, animal chemfuel nodules, animal pouncing leg, animal thermoregulator |
| 6 | advanced cybertech kits | Industrial | 3 -> 1 | new group | Ushanka Hacking | - | jammer kit (high), optimization module (high), remote access port (high) |
| 7 | advanced ghoul enhancements | Industrial (Anomaly) | 5 -> 1 | new group | Integrated Implants | - | deadlife venom claw, ghoul bioferrite extractor, metabolic engine, nerve shredder claw, stalker skull |
| 8 | ghoul enhancements | Industrial (Anomaly) | 5 -> 1 | new group | Anomaly, Odyssey | all | adrenal heart, corrosive heart, ghoul plating, metalblood heart, blood warmer |
| 9 | advanced dead man's switches | Industrial | 4 -> 1 | fold into **EMP dead mans switch** | Die for me | - | **EMP dead mans switch** (existing), **antigrain dead mans switch** (existing), firefoam dead mans switch ↑, incendiary dead mans switch ↑ |
| 10 | brain wiring implants | Industrial | 2 -> 1 | new group | Core, Royalty | all | joywire, mindscrew |
| 11 | surrogate organs | Industrial | 5 -> 1 | new group | EPOE-Forked | - | surrogate kidney, surrogate liver, surrogate lung, surrogate stomach, brain stimulator |
| 12 | prosthetic parts | Industrial | 12 -> 1 | new group | Security Clearance, Core, EPOE-Forked | 2 of 12 | prosthetic leg, cochlear implant, artificial nose, golden eye, hydraulic jaw, light receptor, prosthetic finger, prosthetic foot, prosthetic hand, prosthetic toe, replacement spine, programmable security clearance microchip |
| 13 | compact weapons | Industrial | 3 -> 1 | new group | Royalty, EPOE-Forked | 2 of 3 | elbow blade, knee spike, scyther blade |
| 14 | basic implants | Industrial | 9 -> 1 | fold into **skeletal bracing** | Integrated Implants | - | **skeletal bracing** (existing), **lacto-stimulator** (existing), **voicelock** (existing), **comms implant** (existing), cryptosleep adaptor ↑, internal climate control ↑, brain detonator ↑, brain shocker ↑, neurostreamer ↑ |
| 15 | specialized limbs | Industrial | 2 -> 1 | new group | Royalty | all | drill arm, field hand |
| 16 | venom implants | Industrial | 2 -> 1 | fold into **venom fangs** | Royalty | all | **venom fangs** (existing), venom talon ↑ |
| 17 | orbital modules | Spacer | 4 -> 1 | new group | Bionic modularity | - | orbital bombardment module, orbital mech cluster module, orbital power beam module, tornado generator module |
| 18 | synthesizer modules | Spacer | 8 -> 1 | new group | Bionic modularity | - | alcohol synthesizer module, go-juice synthesizer module, psychite synthesizer module, smokeleaf synthesizer module, wake-up synthesizer module, fuelmaker module, hemomaker module, fertility adjuster module |
| 19 | power modules | Spacer | 3 -> 1 | new group | Bionic modularity | - | atompower module, chempower module, nuclear module |
| 20 | chemical burst modules | Spacer | 10 -> 1 | new group | Bionic modularity | - | high-explosive burst module, incendiary burst module, smoke burst module, smoke spewer module, tox burst module, tox spewer module, cryoweave module, magweave module, pyroweave module, toxweave module |
| 21 | anomaly modules | Spacer (Anomaly) | 4 -> 1 | new group | Bionic modularity | - | deadlife burst module, deadlife spewer module, disruptor flare module, revenant vertebrae module |
| 22 | subpersona chips | Spacer | 12 -> 1 | new group | Bionic modularity | - | assembler subpersona, botanist subpersona, brawler subpersona, chef subpersona, constructor subpersona, mechlord subpersona, miner subpersona, psywielder subpersona, ranger subpersona, socialite subpersona, surgeon subpersona, zoologist subpersona |
| 23 | mechanite modules | Spacer | 10 -> 1 | fold into **flu immunizer module** | Bionic modularity | - | **flu immunizer module** (existing), gut worms immunizer module ↑, lung rot immunizer module ↑, malaria immunizer module ↑, muscle parasites immunizer module ↑, overdose immunizer module ↑, plague immunizer module ↑, scaria immunizer module ↑, sleeping sickness immunizer module ↑, resurrector module ↑ |
| 24 | utility modules | Spacer | 20 -> 1 | new group | Bionic modularity | - | aesthetic module, airwire module, atmofilter module, biowelder module, coagulator module, cooler module, detoxifier module, devourer module, echolocation module, flashlight module, gastrosterilizer module, heater module, hemofilter module, immunoenhancer module, mecharray module, reprocessor module, silence module, tunenode module, vacbreath module, voicemod module |
| 25 | grenade and trap modules | Spacer | 12 -> 1 | new group | Bionic modularity | - | frag grenade module, EMP grenade module, tox grenade module, antigrain trap deployer module, deadlife trap deployer module, EMP trap deployer module, explosive trap deployer module, firefoam trap deployer module, incendiary trap deployer module, smoke trap deployer module, tox trap deployer module, EMP burst module |
| 26 | ranged weapon modules | Spacer | 16 -> 1 | new group | Bionic modularity | - | assault rifle module, autopistol module, chain shotgun module, charge lance module, charge rifle module, heavy SMG module, LMG module, minigun module, pump shotgun module, sniper rifle module, doomsday rocket launcher module, EMP launcher module, incendiary launcher module, smoke launcher module, toxbomb launcher module, ranger lens combat module |
| 27 | melee modules | Spacer | 14 -> 1 | new group | Bionic modularity | - | elbow blade module, hand talon module, knee spike module, power blade module, power claw module, power fang module, power fist module, power kick module, power saw module, powerslash horn module, powerstrike horn module, venom fangs module, venom talon module, brawler lens combat module |
| 28 | deployer modules | Spacer | 5 -> 1 | new group | Bionic modularity | - | turret deployer module, hunter drone deployer module, low-shield deployer module, mini-turret gravdrone module, crypto turret gravdrone module ↑ |
| 29 | work modules | Spacer | 12 -> 1 | new group | Bionic modularity | - | analyzer module, chef module, constructor module, crafter module, drill module, field module, medic module, mindreader module, faunamaster module, gastro-analyzer module, mechanalyzer module, mechsensor module |
| 30 | mobility modules | Spacer | 4 -> 1 | new group | Bionic modularity | - | jump pack module, nuclear jump pack module, leap module, hover module |
| 31 | projector modules | Spacer | 5 -> 1 | new group | Bionic modularity | - | cryoprojector module, magprojector module, medprojector module, pyroprojector module, radprojector module |
| 32 | animal strike modules | Spacer | 9 -> 1 | new group | Bionic modularity - animals | - | cryostrike module, magstrike module, monoslash tail module, plasmaslash tail module, powerslash tail module, powerstrike tail module, pyrostrike module, venomstrike module, zeustrike tail module |
| 33 | animal natural weapons | Spacer | 17 -> 1 | new group | Alpha Implants | - | animal acid spray, animal acidic breath, animal acidic spitter, animal barbed quill thrower, animal bioelectric organ, animal fire breath, animal fire spray, animal foam spray, animal toxic breath, animal venomous spitter, animal wisp fire, animal quad tesla cannon, animal ranged spinneret, animal petrifying gaze, animal piercing spine, animal light focusing lens, animal goo acidifier |
| 34 | animal work chips | Spacer | 8 -> 1 | new group | Alpha Implants | - | animal work chip: clean, animal work chip: feed patient, animal work chip: flick, animal work chip: harvest, animal work chip: hunting, animal work chip: mine, animal work chip: slaughter, animal work chip: sow |
| 35 | animal mutation implants | Spacer (Anomaly) | 4 -> 1 | new group | Alpha Implants | - | animal eldritch flesh tentacle, animal pseudo deadlife shaper, animal ranged trispikes, animal toughspikes |
| 36 | animal body implants | Spacer | 6 -> 1 | new group | Alpha Implants | - | animal enlarger implant, animal shrinker implant, animal stealthskin implant, animal hyper acidic stomach, animal healy power, animal extra gas bag |
| 37 | exec data programs | Spacer | 7 -> 1 | new group | Ushanka Hacking | - | exec data (disarm), exec data (discharge), exec data (fork bomb), exec data (hijack subcore), exec data (short circuit), exec data (virtual black ICE breaker), exec data (zapcode) |
| 38 | animal genetic implants | Spacer | 30 -> 1 | new group | VE Genetics | - | animal bear leg, animal bear liver, animal bionic thrumbo brain, animal bionic thrumbo eye, animal bionic thrumbo jaws, animal boomalope heart, animal boomalope stomach, animal canid eye, animal cat tail, animal chicken brains, animal chitinous heart, animal crocodile spine, animal elephant auditory receptor, animal elephant leg, animal insect mandibles, animal insectile eye, animal insectoid pheromones, animal lizard leg, animal miniature thrumbo horn, animal monitor lizard brain, animal moth tympanal organ, animal muffalo lung, animal muffalo spine, animal reinforced bionic heart, animal reinforced bionic spine, animal reinforced tail, animal rodent ear, animal rodent nose, animal scyther tail, animal wolf fangs |
| 39 | human genetic implants | Spacer | 25 -> 1 | new group | VE Genetics | - | bear claws, bear muscle tissue, boomalope nodules, cat eye, chemfuel heart, chemfuel stomach, compound insectoid eye, devouring jaws, digging mole claws, hibernation module, iguana scales, insectoid receptor, kidney toxic filters, mole-rat nerve dampener, mouse pheromones, muffalo mammaries, muffalo skin, muffalo strengthened muscles, neuron reinforcement, ovipositor, psychic dampeners, thrumbo horn, thrumbo skin, venomous fangs, wolf muscular fibers |
| 40 | animal bionic implants | Spacer | 6 -> 1 | new group | Alpha Implants | - | animal circadian supercharger, animal dermal armor gland, animal healclot synergizer, animal immunoenhancer, animal nuclear stomach, animal unstable skip synapsis |
| 41 | head modules | Spacer | 7 -> 1 | new group | Integrated Implants | - | eye colour module, night vision module, protective lens module, targeting module, telescopic sight module, gourmand tongue module, hemo-fangs module |
| 42 | arm modules | Spacer | 7 -> 1 | new group | Integrated Implants | - | arm dart gun module, arm gauss lance module, arm shotgun module, arm SMG module, death grip module, recoil suppression module, vibro-module |
| 43 | animal producer modules | Spacer | 2 -> 1 | new group | Bionic modularity - animals | - | leathermaker module, meatmaker module |
| 44 | leg and lung modules | Spacer | 5 -> 1 | new group | Integrated Implants | - | digitigrade module, foot blade module, retractable flipper module, venom foot blade module, rebreather module |
| 45 | animal bionic parts | Spacer | 20 -> 1 | new group | Alpha Implants | - | animal bionic beak, animal bionic blade, animal bionic ear, animal bionic eye, animal bionic gas bag, animal bionic heart, animal bionic horn, animal bionic jaw, animal detoxifier kidney, animal bionic leg, animal detoxifier liver, animal detoxifier lung, animal bionic nose, animal bionic shell, animal bionic spine, animal bionic stinger, animal bionic stomach, animal bionic tail, animal bionic tentacle, animal bionic wing |
| 46 | psychic implants | Spacer (Anomaly) | 3 -> 1 | fold into **psychic sustainer** | Integrated Implants | - | **psychic sustainer** (existing), psychic reaper ↑, voidlink ↑ |
| 47 | ultratech arm modules | Spacer | 5 -> 1 | fold into **monowire whip module** | Integrated Implants | - | **monowire whip module** (existing), arm fletcher module ↑, laser arm blade module ↑, plasma claw module ↑, grav kick module ↑ |
| 48 | signal boosters | Spacer | 2 -> 1 | new group | Integrated Implants | - | signal booster (standard), signal booster (high) ↑ |
| 49 | emergency implants | Spacer | 3 -> 1 | fold into **emergency shield** | Integrated Implants | - | **emergency shield** (existing), emergency vac barrier ↑, fire suppression system ↑ |
| 50 | field manipulation implants | Spacer | 2 -> 1 | fold into **shield implant** | Integrated Implants | - | **shield implant** (existing), active camouflage ↑ |
| 51 | biomimicry | Spacer | 2 -> 1 | fold into **cellular adaptor** | Integrated Implants | - | **cellular adaptor** (existing), biochameleon device ↑ |
| 52 | eltex augmentation | Spacer | 2 -> 1 | fold into **eltex adornments** | Integrated Implants | - | **eltex adornments** (existing), neural heatsink ↑ |
| 53 | shoulder weapons | Spacer | 4 -> 1 | new group | Integrated Implants | - | shoulder beam turret, shoulder charge turret, shoulder mortar, shoulder rocket pod |
| 54 | bionic body parts | Spacer | 17 -> 1 | new group | Core, Integrated Implants, Big and Small, EPOE-Forked, Pyrinth Bionics | 6 of 17 | bionic leg, bionic ear, bionic eye, bionic jaw, bionic spine, bionic tongue, bionic finger, bionic foot, bionic hand, bionic toe, bionic nose, silent jaw, bionic locomotive spine, bionic strider leg, pyrinth arm, pyrinth eye, pyrinth leg |
| 55 | subdermal armor | Spacer | 2 -> 1 | fold into **subdermal armour** | Integrated Implants | - | **subdermal armour** (existing), prestige subdermal armour ↑ |
| 56 | sanguophage implants | Spacer | 3 -> 1 | new group | Integrated Implants | - | hemo-fangs, hemogenic microcompressor, deathrest capacitor |
| 57 | advanced specialized limbs | Spacer | 2 -> 1 | fold into **advanced field hand** | EPOE-Forked Royalty | - | **advanced field hand** (existing), advanced drill arm ↑ |
| 58 | bionic compact weapons | Spacer | 3 -> 1 | fold into **bionic hand talon** | EPOE-Forked Royalty | - | **bionic hand talon** (existing), bionic elbow blade ↑, bionic knee spike ↑ |
| 59 | bionic organs | Spacer | 7 -> 1 | new group | Integrated Implants, Ushanka Biological Warfare, Pyrinth Bionics | - | bionic kidney, bionic liver, bionic lung, iron lung, bionic womb, pyrinth liver, pyrinth stomach |
| 60 | advanced bionic parts | Spacer | 10 -> 1 | new group | EPOE-Forked | - | advanced bionic leg, advanced bionic ear, advanced bionic eye, advanced bionic foot, advanced bionic hand, advanced bionic jaw, advanced bionic spine, advanced power arm, protective exoskeleton, exoskeleton suit |
| 61 | skill chips | Spacer | 12 -> 1 | new group | Integrated Implants | - | skill chip (animals), skill chip (artistic), skill chip (construction), skill chip (cooking), skill chip (crafting), skill chip (intellectual), skill chip (medical), skill chip (melee), skill chip (mining), skill chip (plants), skill chip (shooting), skill chip (social) |
| 62 | bionic tails | Spacer | 3 -> 1 | fold into **bionic tail** | Integrated Implants | - | **bionic tail** (existing), claw tail ↑, venom tail ↑ |
| 63 | advanced scyther limbs | Spacer | 3 -> 1 | new group | EPOE-Forked Royalty | - | advanced bionic elbow blade, advanced bionic hand talon, advanced bionic knee spike |
| 64 | gravship implants | Spacer | 3 -> 1 | new group | Integrated Implants, Odyssey | 1 of 3 | personal grav engine, gunnery assistant, pilot assistant |
| 65 | healing implants | Spacer | 4 -> 1 | new group | Integrated Implants, Royalty, Cellcycle Acceleration | 1 of 4 | healing enhancer, cellcycle accelerator, cryptocoagulator, synthmarrow |
| 66 | glitterworld implants | Spacer | 3 -> 1 | new group | EPOE-Forked | - | auxiliary AI (combat), auxiliary AI (worker), tactical bionic eye |
| 67 | rib implants | Spacer | 9 -> 1 | new group | EPOE-Forked | - | adrenaline rib implant, coagulator rib implant, cooling rib implant, drugged rib implant, heating rib implant, medical rib implant, painkiller rib implant, respiration rib implant, wake-up rib implant |
| 68 | synthetic repair | Spacer | 3 -> 1 | fold into **synthetic tissue** | EPOE-Forked | - | **synthetic tissue** (existing), synthetic bone ↑, neuromuscular framework ↑ |
| 69 | synthetic organ integration | Spacer | 2 -> 1 | fold into **synthetic detoxifier liver** | EPOE-Forked Royalty | - | **synthetic detoxifier liver** (existing), synthetic immunoenhanced kidney ↑ |
| 70 | flesh shaping implants | Spacer | 3 -> 1 | new group | Integrated Implants, Royalty | 2 of 3 | aesthetic shaper, love enhancer, strength enhancer |
| 71 | hygiene bionics | Spacer | 2 -> 1 | fold into **bionic bladder** | Dubs Bad Hygiene | all | **bionic bladder** (existing), hygiene enhancer ↑ |
| 72 | toxin filtration | Spacer | 2 -> 1 | fold into **detoxifier kidney** | Biotech | all | **detoxifier kidney** (existing), detoxifier lung ↑ |
| 73 | neural implants | Spacer | 6 -> 1 | new group | Security Clearance, Integrated Implants, Royalty, Royalty eye bionic | 1 of 6 | learning assistant, royal eye, hacking port, memory databank, wired reflexes, security clearance brain interface |
| 74 | skin glands | Spacer | 4 -> 1 | new group | Integrated Implants, Odyssey, Royalty | 3 of 4 | armorskin gland, stoneskin gland, jotunnskin gland, vacskin gland |
| 75 | optimizing nanobots | Spacer | 2 -> 1 | fold into **organic optimizing nanobots** | EPOE-Forked | - | **organic optimizing nanobots** (existing), instinct optimizing nanobots ↑ |
| 76 | molecular implants | Spacer | 4 -> 1 | new group | Integrated Implants, Royalty, EPOE-Forked Royalty | 1 of 4 | immunoenhancer, bio-tuner, detoxifier enhancer, gourmand tongue |
| 77 | synthetic organ set | Spacer | 6 -> 1 | new group | Core, EPOE-Forked | 1 of 6 | synthetic stomach, synthetic kidney, synthetic liver, synthetic lung, muscle stimulator, AI chip |
| 78 | metabolic stomachs | Spacer | 2 -> 1 | new group | Royalty | all | nuclear stomach, sterilizing stomach |
| 79 | circadian implants | Spacer | 2 -> 1 | new group | Royalty, EPOE-Forked Royalty | 1 of 2 | circadian half-cycler, circadian refresher |
| 80 | ultra mechanitor implants | Ultra | 6 -> 1 | new group | Integrated Implants | - | cerebrex node implant, remote resurrector, warprogrammer interface, signal booster (ultra), mechwomb, remote dominator |
| 81 | teeth replacement | Ultra | 2 -> 1 | fold into **plasteel teeth replacement** | Ushanka Glittertech | - | **plasteel teeth replacement** (existing), golden teeth replacement ↑ |
| 82 | skin replacement | Ultra | 3 -> 1 | fold into **plasteel skin replacement** | Ushanka Glittertech | - | **plasteel skin replacement** (existing), golden skin replacement ↑, glitterlink ↑ |
| 83 | android parts | Ultra | 15 -> 1 | new group | VRE Android | - | android arm, android foot, android hand, android leg, artificial jaw, artificial nose, artificial ribcage, artificial spine, air filter, audio processor, metabolism regulator, neuropump, neutrofilter, optical unit, reactor |
| 84 | ultratech modules | Ultra | 11 -> 1 | new group | Bionic modularity | - | monofang module, monosaw module, monoslash horn module, plasmablade module, plasmafang module, plasmasaw module, plasmaslash horn module, zeusfang module, zeusfist module, zeuskick module, zeustrike horn module |
| 85 | basic mechanitor implants | Archotech | 3 -> 1 | new group | Biotech | all | control sublink (standard), mech gestation processor, control sublink (high) ↑ |
| 86 | high mechanitor implants | Archotech | 3 -> 1 | new group | Mechanoid Invaders, Biotech | 2 of 3 | remote repairer, remote shielder, system interlink |
