local ts = game:GetService("TweenService")

local player = game.Players.LocalPlayer
local playerScripts = player.PlayerScripts
local playerGui = player.PlayerGui

local ClientMod = require(playerScripts.ClientMod)
local notifyGUI = playerGui:WaitForChild("NotifyGUI")
local notifyFrame = notifyGUI.NotifyFrame

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local NotifyManager = {
	notifyMods = {},
	layoutOrder = 0,
}

function NotifyManager:init()
	self:addCons()
end

function NotifyManager:addCons()
	notifyFrame.Visible = true
	notifyFrame.BackgroundTransparency = 1

	local templateItemFrame = notifyFrame.TemplateItem
	templateItemFrame.BackgroundTransparency = 1
	templateItemFrame.Visible = false
	self.templateItemFrame = templateItemFrame
end

function NotifyManager:removeNotifyMod(notifyMod)
	if notifyMod["destroyed"] then
		return
	end

	notifyMod["destroyed"] = true
	local frame = notifyMod["frame"]
	if frame then
		frame:Destroy()
	end

	local notifyName = notifyMod["notifyName"]
	self.notifyMods[notifyName] = nil
end

local iconMap = {
	check = "✅",
	error = "❌",
}

function NotifyManager:notifySuccess(txt)
	local data = {
		txt = txt,
		notifyClass = "Success",
	}
	self:newNotifyMod(data)
end

function NotifyManager:notifyError(txt)
	local data = {
		txt = txt,
		notifyClass = "Error",
	}
	self:newNotifyMod(data)
end

function NotifyManager:newNotifyMod(data)
	if data["notifyClass"] == "Error" then
		data["icon"] = "error"
		data["soundClass"] = "SoftError5" -- SoftError3
		data["soundVolume"] = 0.5
		data["color"] = Color3.fromRGB(255, 19, 23)
	elseif data["notifyClass"] == "Success" then
		data["color"] = Color3.fromRGB(7, 255, 86)
		data["icon"] = "check"
		data["soundClass"] = nil
		data["soundVolume"] = 0.5
	end

	local txt = data["txt"]
	local soundClass = data["soundClass"]
	local color = data["color"]
	local duration = data["duration"]

	if soundClass then
		local soundVolume = data["soundVolume"]
		ClientMod.soundManager:addBasicSound(soundClass, soundVolume)
	end

	local notifyName = data["notifyName"]
	if not notifyName then
		notifyName = "NOTIFY_" .. Common.getGUID()
	end

	-- remove all the notifyMods with same notifyName
	for _, notifyMod in pairs(self.notifyMods) do
		if notifyMod["notifyName"] == notifyName then
			self:removeNotifyMod(notifyMod)
		end
	end

	local frame = self.templateItemFrame:Clone()
	frame.Visible = true
	frame.Parent = self.templateItemFrame.Parent

	frame.Name = "NotifyItem123"

	local innerFrame = frame.InnerFrame

	-- innerFrame.UIStroke.Color = color
	innerFrame.Title.TextColor3 = color

	innerFrame.Title.Text = txt
	frame.Size = UDim2.fromScale(0, 0)

	ClientMod.tweenManager:createTween({
		target = frame,
		timer = 0.35, -- 0.5
		easingStyle = "Back",
		easingDirection = "Out",
		goal = {
			Size = UDim2.fromScale(1, 1.3),
		},
	})

	self.layoutOrder += 1
	frame.LayoutOrder = self.layoutOrder

	local newNotifyMod = {
		notifyName = notifyName,
		frame = frame,
	}
	self.notifyMods[notifyName] = newNotifyMod

	routine(function()
		if not duration then
			duration = 2
		end
		wait(duration)

		if newNotifyMod["destroyed"] then
			return
		end

		ClientMod.tweenManager:createTween({
			target = innerFrame.Title,
			timer = 1.5,
			easingStyle = "Quad",
			easingDirection = "In",
			goal = {
				TextTransparency = 1,
			},
		})

		-- move it to the right
		ClientMod.tweenManager:createTween({
			target = innerFrame,
			timer = 0.3,
			easingStyle = "Linear",
			easingDirection = "Out",
			goal = {
				Position = UDim2.fromScale(2, 0.5),
			},
		})

		wait(2)

		self:removeNotifyMod(newNotifyMod)
	end)
end

NotifyManager:init()

return NotifyManager
