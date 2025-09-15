local player = game.Players.LocalPlayer
local playerScripts = player.PlayerScripts
local playerGui = player:WaitForChild("PlayerGui")

local ClientMod = require(playerScripts.ClientMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local ViewportModel = require(playerScripts.ViewportModelLocal)

-- local buttonGUI = playerGui:WaitForChild("ButtonGUI")

-- local ItemInfo = require(game.ReplicatedStorage.ItemInfo)
local ToolInfo = require(game.ReplicatedStorage.ToolInfo)
local PetInfo = require(game.ReplicatedStorage.PetInfo)

local VPManager = {
	spinVPMods = {},
}
VPManager.__index = VPManager

function VPManager:init() end

function VPManager:newToolMod(toolClass)
	local vpFrame = Instance.new("ViewportFrame")

	local vpData = {
		vpFrame = vpFrame,
		toolClass = toolClass,
		-- angle = 15,
	}
	local vpMod = self:initToolVPFrame(vpFrame, vpData)

	local model = Instance.new("Model")
	model.Name = toolClass .. "--DISPLAY"
	model.Parent = game.ReplicatedStorage.DisplayModels

	local vpModel = vpMod["model"]
	local camera = vpMod["camera"]

	camera.Parent = model
	camera.Name = "ThumbnailCamera"
	vpModel.Parent = model
end

function VPManager:initToolVPFrame(vpFrame, data)
	local toolClass = data["toolClass"]

	-- Clear existing children
	vpFrame:ClearAllChildren()
	vpFrame.BackgroundTransparency = 1

	-- Setup camera
	local camera = Instance.new("Camera")
	camera.FieldOfView = data.cameraFOV or 70
	camera.Parent = vpFrame

	-- Setup model
	local baseModel = game.ReplicatedStorage.ToolModels:FindFirstChild(toolClass)
	if not baseModel then
		warn("!!! NO VP BASE MODEL FOUND FOR: ", toolClass)
		return
	end

	local worldModel = Instance.new("WorldModel")
	worldModel.Parent = vpFrame

	local model = baseModel:Clone()

	local decorModel = model:FindFirstChild("DecorModel")
	if decorModel then
		local toolStats = ToolInfo:getMeta(toolClass)

		if toolStats["invisibleHandle"] then
			-- make handle transparent
			local handle = model:FindFirstChild("Handle")
			handle.Transparency = 1

			-- remove decal
			if handle:FindFirstChild("Decal") then
				handle.Decal:Destroy()
			end
		end
	end

	model:PivotTo(CFrame.new())

	model.Parent = worldModel

	vpFrame.CurrentCamera = camera

	-- Setup viewport model
	local vpfModel = ViewportModel.new(vpFrame, camera)
	local modelFrame, size = model:GetBoundingBox()

	vpfModel:SetModel(model)
	vpfModel:Calibrate()

	local distance = vpfModel:GetFitDistance(modelFrame.Position) * 0.9

	local orientation = CFrame.fromEulerAnglesYXZ(math.rad(0), math.rad(90), math.rad(-30))
	local cameraFrame = CFrame.new(modelFrame.Position) * orientation * CFrame.new(0, 0, distance)
	cameraFrame = cameraFrame * CFrame.new(-0.04, 0, 0)
	camera.CFrame = cameraFrame

	return {
		vpFrame = vpFrame,
		model = model,
		camera = camera,

		distance = distance,
		modelPos = modelFrame.Position,
	}
end

function VPManager:setupVPFrame(vpFrame)
	local worldModel = vpFrame:FindFirstChild("WorldModel")
	-- create new WorldModel if not found
	if not worldModel then
		worldModel = Instance.new("WorldModel")
		worldModel.Parent = vpFrame
	end

	-- remove all children in WorldModel
	for _, child in ipairs(worldModel:GetChildren()) do
		child:Destroy()
	end

	-- create new CurrentCamera if not found
	local camera = vpFrame:FindFirstChild("CurrentCamera")
	if not camera then
		camera = Instance.new("Camera")
		camera.Name = "CurrentCamera"
		camera.Parent = vpFrame
	end
	camera.FieldOfView = 50

	vpFrame.CurrentCamera = camera

	return camera, worldModel
end

function VPManager:addPetRigIcon(data)
	local vpFrame = data["vpFrame"]
	local petClass = data["petClass"]
	local noAnimate = data["noAnimate"]
	local mutationClass = data["mutationClass"]
	local distanceRatio = data["distanceRatio"] or 1

	local camera, worldModel = self:setupVPFrame(vpFrame)

	local baseRig = game.ReplicatedStorage.Assets[petClass]
	if not baseRig.PrimaryPart then
		baseRig.PrimaryPart = baseRig:FindFirstChild("HumanoidRootPart")
	end

	local rig = baseRig:Clone()
	rig.Parent = worldModel

	local humanoidRootPart = rig:FindFirstChild("HumanoidRootPart")
	if humanoidRootPart then
		humanoidRootPart:Destroy()
	end

	local armsHoldPart = rig:FindFirstChild("ArmsHoldPart")
	if armsHoldPart then
		armsHoldPart:Destroy()
	end

	local vpfModel = ViewportModel.new(vpFrame, camera)
	local modelFrame, size = rig:GetBoundingBox()

	vpfModel:SetModel(rig)
	vpfModel:Calibrate()

	local animationId = PetInfo.runningAnimationMap[petClass]
	if data["useIdleAnimation"] then
		animationId = PetInfo.idleAnimationMap[petClass]
	end

	local rigEntity = {
		rig = rig,
	}
	local trackMod = ClientMod.animUtils:animate(rigEntity, {
		race = "Movement",
		animationId = animationId,
	})

	if mutationClass then
		local entity = {
			petClass = petClass,
		}
		ClientMod.mutationManager:addMutationToRig(entity, rig, mutationClass)
	end

	routine(function()
		wait(0.2)
		if not noAnimate then
			return
		end
		trackMod["track"]:Stop()
	end)

	local distance = vpfModel:GetFitDistance(modelFrame.Position) * 0.95 * distanceRatio

	local offset = 36 -- 30
	local orientation = CFrame.fromEulerAnglesYXZ(math.rad(0), math.rad(180 + offset), math.rad(0))
	local cameraFrame = CFrame.new(modelFrame.Position) * orientation * CFrame.new(0, 0, distance)
	camera.CFrame = cameraFrame

	return {
		vpFrame = vpFrame,
		rig = rig,
		camera = camera,
	}
end

function VPManager:addFoodModelIcon(data)
	local vpFrame = data["vpFrame"]
	local foodClass = data["foodClass"]

	local camera, worldModel = self:setupVPFrame(vpFrame)

	local baseModel = game.ReplicatedStorage.Assets[foodClass]
	if not baseModel.PrimaryPart then
		baseModel.PrimaryPart = baseModel:FindFirstChild("CollidePart")
	end

	local model = baseModel:Clone()
	model.Parent = worldModel

	local collidePart = model:FindFirstChild("CollidePart")
	if collidePart then
		-- collidePart.Transparency = 1
		collidePart:Destroy()
	end

	local vpfModel = ViewportModel.new(vpFrame, camera)
	local modelFrame, size = model:GetBoundingBox()

	vpfModel:SetModel(model)
	vpfModel:Calibrate()

	local distance = vpfModel:GetFitDistance(modelFrame.Position) * 0.8

	local offset = 36 -- 30
	local orientation = CFrame.fromEulerAnglesYXZ(math.rad(0), math.rad(180 + offset), math.rad(0))

	local modelPos = modelFrame.Position
	local cameraFrame = CFrame.new(modelPos) * orientation * CFrame.new(0, 0, distance)

	cameraFrame = CFrame.new(cameraFrame.Position + Vector3.new(0, 3, 0), modelPos)

	camera.CFrame = cameraFrame

	return {
		vpFrame = vpFrame,
		model = model,
		camera = camera,

		race = "food",

		distance = distance,
		modelPos = modelFrame.Position,
	}
end

function VPManager:addSpinVPMod(manager, vpMod)
	local vpFrame = vpMod["vpFrame"]

	local spinName = "SPIN_" .. Common.getGUID()

	local spinMod = {
		vpFrame = vpFrame,
		manager = manager,
		vpMod = vpMod,
		angle = 0,
	}
	self.spinVPMods[spinName] = spinMod
end

function VPManager:tickRender(timeRatio)
	self:tickSpinVPMods(timeRatio)
end

local BASE_SPIN_SPEED = 0.7 -- 1

function VPManager:tickSpinVPMods(timeRatio)
	for spinName, spinMod in pairs(self.spinVPMods) do
		if not spinMod["manager"].toggled then
			continue
		end

		local vpFrame = spinMod["vpFrame"]
		if not vpFrame or not vpFrame:IsDescendantOf(playerGui) then
			-- remove the spinMod
			self.spinVPMods[spinName] = nil
			continue
		end

		local vpMod = spinMod["vpMod"]
		local newAngle = spinMod["angle"] + BASE_SPIN_SPEED * timeRatio
		local race = vpMod["race"]

		spinMod["angle"] = newAngle

		local offset = 36 -- 30
		local orientation = CFrame.Angles(0, math.rad(180 + offset + newAngle), 0)

		local modelPos = vpMod["modelPos"]
		local distance = vpMod["distance"]
		local camera = vpMod["camera"]

		local hOffset = 3.5 -- 4
		-- if race == "building" then
		-- 	hOffset = 5
		-- end

		local cameraFrame = CFrame.new(modelPos) * orientation * CFrame.new(0, 0, distance)
		cameraFrame = CFrame.new(cameraFrame.Position + Vector3.new(0, hOffset, 0), modelPos)

		camera.CFrame = cameraFrame
	end
end

VPManager:init()

return VPManager
