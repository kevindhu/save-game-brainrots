local WeatherInfo = {}

WeatherInfo["eventWeightMap"] = {
	Normal = 1000000,
	Rainy = 1,
	Sandstorm = 1,
}

WeatherInfo["events"] = {
	["Normal"] = {
		timer = 1,
		color = Color3.fromRGB(255, 255, 255), -- White
		cloudCover = 0.05,
		durationRange = { 3, 8 },

		unitWeightMap = {},
	},
	["Rainy"] = {
		-- timer = 5,
		timer = 60 * 2,
		luck = 10,
		color = Color3.fromRGB(68, 115, 255), -- Blue
		cloudCover = 0.98,
		durationRange = { 3, 8 },

		unitWeightMap = {
			GooseBomber = 1,
			TralaleloTralala = 1,
			BrrBrrPatapim = 0.5,
			MonkeyPineapple = 0.5,
		},
	},
	["Sandstorm"] = {
		-- timer = 5,
		timer = 60 * 3,
		luck = 2,
		color = Color3.fromRGB(255, 198, 89), -- Sandy orange
		cloudCover = 1,
		durationRange = { 5, 12 },

		unitWeightMap = {
			GooseBomber = 1,
			TralaleloTralala = 2,
			BrrBrrPatapim = 1,
		},
	},
	["Snowy"] = {
		-- timer = 5,
		timer = 60 * 3,
		luck = 2,
		color = Color3.fromRGB(255, 255, 255),
		cloudCover = 0.9,

		durationRange = { 4, 10 },

		unitWeightMap = {
			TungTungSahur = 100,
		},
	},
}

function WeatherInfo:init() end

function WeatherInfo:getMeta(itemClass, noWarn)
	local Common = require(game.ReplicatedStorage.Common)
	self.categoryList = {
		"events",
	}
	return Common.getInfoMeta(self, itemClass, noWarn)
end

WeatherInfo:init()

return WeatherInfo
