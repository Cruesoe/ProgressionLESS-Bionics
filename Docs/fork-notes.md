# ProgressionLESS: Bionics fork notes (261015, in progress)

## State

- Repo built from Workshop item 3819707781 (ferny has no public GitHub repo), pushed to Cruesoe/ProgressionLESS-Bionics.
- Rebranded, laid out under `Common`, LoadFolders has identical v1.6/v1.7 lists, LESS preview stamped, deployed to `Mods\ProgressionLESS Bionics`.
- No other mod or fork names `ferny.progressionbionics`; nothing to relink.
- About.xml, README and Steam description still carry N/M placeholders until merges are approved.

## Inventory

644 projects: 562 added by ferny (`Ferny_*`), 82 existing projects rethemed. By era: Medieval 9, Industrial 97, Spacer 487, Ultra 44, Archotech 7. Tabs: Main 607, Anomaly 37.
Genesis pack supports only Core, Royalty, Biotech, Anomaly, Odyssey and Dubs Bad Hygiene folders (about 70 projects).

## Blocker for merging

Every project is also named in ferny's generated `Research Availability` layer (about 57,000 lines: Missing Items, Missing Requirements, Resolve Prerequisites, Original Projects). Merge-Research.ps1 lists these as manual (3 per member, about 1,500 in total). A merged project must be removed only when none of its members' items exist, and prerequisites must be rewired per group. This needs a generator that rebuilds that layer from the merge plan instead of hand edits.

## Draft merge themes (not yet a reviewed table)

Groups follow ferny's own parent projects: one themed project per parent and stage, e.g. prosthetic parts, surrogate organs, bionic body parts, advanced bionic parts, synthetic organs, rib implants, skill chips, Royalty implant families (flesh shaping, healing, molecular, neural, skin glands, metabolism, circadian), Bionic modularity families (melee, ranged, deployers, projectors, utility, power, synthesizers, orbital, chemical, immunizers, subpersonas, ultratech, anomaly, animal), Integrated Implants module families, Alpha Implants animal prosthetics/bionics/work chips/natural weapons, VE Genetics human and animal implants, VRE Android parts, golem modules, ghoul enhancements. Estimated result: roughly 70 to 90 projects.

## Medieval Overhaul

Not supported by the original (no load folder); its Workshop copy wasn't found locally, so the hook hand and steel arm (Smithing) check is still open.
