--/SERVICES

--/TYPES

--/MODULES

local gameDirectory = require(game:GetService("ReplicatedStorage").Shared.GameDirectory)
local globalFunctions = gameDirectory.GlobalFunctions
local characterData = gameDirectory.Require("Server.CharacterData")
local remoteEvent: RemoteEvent =
	gameDirectory.RegisterAsReplicatedService("FrisbeeInputHandler", "RemoteEvent").RemoteEvent
local gameData = require(script.Parent.Data)

--/GLOBAL_VARIABLES

local FrisbeeInputHandler = {}
local FrisbeeActions = {}

--/GLOBAL_FUNCTIONS

local function isCharacterValid(mainChar: Model): Model | boolean
	if not mainChar or not mainChar.Parent then
		return false
	end
	if not mainChar:FindFirstChild("Humanoid") then
		return false
	end
	if mainChar.Humanoid.Health <= 0 then
		return false
	end
	return mainChar
end

--/MODULAR_FUNCTIONS

--<<Handles catching
function FrisbeeActions.Catch(mainPlayer: Player)
	local mainChar: Model = mainPlayer.Character
	local mainCharacterData = characterData.Get(mainChar)
	local targettedFrisbee = gameData.GetTargettedFrisbee(mainChar)
	if
		mainCharacterData
		and mainCharacterData:CatchCDOver()
		and (not targettedFrisbee or not targettedFrisbee:IsHoldingFrisbee(mainChar))
	then
		if not mainCharacterData:IsCatchStateActive() and isCharacterValid(mainChar) then
			mainCharacterData:SetCatchStateActive()
			mainCharacterData:SetCatchState()
			if targettedFrisbee then
				targettedFrisbee:CheckCatch()
			end
			return mainCharacterData:PlayCatchStateFX()
		end
	end
end

--<<Handles throwing
function FrisbeeActions.Throw(mainPlayer: Player, args: { CharCFrame: CFrame, CameraDirection: Vector3, Target: Model })
	local mainChar: Model = mainPlayer.Character
	local mainCharacterData = characterData.Get(mainChar)
	local targettedFrisbee = gameData.GetTargettedFrisbee(mainChar)
	if mainCharacterData and targettedFrisbee and targettedFrisbee:IsHoldingFrisbee(mainChar) then
		if
			args.Target
			and globalFunctions.IsViableCharacter(args.Target)
			and table.find(gameData.GetWhiteListPlayers(mainChar), args.Target)
		then
			return targettedFrisbee:Throw(args.CharCFrame, args.CameraDirection, args.Target)
		end
		return targettedFrisbee:Throw(args.CharCFrame, args.CameraDirection)
	end
end

--Handles the start of throwing
function FrisbeeActions.StartThrow(mainPlayer: Player, args: { Target: Model })
	local mainChar: Model = mainPlayer.Character
	local mainCharacterData = characterData.Get(mainChar)
	local targettedFrisbee = gameData.GetTargettedFrisbee(mainChar)
	if mainCharacterData and targettedFrisbee and targettedFrisbee:IsHoldingFrisbee(mainChar) then
		if args.Target and table.find(gameData.GetWhiteListPlayers(mainChar), args.Target) then
			return mainCharacterData:SetTargettedCharacter(args.Target)
		end
	end
end

function FrisbeeInputHandler.__init__()
	remoteEvent.OnServerEvent:Connect(
		function(mainPlayer: Player, dataTable: { Action: string, Args: { [string]: any } })
			local indexedAction = FrisbeeActions[dataTable.Action]
			return (indexedAction and indexedAction(mainPlayer, dataTable.Args))
		end
	)
	return FrisbeeInputHandler
end

return FrisbeeInputHandler.__init__()
