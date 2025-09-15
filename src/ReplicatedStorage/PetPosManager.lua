local PetPosManager = {
	ATTACK_RADIUS = 8,
}

function PetPosManager:getFollowUserFrame(data)
	local userFrame = data["userFrame"]
	if not userFrame then
		return CFrame.new(0, -20, 0)
	end

	local orderIndexMod = data["orderIndexMod"] or {
		index = 1,
		total = 1,
	}

	local orderIndex = orderIndexMod.index
	local totalPetCount = orderIndexMod.total

	local ratio
	if totalPetCount == 1 then
		-- If there's only one unit, place it at the center (60 degrees)
		ratio = 0.5
	else
		-- Otherwise distribute evenly from 0 to 1
		ratio = (orderIndex - 1) / (totalPetCount - 1)
	end

	local totalAngleRange = 40 + totalPetCount * 15
	local halfAngle = totalAngleRange / 2

	local angleOffset = math.rad(-halfAngle + (totalAngleRange * ratio))

	local baseRadius = 3 -- 8

	local radius = baseRadius + totalPetCount * 0.3
	-- Calculate offset position using angle and radius
	local offsetX = math.sin(angleOffset) * radius
	local offsetZ = math.cos(angleOffset) * radius

	local goalFrame = userFrame * CFrame.new(offsetX, -2, offsetZ)

	return goalFrame
end

function PetPosManager:init() end

PetPosManager:init()

return PetPosManager
