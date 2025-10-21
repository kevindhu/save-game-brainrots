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
		-- Wave 1: Unit1 (38 units)
		{
			unitClass = "Unit1x1",
			count = 38,
			spawnTimer = 0.16,
		},
		-- Wave 2: Unit2 (42 units)
		{
			unitClass = "Unit2x1",
			count = 42,
			spawnTimer = 0.19,
		},
		-- Wave 3: Unit3 (37 units)
		{
			unitClass = "Unit3x1",
			count = 37,
			spawnTimer = 0.24,
		},
		-- Wave 4: Unit4 (43 units)
		{
			unitClass = "Unit4x1",
			count = 43,
			spawnTimer = 0.21,
		},
		-- Wave 5: Unit5 (46 units)
		{
			unitClass = "Unit5x1",
			count = 46,
			spawnTimer = 0.17,
		},
		-- Wave 6: Unit6 (41 units)
		{
			unitClass = "Unit6x1",
			count = 41,
			spawnTimer = 0.23,
		},
	},
	["Mythic1"] = {
		-- Wave 1: Unit1 (23 units)
		{
			unitClass = "Unit1x1",
			count = 23,
			spawnTimer = 0.17,
		},
		-- Wave 2: Unit2 (28 units)
		{
			unitClass = "Unit2x1",
			count = 28,
			spawnTimer = 0.19,
		},
		-- Wave 3: Unit4 (33 units)
		{
			unitClass = "Unit4x1",
			count = 33,
			spawnTimer = 0.21,
		},
		-- Wave 4: Unit5 (29 units)
		{
			unitClass = "Unit5x1",
			count = 29,
			spawnTimer = 0.23,
		},
		-- Wave 5: Unit6 (12 units) - introduction to next tier
		{
			unitClass = "Unit6x1",
			count = 12,
			spawnTimer = 0.26,
		},
	},
	["Legendary1"] = {
		-- Wave 1: Unit1 (14 units)
		{
			unitClass = "Unit1x1",
			count = 14,
			spawnTimer = 0.25,
		},
		-- Wave 2: Unit2 (19 units)
		{
			unitClass = "Unit2x1",
			count = 19,
			spawnTimer = 0.29,
		},
		-- Wave 3: Unit3 (21 units)
		{
			unitClass = "Unit3x1",
			count = 21,
			spawnTimer = 0.31,
		},
		-- Wave 4: Unit4 (16 units)
		{
			unitClass = "Unit4x1",
			count = 16,
			spawnTimer = 0.32,
		},
		-- Wave 5: Unit5 (6 units) - introduction to next tier
		{
			unitClass = "Unit5x1",
			count = 6,
			spawnTimer = 0.38,
		},
	},

	["Epic1"] = {
		-- Wave 1: Unit1 (9 units)
		{
			unitClass = "Unit1x1",
			count = 9,
			spawnTimer = 0.36,
		},
		-- Wave 2: Unit2 (14 units)
		{
			unitClass = "Unit2x1",
			count = 14,
			spawnTimer = 0.38,
		},
		-- Wave 3: Unit3 (8 units)
		{
			unitClass = "Unit3x1",
			count = 8,
			spawnTimer = 0.34,
		},
		-- Wave 4: Unit4 (4 units) - introduction to next tier
		{
			unitClass = "Unit4x1",
			count = 4,
			spawnTimer = 0.37,
		},
	},
	["Epic2"] = {
		-- Wave 1: Unit1 (11 units)
		{
			unitClass = "Unit1x1",
			count = 11,
			spawnTimer = 0.33,
		},
		-- Wave 2: Unit2 (16 units)
		{
			unitClass = "Unit2x2",
			count = 16,
			spawnTimer = 0.36,
		},
		-- Wave 3: Unit3 (6 units)
		{
			unitClass = "Unit3x2",
			count = 6,
			spawnTimer = 0.37,
		},
		-- Wave 4: Unit4 (3 units) - introduction to next tier
		{
			unitClass = "Unit4x2",
			count = 3,
			spawnTimer = 0.39,
		},
	},

	["Rare1"] = {
		-- Wave 1: Unit1 (11 units)
		{
			unitClass = "Unit1x1",
			count = 11,
			spawnTimer = 0.43,
		},
		-- Wave 2: Unit2 (9 units)
		{
			unitClass = "Unit2x1",
			count = 9,
			spawnTimer = 0.44,
		},
		-- Wave 3: Unit3 (4 units) - introduction to next tier
		{
			unitClass = "Unit3x1",
			count = 4,
			spawnTimer = 0.41,
		},
	},
	["Rare2"] = {
		-- Wave 1: Unit1 (13 units)
		{
			unitClass = "Unit1x2",
			count = 13,
			spawnTimer = 0.39,
		},
		-- Wave 2: Unit2 (11 units)
		{
			unitClass = "Unit2x2",
			count = 11,
			spawnTimer = 0.41,
		},
		-- Wave 3: Unit3 (3 units) - introduction to next tier
		{
			unitClass = "Unit3x2",
			count = 3,
			spawnTimer = 0.44,
		},
	},

	["Uncommon1"] = {
		-- Wave 1: Unit1 (11 units)
		{
			unitClass = "Unit1x1",
			count = 11,
			spawnTimer = 0.47,
		},
		-- Wave 2: Unit2 (4 units) - introduction to next tier
		{
			unitClass = "Unit2x1",
			count = 4,
			spawnTimer = 0.43,
		},
	},
	["Uncommon2"] = {
		-- Wave 1: Unit1 (13 units)
		{
			unitClass = "Unit1x2",
			count = 13,
			spawnTimer = 0.44,
		},
		-- Wave 2: Unit2 (3 units) - introduction to next tier
		{
			unitClass = "Unit2x2",
			count = 3,
			spawnTimer = 0.48,
		},
	},

	["Common1"] = {
		-- Wave 1: Unit1 (6 units)
		{
			unitClass = "Unit1x1",
			count = 6,
			spawnTimer = 0.72,
		},
	},
	["Common2"] = {
		-- Wave 1: Unit1 (4 units)
		{
			unitClass = "Unit1x2",
			count = 4,
			spawnTimer = 0.78,
		},
	},
}

return WaveInfo
