--!strict
-- Rojo maps this file to ServerScriptService.Server (a Script).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local shared = ReplicatedStorage:WaitForChild("Shared")
local AlienData = require(shared:WaitForChild("AlienData"))
local LabService = require(script:WaitForChild("LabService"))
local LabWorld = require(script:WaitForChild("LabWorld"))
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
		LabWorld.UpdatePlayer(player, state)
		stateUpdated:FireClient(player, state)
	end
end

remote("RequestState").OnServerEvent:Connect(function(player: Player)
	if allowRequest(player, "State", 1) then
		sendState(player)
	end
end)

local function hatchEgg(player: Player, eggId: any)
	if not allowRequest(player, "Hatch", 0.25) then
		return
	end
	local result = LabService.HatchEgg(player, eggId)
	if result.Success and result.AlienId then
		LabWorld.AddAlien(player, result.AlienId)
	end
	sendState(player)
	hatchResult:FireClient(player, result)
end
remote("HatchEgg").OnServerEvent:Connect(hatchEgg)

local function sellSlime(player: Player)
	if not allowRequest(player, "Sell", AlienData.SellCooldown) then
		return
	end
	local result = LabService.SellSlime(player)
	sendState(player)
	actionResult:FireClient(player, result)
end
remote("SellSlime").OnServerEvent:Connect(sellSlime)

local function addPlayer(player: Player)
	LabService.AddPlayer(player)
	requestTimes[player] = requestTimes[player] or {}
	LabWorld.AddPlayer(player, function(owner: Player)
		hatchEgg(owner, AlienData.StarterEgg.Id)
	end, sellSlime)
	sendState(player)
end

Players.PlayerAdded:Connect(addPlayer)
Players.PlayerRemoving:Connect(function(player: Player)
	LabService.RemovePlayer(player)
	LabWorld.RemovePlayer(player)
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

print("Alien Lab v0.2 farm server ready")
