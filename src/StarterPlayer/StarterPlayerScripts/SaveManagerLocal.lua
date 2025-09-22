local UserInputService = game:GetService("UserInputService")

local player = game.Players.LocalPlayer
local playerScripts = player.PlayerScripts
local playerGui = player.PlayerGui

local ClientMod = require(playerScripts.ClientMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local saveGUI = playerGui:WaitForChild("SaveGUI")
local saveFrame = saveGUI.SaveFrame
local playFrame = saveGUI.PlayFrame

local PetInfo = require(game.ReplicatedStorage.PetInfo)
local RatingInfo = require(game.ReplicatedStorage.RatingInfo)

local SaveManager = {
	waveMods = {},

	saveSizeOffset = 0,
}
SaveManager.__index = SaveManager

function SaveManager:init()
	self:addCons()

	self:toggleSaveFrame(false)
end

function SaveManager:addCons()
	self.templateMainRatingTitle = saveFrame.RatingTitle
	self.templateMainRatingTitle.Visible = false

	local speedButton = playFrame.SpeedButton
	ClientMod.buttonManager:addActivateCons(speedButton, function()
		ClientMod.speedManager:chooseNextSpeedMod()
	end)
	ClientMod.buttonManager:addBasicButtonCons(speedButton)

	local playButton = playFrame.PlayButton
	ClientMod.buttonManager:addActivateCons(playButton, function()
		ClientMod:FireServer("tryTogglePlay", {})
	end)
	ClientMod.buttonManager:addBasicButtonCons(playButton)
end

function SaveManager:updatePlaying(data)
	local playing = data["playing"]
	local playButton = playFrame.PlayButton
	if playing then
		playButton.Title.Text = "STOP"
		playButton.BackgroundColor3 = Color3.fromRGB(211, 70, 70)
		playButton.Icon.Image = "rbxassetid://14219414360"
	else
		playButton.Title.Text = "PLAY"
		playButton.BackgroundColor3 = Color3.fromRGB(43, 226, 88)
		playButton.Icon.Image = "rbxassetid://12099513379"
	end
end

function SaveManager:updateWaveModData(data)
	local waveName = data["waveName"]
	local userName = data["userName"]

	local chosenWaveMod = nil
	for _, waveMod in pairs(self.waveMods) do
		if waveMod["waveName"] == waveName then
			chosenWaveMod = waveMod
			break
		end
	end
	if not chosenWaveMod then
		-- warn("!!! NO WAVE MOD FOUND TO UPDATE DATA: ", waveName)
		return
	end

	chosenWaveMod["killedUnitCount"] = data["killedUnitCount"]
	chosenWaveMod["totalUnitCount"] = data["totalUnitCount"]

	self:refreshBB(chosenWaveMod)

	-- print("UPDATED WAVE MOD DATA: ", waveName, chosenWaveMod["killedUnitCount"], chosenWaveMod["totalUnitCount"])
end

function SaveManager:refreshBB(waveMod)
	local bb = waveMod["bb"]
	if not bb then
		warn("!!! NO BB FOUND TO REFRESH: ", waveMod)
		return
	end

	local unitBar = bb.MainFrame.UnitBar

	local progressRatio = waveMod["killedUnitCount"] / waveMod["totalUnitCount"]

	unitBar.CurrProgress.Size = UDim2.fromScale(progressRatio, 1)
	unitBar.Title.Text = string.format("%s/%s", waveMod["killedUnitCount"], waveMod["totalUnitCount"])

	if waveMod["userName"] == player.Name then
		local mainUnitBar = saveFrame.UnitBar
		mainUnitBar.CurrProgress.Size = UDim2.fromScale(progressRatio, 1)
		mainUnitBar.Title.Text = string.format("%s/%s", waveMod["killedUnitCount"], waveMod["totalUnitCount"])
	end
end

function SaveManager:addWaveMod(data)
	local waveMod = data["waveMod"]
	local saveBaseFrame = data["saveBaseFrame"]

	local userName = waveMod["userName"]

	self:removeWaveMod(userName)

	self:initPetRig(userName, waveMod, saveBaseFrame)

	if userName == player.Name then
		local mainUnitBar = saveFrame.UnitBar
		mainUnitBar.CurrProgress.Size = UDim2.fromScale(0, 1)
		mainUnitBar.Title.Text = string.format("%s/%s", waveMod["killedUnitCount"], waveMod["totalUnitCount"])

		local petData = waveMod["petData"]

		local petClass = petData["petClass"]
		local mutationClass = petData["mutationClass"]

		local petStats = PetInfo:getMeta(petClass)

		local mutationPrefix = ""
		if mutationClass and mutationClass ~= "None" then
			mutationPrefix = mutationClass .. " "
		end

		saveFrame.NameTitle.Text = mutationPrefix .. petStats["alias"]

		saveFrame.Icon.Image = PetInfo:getPetImage(petClass, mutationClass)

		local ratingTitle = self.templateMainRatingTitle:Clone()
		ratingTitle.Visible = true
		ratingTitle.Parent = self.templateMainRatingTitle.Parent

		-- local mainSaveTitle = saveFrame.SaveTitle
		-- mainSaveTitle.Text = "SAVE"
		-- mainSaveTitle.TextColor3 = Color3.fromRGB(255, 32, 36)

		ratingTitle.Text = petStats["rating"]
		ClientMod.ratingManager:applyRatingColor(ratingTitle, petStats["rating"])

		waveMod["ratingTitle"] = ratingTitle

		self:toggleSaveFrame(true)
	end

	waveMod["saveBaseFrame"] = saveBaseFrame

	self.waveMods[userName] = waveMod

	self:refreshSpeedFrame()
end

function SaveManager:failWaveMod(data)
	local userName = data["userName"]
	local unitName = data["unitName"]

	-- print("FAILING WAVE MOD: ", userName, unitName)

	if unitName then
		local unit = ClientMod.units[unitName]
		if unit then
			unit:captureSavePet(data)
		end
	end

	self:removeWaveMod(userName)
end

function SaveManager:removeWaveMod(userName)
	local waveMod = self.waveMods[userName]
	if not waveMod then
		-- warn("!!! NO WAVE MOD FOUND TO REMOVE: ", userName)
		return
	end

	local petEntity = waveMod["petEntity"]

	-- print("DESTROYING PET ENTITY: ", userName, petEntity)

	if petEntity then
		petEntity.rig:Destroy()
		petEntity.outerShell:Destroy()

		waveMod["petEntity"] = nil
	end

	local bb = waveMod["bb"]
	if bb then
		bb:Destroy()
		waveMod["bb"] = nil
	end

	if userName == player.Name then
		self:toggleSaveFrame(false)

		local ratingTitle = waveMod["ratingTitle"]
		if ratingTitle then
			ratingTitle:Destroy()
			waveMod["ratingTitle"] = nil
		end

		self:refreshSpeedFrame()
	end

	self.waveMods[userName] = nil
end

function SaveManager:refreshSpeedFrame()
	local speed = ClientMod.speedManager:getSpeed(player.Name)
	local speedButton = playFrame.SpeedButton

	speedButton.SpeedTitle.Text = speed .. "x"
end

function SaveManager:toggleSaveFrame(newBool)
	saveFrame.Visible = newBool
end

function SaveManager:getWaveMod(userName)
	return self.waveMods[userName]
end

function SaveManager:completeWaveMod(data)
	local pos = data["pos"]
	local petClass = data["petClass"]
	local userName = data["userName"]
	local waveName = data["waveName"]

	local playbackSpeed = Common.randomBetween(0.8, 1)
	ClientMod.soundManager:newSoundMod({
		soundClass = "Pop1",
		volume = 0.2,
		pos = pos,
		playbackSpeed = playbackSpeed,
	})

	local petStats = PetInfo:getMeta(petClass)
	local ratingColor = RatingInfo["ratingColorMap"][petStats["rating"]]

	ClientMod.spellManager:addExplosion({
		spellClass = "WhiteExplosion",
		pos = pos + Vector3.new(0, 3, 0),
		baseColor = ratingColor,
		scale = 0.5, -- 1.5
	})

	local waveMod = self.waveMods[userName]
	if not waveMod or waveMod["hatched"] or waveMod["waveName"] ~= waveName then
		return
	end

	waveMod["hatched"] = true

	local petEntity = waveMod["petEntity"]
	if not petEntity then
		warn("!!! NO PET ENTITY FOUND TO ANIMATE HATCH: ", userName)
		return
	end

	local rig = petEntity.rig
	if not rig or not rig.Parent then
		warn("!!! NO RIG FOUND TO ANIMATE HATCH: ", userName)
		return
	end

	if not rig.PrimaryPart then
		rig.PrimaryPart = rig:FindFirstChild("HumanoidRootPart")

		if not rig.PrimaryPart then
			warn("!!! NO PRIMARY PART FOUND TO ANIMATE HATCH: ", rig, petEntity["petClass"])
			return
		end
	end

	local pos = rig.PrimaryPart.Position
	local startPos = pos + Vector3.new(0, 1, 0)

	for i = 1, 1 do
		local direction = Common.getRandomFlatDir()

		ClientMod.orbManager:newOrbMod({
			userName = userName,
			name = "ORB_" .. Common.getGUID(),
			startPos = startPos,
			direction = direction,
			value = 1,
			itemClass = "Coins",
			petClass = petEntity.petClass,
			mutationClass = petEntity.mutationClass,
		})
	end

	rig:Destroy()
end

function SaveManager:initPetRig(userName, waveMod, saveBaseFrame)
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
		name = userName .. "_WAVE",
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

	self:initBB(waveMod)
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

function SaveManager:initBB(waveMod)
	local petEntity = waveMod["petEntity"]

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

	waveMod["bb"] = bb
end

function SaveManager:tickRender(timeRatio)
	self.saveSizeOffset = self.saveSizeOffset + timeRatio

	for _, waveMod in pairs(self.waveMods) do
		local bb = waveMod["bb"]
		if not bb then
			return
		end

		local saveTitle = bb.MainFrame.SaveTitle
		saveTitle.UIScale.Scale = 1 + math.sin(self.saveSizeOffset * 0.1) * 0.1

		-- local mainSaveTitle = saveFrame.SaveTitle
		-- mainSaveTitle.UIScale.Scale = 1 + math.sin(self.saveSizeOffset * 0.1) * 0.1
	end

	saveFrame.Icon.UIScale.Scale = 1 + math.sin(self.saveSizeOffset * 0.1) * 0.02 -- 0.05
end

SaveManager:init()

return SaveManager
