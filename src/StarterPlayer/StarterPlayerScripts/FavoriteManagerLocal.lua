local AvatarEditorService = game:GetService("AvatarEditorService")

local player = game.Players.LocalPlayer
local playerGui = player.PlayerGui
local playerScripts = player.PlayerScripts

local ClientMod = require(playerScripts.ClientMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local FavoriteManager = {
	idleTimer = 0,
}
FavoriteManager.__index = FavoriteManager

function FavoriteManager:init()
	self:addCons()
end

function FavoriteManager:addCons()
	AvatarEditorService.PromptSetFavoriteCompleted:Connect(function(result)
		if result == Enum.AvatarPromptResult.Success then
			ClientMod:FireServer("finishFavoriteGame")
		end
	end)
end

function FavoriteManager:updateFavoriteData(data)
	self.hasFavoritedGame = data["hasFavoritedGame"]
end

function FavoriteManager:tryStartFavorite()
	if true then
		return
	end

	if self.hasFavoritedGame then
		return
	end

	-- TOGGLE THIS FOR TESTING
	if Common.isStudio then
		return
	end

	AvatarEditorService:PromptSetFavorite(game.PlaceId, Enum.AvatarItemType.Asset, true)
end

FavoriteManager:init()

return FavoriteManager
