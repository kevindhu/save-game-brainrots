local ContentProvider = game:GetService("ContentProvider")

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local player = game.Players.LocalPlayer
local playerScripts = player.PlayerScripts
local playerGui = player.PlayerGui

local rebirthGUI = playerGui:WaitForChild("RebirthGUI")
local shopGUI = playerGui:WaitForChild("ShopGUI")

local ContentManager = {}

function ContentManager:init()
	routine(function()
		self:preloadImages()
	end)
end

function ContentManager:addImagesFromGUI(gui, images)
	for _, child in pairs(gui:GetDescendants()) do
		if not child:IsA("ImageLabel") and not child:IsA("ImageButton") then
			continue
		end
		if child.ImageTransparency == 1 then
			continue
		end
		table.insert(images, child)
	end
end

function ContentManager:preloadImages()
	local images = {}
	self:addImagesFromGUI(rebirthGUI, images)
	self:addImagesFromGUI(shopGUI, images)

	-- print("PRELOADING IMAGES: ", len(images))

	ContentProvider:PreloadAsync(images)
end

ContentManager:init()

return ContentManager
