local HttpService = game:GetService("HttpService")

local ProxyManager = {}

local ServerMod = require(game.ServerScriptService.ServerMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

function ProxyManager:init() end

local PROXY_TOKEN = "secretproxytokenhehe123"
local PROXY_LIST = {
	"http://129.159.38.13/", -- e2 micro proxy (probably bad long term cause its so low memory/cpu)
}

function ProxyManager:callAPI(data)
	local url = data["url"]
	local method = data["method"] or "GET"

	local finalUrl = self:getProxyUrl({
		link = url,
		use_roblo_security = "true",
	})

	-- print("GET FINAL URL: ", finalUrl)

	local lastResponse = nil
	local lastError = nil

	local retryCount = 0
	local retryLimit = 2

	local responseData = nil

	while not responseData and retryCount < retryLimit do
		retryCount = retryCount + 1

		local success, err = pcall(function()
			local response = HttpService:RequestAsync({
				Url = finalUrl,
				Method = method,
				Headers = {
					["proxy-token"] = PROXY_TOKEN,
					["Content-Type"] = "application/json",
				},
			})

			lastResponse = response
			if response["StatusCode"] == 200 then
				responseData = HttpService:JSONDecode(response["Body"])
			else
				lastError = "Status code: "
					.. response["StatusCode"]
					.. " - "
					.. (response["Body"] or "No response body")
			end
		end)

		if not success then
			lastError = err
		end

		-- If request failed, wait before retrying
		if not responseData then
			wait(0.3)
		end
	end

	-- If all retries failed, log warning and return error information
	if not responseData then
		warn("TRULY COULD NOT GET PROXY DATA: ", finalUrl, retryCount, lastError)
		return nil, lastError, lastResponse
	end

	return responseData
end

function ProxyManager:getProxyUrl(args)
	local finalUrl = PROXY_LIST[math.random(len(PROXY_LIST))] .. "?"

	local argString = ""

	local count = 0
	for k, v in pairs(args) do
		if count == 0 then
			argString = argString .. ("%s=%s"):format(HttpService:UrlEncode(k), HttpService:UrlEncode(v))
		else
			argString = argString .. ("&%s=%s"):format(HttpService:UrlEncode(k), HttpService:UrlEncode(v))
		end
		count = count + 1
	end

	finalUrl = finalUrl .. argString
	return finalUrl
end

ProxyManager:init()

return ProxyManager
