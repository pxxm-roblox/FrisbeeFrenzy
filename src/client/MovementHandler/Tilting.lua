--/SERVICES

--/TYPES

--/MODULES

--/GLOBAL_VARIABLES

local TiltingHandler = {}
local rbxCon: RBXScriptConnection = nil

--/GLOBAL_FUNCTIONS

--/MODULAR_FUNCTIONS

function TiltingHandler.SetUpTilt(char: Model)
	local dir, vel
	local angle = 0
	local angle2 = 0

	local root = char:WaitForChild("HumanoidRootPart")
	local Joint = root:WaitForChild("RootJoint")
	local OriginalPos = Joint.C0

	local DevideAngle = 6
	local DevideAngle2 = DevideAngle
	local TiltSpeed = 0.3

	rbxCon = game:GetService("RunService").Heartbeat:Connect(function()
		vel = root.Velocity * Vector3.new(1, 0, 1)
		if vel.Magnitude > 2 then
			dir = vel.Unit
			angle = root.CFrame.RightVector:Dot(dir) / DevideAngle
			angle2 = root.CFrame.LookVector:Dot(dir) / DevideAngle2
		else
			angle = 0
			angle2 = 0
		end

		Joint.C0 = Joint.C0:Lerp(OriginalPos * CFrame.Angles(angle2, -angle, 0), TiltSpeed)
	end)
end

function TiltingHandler.OnCharacterRemoving()
	if rbxCon then
		rbxCon:Disconnect()
		rbxCon = nil
	end
end

return TiltingHandler
