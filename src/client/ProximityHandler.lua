--/SERVICES

local RunService = game:GetService("RunService")

--/TYPES

--/MODULES

--/GLOBAL_VARIABLES

local ProximityHandler = {}

local proximityFunctions: { [BasePart]: { CallBack: (enterState: string) -> (), Entered: boolean } } = {}
local mainPlayer: Player = game:GetService("Players").LocalPlayer

--/GLOBAL_FUNCTIONS

--<<Checks if character is valid to grapple
local function isCharacterValid(mainChar: Model): Model | boolean
	if not mainChar or not mainChar.Parent then
		return false
	end
	if not mainChar:FindFirstChild("HumanoidRootPart") or not mainChar:FindFirstChild("Humanoid") then
		return false
	end
	if mainChar.Humanoid.Health <= 0 then
		return false
	end
	return mainChar
end

--/MODULAR_FUNCTIONS

function ProximityHandler.RegisterProximityFunction(basePart: BasePart, callBack: () -> ())
	proximityFunctions[basePart] = {
		CallBack = callBack,
		Entered = false,
	}
end

RunService.Heartbeat:Connect(function()
	local mainChar: Model = isCharacterValid(mainPlayer.Character)
	if mainChar then
		for part: BasePart, dataTable in next, proximityFunctions do
			if
				(mainChar.HumanoidRootPart.Position - part.Position).Magnitude
				<= math.max(part.Size.X, part.Size.Y, part.Size.Z) / 2
			then
				if not dataTable.Entered then
					dataTable.Entered = true
					dataTable.CallBack("Entered")
				end
			elseif dataTable.Entered then
				dataTable.Entered = false
				dataTable.CallBack("Exited")
			end
		end
	end
end)

return ProximityHandler
