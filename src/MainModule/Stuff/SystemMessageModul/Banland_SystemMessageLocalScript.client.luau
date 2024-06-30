local		TCS										=		game:GetService("TextChatService")
local		RS										=		game:GetService("ReplicatedStorage")
if		TCS.ChatVersion ~= Enum.ChatVersion.TextChatService then
		print("This experience does not use the TextChatService.\nBanland Module chat commands will not get registered.")
		return
end

local		SystemMessageRemote : RemoteEvent					=		RS:WaitForChild("Banland_SystemMessageRemote")

local		TextChannels								=		TCS:WaitForChild("TextChannels")
local		SystemChannel								=		TextChannels:WaitForChild("RBXSystem")

local		Debounce									=		false

local		function	SendMessage(Message : string, HideServerPrefix)
		if		not Message then return end
		
		repeat	task.wait() until not Debounce
				Debounce							=		true
		
		local		String							=		if HideServerPrefix then Message else "[Server]: " .. Message .. "\n"
		local		Result : TextChatMessage				=		SystemChannel:DisplaySystemMessage(String)
		repeat	task.wait() until Result.Status ~= Enum.TextChatMessageStatus.Sending
		if		Result.Status == Enum.TextChatMessageStatus.Floodchecked then
				task.wait(5)
				return	SendMessage(Message, HideServerPrefix)
		end
		
		task.wait()
		Debounce									=		false
end

SystemMessageRemote.OnClientEvent:Connect(SendMessage)

