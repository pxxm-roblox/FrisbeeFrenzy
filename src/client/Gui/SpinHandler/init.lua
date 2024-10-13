--/SERVICES

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

--/TYPES

--/MODULES

local gameDirectory = require(game:GetService("ReplicatedStorage").Shared.GameDirectory)
local remoteFunction = gameDirectory.GetReplicatedServiceFolder("SpinHandler").RemoteFunction
local proximityHandler = gameDirectory.Require("Client.ProximityHandler")
local popUpHandler = gameDirectory.RequireAsync("Client.Gui.GamePopUps")
local globalFunctions = gameDirectory.GlobalFunctions

--/GLOBAL_VARIABLES

local SpinUIHandler = {}
local mainPlayer: Player = game.Players.LocalPlayer
local mainGUI: ScreenGui = mainPlayer.PlayerGui:WaitForChild("MainGUI")
local spinFrame: Frame = mainGUI.Frames.SpinFrame
local spinMain: ImageLabel = spinFrame.SpinMain
local spinButton: ImageButton = spinFrame.SpinButton
local errorPopUp = globalFunctions.UsePopUp(spinFrame.InsufficientPopUp.TextLabel, 0.25)
local baseRotation: number = -spinMain.Rotation

local currentlySpinning: boolean = false

local prizesInSpinOrder = {
	"150 Coins",
	"GoldenGloves",
	"Lucky",
	"2Spins",
	"GrappleAbility",
	"80 Coins",
}

--/GLOBAL_FUNCTIONS

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
	local viewPortFrame: ViewportFrame = spinFrame.SpinMain.GlovePrizeFrame
	local viewPortCamera: Camera = Instance.new("Camera")
	local gloveFolderClone: Folder = gloveFolder:Clone()

	positionGlovesInViewPort(gloveFolderClone, viewPortCamera)
	viewPortFrame.CurrentCamera = viewPortCamera
	viewPortCamera.Parent = viewPortFrame
	gloveFolderClone.Parent = viewPortFrame
end

--<<Handles spinning the spin wheel and lands on the prize
local function spinPrizeWheel(prizeName: string)
	local EFFECT_TIME: number = 5
	local REWARD_DEGREE = 360 / #prizesInSpinOrder
	local randomRewardIndex = table.find(prizesInSpinOrder, prizeName)
	local fullSpins = 5
	local endRotation = -((360 * -fullSpins) + (baseRotation + (REWARD_DEGREE * (randomRewardIndex - 1))))
	local mainTween: Tween =
		TweenService:Create(spinMain, TweenInfo.new(EFFECT_TIME, Enum.EasingStyle.Quart), { Rotation = endRotation })
	spinMain.Rotation = baseRotation
	mainTween:Play()
	return mainTween.Completed:Wait()
end

--<<Sorts logic after contacting server
local function sortServerResponse(dataResponse: { Status: string, Args: string })
	if dataResponse.Status == "Failed" then
		errorPopUp(dataResponse.Args)
	else
		spinPrizeWheel(dataResponse.Args)
		remoteFunction:InvokeServer("Claim")
		return popUpHandler.SortPopUp("ShopUpdate", ("Won %s!"):format(dataResponse.Args))
	end
end

--/MODULAR_FUNCTIONS

createGloveFrame(ReplicatedStorage.Gloves.Rare.GoldGlove)

spinButton.Activated:Connect(function()
	if not currentlySpinning then
		currentlySpinning = true
		sortServerResponse(remoteFunction:InvokeServer("Roll"))
		currentlySpinning = false
	end
end)

proximityHandler.RegisterProximityFunction(workspace.Spawn:WaitForChild("SpinRing"), function(enterState: string)
	spinFrame.Visible = enterState == "Entered"
end)

require(script.SpinPurchases)

return SpinUIHandler
