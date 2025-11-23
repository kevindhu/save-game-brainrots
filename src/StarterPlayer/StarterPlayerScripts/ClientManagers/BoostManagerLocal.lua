local player = game.Players.LocalPlayer
local playerGui = player.PlayerGui
local playerScripts = player.PlayerScripts

local ClientMod = require(playerScripts.ClientMod)

local Common = require(game.ReplicatedStorage.Common)
local len, wait, routine = Common.len, Common.wait, Common.routine

local BoostInfo = require(game.ReplicatedStorage.Data.BoostInfo)

local boostGUI = playerGui:WaitForChild("BoostGUI")
local boostFrame = boostGUI.BoostFrame

local BoostManager = {
	boostMods = {},
}

function BoostManager:init()
	self:addCons()
	self:toggle(true)
end

function BoostManager:addCons()
	boostFrame.Visible = true
	boostFrame.BackgroundTransparency = 1

	local boostList = boostFrame.ItemList
	boostList.Visible = true
	boostList.BackgroundTransparency = 1

	self.templateBoostItem = boostList.TemplateItem
	self.templateBoostItem.BackgroundTransparency = 1
	self.templateBoostItem.Visible = false
end

function BoostManager:toggle(newBool)
	if newBool == self.toggled then
		return
	end

	boostFrame.Visible = newBool
	self.toggled = newBool
end

function BoostManager:newBoostMod(boostData)
	local boostClass = boostData["boostClass"]

	local frame = self.templateBoostItem:Clone()
	frame.Visible = true
	frame.Parent = self.templateBoostItem.Parent

	local innerFrame = frame.InnerFrame
	innerFrame.BackgroundTransparency = 0

	local newBoostMod = {
		frame = frame,
		boostClass = boostClass,
	}
	for k, v in pairs(boostData) do
		newBoostMod[k] = v
	end

	local boostStats = BoostInfo:getMeta(boostClass)

	local aliasTitle = innerFrame.AliasTitle
	aliasTitle.Visible = false
	aliasTitle.Text = boostStats["alias"]

	innerFrame.MouseEnter:Connect(function()
		aliasTitle.Visible = true
	end)
	innerFrame.MouseLeave:Connect(function()
		aliasTitle.Visible = false
	end)

	self.boostMods[boostClass] = newBoostMod

	self:refreshBoostMod(newBoostMod)

	return newBoostMod
end

function BoostManager:removeBoostMod(boostClass)
	local boostMod = self.boostMods[boostClass]

	local frame = boostMod["frame"]
	if frame then
		frame:Destroy()
	end

	self.boostMods[boostClass] = nil
end

function BoostManager:tickSecond()
	self:tickBoostMods()
end

function BoostManager:tickBoostMods()
	for _, boostMod in pairs(self.boostMods) do
		boostMod["duration"] -= 1
		self:refreshBoostMod(boostMod)
	end
end

function BoostManager:refreshBoostMod(boostMod)
	local frame = boostMod["frame"]
	local duration = boostMod["duration"]

	local innerFrame = frame.InnerFrame
	innerFrame.TimerTitle.Text = Common.convertSecondsToReadableString(duration, true)
end

function BoostManager:updateBoostMods(data)
	-- clear all boostMods
	for boostClass, boostMod in pairs(self.boostMods) do
		self:removeBoostMod(boostClass)
	end

	for _, boostData in pairs(data["boostMods"]) do
		self:newBoostMod(boostData)
	end
end

function BoostManager:getMultipliers()
	local multipliers = {}
	for _, boostMod in pairs(self.boostMods) do
		local boostClass = boostMod["boostClass"]
		local boostStats = BoostInfo:getMeta(boostClass)
		local race = boostStats["race"]
		local multiplier = boostStats["multiplier"]

		if not multipliers[race] then
			multipliers[race] = 1
		end
		multipliers[race] = multipliers[race] + (multiplier - 1)
	end
	return multipliers
end

BoostManager:init()

return BoostManager
