--		Initiates the module

--		If Testumgebung, dann nicht
if		script.Parent.Parent.Parent.Name == "Current" or script.Parent.Parent.Parent.Name == "Archiv" then return end

local		Banland									=		require(script.Parent.Parent)
local		Settings									=		require(script.Parent.Parent.Settings)

--		Settings richtigstellen
if		type(Settings.BanlandPlaceId) ~= "number" then
		warn("The BanlandPlaceId has to be a number.")
		Settings.BanlandPlaceId							=		6339756876
end
if		type(Settings.TpTriesUntilKick) ~= "number" then
		warn("The TpTriesUntilKick setting has to be a number.")
		Settings.TpTriesUntilKick						=		6
else
		Settings.TpTriesUntilKick						=		math.clamp(Settings.TpTriesUntilKick, 1, 20)
end
if		type(Settings.DefaultBanDuration) ~= "number" and type(Settings.DefaultBanDuration) ~= "string" then
		warn("The default ban duration has to be a string or a number.")
		Settings.DefaultBanDuration						=		"15min"
end
if		Settings.DefaultIncrementFactor ~= nil and type(Settings.DefaultIncrementFactor) ~= "number" then
		warn("The increment factor has to be a positive number or nil.")
		Settings.DefaultIncrementFactor					=		nil
else
		Settings.DefaultIncrementFactor					=		math.clamp(Settings.DefaultIncrementFactor, 0, 10)
end
if		type(Settings.DefaultBuyouts) ~= "boolean" and type(Settings.DefaultBuyouts) ~= "number" then
		warn("The DefaultBuyouts setting has to be a boolean or a number.")
		Settings.DefaultBuyouts							=		true
end
if		type(Settings.ShowRecordsDefault) ~= "string" or string.lower(Settings.ShowRecordsDefault) ~= "all" and string.lower(Settings.ShowRecordsDefault) ~= "inactive" and string.lower(Settings.ShowRecordsDefault) ~= "active" then
		warn("The ShowRecordsDefault setting has to be 'all' or 'active' or 'inactive'.")
		Settings.ShowRecordsDefault						=		"All"
end
if		type(Settings.DeleteRecordDefault) ~= "boolean" then
		warn("The DeleteRecordDefault setting has to be a boolean.")
		Settings.DeleteRecordDefault						=		false
end
if		type(Settings.GetPlayerDataMethod) ~= "function" then
		warn("The GetPlayerDataMethod setting has to be a function.")
		Settings.GetPlayerDataMethod						=		function(self, UserId : number)
				local		DataStore					=	self.DataStore or require(script.Parent.DataStore)
						self.DataStore				=	DataStore
						
				return	DataStore:GetPlayerData(UserId)
		end
end
if		type(Settings.SetPlayerDataMethod) ~= "function" then
		warn("The SetPlayerDataMethod setting has to be a function.")
		Settings.SetPlayerDataMethod						=		function(self, UserId : number, Data : any)
				local		DataStore					=	self.DataStore or require(script.Parent.DataStore)
						self.DataStore				=	DataStore
						
				return	DataStore:SetPlayerData(UserId, Data)
		end
end
if		type(Settings.UseGlobalBlacklist) ~= "boolean" then
		warn("The UseBlacklist setting has to be a boolean.")
		Settings.UseGlobalBlacklist						=		true
end
if		type(Settings.CheckGroups) ~= "boolean" then
		warn("The CheckGroups setting has to be a boolean.")
		Settings.CheckGroups							=		true
end
if		type(Settings.CheckGroups) ~= "boolean" then
		warn("The CheckGroups setting has to be a boolean.")
		Settings.CheckGroups							=		true
end
if		type(Settings.OverwriteHDAdmin) ~= "boolean" then
		warn("The OverwriteHDAdmin setting has to be a boolean.")
		Settings.OverwriteHDAdmin						=		true
end