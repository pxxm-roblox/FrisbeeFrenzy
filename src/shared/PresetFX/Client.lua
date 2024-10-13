--/SERVICES

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

--/TYPES

--/MODULES

local gameDirectory = require(ReplicatedStorage.Shared.GameDirectory)
local globalFunctions = gameDirectory.GlobalFunctions
local maidModule = gameDirectory.Require("Utils.MaidModule")

--/GLOBAL_VARIABLES

local remoteEvent: RemoteEvent = gameDirectory.GetReplicatedServiceFolder("PresetFX").UnreliableRemoteEvent
local effectsFolder = ReplicatedStorage.Effects.Meshes
local mainPlayer: Player = game.Players.LocalPlayer

local PresetFX_Client = {}
local Effects = {}

--/GLOBAL_FUNCTIONS

--<<Create cubes with size and raycast
local function usePartOnRay(size: number): (placementCFrame: CFrame) -> BasePart?
	local raycastParams: RaycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = { workspace.InGame, workspace.FrisbeesInGame, workspace.Players }
	return function(placementCFrame: CFrame)
		local raycastResult: RaycastResult =
			workspace:Raycast(placementCFrame.Position, Vector3.new(0, -5, 0), raycastParams)
		if raycastResult then
			local part: Part = Instance.new("Part")
			part.Anchored = true
			part.CanCollide = false
			part.Size = Vector3.new(size, size, size)
			part.CFrame = CFrame.new(placementCFrame.X, raycastResult.Position.Y, placementCFrame.Z)
				* CFrame.Angles(math.random(-180, 180), math.random(-180, 180), math.random(-180, 180))
			part.Color = raycastResult.Instance.Color
			part.Material = raycastResult.Instance.Material
			return part
		end
	end
end

--/MODULAR_FUNCTIONS

function Effects.RockTrail(params: { Size: number, Spacing: number, Origin: CFrame, Length: number, Time: number })
	local DEBRIS_TIME: number = 1

	local effectModel: Model = Instance.new("Model")
	local partCreationFunction = usePartOnRay(params.Size)
	local amtParts: number = math.floor(params.Length / params.Size)
	local delayBetween: number = (params.Time and params.Time / amtParts)
	local partsCreated: number = 1
	effectModel.Parent = workspace.Effects
	local runCon: RBXScriptConnection
	runCon = RunService.PreAnimation:Connect(function(dt: number)
		if partsCreated > amtParts then
			return runCon:Disconnect()
		end
		local iterationAmount: number = 1
		if delayBetween then
			iterationAmount = math.max(math.ceil(dt / delayBetween), 1)
		end
		for _ = 1, iterationAmount do
			if partsCreated > amtParts then
				return
			end
			for i = -1, 1, 2 do
				local part: Part =
					partCreationFunction(params.Origin * CFrame.new(i * params.Spacing, 0, -partsCreated * params.Size))
				if part then
					part.Parent = effectModel
				end
			end
			partsCreated += 1
		end
	end)
	return globalFunctions.taskDebris(effectModel, DEBRIS_TIME)
end

function Effects.RockTrailFollow(params: { InstanceReplicate: Instance, Spacing: number, Size: number })
	local effectModel: Model = Instance.new("Model")
	local partCreationFunction = usePartOnRay(params.Size)
	local mainPart: BasePart = params.InstanceReplicate.Parent
	local maidObject = maidModule.Create()
	local originRotation: CFrame = mainPart.CFrame.Rotation
	local lastPosition: Vector3 = mainPart.Position
	effectModel.Parent = workspace.Effects
	maidObject:Add(params.InstanceReplicate.Destroying:Connect(function()
		globalFunctions.taskDebris(effectModel, 1.5)
		return maidObject:Destroy()
	end))
	return maidObject:Add(RunService.PreAnimation:Connect(function()
		local distanceInBetween: number = (mainPart.Position - lastPosition).Magnitude
		local amtParts: number = math.ceil(distanceInBetween / params.Spacing)
		for x = 1, amtParts do
			for i = -1, 1, 2 do
				local part: Part = partCreationFunction(
					CFrame.new(lastPosition) * originRotation * CFrame.new(i * params.Spacing, 0, x * -params.Size)
				)
				if part then
					part.Parent = effectModel
				end
			end
		end
		lastPosition = mainPart.Position
	end))
end

function Effects.SuperJump(params: { MainChar: Model, OriginPosition: Vector3, JumpSpeed: number, JumpTime: number })
	local AMT_RINGS: number = 3
	local EFFECT_TIME: number = 0.45
	local SIZE_SCALE: number = 3
	local JUMP_SPEED: number = params.JumpSpeed
	local JUMP_TIME: number = params.JumpTime
	local charPosition: Vector3 = (
		mainPlayer.Character == params.MainChar and mainPlayer.Character.HumanoidRootPart.Position
		or params.OriginPosition
	)

	local effectModel: Model = Instance.new("Model")
	local totalDistanceTravelled: number = JUMP_SPEED * JUMP_TIME
	local timeInBetween: number = JUMP_TIME / AMT_RINGS
	local tweenInfo: TweenInfo = TweenInfo.new(EFFECT_TIME, Enum.EasingStyle.Cubic)
	local properties: { [string]: any } = {
		Size = effectsFolder.Air.Size * SIZE_SCALE,
		Transparency = 1,
	}
	effectModel.Parent = workspace.Effects

	for x = 1, AMT_RINGS do
		local ringClone: BasePart = effectsFolder.Air:Clone()
		ringClone.CFrame = CFrame.new(charPosition + Vector3.new(0, x * (totalDistanceTravelled / AMT_RINGS)))
		ringClone.Parent = effectModel
		TweenService:Create(ringClone, tweenInfo, properties):Play()
		task.wait(timeInBetween)
	end

	return globalFunctions.taskDebris(effectModel, EFFECT_TIME)
end

function Effects.Invisibility(params: { MainChar: Model, TimeInvisible: number })
	local tweenInfo: TweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad)
	local partsTransparent: { BasePart } = {}
	for _, basePart: BasePart in ipairs(params.MainChar:GetDescendants()) do
		if basePart:IsA("BasePart") and basePart.Transparency == 0 then
			table.insert(partsTransparent, basePart)
			TweenService:Create(basePart, tweenInfo, { Transparency = 0.75 }):Play()
		end
	end
	return task.delay(params.TimeInvisible, function()
		for _, basePart: BasePart in ipairs(partsTransparent) do
			TweenService:Create(basePart, tweenInfo, { Transparency = 0 }):Play()
		end
	end)
end

--/MAIN

remoteEvent.OnClientEvent:Connect(function(effectString: string, ...)
	local indexedEffect = Effects[effectString]
	return (indexedEffect and indexedEffect(...))
end)

return PresetFX_Client
