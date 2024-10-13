--/SERVICES

--/TYPES

--/MODULES

local gameDirectory = require(game:GetService("ReplicatedStorage").Shared.GameDirectory)

--/GLOBAL_VARIABLES

local CoinPurchases = {}

local mainPlayer: Player = game.Players.LocalPlayer
local mainGUI: ScreenGui = mainPlayer.PlayerGui:WaitForChild("MainGUI")
local coinsFrame: Frame = mainGUI.Frames.ShopFrame.CoinsFrame
local remoteFunction: RemoteFunction = gameDirectory.GetReplicatedServiceFolder("ShopUIHandler").RemoteFunction

--/GLOBAL_FUNCTIONS

--<<Returns a function that handles communication with server
local function useOnPurchaseFunction(coinAmt: string)
	return function()
		return remoteFunction:InvokeServer({
			Category = "Coin",
			Item = coinAmt,
		})
	end
end

--/MODULAR_FUNCTIONS

for _, uiFolder: Folder in ipairs(coinsFrame.Coins:GetChildren()) do
	local onInteract = useOnPurchaseFunction(uiFolder.Name)
	uiFolder.ImageButton.MouseButton1Click:Connect(onInteract)
	uiFolder.ImageButton.TouchTap:Connect(onInteract)
end

CoinPurchases.MainFrame = coinsFrame

return CoinPurchases
