local SetInfo = {}

SetInfo["setList"] = {
	"Music",
	"UISound",
}

function SetInfo:init() end

function SetInfo:getMeta(itemClass, noWarn)
	local Common = require(game.ReplicatedStorage.Common)
	self.categoryList = {
		"general",
		"effects",
		"editAvatar",
		"editThumbnail",

		-- PhotoManager
		"photoCamera",
		"photoLight",
		"photoProps",
		"particles",
	}
	return Common.getInfoMeta(self, itemClass, noWarn)
end

SetInfo:init()

return SetInfo
