local ServerMod = require(game.ServerScriptService.ServerMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local BaseTool = require(game.ServerScriptService.Tools.BaseTool)

local PetInfo = require(game.ReplicatedStorage.PetInfo)
local ItemInfo = require(game.ReplicatedStorage.ItemInfo)
local MutationInfo = require(game.ReplicatedStorage.MutationInfo)
local EggInfo = require(game.ReplicatedStorage.EggInfo)

local StashTool = {}
StashTool.__index = StashTool
setmetatable(StashTool, { __index = BaseTool })

function StashTool.new(user, tool, data)
	local self = BaseTool.new(user, tool, data)

	setmetatable(self, StashTool)
	return self
end

function StashTool:init()
	BaseTool.init(self)

	self.tool:SetAttribute("race", self.race)

	local itemClass = self.toolClass
	local itemStats = ItemInfo:getMeta(itemClass, true)
		or PetInfo:getMeta(itemClass, true)
		or EggInfo:getMeta(itemClass, true)

	if not itemStats then
		warn("NO ITEM STATS FOR: ", itemClass)
		return
	end

	local handle = self.tool:FindFirstChild("Handle")
	if handle then
		handle.Transparency = 1
		for _, child in pairs(handle:GetDescendants()) do
			child:Destroy()
		end
	end
end

function StashTool:addEggModel()
	if self.race ~= "egg" then
		return
	end

	local eggClass = self.toolClass

	local toolScaleRatio = 1

	local eggModel = game.ReplicatedStorage.Assets[eggClass]:Clone()
	eggModel.PrimaryPart = eggModel:FindFirstChild("RootPart")

	if self.mutationClass and self.mutationClass ~= "None" then
		ServerMod.mutationManager:addMutationAura(eggModel, self.mutationClass)
	end

	eggModel:ScaleTo(eggModel:GetScale() * toolScaleRatio)

	local head = self.user.rig.Head
	local modelFrame = head.CFrame * CFrame.new(0, 0, -2) -- * CFrame.Angles(math.rad(-90), 0, 0)

	for _, child in pairs(eggModel:GetDescendants()) do
		if not child:IsA("BasePart") then
			continue
		end

		child.CanCollide = false
		child.Anchored = false
		child.Massless = true

		local weld = Instance.new("WeldConstraint")
		weld.Part0 = child
		weld.Part1 = head
		weld.Parent = child
	end

	eggModel:SetPrimaryPartCFrame(modelFrame)

	eggModel.Parent = head

	self.eggModel = eggModel
end

function StashTool:addPetRig()
	local race = self.race
	if race ~= "pet" then
		return
	end

	local head = self.user.rig.Torso

	local fakeRig = game.ReplicatedStorage.Assets[self.toolClass]:Clone()

	local toolScaleRatio = PetInfo:getRealScale(self.baseWeight, self.level)
	local finalScale = fakeRig:GetScale() * toolScaleRatio
	fakeRig:ScaleTo(finalScale)

	local modelFrame, extentsSize = fakeRig:GetBoundingBox()
	local centerOffset = modelFrame:inverse() * fakeRig.PrimaryPart.CFrame

	-- local centerOffset = CFrame.new()

	fakeRig:Destroy()

	local petClass = self.toolClass
	local petRig = ServerMod.weldPetManager:addWeldPetRig({
		petClass = petClass,
		baseWeight = self.baseWeight,
		level = self.level,
		anchorPart = head,
		anchorOffsetFrame = centerOffset * CFrame.new(0, 0, -3),

		-- mutations
		mutationManager = ServerMod.mutationManager,
		mutationClass = self.mutationClass,
	})

	petRig.Name = petClass .. "_WELD_RIG"
	petRig.Parent = self.tool

	self:animatePetRig(petRig)

	self.petRig = petRig
end

function StashTool:animatePetRig(petRig)
	local petClass = self.toolClass
	local animationId = PetInfo["idleAnimationMap"][petClass]
	local weldRigEntity = {
		rig = petRig,
	}
	local trackMod = ServerMod.animUtils:animate(weldRigEntity, {
		race = "Idle",
		animationId = animationId,
	})

	if not trackMod then
		return
	end

	trackMod["track"]:Play()
end

function StashTool:removePetRig()
	if self.petRig then
		self.petRig:Destroy()
		self.petRig = nil
	end
end

function StashTool:removeEggModel()
	local eggModel = self.eggModel
	if eggModel then
		eggModel:Destroy()
	end
end

function StashTool:onEquip()
	BaseTool.onEquip(self)

	self:addPetRig()
	self:addEggModel()

	-- print("EQUIPPING STASH TOOL: ", self.toolName)
end

function StashTool:onUnequip()
	BaseTool.onUnequip(self)

	self:destroy()
end

function StashTool:onActivate() end

function StashTool:tryConfirmPlacement(data)
	if not self:checkPlacementValid(data) then
		return
	end

	-- print("CONFIRMING PLACEMENT: ", data)

	self:confirmPlacement(data)
end

function StashTool:checkPetPlacementValid(data)
	local inputPlaceFrame = data["placeFrame"]

	local floorPart = self.user.home.plotManager.floorPart
	local eggFloorPart = self.user.home.plotManager.eggFloorPart

	local maxPetCount = self.user.home.plotManager:getMaxPetCount()

	if len(self.user.home.petManager.pets) >= maxPetCount then
		self.user:notifyError("Cannot place more than " .. maxPetCount .. " brainrots")
		return false
	end

	local whiteList = {
		floorPart,
		eggFloorPart,
	}

	local isValid, placeFrame = self:raycastPlaceModel(inputPlaceFrame, whiteList)
	if not isValid then
		self.user:notifyError("Invalid placement")
		return false
	end

	local petManager = self.user.home.petManager
	if not petManager.initialized then
		self.user:notifyError("You can't place a brainrot yet")
		return false
	end
	return true
end

function StashTool:raycastPlaceModel(frame, whiteList)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Whitelist
	raycastParams.FilterDescendantsInstances = whiteList

	local raycastResult =
		game.Workspace:Raycast(frame.Position + Vector3.new(0, 10, 0), Vector3.new(0, -20, 0), raycastParams)

	if not raycastResult then
		return false, CFrame.new(0, -100, 0)
	end

	local floorPart = self.user.home.plotManager.floorPart

	local finalFrame = CFrame.new(raycastResult.Position) * Common.getCAngle(floorPart.CFrame)
	return true, finalFrame
end

function StashTool:checkEggPlacementValid(data)
	local inputPlaceFrame = data["placeFrame"]

	-- first, change the placeFrame to be raycast to the ground

	local floorPart = self.user.home.plotManager.floorPart
	local eggFloorPart = self.user.home.plotManager.eggFloorPart

	local whiteList = {
		floorPart,
		eggFloorPart,
	}

	local eggManager = self.user.home.eggManager
	if not eggManager.initialized then
		self.user:notifyError("You can't place an egg yet")
		return false
	end

	local maxEggCount = 15
	if len(eggManager.eggs) >= maxEggCount then
		self.user:notifyError("Cannot place more than " .. maxEggCount .. " eggs")
		return false
	end

	local isValid, placeFrame = self:raycastPlaceModel(inputPlaceFrame, whiteList)
	if not isValid then
		self.user:notifyError("Invalid placement")
		return false
	end

	local placeCollideModel = game.ReplicatedStorage.Assets.PlaceCollideModel:Clone()
	placeCollideModel:PivotTo(placeFrame * CFrame.new(0, placeCollideModel.PrimaryPart.Size.Y / 2, 0))
	placeCollideModel.Parent = game.Workspace.HitBoxes

	-- see if this placeCollidePart collides with other eggs
	local filter = OverlapParams.new()
	filter.FilterType = Enum.RaycastFilterType.Include

	local fakeModels = {}
	for _, egg in pairs(self.user.home.eggManager.eggs) do
		local currPlaceCollideModel = game.ReplicatedStorage.Assets.PlaceCollideModel:Clone()
		currPlaceCollideModel:PivotTo(egg.firstFrame * CFrame.new(0, currPlaceCollideModel.PrimaryPart.Size.Y / 2, 0))
		currPlaceCollideModel.Parent = game.Workspace.HitBoxes

		filter:AddToFilter(currPlaceCollideModel.PrimaryPart)

		table.insert(fakeModels, currPlaceCollideModel)
	end

	local foundParts = game.Workspace:GetPartsInPart(placeCollideModel.PrimaryPart, filter)
	if len(foundParts) > 0 then
		-- not valid
		placeCollideModel:Destroy()
		for _, fakeModel in pairs(fakeModels) do
			fakeModel:Destroy()
		end

		self.user:notifyError("Invalid placement")
		return false
	end

	placeCollideModel:Destroy()

	for _, fakeModel in pairs(fakeModels) do
		fakeModel:Destroy()
	end

	return true
end

function StashTool:checkPlacementValid(data)
	local race = self.race
	if race == "pet" then
		return self:checkPetPlacementValid(data)
	elseif race == "egg" then
		return self:checkEggPlacementValid(data)
	end
end

function StashTool:confirmPlacement(data)
	local placeFrame = data["placeFrame"]

	local itemMod = self.user.home.itemStash:getItemMod(self.toolName)

	ServerMod:FireClient(self.user.player, "newSoundMod", {
		soundClass = "ItemPlacement2",
		volume = 0.5,
	})

	local toolClass = self.toolClass

	local race = self.race

	if race == "pet" then
		local petData = {
			petClass = toolClass,
			firstFrame = placeFrame,
		}
		for k, v in pairs(itemMod) do
			petData[k] = v
		end
		self.user.home.petManager:addPet(petData)

		self.user.home.itemStash:removeItemMod({
			itemName = self.toolName,
		})
	elseif race == "egg" then
		local eggData = {
			eggClass = toolClass,
			firstFrame = placeFrame,
		}
		for k, v in pairs(itemMod) do
			eggData[k] = v
		end

		self.user.home.eggManager:addEgg(eggData)

		local count = itemMod["count"]
		if count > 1 then
			self.user.home.itemStash:updateItemCount({
				itemName = self.toolName,
				count = -1,
			})
		else
			self.user.home.itemStash:removeItemMod({
				itemName = self.toolName,
			})
			self:destroy()
		end
	else
		warn("UNKNOWN RACE TO ACTIVATE: ", self.race)
	end
end

function StashTool:destroy()
	if self.destroyed then
		return
	end

	BaseTool.destroy(self)

	self:removePetRig()
	self:removeEggModel()

	self.user.home.toolManager:removeStashTool({
		toolName = self.toolName,
	})
end

return StashTool
