--/SERVICES

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--/TYPES

--/MODULES

local gameDirectory = require(game:GetService("ReplicatedStorage").Shared.GameDirectory)
local playerDataReplicator = gameDirectory.Require("Client.PlayerDataClient")
local interactFrameHandler = require(script.Parent.InteractionFrame)
local remoteFunction: RemoteFunction = gameDirectory.GetReplicatedServiceFolder("ShopUIHandler").RemoteFunction
playerDataReplicator.WaitForData()

--/GLOBAL_VARIABLES

local GloveFrameHandler = {}

local gloveModelsFolder: Folder = ReplicatedStorage.Gloves

local mainPlayer: Player = Players.LocalPlayer
local mainGUI: ScreenGui = mainPlayer.PlayerGui:WaitForChild("MainGUI")
local glovesFrame: Frame = mainGUI.Frames.ShopFrame.GlovesFrame
local assetsFolder: Folder = glovesFrame.Assets
local scrollingFrame: ScrollingFrame = glovesFrame.ScrollingFrame

--/GLOBAL_FUNCTIONS

--<<Handles equipping function
local function useEquipFunction(gloveName: string)
	return function()
		if remoteFunction:InvokeServer({
			Category = "Glove",
			Item = gloveName,
		}) then
			interactFrameHandler.Clear()
		end
	end
end

--<<Modifies data table depending if the player already equipped glove
local function modifyInteractData(gloveName: string, equippedGlove: string, dataTable)
	if gloveName == equippedGlove then
		dataTable.ButtonText = "Equipped"
		dataTable.ButtonStrokeColor = Color3.fromRGB(255, 0, 0)
		return
	end
	dataTable.OnInteract = useEquipFunction(gloveName)
end

--<<Returns a function that calls the server when the button is pressed
local function getButtonPressFunction(gloveName: string)
	return function()
		local equippedGlove: string = playerDataReplicator.GetData("EquippedGloveSkin")
		local dataTable = {
			Title = gloveName,
			ButtonText = "Equip",
		}
		modifyInteractData(gloveName, equippedGlove, dataTable)
		return interactFrameHandler.SetUpInteraction(dataTable)
	end
end

--<<Positions gloves in the viewport
local function positionGlovesInViewPort(gloveFolder: Folder, camera: Camera)
	local Z_OFFSET: number = 2.5
	local X_OFFSET: number = 0.85
	camera.CFrame = CFrame.new(0, 0, 0)
	local cameraCFrame: CFrame = camera.CFrame
	for _, glove: Model in ipairs(gloveFolder:GetChildren()) do
		glove.PrimaryPart.PivotOffset = CFrame.new(0, 0, 0)
		local x_multiplier: number = glove.Name == "Right" and -1 or 1
		glove:PivotTo(
			CFrame.lookAt(cameraCFrame.Position + cameraCFrame.LookVector * Z_OFFSET, cameraCFrame.Position)
				* CFrame.new(x_multiplier * X_OFFSET, 0, 0)
				* CFrame.Angles(0, math.pi, 0)
		)
	end
end

--<<Creates glove frame and sets it up
local function createGloveFrame(gloveFolder: Folder): Frame
	local frameClone: Frame = assetsFolder[gloveFolder.Parent.Name .. "Item"]:Clone()
	local button: TextButton = frameClone.Button
	local onButtonInteract: () -> () = getButtonPressFunction(gloveFolder.Name)
	local viewPortFrame: ViewportFrame = frameClone.ImageLabel.GloveDisplay
	local viewPortCamera: Camera = Instance.new("Camera")
	local gloveFolderClone: Folder = gloveFolder:Clone()

	positionGlovesInViewPort(gloveFolderClone, viewPortCamera)
	viewPortFrame.CurrentCamera = viewPortCamera
	viewPortCamera.Parent = viewPortFrame
	button.MouseButton1Click:Connect(onButtonInteract)
	button.TouchTap:Connect(onButtonInteract)
	gloveFolderClone.Parent = viewPortFrame
	frameClone.ImageLabel.TextLabel.Text = gloveFolder.Name
	frameClone.Visible = true
	return frameClone
end

--<<Sets up all glove frames from player owned gloves
local function setupGloveFrames()
	local ownedGloveSkins: { string } = playerDataReplicator.GetData("GloveSkins")
	for _, rarityFolder: Folder in ipairs(gloveModelsFolder:GetChildren()) do
		for _, gloveFolder: Folder in ipairs(rarityFolder:GetChildren()) do
			if table.find(ownedGloveSkins, gloveFolder.Name) then
				local gloveFrame: Frame = createGloveFrame(gloveFolder)
				gloveFrame.Parent = scrollingFrame
			end
		end
	end
end

--/MODULAR_FUNCTIONS

setupGloveFrames()
playerDataReplicator.OnDataChanged("GloveSkins", function(newGlove: string)
	for _, rarityFolder: Folder in ipairs(gloveModelsFolder:GetChildren()) do
		local gloveFolder: Folder? = rarityFolder:FindFirstChild(newGlove)
		if gloveFolder then
			local gloveFrame: Frame = createGloveFrame(gloveFolder)
			gloveFrame.Parent = scrollingFrame
		end
	end
end)
GloveFrameHandler.MainFrame = glovesFrame
return GloveFrameHandler
