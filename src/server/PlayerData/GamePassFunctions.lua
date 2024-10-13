local gameDirectory = require(game:GetService("ReplicatedStorage").Shared.GameDirectory)
local CEnum = gameDirectory.CEnum

return {
	[CEnum.GamePasses.ValkGloves.Name] = function(playerData)
		local glovesOwned: { string } = playerData:GetData("GloveSkins")
		if not table.find(glovesOwned, "ValkGlove") then
			playerData:AppendData("GloveSkins", "ValkGlove")
		end
	end,
}
