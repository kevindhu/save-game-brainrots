local ContentProvider = game:GetService("ContentProvider")

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local PetAnimInfo = {}

PetAnimInfo["attack"] = {
	["CappuccinoAssassino"] = 84328023522196,
	["TungTungSahur"] = 107008863057314,
	["Boneca"] = 110782678643770,
	["TrippiTroppi"] = 134409113475354,
	["LiriLira"] = 72182948608400,
	["Ballerina"] = 134188956217795,
	["FrigoCamelo"] = 107085450519778,
	["ChimpBanana"] = 84806177715586,
	["TaTaTaSahur"] = 99717797020746,
	["CapybaraCoconut"] = 133396386564399,
	["DolphinBanana"] = 96157503369906,
	["FishCatLegs"] = 79339225807055,
	["GooseBomber"] = 91564835054510,
	["TralaleloTralala"] = 138125393338516,
	["GlorboFruttoDrillo"] = 118521496050048,
	["RhinoToast"] = 82522027408241,
	["BrrBrrPatapim"] = 137376496131073,
	["ElephantCoconut"] = 130339294507406,
	["TimCheese"] = 87593436991240,
	["GiraffeWatermelon"] = 73391323342941,

	["MonkeyPineapple"] = 117913332407420,
	["OwlAvocado"] = 98552427825566,
	["OrangeDunDun"] = 78678402960492,
	["CowPlanet"] = 70430683365935,
	["OctopusBlueberry"] = 110091389926317,
	["SaltCombined"] = 102660911157825,
	["GorillaWatermelon"] = 119971831538473,
	["MilkShake"] = 0,
	["GrapeSquid"] = 0,
}

PetAnimInfo["idle"] = {
	["CappuccinoAssassino"] = 116646662173314,
	["TungTungSahur"] = 87786602268250,
	["Boneca"] = 113969209734316,
	["TrippiTroppi"] = 136784726548909,
	["LiriLira"] = 129884016874815,
	["Ballerina"] = 87325960722852,
	["FrigoCamelo"] = 134246306295965,
	["ChimpBanana"] = 94688130043368,
	["TaTaTaSahur"] = 81660513054020,
	["CapybaraCoconut"] = 132126212003512,
	["DolphinBanana"] = 107404783703827,
	["FishCatLegs"] = 79996537245156,
	["GooseBomber"] = 74839622338924,
	["TralaleloTralala"] = 125944456076737,
	["GlorboFruttoDrillo"] = 95046618484615,
	["RhinoToast"] = 136381580777641,
	["BrrBrrPatapim"] = 100695145014557, -- bad
	["ElephantCoconut"] = 81491657073708,
	["TimCheese"] = 92935710957935,
	["GiraffeWatermelon"] = 129319326323852,
	["MonkeyPineapple"] = 76936232777638,
	["OwlAvocado"] = 103466877891848,
	["OrangeDunDun"] = 72715789162395,
	["CowPlanet"] = 133846273390238,
	["OctopusBlueberry"] = 87961185193866,
	["SaltCombined"] = 124113804483622, -- 84113127788715,
	["GorillaWatermelon"] = 128010056318634,
	["MilkShake"] = 0,
	["GrapeSquid"] = 0,
}

PetAnimInfo["running"] = {
	["CappuccinoAssassino"] = 95465583144937,
	["TungTungSahur"] = 86798603777066,
	["Boneca"] = 87507928516836,
	["TrippiTroppi"] = 124097601008133,
	["LiriLira"] = 111134859234915,
	["Ballerina"] = 101484693977188,
	["FrigoCamelo"] = 111307672201020,
	["ChimpBanana"] = 119562344226392,
	["TaTaTaSahur"] = 118897024669269, -- very bad
	["CapybaraCoconut"] = 76901508024097,
	["DolphinBanana"] = 110730017980085,
	["FishCatLegs"] = 72752592091221,
	["GooseBomber"] = 116820905035669,
	["TralaleloTralala"] = 96105879410116,
	["GlorboFruttoDrillo"] = 91597618896176,
	["RhinoToast"] = 131074282070529,
	["BrrBrrPatapim"] = 133788569219043,
	["ElephantCoconut"] = 73600214374480,
	["TimCheese"] = 124968142730672,
	["GiraffeWatermelon"] = 120263240089603,
	["MonkeyPineapple"] = 109111908557374,
	["OwlAvocado"] = 80648685514829,
	["OrangeDunDun"] = 77728469628913, -- 115598384378919 (old/bad but could be better if extract from .blend),
	["CowPlanet"] = 88198526719985,
	["OctopusBlueberry"] = 81235521122233,
	["SaltCombined"] = 109976574571139,
	["GorillaWatermelon"] = 130419014386420,
	["MilkShake"] = 0,
	["GrapeSquid"] = 0,
}

function PetAnimInfo:init()
	self:preloadAnimations()
end

function PetAnimInfo:preloadAnimations()
	if Common.isServer then
		return
	end

	local delayTimer = 0.5
	routine(function()
		wait(delayTimer)

		local animations = {}

		local animationList = {
			"attack",
			"idle",
			"running",
		}
		for _, animationClass in pairs(animationList) do
			for _, animationId in pairs(PetAnimInfo[animationClass]) do
				if animationId == -1 or animationId == 0 then
					continue
				end

				local animation = Instance.new("Animation")
				animation.AnimationId = "rbxassetid://" .. animationId
				table.insert(animations, animation)
			end
		end

		-- print("PRELOADING PET ANIMATIONS: ", len(animations))

		ContentProvider:PreloadAsync(animations)
	end)
end

PetAnimInfo:init()

return PetAnimInfo
