local Debris = game:GetService("Debris")
local Players = game:GetService("Players")

local ServerMod = require(game.ServerScriptService.ServerMod)

local ToolInfo = require(game.ReplicatedStorage.ToolInfo)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local BaseTool = {}
BaseTool.__index = BaseTool

function BaseTool.new(user, tool, data)
	local self = {}
	self.user = user
	self.tool = tool
	self.data = data

	self.connections = {}

	setmetatable(self, BaseTool)
	return self
end

function BaseTool:init()
	for k, v in pairs(self.data) do
		self[k] = v
	end

	self.tool.CanBeDropped = false

	self:addCons()
end

function BaseTool:toggleEquipped()
	-- print("TOGGLE EQUIPPED: ", self.toolName, self.equipped)

	local tool = self.tool
	local humanoid = self.user.humanoid

	if self.equipped then
		humanoid:UnequipTools()

		-- need this redundancy cause its stupid
		self.equipped = false
	else
		humanoid:EquipTool(tool)
		-- need this redundancy cause its stupid
		self.equipped = true
	end
end

function BaseTool:addCons()
	local tool = self.tool
	local connection = tool.Activated:Connect(function()
		self:onActivate()
	end)
	table.insert(self.connections, connection)

	connection = tool.Equipped:Connect(function()
		self:onEquip()
	end)
	table.insert(self.connections, connection)

	tool.Unequipped:Connect(function()
		-- print("UNEQUIPPED BASE TOOL: ", self.toolName, self.tool.Parent)
		-- if self.tool.Parent then
		-- 	warn("CLASSNAME: ", self.tool.Parent.ClassName)
		-- end

		self:onUnequip()
	end)

	local destroyConnection = tool.Destroying:Connect(function()
		-- print("DESTROYING BASE TOOL: ", self.toolName)
		self:destroy()
	end)

	table.insert(self.connections, destroyConnection)
end

function BaseTool:onActivate()
	-- print("ACTIVATING")
end

function BaseTool:onEquip()
	self.equipped = true

	-- print("EQUIPPED: ", self.toolName, self.equipped)
end

function BaseTool:onUnequip()
	self.equipped = false
end

function BaseTool:createHitPart(frame, size)
	local hitPart = Instance.new("Part")
	hitPart.Color = Color3.fromRGB(255, 0, 0)

	hitPart.CastShadow = false
	hitPart.Size = Vector3.new(size, size, size)
	hitPart.Transparency = 1
	hitPart.CanCollide = false
	hitPart.CanTouch = true
	hitPart.CFrame = frame
	hitPart.Anchored = true
	hitPart.Parent = workspace

	Debris:AddItem(hitPart, 3)

	return hitPart
end

function BaseTool:getHitUsers(hitPart, currentUser)
	local hitUsers = {}
	local touchingParts = workspace:GetPartsInPart(hitPart)

	for _, part in pairs(touchingParts) do
		local player = Players:GetPlayerFromCharacter(part.Parent)
		if not player then
			continue
		end

		local otherUser = ServerMod.users[player.Name]
		if otherUser == currentUser then
			continue
		end

		if otherUser then
			hitUsers[otherUser.name] = otherUser
		end
	end

	return hitUsers
end

function BaseTool:flingHitUsers(hitUsers, hitPosition, hitForce, ragdollTimer)
	for _, otherUser in pairs(hitUsers) do
		local userPos = otherUser.rootPart.Position
		local hitDirection = (userPos - hitPosition)
		hitDirection += Vector3.new(0, 3, 0)

		-- add sound
		ServerMod:FireAllClients("newSoundMod", {
			soundClass = "Punch2",
			volume = 1,
			pos = hitPosition,
		})

		if hitDirection.Magnitude == 0 then
			hitDirection = Vector3.new(0, 0, 0)
		end

		hitDirection = hitDirection.Unit

		otherUser:flingRig(hitDirection, hitForce, ragdollTimer)
	end
end

function BaseTool:destroy()
	if self.destroyed then
		return
	end
	self.destroyed = true

	local tool = self.tool
	if tool then
		tool:Destroy()
	end

	for _, connection in pairs(self.connections) do
		connection:Disconnect()
	end

	self.user.home.toolManager.toolMods[self.toolName] = nil
end

function BaseTool:doBatHit()
	if self.batHitExpiree and self.batHitExpiree > ServerMod.step then
		return
	end
	local batSwingCooldown = self.batSwingCooldown / self.user.home.speedManager:getSpeed()
	self.batHitExpiree = ServerMod.step + 60 * batSwingCooldown

	local rig = self.user.rig
	if not rig or not rig.Parent then
		return
	end

	-- add sound
	ServerMod:FireAllClients("newSoundMod", {
		soundClass = "Whoosh1",
		volume = 0.4,
		pos = rig.HumanoidRootPart.Position,
	})

	local currFrame = self.user.rig.HumanoidRootPart.CFrame

	-- local hitFrame = currFrame * CFrame.new(0, 0, -5)
	-- -- get humanoid move direction
	-- local moveDirection = self.user.humanoid.MoveDirection
	-- hitFrame = hitFrame + moveDirection * self.user.humanoid.WalkSpeed / 3

	-- for testing
	local hitFrame = currFrame

	local hitPart = self:createHitPart(hitFrame, 12) -- 9

	local size = 24 -- 20
	hitPart.Size = Vector3.new(size, size, size)

	hitPart.Transparency = 1 -- 0.5

	local hitUnits = self:getHitUnits(hitPart)

	local damage = self.batDamage
	local bulkDamageMods = {}
	for _, unit in pairs(hitUnits) do
		unit:updateHealth(-damage, self, 0)

		bulkDamageMods[unit.unitName] = {
			damage,
			unit.health,
		}

		self.user.home.damageManager:addDamage(damage)
	end

	ServerMod:FireAllClients("bulkUpdateUnitDamage", {
		bulkDamageMods = bulkDamageMods,
	})

	self.track:Play()
	self.track:AdjustSpeed(self.user.home.speedManager:getSpeed())
end

function isPointInVolume(point: Vector3, volumeCenter: CFrame, volumeSize: Vector3): boolean
	local volumeSpacePoint = volumeCenter:PointToObjectSpace(point)
	return volumeSpacePoint.X >= -volumeSize.X / 2
		and volumeSpacePoint.X <= volumeSize.X / 2
		and volumeSpacePoint.Y >= -volumeSize.Y / 2
		and volumeSpacePoint.Y <= volumeSize.Y / 2
		and volumeSpacePoint.Z >= -volumeSize.Z / 2
		and volumeSpacePoint.Z <= volumeSize.Z / 2
end

function BaseTool:getHitUnits(hitPart)
	local hitUnits = {}
	for _, unit in pairs(self.user.home.unitManager.units) do
		local unitFrame = unit.currFrame
		if isPointInVolume(unitFrame.Position, hitPart.CFrame, hitPart.Size) then
			hitUnits[unit.unitName] = unit
		end
	end

	return hitUnits
end

return BaseTool
