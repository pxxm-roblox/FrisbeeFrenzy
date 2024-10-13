--/SERVICES

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--/TYPES

--/MODULES

local gameDirectory = require(game:GetService("ReplicatedStorage").Shared.GameDirectory)
local TweenService = game:GetService("TweenService")
local crateRollRemote: RemoteEvent = gameDirectory.GetReplicatedServiceFolder("CrateRoller").RemoteEvent

--/GLOBAL_VARIABLES

local AMT_FRAMES: number = 60
local WINNER_POSITION: number = 55

local CrateRollGUI = {}

local mainPlayer: Player = game.Players.LocalPlayer
local crateRollUI: ScreenGui = mainPlayer.PlayerGui:WaitForChild("CrateGui")
local itemUIFrameFolder: Folder = crateRollUI.Assets
local itemFrameSize: UDim2 = itemUIFrameFolder.CommonItem.Size
local spinnerFrame: Frame = crateRollUI.Main.Spinner.SpinnerFrame

local constantsFolder: Folder = ReplicatedStorage.Constants.Crates

local proximityPrompts: { ProximityPrompt } = {
	workspace.Spawn:WaitForChild("NormalChest"):WaitForChild("Main").ProximityPrompt,
	workspace.Spawn:WaitForChild("NormalChest"):WaitForChild("Main").ProximityPrompt,
}

--/GLOBAL_FUNCTIONS

--<<Destroys all glove frames
local function destroyGloveFrames()
	for _, frame: Frame in ipairs(spinnerFrame:GetChildren()) do
		if frame:IsA("Frame") then
			frame:Destroy()
		end
	end
end

--<<Enables/disables proximity prompts
local function toggleProximityPrompts(enabled: boolean)
	for _, proximPrompt: ProximityPrompt in ipairs(proximityPrompts) do
		proximPrompt.Enabled = enabled
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
	local frameClone: Frame = itemUIFrameFolder[gloveFolder.Parent.Name .. "Item"]:Clone()
	local viewPortFrame: ViewportFrame = frameClone.ImageLabel.GloveDisplay
	local viewPortCamera: Camera = Instance.new("Camera")
	local gloveFolderClone: Folder = gloveFolder:Clone()
	viewPortCamera.Parent = viewPortFrame
	viewPortFrame.CurrentCamera = viewPortCamera
	positionGlovesInViewPort(gloveFolderClone, viewPortCamera)
	gloveFolderClone.Parent = viewPortFrame
	frameClone.ImageLabel.TextLabel.Text = gloveFolder.Name
	frameClone.Visible = true
	return frameClone
end

--<<Parents the table of item frames in random order
local function parentItemFrames(itemFrames: { Frame }, selectedGloveFrame: Frame)
	local currentIndex: number = 1
	while #itemFrames > 0 do
		if currentIndex == WINNER_POSITION then
			selectedGloveFrame.Parent = spinnerFrame
		else
			local randomIndex: number = math.random(1, #itemFrames)
			itemFrames[randomIndex].Parent = spinnerFrame
			table.remove(itemFrames, randomIndex)
		end
		currentIndex += 1
	end
end

--<<Handles the rolling animation
local function handleUIRollingAnimation()
	local POINTER_OFFSET: number = 0.468

	local originalFramePosition: UDim2 = spinnerFrame.Position
	local travelPosition: UDim2 = UDim2.fromScale(
		(originalFramePosition.X.Scale + POINTER_OFFSET) - (itemFrameSize.X.Scale * (WINNER_POSITION - 0.5)),
		originalFramePosition.Y.Scale
	)
	local tweenTime: number = math.random(10, 12)
	local mainTween: Tween = TweenService:Create(spinnerFrame, TweenInfo.new(tweenTime, Enum.EasingStyle.Quart), {
		Position = travelPosition,
	})
	mainTween:Play()
	mainTween.Completed:Wait()
end

--<<Sets up the roll ui accordingly, returns ui object of the rolled glove
local function setUpRollUI(amtGloves: number, crateType: string, gloveFolder: Folder): Frame
	local itemFrames: { Frame } = {}
	local rolledGloveFrame: Frame = nil
	for _, rarityRate: NumberValue in ipairs(constantsFolder[crateType]:GetChildren()) do
		local amtCreate: number = amtGloves * (rarityRate.Value / 100)
		local glovesTable: { Folder } = ReplicatedStorage.Gloves[rarityRate.Name]:GetChildren()
		if amtCreate < 1 then
			amtCreate = 1
		else
			amtCreate = math.floor(amtCreate)
		end
		for _ = 1, amtCreate do
			if not rolledGloveFrame and gloveFolder.Parent.Name == rarityRate.Name then
				rolledGloveFrame = createGloveFrame(gloveFolder)
			else
				table.insert(itemFrames, createGloveFrame(glovesTable[math.random(1, #glovesTable)]))
			end
		end
	end
	return parentItemFrames(itemFrames, rolledGloveFrame)
end

--/MODULAR_FUNCTIONS

crateRollRemote.OnClientEvent:Connect(function(dataTable: { Glove: Folder, Crate: string })
	toggleProximityPrompts(false)
	spinnerFrame.Size = UDim2.fromScale(AMT_FRAMES * itemFrameSize.X.Scale, spinnerFrame.Size.Y.Scale)
	spinnerFrame.Position = UDim2.fromScale((spinnerFrame.Size.X.Scale / 2), spinnerFrame.Position.Y.Scale)
	setUpRollUI(AMT_FRAMES, dataTable.Crate, dataTable.Glove)
	crateRollUI.Enabled = true
	handleUIRollingAnimation()
	crateRollUI.Enabled = false
	crateRollRemote:FireServer()
	destroyGloveFrames()
	toggleProximityPrompts(true)
end)

return CrateRollGUI
