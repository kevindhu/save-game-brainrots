local HttpService = game:GetService("HttpService")

local ServerMod = require(script.Parent.ServerMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local WebhookManager = {}
WebhookManager.__index = WebhookManager

function WebhookManager:init() end

function WebhookManager:getRobloxImageUrl(userId)
	return string.format(
		"https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=%s&size=420x420&format=Png&isCircular=false&thumbnailType=HeadShot",
		userId
	)
end

local channelMap = {
	User = "1354608675314204886/vpmfqgVtoayvkhEo64ZZu5rmS3v-gxPpl8AcDurT5g80hLwGrvrgnpOvReOqSgvo1cDA",
}

local webhookIdMap = {
	-- user
	Report = "User",
}

local titleMap = {
	-- user
	Report = "Reported Outfit",
}

function WebhookManager:addWebhook(data)
	local discordWebhookProxyUrl = "http://192.9.230.16:3000"

	local webhookClass = data["webhookClass"]
	local webhookId = channelMap[webhookIdMap[webhookClass]]
	local webhookUrl = string.format("%s/api/webhooks/%s", discordWebhookProxyUrl, webhookId)

	local title = titleMap[webhookClass]

	-- Create properly formatted Discord embed fields
	local embedFields = {}
	for key, value in pairs(data["embedDetails"]) do
		table.insert(embedFields, {
			name = key,
			value = tostring(value),
			inline = true,
		})
	end

	local robloxImageUrl = self:getRobloxImageUrl(data["userId"])
	local webhookData = {
		embeds = {
			{
				title = title,
				color = 15158332, -- Red color
				fields = embedFields,
			},
		},
		roblox_image_url = robloxImageUrl,
	}
	local success, response = self:callWebhook(webhookUrl, webhookData)
	if not success then
		return false, "failed to call webhook"
	end
	return true, response
end

function WebhookManager:callWebhook(webhookUrl, webhookData)
	-- Encode body if provided
	local encodedBody = webhookData and HttpService:JSONEncode(webhookData) or nil

	local success, response = pcall(function()
		return HttpService:RequestAsync({
			Url = webhookUrl,
			Method = "POST",
			Headers = {
				["Content-Type"] = "application/json",
			},
			Body = encodedBody,
		})
	end)

	-- Handle errors
	if not success or not response then
		warn(debug.traceback())
		warn("FAILED TO CALL WEBHOOK: ", webhookUrl, response, webhookData)
		return false, "failed to call webhook"
	end

	if response["StatusCode"] >= 300 then
		-- warn(debug.traceback())
		warn("BAD WEBHOOK STATUS CODE: ", webhookUrl, response["StatusCode"], response)
		return false, "bad status code"
	end
	return true, response
end

WebhookManager:init()

return WebhookManager
