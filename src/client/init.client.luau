--!strict
-- Buttons send a seed ID, tool ID, alien ID, or bed number. Never a price or reward.
-- The server checks ownership, distance, cash, crop growth, and quest progress.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local shared = ReplicatedStorage:WaitForChild("Shared")
local AlienData = require(shared:WaitForChild("AlienData"))
local FarmData = require(shared:WaitForChild("FarmData"))
local UI = require(script:WaitForChild("LabUI"))
local PetController = require(script:WaitForChild("PetController"))
local remotes = shared:WaitForChild("Remotes")
local function remote(name: string): RemoteEvent
	return remotes:WaitForChild(name) :: RemoteEvent
end

PetController.Start()
local view = UI.Create(player:WaitForChild("PlayerGui") :: PlayerGui)
local state: AlienData.State? = nil
local pending = false
local requestToken = 0
local sentAt: { [string]: number } = {}
local requestIntervals = {
	HatchEgg = 0.26, SellHarvest = 0.51, UpgradeLab = 0.51,
	ReleaseSlime = 0.51, ClaimEvent = 0.51, RequestState = 1,
}

local function refresh()
	UI.Refresh(view, state, pending)
end

local function request(name: string, value: any?)
	if pending or not state then return end
	-- Ignore an accidental rapid second click before showing a waiting state.
	-- Server throttles remain authoritative even if a client removes this guard.
	local now = os.clock()
	local interval = requestIntervals[name] or 0.16
	if sentAt[name] and now - sentAt[name] < interval then return end
	sentAt[name] = now
	pending = true; requestToken += 1
	local token = requestToken
	UI.CancelHatch(view)
	view.Status.Text = if name == "HatchEgg" then "A new garden friend is hatching..." else "One little moment..."
	refresh()
	if name == "HatchEgg" and typeof(value) == "string" then UI.BeginHatch(view, value) end
	remote(name):FireServer(value)
	-- A missing server reply should not leave the whole journal stuck.
	task.delay(6, function()
		if pending and token == requestToken then
			UI.CancelHatch(view)
			pending = false; view.Status.Text = "No reply yet. Try again in a moment."
			refresh(); remote("RequestState"):FireServer()
		end
	end)
end

-- Listen before requesting the first snapshot, so an early reply is never lost.
remote("StateUpdated").OnClientEvent:Connect(function(snapshot: AlienData.State)
	state = snapshot; refresh()
end)

remote("HatchResult").OnClientEvent:Connect(function(result: AlienData.Result)
	pending = false; view.Status.Text = result.Message; refresh()
	if result.Success and result.AlienId and AlienData.Aliens[result.AlienId] then
		view.Status.Text = "Welcome " .. AlienData.Aliens[result.AlienId].DisplayName .. " to your garden!"
		local token = requestToken
		task.delay(0.35, function()
			if token == requestToken then UI.Reveal(view, result.AlienId :: string) end
		end)
	else
		UI.CancelHatch(view)
	end
end)

remote("ActionResult").OnClientEvent:Connect(function(result: AlienData.Result)
	pending = false; view.Status.Text = result.Message; refresh()
end)

remote("OpenShop").OnClientEvent:Connect(function(kind: string)
	local aliases = { Aliens = "Collection", Pets = "Collection", Quest = "Event", Upgrade = "Lab" }
	view.Open(aliases[kind] or kind)
end)

for id, card in view.SeedShop do
	card.Buy.Activated:Connect(function()
		if state and state.Cash >= FarmData.Crops[id].SeedPrice then request("BuySeed", id) end
	end)
end

for id, item in view.SeedChoices do
	item.Activated:Connect(function()
		if state and (state.Seeds[id] or 0) > 0 then
			request("SelectSeed", id)
			view.Open("Farm")
		end
	end)
end

for action, item in view.Actions do
	item.Activated:Connect(function() request("SelectAction", action) end)
end

for index, card in view.Beds do
	card.Use.Activated:Connect(function()
		-- Grid buttons are convenient on touch; the server still requires standing by the bed.
		request("BedAction", index)
	end)
end

for id, item in view.Tools do
	item.Activated:Connect(function()
		if state and not state.Tools[id] and state.Cash >= FarmData.Tools[id].Price then request("BuyTool", id) end
	end)
end

for id, item in view.Eggs do
	item.Activated:Connect(function()
		local current = state; local egg = AlienData.Eggs[id]
		if current and current.Cash >= egg.Price and current.LabLevel >= egg.RequiredLevel
			and current.AlienCount < AlienData.MaxAliens and current.HatchCooldownRemaining <= 0 then
			request("HatchEgg", id)
		end
	end)
end

for id, card in view.Collection do
	card.Equip.Activated:Connect(function() request("EquipAlien", id) end)
end

view.Sell.Activated:Connect(function()
	if state and state.SellValue > 0 then request("SellHarvest") end
end)

view.Upgrade.Activated:Connect(function()
	if not state then return end
	local price = AlienData.UpgradePrices[state.LabLevel + 1]
	if price and state.Cash >= price then request("UpgradeLab") end
end)

view.Release.Activated:Connect(function()
	if not state or state.AlienCount <= 1 or pending then return end
	if view.ReleaseConfirmed then
		view.ReleaseConfirmed = false; request("ReleaseSlime")
	else
		view.ReleaseConfirmed = true; refresh()
		task.delay(4, function() view.ReleaseConfirmed = false; refresh() end)
	end
end)

view.EventAction.Activated:Connect(function()
	if not state then return end
	if not state.EventActive or state.EventProgress >= FarmData.Event.Required then request("ClaimEvent") end
end)

refresh()
remote("RequestState"):FireServer()
print("Alien Lab v0.4 farming client ready")
