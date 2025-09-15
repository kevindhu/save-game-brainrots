local WindLines = require(script.Parent:WaitForChild("WindLinesLocal"))

WindLines:Init({
	Direction = Vector3.new(1, 0, 0.3),
	Speed = 20,
	Lifetime = 1.5, -- 1.5
	SpawnRate = 6, -- 3
})
