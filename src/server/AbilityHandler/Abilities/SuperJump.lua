--/SERVICES

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--/TYPES

--/MODULES

local gameDirectory = require(ReplicatedStorage.Shared.GameDirectory)
local globalFunctions = gameDirectory.GlobalFunctions
local presetFX = gameDirectory.Require("Shared.PresetFX")

--/GLOBAL_VARIABLES

local SuperJumpHandler = {}
local animationFolder = ReplicatedStorage.Animations
local constantsFolder = ReplicatedStorage.Constants.Abilities.SuperJump

local JUMP_SPEED: number = constantsFolder.JumpSpeed.Value

local JUMP_TIME: number = constantsFolder.JumpTime.Value

--/GLOBAL_FUNCTIONS

--/MODULAR_FUNCTIONS

function SuperJumpHandler.Main(mainChar: Model, onAbilityEnd: () -> ())
	local jumpVelocity: Vector3 = Vector3.new(0, JUMP_SPEED, 0)
	local charHRP: BasePart = mainChar.HumanoidRootPart
	local charAnimator: Animator = mainChar.Humanoid.Animator
	local linearVelocity: LinearVelocity, resetFunction = globalFunctions.GetLinearVelocity(mainChar)
	linearVelocity.VectorVelocity = jumpVelocity
	linearVelocity.MaxForce = 1e5
	globalFunctions.SetVelocity(charHRP, linearVelocity.VectorVelocity)
	presetFX.Sort("SuperJump", {
		MainChar = mainChar,
		OriginPosition = charHRP.Position,
		JumpSpeed = JUMP_SPEED,
		JumpTime = JUMP_TIME,
	})
	task.delay(JUMP_TIME, function()
		onAbilityEnd()
		if resetFunction(true) then
			linearVelocity.MaxForce = 0
			linearVelocity.VectorVelocity = Vector3.new()
			globalFunctions.SetVelocity(charHRP, jumpVelocity / 2)
		end
	end)
	return charAnimator:LoadAnimation(animationFolder.Jump):Play()
end

return SuperJumpHandler
