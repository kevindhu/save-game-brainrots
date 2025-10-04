local ServerMod = require(game.ServerScriptService.ServerMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local ItemInfo = require(game.ReplicatedStorage.ItemInfo)
local PetInfo = require(game.ReplicatedStorage.PetInfo)
local RelicInfo = require(game.ReplicatedStorage.RelicInfo)
local CrateInfo = require(game.ReplicatedStorage.CrateInfo)

local ItemStash = {}
ItemStash.__index = ItemStash

function ItemStash.new(owner, data)
	local u = {}
	u.owner = owner
	u.data = data

	u.itemMods = {}

	setmetatable(u, ItemStash)
	return u
end

function ItemStash:init()
	self.user = self.owner.user
	for k, v in pairs(self.data) do
		self[k] = v
	end

	routine(function()
		wait(0.5)
		if self.isNew then
			self:addFirstItems()
		end

		self:sanityCheckForSoftLock()

		self:sendAllItemMods()
	end)
end

function ItemStash:addFirstItems()
	self:updateItemCount({
		itemName = "Coins",
		count = 100,
	})

	if not Common.checkDeveloper(self.user.userId) then
		return
	end

	-- self:updateItemCount({
	-- 	itemName = "Coins",
	-- 	count = 100 * 1000 * 1000,
	-- })

	-- self:updateItemCount({
	-- 	itemName = "Coins",
	-- 	count = 10 * 1000,
	-- })

	self:addTestPets()
	-- self:addTestRelics()
end

function ItemStash:addTestPets()
	local petList = {
		"CappuccinoAssassino",
		"TungTungSahur",
		-- "TrippiTroppi",

		-- "Boneca",
		-- "LiriLira",
		-- "Ballerina",
		-- "FrigoCamelo",
		-- "ChimpBanana",
		-- "TaTaTaSahur",
		-- "CapybaraCoconut",
		-- "DolphinBanana",
		-- "FishCatLegs",
		-- "GooseBomber",
		-- "TralaleloTralala",
		-- "GlorboFruttoDrillo",
		-- "RhinoToast",
		-- "BrrBrrPatapim",
		-- "ElephantCoconut",
		-- "TimCheese",

		-- "Bombardino",

		-- "GiraffeWatermelon",
		-- "MonkeyPineapple",
		-- "OwlAvocado",
		-- "OrangeDunDun",
		-- "CowPlanet",

		-- "OctopusBlueberry",
		-- "SaltCombined",
		"GorillaWatermelon",

		"MilkShake",
		"GrapeSquid",
	}

	local mutationList = {
		"Normal",
		"Gold",
		"Diamond",
		"Bubblegum",
	}
	for _, petClass in ipairs(petList) do
		for _, mutationClass in ipairs(mutationList) do
			local count = 1
			for i = 1, count do
				self:addPet({
					petClass = petClass,
					mutationClass = mutationClass,
				})
			end
		end
	end
end

function ItemStash:addTestRelics()
	local relicList = {
		"Fist1",
		"Speed1",
		"Rich1",
		"Titan1",
		"Angel1",
	}
	for _, relicClass in ipairs(relicList) do
		self:addRelic({
			relicClass = relicClass,
		})
	end
end

function ItemStash:generatePetData(data)
	local itemData = Common.deepCopy(data)

	itemData["itemName"] = "STASH_ITEM_" .. Common.getGUID()
	itemData["itemClass"] = itemData["petClass"]

	itemData["race"] = "pet"

	itemData["creationTimestamp"] = os.time()

	self.user.home.petManager:fillPetDataWithDefaults(itemData)

	return itemData
end

function ItemStash:checkFullPets()
	local totalPetCount = self:getPetItemCount()
	return totalPetCount >= 1000
end

function ItemStash:generateRelicData(data)
	local itemData = Common.deepCopy(data)

	itemData["itemName"] = "STASHTOOL_" .. Common.getGUID()

	local relicClass = itemData["relicClass"]
	itemData["itemClass"] = relicClass

	itemData["relicName"] = itemData["itemName"]

	local relicStats = RelicInfo:getMeta(relicClass)

	local damageRange = relicStats["damageRange"] or { 1, 1 }
	local coinsRange = relicStats["coinsRange"] or { 1, 1 }
	local attackSpeedRange = relicStats["attackSpeedRange"] or { 1, 1 }

	-- generate based on the range (TODO: make this be more than just random between)
	itemData["damage"] = Common.randomBetween(damageRange[1], damageRange[2])
	itemData["coins"] = Common.randomBetween(coinsRange[1], coinsRange[2])
	itemData["attackSpeed"] = Common.randomBetween(attackSpeedRange[1], attackSpeedRange[2])

	itemData["race"] = "relic"

	itemData["creationTimestamp"] = os.time()

	return itemData
end

function ItemStash:addPet(data)
	local itemData = self:generatePetData(data)
	self:addItemMod(itemData)
end

function ItemStash:addRelic(data)
	local itemData = self:generateRelicData(data)
	self:addItemMod(itemData)
end

function ItemStash:addCrate(data)
	local crateClass = data["crateClass"]

	for _, currItemMod in pairs(self.itemMods) do
		if not currItemMod["race"] == "egg" then
			continue
		end
		if currItemMod["itemClass"] ~= crateClass then
			continue
		end

		self:updateItemCount({
			itemName = currItemMod["itemName"],
			count = 1,
		})

		return
	end

	local itemName = "CRATETOOL_" .. Common.getGUID()
	self:addItemMod({
		itemName = itemName,
		itemClass = crateClass,
		race = "crate",
	})

	self:updateItemCount({
		itemName = itemName,
		count = 1,
	})
end

function ItemStash:sanityCheckForSoftLock()
	-- see if coins is less than 100
	local coinsCount = self:getItemCount({
		itemName = "Coins",
	})
	if coinsCount < 100 then
		print("!! SANITY CHECK FOR SOFT LOCK: ", coinsCount)
		self:updateItemCount({
			itemName = "Coins",
			count = 100,
		})
	end
end

function ItemStash:getRelicItemCount()
	local totalCount = 0
	for _, itemMod in pairs(self.itemMods) do
		local race = itemMod["race"]
		if race == "relic" then
			totalCount += 1
		end
	end
	return totalCount
end

function ItemStash:getPetItemCount()
	local totalCount = 0
	for _, itemMod in pairs(self.itemMods) do
		local race = itemMod["race"]
		-- print("RACE: ", race)
		if race == "pet" then
			totalCount += 1
		end
	end

	return totalCount
end

-- this should only be called for currency items
function ItemStash:updateItemCount(data)
	local itemName = data["itemName"]
	local count = data["count"]

	local itemMod = self.itemMods[itemName]
	if not itemMod then
		itemMod = self:newItemMod({
			itemName = itemName,
			itemClass = itemName,
		})
	end

	local newCount = itemMod["count"] + count
	self:setItemCount(itemName, newCount)

	if count > 0 then
		if Common.listContains({ "Gems", "Coins" }, itemName) then
			self.user.home.statManager:incrementStatMod("Total" .. itemName, count)

			-- self:tryStartBuySpeedTutorial()
		else
			self.user.home.alertManager:incrementAlertCount({
				moduleName = "itemStash",
				count = count,
			})
		end
	end
end

function ItemStash:tryStartBuySpeedTutorial()
	local tutManager = self.user.home.tutManager
	if not tutManager.completedTutMods["CompleteTutorial"] then
		return
	end
	if tutManager.completedTutMods["GoToTimeWizard"] or tutManager.tutMods["GoToTimeWizard"] then
		return
	end

	local coins = self:getItemCount({
		itemName = "Coins",
	})

	-- print(coins)

	if coins < 100 then
		return
	end

	tutManager:newTutMod("GoToTimeWizard")
	tutManager:tryChooseNewTutMod()
end

function ItemStash:setItemCount(itemName, newCount)
	local itemMod = self.itemMods[itemName]
	if not itemMod then
		return
	end

	local itemStats = self:getFullItemStats(itemMod["itemClass"])

	-- cap the count at the max count
	local maxCount = itemStats["maxCount"]
	if maxCount then
		newCount = math.min(newCount, maxCount)
	end

	itemMod["count"] = newCount

	self:sendItemMod({
		itemMod = itemMod,
	})
end

function ItemStash:getItemMod(itemName)
	return self.itemMods[itemName]
end

function ItemStash:getItemCount(data)
	local itemName = data["itemName"]
	local itemMod = self.itemMods[itemName]
	if not itemMod then
		-- warn("NO ITEMMOD FOUND TO GET COUNT")
		return 0
	end
	return itemMod["count"]
end

function ItemStash:getFullItemStats(itemClass)
	local itemStats = ItemInfo:getMeta(itemClass, true)
		or PetInfo:getMeta(itemClass, true)
		or RelicInfo:getMeta(itemClass, true)
		or CrateInfo:getMeta(itemClass, true)

	if not itemStats then
		warn("NO ITEM STATS FOUND FOR: ", itemClass)
	end

	return itemStats
end

function ItemStash:addItemMod(data)
	local itemName = data["itemName"]
	local itemClass = data["itemClass"]
	local noSend = data["noSend"]
	local hatchDelayTimer = data["hatchDelayTimer"] or 0

	local noClick = data["noClick"]
	local forceBottom = data["forceBottom"]

	local itemStats = self:getFullItemStats(itemClass)
	data["alias"] = itemStats["alias"]

	if not itemName then
		warn("!!! NO ITEM NAME FOUND FOR: ", itemClass)
		itemName = "ITEM_" .. Common.getGUID()
		data["itemName"] = itemName
	end

	if Common.listContains({ "pet", "relic", "crate" }, data["race"]) then
		self.user.home.alertManager:incrementAlertCount({
			moduleName = "itemStash",
			count = 1,
		})
	end

	local newItemMod = self:newItemMod(data)

	if not noSend then
		routine(function()
			wait(hatchDelayTimer)
			self:sendItemMod({
				itemMod = newItemMod,
				forceBottom = forceBottom,
				noClick = noClick,
			})
		end)
	end

	return newItemMod
end

function ItemStash:removeItemMod(data)
	local itemName = data["itemName"]
	local noSend = data["noSend"]

	local itemMod = self.itemMods[itemName]
	if not itemMod then
		return
	end

	-- see if its a stashtool
	local toolMod = self.user.home.toolManager.stashToolMods[itemName]
	if toolMod then
		toolMod:destroy()
	end

	itemMod["deleted"] = true

	if not noSend then
		self:sendItemMod({
			itemMod = itemMod,
		})
	end

	self.itemMods[itemName] = nil
end

function ItemStash:toggleItemFavorite(data)
	local itemName = data["itemName"]

	local itemMod = self.itemMods[itemName]
	if not itemMod then
		warn("NO ITEM MOD TO TOGGLE FAVORITE: ", itemName)
		return
	end

	itemMod["favorited"] = not itemMod["favorited"]
	self:sendItemMod({
		itemMod = itemMod,
	})
end

function ItemStash:trySellAllToolItems(data)
	local chosenRace = data["race"]

	if not Common.listContains({ "pet", "relic" }, chosenRace) then
		return
	end

	local sellTotalPrice = 0
	for itemName, itemMod in pairs(self.itemMods) do
		local race = itemMod["race"]
		if race ~= chosenRace then
			continue
		end
		if itemMod["deleted"] then
			continue
		end
		if itemMod["favorited"] then
			continue
		end

		local sellPrice = 0
		if chosenRace == "pet" then
			sellPrice = PetInfo:calculateSellPrice({
				petClass = itemMod["itemClass"],
				mutationClass = itemMod["mutationClass"],
			})
		elseif chosenRace == "relic" then
			sellPrice = RelicInfo:calculateSellPrice({
				relicClass = itemMod["itemClass"],
			})
		end
		sellTotalPrice += sellPrice

		self:removeItemMod({
			itemName = itemName,
			noSend = true,
		})
	end

	if sellTotalPrice == 0 then
		self.user:notifyError("No brainrots to sell")
		return
	end

	self:updateItemCount({
		itemName = "Coins",
		count = sellTotalPrice,
	})

	ServerMod:FireClient(self.user.player, "newSoundMod", {
		soundClass = "CashRegister",
		volume = 0.5,
	})

	self:sendAllItemMods()
end

function ItemStash:trySellItem(data)
	local itemName = data["itemName"]

	local itemMod = self.itemMods[itemName]
	if not itemMod then
		return
	end
	local race = itemMod["race"]
	if not Common.listContains({ "pet", "relic" }, race) then
		warn("CANNOT SELL NON-PET ITEM: ", itemName)
		return
	end
	if itemMod["favorited"] then
		self.user:notifyError("Cannot sell favorite brainrots")
		return
	end

	-- local itemStats = self:getFullItemStats(itemMod["itemClass"])
	local sellPrice = 0
	if race == "pet" then
		sellPrice = PetInfo:calculateSellPrice({
			petClass = itemMod["itemClass"],
			mutationClass = itemMod["mutationClass"],
		})
	elseif race == "relic" then
		sellPrice = RelicInfo:calculateSellPrice({
			relicClass = itemMod["itemClass"],
		})
	end

	self:updateItemCount({
		itemName = "Coins",
		count = sellPrice,
	})

	ServerMod:FireClient(self.user.player, "newSoundMod", {
		soundClass = "CashRegister",
		volume = 0.5,
	})

	self.user.home.toolManager:removeStashTool({
		toolName = itemName,
	})
	self:removeItemMod({
		itemName = itemName,
	})
end

function ItemStash:newItemMod(data)
	local itemName = data["itemName"]
	local itemClass = data["itemClass"]
	local race = data["race"]

	local itemStats = self:getFullItemStats(itemClass)

	local newItemMod = {
		itemName = itemName,
		itemClass = itemClass,
		race = race,

		alias = itemStats["alias"],

		favorited = false,

		exp = 0,
		count = 0,
		createdTimestamp = os.time(),
	}
	self.itemMods[itemName] = newItemMod

	-- set all the other metadata
	for k, v in pairs(data) do
		newItemMod[k] = v
	end

	return newItemMod
end

function ItemStash:tryUseItem(data)
	local itemName = data["itemName"]

	local itemMod = self.itemMods[itemName]
	if not itemMod then
		warn("NO ITEMMOD TO USE: ", itemName)
		return
	end

	local itemClass = itemMod["itemClass"]

	local itemStats = self:getFullItemStats(itemClass)

	if not itemStats["consumable"] then
		warn("CANNOT USE NON-CONSUMABLE ITEM: ", itemName)
		return
	end

	if itemStats["tabGroup"] == "Boosts" then
		self.user.home.boostManager:addBoostMod(itemClass)
	end

	self.user:notifySuccess("Used " .. itemMod["alias"])

	local soundData = {
		soundClass = "PotionDrink",
	}
	ServerMod:FireClient(self.user.player, "newSoundMod", soundData)

	self:updateItemCount({
		itemName = itemName,
		count = -1,
	})
end

function ItemStash:sendAllItemMods()
	ServerMod:FireClient(self.user.player, "updateAllItemMods", {
		itemMods = self.itemMods,
	})
end

function ItemStash:sendItemMod(data)
	ServerMod:FireClient(self.user.player, "updateItemMod", data)
end

function ItemStash:saveState()
	local managerData = {
		itemMods = self.itemMods,
	}
	self.user.store:set(self.moduleAlias .. "Info", managerData)
end

function ItemStash:wipe()
	self.itemMods = {}

	self:addFirstItems()
	self:sendAllItemMods()
end

return ItemStash
