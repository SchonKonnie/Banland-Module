local		TELEPORT									=		game:GetService("TeleportService")
local		PLAYERS									=		game:GetService("Players")
local		MESSAGE									=		game:GetService("MessagingService")
local		GROUP										=		game:GetService("GroupService")
local		MPS										=		game:GetService("MarketplaceService")
local		RUN										=		game:GetService("RunService")

type		BanlandModule								=		{	--	for auto-completition. Please lmk if there is another way
				Owner								:		number,
				BanPlayer : (BanlandModule, Player : Player, Duration : string | number | nil, ReasonExternal : string?, ReasonInternal: string?, ResponsibleMod : string?, Buyouts : boolean | number | nil, IncrementFactor : number?) -> string,
				BanAltAccounts : (BanlandModule, Player : Player, Duration : string | number | nil, ReasonExternal : string?, ReasonInternal: string?, ResponsibleMod : string?) -> string,
				OfflineBanPlayer : (BanlandModule, PlayerNameOrId : string | number, Duration : string | number | nil, ReasonExternal : string?, ReasonInternal: string?, ResponsibleMod : string?, Buyouts : boolean | number | nil, IncrementFactor : number?) -> string,
				OfflineBanAltAccounts : (BanlandModule, PlayerNameOrId : string | number, Duration : string | number | nil, ReasonExternal : string?, ReasonInternal: string?, ResponsibleMod : string?) -> string,
				PermbanPlayer : (BanlandModule, Player : Player, ReasonExternal : string?, ReasonInternal: string?, ResponsibleMod : string?) -> string,
				OfflinePermbanPlayer : (BanlandModule, PlayerNameOrId : string | number, ReasonExternal : string?, ReasonInternal: string?, ResponsibleMod : string?) -> string,
				VisitBanland : (BanlandModule, Player : Player, ResponsibleMod : string?) -> string,
				RemoveRecord : (BanlandModule, Player : Player, CaseId : number | "all", DeleteRecord : boolean?) -> string,
				EditActiveRecord : (BanlandModule, PlayerNameOrId : string | number, Duration : string | number | nil, ReasonExternal : string?, ReasonInternal: string?, ResponsibleMod : string?, Buyouts : boolean | number | nil, IncrementFactor : number?) -> string,
				OfflineRemoveRecord : (BanlandModule, PlayerNameOrId : string | number, CaseId : number | "all", DeleteRecord : boolean?) -> string,
				MarkAsUnbannedInBanland : (BanlandModule, Player : Player, CaseId : number?) -> string,
				Unban : (BanlandModule, PlayerNameOrId : string | number, CaseId : number?, DeleteRecord : boolean?) -> string,
				UnbanAltAccounts : (BanlandModule, PlayerNameOrId : string | number) -> string,
				GetRecords : (BanlandModule, PlayerOrNameOrId : Player | string | number) -> string,
				GetAltAccountBanRecords : (BanlandModule, PlayerOrNameOrId : Player | string | number) -> string,
				WipePlayerData : (BanlandModule, PlayerOrNameOrId : Player | string | number) -> string,
		}
if		not RUN:IsRunning() then
		warn("Can't require this module outside of a playtest because it would destroy its own functionality :(")
		return	{} :: BanlandModule

elseif	RUN:IsClient() then
		warn("Woah! This module shouldnt be in reach of clients!")
		return	{} :: BanlandModule
end

local		Settings									=		require(script.Settings)
local		SystemMessageModul							=		require(script.Stuff.SystemMessageModul)
local		GlobalBlacklist								=		{}

--		Imports an external Module  containing a global blacklist of users who have been banned for exploiting, harassment, etc.
if		Settings.UseGlobalBlacklist == true then
		local		Erfolg, Result						=		pcall(function()
				return	require(16704678709) -- a scary external module 😱 which only gets required, when the user decides to have the "UseGlobalBlacklist" set to true
		end)
		if		not Erfolg then
				Settings.UseGlobalBlacklist				=		false
		
		else
				GlobalBlacklist						=		Result
		end
end

local		TeleportScreen								=		script.Stuff:FindFirstChild("TeleportScreen")
local		BannedIndicatorGUI							=		script.Stuff:FindFirstChild("BannedIndicator")
if		not TeleportScreen then
		print("TeleportScreen not found :c")
end
if		not BannedIndicatorGUI then
		print("BannedIndicator not found D:")
end

local		MaxActiveRecords								=		1	--	Please do not change this Setting. Its unfair to the player if they can't see, if they're banned multiple times.
local		MaxScheduledActions							=		10	--	This limit is nessesary because for every action the player will get teleported on join and it is be a terrible experience to be stuck in an infinite teleport loop.

local		RecordsCache								=		{}
local		Debounce									=		{}
local		FailedCache									=		{}

local		Banland									=		{}
		Banland.Settings								=		Settings
		Banland.Owner								=		0
		Banland.IsStudio								=		RUN:IsStudio()

local		function	ZeitUmrechnen(Zeit : string | number | nil)
		assert(Zeit == nil or type(Zeit) == "string" or type(Zeit) == "number", "Duration must be a number in seconds, a string or nil.")
		
		Zeit										=		Zeit or Settings.DefaultBanDuration
		if		type(Zeit) == "number" then
				return	math.clamp(Zeit, 10, 1576800000)
		elseif	tonumber(Zeit) then
				return	math.clamp(tonumber(Zeit) :: number, 10, 1576800000)
		end
		
		if		string.lower(Zeit :: string) == "infinite" or 
				string.lower(Zeit :: string) == "unendlich" or
				string.lower(Zeit :: string) == "permanent" or
				string.lower(Zeit :: string) == "lebenslänglich" or
				string.lower(Zeit :: string) == "für immer" or
				string.lower(Zeit :: string) == "ewig" or
				string.lower(Zeit :: string) == "perm" or
				string.lower(Zeit :: string) == "inf" then
				
				return	ZeitUmrechnen("1y")
		end
		
		local		ZeitString							=		string.lower(Zeit :: string)
		local		ZeitInSekunden						=		0
		local		Einheiten							=		{
				["s"] = 1, -- Sekunden
				["m"] = 60, -- Minuten
				["h"] = 3600, -- Stunden
				["d"] = 86400, -- Tage
				["t"] = 86400, -- Tage
				["w"] = 604800, -- Wochen (7d)
				["o"] = 2592000, -- Monate (30d)
				["y"] = 31536000, -- Jahre (365d)
				["j"] = 31536000, -- Jahre (365d)
		}
		
		for		Wert, Einheit in string.gmatch(ZeitString, "(%d+)(%a)") do
				ZeitInSekunden						+=		Wert * (Einheiten[Einheit] or 1)
		end
		return	math.clamp(ZeitInSekunden, 10, 1576800000)
end

--		Sucht nach dem Owner des spiels und speichert sich die UserId
local		function	GetOwner()
		local		Erfolg, ProductInfo					=		pcall(function()
				return	MPS:GetProductInfo(game.PlaceId, Enum.InfoType.Asset)
		end)
		if		not Erfolg then
				task.wait(60)
				return	GetOwner()
		end
		
		if		ProductInfo.Creator.CreatorType == "Group" then
				local		Erfolg, GroupInfo				=		pcall(function()
						return	GROUP:GetGroupInfoAsync(ProductInfo.Creator.CreatorTargetId)
				end)
				if		not Erfolg then
						task.wait(60)
						return	GetOwner()
				end
						Banland.Owner				=		GroupInfo.Owner.Id
			
		else
				Banland.Owner						=		ProductInfo.Creator.CreatorTargetId
		end
end

local		function	FreezeCharacter(Character : Model?, Info : string?)
		if		not Character then return end
		
		local		Prim								=		Character.PrimaryPart
				Prim.Anchored						=		true
				
		local		Hum								=		Character:FindFirstChildOfClass("Humanoid") or Character:WaitForChild("Humanoid") :: Humanoid
				Hum.WalkSpeed						=		0
				Hum.UseJumpPower						=		0
				Hum.JumpPower						=		0
				Hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
			
		if		not BannedIndicatorGUI then return end
		local		BannedIndicator						=		BannedIndicatorGUI:Clone()
				BannedIndicator.PlayerToHideFrom			=		PLAYERS:GetPlayerFromCharacter(Character)
		local		Label								=		BannedIndicator.Frame:FindFirstChildOfClass("TextLabel")
				Label.Text							=		Info or Label.Text
				BannedIndicator.Parent					=		Character
end
local		function	PrepareTeleport(Spieler, Info : string?)
		Spieler.CharacterAdded:Connect(FreezeCharacter)
		task.spawn(FreezeCharacter, Spieler.Character, Info)
		
		if		not TeleportScreen or not Spieler:FindFirstChild("PlayerGui") then return end
		local		GUI								=		TeleportScreen:Clone()
				GUI.Parent							=		Spieler.PlayerGui
end
local		function	Teleport(Spieler : Player, TPOptions)
		if		not Spieler or not Spieler:IsDescendantOf(PLAYERS) or not TPOptions then return end
		
		if		Banland.IsStudio then
				warn("Teleports are not possible in Studio. Player will get kicked in 5 seconds.")
				task.wait(5)
				Spieler:Kick()
				return	"No teleports possible in Roblox Studio"
		end
		
		local		Erfolg, Ergebnis						=		pcall(function()
				return	TELEPORT:TeleportAsync(Settings.BanlandPlaceId, {Spieler}, TPOptions)
		end)

		if		Erfolg and typeof(Ergebnis) == "Instance" and Ergebnis:IsA("TeleportAsyncResult") then
				return	true
		end
		
		print("The teleport failed.", Ergebnis)
		return	"The teleport failed. " .. if type(Ergebnis) == "string" then Ergebnis else ""
end

local		function	HandleFailedTeleport(Spieler : Player, TeleportResult : Enum.TeleportResult, ErrorMessage: string, PlaceId: number, TeleportOptions : TeleportOptions)
		if		PlaceId ~= Settings.BanlandPlaceId then return end
		
		if		ErrorMessage and string.match(ErrorMessage, "third party with teleport protections") then
				warn("You need to enable third party teleports for this module to work!")
				Spieler:Kick("Teleport failed due to wrong configuration.\n Please contact an admin.")
				return
		else
				print("Teleport Failed:", ErrorMessage)
		end
		
		if		not FailedCache[Spieler] then
				FailedCache[Spieler]					=		0
		end
		
		FailedCache[Spieler]							+=		1
		if		FailedCache[Spieler] >= Settings.TpTriesUntilKick then
				Spieler:Kick("Teleport failed.\n Try again later or contact an admin.")
				return
		end
		
		print("Teleport to Banland failed. Attempts remaining:", Settings.TpTriesUntilKick - FailedCache[Spieler])
		
		if		TeleportResult == Enum.TeleportResult.Flooded then
				task.wait(math.random(20, 40))
			
		elseif	TeleportResult == Enum.TeleportResult.Unauthorized then
				Spieler:Kick("Teleport failed. ".. (ErrorMessage or ""))
		
		elseif	TeleportResult == Enum.TeleportResult.GameNotFound then
				Spieler:Kick("Teleport failed. ".. (ErrorMessage or ""))
			
		elseif	TeleportResult == Enum.TeleportResult.IsTeleporting then
				print("Player is currently teleporting. ".. (ErrorMessage or ""))
				return
		else
				task.wait(5)
		end
		
		Teleport(Spieler, TeleportOptions)
end

local		function	AbInsBanland(Spieler : Player, BanInfo)
		assert(Spieler and typeof(Spieler) == "Instance" and Spieler:IsA("Player"), "Thats not a valid player object.")
		
		if		BanInfo.Type == "Blacklist" then
				--		Fallunterscheidung, damit Blacklisteinträge auch funktionieren.	
		else		
				assert(BanInfo.IncrementFactor == nil or type(BanInfo.IncrementFactor) == "number", "The increment factor has to be a number or nil.")
				if		BanInfo.IncrementFactor then
						BanInfo.IncrementFactor			=		math.clamp(BanInfo.IncrementFactor, 0, 10)
				end
				
				assert(type(BanInfo.DauerInSekunden) == "number", "The duration has to be a number.")
		end
		
		assert(BanInfo.GrundExtern == nil or type(BanInfo.GrundExtern) == "string", "The external reason has to be a string or nil.")
		if		BanInfo.GrundExtern and string.len(BanInfo.GrundExtern) > 100 then
				BanInfo.GrundExtern					=		string.sub(BanInfo.GrundExtern, 1, 100)
		end
		
		assert(BanInfo.GrundIntern == nil or type(BanInfo.GrundIntern) == "string", "The internal reason has to be a string or nil.")
		if		BanInfo.GrundIntern and string.len(BanInfo.GrundIntern) > 100 then
				BanInfo.GrundIntern					=		string.sub(BanInfo.GrundIntern, 1, 100)
		end
		
		assert(BanInfo.Buyouts == nil or type(BanInfo.Buyouts) == "boolean" or typeof(BanInfo.Buyouts) == "number", "Buyouts has to be a boolean, a GamepassId or nil.")
	
		assert(BanInfo.ResponsibleMod == nil or type(BanInfo.ResponsibleMod) == "string", "The responsible mod has to be a string or nil.")
		if		BanInfo.ResponsibleMod and string.len(BanInfo.ResponsibleMod) > 50 then
				BanInfo.ResponsibleMod					=		string.sub(BanInfo.ResponsibleMod, 1, 50)
		end
		
		assert(type(BanInfo.CaseId) == "string", "The CaseId has to be a string.")
		if		string.len(BanInfo.CaseId) > 40 then
				BanInfo.CaseId						=		string.sub(BanInfo.CaseId, 1, 40)
		end
		
		assert(BanInfo.Aktiv == true, "You can only teleport players to banland, wo are banned.")
		
		local		TPOptions							=		Instance.new("TeleportOptions")
				TPOptions:SetTeleportData(BanInfo)
		
		PrepareTeleport(Spieler)
		task.spawn(function()
				Teleport(Spieler, TPOptions)
		end)
end

local		function	Blacklisted(Spieler : Player, BlacklistInfo : {Type : "Blacklist", CaseId : string, Aktiv : true,  GrundExtern : string?, GrundIntern : string?, ResponsibleMod : string?, Message : string?})
		assert(Spieler and typeof(Spieler) == "Instance" and Spieler:IsA("Player"), "Thats not a valid player object.")
		
		assert(BlacklistInfo.GrundExtern == nil or type(BlacklistInfo.GrundExtern) == "string", "The external reason has to be a string or nil.")
		if		BlacklistInfo.GrundExtern and string.len(BlacklistInfo.GrundExtern) > 100 then
				BlacklistInfo.GrundExtern				=		string.sub(BlacklistInfo.GrundExtern, 1, 100)
		end
		
		assert(BlacklistInfo.GrundIntern == nil or type(BlacklistInfo.GrundIntern) == "string", "The internal reason has to be a string or nil.")
		if		BlacklistInfo.GrundIntern and string.len(BlacklistInfo.GrundIntern) > 100 then
				BlacklistInfo.GrundIntern				=		string.sub(BlacklistInfo.GrundIntern, 1, 100)
		end
		
		assert(BlacklistInfo.ResponsibleMod == nil or type(BlacklistInfo.ResponsibleMod) == "string", "The responsible mod has to be a string or nil.")
		if		BlacklistInfo.ResponsibleMod and string.len(BlacklistInfo.ResponsibleMod) > 50 then
				BlacklistInfo.ResponsibleMod				=		string.sub(BlacklistInfo.ResponsibleMod, 1, 50)
		end
		
		assert(type(BlacklistInfo.CaseId) == "string", "The CaseId has to be a string.")
		if		string.len(BlacklistInfo.CaseId) > 40 then
				BlacklistInfo.CaseId					=		string.sub(BlacklistInfo.CaseId, 1, 40)
		end
		
		assert(BlacklistInfo.Aktiv == true, "You can only teleport players to banland, wo are blacklisted.")
		
		assert(BlacklistInfo.Type == "Blacklist", "The Type has to be 'Blacklist'")
		
		assert(BlacklistInfo.Message == nil or type(BlacklistInfo.Message) == "string", "The Message has to be a string or nil.")
		if		BlacklistInfo.Message and string.len(BlacklistInfo.Message) > 150 then
				BlacklistInfo.Message					=		string.sub(BlacklistInfo.Message, 1, 150)
		end
		
		local		TPOptions							=		Instance.new("TeleportOptions")
		TPOptions:SetTeleportData(BlacklistInfo)

		PrepareTeleport(Spieler)
		task.spawn(function()
				Teleport(Spieler, TPOptions)
		end)
end

local		function	RemoveRecord(Spieler : Player, CaseId, DeleteRecord : boolean?)
		assert(Spieler and typeof(Spieler) == "Instance" and Spieler:IsA("Player"), "Thats not a valid player object.")
		
		CaseId									=		tonumber(CaseId) or CaseId

		DeleteRecord								=		if DeleteRecord == nil then Settings.DeleteRecordDefault else DeleteRecord

		if		DeleteRecord then	
				--		Remove all, wenn nur einer
				if		type(CaseId) == "number" and CaseId == 1 and #RecordsCache[Spieler].Records <= 1 then
						RecordsCache[Spieler].Records		=		{}
					
				else
						RecordsCache[Spieler].Records[CaseId]=		nil
				end
				
				local		Success					=		Settings:SetPlayerDataMethod(Spieler.UserId, RecordsCache[Spieler])
				if		Success == false then
						print("[Banland Module]: Saving failed for ".. Spieler.Name..". Record could not be removed.")
						
						return	"[Banland Module]: Saving failed for ".. Spieler.Name..". Record could not be removed."
				end
		end
		
		--		Ab jetzt wieder string
		local		CaseId							=		tostring(CaseId)
		if		string.len(CaseId) > 40 then
				CaseId							=		string.sub(CaseId, 1, 40)
		end
		
		local		RecordInfo							=		{
						Aktion					=		"RemoveRecord",
						CaseId					=		CaseId
		}
		
		local		TPOptions							=		Instance.new("TeleportOptions")
				TPOptions:SetTeleportData(RecordInfo)
				
		PrepareTeleport(Spieler, "Remove Record")
		
		return	Teleport(Spieler, TPOptions) -- Returnt true bei erfolgreichem Teleport und evtl. eine Fehlermeldung als String
end
local		function	RemoveAllRecords(Spieler : Player, DeleteRecord : boolean?)
		assert(Spieler and typeof(Spieler) == "Instance" and Spieler:IsA("Player"), "Thats not a valid player object.")
		
		DeleteRecord								=		if DeleteRecord == nil then Settings.DeleteRecordDefault else DeleteRecord
		
		if		DeleteRecord then
						RecordsCache[Spieler].Records		=		{}
				local		Success					=		Settings:SetPlayerDataMethod(Spieler.UserId, RecordsCache[Spieler])
				if		Success == false then
						print("[Banland Module]: Saving failed for ".. Spieler.Name..". Records could not be removed.")
						
						--		Records Cache wieder auf {} packen, damit Folgecommands nicht scheitern
						RecordsCache[Spieler].Records		=		{}
						return	"[Banland Module]: Saving failed for ".. Spieler.Name..". Records could not be removed."	
				end
		end
		
		local		TeleportInfo						=		{
								Aktion			=		"RemoveAllRecords"
		}
		
		local		TPOptions							=		Instance.new("TeleportOptions")
				TPOptions:SetTeleportData(TeleportInfo)
				
		PrepareTeleport(Spieler, "Remove All Records")
		
		return	Teleport(Spieler , TPOptions) -- Returnt true bei erfolgreichem Teleport
end

local		function	PlayerAdded(Spieler : Player)
		local		Daten								=		Settings:GetPlayerDataMethod(Spieler.UserId)
		if		not Daten then 
				task.wait(math.random(20, 60))
				if		not Spieler or not Spieler:IsDescendantOf(PLAYERS) then return end
				return	PlayerAdded(Spieler)
		end	
		assert(type(Daten) == "table", "The GetPlayerDataMethod has to return a table for the module to store data.")
		--		Rückwärtskompatibilität sichern 🙄
		if		not Daten.Records then
				Daten								=		{
						Records					=		Daten,
						Aktionen					=		{}
				}
		end
		
		--		Checken ob Unban
		local		JoinData							=		Spieler:GetJoinData()
		if		JoinData.SourcePlaceId == Settings.BanlandPlaceId and JoinData.TeleportData then
				local		TeleportData				=		JoinData.TeleportData
				
				--		Falls der Spieler durch eine Joinaktion ins Banland teleportiert und nun zurück geschickt wurde,
				--		die Aktion aus den vorgemerkten Aktionen entfernen
				if		TeleportData.Response == "MarkActionAsDone" then
						for		i, Aktion in Daten.Aktionen do
								if		Aktion.CaseId ~= TeleportData.CaseId or
										Aktion.Aktion ~= TeleportData.Aktion then
										continue			
								end
									
								table.remove(Daten.Aktionen, i)
				
								local		Success	=		Settings:SetPlayerDataMethod(Spieler.UserId, Daten)
								if		Success == false then
										print("[Banland Module]: Saving failed for", Spieler.Name..". If that happens too often, your unbanned players will get unnecessarily teleported whenever they join.")
								end
								
								break
						end
					
				else
						-- Der Spieler wurde im Banland Entbannt
						-- Record getten
						local		Record			=		nil
						for		CaseId, Case in Daten.Records do
								if		Case.CaseId ~= TeleportData.CaseId then continue end
								
								Record			=		Case
								break
						end
						
						if		Record then
								--		Record existiert: Unban
								Record.Aktiv		=		false
								
								--		Falls der spieler offline entbannt wurde aber schon seine Strafe abgesessen hat, muss die unban Aktion nicht mehr ausgeführt werden.
								if		Record.Aktion == "Unban" or Record.Aktion == "UnbanAllCases" then
										Record.Aktion=		nil
								end
								
								local		Success	=		Settings:SetPlayerDataMethod(Spieler.UserId, Daten)
								if		Success == false then
										print("[Banland Module]: Saving failed for", Spieler.Name..". If that happens too often, your unbanned players will get unnecessarily teleported whenever they join.")
								end
							
						else
								--	Remove Record im Banland weil er ist offensichtlich im Spiel schon removed
								RemoveRecord(Spieler, TeleportData.CaseId)
						end
				end
		end
		
		--		Wenn TeleportInfos für den Join vorgemerkt sind, Spieler mit ihnen teleportieren und den Eintrag entfernen
		if		#Daten.Aktionen >= 1 then
				local		TPOptions					=		Instance.new("TeleportOptions")
						TPOptions:SetTeleportData(Daten.Aktionen[1])

				PrepareTeleport(Spieler)
				task.spawn(function()
						Teleport(Spieler, TPOptions)
				end)

				return
		end
		
		--		Daten Cachen
		RecordsCache[Spieler]							=		Daten
		
		--		Wenn Strafen aktiv sind, abschieben
		for		CaseId, BanInfo in Daten.Records do		
				if		BanInfo.Aktiv then
						AbInsBanland(Spieler, BanInfo)
						return
				end
				
				--		Banland mitteilen, dass die Strafe nun inaktiv ist, falls er offline entbannt wurde.
				if		(BanInfo.Aktion == "Unban") and not Banland.IsStudio then
						BanInfo.Aktion				=		nil -- Aktion Unban ist dafür da, damit das Modul weiß, dass der Spieler beim Join entbannt werden soll. Sie wird nicht ins Banland übermittelt.
						
						local		TPOptions			=		Instance.new("TeleportOptions")
						TPOptions:SetTeleportData(BanInfo)

						PrepareTeleport(Spieler)
						task.spawn(function()
								Teleport(Spieler, TPOptions)
						end)
						
						local		Success			=		Settings:SetPlayerDataMethod(Spieler.UserId, RecordsCache[Spieler])
						if		Success == false then
								print("[Banland Module]: Saving failed for", Spieler.Name..". If that happens too often, your unbanned players will get unnecessarily teleported whenever they join.")
						end
						return
				end
		end
		
		--		Check Blacklist
		for		_, NameOrUserId in Settings.Blacklist do
				if		Spieler.Name ~= NameOrUserId and Spieler.UserId ~= NameOrUserId then continue end
				
				local		BlacklistInfo				=		{}
						BlacklistInfo.Type			=		"Blacklist"
						BlacklistInfo.CaseId			=		"Blacklist"
						BlacklistInfo.Aktiv			=		true
						BlacklistInfo.GrundExtern		=		"You are blacklisted from the experience."
						
				Blacklisted(Spieler, BlacklistInfo)
				return		
		end
		
		--		Global Blacklist checken
		if		not Settings.UseGlobalBlacklist then return end
		local		IsBlacklisted, BlacklistInfo				=		GlobalBlacklist:IsPlayerBlacklisted(Spieler)
		if		IsBlacklisted then
				Blacklisted(Spieler, BlacklistInfo)
				return
		end
		
		--		Global Blacklist checken (Nach Gruppen)
		if		not Settings.CheckGroups then return end
				IsBlacklisted, BlacklistInfo				=		GlobalBlacklist:IsGroupBlacklisted(Spieler)
		if		IsBlacklisted then
				Blacklisted(Spieler, BlacklistInfo)
				return
		end
end

local		function	OfflineCommandListener(Message)
		if		type(Message.Data) ~= "table" then return end
		local		Daten								=		Message.Data
		
		local		Spieler							=		PLAYERS:GetPlayerByUserId(Daten.UserId)
		if		not Spieler then return end
		
		if		Spieler.UserId == Banland.Owner then
				print("Someone tried to use an offline command on the Owner.")
				return
		end
		
		if		Daten.Aktion == "Kick" then
				Spieler:Kick(Daten.Argumente and Daten.Argumente[1] or "Someone used an offline command on you.")
				
		else
				--		PlayerAdded nochmal durchführen. Da werden die Daten neu geladen und alle weiteren Fälle abgedeckt
				PlayerAdded(Spieler)
		end
end

local		function	PlayerRemoving(Spieler : Player)
		RecordsCache[Spieler]							=		nil
		Debounce[Spieler]								=		nil
end

--		Bans the player
function	Banland:BanPlayer(Player : Player, Duration : string | number | nil, ReasonExternal : string?, ReasonInternal: string?, ResponsibleMod : string?, Buyouts : boolean | number | nil, IncrementFactor : number?)
		if		not Player or typeof(Player) ~= "Instance" or not Player:IsA("Player") then
				print(Player, "is not a valid player object.")
				return	"You did not provide a valid player object."
		end
		
		if		Debounce[Player] then return "Commands on this target are on debounce." end
		task.spawn(function()
				Debounce[Player]						=		true
				task.wait(30)
				Debounce[Player]						=		nil
		end)
		
		assert(ReasonExternal == nil or type(ReasonExternal) == "string", "The external reason has to be a string or nil.")
		if		ReasonExternal and string.len(ReasonExternal) > 100 then
				ReasonExternal						=		string.sub(ReasonExternal, 1, 100)
		end
		
		assert(ReasonInternal == nil or type(ReasonInternal) == "string", "The internal reason has to be a string or nil.")
		if		ReasonInternal and string.len(ReasonInternal) > 100 then
				ReasonInternal						=		string.sub(ReasonInternal, 1, 100)
		end
		
		assert(Buyouts == nil or type(Buyouts) == "boolean" or type(Buyouts) == "number", "Buyouts has to be a boolean, a GamepassId or nil.")
		if		Buyouts == nil then
				Buyouts							=		Settings.DefaultBuyouts
		end
	
		assert(IncrementFactor == nil or type(IncrementFactor) == "number", "The increment factor has to be a number or nil.")
		if		IncrementFactor then
				IncrementFactor						=		math.clamp(IncrementFactor, 0, 10)
		end
		
		assert(ResponsibleMod == nil or type(ResponsibleMod) == "string", "The responsible mod has to be a string or nil.")
		if		ResponsibleMod and string.len(ResponsibleMod) > 50 then
				ResponsibleMod						=		string.sub(ResponsibleMod, 1, 50)
		end
		
		if		Player.UserId == self.Owner then
				print("The owner can't get banned.")
				return	"The owner can't get banned."
		end
		
		--		Record Table anlegen, falls keiner existiert
		if		not RecordsCache[Player] then
				RecordsCache[Player]					=	Settings:GetPlayerDataMethod(Player.UserId)
				if		not RecordsCache[Player] then
						print("Ban failed. Coudn't load playerdata.")
						return	"Ban failed. Coudn't load playerdata."
				end
				--		Rückwärtskompatibilität sichern 🙄
				if		not RecordsCache[Player].Records then
						RecordsCache[Player]			=		{
								Records			=		RecordsCache[Player],
								Aktionen			=		{}
						}
				end
		
		end
		
		--		Verhindern, dass zu viele aktive Bans angelegt werden. Banland akzeptiert sowieso keine weiteren.
		local		ActiveCases							=		0
		for		CaseId, BanInfo in RecordsCache[Player].Records do
				if	BanInfo.Aktiv ~= true then continue end
				ActiveCases							+=		1
		end
		if		ActiveCases >= MaxActiveRecords then
				print("Ban failed. There are too many active cases for that player already.\nThey first need to get unbanned before getting banned again.\nActiveCases: "..ActiveCases)
				return	"Ban failed. There are too many active cases for that player already.\nThey first need to get unbanned before getting banned again.\nActiveCases: "..ActiveCases	
		end
		
		--		BanInfo Anlegen
		local		CaseIdNumber						=		#RecordsCache[Player].Records + 1
		if		CaseIdNumber > 9999 then
				print("Ban failed. There are already too many records saved for that player. You need to remove some or all records for that player and also delete them first.")
				return	"Ban failed. There are already too many records saved for that player. You need to remove some or all records for that player and also delete them first."	
		end
		local		BanInfo							=		{}
				BanInfo.CaseId						=		tostring(CaseIdNumber)
				BanInfo.Aktiv						=		true
				BanInfo.DauerInSekunden					=		ZeitUmrechnen(Duration)
				BanInfo.GrundExtern					=		ReasonExternal
				BanInfo.GrundIntern					=		ReasonInternal
				BanInfo.Buyouts						=		Buyouts
				BanInfo.IncrementFaktor					=		IncrementFactor or Settings.DefaultIncrementFactor
				BanInfo.ResponsibleMod					=		ResponsibleMod
		
		--		Eintrag Speichern
		RecordsCache[Player].Records[CaseIdNumber]			=		BanInfo
	
		local		Success							=		Settings:SetPlayerDataMethod(Player.UserId, RecordsCache[Player])
		if		Success == false then
				return	"Saving failed. Ban unsuccessful. You can use the /kick command to get rid of them for now."
		end
		--		Wech mit dem
		AbInsBanland(Player, BanInfo)
		
		return	Player.Name .. " got banned for " .. if Duration then tostring(Duration) else Settings.DefaultBanDuration
end

--		Bans the player using the Roblox Ban API and Alt Acccount detection
function	Banland:BanAltAccounts(Player : Player, Duration : string | number | nil, ReasonExternal : string?, ReasonInternal: string?, ResponsibleMod : string?)
		if		RUN:IsStudio() then
				print("Can't use the BanAltAccounts Method.\nThe Roblox Ban API does not work in Roblox Studio :/")
				return	"Can't use the BanAltAccounts Method.\nThe Roblox Ban API does not work in Roblox Studio :/"
		end
		
		if		not Player or typeof(Player) ~= "Instance" or not Player:IsA("Player") then
				print(Player, "is not a valid player object.")
				return	"You did not provide a valid player object."
		end
		
		if		Debounce[Player] then return "Commands on this target are on debounce." end
		task.spawn(function()
				Debounce[Player]						=		true
				task.wait(30)
				Debounce[Player]						=		nil
		end)
		
		assert(ReasonExternal == nil or type(ReasonExternal) == "string", "The external reason has to be a string or nil.")
		if		ReasonExternal and string.len(ReasonExternal) > 100 then
				ReasonExternal						=		string.sub(ReasonExternal, 1, 100)
		end
		
		assert(ReasonInternal == nil or type(ReasonInternal) == "string", "The internal reason has to be a string or nil.")
		if		ReasonInternal and string.len(ReasonInternal) > 100 then
				ReasonInternal						=		string.sub(ReasonInternal, 1, 100)
		end
		
		assert(ResponsibleMod == nil or type(ResponsibleMod) == "string", "The responsible mod has to be a string or nil.")
		if		ResponsibleMod and string.len(ResponsibleMod) > 50 then
				ResponsibleMod						=		string.sub(ResponsibleMod, 1, 50)
		end
		
		if		Player.UserId == self.Owner then
				print("The owner can't get banned.")
				return	"The owner can't get banned."
		end
	
		--		BanConfig erstellen
		local		BanInfo							=		{}
				BanInfo.UserIds						=		{Player.UserId}
				BanInfo.Duration						=		ZeitUmrechnen(Duration)
				BanInfo.DisplayReason					=		ReasonExternal or ""
				BanInfo.PrivateReason					=		(ReasonInternal or "") .." Ban by ".. (ResponsibleMod or "unknown")
				BanInfo.ExcludeAltAccounts				=		false
				BanInfo.ApplyToUniverse					=		true
		
	
		local		Success, Response						=		pcall(function()
				return	PLAYERS:BanAsync(BanInfo)
		end)
		
		if		Success == false then
				return	"Ban unsuccessful. "..Response.."\nYou can use the /kick command to get rid of them for now."
		end
		
		return	Player.Name .. " got banned for " .. if Duration then tostring(Duration) else Settings.DefaultBanDuration
end

--		Bans the player
function	Banland:OfflineBanPlayer(PlayerNameOrId : string | number, Duration : string | number | nil, ReasonExternal : string?, ReasonInternal: string?, ResponsibleMod : string?, Buyouts : boolean | number | nil, IncrementFactor : number?)
		if		not Settings.AllowOfflineCommands then
				print("Offline commands are disabled!")
				return	"Offline commands are disabled!"
		end
		
		assert(PlayerNameOrId and type(PlayerNameOrId) == "string" or type(PlayerNameOrId) == "number", "PlayerNameOrId needs to be a string or number.")
		
		if		Debounce[PlayerNameOrId] then return "Commands on this target are on debounce." end
		task.spawn(function()
				Debounce[PlayerNameOrId]				=		true
				task.wait(2)
				Debounce[PlayerNameOrId]				=		nil
		end)
		
		assert(ReasonExternal == nil or type(ReasonExternal) == "string", "The external reason has to be a string or nil.")
		if		ReasonExternal and string.len(ReasonExternal) > 100 then
				ReasonExternal						=		string.sub(ReasonExternal, 1, 100)
		end
		
		assert(ReasonInternal == nil or type(ReasonInternal) == "string", "The internal reason has to be a string or nil.")
		if		ReasonInternal and string.len(ReasonInternal) > 100 then
				ReasonInternal						=		string.sub(ReasonInternal, 1, 100)
		end
		
		assert(Buyouts == nil or type(Buyouts) == "boolean" or type(Buyouts) == "number", "Buyouts has to be a boolean, a GamepassId or nil.")
		if		Buyouts == nil then
				Buyouts							=		Settings.DefaultBuyouts
		end

		assert(IncrementFactor == nil or type(IncrementFactor) == "number", "The increment factor has to be a number or nil.")
		if		IncrementFactor then
				IncrementFactor						=		math.clamp(IncrementFactor, 0, 10)
		end
		
		assert(ResponsibleMod == nil or type(ResponsibleMod) == "string", "The responsible mod has to be a string or nil.")
		if		ResponsibleMod and string.len(ResponsibleMod) > 50 then
				ResponsibleMod						=		string.sub(ResponsibleMod, 1, 50)
		end
		
		local		UserId							=		tonumber(PlayerNameOrId)
		if		not UserId then
				local		Erfolg, Ergebnis				=		pcall(function()
						return	PLAYERS:GetUserIdFromNameAsync(PlayerNameOrId)
				end)
				
				if		not Erfolg then						
						return	"Offlineban was not successful. Was not able to get the UserId of '"..PlayerNameOrId.."'"
				else
						
						UserId					=		Ergebnis
				end
		end
		
		if		UserId == self.Owner then
				print("The owner can't get banned.")
				return	"The owner can't get banned."
		end
		
		--		Schauen, ob der Spieler online ist, dann online Ban
		local		Player							=		PLAYERS:GetPlayerByUserId(UserId)
		if		Player then
				return	self:BanPlayer(Player, Duration, ReasonExternal, ReasonInternal, ResponsibleMod, Buyouts, IncrementFactor)
		end
		
		--		Daten getten
		local		Records							=		Settings:GetPlayerDataMethod(UserId)
		if		not Records then
				print("Offlineban not successful. Couldn't load player data.")
				return	"Error: Offlineban not successful. Couldn't load player data."
		end
		assert(type(Records) == "table", "The GetPlayerDataMethod has to return a table for the module to store data.")
		--		Rückwärtskompatibilität sichern 🙄
		if		not Records.Records then
				Records							=		{
						Records					=		Records,
						Aktionen					=		{}
				}
		end
		
		--		Verhindern, dass zu viele aktive Bans angelegt werden. Banland akzeptiert sowieso keine weiteren.
		local		ActiveCases							=		0
		for		CaseId, BanInfo in Records.Records do
				if	BanInfo.Aktiv ~= true then continue end
				ActiveCases							+=		1
		end
		if		ActiveCases >= MaxActiveRecords then
				print("Offlineban failed. There are too many active cases for that player already.\nThey first need to get unbanned before getting banned again.\nActiveCases: "..ActiveCases)
				return	"Offlineban failed. There are too many active cases for that player already.\nThey first need to get unbanned before getting banned again.\nActiveCases: "..ActiveCases	
		end
		
		--		BanInfo anlegen
		local		CaseIdNumber						=		#Records.Records + 1
		if		CaseIdNumber > 9999 then
				print("Offlineban failed. There are already too many records saved for that player. You need to remove some or all records for that player and also delete them first.")
				return	"Offlineban failed. There are already too many records saved for that player. You need to remove some or all records for that player and also delete them first."	
		end
		
		local		BanInfo							=		{}
				BanInfo.CaseId						=		tostring(CaseIdNumber)
				BanInfo.Aktiv						=		true
				BanInfo.DauerInSekunden					=		ZeitUmrechnen(Duration)
				BanInfo.GrundExtern					=		ReasonExternal
				BanInfo.GrundIntern					=		ReasonInternal
				BanInfo.Buyouts						=		Buyouts
				BanInfo.IncrementFaktor					=		IncrementFactor or Settings.DefaultIncrementFactor
				BanInfo.ResponsibleMod					=		ResponsibleMod
		
		--		Eintrag Speichern
		
		Records.Records[CaseIdNumber]						=		BanInfo
	
		local		Success							=		Settings:SetPlayerDataMethod(UserId, Records)
		if		Success == false then
				return	"Saving failed. Offlineban unsuccessful."
		end
		
		--		Offline Command auf anderen Servern durchsetzen, falls der Spieler dort online ist
		task.defer(function()
				MESSAGE:PublishAsync("BanlandModul_OfflineCommands", {UserId = UserId})
		end)
		
		return	PlayerNameOrId .. " got banned for " .. if Duration then tostring(Duration) else Settings.DefaultBanDuration
end

--		Bans the player using the Roblox Ban API and Alt Acccount detection
function	Banland:OfflineBanAltAccounts(PlayerNameOrId : string | number, Duration : string | number | nil, ReasonExternal : string?, ReasonInternal: string?, ResponsibleMod : string?)
		if		RUN:IsStudio() then
				print("Can't use the OfflineBanAltAccounts Method.\nThe Roblox Ban API does not work in Roblox Studio :/")
				return	"Can't use the OfflineBanAltAccounts Method.\nThe Roblox Ban API does not work in Roblox Studio :/"
		end
		
		if		not Settings.AllowOfflineCommands then
				print("Offline commands are disabled!")
				return	"Offline commands are disabled!"
		end
		
		assert(PlayerNameOrId and type(PlayerNameOrId) == "string" or type(PlayerNameOrId) == "number", "PlayerNameOrId needs to be a string or number.")
		
		if		Debounce[PlayerNameOrId] then return "Commands on this target are on debounce." end
		task.spawn(function()
				Debounce[PlayerNameOrId]				=		true
				task.wait(2)
				Debounce[PlayerNameOrId]				=		nil
		end)
		
		assert(ReasonExternal == nil or type(ReasonExternal) == "string", "The external reason has to be a string or nil.")
		if		ReasonExternal and string.len(ReasonExternal) > 100 then
				ReasonExternal						=		string.sub(ReasonExternal, 1, 100)
		end
		
		assert(ReasonInternal == nil or type(ReasonInternal) == "string", "The internal reason has to be a string or nil.")
		if		ReasonInternal and string.len(ReasonInternal) > 100 then
				ReasonInternal						=		string.sub(ReasonInternal, 1, 100)
		end
		
		assert(ResponsibleMod == nil or type(ResponsibleMod) == "string", "The responsible mod has to be a string or nil.")
		if		ResponsibleMod and string.len(ResponsibleMod) > 50 then
				ResponsibleMod						=		string.sub(ResponsibleMod, 1, 50)
		end
		
		local		UserId							=		tonumber(PlayerNameOrId)
		if		not UserId then
				local		Erfolg, Ergebnis				=		pcall(function()
						return	PLAYERS:GetUserIdFromNameAsync(PlayerNameOrId)
				end)
				
				if		not Erfolg then						
						return	"Offlineban was not successful. Was unable to get the UserId of '"..PlayerNameOrId.."'"
				else
						
						UserId					=		Ergebnis
				end
		end
		
		if		UserId == self.Owner then
				print("The owner can't get banned.")
				return	"The owner can't get banned."
		end
		
		--		Schauen, ob der Spieler online ist, dann online Ban
		local		Player							=		PLAYERS:GetPlayerByUserId(UserId)
		if		Player then
				return	self:BanAltAccounts(Player, Duration, ReasonExternal, ReasonInternal, ResponsibleMod)
		end
		
		--		BanConfig erstellen
		local		BanInfo							=		{}
				BanInfo.UserIds						=		{UserId}
				BanInfo.Duration						=		ZeitUmrechnen(Duration)
				BanInfo.DisplayReason					=		ReasonExternal or ""
				BanInfo.PrivateReason					=		(ReasonInternal or "") .." Ban by ".. (ResponsibleMod or "unknown")
				BanInfo.ExcludeAltAccounts				=		false
				BanInfo.ApplyToUniverse					=		true
		
	
		local		Success, Response						=		pcall(function()
				return	PLAYERS:BanAsync(BanInfo)
		end)

		if		Success == false then
				return	"Offlineban unsuccessful. "..Response
		end
		
		--		Offline Command auf anderen Servern durchsetzen, falls der Spieler dort online ist
		task.defer(function()
				MESSAGE:PublishAsync("BanlandModul_OfflineCommands", {UserId = UserId, Aktion = "Kick", Argumente = {ReasonExternal or "You got banned from this experience."}})
		end)
		
		return	PlayerNameOrId .. " got banned for " .. if Duration then tostring(Duration) else Settings.DefaultBanDuration
end

--		Permanently bans a player. The won't be able to play your game and banland will handle them, like a blacklisted player.
function	Banland:PermbanPlayer(Player : Player, ReasonExternal : string?, ReasonInternal: string?, ResponsibleMod : string?)
		if		not Player or typeof(Player) ~= "Instance" or not Player:IsA("Player") then
				print(Player, "is not a valid player object.")
				return	"You did not provide a valid player object."
		end
		
		assert(ReasonExternal == nil or type(ReasonExternal) == "string", "The external reason has to be a string or nil.")
		if		ReasonExternal and string.len(ReasonExternal) > 100 then
				ReasonExternal						=		string.sub(ReasonExternal, 1, 100)
		end
		
		assert(ReasonInternal == nil or type(ReasonInternal) == "string", "The internal reason has to be a string or nil.")
		if		ReasonInternal and string.len(ReasonInternal) > 100 then
				ReasonInternal						=		string.sub(ReasonInternal, 1, 100)
		end
		
		assert(ResponsibleMod == nil or type(ResponsibleMod) == "string", "The responsible mod has to be a string or nil.")
		if		ResponsibleMod and string.len(ResponsibleMod) > 50 then
				ResponsibleMod						=		string.sub(ResponsibleMod, 1, 50)
		end
		
		if		Player.UserId == self.Owner then
				print("The owner can't get banned.")
				return	"The owner can't get banned."
		end
		
		--		Record Table anlegen, falls keiner existiert
		if		not RecordsCache[Player] then
				RecordsCache[Player]					=	Settings:GetPlayerDataMethod(Player.UserId)
				if		not RecordsCache[Player] then
						print("Permban failed. Coudn't retrieve playerdata.")
						return	"Permban failed. Coudn't retrieve playerdata."
				end
				--		Rückwärtskompatibilität sichern 🙄
				if		not RecordsCache[Player].Records then
						RecordsCache[Player]			=		{
								Records			=		RecordsCache[Player],
								Aktionen			=		{}
						}
				end
		end
		
		--		Verhindern, dass zu viele aktive Bans angelegt werden. Banland akzeptiert sowieso keine weiteren.
		local		ActiveCases							=		0
		for		CaseId, BanInfo in RecordsCache[Player].Records do
				if	BanInfo.Aktiv ~= true then continue end
				ActiveCases							+=		1
		end
		if		ActiveCases >= MaxActiveRecords then
				print("Permban failed. There are too many active cases for that player already.\nThey first need to get unbanned before getting banned again.\nActiveCases: "..ActiveCases)
				return	"Permban failed. There are too many active cases for that player already.\nThey first need to get unbanned before getting banned again.\nActiveCases: "..ActiveCases	
		end
		
		--		BlacklistInfo anlegen
		local		CaseIdNumber						=		#RecordsCache[Player].Records + 1
		if		CaseIdNumber > 9999 then
				print("Permban failed. There are already too many records saved for that player. You need to remove some or all records for that player and also delete them first.")
				return	"Permban failed. There are already too many records saved for that player. You need to remove some or all records for that player and also delete them first."	
		end
		local		BlacklistInfo						=		{}
				BlacklistInfo.Type					=		"Blacklist"
				BlacklistInfo.CaseId					=		tostring(CaseIdNumber)
				BlacklistInfo.Aktiv					=		true
				BlacklistInfo.GrundExtern				=		ReasonExternal
				BlacklistInfo.GrundIntern				=		ReasonInternal
				BlacklistInfo.ResponsibleMod				=		ResponsibleMod
		
		--		Eintrag Speichern
		RecordsCache[Player].Records[CaseIdNumber]			=		BlacklistInfo

		local		Success							=		Settings:SetPlayerDataMethod(Player.UserId, RecordsCache[Player])
		if		Success == false then
				return	"Saving failed. Permban unsuccessful. You can use the /kick command to get rid of them for now."
		end
		
		--		Wech mit dem
		Blacklisted(Player, BlacklistInfo)

		return	Player.Name .. " got permanently banned."
end

--		Permanently bans an offline player. The won't be able to play your game and banland will handle them, like a blacklisted player.
function	Banland:OfflinePermbanPlayer(PlayerNameOrId : string | number, ReasonExternal : string?, ReasonInternal: string?, ResponsibleMod : string?)
		if		not Settings.AllowOfflineCommands then
				print("Offline commands are disabled!")
				return	"Offline commands are disabled!"
		end
		
		assert(PlayerNameOrId and type(PlayerNameOrId) == "string" or type(PlayerNameOrId) == "number", "PlayerNameOrId needs to be a string or number.")
		
		if		Debounce[PlayerNameOrId] then return "Commands on this target are on debounce." end
		task.spawn(function()
				Debounce[PlayerNameOrId]				=		true
				task.wait(2)
				Debounce[PlayerNameOrId]				=		nil
		end)
		
		assert(ReasonExternal == nil or type(ReasonExternal) == "string", "The external reason has to be a string or nil.")
		if		ReasonExternal and string.len(ReasonExternal) > 100 then
				ReasonExternal						=		string.sub(ReasonExternal, 1, 100)
		end
		
		assert(ReasonInternal == nil or type(ReasonInternal) == "string", "The internal reason has to be a string or nil.")
		if		ReasonInternal and string.len(ReasonInternal) > 100 then
				ReasonInternal						=		string.sub(ReasonInternal, 1, 100)
		end
		
		assert(ResponsibleMod == nil or type(ResponsibleMod) == "string", "The responsible mod has to be a string or nil.")
		if		ResponsibleMod and string.len(ResponsibleMod) > 50 then
				ResponsibleMod						=		string.sub(ResponsibleMod, 1, 50)
		end
		
		local		UserId							=		tonumber(PlayerNameOrId)
		if		not UserId then
				local		Erfolg, Ergebnis				=		pcall(function()
						return	PLAYERS:GetUserIdFromNameAsync(PlayerNameOrId)
				end)
				
				if		not Erfolg then
						return	"Offlinepermban was not successful. Was not able to get the UserId of '"..PlayerNameOrId.."'"
				else
						
						UserId					=		Ergebnis
				end
		end
		
		if		UserId == self.Owner then
				print("The owner can't get banned.")
				return	"The owner can't get banned."
		end
		
		--		Schauen, ob der Spieler online ist, dann online Permban
		local		Player							=		PLAYERS:GetPlayerByUserId(UserId)
		if		Player then
				return	self:Permban(Player, ReasonExternal, ReasonInternal, ResponsibleMod)
		end
		
		--		Daten getten
		local		Records							=		Settings:GetPlayerDataMethod(UserId)
		if		not Records then
				print("Offlinepermban failed. Coudn't retrieve playerdata.")
				return	"Offlinepermban failed. Coudn't retrieve playerdata."
		end
		assert(type(Records) == "table", "The GetPlayerDataMethod has to return a table for the module to store data.")
		--		Rückwärtskompatibilität sichern 🙄
		if		not Records.Records then
				Records							=		{
						Records					=		Records,
						Aktionen					=		{}
				}
		end
		
		--		Verhindern, dass zu viele aktive Bans angelegt werden. Banland akzeptiert sowieso keine weiteren.
		local		ActiveCases							=		0
		for		CaseId, BanInfo in Records.Records do
				if	BanInfo.Aktiv ~= true then continue end
				ActiveCases							+=		1
		end
		if		ActiveCases >= MaxActiveRecords then
				print("Offlinepermban failed. There are too many active cases for that player already.\nThey first need to get unbanned before getting banned again.\nActiveCases: "..ActiveCases)
				return	"Offlinepermban failed. There are too many active cases for that player already.\nThey first need to get unbanned before getting banned again.\nActiveCases: "..ActiveCases	
		end
		
		--		BlacklistInfo anlegen
		local		CaseIdNumber						=		#Records.Records + 1
		if		CaseIdNumber > 9999 then
				print("Offlinepermban failed. There are already too many records saved for that player. You need to remove some or all records for that player and also delete them first.")
				return	"Offlinepermban failed. There are already too many records saved for that player. You need to remove some or all records for that player and also delete them first."	
		end
		local		BlacklistInfo						=		{}
				BlacklistInfo.Type					=		"Blacklist"
				BlacklistInfo.CaseId					=		tostring(CaseIdNumber)
				BlacklistInfo.Aktiv					=		true
				BlacklistInfo.GrundExtern				=		ReasonExternal
				BlacklistInfo.GrundIntern				=		ReasonInternal
				BlacklistInfo.ResponsibleMod				=		ResponsibleMod
		
		--		Eintrag Speichern
		Records.Records[CaseIdNumber]						=		BlacklistInfo

		local		Success							=		Settings:SetPlayerDataMethod(UserId, Records)
		if		Success == false then
				return	"Saving failed. Offlinepermban unsuccessful."
		end
		
		--		Offline Command auf anderen Servern durchsetzen, falls der Spieler dort online ist
		task.defer(function()
				MESSAGE:PublishAsync("BanlandModul_OfflineCommands", {UserId = UserId})
		end)

		return	PlayerNameOrId .. " got permanently banned."
end

--		Teleports a player to the banland without banning them.
function	Banland:VisitBanland(Player : Player, ResponsibleMod : string?)
		if		not Player or typeof(Player) ~= "Instance" or not Player:IsA("Player") then
				print(Player, "is not a valid player object.")
				return	"You did not provide a valid player object."
		end
		
		assert(ResponsibleMod == nil or type(ResponsibleMod) == "string", "The responsible mod has to be a string or nil.")
		if		ResponsibleMod and string.len(ResponsibleMod) > 50 then
				ResponsibleMod						=		string.sub(ResponsibleMod, 1, 50)
		end
		
		local		TPInfo							=		{}
				TPInfo.Type							=		"Visit"
				TPInfo.ResponsibleMod					=		ResponsibleMod
				
		local		TPOptions							=		Instance.new("TeleportOptions")
				TPOptions:SetTeleportData(TPInfo)

		PrepareTeleport(Player, "Visit")
		task.spawn(function()
				Teleport(Player, TPOptions)
		end)

		return	Player.Name .. " got sent to banland for a visit."
end

--		Removes the record in Banland for the given CaseId
function	Banland:RemoveRecord(Player : Player, CaseId : number | "all", DeleteRecord : boolean?)
		if		not Player or typeof(Player) ~= "Instance" or not Player:IsA("Player") then
				print(Player, "is not a valid player object.")
				return	"You did not provide a valid player object."
		end
		
		if		Debounce[Player] then return "Commands on this player are on debounce." end
		task.spawn(function()
				Debounce[Player]						=		true
				task.wait(2)
				Debounce[Player]						=		nil
		end)

		if		CaseId == "all" then
				local		Result					=		RemoveAllRecords(Player, DeleteRecord)
				if		Result ~= true then
						return	"The attempt to remove all records failed. "..if type(Result) == "string" then Result else ""
				end
				return	"Successfully sent "..Player.Name.." to banland to remove all records. (If the teleport didn't fail)"
		end
		
		assert(type(CaseId) == "number", "The CaseId has to be a number")
		
		local		Result							=		RemoveRecord(Player, CaseId, DeleteRecord)
		if		Result ~= true then
				return	"The attempt to remove the record failed. "..if type(Result) == "string" then Result else ""
		end
		
		return	"Successfully sent "..Player.Name.." to banland to remove record "..CaseId..". (If the teleport didn't fail)"
end

--		Overwrites the active record of the given player
function	Banland:EditActiveRecord(PlayerNameOrId : string | number, Duration : string | number | nil, ReasonExternal : string?, ReasonInternal: string?, ResponsibleMod : string?, Buyouts : boolean | number | nil, IncrementFactor : number?)
		if		not Settings.AllowOfflineCommands then 
				warn("Offline Commands are disabled!")
				return	"Offline commands are disabled!"
		end
		
		assert(PlayerNameOrId and type(PlayerNameOrId) == "string" or type(PlayerNameOrId) == "number", "PlayerNameOrId needs to be a string or number.")
		
		if		Debounce[PlayerNameOrId] then return "Commands on this target are on debounce." end
		task.spawn(function()
				Debounce[PlayerNameOrId]				=		true
				task.wait(2)
				Debounce[PlayerNameOrId]				=		nil
		end)
		
		assert(ReasonExternal == nil or type(ReasonExternal) == "string", "The external reason has to be a string or nil.")
		if		ReasonExternal and string.len(ReasonExternal) > 100 then
				ReasonExternal						=		string.sub(ReasonExternal, 1, 100)
		end
		
		assert(ReasonInternal == nil or type(ReasonInternal) == "string", "The internal reason has to be a string or nil.")
		if		ReasonInternal and string.len(ReasonInternal) > 100 then
				ReasonInternal						=		string.sub(ReasonInternal, 1, 100)
		end
		
		assert(Buyouts == nil or type(Buyouts) == "boolean" or type(Buyouts) == "number", "Buyouts has to be a boolean, a GamepassId or nil.")
		if		Buyouts == nil then
				Buyouts							=		Settings.DefaultBuyouts
		end

		assert(IncrementFactor == nil or type(IncrementFactor) == "number", "The increment factor has to be a number or nil.")
		if		IncrementFactor then
				IncrementFactor						=		math.clamp(IncrementFactor, 0, 10)
		end
		
		assert(ResponsibleMod == nil or type(ResponsibleMod) == "string", "The responsible mod has to be a string or nil.")
		if		ResponsibleMod and string.len(ResponsibleMod) > 50 then
				ResponsibleMod						=		string.sub(ResponsibleMod, 1, 50)
		end
		
		local		UserId							=		tonumber(PlayerNameOrId)
		if		not UserId then
				local		Erfolg, Ergebnis				=		pcall(function()
						return	PLAYERS:GetUserIdFromNameAsync(PlayerNameOrId)
				end)
				
				if		not Erfolg then
						return	"EditActiveRecord was not successful. Was not able to get the UserId of '"..PlayerNameOrId.."'"
				else
						
						UserId					=		Ergebnis
				end
		end

		local		Player							=		PLAYERS:GetPlayerByUserId(UserId)
		if		Player then
				return	tostring(PlayerNameOrId) .. " is online on this server. Therefore there should be no active case for them yet or anymore."
		end
		
		local		Records							=		Settings:GetPlayerDataMethod(UserId)
		if		not Records then
				return	"Error: Couldn't load player data."
		end
		assert(type(Records) == "table", "The GetPlayerDataMethod has to return a table for the module to store data.")
		--		Rückwärtskompatibilität sichern 🙄
		if		not Records.Records then
				Records							=		{
						Records					=		Records,
						Aktionen					=		{}
				}
		end
		
		--		Nächsten aktiven Record finden
		local		ActiveRecord						=		nil
		for		CaseId, BanInfo in Records.Records do		
				if		not BanInfo.Aktiv then continue end
				ActiveRecord						=		BanInfo
				break
		end
		if		not ActiveRecord then
				return	"EditActiveRecord was not successful. Currently there is no active record for "..PlayerNameOrId
		end
		
		--		Daten überschreiben
		ActiveRecord.DauerInSekunden						=		if Duration then ZeitUmrechnen(Duration) else ActiveRecord.DauerInSekunden
		ActiveRecord.GrundExtern						=		ReasonExternal or ActiveRecord.GrundExtern
		ActiveRecord.GrundIntern						=		ReasonInternal or ActiveRecord.GrundIntern
		ActiveRecord.Buyouts							=		Buyouts or ActiveRecord.Buyouts
		ActiveRecord.IncrementFaktor						=		IncrementFactor or ActiveRecord.IncrementFaktor
		ActiveRecord.ResponsibleMod						=		ResponsibleMod or ActiveRecord.ResponsibleMod
			
		--		Speichern
		local		Success							=		Settings:SetPlayerDataMethod(UserId, Records)
		if		Success == false then
				print("[Banland Module]: Saving failed for ".. PlayerNameOrId..". Active record could not be edited.")

				return	"EditActiveRecord was not successful: Saving failed."
		end
		
		--		Offline Command auf anderen Servern durchsetzen ist nicht erforderlich, da der Spieler ja bereits gebannt sein müsste
		
		return	"The active record for "..PlayerNameOrId.." was successfully edited."
end

--		Removes the record in Banland on offline Players for the given CaseId
function	Banland:OfflineRemoveRecord(PlayerNameOrId : string | number, CaseId : number | "all", DeleteRecord : boolean?)
		if		not Settings.AllowOfflineCommands then
				print("Offline commands are disabled!")
				return	"Offline commands are disabled!"
		end
		
		if		type(PlayerNameOrId) ~= "string" and type(PlayerNameOrId) ~= "number" then
				print("PlayerNameOrId needs to be a string or number.")
				return	"PlayerNameOrId needs to be a string or number."
		end
		
		if		Debounce[PlayerNameOrId] then return "Commands on this player are on debounce." end
		task.spawn(function()
				Debounce[PlayerNameOrId]				=		true
				task.wait(2)
				Debounce[PlayerNameOrId]				=		nil
		end)
		
		local		UserId							=		tonumber(PlayerNameOrId)
		if		not UserId then
				local		Erfolg, Ergebnis				=		pcall(function()
						return	PLAYERS:GetUserIdFromNameAsync(PlayerNameOrId)
				end)
				
				if		not Erfolg then
						return	"OfflineRemoveRecord was not successful. Was not able to get the UserId of '"..PlayerNameOrId.."'"
				else
						UserId					=		Ergebnis
				end
		end
		
		if		type(CaseId) ~= "number" and CaseId ~= "all" then
				print("The CaseId has to be a number or 'all'")
				return	"The CaseId has to be a number or 'all'"
		end
		
		local		Player							=		PLAYERS:GetPlayerByUserId(UserId)
		if		Player then
				return	self:RemoveRecord(Player, CaseId, DeleteRecord)
		end
		
		local		Records							=		Settings:GetPlayerDataMethod(UserId)
		if		not Records then
				print("Error: OfflineRemoveRecord not successful. Couldn't load player data.")
				return	"Error: OfflineRemoveRecord not successful. Couldn't load player data."
		end
		assert(type(Records) == "table", "The GetPlayerDataMethod has to return a table for the module to store data.")
		--		Rückwärtskompatibilität sichern 🙄
		if		not Records.Records then
				Records							=		{
						Records					=		Records,
						Aktionen					=		{}
				}
		end
		
		if		#Records.Aktionen >= MaxScheduledActions -1 then
				--	This limit is nessesary because for every action the player will get teleported on join and it is be a terrible experience to be stuck in an infinite teleport loop.
				return	"There are already too many scheduled actions for that player. They must join the game first."
		end
		
		--		Remove all Records
		if		CaseId == "all" then
				if		DeleteRecord then
						Records.Records				=		{}
				end
				
				--		Alle weiteren RemoveRecord Aktionen entfernen, da jetzt eh alle removed werden
				local		NeuerTable					=		{}
				for		_, Inhalt in Records.Aktionen do
						if		Inhalt.Aktion ~= "RemoveAllRecords" and
								Inhalt.Aktion ~= "RemoveRecord" then
								continue
						end
						table.insert(NeuerTable, Inhalt)	
				end
				Records.Aktionen						=		NeuerTable
				
				--		Aktion schedulen
				table.insert(Records.Aktionen,{
						Aktion					=		"RemoveAllRecords"
				})
				
				--		Speichern
				local		Success					=		Settings:SetPlayerDataMethod(UserId, Records)
				if		Success == false then
						print("[Banland Module]: Saving failed for ".. PlayerNameOrId..". Record could not be removed.")

						return	"OfflineRemoveAllRecords was not successful: Saving failed."
				end
				
				return	"All records were successfully marked to get removed, when "..PlayerNameOrId.." rejoins the experience."
		end
		
		if		type(CaseId) ~= "number" then
				print("The CaseId has to be a number")
				return	"The CaseId has to be a number"
		end
		
		--		Delete Record
		if		DeleteRecord then
				--		Remove all, wenn nur einer
				if		type(CaseId) and CaseId == 1 and #Records.Records <= 1 then
						Records.Records				=		{}
					
				else
						Records.Records[CaseId]			=		nil
				end
		end
		
		--		Ab jetzt wieder string
		local		CaseId							=		tostring(CaseId)
		if		string.len(CaseId) > 40 then
				CaseId							=		string.sub(CaseId, 1, 40)
		end
		
		--		Falls der Record oder alle Records bereits zum removen gescheduled sind, abbrechen.
		for		_, Aktion in Records.Aktionen do
				if		Aktion.Aktion == "RemoveAllRecords" or
						Aktion.Aktion == "RemoveRecord" and Aktion.CaseId == CaseId then
						
						return	"The record is already scheduled to get removed.".. if DeleteRecord then " It got deleted if it wasnt already." else ""
				end
		end
		
		--		Aktion schedulen
		table.insert(Records.Aktionen,{
				Aktion							=		"RemoveRecord",
				CaseId							=		CaseId
		})
		
		--		Speichern
		local		Success							=		Settings:SetPlayerDataMethod(UserId, Records)
		if		Success == false then
				print("[Banland Module]: Saving failed for ".. PlayerNameOrId..". Record could not be removed.")

				return	"OfflineRemoveRecord was not successful: Saving failed."
		end
		
		--		Offline Command auf anderen Servern durchsetzen, falls der Spieler dort online ist
		task.defer(function()
				MESSAGE:PublishAsync("BanlandModul_OfflineCommands", {UserId = UserId})
		end)
		
		return	"The record was successfully marked to get removed, when "..PlayerNameOrId.." rejoins the experience."
end

--		Deactivates the ban for the given CaseId or for all cases, if no CaseId is given in banland for an online player.
function	Banland:MarkAsUnbannedInBanland(Player : Player, CaseId : number?)
		if		not Player or typeof(Player) ~= "Instance" or not Player:IsA("Player") then
				print(Player, "is not a valid player object.")
				return	"You did not provide a valid player object."
		end
		
		if		Debounce[Player] then return "Commands on this player are on debounce." end
		task.spawn(function()
				Debounce[Player]						=		true
				task.wait(2)
				Debounce[Player]						=		nil
		end)
		
		if		type(CaseId) ~= "number" and CaseId ~= nil then
				print("The CaseId has to be a number or nil")
				return	"The CaseId has to be a number or nil"
		end
		
		if		CaseId == nil then
				for		CaseId, Record in RecordsCache[Player].Records do
						if		Record.Aktiv == false then continue end
						
						Record.Aktiv				=		false
				end
				
				local		TPOptions					=		Instance.new("TeleportOptions")
				TPOptions:SetTeleportData({
						Aktion					=		"UnbanAllCases"
				})

				PrepareTeleport(Player)
				task.spawn(function()
						Teleport(Player, TPOptions)
				end)
		
		else
				local		Record					=		RecordsCache[Player].Records[CaseId]
				if		not Record then	-- Kann ja sein, dass der Record im Banland existiert aber hier gelöscht ist oder nie gespeichert wurde.
						--		Record im Banland removen
						Debounce[Player]				=		nil
						return	"This CaseId does not exist for the player. They will get teleported anyways because it might exist in banland. " .. self:RemoveRecord(Player, CaseId)
				end
				
				Record.Aktiv						=		false
				Record.Aktion						=		"Unban"

				local		TPOptions					=		Instance.new("TeleportOptions")
				TPOptions:SetTeleportData(Record)

				PrepareTeleport(Player, "Unban")
				task.spawn(function()
						Teleport(Player, TPOptions)
				end)
				
				--		Sonst wirds beim rejoin noch mal gemacht
				Record.Aktion						=		nil
		end
		
		local		Success							=		Settings:SetPlayerDataMethod(Player.UserId, RecordsCache[Player])
		if		Success == false then
				return	"Saving failed. "..Player.Name .. " got marked as unbanned anyway. (If the teleport didn't fail)"
		end
		
		return	Player.Name .. " got marked as unbanned. (If the teleport didn't fail)"
end

--		Deactivates the ban for the given CaseId or for all cases, if no CaseId is given for an offline player by name or UserId.
function	Banland:Unban(PlayerNameOrId : string | number, CaseId : number?, DeleteRecord : boolean?)
		if		not Settings.AllowOfflineCommands then
				print("Offline commands are disabled!")
				return	"Offline commands are disabled!"
		end
		
		if		type(PlayerNameOrId) ~= "string" and type(PlayerNameOrId) ~= "number" then
				print("PlayerNameOrId needs to be a string or number.")
				return	"PlayerNameOrId needs to be a string or number."
		end
		
		if		type(DeleteRecord) ~= "boolean" and DeleteRecord ~= nil then
				print("DeleteRecord needs to be a boolean or number.")
				return	"DeleteRecord needs to be a boolean or number."
		end
		
		if		Debounce[PlayerNameOrId] then return "Commands on this player are on debounce." end
		task.spawn(function()
				Debounce[PlayerNameOrId]				=		true
				task.wait(2)
				Debounce[PlayerNameOrId]				=		nil
		end)
		
		local		UserId							=		tonumber(PlayerNameOrId)
		if		not UserId then
				local		Erfolg, Ergebnis				=		pcall(function()
						return	PLAYERS:GetUserIdFromNameAsync(PlayerNameOrId)
				end)
				
				if		not Erfolg then
						return	"Unban was not successful. Was not able to get the UserId of '"..PlayerNameOrId.."'"
				else
						
						UserId					=		Ergebnis
				end
		end
		
		if		type(CaseId) ~= "number" and CaseId ~= nil then
				print("The CaseId has to be a number or nil")
				return	"The CaseId has to be a number or nil"
		end
		
		local		Player							=		PLAYERS:GetPlayerByUserId(UserId)
		if		Player then
				return	self:MarkAsUnbannedInBanland(Player, CaseId)
		end
		
		local		Records							=		Settings:GetPlayerDataMethod(UserId)
		if		not Records then
				return	"Error: Unban not successful. Couldn't load player data."
		end
		assert(type(Records) == "table", "The GetPlayerDataMethod has to return a table for the module to store data.")
		--		Rückwärtskompatibilität sichern 🙄
		if		not Records.Records then
				Records							=		{
						Records					=		Records,
						Aktionen					=		{}
				}
		end
		
		local		GotUnbanned							=		false
		
		if		CaseId == nil then
				if		DeleteRecord then
						Records.Records				=		{}
				
						--		Falls bereits eine UnbanAllCases Aktion gescheduled ist, keine weitere anlegen
						for		_, Inhalt in Records.Aktionen do
								if		Inhalt.Aktion == "UnbanAllCases" or
										Inhalt.Aktion == "UnbanAndRemoveAllCases" then
										
										return	"All records of " .. tostring(PlayerNameOrId) .. " have been deleted."
								end
						end
						
						--		Schedule Action Limit
						if		#Records.Aktionen >= MaxScheduledActions -1 then
								--		This limit is nessesary because for every action the player will get teleported on join and it is be a terrible experience to be stuck in an infinite teleport loop.
								return	"There are already too many scheduled actions for that player. They must join the game first."
						end
						
						--		Aktion schedulen
						table.insert(Records.Aktionen,{
								Aktion			=		"UnbanAndRemoveAllCases"
						})
						
						GotUnbanned					=		true
				else
						
						local		AlreadyMarkedForUnbanAllCases	=	false
						for		CaseId, Record in Records.Records do
								if		Record.Aktiv == false then continue end
								Record.Aktiv		=		false
								--Record.Type					=		nil
								GotUnbanned			=		true
								
								if		UserId < 0 then continue end -- In der Testumgebung ist sowas echt nervig
								if		AlreadyMarkedForUnbanAllCases then continue end

								--		Schedule Action Limit
								if		#Records.Aktionen >= MaxScheduledActions -1 then
										--	This limit is nessesary because for every action the player will get teleported on join and it is be a terrible experience to be stuck in an infinite teleport loop.
										return	"There are already too many scheduled actions for that player. They must join the game first."
								end
								
								--		Aktion schedulen
								table.insert(Records.Aktionen,{
										Aktion	=		"UnbanAllCases"
								})
								
								AlreadyMarkedForUnbanAllCases	=	true
						end
				end
				
		else
				if		DeleteRecord then
						--		Schedule Action Limit
						if		#Records.Aktionen >= MaxScheduledActions -1 then
								--	This limit is nessesary because for every action the player will get teleported on join and it is be a terrible experience to be stuck in an infinite teleport loop.
								return	"There are already too many scheduled actions for that player. They must join the game first."
						end
						
						--		Falls der Record oder alle Records bereits zum entbannen gescheduled sind, abbrechen.
						for		_, Aktion in Records.Aktionen do
								if		Aktion.Aktion == "UnbanAndRemoveAllCases" or
										Aktion.Aktion == "UnbanAllCases" or
										Aktion.Aktion == "UnbanAndRemove" and Aktion.CaseId == CaseId then
						
										return	"The record is already scheduled to get deleted."
								end
						end
						
						--		Record Löschen
						Records.Records[CaseId]			=		nil
						
						--		Aktion schedulen
						table.insert(Records.Aktionen,{
								Aktion			=		"UnbanAndRemove",
								CaseId			=		tostring(CaseId)
						})
						
						GotUnbanned					=		true
						
				else
						
						local		Record			=		Records.Records[CaseId]
						if		not Record then
								return	"Error: Record not found for "..PlayerNameOrId
						end
						if		Record.Aktiv == false then 
								return	"Error: The Record is already inactive. Player: "..PlayerNameOrId.." CaseId: "..CaseId 	
						end
						Record.Aktiv				=		false
						GotUnbanned					=		true
						
						if		UserId < 0 then return end -- In der Testumgebung ist sowas echt nervig
						
						Record.Aktion				=		"Unban"	
				end				
		end
		
		if		not GotUnbanned then
				return	"Error: "..PlayerNameOrId.." is not banned and can't get unbanned."
		end

		local		Success							=		Settings:SetPlayerDataMethod(UserId, Records)
		if		Success == false then
				return	"Saving failed. Unban unsuccessful."
		end
		
		--		Offline Command auf anderen Servern durchsetzen ist nicht erforderlich, da der Spieler ja aktuell gebannt sein müsste		
		
		return	tostring(PlayerNameOrId) .. " got unbanned."
end

--		Deactivates the Roblox Ban API ban for an offline player by name or UserId.
function	Banland:UnbanAltAccounts(PlayerNameOrId : string | number)
		if		RUN:IsStudio() then
				print("Can't use the UnbanAltAccounts Method.\nThe Roblox Ban API does not work in Roblox Studio :/")
				return	"Can't use the UnbanAltAccounts Method.\nThe Roblox Ban API does not work in Roblox Studio :/"
		end
		
		if		not Settings.AllowOfflineCommands then
				print("Offline commands are disabled!")
				return	"Offline commands are disabled!"
		end
		
		if		type(PlayerNameOrId) ~= "string" and type(PlayerNameOrId) ~= "number" then
				print("PlayerNameOrId needs to be a string or number.")
				return	"PlayerNameOrId needs to be a string or number."
		end
		
		if		Debounce[PlayerNameOrId] then return "Commands on this player are on debounce." end
		task.spawn(function()
				Debounce[PlayerNameOrId]				=		true
				task.wait(2)
				Debounce[PlayerNameOrId]				=		nil
		end)
		
		local		UserId							=		tonumber(PlayerNameOrId)
		if		not UserId then
				local		Erfolg, Ergebnis				=		pcall(function()
						return	PLAYERS:GetUserIdFromNameAsync(PlayerNameOrId)
				end)
				
				if		not Erfolg then
						return	"Unban was not successful. Was not able to get the UserId of '"..PlayerNameOrId.."'"
				else
						
						UserId					=		Ergebnis
				end
		end
			
		--		BanConfig erstellen
		local		UnbanInfo							=		{}
				UnbanInfo.UserIds						=		{UserId}
				UnbanInfo.ApplyToUniverse				=		true
		
	
		local		Success, Response						=		pcall(function()
				return	PLAYERS:UnbanAsync(UnbanInfo)
		end)

		if		Success == false then
				return	"Unban unsuccessful. "..Response
		end
		
		--		Offline Command auf anderen Servern durchsetzen ist nicht erforderlich, da der Spieler ja aktuell gebannt sein müsste
		
		return	tostring(PlayerNameOrId) .. " and their alt accounts got unbanned."
end

--		Returns the criminal records for the player
function	Banland:GetRecords(PlayerOrNameOrId : Player | string | number)
		if		type(PlayerOrNameOrId) == "number" or type(PlayerOrNameOrId) == "string" then
				if		not Settings.AllowOfflineCommands then 
						warn("Offline Commands are disabled!")
						return	"Target not found on this server and offline commands are disabled!"
				end
				
				if		Debounce[PlayerOrNameOrId] then return "Commands on this player are on debounce." end
				task.spawn(function()
						Debounce[PlayerOrNameOrId]		=		true
						task.wait(2)
						Debounce[PlayerOrNameOrId]		=		nil
				end)
				
				local		UserId					=		tonumber(PlayerOrNameOrId)
				if		not UserId then
						local		Erfolg, Ergebnis		=		pcall(function()
								return	PLAYERS:GetUserIdFromNameAsync(PlayerOrNameOrId)
						end)
						
						if		not Erfolg then
								return	"GetRecords was not successful. Was not able to get the UserId of '"..PlayerOrNameOrId.."'"
						else
								
								UserId					=		Ergebnis
						end
				end

				local		Player							=		PLAYERS:GetPlayerByUserId(UserId)
				if		Player then
						return	RecordsCache[Player].Records
				end
				
				local		Records							=		Settings:GetPlayerDataMethod(UserId)
				if		not Records then
						return	"Error: Couldn't load player data."
				end
				assert(type(Records) == "table", "The GetPlayerDataMethod has to return a table for the module to store data.")
				--		Rückwärtskompatibilität sichern 🙄
				if		not Records.Records then
						Records							=		{
								Records					=		Records,
								Aktionen					=		{}
						}
				end
				
				return	Records.Records		
		end
		
		return	RecordsCache[PlayerOrNameOrId].Records
end

--		Returns a list of all Roblox Ban API Records for a player
function	Banland:GetAltAccountBanRecords(PlayerOrNameOrId : Player | string | number)
		local		UserId							=		nil
		if		type(PlayerOrNameOrId) == "number" or type(PlayerOrNameOrId) == "string" then
				if		not Settings.AllowOfflineCommands then 
						warn("Offline Commands are disabled!")
						return	"Target not found on this server and offline commands are disabled!"
				end
				
				if		Debounce[PlayerOrNameOrId] then return "Commands on this player are on debounce." end
				task.spawn(function()
						Debounce[PlayerOrNameOrId]		=		true
						task.wait(2)
						Debounce[PlayerOrNameOrId]		=		nil
				end)
				
				UserId							=		tonumber(PlayerOrNameOrId)
				if		not UserId then
						local		Erfolg, Ergebnis		=		pcall(function()
								return	PLAYERS:GetUserIdFromNameAsync(PlayerOrNameOrId)
						end)
						
						if		not Erfolg then
								return	"GetRecords was not successful. Was not able to get the UserId of '"..PlayerOrNameOrId.."'"
						else
								
								UserId			=		Ergebnis
						end
				end
			
		else
				UserId							=		PlayerOrNameOrId.UserId
		end
		
		local		Erfolg, BanHistory					=		pcall(function()
				return	PLAYERS:GetBanHistoryAsync(UserId)
		end)
		
		if		not Erfolg then
				return	"Was not able to retrieve the AltAccount BanRecords. "..BanHistory
		end
		
		local		Records					=		{}
		
		while		true do
				table.insert(Records, BanHistory:GetCurrentPage()[1])
				if		BanHistory.IsFinished then break end
				
				BanHistory:AdvanceToNextPageAsync()
		end
		
		return	Records
end

--		For requests for the right to erasure
function	Banland:WipePlayerData(PlayerOrNameOrId : Player | string | number)
		if		type(PlayerOrNameOrId) == "number" or type(PlayerOrNameOrId) == "string" then
				if		not Settings.AllowOfflineCommands then 
						warn("Offline Commands are disabled!")
						return	"Target not found on this server and offline commands are disabled!"
				end
				
				if		Debounce[PlayerOrNameOrId] then return "Commands on this player are on debounce." end
				task.spawn(function()
						Debounce[PlayerOrNameOrId]		=		true
						task.wait(2)
						Debounce[PlayerOrNameOrId]		=		nil
				end)
				
				local		UserId					=		tonumber(PlayerOrNameOrId)
				if		not UserId then
						local		Erfolg, Ergebnis		=		pcall(function()
								return	PLAYERS:GetUserIdFromNameAsync(PlayerOrNameOrId)
						end)
						
						if		not Erfolg then
								return	"WipePlayerData was not successful. Was not able to get the UserId of '"..PlayerOrNameOrId.."'"
						else
								
								UserId					=		Ergebnis
						end
				end

				local		Player							=		PLAYERS:GetPlayerByUserId(UserId)
				if		Player then
						return	self:WipePlayerData(Player)
				end
				
				--		Spieler kicken, falls er auf einem anderen Server online sein sollte. Eigentlich soll dieser Command aber nur an UserIds von Spielern genutzt werden, die ihren Roblox Account löschen lassen haben
				task.defer(function()
						MESSAGE:PublishAsync("BanlandModul_OfflineCommands", {UserId = UserId, Aktion = "Kick", Argumente = {"Someone wiped your Banland Data. This method was originally intended to be used on UserIds of players who deleted their accounts but here we are…"}})
				end)
		
				return	Settings:WipePlayerDataMethod(UserId)	
		end
		
		PlayerOrNameOrId:Kick("Someone wiped your Banland Data. This method was originally intended to be used on UserIds of players who deleted their accounts but here are you…")
		
		return	Settings:WipePlayerDataMethod(PlayerOrNameOrId.UserId)
end


for		_, Spieler in PLAYERS:GetPlayers() do
		coroutine.wrap(PlayerAdded)(Spieler)
end
PLAYERS.PlayerRemoving:Connect(PlayerRemoving)
PLAYERS.PlayerAdded:Connect(PlayerAdded)
TELEPORT.TeleportInitFailed:Connect(HandleFailedTeleport)
MESSAGE:SubscribeAsync("BanlandModul_OfflineCommands", OfflineCommandListener)

--		Owner getten
task.spawn(GetOwner)


return	Banland