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
	plotMods = {},
}
PlotManager.__index = PlotManager

function PlotManager:init()
	self:addCons()

	self:initAllPlotMods()
end

function PlotManager:initAllPlotMods()
	for i = 1, MapInfo.PLOT_COUNT do
		local plotName = "Plot" .. i

		local plotModel = game.Workspace:WaitForChild(plotName)

		local floorPart = plotModel:WaitForChild("FloorPart")
		local savePart = plotModel:WaitForChild("SavePart")
		local unitStartPart = plotModel:WaitForChild("UnitStartPart")

		local newPlotMod = {
			plotName = plotName,
			userName = nil,

			floorPart = floorPart,
			savePart = savePart,
			unitStartPart = unitStartPart,

			model = plotModel,
		}
		self.plotMods[plotName] = newPlotMod

		-- init the sign bb
		local signModel = plotModel:WaitForChild("SmallSign")
		routine(function()
			local bb = signModel:WaitForChild("BBPart"):WaitForChild("BB")

			bb.Adornee = bb.Parent
			bb.Parent = playerGui

			local likeButton = bb.MainFrame.LikeButton
			ClientMod.buttonManager:addBasicButtonCons(likeButton)
			ClientMod.buttonManager:addActivateCons(likeButton, function()
				local userName = newPlotMod.userName
				if not userName then
					warn("COULD NOT ADD LIKE: NO USER NAME")
					return
				end

				ClientMod:FireServer("tryAddLike", {
					userName = userName,
				})
			end)

			newPlotMod["bb"] = bb
			self:refreshPlotMod(newPlotMod)
		end)
	end
end

function PlotManager:clearPlotMod(plotName)
	local plotMod = self.plotMods[plotName]
	if not plotMod then
		return
	end

	plotMod["userId"] = nil
	plotMod["userName"] = nil

	self:refreshPlotMod(plotMod)
end

function PlotManager:updateGlobalPlot(data)
	local plotName = data.plotName
	local userName = data.userName
	local userId = data.userId
	local hatchedCount = data.hatchedCount
	local likeUserList = data.likeUserList

	local plotMod = self.plotMods[plotName]

	plotMod.userName = userName
	plotMod.userId = userId
	plotMod.hatchedCount = hatchedCount
	plotMod.likeUserList = likeUserList

	if plotMod.userName == player.Name then
		self.model = plotMod.model
		self.floorPart = plotMod.floorPart
		self.savePart = plotMod.savePart
		self.unitStartPart = plotMod.unitStartPart
	end

	self:refreshPlotMod(plotMod)
end

function PlotManager:refreshPlotMod(plotMod)
	local bb = plotMod["bb"]
	local userName = plotMod.userName
	local userId = plotMod.userId
	local hatchedCount = plotMod.hatchedCount
	local likeUserList = plotMod.likeUserList

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
end

function PlotManager:tryTeleportTo(teleportClass)
	local user = ClientMod:getLocalUser()
	if teleportClass == "MyPlot" then
		local floorPart = self.floorPart
		local xOffset = -110 -- 10
		local spawnFrame = floorPart.CFrame * CFrame.new(xOffset, 10, 0) * CFrame.Angles(0, math.rad(-90), 0)

		user.rig:PivotTo(spawnFrame)
	end
end

function PlotManager:tick() end

PlotManager:init()

return PlotManager
