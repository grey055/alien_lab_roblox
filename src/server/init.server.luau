--!strict
-- Rojo maps this file to ServerScriptService.Server (a Script).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local shared = ReplicatedStorage:WaitForChild("Shared")
local AlienData = require(shared:WaitForChild("AlienData"))
local LabService = require(script:WaitForChild("LabService"))
local remotes = shared:WaitForChild("Remotes")

local function remote(name: string): RemoteEvent
	return remotes:WaitForChild(name) :: RemoteEvent
end

local stateUpdated = remote("StateUpdated")
local hatchResult = remote("HatchResult")
local actionResult = remote("ActionResult")

-- Each request has a short server rate limit, including malformed requests.
-- Dropping excessive requests also avoids flooding the client with replies.
local requestTimes: { [Player]: { [string]: number } } = {}
local function allowRequest(player: Player, action: string, interval: number): boolean
	local times = requestTimes[player]
	if not times then
		return false
	end
	local now = os.clock()
	local last = times[action]
	if last and now - last < interval then
		return false
	end
	times[action] = now
	return true
end

local function sendState(player: Player)
	local state = LabService.GetState(player)
	if state then
		stateUpdated:FireClient(player, state)
	end
end

remote("RequestState").OnServerEvent:Connect(function(player: Player)
	if allowRequest(player, "State", 1) then
		sendState(player)
	end
end)

remote("HatchEgg").OnServerEvent:Connect(function(player: Player, eggId: any)
	if not allowRequest(player, "Hatch", 0.25) then
		return
	end
	local result = LabService.HatchEgg(player, eggId)
	sendState(player)
	hatchResult:FireClient(player, result)
end)

remote("SellSlime").OnServerEvent:Connect(function(player: Player)
	if not allowRequest(player, "Sell", AlienData.SellCooldown) then
		return
	end
	local result = LabService.SellSlime(player)
	sendState(player)
	actionResult:FireClient(player, result)
end)

local function addPlayer(player: Player)
	LabService.AddPlayer(player)
	requestTimes[player] = requestTimes[player] or {}
	sendState(player)
end

Players.PlayerAdded:Connect(addPlayer)
Players.PlayerRemoving:Connect(function(player: Player)
	LabService.RemovePlayer(player)
	requestTimes[player] = nil
end)
for _, player in Players:GetPlayers() do
	addPlayer(player)
end

-- One production loop for the whole server. Nothing is produced on the client.
task.spawn(function()
	while true do
		local elapsed = task.wait(AlienData.ProductionInterval)
		for _, player in Players:GetPlayers() do
			LabService.ProduceSlime(player, elapsed)
			sendState(player)
		end
	end
end)

print("Alien Lab v0.1 server ready")
