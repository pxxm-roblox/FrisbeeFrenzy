local gameDirectory = require(game:GetService("ReplicatedStorage").Shared.GameDirectory)
local playerDataManager = gameDirectory.Require("Server.PlayerData")

local CEnum = gameDirectory.CEnum

return {
	[CEnum.GamePasses.VIP.Name] = function(mainPlayer: Player)
		local playerData = playerDataManager.GetPlayerData(mainPlayer)
		mainPlayer:SetAttribute("ChatTag", "VIP")
		return (playerData and playerData:IncrementData("Coins", 2000))
	end,
	[CEnum.GamePasses.ValkGloves.Name] = function(mainPlayer: Player)
		local playerData = playerDataManager.GetPlayerData(mainPlayer)
		local glovesOwned: { string } = playerData:GetData("GloveSkins")
		if not table.find(glovesOwned, "ValkGlove") then
			playerData:AppendData("GloveSkins", "ValkGlove")
		end
	end,
}
