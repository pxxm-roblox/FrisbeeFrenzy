local UserInputService = game:GetService("UserInputService")

local INPUT_ACTIONS = {
	Main = "Main",
	Grapple = "Grapple",
	Ability = "Ability",
}
local playerDevice: string = "PC" --DEFAULT

if UserInputService.MouseEnabled and UserInputService.KeyboardEnabled then
	playerDevice = "PC"
elseif UserInputService.TouchEnabled then
	playerDevice = "Mobile"
end

return {
	INPUT_ACTIONS = INPUT_ACTIONS,
	PlayerDevice = playerDevice,
	PC = {
		[INPUT_ACTIONS.Main] = { Enum.KeyCode.F, Enum.UserInputType.MouseButton1 },
		[INPUT_ACTIONS.Ability] = Enum.KeyCode.Q,
	},
}
