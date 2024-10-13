--/SERVICES

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--/TYPES

--/MODULES

local gameDirectory = require(game:GetService("ReplicatedStorage").Shared.GameDirectory)
local globalFunctions = gameDirectory.GlobalFunctions
local mainServices = gameDirectory.GetServices()

--/GLOBAL_VARIABLES

local Dash_Client = {}
local dashConstants: Folder = ReplicatedStorage.Constants.Abilities
local mainPlayer: Player = mainServices.Players.LocalPlayer
local animationFolder: Folder = ReplicatedStorage.Animations.Dash
local abilityRemoteEvent: RemoteEvent = gameDirectory.GetReplicatedServiceFolder("AbilityHandler").RemoteEvent

local DASH_SPEED: number = dashConstants.DashSpeed.Value
local DASH_TIME: number = dashConstants.DashTime.Value

local directions = {
	Forward = { 1, "LookVector" },
	Backward = { -1, "LookVector" },
	Left = { -1, "RightVector" },
	Right = { 1, "RightVector" },
}

--/GLOBAL_FUNCTIONS

local function getDirection(charHRP: BasePart): string
	local velocity = charHRP.CFrame:Inverse() * (charHRP.Position + charHRP.AssemblyLinearVelocity)
	local yDirection = math.atan2(velocity.X, -velocity.Z)
	local roundedDirection = math.ceil(math.deg(yDirection) - 0.5)
	if roundedDirection > 45 and roundedDirection < 135 then --strafing right
		return "Right"
	elseif roundedDirection < -45 and roundedDirection > -135 then --strafing left
		return "Left"
	elseif roundedDirection <= -135 or roundedDirection >= 135 then
		return "Backward"
	end
	return "Forward"
end

--/MODULAR_FUNCTIONS

function Dash_Client.Main(onSkillEnd: (cooldownTime: number) -> nil, customSpeed: number?)
	local mainChar: Model = mainPlayer.Character
	local charHRP: BasePart = mainChar.HumanoidRootPart
	local charHumanoid: Humanoid = mainChar.Humanoid
	local dashDirection: string = getDirection(charHRP)
	local directionData: { number | string } = directions[dashDirection]
	local linearVelocity: LinearVelocity, linearVelStateCheck = globalFunctions.GetLinearVelocity(mainChar)
	local vectorDirection: Vector3 = charHRP.CFrame[directionData[2]] * directionData[1]
	abilityRemoteEvent:FireServer({
		MoveDirection = vectorDirection,
	})
	linearVelocity.VectorVelocity = vectorDirection * (customSpeed or DASH_SPEED)
	linearVelocity.MaxForce = 1e5
	charHumanoid.Animator:LoadAnimation(animationFolder[dashDirection]):Play()
	charHumanoid.JumpPower = 0
	return task.delay(DASH_TIME, function()
		if linearVelStateCheck(true) then
			linearVelocity.VectorVelocity = Vector3.new()
			linearVelocity.MaxForce = 0
			globalFunctions.SetVelocity(charHRP, linearVelocity.VectorVelocity)
		end
		charHumanoid.JumpPower = 50
		return onSkillEnd()
	end)
end

return Dash_Client
