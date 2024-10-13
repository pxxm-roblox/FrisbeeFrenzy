--/SERVICES

--/TYPES

type FrisbeeData = {
	FrisbeePart: BasePart,
	FrisbeeDirection: Vector3,
	EventMaid: {},
}

--/MODULES

local gameDirectory = require(game:GetService("ReplicatedStorage").Shared.GameDirectory)
local RunService = game:GetService("RunService")
local remoteEvent: RemoteEvent = gameDirectory.GetReplicatedServiceFolder("FrisbeeClientReplicator").RemoteEvent
local directionRemoteReplicator: UnreliableRemoteEvent =
	gameDirectory.GetReplicatedServiceFolder("FrisbeeDirectionReplication").UnreliableRemoteEvent
local maidModule = gameDirectory.Require("Utils.MaidModule")
local globalFunctions = gameDirectory.GlobalFunctions

--/GLOBAL_VARIABLES

local FrisbeeClientSim = {}
local FrisbeeFunctions = {}
local frisbeeFolder: Folder = workspace.FrisbeesInGame

local mainPlayer: Player = game.Players.LocalPlayer

local BASE_MINIMUM_DISTANCE: number = 15

local MAXIMUM_KILL_DISTANCE: number = game.ReplicatedStorage.Constants.Frisbee.MAXIMUM_KILL_DISTANCE.Value

local FrisbeesInstanceData: { [number]: FrisbeeData } = {}

--/GLOBAL_FUNCTIONS

--<<Returns frisbeeInstance from ID passed
local function getFrisbeeInstanceFromID(id: number): Instance
	local MAX_TRIES: number = 3
	local frisbeeReturn: Instance = nil
	for _, frisbeeInstance: Instance in ipairs(frisbeeFolder:GetChildren()) do
		if frisbeeInstance:GetAttribute("ID") == id then
			frisbeeReturn = frisbeeInstance
			break
		end
	end
	if not frisbeeReturn then
		while not frisbeeReturn and MAX_TRIES > 0 do
			local newFrisbee: Instance = frisbeeFolder.ChildAdded:Wait()
			if newFrisbee:GetAttribute("ID") == id then
				frisbeeReturn = newFrisbee
			end
			MAX_TRIES -= 1
		end
	end
	return frisbeeReturn
end

--<<Checks if the frisbee travel distance is bigger than the distance between the frisbee and the player + kill magnitude
local function travelDistanceBiggerThanMagnitude(currentSpeed: number, distanceInBetween, dt: number): boolean
	return (currentSpeed * dt) > distanceInBetween
end

--/MODULAR_FUNCTIONS

function FrisbeeFunctions.Chasing(
	frisbeeData: FrisbeeData,
	data: { Target: Model, Speed: number, ThrowDirection: Vector3 }
): nil
	local frisbeePart: BasePart = frisbeeData.FrisbeePart
	local eventMaid = frisbeeData.EventMaid
	eventMaid:Clear()
	local enemyChar: Model = data.Target
	if enemyChar then
		local charHRP: BasePart = enemyChar:FindFirstChild("HumanoidRootPart")
		if charHRP then
			local frisbeeDirection = (data.ThrowDirection or frisbeePart:GetAttribute("ThrowDirection"))
			local frisbeeSpeed: number = (data.Speed or frisbeePart:GetAttribute("Speed"))
			local lerpCalculator = globalFunctions.UseFrisbeeDirectionLerping()
			eventMaid:Add(frisbeePart:GetAttributeChangedSignal("ThrowDirection"):Connect(function()
				lerpCalculator = globalFunctions.UseFrisbeeDirectionLerping()
				frisbeeDirection = frisbeePart:GetAttribute("ThrowDirection")
			end))
			return eventMaid:Add(RunService.PreSimulation:Connect(function(dt: number)
				local currentPosition: Vector3 = frisbeePart:GetAttribute("CurrentPosition")
				if
					currentPosition
					and (frisbeePart.Position - currentPosition).Magnitude
						> (BASE_MINIMUM_DISTANCE + (frisbeeSpeed * (dt + mainPlayer:GetNetworkPing() * 2)))
				then
					frisbeePart.CFrame = CFrame.new(currentPosition) * frisbeePart.CFrame.Rotation
				end
				local travelDistance: number = frisbeeSpeed * dt
				local vectorDifference: Vector3 = (charHRP.Position - frisbeePart.Position)
				if
					vectorDifference.Magnitude > MAXIMUM_KILL_DISTANCE
					and not travelDistanceBiggerThanMagnitude(frisbeeSpeed, vectorDifference.Magnitude, dt)
				then
					frisbeePart.CFrame =
						CFrame.lookAt(frisbeePart.Position + frisbeeDirection.Unit * travelDistance, charHRP.Position)
					frisbeeDirection = (frisbeeData.FrisbeeDirection or frisbeeDirection):Lerp(
						vectorDifference.Unit,
						lerpCalculator(travelDistance, vectorDifference.Magnitude)
					)
				end
			end))
		end
	end
end

function FrisbeeFunctions.Frozen(frisbeeData: FrisbeeData)
	local frisbeePart: BasePart = frisbeeData.FrisbeePart
	local eventMaid = frisbeeData.EventMaid
	eventMaid:Clear()
	local currentFrisbeeCFrame: Vector3 = CFrame.new(frisbeePart:GetAttribute("CurrentPosition"))
	if currentFrisbeeCFrame then
		frisbeePart.CFrame = currentFrisbeeCFrame
		task.wait()
		frisbeePart.CFrame = currentFrisbeeCFrame
	end
end

function FrisbeeClientSim.SetUp(args: { FrisbeeID: number })
	local frisbeePart: BasePart = getFrisbeeInstanceFromID(args.FrisbeeID)
	if frisbeePart and frisbeePart.Parent then
		local maidObject = maidModule.Create()
		local eventMaid = maidModule.Create()
		maidObject:Add(frisbeePart.Destroying:Connect(function()
			FrisbeesInstanceData[args.FrisbeeID] = nil
			return maidObject:Destroy()
		end))
		FrisbeesInstanceData[args.FrisbeeID] = {
			EventMaid = eventMaid,
			FrisbeePart = frisbeePart,
			FrisbeeDirection = Vector3.new(),
		}
	end
end

function FrisbeeClientSim.ChangeState(args: { ID: number, State: string, FrisbeeAttributes: { [string]: any } })
	local frisbeeInstanceData = FrisbeesInstanceData[args.ID]
	if frisbeeInstanceData then
		local indexedFunction = FrisbeeFunctions[args.State]
		if indexedFunction then
			return indexedFunction(frisbeeInstanceData, args.FrisbeeAttributes)
		else
			frisbeeInstanceData.EventMaid:Clear()
		end
	end
end

--/WORKSPACE

remoteEvent.OnClientEvent:Connect(function(dataTable: { Method: string, Args: { [string]: any } })
	local indexedMethod = FrisbeeClientSim[dataTable.Method]
	return (indexedMethod and indexedMethod(dataTable.Args))
end)

directionRemoteReplicator.OnClientEvent:Connect(function(frisbeeID: number, direction: Vector3)
	if direction and FrisbeesInstanceData[frisbeeID] then
		FrisbeesInstanceData[frisbeeID].FrisbeeDirection = direction
	end
end)

return FrisbeeClientSim
