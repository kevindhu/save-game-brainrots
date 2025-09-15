local player = game.Players.LocalPlayer
local playerScripts = player.PlayerScripts
local playerGui = player.PlayerGui

local ClientMod = require(playerScripts.ClientMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local tradeGUI = playerGui:WaitForChild("TradeGUI")
local confirmFrame = tradeGUI.ConfirmFrame

local TradeManager = {}
TradeManager.__index = TradeManager

function TradeManager:init()
	self:addCons()

	self:toggleConfirmFrame(false)
end

function TradeManager:addCons()
	ClientMod.buttonManager:addActivateCons(confirmFrame.AcceptButton, function()
		ClientMod:FireServer("tryAcceptGift", {
			gifterUserName = self.gifterUserName,
			acceptBool = true,
		})
		self:toggleConfirmFrame(false)
	end)

	ClientMod.buttonManager:addActivateCons(confirmFrame.DeclineButton, function()
		ClientMod:FireServer("tryAcceptGift", {
			gifterUserName = self.gifterUserName,
			acceptBool = false,
		})
		self:toggleConfirmFrame(false)
	end)
end

function TradeManager:updateGiftMod(data)
	self.gifterUserName = data["gifterUserName"]
	self.giftMod = data["giftMod"]

	local itemClass = self.giftMod["itemClass"]
	local itemStats = ClientMod.itemStash:getFullItemStats(itemClass)

	confirmFrame.DescriptionTitle.Text =
		string.format("%s is gifting you a %s", self.gifterUserName, itemStats["alias"])

	local expiree = self.giftMod["expiree"]
	local timeLeft = expiree - os.time()

	local progressBar = confirmFrame.TimeBar.ProgressBar
	progressBar.Size = UDim2.fromScale(1, 1)

	ClientMod.tweenManager:createTween({
		target = progressBar,
		timer = timeLeft,
		easingStyle = "Linear",
		easingDirection = "Out",
		goal = { Size = UDim2.fromScale(0, 1) },
	})

	self:toggleConfirmFrame(true)
end

function TradeManager:toggleConfirmFrame(newBool)
	if newBool then
		confirmFrame.Visible = true
	else
		confirmFrame.Visible = false
	end
end

function TradeManager:tick()
	local giftMod = self.giftMod
	if not giftMod then
		return
	end

	local expiree = giftMod["expiree"]
	if expiree < os.time() then
		self:toggleConfirmFrame(false)
	end
end

TradeManager:init()

return TradeManager
