local ServerMod = require(game.ServerScriptService.ServerMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local BaseTool = require(game.ServerScriptService.Tools.BaseTool)

local PetInfo = require(game.ReplicatedStorage.PetInfo)
local ItemInfo = require(game.ReplicatedStorage.ItemInfo)
local MutationInfo = require(game.ReplicatedStorage.MutationInfo)

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
	local itemStats = ItemInfo:getMeta(itemClass, true) or PetInfo:getMeta(itemClass, true)

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

function StashTool:onEquip()
	BaseTool.onEquip(self)

	self:addPetRig()

	-- print("EQUIPPING STASH TOOL: ", self.toolName)
end

function StashTool:onUnequip()
	BaseTool.onUnequip(self)

	self:destroy()
end

function StashTool:onActivate() end

function StashTool:checkPetPlacementValid(data)
	local inputPlaceFrame = data["placeFrame"]

	local floorPart = self.user.home.plotManager.floorPart

	local maxPetCount = self.user.home.plotManager:getMaxPetCount()

	if len(self.user.home.petManager.pets) >= maxPetCount then
		self.user:notifyError("Cannot place more than " .. maxPetCount .. " brainrots")
		return false
	end

	local whiteList = {
		floorPart,
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

function StashTool:checkPlacementValid(data)
	local race = self.race
	if race == "pet" then
		return self:checkPetPlacementValid(data)
	end
end

function StashTool:confirmPlacement(petSpot)
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
		}
		for k, v in pairs(itemMod) do
			petData[k] = v
		end

		self.user.home.petManager:occupyPetSpot(petSpot, petData)

		self.user.home.itemStash:removeItemMod({
			itemName = self.toolName,
		})
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

	self.user.home.toolManager:removeStashTool({
		toolName = self.toolName,
	})
end

return StashTool
