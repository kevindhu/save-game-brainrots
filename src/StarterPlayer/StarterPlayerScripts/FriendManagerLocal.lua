local SocialService = game:GetService("SocialService")

local player = game.Players.LocalPlayer
local playerScripts = player.PlayerScripts
local playerGui = player.PlayerGui

local ClientMod = require(playerScripts.ClientMod)

local buffGUI = playerGui:WaitForChild("BuffGUI")
local buffFrame = buffGUI.BuffFrame
local friendsFrame = buffFrame.Friends

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local FriendManager = {
	currFriendMap = {},
}

function FriendManager:init()
	self:addCons()

	-- self:doFakeFriendRequestLoop()
end

function FriendManager:addCons()
	local inviteOptions = Instance.new("ExperienceInviteOptions")
	inviteOptions.PromptMessage = "Get +10% Strength if your friend joins!"
	self.inviteOptions = inviteOptions

	local buttonFrame = friendsFrame.ButtonFrame
	ClientMod.buttonManager:addActivateCons(buttonFrame, function()
		local canInvite = SocialService:CanSendGameInviteAsync(player)
		if not canInvite then
			return
		end

		SocialService:PromptGameInvite(player, self.inviteOptions)
	end)
	ClientMod.buttonManager:addBasicButtonCons(buttonFrame)
end

function FriendManager:doFakeFriendRequestLoop()
	routine(function()
		wait(15)
		while true do
			self:addFakeFriendRequest()
			wait(math.random(60 * 5, 60 * 8))
		end
	end)
end

function FriendManager:updateFriends(data)
	local friendMap = data["friendMap"]
	local friendCount = data["friendCount"]

	self.currFriendMap = friendMap

	friendsFrame.Visible = true

	local buttonFrame = friendsFrame.ButtonFrame

	-- add 10% boost per friend
	local boost = (friendCount * 0.1)
	buttonFrame.Title.Text = string.format("+%d%%", boost * 100)
end

function FriendManager:addFakeFriendRequest()
	-- add random person as friend
	local chosenPlayer = nil
	for _, otherPlayer in pairs(game.Players:GetPlayers()) do
		if player == otherPlayer then
			continue
		end
		if self.currFriendMap[otherPlayer.UserId] then
			continue
		end

		chosenPlayer = otherPlayer
		break
	end

	if not chosenPlayer then
		-- local canInvite = SocialService:CanSendGameInviteAsync(player)
		-- if not canInvite then
		-- 	return
		-- end
		SocialService:PromptGameInvite(player, self.inviteOptions)
		return
	end

	local CoreGui = game:GetService("StarterGui")

	local chosenUserId = chosenPlayer.UserId
	local imageId = Common.getProfileImageFromUserId(chosenUserId)

	local userName = Common.getUsernameFromUserId(chosenUserId)
	local finalText = string.format("%s has added you as a friend", userName)

	local bindable = Instance.new("BindableFunction")
	function bindable.OnInvoke(response)
		if response == "Decline" then
			return
		end

		game.StarterGui:SetCore("PromptSendFriendRequest", chosenPlayer)
	end

	CoreGui:SetCore("SendNotification", {
		Icon = imageId,
		Title = userName,
		Text = "Sent you a friend request!",
		Duration = 10,
		Callback = bindable,
		Button1 = "Accept",
		Button2 = "Decline",
	})
end

FriendManager:init()

return FriendManager
