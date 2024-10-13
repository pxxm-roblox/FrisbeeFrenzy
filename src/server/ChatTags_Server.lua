--/SERVICES

--/TYPES

--/MODULES

local gameDirectory = require(game:GetService("ReplicatedStorage").Shared.GameDirectory)
local CEnum = gameDirectory.CEnum
local playerDataManager = gameDirectory.Require("Server.PlayerData")

--/GLOBAL_VARIABLES

local chatTagsServer = {}

local GROUP_ID: number = 33213988

local Group_Roles = {
	[255] = "Owner",
	[254] = "Developer",
}

--/GLOBAL_FUNCTIONS

--/MODULAR_FUNCTIONS

function chatTagsServer.SetChatTags(mainPlayer: Player)
	local roleNumber: number = mainPlayer:GetRankInGroup(GROUP_ID)
	local role: string = Group_Roles[roleNumber]
	if role then
		mainPlayer:SetAttribute("ChatTag", role)
	else
		local playerData = playerDataManager.GetPlayerData(mainPlayer)
		if playerData:OwnsGamepass(CEnum.GamePasses.VIP.Name) then
			mainPlayer:SetAttribute("ChatTag", "VIP")
		end
	end
end

return chatTagsServer
