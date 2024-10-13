--/SERVICES

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--/TYPES

--/MODULES

local gameDirectory = require(game:GetService("ReplicatedStorage").Shared.GameDirectory)
local cooldownDisplay = gameDirectory.RequireAsync("Client.Gui.CooldownDisplay")

--/GLOBAL_VARIABLES

local mainPlayer: Player = game.Players.LocalPlayer

local AbilitiesHandler_Client = {
	SkillInUse = false,
	CDTable = {
		CachedTime = 0,
		Cooldown = 0,
	},
}

local clientAbilitiesModules = {}

--/GLOBAL_FUNCTIONS

--<<Checks if character exists and is alive
local function isCharacterValid(): boolean
	local mainChar: Model = mainPlayer.Character
	if mainChar then
		local charHRP: BasePart? = mainChar:FindFirstChild("HumanoidRootPart")
		local charHumanoid: Humanoid? = charHRP and mainChar:FindFirstChild("Humanoid")
		if charHumanoid and charHumanoid.Health > 0 then
			return mainChar.Parent == workspace.InGame
		end
	end
	return false
end

--<<Sets skill in use to false, and sets cooldown
local function useOnSkillFinished(skillName: string)
	local cooldownTime: number = ReplicatedStorage.Constants.CoolDowns[skillName].Value
	return function(ignoreAbilityCD: boolean?)
		AbilitiesHandler_Client.SkillInUse = false
		if not ignoreAbilityCD then
			AbilitiesHandler_Client.CDTable.CachedTime = os.clock()
			AbilitiesHandler_Client.CDTable.Cooldown = cooldownTime
			return cooldownDisplay.PlayTween("Ability", {
				CDTime = cooldownTime,
			})
		end
	end
end

--/MODULAR_FUNCTIONS

--<<Checks if ability is a client ability and returns true if it is
function AbilitiesHandler_Client.IsClientAbility(abilityName: string)
	return clientAbilitiesModules[abilityName] ~= nil
end

--<<Checks if ability is currently inavailable
function AbilitiesHandler_Client.CanUseAbility()
	local cdTable = AbilitiesHandler_Client.CDTable
	return not AbilitiesHandler_Client.SkillInUse and (os.clock() - cdTable.CachedTime) >= cdTable.Cooldown
end

--<<Calls client ability modules main function, main is passed with a function to start cooldown
function AbilitiesHandler_Client.HandleClientAbility(abilityName: string)
	if AbilitiesHandler_Client.CanUseAbility() and isCharacterValid() then
		AbilitiesHandler_Client.SkillInUse = true
		return clientAbilitiesModules[abilityName].Main(useOnSkillFinished(abilityName))
	end
end

--<<Resets all skill in use and cooldown
function AbilitiesHandler_Client.ResetSkills()
	AbilitiesHandler_Client.SkillInUse = false
	AbilitiesHandler_Client.CDTable.CachedTime = 0
	AbilitiesHandler_Client.CDTable.Cooldown = 0
end

--/WORKSPACE

for _, abilityModule: ModuleScript in ipairs(script:GetChildren()) do
	clientAbilitiesModules[abilityModule.Name] = require(abilityModule)
end

return AbilitiesHandler_Client
