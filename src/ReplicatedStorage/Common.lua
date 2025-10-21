local Debris = game:GetService("Debris")
local HTTPService = game:GetService("HttpService")
local market = game:GetService("MarketplaceService")
local players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local TEST_CLONE_PLOTS = false

local Common = {
	isStudio = RunService:IsStudio(),
	isServer = RunService:IsServer(),

	testClonePlots = TEST_CLONE_PLOTS,

	robuxSymbol = "",

	-- DEVELOPER
	developerUserIds = {
		2844656066, -- lobotomy6612

		-- for testing locally
		-1, -- Player1
		-2, -- Player2
	},

	mainPlaceId = 96761746514152,
	testPlaceId = 96761746514152,

	groupId = 338831493, -- Brainrot Atelier
	universeId = 8458205008,

	strengthEmoji = "💪",
	anchorEmoji = "⚓",
	speedEmoji = "👟",

	-- UI
	clickInputTypes = {
		Enum.UserInputType.MouseButton1,
		Enum.UserInputType.Touch,
	},

	touchEnabled = UserInputService.TouchEnabled,

	usernameMap = {},
	userIdMap = {},
}

function Common.applyDescription(humanoid, description)
	local success, err = pcall(function()
		humanoid:ApplyDescription(description)
	end)
	return success, err
end

function Common.setCustomPhysicalProperties(data)
	local part = data["part"]
	local density = data["density"] or 0.03 -- 0.0001
	local friction = data["friction"] or 0 -- 0.1
	local elasticity = data["elasticity"] or 1 -- 0.8 -- 0.2 (orig)
	local frictionWeight = data["frictionWeight"] or 1
	local elasticityWeight = data["elasticityWeight"] or 5 -- 2

	-- Construct new PhysicalProperties and set
	local properties = PhysicalProperties.new(density, friction, elasticity, frictionWeight, elasticityWeight)
	part.CustomPhysicalProperties = properties
end

function Common.shuffleList(list)
	local size = #list
	for i = size, 2, -1 do
		local j = math.random(i)
		list[i], list[j] = list[j], list[i]
	end
	return list
end

function Common.rollFromProbMap(probMap)
	local totalWeight = 0
	for itemClass, weight in pairs(probMap) do
		totalWeight = totalWeight + weight
	end

	local randomNumber = math.random()
	local thresholdWeight = randomNumber * totalWeight
	local currentWeight = 0

	for itemClass, weight in pairs(probMap) do
		currentWeight = currentWeight + weight
		if currentWeight >= thresholdWeight then
			return itemClass
		end
	end

	warn("ERROR: COULD NOT ROLL FROM PROB MAP: ", probMap)
	return nil
end

function Common.rollFromInverseProbMap(probMap, luck)
	luck = luck or 1

	local totalWeight = 0
	local weightMods = {}

	for itemClass, count in pairs(probMap) do
		if count < 0 then
			continue
		end

		-- Calculate debuff based on count and luck (inverse probability logic)
		local debuff = 1 + (luck / (count + 1))
		local weight = 1 / count
		local finalWeight = weight / debuff

		table.insert(weightMods, { itemClass, finalWeight, count })
		totalWeight = totalWeight + finalWeight
	end

	if totalWeight == 0 then
		warn("ERROR: TOTAL WEIGHT IS 0 IN INVERSE PROB MAP: ", probMap)
		return nil
	end

	local random = math.random() * totalWeight
	local currentWeight = 0

	for _, weightMod in ipairs(weightMods) do
		local itemClass = weightMod[1]
		local addWeight = weightMod[2]

		currentWeight = currentWeight + addWeight

		if currentWeight >= random then
			return itemClass
		end
	end

	warn("ERROR: COULD NOT ROLL FROM INVERSE PROB MAP: ", probMap)
	return nil
end

function Common.getInfoMeta(module, itemClass, noWarn)
	for _, categoryClass in pairs(module.categoryList) do
		local currStats = module[categoryClass][itemClass]
		if currStats then
			return currStats
		end
	end
	if not noWarn then
		warn(debug.traceback())
		warn("COULD NOT GET STATS FOR : ", itemClass, module)
	end
	return false
end

local profileImageMap = {}
function Common.getProfileImageFromUserId(userId)
	userId = tonumber(userId)
	if userId <= 0 then
		userId = 1
	end

	if profileImageMap[userId] then
		return profileImageMap[userId]
	end

	local faceImage = ""
	local faceError
	local success, response = pcall(function()
		faceImage, faceError =
			game.Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
	end)
	if success then
		profileImageMap[userId] = faceImage
	end

	-- print("FACE IMAGE: ", faceImage)
	return faceImage
end

function Common.getUserIdFromUsername(userName)
	local userIdMap = Common.userIdMap

	if userName:lower() == "player1" then
		return -1
	end
	if userName:lower() == "player2" then
		return -2
	end

	if userIdMap[userName] then
		return userIdMap[userName]
	end

	local userId
	local success, err
	local retryLimit = 2

	for i = 1, retryLimit do
		success, err = pcall(function()
			userId = game.Players:GetUserIdFromNameAsync(userName)
		end)
		if success then
			break
		end
	end

	if not success then
		-- warn("COULD NOT GET USERID FROM USERNAME: ", userName, err)
		return
	end

	userIdMap[userName] = userId
	return userId
end

local humanoidDescriptionMap = {}
function Common.getHumanoidDescriptionFromUserId(userId)
	local cachedDescriptionMod = humanoidDescriptionMap[userId]
	if cachedDescriptionMod and cachedDescriptionMod.cacheExpiree > os.time() then
		local description = cachedDescriptionMod.description
		-- warn("GOT CACHED HUMANOID DESCRIPTION: ", userId, description)
		return true, description
	end

	local success, response = pcall(function()
		return game.Players:GetHumanoidDescriptionFromUserId(userId)
	end)

	if success then
		humanoidDescriptionMap[userId] = {
			description = response,
			cacheExpiree = os.time() + 60 * 1, -- 1 minute
		}
	end

	return success, response
end

function Common.updateUsernameMap(data)
	local usernameMap = Common.usernameMap
	for userId, userName in pairs(data) do
		userId = tonumber(userId)
		usernameMap[userId] = userName
	end
end

function Common.randomBetween(min, max)
	return min + (max - min) * math.random()
end

function Common.getUsernameFromUserId(userId)
	userId = tonumber(userId)

	if userId < 0 then
		return "Player" .. tostring(math.abs(userId))
	end

	-- Check if the cache contains the name
	local usernameMap = Common.usernameMap
	if usernameMap[userId] then
		return usernameMap[userId]
	end
	-- Second, check if the user is already connected to the server
	local player = players:GetPlayerByUserId(userId)
	if player then
		usernameMap[userId] = player.Name
		return player.Name
	end

	-- IF PREVIOUS METHODS FAILED, IT NEEDS TO CALL THE API
	-- warn(debug.traceback())
	-- print("API FETCHING USERNAME FROM USERID")

	local defaultName = string.format("userId:<%d>", userId)

	-- If all else fails, send a request
	local retryLimit = 2
	local lastSuccess, lastError
	local name
	for i = 1, retryLimit do
		lastSuccess, lastError = pcall(function()
			name = players:GetNameFromUserIdAsync(userId)
		end)
		if name then
			break
		end
		wait(0.5)
	end
	if not name then
		-- can happen even with retry limit
		-- warn("CANNOT GET NAME FROM USERID: ", userId, lastError)

		-- if already cached by the time this is called, return that
		if usernameMap[userId] then
			return usernameMap[userId]
		end
		return defaultName
	end
	usernameMap[userId] = name

	-- send this to the client map

	return name
end

local productInfoMap = {}
function Common.getProductInfo(productId, productType)
	local productKey = productId .. "_" .. tostring(productType)

	local productInfo = productInfoMap[productKey]
	if productInfo then
		-- warn("GOT CACHED PRODUCT INFO: ", productId, productType, productInfo)
		return productInfo
	end

	local success, err = pcall(function()
		productInfo = market:GetProductInfo(productId, productType)
	end)
	if not success then
		-- warn("COULD NOT GET PRODUCT INFO: ", productId, productType, err)
		return
	end

	productInfoMap[productKey] = productInfo
	return productInfo
end

function Common.getDefaultNameColor(name)
	local NAME_COLORS = {
		Color3.fromRGB(253, 41, 67), -- Bright red
		Color3.fromRGB(1, 162, 255), -- Bright blue
		Color3.fromRGB(2, 184, 87), -- Earth green
		BrickColor.new("Bright violet").Color,
		BrickColor.new("Bright orange").Color,
		BrickColor.new("Bright yellow").Color,
		BrickColor.new("Light reddish violet").Color,
		BrickColor.new("Brick yellow").Color,
	}

	local function GetNameValue(pName)
		local value = 0
		for index = 1, #pName do
			local cValue = string.byte(string.sub(pName, index, index))
			local reverseIndex = #pName - index + 1
			if #pName % 2 == 1 then
				reverseIndex = reverseIndex - 1
			end
			if reverseIndex % 4 >= 2 then
				cValue = -cValue
			end
			value = value + cValue
		end
		return value
	end

	local color_offset = 0
	return NAME_COLORS[((GetNameValue(name) + color_offset) % #NAME_COLORS) + 1]
end

function Common.wait(seconds)
	return task.wait(seconds)
end

function Common.checkDeveloper(userId)
	-- return false
	return Common.listContains(Common.developerUserIds, userId)
end

function Common.len(lst)
	local count = 0

	for name, obj in pairs(lst) do
		count = count + 1
	end
	return count
end

-- in seconds, but can be fractional
function Common.getCurrentDecimalTime()
	local ms = DateTime.now().UnixTimestampMillis
	local currentTime = ms / 1000

	return currentTime
end

function Common.getCAngle(frame)
	local x, y, z = frame:toEulerAnglesXYZ()

	if x ~= x or y ~= y or z ~= z then
		-- warn(frame, frame.p)
		warn("BAD GETCANGLE: ", x, y, z)
		x = 0
		y = 0
		z = 0
	end

	return CFrame.Angles(x, y, z)
end

function Common.tableToString(table)
	local retString = nil
	local success, err = pcall(function()
		retString = HTTPService:JSONEncode(table)
	end)
	if not success then
		return "ERROR_TABLE_TO_STRING"
	end
	return retString
end

function Common.toDegrees(angle)
	return angle * 180 / math.pi
end

function Common.toRadians(angle)
	return angle * math.pi / 180
end

function Common.deepCopy(original)
	if not original then
		return nil
	end

	local copy = {}
	for k, v in pairs(original) do
		-- as before, but if we find a table, make sure we copy that too
		if type(v) == "table" then
			v = Common.deepCopy(v)
		end
		copy[k] = v
	end

	return copy
end

function Common.addRichTextColor(text, color)
	local r = math.floor(color.r * 255)
	local g = math.floor(color.g * 255)
	local b = math.floor(color.b * 255)
	local newText = string.format('<font color="rgb(%s,%s,%s)">%s</font>', r, g, b, text)

	return newText
end

function Common.addRichTextStroke(text, color, thickness)
	local r = math.floor(color.r * 255)
	local g = math.floor(color.g * 255)
	local b = math.floor(color.b * 255)

	local txt = string.format(
		'<stroke color="rgb(%s,%s,%s)" joins="round" thickness="%s" transparency="0">%s</stroke>',
		r,
		g,
		b,
		thickness,
		text
	)
	return txt
end

function Common.routine(func)
	task.spawn(func)
end

function Common.simpleRound(num, places)
	places = math.pow(10, places or 0)
	num = num * places
	if num >= 0 then
		num = math.floor(num + 0.5)
	else
		num = math.ceil(num - 0.5)
	end

	return num / places
end

function Common.lerpClassic(a, b, t)
	return a + (b - a) * t
end

function Common.lerp(a, b, t)
	local diff = math.floor(math.abs((b - a) * t))
	if diff == 0 then
		return b
	end

	return a + (b - a) * t
end

-- WARNING - this can only check if its the same memory!
-- DO NOT USE THIS ON SAVED LISTS
-- THEY WILL HAVE DIFF MEMORIES FOR EACH KEY, VALUE
function Common.removeFromTable(mod, value)
	for index, currValue in pairs(mod) do
		if currValue == value then
			-- print("REMOVING VALUE FROM MOD: ", mod, value, index)
			table.remove(mod, index)
			return
		end
	end
end

function Common.setCollisionGroup(object, group)
	if not object then
		return
	end

	for _, descendant in ipairs(object:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.CollisionGroup = group
			-- print("SET COLLISION GROUP: ", descendant, group)
		end
	end

	-- Also check the object itself if it's a BasePart
	if object:IsA("BasePart") then
		object.CollisionGroup = group
	end
end

function Common.getRandomFlatDir()
	local randX = Common.randomDecimal()
	local randZ = Common.randomDecimal()

	-- NOTE: remember you CANNOT put .unit on an empty vector
	local moveDir = Vector3.new(randX, 0, randZ).unit

	if moveDir.X ~= moveDir.X then
		error("NAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAN")
	end

	return moveDir
end

function Common.randomDecimal()
	local decimal = math.random() + 0.01
	if math.random(100) >= 50 then
		decimal = -decimal
	end
	return decimal
end

function Common.weldPartsToRig(rig)
	local weldPartsModel = rig:FindFirstChild("WeldParts")
	if not weldPartsModel then
		return
	end

	Common.weldPartsFromModel({
		rig = rig,
		referenceRig = rig,
		weldPartsModel = weldPartsModel,
	})
end

local R15PartNameMap = {
	["RightUpperArm"] = "Right Arm",
	["RightLowerArm"] = "Right Arm",
	["RightHand"] = "Right Arm",
	["LeftUpperArm"] = "Left Arm",
	["LeftLowerArm"] = "Left Arm",
	["LeftHand"] = "Left Arm",
	["RightUpperLeg"] = "Right Leg",
	["RightLowerLeg"] = "Right Leg",
	["RightFoot"] = "Right Leg",
	["LeftUpperLeg"] = "Left Leg",
	["LeftLowerLeg"] = "Left Leg",
	["LeftFoot"] = "Left Leg",
	["UpperTorso"] = "Torso",
	["LowerTorso"] = "Torso",
	["Head"] = "Head",
	["HumanoidRootPart"] = "Torso",
}

function Common.weldPartsFromModel(data)
	local rig = data["rig"]
	local referenceRig = data["referenceRig"]
	local weldPartsModel = data["weldPartsModel"]

	for _, currPart in pairs(weldPartsModel:GetChildren()) do
		if not currPart:IsA("BasePart") then
			continue
		end

		local basePartName = currPart.Name
		basePartName = R15PartNameMap[basePartName] or basePartName

		local referenceBasePart = referenceRig:FindFirstChild(basePartName)
		if not referenceBasePart then
			warn("!! NO REFERENCE BASEPART FOUND: ", basePartName, rig)
			continue
		end

		local basePart = rig:FindFirstChild(basePartName)
		if not basePart then
			warn("!! NO BASEPART FOUND: ", basePartName, rig)
			continue
		end

		-- get the cframe offset from the reference basepart
		local referenceOffset = referenceBasePart.CFrame:ToObjectSpace(currPart.CFrame)
		currPart.CFrame = basePart.CFrame * referenceOffset
		currPart.Name = basePartName .. "_WELDPART"

		Common.weldPartToBasePart(currPart, basePart)
	end

	-- weldPartsModel:Destroy()
end

function Common.basicWeldPartsOnRig(weldPartsModel, rig)
	for _, currPart in pairs(weldPartsModel:GetDescendants()) do
		if not currPart:IsA("BasePart") then
			continue
		end

		local basePartName = currPart.Name

		local basePart = rig:FindFirstChild(basePartName)
		if not basePart then
			warn("!! NO BASEPART FOUND: ", basePartName, rig)
			continue
		end

		currPart.CFrame = basePart.CFrame
		currPart.Transparency = 1

		Common.weldPartToBasePart(currPart, basePart)
	end
end

function Common.setRigDensity(rig, density, friction)
	for _, child in pairs(rig:GetDescendants()) do
		if not child:IsA("BasePart") then
			continue
		end
		if child.Massless then
			continue
		end

		local defaultFriction = 0.1 -- 0.01
		if not friction then
			friction = defaultFriction
		end

		Common.setCustomPhysicalProperties({
			part = child,
			density = density,
			friction = defaultFriction,
			elasticity = 0.8,
			frictionWeight = 0.1,
			elasticityWeight = 5,
		})
	end
end

function Common.weldPartToBasePart(currPart, basePart)
	currPart.CanCollide = false
	currPart.Massless = true

	-- weld the part onto the base
	local weld = Instance.new("Motor6D")
	weld.Part0 = currPart
	weld.Part1 = basePart
	weld.C0 = currPart.CFrame:inverse() * basePart.CFrame
	weld.C1 = CFrame.new(0, 0, 0)
	weld.Name = "RigWeldMotor123"
	weld.Parent = currPart

	currPart:SetAttribute("IsWeldPart", true)

	currPart.Anchored = false
end

function Common.getHorizontalVector(pos1, pos2)
	return Vector3.new(pos2.X - pos1.X, 0, pos2.Z - pos1.Z)
end

function Common.getHorizontalDist(pos1, pos2)
	local finalVect = Common.getHorizontalVector(pos2, pos1)
	if finalVect == Vector3.new() then
		return 0
	end
	return finalVect.Magnitude
end

function Common.abbreviateNumber(number, decimalPlaces)
	number = tonumber(number)

	if not decimalPlaces then
		decimalPlaces = 2
	end

	-- Create ordered list of abbreviations from largest to smallest
	local orderedAbbreviations = {
		{ symbol = "V", value = 10 ^ 63 },
		{ symbol = "Nd", value = 10 ^ 60 },
		{ symbol = "Od", value = 10 ^ 57 },
		{ symbol = "Spd", value = 10 ^ 54 },
		{ symbol = "Sd", value = 10 ^ 51 },
		{ symbol = "Qnd", value = 10 ^ 48 },
		{ symbol = "Qtd", value = 10 ^ 45 },
		{ symbol = "Td", value = 10 ^ 42 },
		{ symbol = "Dd", value = 10 ^ 39 },
		{ symbol = "Ud", value = 10 ^ 36 },
		{ symbol = "Dc", value = 10 ^ 33 },
		{ symbol = "No", value = 10 ^ 30 },
		{ symbol = "Oc", value = 10 ^ 27 },
		{ symbol = "Sp", value = 10 ^ 24 },
		{ symbol = "Sx", value = 10 ^ 21 },
		{ symbol = "Qi", value = 10 ^ 18 },
		{ symbol = "Qa", value = 10 ^ 15 },
		{ symbol = "T", value = 10 ^ 12 },
		{ symbol = "B", value = 10 ^ 9 },
		{ symbol = "M", value = 10 ^ 6 },
		{ symbol = "K", value = 10 ^ 3 },
	}

	-- Find the appropriate abbreviation
	for _, abbr in ipairs(orderedAbbreviations) do
		if number >= abbr.value then
			local shortNum = number / abbr.value
			local roundedShortNum = Common.simpleRound(shortNum, decimalPlaces)

			-- Check if rounding would push us to the next abbreviation
			if roundedShortNum >= 1000 and abbr.symbol ~= "V" then
				-- Find the next abbreviation up
				for i, nextAbbr in ipairs(orderedAbbreviations) do
					if nextAbbr.value == abbr.value * 1000 then
						return "1" .. nextAbbr.symbol
					end
				end
			else
				return tostring(roundedShortNum) .. abbr.symbol
			end
		end
	end

	-- If no abbreviation is used, just round the number
	return tostring(Common.simpleRound(tonumber(number), decimalPlaces))
end

function Common.safeUnit(vector, item)
	local bad = nil
	if vector.Magnitude == 0 then
		warn(debug.traceback())
		warn("WARNING BAD VECTOR: ", vector, item.name)
		vector = Vector3.new(1, 0, 0)
		bad = true
	end
	return vector.unit, bad
end

function Common.createTestLine(posA, posB, duration, color)
	local line = Instance.new("Part")

	line.Anchored = true
	line.CanCollide = false
	line.Parent = workspace

	local midPos = (posA + posB) / 2
	local vect = (posB - posA).unit
	local length = (posA - posB).Magnitude
	local finalFrame = CFrame.new(midPos, midPos + vect)

	line.Size = Vector3.new(1, 1, length)
	line.CFrame = finalFrame
	line.Name = "TESTLINE123"
	line.Parent = game.Workspace.HitBoxes

	if color then
		line.Color = color
	end

	if duration then
		Debris:AddItem(line, duration)
	end

	return line
end

function Common.getGUID()
	local randomID = HTTPService:GenerateGUID(false)

	-- Remove hyphens and truncate to 10 characters
	randomID = string.gsub(randomID, "-", "")
	randomID = string.sub(randomID, 1, 15)

	return randomID
end

function Common.colorToHex(color)
	return string.format("#%02X%02X%02X", color.R * 0xFF, color.G * 0xFF, color.B * 0xFF)
end

function Common.colorFromHex(hex)
	local r, g, b = string.match(hex, "^#?(%w%w)(%w%w)(%w%w)$")
	return Color3.fromRGB(tonumber(r, 16), tonumber(g, 16), tonumber(b, 16))
end

function Common.getMaxCharText(text, maxCount)
	local currCount = 0

	local limit
	local success, err = pcall(function()
		for first, last in utf8.graphemes(text) do
			local charLength = last + 1 - first
			currCount = currCount + charLength

			if currCount >= maxCount then
				-- print(currCount, last)
				limit = last
				break
			end
		end
	end)
	if not success then
		return "ERROR_MAX_TEXT", 0
	end
	return text:sub(1, limit), currCount
end

function Common.getReadableDateString(timestamp)
	local timeMod = os.date("*t", timestamp)

	local minuteString = string.format("%0.2i", timeMod["min"])
	local secondString = string.format("%0.2i", timeMod["sec"])

	local returnString = string.format(
		"%s/%s/%s %s:%s:%s",
		timeMod["month"],
		timeMod["day"],
		timeMod["year"],
		timeMod["hour"],
		minuteString,
		secondString
	)
	return returnString
end

function Common.checkInGroup(player)
	local isInGroup
	pcall(function()
		isInGroup = player:IsInGroup(Common.groupId)
	end)
	return isInGroup
end

function Common.commas(amount)
	local formatted = amount
	while true do
		local k
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
		if k == 0 then
			break
		end
	end
	return formatted
end

function Common.convertSecondsToReadableString(totalSeconds, colonNotation)
	if totalSeconds < 0 then
		return "UNDEFINED: " .. totalSeconds
	end

	local days = math.floor(totalSeconds / 86400)
	local hours = math.floor(totalSeconds / 3600) % 24
	local minutes = math.floor(totalSeconds / 60) % 60
	local seconds = math.floor(totalSeconds % 60)

	if colonNotation then
		if hours > 0 then
			return string.format("%d:%02d:%02d", hours, minutes, seconds)
		else
			return string.format("%d:%02d", minutes, seconds)
		end
	else
		if days > 0 then
			return string.format("%dd %dh %dm", days, hours, minutes)
		elseif hours > 0 then
			return string.format("%dh %dm", hours, minutes)
		elseif minutes > 0 then
			return string.format("%dm %ds", minutes, seconds)
		else
			return string.format("%ds", seconds)
		end
	end
end

function Common.listContains(lst, item)
	for _, thing in pairs(lst) do
		if thing == item then
			return true
		end
	end
	return false
end

function Common.quadraticBezier(t, p0, p1, p2)
	return (1 - t) ^ 2 * p0 + (1 - t) * 2 * t * p1 + t ^ 2 * p2
end

function Common.getAngleBetweenVectors(vectorA, vectorB)
	local radAngle = math.acos(vectorA:Dot(vectorB) / (vectorA.Magnitude * vectorB.Magnitude))
	return Common.toDegrees(radAngle)
end

function Common.getBaseAngleFromFrame(frame, baseVector)
	if not baseVector then
		baseVector = Vector3.new(1, 0, 0)
	end

	local projectedVector = frame:VectorToObjectSpace(baseVector) * Vector3.new(1, 0, 1)
	local radAngle = math.atan2(projectedVector.Z, projectedVector.X)

	return Common.toDegrees(radAngle)
end

return Common
