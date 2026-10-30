Scriptname RW_MCM extends MCM_ConfigBase
{Renown and Wanted: settings and status page served by MCM Helper (MCM/Config/RenownWanted/config.json).
Options are bound to GlobalVariables there; the one button (Hold life: Undo friends and rivals) calls the function
below.}

Quest Property MainQuest Auto

Function ResetRelationships()
	if ShowMessage("Everyone Renown and Wanted made a friend or rival goes back to neutral. Continue?", true)
		(MainQuest as RW_Main).ResetRelationships()
	endif
EndFunction
