--		Simple DataStore Module just in case you don't implement your own methods.

local		DSS								=		game:GetService("DataStoreService")
local		DS								=		DSS:GetDataStore("BanlandPlayerData")

local		DataStore							=		{}
local		Failed							=		{}


function	DataStore:GetPlayerData(UserId : number)
		local		Erfolg, Ergebnis				=		pcall(function()
				return	DS:GetAsync("Spieler_"..UserId)
		end)	
		if		not Erfolg then
				if		not Failed[UserId] then
						Failed[UserId]		=		0
				end
				Failed[UserId]				+=		1
				
				if		Failed[UserId] >= 2 then
						Failed[UserId]		=		nil
						return	nil
				end
				
				task.wait(math.random(10, 20))
				return	self:GetPlayerData(UserId)
		end
		
		Ergebnis							=		Ergebnis or {}
		Failed[UserId]						=		nil
		
		return	Ergebnis
end

function	DataStore:SetPlayerData(UserId : number, Data)
		local		Erfolg, Ergebnis				=		pcall(function()
				if		Data == nil then
						return	DS:RemoveAsync("Spieler_"..UserId)
				end
				return	DS:SetAsync("Spieler_"..UserId, Data)
		end)	
		if		not Erfolg then
				if		not Failed[UserId] then
						Failed[UserId]		=		0
				end
				Failed[UserId]				+=		1
				
				if		Failed[UserId] >= 2 then
						Failed[UserId]		=		nil
						return	false
				end
			
				task.wait(math.random(10, 20))
				return	self:SetPlayerData(UserId, Data)
		end
		
		return	true
end


return	DataStore
