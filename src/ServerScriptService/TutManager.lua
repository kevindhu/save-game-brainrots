local ServerMod = require(game.ServerScriptService.ServerMod)

local TutInfo = require(game.ReplicatedStorage.TutInfo)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local TutManager = {}
TutManager.__index = TutManager

function TutManager.new(owner, data)
	local u = {}
	u.owner = owner
	u.data = data

	u.tutMods = {}
	u.completedTutMods = {}

	setmetatable(u, TutManager)
	return u
end

function TutManager:init()
	self.user = self.owner.user
	for k, v in pairs(self.data) do
		self[k] = v
	end

	self:sendCompletedMods()

	routine(function()
		wait(2)

		if self.isNew then
			self:initFirstTutMods()
		end

		self:loadChosenTutMod()
		self:tryChooseNewTutMod()

		self.initialized = true
	end)
end

function TutManager:loadChosenTutMod()
	local savedChosenTutModName = self.savedChosenTutModName
	if not savedChosenTutModName then
		return
	end

	local tutMod = self.tutMods[savedChosenTutModName]
	if not tutMod then
		warn("!!! NO TUTMOD WITH NAME: ", savedChosenTutModName, self.tutMods)
		return
	end

	self:chooseTutMod(tutMod)
end

function TutManager:tryChooseNewTutMod()
	if self.chosenTutMod then
		return
	end

	for _, tutMod in pairs(self.tutMods) do
		self:chooseTutMod(tutMod)
		return
	end
end

function TutManager:initFirstTutMods()
	if Common.checkDeveloper(self.user.userId) then
		return
	end

	-- clear all existing tutMods
	self.tutMods = {}
	self.completedTutMods = {}

	self.chosenTutModName = nil

	self.user.home.analyticsManager:logOnboardingFunnelEvent(1, "Tutorial Started", {})

	self:newTutMod("TeleportToEggShop1")
end

function TutManager:newTutMod(tutName)
	if self.tutMods[tutName] then
		warn("ALREADY HAVE TUTMOD CANNOT ADD NEW: ", tutName)
		return
	end

	local tutStats = TutInfo:getMeta(tutName)

	local newTutMod = {
		tutName = tutName,
		targetClass = tutStats["targetClass"],
		requireMod = Common.deepCopy(tutStats["requireMod"]),
	}
	self.tutMods[tutName] = newTutMod

	local requireMod = newTutMod["requireMod"]
	if requireMod["timer"] then
		local newExpiree = os.time() + requireMod["timer"]
		newTutMod["expiree"] = newExpiree
	end

	self:sendTutMods()
end

function TutManager:sendTutMods()
	ServerMod:FireClient(self.user.player, "updateTutMods", self.tutMods)
end

function TutManager:sendCompletedMods()
	ServerMod:FireClient(self.user.player, "updateCompletedTutMods", self.completedTutMods)
end

function TutManager:tick()
	if not self.initialized then
		return
	end
	self:tickChosenTutMod()
end

function TutManager:tickChosenTutMod()
	local tutMod = self.chosenTutMod
	if not tutMod then
		return
	end
	local expiree = tutMod["expiree"]
	if not expiree or expiree > os.time() then
		return
	end

	local tutName = tutMod["tutName"]
	self:completeTutMod(tutName)
end

function TutManager:chooseTutMod(tutMod)
	self.chosenTutMod = tutMod

	local tutName = nil
	if tutMod then
		tutName = tutMod["tutName"]
	end

	-- print("CHOSEN TUT MOD: ", tutName)

	local chosenData = {
		tutName = tutName,
	}
	ServerMod:FireClient(self.user.player, "chooseTutMod", chosenData)
end

function TutManager:tryUpdateTutMod(data)
	-- TODO: validate if this is possible to do

	self:updateTutMod(data)
end

function TutManager:updateTutMod(data)
	local chosenTargetClass = data["targetClass"]
	local updateCount = data["updateCount"]
	local setCount = data["setCount"]

	for currName, tutMod in pairs(self.tutMods) do
		local targetClass = tutMod["targetClass"]
		if chosenTargetClass ~= targetClass then
			continue
		end

		local requireMod = tutMod["requireMod"]
		if setCount then
			if requireMod["setCount"] <= setCount then
				self:completeTutMod(currName)
			end
		elseif updateCount then
			requireMod["count"] = requireMod["count"] - updateCount

			if requireMod["count"] <= 0 then
				self:completeTutMod(currName)

			-- send the tutMods with the new require count
			elseif tutMod["countText"] then
				self:sendTutMods()
			end
		end
	end
end

function TutManager:checkCompletedMajorTutorial()
	return self.completedTutMods["BuySecondEgg"] ~= nil
end

function TutManager:checkHasCompletedAllTutorials()
	if Common.checkDeveloper(self.user.userId) then
		return true
	end

	return (self.completedTutMods["CompleteTutorial"] ~= nil)
end

function TutManager:completeTutMod(tutName)
	local tutMod = self.tutMods[tutName]
	if not tutMod then
		warn("!!! NO TUTMOD WITH NAME: ", tutName, self.tutMods)
		return
	end

	self.tutMods[tutName] = nil
	self.completedTutMods[tutName] = {
		completionTime = os.time(),
	}

	local tutStats = TutInfo:getMeta(tutName)

	self:chooseTutMod(nil)
	self:sendCompletedMods()

	local funnelStep = tutStats["funnelStep"] + 1
	local funnelName = tutName .. " Completed"

	self.user.home.analyticsManager:logOnboardingFunnelEvent(funnelStep, funnelName, {})

	local enableList = TutInfo.enableMapping[tutName]
	if enableList then
		for _, newName in pairs(enableList) do
			self:newTutMod(newName)
		end
	end

	routine(function()
		local favoriteManager = self.user.home.favoriteManager
		favoriteManager.favoriteGameExpiree = os.time() + math.random(10, 15)
		if tutName == "CompleteTutorial" then
			favoriteManager:tryStartFavorite()
		end
	end)

	self:tryChooseNewTutMod()
end

function TutManager:saveState()
	local savedChosenTutModName = nil
	if self.chosenTutMod then
		savedChosenTutModName = self.chosenTutMod["tutName"]
	end

	local managerData = {
		tutMods = self.tutMods,
		completedTutMods = self.completedTutMods,
		savedChosenTutModName = savedChosenTutModName,
	}
	self.user.store:set(self.moduleAlias .. "Info", managerData)
end

return TutManager
