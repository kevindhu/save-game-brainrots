local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local MutationInfo = require(game.ReplicatedStorage.MutationInfo)
local EasyVisuals = require(game.ReplicatedStorage.EasyVisuals)

local MutationManager = {
	effectMap = {},
}

function MutationManager:init() end

function MutationManager:addMutationToRig(entity, rig, mutationClass)
	if not mutationClass then
		return
	end

	self:addMutationAura(rig, mutationClass)

	if mutationClass == "Rainbow" then
		if Common.isServer then
			local ServerMod = require(game.ServerScriptService.ServerMod)
			ServerMod.rainbowManager:addRainbowRig(rig)
		else
			local player = game.Players.LocalPlayer
			local playerScripts = player.PlayerScripts
			local ClientMod = require(playerScripts.ClientMod)
			ClientMod.rainbowManager:addRainbowRig(rig)
		end
	elseif mutationClass == "Gold" then
		self:addColorFromMutationRig(rig, mutationClass, entity, "GOLD")
	elseif mutationClass == "Diamond" then
		self:addColorFromMutationRig(rig, mutationClass, entity, "DIAMOND")
	elseif mutationClass == "Bubblegum" then
		self:addColorFromMutationRig(rig, mutationClass, entity, "BUBBLEGUM")
	end
end

function MutationManager:addColorFromMutationRig(rig, mutationClass, entity, colorName)
	local petClass = entity.petClass
	local referenceRig = game.ReplicatedStorage.Assets:FindFirstChild(petClass .. "#" .. colorName)
	if not referenceRig then
		-- warn("TODO: NO GOLD REFERENCE RIG FOR: ", petClass)
		return
	end

	for _, currPart in pairs(referenceRig:GetDescendants()) do
		if not currPart:IsA("BasePart") then
			continue
		end
		local ignoreList = {
			"ArmsHoldPart",
			"HumanoidRootPart",
		}
		if Common.listContains(ignoreList, currPart.Name) then
			continue
		end

		-- color the rig the same as the reference rig
		local origPart = rig:FindFirstChild(currPart.Name, true)
		if not origPart then
			warn("!!! NO ORIG PART FOUND FOR GOLD: ", currPart.Name)
			continue
		end
		origPart.Color = currPart.Color

		for _, child in pairs(origPart:GetDescendants()) do
			if child:IsA("SurfaceAppearance") then
				child:Destroy()
			end
		end

		-- add all surface appearances from the reference rig
		for _, child in pairs(currPart:GetDescendants()) do
			if not child:IsA("SurfaceAppearance") then
				continue
			end
			local newSurfaceAppearance = child:Clone()
			newSurfaceAppearance.Parent = origPart
		end
	end
end

-- NOTE: not using this anymore
function MutationManager:addColorFromPartIndexes(rig, mutationClass, entity)
	local mutationColorMap = MutationInfo.mutations[mutationClass].partColorIndexes

	local petClass = entity.petClass
	local referenceRig = game.ReplicatedStorage.Assets:FindFirstChild(petClass)
	if not referenceRig then
		-- warn("TODO: NO GOLD REFERENCE RIG FOR: ", petClass)
		return
	end

	for _, part in pairs(rig:GetDescendants()) do
		local colorIndex = part:GetAttribute("Color")
		if not colorIndex then
			continue
		end
		colorIndex = tonumber(colorIndex)

		local color = mutationColorMap[colorIndex]
		if not color then
			warn("NO COLOR FOUND FOR: ", colorIndex)
			continue
		end
		part.Color = color
	end
end

function MutationManager:addMutationAura(rig, mutationClass)
	local baseMutationModel = game.ReplicatedStorage.Assets:FindFirstChild("Aura" .. mutationClass)
	if not baseMutationModel then
		-- warn("COULD NOT FIND BASE AURA MODEL FOR: ", mutationClass)
		return
	end

	local rootPart = rig:FindFirstChild("RootPart") or rig.PrimaryPart

	local auraAttachment = rootPart:FindFirstChild("AuraAttachment")
	if not auraAttachment then
		warn("NO AURA ATTACHMENT FOUND FOR: ", rig.Name)
		return
	end

	local weldPartsModel = baseMutationModel:Clone()

	-- create mutationpart at the rootPart
	local mutationPart = Instance.new("Part")
	mutationPart.Name = "MutationPart"
	mutationPart.Size = Vector3.new(0.3, 0.3, 0.3)
	mutationPart.Anchored = false
	mutationPart.CanCollide = false
	mutationPart.Massless = true
	mutationPart.Transparency = 1
	mutationPart.Parent = rig

	mutationPart.CFrame = auraAttachment.WorldCFrame

	-- motor6d to the rootPart
	local weld = Instance.new("Motor6D")
	weld.Name = "AuraMotor123"
	weld.Part0 = rootPart
	weld.Part1 = mutationPart
	weld.C0 = rootPart.CFrame:inverse() * mutationPart.CFrame
	weld.C1 = CFrame.new(0, 0, 0)
	weld.Parent = mutationPart

	for _, currPart in pairs(weldPartsModel:GetDescendants()) do
		if not currPart:IsA("BasePart") then
			continue
		end
		currPart.Transparency = 1 -- 0.5
		currPart.Name = "MutationPart"
	end

	Common.basicWeldPartsOnRig(weldPartsModel, rig)

	weldPartsModel.Name = "MutationAuraWeldParts"
	weldPartsModel.Parent = rig

	return weldPartsModel
end

function MutationManager:cleanEffectMap()
	for title, _ in pairs(self.effectMap) do
		if not title or not title.Parent then
			-- warn("CLEANING UP EFFECT MAP: ", title)
			self.effectMap[title] = nil
		end
	end
end

local easyVisualPresetMap = {
	["Rainbow"] = "Rainbow",
}

function MutationManager:applyMutationColor(title, mutationClass)
	if not mutationClass or mutationClass == "None" then
		title.Visible = false
		return
	end

	title.Visible = true

	local mutationStats = MutationInfo.mutations[mutationClass]
	if not mutationStats then
		warn("!!! NO MUTATION STATS FOUND FOR: ", mutationClass)
		return
	end

	title.Text = mutationStats["alias"]
	title.TextColor3 = mutationStats["color"]

	self:cleanEffectMap()

	local oldEffectMod = self.effectMap[title]
	if oldEffectMod then
		if oldEffectMod.mutationClass == mutationClass then
			return
		end

		oldEffectMod.effect:Destroy()
		self.effectMap[title] = nil
	end

	if easyVisualPresetMap[mutationClass] then
		title.TextColor3 = Color3.fromRGB(255, 255, 255)

		local effect = EasyVisuals.new(title, easyVisualPresetMap[mutationClass], 0.5)
		self.effectMap[title] = {
			effect = effect,
			mutationClass = mutationClass,
		}
	end
end

return MutationManager
