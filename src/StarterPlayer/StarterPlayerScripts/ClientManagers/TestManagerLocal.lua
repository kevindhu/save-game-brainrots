local player = game.Players.LocalPlayer
local playerScripts = player.PlayerScripts
local playerGui = player.PlayerGui

local ClientMod = require(playerScripts.ClientMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local fakeRobuxGUI = playerGui:WaitForChild("FakeRobuxGUI")
local fakeRobuxFrame = fakeRobuxGUI.RobuxFrame

local TestManager = {}
TestManager.__index = TestManager

function TestManager:init()
	fakeRobuxFrame.BackgroundTransparency = 1
	fakeRobuxFrame.Visible = self:checkToggled()
end

function TestManager:checkToggled()
	return game.PlaceId == Common.testPlaceId
end

function TestManager:updateRobuxCount(data)
	local robuxCount = data["robuxCount"]
	fakeRobuxFrame.RobuxTitle.Text = "TEST ROBUX: " .. Common.robuxSymbol .. robuxCount
end

TestManager:init()

return TestManager
