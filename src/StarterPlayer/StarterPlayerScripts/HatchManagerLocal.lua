local UserInputService = game:GetService("UserInputService")

local player = game.Players.LocalPlayer
local playerScripts = player.PlayerScripts
local playerGui = player.PlayerGui

local ClientMod = require(playerScripts.ClientMod)

local hatchGUI = playerGui:WaitForChild("HatchGUI")
local hatchFrame = hatchGUI.HatchFrame
local barFrame = hatchFrame.BarFrame

local PetInfo = require(game.ReplicatedStorage.PetInfo)

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
	local hatchStep = ClientMod.step
	self.hatchStep = hatchStep

	local petClass = data.petClass
	local mutationClass = data.mutationClass

	self:toggleHatchFrame(true)

	ClientMod.soundManager:newSoundMod({
		soundClass = "EggFinish1",
		-- pos = barFrame.Position,
		-- volume = 0.5,
	})

	self.hatchCompleteExpiree = ClientMod.step + 60 * 1.5

	local imageId = PetInfo:getPetImage(petClass, mutationClass)

	local petStats = PetInfo:getMeta(petClass)

	barFrame.Position = UDim2.fromScale(0, 0.5)
	barFrame.NameTitle.Text = petStats["alias"]

	local rating = petStats["rating"]
	if not rating then
		rating = "Common"
	end
	ClientMod.ratingManager:applyRatingColor(barFrame.NameTitle, rating)

	local continueTitle = hatchFrame.ContinueTitle
	continueTitle.TextTransparency = 1
	continueTitle.UIStroke.Transparency = 1

	local icon = barFrame.Icon
	icon.Image = imageId

	local moveTime = 0.5
	ClientMod.tweenManager:createTween({
		target = barFrame,
		timer = moveTime,
		easingStyle = "Quad",
		easingDirection = "Out",
		goal = {
			Position = UDim2.fromScale(0.5, 0.5),
		},
	})

	hatchFrame.BackgroundTransparency = 1
	ClientMod.tweenManager:createTween({
		target = hatchFrame,
		timer = 0.3,
		easingStyle = "Quad",
		easingDirection = "Out",
		goal = {
			BackgroundTransparency = 0.8,
		},
	})

	routine(function()
		if self.iconExpandTween then
			self.iconExpandTween:Cancel()
			self.iconExpandTween = nil
		end
		icon.UIScale.Scale = 0

		wait(moveTime)

		icon.UIScale.Scale = 0

		if self.hatchStep ~= hatchStep then
			warn("HATCH STEP DIFFERENT, NOT DOING ICON EXPAND")
			return
		end

		local iconExpandTime = 0.5 -- 0.4

		self.iconExpandTween = ClientMod.tweenManager:createTween({
			target = icon.UIScale,
			timer = iconExpandTime,
			easingStyle = "Back",
			easingDirection = "Out",
			goal = {
				Scale = 1.1, -- 1
			},
		})

		ClientMod.tweenManager:createTween({
			target = continueTitle,
			timer = 0.3,
			easingStyle = "Quad",
			easingDirection = "Out",
			goal = {
				TextTransparency = 0,
			},
		})

		ClientMod.tweenManager:createTween({
			target = continueTitle.UIStroke,
			timer = 0.3,
			easingStyle = "Quad",
			easingDirection = "Out",
			goal = {
				Transparency = 0,
			},
		})
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
