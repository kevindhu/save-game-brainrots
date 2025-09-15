-- local ts = game:GetService("TweenService")

local ClientMod = require(script.Parent:WaitForChild("ClientMod"))

local EasyVisuals = require(game.ReplicatedStorage.EasyVisuals)

local player = game.Players.LocalPlayer
local playerScripts = player:WaitForChild("PlayerScripts")
local playerGui = player:WaitForChild("PlayerGui")

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local Map = {}

function Map:init()
	self:initGroupChest()
end

function Map:initGroupChest()
	local groupChest = game.Workspace:WaitForChild("GroupChest")
	local promptPart = groupChest.PromptPart

	local prompt = ClientMod.uiManager:createPrompt({
		actionText = "Open Gift",
		name = "RewardGroupChest",
		holdDuration = 0.3,
		enabled = true,
		maxActivationDistance = 22,
		parent = promptPart,
	})

	prompt.Triggered:Connect(function()
		ClientMod:FireServer("tryClaimGroupReward")
	end)

	prompt.Parent = promptPart

	local bb = groupChest:WaitForChild("BB")
	bb.MaxDistance = 200
	ClientMod.uiScaleManager:addDistStrokeModsFromBB({
		bb = bb,
		adornee = bb.Adornee,
		baseDistance = 50,
	})

	EasyVisuals.new(bb.MainFrame.Title, "Silver", 0.5)
end

Map:init()

return Map
