--/SERVICES

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

--/TYPES

--/MODULES

local gameDirectory = require(game:GetService("ReplicatedStorage").Shared.GameDirectory)
local playerDataClient = gameDirectory.Require("Client.PlayerDataClient")
playerDataClient.WaitForData()

--/GLOBAL_VARIABLES

local AmtIndicators = {}

local moneySound: Sound = ReplicatedStorage.Sounds.Money

local mainPlayer: Player = game.Players.LocalPlayer
local mainGui: ScreenGui = mainPlayer.PlayerGui:WaitForChild("MainGUI")
local moneyImageButton: ImageButton = mainGui.Buttons.CoinsButton
local coinAmountText: TextLabel = moneyImageButton.CoinAmount
local addMoneyPopUp: ImageLabel = mainGui.Frames.PopUps.CoinAdd.coinLabel
local coinAddText: TextLabel = addMoneyPopUp.multiplier

local spinBillboardUITextLabel: TextLabel = workspace.Spawn:WaitForChild("SpinSign").Display.SurfaceGui.TextLabel
local spinTextUI: TextLabel = mainGui.Frames.SpinFrame.SpinAmount.TextLabel

local money_names = {
	{ Req = 3, Str = "K" },
	{ Req = 6, Str = "M" },
	{ Req = 9, Str = "B" },
	{ Req = 12, Str = "T" },
}

--/GLOBAL_FUNCTIONS

local function formatMoneyBalance(balance): string
	local amount_money = balance
	local money_index = math.floor(math.log10(amount_money))
	local array_length = #money_names
	for n, tab in ipairs(money_names) do
		if money_index >= tab.Req then
			if n == array_length or money_index < money_names[n + 1].Req then
				local divided_number = (amount_money / (10 ^ tab.Req))
				return ("%.1f%s"):format(math.floor(divided_number * 10) / 10, tab.Str)
			end
		end
	end
	return tostring(amount_money)
end

--<<Handles tweening the pop up effect
local function useCoinAddPopUpEffect()
	local sessionFlag: number = 0
	return function(coinsAdded: number)
		local clockFlag: number = os.clock()
		sessionFlag = clockFlag
		local tweenInfo: TweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Cubic)
		coinAddText.Text = "+" .. coinsAdded
		TweenService:Create(addMoneyPopUp, tweenInfo, { ImageTransparency = 0 }):Play()
		TweenService:Create(coinAddText, tweenInfo, { TextTransparency = 0 }):Play()
		TweenService:Create(coinAddText.UIStroke, tweenInfo, { Transparency = 0 }):Play()
		task.delay(tweenInfo.Time + 0.5, function()
			if sessionFlag == clockFlag then
				TweenService:Create(addMoneyPopUp, tweenInfo, { ImageTransparency = 1 }):Play()
				TweenService:Create(coinAddText, tweenInfo, { TextTransparency = 1 }):Play()
				return TweenService:Create(coinAddText.UIStroke, tweenInfo, { Transparency = 1 }):Play()
			end
		end)
	end
end

local function useCoinUpdater()
	local lastBalance: number = playerDataClient.GetData("Coins")
	local coinAddPopUpEffect = useCoinAddPopUpEffect()
	return function(newBalance: number)
		coinAmountText.Text = formatMoneyBalance(newBalance)
		if newBalance > lastBalance then
			coinAddPopUpEffect(newBalance - lastBalance)
			SoundService:PlayLocalSound(moneySound)
		else
			SoundService:PlayLocalSound(ReplicatedStorage.Sounds.MoneySpent)
		end
		lastBalance = newBalance
	end
end

local function updateSpins(spinAmount: number)
	spinBillboardUITextLabel.Text = ("Spin (%d)"):format(spinAmount)
	spinTextUI.Text = ("Spins: %d"):format(spinAmount)
end

--/MODULAR_FUNCTIONS

coinAmountText.Text = formatMoneyBalance(playerDataClient.GetData("Coins"))
spinBillboardUITextLabel.Text = ("Spin (%d)"):format(playerDataClient.GetData("Spins"))
spinTextUI.Text = ("Spins: %d"):format(playerDataClient.GetData("Spins"))

playerDataClient.OnDataChanged("Coins", useCoinUpdater())
playerDataClient.OnDataChanged("Spins", updateSpins)

return AmtIndicators
