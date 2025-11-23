local RatingInfo = require(game.ReplicatedStorage.Data.RatingInfo)

local EasyVisuals = require(game.ReplicatedStorage.EasyVisuals)

local RatingManager = {
	visualMods = {},
}

local easyVisualPresetMap = {
	["Secret"] = "Zebra",
	["Mythic"] = "Rainbow",
}

function RatingManager:applyRatingColor(frame, rating)
	local ratingColor = RatingInfo["ratingColorMap"][rating]

	local oldVisualMod = self.visualMods[frame]
	if oldVisualMod then
		oldVisualMod:Destroy()
		self.visualMods[frame] = nil
	end

	if frame:IsA("TextLabel") then
		frame.TextColor3 = ratingColor
	else
		frame.BackgroundColor3 = ratingColor
	end

	if easyVisualPresetMap[rating] then
		if frame:IsA("TextLabel") then
			frame.TextColor3 = Color3.fromRGB(255, 255, 255)
		else
			frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		end

		local speed = 0.5
		local visualMod = EasyVisuals.new(frame, easyVisualPresetMap[rating], speed)
		self.visualMods[frame] = visualMod
	end

	self:cleanUpVisualMods()
end

function RatingManager:cleanUpVisualMods()
	for otherFrame, _ in pairs(self.visualMods) do
		if not otherFrame or not otherFrame.Parent then
			self.visualMods[otherFrame] = nil
		end
	end
end

return RatingManager
