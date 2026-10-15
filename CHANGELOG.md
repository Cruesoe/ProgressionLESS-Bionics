# Changelog

## 0.1.18 — 2026-10-14

- Added availability checks across all 548 added research projects. Projects are removed from the loaded XML when the corresponding item is absent, its manufacturing route is disabled, or ReplaceLib redirects it to another item.
- Mirrored item-level optional requirements, including EBSG Framework and DLC requirements. Integrated Implants’ protective lens and other module projects no longer remain when their required framework or source items are absent; the bionic liver project no longer remains when its source folder excludes the item.
- Preserved original research IDs. Original projects are not rethemed when their root item is absent, and their optional item requirements now also guard those retheming patches.
- Reconnected references to missing added projects to a surviving replacement project where mapped, otherwise to available prerequisites from the omitted project. Integrated Implants liver, kidney, and lung projects prefer the corresponding EPOE synthetic-organ projects when those items are absent or replaced; this does not replace the organ items itself.
- Retained the seven existing Bionic modularity priority replacements and their standalone research paths.

## 0.1.17 — 2026-10-03

- Changed standard and high signal-booster research from Archotech to Spacer (500 base research points each).
- Changed ultra signal booster, Remote dominator, Remote resurrector, Mechwomb, Warprogrammer interface, and Cerebrex node implant research from Archotech to Ultra (800 base research points each).
- Research tiers now follow their original mechtech research gates rather than the items’ Archotech classifications. Item tech levels, effects, recipes, and project prerequisites are unchanged.

## 0.1.16 — 2026-10-03

- Added Bionic replacements as a direct prerequisite for Pilot assistant, Gunnery assistant, and Personal grav engine. Their existing Advanced gravtech / Gravship prerequisites remain, including when those technologies appear on the separate Grav study page.
- Confirmed Extra limbs still unlocks 30 additional-arm surgery options in the current mod configuration. It is retained as surgical research; its empty item-unlock display does not mean those surgeries were removed.
- Preserved existing research costs and all overlap changes.

## 0.1.15 — 2026-10-01

### Bionic modularity + Integrated Implants

When both mods are active, Bionic modularity takes priority for these seven overlapping modules:

| Integrated Implants item replaced | Bionic modularity item retained |
|---|---|
| revenant vertebrae module (`LTS_ModuleSpine_RevenantVertebrae`) | revenant vertebrae module (`BM_SpacerRevenantVertebraeAbilityModule`) |
| venom fangs module (`LTS_ModuleJaw_VenomFangs`) | venom fangs module (`BM_SpacerVenomFangsCombatModule`) |
| detoxifier kidney module (`LTS_ModuleKidney_DetoxifierKidney`) | detoxifier module (`BM_SpacerDetoxifierUtilityModule`) |
| detoxifier lung module (`LTS_ModuleLung_DetoxifierLung`) | atmofilter module (`BM_SpacerAtmofilterUtilityModule`) |
| bionic claw module (`LTS_ModuleArm_BionicClaw`) | power claw module (`BM_SpacerPowerClawCombatModule`) |
| arm blade module (`LTS_ModuleArm_ArmBlade`) | elbow blade module (`BM_SpacerElbowBladeCombatModule`) |
| zeusknuckles module (`LTS_ModuleArm_ZeusKnuckles`) | zeusfist module (`BM_SpacerZeusfistCombatModule`) |

- Added ReplaceLib as a dependency and added seven guarded replacers. Existing item references and saved item names are redirected by ReplaceLib.
- The seven duplicate Progression: Bionics research projects and their recipe patches load only when Integrated Implants is active and Bionic modularity is absent. No original game or source-mod research IDs are deleted.
- With both mods active, 637 distinct item projects load: 96 reused original projects and 541 added projects. The complete conditional catalogue still covers 644 items.
- Crypto claw module now requires Power claw module when both mods are active; it retains Bionic claw module as its prerequisite when Integrated Implants is used without Bionic modularity. All prerequisite references to the seven replaced projects are redirected.
- Disabled the replaced items’ inherited automatic recipes and removed their explicit manufacturing recipes when present. Shared items use Bionic modularity’s crafting costs, recipes, and research.
- Preserved Integrated Implants’ EBSG self-installation components, slot restrictions, exclusion lists, and installed HediffDefs on the shared items. Existing Bionic modularity surgeries and animal support remain available. Removal of the retained Integrated Implants effects returns the shared item.
- Zeusknuckles’ installed effect uses 22 blunt damage instead of 24 to match zeusfist; its 6 EMP damage and 2-second cooldown remain unchanged.
- Kept the mechanically distinct plasma claw, laser arm blade, rebreather, ranged modules, and other nonduplicate variants.
- Updated the workshop drafts, research catalogue, and coverage audit to explain the conditional replacements.

Validation: XML and research-graph checks passed with both mods, each mod separately, neither mod, missing-original research fallbacks, and the current 1,584-mod configuration. The game has not been launched to verify installation and removal behavior.
