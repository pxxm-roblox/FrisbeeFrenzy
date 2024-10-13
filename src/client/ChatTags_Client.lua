--/SERVICES

local TextChatService: TextChatService = game:GetService("TextChatService")
local Players = game:GetService("Players")

--/TYPES

--/MODULES

--/GLOBAL_VARIABLES

local chatTagsClient = {}

local ChatTags = {
	Developer = {
		Color = "#3bd6c6",
		Tag = "Developer 🔨",
	},
	Owner = {
		Color = "#ff0000",
		Tag = "Owner 👑",
	},
	VIP = {
		Color = "#fdf68c",
		Tag = "VIP ✨",
	},
}

--/GLOBAL_FUNCTIONS

--/MODULAR_FUNCTIONS

TextChatService.OnIncomingMessage = function(message: TextChatMessage)
	local props = Instance.new("TextChatMessageProperties")

	if message.TextSource then
		local player: Player = Players:GetPlayerByUserId(message.TextSource.UserId)
		local chatTag: string = player:GetAttribute("ChatTag")
		if chatTag then
			local chatTagData = ChatTags[chatTag]
			props.PrefixText = ("<font color='%s'>[%s]</font> "):format(chatTagData.Color, chatTagData.Tag)
				.. message.PrefixText
		end
	end

	return props
end

return chatTagsClient
