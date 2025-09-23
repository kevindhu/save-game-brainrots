local player = game.Players.LocalPlayer
local playerScripts = player.PlayerScripts
local playerGui = player.PlayerGui

local ClientMod = require(playerScripts.ClientMod)

local comebackGUI = playerGui:WaitForChild("ComebackGUI")
local claimFrame = comebackGUI.ClaimFrame

local EasyVisuals = require(game.ReplicatedStorage.EasyVisuals)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local ClaimOfflineManager = {
	itemMods = {},

	visualEffects = {},
}

function ClaimOfflineManager:init()
	self:addCons()

	self:toggle({
		newBool = false,
	})
end

function ClaimOfflineManager:addCons()
	local closeButton = claimFrame.CloseButton
	closeButton.Activated:Connect(function()
		ClientMod:FireServer("tryClaimOfflineCoins", {
			boost = false,
		})
	end)
	ClientMod.buttonManager:addBasicButtonCons(closeButton)

	local claimButton = claimFrame.ClaimButton
	ClientMod.buttonManager:addActivateCons(claimButton, function()
		ClientMod:FireServer("tryClaimOfflineCoins", {
			boost = false,
		})
	end)
	ClientMod.buttonManager:addBasicButtonCons(claimButton)

	local claimBoostButton = claimFrame.ClaimBoostButton
	ClientMod.buttonManager:addActivateCons(claimBoostButton, function()
		ClientMod:FireServer("tryClaimOfflineCoins", {
			boost = true,
		})
	end)
	ClientMod.buttonManager:addBasicButtonCons(claimBoostButton)
end

function ClaimOfflineManager:claimedOfflineCoins(data)
	-- for _, effect in ipairs(self.visualEffects) do
	-- 	effect:Destroy()
	-- end
	-- self.visualEffects = {}

	self:toggle({
		newBool = false,
	})
end

function ClaimOfflineManager:updateOfflineData(data)
	local totalOfflineCoins = data["totalOfflineCoins"]

	claimFrame.Earned.InnerFrame.AmountTitle.Text = "$" .. Common.abbreviateNumber(totalOfflineCoins, 1)

	claimFrame.Boost.InnerFrame.AmountTitle.Text = "$" .. Common.abbreviateNumber(totalOfflineCoins * 10, 1)

	self:toggle({
		newBool = true,
	})
end

function ClaimOfflineManager:toggle(data)
	local newBool = data["newBool"]

	if newBool == self.toggled then
		return
	end

	if newBool then
		ClientMod.uiManager:animateOpen(claimFrame)
		ClientMod.uiManager:toggleOffAllGUI()
	end

	ClientMod.uiManager:toggleHUD(not newBool)

	ClientMod.uiManager:interactMainFrame(claimFrame, data)

	self.toggled = newBool
end

ClaimOfflineManager:init()

return ClaimOfflineManager
