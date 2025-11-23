local player = game.Players.LocalPlayer
local playerGui = player.PlayerGui
local playerScripts = player.PlayerScripts

local ClientMod = require(playerScripts.ClientMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local UIScaleManager = {
	strokeMods = {},
	staticTextMods = {},
	distStrokeMods = {},
}

local REFERENCE_RESOLUTION = Vector2.new(1616, 880)

function UIScaleManager:init()
	self:addCons()
end

function UIScaleManager:addCons()
	routine(function()
		local camera = workspace.CurrentCamera
		camera:GetPropertyChangedSignal("ViewportSize"):connect(function()
			self:refreshAllScaleMods()
		end)

		playerGui.DescendantAdded:Connect(function(instance)
			local validClasses = {
				"BillboardGui",
				"UITextSizeConstraint",
				"TextLabel",
			}
			if Common.listContains(validClasses, instance.ClassName) then
				self:recurseGUIForScaleMods(instance)
			end
		end)

		wait(1)

		-- print("RECURSING GUI FOR SCALE MODS")

		self:recurseGUIForScaleMods(playerGui)

		self:refreshAllScaleMods()
	end)
end

function UIScaleManager:recurseGUIForScaleMods(thing)
	for _, child in pairs(thing:GetDescendants()) do
		self:tryAddScaleMod(child)
	end
	self:tryAddScaleMod(thing)
end

function UIScaleManager:tryAddScaleMod(thing)
	local ignoreList = {
		"BackpackGui",
		"ProximityPrompts",
	}

	-- skip if it's in the ignore list
	for _, ignore in pairs(ignoreList) do
		local ignoreGUI = playerGui:FindFirstChild(ignore)
		if ignoreGUI and thing:IsDescendantOf(ignoreGUI) then
			return
		end
	end

	-- print("TRYING TO ADD SCALE MOD FOR: ", thing)

	if thing:IsA("UIStroke") then
		self:newStrokeMod(thing)
	end
	if thing:IsA("TextLabel") or thing:IsA("TextButton") then
		self:newStaticTextMod(thing)
	end
end

function UIScaleManager:refreshAllScaleMods()
	for _, strokeMod in pairs(self.strokeMods) do
		self:refreshStrokeMod(strokeMod)
	end
	for _, textMod in pairs(self.staticTextMods) do
		self:refreshStaticTextMod(textMod)
	end
end

function UIScaleManager:newStaticTextMod(title)
	if self.staticTextMods[title] then
		return
	end
	if title.TextScaled then
		return
	end

	local origTextSize = title.TextSize
	local textMod = {
		title = title,
		origTextSize = origTextSize,
	}
	self.staticTextMods[title] = textMod

	self:refreshStaticTextMod(textMod)
end

function UIScaleManager:newStrokeMod(stroke)
	if self.strokeMods[stroke] then
		-- print("ALREADY HAVE STROKEMOD FOR: ", stroke, stroke.Parent)
		return
	end

	local newStrokeMod = {
		stroke = stroke,
		baseThickness = stroke.Thickness,
		-- baseAbsoluteSize = text.AbsoluteSize,
	}
	self.strokeMods[stroke] = newStrokeMod

	self:refreshStrokeMod(newStrokeMod)
end

function UIScaleManager:checkScaleModsDeleted()
	local deletedCount = 0
	for stroke, strokeMod in pairs(self.strokeMods) do
		if not stroke or not stroke.Parent then
			self.strokeMods[stroke] = nil
			deletedCount += 1
		end
	end
	for title, textMod in pairs(self.staticTextMods) do
		if not title or not title.Parent then
			self.staticTextMods[title] = nil
			deletedCount += 1
		end
	end

	if deletedCount > 0 then
		print("DELETED SCALE MODS AUTOMATICALLY: ", deletedCount)
	end
end

function UIScaleManager:addDistStrokeModsFromBB(data)
	local bb = data["bb"]
	local adornee = data["adornee"]
	local baseDistance = data["baseDistance"]

	if not bb or not bb.Parent then
		warn(debug.traceback())
		warn("!!! NO BB FOUND FOR: ", bb)
		return
	end

	if not adornee then
		warn(debug.traceback())
		warn("!!! NO ADORNEE FOUND FOR: ", bb)
	end

	for _, child in pairs(bb:GetDescendants()) do
		if child:IsA("UIStroke") then
			self:newDistStrokeMod({
				bb = bb,
				stroke = child,
				adornee = adornee,
				baseDistance = baseDistance,
			})
		end
	end
end

function UIScaleManager:newDistStrokeMod(data)
	local bb = data["bb"]
	local stroke = data["stroke"]
	local adornee = data["adornee"]
	local baseDistance = data["baseDistance"]

	local newStrokeMod = {
		bb = bb,
		stroke = stroke,
		baseThickness = stroke.Thickness,
		adornee = adornee,
		baseDistance = baseDistance,
	}
	self.distStrokeMods[stroke] = newStrokeMod
end

function UIScaleManager:refreshStaticTextMod(mod)
	local title = mod["title"]
	local origTextSize = mod["origTextSize"]

	local camera = workspace.CurrentCamera
	local viewportSize = camera.ViewportSize

	local xRatio = viewportSize.X / 1648
	local yRatio = viewportSize.Y / 871

	local smallRatio = math.min(xRatio, yRatio)

	local newTextSize = origTextSize * smallRatio -- xRatio * yRatio
	title.TextSize = newTextSize
end

-- do it on heartbeat instead of render cause render is too performance heavy
function UIScaleManager:tick(timeRatio)
	for _, strokeMod in pairs(self.distStrokeMods) do
		self:refreshDistStrokeMod(strokeMod)
	end
end

function UIScaleManager:refreshDistStrokeMod(strokeMod)
	local stroke = strokeMod["stroke"]
	local baseThickness = strokeMod["baseThickness"]
	local adornee = strokeMod["adornee"]
	local bb = strokeMod["bb"]

	-- if stroke or bb is destroyed, remove it
	if not stroke or not stroke.Parent or not adornee or not adornee.Parent then
		self.distStrokeMods[stroke] = nil
		return
	end

	local camera = workspace.CurrentCamera

	-- get distance between camera CFrame and adornee CFrame
	local distance = (camera.CFrame.Position - adornee.Position).Magnitude
	distance = math.max(distance, 1)

	-- -- skip if distance is too far
	-- local distBuffer = 5
	-- if distance > bb.MaxDistance + distBuffer then
	-- 	return
	-- end

	local baseDistance = strokeMod["baseDistance"] or 20
	local distanceScale = baseDistance / distance

	local viewportSize = camera.ViewportSize

	local referenceSize = REFERENCE_RESOLUTION
	local resolutionScale = math.min(viewportSize.X, viewportSize.Y) / math.min(referenceSize.X, referenceSize.Y)

	local newThickness = baseThickness * distanceScale * resolutionScale

	stroke.Thickness = newThickness
end

function UIScaleManager:refreshStrokeMod(strokeMod)
	local camera = workspace.CurrentCamera
	local viewportSize = camera.ViewportSize

	local referenceSize = REFERENCE_RESOLUTION
	local resolutionScale = math.min(viewportSize.X, viewportSize.Y) / math.min(referenceSize.X, referenceSize.Y)

	local stroke = strokeMod["stroke"]
	local baseThickness = strokeMod["baseThickness"]

	stroke.Thickness = baseThickness * resolutionScale
end

UIScaleManager:init()

return UIScaleManager
