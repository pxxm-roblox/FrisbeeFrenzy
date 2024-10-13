--/SERVICES

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--/TYPES

--/MODULES

local gameDirectory = require(ReplicatedStorage.Shared.GameDirectory)
local presetFX = gameDirectory.Require("Shared.PresetFX")

--/GLOBAL_VARIABLES

local DASH_TIME: number = ReplicatedStorage.Constants.Abilities.DashTime.Value

local DASH_SPEED: number = ReplicatedStorage.Constants.Abilities.DashSpeed.Value

local DashAbility = {}

--/GLOBAL_FUNCTIONS

--<<Raycasts forward for a wall if theres a wall recalculate time and return it
-- local function raycastDashTime(charPosition: Vector3, lookVector: Vector3, dashSpeed: number): number
-- 	local raycastParams: RaycastParams = RaycastParams.new()
-- 	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
-- 	raycastParams.FilterDescendantsInstances = { workspace.InGame, workspace.FrisbeesInGame, workspace.Players }
-- 	local raycastResult: RaycastResult = workspace:Raycast(charPosition, lookVector * 1e5, raycastParams)
-- 	if raycastResult then
-- 		return ((raycastResult.Position - charPosition).Magnitude - 5) / dashSpeed
-- 	end
-- 	return -1
-- end

--/MODULAR_FUNCTIONS

function DashAbility.Main(
	mainChar: Model,
	onAbilityEnd: (ignoreReplication: boolean) -> nil,
	args: { MoveDirection: Vector3, CustomSpeed: number }
)
	local charHRP: BasePart = mainChar.HumanoidRootPart
	onAbilityEnd(true)
	return presetFX.Sort("RockTrail", {
		Origin = CFrame.lookAt(charHRP.Position, charHRP.Position + args.MoveDirection * 3),
		Size = 1,
		Spacing = 3,
		Length = DASH_TIME * (args.CustomSpeed or DASH_SPEED),
		Time = DASH_TIME,
	})
end

return DashAbility
