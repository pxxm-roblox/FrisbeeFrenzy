local FrisbeeHandler = {}
FrisbeeHandler.__index = FrisbeeHandler

--/SERVICES

--/TYPES

type self = {
	State: string,
	CurrentSpeed: number,
	ThrowDirection: Vector3,
	Position: Vector3,
	ID: number,
	Caught: boolean,
	CanCatch: boolean,
	HoldFlag: number,
	Part: BasePart,
	Destroyed: boolean,
	MiddlePosition: Vector3,
	MaidObject: {},
	Target: Model,
	Thrower: Model?,
}
export type FrisbeeObject = typeof(setmetatable({} :: self, FrisbeeHandler))

--/MODULES

local gameDirectory = require(game:GetService("ReplicatedStorage").Shared.GameDirectory)
local serverUtils = gameDirectory.Require("Server.Utils.General")
local RunService = game:GetService("RunService")
local mainServices = gameDirectory.GetServices()
local globalFunctions = gameDirectory.GlobalFunctions
local maidModule = gameDirectory.Require("Utils.MaidModule")
local characterDataModule = gameDirectory.Require("Server.CharacterData")
local gameData = gameDirectory.Require("Server.GameManager.Data")
local rewardsHandler = gameDirectory.Require("Server.RewardsHandler")
local abilityHandler = gameDirectory.Require("Server.AbilityHandler")

--/GLOBAL_VARIABLES
local constantsFolder = mainServices.ReplicatedStorage.Constants.Frisbee

local soundsFolder = mainServices.ReplicatedStorage.Sounds

local FRISBEE_STATES = {
	Idle = "Idle",
	Thrown = "Thrown",
	Paused = "Paused",
	Chasing = "Chasing",
	Held = "Held",
	Frozen = "Frozen",
}
local BASE_SPEED: number = constantsFolder.BASE_SPEED.Value
local MAXIMUM_KILL_DISTANCE: number = constantsFolder.MAXIMUM_KILL_DISTANCE.Value
-- local TARGET_DELAY: number = constantsFolder.TARGET_DELAY.Value
local INITIAL_TARGET_DELAY: number = constantsFolder.INITIAL_TARGET_DELAY.Value
local MAX_HOLD_TIME: number = constantsFolder.MAX_HOLD_TIME.Value
local SPEED_INCREMENT: number = constantsFolder.SPEED_INCREMENT.Value
-- local THROW_TARGET_RANGE: number = constantsFolder.THROW_TARGET_RANGE.Value
local CATCH_DISTANCE: number = constantsFolder.CATCH_DISTANCE.Value
local MITIGATION_DISTANCE: number = 5
local TESTING_FRISBEE_PART: boolean = mainServices.ReplicatedStorage.Constants.TestingFrisbee.Value

local frisbeePartReference: BasePart = script.FrisbeePart
local playerCharacters: Folder = workspace.InGame
local animationFolder = mainServices.ReplicatedStorage.Animations
local remoteEvent: RemoteEvent =
	gameDirectory.RegisterAsReplicatedService("FrisbeeClientReplicator", "RemoteEvent").RemoteEvent
local directionRemoteReplicator: UnreliableRemoteEvent = gameDirectory.RegisterAsReplicatedService(
	"FrisbeeDirectionReplication",
	"UnreliableRemoteEvent"
).UnreliableRemoteEvent
local popUpHandlerRemote: RemoteEvent = gameDirectory.GetReplicatedServiceFolder("PopUpHandler").RemoteEvent
local effectsFolder = mainServices.ReplicatedStorage.Effects

--/GLOBAL_FUNCTIONS

--Returns the amount of players alive ingame currently
local function getPlayersAlive(): number
	local playersAlive: number = 0
	for _, mainChar: Model in ipairs(workspace.InGame:GetChildren()) do
		local charHumanoid: Humanoid? = mainChar:FindFirstChildWhichIsA("Humanoid")
		if charHumanoid and charHumanoid.Health > 0 then
			playersAlive += 1
		end
	end
	return playersAlive
end

--<<Sets up frisbee part for frisbee object
local function setUpFrisbeePart(): BasePart
	local partReturn: BasePart = frisbeePartReference.Value:Clone()
	local attachment: Attachment = Instance.new("Attachment")
	attachment.Parent = partReturn
	partReturn.Anchored = true
	return partReturn
end

--<<Replicates frisbee part data
local function replicateFrisbeeData(frisbeeObject: FrisbeeObject, dataReplicate: { [string]: any }?)
	local frisbeeInstance: Instance = frisbeeObject.Part
	local targetChar: Model = frisbeeObject:GetTarget()
	if targetChar then
		local mainPlayer: Player = mainServices.Players:GetPlayerFromCharacter(frisbeeObject:GetTarget())
		frisbeeInstance:SetAttribute("Target", (mainPlayer and mainPlayer.Name or frisbeeObject:GetTarget().Name))
	else
		frisbeeInstance:SetAttribute("Target", "")
	end
	frisbeeInstance:SetAttribute("CurrentPosition", frisbeeObject.Position)
	frisbeeInstance:SetAttribute("ThrowDirection", frisbeeObject.ThrowDirection)
	frisbeeInstance:SetAttribute("Speed", frisbeeObject.CurrentSpeed)
	frisbeeInstance:SetAttribute("State", frisbeeObject:GetState())
	return remoteEvent:FireAllClients({
		Method = "ChangeState",
		Args = {
			ID = frisbeeObject.ID,
			State = frisbeeObject:GetState(),
			FrisbeeAttributes = dataReplicate,
		},
	})
end

--<<Sets up frisbee part on start
local function setUpOnStart(frisbeePart: BasePart, middlePosition: Vector3)
	if not frisbeePart.Parent then
		local clockFlag: number = os.clock()
		frisbeePart.CFrame = CFrame.new(middlePosition)
		frisbeePart.Parent = workspace.FrisbeesInGame
		frisbeePart:SetAttribute("ID", clockFlag)
		remoteEvent:FireAllClients({
			Method = "SetUp",
			Args = {
				FrisbeeID = clockFlag,
			},
		})
		return clockFlag
	end
end

--<<Sets up highlight and parents to model
local function highlightTarget(mainTarget: Model): Highlight
	local highlight: Highlight = mainServices.ReplicatedStorage.Effects.Other.TargetHighlight:Clone()
	highlight.Parent = mainTarget
	return highlight
end

-- --<<Sets a time flag and returns a function that checks if the time flag is the same
-- local function useTimeFlag(frisbeeObject: FrisbeeObject): () -> boolean
-- 	local timeFlag = os.clock()
-- 	frisbeeObject.HoldFlag = timeFlag
-- 	return function()
-- 		return timeFlag == frisbeeObject.HoldFlag
-- 	end
-- end

--<<Sets the frisbee part CFrame for a throw
local function getThrowCFrame(mainChar: Model, localCFrame: CFrame, throwDirection: Vector3): CFrame
	local cframeReturn: CFrame
	if (mainChar.HumanoidRootPart.Position - localCFrame.Position).Magnitude <= MITIGATION_DISTANCE then
		cframeReturn = localCFrame
	else
		cframeReturn = mainChar.HumanoidRootPart.CFrame
	end
	cframeReturn = CFrame.lookAt(cframeReturn.Position, cframeReturn.Position + throwDirection * 3)
	return cframeReturn
end

--<<Makes catch now gui visible for player if player exists
local function indicateCatchNow(mainPlayer: Player)
	if mainPlayer then
		local playerGui: PlayerGui = mainPlayer.PlayerGui
		playerGui.Window.Action.Text = "CATCH NOW!"
		if not playerGui.Window.Action.Visible then
			playerGui.Window.Action.Visible = true
			return function()
				playerGui.Window.Action.Visible = false
			end
		end
	end
end

--<<Handles when to indicate catch window
local function handleCatchWindow(vectorDifference: number, frisbeeObject: FrisbeeObject, mainPlayer: Player)
	if mainPlayer then
		if
			vectorDifference
			<= (CATCH_DISTANCE + (frisbeeObject.CurrentSpeed * globalFunctions.GetPlayerPing(mainPlayer.Character)))
		then
			if not frisbeeObject.CanCatch then
				frisbeeObject:SetCanCatch(true)
			end
			return indicateCatchNow(mainPlayer)
		end
	end
end

--<<Returns a function if player exists allows one to manipulate the indicator gui
local function useIndicatorGuiCaught(mainPlayer: Player): () -> boolean
	if mainPlayer then
		local windowGui: ScreenGui = mainPlayer.PlayerGui.Window
		local actionTextLabel: TextLabel = windowGui.Action
		local timerTextLabel: TextLabel = windowGui.Timer
		actionTextLabel.Text = "CLICK/TAP TO THROW NOW!"
		actionTextLabel.Visible = true
		timerTextLabel.Visible = true
		return function(currentTime: number)
			local timeDifference: number = MAX_HOLD_TIME - currentTime
			if timeDifference <= 0 then
				actionTextLabel.Visible = false
				timerTextLabel.Visible = false
				return
			end
			timerTextLabel.Text = math.round(timeDifference * 100) / 100
		end, function()
			actionTextLabel.Visible = false
			timerTextLabel.Visible = false
		end
	end
end

--<<Handles the time out for holding the frisbee
local function handleTimeOut(frisbeeObject: FrisbeeObject)
	local mainChar: Model = frisbeeObject:GetTarget()
	local maidObject = frisbeeObject.MaidObject
	local charHRP: BasePart = mainChar.HumanoidRootPart
	local characterDataObject = characterDataModule.Get(mainChar)
	local guiSetterHandler: (timePassed: number) -> ()?, resetFunction =
		useIndicatorGuiCaught(mainServices.Players:GetPlayerFromCharacter(mainChar))
	local timePassed: number = 0
	local runCon: RBXScriptConnection = nil
	maidObject:Add(resetFunction)
	runCon = maidObject:Add(RunService.PostSimulation:Connect(function(dt: number)
		timePassed += dt
		if timePassed >= MAX_HOLD_TIME then
			runCon:Disconnect()
			frisbeeObject:Throw(charHRP.CFrame, charHRP.CFrame.LookVector, characterDataObject:GetTargettedCharacter())
		end
		return (guiSetterHandler and guiSetterHandler(timePassed))
	end))
end

--<<Creates beam effect and links to frisbee from character
-- local function beamTargetToFrisbee(frisbeePart: BasePart, mainChar: Model): Beam
-- 	-- local beamClone: Beam = mainServices.ReplicatedStorage.Effects.Other.ArrowBeam:Clone()
-- 	-- beamClone.Attachment1 = frisbeePart.Attachment
-- 	-- beamClone.Attachment0 = mainChar.HumanoidRootPart:FindFirstChildWhichIsA("Attachment")
-- 	-- beamClone.Parent = mainChar
-- 	-- return beamClone
-- end

--<<Returns a function that can be used for raycasting
local function useFrisbeeRayCast(): (position: Vector3, direction: Vector3) -> RaycastResult?
	local raycastParams: RaycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Include
	raycastParams.FilterDescendantsInstances = {}
	return function(position: Vector3, direction: Vector3)
		return workspace:Raycast(position, direction, raycastParams)
	end
end

--<<Returns reflected velocity vector and sets frisbee part to reflected velocity vector
local function reflectVelocity(velocityVector: Vector3, raycastResult: RaycastResult?): Vector3
	if raycastResult then
		return velocityVector - (2 * velocityVector:Dot(raycastResult.Normal) * raycastResult.Normal)
	end
	return nil
end

--<<Checks if the frisbee travel distance is bigger than the distance between the frisbee and the player + kill magnitude
local function travelDistanceBiggerThanMagnitude(
	frisbeeObject: FrisbeeObject,
	frisbeePosition: Vector3,
	dt: number
): boolean
	return (frisbeeObject.CurrentSpeed * dt)
		> (frisbeePosition - frisbeeObject.Target.HumanoidRootPart.Position).Magnitude
end

--<<Returns random player if it is viable
local function getFurthestPlayableCharacter(frisbeePosition: Vector3, characters: { Model }): Model?
	local viableCharacters: { Model } = {}
	for _, mainChar: Model in characters do
		if mainChar:FindFirstChild("HumanoidRootPart") and mainChar:FindFirstChild("Humanoid") then
			if mainChar.Humanoid.Health > 0 then
				table.insert(viableCharacters, mainChar)
			end
		end
	end
	if #viableCharacters > 1 then
		local furthestCharacter: Model, distance: number = nil, -1
		for _, mainChar: Model in ipairs(viableCharacters) do
			local charHRP: BasePart = mainChar.HumanoidRootPart
			local magnitudeDistance: number = (charHRP.Position - frisbeePosition).Magnitude
			if magnitudeDistance > distance then
				furthestCharacter = mainChar
				distance = magnitudeDistance
			end
		end
		return furthestCharacter
	end
	return nil
end

--<<Plays death sound
local function playDeathSound(charPos: Vector3)
	local basePart: BasePart = Instance.new("Part")
	basePart.Transparency = 1
	basePart.Anchored = true
	basePart.CanCollide = false
	basePart.CFrame = CFrame.new(charPos)
	basePart.Parent = workspace
	local soundClone: Sound = soundsFolder.DeathSound:Clone()
	soundClone.Parent = basePart
	soundClone:Play()
	return globalFunctions.taskDebris(basePart, soundClone.TimeLength + 1)
end

--<<Gets the closest character to frisbee and if they are under the target range return true
-- local function getThrowTarget(frisbeePart: BasePart, whiteListModels: { Model }): Model?
-- 	local enemyChar: Model, magnitudeDistance: number =
-- 		globalFunctions.GetClosestCharacter(frisbeePart.Position, whiteListModels)
-- 	if magnitudeDistance <= THROW_TARGET_RANGE then
-- 		return enemyChar
-- 	end
-- end

--Creates a test part and returns it
local function setUpTestPart(position: Vector3): BasePart
	local testPart: BasePart = Instance.new("Part")
	testPart.Anchored = true
	testPart.CanCollide = false
	testPart.Size = Vector3.new(3, 3, 3)
	testPart.Material = Enum.Material.Neon
	testPart.Color = Color3.fromRGB(255, 0, 0)
	testPart.Parent = workspace
	testPart.CFrame = CFrame.new(position)
	return testPart
end

--/MODULAR_FUNCTIONS

--<<Creates frisbee object and returns it
function FrisbeeHandler.new(middlePosition: Vector3): FrisbeeObject
	return setmetatable({
		CurrentSpeed = BASE_SPEED,
		State = FRISBEE_STATES.Idle,
		CanCatch = false,
		Caught = false,
		MiddlePosition = middlePosition,
		MaidObject = maidModule.Create(),
		Part = setUpFrisbeePart(),
		Destroyed = false,
		Target = nil,
	}, FrisbeeHandler)
end

--<<Returns if the frisbee is active, can be thrown caught, etc...
function FrisbeeHandler.IsActive(self: FrisbeeObject): boolean
	return self.Active
end

--<<Returns frisbee state
function FrisbeeHandler.GetState(self: FrisbeeObject)
	return self.State
end

--<<Sets frisbee state
function FrisbeeHandler.SetState(self: FrisbeeObject, state: string)
	if not FRISBEE_STATES[state] then
		error("Invalid frisbee state")
	end
	self.State = state
end

--<<Returns frisbee speed
function FrisbeeHandler.GetSpeed(self: FrisbeeObject)
	return self.CurrentSpeed
end

--<<Starts the frisbee process
function FrisbeeHandler.Start(self: FrisbeeObject)
	if self.Destroyed then
		return
	end
	local GAME_LOOP_TIME: number = 1

	self.ID = setUpOnStart(self.Part, self.MiddlePosition)

	task.spawn(function()
		while not self.Destroyed do
			if self:GetState() == FRISBEE_STATES.Idle then
				task.wait(INITIAL_TARGET_DELAY)
				if not self.Destroyed then
					local enemyChar: Model? =
						getFurthestPlayableCharacter(self.Part.Position, playerCharacters:GetChildren())
					if enemyChar then
						self:Chase(enemyChar)
					end
				end
			end
			task.wait(GAME_LOOP_TIME)
		end
	end)
end

--<<Chases passed target
function FrisbeeHandler.Chase(self: FrisbeeObject, target: Model, initialThrowDirection: Vector3)
	if self.Destroyed then
		return
	end
	local characterDataObject = characterDataModule.Get(target)
	if not globalFunctions.IsViableCharacter(target) or not characterDataObject then
		return self:ChaseClosestEnemy(self.Thrower, initialThrowDirection)
	end

	self:SetState(FRISBEE_STATES.Chasing)
	self.HoldFlag = nil
	self.Target = target

	local maidObject = self.MaidObject
	self.Position = self.Part.Position
	local lastDirection: Vector3 = initialThrowDirection or (target.HumanoidRootPart.Position - self.Position).Unit
	local mainPlayer: Player? = mainServices.Players:GetPlayerFromCharacter(target)
	local frisbeeRaycast: (position: Vector3, direction: Vector3) -> RaycastResult? = useFrisbeeRayCast()
	local frisbeeDirectionLerpHandler = globalFunctions.UseFrisbeeDirectionLerping()
	local playerCaughtChecker: () -> boolean = characterDataObject:UseFrisbeeCaughtChecker(self.CurrentSpeed)
	local testPart: BasePart? = (TESTING_FRISBEE_PART and maidObject:Add(setUpTestPart(self.Position))) or nil

	self.ThrowDirection = lastDirection

	replicateFrisbeeData(self, {
		Target = target,
		Speed = self.CurrentSpeed,
		ThrowDirection = lastDirection,
	})
	maidObject:Add(highlightTarget(target))
	maidObject:Add(mainServices.RunService.PreAnimation:Connect(function(dt: number)
		local vectorDifference: Vector3 = target.HumanoidRootPart.Position - self.Position
		maidObject:Add(handleCatchWindow(vectorDifference.Magnitude, self, mainPlayer))
		if self:GetState() ~= FRISBEE_STATES.Frozen then
			if
				vectorDifference.Magnitude <= MAXIMUM_KILL_DISTANCE
				or travelDistanceBiggerThanMagnitude(self, self.Position, dt)
			then
				if self.Caught or playerCaughtChecker() then
					self:Catch()
					return characterDataObject:ResetCatchState()
				end
				return self:Kill()
			end
			if abilityHandler.SortAbilityOnTargetted(mainPlayer, self) then
				return
			end
			directionRemoteReplicator:FireAllClients(self.ID, lastDirection)
			local travelDistance: number = self.CurrentSpeed * dt
			local raycastResult: RaycastResult? = frisbeeRaycast(self.Position, lastDirection.Unit * travelDistance)
			if raycastResult then
				lastDirection = reflectVelocity(lastDirection.Unit, raycastResult)
				frisbeeDirectionLerpHandler = globalFunctions.UseFrisbeeDirectionLerping()
				--frisbeePart:SetAttribute("ServerCFrame", frisbeePart.CFrame)
				return self.Part:SetAttribute("ThrowDirection", lastDirection)
			end
			self.Position += (lastDirection.Unit * travelDistance)
			if testPart then
				testPart.CFrame = CFrame.new(self.Position)
			end
			self.Part:SetAttribute("CurrentPosition", self.Position)
			lastDirection = lastDirection:Lerp(
				vectorDifference.Unit,
				frisbeeDirectionLerpHandler(travelDistance, vectorDifference.Magnitude)
			)
		end
	end))
end

--<<Kills target if passed
function FrisbeeHandler.Kill(self: FrisbeeObject)
	if self.Thrower and self.Thrower.Parent then
		rewardsHandler.RewardKill(self.Thrower, self.Target)
		serverUtils.EmitVFXAndDebris(
			serverUtils.GetVFX("Death", game.Players:GetPlayerFromCharacter(self.Thrower)),
			self.Target.HumanoidRootPart
		)
	end
	local enemyChar: Model = self.Target
	enemyChar.Humanoid.Health = 0
	self:TotalReset()
	if getPlayersAlive() == 2 then
		popUpHandlerRemote:FireAllClients("StandOff", "1 v 1")
	end
	return (enemyChar:FindFirstChild("HumanoidRootPart") and playDeathSound(enemyChar.HumanoidRootPart.Position))
end

--<<Total Reset, resets frisbee like when it first started
function FrisbeeHandler.TotalReset(self: FrisbeeObject)
	self:SetState(FRISBEE_STATES.Idle)
	self:Reset({ CFrame = CFrame.new(self.MiddlePosition) })
	self.Position = self.MiddlePosition
	self.CurrentSpeed = BASE_SPEED
	self:ResetThrower()
	self.Target = nil
	replicateFrisbeeData(self)
end

--<<Returns the target of the frisbee
function FrisbeeHandler.GetTarget(self: FrisbeeObject)
	return self.Target
end

--<<Resets Frisbee
function FrisbeeHandler.Reset(self: FrisbeeObject, params: { CFrame: CFrame? })
	self.MaidObject:Destroy()
	self.MaidObject = maidModule.Create()
	self.Part.Anchored = true
	self.Caught = false
	self:SetCanCatch(false)

	if params then
		if params.CFrame then
			self.Part.CFrame = params.CFrame
		end
	end
end

--<<Returns true if the passed character is currently holding the frisbee
function FrisbeeHandler.IsHoldingFrisbee(self: FrisbeeObject, mainChar: Model)
	return self.Target == mainChar and self:GetState() == FRISBEE_STATES.Held
end

--<<Catches Frisbee and holds it in hand
function FrisbeeHandler.Catch(self: FrisbeeObject)
	if not self.Target or self.Destroyed or self:GetState() ~= FRISBEE_STATES.Chasing then
		return
	end
	self:Reset()
	self:SetState(FRISBEE_STATES.Held)
	self.CurrentSpeed += SPEED_INCREMENT
	self:ResetThrower()

	local mainChar: Model = self.Target
	local frisbeePart: BasePart = self.Part

	frisbeePart.Anchored = false

	replicateFrisbeeData(self)
	frisbeePart:SetAttribute("CurrentPosition", nil)
	self.MaidObject:Add(globalFunctions.CreateWeld(mainChar["Right Arm"], frisbeePart, CFrame.new(0, -1, 0)))

	mainChar.Humanoid.Animator:LoadAnimation(animationFolder.Catch):Play()
	globalFunctions.DebrisSound(soundsFolder.CatchSound, mainChar.HumanoidRootPart)
	return handleTimeOut(self)
end

--<<Checks if target caught the frisbee and if they did call self:Catch()
function FrisbeeHandler.CheckCatch(self: FrisbeeObject): boolean
	if self.Target then
		if self.CanCatch then
			self:SetCanCatch(false)
			self.Caught = true
			return true
		end
	end
	return false
end

--<<Sets thrower
function FrisbeeHandler.SetThrower(self: FrisbeeObject, mainChar: Model)
	self.Thrower = mainChar
end

--<<Resets thrower
function FrisbeeHandler.ResetThrower(self: FrisbeeObject)
	self.Thrower = nil
end

--<<Handles throwing the frisbee
function FrisbeeHandler.Throw(self: FrisbeeObject, charCFrame: CFrame, throwDirection: Vector3, customTarget: Model?)
	if self.Destroyed then
		return
	end
	self:SetState(FRISBEE_STATES.Thrown)
	self.HoldFlag = nil
	throwDirection = throwDirection.Unit
	local mainChar: Model = self.Target
	local frisbeePart: BasePart = self.Part
	-- local linearVelocity: LinearVelocity = frisbeePart.LinearVelocity
	-- local alignOrientation: AlignOrientation = frisbeePart.AlignOrientation
	-- local raycastFunction = useFrisbeeRayCast()
	local travelDirection: Vector3 = throwDirection
	local enemyChar: Model = customTarget
		or globalFunctions.GetClosestCharacter(frisbeePart.Position, gameData.GetWhiteListPlayers(mainChar))
	-- local clockCompare: number = os.clock()
	self.Target = nil
	self:SetThrower(mainChar)
	serverUtils.EmitVFXAndDebris(serverUtils.GetVFX("Hit", game.Players:GetPlayerFromCharacter(mainChar)), frisbeePart)
	self:Reset({
		CFrame = getThrowCFrame(mainChar, charCFrame, travelDirection),
		-- Velocity = travelDirection * self.CurrentSpeed,
	})
	globalFunctions.DebrisSound(soundsFolder.ThrowSound, frisbeePart)
	return (enemyChar and self:Chase(enemyChar, travelDirection))
end

--Chases closest enemy
function FrisbeeHandler.ChaseClosestEnemy(self: FrisbeeObject, charIgnore: Model?, initialThrowDirection: Vector3)
	local characterTable: { Model } = charIgnore and gameData.GetWhiteListPlayers(charIgnore)
		or playerCharacters:GetChildren()
	local newTarget: Model? = globalFunctions.GetClosestCharacter(self.Part.Position, characterTable)
	if newTarget then
		return self:Chase(newTarget, initialThrowDirection)
	end
	return self:SetState(FRISBEE_STATES.Idle)
end

--Pauses the frisbee without freeze
function FrisbeeHandler.Pause(self: FrisbeeObject)
	if self.Destroyed then
		return
	end
	self:Reset({
		CFrame = CFrame.new(self.Position),
	})
	self:ResetThrower()
	self.Target = nil
	self:SetState(FRISBEE_STATES.Paused)
	return replicateFrisbeeData(self)
end

--<<Freeze frisbee for a set amount of time
function FrisbeeHandler.Freeze(self: FrisbeeObject, freezeTime: number)
	if self.Destroyed or self:GetState() ~= FRISBEE_STATES.Chasing then
		return
	end
	local maidObject = self.MaidObject:Add(maidModule.Create())
	local iceCubePart: BasePart = maidObject:Add(effectsFolder.Parts.IceCube:Clone())
	globalFunctions.CreateWeld(self.Part, iceCubePart, CFrame.new(0, 0, 0))
	iceCubePart.Parent = workspace.Effects
	self:SetState(FRISBEE_STATES.Frozen)
	replicateFrisbeeData(self)
	return task.delay(freezeTime, function()
		if self:GetState() == FRISBEE_STATES.Frozen and iceCubePart.Parent then
			self:SetState(FRISBEE_STATES.Chasing)
			replicateFrisbeeData(self, {
				Target = self:GetTarget(),
			})
		end
		maidObject:Destroy()
	end)
end

function FrisbeeHandler.Destroy(self: FrisbeeObject)
	self.Destroyed = true
	self:TotalReset()
	self.MaidObject:Destroy()
	return self.Part:Destroy()
end

function FrisbeeHandler.SetCanCatch(self: FrisbeeObject, canCatch: boolean)
	self.CanCatch = canCatch
end

return FrisbeeHandler
