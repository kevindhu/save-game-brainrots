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

local saveGUI = playerGui:WaitForChild("SaveGUI")

local blackGUI = playerGui:WaitForChild("BlackGUI")

local TutManager = {
	tutMods = {},
	completedTutMods = {},

	chosenAbsoluteSize = Vector2.new(0, 0),
	chosenAbsolutePos = Vector2.new(0, 0),
}

function TutManager:init()
	self:addCons()

	self:initAllBlackFrames()

	self:initMainHintIcon()

	-- self.chosenFrame = playerGui:WaitForChild("ButtonGUI").TopFrame.MyPlotCover

	routine(function()
		self:addLocationBeamModel()

		self:toggle({
			newBool = true,
		})

		self.initialized = true
	end)
end

function TutManager:initMainHintIcon()
	self.hintIcon = blackGUI.HintIcon

	local frame = Instance.new("Frame")
	frame.Visible = false
	frame.Parent = playerGui
	self.hintAnimationFrame = frame

	routine(function()
		local moveTimer = 0.5
		while true do
			ClientMod.tweenManager:createTween({
				target = self.hintAnimationFrame,
				timer = moveTimer,
				easingStyle = "Quad",
				easingDirection = "Out",
				goal = {
					Position = UDim2.fromScale(0, 1),
				},
			})

			wait(moveTimer)

			ClientMod.tweenManager:createTween({
				target = self.hintAnimationFrame,
				timer = moveTimer,
				easingStyle = "Quad",
				easingDirection = "In",
				goal = {
					Position = UDim2.fromScale(0, 0),
				},
			})
			wait(moveTimer)
		end
	end)
end

function TutManager:toggleBlackFrames(newBool)
	self.blackLeftFrame.Visible = newBool
	self.blackRightFrame.Visible = newBool
	self.blackTopFrame.Visible = newBool
	self.blackBottomFrame.Visible = newBool
end

function TutManager:initAllBlackFrames()
	self.blackLeftFrame = self:initBlackFrame("Left")
	self.blackRightFrame = self:initBlackFrame("Right")
	self.blackTopFrame = self:initBlackFrame("Top")
	self.blackBottomFrame = self:initBlackFrame("Bottom")

	self:toggleBlackFrames(false)
end

function TutManager:initBlackFrame(name)
	local frame = Instance.new("Frame")
	frame.BackgroundTransparency = 0.3 -- 0.5
	frame.Size = UDim2.fromScale(5, 2)
	frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	frame.Parent = blackGUI
	frame.BorderSizePixel = 0

	frame.Name = name .. "BlackFrame"

	return frame
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

function TutManager:initBatHintIcon(batItemFrame)
	local batHintIcon = batItemFrame.HintIcon
	self.batHintIcon = batHintIcon
	self:toggleHintIcon(batHintIcon, false)

	self.batHintItemFrame = batItemFrame.Cover

	self:refreshHintIcons()
end

function TutManager:initPetHintIcon(petItemFrame)
	if self.petHintIcon then
		return
	end

	self.petHintItemFrame = petItemFrame.Cover

	local petHintIcon = petItemFrame.HintIcon
	self.petHintIcon = petHintIcon
	self:toggleHintIcon(petHintIcon, false)

	print("INIT PET HINT ICON: ", petHintIcon)

	self:refreshHintIcons()
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

function TutManager:toggleHintIcon(hintIcon, newBool)
	if not hintIcon then
		return
	end
	hintIcon.Visible = false -- newBool
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

	self:toggleLocationBeam(false)
	self.chosenFrame = nil

	if not tutName then
		self.chosenTutMod = nil
		self:toggleText(false)
		return
	end

	local tutMod = self.tutMods[tutName]
	self.chosenTutMod = tutMod

	self:refreshHintIcons()
	self:updateLocationBeam(tutMod["targetClass"])

	self:startTextAnimation()
end

function TutManager:refreshHintIcons()
	local tutMod = self.chosenTutMod
	if not tutMod then
		return
	end

	local targetClass = tutMod["targetClass"]

	-- clear all existing animations
	self:toggleHintIcon(self.myPlotHintIcon, false)
	self:toggleHintIcon(self.batHintIcon, false)
	self:toggleHintIcon(self.petHintIcon, false)
	self:toggleHintIcon(self.playButtonHintIcon, false)

	self.flippedHintIcon = false

	if targetClass == "TeleportToEggShop" then
		self:toggleHintIcon(self.eggHintIcon, true)
	elseif targetClass == "EquipBat1" then
		self:toggleHintIcon(self.batHintIcon, true)
		self.chosenFrame = self.batHintItemFrame
	elseif targetClass == "EquipBat2" then
		self:toggleHintIcon(self.batHintIcon, true)
		self.chosenFrame = self.batHintItemFrame
	elseif targetClass == "PressPlay" then
		self:toggleHintIcon(self.playButtonHintIcon, true)
		self.flippedHintIcon = true
		self.chosenFrame = playerGui:WaitForChild("SaveGUI").PlayFrame.PlayButton.Cover
	elseif targetClass == "EquipFirstPet" then
		self:toggleHintIcon(self.petHintIcon, true)
		self.chosenFrame = self.petHintItemFrame
	elseif targetClass == "Buy2xSpeedCommon" then
		self.chosenFrame = self.speedHintItemFrame
	elseif targetClass == "CloseTimeWizard" then
		local speedGUI = playerGui:WaitForChild("SpeedGUI")
		local speedFrame = speedGUI.SpeedFrame
		self.chosenFrame = speedFrame.CloseButton.Cover
	elseif targetClass == "Choose2xSpeedCommon" then
		self.chosenFrame = playerGui:WaitForChild("SaveGUI").PlayFrame.SpeedButton.Cover
	end
end

function TutManager:updateLocationBeam(targetClass)
	local endPart = self.locationBeamModel.End

	if targetClass == "PlaceFirstPet" then
		self:toggleLocationBeam(true)
		local model = ClientMod.plotManager.model
		if not model then
			warn("!!! COULD NOT FIND FLOOR PART FOR LOCATION BEAM")
			return
		end
		endPart.Position = model.PetSpot1.BasePart.Position
	elseif targetClass == "GoToTimeWizard" then
		self:toggleLocationBeam(true)
		endPart.Position = ClientMod.vendorManager.vendorMods["TimeWizardVendor"].rig.HumanoidRootPart.Position
	end
end

function TutManager:startTextAnimation()
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

function TutManager:tick(timeRatio)
	if not self.initialized then
		return
	end

	local user = ClientMod:getLocalUser()
	if not user then
		return
	end

	self:tickLocationBeamModel()
	self:tickHintIconsVisible()

	self:tickBlackFrames()

	self:tickChosenAbsoluteSize(timeRatio)
end

function TutManager:tickChosenAbsoluteSize(timeRatio)
	local chosenFrame = self.chosenFrame
	if not chosenFrame then
		self:toggleBlackFrames(false)
		self.hintIcon.Visible = false
		return
	end

	local lerpRatio = 0.15 -- 0.1
	self.chosenAbsoluteSize = self.chosenAbsoluteSize:Lerp(chosenFrame.AbsoluteSize, lerpRatio * timeRatio)

	self.chosenAbsolutePos = self.chosenAbsolutePos:Lerp(chosenFrame.AbsolutePosition, lerpRatio * timeRatio)

	self.hintIcon.Visible = true

	local animationOffset = -self.hintAnimationFrame.Position.Y.Scale * self.chosenAbsoluteSize.Y * 0.25

	local yOffset = 0
	if self.flippedHintIcon then
		yOffset = self.hintIcon.AbsoluteSize.Y * 0.5 + self.chosenAbsoluteSize.Y
		yOffset -= animationOffset
		self.hintIcon.Rotation = 360
	else
		yOffset = -self.hintIcon.AbsoluteSize.Y * 0.5
		yOffset += animationOffset
		self.hintIcon.Rotation = 180
	end

	local guiInset = game:GetService("GuiService"):GetGuiInset()
	local newPos = self.chosenAbsolutePos
		+ Vector2.new(self.chosenAbsoluteSize.X * 0.5, yOffset)
		+ Vector2.new(0, guiInset.Y)

	local vpX = workspace.CurrentCamera.ViewportSize.X
	local vpY = workspace.CurrentCamera.ViewportSize.Y

	self.hintIcon.Position = UDim2.fromScale(newPos.X / vpX, newPos.Y / vpY)

	self:toggleBlackFrames(true)
end

function TutManager:tickBlackFrames()
	local guiInset = game:GetService("GuiService"):GetGuiInset()

	local frameX = self.chosenAbsoluteSize.X
	local frameY = self.chosenAbsoluteSize.Y

	-- print(frameX, frameY)

	local posX = self.chosenAbsolutePos.X
	local posY = self.chosenAbsolutePos.Y

	local vpX = workspace.CurrentCamera.ViewportSize.X
	local vpY = workspace.CurrentCamera.ViewportSize.Y

	self.blackLeftFrame.Position = UDim2.fromScale((posX - self.blackLeftFrame.AbsoluteSize.X) / vpX, 0)

	self.blackRightFrame.Position = UDim2.fromScale((posX + frameX) / vpX, 0)

	self.blackTopFrame.Position =
		UDim2.fromScale(posX / vpX, (posY - self.blackTopFrame.AbsoluteSize.Y + guiInset.Y) / vpY)
	self.blackTopFrame.Size = UDim2.fromScale(frameX / vpX, 2)

	self.blackBottomFrame.Position = UDim2.fromScale(posX / vpX, (posY + frameY + guiInset.Y) / vpY)
	self.blackBottomFrame.Size = UDim2.fromScale(frameX / vpX, 2)
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
