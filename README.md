# Renown and Wanted

Your deeds follow you in Skyrim. Every hold remembers what you did for it, the whole province knows your big
accomplishments, and crime leaves a mark that doesn't fully wash off. Run up a big bounty and the hold sends hunters
after you: a lone mercenary at first, soldiers and their officers if you keep it up.

## Reputation and renown
- **Reputation, per hold (0-100), never drops.** It comes from real progress, tracked as it happens:
  - quests completed for the hold and its people (radiant and side quests count where they happened),
  - dragons killed and dungeons cleared in the hold,
  - owning a house there, and becoming Thane.
- **Renown, across Skyrim (0-100), never drops:** the main quest, the guilds, the civil war, the DLCs.
- **Your fame in a hold** combines both, minus a grudge: being hated in one hold makes it harder (not impossible) to
  be glorified in the others.
- On first install, quest lines you've already finished count at half value, so an existing character isn't treated
  as a nobody.

## Infamy and bounties
- **Infamy (0-100)** rises with every new bounty, twice as fast for violent crimes (assault, murder).
- It fades over time, but only down to a floor: half of the highest infamy you ever reached. Crime is a lasting
  consequence.
- **Bounties decay** once per game day while you're away from the hold: faster with fame there, slower with infamy.
  At zero the hold forgives you; the infamy stays.

## Hunters
- A bounty over 1,000 makes you hunted by that hold. How often and how hard depends on the bounty, your infamy and
  your fame there:
  1. a lone mercenary,
  2. a pair of mercenaries,
  3. a squad of hold soldiers,
  4. officers with soldiers,
  5. an elite crew with a named captain.
- Soldiers come from whoever holds the hold in the civil war. Everyone uses the game's own leveled lists, so overhauls
  that rebalance those lists rebalance the hunters too.
- High infamy starts every party one tier higher.

## Perks
| When | Perk |
|---|---|
| your fame in the current hold is high | **Favored of the Hold**: better prices with its merchants |
| your infamy is (and always was) very low | **Clean Hands**: slightly better prices everywhere |
| your infamy is high | **Dread**: intimidation comes easily |
| your renown is high | **Known Hero**: new non-violent bounties are halved |
| your infamy and renown are both high | **Feared and Respected**: hunter parties come one tier lighter |

## Hold life (1.1)
- **Friends where you're admired.** In a hold where you are Favored, residents you have no history with (the game's
  neutral relationship rank only) become your friends. That is the game's own friendship: friendly greetings, free
  low-value items and a bed in their homes, and it counts toward becoming Thane. Because friends now come easier,
  the friends needed for thanehood go up from 5 to 8 in major holds and from 3 to 5 in minor ones (both adjustable).
- **Rivals where you're infamous.** Where your infamy in a hold reaches 30, its neutral residents turn cold (the
  game's rival rank). They calm down again when your infamy fades.
- **Gifts.** Entering a town where you are Favored, a friend may walk up, greet you and hand you something local
  (35% per visit, at most once every 3 days per hold; rarer gifts at fame 80+).
- **House prices.** The five city houses cost up to twice as much at infamy 100 in that hold and up to 15% less at
  fame 100, starting from whatever price your load order set. Turn this off in the MCM before uninstalling to put the
  prices back.
- An MCM button undoes every friend and rival the mod made (thane progress already earned stays).
- **With Skyrim Reputation installed**, friends and rivals start switched off: Skyrim Reputation reads those ranks with
  some NPCs as favors done and with beggars as charity. Switch them on in the MCM if you want both.

## Settings and status
An MCM page (MCM Helper) shows your renown, infamy, and each hold's reputation and bounty, and has every number:
decay speed, infamy rates and floor, hunter threshold and interval, perk thresholds, hold life (friends, rivals,
gifts, house prices, thane requirements), notifications, debug log.

## Updating from 1.0
Save safety: every 1.0 record keeps its form ID, and the new ones come after them, so 1.1 installs over 1.0 on an
existing save. Hold life starts on its own after the first load.

## Which quests count
The mod ships rules for the base game, its DLCs and Creation Club content
(`SKSE/Plugins/StorageUtilData/RenownWanted/Quests.json`). Quests from other mods count once a rules file names them:
the mod reads every `Quests*.json` in that folder, so a mod or list can add its quests with its own file, e.g.
`Quests_MyQuestMod.json`. Each entry is one line in the string list `rules`:
```
plugin|local form id (decimal)|hold (0-8, -1 = the hold where you finish it)|reputation|renown|editor id
```
Holds: 0 Whiterun, 1 Eastmarch, 2 the Rift, 3 Haafingar, 4 the Reach, 5 the Pale, 6 Falkreath, 7 Hjaalmarch,
8 Winterhold. A quest listed in several files counts once.

## Requirements
- [SKSE64](https://skse.silverlock.org/)
- [PapyrusUtil SE](https://www.nexusmods.com/skyrimspecialedition/mods/13048)
- [powerofthree's Papyrus Extender](https://www.nexusmods.com/skyrimspecialedition/mods/22854)
- For the settings and status page: [MCM Helper](https://www.nexusmods.com/skyrimspecialedition/mods/53000) and
  [SkyUI](https://www.nexusmods.com/skyrimspecialedition/mods/12604)

`RenownWanted.esp` is flagged light (ESL) and has only Skyrim.esm as a master. Tested on Skyrim 1.6.1170 (Steam), in a
Requiem list.

## Building
`Scripts/Source/` are the Papyrus scripts (they import PapyrusUtil and powerofthree's Papyrus Extender sources).
`renown_wanted.toml` describes the plugin's records; the author's own tooling builds `RenownWanted.esp` and the MCM page
from it, and writes `Quests.json` from the base game's quest records (journal type and editor id decide each quest's
weights and hold). The built files are included in the release.

## License
MIT, see [LICENSE](LICENSE). Use it, change it, include it in your lists and mods.
