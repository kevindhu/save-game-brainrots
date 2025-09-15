local debris = game:GetService("Debris")

local localPlayer = game.Players.LocalPlayer
local playerScripts = localPlayer.PlayerScripts
local playerGui = localPlayer.PlayerGui

local ClientMod = require(playerScripts.ClientMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local User = {}
User.__index = User

function User.new(data)
	local u = {}
	u.data = data

	u.baseWalkspeed = 16

	u.strength = 0

	setmetatable(u, User)
	return u
end

function User:init()
	local data = self.data
	for k, v in pairs(data) do
		self[k] = v
	end

	local player = self.player
	self.userId = player.UserId

	self:addRigCons()

	self:refreshCamera()

	routine(function()
		if self:isPlayerUser() then
			self:initGroupRank()
			-- make the server user
			ClientMod:FireServer("makeUser")
		end
	end)
end

function User:toggleInvertedControls(data)
	local newBool = data["newBool"]

	if not self:isPlayerUser() then
		return
	end

	local playerModule = require(playerScripts:WaitForChild("PlayerModule"))
	local movementController = playerModule:GetControls()

	if newBool then
		movementController.moveFunction = function(player, direction, relative)
			self.player.Move(player, -direction, relative)
		end
	else
		movementController.moveFunction = function(player, direction, relative)
			self.player.Move(player, direction, relative)
		end
	end
end

function User:toggleStone(data)
	local newBool = data["newBool"]

	local rig = self.rig
	if not rig then
		return
	end

	if newBool then
		ClientMod.soundManager:newSoundMod({
			soundClass = "StoneTransform",
			pos = self.currFrame.Position,
			volume = 1,
		})

		self:toggleRigAnchored(true)
		self:toggleRigVisibility(false)
		self:addStoneRig()
	else
		self:removeStoneRig()
		self:toggleRigAnchored(false)
		self:toggleRigVisibility(true)
	end
end

function User:toggleIce(data)
	local newBool = data["newBool"]

	local rig = self.rig
	if not rig then
		return
	end

	if newBool then
		self:addIce()
		self:toggleRigAnchored(true)
		-- self:toggleRigVisibility(false)
	else
		self:removeIce()
		self:toggleRigAnchored(false)
		-- self:toggleRigVisibility(true)
	end
end

function User:addIce()
	if self.iceModel then
		return
	end

	self.iceModel = ClientMod.spellManager:addAnimatedEmitter({
		spellClass = "Aokiji/IceBlock",
		emitterMod = {
			timer = 5,
		},
		scale = 1,
		frame = self.rig.Torso.CFrame,
		-- baseColor = Color3.fromRGB(255, 255, 255),
	})
	self.iceModel.TopPart.Transparency = 0.8
end

function User:removeIce()
	if not self.iceModel then
		return
	end
	self.iceModel:destroy()
	self.iceModel = nil
end

function User:toggleRigAnchored(newBool)
	-- if not self:isPlayerUser() then
	-- 	return
	-- end

	local rig = self.rig
	if not rig then
		return
	end
	for _, child in pairs(rig:GetDescendants()) do
		if child.Name == "HumanoidRootPart" then
			continue
		end
		if child:IsA("BasePart") then
			child.Anchored = newBool
		end
	end
end

function User:toggleRigVisibility(newBool)
	local rig = self.rig
	if not rig then
		return
	end
	for _, child in pairs(rig:GetDescendants()) do
		if child:IsA("Decal") then
			child.Transparency = newBool and 0 or 1
		end
		if child:IsA("BasePart") then
			if child.Name == "HumanoidRootPart" then
				continue
			end
			child.Transparency = newBool and 0 or 1
		end
	end
end

function User:toggleControls(data)
	local newBool = data["toggle"]

	if newBool then
		-- print("TOGGLE CONTROLS: ", newBool)
		self.humanoid:MoveTo(self.currFrame.Position)
	end

	ClientMod:toggleControls(newBool)
end

function User:initGroupRank()
	if Common.isStudio then
		return
	end

	local player = self.player

	local role
	local startTime = os.clock()
	local success, err = pcall(function()
		role = player:GetRoleInGroup(Common.groupId)
	end)
	if not success then
		role = "Unknown"
	end

	-- local validRoleList = {
	-- 	"Tester",
	-- 	"Developer",
	-- 	"Asset",
	-- 	"Admin",
	-- 	"Owner",
	-- }
	-- if not Common.listContains(validRoleList, role) then
	-- 	player:Kick("You are not authorized to play on this game.")
	-- end

	-- print("GOT ROLE: ", role, " IN ", os.clock() - startTime, " SECONDS")
end

function User:refreshInvertedCamera()
	local player = self.player
	player.CameraMinZoomDistance = 5
	player.CameraMaxZoomDistance = 5
	wait()
	player.CameraMinZoomDistance = 5
	player.CameraMaxZoomDistance = 10
end

function User:refreshCamera()
	if not self:isPlayerUser() then
		return
	end

	local player = self.player

	player.CameraMinZoomDistance = 14
	player.CameraMaxZoomDistance = 14
	wait()
	player.CameraMinZoomDistance = 0.5
	player.CameraMaxZoomDistance = 40 -- 80
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

-- have to do this on the client for it to work!
function User:toggleRagdoll(data)
	local newBool = data["newBool"]

	local camera = workspace.CurrentCamera

	local rig = self.rig
	if not rig then
		warn("NO RIG FOUND FOR TOGGLE RAGDOLL: ", self.name)
		return
	end
	local humanoid = rig:FindFirstChild("Humanoid")
	if not humanoid then
		warn("NO HUMANOID FOUND FOR TOGGLE RAGDOLL: ", self.name)
		return
	end

	local animateScript = rig:FindFirstChild("Animate")

	if newBool then
		camera.CameraSubject = rig.Head
		humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
		humanoid:ChangeState(Enum.HumanoidStateType.Ragdoll)

		-- Stop animations
		for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
			track:Stop(0)
		end
		animateScript.Disabled = true
	else
		camera.CameraSubject = humanoid
		animateScript.Disabled = false
		humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
		humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	end
end

function User:updateStrength(data)
	local totalStrength = data["totalStrength"]
	self.totalStrength = totalStrength

	ClientMod.currManager:updateItemMod({
		itemClass = "Strength",
		count = totalStrength,
	})
end

function User:updateWalkspeed(data)
	local newWalkspeed = data["newWalkspeed"]
	self.baseWalkspeed = newWalkspeed

	-- print("GOT NEW WALKSPEED FROM SERVER: ", newWalkspeed)
end

function User:refreshWalkspeed()
	if not self:isPlayerUser() then
		warn("NOT PLAYER USER CANNOT REFRESH WALKSPEED: ", self.name)
		return
	end

	local humanoid = self.humanoid
	if not humanoid then
		return
	end

	humanoid.WalkSpeed = self.baseWalkspeed
end

function User:respawn(rig)
	local rootPart = rig:WaitForChild("HumanoidRootPart", 10)
	local humanoid = rig:WaitForChild("Humanoid", 10)

	self.rootPart = rootPart
	self.humanoid = humanoid
	self.rig = rig

	if not rootPart or not humanoid then
		warn("!!! NO ROOT PART OR HUMANOID FOUND FOR RESPAWN: ", self.name)
		return
	end

	self:addPullArrow()

	self.runningSpeed = 0
	humanoid.Running:Connect(function(speed)
		self.runningSpeed = speed
	end)

	if not self:isPlayerUser() then
		local prompt = ClientMod.uiManager:createPrompt({
			actionText = "Gift",
			objectText = nil,
			name = "UserGiftPrompt",
			holdDuration = 1.5,
			enabled = false,
			maxActivationDistance = 20,
			parent = rootPart,
		})

		self.giftPrompt = prompt

		prompt.Triggered:Connect(function()
			ClientMod:FireServer("tryStartTrade", {
				userName = self.name,
			})
		end)
	end

	humanoid.Died:Connect(function()
		-- print("HUMANOID DIED: ", self.name)
		if self:isPlayerUser() then
			ClientMod:FireServer("userDied")
		end
	end)

	self.currFrame = rootPart.CFrame

	-- clear trackMods for animUtils
	self.trackMods = nil
	self.raceTrackMods = nil
	self.animationGroupIndexMap = nil

	if self:isPlayerUser() then
		-- ClientMod.dashManager:initBodyMovers(self)
		-- ClientMod.swimManager:initBodyMovers(self)
	end

	routine(function()
		wait(5)
		-- self:doTestCheat()
		-- self:doTestWalkSpeedCheat()
	end)
end

function User:doTestWalkSpeedCheat()
	print("DOING TEST WALKSPEED CHEAT")
	local humanoid = self.humanoid
	if not humanoid then
		return
	end

	for i = 1, 10000 do
		humanoid.WalkSpeed = 200
		wait()
	end
end

function User:doTestCheat()
	local rootPart = self.rootPart

	print("SIMULATING TELEPORT CHEATING")

	-- simulate teleport cheating
	for i = 1, 50000 do
		local pos = Vector3.new(-1653.59, 40.098, 1028.606)
		rootPart.CFrame = CFrame.new(pos)
		wait()
	end
end

function User:addPullArrow()
	if not self:isPlayerUser() then
		return
	end

	if self.pullArrow then
		self.pullArrow:Destroy()
		self.pullArrow = nil
	end

	if not ClientMod.plotManager.obtainAttachment then
		return
	end

	local rigAttachment = Instance.new("Attachment")
	rigAttachment.Parent = self.rig.Torso

	local pullArrow = game.Workspace:WaitForChild("PullArrowModel"):WaitForChild("Beam"):Clone()
	pullArrow.Parent = game.Workspace.HitBoxes
	self.pullArrow = pullArrow

	pullArrow.Attachment1 = rigAttachment
	pullArrow.Attachment0 = ClientMod.plotManager.obtainAttachment

	pullArrow.Enabled = false
end

function User:togglePullArrow(newBool)
	if not self.pullArrow then
		return
	end

	self.pullArrow.Enabled = newBool
end

function User:toggleGiftPrompt(newBool)
	if self:isPlayerUser() then
		return
	end
	if not self.giftPrompt then
		return
	end

	self.giftPrompt.Enabled = newBool
end

function User:animateJump()
	local rootPart = self.rootPart
	if not rootPart then
		return
	end

	local emitterModel = ClientMod.spellUtils:createEmitterModel({
		spellClass = "DashDust",
	})
	emitterModel.PrimaryPart.Transparency = 1
	emitterModel:PivotTo(CFrame.new(rootPart.Position - Vector3.new(0, 2, 0)))
	debris:AddItem(emitterModel, 4)

	local scale = 1.5 -- 1 (orig) -- 0.5
	ClientMod.spellUtils:shootEmitter({
		emitterModel = emitterModel,
		scale = scale,
	})

	ClientMod.animUtils:animate(self, {
		race = "DoubleJump",
		animationClass = "DoubleJump",
	})
end

function User:animateDash(sideClass)
	if sideClass == "Front" then
		ClientMod.animUtils:animate(self, {
			race = "Dash",
			animationGroupClass = "Dash",
		})
		return
	end

	ClientMod.animUtils:animate(self, {
		race = "Dash",
		animationClass = "Dash" .. sideClass,
	})
end

function User:tick(timeRatio)
	self:tickCurrFrame(timeRatio)
	self:tickWalkSpeed()
	self:tickCheckCheatWalkSpeed()

	-- self:tickTestFireworks()
end

function User:tickTestFireworks()
	if not self:isPlayerUser() then
		return
	end

	if self.fireworksExpiree and self.fireworksExpiree > ClientMod.step then
		return
	end
	self.fireworksExpiree = ClientMod.step + 60 * 2

	ClientMod.fireworksManager:shootFireworkSequence(self.currFrame)
end

function User:tickWalkSpeed()
	local humanoid = self.humanoid
	if not humanoid then
		return
	end

	local baseWalkspeed = self.baseWalkspeed
	humanoid.WalkSpeed = baseWalkspeed
end

function User:tickCheckCheatWalkSpeed()
	if not self:isPlayerUser() then
		return
	end

	if self.checkWalkSpeedExpiree and self.checkWalkSpeedExpiree > ClientMod.step then
		return
	end
	self.checkWalkSpeedExpiree = ClientMod.step + 60 * 0.5

	local humanoid = self.humanoid
	if not humanoid then
		return
	end
	ClientMod:FireServer("updateWalkSpeed", {
		walkSpeed = humanoid.WalkSpeed,
	})
end

function User:isPlayerUser()
	return self.name == localPlayer.Name
end

function User:tickCurrFrame(timeRatio)
	local rootPart = self.rootPart
	if not rootPart then
		return
	end

	local newCurrFrame = rootPart.CFrame

	self.currFrame = newCurrFrame
end

-- only works if isPlayerUser
function User:finishInit()
	self.initialized = true
end

function User:destroy()
	if self.destroyed then
		return
	end
	self.destroyed = true

	ClientMod.users[self.name] = nil
end

return User
