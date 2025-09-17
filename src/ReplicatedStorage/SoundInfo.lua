local ContentProvider = game:GetService("ContentProvider")

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local SoundInfo = {}

SoundInfo["sounds"] = {
	["PetHit1"] = {
		id = 93756464269927,
		volume = 0.5,
	},
	["PetHit2"] = {
		id = 95359441386432,
		volume = 0.5,
	},
	["PetHit3"] = {
		id = 95359441386432, -- 82942397702096,
		volume = 0.5,
	},
	["PetHit4"] = {
		id = 121358220078605,
		volume = 0.5,
	},
	["PetHit5"] = {
		id = 132841872580385,
		volume = 0.5,
	},
	["FireworksLaunch"] = {
		id = 6958700030,
		volume = 1,
	},

	["BoopHit1"] = {
		id = 8836769160,
		volume = 0.5,
	},
	["BoopHit2"] = {
		id = 8836769258,
		volume = 0.5,
	},
	["BoopHit3"] = {
		id = 8836769025,
		volume = 0.5,
	},
	["BoopHit4"] = {
		id = 8836768864,
		volume = 0.5,
	},
	["BoopHit5"] = {
		id = 8836768741,
		volume = 0.5,
	},

	-- PUNCHES
	["Punch1"] = {
		id = 7468131335,
		volume = 1,
	},
	["Punch2"] = {
		id = 146163534,
		volume = 0.5,
	},

	["RopeTug"] = {
		id = 9118709336,
		volume = 0.5,

		startTime = 0.35,
	},
	["RopeTug2"] = {
		id = 114813573682393,
		volume = 0.4,

		startTime = 0.1,
	},

	["CoilStart"] = {
		id = 99173388,
		volume = 0.2,
	},
	["CashRegister"] = {
		id = 139484047183513,
		volume = 0.4,
	},
	["CashRegister2"] = {
		id = 85680064777114,
		volume = 0.85, -- 0.4
	},
	["CashBuy"] = {
		id = 4612383453,
		volume = 0.2,
	},

	["VoiceBeep"] = {
		id = 98969952323684,
		volume = 0.5,
	},

	["EvilLaugh"] = {
		id = 99037509129849,
		volume = 0.1, -- 0.15
	},

	["ItemPlacement"] = {
		id = 7650220708,
		volume = 0.2,
		playbackSpeed = 0.9,
	},
	["ItemPlacement2"] = {
		id = 100053912342345,
		volume = 0.145,
		playbackSpeed = 1.1,
	},

	-- SUCCESS SOUNDS
	["Notice"] = {
		id = 2865227271,
		volume = 0.2,
	},

	["Eat"] = {
		id = 3043029786,
		volume = 0.5,
	},

	["SoftSuccess"] = {
		id = 97881181065416,
		volume = 0.2,
	},

	-- success obtain
	-- ["SuccessObtainUnit"] = {
	-- 	id = 9115975838,
	-- 	volume = 0.2,
	-- },
	["SuccessSoftObtain"] = {
		id = 3450794184,
		volume = 0.2,
	},

	["SoftSuccess2"] = {
		id = 3450794184,
		volume = 0.2,
	},
	["SuccessRebirth"] = {
		id = 18403881159,
		volume = 1,
	},

	-- ERROR SOUNDS
	["SoftError1"] = {
		id = 644569388,
		volume = 0.5,
	},
	["SoftError2"] = {
		id = 8426701399,
		volume = 0.5,
	},
	["SoftError3"] = {
		id = 550209561,
		volume = 0.5,
	},
	["SoftError4"] = { -- classic butotn sound
		id = 12221967,
		volume = 1,
	},
	["SoftError5"] = {
		id = 180185084,
		volume = 0.5,
	},

	-- WHOOSH SOUNDS
	["Whoosh1"] = {
		id = 2795036553,
		volume = 0.5,
	},

	["ButtonHover1"] = {
		id = 6324801967,
		volume = 0.25,
	},

	["Pop1"] = {
		id = 1289263994,
		volume = 0.25,
	},
	["SproutPop1"] = {
		id = 101517849465268,
		volume = 0.25,
	},
	["SproutPop2"] = {
		id = 118801631044440,
		volume = 0.05,
	},
	["EggFinish1"] = {
		id = 75986971248561,
		volume = 0.2,
	},
	["HammerHit"] = {
		id = 180163738,
		volume = 0.15,
	},

	-- PRODUCT STARTED
	["ProductStarted"] = {
		id = 112735442881169,
		volume = 0.5,
	},
	["ProductStarted2"] = {
		id = 120926797677784,
		volume = 0.5,
	},

	-- CLICK SOUNDS
	["ButtonClick1"] = {
		id = 140423032940322,
		volume = 1,
	},
	["ButtonClick2"] = {
		id = 876939830,
		volume = 1,
	},
	["ButtonClick3"] = {
		id = 9080070218,
		volume = 0.8,
	},

	-- EGG SOUNDS
	["EggBreak1"] = {
		id = 9113959343,
		volume = 0.5,
	},
	["EggBreak2"] = {
		id = 126409451844008,
		volume = 0.5,
	},
	["EggHit1"] = {
		id = 9113958649,
		volume = 0.5,
	},

	["TypeWriter"] = {
		id = 9120299506,
		volume = 0.3,
	},

	-- shard collect
	["CoinCollect2"] = {
		id = 115520671198314,
		volume = 0.1,
	},
}

SoundInfo["petSounds"] = {
	-- PET SOUNDS
	["CappuccinoAssassino"] = {
		id = 134664003196803,
		volume = 0.5,
	},
	["TungTungSahur"] = {
		id = 97294555436195,
		volume = 0.5,
	},
	["Boneca"] = {
		id = 133971165510417,
		volume = 0.5,
	},
	["TrippiTroppi"] = {
		id = 100582670416163,
		volume = 0.5,
	},
	["LiriLira"] = {
		id = 95152573009334,
		volume = 0.5,
	},
	["Ballerina"] = {
		id = 86820802105862,
		volume = 0.5,
	},
	["FrigoCamelo"] = {
		id = 85206468677771,
		volume = 0.5,
	},
	["ChimpBanana"] = {
		id = 133370914081454,
		volume = 0.5,
	},
	["TaTaTaSahur"] = {
		id = 88521923673155,
		volume = 0.5,
	},
	["CapybaraCoconut"] = {
		id = 78895467333350,
		volume = 0.5,
	},

	["DolphinBanana"] = {
		id = 101007636281496,
		volume = 0.5,
	},

	["FishCatLegs"] = {
		id = 103887376533418,
		volume = 0.5,
	},

	["GooseBomber"] = {
		id = 80038260529993,
		volume = 0.5,
	},
	["TralaleloTralala"] = {
		id = 116499133658518,
		volume = 0.5,
	},
	["GlorboFruttoDrillo"] = {
		id = 113208805657115,
		volume = 0.5,
	},
	["RhinoToast"] = {
		id = 101313231952056,
		volume = 0.5,
	},
	["BrrBrrPatapim"] = {
		id = 81029704103961,
		volume = 0.5,
	},
	["ElephantCoconut"] = {
		id = 114080817167826,
		volume = 0.5,
	},
	["TimCheese"] = {
		id = 75681329260442,
		volume = 0.5,
	},
	["GiraffeWatermelon"] = {
		id = 131855467495856,
		volume = 0.45,
	},
	["MonkeyPineapple"] = {
		id = 110180558188504,
		volume = 0.5,
	},
	["OwlAvocado"] = {
		id = 86806101998019,
		volume = 0.5,
	},
	["OrangeDunDun"] = {
		id = 124857115895857,
		volume = 0.5,
	},
	["CowPlanet"] = {
		id = 133886521040513,
		volume = 0.5,
	},
	["OctopusBlueberry"] = {
		id = 84079497413006,
		volume = 0.5,
	},
	["SaltCombined"] = {
		id = 75740374835685,
		volume = 0.5,
	},
	["GorillaWatermelon"] = {
		id = 86952284674931,
		volume = 0.8,
	},
	["MilkShake"] = {
		id = 101301649674115,
		volume = 0.3,
	},
	["GrapeSquid"] = {
		id = 115709645272962,
		volume = 0.5,
	},
}

function SoundInfo:init()
	for soundClass, soundData in pairs(self.petSounds) do
		self.sounds[soundClass] = soundData
	end

	self:preloadSounds()
end

function SoundInfo:preloadSounds()
	if Common.isServer then
		return
	end

	routine(function()
		local sounds = {}
		for soundClass, soundData in pairs(self.sounds) do
			local soundId = soundData["id"]
			if tonumber(soundId) == 0 then
				continue
			end
			local sound = Instance.new("Sound")
			sound.SoundId = "rbxassetid://" .. soundId
			sound.Parent = workspace
			sound.Volume = 0.0001
			sound:Play()
			table.insert(sounds, sound)
		end

		-- print("PRELOADING SOUNDS: ", len(sounds))

		ContentProvider:PreloadAsync(sounds)

		for _, sound in sounds do
			sound:Destroy()
		end
	end)
end

SoundInfo:init()

return SoundInfo
