local GuiService = game:GetService("GuiService")

local player = game.Players.LocalPlayer
local playerScripts = player.PlayerScripts
local playerGui = player.PlayerGui

local ClientMod = require(playerScripts.ClientMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local leaveGUI = playerGui:WaitForChild("LeaveGUI")
local leaveFrame = leaveGUI.LeaveFrame

local LeaveManager = {}

function LeaveManager:init()
	self:addCons()
end

function LeaveManager:addCons()
	leaveFrame.ImageTransparency = 1

	leaveGUI.Enabled = true
	leaveFrame.Visible = true

	if Common.isStudio then
		return
	end

	GuiService.MenuOpened:Connect(function()
		leaveFrame.ImageTransparency = 0
		leaveFrame.Game:Play()
	end)

	GuiService.MenuClosed:Connect(function()
		leaveFrame.ImageTransparency = 1
		leaveFrame.Game:Stop()
	end)
end

LeaveManager:init()

return LeaveManager
