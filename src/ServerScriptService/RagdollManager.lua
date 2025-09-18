local ServerMod = require(game.ServerScriptService.ServerMod)

local RagdollManager = {}
RagdollManager.__index = RagdollManager

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

-- Joints that should remain enabled during ragdoll
local EXCLUDED_JOINTS = {
	LeftWrist = true,
	RightWrist = true,
	LeftAnkle = true,
	RightAnkle = true,
}

-- Check if a joint should be affected by ragdoll
local function isValidJoint(jointName)
	return not EXCLUDED_JOINTS[jointName]
end

-- Toggle ragdoll state for a character
function RagdollManager:toggleRagdoll(user, newBool)
	user.ragdolled = newBool

	local rig = user.rig
	if not rig then
		warn("NO RIG FOUND FOR TOGGLE RAGDOLL: ", user.name)
		return
	end

	-- Notify client
	ServerMod:FireClient(user.player, "toggleRagdoll", {
		newBool = newBool,
	})

	-- print("RAGDOLLING: ", newBool, rig.Name)

	self:ragdollRig(rig, newBool)
end

function RagdollManager:ragdollRig(rig, newBool)
	if newBool then
		-- Enable ragdoll physics
		local badMotor6Ds = {
			"RigWeldMotor123",
		}

		-- Enable ragdoll physics
		for _, child in pairs(rig:GetDescendants()) do
			if Common.listContains(badMotor6Ds, child.Name) then
				continue
			end

			if child:IsA("Motor6D") and isValidJoint(child.Name) then
				child.Enabled = false
			elseif child:IsA("BallSocketConstraint") then
				child.Enabled = true
			elseif child.Name == "Torso" then
				-- Add random velocity for realistic effect
				local bodyVelocity = Instance.new("BodyVelocity", child)
				bodyVelocity.Velocity = Vector3.new(math.random(-10, 10), 0, math.random(-10, 10)) * 0.05
				routine(function()
					wait(0.1)
					bodyVelocity:Destroy()
				end)
			elseif child:IsA("BasePart") then
				-- local density = 0.01 -- 10
				-- local friction = 0.1 -- 0.1
				-- local elasticity = 0.5 -- 0.8 -- 0.2 (orig)
				-- local frictionWeight = 1
				-- local elasticityWeight = 5 -- 2

				-- -- Construct new PhysicalProperties and set
				-- local properties =
				-- 	PhysicalProperties.new(density, friction, elasticity, frictionWeight, elasticityWeight)
				-- child.CustomPhysicalProperties = properties
			end
		end
	else
		-- Disable ragdoll physics
		for _, child in pairs(rig:GetDescendants()) do
			if child:IsA("Motor6D") then
				child.Enabled = true
			elseif child:IsA("BallSocketConstraint") then
				child.Enabled = false
			elseif child:IsA("BasePart") then
				-- local density = 0.1 -- 10
				-- local friction = 2 -- 0.1
				-- local elasticity = 0 -- 0.8 -- 0.2 (orig)
				-- local frictionWeight = 1
				-- local elasticityWeight = 5 -- 2

				-- Construct new PhysicalProperties and set
				-- local properties =
				-- 	PhysicalProperties.new(density, friction, elasticity, frictionWeight, elasticityWeight)

				-- child.CustomPhysicalProperties = properties
			end
		end
	end
end

-- Set up joints and collision groups for ragdoll physics
function RagdollManager:setupJoints(rig)
	if not rig or not rig.Parent then
		-- warn("NO RIG FOUND FOR SETUP JOINTS: ", rig)
		return
	end
	local humanoid = rig:FindFirstChild("Humanoid")
	if not humanoid then
		warn("NO HUMANOID FOUND ON RIG: ", rig)
		return
	end

	-- remove all previous ballsocketjoints
	for _, child in pairs(rig:GetDescendants()) do
		if child:IsA("BallSocketConstraint") then
			-- warn("DESTROYING BALLSOCKET CONSTRAINT: ", child)
			child:Destroy()
		end
	end

	humanoid.BreakJointsOnDeath = false
	humanoid.RequiresNeck = true

	local rootPart = rig:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		warn("NO ROOT PART FOUND ON RIG: ", rig)
		return
	end

	-- Set up physics constraints for each body part
	for _, child in pairs(rig:GetDescendants()) do
		if child:IsA("Motor6D") and isValidJoint(child.Name) then
			local joint = child
			-- Create ball socket constraint system for ragdoll
			local ballSocket = Instance.new("BallSocketConstraint", joint.Parent)

			local attachment0 = Instance.new("Attachment", joint.Part0)
			local attachment1 = Instance.new("Attachment", joint.Part1)

			ballSocket.MaxFrictionTorque = 1 -- 0
			ballSocket.Restitution = 0

			ballSocket.Attachment0 = attachment0
			ballSocket.Attachment1 = attachment1
			attachment0.CFrame = joint.C0
			attachment1.CFrame = joint.C1

			ballSocket.LimitsEnabled = true
			ballSocket.TwistLimitsEnabled = true
			ballSocket.Enabled = false
		elseif child:IsA("BasePart") then
			-- Configure collision groups
			if child.Name == "HumanoidRootPart" then
				-- ServerMod:setCollisionGroupRec(part, "PlayerRootPart")
			else
				-- ServerMod:setCollisionGroupRec(part, "Players")

				-- Ensure head can collide for realistic physics
				if child.Name == "Head" then
					child.CanCollide = true
				end
			end
		end
	end
end

return RagdollManager
