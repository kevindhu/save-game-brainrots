local UserInputService = game:GetService("UserInputService")
local CurrentCamera = workspace.CurrentCamera

local DeviceManager = {}

function DeviceManager:init()
	-- print("GOT DEVICE: ", self:getDevice())
end

local GamepadStates = {
	Enum.UserInputType.Gamepad1,
	Enum.UserInputType.Gamepad2,
	Enum.UserInputType.Gamepad3,
	Enum.UserInputType.Gamepad4,
	Enum.UserInputType.Gamepad5,
	Enum.UserInputType.Gamepad6,
	Enum.UserInputType.Gamepad7,
	Enum.UserInputType.Gamepad8,
}

function DeviceManager:getDevice()
	local inputType = UserInputService:GetLastInputType()

	-- Check if it's a gamepad/console input
	if table.find(GamepadStates, inputType) then
		return "Console"
	-- Check if it's mobile (touch enabled or small screen or touch input)
	elseif
		CurrentCamera.ViewportSize.Y <= 600
		or UserInputService.TouchEnabled
		or inputType == Enum.UserInputType.Touch
	then
		return "Mobile"
	else
		return "PC"
	end
end

DeviceManager:init()

return DeviceManager
