local PolicyService = game:GetService("PolicyService")

local ServerMod = require(game.ServerScriptService.ServerMod)
local Store = require(game.ServerScriptService.Store)
local Home = require(game.ServerScriptService.Home)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

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
			self.home.badgeManager:addBadge("Join")
		end)

		self:syncAllGlobalMods()

		self.home.analyticsManager:logFunnelStepEvent("UserSession", 1, "Joined", {})
	end)
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

function User:newNotifyMod(data)
	ServerMod:FireClient(self.player, "addNotify", data)
end

function User:notifySuccess(txt, duration, soundClass)
	local data = {
		txt = txt,
		notifyClass = "Success",
		duration = duration,
		soundClass = soundClass,
	}
	ServerMod:FireClient(self.player, "addNotify", data)
end

function User:notifyError(txt, duration, soundClass)
	local data = {
		txt = txt,
		notifyClass = "Error",
		duration = duration,
		soundClass = soundClass,
	}
	ServerMod:FireClient(self.player, "addNotify", data)
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

	-- add rope attachment
	local ropeAttachment = Instance.new("Attachment")
	local torso = rig:FindFirstChild("Torso")
	ropeAttachment.Name = "RopeAttachment"
	ropeAttachment.Parent = torso

	local floorPart = self.home.plotManager.floorPart

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

	local toolManager = self.home.toolManager
	local starterToolClasses = {
		"Bat1",
	}
	for _, toolClass in pairs(starterToolClasses) do
		toolManager:newTool({
			toolClass = toolClass,
		})
	end
end

local FLING_COOLDOWN = 0.5

function User:flingRig(dir, force, ragdollTimer)
	if self.notFlingable then
		return
	end
	if self.ragdolled then
		warn("ALREADY RAGDOLLLED, NOT FLINGING: ", self.name)
		return
	end

	self.home.plotManager:clearWeldedStealUnit()

	if self.flingExpiree and self.flingExpiree > ServerMod.step then
		return
	end
	self.flingExpiree = ServerMod.step + 60 * FLING_COOLDOWN

	local rootPart = self.rootPart
	if not rootPart then
		return
	end

	ServerMod.ragdollManager:toggleRagdoll(self, true)

	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.P = 100000
	bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)

	self.humanoid.PlatformStand = true
	self.humanoid.JumpPower = 0

	if not force then
		force = 100
	end

	dir = dir.Unit
	bodyVelocity.Velocity = dir * force
	bodyVelocity.Parent = rootPart

	-- Create AngularVelocity instead of BodyGyro
	local angularVelocity = Instance.new("BodyAngularVelocity")
	angularVelocity.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
	angularVelocity.P = 100000
	angularVelocity.Parent = rootPart

	-- Set random angular velocity for spinning effect
	local angularDir = Vector3.new(math.random(-20, 20), math.random(-20, 20), math.random(-20, 20))
	if angularDir.Magnitude > 0 then
		angularDir = angularDir.Unit
	else
		angularDir = Vector3.new(1, 0, 0)
	end
	angularVelocity.AngularVelocity = angularDir * 40

	self.humanoid:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, true)

	if not ragdollTimer then
		ragdollTimer = 1.8 -- 2
	end

	local humanoid = self.humanoid

	routine(function()
		wait(0.2)
		bodyVelocity.MaxForce = Vector3.new(0, 0, 0)

		bodyVelocity:Destroy()
		angularVelocity:Destroy()

		wait(ragdollTimer)

		if self.humanoid ~= humanoid then
			return
		end

		self.humanoid.PlatformStand = false
		self.humanoid.JumpPower = 50

		wait(0.5)
		ServerMod.ragdollManager:toggleRagdoll(self, false)
	end)
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

	ServerMod.ragdollManager:ragdollRig(self.rig, true)

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
	local newWalkspeed = 50 -- 42 -- 30

	-- finally add the multiplier at the end, so it stacks
	if self.home.shopManager:checkOwnsGamepass("VIP") then
		newWalkspeed = newWalkspeed * 1.2
	end

	return newWalkspeed
end

function User:refreshWalkspeed()
	local humanoid = self.humanoid
	if not humanoid then
		return
	end

	local newWalkspeed = self:getWalkspeed()
	humanoid.WalkSpeed = newWalkspeed

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

	local home = Home.new(self)
	home:init()
	self.home = home

	self.home:initAllModules()

	-- finish initing all modules, can toggle saving
	self.store:toggleSave(true)

	return true
end

function User:tick(timeRatio)
	if not self.initialized then
		return
	end
	if self.destroying or self.destroyed then
		return
	end

	self:tickCurrFrame()
	self:tickForceWalk()

	local home = self.home
	if home then
		home:tick(timeRatio)
	end
end

function User:kick(reason)
	if self.kicked then
		return
	end
	self.kicked = true

	warn("KICKING: ", self.name, reason)

	self.player:Kick(reason)
end

function User:addForceWalk(goalPos, timer)
	self.forceWalkPos = goalPos
	self.forceWalkExpiree = ServerMod.step + 60 * timer
end

function User:tickForceWalk()
	if not self.forceWalkExpiree or self.forceWalkExpiree < ServerMod.step then
		return
	end

	local humanoid = self.humanoid
	if not humanoid then
		return
	end
	humanoid:MoveTo(self.forceWalkPos)
end

function User:sync(otherUser)
	local data = {
		name = self.name,
		player = self.player,
	}
	ServerMod:FireClient(otherUser.player, "addUser", data)

	local home = self.home
	home:sync(otherUser)
end

function User:syncAllGlobalMods()
	if self.destroyed then
		return
	end
	self:sync(self)

	for _, otherUser in pairs(ServerMod.users) do
		if otherUser == self or not otherUser.initialized or otherUser.destroyed then
			continue
		end
		otherUser:sync(self)
		self:sync(otherUser)
	end

	for _, leader in pairs(ServerMod.leaders) do
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
		for _, otherUser in pairs(ServerMod.users) do
			if otherUser == self or not otherUser.initialized or otherUser.destroyed then
				continue
			end
			otherUser:sync(self)
			self:sync(otherUser)
		end
	end)
end

function User:saveAll()
	local home = self.home
	if home then
		home:saveState()
	end
end

function User:destroyAllModules()
	local store = self.store
	if store then
		store:release()
	end

	local home = self.home
	if home then
		home:destroy()
	end
end

function User:desyncModules()
	for _, otherUser in pairs(ServerMod.users) do
		local data = {
			name = self.name,
		}
		ServerMod:FireClient(otherUser.player, "removeUser", data)

		if not otherUser.initialized then
			continue
		end
		otherUser.home.friendManager:refreshFriendCount()
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
		self:saveAll()

		self.destroying = true
		self:destroyAllModules()

		if not Common.isStudio then
			ServerMod.users[self.name] = nil
		end
	end)
end

return User
