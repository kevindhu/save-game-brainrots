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
			-- make the server user
			ClientMod:FireServer("makeUser")
		end
	end)
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

function User:toggleGiftPrompt(newBool)
	if self:isPlayerUser() then
		return
	end
	if not self.giftPrompt then
		return
	end

	self.giftPrompt.Enabled = newBool
end

function User:tick(timeRatio)
	self:tickCurrFrame(timeRatio)
	self:tickWalkSpeed()
	self:tickCheckCheatWalkSpeed()
end

function User:tickWalkSpeed()
	local humanoid = self.humanoid
	if not humanoid then
		return
	end

	local baseWalkspeed = self.baseWalkspeed
	humanoid.WalkSpeed = baseWalkspeed
end

function User:updateWalkspeed(data)
	local newWalkspeed = data["newWalkspeed"]
	self.baseWalkspeed = newWalkspeed

	-- print("UPDATING WALKSPEED: ", newWalkspeed)
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
	ClientMod:FireServer("updateWalkspeed", {
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
