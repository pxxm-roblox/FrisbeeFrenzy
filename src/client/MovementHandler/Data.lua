local mainPlayer: Player = game:GetService("Players").LocalPlayer

local movementDataManager = {}
local DATA_VALUES = {
	MovementRestricted = false,
	DoubleJumped = false,
	CanDoubleJump = false,
	CurrentlyGrappling = false,
}

function movementDataManager.IsCurrentlyGrappling()
	return DATA_VALUES.CurrentlyGrappling
end

function movementDataManager.SetCurrentlyGrappling(bool: boolean)
	DATA_VALUES.CurrentlyGrappling = bool
end

function movementDataManager.IsMovementRestricted()
	local mainChar: Model = mainPlayer.Character
	if mainChar then
		local linearVelocity: LinearVelocity = mainChar.HumanoidRootPart:FindFirstChild("LinearVelocity")
		if linearVelocity and linearVelocity.MaxForce > 0 then
			return true
		end
	end
	return (DATA_VALUES.MovementRestricted or DATA_VALUES.CurrentlyGrappling)
end

function movementDataManager.CanDoubleJump()
	return DATA_VALUES.CanDoubleJump
end

function movementDataManager.DoubleJumped()
	return DATA_VALUES.DoubleJumped
end

function movementDataManager.SetDoubleJumped(bool: boolean)
	DATA_VALUES.DoubleJumped = bool
end

function movementDataManager.SetCanDoubleJump(bool: boolean)
	DATA_VALUES.CanDoubleJump = bool
end

return movementDataManager
