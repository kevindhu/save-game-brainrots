local ServerMod = require(game.ServerScriptService.ServerMod)

local CodeInfo = require(game.ReplicatedStorage.Data.CodeInfo)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local CodeManager = {}
CodeManager.__index = CodeManager

function CodeManager.new(user, data)
	local u = {}
	u.user = user
	u.data = data

	u.codeMods = {}

	setmetatable(u, CodeManager)
	return u
end

function CodeManager:init()
	local data = self.data
	for k, v in pairs(data) do
		self[k] = v
	end
end

function CodeManager:tryCode(data)
	local codeClass = data["codeClass"]
	if self.codeMods[codeClass] then
		-- send redeem
		local failureText = "Already redeemed: %s"
		failureText = string.format(failureText, codeClass)
		self:sendNotification(failureText, false)
		return
	end

	if codeClass == "tutorial" then
		local tutManager = self.user.tutManager
		if not tutManager:checkCompletedMajorTutorial() then
			local failureText = "You must complete the tutorial first!"
			self:sendNotification(failureText, false)
			return
		end
	end

	local noWarn = true
	local stats = CodeInfo:getMeta(codeClass, noWarn)
	if not stats then
		local failureText = "Invalid code!"
		self:sendNotification(failureText, false)
		return
	end

	if stats["expiree"] and os.time() > stats["expiree"] then
		local failureText = "Code has expired!"
		self:sendNotification(failureText, false)
		return
	end

	self:newCodeMod(codeClass)

	local successTxt = "Redeemed code: '%s'"
	successTxt = string.format(successTxt, codeClass)

	self.user.notifyManager:notifySuccess(successTxt, nil, "SuccessNotify1")
	self:sendNotification(successTxt, true)
	self:addReward(codeClass)
end

function CodeManager:addReward(codeClass)
	local stats = CodeInfo:getMeta(codeClass)
	local rewardList = stats["rewards"]
	for _, reward in pairs(rewardList) do
		self.user.rewardManager:addRewards(reward)
	end
end

function CodeManager:newCodeMod(codeClass)
	local newCodeMod = {
		codeClass = codeClass,
		redeemTime = os.time(),
	}
	self.codeMods[codeClass] = newCodeMod
end

function CodeManager:sendNotification(txt, success)
	local data = {
		txt = txt,
		success = success,
	}
	ServerMod:FireClient(self.user.player, "codeNotify", data)
end

function CodeManager:saveState()
	local managerInfo = {
		codeMods = self.codeMods,
	}
	self.user.store:set(self.moduleAlias .. "Info", managerInfo)
end

return CodeManager
