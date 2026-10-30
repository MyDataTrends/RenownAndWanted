Scriptname RW_Main extends Quest
{Renown and Wanted v0.1 (2026-10-23). Spec: agent/specs/crime-reputation.spec.md.
Per hold: bounty (vanilla crime gold) decays while you are away; reputation from real progress (never drops); infamy
from bounties, remedied only down to a floor. Hunters come while a hold's bounty is over the threshold, tougher with
infamy, milder with fame. v0.2: reputation is event-driven (user, 2026-10-23): each counted quest's completion
(powerofthree's Papyrus Extender quest events; the list is SKSE/Plugins/StorageUtilData/RenownWanted/Quests.json,
built from the load order by dev/RenownWanted/quest_rules.py), dragons killed (OnActorKilled, credited where the dragon
died), locations cleared (credited to their hold when you leave them) and owned houses (first visit).}

; ---- holds (order: Whiterun Eastmarch Rift Haafingar Reach Pale Falkreath Hjaalmarch Winterhold)
Location Property HoldWhiterun Auto
Location Property HoldEastmarch Auto
Location Property HoldRift Auto
Location Property HoldHaafingar Auto
Location Property HoldReach Auto
Location Property HoldPale Auto
Location Property HoldFalkreath Auto
Location Property HoldHjaalmarch Auto
Location Property HoldWinterhold Auto
Faction Property CrimeWhiterun Auto
Faction Property CrimeEastmarch Auto
Faction Property CrimeRift Auto
Faction Property CrimeHaafingar Auto
Faction Property CrimeReach Auto
Faction Property CrimePale Auto
Faction Property CrimeFalkreath Auto
Faction Property CrimeHjaalmarch Auto
Faction Property CrimeWinterhold Auto
GlobalVariable Property gRepWhiterun Auto
GlobalVariable Property gRepEastmarch Auto
GlobalVariable Property gRepRift Auto
GlobalVariable Property gRepHaafingar Auto
GlobalVariable Property gRepReach Auto
GlobalVariable Property gRepPale Auto
GlobalVariable Property gRepFalkreath Auto
GlobalVariable Property gRepHjaalmarch Auto
GlobalVariable Property gRepWinterhold Auto
GlobalVariable Property gInfWhiterun Auto
GlobalVariable Property gInfEastmarch Auto
GlobalVariable Property gInfRift Auto
GlobalVariable Property gInfHaafingar Auto
GlobalVariable Property gInfReach Auto
GlobalVariable Property gInfPale Auto
GlobalVariable Property gInfFalkreath Auto
GlobalVariable Property gInfHjaalmarch Auto
GlobalVariable Property gInfWinterhold Auto

; ---- settings and status (MCM)
GlobalVariable Property gEnabled Auto
GlobalVariable Property gHuntersEnabled Auto
GlobalVariable Property gNotifications Auto
GlobalVariable Property gDebug Auto
GlobalVariable Property gDebugBounty Auto  ; testing: > 0 adds that much bounty in Whiterun on the next tick
GlobalVariable Property gDecayBase Auto
GlobalVariable Property gInfamyDivisor Auto
GlobalVariable Property gViolentMult Auto
GlobalVariable Property gFloorShare Auto
GlobalVariable Property gInfamyDailyDecay Auto
GlobalVariable Property gRemedyDivisor Auto
GlobalVariable Property gHuntThreshold Auto
GlobalVariable Property gHuntIntervalMax Auto
GlobalVariable Property gRepScale Auto
GlobalVariable Property gFavoredThreshold Auto
GlobalVariable Property gKnownHeroThreshold Auto
GlobalVariable Property gDreadThreshold Auto
GlobalVariable Property gCleanThreshold Auto
GlobalVariable Property gRespectedThreshold Auto
GlobalVariable Property gInfamy Auto
GlobalVariable Property gInfamyPeak Auto
GlobalVariable Property gRenown Auto

; ---- world
Quest Property ThaneQuest Auto
Keyword Property CWOwner Auto
Keyword Property LocTypeHabitation Auto
LeveledActor Property MercMelee Auto
LeveledActor Property MercMissile Auto
LeveledActor Property MercBoss Auto
LeveledActor Property GuardImp Auto
LeveledActor Property GuardSons Auto
LeveledActor Property SoldierImp Auto
LeveledActor Property SoldierSons Auto
LeveledActor Property CaptainImp Auto
LeveledActor Property CaptainSons Auto
Perk Property PerkFavored Auto
Perk Property PerkClean Auto
Perk Property PerkDread Auto
Keyword Property ActorTypeDragon Auto
Keyword Property LocTypePlayerHouse Auto

; ---- 1.1: hold life. Residents of a hold that admires you become friends (vanilla's friendly greetings, low-value
; items and beds in their homes, and it counts toward thanehood, whose friend counts are raised to offset that);
; where your infamy is high they become rivals. Friends sometimes bring a gift. House prices follow your standing.
GlobalVariable Property gFriendsOn Auto
GlobalVariable Property gRivalsOn Auto
GlobalVariable Property gRivalThreshold Auto
GlobalVariable Property gGiftsOn Auto
GlobalVariable Property gGiftChance Auto
GlobalVariable Property gGiftCooldown Auto
GlobalVariable Property gHousePricesOn Auto
GlobalVariable Property gHouseSurcharge Auto
GlobalVariable Property gHouseDiscount Auto
GlobalVariable Property gThaneMajor Auto
GlobalVariable Property gThaneMinor Auto
GlobalVariable Property FriendsTotalMajorHold Auto
GlobalVariable Property FriendsTotalMinorHold Auto
GlobalVariable Property HPWhiterun Auto
GlobalVariable Property HPWindhelm Auto
GlobalVariable Property HPRiften Auto
GlobalVariable Property HPSolitude Auto
GlobalVariable Property HPMarkarth Auto
Topic Property RelationshipHellos Auto
FormList Property GiftsWhiterun Auto
FormList Property GiftsEastmarch Auto
FormList Property GiftsRift Auto
FormList Property GiftsHaafingar Auto
FormList Property GiftsReach Auto
FormList Property GiftsPale Auto
FormList Property GiftsFalkreath Auto
FormList Property GiftsHjaalmarch Auto
FormList Property GiftsWinterhold Auto
FormList Property GiftsRare Auto

; ---- state (saved with the game)
Location[] holds
Faction[] crimes
GlobalVariable[] repG
GlobalVariable[] infG
String[] holdNames
float[] infPeak        ; highest infamy each hold ever gave you (its floor = share x this)
int[] lastGold
int[] lastViolent
float[] lastParty      ; game day of the last hunter party per hold
bool[] thaneCounted
int questsRegistered = 0
bool initialized = false
float lastDay = 0.0
Actor[] party
float partyDay = 0.0
int partyHold = -1
bool busy = false  ; OnInit can fire twice when the quest is added to a running save; one Setup at a time
; 1.1 (None on a 1.0 save until Setup fills them)
float[] lastGift       ; game day of the last gift per hold
float[] hpBase         ; each hold's house price before this mod scaled it (whatever plugin set it)
bool reputationChecked = false
int pendingGiftHold = -1
FormList[] giftLists
GlobalVariable[] hpG   ; the hold's house price global, None for holds without a city house to buy

; OnInit runs while a save is still loading (a quest added to a running game); the engine then reset this script's
; arrays mid-loop (2026-10-23: 'Cannot access an element of a None array' in Setup). Setup waits 2 s instead.
Event OnInit()
	RegisterForSingleUpdate(2.0)
EndEvent

Event OnUpdate()
	if pendingGiftHold >= 0
		int h = pendingGiftHold
		pendingGiftHold = -1
		GiveGift(Game.GetPlayer(), h)
	else
		Setup()
	endif
EndEvent

Function OnGameLoad()
	Setup()
EndFunction

Function Setup()
	if busy
		return
	endif
	busy = true
	holds = new Location[9]
	holds[0] = HoldWhiterun
	holds[1] = HoldEastmarch
	holds[2] = HoldRift
	holds[3] = HoldHaafingar
	holds[4] = HoldReach
	holds[5] = HoldPale
	holds[6] = HoldFalkreath
	holds[7] = HoldHjaalmarch
	holds[8] = HoldWinterhold
	crimes = new Faction[9]
	crimes[0] = CrimeWhiterun
	crimes[1] = CrimeEastmarch
	crimes[2] = CrimeRift
	crimes[3] = CrimeHaafingar
	crimes[4] = CrimeReach
	crimes[5] = CrimePale
	crimes[6] = CrimeFalkreath
	crimes[7] = CrimeHjaalmarch
	crimes[8] = CrimeWinterhold
	repG = new GlobalVariable[9]
	repG[0] = gRepWhiterun
	repG[1] = gRepEastmarch
	repG[2] = gRepRift
	repG[3] = gRepHaafingar
	repG[4] = gRepReach
	repG[5] = gRepPale
	repG[6] = gRepFalkreath
	repG[7] = gRepHjaalmarch
	repG[8] = gRepWinterhold
	infG = new GlobalVariable[9]
	infG[0] = gInfWhiterun
	infG[1] = gInfEastmarch
	infG[2] = gInfRift
	infG[3] = gInfHaafingar
	infG[4] = gInfReach
	infG[5] = gInfPale
	infG[6] = gInfFalkreath
	infG[7] = gInfHjaalmarch
	infG[8] = gInfWinterhold
	holdNames = new String[9]
	holdNames[0] = "Whiterun"
	holdNames[1] = "Eastmarch"
	holdNames[2] = "the Rift"
	holdNames[3] = "Haafingar"
	holdNames[4] = "the Reach"
	holdNames[5] = "the Pale"
	holdNames[6] = "Falkreath"
	holdNames[7] = "Hjaalmarch"
	holdNames[8] = "Winterhold"
	if !initialized
		infPeak = new float[9]
		lastGold = new int[9]
		lastViolent = new int[9]
		lastParty = new float[9]
		thaneCounted = new bool[9]
		party = new Actor[5]
		int i = 0
		while i < 9
			lastGold[i] = crimes[i].GetCrimeGold()
			lastViolent[i] = crimes[i].GetCrimeGoldViolent()
			lastParty[i] = -100.0  ; no party yet: the first may come as soon as the bounty is high enough
			i += 1
		endwhile
		lastDay = Utility.GetCurrentGameTime()
		initialized = true
		Log("installed; renown " + gRenown.GetValue())
	endif
	SetupHoldLife()
	RegisterEvents()
	RegisterForSingleUpdateGameTime(1.0)
	busy = false
EndFunction




Event OnUpdateGameTime()
	if gEnabled.GetValue() > 0.5
		Tick()
	endif
	RegisterForSingleUpdateGameTime(1.0)
EndEvent

Function Tick()
	Actor player = Game.GetPlayer()
	int h = CurrentHold(player)
	if gDebugBounty.GetValue() > 0.0
		crimes[0].ModCrimeGold(gDebugBounty.GetValue() as int, false)
		gDebugBounty.SetValue(0.0)
	endif
	ProcessThanes()
	ProcessCrime()
	float now = Utility.GetCurrentGameTime()
	if Math.Floor(now) > Math.Floor(lastDay)
		DailyDecay(player, (Math.Floor(now) - Math.Floor(lastDay)) as float)
		lastDay = now
	endif
	if gHuntersEnabled.GetValue() > 0.5
		CleanupParty(player, now)
		MaybeHunt(player, h, now)
	endif
	UpdatePerks(player, h)
	ApplyThaneCounts()
	HoldLife(player, h)
	Log("tick: hold " + h + ", renown " + gRenown.GetValue() + ", infamy " + gInfamy.GetValue() + ", Whiterun bounty " + crimes[0].GetCrimeGold() + ", heat " + Heat(0) + ", fame " + Fame(0) + ", party " + partyHold)
EndFunction

int Function CurrentHold(Actor player)
	int i = 0
	while i < 9
		if player.IsInLocation(holds[i])
			return i
		endif
		i += 1
	endwhile
	return -1
EndFunction


; ---------------------------------------------------------------- reputation events
; Quest rules: every Quests*.json in Data/SKSE/Plugins/StorageUtilData/RenownWanted/ (JsonUtil paths are relative to
; StorageUtilData). The mod ships Quests.json (base game and DLC); a list or another mod adds its quests with its own
; Quests_<name>.json, string list "rules", one per quest: plugin|local form id (decimal)|hold (-1 = where completed)|
; reputation|renown|editor id. A quest listed in several files counts once (the first file, by name).
int registerRun = 0

; Registers every quest in the rules files for its stop event and keeps its hold and weights on the quest form
; (StorageUtil, saved with the game). The first run also counts quest-line milestones already reached (renown at half).
Function RegisterEvents()
	PO3_Events_Form.RegisterForActorKilled(Self)
	registerRun += 1
	String[] files = JsonUtil.JsonInFolder("RenownWanted")
	bool firstRun = questsRegistered == 0
	float seed = 0.0
	int count = 0
	int total = 0
	String used = ""
	int fi = 0
	while fi < files.Length
		String name = files[fi]
		if StringUtil.Find(name, "Quests") == 0
			if StringUtil.Find(name, ".json") > 0
				name = StringUtil.Substring(name, 0, StringUtil.Find(name, ".json"))
			endif
			String file = "RenownWanted/" + name
			used += name + " "
			int n = JsonUtil.StringListCount(file, "rules")
			total += n
			int i = 0
			while i < n
				String[] f = StringUtil.Split(JsonUtil.StringListGet(file, "rules", i), "|")
				if f.Length >= 5
					Quest q = Game.GetFormFromFile(f[1] as int, f[0]) as Quest
					if q && StorageUtil.GetIntValue(q, "RW_run") != registerRun
						StorageUtil.SetIntValue(q, "RW_run", registerRun)
						PO3_Events_Form.RegisterForQuest(Self, q)
						StorageUtil.SetIntValue(q, "RW_hold", f[2] as int)
						StorageUtil.SetFloatValue(q, "RW_rep", f[3] as float)
						StorageUtil.SetFloatValue(q, "RW_renown", f[4] as float)
						if firstRun && q.IsCompleted()
							seed += (f[4] as float) * 0.5
						endif
						count += 1
					endif
				endif
				i += 1
			endwhile
		endif
		fi += 1
	endwhile
	questsRegistered = count
	if firstRun && seed > 0.0
		AddRenown(seed)
	endif
	; always written (one line per load): proves the rules files were found where JsonUtil looks
	MiscUtil.WriteToFile("Data/SKSE/Plugins/RenownWanted/Debug.log", "registered " + count + " of " + total + " quests from " + used + "; renown seed " + seed + "\n", true, true)
EndFunction

Event OnQuestStop(Quest akQuest)
	if gEnabled.GetValue() < 0.5 || !akQuest.IsCompleted()
		return
	endif
	Actor player = Game.GetPlayer()
	int h = StorageUtil.GetIntValue(akQuest, "RW_hold", -1)
	if h < 0
		h = CurrentHold(player)
	endif
	float scale = gRepScale.GetValue()
	float rep = StorageUtil.GetFloatValue(akQuest, "RW_rep") * scale
	float renown = StorageUtil.GetFloatValue(akQuest, "RW_renown") * scale
	if h >= 0
		AddRep(h, rep)
	else
		AddRenown(rep * 0.5)
	endif
	if renown > 0.0
		AddRenown(renown)
		if renown >= 8.0
			Notify("Word of your deeds spreads across Skyrim.")
		endif
	endif
	ProcessThanes()
	Log("quest " + akQuest.GetName() + " completed: hold " + h + " +" + rep + ", renown +" + renown)
EndEvent

; dragons: credited to the hold where the dragon died, when you or your companions brought it down
Event OnActorKilled(Actor akVictim, Actor akKiller)
	if gEnabled.GetValue() < 0.5 || !akVictim || !akVictim.HasKeyword(ActorTypeDragon)
		return
	endif
	Actor player = Game.GetPlayer()
	if akKiller != player && !(akKiller && akKiller.IsPlayerTeammate())
		return
	endif
	int h = CurrentHold(akVictim)
	float scale = gRepScale.GetValue()
	if h >= 0
		AddRep(h, 5.0 * scale)
		Notify(holdNames[h] + " will remember the dragon you slew.")
	endif
	AddRenown(1.0 * scale)
	Log("dragon killed in hold " + h)
EndEvent

; locations: a cleared location counts for its hold when you leave it (once; one already cleared when you enter
; does not count); a house that is yours counts for its hold on your first visit
Function OnLocationChanged(Location akOld, Location akNew)
	if gEnabled.GetValue() < 0.5 || !initialized
		return
	endif
	Actor player = Game.GetPlayer()
	float scale = gRepScale.GetValue()
	if akOld && akOld.IsCleared() && StorageUtil.GetIntValue(akOld, "RW_cleared") == 0
		StorageUtil.SetIntValue(akOld, "RW_cleared", 1)
		int h = HoldOfLocation(akOld)
		if h >= 0
			AddRep(h, 3.0 * scale)
			Log("cleared " + akOld.GetName() + " in hold " + h)
		endif
	endif
	if akNew
		if akNew.IsCleared()
			StorageUtil.SetIntValue(akNew, "RW_cleared", 1)
		endif
		Cell c = player.GetParentCell()
		if StorageUtil.GetIntValue(akNew, "RW_home") == 0 && c && c.GetActorOwner() == player.GetActorBase()
			StorageUtil.SetIntValue(akNew, "RW_home", 1)
			int hh = HoldOfLocation(akNew)
			if hh >= 0
				AddRep(hh, 10.0 * scale)
				Notify("A home in " + holdNames[hh] + ". Its people count you as one of their own.")
			endif
		endif
	endif
	ProcessThanes()
	int here = CurrentHold(player)
	UpdatePerks(player, here)
	HoldLife(player, here)
	if akNew && here >= 0 && akNew.HasKeyword(LocTypeHabitation)
		MaybeGift(here)
	endif
EndFunction

int Function HoldOfLocation(Location loc)
	int i = 0
	while i < 9
		if loc == holds[i] || holds[i].IsChild(loc)
			return i
		endif
		i += 1
	endwhile
	return -1
EndFunction

Function ProcessThanes()
	FavorJarlsMakeFriendsScript f = ThaneQuest as FavorJarlsMakeFriendsScript
	if !f
		return
	endif
	int i = 0
	while i < 9
		if !thaneCounted[i] && IsThane(f, i)
			thaneCounted[i] = true
			AddRep(i, 20.0)
			AddRenown(3.0)
			Notify("You are Thane of " + holdNames[i] + ". Its people will not forget it.")
		endif
		i += 1
	endwhile
EndFunction

bool Function IsThane(FavorJarlsMakeFriendsScript f, int i)
	if i == 0
		return f.WhiterunImpGetOutofJail > 0 || f.WhiterunSonsGetOutofJail > 0
	elseif i == 1
		return f.EastmarchImpGetOutofJail > 0 || f.EastmarchSonsGetOutofJail > 0
	elseif i == 2
		return f.RiftImpGetoutofJail > 0 || f.RiftSonsGetOutofJail > 0
	elseif i == 3
		return f.HaafingarImpGetOutofJail > 0 || f.HaafingarSonsGetOutofJail > 0
	elseif i == 4
		return f.ReachImpGetOutofJail > 0 || f.ReachSonsGetOutofJail > 0
	elseif i == 5
		return f.PaleImpGetOutofJail > 0 || f.PaleSonsGetOutofJail > 0
	elseif i == 6
		return f.FalkreathImpGetOutofJail > 0 || f.FalkreathSonsGetOutofJail > 0
	elseif i == 7
		return f.HjaalmarchImpGetOutofJail > 0 || f.HjaalmarchSonsGetOutofJail > 0
	endif
	return f.WinterholdImpGetOutofJail > 0 || f.WinterholdSonsGetOutofJail > 0
EndFunction

; Reputation never drops. A grudge elsewhere (the worst hold's infamy) slows new reputation by up to 30%.
Function AddRep(int h, float amount)
	float worst = 0.0
	int i = 0
	while i < 9
		if i != h && infG[i].GetValue() > worst
			worst = infG[i].GetValue()
		endif
		i += 1
	endwhile
	float mult = 1.0 - 0.3 * Clamp(worst / 50.0, 0.0, 1.0)
	repG[h].SetValue(Clamp(repG[h].GetValue() + amount * mult, 0.0, 100.0))
EndFunction

Function AddRenown(float amount)
	gRenown.SetValue(Clamp(gRenown.GetValue() + amount, 0.0, 100.0))
EndFunction

; Fame in a hold: its reputation, a share of renown, minus the infamy you earned there and part of the worst grudge
; elsewhere when it outweighs this hold's regard.
float Function Fame(int h)
	float worst = 0.0
	int i = 0
	while i < 9
		if i != h && infG[i].GetValue() > worst
			worst = infG[i].GetValue()
		endif
		i += 1
	endwhile
	float rep = repG[h].GetValue()
	float grudge = worst - rep
	if grudge < 0.0
		grudge = 0.0
	endif
	return Clamp(rep + gRenown.GetValue() / 4.0 - infG[h].GetValue() - grudge / 3.0, 0.0, 100.0)
EndFunction

; ---------------------------------------------------------------- crime and infamy
Function ProcessCrime()
	int i = 0
	while i < 9
		int g = crimes[i].GetCrimeGold()
		int v = crimes[i].GetCrimeGoldViolent()
		if g > lastGold[i]
			int dv = v - lastViolent[i]
			if dv < 0
				dv = 0
			endif
			int dnv = (g - lastGold[i]) - dv
			if dnv > 0 && gRenown.GetValue() >= gKnownHeroThreshold.GetValue()
				; Known Hero: new non-violent bounties are halved
				int nv = crimes[i].GetCrimeGoldNonViolent()
				crimes[i].SetCrimeGold(nv - dnv / 2)
				dnv -= dnv / 2
				Notify("Your renown softens " + holdNames[i] + "'s charge.")
			endif
			float add = (dnv + dv * gViolentMult.GetValue()) / gInfamyDivisor.GetValue()
			AddInfamy(i, add)
			Log(holdNames[i] + " bounty up: +" + dnv + " (+" + dv + " violent), infamy +" + add)
		elseif g < lastGold[i]
			; paid, jailed or forgiven by a guard: a remedy, down to the floor
			AddInfamy(i, -(lastGold[i] - g) / gRemedyDivisor.GetValue())
		endif
		lastGold[i] = crimes[i].GetCrimeGold()
		lastViolent[i] = crimes[i].GetCrimeGoldViolent()
		i += 1
	endwhile
EndFunction

Function AddInfamy(int h, float amount)
	float cur = infG[h].GetValue() + amount
	if cur > infPeak[h]
		infPeak[h] = cur
	endif
	float floorV = infPeak[h] * gFloorShare.GetValue()
	if cur < floorV
		cur = floorV
	endif
	infG[h].SetValue(Clamp(cur, 0.0, 100.0))
	float total = 0.0
	int i = 0
	while i < 9
		total += infG[i].GetValue()
		i += 1
	endwhile
	gInfamy.SetValue(Clamp(total, 0.0, 100.0))
	if gInfamy.GetValue() > gInfamyPeak.GetValue()
		gInfamyPeak.SetValue(gInfamy.GetValue())
	endif
EndFunction

; Once per game day: bounties of holds you are away from fade (fame speeds it, infamy slows it); infamy fades to
; its floor.
Function DailyDecay(Actor player, float days)
	int i = 0
	while i < 9
		int g = crimes[i].GetCrimeGold()
		if g > 0 && !player.IsInLocation(holds[i])
			int amount = (gDecayBase.GetValue() * days * (1.0 + Fame(i) / 100.0) / (1.0 + gInfamy.GetValue() / 100.0)) as int
			int nv = crimes[i].GetCrimeGoldNonViolent()
			int v = crimes[i].GetCrimeGoldViolent()
			if amount >= nv
				crimes[i].SetCrimeGold(0)
				int rest = v - (amount - nv)
				if rest < 0
					rest = 0
				endif
				crimes[i].SetCrimeGoldViolent(rest)
			else
				crimes[i].SetCrimeGold(nv - amount)
			endif
			lastGold[i] = crimes[i].GetCrimeGold()
			lastViolent[i] = crimes[i].GetCrimeGoldViolent()
			if lastGold[i] == 0
				Notify(holdNames[i] + " no longer wants you. Your name is not forgotten.")
			endif
		endif
		if infG[i].GetValue() > 0.0
			AddInfamy(i, -gInfamyDailyDecay.GetValue() * days)
		endif
		i += 1
	endwhile
EndFunction

; ---------------------------------------------------------------- hunters
float Function Heat(int h)
	float b = crimes[h].GetCrimeGold() / 1000.0
	return b * (1.0 + gInfamy.GetValue() / 50.0) / (1.0 + Fame(h) / 50.0)
EndFunction

Function MaybeHunt(Actor player, int here, float now)
	if partyHold >= 0 || player.IsInInterior() || player.IsInCombat()
		return
	endif
	Location loc = player.GetCurrentLocation()
	if loc && loc.HasKeyword(LocTypeHabitation)
		return
	endif
	int best = -1
	float bestHeat = 0.0
	int i = 0
	while i < 9
		if crimes[i].GetCrimeGold() > gHuntThreshold.GetValue()
			float heat = Heat(i)
			float interval = gHuntIntervalMax.GetValue() - heat
			if interval < 1.0
				interval = 1.0
			endif
			if heat > bestHeat && now - lastParty[i] >= interval
				best = i
				bestHeat = heat
			endif
		endif
		i += 1
	endwhile
	if best >= 0
		SpawnParty(player, best, bestHeat, now)
	endif
EndFunction

; tier 1 a lone mercenary, 2 a mercenary pair, 3 hold guards, 4 more guards with a soldier, 5 an elite crew with a
; captain. High infamy starts one tier higher; Feared and Respected (infamy and renown both high) one lower.
Function SpawnParty(Actor player, int h, float heat, float now)
	int tier = Math.Floor(heat)  ; heat 1 (a bounty just over the threshold, no infamy or fame) = a lone mercenary
	if gInfamy.GetValue() >= 60.0
		tier += 1
	endif
	if gInfamy.GetValue() >= gRespectedThreshold.GetValue() && gRenown.GetValue() >= gRespectedThreshold.GetValue()
		tier -= 1
	endif
	if tier < 1
		tier = 1
	elseif tier > 5
		tier = 5
	endif
	bool sons = holds[h].GetKeywordData(CWOwner) == 2.0
	String holdName = holdNames[h]
	if tier == 1
		Place(player, 0, MercMelee, holdName + " Bounty Hunter", false, h)
	elseif tier == 2
		Place(player, 0, MercMelee, holdName + " Bounty Hunter", false, h)
		Place(player, 1, MercMissile, holdName + " Bounty Hunter", false, h)
	elseif tier == 3
		Place(player, 0, Pick(sons, GuardSons, GuardImp), "Guard of " + holdName, true, h)
		Place(player, 1, Pick(sons, GuardSons, GuardImp), "Guard of " + holdName, true, h)
		Place(player, 2, MercBoss, holdName + " Bounty Hunter", false, h)
	elseif tier == 4
		Place(player, 0, Pick(sons, GuardSons, GuardImp), "Guard of " + holdName, true, h)
		Place(player, 1, Pick(sons, GuardSons, GuardImp), "Guard of " + holdName, true, h)
		Place(player, 2, Pick(sons, SoldierSons, SoldierImp), "Soldier of " + holdName, true, h)
		Place(player, 3, MercBoss, holdName + " Bounty Hunter", false, h)
	else
		Place(player, 0, Pick(sons, SoldierSons, SoldierImp), "Soldier of " + holdName, true, h)
		Place(player, 1, Pick(sons, SoldierSons, SoldierImp), "Soldier of " + holdName, true, h)
		Place(player, 2, Pick(sons, GuardSons, GuardImp), "Guard of " + holdName, true, h)
		Place(player, 3, Pick(sons, GuardSons, GuardImp), "Guard of " + holdName, true, h)
		Actor cap = Place(player, 4, Pick(sons, CaptainSons, CaptainImp), "Hunt Captain of " + holdName, true, h)
		if cap
			cap.ModActorValue("Health", cap.GetBaseActorValue("Health"))
		endif
	endif
	partyHold = h
	partyDay = now
	lastParty[h] = now
	if tier >= 3
		Notify(holdName + " has sent its soldiers for you.")
	else
		Notify("Bounty hunters from " + holdName + " have found you.")
	endif
	Log("party tier " + tier + " from " + holdName + ", heat " + heat)
	SendModEvent("RenownWanted_Hunters", holdName, tier as float)  ; for other mods (the session recorder clips it)
EndFunction

LeveledActor Function Pick(bool sons, LeveledActor a, LeveledActor b)
	if sons
		return a
	endif
	return b
EndFunction

; Placed behind the player at a distance, then sent after them. Hold guards get the hold's crime faction, so
; yielding to them leads to the usual arrest.
Actor Function Place(Actor player, int slot, LeveledActor what, String name, bool lawful, int h)
	float a = player.GetAngleZ() + 180.0 + (slot - 2) * 20.0
	float dist = 1800.0 + slot * 120.0
	Actor act = player.PlaceAtMe(what) as Actor
	if !act
		return None
	endif
	act.MoveTo(player, dist * Math.Sin(a), dist * Math.Cos(a), 50.0, false)
	act.SetDisplayName(name, true)
	if lawful
		act.SetCrimeFaction(crimes[h])
	endif
	act.StartCombat(player)
	party[slot] = act
	return act
EndFunction

; The party leaves the world once all are dead and you are away, or after a day and a half.
Function CleanupParty(Actor player, float now)
	if partyHold < 0
		return
	endif
	bool alive = false
	bool near = false
	int i = 0
	while i < 5
		if party[i] && !party[i].IsDead()
			alive = true
		endif
		if party[i] && party[i].GetDistance(player) < 4000.0
			near = true
		endif
		i += 1
	endwhile
	if (!alive && !near) || now - partyDay > 1.5
		i = 0
		while i < 5
			if party[i]
				party[i].Delete()
				party[i] = None
			endif
			i += 1
		endwhile
		partyHold = -1
	endif
EndFunction

; ---------------------------------------------------------------- hold life (1.1)
Function SetupHoldLife()
	if !lastGift
		lastGift = new float[9]
		int i = 0
		while i < 9
			lastGift[i] = -100.0
			i += 1
		endwhile
	endif
	if !hpBase
		hpBase = new float[9]
	endif
	giftLists = new FormList[9]
	giftLists[0] = GiftsWhiterun
	giftLists[1] = GiftsEastmarch
	giftLists[2] = GiftsRift
	giftLists[3] = GiftsHaafingar
	giftLists[4] = GiftsReach
	giftLists[5] = GiftsPale
	giftLists[6] = GiftsFalkreath
	giftLists[7] = GiftsHjaalmarch
	giftLists[8] = GiftsWinterhold
	hpG = new GlobalVariable[9]  ; the five holds whose steward sells a city house (vanilla HousePurchase)
	hpG[0] = HPWhiterun
	hpG[1] = HPWindhelm
	hpG[2] = HPRiften
	hpG[3] = HPSolitude
	hpG[4] = HPMarkarth
	; Skyrim Reputation counts rank >= 1 with certain NPCs as favors done (its sr_rqc_scr_favor*.psc) and with beggars
	; as charity: making residents friends would credit deeds never done. With it loaded, ranks are left alone unless
	; the player turns them back on.
	if !reputationChecked
		reputationChecked = true
		if Game.GetModByName("SkyrimReputation_SSE.esp") != 255
			gFriendsOn.SetValue(0.0)
			gRivalsOn.SetValue(0.0)
			Notify("Skyrim Reputation is installed: hold friendships and rivalries are off (MCM: Hold life).")
		endif
	endif
	ApplyThaneCounts()
EndFunction

; Vanilla counts friends toward a hold's thane quest (FavorJarlsMakeFriendsScript, through the Story Manager's
; relationship-change event), up to FriendsTotalMajorHold / MinorHold (5 / 3). Friends made here count too, so the
; totals are raised (MCM).
Function ApplyThaneCounts()
	if FriendsTotalMajorHold && gThaneMajor.GetValue() > 0.0
		FriendsTotalMajorHold.SetValue(gThaneMajor.GetValue())
	endif
	if FriendsTotalMinorHold && gThaneMinor.GetValue() > 0.0
		FriendsTotalMinorHold.SetValue(gThaneMinor.GetValue())
	endif
EndFunction

Function HoldLife(Actor player, int h)
	if h < 0 || !giftLists
		return
	endif
	UpdateRelationships(player, h)
	UpdateHousePrice(h)
EndFunction

; Residents of the hold loaded around you, at the neutral rank only: friends where the hold admires you (Favored),
; rivals where your infamy there is high. Spouses, followers, guards and anyone at another rank are left alone. The
; changed actors are remembered (StorageUtil) so rivals calm down when infamy fades, and the MCM can undo all of it.
Function UpdateRelationships(Actor player, int h)
	bool friends = gFriendsOn.GetValue() > 0.5 && Fame(h) >= gFavoredThreshold.GetValue()
	bool rivals = gRivalsOn.GetValue() > 0.5 && infG[h].GetValue() >= gRivalThreshold.GetValue()
	Actor[] near = PO3_SKSEFunctions.GetActorsByProcessingLevel(0)
	int made = 0
	int calmed = 0
	int i = 0
	while i < near.Length
		Actor a = near[i]
		if a && a != player && !a.IsDead() && !a.IsGuard() && !a.IsPlayerTeammate() && a.GetCrimeFaction() == crimes[h]
			int rank = a.GetRelationshipRank(player)
			if rank == 0
				if friends
					a.SetRelationshipRank(player, 1)
					StorageUtil.FormListAdd(None, "RW_Friends", a, false)
					made += 1
				elseif rivals
					a.SetRelationshipRank(player, -1)
					StorageUtil.FormListAdd(None, "RW_Rivals", a, false)
					made += 1
				endif
			elseif rank == -1 && !rivals && StorageUtil.FormListHas(None, "RW_Rivals", a)
				a.SetRelationshipRank(player, 0)  ; infamy faded: the grudge goes with it
				StorageUtil.FormListRemove(None, "RW_Rivals", a, true)
				calmed += 1
				if friends
					a.SetRelationshipRank(player, 1)
					StorageUtil.FormListAdd(None, "RW_Friends", a, false)
				endif
			endif
		endif
		i += 1
	endwhile
	Log("hold " + h + ": fame " + Fame(h) + ", infamy " + infG[h].GetValue() + ", " + near.Length + " actors loaded, " + made + " now friends/rivals, " + calmed + " rivals calmed (friends " + friends + ", rivals " + rivals + ")")
EndFunction

; MCM: everyone this mod befriended or turned into a rival goes back to neutral, if they still have that rank
Function ResetRelationships()
	Actor player = Game.GetPlayer()
	int n = 0
	int i = StorageUtil.FormListCount(None, "RW_Friends")
	while i > 0
		i -= 1
		Actor a = StorageUtil.FormListGet(None, "RW_Friends", i) as Actor
		if a && a.GetRelationshipRank(player) == 1
			a.SetRelationshipRank(player, 0)
			n += 1
		endif
	endwhile
	i = StorageUtil.FormListCount(None, "RW_Rivals")
	while i > 0
		i -= 1
		Actor a = StorageUtil.FormListGet(None, "RW_Rivals", i) as Actor
		if a && a.GetRelationshipRank(player) == -1
			a.SetRelationshipRank(player, 0)
			n += 1
		endif
	endwhile
	StorageUtil.FormListClear(None, "RW_Friends")
	StorageUtil.FormListClear(None, "RW_Rivals")
	Debug.Notification("Renown and Wanted: " + n + " residents back to neutral.")
	Log("undo: " + n + " residents back to neutral")
EndFunction

; The hold's city house: its price as the load order set it, + up to gHouseSurcharge % at infamy 100 there,
; - up to gHouseDiscount % at fame 100. The steward shows and charges this global (HousePurchaseScript).
Function UpdateHousePrice(int h)
	GlobalVariable g = hpG[h]
	if !g
		return
	endif
	if hpBase[h] <= 0.0
		hpBase[h] = g.GetValue()
	endif
	float mult = 1.0
	if gHousePricesOn.GetValue() > 0.5
		mult = 1.0 + gHouseSurcharge.GetValue() / 100.0 * infG[h].GetValue() / 100.0 - gHouseDiscount.GetValue() / 100.0 * Fame(h) / 100.0
	endif
	g.SetValue(Math.Floor(hpBase[h] * mult + 0.5) as float)
	Log("house price in hold " + h + ": " + g.GetValue() + " (base " + hpBase[h] + ")")
EndFunction

; Entering a town where the hold admires you: a chance (per visit, with a cooldown per hold) that a friend brings a gift.
; The walk and the handoff run a few seconds later, off the location event.
Function MaybeGift(int h)
	if gGiftsOn.GetValue() < 0.5 || pendingGiftHold >= 0 || Fame(h) < gFavoredThreshold.GetValue()
		Log("gift in hold " + h + ": not now (on " + gGiftsOn.GetValue() + ", fame " + Fame(h) + ")")
		return
	endif
	if Utility.GetCurrentGameTime() - lastGift[h] < gGiftCooldown.GetValue() || Utility.RandomFloat(0.0, 100.0) >= gGiftChance.GetValue()
		Log("gift in hold " + h + ": cooldown or chance")
		return
	endif
	Log("gift in hold " + h + ": a friend will come")
	pendingGiftHold = h
	RegisterForSingleUpdate(8.0)
EndFunction

Function GiveGift(Actor player, int h)
	if CurrentHold(player) != h || player.IsInCombat()
		return
	endif
	Actor giver = PickGiver(player, h)
	if !giver
		Log("gift in hold " + h + ": no friend nearby")
		return
	endif
	lastGift[h] = Utility.GetCurrentGameTime()
	giver.PathToReference(player, 0.5)
	if giver.GetDistance(player) > 400.0 || player.IsInCombat() || giver.IsInCombat()
		return
	endif
	giver.SetLookAt(player)
	giver.Say(RelationshipHellos)  ; vanilla's voiced friendly greetings, for rank >= 1 (the giver is a friend)
	Utility.Wait(2.5)
	Form item = PickGift(h)
	if item
		player.AddItem(item, 1, true)
		Debug.Notification(giver.GetDisplayName() + " presses a gift into your hands: " + item.GetName() + ". \"For what you did for " + holdNames[h] + ".\"")
		Log("gift in hold " + h + " from " + giver.GetDisplayName() + ": " + item.GetName())
	endif
	giver.ClearLookAt()
EndFunction

; a friend of yours from this hold, nearby, not busy: a random named resident among the first 16 found, or a generic
; one when no named resident is around (2026-10-30 test: a nameless "Mercenary" brought the gift)
Actor Function PickGiver(Actor player, int h)
	Actor[] near = PO3_SKSEFunctions.GetActorsByProcessingLevel(0)
	Actor[] named = new Actor[16]
	Actor[] other = new Actor[16]
	int nn = 0
	int no = 0
	int i = 0
	while i < near.Length && nn < 16
		Actor a = near[i]
		if a && a != player && !a.IsDead() && !a.IsGuard() && !a.IsPlayerTeammate() && !a.IsInCombat() && a.GetCrimeFaction() == crimes[h] && a.GetRelationshipRank(player) >= 1 && a.GetDistance(player) < 2500.0
			if a.GetActorBase().IsUnique()
				named[nn] = a
				nn += 1
			elseif no < 16
				other[no] = a
				no += 1
			endif
		endif
		i += 1
	endwhile
	if nn > 0
		return named[Utility.RandomInt(0, nn - 1)]
	elseif no > 0
		return other[Utility.RandomInt(0, no - 1)]
	endif
	return None
EndFunction

; the hold's own gifts; at fame 80+ one time in four something finer
Form Function PickGift(int h)
	FormList l = giftLists[h]
	if Fame(h) >= 80.0 && Utility.RandomInt(0, 3) == 0
		l = GiftsRare
	endif
	if !l || l.GetSize() == 0
		return None
	endif
	return l.GetAt(Utility.RandomInt(0, l.GetSize() - 1))
EndFunction

; ---------------------------------------------------------------- perks
Function UpdatePerks(Actor player, int h)
	SetPerk(player, PerkFavored, h >= 0 && Fame(h) >= gFavoredThreshold.GetValue())
	float c = gCleanThreshold.GetValue()
	SetPerk(player, PerkClean, gInfamy.GetValue() <= c && gInfamyPeak.GetValue() <= c * 2.0)
	SetPerk(player, PerkDread, gInfamy.GetValue() >= gDreadThreshold.GetValue())
EndFunction

Function SetPerk(Actor player, Perk p, bool want)
	if want && !player.HasPerk(p)
		player.AddPerk(p)
	elseif !want && player.HasPerk(p)
		player.RemovePerk(p)
	endif
EndFunction

; ---------------------------------------------------------------- helpers
float Function Clamp(float x, float lo, float hi)
	if x < lo
		return lo
	elseif x > hi
		return hi
	endif
	return x
EndFunction

Function Notify(String s)
	if gNotifications.GetValue() > 0.5
		Debug.Notification(s)
	endif
EndFunction

Function Log(String s)
	if gDebug.GetValue() > 0.5
		Debug.Trace("[RenownWanted] " + s)
		; also straight to a file: the Papyrus log loses its tail when the game is closed (2026-10-23)
		MiscUtil.WriteToFile("Data/SKSE/Plugins/RenownWanted/Debug.log", s + "\n", true, true)
	endif
	if gDebug.GetValue() > 1.5  ; testing: also on screen (the Papyrus log loses its tail when the game is killed)
		Debug.Notification("RW: " + s)
	endif
EndFunction

