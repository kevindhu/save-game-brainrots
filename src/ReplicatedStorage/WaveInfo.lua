local WaveInfo = {}

WaveInfo["ratingCountMap"] = {
	["Secret"] = 1,
	["Mythic"] = 1,
	["Legendary"] = 1,
	["Epic"] = 2,
	["Rare"] = 2,
	["Uncommon"] = 2,
	["Common"] = 2,
}

WaveInfo["ratingWaveMap"] = {
	["Secret1"] = {
		-- Wave 1: Unit1 (40 units)
		{
			unitClass = "Unit1x1",
			count = 40,
			spawnTimer = 0.15,
		},
		-- Wave 2: Unit2 (40 units)
		{
			unitClass = "Unit2x1",
			count = 40,
			spawnTimer = 0.2,
		},
		-- Wave 3: Unit3 (40 units)
		{
			unitClass = "Unit3x1",
			count = 40,
			spawnTimer = 0.25,
		},
		-- Wave 4: Unit4 (45 units)
		{
			unitClass = "Unit4x1",
			count = 45,
			spawnTimer = 0.2,
		},
		-- Wave 5: Unit5 (45 units)
		{
			unitClass = "Unit5x1",
			count = 45,
			spawnTimer = 0.18,
		},
		-- Wave 6: Unit6 (40 units)
		{
			unitClass = "Unit6x1",
			count = 40,
			spawnTimer = 0.22,
		},
	},
	["Mythic1"] = {
		-- Wave 1: Unit1 (25 units)
		{
			unitClass = "Unit1x1",
			count = 25,
			spawnTimer = 0.15,
		},
		-- Wave 2: Unit2 (30 units)
		{
			unitClass = "Unit2x1",
			count = 30,
			spawnTimer = 0.18,
		},
		-- Wave 3: Unit4 (35 units)
		{
			unitClass = "Unit4x1",
			count = 35,
			spawnTimer = 0.2,
		},
		-- Wave 4: Unit5 (30 units)
		{
			unitClass = "Unit5x1",
			count = 30,
			spawnTimer = 0.22,
		},
		-- Wave 5: Unit6 (10 units) - introduction to next tier
		{
			unitClass = "Unit6x1",
			count = 10,
			spawnTimer = 0.25,
		},
	},
	["Legendary1"] = {
		-- Wave 1: Unit1 (15 units)
		{
			unitClass = "Unit1x1",
			count = 15,
			spawnTimer = 0.24,
		},
		-- Wave 2: Unit2 (20 units)
		{
			unitClass = "Unit2x1",
			count = 20,
			spawnTimer = 0.28,
		},
		-- Wave 3: Unit3 (20 units)
		{
			unitClass = "Unit3x1",
			count = 20,
			spawnTimer = 0.3,
		},
		-- Wave 4: Unit4 (15 units)
		{
			unitClass = "Unit4x1",
			count = 15,
			spawnTimer = 0.3,
		},
		-- Wave 5: Unit5 (5 units) - introduction to next tier
		{
			unitClass = "Unit5x1",
			count = 5,
			spawnTimer = 0.4,
		},
	},

	["Epic1"] = {
		-- Wave 1: Unit1 (10 units)
		{
			unitClass = "Unit1x1",
			count = 10,
			spawnTimer = 0.35,
		},
		-- Wave 2: Unit2 (15 units)
		{
			unitClass = "Unit2x1",
			count = 15,
			spawnTimer = 0.37,
		},
		-- Wave 3: Unit3 (7 units)
		{
			unitClass = "Unit3x1",
			count = 7,
			spawnTimer = 0.35,
		},
		-- Wave 4: Unit4 (3 units) - introduction to next tier
		{
			unitClass = "Unit4x1",
			count = 3,
			spawnTimer = 0.35,
		},
	},
	["Epic2"] = {
		-- Wave 1: Unit1 (10 units)
		{
			unitClass = "Unit1x1",
			count = 10,
			spawnTimer = 0.35,
		},
		-- Wave 2: Unit2 (15 units)
		{
			unitClass = "Unit2x2",
			count = 15,
			spawnTimer = 0.37,
		},
		-- Wave 3: Unit3 (7 units)
		{
			unitClass = "Unit3x2",
			count = 7,
			spawnTimer = 0.35,
		},
		-- Wave 4: Unit4 (3 units) - introduction to next tier
		{
			unitClass = "Unit4x2",
			count = 3,
			spawnTimer = 0.35,
		},
	},

	["Rare1"] = {
		-- Wave 1: Unit1 (12 units)
		{
			unitClass = "Unit1x1",
			count = 12,
			spawnTimer = 0.41,
		},
		-- Wave 2: Unit2 (10 units)
		{
			unitClass = "Unit2x1",
			count = 10,
			spawnTimer = 0.42,
		},
		-- Wave 3: Unit3 (3 units) - introduction to next tier
		{
			unitClass = "Unit3x1",
			count = 3,
			spawnTimer = 0.42,
		},
	},
	["Rare2"] = {
		-- Wave 1: Unit1 (12 units)
		{
			unitClass = "Unit1x2",
			count = 12,
			spawnTimer = 0.41,
		},
		-- Wave 2: Unit2 (10 units)
		{
			unitClass = "Unit2x2",
			count = 10,
			spawnTimer = 0.42,
		},
		-- Wave 3: Unit3 (3 units) - introduction to next tier
		{
			unitClass = "Unit3x2",
			count = 3,
			spawnTimer = 0.42,
		},
	},

	["Uncommon1"] = {
		-- Wave 1: Unit1 (12 units)
		{
			unitClass = "Unit1x1",
			count = 12,
			spawnTimer = 0.45,
		},
		-- Wave 2: Unit2 (3 units) - introduction to next tier
		{
			unitClass = "Unit2x1",
			count = 3,
			spawnTimer = 0.45,
		},
	},
	["Uncommon2"] = {
		-- Wave 1: Unit1 (12 units)
		{
			unitClass = "Unit1x2",
			count = 12,
			spawnTimer = 0.45,
		},
		-- Wave 2: Unit2 (3 units) - introduction to next tier
		{
			unitClass = "Unit2x2",
			count = 3,
			spawnTimer = 0.45,
		},
	},

	["Common1"] = {
		-- Wave 1: Unit1 (7 units)
		{
			unitClass = "Unit1x1",
			count = 7,
			spawnTimer = 0.6,
		},
	},
	["Common2"] = {
		-- Wave 1: Unit1 (7 units)
		{
			unitClass = "Unit1x2",
			count = 7,
			spawnTimer = 0.6,
		},
	},
}

return WaveInfo
