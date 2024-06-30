--		Überschreibt HD Admin Ban Commands

--		If Testumgebung, dann nicht
if		script.Parent.Parent.Parent.Name == "Current" or script.Parent.Parent.Parent.Name == "Archiv" then return end

local		PLAYERS									=		game:GetService("Players")
local		SS										=		game:GetService("ServerStorage")

local		Banland									=		require(script.Parent.Parent)
local		Settings									=		require(script.Parent.Parent.Settings)
local		SystemMessageModul							=		require(script.Parent.SystemMessageModul)

if		not Settings.OverwriteHDAdmin then return end

local		main										=		_G.HDAdminMain
if		not main then return end -- wenn kein HD Admin, dann kein Overwrite
local		settings									=		main.settings

--		Warten bis initialisiert
if		not main.initialized then
		repeat	task.wait() until main.initialized
end


--		Simuliert die gleiche Funktion, die im Banland Modul benutzt wird, um zu prüfen, ob die Zeitangabe gültig ist oder geskippt wurde.
local		function	ZeitUmrechnen(Zeit : string | number | nil)
		if		not Zeit then return end

		if		type(Zeit) == "number" or tonumber(Zeit) then
				return	true
		end
		
		if		string.lower(Zeit :: string) == "infinite" or 
				string.lower(Zeit :: string) == "unendlich" or
				string.lower(Zeit :: string) == "permanent" or
				string.lower(Zeit :: string) == "lebenslänglich" or
				string.lower(Zeit :: string) == "für immer" or
				string.lower(Zeit :: string) == "ewig" or
				string.lower(Zeit :: string) == "perm" or
				string.lower(Zeit :: string) == "inf" then
				return	true, true
		end
		
		for		Wert, Einheit in string.gmatch(string.lower(Zeit), "(%d+)(%a)") do
				if		Wert == 0 or Wert == nil or not tonumber(Wert) then continue end
				return	true
		end
		
		return	false
end

local		function	HasBanRights(speaker, speakerData, speakerRank, plr, username)
		local		plrData							=		main.pd[plr]
		local		plrRank							=		math.huge
		
		if		plrData then
				plrRank							=		plrData.Rank
		else
				if		plr.UserId ~= main.ownerId then
						local success
						success, plrData = main.modules.PlayerData:GetData(speaker, 1, plr.UserId)
						plrRank = plrData and tonumber(plrData.Rank)
				end
		end
		
		local		errorStart							=		"Failed to ban "..username..": "

		if 		game.VIPServerOwnerId ~= 0 and (main.blacklistedVipServerCommands["permban"] or main.blacklistedVipServerCommands["pban"]) then 
				main.signals.Error:FireClient(speaker, {"Banland Module", errorStart.."This command is not enabled on VIP Servers."})
				return	false
					
		elseif	speakerData and speakerData.Rank < main.commandRanks.permban then
				main.signals.Error:FireClient(speaker, {"Banland Module", errorStart.."You don't have the permission to ban players on all servers."})
				return	false
					
		elseif	not plrRank then
				main.signals.Error:FireClient(speaker, {"Banland Module", errorStart.."Data not found."})
				return	false
					
		elseif	speakerRank <= plrRank then
				main.signals.Error:FireClient(speaker, {"Banland Module", errorStart.."You don't have the permission to use this command on "..username})
				return	false
		end
		
		return	true
end

local		UserIdCache									=		{}
local		function	GetUserId(NameOrUserId : string)
		if		not Settings.AllowOfflineCommands then 
				warn("Offline Commands are disabled!")
				return	"Target not found and offline commands are disabled!"
		end
		
		if		not NameOrUserId then
				return	"Invalid arguments. Expected a name or UserId"
		end
		
		local		UserId							=		tonumber(NameOrUserId)
		if		not UserId then
				if		UserIdCache[NameOrUserId] then
						return	UserIdCache[NameOrUserId]
				end
				
				local		Erfolg, Ergebnis				=		pcall(function()
						return	PLAYERS:GetUserIdFromNameAsync(NameOrUserId)
				end)
				
				if		not Erfolg then
						print("UserId not found for '"..NameOrUserId.."'")
						return	"UserId not found for '"..NameOrUserId.."'"
						
				else
						UserIdCache[NameOrUserId]		=		Ergebnis
						return	Ergebnis
				end
		end
		
		return	UserId
end

local		function	BanFunction(speaker, args)
		local 	plr = args[1]
				
		local		speakerData							=		main.pd[speaker]
		local		speakerRank							=		speakerData.Rank
		
		local		username							=		plr.Name
		
		local		Dauer								=		args[2]
		
		local		Reason							=		args[3]

		if		not HasBanRights(speaker, speakerData,speakerRank, plr, username) then return end
		
		SystemMessageModul:Send(speaker, "Trying to ban "..(if typeof(plr) == "Instance" then plr.Name else plr) .. "…")
		
		local		Result							=		""
		local		Valid, Permanent						=		ZeitUmrechnen(Dauer)
		if		not Valid then
				if		Reason then
						Reason					=		Dauer.." "..Reason
				else
						Reason					=		Dauer
				end
						Result					=		Banland:BanPlayer(plr, nil, Reason, nil, speaker.Name)
			
		else
				if		Permanent then
						Result					=		Banland:PermbanPlayer(plr, Reason, nil, speaker.Name)
				
				else
						Result					=		Banland:BanPlayer(plr, Dauer, Reason, nil, speaker.Name)
				end
		end
		
				SystemMessageModul:Send(speaker, Result)
				main.signals.Notice:FireClient(speaker, {"Banland Module", Result})
end

local		function	BanAltAccFunction(speaker, args)
		local 	plr = args[1]
				
		local		speakerData							=		main.pd[speaker]
		local		speakerRank							=		speakerData.Rank
		
		local		username							=		plr.Name
		
		local		Dauer								=		args[2]
		
		local		Reason							=		args[3]

		if		not HasBanRights(speaker, speakerData,speakerRank, plr, username) then return end
		
		SystemMessageModul:Send(speaker, "Trying to ban "..(if typeof(plr) == "Instance" then plr.Name else plr) .. "…")
		
		local		Result							=		""
		local		Valid, Permanent						=		ZeitUmrechnen(Dauer)
		if		not Valid then
				if		Reason then
						Reason					=		Dauer.." "..Reason
				else
						Reason					=		Dauer
				end
						Result					=		Banland:BanAltAccounts(plr, nil, Reason, nil, speaker.Name)
			
		else
				if		Permanent then
						Result					=		Banland:BanAltAccounts(plr, "2y", Reason, nil, speaker.Name)
				
				else
						Result					=		Banland:BanAltAccounts(plr, Dauer, Reason, nil, speaker.Name)
				end
		end
		
				SystemMessageModul:Send(speaker, Result)
				main.signals.Notice:FireClient(speaker, {"Banland Module", Result})
end

local		function	UnBanFunction(speaker, args)
		local 	plr								=		args[1]
		local		CaseId							=		args[2]
		
		local		TargetId							=		GetUserId(plr)
		
		if		not TargetId then
				SystemMessageModul:Send(speaker, "Target not found.")
				main.signals.Error:FireClient(speaker, {"Banland Module", "Target not found."})
				return
				
		elseif	type(TargetId) == "string" then
				SystemMessageModul:Send(speaker, TargetId)
				main.signals.Error:FireClient(speaker, {"Banland Module", TargetId})
				return
		end

		--		Keine Banrights checken. Wir verlassen uns auf HD Admins Rightsystem
		SystemMessageModul:Send(speaker, "Trying to unban "..(if typeof(plr) == "Instance" then plr.Name else plr) .. "…")
				
		if		not CaseId then
				local		Result					=		Banland:Unban(TargetId)
				SystemMessageModul:Send(speaker, Result)
				main.signals.Notice:FireClient(speaker, {"Banland Module", Result})
				return
		end
		
		CaseId									=		tonumber(CaseId)
		if		not CaseId then
				SystemMessageModul:Send(speaker, "Invalid arguments for 'OfflineUnban':\nThe CaseId has to be a number or nil for all cases.")
				main.signals.Error:FireClient(speaker, {"Banland Module", "The CaseId has to be a number or nil for all cases."})
				return
		end
		
		local		Result							=		Banland:Unban(plr, CaseId)
				SystemMessageModul:Send(speaker, Result)
				main.signals.Notice:FireClient(speaker, {"Banland Module", Result})	
end

local		function	ShowRecords(speaker, args)
		local 	plr								=		args[1]
		local		ActiveOrInactive						=		string.lower(args[2] or Settings.ShowRecordsDefault or "all")

		local		speakerData							=		main.pd[speaker]
		local		speakerRank							=		speakerData.Rank
				
		local		username							=		if typeof(plr) == "Instance" then plr.Name else plr
		
		local		errorStart = "Failed to show criminal records of "..username..": "
		
		SystemMessageModul:Send(speaker, "Loading the records of "..(if typeof(plr) == "Instance" then plr.Name else plr) .. "…")
		
		local		Records							=		Banland:GetRecords(plr)
		
		if		Records == nil or #Records <= 0 then
				SystemMessageModul:Send(speaker, "There are no criminal records for '".. username .. "'")
				main.signals.Notice:FireClient(speaker, {"Banland Module", "There are no criminal records for '".. username .. "'"})
				return
		end
		
		local		FinalString							=		"Criminal Records for "..username.. ":\n"
		local		NoRecords							=		true
		
		for		CaseId, Case in Records do
				if		ActiveOrInactive == "active" and not Case.Aktiv then continue end
				if		ActiveOrInactive == "inactive" and Case.Aktiv then continue end
				NoRecords							=		false
				local		String					=		"\nCaseId: "..CaseId
						
						String					..=		"\nActive: "..(if Case.Aktiv then "true" else "false")
				
						String					..=		"\nReason: " .. if Case.GrundExtern then Case.GrundExtern else "No reason given."
				
				if		Case.GrundIntern then
						String					..=		"\nInternal Reason: "..Case.GrundIntern
				end
				
				if		Case.DauerInSekunden then
						String					..=		"\nDuration: "..Case.DauerInSekunden.."s"
				else
						String					..=		"\nDuration: Permanent"
				end
						
				if		Case.ResponsibleMod then
						String					..=		"\nResponsible Mod: "..Case.ResponsibleMod
				end
				
						String					..=		"\n"
					
						FinalString					..=		String
		end
		
		if		NoRecords and ActiveOrInactive ~= "all" then 
				local		Gegenteil					=		if ActiveOrInactive == "active" then "inactive" else "active"
				SystemMessageModul:Send(speaker, "There are no ".. ActiveOrInactive .." criminal records for '".. username .. "'. But there are ".. Gegenteil .." cases.\nUse '".. Gegenteil .."' as second argument after their name to show them.")
				main.signals.Error:FireClient(speaker, {"Banland Module", "There are no ".. ActiveOrInactive .." criminal records for '".. username .. "'. But there are ".. Gegenteil .." cases.\nUse '".. Gegenteil .."' as second argument after their name to show them."})
				return
		end
		
		SystemMessageModul:Send(speaker, FinalString)
		main.signals.Notice:FireClient(speaker, {"Banland Module", "Criminal records got printed to your local chat."})
end

local		function	ShowAltAccountBanRecords(speaker, args)
		local 	plr								=		args[1]

		local		speakerData							=		main.pd[speaker]
		local		speakerRank							=		speakerData.Rank
				
		local		username							=		if typeof(plr) == "Instance" then plr.Name else plr
		
		local		errorStart = "Failed to show criminal records of "..username..": "
		
		SystemMessageModul:Send(speaker, "Loading the alt account ban records of "..(if typeof(plr) == "Instance" then plr.Name else plr) .. "…")
		
		local		Records							=		Banland:GetAltAccountBanRecords(plr)
		
		if		Records == nil or #Records <= 0 then
				SystemMessageModul:Send(speaker, "There are no alt account ban records for '".. username .. "'")
				main.signals.Notice:FireClient(speaker, {"Banland Module", "There are no alt account ban records for '".. username .. "'"})
				return
		end
		
		local		FinalString							=		"Alt account ban records for "..(if typeof(plr) == "Instance" then plr.Name else plr).. ":\n"
		
		for		i, Case in Records do
				local		String					=		"\nEntry "..i..":"
						
						String					..=		"\nType: " .. (if Case.Ban then "Ban" else "Unban")
				
						String					..=		"\nReason: " .. if Case.DisplayReason and Case.DisplayReason ~= "" then Case.DisplayReason else "No reason given."
				
				if		Case.PrivateReason and Case.PrivateReason ~= "" then
						String					..=		"\nInternal Reason: "..Case.PrivateReason
				end
				
				if		Case.StartTime then
						String					..=		"\nStart Time: "..Case.StartTime
				end
				
				if		Case.Duration and Case.Duration ~= -1 then
						String					..=		"\nDuration: "..Case.Duration.."s"
					
				elseif 	Case.Duration and Case.Duration == -1 then
						String					..=		"\nDuration: Permanent"
				end
				
						String					..=		"\n"
					
						FinalString					..=		String
		end
		
		SystemMessageModul:Send(speaker, FinalString)
		main.signals.Notice:FireClient(speaker, {"Banland Module", "Alt account ban records got printed to your local chat."})
end


--		Commands überschreiben
main.commands.ban										=		{
		Name										=		"ban",
		Aliases									=		{},
		Prefixes									=		{},
		Rank										=		4,
		RankLock									=		false,
		Loopable 									=		false,
		Tags										=		{},
		Description									=		"Bans an online player. [Overwritten by the Banland Module]",
		Contributors								=		{"Banland Module"},

		Args										=		{"player", "duration", "reason"},
		Function									=		BanFunction,
		
		--UnFunction									=		UnBanFunction,
}

main.commands.directban									=		{
		Name										=		"directBan",
		Aliases									=		{},
		Prefixes									=		{},
		Rank										=		4,
		RankLock									=		false,
		Loopable 									=		false,
		Tags										=		{},
		Description									=		"Bans an online player. Same as ban. [Overwritten by the Banland Module]",
		Contributors								=		{"Banland Module"},

		Args										=		{"player", "duration", "reason"},
		Function									=		BanFunction,

		--UnFunction									=		UnBanFunction,
}

main.commands.permban									=		{
		Name										=		"permBan",
		Aliases									=		{},
		Prefixes									=		{},
		Rank										=		5,
		RankLock									=		false,
		Loopable 									=		false,
		Tags										=		{},
		Description									=		"Permanently bans the player. They won't have to stay in a cell in banland forever but they can't come back unless they get unbanned. [Overwritten by the Banland Module]",
		Contributors								=		{"Banland Module"},

		Args										=		{"player", "reason"},
		Function									=		function(speaker, args)
				local 	plr						=		args[1]
				
				local		speakerData					=		main.pd[speaker]
				local		speakerRank					=		speakerData.Rank
						
				local		username					=		plr.Name
				local		Reason							=		args[2]

				local		plrData = main.pd[plr]
				local		plrRank = math.huge
				
				if		plrData then
						plrRank = plrData.Rank
				else
						if		plr.UserId ~= main.ownerId then
								local success
								success, plrData = main.modules.PlayerData:GetData(speaker, 1, plr.UserId)
								plrRank = plrData and tonumber(plrData.Rank)
						end
				end
				
				if		not HasBanRights(speaker, speakerData,speakerRank, plr, username) then return end
				
				SystemMessageModul:Send(speaker, "Trying to permban "..(if typeof(plr) == "Instance" then plr.Name else plr) .. "…")
				
				local		Result							=		Banland:PermbanPlayer(plr, Reason, nil, speaker.Name)
				
						SystemMessageModul:Send(speaker, Result)
						main.signals.Notice:FireClient(speaker, {"Banland Module", Result})
		end,
		
		--UnFunction									=		UnBanFunction,
}

main.commands.banland									=		{
		Name										=		"banland",
		Aliases									=		{},
		Prefixes									=		{},
		Rank										=		4,
		RankLock									=		false,
		Loopable 									=		false,
		Tags										=		{},
		Description									=		"Prints all criminal records for the given player in your local chat. [Created by the Banland Module]",
		Contributors								=		{"Banland Module"},

		Args										=		{"player", "ActiveOrInactive"},
		Function									=		ShowRecords,
		
		--UnFunction									=		function(speaker, args)
		--		main.signals.Error:FireClient(speaker, {"Banland Module", "Nah bro"})
		--end,
}

main.commands.timeban									=		nil


--		Commands ergänzen
main.commands.banaltaccounts								=		{
		Name										=		"banaltaccounts",
		Aliases									=		{"altaccountban", "banapiban"},
		Prefixes									=		{},
		Rank										=		4,
		RankLock									=		false,
		Loopable 									=		false,
		Tags										=		{},
		Description									=		"Bans an online player and all their alt accounts. [Created by the Banland Module]",
		Contributors								=		{"Banland Module"},

		Args										=		{"player", "duration", "reason"},
		Function									=		BanAltAccFunction,
}

main.commands.removerecord								=		{
		Name										=		"removeRecord",
		Aliases									=		{"remove"},
		Prefixes									=		{},
		Rank										=		4,
		RankLock									=		false,
		Loopable 									=		false,
		Tags										=		{},
		Description									=		"Removes the record in Banland for the given CaseId or 'all'. Get CaseId with the 'showRecords' command. [Created by the Banland Module]",
		Contributors								=		{"Banland Module"},

		Args										=		{"player", "caseIdOrAll", "delete"},
		Function									=		function(speaker, args)
				local 	plr						=		args[1]
				local		CaseId					=		tonumber(args[2] or "")
				local		Delete					=		args[3]
				
				local		speakerData					=		main.pd[speaker]
				local		speakerRank					=		speakerData.Rank
						
				local		reason					=		args[2]
				local		username					=		plr.Name

				local		plrData = main.pd[plr]
				local		plrRank = math.huge
				
				if		plrData then
						plrRank = plrData.Rank
				else
						if		plr.UserId ~= main.ownerId then
								local success
								success, plrData = main.modules.PlayerData:GetData(speaker, 1, plr.UserId)
								plrRank = plrData and tonumber(plrData.Rank)
						end
				end
				
				local		errorStart = "Failed to remove record: "

				if 		not plrRank then
						main.signals.Error:FireClient(speaker, {"Banland Module", errorStart.."Data not found."})
						return
							
				elseif	speakerRank <= plrRank then
						main.signals.Error:FireClient(speaker, {"Banland Module", errorStart.."You don't have the permission to use this command on "..username})
						return
				end
				
				if		Delete and string.lower(Delete) == "true" then
						Delete							=		true
					
				elseif	Delete and string.lower(Delete) == "false" then
						Delete							=		false
						
				else
						Delete							=		nil
				end
				
				local		Result
				if		not args[2] then
						main.signals.Error:FireClient(speaker, {"Banland Module", errorStart.."The command requires a CaseId or 'All'"})
						return
				
				elseif	string.lower(args[2]) == "all" then
						SystemMessageModul:Send(speaker, "Trying to remove all records from "..(if typeof(plr) == "Instance" then plr.Name else plr) .. "…")
						
						Result					=		Banland:RemoveRecord(plr, "all", Delete)
						
				elseif	not CaseId then
						main.signals.Error:FireClient(speaker, {"Banland Module", errorStart.."The CaseId has to be a number or 'All' for all cases."})
						return
				
				else
						SystemMessageModul:Send(speaker, "Trying to remove the record "..CaseId.." from "..(if typeof(plr) == "Instance" then plr.Name else plr) .. "…")
		
						Result					=		Banland:RemoveRecord(plr, CaseId, Delete)
				end
				
						SystemMessageModul:Send(speaker, Result)
						main.signals.Notice:FireClient(speaker, {"Banland Module", Result})
		end,
		
		--UnFunction									=		function(speaker, args)
		--		main.signals.Error:FireClient(speaker, {"There is no way to undo removing a record in banland. You'll have to ban the user again."})	
		--end,
}

main.commands.showrecords								=		{
		Name										=		"showRecords",
		Aliases									=		{"records"},
		Prefixes									=		{},
		Rank										=		4,
		RankLock									=		false,
		Loopable 									=		false,
		Tags										=		{},
		Description									=		"Prints all criminal records for the given player in your local chat. [Created by the Banland Module]",
		Contributors								=		{"Banland Module"},

		Args										=		{"playerarg", "ActiveOrInactive"},
		Function									=		ShowRecords,
		
		--UnFunction									=		function(speaker, args)
		--		main.signals.Error:FireClient(speaker, {"Banland Module", "Nah bro"})
		--end,
}

main.commands.showaltaccountbanrecords								=		{
		Name										=		"showaltaccountbanrecords",
		Aliases									=		{"AltAccountBanRecords"},
		Prefixes									=		{},
		Rank										=		4,
		RankLock									=		false,
		Loopable 									=		false,
		Tags										=		{},
		Description									=		"Prints all alt account ban records for the given player in your local chat. [Created by the Banland Module]",
		Contributors								=		{"Banland Module"},

		Args										=		{"playerarg"},
		Function									=		ShowAltAccountBanRecords,
		
		--UnFunction									=		function(speaker, args)
		--		main.signals.Error:FireClient(speaker, {"Banland Module", "Nah bro"})
		--end,
}

main.commands.unban									=		{
		Name										=		"unban",
		Aliases									=		{},
		Prefixes									=		{},
		Rank										=		4,
		RankLock									=		false,
		Loopable 									=		false,
		Tags										=		{},
		Description									=		"Deactivates the criminal record of the player for the given CaseId [Created by the Banland Module]",
		Contributors								=		{"Banland Module"},

		Args										=		{"playerarg", "caseId"},
		Function									=		UnBanFunction,
}

main.commands.markunbanned								=		{
		Name										=		"markUnbanned",
		Aliases									=		{"onlineUnban", "markAsUnbanned"},
		Prefixes									=		{},
		Rank										=		4,
		RankLock									=		false,
		Loopable 									=		false,
		Tags										=		{},
		Description									=		"Deactivates the ban for the given CaseId or for all cases, if no CaseId is given in banland for an online player. [Created by the Banland Module]",
		Contributors								=		{"Banland Module"},

		Args										=		{"player", "caseId"},
		Function									=		function(speaker, args)
				local 	plr						=		args[1]
				local		CaseId					=		tonumber(args[2] or "")
				
				local		speakerData					=		main.pd[speaker]
				local		speakerRank					=		speakerData.Rank
						
				local		reason					=		args[2]
				local		username					=		plr.Name
				
				local		errorStart = "Failed to mark as unbanned: "

				if 		game.VIPServerOwnerId ~= 0 and (main.blacklistedVipServerCommands["permban"] or main.blacklistedVipServerCommands["pban"]) then 
						main.signals.Error:FireClient(speaker, {"Banland Module", errorStart.."This command is not enabled on VIP Servers."})
						return
							
				elseif	speakerData and speakerData.Rank < main.commandRanks.permban then
						main.signals.Error:FireClient(speaker, {"Banland Module", errorStart.."You don't have the permission to ban players on all servers."})
						return
				end
				
				local		Result
				if		not args[2] then
						Result					=		Banland:MarkAsUnbannedInBanland(plr)
					
				elseif	not CaseId then
						main.signals.Error:FireClient(speaker, {"Banland Module", errorStart.."The CaseId has to be a number or nil for all cases."})
						return
				
				else
						Result					=		Banland:MarkAsUnbannedInBanland(plr, CaseId)
				end
				
						SystemMessageModul:Send(speaker, Result)
						main.signals.Notice:FireClient(speaker, {"Banland Module", Result})
		end,
		
		--UnFunction									=		function(speaker, args)
		--		SystemMessageModul:Send(speaker, "Nope")
		--end,
}

main.commands.visitbanland								=		{
		Name										=		"visitBanland",
		Aliases									=		{"visitBanland", "teleportToBanland"},
		Prefixes									=		{},
		Rank										=		4,
		RankLock									=		false,
		Loopable 									=		false,
		Tags										=		{},
		Description									=		"Teleports the targeted player to the banland without banning them. [Created by the Banland Module]",
		Contributors								=		{"Banland Module"},

		Args										=		{"player"},
		Function									=		function(speaker, args)
				local 	plr						=		args[1]
				
				local		speakerData					=		main.pd[speaker]
				local		speakerRank					=		speakerData.Rank
						
				local		username					=		plr.Name

				local		plrData = main.pd[plr]
				local		plrRank = math.huge
				
				if		plrData then
						plrRank = plrData.Rank
				else
						if		plr.UserId ~= main.ownerId then
								local success
								success, plrData = main.modules.PlayerData:GetData(speaker, 1, plr.UserId)
								plrRank = plrData and tonumber(plrData.Rank)
						end
				end
				
				local		errorStart = "Failed to mark as unbanned: "

				if 		game.VIPServerOwnerId ~= 0 and (main.blacklistedVipServerCommands["permban"] or main.blacklistedVipServerCommands["pban"]) then 
						main.signals.Error:FireClient(speaker, {"Banland Module", errorStart.."This command is not enabled on VIP Servers."})
						return
							
				elseif	speakerData and speakerData.Rank < main.commandRanks.permban then
						main.signals.Error:FireClient(speaker, {"Banland Module", errorStart.."You don't have the permission to ban players on all servers."})
						return
				end
				
				local		Result					=		Banland:VisitBanland(plr, speaker.Name)
						SystemMessageModul:Send(speaker, Result)
						main.signals.Notice:FireClient(speaker, {"Banland Module", Result})
		end,
		
		--UnFunction									=		function(speaker, args)
		--		SystemMessageModul:Send(speaker, "Nope")
		--end,
}

--		Command Infos überschreiben
for		i, CommandInfo in main.commandInfo do
		if		CommandInfo.Name == "ban"then
				main.commandInfo[i]					=		{
						Aliases					=		{},
						Args						=		{"player", "duration", "reason"},
						Contributors				=		{"Banland Module"},
						Description					=		"Bans an online player. Same as ban. [Overwritten by the Banland Module]",
						Loopable					=		false,
						Name						=		"ban",
						Prefixes					=		{settings.Prefix},
						Rank						=		4,
						RankName					=		settings.Ranks[4][2],
						Tags						=		{},
						--UnFunction					=		"unBan"
				}
			
		elseif	CommandInfo.Name == "directBan"then
				main.commandInfo[i]					=		{
						Aliases					=		{},
						Args						=		{"player", "duration", "reason"},
						Contributors				=		{"Banland Module"},
						Description					=		"Bans the player. [Overwritten by the Banland Module]",
						Loopable					=		false,
						Name						=		"directBan",
						Prefixes					=		{settings.Prefix},
						Rank						=		4,
						RankName					=		settings.Ranks[4][2],
						Tags						=		{},
						--UnFunction					=		"unDirectBan"
				}
				
		elseif	CommandInfo.Name == "permBan"then
				main.commandInfo[i]					=		{
						Aliases					=		{},
						Args						=		{"player", "reason"},
						Contributors				=		{"Banland Module"},
						Description					=		"Bans a player for 1 year. Thats basically permanent because they have to stay in banland for a whole year. [Overwritten by the Banland Module]",
						Loopable					=		false,
						Name						=		"permBan",
						Prefixes					=		{settings.Prefix},
						Rank						=		5,
						RankName					=		settings.Ranks[5][2],
						Tags						=		{},
						--UnFunction					=		"unPermBan"
				}
				
		elseif	CommandInfo.Name == "timeBan"then
				table.remove(main.commandInfo, i)
			
		elseif	CommandInfo.Name == "banland" then
				main.commandInfo[i]					=		{
						Aliases					=		{},
						Args						=		{"player", "ActiveOrInactive"},
						Contributors				=		{"Banland Module"},
						Description					=		"Prints all criminal records for the given player in your local chat. [Overwritten by the Banland Module]",
						Loopable					=		false,
						Name						=		"banland",
						Prefixes					=		{settings.Prefix},
						Rank						=		4,
						RankName					=		settings.Ranks[4][2],
						Tags						=		{},
				}
				
		end
end

--		Command Infos ergänzen
table.insert(main.commandInfo, {
		Aliases									=		{"altaccountban", "banapiban"},
		Args										=		{"player", "duration", "reason"},
		Contributors								=		{"Banland Module"},
		Description									=		"Bans an online player and all their alt accounts. [Created by the Banland Module]",
		Loopable									=		false,
		Name										=		"banAltAccounts",
		Prefixes									=		{settings.Prefix},
		Rank										=		4,
		RankName									=		settings.Ranks[4][2],
		Tags										=		{},
})
table.insert(main.commandInfo, {
		Aliases									=		{"remove"},
		Args										=		{"player", "caseIdOrAll", "delete"},
		Contributors								=		{"Banland Module"},
		Description									=		"Removes the record in Banland for the given CaseId or 'all'. Get CaseId with the 'showRecords' command. [Created by the Banland Module]",
		Loopable									=		false,
		Name										=		"removeRecord",
		Prefixes									=		{settings.Prefix},
		Rank										=		4,
		RankName									=		settings.Ranks[4][2],
		Tags										=		{},
})
table.insert(main.commandInfo, {
		Aliases									=		{"records"},
		Args										=		{"playerArg", "ActiveOrInactive"},
		Contributors								=		{"Banland Module"},
		Description									=		"Prints all criminal records for the given player in your local chat. [Created by the Banland Module]",
		Loopable									=		false,
		Name										=		"showRecords",
		Prefixes									=		{settings.Prefix},
		Rank										=		4,
		RankName									=		settings.Ranks[4][2],
		Tags										=		{},
})
table.insert(main.commandInfo, {
		Aliases									=		{"AltAccountBanRecords"},
		Args										=		{"playerArg"},
		Contributors								=		{"Banland Module"},
		Description									=		"Prints all criminal records for the given player in your local chat. [Created by the Banland Module]",
		Loopable									=		false,
		Name										=		"showAltAccountBanRecords",
		Prefixes									=		{settings.Prefix},
		Rank										=		4,
		RankName									=		settings.Ranks[4][2],
		Tags										=		{},
})
table.insert(main.commandInfo, {
		Aliases									=		{},
		Args										=		{"playerarg", "caseId"},
		Contributors								=		{"Banland Module"},
		Description									=		"Deactivates the criminal record of the player for the given CaseId [Created by the Banland Module]",
		Loopable									=		false,
		Name										=		"unban",
		Prefixes									=		{settings.Prefix},
		Rank										=		4,
		RankName									=		settings.Ranks[4][2],
		Tags										=		{},
})
table.insert(main.commandInfo, {
		Aliases									=		{"onlineUnban", "markAsUnbanned"},
		Args										=		{"player", "caseId"},
		Contributors								=		{"Banland Module"},
		Description									=		"Deactivates the ban for the given CaseId or for all cases, if no CaseId is given in banland for an online player. [Created by the Banland Module]",
		Loopable									=		false,
		Name										=		"markUnbanned",
		Prefixes									=		{settings.Prefix},
		Rank										=		4,
		RankName									=		settings.Ranks[4][2],
		Tags										=		{},
})
table.insert(main.commandInfo, {
		Aliases									=		{"visitBanland", "teleportToBanland"},
		Args										=		{"player"},
		Contributors								=		{"Banland Module"},
		Description									=		"Teleports the targeted player to the banland without banning them. [Created by the Banland Module]",
		Loopable									=		false,
		Name										=		"visitBanland",
		Prefixes									=		{settings.Prefix},
		Rank										=		4,
		RankName									=		settings.Ranks[4][2],
		Tags										=		{},
})