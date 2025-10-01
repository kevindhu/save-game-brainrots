local ServerMod = require(game.ServerScriptService.ServerMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local PlotManager = {}
PlotManager.__index = PlotManager

function PlotManager.new(owner, data)
	local u = {}
	u.owner = owner
	u.data = data

	u.likeUserList = {}
	u.hatchedCount = 0

	setmetatable(u, PlotManager)
	return u
end

function PlotManager:init()
	self.user = self.owner.user
	for k, v in pairs(self.data) do
		self[k] = v
	end

	self:obtainRandomPlotName()

	routine(function()
		self:initModel()

		self:sendPlotInfo()

		wait(1)
		self.user.home.saveManager:initSaveModel(self.saveModel)
		self.user.home.pityManager:initPityModel(self.model)
	end)
end

function PlotManager:getTotalLuck()
	local totalUserLuck = 0
	if self.user.home.shopManager:checkOwnsGamepass("BigLuck") then
		totalUserLuck += 2
	end
	if self.user.home.shopManager:checkOwnsGamepass("SmallLuck") then
		totalUserLuck += 0.8
	end

	local serverLuck = ServerMod.luckManager.serverLuck - 1
	local totalLuck = totalUserLuck * 50 + serverLuck * 100

	-- print("GOT TOTAL LUCK: ", totalLuck)

	return totalLuck
end

function PlotManager:obtainRandomPlotName()
	local plotName = ServerMod.map:obtainRandomPlotName()

	-- if self.user.name == "lobotomy6612" and Common.isStudio then
	-- 	plotName = "Plot1"
	-- end

	self.plotName = plotName
end

function PlotManager:getUnitMaxPullCount()
	local unitMaxPullCount = 3

	-- if self.user.home.shopManager:checkOwnsGamepass("Pull2MoreUnits") then
	-- 	unitMaxPullCount = 5
	-- end

	return unitMaxPullCount
end

function PlotManager:tryAddLike(data)
	local userName = data.userName

	if not userName then
		warn("COULD NOT ADD LIKE: NO USER NAME")
		return
	end

	local otherUser = ServerMod.users[userName]
	if not otherUser or not otherUser.initialized then
		warn("COULD NOT ADD LIKE: NO USER")
		return
	end

	if otherUser == self.user then
		-- self.user:notifyError("You cannot like your own plot")
		warn("CANNOT LIKE YOUR OWN PLOT")
		return
	end

	if self.tryAddLikeExpiree and self.tryAddLikeExpiree > ServerMod.step then
		self.user:notifyError("Please wait before trying again")
		return
	end
	self.tryAddLikeExpiree = ServerMod.step + 60 * 1

	local otherPlotManager = otherUser.home.plotManager

	local likeUserList = otherPlotManager.likeUserList
	local alreadyLiked = Common.listContains(likeUserList, tostring(self.user.userId))

	-- cannot remove like for now
	if alreadyLiked then
		return
	end

	otherPlotManager:addLike(self.user.userId)
	self.user:notifySuccess("You have liked " .. userName .. "'s Plot")
end

function PlotManager:initModel()
	local model = game.Workspace[self.plotName]
	self.model = model

	self.floorPart = model.FloorPart
	self.unitStartPart = model.UnitStartPart
	self.safeZone = model.SafeZone

	self.saveModel = model.SaveModel

	self.plotBaseFrame = self.floorPart.CFrame

	self.floorPart:SetAttribute("userName", self.user.name)

	self:initPlotOverhead()
end

function PlotManager:getMaxPetCount()
	local count = 12
	if self.user.home.shopManager:checkOwnsGamepass("10MorePets") then
		count += 10
	end
	return count
end

function PlotManager:sendPlotInfo()
	local plotInfo = {
		plotName = self.plotName,
		userName = self.user.name,
		userId = self.user.userId,
		hatchedCount = self.hatchedCount,
		likeUserList = self.likeUserList,
	}
	ServerMod:FireClient(self.user.player, "updateGlobalPlot", plotInfo)
end

function PlotManager:initPlotOverhead()
	local plotOverheadPart = game.ReplicatedStorage.Assets.PlotOverheadBBPart:Clone()
	plotOverheadPart.Transparency = 1
	plotOverheadPart.Parent = game.Workspace.HitBoxes

	local height = 42 -- 75
	plotOverheadPart.CFrame = self.floorPart.CFrame * CFrame.new(0, height, 0)

	local bb = plotOverheadPart.BB
	bb.MaxDistance = 500

	local mainFrame = bb.MainFrame
	routine(function()
		mainFrame.ProfileIcon.Image = Common.getProfileImageFromUserId(self.user.userId)
	end)
	mainFrame.Title.Text = string.format("@%s", self.user.name)

	self.plotOverheadPart = plotOverheadPart
end

function PlotManager:addLike(userId)
	if Common.listContains(self.likeUserList, tostring(userId)) then
		warn("USER ALREADY LIKED: ", userId)
		return
	end

	table.insert(self.likeUserList, tostring(userId))

	self:sendPlotInfo()
end

function PlotManager:saveState()
	local managerData = {
		likeUserList = self.likeUserList,
		hatchedCount = self.hatchedCount,
	}
	self.user.store:set(self.moduleAlias .. "Info", managerData)
end

function PlotManager:wipe()
	self.likeUserList = {}
	self.hatchedCount = 0

	self:sendPlotInfo()
end

function PlotManager:destroy()
	if self.plotOverheadPart then
		self.plotOverheadPart:Destroy()
		self.plotOverheadPart = nil
	end

	ServerMod.map:cleanPlotModel(self.plotName)

	ServerMod:FireAllClients("clearPlotMod", {
		plotName = self.plotName,
	})
end

return PlotManager
