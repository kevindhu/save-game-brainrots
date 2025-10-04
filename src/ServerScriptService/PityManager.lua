local ServerMod = require(game.ServerScriptService.ServerMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local PityManager = {}
PityManager.__index = PityManager

function PityManager.new(owner, data)
	local u = {}
	u.owner = owner
	u.data = data

	u.legendaryCount = 0
	u.mythicCount = 0

	u.legendaryMax = 100 -- 20
	u.mythicMax = 1000

	setmetatable(u, PityManager)
	return u
end

function PityManager:init()
	self.user = self.owner.user
	for k, v in pairs(self.data) do
		self[k] = v
	end
end

function PityManager:initPityModel(model)
	self.boardModel = model.PityBoardModel

	local boardPart = self.boardModel.BoardPart

	self.boardFrame = boardPart.BB.MainFrame

	self:refreshBB()
end

function PityManager:incrementPetCount()
	self.legendaryCount += 1
	self.mythicCount += 1

	if self.mythicCount >= self.mythicMax then
		self.mythicUnlocked = true
		self.mythicCount = 0
	end
	if self.legendaryCount >= self.legendaryMax then
		self.legendaryUnlocked = true
		self.legendaryCount = 0
	end

	self:refreshBB()
end

function PityManager:refreshBB()
	local boardFrame = self.boardFrame

	local legendaryProgressBar = boardFrame.LegendaryProgressBar
	legendaryProgressBar.Title.Text = string.format("%s/%s", self.legendaryCount, self.legendaryMax)
	legendaryProgressBar.ProgressBar.Size = UDim2.fromScale(self.legendaryCount / self.legendaryMax, 1)

	local mythicProgressBar = boardFrame.MythicProgressBar
	mythicProgressBar.Title.Text = string.format("%s/%s", self.mythicCount, self.mythicMax)
	mythicProgressBar.ProgressBar.Size = UDim2.fromScale(self.mythicCount / self.mythicMax, 1)
end

function PityManager:saveState()
	local managerData = {
		legendaryCount = self.legendaryCount,
		mythicCount = self.mythicCount,

		legendaryUnlocked = self.legendaryUnlocked,
		mythicUnlocked = self.mythicUnlocked,
	}
	self.user.store:set(self.moduleAlias .. "Info", managerData)
end

function PityManager:wipe()
	self.legendaryCount = 0
	self.mythicCount = 0
	self.legendaryUnlocked = false
	self.mythicUnlocked = false
	self:refreshBB()
end

return PityManager
