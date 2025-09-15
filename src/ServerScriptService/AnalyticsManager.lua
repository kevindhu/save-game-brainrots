local AnalyticsService = game:GetService("AnalyticsService")

local ServerMod = require(game.ServerScriptService.ServerMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local AnalyticsManager = {}
AnalyticsManager.__index = AnalyticsManager

function AnalyticsManager.new(owner, data)
	local u = {}
	u.owner = owner
	u.data = data

	setmetatable(u, AnalyticsManager)
	return u
end

function AnalyticsManager:init()
	self.user = self.owner.user
	for k, v in pairs(self.data) do
		self[k] = v
	end
end

function AnalyticsManager:logCustomEvent(eventName, value, eventData)
	if Common.isStudio then
		return
	end

	if len(eventData) > 3 then
		warn("EVENT DATA HAS TOO MANY FIELDS: ", eventName, eventData)
		return
	end

	local eventDictionary = self:createEventDictionary(eventData)

	-- print("LOGGING CUSTOM EVENT: ", eventName, value, eventDictionary)

	if Common.isStudio then
		return
	end

	AnalyticsService:LogCustomEvent(self.user.player, eventName, value, eventDictionary)
end

function AnalyticsManager:createEventDictionary(eventData)
	local eventDictionary = {}
	for index, v in ipairs(eventData) do
		eventDictionary[Enum.AnalyticsCustomFieldKeys["CustomField0" .. index].Name] = v
	end
	return eventDictionary
end

function AnalyticsManager:logFunnelStepEvent(funnelName, stepNumber, stepName, eventData)
	local eventDictionary = self:createEventDictionary(eventData)

	local funnelSessionId = self.user.funnelSessionId

	-- print("LOGGING FUNNEL EVENT: ", funnelName, funnelSessionId, stepNumber, stepName, eventDictionary)

	if Common.isStudio then
		return
	end

	AnalyticsService:LogFunnelStepEvent(
		self.user.player,
		funnelName,
		funnelSessionId,
		stepNumber, -- step number
		stepName, -- step name
		eventDictionary -- custom fields
	)
end

function AnalyticsManager:logOnboardingFunnelEvent(stepNumber, stepName, eventData)
	local eventDictionary = self:createEventDictionary(eventData)

	if Common.isStudio then
		return
	end

	self:logFunnelStepEvent("Tutorial1", stepNumber, stepName, eventData)

	AnalyticsService:LogOnboardingFunnelStepEvent(
		self.user.player,
		stepNumber, -- step number
		stepName, -- step name
		eventDictionary -- custom fields
	)
end

function AnalyticsManager:saveState() end

return AnalyticsManager
