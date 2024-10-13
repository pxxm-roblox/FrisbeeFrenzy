--/SERVICES

--/TYPES

--/MODULES

local gameDirectory = require(game:GetService("ReplicatedStorage").Shared.GameDirectory)
local maidModule = gameDirectory.Require("Utils.MaidModule")
local globalFunctions = gameDirectory.GlobalFunctions

--/GLOBAL_VARIABLES

local SpectateHandler = {}
local EventMaid = maidModule.Create()

local CurrentlySpectating: boolean = false

local mainPlayer: Player = game.Players.LocalPlayer
local spectateUI: ScreenGui = mainPlayer.PlayerGui:WaitForChild("SpectateUI")
local currentCamera: Camera = workspace.CurrentCamera

--/GLOBAL_FUNCTIONS

--Handles camera state based on currently spectating state
local function connectCameraState(spectateChar: Model)
	currentCamera.CameraType = Enum.CameraType.Custom
	currentCamera.CameraSubject = spectateChar.Humanoid
end

local function disconnectCameraState()
	local mainChar: Model? = mainPlayer.Character
	local charHumanoid: Humanoid? = mainChar and mainChar:FindFirstChildWhichIsA("Humanoid")
	currentCamera.CameraType = Enum.CameraType.Custom
	currentCamera.CameraSubject = charHumanoid
end

local function getNextCharacter(charactersInGame: { Model }, currentIndex): (Model, number)
	if currentIndex >= #charactersInGame then
		return charactersInGame[1], 1
	end
	return charactersInGame[currentIndex + 1], currentIndex + 1
end

local function getPreviousCharacter(charactersInGame: { Model }, currentIndex): (Model, number)
	if currentIndex <= 1 or currentIndex - 1 >= #charactersInGame then
		return charactersInGame[#charactersInGame], #charactersInGame
	end
	return charactersInGame[currentIndex - 1], currentIndex - 1
end

--Creates a new array with valid characters
local function updateCharacterArray(oldCharArray: { Model }): { Model }
	local newCharArray: { Model } = {}
	for _, mainChar: Model in ipairs(oldCharArray) do
		if globalFunctions.IsViableCharacter(mainChar) then
			table.insert(newCharArray, mainChar)
		end
	end
	return newCharArray
end

--Enables the spectate ui for the player
local function setUpAndEnableSpectateUI()
	if not spectateUI.Enabled then
		spectateUI.Enabled = true
		local charactersInGame: { Model } = workspace.InGame:GetChildren()
		local currentSpectateIndex: number = 1
		EventMaid:Add(function()
			spectateUI.Enabled = false
			CurrentlySpectating = false
			return disconnectCameraState()
		end)
		EventMaid:Add(spectateUI.StartSpectate.Activated:Connect(function()
			CurrentlySpectating = not CurrentlySpectating
			if CurrentlySpectating then
				charactersInGame = updateCharacterArray(charactersInGame)
				return connectCameraState(charactersInGame[1])
			end
			return disconnectCameraState()
		end))
		EventMaid:Add(spectateUI.NextArrow.Activated:Connect(function()
			charactersInGame = updateCharacterArray(charactersInGame)
			local nextChar: Model, nextIndex: number = getNextCharacter(charactersInGame, currentSpectateIndex)
			currentSpectateIndex = nextIndex
			return connectCameraState(nextChar)
		end))
		EventMaid:Add(spectateUI.PreviousArrow.Activated:Connect(function()
			charactersInGame = updateCharacterArray(charactersInGame)
			local prevChar: Model, prevIndex: number = getPreviousCharacter(charactersInGame, currentSpectateIndex)
			currentSpectateIndex = prevIndex
			return connectCameraState(prevChar)
		end))
	end
end

--Checks if player can spectate then calls set up
local function checkIfCanSpectate(mainChar: Model): boolean
	if
		mainChar
		and not mainChar:IsDescendantOf(workspace.InGame)
		and #workspace.InGame:GetChildren() > 1
		and not spectateUI.Enabled
	then
		setUpAndEnableSpectateUI()
		return true
	end
	return false
end

--/MODULAR_FUNCTIONS

function SpectateHandler.__init__()
	local CharMaid = maidModule.Create()
	mainPlayer.CharacterAppearanceLoaded:Connect(function(mainChar: Model)
		EventMaid:Clear()
		CharMaid:Clear()
		checkIfCanSpectate(mainChar)
		mainChar.AncestryChanged:Connect(function()
			return (mainChar:IsDescendantOf(workspace.InGame) and EventMaid:Clear())
		end)
		return CharMaid:Add(workspace.InGame.ChildAdded:Connect(function()
			return checkIfCanSpectate(mainPlayer.Character)
		end))
	end)
	workspace.InGame.ChildRemoved:Connect(function()
		if #workspace.InGame:GetChildren() <= 1 then
			return EventMaid:Clear()
		end
	end)
	return SpectateHandler
end

return SpectateHandler.__init__()
