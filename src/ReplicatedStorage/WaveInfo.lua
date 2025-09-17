local WaveInfo = {}

WaveInfo["ratingWaveMap"] = {
	["Secret"] = {
		{
			unitClass = "Unit1",
			count = 5,
			spawnTimer = 0.02,
		},
		-- {
		-- 	unitClass = "Unit2",
		-- 	count = 5,
		-- 	spawnTimer = 0.2,
		-- },
	},
	["Mythic"] = {
		{
			unitClass = "Unit1",
			count = 5,
			spawnTimer = 0.5,
		},
		{
			unitClass = "Unit2",
			count = 10,
			spawnTimer = 0.02,
		},
		{
			unitClass = "Unit3",
			count = 1,
			spawnTimer = 0.02,
		},
	},
	["Legendary"] = {
		{
			unitClass = "Unit1",
			count = 5,
			spawnTimer = 0.5,
		},
		{
			unitClass = "Unit2",
			count = 10,
			spawnTimer = 0.02,
		},
		{
			unitClass = "Unit3",
			count = 1,
			spawnTimer = 0.02,
		},
	},
	["Epic"] = {
		{
			unitClass = "Unit1",
			count = 5,
			spawnTimer = 0.5,
		},
		{
			unitClass = "Unit2",
			count = 10,
			spawnTimer = 0.02,
		},
		{
			unitClass = "Unit3",
			count = 1,
			spawnTimer = 0.02,
		},
	},
	["Rare"] = {
		{
			unitClass = "Unit1",
			count = 5,
			spawnTimer = 0.1,
		},
		{
			unitClass = "Unit2",
			count = 10,
			spawnTimer = 0.02,
		},
	},
	["Uncommon"] = {
		{
			unitClass = "Unit1",
			count = 5,
			spawnTimer = 0.1,
		},
		{
			unitClass = "Unit2",
			count = 10,
			spawnTimer = 0.02,
		},
	},
	["Common"] = {
		{
			unitClass = "Unit2",
			count = 5,
			spawnTimer = 0.2,
		},
	},
}

return WaveInfo
