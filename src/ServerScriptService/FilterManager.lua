local TextService = game:GetService("TextService")

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local ServerMod = require(game.ServerScriptService.ServerMod)

-- this will filter the sentences as one block instead of one by one
local HARD_FILTERING_ENABLED = false
local PRIVATE_CHAT_ENABLED = false

local FilterManager = {}

function FilterManager:init() end

-- strictest filtering settings
function FilterManager:filterStringForBroadcast(chatString, player)
	local userId = player.UserId

	local filteredString
	local success, err = pcall(function()
		-- filter it for chat for the receiving
		local chatFilterContext = Enum.TextFilterContext.PublicChat
		if PRIVATE_CHAT_ENABLED then
			chatFilterContext = Enum.TextFilterContext.PrivateChat
		end

		local filteredResult = TextService:FilterStringAsync(chatString, userId, chatFilterContext)
		filteredString = filteredResult:GetNonChatStringForBroadcastAsync()
	end)
	if not success then
		warn("COULD NOT FILTER STRING: ", err)
		return ""
	end
	return filteredString
end

function FilterManager:filterSentences(messageString, player, forNonChat)
	if HARD_FILTERING_ENABLED then
		return self:filterStringForBroadcast(messageString, player)
	end

	-- Split the chatString into sentences with their ending punctuation
	local sentences = {}
	for sentence, ending in messageString:gmatch("([^%.%!%?%,]+)([%.%!%?%,]?)") do
		-- Trim leading and trailing whitespace, and reduce multiple spaces to single spaces
		sentence = sentence:match("^%s*(.-)%s*$"):gsub("%s+", " ")
		if sentence ~= "" then
			-- Keep the sentence with its ending punctuation
			table.insert(sentences, { text = sentence, ending = ending })
		end
	end

	local filteredSentences = {}
	for _, sentenceData in ipairs(sentences) do
		local filteredSentence = self:filterString(sentenceData.text, player, forNonChat)
		if sentenceData.ending ~= "" then
			filteredSentence = filteredSentence .. sentenceData.ending
		end
		table.insert(filteredSentences, filteredSentence)
	end

	-- Combine the filtered sentences back into a single string
	local filteredString = table.concat(filteredSentences, " ")
	if not filteredString or filteredString == "" then
		warn("!!!!!! NO FILTERED STRING: ", messageString)
		filteredString = "..."
	end

	return filteredString
end

function FilterManager:filterStringFromAuthor(chatString, player, authorUserId)
	local userId = player.UserId

	local filteredString
	local success, err = pcall(function()
		local filteredResult =
			TextService:FilterStringAsync(chatString, authorUserId, Enum.TextFilterContext.PublicChat)

		-- have to set it to true cause roblox broke GetChatForUserAsync:
		-- https://devforum.roblox.com/t/textservice-filtering-returns-empty-message-for-valid-text-input/
		-- filteredString = filteredResult:GetChatForUserAsync(userId)
		filteredString = filteredResult:GetNonChatStringForUserAsync(userId)
	end)
	if not success then
		warn("COULD NOT FILTER STRING: ", err)
		return false, nil
	end

	return true, filteredString
end

function FilterManager:filterString(chatString, player, forNonChat)
	local userId = player.UserId

	-- have to set it to true cause roblox broke GetChatForUserAsync:
	-- https://devforum.roblox.com/t/textservice-filtering-returns-empty-message-for-valid-text-input/
	forNonChat = true

	local filteredString
	local success, err = pcall(function()
		-- filter it for chat for the receiving
		local chatFilterContext = Enum.TextFilterContext.PublicChat
		if PRIVATE_CHAT_ENABLED then
			chatFilterContext = Enum.TextFilterContext.PrivateChat
		end

		local filteredResult = TextService:FilterStringAsync(chatString, userId, chatFilterContext)

		if forNonChat then
			filteredString = filteredResult:GetNonChatStringForUserAsync(userId)
		else
			filteredString = filteredResult:GetChatForUserAsync(userId)
		end
	end)
	if not success then
		warn("COULD NOT FILTER STRING: ", err)
		return false, nil
	end
	return true, filteredString
end

FilterManager:init()

return FilterManager
