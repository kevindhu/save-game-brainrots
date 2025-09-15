local player = game.Players.LocalPlayer
local playerGui = player.PlayerGui
local playerScripts = player.PlayerScripts

local ClientMod = require(playerScripts.ClientMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local hintGUI = playerGui:WaitForChild("HintGUI")
local hintFrame = hintGUI.HintFrame

local HintManager = {}
HintManager.__index = HintManager

function HintManager:init()
	self:addCons()
end

function HintManager:addCons()
	print("ADDING CONS")
	hintFrame.Visible = true
end

function HintManager:tick()
	if not self.chosenHintMod then
		hintFrame.Visible = false
		return
	end

	hintFrame.Visible = true

	local mouse = player:GetMouse()
	local mouseX = mouse.X
	local mouseY = mouse.Y

	local absoluteSize = hintFrame.AbsoluteSize

	local finalX = mouseX
	local finalY = mouseY - absoluteSize.Y / 2

	hintFrame.Position = UDim2.new(0, finalX, -0.01, finalY)
end

function HintManager:addHintFrameCons(data)
	local frame = data["frame"]
	local alias = data["alias"]

	local newHintMod = {
		frame = frame,
	}

	frame.MouseEnter:Connect(function()
		self.chosenHintMod = newHintMod
		hintFrame.Title.Text = alias
	end)

	frame.MouseLeave:Connect(function()
		if self.chosenHintMod == newHintMod then
			self.chosenHintMod = nil
		end
	end)
end

HintManager:init()

return HintManager
