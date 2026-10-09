--!strict
-- Client actions send only an egg ID or an upgrade request. The server owns the economy.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local shared = ReplicatedStorage:WaitForChild("Shared")
local AlienData = require(shared:WaitForChild("AlienData"))
local UI = require(script:WaitForChild("LabUI"))
local PetController = require(script:WaitForChild("PetController"))
local remotes = shared:WaitForChild("Remotes")
local function remote(name: string): RemoteEvent return remotes:WaitForChild(name) :: RemoteEvent end
PetController.Start()
local view = UI.Create(player:WaitForChild("PlayerGui") :: PlayerGui)
local state: AlienData.State? = nil
local pending = false
local requestToken = 0

local function refresh() UI.Refresh(view, state, pending) end
local function request(name: string, eggId: string?)
	if pending or not state then return end
	pending = true; requestToken += 1
	local token = requestToken
	UI.CancelHatch(view)
	view.Status.Text = if name == "HatchEgg" then "Opening your egg..." else "Working..."
	refresh()
	if name == "HatchEgg" and eggId then UI.BeginHatch(view, eggId) end
	remote(name):FireServer(eggId)
	task.delay(6, function()
		if pending and token == requestToken then
			UI.CancelHatch(view)
			pending = false; view.Status.Text = "No reply yet. Try again in a moment."; refresh(); remote("RequestState"):FireServer()
		end
	end)
end

remote("StateUpdated").OnClientEvent:Connect(function(snapshot: AlienData.State)
	state = snapshot; refresh()
end)
remote("HatchResult").OnClientEvent:Connect(function(result: AlienData.Result)
	pending = false; view.Status.Text = result.Message; refresh()
	if result.Success and result.AlienId then
		local alien = AlienData.Aliens[result.AlienId]
		view.Status.Text = "Welcome " .. alien.DisplayName .. " to your garden!"
		-- Brief anticipation before the server-approved reveal. A newer reveal supersedes this one.
		local token = requestToken
		task.delay(0.35, function() if token == requestToken then UI.Reveal(view, result.AlienId :: string) end end)
	else
		UI.CancelHatch(view)
	end
end)
remote("ActionResult").OnClientEvent:Connect(function(result: AlienData.Result)
	pending = false; view.Status.Text = result.Message; refresh()
end)
for id, b in view.Eggs do
	b.Activated:Connect(function()
		local current = state; local egg = AlienData.Eggs[id]
		if current and current.Cash >= egg.Price and current.LabLevel >= egg.RequiredLevel
			and current.AlienCount < AlienData.MaxAliens and current.HatchCooldownRemaining <= 0 then request("HatchEgg", id) end
	end)
end
view.Sell.Activated:Connect(function() if state and state.Slime > 0 then request("SellSlime") end end)
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
refresh()
remote("RequestState"):FireServer()
print("Alien Lab v0.3 garden client ready")
