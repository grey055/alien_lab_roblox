--!strict
-- All balances and owned aliens live here on the server. v0.1 has no saving yet.
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
	return rate
end

function LabService.AddPlayer(player: Player)
	-- Covers both PlayerAdded and players already present when the script starts.
	if profiles[player] then
		return
	end

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats" -- Roblox requires this exact lowercase name.
	local cash = Instance.new("IntValue")
	cash.Name = "Cash"
	cash.Value = AlienData.StartingCash
	cash.Parent = leaderstats
	leaderstats.Parent = player

	profiles[player] = {
		Cash = AlienData.StartingCash,
		Slime = 0,
		Aliens = { AlienData.StarterAlienId }, -- Your free first alien starts producing.
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
	return {
		Cash = profile.Cash,
		Slime = profile.Slime,
		ProductionRate = productionRate(profile),
		AlienCount = #profile.Aliens,
		HatchCooldownRemaining = math.max(0, profile.NextHatchAt - os.clock()),
		LastHatchedAlienId = profile.LastHatchedAlienId,
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
	local egg = AlienData.StarterEgg
	if typeof(eggId) ~= "string" or eggId ~= egg.Id then
		return failure("That egg does not exist.")
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

return LabService
