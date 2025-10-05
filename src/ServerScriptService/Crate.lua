local ServerMod = require(script.Parent.ServerMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local CrateInfo = require(game.ReplicatedStorage.CrateInfo)
local RatingInfo = require(game.ReplicatedStorage.RatingInfo)
local PetInfo = require(game.ReplicatedStorage.PetInfo)
local RelicInfo = require(game.ReplicatedStorage.RelicInfo)

local Crate = {}
Crate.__index = Crate

function Crate.new(data)
	local u = {}
	u.data = data

	setmetatable(u, Crate)
	return u
end

function Crate:init()
	for k, v in pairs(self.data) do
		self[k] = v
	end
	self.user = self.owner.user

	-- self.baseModel = game.ReplicatedStorage.Assets[self.crateClass]

	self.crateStats = CrateInfo:getMeta(self.crateClass)
	self.currFrame = self.firstFrame

	for _, otherUser in pairs(ServerMod.users) do
		self:sync(otherUser)
	end

	routine(function()
		self:hatch()
	end)
end

function Crate:sync(otherUser)
	ServerMod:FireClient(otherUser.player, "newCrate", {
		crateName = self.crateName,
		userName = self.user.name,

		crateClass = self.crateClass,

		currFrame = self.currFrame,
	})
end

function Crate:hatch()
	local relicProbMap = Common.deepCopy(self.crateStats["relicProbMap"])
	-- self:addWeatherWeight(relicProbMap)
	-- self:addLuckWeights(relicProbMap)

	local relicClass = Common.rollFromProbMap(relicProbMap)

	self.user.home.tutManager:updateTutMod({
		targetClass = "HatchFirstCrate",
		updateCount = 1,
	})

	ServerMod:FireClient(self.user.player, "doHatch", {
		userName = self.user.name,
		itemClass = "Relic",
		relicClass = relicClass,
	})

	local relicStats = RelicInfo:getMeta(relicClass)
	self.user:newNotifyMod({
		txt = string.format("You unboxed a %s!", Common.addRichTextColor(relicStats["alias"], relicStats["color"])),
		color = Color3.fromRGB(255, 255, 255),
	})
	ServerMod:FireClient(self.user.player, "newSoundMod", {
		soundClass = "SuccessHatch1",
		volume = 0.5,
	})

	local itemData = {
		relicClass = relicClass,
	}
	self.user.home.itemStash:addRelic(itemData)

	self:destroy()
end

function Crate:destroy()
	if self.destroyed then
		warn("ALREADY DESTROYED USER HUH: ", self.name)
		return
	end
	self.destroyed = true

	self.owner.crates[self.crateName] = nil

	ServerMod:FireAllClients("removeCrate", {
		crateName = self.crateName,
	})
end

return Crate
