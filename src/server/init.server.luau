--!strict
-- Server startup: player farms, validated requests, crop growth, and safe saves.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local shared = ReplicatedStorage:WaitForChild("Shared")
local AlienData = require(shared:WaitForChild("AlienData"))
local LabService = require(script:WaitForChild("LabService"))
local LabWorld = require(script:WaitForChild("LabWorld"))
local Persistence = require(script:WaitForChild("DataPersistence"))
local remotes = shared:WaitForChild("Remotes")
local function remote(name: string): RemoteEvent return remotes:WaitForChild(name) :: RemoteEvent end
local requestTimes: { [Player]: { [string]: number } } = {}
local loading: { [Player]: boolean } = {}
local closing = false

local function allow(player: Player, action: string, interval: number): boolean
	local times = requestTimes[player]; if not times then return false end
	local now = os.clock(); local last = times[action]
	if last and now - last < interval then return false end
	times[action] = now; return true
end

local function sendState(player: Player)
	local state = LabService.GetState(player)
	if state then LabWorld.UpdatePlayer(player, state); remote("StateUpdated"):FireClient(player, state) end
end
local function reply(player: Player, result: AlienData.Result)
	sendState(player); remote("ActionResult"):FireClient(player, result)
end

remote("RequestState").OnServerEvent:Connect(function(player: Player)
	if allow(player, "State", 1) then sendState(player) end
end)

local function hatch(player: Player, id: any)
	if not allow(player, "Hatch", 0.25) then return end
	local result = LabService.HatchEgg(player, id)
	if result.Success and result.AlienId then LabWorld.AddAlien(player, result.AlienId) end
	sendState(player); remote("HatchResult"):FireClient(player, result)
end
remote("HatchEgg").OnServerEvent:Connect(hatch)

-- These transactions consume only IDs; extra client arguments cannot set prices or rewards.
for eventName, methodName in { BuySeed = "BuySeed", BuyTool = "BuyTool", SelectSeed = "SelectSeed",
	SelectAction = "SelectAction", EquipAlien = "EquipAlien" } do
	remote(eventName).OnServerEvent:Connect(function(player: Player, id: any)
		if allow(player, eventName, 0.15) then reply(player, LabService[methodName](player, id)) end
	end)
end
remote("SellHarvest").OnServerEvent:Connect(function(player: Player)
	if allow(player, "Sell", AlienData.SellCooldown) then reply(player, LabService.SellHarvest(player)) end
end)
remote("UpgradeLab").OnServerEvent:Connect(function(player: Player)
	if allow(player, "Upgrade", 0.5) then reply(player, LabService.UpgradeLab(player)) end
end)
remote("ReleaseSlime").OnServerEvent:Connect(function(player: Player)
	if not allow(player, "Release", 0.5) then return end
	local result = LabService.ReleaseWeakest(player)
	if result.Success and result.AlienId then LabWorld.RemoveAlien(player, result.AlienId) end
	reply(player, result)
end)

local function bedAction(player: Player, index: any, action: any?)
	if not allow(player, "Bed", 0.15) then return end
	-- Do not trust a clicked UI bed or a forged ProximityPrompt. Both need ownership and distance.
	if typeof(index) ~= "number" or index ~= index or index % 1 ~= 0 or not LabWorld.CanUseBed(player, index) then
		reply(player, { Success = false, Message = "Walk closer to one of your own planting beds first." }); return
	end
	reply(player, LabService.InteractBed(player, index, action))
end
remote("BedAction").OnServerEvent:Connect(bedAction)

local function claimEvent(player: Player)
	if not allow(player, "Quest", 0.5) then return end
	if not LabWorld.CanUseEvent(player) then
		reply(player, { Success = false, Message = "Visit the researcher beside the glowing comet in the plaza." }); return
	end
	reply(player, LabService.ClaimEvent(player))
	remote("OpenShop"):FireClient(player, "Event")
end
remote("ClaimEvent").OnServerEvent:Connect(claimEvent)

local function addPlayer(player: Player)
	if closing or loading[player] or LabService.GetState(player) then return end
	loading[player] = true
	local saved, status = Persistence.Load(player)
	loading[player] = nil
	if closing or player.Parent ~= Players then
		if saved then Persistence.Save(player, saved, true) end
		return
	end
	if status == "Locked" then player:Kick("Your garden save is busy or needs a newer game version. Please reconnect in a moment."); return end
	LabService.AddPlayer(player, saved, status)
	requestTimes[player] = {}
	local snapshot = LabService.Export(player) :: any
	LabWorld.AddPlayer(player, {
		OpenShop = function(owner: Player, kind: string)
			if allow(owner, "Shop", 0.25) then remote("OpenShop"):FireClient(owner, kind) end
		end,
		Bed = bedAction,
		ClaimEvent = claimEvent,
	}, snapshot.Aliens)
	sendState(player)
end
Players.PlayerAdded:Connect(addPlayer)
Players.PlayerRemoving:Connect(function(player: Player)
	local snapshot = LabService.Export(player)
	LabService.RemovePlayer(player); LabWorld.RemovePlayer(player); requestTimes[player] = nil
	if snapshot then Persistence.Save(player, snapshot, true) end
end)
for _, player in Players:GetPlayers() do task.spawn(addPlayer, player) end

task.spawn(function()
	while not closing do
		local elapsed = task.wait(AlienData.ProductionInterval)
		if closing then break end
		for _, player in Players:GetPlayers() do LabService.Tick(player, elapsed); sendState(player) end
	end
end)
task.spawn(function()
	while not closing do
		task.wait(60); if closing then break end
		for _, player in Players:GetPlayers() do
			task.spawn(function()
				local snapshot = LabService.Export(player)
				if snapshot then
					local status = Persistence.Save(player, snapshot)
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
print("Alien Lab v0.4 cosmic farming server ready")
