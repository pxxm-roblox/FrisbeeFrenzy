--/SERVICES

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--/TYPES

--/MODULES

local gameDirectory = require(ReplicatedStorage.Shared.GameDirectory)
local characterDataManager = gameDirectory.Require("Server.CharacterData")
local playerDataManager = gameDirectory.Require("Server.PlayerData")
local remoteEvent: RemoteEvent = gameDirectory.RegisterAsReplicatedService("AbilityHandler", "RemoteEvent").RemoteEvent

--/GLOBAL_VARIABLES

local AbilityHandler = {}
local Abilities = {}

local cooldownsFolder: Folder = ReplicatedStorage.Constants.CoolDowns

local TESTING_ABILITY: string? = nil

--/GLOBAL_FUNCTIONS

--<<Check if character exists and is alive to use ability
local function characterExistsCheck(mainPlayer: Player): boolean
	local mainChar: Model = mainPlayer.Character
	if mainChar and mainChar.Parent and mainChar:FindFirstChild("HumanoidRootPart") then
		local charHumanoid: Humanoid = mainChar:FindFirstChild("Humanoid")
		return (charHumanoid and charHumanoid.Health > 0 or false)
	end
	return false
end

--<<Returns a function that sets ability cooldown
local function onAbilityEnd(skillName: string, characterData)
	characterData:SetAbilityState(true)
	local cooldownTime: number = cooldownsFolder[skillName].Value
	return function(ignoreReplication: boolean, ignoreAbilityCD: boolean)
		if not ignoreAbilityCD then
			characterData:SetAbilityCD(cooldownTime, ignoreReplication)
		end
		return characterData:SetAbilityState(false)
	end
end

--/MODULAR_FUNCTIONS

function AbilityHandler.SortAbilityOnTargetted(mainPlayer: Player, frisbeeObject): boolean
	if mainPlayer then
		local playerData = playerDataManager.GetPlayerData(mainPlayer)
		local mainChar: Model = mainPlayer.Character
		local abilityName: string = playerData:GetData("EquippedAbility")
		local ability = Abilities[TESTING_ABILITY or abilityName]
		if ability and ability.OnTargettedByFrisbee then
			local mainCharacterData = characterDataManager.Get(mainChar)
			if mainCharacterData and mainCharacterData:GetAbilityState() then
				return ability.OnTargettedByFrisbee(mainChar, frisbeeObject)
			end
		end
	end
end

remoteEvent.OnServerEvent:Connect(function(mainPlayer: Player, dataTable: { [string]: any })
	if characterExistsCheck(mainPlayer) then
		local mainChar: Model = mainPlayer.Character
		local playerData = playerDataManager.GetPlayerData(mainPlayer)
		local mainCharacterData = characterDataManager.Get(mainChar)
		local abilityName: string = playerData:GetData("EquippedAbility")
		if mainCharacterData and mainCharacterData:CanUseAbility() then
			local ability = Abilities[TESTING_ABILITY or abilityName]
			return ability and ability.Main(mainChar, onAbilityEnd(abilityName, mainCharacterData), dataTable)
		end
	end
end)

for _, abilityScript: ModuleScript in ipairs(script.Abilities:GetChildren()) do
	Abilities[abilityScript.Name] = require(abilityScript)
end

return AbilityHandler
