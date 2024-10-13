--/SERVICES

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--/TYPES

--/MODULES

local gameDirectory = require(game:GetService("ReplicatedStorage").Shared.GameDirectory)
local playerDataReplicator = gameDirectory.Require("Client.PlayerDataClient")
local interactFrameHandler = require(script.Parent.InteractionFrame)
playerDataReplicator.WaitForData()

--/GLOBAL_VARIABLES

local AbilitiesUIHandler = {}

local priceConstants: Folder = ReplicatedStorage.Constants.Prices
local mainPlayer: Player = game.Players.LocalPlayer
local mainGUI: ScreenGui = mainPlayer.PlayerGui:WaitForChild("MainGUI")
local abilitiesFrame: Frame = mainGUI.Frames.ShopFrame.AbilitiesFrame
local scrollingFrame: ScrollingFrame = abilitiesFrame.ScrollingFrame
local assetsFolder: Folder = abilitiesFrame.Assets
local referenceFrame: Frame = assetsFolder.FrameReference
local remoteFunction: RemoteFunction = gameDirectory.GetReplicatedServiceFolder("ShopUIHandler").RemoteFunction

--/GLOBAL_FUNCTIONS

--<<Returns function that handles purchase
local function useOnPurchaseFunction(abilityName: string)
	return function()
		if remoteFunction:InvokeServer({
			Category = "Ability",
			Item = abilityName,
		}) then
			interactFrameHandler.Clear()
		end
	end
end

--<<Modifies data table to account for price
local function displayPrice(abilityName: string, dataTable): boolean
	local price: number = priceConstants:FindFirstChild(abilityName)
	if price then
		dataTable.Description = tostring(price.Value) .. " Coins"
		return true
	end
	dataTable.ButtonText = "Unpurchaseable"
	dataTable.ButtonStrokeColor = Color3.fromRGB(255, 0, 0)
	return false
end

--<<Changes table if ability name is equipped ability
local function modifyDataTable(abilityName: string, dataTable)
	local equippedAbility: string = playerDataReplicator.GetData("EquippedAbility")
	if abilityName == equippedAbility then
		dataTable.ButtonText = "Equipped"
		dataTable.ButtonStrokeColor = Color3.fromRGB(255, 0, 0)
		return dataTable
	end
	if dataTable.ButtonText ~= "Purchase" or displayPrice(abilityName, dataTable) then
		dataTable.OnInteract = useOnPurchaseFunction(abilityName)
	end
	return dataTable
end

--<<Returns a function that processes button click
local function useOnAbilitySelect(buttonObject: ImageButton)
	return function()
		return interactFrameHandler.SetUpInteraction(modifyDataTable(buttonObject.Name, {
			Title = buttonObject.Name,
			ButtonText = (buttonObject.Parent.Name == "OwnedAbilities" and "Equip" or "Purchase"),
		}))
	end
end

--<<Returns two arrays of frames, one for owned abilities and one for unowned abilities
local function getAbilityFrames(): ({ Frame }, { Frame })
	local allAbilityFrames: { Frame } = assetsFolder.Abilities:GetChildren()
	local shopAbilityFrames: { Frame } = {}
	local ownedAbilityFrames: { Frame } = {}
	local ownedAbilities = playerDataReplicator.GetData("Abilities")
	for _: number, frame: Frame in ipairs(allAbilityFrames) do
		if table.find(ownedAbilities, frame.Name) then
			table.insert(ownedAbilityFrames, frame)
		else
			table.insert(shopAbilityFrames, frame)
		end
	end

	return ownedAbilityFrames, shopAbilityFrames
end

--<<Creates ability frames and parents them accordingly
local function createAbilityFrames(frameArray: { Frame }, frameParent: Frame)
	local height: number = math.ceil(#frameArray / 3)
	local uiGridLayout: UIGridLayout = frameParent.UIGridLayout
	frameParent.Size = UDim2.fromScale(frameParent.Size.X.Scale, height * referenceFrame.Size.Y.Scale)
	uiGridLayout.CellSize = UDim2.fromScale(uiGridLayout.CellSize.X.Scale, 1 / height)
	for _, imageButton: ImageButton in ipairs(frameArray) do
		local buttonClone: ImageButton = imageButton:Clone()
		local onSelect: () -> () = useOnAbilitySelect(buttonClone)
		buttonClone.Visible = true
		buttonClone.MouseButton1Click:Connect(onSelect)
		buttonClone.TouchTap:Connect(onSelect)
		buttonClone.Parent = frameParent
	end
end

--<<Readjusts the size of the frame
local function resizeFrame(frame: Frame, frameArray: { Frame })
	local uiGridLayout: UIGridLayout = frame.UIGridLayout
	local height: number = math.ceil((#frameArray - 1) / 3)
	frame.Size = UDim2.fromScale(frame.Size.X.Scale, height * referenceFrame.Size.Y.Scale)
	uiGridLayout.CellSize = UDim2.fromScale(uiGridLayout.CellSize.X.Scale, 1 / height)
end

--<<Sets up abilities shop and owned abilities frame
local function setUpAbilityFrames()
	local ownedAbilityFrames, unownedAbilities: { Frame } = getAbilityFrames()
	createAbilityFrames(ownedAbilityFrames, scrollingFrame.OwnedAbilities)
	return createAbilityFrames(unownedAbilities, scrollingFrame.AbilitiesShop)
end

--/MODULAR_FUNCTIONS

setUpAbilityFrames()

AbilitiesUIHandler.MainFrame = abilitiesFrame

playerDataReplicator.OnDataChanged("Abilities", function(purchasedAbility: string)
	local buttonElement: ImageButton? = scrollingFrame.AbilitiesShop:FindFirstChild(purchasedAbility)
	if buttonElement then
		buttonElement.Parent = scrollingFrame.OwnedAbilities
		resizeFrame(scrollingFrame.OwnedAbilities, scrollingFrame.OwnedAbilities:GetChildren())
		return resizeFrame(scrollingFrame.AbilitiesShop, scrollingFrame.AbilitiesShop:GetChildren())
	end
end)

return AbilitiesUIHandler
