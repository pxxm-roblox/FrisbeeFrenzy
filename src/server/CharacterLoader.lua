--/SERVICES

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--/TYPES

--/MODULES

local gameDirectory = require(game:GetService("ReplicatedStorage").Shared.GameDirectory)
local globalFunctions = gameDirectory.GlobalFunctions
local playerDataManager = gameDirectory.Require("Server.PlayerData")
local chatTagsServer = gameDirectory.Require("Server.ChatTags_Server")
local mainServices = gameDirectory.GetServices()
local playerLoadedRemote: RemoteEvent =
	gameDirectory.RegisterAsReplicatedService("PlayerLoaded", "RemoteEvent").RemoteEvent

--/GLOBAL_VARIABLES

local characterLoader = {}
local remoteEvent: RemoteEvent = gameDirectory.GetReplicatedServiceFolder("DataReplicator").RemoteEvent

--/GLOBAL_FUNCTIONS

local function createLinearVelocity(charHRP: BasePart): LinearVelocity
	local linearVelocity: LinearVelocity = Instance.new("LinearVelocity")
	local attachment0: Attachment = Instance.new("Attachment")
	attachment0.Parent = charHRP
	linearVelocity:SetAttribute("State", 0)
	linearVelocity.Attachment0 = attachment0
	linearVelocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	linearVelocity.MaxForce = 0
	linearVelocity.VectorVelocity = Vector3.new()
	linearVelocity.Parent = charHRP
end

local function setUpCharEffects(mainChar: Model)
	local attachment0: Attachment = Instance.new("Attachment")
	attachment0.Position = Vector3.new(0, -1, 0)
	attachment0.Parent = mainChar["Right Arm"]
	local beamClone: Beam = mainServices.ReplicatedStorage.Effects.Other.GrappleString:Clone()
	beamClone.Attachment0 = attachment0
	beamClone.Parent = mainChar["Right Arm"]
end

local function setUpCharFolders(mainChar: Model)
	local glovesFolder: Folder = Instance.new("Folder")
	glovesFolder.Name = "EquippedGloves"
	glovesFolder.Parent = mainChar
end

local function setUpCharHumanoid(charHumanoid: Humanoid)
	charHumanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
	return charHumanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
end

--<<Sets up char gloves
local function setUpCharGloves(mainChar, profile)
	if profile then
		if profile:GetData("EquippedGloveSkin") ~= "" then
			globalFunctions.WeldEquippedGloves(
				mainChar,
				ReplicatedStorage.Gloves:FindFirstChild(profile:GetData("EquippedGloveSkin"), true)
			)
		end
	end
end

--/MODULAR_FUNCTIONS

playerLoadedRemote.OnServerEvent:Connect(function(mainPlayer: Player)
	return playerDataManager.OnDataLoaded(mainPlayer, function(profile)
		profile:SetLoaded()
		setUpCharGloves(mainPlayer.Character, profile)
		remoteEvent:FireClient(mainPlayer, {
			Action = "Loaded",
			Args = {
				Data = profile:GetAllData(),
				MetaData = profile:GetMetaData(),
			},
		})
		return chatTagsServer.SetChatTags(mainPlayer)
	end)
end)

mainServices.Players.PlayerAdded:Connect(function(mainPlayer: Player)
	mainPlayer.CharacterAdded:Connect(function(mainChar: Model)
		createLinearVelocity(mainChar.HumanoidRootPart)
		setUpCharEffects(mainChar)
		setUpCharHumanoid(mainChar:FindFirstChild("Humanoid") or mainChar:WaitForChild("Humanoid"))
		setUpCharFolders(mainChar)
		setUpCharGloves(mainPlayer.Character, playerDataManager.GetPlayerData(mainPlayer))
		if mainChar.Parent ~= workspace then
			mainChar.AncestryChanged:Wait()
		end
		task.wait()
		mainChar.Parent = workspace.Players
	end)
end)

return characterLoader
