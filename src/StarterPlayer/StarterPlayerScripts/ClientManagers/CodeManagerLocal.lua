local player = game.Players.LocalPlayer
local playerScripts = player.PlayerScripts
local playerGui = player.PlayerGui

local ClientMod = require(playerScripts.ClientMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local exclusiveShopGUI = playerGui:WaitForChild("ExclusiveShopGUI")
local shopFrame = exclusiveShopGUI.ShopFrame
local codeFrame = shopFrame.MainItemList.Codes.CodeFrame

local CodeManager = {
	currCodeClass = nil,
}

function CodeManager:init()
	self:addCons()
end

function CodeManager:addCons()
	self:addCodeCons()
end

function CodeManager:addCodeCons()
	local codeTextBox = codeFrame.InnerFrame.TextBox
	codeTextBox.FocusLost:Connect(function(enterPressed)
		local txt = codeTextBox.Text

		local editedText = txt:lower()

		local charLimit = 30 -- 20
		if string.sub(editedText, 1, charLimit) then
			--			print("currText over the charLimit: ", currText)
			editedText = string.sub(editedText, 1, charLimit)
		end
		editedText = editedText:gsub(" ", "")
		codeTextBox.Text = editedText

		self.currCodeClass = editedText
	end)

	local redeemButton = codeFrame.RedeemButton
	ClientMod.buttonManager:addActivateCons(redeemButton, function()
		if not self.currCodeClass then
			return
		end

		local codeData = {
			codeClass = self.currCodeClass,
		}
		ClientMod:FireServer("tryCode", codeData)
		self.currCodeClass = nil
	end)
	ClientMod.buttonManager:addBasicButtonCons(redeemButton)
end

function CodeManager:notifyText(data)
	local txt = data["txt"]
	local success = data["success"]

	local notifyStep = ClientMod.step
	self.notifyStep = notifyStep

	local descriptionText = codeFrame.DescriptionText
	descriptionText.Text = txt
	if success then
		descriptionText.TextColor3 = Color3.fromRGB(19, 255, 66)
		-- ClientMod.uiManager:addSound("PurchaseSuccessful", 0.1)
	else
		descriptionText.TextColor3 = Color3.fromRGB(255, 63, 38)
	end

	routine(function()
		self:wiggleFrame(descriptionText)
	end)

	routine(function()
		wait(3)
		if self.notifyStep ~= notifyStep then
			return
		end

		descriptionText.Text = "Join our community server for codes!"
		descriptionText.TextColor3 = Color3.new(1, 1, 1)
	end)
end

function CodeManager:wiggleFrame(frame)
	local currAngle = 6 -- 8 (orig)

	local wiggleTimer = 0.12 -- 0.15 -- 0.05
	for i = 1, 2 do
		for j = 1, 2 do
			local sign = 1
			if j == 2 then
				sign = -1
			end

			local currRotation = currAngle * sign
			ClientMod.tweenManager:createTween({
				target = frame,
				timer = wiggleTimer,
				easingStyle = "Quad",
				easingDirection = "Out",
				goal = {
					Rotation = currRotation,
				},
			})
			wait(wiggleTimer)
		end
	end

	ClientMod.tweenManager:createTween({
		target = frame,
		timer = 0.15,
		easingStyle = "Quad",
		easingDirection = "Out",
		goal = {
			Rotation = 0,
		},
	})
end

CodeManager:init()

return CodeManager
