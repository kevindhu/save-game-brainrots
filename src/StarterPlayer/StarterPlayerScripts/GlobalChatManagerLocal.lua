local TextChatService = game:GetService("TextChatService")

local player = game.Players.LocalPlayer
local playerScripts = game.Players.LocalPlayer.PlayerScripts
local playerGui = player:WaitForChild("PlayerGui")

local ClientMod = require(playerScripts.ClientMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local generalChannel = TextChatService.TextChannels.RBXGeneral
TextChatService.ChannelTabsConfiguration.Enabled = false

local GlobalChatManager = {}

function GlobalChatManager:init()
	self:addTextChatCons()
end

function GlobalChatManager:addTextChatCons()
	TextChatService.OnIncomingMessage = function(message)
		local props = Instance.new("TextChatMessageProperties")

		if message.TextSource then
			local vipHeader = Common.addRichTextColor("[VIP]", Color3.fromRGB(247, 255, 90))
			props.PrefixText = vipHeader .. " " .. message.PrefixText
		end

		return props
	end
end

function GlobalChatManager:addWelcome(data)
	local welcomeMessages = {
		{
			text = "😀 Private servers are free!",
			color = Color3.fromRGB(255, 255, 255),
		},
		{
			text = "❤️ Leaving a like and favorite would be much appreciated!",
			color = Color3.fromRGB(79, 234, 255),
		},
		{
			text = "📢 Join our roblox group and community server for updates!",
			color = Color3.fromRGB(172, 117, 255),
		},
	}

	for _, message in ipairs(welcomeMessages) do
		local coloredText = Common.addRichTextColor(message.text, message.color)
		generalChannel:DisplaySystemMessage(coloredText)
	end
end

function GlobalChatManager:broadcastServerMessage(data)
	local message = data["message"]
	local messageColor = data["color"] or Color3.fromRGB(254, 112, 73)

	local richMessageString = self:buildRichText({
		{ text = message, color = messageColor },
	})
	generalChannel:DisplaySystemMessage(richMessageString)
end

-- Helper function to build rich text from segments
function GlobalChatManager:buildRichText(segments)
	local result = ""
	for _, segment in ipairs(segments) do
		result = result .. Common.addRichTextColor(segment.text, segment.color)
	end
	return result
end

GlobalChatManager:init()

return GlobalChatManager
