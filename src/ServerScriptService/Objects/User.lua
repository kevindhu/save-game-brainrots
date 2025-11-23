local PolicyService = game:GetService("PolicyService")

local ServerMod = require(game.ServerScriptService.ServerMod)

local Store = require(game.ServerScriptService.Datastore.Store)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local UserConfig = require(game.ServerScriptService.Configs.UserConfig)

local User = {}
User.__index = User

function User.new(player)
	local u = {}
	u.player = player
	u.name = player.Name

	u.respawnTimer = 1

	setmetatable(u, User)
	return u
end

function User:init()
	local player = self.player
	self.userId = player.UserId
	self.displayName = player.DisplayName
	self.user = self

	self:initPlayer()

	self.funnelSessionId = self.userId .. "_" .. Common.getGUID()

	routine(function()
		self:initAllModules()
		self:addRigCons()

		self.initialized = true

		local data = {}
		ServerMod:FireClient(self.player, "finishUserInit", data)

		routine(function()
			self.badgeManager:addBadge("Join")
		end)

		self:syncAllGlobalMods()

		self.analyticsManager:logFunnelStepEvent("UserSession", 1, "Joined", {})
	end)

	routine(function()
		self:initGroupRank()
	end)
end

function User:initGroupRank()
	local player = self.player

	local role
	local success, err = pcall(function()
		role = player:GetRoleInGroup(Common.groupId)
	end)
	if not success then
		role = "Unknown"
	end
	print("INIT GROUP RANK: ", role)

	self.groupRole = role
end

function User:addRigCons()
	local player = self.player

	routine(function()
		local rig = player.Character or player.CharacterAdded:Wait()
		self:respawn(rig)
	end)

	player.CharacterAdded:Connect(function(rig)
		self:respawn(rig)
	end)
end

function User:initPlayer()
	local success, policyMod = pcall(function()
		return PolicyService:GetPolicyInfoForPlayerAsync(self.player)
	end)
	if success then
		self.policyMod = policyMod
	end
end

function User:respawn(rig)
	self.respawnTimestamp = os.time()

	self.dead = false

	self.rig = rig
	rig.Parent = game.Workspace.UserRigs

	local humanoid = self.rig:FindFirstChild("Humanoid")
	self.humanoid = humanoid

	local rootPart = rig:FindFirstChild("HumanoidRootPart")
	self.rootPart = rootPart

	local floorPart = self.plotManager.floorPart

	local xOffset = -20 -- 10
	local spawnFrame = floorPart.CFrame * CFrame.new(xOffset, 10, 0) * CFrame.Angles(0, math.rad(90), 0)

	rootPart:PivotTo(spawnFrame)

	for _, child in pairs(rig:GetDescendants()) do
		if child:IsA("Accessory") then
			for _, child2 in pairs(child:GetDescendants()) do
				if child2:IsA("BasePart") then
					child2.Massless = true
				end
			end
		end
	end

	self:tickCurrFrame()

	self:addHumanoidCons()
	Common.setCollisionGroup(rig, "Players")

	ServerMod.ragdollManager:setupJoints(self.rig)
	ServerMod.ragdollManager:toggleRagdoll(self, false)

	local toolManager = self.toolManager
	local starterToolClasses = {
		"Bat1",
	}
	for _, toolClass in pairs(starterToolClasses) do
		toolManager:newTool({
			toolClass = toolClass,
		})
	end
end

function User:addHumanoidCons()
	local humanoid = self.humanoid
	if not humanoid then
		return
	end

	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	self:refreshWalkspeed()
end

function User:die()
	if self.dead then
		return
	end
	self.dead = true

	self.humanoid.Health = 0

	local timer = self.respawnTimer
	wait(timer)

	self:preventMemoryLeak()
	self.player:LoadCharacter()
end

function User:preventMemoryLeak()
	local player = self.player
	-- prevent memory leak? https://twitter.com/MrChickenRocket/status/1699005062360789405
	if player.Character then
		player.Character:Destroy()
		player.Character = nil
	end
end

function User:getWalkspeed()
	local newWalkspeed = 30 -- 50 (orig for awhile)

	-- finally add the multiplier at the end, so it stacks
	if self.shopManager:checkOwnsGamepass("VIP") then
		newWalkspeed = newWalkspeed * 1.2
	end

	return newWalkspeed
end

function User:tickSecond()
	for _, managerClass in pairs(UserConfig.TICK_SECOND_LIST) do
		local manager = self[managerClass]
		if not manager or not manager.tickSecond then
			warn("NO TICK SECOND FUNCTION FOR MANAGER: ", managerClass)
			continue
		end
		manager:tickSecond()
	end
end

function User:refreshWalkspeed()
	local humanoid = self.humanoid
	if not humanoid then
		return
	end

	local newWalkspeed = self:getWalkspeed()
	humanoid.WalkSpeed = newWalkspeed

	-- print("REFRESHING WALKSPEED: ", newWalkspeed)

	ServerMod:FireClient(self.player, "updateWalkspeed", {
		newWalkspeed = newWalkspeed,
	})
end

function User:tickCurrFrame()
	local rootPart = self.rootPart
	if rootPart then
		local currFrame = rootPart.CFrame
		self.currFrame = currFrame
	end
end

function User:initAllModules()
	if self.destroyed then
		return
	end

	local store = Store.new(self)
	store:init()
	self.store = store

	for _, moduleInfo in ipairs(UserConfig.USERMANAGERS_LIST) do
		self:loadUserManager(moduleInfo[1], moduleInfo[2])
	end

	-- finish initing all usermanagers, can toggle saving
	self.store:toggleSave(true)
end

function User:loadUserManager(moduleName, moduleAlias)
	local store = self.store

	local defaultInfo = {
		isNew = true,
	}
	local managerInfo = store:get(moduleAlias .. "Info") or defaultInfo

	local UserManager = require(game.ServerScriptService.UserManagers[moduleName])

	local userManager = UserManager.new(self, managerInfo)
	userManager.moduleAlias = moduleAlias
	userManager:init()
	self[moduleAlias] = userManager
end

function User:tick(timeRatio)
	if not self.initialized then
		return
	end
	if self.destroying or self.destroyed then
		return
	end

	self:tickCurrFrame()

	for _, managerClass in pairs(UserConfig.TICK_LIST) do
		local manager = self[managerClass]
		if not manager then
			continue
		end
		manager:tick(timeRatio)
	end
end

function User:sync(otherUser)
	local data = {
		name = self.name,
		player = self.player,
	}
	ServerMod:FireClient(otherUser.player, "addUser", data)

	for _, managerClass in pairs(UserConfig.SYNC_LIST) do
		local manager = self[managerClass]
		if not manager then
			continue
		end
		manager:sync(otherUser)
	end
end

function User:syncAllGlobalMods()
	if self.destroyed then
		return
	end
	self:sync(self)

	for _, otherUser in pairs(ServerMod.userManager:getAllUsers()) do
		if otherUser == self or not otherUser.initialized or otherUser.destroyed then
			continue
		end
		otherUser:sync(self)
		self:sync(otherUser)
	end

	for _, leader in pairs(ServerMod.leaderManager.leaders) do
		leader:sync(self)
	end

	ServerMod.weatherManager:sync(self)
	ServerMod.luckManager:sync(self)
	ServerMod.buyCrateManager:sync(self)

	routine(function()
		wait(3)
		-- retry syncing again just to make sure globalUsers are gotten
		if self.destroyed then
			return
		end

		-- retry syncing with self after waiting
		self:sync(self)

		-- retry syncing with others again after waiting
		for _, otherUser in pairs(ServerMod.userManager:getAllUsers()) do
			if otherUser == self or not otherUser.initialized or otherUser.destroyed then
				continue
			end
			otherUser:sync(self)
			self:sync(otherUser)
		end
	end)
end

function User:saveAllManagers()
	for _, managerClass in pairs(UserConfig.SAVE_LIST) do
		local manager = self[managerClass]
		if not manager or not manager.saveState then
			warn("!!! NO SAVE STATE FUNCTION FOR MANAGER: ", managerClass)
			continue
		end
		manager:saveState()
	end
end

function User:wipeAllModules()
	for _, managerClass in pairs(UserConfig.SAVE_LIST) do
		local manager = self[managerClass]
		if not manager or not manager.wipe then
			warn("NO WIPE FUNCTION FOR MANAGER: ", managerClass)
			continue
		end
		manager:wipe()
	end
end

function User:destroyAllModules()
	local store = self.store
	if store then
		store:release()
	end

	for _, managerClass in pairs(UserConfig.DESTROY_LIST) do
		local manager = self[managerClass]
		if not manager then
			continue
		end
		manager:destroy()
	end
end

function User:desyncModules()
	for _, otherUser in pairs(ServerMod.userManager:getAllUsers()) do
		local data = {
			name = self.name,
		}
		ServerMod:FireClient(otherUser.player, "removeUser", data)

		if not otherUser.initialized then
			continue
		end
		otherUser.friendManager:refreshFriendCount()
	end
end

function User:destroy()
	if self.destroyed then
		warn("ALREADY DESTROYED USER HUH: ", self.name)
		return
	end
	self.destroyed = true

	-- remove the GlobalUser for other users
	self:desyncModules()

	routine(function()
		self:saveAllManagers()
		self:destroyAllModules()
	end)
end

return User
