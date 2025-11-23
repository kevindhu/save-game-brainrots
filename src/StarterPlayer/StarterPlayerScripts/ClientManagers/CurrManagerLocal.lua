local ts = game:GetService("TweenService")

local player = game.Players.LocalPlayer
local playerScripts = player.PlayerScripts
local playerGui = player.PlayerGui

local ClientMod = require(playerScripts.ClientMod)
local buttonGUI = playerGui:WaitForChild("ButtonGUI")

local leftFrame = buttonGUI.LeftFrame
-- local rightFrame = buttonGUI.RightFrame

local coinsFrame = leftFrame.CoinsFrame
local coinsNotifyFrame = leftFrame.CoinsNotifyFrame

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local CurrManager = {
	itemMods = {},
	lerpItemMods = {},
	bounceExpirees = {},

	coinsNotifyMods = {},
}

function CurrManager:init()
	self:addCons()
end

function CurrManager:addCons()
	coinsNotifyFrame.Visible = true
	coinsNotifyFrame.BackgroundTransparency = 1

	self.templateCoinsNotifyItem = coinsNotifyFrame.TemplateItem
	self.templateCoinsNotifyItem.Visible = false
end

function CurrManager:addCoinsNotify(data)
	local count = data["count"]
	local countAbsolute = math.abs(count)

	local notifyName = "CoinsNotify_" .. Common.getGUID()

	local frame = self.templateCoinsNotifyItem:Clone()
	frame.Parent = self.templateCoinsNotifyItem.Parent
	frame.Visible = true

	local title = frame.Title

	if count > 0 then
		title.Text = string.format("+$%s", Common.abbreviateNumber(countAbsolute))
		title.TextColor3 = Color3.fromRGB(255, 213, 1)
	else
		title.Text = string.format("-$%s", Common.abbreviateNumber(countAbsolute))
		title.TextColor3 = Color3.fromRGB(255, 0, 0)
	end

	local newCoinsNotifyMod = {
		frame = frame,
		notifyName = notifyName,
	}
	self.coinsNotifyMods[notifyName] = newCoinsNotifyMod

	routine(function()
		wait(0.45) -- 0.75

		local fadeTimer = 1
		ClientMod.tweenManager:createTween({
			target = frame.Title,
			timer = fadeTimer,
			easingStyle = "Quad",
			easingDirection = "Out",
			goal = {
				TextTransparency = 1,
			},
		})

		ClientMod.tweenManager:createTween({
			target = frame.Title.UIStroke,
			timer = fadeTimer,
			easingStyle = "Quad",
			easingDirection = "Out",
			goal = {
				Transparency = 1,
			},
		})

		wait(fadeTimer + 0.5)
		self:removeCoinsNotify(newCoinsNotifyMod)
	end)
end

function CurrManager:removeCoinsNotify(coinsNotifyMod)
	local frame = coinsNotifyMod["frame"]
	local notifyName = coinsNotifyMod["notifyName"]
	if frame then
		frame:Destroy()
	end
	self.coinsNotifyMods[notifyName] = nil
end

function CurrManager:updateItemMod(data)
	local itemClass = data["itemClass"]
	local count = data["count"]

	self.itemMods[itemClass] = count

	if itemClass == "Coins" then
		ClientMod.luckWizardManager:refreshProgressBar()
	end

	-- ClientMod.basicManager:refreshItemMods()
end

function CurrManager:tickRender(timeRatio)
	for itemClass, itemMod in pairs(self.itemMods) do
		if not Common.listContains({ "Coins" }, itemClass) then
			return
		end

		local startValue = self.lerpItemMods[itemClass] or 0
		local endValue = self.itemMods[itemClass] or 0

		local lerpRatio = 0.1 * timeRatio
		local newValue = Common.lerp(startValue, endValue, lerpRatio)

		self.lerpItemMods[itemClass] = newValue

		if itemClass == "Coins" then
			local coinString = Common.abbreviateNumber(math.round(newValue), 1)
			coinsFrame.Title.Text = coinString
		end
	end
end

function CurrManager:animateIconBounce(icon)
	if self.bounceExpirees[icon] and self.bounceExpirees[icon] > ClientMod.step then
		return
	end
	self.bounceExpirees[icon] = ClientMod.step + 10

	local uiScale = icon.UIScale

	local startScale = 1
	local goalScale = 1.2 -- 1.1

	uiScale.Scale = startScale

	ClientMod.tweenManager:createTween({
		target = uiScale,
		timer = 0.05,
		easingStyle = "Quad",
		easingDirection = "Out",
		repeatCount = 0,
		reverses = true,
		delayTime = 0,
		goal = {
			Scale = goalScale,
		},
	})
end

CurrManager:init()

return CurrManager
