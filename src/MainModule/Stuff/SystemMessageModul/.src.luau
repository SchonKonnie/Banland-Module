local		PLAYERS									=		game:GetService("Players")
local		RS										=		game:GetService("ReplicatedStorage")
local		SP										=		game:GetService("StarterPlayer")
local		TCS										=		game:GetService("TextChatService")
if		TCS.ChatVersion ~= Enum.ChatVersion.TextChatService then
		print("This experience does not use the TextChatService.\nChat commands will not get registered.")
		return	{Send = function(self, Player : Player | "All", Message : string, ShowServerPrefix : boolean?) end}
end

local		Banland_SystemMessageLocalScript					=		script.Banland_SystemMessageLocalScript
		Banland_SystemMessageLocalScript.Parent				=		SP.StarterPlayerScripts

local		SystemMessageRemote							=		Instance.new("RemoteEvent")
		SystemMessageRemote.Name						=		"Banland_SystemMessageRemote"
		SystemMessageRemote.Parent						=		RS

local		TextChannels								=		TCS:WaitForChild("TextChannels")

local		BanlandChannel								=		Instance.new("TextChannel")
		BanlandChannel.Name							=		"BanlandChannel"
		BanlandChannel.Parent							=		TextChannels
		
		
local		SystemMessageModul							=		{}
function	SystemMessageModul:Send(Player : Player | "All", Message : string, HideServerPrefix : boolean?)
		if		Player == "All" then
				SystemMessageRemote:FireAllClients(Message, HideServerPrefix)
		else
				SystemMessageRemote:FireClient(Player, Message, HideServerPrefix)
		end
end


return	SystemMessageModul
