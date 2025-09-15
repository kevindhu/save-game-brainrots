local player = game.Players.LocalPlayer
local playerScripts = player:WaitForChild("PlayerScripts")
local playerGui = player:WaitForChild("PlayerGui")

local ClientMod = require(playerScripts:WaitForChild("ClientMod"))

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local BaseTool = {}
BaseTool.__index = BaseTool

function BaseTool.new(tool, data)
	local self = {}
	self.tool = tool
	self.data = data

	self.connections = {}

	setmetatable(self, BaseTool)
	return self
end

function BaseTool:init()
	for k, v in pairs(self.data) do
		self[k] = v
	end

	self:addCons()
end

function BaseTool:addCons()
	local tool = self.tool
	local connection = tool.Activated:Connect(function()
		self:onActivate()
	end)
	table.insert(self.connections, connection)

	connection = tool.Equipped:Connect(function()
		self:onEquip()
	end)
	table.insert(self.connections, connection)

	tool.Unequipped:Connect(function()
		self:onUnequip()
	end)

	local destroyConnection = tool.Destroying:Connect(function()
		self:destroy()
	end)
	table.insert(self.connections, destroyConnection)
end

function BaseTool:onActivate()
	-- print("ACTIVATING")
end

function BaseTool:onEquip()
	self.equipped = true
end

function BaseTool:onUnequip()
	self.equipped = false
end

function BaseTool:performRaycast(distance, whitelist)
	local mouse = player:GetMouse()
	local camera = workspace.CurrentCamera

	local unitRay = camera:ScreenPointToRay(mouse.X, mouse.Y)
	local ray = Ray.new(unitRay.Origin, unitRay.Direction * distance)

	return workspace:FindPartOnRayWithWhitelist(ray, whitelist)
end

function BaseTool:destroy()
	if self.destroyed then
		return
	end
	self.destroyed = true

	for _, connection in pairs(self.connections) do
		-- print("DISCONNECTING", connection)
		connection:Disconnect()
	end

	ClientMod.toolManager:removeToolMod(self.toolName)
end

return BaseTool
