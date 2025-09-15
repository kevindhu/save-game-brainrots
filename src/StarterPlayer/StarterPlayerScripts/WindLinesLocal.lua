local RunService = game:GetService("RunService")
local Terrain = workspace:FindFirstChildOfClass("Terrain")

local EMPTY_TABLE = {}
local OFFSET = Vector3.new(0, 0.1, 0)

local WindLines = {}

WindLines.UpdateQueue = table.create(10)

function WindLines:Init(Settings)
	-- Set defaults
	self.Lifetime = Settings.Lifetime or 3
	self.Direction = Settings.Direction or Vector3.new(1, 0, 0)
	self.Speed = Settings.Speed or 6

	-- Clear any old stuff
	if self.UpdateConnection then
		self.UpdateConnection:Disconnect()
		self.UpdateConnection = nil
	end

	for _, WindLine in ipairs(self.UpdateQueue) do
		WindLine.Attachment0:Destroy()
		WindLine.Attachment1:Destroy()
		WindLine.Trail:Destroy()
	end
	table.clear(self.UpdateQueue)

	self.LastSpawned = os.clock()
	local SpawnRate = 1 / (Settings.SpawnRate or 25)

	-- Setup logic loop
	self.UpdateConnection = RunService.Heartbeat:Connect(function()
		local Clock = os.clock()

		-- Spawn handler
		if Clock - self.LastSpawned > SpawnRate then
			self:Create()
			self.LastSpawned = Clock
		end

		-- Update queue handler
		debug.profilebegin("Wind Lines")
		for i, WindLine in ipairs(self.UpdateQueue) do
			local AliveTime = Clock - WindLine.StartClock
			if AliveTime >= WindLine.Lifetime then
				-- Destroy the objects
				WindLine.Attachment0:Destroy()
				WindLine.Attachment1:Destroy()
				WindLine.Trail:Destroy()

				-- unordered remove at this index
				local Length = #self.UpdateQueue
				self.UpdateQueue[i] = self.UpdateQueue[Length]
				self.UpdateQueue[Length] = nil

				continue
			end

			WindLine.Trail.MaxLength = 20 - (20 * (AliveTime / WindLine.Lifetime))

			local SeededClock = (Clock + WindLine.Seed) * (WindLine.Speed * 0.2)
			local StartPos = WindLine.Position
			WindLine.Attachment0.WorldPosition = (CFrame.new(StartPos, StartPos + WindLine.Direction) * CFrame.new(
				0,
				0,
				WindLine.Speed * -AliveTime
			)).Position + Vector3.new(
				math.sin(SeededClock) * 0.5,
				math.sin(SeededClock) * 0.8,
				math.sin(SeededClock) * 0.5
			)

			WindLine.Attachment1.WorldPosition = WindLine.Attachment0.WorldPosition + OFFSET
		end
		debug.profileend()
	end)
end

function WindLines:Cleanup()
	if self.UpdateConnection then
		self.UpdateConnection:Disconnect()
		self.UpdateConnection = nil
	end

	for _, WindLine in ipairs(self.UpdateQueue) do
		WindLine.Attachment0:Destroy()
		WindLine.Attachment1:Destroy()
		WindLine.Trail:Destroy()
	end
	table.clear(self.UpdateQueue)
end

function WindLines:Create(Settings)
	debug.profilebegin("Add Wind Line")

	Settings = Settings or EMPTY_TABLE

	local Lifetime = Settings.Lifetime or self.Lifetime
	local Position = Settings.Position
		or (workspace.CurrentCamera.CFrame * CFrame.Angles(
			math.rad(math.random(-30, 70)),
			math.rad(math.random(-80, 80)),
			0
		) * CFrame.new(0, 0, math.random(200, 600) * -0.1)).Position
	local Direction = Settings.Direction or self.Direction
	local Speed = Settings.Speed or self.Speed
	if Speed <= 0 then
		return
	end

	local Attachment0 = Instance.new("Attachment")
	local Attachment1 = Instance.new("Attachment")

	local Trail = Instance.new("Trail")
	Trail.Attachment0 = Attachment0
	Trail.Attachment1 = Attachment1
	Trail.WidthScale = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(0.2, 1),
		NumberSequenceKeypoint.new(0.8, 1),
		NumberSequenceKeypoint.new(1, 0.3),
	})
	Trail.Transparency = NumberSequence.new(0.7)
	Trail.FaceCamera = true
	Trail.Parent = Attachment0

	Attachment0.WorldPosition = Position
	Attachment1.WorldPosition = Position + OFFSET

	local WindLine = {
		Attachment0 = Attachment0,
		Attachment1 = Attachment1,
		Trail = Trail,
		Lifetime = Lifetime + (math.random(-10, 10) * 0.1),
		Position = Position,
		Direction = Direction,
		Speed = Speed + (math.random(-10, 10) * 0.1),
		StartClock = os.clock(),
		Seed = math.random(1, 1000) * 0.1,
	}

	self.UpdateQueue[#self.UpdateQueue + 1] = WindLine

	Attachment0.Parent = Terrain
	Attachment1.Parent = Terrain

	debug.profileend()
end

return WindLines
