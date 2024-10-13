local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
--//services

--//types

--//modules

local promiseModule = require(script.Parent.Promise)

--//global_variables

local globalFunctions = {}

--//global_functions

--//modular_functions

--<<Safely requires a module
function globalFunctions.safeRequire(moduleRequire: ModuleScript, displayDebugMessages: boolean)
	local moduleRequired
	task.spawn(function()
		local cachedTime: number = os.clock()
		moduleRequired = require(moduleRequire)
		if displayDebugMessages then
			local timeDelta: number = os.clock() - cachedTime
			return print(
				string.format(
					"[%02d:%02d]: %s has sucessfully loaded!",
					math.floor(timeDelta / 60),
					timeDelta % 60,
					moduleRequire:GetFullName()
				)
			)
		end
	end)
	return moduleRequired
end

--<<Safely requires but async
function globalFunctions.safeRequireAsync(moduleRequire: ModuleScript, displayDebugMessages: boolean)
	local cachedTime: number = os.clock()
	local moduleRequired = require(moduleRequire)
	if displayDebugMessages then
		local timeDelta: number = os.clock() - cachedTime
		return print(
			string.format(
				"[%02d:%02d]: %s has sucessfully loaded!",
				math.floor(timeDelta / 60),
				timeDelta % 60,
				moduleRequire:GetFullName()
			)
		)
	end
	return moduleRequired
end

--<<Basically game.debris but with task
function globalFunctions.taskDebris(item: Instance, timeWait: number | RBXScriptSignal)
	if typeof(timeWait) == "RBXScriptSignal" then
		return task.spawn(function()
			timeWait:Wait()
			return item:Destroy()
		end)
	end
	return task.delay(timeWait, item.Destroy, item)
end

--<<Plays a sound and debris it after
function globalFunctions.DebrisSound(soundObject: Sound, parentInstance: Instance, dur: number?)
	local soundClone: Sound = soundObject:Clone()
	soundClone.Parent = parentInstance
	soundClone:Play()
	return globalFunctions.taskDebris(soundClone, dur or soundObject.TimeLength)
end

--<<Creates a new weld
function globalFunctions.CreateWeld(p0: BasePart, p1: BasePart, c0: CFrame, c1: CFrame): Weld
	local newWeld: Weld = Instance.new("Weld")
	newWeld.Part0 = p0
	newWeld.Part1 = p1

	if c0 then
		newWeld.C0 = c0
	end

	if c1 then
		newWeld.C1 = c1
	end

	newWeld.Parent = p1
	return newWeld
end

--<<Deep copy of table
function globalFunctions.DeepCopy(originalTable: { any })
	local tableClone = {}
	for k, v in next, originalTable do
		tableClone[k] = (type(v) == "table" and globalFunctions.DeepCopy(v) or v)
	end
	return tableClone
end

--<<Returns random item from table
function globalFunctions.RandomItem(table: { any })
	return table[math.random(1, #table)]
end

--Returns if the character is a viable character
function globalFunctions.IsViableCharacter(mainChar: Model): boolean
	if
		mainChar
		and mainChar.Parent
		and mainChar:FindFirstChild("HumanoidRootPart")
		and mainChar:FindFirstChild("Humanoid")
	then
		if mainChar.Humanoid.Health > 0 then
			return true
		end
	end
	return false
end

--<<Gets the closest character in folder to the passed position and returns the magnitude
function globalFunctions.GetClosestCharacter(pos: Vector3, charTable: { Model }): (Model, number)
	local closestDistance: number = math.huge
	local closestCharacter: Model
	for _, value in ipairs(charTable) do
		if globalFunctions.IsViableCharacter(value) then
			local distance: number = (value.HumanoidRootPart.Position - pos).Magnitude
			if distance < closestDistance then
				closestDistance = distance
				closestCharacter = value
			end
		end
	end
	return closestCharacter, closestDistance
end

--<<Returns player ping
function globalFunctions.GetPlayerPing(mainChar: Model): number
	local mainPlayer: Player? = game.Players:GetPlayerFromCharacter(mainChar)
	if mainPlayer then
		return mainPlayer:GetNetworkPing() * 2
	end
	return 0
end

--<<Returns raycast params for blacklisted
function globalFunctions.GetPlayerParams()
	local raycastParams: RaycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = {
		workspace.InGame,
		workspace.FrisbeesInGame,
	}
	return raycastParams
end

--<<Handles animation marker n stuff
--<<Plays random animation and calls function passed on marker
function globalFunctions.PlayAnimationMarker(
	charAnimator: Animator,
	args: {
		Animation: Animation,
		Marker: string,
		Function: () -> (),
		OnStop: () -> (),
	}
)
	local animationTrack: AnimationTrack = charAnimator:LoadAnimation(args.Animation)
	local animCon: RBXScriptConnection
	animCon = animationTrack:GetMarkerReachedSignal(args.Marker):Connect(args.Function)
	promiseModule.WrapEvent(animationTrack.Stopped, animationTrack.Length + 1):Then(function()
		animCon:Disconnect()
		animationTrack:Destroy()
		return (args.OnStop and args.OnStop())
	end)
	return animationTrack:Play()
end

--<<Returns linear velocity in character and sets the state to a clock flag and returns a function to compare if the flag is still valid
function globalFunctions.GetLinearVelocity(mainChar: Model): (LinearVelocity, (resetClock: boolean) -> boolean)
	local linearVelocity: LinearVelocity = mainChar.HumanoidRootPart:FindFirstChild("LinearVelocity")
	if linearVelocity then
		local clockFlag: number = os.clock()
		linearVelocity:SetAttribute("State", clockFlag)
		return linearVelocity,
			function(resetClock: boolean)
				if linearVelocity:GetAttribute("State") == clockFlag then
					if resetClock then
						linearVelocity:SetAttribute("State", 0)
					end
					return true
				end
				return false
			end
	end
	return nil
end

--<<Instanteously sets character velocity
function globalFunctions.SetVelocity(basePart: BasePart, velocity: Vector3)
	basePart.AssemblyLinearVelocity = velocity
	return basePart:ApplyImpulse(velocity)
end

--<<Formats seconds into minutes:seconds
function globalFunctions.FormatSecondsIntoMinutes(totalTime: number)
	local minutes: number = math.floor(totalTime / 60)
	local seconds: number = totalTime - (minutes * 60)
	return ("%d:%02.f"):format(minutes, seconds)
end

--<<Equips gloves accordingly
function globalFunctions.WeldEquippedGloves(mainChar: Model, glovesFolder: Folder)
	local newGloves: Folder = glovesFolder:Clone()
	local charGloves: Folder = mainChar.EquippedGloves
	local Y_OFFSET: number = -0.4725

	charGloves:ClearAllChildren()
	globalFunctions.CreateWeld(mainChar["Right Arm"], newGloves.Right.PrimaryPart, CFrame.new(0, Y_OFFSET, 0))
	globalFunctions.CreateWeld(mainChar["Left Arm"], newGloves.Left.PrimaryPart, CFrame.new(0, Y_OFFSET, 0))
	newGloves.Parent = charGloves
end

--<<Returns a function that can be called to use with pop ups
function globalFunctions.UsePopUp(textLabel: TextLabel, appearanceTime: number, soundObject: Sound?)
	local effectFlag: number
	return function(stringText: string)
		local flagCompare: number = os.clock()
		effectFlag = flagCompare
		local tweenInfo: TweenInfo = TweenInfo.new(0.35, Enum.EasingStyle.Sine)
		textLabel.Text = stringText
		if soundObject then
			SoundService:PlayLocalSound(soundObject)
		end
		TweenService:Create(textLabel, tweenInfo, {
			TextTransparency = 0,
		}):Play()
		TweenService:Create(textLabel.UIStroke, tweenInfo, {
			Transparency = 0,
		}):Play()
		return task.delay(tweenInfo.Time + appearanceTime, function()
			if flagCompare == effectFlag then
				TweenService:Create(textLabel, tweenInfo, {
					TextTransparency = 1,
				}):Play()
				return TweenService:Create(textLabel.UIStroke, tweenInfo, {
					Transparency = 1,
				}):Play()
			end
		end)
	end
end

--<<Returns curve scale based on distance travelled and distance between
function globalFunctions.UseCurveScale(): (distanceCovered: number, distanceBetween: number) -> number
	local distanceTravelled: number = 0
	return function(distanceCovered: number, distanceBetween: number)
		distanceTravelled += distanceCovered
		return 1 + 1 / math.max(0.001, distanceBetween - distanceTravelled)
	end
end

--<<Returns a function that is used for lerping frisbee direction
function globalFunctions.UseFrisbeeDirectionLerping(): (distanceCovered: number, distanceBetween: number) -> number
	local LERP_CONSTANT: number = game.ReplicatedStorage.Constants.Frisbee.LERP_CONSTANT.Value

	local curveScaleCalculator = globalFunctions.UseCurveScale()
	local lerpAmount: number = 0
	return function(distanceCovered: number, distanceBetween: number)
		if lerpAmount < 1 then
			lerpAmount =
				math.min(lerpAmount + (LERP_CONSTANT * curveScaleCalculator(distanceCovered, distanceBetween)), 1)
		end
		return lerpAmount
	end
end

return globalFunctions
