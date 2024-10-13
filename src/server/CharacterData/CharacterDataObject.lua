--/SERVICES

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--/TYPES

type self = {
	Character: Model,
	CatchState: number,
	CatchCD: number,
	AbilityInUse: boolean,
	TargettedCharacter: Model,
	CatchStateActive: boolean,
	AbilityCD: {
		CachedTime: number,
		Cooldown: number,
	},
	CatchStateFX: {
		AnimationTrack: AnimationTrack,
		Sound: Sound,
	},
}

--/MODULES

local gameDirectory = require(game:GetService("ReplicatedStorage").Shared.GameDirectory)
local CEnum = gameDirectory.CEnum
local globalFunctions = gameDirectory.GlobalFunctions
local playerDataManager = gameDirectory.Require("Server.PlayerData")
local gameDataManager = gameDirectory.Require("Server.GameManager.Data")
local cooldownDisplayRemote: RemoteEvent =
	gameDirectory.RegisterAsReplicatedService("CooldownDisplayRemote", "RemoteEvent").RemoteEvent

--/GLOBAL_VARIABLES

local CATCH_WINDOW: number = ReplicatedStorage.Constants.Main.CATCH_TIME_WINDOW.Value
local CATCH_COOLDOWN: number = ReplicatedStorage.Constants.Main.CATCH_COOLDOWN.Value
local WINDOW_MULTIPLIER: number = ReplicatedStorage.Constants.Main.WINDOW_MULTIPLIER.Value
local CATCH_DISTANCE: number = ReplicatedStorage.Constants.Frisbee.CATCH_DISTANCE.Value

local LESS_CD_DECREASE_MULTIPLIER: number = ReplicatedStorage.Constants.Main.LessCDDecreaseMultiplier.Value

local CharacterDataObject = {}
CharacterDataObject.__index = CharacterDataObject

type CharacterDataObject = typeof(setmetatable({} :: self, CharacterDataObject))

--/GLOBAL_FUNCTIONS

--/MODULAR_FUNCTIONS

function CharacterDataObject.new(mainChar: Model): CharacterDataObject
	return setmetatable({
		Player = Players:GetPlayerFromCharacter(mainChar),
		Character = mainChar,
		CatchStateActive = false,
		CatchState = 0,
		TargettedCharacter = nil,
		CatchCD = 0,
		AbilityInUse = false,
		CatchStateFX = {},
		AbilityCD = {
			CachedTime = 0,
			Cooldown = 0,
		},
	}, CharacterDataObject)
end

function CharacterDataObject.SetCatchState(self: CharacterDataObject)
	self.CatchState = os.clock()
end

function CharacterDataObject.PlayCatchStateFX(self: CharacterDataObject)
	local animationTrack: AnimationTrack =
		self.Character.Humanoid.Animator:LoadAnimation(ReplicatedStorage.Animations.CatchIdle)
	local soundObject: Sound = ReplicatedStorage.Sounds.IdleSound:Clone()
	local catchStateFX = self.CatchStateFX
	local frisbeeObject = gameDataManager.GetFrisbee()
	soundObject.Parent = self.Character.HumanoidRootPart
	catchStateFX.AnimationTrack = animationTrack
	catchStateFX.Sound = soundObject
	soundObject:Play()
	animationTrack:Play()
	return task.delay(self:GetCatchWindowTime(frisbeeObject:GetSpeed()), function()
		return self:ResetCatchState(animationTrack) and self:SetCatchCD()
	end)
end

function CharacterDataObject.ResetCatchState(self: CharacterDataObject, animationTrackFlag: AnimationTrack?): boolean
	local catchStateFX = self.CatchStateFX
	if not animationTrackFlag or animationTrackFlag == catchStateFX.AnimationTrack then
		if catchStateFX.AnimationTrack then
			catchStateFX.AnimationTrack:Stop()
			catchStateFX.AnimationTrack:Destroy()
			catchStateFX.AnimationTrack = nil
		end
		if catchStateFX.Sound then
			catchStateFX.Sound:Destroy()
			catchStateFX.Sound = nil
		end
		self:ResetCatchCD()
		self.CatchStateActive = false
		return true
	end
	return false
end

function CharacterDataObject.SetCatchCD(self: CharacterDataObject)
	self.CatchCD = os.clock()
	return (
		self.Player
		and cooldownDisplayRemote:FireClient(self.Player, {
			Method = "PlayTween",
			FrameName = "Catch",
			Args = {
				CDTime = CATCH_COOLDOWN,
			},
		})
	)
end

function CharacterDataObject.ResetCatchCD(self: CharacterDataObject)
	self.CatchCD = 0
	return (
		self.Player
		and cooldownDisplayRemote:FireClient(self.Player, {
			Method = "Clear",
			FrameName = "Catch",
		})
	)
end

function CharacterDataObject.CanUseAbility(self: CharacterDataObject)
	return not self.AbilityInUse and self:IsAbilityCDOver()
end

function CharacterDataObject.GetAbilityState(self: CharacterDataObject)
	return self.AbilityInUse
end

function CharacterDataObject.CatchCDOver(self: CharacterDataObject): boolean
	return (os.clock() - self.CatchCD) >= CATCH_COOLDOWN
end

function CharacterDataObject.IsCatchStateActive(self: CharacterDataObject): boolean
	return self.CatchStateActive
end

function CharacterDataObject.SetCatchStateActive(self: CharacterDataObject)
	self.CatchStateActive = true
end

function CharacterDataObject.PlayerCaughtFrisbee(self: CharacterDataObject): boolean
	return (os.clock() - self.CatchState) <= (CATCH_WINDOW + globalFunctions.GetPlayerPing(self.Character))
end

function CharacterDataObject.UseFrisbeeCaughtChecker(self: CharacterDataObject, frisbeeSpeed: number): () -> boolean
	local catchWindow: number = self:GetCatchWindowTime(frisbeeSpeed)
	return function()
		return (os.clock() - self.CatchState) <= (catchWindow + globalFunctions.GetPlayerPing(self.Character))
	end
end

function CharacterDataObject.GetCatchWindowTime(_, frisbeeSpeed: number): number
	return (CATCH_DISTANCE / frisbeeSpeed) * WINDOW_MULTIPLIER
end

function CharacterDataObject.IsAbilityCDOver(self: CharacterDataObject): boolean
	return (os.clock() - self.AbilityCD.CachedTime) >= self.AbilityCD.Cooldown
end

function CharacterDataObject.SetAbilityState(self: CharacterDataObject, inUse: boolean)
	self.AbilityInUse = inUse
end

function CharacterDataObject.SetAbilityCD(self: CharacterDataObject, cooldownTime: number, ignoreReplication: boolean)
	if self.Player then
		local playerData = playerDataManager.GetPlayerData(self.Player)
		if playerData and playerData:OwnsGamepass(CEnum.GamePasses.LessCD.Name) then
			cooldownTime /= LESS_CD_DECREASE_MULTIPLIER
		end
		if not ignoreReplication then
			cooldownDisplayRemote:FireClient(self.Player, {
				Method = "PlayTween",
				FrameName = "Ability",
				Args = {
					CDTime = cooldownTime,
				},
			})
		end
	end
	self.AbilityCD.CachedTime = os.clock()
	self.AbilityCD.Cooldown = cooldownTime
end

function CharacterDataObject.SetTargettedCharacter(self: CharacterDataObject, targettedCharacter: Model)
	self.TargettedCharacter = targettedCharacter
end

function CharacterDataObject.GetTargettedCharacter(self: CharacterDataObject): Model
	local targettedCharacter: Model = self.TargettedCharacter
	self.TargettedCharacter = nil
	return targettedCharacter
end

return CharacterDataObject
