Scriptname RW_PlayerAlias extends ReferenceAlias
{Renown and Wanted: re-arms the hourly tick after every load (game-time update registrations need a live script) and
passes location changes on (cleared locations, owned houses, hold-dependent perks).}

Event OnPlayerLoadGame()
	(GetOwningQuest() as RW_Main).OnGameLoad()
EndEvent

Event OnLocationChange(Location akOldLoc, Location akNewLoc)
	(GetOwningQuest() as RW_Main).OnLocationChanged(akOldLoc, akNewLoc)
EndEvent
