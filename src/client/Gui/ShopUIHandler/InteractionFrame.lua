--/SERVICES

--/TYPES

--/MODULES

local gameDirectory = require(game:GetService("ReplicatedStorage").Shared.GameDirectory)
local maidModule = gameDirectory.Require("Utils.MaidModule")

--/GLOBAL_VARIABLES

local InteractionFrameHandler = {}

local mainPlayer: Player = game.Players.LocalPlayer
local mainGUI: ScreenGui = mainPlayer.PlayerGui:WaitForChild("MainGUI")
local shopFrame: Frame = mainGUI.Frames.ShopFrame
local itemInteractFrame: Frame = shopFrame.ItemInteractFrame
local interactButton: ImageButton = itemInteractFrame.InteractionButton
local maidObject = maidModule.Create()
local inSession: boolean = false

--/GLOBAL_FUNCTIONS

local function useHandleInteract(onInteract: () -> ())
	return function()
		inSession = true
		onInteract()
		inSession = false
	end
end

--/MODULAR_FUNCTIONS

function InteractionFrameHandler.SetUpInteraction(dataTable: {
	Title: string,
	Description: string?,
	ButtonStrokeColor: Color3?,
	ButtonText: string,
	OnInteract: (() -> ())?,
})
	if not inSession then
		maidObject:Clear()
		itemInteractFrame.ItemInteract.Text = dataTable.Title
		interactButton.TextLabel.Text = dataTable.ButtonText
		if dataTable.ButtonStrokeColor then
			interactButton.TextLabel.UIStroke.Color = dataTable.ButtonStrokeColor
		else
			interactButton.TextLabel.UIStroke.Color = Color3.fromRGB(46, 100, 44)
		end
		if dataTable.Description then
			itemInteractFrame.Description.Text = dataTable.Description
		else
			itemInteractFrame.Description.Text = ""
		end
		itemInteractFrame.Visible = true
		if dataTable.OnInteract then
			local handleInteract = useHandleInteract(dataTable.OnInteract)
			maidObject:AddMultiple(
				interactButton.MouseButton1Click:Connect(handleInteract),
				interactButton.TouchTap:Connect(handleInteract)
			)
		end
	end
end

function InteractionFrameHandler.Clear()
	maidObject:Clear()
	itemInteractFrame.Visible = false
end

return InteractionFrameHandler
