--		Registriert Commands

--		If Testumgebung, dann nicht
if		script.Parent.Parent.Parent.Name == "Current" or script.Parent.Parent.Parent.Name == "Archiv" then return end

local		TCS										=		game:GetService("TextChatService")
if		TCS.ChatVersion ~= Enum.ChatVersion.TextChatService then
		print("This experience does not use the TextChatService.\nChat commands will not get registered.")
		return
end

local		Banland									=		require(script.Parent.Parent)
local		Settings									=		require(script.Parent.Parent.Settings)
local		SystemMessageModul							=		require(script.Parent.SystemMessageModul)
local		RegisterCommandsModul							=		require(script.Parent.RegisterCommandsModul)


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

local		function	TupleToString(...)
		if		not ... then
				return 	nil
		end
		
		local		String							=		""
		
		for		_, Wort in {...} do
				String							..=		Wort .. " "
		end
		
		return	string.sub(String, 1, String:len(String) -1)
end


--		Commands Registrieren
RegisterCommandsModul:RegisterCommandOnTarget("Ban", "Ban", "Ban", function(Spieler, Target, Dauer, ...)
		SystemMessageModul:Send(Spieler, "Trying to ban "..(if typeof(Target) == "Instance" then Target.Name else Target) .. "…")
		
		local		Reason							=		TupleToString(...)
		local		Valid, Permanent						=		ZeitUmrechnen(Dauer)
		if		not Valid then
				if		Reason then
						Reason					=		Dauer.." "..Reason
				else
						Reason					=		Dauer
				end
				SystemMessageModul:Send(Spieler, Banland:BanPlayer(Target, nil, Reason, nil, Spieler.Name))
			
		else
				if		Permanent then
						SystemMessageModul:Send(Spieler, Banland:PermbanPlayer(Target, Reason, nil, Spieler.Name))
				
				else
						SystemMessageModul:Send(Spieler, Banland:BanPlayer(Target, Dauer, Reason, nil, Spieler.Name))
				end
		end
end)
RegisterCommandsModul:RegisterCommandOnTarget("BanAltAccounts", "BanAltAccounts", "AltAccountBan", function(Spieler, Target, Dauer, ...)
		SystemMessageModul:Send(Spieler, "Trying to ban "..(if typeof(Target) == "Instance" then Target.Name else Target) .. " and all their alt accounts…")
		
		local		Reason							=		TupleToString(...)
		local		Valid, Permanent						=		ZeitUmrechnen(Dauer)
		if		not Valid then
				if		Reason then
						Reason					=		Dauer.." "..Reason
				else
						Reason					=		Dauer
				end
				SystemMessageModul:Send(Spieler, Banland:BanAltAccounts(Target, nil, Reason, nil, Spieler.Name))
			
		else
				if		Permanent then
						SystemMessageModul:Send(Spieler, Banland:BanAltAccounts(Target, "2y", Reason, nil, Spieler.Name))
				
				else
						SystemMessageModul:Send(Spieler, Banland:BanAltAccounts(Target, Dauer, Reason, nil, Spieler.Name))
				end
		end
end)
RegisterCommandsModul:RegisterCommandOnTarget("PermBan", "PermBan", "PermBan", function(Spieler, Target, ...)
		SystemMessageModul:Send(Spieler, "Trying to permanently ban "..(if typeof(Target) == "Instance" then Target.Name else Target) .. "…")
		
		SystemMessageModul:Send(Spieler, Banland:PermbanPlayer(Target, TupleToString(...), nil, Spieler.Name))
end)

RegisterCommandsModul:RegisterCommandOnTarget("KickPlayer", "Kick", "KickPlayer", function(Spieler, Target, ...)
		if		Target.UserId == Banland.Owner then 
				SystemMessageModul:Send(Spieler, "The owner can't get kicked.")
				return
		end
		
		Target:Kick(TupleToString(...) or "You got kicked from the server.")
		SystemMessageModul:Send(Spieler, Target.Name.." got kicked from the server.")
end)

RegisterCommandsModul:RegisterCommandOnTarget("VisitBanland", "VisitBanland", "TeleportToBanland", function(Spieler, Target)
		SystemMessageModul:Send(Spieler, Banland:VisitBanland(Target, Spieler.Name))
end, 0)

RegisterCommandsModul:RegisterCommandOnTarget("RemoveRecord", "RemoveRecord", "Remove", function(Spieler, Target, CaseId, Delete)
		if		not CaseId then
				SystemMessageModul:Send(Spieler, "Invalid arguments for 'RemoveRecord':\nThe command requires a CaseId or 'All'")
				return
		end
		
		if		Delete and string.lower(Delete) == "true" then
				Delete							=		true
			
		elseif	Delete and string.lower(Delete) == "false" then
				Delete							=		false
				
		else
				Delete							=		nil
		end
		
		
		--		Offline Command
		if		type(Target) == "string" or type(Target) == "number" then
				--		All
				if		string.lower(CaseId) == "all" then
						SystemMessageModul:Send(Spieler, "Trying to remove all records from "..(if typeof(Target) == "Instance" then Target.Name else Target) .. "…")
						
						SystemMessageModul:Send(Spieler, Banland:OfflineRemoveRecord(Target, "all", Delete))
						return
				end
				
				SystemMessageModul:Send(Spieler, "Trying to remove the record "..CaseId.." from "..(if typeof(Target) == "Instance" then Target.Name else Target) .. "…")
		
				
				--		Mit CaseId
				CaseId									=		tonumber(CaseId)
				if		not CaseId then
						SystemMessageModul:Send(Spieler, "Invalid arguments for 'OfflineRemoveRecord':\nThe CaseId has to be a number or 'All' for all cases.")
						return
				end
				SystemMessageModul:Send(Spieler, Banland:OfflineRemoveRecord(Target, CaseId, Delete))
				return
		end
		
		--		All
		if		string.lower(CaseId) == "all" then
				SystemMessageModul:Send(Spieler, "Trying to remove all records from "..(if typeof(Target) == "Instance" then Target.Name else Target) .. "…")
		
				SystemMessageModul:Send(Spieler, Banland:RemoveRecord(Target, "all", Delete))
				return
		end
		
		--		Mit CaseId
		CaseId									=		tonumber(CaseId)
		if		not CaseId then
				SystemMessageModul:Send(Spieler, "Invalid arguments for 'RemoveRecord':\nThe CaseId has to be a number or 'All' for all cases.")
				return
		end
		SystemMessageModul:Send(Spieler, "Trying to remove the record "..CaseId.." from "..(if typeof(Target) == "Instance" then Target.Name else Target) .. "…")
		
		
		SystemMessageModul:Send(Spieler, Banland:RemoveRecord(Target, CaseId, Delete))
end, nil, Settings.AllowOfflineCommands)

RegisterCommandsModul:RegisterCommandOnTarget("OnlineUnban", "MarkAsUnbanned", "OnlineUnban", function(Spieler, Target, CaseId)
		if		not CaseId then
				SystemMessageModul:Send(Spieler, Banland:MarkAsUnbannedInBanland(Target))
				return
		end
		
		CaseId									=		tonumber(CaseId)
		if		not CaseId then
				SystemMessageModul:Send(Spieler, "Invalid arguments for 'OnlineUnban':\nThe CaseId has to be a number or nil for all cases.")
				return
		end
		
		SystemMessageModul:Send(Spieler, Banland:MarkAsUnbannedInBanland(Target, CaseId))
end, - 99999)

RegisterCommandsModul:RegisterCommandOnTarget("ShowRecords", "Records", "ShowRecords", function(Spieler, Target, ActiveOrInactive)
		SystemMessageModul:Send(Spieler, "Loading the records of "..(if typeof(Target) == "Instance" then Target.Name else Target) .. "…")
		
		ActiveOrInactive								=		string.lower(ActiveOrInactive or Settings.ShowRecordsDefault or "all")
														
		local		Records							=		Banland:GetRecords(Target)
		
		if		Records == nil or #Records <= 0 then
				SystemMessageModul:Send(Spieler, "There are no criminal records for '".. (if typeof(Target) == "Instance" then Target.Name else Target) .. "'")
				return
		end
		
		local		FinalString							=		"Criminal Records for "..(if typeof(Target) == "Instance" then Target.Name else Target).. ":\n"
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
				SystemMessageModul:Send(Spieler,"There are no ".. ActiveOrInactive .." criminal records for '".. (if typeof(Target) == "Instance" then Target.Name else Target) .. "'. But there are ".. Gegenteil .." cases.\nUse '".. Gegenteil .."' as second argument after their name to show them.")
				return
		end
		
		SystemMessageModul:Send(Spieler, FinalString)
end, - 99999, Settings.AllowOfflineCommands)

RegisterCommandsModul:RegisterCommandOnTarget("ShowAltAccountBanRecords", "ShowAltAccountBanRecords", "AltAccountBanRecords", function(Spieler, Target)
		SystemMessageModul:Send(Spieler, "Loading the alt account ban records of "..(if typeof(Target) == "Instance" then Target.Name else Target) .. "…")
														
		local		Records							=		Banland:GetAltAccountBanRecords(Target)
		
		if		Records == nil or #Records <= 0 then
				SystemMessageModul:Send(Spieler, "There are no alt account ban records for '".. (if typeof(Target) == "Instance" then Target.Name else Target) .. "'")
				return
		end
		
		local		FinalString							=		"Alt account ban records for "..(if typeof(Target) == "Instance" then Target.Name else Target).. ":\n"
		
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
		
		SystemMessageModul:Send(Spieler, FinalString)
end, - 99999, Settings.AllowOfflineCommands)

RegisterCommandsModul:RegisterCommandOnTarget("WipePlayerData", "WipeBanlandData", "WipeBanlandData", function(Spieler, Target)
		if		Target == Spieler then
				SystemMessageModul:Send(Spieler, "You can't wipe your own playerdata.")
				return
		end
		
		SystemMessageModul:Send(Spieler, "Trying to wipe all playerdata for "..(if typeof(Target) == "Instance" then Target.Name else Target) .. "…")
		
		local		Result							=		Banland:WipePlayerData(Target)
		
		if		Result == true then
				SystemMessageModul:Send(Spieler, "Banland playerdata was successfully wiped for "..(if typeof(Target) == "Instance" then Target.Name else Target))
		
		else
				SystemMessageModul:Send(Spieler, "Error: Was not able to wipe the playerdata for "..(if typeof(Target) == "Instance" then Target.Name else Target))
		end
		
end, - 99999, Settings.AllowOfflineCommands)

--		Offline Commands
if		not Settings.AllowOfflineCommands then return end

RegisterCommandsModul:RegisterOfflineCommand("OfflineUnban", "Unban", "OfflineUnban", function(Spieler, TargetId, CaseId, DeleteRecord)
		SystemMessageModul:Send(Spieler, "Trying to unban ".. TargetId .. "…")
		
		if		DeleteRecord and string.lower(DeleteRecord) == "true" then
				DeleteRecord						=		true
			
		elseif	DeleteRecord and string.lower(DeleteRecord) == "false" then
				DeleteRecord						=		false
				
		else
				DeleteRecord						=		nil
		end
		
		if		not CaseId or CaseId == "all" then
				SystemMessageModul:Send(Spieler, Banland:Unban(TargetId, nil, DeleteRecord))
				return
		end
		
		CaseId									=		tonumber(CaseId)
		if		not CaseId then
				SystemMessageModul:Send(Spieler, "Invalid arguments for 'OfflineUnban':\nThe CaseId has to be a number or nil for all cases.")
				return
		end
		SystemMessageModul:Send(Spieler, Banland:Unban(TargetId, CaseId, DeleteRecord))
end, - 99999)

RegisterCommandsModul:RegisterOfflineCommand("OfflineUnbanAltAccounts", "UnbanAltAccounts", "AltAccountUnban", function(Spieler, TargetId)
		SystemMessageModul:Send(Spieler, "Trying to unban ".. TargetId .. " and their alt accounts…")
		
		SystemMessageModul:Send(Spieler, Banland:UnbanAltAccounts(TargetId))
end, - 99999)

RegisterCommandsModul:RegisterOfflineCommand("OfflineBan", "OfflineBan", "BanOffline", function(Spieler, TargetId, Dauer, ...)		
		SystemMessageModul:Send(Spieler, "Trying to offlineban ".. TargetId .. "…")
		
		local		Reason							=		TupleToString(...)		
		local		Valid, Permanent						=		ZeitUmrechnen(Dauer)
		if		not Valid then
				if		Reason then
						Reason					=		Dauer.." "..Reason
				else
						Reason					=		Dauer
				end
				SystemMessageModul:Send(Spieler, Banland:OfflineBanPlayer(TargetId, nil, Reason, nil, Spieler.Name))
			
		else
				if		Permanent then
						SystemMessageModul:Send(Spieler, Banland:OfflinePermbanPlayer(TargetId, Reason, nil, Spieler.Name))
				
				else
						SystemMessageModul:Send(Spieler, Banland:OfflineBanPlayer(TargetId, Dauer, Reason, nil, Spieler.Name))
				end
		end
		
end)

RegisterCommandsModul:RegisterOfflineCommand("OfflineBanAltAccounts", "OfflineBanAltAccounts", "AltAccountOfflineBan", function(Spieler, TargetId, Dauer, ...)		
		SystemMessageModul:Send(Spieler, "Trying to offlineban ".. TargetId .. "…")
		
		local		Reason							=		TupleToString(...)		
		local		Valid, Permanent						=		ZeitUmrechnen(Dauer)
		if		not Valid then
				if		Reason then
						Reason					=		Dauer.." "..Reason
				else
						Reason					=		Dauer
				end
				SystemMessageModul:Send(Spieler, Banland:OfflineBanAltAccounts(TargetId, nil, Reason, nil, Spieler.Name))
			
		else
				if		Permanent then
						SystemMessageModul:Send(Spieler, Banland:OfflineBanAltAccounts(TargetId, "2y", Reason, nil, Spieler.Name))
				
				else
						SystemMessageModul:Send(Spieler, Banland:OfflineBanAltAccounts(TargetId, Dauer, Reason, nil, Spieler.Name))
				end
		end
		
end)

RegisterCommandsModul:RegisterOfflineCommand("OfflinePermBan", "OfflinePermBan", "PermbanOffline", function(Spieler, TargetId, ...)		
		SystemMessageModul:Send(Spieler, "Trying to permanently ban ".. TargetId .. "…")
		
		SystemMessageModul:Send(Spieler, Banland:OfflinePermbanPlayer(TargetId, TupleToString(...), nil, Spieler.Name))
end)