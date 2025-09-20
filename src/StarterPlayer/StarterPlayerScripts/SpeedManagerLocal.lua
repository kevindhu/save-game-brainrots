local player = game.Players.LocalPlayer
local playerScripts = player.PlayerScripts
local playerGui = player.PlayerGui

local ClientMod = require(playerScripts.ClientMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

-- local CodeInfo = require(game.ReplicatedStorage.CodeInfo)

-- local exclusiveShopGUI = playerGui:WaitForChild("ExclusiveShopGUI")
-- local shopFrame = exclusiveShopGUI.ShopFrame

local SpeedManager = {
	speed = 1,
}

function SpeedManager:init()
	self:addCons()
end

function SpeedManager:addCons() end

function SpeedManager:updateGameSpeed(data)
	local speed = data["speed"]
	self.speed = speed
end

function SpeedManager:getSpeed()
	return self.speed
end

SpeedManager:init()

return SpeedManager
