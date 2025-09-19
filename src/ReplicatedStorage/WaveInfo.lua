local WaveInfo = {}

WaveInfo["ratingWaveMap"] = {
	["Secret"] = {
		{
			unitClass = "Unit4",
			count = 5,
			spawnTimer = 0.02,
		},
	},
	["Mythic"] = {
		{
			unitClass = "Unit4",
			count = 5,
			spawnTimer = 0.5,
		},
	},
	["Legendary"] = {
		{
			unitClass = "Unit1",
			count = 5,
			spawnTimer = 0.5,
		},
	},
	["Epic"] = {
		{
			unitClass = "Unit4",
			count = 5,
			spawnTimer = 0.5,
		},
	},
	["Rare"] = {
		{
			unitClass = "Unit4",
			count = 5,
			spawnTimer = 0.1,
		},
		{
			unitClass = "Unit2",
			count = 3,
			spawnTimer = 0.02,
		},
	},
	["Uncommon"] = {
		{
			unitClass = "Unit4",
			count = 5,
			spawnTimer = 0.1,
		},
		{
			unitClass = "Unit2",
			count = 3,
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
