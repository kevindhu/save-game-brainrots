local player = game.Players.LocalPlayer
local playerScripts = player.PlayerScripts
local playerGui = player.PlayerGui

local ClientMod = require(playerScripts.ClientMod)
local LeaderInfo = require(game.ReplicatedStorage.Data.LeaderInfo)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local Leader = {}
Leader.__index = Leader

function Leader.new(data)
	local u = {}
	u.data = data

	u.userMods = {}
	u.userModsList = {}

	setmetatable(u, Leader)
	return u
end

function Leader:init()
	local data = self.data
	for k, v in pairs(data) do
		self[k] = v
	end

	self:initStats()
	self:initModel()
	self:initBB()
end

function Leader:initModel()
	local model = game.Workspace:WaitForChild("Leaderboards"):WaitForChild(self.leaderClass .. "Model")
	self.model = model
end

function Leader:initStats()
	local stats = LeaderInfo:getMeta(self.leaderClass)
	self.stats = stats

	self.itemClass = stats["itemClass"]
end

function Leader:initBB()
	local bb = self.model:WaitForChild("BBPart").BB
	bb.Adornee = bb.Parent
	bb.Name = "LEADERBB"

	local defaultDistance = 75

	-- added to playerGUI here
	ClientMod.uiManager:addBBToPlayerGUI(bb, defaultDistance)

	local itemList = bb.ItemList
	itemList.BackgroundTransparency = 1

	self.templateUserItem = itemList.TemplateItem
	self.templateUserItem.Visible = false

	self.bb = bb
end

function Leader:removeUserMod(userMod)
	local userId = userMod["userId"]
	local frame = userMod["frame"]
	if frame and frame.Parent then
		frame:Destroy()
	end

	userMod["destroyed"] = true

	self.userMods[tostring(userId)] = nil
end

function Leader:updateUserMods(data)
	local userModsData = data["userModsList"]
	self.userModsData = userModsData

	self:populateBB()
end

function Leader:populateBB()
	if not self.bb then
		return
	end

	for _, userMod in pairs(self.userMods) do
		self:removeUserMod(userMod)
	end
	self.userModsList = {}

	local userModsData = self.userModsData
	if not userModsData then
		return
	end

	for index, userData in pairs(userModsData) do
		self:newUserMod(userData)
	end

	self:refreshUsernames()
end

local rankIconMap = {
	["1"] = "rbxassetid://105088297845713",
	["2"] = "rbxassetid://137895795677217",
	["3"] = "rbxassetid://80752807509079",
}

function Leader:newUserMod(userData)
	local frame = self.templateUserItem:Clone()
	frame.Visible = true
	frame.Parent = self.templateUserItem.Parent

	local userId = userData["userId"]
	local score = userData["score"]
	local rank = userData["rank"]

	local scoreString = Common.abbreviateNumber(score, 2)
	if self.itemClass == "Playtime" then
		scoreString = Common.convertSecondsToReadableString(score)
	elseif self.itemClass == "RobuxDonations" then
		scoreString = Common.commas(score) .. " R$"
	end

	local rankTitle = frame.RankTitle
	local icon = rankTitle.Icon
	if rankIconMap[tostring(rank)] then
		icon.Image = rankIconMap[tostring(rank)]
		rankTitle.Text = ""
		icon.Visible = true
	else
		rankTitle.Text = rank
		icon.Visible = false
	end

	frame.ValueTitle.Text = scoreString

	frame.BackgroundTransparency = 1

	frame.LayoutOrder = rank

	local newUserMod = {
		frame = frame,

		userId = userId,
		score = score,
		rank = rank,
	}

	frame.NameTitle.Text = "..."

	routine(function()
		local faceImage = Common.getProfileImageFromUserId(userId)
		if not faceImage or not frame or newUserMod["destroyed"] then
			return
		end
		local playerIcon = frame:FindFirstChild("PlayerIcon")
		if not playerIcon then
			return
		end

		playerIcon.Image = faceImage
	end)

	self.userMods[tostring(userId)] = newUserMod
	table.insert(self.userModsList, newUserMod)
end

function Leader:refreshUsernames()
	for _, userMod in pairs(self.userMods) do
		local usernameMap = Common.usernameMap
		local frame = userMod["frame"]
		local userId = userMod["userId"]

		userId = tonumber(userId)

		local userName = usernameMap[userId]
		if not userName then
			continue
		end
		frame.NameTitle.Text = userName
	end
end

return Leader
