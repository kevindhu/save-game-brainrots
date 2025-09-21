local UserInputService = game:GetService("UserInputService")

local player = game.Players.LocalPlayer
local playerScripts = player.PlayerScripts
local playerGui = player.PlayerGui

local ClientMod = require(playerScripts.ClientMod)

local hatchGUI = playerGui:WaitForChild("HatchGUI")
local hatchFrame = hatchGUI.HatchFrame
local barFrame = hatchFrame.BarFrame

local PetInfo = require(game.ReplicatedStorage.PetInfo)
local RatingInfo = require(game.ReplicatedStorage.RatingInfo)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local HatchManager = {
	hatchCompleteExpiree = 0,
}
HatchManager.__index = HatchManager

function HatchManager:init()
	self:addCons()

	hatchFrame.Visible = false

	-- routine(function()
	-- 	wait(2)
	-- 	self:doHatch({
	-- 		petClass = "GlorboFruttoDrillo",
	-- 		mutationClass = "None",
	-- 	})
	-- end)
end

function HatchManager:addCons()
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end
		if Common.listContains(Common.clickInputTypes, input.UserInputType) then
			self:tryCompleteHatch()
		end
	end)
end

function HatchManager:toggleHatchFrame(newBool)
	hatchFrame.Visible = newBool

	self.toggled = newBool

	ClientMod.uiManager:toggleHUD(not newBool)
end

function HatchManager:doHatch(data)
	local pos = data["pos"]
	local petClass = data["petClass"]

	local userName = data["userName"]
	local waveName = data["waveName"]

	print("DO HATCH: ", userName)

	if userName == player.Name then
		ClientMod.saveManager:waveModSuccess(userName)
	end

	routine(function()
		wait(0.5)
		ClientMod.soundManager:newSoundMod({
			soundClass = "Pop1",
			volume = 0.2,
			pos = pos,
		})

		local petStats = PetInfo:getMeta(petClass)
		local ratingColor = RatingInfo["ratingColorMap"][petStats["rating"]]

		ClientMod.spellManager:addExplosion({
			spellClass = "WhiteExplosion",
			pos = pos + Vector3.new(0, 3, 0),
			baseColor = ratingColor,
			scale = 0.5, -- 1.5
		})

		ClientMod.saveManager:animateHatch(userName, waveName)
	end)
end

function HatchManager:tryCompleteHatch()
	if ClientMod.step < self.hatchCompleteExpiree then
		return
	end

	self:toggleHatchFrame(false)
end

HatchManager:init()

return HatchManager
