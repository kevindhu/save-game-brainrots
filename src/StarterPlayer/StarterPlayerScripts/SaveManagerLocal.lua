local UserInputService = game:GetService("UserInputService")

local player = game.Players.LocalPlayer
local playerScripts = player.PlayerScripts
local playerGui = player.PlayerGui

local ClientMod = require(playerScripts.ClientMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local buttonGUI = playerGui:WaitForChild("ButtonGUI")

local PetInfo = require(game.ReplicatedStorage.PetInfo)

local SaveManager = {
	waveMods = {},

	saveSizeOffset = 0,
}
SaveManager.__index = SaveManager

function SaveManager:init()
	self:addCons()
end

function SaveManager:addCons() end

function SaveManager:updateWaveModData(data)
	local waveName = data["waveName"]
	local chosenWaveMod = nil
	for _, waveMod in pairs(self.waveMods) do
		if waveMod["waveName"] == waveName then
			chosenWaveMod = waveMod
			break
		end
	end
	if not chosenWaveMod then
		warn("!!! NO WAVE MOD FOUND TO UPDATE DATA: ", waveName)
		return
	end

	chosenWaveMod["killedUnitCount"] = data["killedUnitCount"]
	chosenWaveMod["totalUnitCount"] = data["totalUnitCount"]

	self:refreshBB(chosenWaveMod)

	-- print("UPDATED WAVE MOD DATA: ", waveName, chosenWaveMod["killedUnitCount"], chosenWaveMod["totalUnitCount"])
end

function SaveManager:refreshBB(waveMod)
	local bb = self.bb
	if not bb then
		warn("!!! NO BB FOUND TO REFRESH: ", waveMod)
		return
	end

	local unitBar = bb.MainFrame.UnitBar

	local progressRatio = waveMod["killedUnitCount"] / waveMod["totalUnitCount"]

	unitBar.CurrProgress.Size = UDim2.fromScale(progressRatio, 1)
	unitBar.Title.Text = string.format("%s/%s", waveMod["killedUnitCount"], waveMod["totalUnitCount"])
end

function SaveManager:addWaveMod(data)
	local waveMod = data["waveMod"]
	local saveBaseFrame = data["saveBaseFrame"]

	local plotName = waveMod["plotName"]

	self:removeWaveMod(plotName)

	self:initPetRig(plotName, waveMod, saveBaseFrame)
	self.waveMods[plotName] = waveMod
end

function SaveManager:removeWaveMod(plotName)
	local waveMod = self.waveMods[plotName]
	if not waveMod then
		-- warn("!!! NO WAVE MOD FOUND TO REMOVE: ", plotName)
		return
	end

	local petEntity = waveMod["petEntity"]
	if petEntity then
		petEntity.rig:Destroy()
		petEntity.outerShell:Destroy()
		waveMod.petEntity = nil
	end

	self.waveMods[waveMod.plotName] = nil
end

function SaveManager:animateHatch(plotName)
	local waveMod = self.waveMods[plotName]
	if not waveMod then
		return
	end

	local petEntity = waveMod["petEntity"]
	if not petEntity then
		warn("!!! NO PET ENTITY FOUND TO ANIMATE HATCH: ", plotName)
		return
	end

	local rig = petEntity.rig

	local pos = rig.PrimaryPart.Position
	local startPos = pos + Vector3.new(0, 1, 0)

	for i = 1, 1 do
		local direction = Common.getRandomFlatDir()

		ClientMod.orbManager:newOrbMod({
			name = "ORB_" .. Common.getGUID(),
			startPos = startPos,
			direction = direction,
			value = 1,
			itemClass = "Coins",
			petClass = petEntity.petClass,
			mutationClass = petEntity.mutationClass,
		})
	end

	if rig then
		rig:Destroy()
	end

	-- ClientMod.tweenManager:createTween({
	-- 	target = rig,
	-- 	timer = 3,
	-- 	easingStyle = "Quad",
	-- 	easingDirection = "Out",
	-- 	goal = {
	-- 		CFrame = rig.PrimaryPart.CFrame * CFrame.new(0, 10, 0),
	-- 	},
	-- })

	-- for _, child in pairs(rig:GetDescendants()) do
	-- 	if child:IsA("BasePart") then
	-- 		ClientMod.tweenManager:createTween({
	-- 			target = child,
	-- 			timer = 0.5,
	-- 			easingStyle = "Linear",
	-- 			easingDirection = "Out",
	-- 			goal = {
	-- 				Transparency = 1,
	-- 			},
	-- 		})
	-- 	elseif child:IsA("Decal") then
	-- 		ClientMod.tweenManager:createTween({
	-- 			target = child,
	-- 			timer = 0.5,
	-- 			easingStyle = "Linear",
	-- 			easingDirection = "Out",
	-- 			goal = {
	-- 				Transparency = 1,
	-- 			},
	-- 		})
	-- 	end
	-- end
end

function SaveManager:initPetRig(plotName, waveMod, saveBaseFrame)
	if self.bb then
		self.bb:Destroy()
		self.bb = nil
	end

	local petData = waveMod["petData"]

	local petClass = petData["petClass"]
	local mutationClass = petData["mutationClass"]

	local baseRig = game.ReplicatedStorage.Assets[petClass]
	if not baseRig.PrimaryPart then
		baseRig.PrimaryPart = baseRig:FindFirstChild("HumanoidRootPart")
	end

	local rig = baseRig:Clone()
	rig.PrimaryPart.Transparency = 1 -- 0.5

	local rootPartMotor = rig.PrimaryPart:FindFirstChild("RootPart")
	if not rootPartMotor then
		local rootPart = rig:FindFirstChild("RootPart") or rig:FindFirstChild("FakeRootPart")
		rootPartMotor = Instance.new("Motor6D")

		rootPartMotor.Part0 = rig.PrimaryPart
		rootPartMotor.Part1 = rootPart
		rootPartMotor.C0 = rig.PrimaryPart.CFrame:inverse() * rootPart.CFrame
		rootPartMotor.C1 = CFrame.new(0, 0, 0)
		rootPartMotor.Name = "RootPart"

		rootPartMotor.Parent = rig.PrimaryPart
	end

	rig.Parent = game.Workspace.PetRigs

	Common.setCollisionGroup(rig, "Pets")

	Common.weldPartsToRig(rig)

	rig:SetAttribute("petName", self.petName)

	PetInfo:refreshPetScale(rig, petData)

	local rootPart = rig:WaitForChild("HumanoidRootPart", 2)
	if not rootPart then
		warn("!! NO ROOT PART FOUND FOR PET: ", self.petName, self.petClass)
	end

	for _, part in pairs(rig:GetDescendants()) do
		if part:IsA("BasePart") and part ~= rootPart then
			part.Anchored = false
			part.CanQuery = true
		end
	end

	local partTextureMap = {}

	for _, child in pairs(rig:GetDescendants()) do
		if child:IsA("BasePart") then
			local textureMod = {}
			textureMod["Color"] = child.Color
			textureMod["Transparency"] = child.Transparency

			if child:IsA("MeshPart") then
				textureMod["TextureID"] = child.TextureID

				local surfaceAppearance = child:FindFirstChildWhichIsA("SurfaceAppearance")
				if surfaceAppearance then
					textureMod["SurfaceAppearance"] = surfaceAppearance:Clone()
				end
			end
			partTextureMap[child] = textureMod
		end
	end

	local outerShell = Instance.new("Model")
	rig.Parent = outerShell

	local fakeHumanoid = Instance.new("Humanoid")
	fakeHumanoid.Parent = outerShell
	fakeHumanoid.EvaluateStateMachine = false

	outerShell:SetAttribute("petName", self.petName)
	outerShell.Parent = game.Workspace.PetRigs

	local hOffset = rootPart.Size.Y * 0.5
	local rigFrame = saveBaseFrame * CFrame.new(0, hOffset, 0)
	rig:SetPrimaryPartCFrame(rigFrame)

	local newPetEntity = {
		name = plotName .. "_WAVE",
		rig = rig,
		outerShell = outerShell,
		partTextureMap = partTextureMap,

		petClass = petClass,
		mutationClass = mutationClass,
	}

	if mutationClass then
		-- print("ADDING MUTATION TO RIG: ", mutationClass, rig)
		ClientMod.mutationManager:addMutationToRig(newPetEntity, rig, mutationClass)
	end

	local trackMod = ClientMod.animUtils:animate(newPetEntity, {
		race = "Idle",
		animationId = PetInfo.idleAnimationMap[petClass],
	})

	waveMod["petEntity"] = newPetEntity

	self:initBB(newPetEntity)
	self:refreshBB(waveMod)

	local finalScale = baseRig:GetScale()

	rig:ScaleTo(finalScale * 0.1)
	ClientMod.tweenManager:createTween({
		target = rig,
		timer = 1,
		easingStyle = "Elastic",
		easingDirection = "Out",
		goal = { Scale = finalScale },
	})
end

function SaveManager:initBB(petEntity)
	local rig = petEntity.rig
	local mutationClass = petEntity.mutationClass
	local petClass = petEntity.petClass

	local petStats = PetInfo:getMeta(petClass)

	local bb = game.ReplicatedStorage.Assets.SaveBBPart.BB:Clone()

	local fakeRootPart = rig:FindFirstChild("RootPart")

	bb.Adornee = fakeRootPart:FindFirstChild("BBAttachment")
	bb.Parent = playerGui

	local rating = petStats["rating"]
	local nameTitle = bb.MainFrame.NameTitle

	local mutationPrefix = ""
	if mutationClass and mutationClass ~= "None" then
		mutationPrefix = mutationClass .. " "
	end
	nameTitle.Text = mutationPrefix .. petStats["alias"]

	local ratingTitle = bb.MainFrame.RatingTitle
	ratingTitle.Text = rating
	ClientMod.ratingManager:applyRatingColor(ratingTitle, rating)

	ClientMod.uiScaleManager:addDistStrokeModsFromBB({
		bb = bb,
		adornee = fakeRootPart,
		baseDistance = 40,
	})

	self.bb = bb
end

function SaveManager:tickRender(timeRatio)
	if not self.bb then
		return
	end
	self.saveSizeOffset = self.saveSizeOffset + timeRatio

	local saveTitle = self.bb.MainFrame.SaveTitle
	saveTitle.UIScale.Scale = 1 + math.sin(self.saveSizeOffset * 0.1) * 0.1
end

SaveManager:init()

return SaveManager
