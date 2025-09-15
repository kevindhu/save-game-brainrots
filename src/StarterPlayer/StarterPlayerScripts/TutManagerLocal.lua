local player = game.Players.LocalPlayer
local playerGui = player.PlayerGui
local playerScripts = player.PlayerScripts

local ClientMod = require(playerScripts.ClientMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local TutInfo = require(game.ReplicatedStorage.TutInfo)
local PetInfo = require(game.ReplicatedStorage.PetInfo)

local tutGUI = playerGui:WaitForChild("TutGUI")
local messageFrame = tutGUI.MessageFrame

local buttonGUI = playerGui:WaitForChild("ButtonGUI")
local topFrame = buttonGUI.TopFrame

local TutManager = {
	tutMods = {},
	completedTutMods = {},
}

function TutManager:init()
	self:addCons()

	self:initButtonHintIcons()

	routine(function()
		self:addLocationBeamModel()

		self:toggle({
			newBool = true,
		})

		self.initialized = true
	end)
end

function TutManager:addLocationBeamModel()
	local locationBeamModel = game.ReplicatedStorage.Assets:WaitForChild("LocationArrowModel"):Clone()
	locationBeamModel.Name = "LocationBeamModel"
	locationBeamModel.Parent = game.Workspace.HitBoxes

	local startPart = locationBeamModel:FindFirstChild("Start")
	local endPart = locationBeamModel:FindFirstChild("End")

	startPart.Transparency = 1
	endPart.Transparency = 1

	self.locationBeamModel = locationBeamModel
	self:toggleLocationBeam(false)
end

function TutManager:toggleLocationBeam(newBool)
	self.locationBeamModel.Beam.Enabled = newBool
end

function TutManager:initButtonHintIcons()
	local eggHintIcon = topFrame.Eggs.HintIcon
	self.eggHintIcon = eggHintIcon
	self:toggleHintIcon(eggHintIcon, false)
	self:doFullHintIconAnimation(eggHintIcon)

	local myPlotHintIcon = topFrame.MyPlot.HintIcon
	self.myPlotHintIcon = myPlotHintIcon
	self:toggleHintIcon(myPlotHintIcon, false)
	self:doFullHintIconAnimation(myPlotHintIcon)
end

local WAVE_ANIMATION_ID = 108989129166651

function TutManager:addCons()
	local title = messageFrame.Title

	local viewportSize = workspace.CurrentCamera.ViewportSize
	local ratio = viewportSize.X / 1920
	title.TextSize = title.TextSize * ratio

	local rig = messageFrame.VPFrame.WorldModel.TungTungSahur

	routine(function()
		messageFrame.VPFrame.BackgroundTransparency = 1

		local animationId = PetInfo.idleAnimationMap["TungTungSahur"]

		local rigEntity = {
			rig = rig,
		}
		ClientMod.animUtils:animate(rigEntity, {
			race = "Movement",
			animationId = animationId,
		})
	end)

	routine(function()
		while true do
			local rigEntity = {
				rig = rig,
			}
			ClientMod.animUtils:animate(rigEntity, {
				race = "Act",
				animationId = WAVE_ANIMATION_ID,
			})
			wait(7)
		end
	end)
end

function TutManager:doFullHintIconAnimation(hintIcon)
	routine(function()
		local moveTimer = 0.5
		while true do
			ClientMod.tweenManager:createTween({
				target = hintIcon,
				timer = moveTimer,
				easingStyle = "Quad",
				easingDirection = "Out",
				goal = {
					Position = UDim2.fromScale(0.5, 2.5),
				},
			})

			wait(moveTimer)

			ClientMod.tweenManager:createTween({
				target = hintIcon,
				timer = moveTimer,
				easingStyle = "Quad",
				easingDirection = "In",
				goal = {
					Position = UDim2.fromScale(0.5, 1.9),
				},
			})
			wait(moveTimer)
		end
	end)
end

function TutManager:toggleHintIcon(hintIcon, newBool)
	if not hintIcon then
		return
	end
	hintIcon.Visible = newBool
end

function TutManager:toggle(data)
	local newBool = data["newBool"]

	self.toggled = newBool
	self:toggleText(self.textToggled)
end

function TutManager:updateCompletedTutMods(completedData)
	self.completedTutMods = Common.deepCopy(completedData)
end

function TutManager:toggleText(newBool)
	self.textToggled = newBool

	messageFrame.Visible = newBool
end

function TutManager:updateTutMods(fullTutData)
	self.tutMods = Common.deepCopy(fullTutData)
end

local function removeTags(str)
	-- replace line break tags (otherwise grapheme loop will miss those linebreak characters)
	str = str:gsub("<br%s*/>", "\n")
	return (str:gsub("<[^<>]->", ""))
end

function TutManager:chooseTutMod(data)
	local tutName = data["tutName"]

	-- clear all existing animations
	self:toggleHintIcon(self.eggHintIcon, false)
	self:toggleHintIcon(self.myPlotHintIcon, false)
	self:toggleHintIcon(self.closeEggShopHintIcon, false)
	self:toggleHintIcon(self.buyEggHintIcon, false)

	self:toggleLocationBeam(false)

	if not tutName then
		self.chosenTutMod = nil
		self:toggleText(false)
		return
	end

	local tutMod = self.tutMods[tutName]
	self.chosenTutMod = tutMod

	local targetClass = tutMod["targetClass"]
	if targetClass == "TeleportToEggShop" then
		self:toggleHintIcon(self.eggHintIcon, true)
	elseif targetClass == "BuyEgg1" then
		self:toggleHintIcon(self.buyEggHintIcon, true)
	elseif targetClass == "PlaceFirstEgg" then
		self:toggleHintIcon(self.myPlotHintIcon, true)
	elseif targetClass == "CloseEggShop" then
		self:toggleHintIcon(self.closeEggShopHintIcon, true)
	end

	self:updateLocationBeam(targetClass)

	self:startTextAnimation()
end

function TutManager:updateLocationBeam(targetClass)
	local endPart = self.locationBeamModel.End

	local eggShopTargetPos =
		game.Workspace:WaitForChild("EggShopModel"):WaitForChild("Rig"):WaitForChild("HumanoidRootPart").Position

	if targetClass == "TeleportToEggShop" then
		self:toggleLocationBeam(true)
		endPart.Position = eggShopTargetPos
	elseif targetClass == "BuyEgg1" then
		self:toggleLocationBeam(true)
		endPart.Position = eggShopTargetPos
	elseif targetClass == "PlaceFirstEgg" then
		self:toggleLocationBeam(true)
		local floorPart = ClientMod.plotManager.floorPart
		if not floorPart then
			warn("!!! COULD NOT FIND FLOOR PART FOR LOCATION BEAM")
			return
		end
		endPart.Position = floorPart.Position
	elseif targetClass == "HatchFirstEgg" then
		self:toggleLocationBeam(true)
		local chosenEgg = nil
		for _, egg in pairs(ClientMod.eggs) do
			if egg.userName == player.Name then
				chosenEgg = egg
				break
			end
		end
		if not chosenEgg then
			warn("!!! COULD NOT FIND CHOSEN EGG FOR LOCATION BEAM")
			return
		end
		endPart.Position = chosenEgg.model.PrimaryPart.Position
	end
end

function TutManager:startTextAnimation()
	-- print("START TEXT ANIMATION: ", self.chosenTutMod)

	local tutMod = self.chosenTutMod
	local tutName = tutMod["tutName"]

	local tutStats = TutInfo:getMeta(tutName)

	local finalText = tutStats["text"]

	local dialogueStep = ClientMod.step
	self.dialogueStep = dialogueStep

	local displayText = removeTags(finalText)

	local waitDuration = 0.03

	routine(function()
		local title = messageFrame.Title
		title.Text = finalText
		title.MaxVisibleGraphemes = 0

		local index = 0
		for first, last in utf8.graphemes(displayText) do
			if self.dialogueStep ~= dialogueStep then
				break
			end

			index += 1

			-- add voice beep
			self:tryAddVoiceBeep()

			title.MaxVisibleGraphemes = index
			wait(waitDuration)
		end
	end)

	self:toggleText(true)
end

function TutManager:tryAddVoiceBeep()
	if self.voiceExpiree and self.voiceExpiree > ClientMod.step then
		return
	end
	self.voiceExpiree = ClientMod.step + 5

	if Common.isStudio then
		return
	end

	ClientMod.soundManager:newSoundMod({
		soundClass = "VoiceBeep",
		volume = 0.5,
	})
end

function TutManager:tick()
	if not self.initialized then
		return
	end

	local user = ClientMod:getLocalUser()
	if not user then
		return
	end

	self:tickLocationBeamModel()
	self:tickHintIconsVisible()
end

function TutManager:tickHintIconsVisible()
	local chosenTutMod = self.chosenTutMod
	if not chosenTutMod then
		return
	end

	local user = ClientMod:getLocalUser()
	if not user then
		return
	end
	local userFrame = user.currFrame
	if not userFrame then
		return
	end
	local userPos = userFrame.Position

	local targetClass = chosenTutMod["targetClass"]
	if targetClass == "PlaceFirstEgg" then
		-- see how far you are from the floor part
		local floorPart = ClientMod.plotManager.floorPart
		if not floorPart then
			warn("!!! COULD NOT FIND FLOOR PART FOR HINT ICON")
			return
		end
		local distance = Common.getHorizontalDist(userPos, floorPart.Position)
		if distance < 115 then
			self:toggleHintIcon(self.myPlotHintIcon, false)
		else
			self:toggleHintIcon(self.myPlotHintIcon, true)
		end
	elseif targetClass == "TeleportToEggShop" then
		local eggShopTargetPos =
			game.Workspace:WaitForChild("EggShopModel"):WaitForChild("Rig"):WaitForChild("HumanoidRootPart").Position

		local distance = (userPos - eggShopTargetPos).Magnitude

		-- print("DISTANCE: ", distance)

		if distance < 30 then
			self:toggleHintIcon(self.eggHintIcon, false)
		else
			self:toggleHintIcon(self.eggHintIcon, true)
		end
	end
end

function TutManager:tickLocationBeamModel()
	local locationBeamModel = self.locationBeamModel
	if not locationBeamModel then
		return
	end

	local user = ClientMod:getLocalUser()
	local userRig = user.rig
	if not userRig then
		return
	end
	local torso = userRig:FindFirstChild("Torso")
	if not torso then
		return
	end

	self.locationBeamModel.Start.Position = torso.Position
end

TutManager:init()

return TutManager
