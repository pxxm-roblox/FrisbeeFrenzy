--/SERVICES

--/TYPES

--/MODULES

--/GLOBAL_VARIABLES

local GrappleAbility = {}

--/GLOBAL_FUNCTIONS

local function enableGrappleString(mainChar: Model, oldSelectedPart: BasePart)
	local beamEffect: Beam = mainChar["Right Arm"]:FindFirstChild("GrappleString")
	if beamEffect then
		local attachment1: Attachment = oldSelectedPart:FindFirstChildWhichIsA("Attachment")
			or Instance.new("Attachment")
		attachment1.Parent = oldSelectedPart
		beamEffect.Attachment1 = attachment1
	end
end

--<Disables string effect
local function disableGrappleString(mainChar: Model)
	local beamEffect: Beam = mainChar["Right Arm"]:FindFirstChild("GrappleString")
	if beamEffect then
		beamEffect.Attachment1 = nil
	end
end

--/MODULAR_FUNCTIONS

function GrappleAbility.Main(
	mainChar: Model,
	onAbilityEnd: (ignoreReplication: boolean) -> nil,
	args: { Time: number, Part: BasePart }
)
	enableGrappleString(mainChar, args.Part)
	return task.delay(args.Time, function()
		onAbilityEnd(true)
		disableGrappleString(mainChar)
	end)
end

return GrappleAbility
