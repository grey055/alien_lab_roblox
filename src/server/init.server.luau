--!strict
-- Rojo maps this file to ServerScriptService.Server (a Script).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local shared = ReplicatedStorage:WaitForChild("Shared")
local AlienData = require(shared:WaitForChild("AlienData"))
local LabService = require(script:WaitForChild("LabService"))
local LabWorld = require(script:WaitForChild("LabWorld"))
local Persistence = require(script:WaitForChild("DataPersistence"))
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

remote("UpgradeLab").OnServerEvent:Connect(function(player: Player)
	if not allowRequest(player, "Upgrade", 0.5) then return end
	local result = LabService.UpgradeLab(player)
	sendState(player)
	actionResult:FireClient(player, result)
end)

remote("ReleaseSlime").OnServerEvent:Connect(function(player: Player)
	if not allowRequest(player, "Release", 0.5) then return end
	local result = LabService.ReleaseWeakest(player)
	if result.Success and result.AlienId then LabWorld.RemoveAlien(player, result.AlienId) end
	sendState(player); actionResult:FireClient(player, result)
end)

local loading: { [Player]: boolean } = {}
local closing = false
local function addPlayer(player: Player)
	if closing or loading[player] or LabService.GetState(player) then return end
	loading[player] = true
	local saved, status = Persistence.Load(player)
	loading[player] = nil
	-- Loading can yield. A player who left during that wait must not get a ghost farm.
	if closing or player.Parent ~= Players then
		if saved then Persistence.Save(player, saved, true) end
		return
	end
	if status == "Locked" then player:Kick("Your lab is open in another server. Please reconnect in a moment."); return end
	LabService.AddPlayer(player, saved, status)
	requestTimes[player] = requestTimes[player] or {}
	LabWorld.AddPlayer(player, hatchEgg, sellSlime, (LabService.Export(player) :: any).Aliens, function(owner: Player)
		if allowRequest(owner, "Upgrade", 0.5) then
			local result = LabService.UpgradeLab(owner); sendState(owner); actionResult:FireClient(owner, result)
		end
	end)
	sendState(player)
end

Players.PlayerAdded:Connect(addPlayer)
Players.PlayerRemoving:Connect(function(player: Player)
	local snapshot = LabService.Export(player)
	LabService.RemovePlayer(player)
	LabWorld.RemovePlayer(player)
	requestTimes[player] = nil
	if snapshot then Persistence.Save(player, snapshot, true) end
end)
for _, player in Players:GetPlayers() do
	task.spawn(addPlayer, player)
end

-- One production loop for the whole server. Nothing is produced on the client.
task.spawn(function()
	while not closing do
		local elapsed = task.wait(AlienData.ProductionInterval)
		if closing then break end
		for _, player in Players:GetPlayers() do
			LabService.ProduceSlime(player, elapsed)
			sendState(player)
		end
	end
end)

-- Saves never block slime production. Shutdown and leaving release the session lock.
task.spawn(function()
	while not closing do
		task.wait(60)
		if closing then break end
		for _, player in Players:GetPlayers() do
			task.spawn(function()
				local snapshot = LabService.Export(player)
				if snapshot then
					local status = Persistence.Save(player, snapshot)
					-- Expired ownership means another server may now be playing this profile.
					if status == "Save session expired" then player:Kick("Your save session expired. Please reconnect safely."); return end
					if not closing then LabService.SetSaveStatus(player, status); sendState(player) end
				end
			end)
		end
	end
end)
game:BindToClose(function()
	closing = true
	local pending = 0
	for _, player in Players:GetPlayers() do
		local snapshot = LabService.Export(player)
		if snapshot then
			pending += 1
			task.spawn(function() Persistence.Save(player, snapshot, true); pending -= 1 end)
		end
	end
	local deadline = os.clock() + 25
	while pending > 0 and os.clock() < deadline do task.wait(0.1) end
end)

print("Alien Lab v0.3 garden server ready")
