local MusicInfo = {}

MusicInfo["Default"] = {
	{ 9045766377, 0.15 }, -- piano classical

	-- { 1836009208, 0.09 }, -- gag classic easter song
	-- { 89535139236133, 0.09 },
	-- { 98661372350894, 0.09 },
	-- { 84634512926214, 0.09 },
	-- { 1842205471, 0.09 },
	-- { 1843640051, 0.09 },
	-- { 9047881924, 0.09 },
	-- { 1842252986, 0.09 },
	-- { 103537575410966, 0.09 },
	-- { 131398409499062, 0.09 }, -- original
}

MusicInfo["LegendarySpawn"] = {
	{ 1841703337, 0.15 }, -- underworld
}

MusicInfo["MythicSpawn"] = {
	{ 1837845027, 0.15 }, -- underworld
}

MusicInfo["SecretSpawn"] = {
	{ 138118304933431, 0.15 }, -- tralalelo phonk
}

function MusicInfo:getMeta(itemClass, noWarn)
	local Common = require(game.ReplicatedStorage.Common)
	self.categoryList = {
		"zones",
	}
	return Common.getInfoMeta(self, itemClass, noWarn)
end

return MusicInfo
