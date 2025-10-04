local WaveInfo = {}

WaveInfo["ratingWaveMap"] = {
	["Secret"] = {
		-- Wave 1: Unit1 (40 units)
		{
			unitClass = "Unit1",
			count = 40,
			spawnTimer = 0.15,
		},
		-- Wave 2: Unit2 (40 units)
		{
			unitClass = "Unit2",
			count = 40,
			spawnTimer = 0.2,
		},
		-- Wave 3: Unit3 (40 units)
		{
			unitClass = "Unit3",
			count = 40,
			spawnTimer = 0.25,
		},
		-- Wave 4: Unit4 (45 units)
		{
			unitClass = "Unit4",
			count = 45,
			spawnTimer = 0.2,
		},
		-- Wave 5: Unit5 (45 units)
		{
			unitClass = "Unit5",
			count = 45,
			spawnTimer = 0.18,
		},
		-- Wave 6: Unit6 (40 units)
		{
			unitClass = "Unit6",
			count = 40,
			spawnTimer = 0.22,
		},
	},
	["Mythic"] = {
		-- Wave 1: Unit1 (25 units)
		{
			unitClass = "Unit1",
			count = 25,
			spawnTimer = 0.15,
		},
		-- Wave 2: Unit2 (30 units)
		{
			unitClass = "Unit2",
			count = 30,
			spawnTimer = 0.18,
		},
		-- Wave 3: Unit4 (35 units)
		{
			unitClass = "Unit4",
			count = 35,
			spawnTimer = 0.2,
		},
		-- Wave 4: Unit5 (30 units)
		{
			unitClass = "Unit5",
			count = 30,
			spawnTimer = 0.22,
		},
		-- Wave 5: Unit6 (10 units) - introduction to next tier
		{
			unitClass = "Unit6",
			count = 10,
			spawnTimer = 0.25,
		},
	},
	["Legendary"] = {
		-- Wave 1: Unit1 (15 units)
		{
			unitClass = "Unit1",
			count = 15,
			spawnTimer = 0.24,
		},
		-- Wave 2: Unit2 (20 units)
		{
			unitClass = "Unit2",
			count = 20,
			spawnTimer = 0.28,
		},
		-- Wave 3: Unit3 (20 units)
		{
			unitClass = "Unit3",
			count = 20,
			spawnTimer = 0.3,
		},
		-- Wave 4: Unit4 (15 units)
		{
			unitClass = "Unit4",
			count = 15,
			spawnTimer = 0.3,
		},
		-- Wave 5: Unit5 (5 units) - introduction to next tier
		{
			unitClass = "Unit5",
			count = 5,
			spawnTimer = 0.4,
		},
	},
	["Epic"] = {
		-- Wave 1: Unit1 (10 units)
		{
			unitClass = "Unit1",
			count = 10,
			spawnTimer = 0.35,
		},
		-- Wave 2: Unit2 (15 units)
		{
			unitClass = "Unit2",
			count = 15,
			spawnTimer = 0.37,
		},
		-- Wave 3: Unit3 (7 units)
		{
			unitClass = "Unit3",
			count = 7,
			spawnTimer = 0.35,
		},
		-- Wave 4: Unit4 (3 units) - introduction to next tier
		{
			unitClass = "Unit4",
			count = 3,
			spawnTimer = 0.35,
		},
	},
	["Rare"] = {
		-- Wave 1: Unit1 (12 units)
		{
			unitClass = "Unit1",
			count = 12,
			spawnTimer = 0.41,
		},
		-- Wave 2: Unit2 (10 units)
		{
			unitClass = "Unit2",
			count = 10,
			spawnTimer = 0.42,
		},
		-- Wave 3: Unit3 (3 units) - introduction to next tier
		{
			unitClass = "Unit3",
			count = 3,
			spawnTimer = 0.42,
		},
	},
	["Uncommon"] = {
		-- Wave 1: Unit1 (12 units)
		{
			unitClass = "Unit1",
			count = 12,
			spawnTimer = 0.45,
		},
		-- Wave 2: Unit2 (3 units) - introduction to next tier
		{
			unitClass = "Unit2",
			count = 3,
			spawnTimer = 0.45,
		},
	},
	["Common"] = {
		-- Wave 1: Unit1 (7 units)
		{
			unitClass = "Unit1",
			count = 7,
			spawnTimer = 0.6,
		},
	},
}

return WaveInfo
