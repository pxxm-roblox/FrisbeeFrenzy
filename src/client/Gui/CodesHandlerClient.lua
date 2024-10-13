--/SERVICES

--/TYPES

--/MODULES

local gameDirectory = require(game:GetService("ReplicatedStorage").Shared.GameDirectory)
local globalFunctions = gameDirectory.GlobalFunctions
local remoteFunction: RemoteFunction = gameDirectory.GetReplicatedServiceFolder("CodesHandler").RemoteFunction

--/GLOBAL_VARIABLES

local codesHandlerClient = {}

local processingCode: boolean = false

local mainPlayer: Player = game:GetService("Players").LocalPlayer
local mainGUI: ScreenGui = mainPlayer.PlayerGui:WaitForChild("MainGUI")
local codesFrame: ImageLabel = mainGUI.Frames.CodesFrame
local codesButton: ImageButton = mainGUI.Buttons.CodesButton
local textBox: TextBox = codesFrame.TextBox
local redeemButton: ImageButton = codesFrame.Redeem

local successPopUp: (string) -> () = globalFunctions.UsePopUp(codesFrame.SuccessPopUp.Success, 0.5)

local invalidPopUp: (string) -> () = globalFunctions.UsePopUp(codesFrame.InvalidPopUp.Invalid, 0.5)

--/GLOBAL_FUNCTIONS

--<<Submits the code and handles the response accordingly
local function submitInputtedCode()
	if not processingCode then
		processingCode = true
		if remoteFunction:InvokeServer(textBox.Text) then
			successPopUp("SUCCESSFULLY REDEEMED!")
		else
			invalidPopUp("INVALID!")
		end
		processingCode = false
	end
end

--/MODULAR_FUNCTIONS

redeemButton.Activated:Connect(submitInputtedCode)

codesFrame.Close.Activated:Connect(function()
	codesFrame.Visible = false
end)

codesButton.Activated:Connect(function()
	codesFrame.Visible = true
end)

return codesHandlerClient
