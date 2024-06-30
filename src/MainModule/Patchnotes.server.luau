--disable

-- 	PATCHNOTES

--[[

##### Version 4.2	##########################################################


•	Added the new commands to the Read Me plis 🥺 file
•	The module is now also available on GitHub in case its getting
	automoderated again: https://github.com/SchonKonnie/Banland-Module
•	The module will now cancel itself if it is required outside
	of a playtest or required by a client


##### Version 4.1	##########################################################

•	Added the BanAltAccounts commands and method to use the Roblox Ban
	API with their alt account detection
	(It bans the player + alt accounts)
•	Added the OfflineBanAltAccounts command and method
•	Added the UnbanAltAccounts command and method
•	Added the GetAltAccountBanRecords method
•	Added the ShowAltAccountBanRecords commands
•	Fixed a minor bug that might happen when methods get invoked with
	wrong variable types

##### Version 4.0	##########################################################

Note:
	I was forced to push out v4.0 earlier than expected.
	I tested all TCS Commands as exessive as I could but there might
	still be bugs.
	Some features that where planned for this version will be
	delayed as I had to shift priorities.
	
•	Added the WipePlayerData command and method for right of erasure
	requests
•	Added the OfflinePermban command and method
•	Added an OfflineRemoveRecord method
•	Added offline support for the RemoveRecord TextChatService command
•	Added a 'DeleteRecord' option as third parameter to the Unban
	command and method
•	Added feedback prints when activating commands to show that its
	working, even if the command yields a bit longer
•	Fixed a bug where the HD Admin Ban command would print nothing as
	result
•	Fixed a bug where offline commands could yield forever when the player
	doesn't exist
•	Updated the TeleportScreenGui to animate the text while
	loading
•	Fixed a small vulnerability that could have prevented the module 
	from working in special cases
•	Changed the data structure and added backwards compatibility checks 😰

##### Version 3.3	##########################################################

•	Fixed a bug where the blacklist did not work

##### Version 3.2	##########################################################

•	Fixed a bug where the default buyouts might not be transmitted

##### Version 3.1	##########################################################

•	Fixed a bug where the first word of the ban reason might cut off
	
##### Version 3.0	##########################################################

•	Added Patchnotes
•	Removed Settings.DefaultSendToBanland
•	Added Third Argument to "RemoveRecord": "DeleteRecord"
	–	This option lets you decide if you want the record
		to also be removed of your own DataStore.
•	Added Settings.DeleteRecordDefault
•	Unban and ShowRecords won't require the target to have less
	Banpower anymore which makes them usable with HD Admin

############################################################################

]]--