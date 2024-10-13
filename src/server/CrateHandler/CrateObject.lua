local CrateObjectModule = {}
CrateObjectModule.__index = CrateObjectModule

--/SERVICES

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LUCKY_EXTRA_MULTIPLIER: number = ReplicatedStorage.Constants.LuckyExtraMultiplier.Value

--/TYPES

type self = {
	Rates: {
		{
			Rate: number,
			Rarity: string,
		}
	},
	Gloves: Folder,
}

type CrateObject = typeof(setmetatable({} :: self, CrateObjectModule))

--/MODULES

--/GLOBAL_VARIABLES

local glovesFolder: Folder = ReplicatedStorage.Gloves

--/GLOBAL_FUNCTIONS

--/MODULAR_FUNCTIONS

function CrateObjectModule.new(ratesFolder: Folder): CrateObject
	local crateObject: CrateObject = setmetatable({
		Rates = {
			{
				Rarity = "Mythic",
				Rate = ratesFolder.Mythic.Value,
			},
			{
				Rarity = "Legendary",
				Rate = ratesFolder.Legendary.Value,
			},
			{
				Rarity = "Rare",
				Rate = ratesFolder.Rare.Value,
			},
			{
				Rarity = "Common",
				Rate = ratesFolder.Common.Value,
			},
		},
	}, CrateObjectModule)
	return crateObject
end

--<<Returns the glove that player rolled
function CrateObjectModule.RollGlove(self: CrateObject, isLucky: boolean): Model
	local randomObject: Random = Random.new(tick())
	local randomNumber: number = randomObject:NextInteger(1, 100) / (isLucky and LUCKY_EXTRA_MULTIPLIER or 1)
	local weightCompare: number = 0
	local rarityGet: string = nil
	for _, rarity in self.Rates do
		weightCompare += rarity.Rate
		if randomNumber <= weightCompare then
			rarityGet = rarity.Rarity
			break
		end
	end
	local rarityFolder: { Model } = glovesFolder[rarityGet]:GetChildren()
	return rarityFolder[randomObject:NextInteger(1, #rarityFolder)]
end

return CrateObjectModule
