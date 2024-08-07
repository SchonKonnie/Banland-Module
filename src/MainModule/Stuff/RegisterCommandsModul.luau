--		Modul, mit dem ich TextChatService Commands registrieren kann
local		PLAYERS									=		game:GetService("Players")
local		RUN										=		game:GetService("RunService")
local		TCS										=		game:GetService("TextChatService")
if		TCS.ChatVersion ~= Enum.ChatVersion.TextChatService then
		print("This experience does not use the TextChatService.\nChat commands will not get registered.")
end

local		IsStudio									=		RUN:IsStudio() -- For Debug Prints

local		Banland									=		require(script.Parent.Parent)
local		Settings									=		require(script.Parent.Parent.Settings)
local		SystemMessageModul							=		require(script.Parent.SystemMessageModul)

local		TextChatCommands								=		TCS:WaitForChild("TextChatCommands")

local		UserIdCache									=		{}
local		RegisterCommandsModul							=		{}

--		Kein Plan, was ich damals gemacht habe aber es funktioniert…
local		function	NeueMatrix(N, M)
		local		Matrix							=		table.create(N, table.create(M, 0))
				Matrix[0]							=		table.create(M, 0)
				
		for		_, i in Matrix do
				i[0]								=		0
		end
		
		return	Matrix
end

local		function	LevenshteinDistanz(String1: string, String2: string): number
		local		Zeilen							=		string.len(String1) 
		local		Spalten							=		string.len(String2) 
		
		if		Zeilen == 0 then
				return	Spalten
				
		elseif	Spalten == 0 then 
				return	Zeilen
			
		elseif	String1 == String2 then -- lol
				return	0
		end
		
		local		Matrix							=		NeueMatrix(Zeilen, Spalten)
		
		-- Matrix initialisieren
		for		i = 1, Zeilen do
				Matrix[i][0]						=		i
		end
		for		j = 1, Zeilen do
				Matrix[0][j]						=		j
		end
		
		for		i = 1, Zeilen do
				for		j = 1, Spalten do
						if		(String1:byte(i) == String2:byte(i)) then
								-- wenn's passt
								Matrix[i][j]		=		Matrix[i-1][j-1]
							
						else
								local		Einsetzen	=		Matrix[i][j-1] + 1
								local		Entfernen	=		Matrix[i - 1][j] + 1
								local		Ersetzen	=		Matrix[i - 1][j - 1] + 1

								Matrix[i][j] = math.min(Einsetzen, Entfernen, Ersetzen)
						end
				end
		end
		return	Matrix[Zeilen][Spalten], Matrix
end

local		function	GetPlayerByName(Name : string, Caster : Player)
		if		not Name or Name == "me" then
				return	Caster
		
		elseif	Name == "random" then
				return	PLAYERS:GetPlayers()[math.random(1, #PLAYERS:GetPlayers())]
		end
		
		local		DisplaynameMatch, Count					=		nil, 0
		
		local		Ergebnis, Ergebnis2
		local		DistanzName, DistanzDisplayname			=		30, 30
		local		isMatch1, matches1, isMatch2, matches2		=		false, 0, false, 0
		for		_, Spieler in PLAYERS:GetPlayers() do
				if		string.lower(Spieler.Name) == string.lower(Name) then
						return	Spieler
				end
				if		string.lower(Spieler.DisplayName) == string.lower(Name) then
						DisplaynameMatch				=		Spieler
						Count						+=		1
				end
				
				local		Distanz					=		LevenshteinDistanz(string.lower(Spieler.Name), Name)
				local		Distanz2					=		LevenshteinDistanz(string.lower(Spieler.DisplayName), Name)

				local		ThisIsMatch1				=		false
				local		ThisIsMatch2				=		false
				
				if		Distanz <= string.len(Spieler.Name) * .4 and
						string.find(string.lower(Spieler.Name), Name) then 
						matches1					+=		1
						ThisIsMatch1				=		true
				end
				if		Distanz2 <= string.len(Spieler.DisplayName) * .4 and
						string.find(string.lower(Spieler.DisplayName), Name) then 
						matches2					+=		1
						ThisIsMatch2				=		true
				end
				
				if		Distanz < DistanzName then
						if		ThisIsMatch1 then
								isMatch1			=		true
						else
								isMatch1			=		false
						end
						
						Ergebnis					=		Spieler
						DistanzName					=		Distanz
					
				elseif	Distanz == DistanzName then -- Gleiche Distanz == uneindeutig und das ist nicht gut
						isMatch1					=		false
						Ergebnis					=		nil
				end
				
				if		Distanz2 < DistanzDisplayname then
						if		ThisIsMatch2 then
								isMatch2			=		true
						else
								isMatch2			=		false
						end
						
						Ergebnis2					=		Spieler
						DistanzDisplayname			=		Distanz2
					
				elseif	Distanz2 == DistanzDisplayname then -- Gleiche Distanz == uneindeutig und das ist nicht gut
						isMatch2					=		false
						Ergebnis2					=		nil	
				end
		end
		
		if		Count == 1 then -- DisplaynameMatch nur dann returnen, wenn es nur einen Spieler mit diesem DisplayName auf dem Server gibt
				return	DisplaynameMatch
		end
		
		if		Ergebnis and DistanzName < DistanzDisplayname + 2 and (
				DistanzName <= string.len(Ergebnis.Name) * .3 or
				isMatch1 and matches1 == 1) then
				
				return	Ergebnis
			
		elseif	Ergebnis2 and DistanzDisplayname < DistanzName and (
				DistanzDisplayname <= string.len(Ergebnis2.DisplayName) * .3 or
				isMatch2 and matches2 == 1) then
				
				return	Ergebnis2
		end
end

local		function	GetUserId(NameOrUserId : string)
		if		not Settings.AllowOfflineCommands then 
				warn("Offline Commands are disabled!")
				return	"Target not found on this server and offline commands are disabled!"
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
						return	false, "UserId not found for '"..NameOrUserId.."'"
						
				else
						UserIdCache[NameOrUserId]		=		Ergebnis
						return	Ergebnis
				end
		end
		
		return	UserId
end

local		function	GetArgsAndOfflineTargetId(unfilteredText : string)
		local 	Words								=		string.split(unfilteredText, " ")
		
		local		TargetName							=		Words[2]
		local		TargetId, Response					=		GetUserId(TargetName)
		if		not TargetId then
				return	nil, nil, TargetName, Response
		end
		
		table.remove(Words, 1)
		table.remove(Words, 1)
		
		return	Words, TargetId, TargetName
end
local		function	GetArgsAndOnlineTarget(unfilteredText : string, Caster : Player)
		local 	Words								=		string.split(unfilteredText, " ")
		
		local		Target							=		if not Words[2] then Caster else GetPlayerByName(string.lower(Words[2]), Caster)
		
		table.remove(Words, 1)
		table.remove(Words, 1)
		
		return	Words, Target
end


function	RegisterCommandsModul:RegisterOfflineCommand(Name : string, PrimAlias : string, SecAlias : string, Callback : (Player, number, any) -> (), RequiredBanPowerDiff : number?)
				RequiredBanPowerDiff					=		RequiredBanPowerDiff or 1
				
		local		Command							=		Instance.new("TextChatCommand")
				Command.Name						=		"Banland_"..Name
				Command.AutocompleteVisible				=		true
				Command.PrimaryAlias					=		"/"..string.lower(PrimAlias)
				Command.SecondaryAlias					=		"/"..string.lower(SecAlias)
				Command.Parent						=		TextChatCommands
				Command.Triggered:Connect(function(originTextSource: TextSource, unfilteredText: string)
						local		Spieler			=		PLAYERS:GetPlayerByUserId(originTextSource.UserId)
						if		not Spieler then return end
						
						--SystemMessageModul:Send(Spieler, "Calling the "..PrimAlias.." offline command.\nThis might take a while…")
						
						local		BanPower			=		if Spieler.UserId == Banland.Owner then 9999 else Settings:GetBanPower(Spieler)
						if		not BanPower or BanPower <= 0 then
								SystemMessageModul:Send(Spieler, "You don't have the permission to use this command.")
								if	not IsStudio then return end
								print(Spieler.Name.." does not have enough BanPower for the ".. Name .. " command.")
								return
						end
						
						local		ArgTable, TargetId, TargetName, Response =	GetArgsAndOfflineTargetId(unfilteredText)
						if		not TargetId then
								SystemMessageModul:Send(Spieler, Response or "UserId for target '"..TargetName.."' could not be found.")
								return
						end
						
						local		TargetPower			=		Settings:GetBanPower(TargetId)
				
						if		TargetPower and BanPower < TargetPower + RequiredBanPowerDiff then
								SystemMessageModul:Send(Spieler, "You don't have enough BanPower to use this command on ".. TargetName ..".\nYour BanPower: "..BanPower.." Their BanPower: "..TargetPower..(if RequiredBanPowerDiff then " Required difference: ".. RequiredBanPowerDiff else ""))
								if	not IsStudio then return end
								print(Spieler.Name.." does not have enough BanPower to use the " .. Name .." command on " .. TargetName,"\nBanPower:", BanPower,"TargetPower:", TargetPower, "Required difference:", RequiredBanPowerDiff)
								return
						end
						
						Callback(Spieler, TargetId, table.unpack(ArgTable))
				end)
end
function	RegisterCommandsModul:RegisterCommandOnTarget(Name : string, PrimAlias : string, SecAlias : string, Callback : (Player, Player, any) -> (), RequiredBanPowerDiff : number?, TargetCanBeOffline : boolean?)
				RequiredBanPowerDiff					=		RequiredBanPowerDiff or 1
				TargetCanBeOffline					=		if TargetCanBeOffline == true then true else false
		
		local		Command							=		Instance.new("TextChatCommand")
				Command.Name						=		"Banland_"..Name
				Command.AutocompleteVisible				=		true
				Command.PrimaryAlias					=		"/"..string.lower(PrimAlias)
				Command.SecondaryAlias					=		"/"..string.lower(SecAlias)
				Command.Parent						=		TextChatCommands
				Command.Triggered:Connect(function(originTextSource: TextSource, unfilteredText: string)
						local		Spieler			=		PLAYERS:GetPlayerByUserId(originTextSource.UserId)
						if		not Spieler then return end
						
						--SystemMessageModul:Send(Spieler, "Calling the "..PrimAlias.." command.\nThis might take a while…")
						
						local		BanPower			=		if Spieler.UserId == Banland.Owner then 9999 else Settings:GetBanPower(Spieler)
						if		not BanPower or BanPower <= 0 then
								SystemMessageModul:Send(Spieler, "You don't have the permission to use this command.")
								if	not IsStudio then return end
								print(Spieler.Name.." does not have enough BanPower for the ".. Name .. " command.")
								return
						end
						
						local		ArgTable, Target		=		GetArgsAndOnlineTarget(unfilteredText, Spieler)
	
						if		not Target then
								if		TargetCanBeOffline == true then
										local		ArgTable, TargetId, TargetName, Response =	GetArgsAndOfflineTargetId(unfilteredText)
										if		not TargetId then
												SystemMessageModul:Send(Spieler, Response or "UserId for target '"..TargetName.."' could not be found.")
												return
										end
										
										local		TargetPower			=		if TargetId == Banland.Owner then 9999 else Settings:GetBanPower(TargetId)
				
										if		TargetPower and BanPower < TargetPower + RequiredBanPowerDiff then
												SystemMessageModul:Send(Spieler, "You don't have enough BanPower to use this command on ".. TargetName ..".\nYour BanPower: "..BanPower.." Their BanPower: "..TargetPower..(if RequiredBanPowerDiff then " Required difference: ".. RequiredBanPowerDiff else ""))
												if	not IsStudio then return end
												print(Spieler.Name.." does not have enough BanPower to use the " .. Name .." command on " .. TargetName,"\nBanPower:", BanPower,"TargetPower:", TargetPower, "Required difference:", RequiredBanPowerDiff)
												return
										end
										
										Callback(Spieler, TargetId, table.unpack(ArgTable))
										return
								end
								
								SystemMessageModul:Send(Spieler, "Target not found on this server.")
								return
						end
						
						local		TargetPower			=		Settings:GetBanPower(Target)
	
						if		TargetPower and BanPower < TargetPower + RequiredBanPowerDiff then
								SystemMessageModul:Send(Spieler, "You don't have enough BanPower to use this command on ".. Target.Name ..".\nYour BanPower: "..BanPower.." Their BanPower: "..TargetPower..(if RequiredBanPowerDiff then " Required difference: ".. RequiredBanPowerDiff else ""))
								if	not IsStudio then return end
								print(Spieler.Name.." does not have enough BanPower to use the " .. Name .." command on " .. Target.Name,"\nBanPower:", BanPower,"TargetPower:", TargetPower, "Required difference:", RequiredBanPowerDiff)
								return
						end
						
						Callback(Spieler, Target, table.unpack(ArgTable))
				end)
end


return	RegisterCommandsModul