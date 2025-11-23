local LikeManager = {}

local ServerMod = require(game.ServerScriptService.ServerMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

-- Threshold constant for like count milestones
local LIKE_THRESHOLD = 5000 -- 1000
local LIKE_REWARD_RATING = "Secret"

function LikeManager:init() end

function LikeManager:tick()
	routine(function()
		self:tickLikeCounter()
	end)
end

local CHECK_LIKE_TIMER = 60 * 2

function LikeManager:tickLikeCounter()
	if self.likeExpiree and self.likeExpiree > os.time() then
		return
	end
	self.likeExpiree = os.time() + CHECK_LIKE_TIMER

	local likeCounterPart = game.Workspace.LikeCounterModel.ScreenPart

	local oldLikeCount = self.currLikeCount

	local likeCount = self:getLikeCount()
	if likeCount == -1 then
		return
	end

	self.currLikeCount = likeCount

	self:checkCrossedLikeCount(oldLikeCount, likeCount)

	local goalLikeCount = self:calculateNextLikeCount(likeCount)

	local expBar = likeCounterPart.BB.MainFrame.ExpBar
	expBar.Title.Text = "Like Count: "
		.. Common.abbreviateNumber(likeCount)
		.. "/"
		.. Common.abbreviateNumber(goalLikeCount)
	expBar.ProgressBar.Size = UDim2.fromScale(likeCount / goalLikeCount, 1)

	local ratingTitle = likeCounterPart.BB.MainFrame.RatingTitle
	ServerMod.ratingManager:applyRatingColor(ratingTitle, LIKE_REWARD_RATING)

	-- local likeString = Common.abbreviateNumber(goalLikeCount)
	local likeString = Common.commas(goalLikeCount)
	likeCounterPart.BB.MainFrame.LikesTitle.Text = string.format("%s likes!", likeString)
end

function LikeManager:checkCrossedLikeCount(oldLikeCount, likeCount)
	if not oldLikeCount then
		return
	end

	local oldThreshold = math.floor(oldLikeCount / LIKE_THRESHOLD)
	local newThreshold = math.floor(likeCount / LIKE_THRESHOLD)

	if newThreshold > oldThreshold then
		print(
			string.format(
				"LIKE THRESHOLD CROSSED! From %d to %d likes (crossed %d threshold milestone)",
				oldLikeCount,
				likeCount,
				newThreshold * LIKE_THRESHOLD
			)
		)

		-- local rating = LIKE_REWARD_RATING
		-- ServerMod.unitManager:spawnRatingUnit(rating)
	end
end

-- have this be in increments of LIKE_THRESHOLD, so 1000 -> 2000 -> 3000 -> etc
function LikeManager:calculateNextLikeCount(likeCount)
	return math.ceil((likeCount + 1) / LIKE_THRESHOLD) * LIKE_THRESHOLD
end

local urlPrefixMap = {
	["games.roblox.com"] = "u62826t1rd.execute-api.us-west-1.amazonaws.com",
	["avatar.roblox.com"] = "c6xv8n7weh.execute-api.us-west-1.amazonaws.com",
	["catalog.roblox.com"] = "oz7ocmyou4.execute-api.us-west-1.amazonaws.com",
}

function LikeManager:getLikeCount()
	local startTime = os.clock()
	local universeId = Common.universeId
	-- local universeId = 7709344486 -- steal a brainrot

	local urlPrefix = urlPrefixMap["games.roblox.com"]

	local gamesUrl = string.format("%s/v1/games/votes?universeIds=%s", urlPrefix, universeId)

	local response, err, lastResponse = ServerMod.proxyManager:callAPI({
		url = gamesUrl,
		method = "GET",
	})

	if not response then
		warn("COULD NOT GET LIKES: ", err, lastResponse)
		return -1
	end
	local likeCount = response["data"][1]["upVotes"]

	-- print("GOT LIKES URL: ", gamesUrl)
	-- print("GOT LIKES: ", likeCount, " in ", os.clock() - startTime, " seconds")

	return likeCount
end

LikeManager:init()

return LikeManager
