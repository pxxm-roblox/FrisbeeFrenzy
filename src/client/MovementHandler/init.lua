--/SERVICES

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

--/TYPES

--/MODULES

local movementData = require(script.Data)
local tiltingHandler = require(script.Tilting)
local abilitiesHandler_Client = require(script.Parent.AbilitiesHandler_Client)

--/GLOBAL_VARIABLES

local DOUBLE_JUMP_CD: number = ReplicatedStorage.Constants.Main.DOUBLE_JUMP_CD.Value
local JUMP_POWER_MULTIPLIER: number = ReplicatedStorage.Constants.Main.DOUBLE_JUMP_POWER_MULTIPLIER.Value
local TIME_BETWEEN_JUMPS: number = 0.1

local MovementHandler = {}
local mainPlayer = game.Players.LocalPlayer

local oldJumpPower: number = nil
local animationFolder = ReplicatedStorage.Animations

--/GLOBAL_FUNCTIONS

--<<Returns animation based on move direction
local function getDirectionJumpAnimation(moveNumberZ: number)
	return (moveNumberZ < 0 and animationFolder.FrontDoubleJump or animationFolder.DoubleJump)
end

--/MODULAR_FUNCTIONS

function MovementHandler.SetUpDoubleJump()
	local cdCache: number = 0
	return UserInputService.JumpRequest:Connect(function()
		if movementData.IsMovementRestricted() then
			return
		end
		local mainChar: Model = mainPlayer.Character
		local charHumanoid: Humanoid = (mainChar and mainChar.Parent and mainChar:FindFirstChildWhichIsA("Humanoid"))
		if charHumanoid and charHumanoid.Health > 0 then
			if
				os.clock() - cdCache >= DOUBLE_JUMP_CD
				and movementData.CanDoubleJump()
				and not movementData.DoubleJumped()
			then
				cdCache = os.clock()
				charHumanoid.JumpPower = oldJumpPower * JUMP_POWER_MULTIPLIER
				movementData.SetDoubleJumped(true)
				charHumanoid:ChangeState(Enum.HumanoidStateType.Jumping)
				return charHumanoid.Animator
					:LoadAnimation(
						getDirectionJumpAnimation(
							mainChar.HumanoidRootPart.CFrame:VectorToObjectSpace(charHumanoid.MoveDirection).Z
						)
					)
					:Play()
			end
		end
	end)
end

function MovementHandler.OnCharacterAdded(mainChar: Model)
	local charHumanoid: Humanoid = mainChar:WaitForChild("Humanoid")
	local clockFlag: number = nil
	charHumanoid.UseJumpPower = true
	charHumanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
	charHumanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
	oldJumpPower = charHumanoid.JumpPower
	movementData.SetCanDoubleJump(true)
	charHumanoid.StateChanged:Connect(function(_, newState: Enum.HumanoidStateType)
		if newState == Enum.HumanoidStateType.Landed then
			charHumanoid.JumpPower = oldJumpPower
			clockFlag = nil
			movementData.SetCanDoubleJump(false)
			return movementData.SetDoubleJumped(false)
		end
		if newState == Enum.HumanoidStateType.Freefall then
			local flagCheck: number = os.clock()
			clockFlag = flagCheck
			task.wait(TIME_BETWEEN_JUMPS)
			return (flagCheck == clockFlag and movementData.SetCanDoubleJump(true))
		end
	end)
end

function MovementHandler.init()
	MovementHandler.SetUpDoubleJump()
	return MovementHandler
end

mainPlayer.CharacterAdded:Connect(function(mainChar: Model)
	MovementHandler.OnCharacterAdded(mainChar)
	abilitiesHandler_Client.ResetSkills()
	return tiltingHandler.SetUpTilt(mainChar)
end)

mainPlayer.CharacterRemoving:Connect(function()
	return tiltingHandler.OnCharacterRemoving()
end)

if mainPlayer.Character then
	MovementHandler.OnCharacterAdded(mainPlayer.Character)
	tiltingHandler.SetUpTilt(mainPlayer.Character)
end

return MovementHandler.init()
