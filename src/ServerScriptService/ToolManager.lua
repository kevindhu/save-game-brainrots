local ServerMod = require(game.ServerScriptService.ServerMod)

local ToolInfo = require(game.ReplicatedStorage.ToolInfo)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local ToolManager = {}
ToolManager.__index = ToolManager

function ToolManager.new(owner, data)
	local u = {}
	u.owner = owner
	u.data = data

	u.toolMods = {}
	u.stashToolMods = {}
	u.foodToolMods = {}

	u.permanentToolMods = {}

	setmetatable(u, ToolManager)
	return u
end

function ToolManager:init()
	self.user = self.owner.user
	for k, v in pairs(self.data) do
		self[k] = v
	end
end

function ToolManager:tryBuyTool(data)
	local toolClass = data.toolClass

	local toolStats = ToolInfo:getMeta(toolClass)
	local price = toolStats["price"]
	if not price then
		warn("CANNOT FIND PRICE FOR ", toolClass)
		return
	end

	local coinsCount = self.user.home.itemStash:getItemCount({
		itemName = "Coins",
	})
	if coinsCount < price then
		self.user:notifyError("You don't have enough coins to buy this tool")
		return
	end

	if self:checkToolOwned(toolClass) then
		self.user:notifyError("You already own this tool")
		return
	end

	self.user:notifySuccess("You bought the " .. toolStats["alias"] .. "!")
	ServerMod:FireClient(self.user.player, "newSoundMod", {
		soundClass = "CashBuy",
		volume = 0.5,
		-- pos = self.user.humanoid.RootPart.Position,
	})

	self:newTool({
		toolClass = toolClass,
	})
end

function ToolManager:tryEquipBottomMod(data)
	local itemName = data["itemName"]

	local toolClasses = {
		"Hammer",
		"Bat1",
	}
	if Common.listContains(toolClasses, itemName) then
		local chosenToolMod
		for _, toolMod in pairs(self.toolMods) do
			if Common.listContains(toolClasses, toolMod.toolClass) then
				chosenToolMod = toolMod
				break
			end
		end
		chosenToolMod:toggleEquipped()
	else
		local itemMod = self.user.home.itemStash:getItemMod(itemName)
		if not itemMod then
			warn("NO ITEM MOD TO EQUIP: ", itemName)
			return
		end

		local stashToolMod = self.stashToolMods[itemName]
		if stashToolMod then
			-- unequip the tool by destroying it
			stashToolMod:destroy()
		else
			-- create new stash tool
			local toolData = {
				toolName = itemName,
				toolClass = itemMod["itemClass"],
			}
			for k, v in pairs(itemMod) do
				toolData[k] = v
			end

			self:newStashTool(toolData)

			self.user.home.tutManager:updateTutMod({
				targetClass = "EquipFirstPet",
				updateCount = 1,
			})
		end
	end
end

function ToolManager:tick()
	for _, toolMod in pairs(self.stashToolMods) do
		if not toolMod.isTickable then
			continue
		end
		-- print(toolMod.toolClass)
		toolMod:tick()
	end

	for _, toolMod in pairs(self.toolMods) do
		if not toolMod.isTickable then
			continue
		end
		-- print(toolMod.toolClass)
		toolMod:tick()
	end
end

function ToolManager:addPermanentTool(toolClass)
	self.permanentToolMods[toolClass] = {
		buyTimestamp = os.time(),
	}

	self:newTool({
		toolClass = toolClass,
	})
end

function ToolManager:checkToolOwned(toolClass)
	-- see if tool already owned
	for _, child in pairs(self.user.player.Backpack:GetChildren()) do
		if child.Name == toolClass then
			return true
		end
	end

	-- see if tool already equipped
	for _, child in pairs(self.user.player.Character:GetChildren()) do
		if child.Name == toolClass then
			return true
		end
	end

	return false
end

function ToolManager:getEquippedToolMod()
	for _, toolMod in pairs(self.toolMods) do
		if toolMod.equipped then
			return toolMod
		end
	end

	for _, toolMod in pairs(self.stashToolMods) do
		if toolMod.equipped then
			return toolMod
		end
	end
end

function ToolManager:editToolModel(tool)
	local handle = tool:FindFirstChild("Handle")
	handle.Anchored = false
	handle.Massless = true
	handle.CanCollide = false

	handle.Transparency = 1
	for _, child in pairs(handle:GetDescendants()) do
		if child:IsA("Decal") then
			child:Destroy()
		end
	end

	tool.PrimaryPart = handle

	local decorModel = tool:FindFirstChild("DecorModel")
	if decorModel then
		for _, child in pairs(decorModel:GetDescendants()) do
			if child:IsA("BasePart") then
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = child
				weld.Part1 = handle
				weld.Name = "ToolWeld1"
				weld.Parent = child
				child.Anchored = false
				child.Massless = true
				child.CanCollide = false
			end
		end
	end

	return tool
end

function ToolManager:newTool(data)
	local toolClass = data.toolClass

	local tool = game.ReplicatedStorage.ToolModels[toolClass]:Clone()
	self:editToolModel(tool)
	tool.Parent = self.user.player.Backpack

	local toolScriptDirectory = game.ServerScriptService.Tools:FindFirstChild(toolClass)
	if not toolScriptDirectory then
		warn("NO TOOL SCRIPT FOUND FOR ", toolClass)
		toolScriptDirectory = game.ServerScriptService.Tools.BaseTool
	end

	local toolName = "TOOL_" .. Common.getGUID()

	local ToolModule = require(toolScriptDirectory)
	local toolScript = ToolModule.new(self.user, tool, {
		toolName = toolName,
		toolClass = toolClass,
	})
	toolScript:init()

	ServerMod:FireClient(self.user.player, "addTool", {
		tool = tool,
		toolName = toolName,
		toolClass = toolClass,
	})
	self.toolMods[toolName] = toolScript
end

function ToolManager:newStashTool(data)
	local toolName = data["toolName"]
	local toolClass = data["toolClass"]

	-- remove all previous stash tools
	for currToolName, toolMod in pairs(self.stashToolMods) do
		-- toolMod:destroy()
		self:removeStashTool({
			toolName = currToolName,
		})
	end

	local baseTool = game.ReplicatedStorage.ToolModels.BaseStashTool

	local tool = baseTool:Clone()
	self:editToolModel(tool)
	tool.Parent = self.user.player.Backpack

	local ToolModule = require(game.ServerScriptService.Tools.StashTool)

	local toolData = {
		tool = tool,
		toolName = toolName,
		toolClass = toolClass,
	}
	for k, v in pairs(data) do
		toolData[k] = v
	end

	local toolScript = ToolModule.new(self.user, tool, toolData)
	toolScript:init()
	self.stashToolMods[toolName] = toolScript

	ServerMod:FireClient(self.user.player, "addStashTool", toolData)

	routine(function()
		-- this wait is probably necessary or its REALLY STUPID
		wait()
		if not tool or not tool.Parent then
			-- warn("NO TOOL OR PARENT TO EQUIP: ", toolName)
			return
		end

		self.user.humanoid:EquipTool(tool)
	end)

	-- print("EQUIPPED STASH TOOL: ", toolName)
end

function ToolManager:removeStashTool(data)
	local toolName = data["toolName"]
	local toolMod = self.stashToolMods[toolName]

	if not toolMod then
		-- already removed
		-- warn("NO STASH TOOL MOD TO REMOVE: ", toolName)
		return
	end

	toolMod:destroy()
	self.stashToolMods[toolName] = nil
end

function ToolManager:tryPlaceRelicAtPetSpot(data)
	local toolName = data["toolName"]
	local petSpotName = data["petSpotName"]

	local petSpot = self.user.home.petManager.petSpots[petSpotName]
	if not petSpot then
		warn("NO PET SPOT TO PLACE PET AT: ", petSpotName)
		return
	end
	if not petSpot.unlocked then
		self.user:notifyError("This platform is not unlocked")
		return
	end
	if not petSpot.petData then
		self.user:notifyError("This platform is not occupied")
		return
	end
	if len(petSpot.petData["relicMods"]) >= 1 then
		self.user:notifyError("Brainrot already has a relic")
		return
	end

	local toolMod = self.stashToolMods[toolName]
	if not toolMod then
		warn("NO TOOL MOD TO PLACE: ", toolName)
		return
	end

	toolMod:confirmPlacement(petSpot)
end

function ToolManager:tryPlacePetAtPetSpot(data)
	local toolName = data["toolName"]
	local petSpotName = data["petSpotName"]

	local petSpot = self.user.home.petManager.petSpots[petSpotName]
	if not petSpot then
		warn("NO PET SPOT TO PLACE PET AT: ", petSpotName)
		return
	end
	if not petSpot.unlocked then
		self.user:notifyError("This pet spot is not unlocked")
		return
	end
	if not petSpot.initialized then
		self.user:notifyError("Please wait before trying again")
		return
	end

	local toolMod = self.stashToolMods[toolName]
	if not toolMod then
		warn("NO TOOL MOD TO PLACE: ", toolName)
		return
	end

	toolMod:confirmPlacement(petSpot)
end

function ToolManager:saveState()
	local managerData = {
		permanentToolMods = self.permanentToolMods,
	}
	self.user.store:set(self.moduleAlias .. "Info", managerData)
end

return ToolManager
