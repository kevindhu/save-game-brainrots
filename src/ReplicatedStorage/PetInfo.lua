local ContentProvider = game:GetService("ContentProvider")

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local PetInfo = {}

local PetAnimInfo = require(game.ReplicatedStorage.PetAnimInfo)
local PetBalanceInfo = require(game.ReplicatedStorage.PetBalanceInfo)
local RatingInfo = require(game.ReplicatedStorage.RatingInfo)

PetInfo.idleAnimationMap = PetAnimInfo.idle
PetInfo.runningAnimationMap = PetAnimInfo.running
PetInfo.attackAnimationMap = PetAnimInfo.attack

PetInfo.attackDamageMap = PetBalanceInfo.attackDamageMap
PetInfo.coinsPerSecondMap = PetBalanceInfo.coinsPerSecondMap

PetInfo["petOrderList"] = {
	"CappuccinoAssassino",
	"TungTungSahur",
	"TrippiTroppi",

	"Boneca",
	"LiriLira",
	"Ballerina",
	"FrigoCamelo",
	"ChimpBanana",
	"TaTaTaSahur",
	"CapybaraCoconut",
	"DolphinBanana",
	"FishCatLegs",
	"GooseBomber",
	"TralaleloTralala",
	"GlorboFruttoDrillo",
	"RhinoToast",
	"BrrBrrPatapim",
	"ElephantCoconut",
	"TimCheese",
	"Bombardino",
	"GiraffeWatermelon",
	"MonkeyPineapple",
	"OwlAvocado",
	"OrangeDunDun",
	"CowPlanet",

	"OctopusBlueberry",
	"SaltCombined",
	"GorillaWatermelon",
	"MilkShake",
	"GrapeSquid",
}

PetInfo["ratingMap"] = {
	-- common
	["CappuccinoAssassino"] = "Common",
	["TungTungSahur"] = "Common",
	["TrippiTroppi"] = "Common",

	["Boneca"] = "Uncommon",
	["LiriLira"] = "Uncommon",
	["Ballerina"] = "Uncommon",

	-- rare
	["FrigoCamelo"] = "Rare",
	["ChimpBanana"] = "Rare",
	["TaTaTaSahur"] = "Rare",

	["CapybaraCoconut"] = "Rare",
	["DolphinBanana"] = "Rare",

	["FishCatLegs"] = "Rare",

	-- epic
	["GooseBomber"] = "Epic",
	["TralaleloTralala"] = "Epic",

	["GlorboFruttoDrillo"] = "Epic",
	["RhinoToast"] = "Epic",

	-- legendary
	["BrrBrrPatapim"] = "Legendary",
	["ElephantCoconut"] = "Legendary",
	["TimCheese"] = "Legendary",
	["Bombardino"] = "Legendary",
	["GiraffeWatermelon"] = "Legendary",
	["MonkeyPineapple"] = "Legendary",
	["OwlAvocado"] = "Legendary",

	-- mythic
	["OrangeDunDun"] = "Mythic",
	["CowPlanet"] = "Mythic",
	["OctopusBlueberry"] = "Mythic",
	["SaltCombined"] = "Mythic",

	-- secret
	["GorillaWatermelon"] = "Secret",
	["MilkShake"] = "Secret",
	["GrapeSquid"] = "Secret",
}

PetInfo["attackRangeMap"] = {
	["GooseBomber"] = 2,
	["LiriLira"] = 2,
	["OctopusBlueberry"] = 4,
}

PetInfo["attackDelayMap"] = {
	["GooseBomber"] = 0.05,
	["LiriLira"] = 0.05,
	["OrangeDunDun"] = 0.05,
}

PetInfo["giantScaleRatios"] = {
	["CappuccinoAssassino"] = 1.5,
	["TungTungSahur"] = 1.6,
	["Boneca"] = 1.6,
	["TrippiTroppi"] = 1.6,
	["LiriLira"] = 1.6,
	["Ballerina"] = 1.6,
	["FrigoCamelo"] = 1.6,
	["ChimpBanana"] = 1.6,
	["TaTaTaSahur"] = 1.6,
	["CapybaraCoconut"] = 1.65,
	["DolphinBanana"] = 1.65,
	["FishCatLegs"] = 1.68,
	["GooseBomber"] = 1.7,
	["TralaleloTralala"] = 1.7,
	["GlorboFruttoDrillo"] = 1.7,
	["RhinoToast"] = 1.7,
	["BrrBrrPatapim"] = 1.75,
	["ElephantCoconut"] = 1.8,
	["TimCheese"] = 1.82,
	["Bombardino"] = 1.81,
	["GiraffeWatermelon"] = 1.82,
	["MonkeyPineapple"] = 1.85,
	["OwlAvocado"] = 1.85,
	["OrangeDunDun"] = 1.9,
	["CowPlanet"] = 2,

	["OctopusBlueberry"] = 2,
	["SaltCombined"] = 2,
	["GorillaWatermelon"] = 2,
	["MilkShake"] = 2,
	["GrapeSquid"] = 2,
}

PetInfo["aliasMap"] = {
	["CappuccinoAssassino"] = "Cappuccino Assassino",
	["TungTungSahur"] = "Tung Tung Tung Sahur",
	["Boneca"] = "Boneca Ambalabu",
	["TrippiTroppi"] = "Trippi Troppi",
	["LiriLira"] = "Lirilì Larilà",
	["Ballerina"] = "Ballerina",
	["FrigoCamelo"] = "Frigo Camello",
	["ChimpBanana"] = "Chimp Banana",
	["TaTaTaSahur"] = "Ta Ta Ta Sahur",
	["CapybaraCoconut"] = "Burbaloni Lulilolli",
	["DolphinBanana"] = "Dolphinita Bananita",
	["FishCatLegs"] = "Trulimero Trulichina",
	["GooseBomber"] = "Bombombini Gusini",
	["TralaleloTralala"] = "Tralalelo Tralala",
	["GlorboFruttoDrillo"] = "Glorbo Frutto Drillo",
	["RhinoToast"] = "Rhino Toasterino",
	["BrrBrrPatapim"] = "Brr Brr Patapim",
	["ElephantCoconut"] = "Cocofanto Elefanto",
	["TimCheese"] = "Tim Cheese",
	["Bombardino"] = "Bombardino Crocodilo",
	["GiraffeWatermelon"] = "Girafa Celestre",

	["MonkeyPineapple"] = "Orangutini Ananasini",
	["OwlAvocado"] = "Avocadini Guffo",
	["OrangeDunDun"] = "Odin Din Din Dun",
	["CowPlanet"] = "La Vacca Saturno",

	["OctopusBlueberry"] = "Blueberinni Octopusini",
	["SaltCombined"] = "Garamama Mandundung",
	["GorillaWatermelon"] = "Gorillo Watermellondrillo",
	["MilkShake"] = "Ballerino Lololo",
	["GrapeSquid"] = "Graipus",
}

PetInfo["mutationImageMap"] = {
	["CappuccinoAssassino"] = {
		["Gold"] = "rbxassetid://109667066379119",
		["Diamond"] = "rbxassetid://80784325188772",
		["Bubblegum"] = "rbxassetid://106947706747500",
		["Volcanic"] = "rbxassetid://0",
	},
	["TungTungSahur"] = {
		["Gold"] = "rbxassetid://91759418447243",
		["Diamond"] = "rbxassetid://102383258702328",
		["Bubblegum"] = "rbxassetid://77802883392513",
		["Volcanic"] = "rbxassetid://0",
	},
	["Boneca"] = {
		["Gold"] = "rbxassetid://91644586735328",
		["Diamond"] = "rbxassetid://133615957145699",
		["Bubblegum"] = "rbxassetid://89900816364816",
		["Volcanic"] = "rbxassetid://0",
	},
	["TrippiTroppi"] = {
		["Gold"] = "rbxassetid://80045757220013",
		["Diamond"] = "rbxassetid://135807283864146",
		["Bubblegum"] = "rbxassetid://86323729800319",
		["Volcanic"] = "rbxassetid://0",
	},
	["LiriLira"] = {
		["Gold"] = "rbxassetid://117609302439636",
		["Diamond"] = "rbxassetid://130187762654592",
		["Bubblegum"] = "rbxassetid://81283367906305",
		["Volcanic"] = "rbxassetid://0",
	},
	["Ballerina"] = {
		["Gold"] = "rbxassetid://130276453619027",
		["Diamond"] = "rbxassetid://125211136218071",
		["Bubblegum"] = "rbxassetid://79711211482129",
		["Volcanic"] = "rbxassetid://0",
	},
	["FrigoCamelo"] = {
		["Gold"] = "rbxassetid://113476526825007",
		["Diamond"] = "rbxassetid://115299180815446",
		["Bubblegum"] = "rbxassetid://76987100230276",
		["Volcanic"] = "rbxassetid://0",
	},
	["ChimpBanana"] = {
		["Gold"] = "rbxassetid://113293594422120",
		["Diamond"] = "rbxassetid://73758849382231",
		["Bubblegum"] = "rbxassetid://125487875933475",
		["Volcanic"] = "rbxassetid://0",
	},
	["TaTaTaSahur"] = {
		["Gold"] = "rbxassetid://90850923270500",
		["Diamond"] = "rbxassetid://135307233433423",
		["Bubblegum"] = "rbxassetid://134181879182030",
		["Volcanic"] = "rbxassetid://0",
	},
	["CapybaraCoconut"] = {
		["Gold"] = "rbxassetid://106931430917794",
		["Diamond"] = "rbxassetid://94538135575929",
		["Bubblegum"] = "rbxassetid://90431790503006",
		["Volcanic"] = "rbxassetid://0",
	},
	["DolphinBanana"] = {
		["Gold"] = "rbxassetid://101723477471488",
		["Diamond"] = "rbxassetid://105148034223038",
		["Bubblegum"] = "rbxassetid://135061805879416",
		["Volcanic"] = "rbxassetid://0",
	},
	["FishCatLegs"] = {
		["Gold"] = "rbxassetid://91105334166770",
		["Diamond"] = "rbxassetid://93086434085583",
		["Bubblegum"] = "rbxassetid://100375668850469",
		["Volcanic"] = "rbxassetid://0",
	},
	["GooseBomber"] = {
		["Gold"] = "rbxassetid://76849534840322",
		["Diamond"] = "rbxassetid://109735154044923",
		["Bubblegum"] = "rbxassetid://86792159783540",
		["Volcanic"] = "rbxassetid://0",
	},
	["TralaleloTralala"] = {
		["Gold"] = "rbxassetid://120940510857129",
		["Diamond"] = "rbxassetid://107152431827475",
		["Bubblegum"] = "rbxassetid://90406338989634",
		["Volcanic"] = "rbxassetid://0",
	},
	["GlorboFruttoDrillo"] = {
		["Gold"] = "rbxassetid://76072223374744",
		["Diamond"] = "rbxassetid://71711553826838",
		["Bubblegum"] = "rbxassetid://71854627493956",
		["Volcanic"] = "rbxassetid://0",
	},
	["RhinoToast"] = {
		["Gold"] = "rbxassetid://78413580245454",
		["Diamond"] = "rbxassetid://139008182211340",
		["Bubblegum"] = "rbxassetid://136797729683722",
		["Volcanic"] = "rbxassetid://0",
	},
	["BrrBrrPatapim"] = {
		["Gold"] = "rbxassetid://104509723562865",
		["Diamond"] = "rbxassetid://72321985645528",
		["Bubblegum"] = "rbxassetid://104036020310739",
		["Volcanic"] = "rbxassetid://0",
	},
	["ElephantCoconut"] = {
		["Gold"] = "rbxassetid://136672281951642",
		["Diamond"] = "rbxassetid://136227082701021",
		["Bubblegum"] = "rbxassetid://96192552239399",
		["Volcanic"] = "rbxassetid://0",
	},
	["TimCheese"] = {
		["Gold"] = "rbxassetid://136202746932730",
		["Diamond"] = "rbxassetid://108500760261447",
		["Bubblegum"] = "rbxassetid://89411517211223",
		["Volcanic"] = "rbxassetid://0",
	},
	["Bombardino"] = {
		["Gold"] = "rbxassetid://109282893882558",
		["Diamond"] = "rbxassetid://120440778555930",
		["Bubblegum"] = "rbxassetid://99547066900529",
		["Volcanic"] = "rbxassetid://0",
	},
	["GiraffeWatermelon"] = {
		["Gold"] = "rbxassetid://79992998598461",
		["Diamond"] = "rbxassetid://99482906951302",
		["Bubblegum"] = "rbxassetid://97876000543090",
		["Volcanic"] = "rbxassetid://0",
	},
	["MonkeyPineapple"] = {
		["Gold"] = "rbxassetid://122874175842428",
		["Diamond"] = "rbxassetid://122874175842428",
		["Bubblegum"] = "rbxassetid://98314280460935",
		["Volcanic"] = "rbxassetid://0",
	},
	["OwlAvocado"] = {
		["Gold"] = "rbxassetid://98237605840415",
		["Diamond"] = "rbxassetid://98237605840415",
		["Bubblegum"] = "rbxassetid://71475263405728",
		["Volcanic"] = "rbxassetid://0",
	},
	["OrangeDunDun"] = {
		["Gold"] = "rbxassetid://122850576079196",
		["Diamond"] = "rbxassetid://79736625593100",
		["Bubblegum"] = "rbxassetid://103651421204627",
		["Volcanic"] = "rbxassetid://0",
	},
	["CowPlanet"] = {
		["Gold"] = "rbxassetid://124940438953803",
		["Diamond"] = "rbxassetid://78141639865951",
		["Bubblegum"] = "rbxassetid://117483150907441",
		["Volcanic"] = "rbxassetid://0",
	},
	["OctopusBlueberry"] = {
		["Gold"] = "rbxassetid://112751578819272",
		["Diamond"] = "rbxassetid://131194548387520",
		["Bubblegum"] = "rbxassetid://103648442177331",
		["Volcanic"] = "rbxassetid://0",
	},
	["SaltCombined"] = {
		["Gold"] = "rbxassetid://86716558466154",
		["Diamond"] = "rbxassetid://103853565610494",
		["Bubblegum"] = "rbxassetid://118254973567124",
		["Volcanic"] = "rbxassetid://0",
	},
	["GorillaWatermelon"] = {
		["Gold"] = "rbxassetid://90960308108416",
		["Diamond"] = "rbxassetid://73452531075832",
		["Bubblegum"] = "rbxassetid://138508963545763",
		["Volcanic"] = "rbxassetid://0",
	},
	["MilkShake"] = {
		["Gold"] = "rbxassetid://109428616204581",
		["Diamond"] = "rbxassetid://96902895146837",
		["Bubblegum"] = "rbxassetid://107914900078537",
		["Volcanic"] = "rbxassetid://0",
	},
	["GrapeSquid"] = {
		["Gold"] = "rbxassetid://89393777364963",
		["Diamond"] = "rbxassetid://100975650537723",
		["Bubblegum"] = "rbxassetid://80549121217705",
		["Volcanic"] = "rbxassetid://0",
	},
}

PetInfo["imageMap"] = {
	["CappuccinoAssassino"] = "rbxassetid://101310774768299",
	["TungTungSahur"] = "rbxassetid://97377640975338",
	["Boneca"] = "rbxassetid://84822321337725",
	["TrippiTroppi"] = "rbxassetid://117805314983035",
	["LiriLira"] = "rbxassetid://71755502023965",
	["Ballerina"] = "rbxassetid://132866572049485",
	["FrigoCamelo"] = "rbxassetid://81304947639096",
	["ChimpBanana"] = "rbxassetid://115144607447163",
	["TaTaTaSahur"] = "rbxassetid://115669545079726",
	["CapybaraCoconut"] = "rbxassetid://134962059936697",
	["DolphinBanana"] = "rbxassetid://125646734028183",
	["FishCatLegs"] = "rbxassetid://139387788524763",
	["GooseBomber"] = "rbxassetid://137304183045715",
	["TralaleloTralala"] = "rbxassetid://92228079842241",
	["GlorboFruttoDrillo"] = "rbxassetid://130586234745004",
	["RhinoToast"] = "rbxassetid://105307635647356",
	["BrrBrrPatapim"] = "rbxassetid://137549562017395",
	["ElephantCoconut"] = "rbxassetid://99305163220468",
	["TimCheese"] = "rbxassetid://130510088858325",
	["Bombardino"] = "rbxassetid://109970404191330",
	["GiraffeWatermelon"] = "rbxassetid://116021689375128",
	["MonkeyPineapple"] = "rbxassetid://76927325067882",
	["OwlAvocado"] = "rbxassetid://105088408802061",
	["OrangeDunDun"] = "rbxassetid://122849133369776",
	["CowPlanet"] = "rbxassetid://98880788883853",

	["OctopusBlueberry"] = "rbxassetid://107771232706312",
	["SaltCombined"] = "rbxassetid://112926897275871",
	["GorillaWatermelon"] = "rbxassetid://70891205809915",
	["MilkShake"] = "rbxassetid://100921899959556",
	["GrapeSquid"] = "rbxassetid://131692296995197",
}

function PetInfo:init()
	self.pets = {}

	for _, petClass in pairs(self.petOrderList) do
		local rating = self.ratingMap[petClass]

		self.pets[petClass] = {
			alias = self.aliasMap[petClass],
			rating = rating,
			attackDelay = self.attackDelayMap[petClass],
			attackDamage = self.attackDamageMap[petClass],
			coinsPerSecond = self.coinsPerSecondMap[petClass],
			image = self.imageMap[petClass],
			mutationImageMap = self.mutationImageMap[petClass],
		}
	end

	self:preloadPetRigs()
	self:preloadPetImages()
end

function PetInfo:getPetImage(petClass, mutationClass)
	local image = self.imageMap[petClass]
	local mutationImageMap = self.mutationImageMap[petClass]

	-- print("MUTATION IMAGE MAP: ", mutationImageMap, petClass, mutationClass)

	if mutationClass and mutationClass ~= "None" and mutationImageMap then
		image = mutationImageMap[mutationClass]
	end
	return image or "rbxassetid://120444751052938"
end

PetInfo.weightMultiplierMap = {
	["CappuccinoAssassino"] = 1,
	["TungTungSahur"] = 1.058,
	["Boneca"] = 1.115,
	["TrippiTroppi"] = 1.173,
	["LiriLira"] = 1.231,
	["Ballerina"] = 1.288,
	["FrigoCamelo"] = 1.346,
	["ChimpBanana"] = 1.404,
	["TaTaTaSahur"] = 1.462,
	["CapybaraCoconut"] = 1.519,
	["DolphinBanana"] = 1.577,
	["FishCatLegs"] = 1.635,
	["GooseBomber"] = 1.692,
	["TralaleloTralala"] = 1.75,
	["GlorboFruttoDrillo"] = 1.808,
	["RhinoToast"] = 1.865,
	["BrrBrrPatapim"] = 1.923,
	["ElephantCoconut"] = 1.981,
	["TimCheese"] = 2.038,
	["Bombardino"] = 2.096,
	["GiraffeWatermelon"] = 2.096,
	["MonkeyPineapple"] = 2.154,
	["OwlAvocado"] = 2.212,
	["OrangeDunDun"] = 2.269,
	["CowPlanet"] = 2.327,

	["OctopusBlueberry"] = 2.385,
	["SaltCombined"] = 2.442,
	["GorillaWatermelon"] = 2.5,
	["MilkShake"] = 2.5,
	["GrapeSquid"] = 2.52,
}

function PetInfo:getRealScale(baseWeight, level)
	local levelMultiplier = 1 + (level - 1) * 0.01
	local finalScale = baseWeight * levelMultiplier

	return finalScale
end

function PetInfo:refreshPetScale(rig, petData)
	local baseRig = game.ReplicatedStorage.Assets[petData["petClass"]]
	local baseScale = baseRig:GetScale()
	local finalScale = baseScale * self:getRealScale(petData["baseWeight"], petData["level"])
	rig:ScaleTo(finalScale)
end

function PetInfo:getRealWeight(petClass, baseWeight, level)
	local finalWeight = baseWeight * self.weightMultiplierMap[petClass]

	local levelMultiplier = 1 + (level - 1) * 0.01
	finalWeight = finalWeight * levelMultiplier

	return finalWeight
end

function PetInfo:calculateSellPrice(data)
	local petClass = data["petClass"]
	local mutationClass = data["mutationClass"]

	-- TODO:
	local sellPrice = 100

	return sellPrice
end

function PetInfo:getMaxLevel(rating)
	return RatingInfo.ratingMaxLevelMap[rating]
end

function PetInfo:calculateLevelUpPrice(petData)
	local level = petData["level"]
	-- local rating = petData["rating"]

	-- Calculate required coins using formula: 50 * 1.1^currentLevel
	local coinsCount = 50 * 1.1 ^ level
	coinsCount = math.floor(coinsCount)

	return coinsCount
end

function PetInfo:preloadPetImages()
	if Common.isServer then
		return
	end

	-- uses a hack where you make a preloadGUI and put all the images in it with very small size but visible on the screen
	-- https://devforum.roblox.com/t/preloading-images-and-keeping-them-loaded/2998098

	local player = game.Players.LocalPlayer
	local playerGui = player.PlayerGui

	local preloadGui = Instance.new("ScreenGui")
	preloadGui.Name = "PetPreloadGui"
	preloadGui.ResetOnSpawn = false
	preloadGui.IgnoreGuiInset = true
	preloadGui.Parent = playerGui

	local delayTimer = 0.2
	routine(function()
		wait(delayTimer)

		local images = {}

		for _, petClass in pairs(self.petOrderList) do
			local image = self.imageMap[petClass]
			if not image then
				continue
			end
			local imageLabel = Instance.new("ImageLabel")
			imageLabel.Image = image
			imageLabel.ImageTransparency = 0.95
			imageLabel.BackgroundTransparency = 1
			imageLabel.Size = UDim2.fromOffset(1, 1)
			imageLabel.Parent = preloadGui
		end

		for _, imageMap in pairs(self.mutationImageMap) do
			for _, image in pairs(imageMap) do
				local imageLabel = Instance.new("ImageLabel")
				imageLabel.Image = image
				imageLabel.ImageTransparency = 0.95
				imageLabel.BackgroundTransparency = 1
				imageLabel.Size = UDim2.fromOffset(1, 1)
				imageLabel.Parent = preloadGui
			end
		end

		-- print("PRELOADING PET IMAGES: ", len(preloadGui:GetChildren()))

		ContentProvider:PreloadAsync(preloadGui:GetChildren())
	end)
end

function PetInfo:preloadPetRigs()
	if Common.isServer then
		return
	end

	local delayTimer = 0.2

	routine(function()
		wait(delayTimer)

		local rigList = {}

		for _, petClass in pairs(self.petOrderList) do
			local petRig = game.ReplicatedStorage.Assets:FindFirstChild(petClass)
			if not petRig then
				continue
			end
			table.insert(rigList, petRig)
		end

		-- print("PRELOADING PET RIGS: ", len(rigList))

		ContentProvider:PreloadAsync(rigList)
	end)
end

function PetInfo:getMeta(itemClass, noWarn)
	self.categoryList = {
		"pets",
	}
	return Common.getInfoMeta(self, itemClass, noWarn)
end

PetInfo:init()

return PetInfo
