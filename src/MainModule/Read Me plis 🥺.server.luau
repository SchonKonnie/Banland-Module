--disable

-- README

--[[

########	  INFO	########################


	This module provides an alternative method for banning players in Roblox games.
	Banned players are confined to a jail cell in a separate experience until their ban duration elapses.
	This approach aims to enhance the effectiveness of bans by restricting players' activities during the penalty period.
	Additionally, players have the option to purchase their freedom using Robux,
	although this feature can be disabled if desired.

	Please note that this module utilizes the TeleportService, which may trigger theTeleportInitFailed event
	if teleportation attempts fail.


########	  SETUP	########################

0.	The module needs to be parented to ServerScriptService.

1.	Enable third-party teleports in your game settings to ensure the proper functioning of the module.

2.	Customize the settings in the "Settings" module according to your preferences.
	Ensure to retain the default BanlandPlaceId setting unless you have an alternative location compatible with this module.

3.	Optionally (but recommended), implement custom DataStore methods to optimize performance and reduce DataStore calls.
	If implemented, you can delete the "DataStore" ModuleScript in the "Stuff" folder.

4.	Optionally, Customize the TeleportScreen GUI as desired while maintaining its name ("TeleportScreen") and
	parentage under the "Stuff" folder. Same goes for the BannedIndicator, this BillboardGUI will get put in
	banned characters while they're frozen and wait for the teleport.

5.	Optionally, deactivate the "OverwriteHDAdmin" setting or delete the "HDAdminOverwrite" Script in the "Stuff" folder
	if you prefer not to overwrite HD Admin ban commands or don't use HD Admin in your experience.

6.	Optionally, delete the "Commands" script in the "Stuff" folder to deactivate automatic registration of TextChatService commands.
	(They will only work, if you are using the TextChatService and not the LegacyChatService)

7.	Better don't try modifying the "Init" Script, "SystemMessageModul," or "MainModule" to avoid unintended consequences.



########	    TextChatService Commands    	########################

	If not deactivated, the module automatically registers the following commands in the TextChatService and/or HD Admin:
	Offline Commands can be deactivated if you don't want them to use API calls.
	Online Commands search for targeted players on the server, even if you don't type their name 100% right.
	
•	Ban [Target, Duration | Reason?, Reason?]:
	Bans the targeted player for the given or default duration and reason.
	Examples:	/Ban PlayerName			(default duration, no reason)
			/ban UserId	because uhhhm	(default duration, reason: "because uhhhm")			
			/ban PlayerName 12m10s		(ban for 12m 10s, no reason)
			/ban UserId 500			(ban for 500 seconds)
			/ban UserId 1d good reason	(ban for 1 day, reason: "good reason")

•	BanAltAccounts [Target, Duration | Reason?, Reason?]:
	Uses the Roblox Ban API to ban a player including their detected alt accounts.
	Examples:	/BanAltAccounts PlayerName			(default duration, no reason)
			/AltAccountBan UserId	because uhhhm	(default duration, reason: "because uhhhm")			
			/BanAltAccounts PlayerName 12m10s		(ban for 12m 10s, no reason)
			/BanAltAccounts UserId 500			(ban for 500 seconds)
			/AltAccountBan UserId 1d good reason	(ban for 1 day, reason: "good reason")

•	Kick [Target, Reason?]:
	Kicks the targeted player from the server.
	Examples:	/Kick PlayerName
			/Kick UserId good reason	
			
•	VisitBanland [Target]:
	Teleports the targeted player (or yourself) to banland.
	Examples:	/VisitBanland PlayerName
			/VisitBanland UserId 	
	
•	PermBan [Target, Reason?]:
	Bans the targeted player permanently.
	Examples:	/PermBan PlayerName
			/permban UserId good reason	

•	ShowRecords [Target, ActiveOrInactive?]:
	Prints the criminal records of the targeted player your local chat.
	Also works with offline players.
	Examples:	/ShowRecords PlayerName Active	(prints active records)
			/showrecords UserId Inactive		(prints inactive records)
			/Records PlayerName			(prints both All)
	
•	ShowAltAccountBanRecords [Target]:
	Prints the Roblox Ban API records of the targeted player your local chat.
	Also works with offline players.
	Examples:	/ShowRecords PlayerName
			/AltAccountBanRecords UserId

•	Unban [TargetNameOrId, CaseId | "all"?, DeleteRecord]:
	Unbans the targeted player. 
	To also completely delete the record in your DataStore and in banland, use true as third argument.
	!Offline Command!
	Examples:	/Unban PlayerName				(Deactivates all records)
			/unban UserId 1				(Deactivates the record with the CaseId 1)
			/unban UserId 12 true			(Deletes with the CaseId 12 in your database and in banland)
			/unban UserId all true			(Deletes all records your database and in banland)

•	UnbanAltAccounts [TargetNameOrId]:
	Unbans the targeted player with the Roblox Ban API. 
	!Offline Command!
	Examples:	/UnbanAltAccounts PlayerName
			/AltAccountUnban UserId

•	OfflineBan [TargetNameOrId, Duration? | Reason?, Reason?]:
	Bans the targeted player for the given or default duration even if they're offline.
	!Offline Command!
	Examples:	/OfflineBan PlayerName			(default duration)
			/banoffline UserId 1w			(1 week)
			/banoffline PlayerName 1h Reason	(1 hour + given reason)
			/banoffline UserId Reason		(default duration + given reason)

•	OfflineBanAltAccounts [TargetNameOrId, Duration? | Reason?, Reason?]:
	Bans the targeted player with the Roblox Ban API for the given or default duration even if they're offline.
	!Offline Command!
	Examples:	/OfflineBanAltAccounts PlayerName			(default duration)
			/OfflineBanAltAccounts UserId 1w			(1 week)
			/AltAccountOfflineBan PlayerName 1h Reason	(1 hour + given reason)
			/AltAccountOfflineBan UserId Reason			(default duration + given reason)
	
•	OfflinePermBan [TargetNameOrId, Reason?]:
	Permanently bans the targeted player for the given reason even if they're offline.
	!Offline Command!
	Examples:	/OfflinePermBan PlayerName
			/permbanoffline UserId Reason	
	
•	RemoveRecord [Target, CaseId | "all", Delete]:
	Teleport the targeted player to banland to remove the record from their criminal history there. 
	To also delete the record in your DataStore, use true as third argument or set the DeleteRecordDefault setting to true.
	Also works with offline players.
	Examples:	/RemoveRecord PlayerName 2		(Removes the record with the CaseId 2)
			/remove UserId all			(All records)
			/remove UserId 12 true			(Removes the record with the CaseId 2 and also deletes the enty here)


•	OnlineUnban [Target, CaseId?]:
	Teleport the targeted player to banland to mark them as unbanned.
	This might be useful, if you have unbanned them manually to also tell the banland, they don't belong in a jail cell anymore.
	Examples:	/MarkAsUnbanned PlayerName
			/OnlineUnban UserId 3			(Tells banland, their record with the CaseId 3 is inactive.)


########			    API   			########################

- [ ] BanPlayer
	- Player : Player
	- Duration : string | number  | nil
	- ReasonExternal : string?
		- A reason that is displayed to the player
	- ReasonInternal : string?
		- A reason that can only be viewed by mods
	- ResponsibleMod : string?
	- Buyouts : boolean | number | nil
		- If the player is allowed to buy his way out. GamepassId can be entered
	- IncrementFactor : number?
		- A factor by which the ban duration is automatically increased based on the criminal history. Values above 1 are very high and should not exceed 10.
		  
- [ ] BanAltAccounts
	- Player : Player
	- Duration : string | number | nil
	- ReasonExternal : string?
	- ReasonInternal : string?
	- ResponsibleMod : string?
		  
- [ ] OfflineBanPlayer
	- PlayerNameOrId : string | number
	- Duration : string | number | nil
	- ReasonExternal : string?
	- ReasonInternal : string?
	- ResponsibleMod : string?
	- Buyouts : boolean | number | nil
	- IncrementFactor : number?
	  
- [ ] OfflineBanAltAccounts
	- PlayerNameOrId : string | number
	- Duration : string | number | nil
	- ReasonExternal : string?
	- ReasonInternal : string?
	- ResponsibleMod : string?
	  
- [ ] PermbanPlayer
	- Player : Player
	- ReasonExternal : string?
	- ReasonInternal : string?
	- ResponsibleMod : string?
	  
- [ ] OfflinePermbanPlayer
	- PlayerNameOrId : string | number
	- ReasonExternal : string?
	- ReasonInternal : string?
	- ResponsibleMod : string?
	  
- [ ] VisitBanland
	- Player : Player
	- ResponsibleMod : string?
	  
- [ ] RemoveRecord
	- Player : Player
	- CaseId : number | "all"
	- DeleteRecord : boolean?
		- If the entry should also be deleted in the local DataStore
	  
- [ ] EditActiveRecord
	- Player : Player
	- Duration : string | number  | nil
	- ReasonExternal : string?
	- ReasonInternal : string?
	- ResponsibleMod : string?
	- Buyouts : boolean | number | nil
	- IncrementFactor : number?
	  
- [ ] OfflineRemoveRecord
	- PlayerNameOrId : string | number
	- CaseId : number | "all"
	- DeleteRecord : boolean?
	  
- [ ] MarkAsUnbannedInBanland
	- Player : Player
	- CaseId : number?
	  
- [ ] Unban
	- PlayerNameOrId : string | number
	- CaseId : number?
	- DeleteRecord : boolean?
	  
- [ ] UnbanAltAccounts
	- PlayerNameOrId : string | number
	  
- [ ] GetRecords
	- PlayerOrNameOrId : Player | string | number
	  
- [ ] GetAltAccountBanRecords
	- PlayerOrNameOrId : Player | string | number
	  
- [ ] WipePlayerData
	- PlayerOrNameOrId : Player | string | number
	
########	  CONTACT	########################
	
	--		STOP READING!!! THAT MAY NOT BE SUITABLE FOR YOUR EYES!
	
	--		I MEAN IT!

	local		WhoeverReadsThisReadMeComment : Player
	if		not table.find(game:GetService("PolicyService"):GetPolicyInfoForPlayerAsync(WhoeverReadsThisReadMeComment).AllowedExternalLinkReferences, "Discord") then
			return
	end	--	no pcall because its okay if this comment errors.
	
	For questions or suggestions, please join the Discord Server linked in the Based Trash Roblox group and open a support ticket.

]]
