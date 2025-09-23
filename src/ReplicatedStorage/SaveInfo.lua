local SaveInfo = {
	VERSION = "ve.3.005",
	ODS_VERSION = "2.0.2",

	STUDIO_VERSION = "std.ve.0.0.0003",
	STUDIO_ODS_VERSION = "10.0.1",

	-- only enabled in studio!
	NO_SAVE = true,

	-- update this with every update
	GAME_VERSION = "0.0.5",
}

local Common = require(game.ReplicatedStorage.Common)

-- if Common.isStudio then
-- 	SaveInfo.VERSION = SaveInfo.STUDIO_VERSION
-- 	SaveInfo.ODS_VERSION = SaveInfo.STUDIO_ODS_VERSION
-- end

return SaveInfo
