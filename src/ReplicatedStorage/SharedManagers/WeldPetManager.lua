local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local PetInfo = require(game.ReplicatedStorage.Data.PetInfo)

local WeldPetManager = {}
WeldPetManager.__index = WeldPetManager

function WeldPetManager.new()
	local self = setmetatable({}, WeldPetManager)
	return self
end

function WeldPetManager:addWeldPetRig(data)
	local petClass = data["petClass"]
	local anchorPart = data["anchorPart"]
	local anchorOffsetFrame = data["anchorOffsetFrame"]
	local noParent = data["noParent"]

	-- weight
	local baseWeight = data["baseWeight"]
	local level = data["level"]

	-- mutations
	local mutationManager = data["mutationManager"]
	local mutationClass = data["mutationClass"]

	local rig = game.ReplicatedStorage.Assets[petClass]:Clone()

	rig.HumanoidRootPart.Transparency = 1

	local armsHoldPart = rig:FindFirstChild("ArmsHoldPart")
	if armsHoldPart then
		armsHoldPart:Destroy()
	end

	-- add root part motor
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

	local decorModel = rig:FindFirstChild("DecorModel")
	if decorModel then
		local anchorRootPart = rig:FindFirstChild("RootPart") or rig:FindFirstChild("FakeRootPart")

		for _, child in pairs(decorModel:GetDescendants()) do
			if not child:IsA("BasePart") then
				continue
			end

			child.Anchored = false
			child.CanCollide = false

			-- weld it to the primaryPart
			local weld = Instance.new("Motor6D")
			weld.Part0 = child
			weld.Part1 = anchorRootPart
			weld.C0 = child.CFrame:inverse() * anchorRootPart.CFrame
			weld.C1 = CFrame.new(0, 0, 0)
			weld.Name = "DecorWeldMotor123"
			weld.Parent = child

			-- print("!! WELDING DECOR: ", child, weld, anchorRootPart)
		end
	end

	-- unanchor all parts
	for _, child in pairs(rig:GetDescendants()) do
		if not child:IsA("BasePart") then
			continue
		end
		child.Anchored = false
	end

	local entity = {
		petClass = petClass,
	}
	mutationManager:addMutationToRig(entity, rig, mutationClass)

	local baseScale = rig:GetScale()
	local finalScale = baseScale * PetInfo:getRealScale(baseWeight, level)

	rig:ScaleTo(finalScale)

	if not anchorOffsetFrame then
		anchorOffsetFrame = CFrame.new(0, 0, 0)
	end

	rig:SetPrimaryPartCFrame(
		anchorPart.CFrame * anchorOffsetFrame * CFrame.new(0, -anchorPart.Size.Y / 2 + rig.PrimaryPart.Size.Y / 2, 0)
	)

	-- make all massless
	for _, child in pairs(rig:GetDescendants()) do
		if not child:IsA("BasePart") then
			continue
		end

		child.CanCollide = false
		child.Massless = true
	end

	-- weld to the anchorPart
	local primaryPart = rig.PrimaryPart
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = primaryPart
	weld.Part1 = anchorPart
	weld.Parent = primaryPart

	if not noParent then
		rig.Parent = game.Workspace.HitBoxes
	end

	for _, child in pairs(rig:GetDescendants()) do
		if not child:IsA("BasePart") then
			continue
		end
		child.CanCollide = false
	end

	return rig
end

return WeldPetManager
