--!strict
-- All balances, upgrades, and hatch rolls live on the server.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AlienData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("AlienData"))

type Profile = {
	Cash: number,
	Slime: number,
	Aliens: { string },
	SlimeRemainder: number,
	NextHatchAt: number,
	NextSellAt: number,
	LastHatchedAlienId: string?,
	CashValue: IntValue,
	LabLevel: number,
	Discovered: { [string]: boolean },
	SaveStatus: string,
}

local LabService = {}
local profiles: { [Player]: Profile } = {}
local random = Random.new()

local function failure(message: string): AlienData.Result
	return { Success = false, Message = message }
end

local function productionRate(profile: Profile): number
	local rate = 0
	for _, alienId in profile.Aliens do
		rate += AlienData.Aliens[alienId].SlimePerSecond
	end
	return rate * (1 + profile.LabLevel * AlienData.BonusPerLevel)
end

local function weakest(profile: Profile): (number, string)
	local index = 1
	for i, id in profile.Aliens do
		if AlienData.Aliens[id].SlimePerSecond < AlienData.Aliens[profile.Aliens[index]].SlimePerSecond then index = i end
	end
	return index, profile.Aliens[index]
end

function LabService.AddPlayer(player: Player, saved: any?, saveStatus: string?)
	-- Covers both PlayerAdded and players already present when the script starts.
	if profiles[player] then
		return
	end

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats" -- Roblox requires this exact lowercase name.
	local cash = Instance.new("IntValue")
	cash.Name = "Cash"
	cash.Value = if saved then saved.Cash else AlienData.StartingCash
	cash.Parent = leaderstats
	leaderstats.Parent = player

	profiles[player] = {
		Cash = cash.Value,
		Slime = if saved then saved.Slime else 0,
		Aliens = if saved then table.clone(saved.Aliens) else { AlienData.StarterAlienId },
		LabLevel = if saved then saved.LabLevel else 0,
		Discovered = if saved then table.clone(saved.Discovered) else { [AlienData.StarterAlienId] = true },
		SaveStatus = saveStatus or "Session mode",
		SlimeRemainder = 0,
		NextHatchAt = 0,
		NextSellAt = 0,
		LastHatchedAlienId = nil,
		CashValue = cash,
	}
end

function LabService.RemovePlayer(player: Player)
	profiles[player] = nil
end

function LabService.GetState(player: Player): AlienData.State?
	local profile = profiles[player]
	if not profile then
		return nil
	end

	-- Send a small copy; the private inventory and leaderstats object stay here.
	local discovered = {}
	for _, id in AlienData.AlienOrder do
		if profile.Discovered[id] then table.insert(discovered, id) end
	end
	return {
		Cash = profile.Cash,
		Slime = profile.Slime,
		ProductionRate = productionRate(profile),
		AlienCount = #profile.Aliens,
		HatchCooldownRemaining = math.max(0, profile.NextHatchAt - os.clock()),
		LastHatchedAlienId = profile.LastHatchedAlienId,
		LabLevel = profile.LabLevel,
		Discovered = discovered,
		SaveStatus = profile.SaveStatus,
		WeakestAlienId = select(2, weakest(profile)),
	}
end

function LabService.ProduceSlime(player: Player, elapsed: number)
	local profile = profiles[player]
	if not profile then
		return
	end

	-- task.wait may take slightly longer than one second. Keep fractional slime
	-- so production follows elapsed time without losing those small differences.
	profile.SlimeRemainder += productionRate(profile) * elapsed
	local wholeSlime = math.floor(profile.SlimeRemainder)
	profile.Slime += wholeSlime
	profile.SlimeRemainder -= wholeSlime
end

function LabService.HatchEgg(player: Player, eggId: any): AlienData.Result
	local profile = profiles[player]
	if not profile then
		return failure("Your lab is still loading. Please try again.")
	end

	-- The client may request only this egg ID. Never accept a client price,
	-- balance, alien result, or quantity. Tables and unknown IDs are rejected.
	if typeof(eggId) ~= "string" or not AlienData.Eggs[eggId] then
		return failure("That egg does not exist.")
	end
	local egg = AlienData.Eggs[eggId]
	if profile.LabLevel < egg.RequiredLevel then
		return failure(string.format("Upgrade your lab to level %d first!", egg.RequiredLevel))
	end

	local now = os.clock()
	if now < profile.NextHatchAt then
		return failure("Please wait for your egg cooldown.")
	end
	if #profile.Aliens >= AlienData.MaxAliens then
		return failure(string.format("Your lab is full (%d aliens).", AlienData.MaxAliens))
	end
	if profile.Cash < egg.Price then
		return failure("Not enough cash. Sell some slime first!")
	end

	local totalWeight = 0
	for _, entry in egg.Pool do
		totalWeight += entry.Weight
	end
	local roll = random:NextInteger(1, totalWeight)
	local runningWeight = 0
	local alienId = egg.Pool[#egg.Pool].AlienId
	for _, entry in egg.Pool do
		runningWeight += entry.Weight
		if roll <= runningWeight then
			alienId = entry.AlienId
			break
		end
	end

	-- No waits between validation, payment, and granting the alien: another
	-- request cannot spend the same cash while this purchase is in progress.
	profile.Cash -= egg.Price
	profile.CashValue.Value = profile.Cash
	table.insert(profile.Aliens, alienId) -- Duplicates are allowed and all produce.
	profile.NextHatchAt = now + egg.HatchCooldown
	profile.LastHatchedAlienId = alienId
	profile.Discovered[alienId] = true

	return { Success = true, Message = "Egg hatched!", AlienId = alienId }
end

function LabService.SellSlime(player: Player): AlienData.Result
	local profile = profiles[player]
	if not profile then
		return failure("Your lab is still loading. Please try again.")
	end

	local now = os.clock()
	if now < profile.NextSellAt then
		return failure("Please wait before selling again.")
	end
	profile.NextSellAt = now + AlienData.SellCooldown
	if profile.Slime <= 0 then
		return failure("You have no slime to sell yet.")
	end

	-- Sell the server's entire slime balance. The client sends no amount.
	local sold = profile.Slime
	local earned = sold * AlienData.CashPerSlime
	profile.Slime = 0
	profile.Cash += earned
	profile.CashValue.Value = profile.Cash
	return { Success = true, Message = string.format("Sold %d slime for $%d.", sold, earned) }
end

function LabService.UpgradeLab(player: Player): AlienData.Result
	local profile = profiles[player]
	if not profile then return failure("Your lab is still loading.") end
	local price = AlienData.UpgradePrices[profile.LabLevel + 1]
	if not price then return failure("Your lab is fully upgraded!") end
	if profile.Cash < price then return failure("Sell more slime to afford this upgrade.") end
	-- One uninterrupted transaction; neither the price nor the level comes from the client.
	profile.Cash -= price
	profile.CashValue.Value = profile.Cash
	profile.LabLevel += 1
	return { Success = true, Message = string.format("Lab level %d! All slimes now produce faster.", profile.LabLevel) }
end

function LabService.SetSaveStatus(player: Player, status: string)
	local profile = profiles[player]
	if profile then profile.SaveStatus = status end
end

function LabService.ReleaseWeakest(player: Player): AlienData.Result
	local profile = profiles[player]
	if not profile then return failure("Your lab is still loading.") end
	if #profile.Aliens <= 1 then return failure("Keep at least one slime in your garden!") end
	local index, id = weakest(profile)
	table.remove(profile.Aliens, index)
	-- Discoveries stay unlocked. Releasing gives no refund; it makes room for a better hatch.
	return { Success = true, AlienId = id, Message = "Released " .. AlienData.Aliens[id].DisplayName .. ". Collection discovery kept." }
end

function LabService.Export(player: Player): any?
	local profile = profiles[player]
	if not profile then return nil end
	-- Saving receives a copy, so production can continue while a write yields.
	return { Cash = profile.Cash, Slime = profile.Slime, Aliens = table.clone(profile.Aliens),
		LabLevel = profile.LabLevel, Discovered = table.clone(profile.Discovered) }
end

return LabService
