--/SERVICES

local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

--/TYPES

--/MODULES

local gameDirectory = require(game:GetService("ReplicatedStorage").Shared.GameDirectory)
local mainServices = gameDirectory.GetServices()
local remoteEvent: RemoteEvent = gameDirectory.GetReplicatedServiceFolder("FrisbeeInputHandler").RemoteEvent
local abilityRemoteEvent: RemoteEvent = gameDirectory.GetReplicatedServiceFolder("AbilityHandler").RemoteEvent
local promiseModule = gameDirectory.Require("Utils.Promise")
local abilitiesHandler_Client = gameDirectory.RequireAsync("Client.AbilitiesHandler_Client")
local grappleHandler = gameDirectory.Require("Client.GrappleHandler")
local playerDataClient = gameDirectory.Require("Client.PlayerDataClient")
local inputData = require(script.Inputs)

--/GLOBAL_VARIABLES

local InputHandler = {}
local inputFunctions = {}
local catchAnimationID: number = ReplicatedStorage.Animations.Catch.AnimationId
local mainPlayer: Player = mainServices.Players.LocalPlayer
local mainGui: ScreenGui = mainPlayer.PlayerGui:WaitForChild("MainGUI")
local buttonsFolder: Folder = mainGui.Buttons
local currentCamera: Camera = workspace.CurrentCamera
local currentlyThrowing: boolean = false

--/GLOBAL_FUNCTIONS

--<<Plays random animation and calls function passed on marker
local function playRandomAnimationMarker(
	charAnimator: Animator,
	args: {
		AnimationFolder: Folder,
		Marker: string,
		Function: () -> (),
		OnStop: () -> (),
	}
)
	local animations: { Animation } = args.AnimationFolder:GetChildren()
	local animationTrack: AnimationTrack = charAnimator:LoadAnimation(animations[math.random(1, #animations)])
	local animCon: RBXScriptConnection
	animCon = animationTrack:GetMarkerReachedSignal(args.Marker):Connect(args.Function)
	promiseModule.WrapEvent(animationTrack.Stopped, animationTrack.Length + 1):Then(function()
		animCon:Disconnect()
		animationTrack:Destroy()
		return (args.OnStop and args.OnStop())
	end)
	return animationTrack:Play(0.15, nil, 1.7)
end

--<<Gets shoot direction based on user device
local function getShootDirection(mainChar: Model): Vector3
	if not mainChar then
		return
	end
	if inputData.PlayerDevice == "PC" then
		local mousePosition: Vector2 = UserInputService:GetMouseLocation()
		local viewportRay: Ray = currentCamera:ViewportPointToRay(mousePosition.X, mousePosition.Y)
		return (viewportRay.Origin + viewportRay.Direction * 100) - mainChar.HumanoidRootPart.Position
	end
	return currentCamera.CFrame.LookVector
end

--<<Returns if character is holding a frisbee
local function isCharacterHoldingFrisbee(mainChar: Model): boolean
	for _, frisbeePart: Instance in ipairs(workspace.FrisbeesInGame:GetChildren()) do
		if frisbeePart:GetAttribute("Target") == mainChar.Name and frisbeePart:GetAttribute("State") == "Held" then
			return true
		end
	end
	return false
end

--<<Returns a target if there is one close to center of screen
local function getTargettedPlayer(): Model?
	local middlePosition: Vector3 = (
		inputData.PlayerDevice == "PC" and UserInputService:GetMouseLocation()
		or Vector2.new(currentCamera.ViewportSize.X / 2, currentCamera.ViewportSize.Y / 2)
	)
	local closestChar: Model, magnitude: number = nil, math.huge
	for _, mainChar: Model in ipairs(workspace.InGame:GetChildren()) do
		if mainChar ~= mainPlayer.Character then
			local position3D: Vector3, visible: boolean =
				currentCamera:WorldToViewportPoint(mainChar.HumanoidRootPart.Position)
			local position2D: Vector2 = Vector2.new(position3D.X, position3D.Y)
			local magDifference: number = (position2D - middlePosition).Magnitude
			if visible and magDifference < magnitude then
				magnitude = magDifference
				closestChar = mainChar
			end
		end
	end
	return closestChar
end

--Stops the catching animation if it is playing
local function stopCatchingAnimation(mainChar: Model)
	local charAnimator: Animator = mainChar.Humanoid.Animator
	for _, animationTrack: AnimationTrack in ipairs(charAnimator:GetPlayingAnimationTracks()) do
		if animationTrack.Animation.AnimationId == catchAnimationID then
			animationTrack:Stop()
		end
	end
end

--<<Handles throwing input
local function handleThrowingInput()
	if currentlyThrowing or not isCharacterHoldingFrisbee(mainPlayer.Character) then
		return false
	end
	currentlyThrowing = true
	local mainChar: Model = mainPlayer.Character
	remoteEvent:FireServer({
		Action = "StartThrow",
		Args = {
			Target = getTargettedPlayer(),
		},
	})
	stopCatchingAnimation(mainChar)
	playRandomAnimationMarker(mainChar.Humanoid.Animator, {
		AnimationFolder = ReplicatedStorage.Animations.Throws,
		Marker = "Throw",
		Function = function()
			return remoteEvent:FireServer({
				Action = "Throw",
				Args = {
					CharCFrame = mainChar.HumanoidRootPart.CFrame,
					CameraDirection = getShootDirection(mainChar),
					Target = getTargettedPlayer(),
				},
			})
		end,
		OnStop = function()
			currentlyThrowing = false
		end,
	})
	return true
end

--<<Processes user input and fires server accordingly
local function processUserInput(actionName: string, inputState: Enum.UserInputState)
	if
		inputState == Enum.UserInputState.Begin
		and mainPlayer.Character
		and mainPlayer.Character.Parent
		and mainPlayer.Character:FindFirstChild("HumanoidRootPart")
	then
		return inputFunctions[actionName]()
	end
end

--/MODULAR_FUNCTIONS

function inputFunctions.Main()
	if not currentlyThrowing then
		return handleThrowingInput() or remoteEvent:FireServer({
			Action = "Catch",
		})
	end
end

function inputFunctions.Grapple()
	return grappleHandler.OnGrapple()
end

function inputFunctions.Ability()
	if abilitiesHandler_Client.CanUseAbility() then
		local abilityName: string = playerDataClient.GetData("EquippedAbility")
		if abilitiesHandler_Client.IsClientAbility(abilityName) then
			return abilitiesHandler_Client.HandleClientAbility(abilityName)
		end
		return abilityRemoteEvent:FireServer({
			LookVector = mainPlayer.Character.HumanoidRootPart.CFrame.LookVector,
		})
	end
end

function InputHandler.__init__()
	if inputData.PlayerDevice ~= "Mobile" then
		for action, input in next, inputData[inputData.PlayerDevice] do
			if typeof(input) == "table" then
				ContextActionService:BindAction(action, processUserInput, false, unpack(input))
				continue
			end
			ContextActionService:BindAction(action, processUserInput, false, input)
		end
	else
		buttonsFolder.CatchDisplay.Inner.Visible = false
		buttonsFolder.AbilityDisplay.Inner.Visible = false
		UserInputService.TouchTapInWorld:Connect(function(_, processedByUI)
			if not processedByUI then
				return inputFunctions.Main()
			end
		end)
		buttonsFolder.CatchDisplay.Activated:Connect(function()
			return inputFunctions.Main()
		end)
		buttonsFolder.AbilityDisplay.Activated:Connect(function()
			return inputFunctions.Ability()
		end)
	end
	return InputHandler
end

return InputHandler.__init__()
