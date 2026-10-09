--!strict
-- Rojo maps this file to StarterPlayerScripts.Client (a LocalScript).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local shared = ReplicatedStorage:WaitForChild("Shared")
local AlienData = require(shared:WaitForChild("AlienData"))
local LabUI = require(script:WaitForChild("LabUI"))
local remotes = shared:WaitForChild("Remotes")

local function remote(name: string): RemoteEvent
	return remotes:WaitForChild(name) :: RemoteEvent
end

local view = LabUI.Create(player:WaitForChild("PlayerGui") :: PlayerGui)
local state: AlienData.State? = nil
local hatchPending = false
local sellPending = false
local hatchRequest = 0
local sellRequest = 0

local function refresh()
	local current = state
	if not current then
		LabUI.SetButtonEnabled(view.Hatch, false)
		LabUI.SetButtonEnabled(view.Sell, false)
		return
	end

	view.Cash.Text = string.format("Cash: $%d", current.Cash)
	view.Slime.Text = string.format("Slime: %d", current.Slime)
	view.Production.Text = string.format("Production: %d slime / second", current.ProductionRate)
	view.Aliens.Text = string.format("Aliens: %d / %d", current.AlienCount, AlienData.MaxAliens)

	local canHatch = not hatchPending and current.HatchCooldownRemaining <= 0
		and current.Cash >= AlienData.StarterEgg.Price and current.AlienCount < AlienData.MaxAliens
	if hatchPending then
		view.Hatch.Text = "Hatching..."
	elseif current.HatchCooldownRemaining > 0 then
		view.Hatch.Text = string.format("Next egg in %ds", math.ceil(current.HatchCooldownRemaining))
	elseif current.AlienCount >= AlienData.MaxAliens then
		view.Hatch.Text = "Your lab is full"
	elseif current.Cash < AlienData.StarterEgg.Price then
		view.Hatch.Text = string.format("Need $%d to hatch", AlienData.StarterEgg.Price)
	else
		view.Hatch.Text = string.format("Hatch %s ($%d)", AlienData.StarterEgg.DisplayName, AlienData.StarterEgg.Price)
	end
	view.Sell.Text = if sellPending then "Selling..." else "Sell all slime"
	LabUI.SetButtonEnabled(view.Hatch, canHatch)
	LabUI.SetButtonEnabled(view.Sell, not sellPending and current.Slime > 0)

	if current.LastHatchedAlienId then
		local alien = AlienData.Aliens[current.LastHatchedAlienId]
		view.Result.Text = string.format("Last hatch: %s (%s)", alien.DisplayName, alien.Rarity)
	end
end

-- Connect listeners BEFORE requesting the first snapshot. This also handles
-- a client whose UI started after the server sent its PlayerAdded update.
remote("StateUpdated").OnClientEvent:Connect(function(snapshot: AlienData.State)
	state = snapshot
	refresh()
end)

remote("HatchResult").OnClientEvent:Connect(function(result: AlienData.Result)
	hatchPending = false
	view.Status.Text = result.Message
	refresh()
end)

remote("ActionResult").OnClientEvent:Connect(function(result: AlienData.Result)
	sellPending = false
	view.Status.Text = result.Message
	refresh()
end)

view.Hatch.Activated:Connect(function()
	local current = state
	if not current or hatchPending or current.HatchCooldownRemaining > 0
		or current.Cash < AlienData.StarterEgg.Price or current.AlienCount >= AlienData.MaxAliens then
		return
	end
	hatchPending = true
	hatchRequest += 1
	local request = hatchRequest
	refresh()
	-- Only ask for an egg ID; the server decides the price and hatch outcome.
	remote("HatchEgg"):FireServer(AlienData.StarterEgg.Id)
	task.delay(5, function()
		if hatchPending and hatchRequest == request then
			hatchPending = false
			view.Status.Text = "No hatch reply yet. Please try again."
			refresh()
		end
	end)
end)

view.Sell.Activated:Connect(function()
	local current = state
	if not current or sellPending or current.Slime <= 0 then
		return
	end
	sellPending = true
	sellRequest += 1
	local request = sellRequest
	refresh()
	remote("SellSlime"):FireServer()
	task.delay(5, function()
		if sellPending and sellRequest == request then
			sellPending = false
			view.Status.Text = "No sell reply yet. Please try again."
			refresh()
		end
	end)
end)

refresh()
remote("RequestState"):FireServer()
print("Alien Lab v0.1 client ready")
