--/SERVICES

local UserInputService = game:GetService("UserInputService")

--/TYPES

--/MODULES

local gameDirectory = require(game:GetService("ReplicatedStorage").Shared.GameDirectory)
local globalFunctions = gameDirectory.GlobalFunctions
local mainServices = gameDirectory.GetServices()
local inputData = gameDirectory.Require("Client.InputHandler.Inputs")
local maidModule = gameDirectory.Require("Utils.MaidModule")
local movementData = gameDirectory.Require("Client.MovementHandler.Data")
local playerDataManager = gameDirectory.Require("Client.PlayerDataClient")
local abilityRemoteEvent: RemoteEvent = gameDirectory.GetReplicatedServiceFolder("AbilityHandler").RemoteEvent
playerDataManager.WaitForData()

--/GLOBAL_VARIABLES

local GrappleHandler = {}

local constantsFolder = game.ReplicatedStorage.Constants.Grapple
local resetFunction: () -> nil = nil

local MAX_GRAPPLE_DISTANCE: number = constantsFolder.GRAPPLE_MAX_DISTANCE.Value
local SELECTION_DISTANCE: number = constantsFolder.SELECTION_DISTANCE.Value
local GRAPPLE_SPEED: number = constantsFolder.GRAPPLE_SPEED.Value
local SLOW_DOWN_SPEED: number = 75

local grappleFolderPoints: Folder = workspace.GrapplePoints

local animationFolder = game.ReplicatedStorage.Animations

local grapplePoints: { BasePart } = {}
local selectedPart: BasePart = nil
local currentCamera: Camera = workspace.CurrentCamera
local mainPlayer: Player = mainServices.Players.LocalPlayer

--/GLOBAL_FUNCTIONS

--<<Adds grapple point into grapple points table
local function addGrappleInstanceIntoGrapplePoints(mainChild: Instance)
	if mainChild:IsA("Folder") then
		for _, child: BasePart in ipairs(mainChild:GetChildren()) do
			if child:IsA("BasePart") then
				table.insert(grapplePoints, child)
			elseif child:IsA("Folder") then
				addGrappleInstanceIntoGrapplePoints(child)
			end
		end
		return
	end
	table.insert(grapplePoints, mainChild)
end

--<<Checks if character is valid to grapple
local function isCharacterValidToGrapple(mainChar: Model): Model | boolean
	if playerDataManager.GetData("EquippedAbility") ~= "Grapple" then
		return false
	end
	if not mainChar or not mainChar.Parent or mainChar.Parent ~= workspace.InGame then
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

--<<Iterates through grapple points and checks if they are close enough, if they are enable billboard gui else disable
local function updateGrapplePointGui(grapplePoint: BasePart, enabled: boolean)
	local gui: BillboardGui = grapplePoint:FindFirstChild("GrappleIcon")
	if gui then
		if enabled and not gui.Enabled then
			gui.Enabled = true
		elseif not enabled and gui.Enabled then
			gui.Enabled = false
		end
	end
end

--<<Raycasts for any collisions along grapple path
local function raycastForCollisions(mainPosition: Vector3, selectedPartPosition: Vector3): RaycastResult | nil
	local raycastParams: RaycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = {
		workspace.InGame,
		workspace.FrisbeesInGame,
		workspace.GrapplePoints,
		workspace.Players,
	}
	return workspace:Raycast(mainPosition, selectedPartPosition - mainPosition, raycastParams)
end

--<<Returns the closest part to characters mouse if it is within range
local function getClosestGrapplePoint(mainPosition: Vector3): BasePart?
	local closestPart: BasePart, closestDistance: number = nil, math.huge
	local middlePosition: Vector3 = (
		inputData.PlayerDevice == "PC" and UserInputService:GetMouseLocation()
		or Vector2.new(currentCamera.ViewportSize.X / 2, currentCamera.ViewportSize.Y / 2)
	)
	for _, grapplePoint: BasePart in ipairs(grapplePoints) do
		if
			(grapplePoint.Position - mainPosition).Magnitude <= MAX_GRAPPLE_DISTANCE
			and not raycastForCollisions(mainPosition, grapplePoint.Position)
		then
			updateGrapplePointGui(grapplePoint, true)
			local position3D: Vector3, visible: boolean = currentCamera:WorldToViewportPoint(grapplePoint.Position)
			if visible then
				local position2D: Vector2 = Vector2.new(position3D.X, position3D.Y)
				local magDifference: number = (position2D - middlePosition).Magnitude
				if visible and magDifference < closestDistance then
					closestDistance = magDifference
					closestPart = grapplePoint
				end
			end
			continue
		end
		updateGrapplePointGui(grapplePoint, false)
	end
	if closestPart and closestDistance <= SELECTION_DISTANCE then
		return closestPart
	end
	return nil
end

--<<Switches the grapple point gui colour based on if it is selected or not
local function switchGrapplePointGuiColour(grapplePoint: BasePart, selected: boolean)
	local gui: BillboardGui = grapplePoint:FindFirstChild("GrappleIcon")
	if gui then
		if selected then
			gui.Image.ImageColor3 = Color3.fromRGB(0, 255, 0)
		else
			gui.Image.ImageColor3 = Color3.fromRGB(255, 255, 0)
		end
	end
end

--<<Checks if linear velocity state is valid to use
local function isLinearVelocityValid(linearVelocity: LinearVelocity): boolean
	return linearVelocity:GetAttribute("State") == 0
end

--<<Suspends character with linear velocity
local function suspendPlayerCharacterLinearVelocity(linearVelocity: LinearVelocity)
	linearVelocity.VectorVelocity = Vector3.new()
	linearVelocity.MaxForce = 1e5
end

--<<Sets velocity towards linear velocity and stops at a calculated time
local function launchPlayerTowardsGrapple(
	currentPosition: Vector3,
	grapplePosition: Vector3,
	linearVelocity: LinearVelocity,
	onVelocityEnd: () -> ()
): boolean
	local vectorDifference: Vector3 = (grapplePosition - currentPosition)
	local travelTime: number = vectorDifference.Magnitude / GRAPPLE_SPEED
	linearVelocity.VectorVelocity = vectorDifference.Unit * GRAPPLE_SPEED
	linearVelocity.MaxForce = 1e5
	return task.delay(travelTime, function()
		movementData.SetCurrentlyGrappling(false)
		if isLinearVelocityValid(linearVelocity) then
			local mainPart: BasePart = linearVelocity.Parent
			linearVelocity.VectorVelocity = Vector3.new()
			linearVelocity.MaxForce = 0
			mainPart.AssemblyLinearVelocity = mainPart.AssemblyLinearVelocity.Unit * SLOW_DOWN_SPEED
		end
		return onVelocityEnd and onVelocityEnd()
	end)
end

--<<Enables string effect
local function enableGrappleString(mainChar: Model, oldSelectedPart: BasePart)
	local beamEffect: Beam = mainChar["Right Arm"]:FindFirstChild("GrappleString")
	if beamEffect then
		local attachment1: Attachment = oldSelectedPart:FindFirstChildWhichIsA("Attachment")
			or Instance.new("Attachment")
		attachment1.Parent = oldSelectedPart
		beamEffect.Attachment1 = attachment1
	end
end

--<Disables string effect
local function disableGrappleString(mainChar: Model)
	local beamEffect: Beam = mainChar["Right Arm"]:FindFirstChild("GrappleString")
	if beamEffect then
		beamEffect.Attachment1 = nil
	end
end

local function initializeGrappleHandler(): () -> nil
	local maidObject = maidModule.Create()
	addGrappleInstanceIntoGrapplePoints(workspace.GrapplePoints)

	maidObject:Add(mainServices.RunService.PostSimulation:Connect(function()
		local mainChar: Model = isCharacterValidToGrapple(mainPlayer.Character)
		if mainChar then
			local oldSelectedPart: BasePart? = selectedPart
			selectedPart = getClosestGrapplePoint(mainChar.HumanoidRootPart.Position)
			if selectedPart ~= oldSelectedPart then
				if oldSelectedPart then
					switchGrapplePointGuiColour(oldSelectedPart, false)
				end
				if selectedPart then
					switchGrapplePointGuiColour(selectedPart, true)
				end
			end
		end
	end))

	maidObject:AddMultiple(
		grappleFolderPoints.ChildAdded:Connect(addGrappleInstanceIntoGrapplePoints),

		grappleFolderPoints.ChildRemoved:Connect(function(mainChild: BasePart | Folder)
			if mainChild:IsA("Folder") then
				for x, grapplePoint: BasePart in ipairs(grapplePoints) do
					if grapplePoint:IsDescendantOf(mainChild) then
						grapplePoints[x] = nil
					end
				end
				return
			end
			local index: number = table.find(grapplePoints, mainChild)
			if index then
				grapplePoints[index] = nil
			end
		end)
	)

	return function()
		selectedPart = nil
		for _, grapplePart: BasePart in ipairs(grapplePoints) do
			updateGrapplePointGui(grapplePart, false)
		end
		table.clear(grapplePoints)
		return maidObject:Destroy()
	end
end

--/MODULAR_FUNCTIONS

--<<On grapple input
function GrappleHandler.OnGrapple(): boolean
	local mainChar: Model = isCharacterValidToGrapple(mainPlayer.Character)
	local oldSelectedPart: BasePart? = selectedPart
	if mainChar and oldSelectedPart then
		local linearVelocity: LinearVelocity = mainChar.HumanoidRootPart:FindFirstChild("LinearVelocity")
		local charAnimator: Animator = mainChar.Humanoid.Animator
		local playerGrappled: boolean = false
		if linearVelocity and isLinearVelocityValid(linearVelocity) and not movementData.IsCurrentlyGrappling() then
			movementData.SetCurrentlyGrappling(true)
			suspendPlayerCharacterLinearVelocity(linearVelocity)
			enableGrappleString(mainChar, oldSelectedPart)
			abilityRemoteEvent:FireServer({
				Time = (oldSelectedPart.Position - mainChar.HumanoidRootPart.Position).Magnitude / GRAPPLE_SPEED,
				Part = oldSelectedPart,
			})
			globalFunctions.PlayAnimationMarker(charAnimator, {
				Animation = animationFolder.Grapple,
				Marker = "Action",
				Function = function()
					if isLinearVelocityValid(linearVelocity) then
						playerGrappled = true
						launchPlayerTowardsGrapple(
							mainChar.HumanoidRootPart.Position,
							oldSelectedPart.Position,
							linearVelocity,
							function()
								return disableGrappleString(mainChar)
							end
						)
					end
				end,
				OnStop = function()
					if not playerGrappled then
						disableGrappleString(mainChar)
						return movementData.SetCurrentlyGrappling(false)
					end
				end,
			})
			return true
		end
	end
	return false
end

--/WORKSPACE

if playerDataManager.GetData("EquippedAbility") == "Grapple" then
	resetFunction = initializeGrappleHandler()
end

playerDataManager.OnDataChanged("EquippedAbility", function(newAbility: string)
	if resetFunction then
		resetFunction()
		resetFunction = nil
	end
	if newAbility == "Grapple" then
		resetFunction = initializeGrappleHandler()
	end
end)

return GrappleHandler
