--/SERVICES

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--/TYPES

--/MODULES

local gameDirectory = require(game:GetService("ReplicatedStorage").Shared.GameDirectory)
local globalFunctions = gameDirectory.GlobalFunctions
local CEnum = gameDirectory.CEnum
local playerDataManager = gameDirectory.Require("Server.PlayerData")
local characterData = gameDirectory.Require("Server.CharacterData")
local mainGameUtils = require(game.ServerScriptService.MainGame.Utils)

--/GLOBAL_VARIABLES

local Utilities = {}
local SPAWN_DISTANCE_FROM_CENTER: number = 100

--/GLOBAL_FUNCTIONS

local function isCharacterValid(mainChar: Model): boolean
	local charHRP: BasePart = (mainChar and mainChar:FindFirstChild("HumanoidRootPart"))
	local charHumanoid: Humanoid = (charHRP and mainChar:FindFirstChild("Humanoid") and mainChar.Humanoid.Health > 0)
	if charHumanoid then
		return true
	end
	return false
end

local function getSpawnPosition(midPoint: Vector3): Vector3
	local raycastParams: RaycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = { workspace.InGame, workspace.GrapplePoints, workspace.Players }
	local newCFrame: CFrame = CFrame.new(midPoint + Vector3.new(0, 1, 0))
	local raycastResult: RaycastResult? =
		workspace:Raycast(newCFrame.Position, newCFrame.LookVector * SPAWN_DISTANCE_FROM_CENTER, raycastParams)
	if not raycastResult then
		return newCFrame.Position + (newCFrame.LookVector * SPAWN_DISTANCE_FROM_CENTER)
	end
	return newCFrame.Position + (newCFrame.LookVector * ((raycastResult.Position - newCFrame.Position).Magnitude - 2))
end

--/MODULAR_FUNCTIONS

function Utilities.AccountForx2Coins(mainPlayer: Player, coinsGive: number)
	local playerData = playerDataManager.GetPlayerData(mainPlayer)
	if playerData then
		if playerData:OwnsGamepass(CEnum.GamePasses.x2Coins.Name) then
			return coinsGive * 2
		end
	end
	return coinsGive
end

function Utilities.SpawnCharacterInGame(mainChar: Model)
	if isCharacterValid(mainChar) then
		local mapModel: Model = mainGameUtils.GetCurrentMap()
		local midPoint: BasePart = mapModel["Mid point"]
		local charHRP: BasePart = mainChar.HumanoidRootPart
		charHRP.CFrame = CFrame.new(getSpawnPosition(midPoint.Position)) * charHRP.CFrame.Rotation
		mainChar.Parent = workspace.InGame
		characterData.Register(mainChar)
	end
end

--<<Gets death/hit effect based on user equipped glove
function Utilities.GetVFX(typeVFX: string, mainPlayer: Player): Attachment?
	if mainPlayer then
		local playerData = playerDataManager.GetPlayerData(mainPlayer)
		local equippedGloveSkin: string = playerData:GetData("EquippedGloveSkin")
		local vfxFolder: Folder = ReplicatedStorage.VFX:FindFirstChild(equippedGloveSkin)
			or ReplicatedStorage.VFX.Default
		return vfxFolder[typeVFX].Attachment
	end
end

--<<Emits and destroys an effect
function Utilities.EmitVFXAndDebris(mainAttachment: Attachment, mainPart: BasePart, debrisTime: number?)
	if mainAttachment then
		local attachmentClone: Attachment = mainAttachment:Clone()
		attachmentClone.Parent = mainPart
		for _, particle: ParticleEmitter in ipairs(attachmentClone:GetChildren()) do
			particle:Emit(particle:GetAttribute("EmitCount"))
		end
		return globalFunctions.taskDebris(attachmentClone, debrisTime or 1.5)
	end
end

return Utilities
