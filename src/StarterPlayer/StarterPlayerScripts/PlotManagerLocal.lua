local UserInputService = game:GetService("UserInputService")

local player = game.Players.LocalPlayer
local playerScripts = player.PlayerScripts
local playerGui = player.PlayerGui

local ClientMod = require(playerScripts.ClientMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local buttonGUI = playerGui:WaitForChild("ButtonGUI")
local topFrame = buttonGUI.TopFrame

local plotGUI = playerGui:WaitForChild("PlotGUI")

local MapInfo = require(game.ReplicatedStorage.MapInfo)

local PlotManager = {
	plotSignMap = {},
}
PlotManager.__index = PlotManager

function PlotManager:init()
	self:addCons()

	routine(function()
		self:addAllPlotSmallSigns()
	end)
end

function PlotManager:addAllPlotSmallSigns()
	for i = 1, MapInfo.PLOT_COUNT do
		local plotName = "Plot" .. i

		local plotModel = game.Workspace:WaitForChild(plotName)
		local signModel = plotModel:WaitForChild("SmallSign")

		local newPlotSignMod = {
			plotName = plotName,
			userName = nil,
		}
		self.plotSignMap[plotName] = newPlotSignMod

		routine(function()
			local bb = signModel:WaitForChild("BBPart"):WaitForChild("BB")

			bb.Adornee = bb.Parent
			bb.Parent = playerGui

			local likeButton = bb.MainFrame.LikeButton
			ClientMod.buttonManager:addBasicButtonCons(likeButton)
			ClientMod.buttonManager:addActivateCons(likeButton, function()
				local userName = newPlotSignMod.userName
				if not userName then
					warn("COULD NOT ADD LIKE: NO USER NAME")
					return
				end

				ClientMod:FireServer("tryAddLike", {
					userName = userName,
				})
			end)

			newPlotSignMod["bb"] = bb
			self:refreshPlotSignMod(newPlotSignMod)
		end)
	end
end

function PlotManager:clearPlotSignMod(plotName)
	local plotSignMod = self.plotSignMap[plotName]
	if not plotSignMod then
		return
	end

	plotSignMod["userId"] = nil
	plotSignMod["userName"] = nil

	self:refreshPlotSignMod(plotSignMod)
end

function PlotManager:updateGlobalPlot(data)
	local plotName = data.plotName
	local userName = data.userName
	local userId = data.userId
	local hatchedCount = data.hatchedCount
	local likeUserList = data.likeUserList

	local plotSignMod = self.plotSignMap[plotName]

	plotSignMod.userName = userName
	plotSignMod.userId = userId
	plotSignMod.hatchedCount = hatchedCount
	plotSignMod.likeUserList = likeUserList

	self:refreshPlotSignMod(plotSignMod)
end

function PlotManager:refreshPlotSignMod(plotSignMod)
	local bb = plotSignMod["bb"]
	local userName = plotSignMod.userName
	local userId = plotSignMod.userId
	local hatchedCount = plotSignMod.hatchedCount
	local likeUserList = plotSignMod.likeUserList

	-- print("!! REFRESHING PLOT SIGN MOD: ", plotSignMod)

	-- no bb yet
	if not bb then
		return
	end

	-- no user yet
	if not userId then
		bb.MainFrame.Visible = false
		bb.UnclaimedFrame.Visible = true
		return
	end

	bb.MainFrame.Visible = true
	bb.UnclaimedFrame.Visible = false

	local mainFrame = bb.MainFrame

	mainFrame.AliasTitle.Text = userName
	routine(function()
		mainFrame.ProfileIcon.Image = Common.getProfileImageFromUserId(userId)
	end)

	mainFrame.HatchedTitle.Text = string.format("Hatched: %s times", Common.commas(hatchedCount))
	mainFrame.LikeButton.Title.Text = "x" .. Common.commas(len(likeUserList))
end

function PlotManager:addCons()
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end

		self.startTouchTime = os.clock()
		self.startTouchPosition = input.Position
	end)

	UserInputService.InputEnded:Connect(function(input, gameProcessed)
		if input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end

		if gameProcessed then
			return
		end

		if not self.startTouchTime then
			return
		end

		self.endTouchTime = os.clock()
		self.endTouchPosition = input.Position

		local distance = (self.startTouchPosition - self.endTouchPosition).Magnitude
		if distance > 10 then
			return
		end

		local timeDiff = self.endTouchTime - self.startTouchTime
		if timeDiff > 0.1 then
			return
		end

		self.mousePosition = self.endTouchPosition
	end)

	local myPlotButton = topFrame.MyPlot

	ClientMod.buttonManager:addBasicButtonCons(myPlotButton)
	ClientMod.buttonManager:addActivateCons(myPlotButton, function()
		self:tryTeleportTo("MyPlot")
	end)

	local eggsButton = topFrame.Eggs
	ClientMod.buttonManager:addBasicButtonCons(eggsButton)
	ClientMod.buttonManager:addActivateCons(eggsButton, function()
		self:tryTeleportTo("EggShop")
	end)
end

function PlotManager:tryTeleportTo(teleportClass)
	local user = ClientMod:getLocalUser()
	if teleportClass == "MyPlot" then
		local floorPart = self.floorPart
		local xOffset = -110 -- 10
		local spawnFrame = floorPart.CFrame * CFrame.new(xOffset, 10, 0) * CFrame.Angles(0, math.rad(-90), 0)

		user.rig:PivotTo(spawnFrame)
	elseif teleportClass == "EggShop" then
		user.rig:PivotTo(game.Workspace.EggShopModel.TeleportPart.CFrame * CFrame.new(0, 10, 0))
	end
end

function PlotManager:initPlot(data)
	local plotName = data.plotName
	self.plotName = plotName

	local model = game.Workspace:WaitForChild(plotName)
	self.model = model

	self.floorPart = model:WaitForChild("FloorPart")
	self.eggFloorPart = model:WaitForChild("EggFloorPart")

	local user = ClientMod:getLocalUser()
	user:addPullArrow()

	ClientMod.buyZoneManager:addBuyZoneArea(model)
end

function PlotManager:tick() end

PlotManager:init()

return PlotManager
