local player = game.Players.LocalPlayer
local playerScripts = player.PlayerScripts
local playerGui = player.PlayerGui

local ClientMod = require(playerScripts.ClientMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local buttonGUI = playerGui:WaitForChild("ButtonGUI")

local leftFrame = buttonGUI.LeftFrame
local rightFrame = buttonGUI.RightFrame

local ButtonManager = {
	buttonMods = {},
	selectedButtons = {},
}

function ButtonManager:init()
	self:addCons()
end

function ButtonManager:addCons()
	local buttonList = {
		"Shop",
		"Index",
	}
	for _, buttonName in pairs(buttonList) do
		local button = leftFrame:FindFirstChild(buttonName)
		if not button then
			continue
		end
		self:addBasicButtonCons(button)
	end
end

function ButtonManager:addActivateCons(button, activateMethod)
	button.Active = true
	button.Activated:Connect(function()
		self:addButtonPressSound()
		activateMethod()
	end)
end

function ButtonManager:newButtonMod(button)
	local newButtonMod = {
		button = button,
		baseSize = button.Size,
	}
	self.buttonMods[button] = newButtonMod

	local innerIcon = button:FindFirstChild("Icon")
	if innerIcon then
		newButtonMod["baseIconSize"] = innerIcon.Size
	end

	return newButtonMod
end

function ButtonManager:addButtonPressSound()
	ClientMod.soundManager:addBasicSound("ButtonClick1") -- ButtonClick1
end

function ButtonManager:addBasicButtonCons(buttonFrame)
	buttonFrame.AutoButtonColor = false

	self:addButtonHoverCons({
		button = buttonFrame,
		easingStyle = "Quad",
		expandRatio = 1.05, -- 1.08
		noIconRotate = true,
		timer = 0.15, -- 0.15

		-- icon
		expandIcon = false,

		-- noDisableHover = true,
	})

	self:addButtonPressCons({
		button = buttonFrame,
		animatePress = true,
	})
end

function ButtonManager:addButtonHoverCons(data)
	local button = data["button"]
	local buttonMod = self.buttonMods[button]
	if not buttonMod then
		buttonMod = self:newButtonMod(button)
	end
	for k, v in pairs(data) do
		buttonMod[k] = v
	end

	button.InputBegan:connect(function(input)
		if not Common.listContains({ Enum.UserInputType.MouseMovement }, input.UserInputType) then
			return
		end
		self:enableHover(button)
	end)

	button.InputEnded:connect(function(input)
		if not Common.listContains({ Enum.UserInputType.MouseMovement }, input.UserInputType) then
			return
		end
		self:disableHover(button)
	end)
end

function ButtonManager:enableHover(button)
	local buttonMod = self.buttonMods[button]

	local timer = buttonMod["timer"] or 0.15
	buttonMod["hovered"] = true

	local baseSize = buttonMod["baseSize"]
	local expandRatio = buttonMod["expandRatio"] or 1.05
	local bigSize = UDim2.fromScale(baseSize.X.Scale * expandRatio, baseSize.Y.Scale * expandRatio)

	ClientMod.tweenManager:createTween({
		target = button,
		timer = timer,
		easingStyle = buttonMod["easingStyle"] or "Quad",
		easingDirection = "Out",
		goal = { Size = bigSize },
	})

	local innerIcon = button:FindFirstChild("Icon")
	if innerIcon then
		if not buttonMod["noIconRotate"] then
			local newAngle = 10
			ClientMod.tweenManager:createTween({
				target = innerIcon,
				timer = timer,
				easingStyle = "Quad",
				easingDirection = "Out",
				goal = { Rotation = newAngle },
			})
		end
		if buttonMod["expandIcon"] then
			local baseIconSize = buttonMod["baseIconSize"]
			local iconExpandRatio = buttonMod["iconExpandRatio"] or 1.15
			local bigIconSize =
				UDim2.fromScale(baseIconSize.X.Scale * iconExpandRatio, baseIconSize.Y.Scale * iconExpandRatio)
			ClientMod.tweenManager:createTween({
				target = innerIcon,
				timer = timer,
				easingStyle = buttonMod["easingStyle"] or "Quad",
				easingDirection = "Out",
				goal = { Size = bigIconSize },
			})
		end
	end
	-- self:addSound("HoverTick", 0.01, "HoverTick123") -- 0.03
end

function ButtonManager:disableHover(button)
	local buttonMod = self.buttonMods[button]

	buttonMod["hovered"] = false

	local baseSize = buttonMod["baseSize"]

	local timer = buttonMod["timer"] or 0.1
	timer = timer * 0.7
	ClientMod.tweenManager:createTween({
		target = button,
		timer = timer,
		easingStyle = buttonMod["easingStyle"] or "Quad",
		easingDirection = "Out",
		goal = { Size = baseSize },
	})

	local innerIcon = button:FindFirstChild("Icon")
	if innerIcon then
		if not buttonMod["noIconRotate"] then
			ClientMod.tweenManager:createTween({
				target = innerIcon,
				timer = timer,
				easingStyle = "Quad",
				easingDirection = "Out",
				goal = { Rotation = 0 },
			})
		end
		if buttonMod["expandIcon"] then
			ClientMod.tweenManager:createTween({
				target = innerIcon,
				timer = timer,
				easingStyle = buttonMod["easingStyle"] or "Quad",
				easingDirection = "Out",
				goal = { Size = buttonMod["baseIconSize"] },
			})
		end
	end
end

function ButtonManager:addButtonPressCons(data)
	local button = data["button"]
	local buttonMod = self.buttonMods[button]
	if not buttonMod then
		buttonMod = self:newButtonMod(button)
	end
	for k, v in pairs(data) do
		buttonMod[k] = v
	end

	button.MouseEnter:Connect(function()
		self:selectButton(button, true)
	end)
	button.MouseLeave:Connect(function()
		self:selectButton(button, false)
	end)

	button.InputBegan:connect(function(input)
		if not Common.listContains(Common.clickInputTypes, input.UserInputType) then
			return
		end

		if self.selectedButtons[button] then
			buttonMod["pressed"] = true
			self:togglePressButton(button, true)
		end
	end)
	button.InputEnded:connect(function(input)
		if not Common.listContains(Common.clickInputTypes, input.UserInputType) then
			return
		end
		buttonMod["pressed"] = false
		self:togglePressButton(button, false)
	end)
end

function ButtonManager:togglePressButton(button, isPressed)
	local buttonMod = self.buttonMods[button]

	local baseSize = buttonMod["baseSize"]
	local pressRatio = buttonMod["pressRatio"] or 0.9
	local pressSize = UDim2.fromScale(baseSize.X.Scale * pressRatio, baseSize.Y.Scale * pressRatio)

	local timer = 0.07
	local easingStyle = "Quad"
	local newSize
	if isPressed then
		newSize = pressSize
	else
		timer = 0.2
		easingStyle = "Back"
		newSize = baseSize

		if buttonMod["hovered"] then
			if not buttonMod["noDisableHover"] then
				self:disableHover(button)
				return
			else
				local expandRatio = buttonMod["expandRatio"] or 1.05
				newSize = UDim2.fromScale(baseSize.X.Scale * expandRatio, baseSize.Y.Scale * expandRatio)
			end
		end
	end

	ClientMod.tweenManager:createTween({
		target = button,
		timer = timer,
		easingStyle = easingStyle,
		easingDirection = "Out",
		goal = { Size = newSize },
	})
end

function ButtonManager:selectButton(button, bool)
	if bool then
		self.selectedButtons[button] = true
	else
		self.selectedButtons[button] = nil
	end
end

ButtonManager:init()

return ButtonManager
