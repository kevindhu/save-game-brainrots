local ServerMod = require(game.ServerScriptService.ServerMod)

local SetInfo = require(game.ReplicatedStorage.SetInfo)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local SetManager = {}
SetManager.__index = SetManager

function SetManager.new(owner, data)
	local u = {}
	u.owner = owner
	u.data = data

	u.setMods = {}

	setmetatable(u, SetManager)
	return u
end

function SetManager:init()
	self.user = self.owner.user
	for k, v in pairs(self.data) do
		self[k] = v
	end

	self:refreshSetMods()
	self:sendSetMods()

	self.initialized = true
end

function SetManager:resetSet(data)
	local setClass = data["setClass"]
	local setMod = self.setMods[setClass]
	if not setMod then
		warn("NO SETMOD NAMED: ", setClass)
		return
	end

	local setStats = SetInfo:getMeta(setClass)
	local setRace = setStats["race"]
	if setRace == "toggle" then
		setMod["toggled"] = setStats["defaultToggle"] or false
	elseif setRace == "slider" then
		local defaultCount = setStats["defaultCount"]

		-- set tentativeCount too so no more jittering on the "isTentative" calls on setAll()
		setMod["count"] = defaultCount
		setMod["tentativeCount"] = defaultCount
		setMod["setOnce"] = false
	end

	self:sendSetMods()
end

function SetManager:trySetToggle(data)
	local setClass = data["setClass"]
	local newToggle = data["toggle"]

	local setMod = self.setMods[setClass]
	if not setMod then
		warn("NO SETMOD NAMED: ", setClass)
		return
	end

	if typeof(newToggle) ~= "boolean" then
		return
	end

	setMod["toggled"] = newToggle

	self:sendSetMods()
end

function SetManager:trySetDropdown(data)
	local setClass = data["setClass"]
	local choiceClass = data["choiceClass"]

	local setMod = self.setMods[setClass]
	if not setMod then
		warn("NO SETMOD NAMED: ", setClass)
		return
	end

	local setStats = SetInfo:getMeta(setClass)
	if not table.find(setStats["choiceList"], choiceClass) then
		warn("NOT A VALID CHOICE: ", choiceClass)
		return
	end

	setMod["choiceClass"] = choiceClass

	self:sendSetMods()
end

function SetManager:trySetSlide(data)
	local setClass = data["setClass"]
	local newCount = data["count"]

	if typeof(newCount) ~= "number" then
		return
	end

	local setMod = self.setMods[setClass]
	if not setMod then
		warn("NO SETMOD NAMED: ", setClass)
		return
	end

	local setStats = SetInfo:getMeta(setClass)
	local minLimit = setStats["minLimit"]
	local maxLimit = setStats["maxLimit"]

	newCount = math.clamp(newCount, minLimit, maxLimit)

	setMod["count"] = newCount

	self:sendSetMods()
end

function SetManager:sendSetMods()
	ServerMod:FireClient(self.user.player, "uSetMods", self.setMods)
end

function SetManager:refreshSetMods()
	for index, setClass in pairs(SetInfo.setList) do
		local stats = SetInfo:getMeta(setClass)
		local setRace = stats["race"]

		local oldSetMod = self.setMods[setClass]
		if oldSetMod then
			-- do sanity checks on oldSetMod (should only need to check sliders, not toggles)
			if setRace == "slider" then
				local oldCount = oldSetMod["count"]
				oldSetMod["count"] = math.clamp(oldCount, stats["minLimit"], stats["maxLimit"])
			elseif setRace == "dropdown" then
				local defaultChoice = stats["defaultChoice"]
				if not oldSetMod["choiceClass"] then
					oldSetMod["choiceClass"] = defaultChoice
				end
			end
		else
			local newSetMod = {
				index = index,
				setClass = setClass,
			}

			if setRace == "toggle" then
				local defaultToggle = stats["defaultToggle"]
				newSetMod["toggled"] = defaultToggle
			elseif setRace == "slider" then
				local defaultCount = stats["defaultCount"]
				newSetMod["count"] = defaultCount
			elseif setRace == "dropdown" then
				local defaultChoice = stats["defaultChoice"]

				newSetMod["choiceClass"] = defaultChoice
			end

			self.setMods[setClass] = newSetMod
		end
	end
end

function SetManager:saveState()
	local managerData = {
		isNew = false,
		setMods = self.setMods,
	}
	self.user.store:set(self.moduleAlias .. "Info", managerData)
end

return SetManager
