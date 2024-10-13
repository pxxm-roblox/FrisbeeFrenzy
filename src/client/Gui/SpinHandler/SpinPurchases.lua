--/SERVICES

--/TYPES

--/MODULES

local gameDirectory = require(game:GetService("ReplicatedStorage").Shared.GameDirectory)
local CEnum = gameDirectory.CEnum
local playerDataClient = gameDirectory.Require("Client.PlayerDataClient")
local remoteFunction = gameDirectory.GetReplicatedServiceFolder("ShopUIHandler").RemoteFunction
playerDataClient.WaitForData()

--/GLOBAL_VARIABLES

local PurchaseSpins = {}

local mainPlayer: Player = game.Players.LocalPlayer
local mainGUI: ScreenGui = mainPlayer.PlayerGui:WaitForChild("MainGUI")
local buySpinsFrame: Frame = mainGUI.Frames.BuySpins
local spinFrame: Frame = mainGUI.Frames.SpinFrame
local buttonImageLabel: ImageLabel = buySpinsFrame.Purchases

local purchaseButtons: { ImageButton } = {
	buttonImageLabel.SpinCoins,
	buttonImageLabel["1Spin"],
	buttonImageLabel["5Spins"],
	buySpinsFrame.DiscountFrame.ImageLabel.DailyDiscount,
}

--/GLOBAL_FUNCTIONS

--/MODULAR_FUNCTIONS

for _, imageButton in ipairs(purchaseButtons) do
	imageButton.Activated:Connect(function()
		return remoteFunction:InvokeServer({
			Category = "Spins",
			Item = imageButton.Name,
		})
	end)
end

buySpinsFrame.Close.Activated:Connect(function()
	buySpinsFrame.Visible = false
end)

spinFrame.BuySpins.Activated:Connect(function()
	buySpinsFrame.Visible = true
end)

buttonImageLabel.SpinsLeft.Text = ("(%d left)"):format(
	3 - playerDataClient.GetData(CEnum.ClaimItems.SpinsBoughtWithCoins)
)

playerDataClient.OnDataChanged(CEnum.ClaimItems.SpinsBoughtWithCoins, function(spinAmount: number)
	buttonImageLabel.SpinsLeft.Text = ("(%d left)"):format(3 - spinAmount)
end)

return PurchaseSpins
