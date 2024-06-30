local		Settings				=		{
		
		OverwriteHDAdmin			=		true,
		--	If set to true the module will search for HD Admin and replace the ban command.
		--	If you don't use HD Admin, nothing will happen.

		DefaultBanDuration		=		"10min",
		--	The default ban duration if nothing else is set.
		--	(I don't recommend large durations because it is actual ingame time they have to spend in banland
		--	and the ban duration increases exponentually if you don't set the next setting to 0 or nil)
		
		DefaultIncrementFactor		=		.5,
		--	For every historic ban the duration of the new one will be incremented by this factor of its own duration exponentually.
		--	Set to 0 or nil to disable this feature.
		
		DefaultBuyouts			=		true,	
		--	Set this to false if you don't want to allow the banned player to pay robux to get unbanned early.
		--	You can also set a GamepassId for a instant buyout.

		BanPowerTable			=		{
			ExampleMod			=		1,
			Example_Mod			=		1,
			
			ExampleHeadMod		=		2,
			Example_HeadMod		=		2,
			
			Example_Admin		=		3,
			
			Example_Owner		=		4,
			
			[-1]				=		2,	-- UserId of Player1 while playtesting on a local Server
			[-2]				=		1	-- UserId of Player2 while playtesting on a local Server
		},
		--	A table of names and UserIds and corresponding BanPower values. Filled with examples. (Better remove them unless you want them to have BanPower)
		--	BanPower determines who can use TextChatService commands. You can only ban players with less BanPower than yourself.
		--	You can edit this table or delete this setting entirely and overwrite the "GetBanPower" method.
		--	Do not set BanPower values too high. The experience owner always has 9999 BanPower by default.

		ShowRecordsDefault		=		"All",
		--	All, Active or Inactive
		--	Specifies which cases should be printed out by default if the ShowRecords command is used without the third argument.

		DeleteRecordDefault		=		false,
		--	true or false
		--	If set to true the /RemoveRecord command will also delete the record in your datastore and not only in banland.

		Blacklist				=		{
			"ExamplePlayer",
			1234567890,
		},
		--	Array of names and UserIds of blacklisted players.
		--	Blacklisted players will always get sent to banland when they join, as long as they are on this list,
		--	regardless how much time they already spent there.
		
		
		GetBanPower				=		function(self, UserIdOrPlayer : number | Player) : number?				
				--		Check if it is a UserId or a Player (Not necessary if OfflineCommands ar disabled)
				if		type(UserIdOrPlayer) == "number" then --	Íts a UserId						
						--	Create a table to cache usernames
						if not self.NameCache then self.NameCache	= {} end
						
						--	Get the username of the player
						local		Success, Name = pcall(function()
								return	self.NameCache[UserIdOrPlayer] or game.Players:GetNameFromUserIdAsync(UserIdOrPlayer)
						end)
						--	If it does not work, then 😫
						if		not Success then return end
						
						--	Cache the name of the player
						self.NameCache[UserIdOrPlayer] = Name
						
						--	Return the BanPower or nil
						return	self.BanPowerTable[Name] or self.BanPowerTable[UserIdOrPlayer]					
						
				end
				
				--	Its a Player object
				
				--	Return the BanPower or nil
				return	self.BanPowerTable[UserIdOrPlayer.Name] or self.BanPowerTable[UserIdOrPlayer.UserId]
		end,
		--	This method has to return then BanPower (a number or nil) for any given UserId or Player.
		--	You can overwrite it, as long as the arguments stay the same and it still only returns numbers or nil.
		--	The method has to work with a Player object and a UserId (sorry but we cant get Player objects of offline players)
		--	EXCEPT: if you disable offline commands. In this case the method will never be used with a UserId.
		--	To be able to use any commands, the player needs at least 1 BanPower
		--	Players can only use commands on players with lower numbers.
		--	Do not return too high BanPower values. The experience owner always has 9999 BanPower by default.


		GetPlayerDataMethod				=		function(self, UserId : number)
				local		DataStore		=	self.DataStore or require(script.Parent.Stuff.DataStore)
						self.DataStore	=	DataStore
						
				return	DataStore:GetPlayerData(UserId)
		end,
		--	Change this method if you want this module to use your own DataStore stuff to cut down on the read limit use.
		--	The arguments have to stay the same!
		--	But do not return all player data but only a table where this module can save its entries!


		SetPlayerDataMethod				=		function(self, UserId : number, Data : any)
				local		DataStore		=	self.DataStore or require(script.Parent.Stuff.DataStore)
						self.DataStore	=	DataStore
						
				return	DataStore:SetPlayerData(UserId, Data)
		end,
		--	Change this method if you want this module to use your own DataStore stuff to cut down on the write limit use.
		--	The arguments have to stay the same!
		--	But do not let it overwrite all player data but only the table where this module can save its entries!
		--	The method has to return false if saving failed. The module will not attempt to call the method again
		--	by itsself but it will notify the user if it failed.
		
		
		WipePlayerDataMethod				=		function(self, UserId : number)
				local		DataStore		=	self.DataStore or require(script.Parent.Stuff.DataStore)
						self.DataStore	=	DataStore
						
				return	DataStore:SetPlayerData(UserId) -- Setting the data to nil, wipes it (with this method)
		end,
		--	Change this method if you also changed the other 2 methods above.
		--	The arguments have to stay the same!
		--	Its purpose is to delete the playerdata for the given UserId in case of a right of erasure request.
		--	If you implemented your own DataStore module, you can use this method to wipe the whole profile
		--	if you like or just delete the method. If you edit this method, make sure to return a boolean
		--	to tell if the action was successful.
		--	This will be most likely used on offline players. So if you put AllowOfflineCommands on false, there
		--	might be no use for this method.


		AllowOfflineCommands		=		true,
		--	Set this to false if your Set and Get PlayerDataMethods don not work with offline players.
		--	Note that the Unban Method will also not work and you have to handle unbans yourself.
		
		TpTriesUntilKick			=		6,
		--	After how many failed teleport attempts the module is supposed to kick the player instead.
		
		UseGlobalBlacklist		=		true,
		--	The module comes with a global blacklist made by us.
		--	If you don't want to punish those blacklisted people you can disable this setting.
		
		CheckGroups				=		true,
		--	The module also checks if the player is in a blacklisted group.
		--	This process may use up some API Limits so you can disable it separately.

		BanlandPlaceId			=		16545628485,
		--	The PlaceId of the Place where the player gets sent to. Don't change it unless you have a working place already! (TestPlaceId with more Bugs: 6339756876)

}


return	Settings
