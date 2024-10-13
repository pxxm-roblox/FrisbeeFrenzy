--/SERVICES

local Players = game:GetService("Players")

--/TYPES

--/MODULES

--/GLOBAL_VARIABLES

local ShopHandlerUIHandler = {}

local mainPlayer: Player = Players.LocalPlayer
local mainGUI: ScreenGui = mainPlayer.PlayerGui:WaitForChild("MainGUI")
local coinButton: ImageButton = mainGUI.Buttons.CoinsButton
local shopFrame: Frame = mainGUI.Frames.ShopFrame
local shopButton: ImageButton = mainGUI.Buttons.ShopButton
local closeButton: ImageButton = shopFrame.Close
local mainFrames: { [string]: Frame } = {
	Gloves = require(script.GloveFrame).MainFrame,
	Abilities = require(script.Abilities).MainFrame,
	Coins = require(script.CoinPurchases).MainFrame,
	Passes = require(script.PassesFrameHandler).MainFrame,
}
local currentFrame: Frame = mainFrames.Gloves

--/GLOBAL_FUNCTIONS

--<<Shows shop frame
local function showShopFrame()
	shopFrame.Visible = true
end

--<<Hides shop frame
local function hideShopFrame()
	shopFrame.Visible = false
end

local function handleCoinSectionChange()
	local selectedFrame: Frame = mainFrames.Coins
	shopFrame.Visible = true
	if currentFrame ~= selectedFrame then
		currentFrame.Visible = false
		currentFrame = mainFrames.Coins
		currentFrame.Visible = true
	end
end

--/MODULAR_FUNCTIONS

shopButton.MouseButton1Click:Connect(showShopFrame)
shopButton.TouchTap:Connect(showShopFrame)
closeButton.MouseButton1Click:Connect(hideShopFrame)
closeButton.TouchTap:Connect(hideShopFrame)

for _, button: ImageButton in ipairs(shopFrame.ShopFrame.SectionButtons:GetChildren()) do
	if mainFrames[button.Name] then
		local function handleSectionChange()
			local selectedFrame: Frame = mainFrames[button.Name]
			if currentFrame ~= selectedFrame then
				currentFrame.Visible = false
				currentFrame = mainFrames[button.Name]
				currentFrame.Visible = true
			end
		end
		button.MouseButton1Click:Connect(handleSectionChange)
		button.TouchTap:Connect(handleSectionChange)
	end
end

coinButton.MouseButton1Click:Connect(handleCoinSectionChange)
coinButton.TouchTap:Connect(handleCoinSectionChange)

ShopHandlerUIHandler.HandleCoinSectionChange = handleCoinSectionChange

return ShopHandlerUIHandler
