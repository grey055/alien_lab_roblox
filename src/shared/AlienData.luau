--!strict
-- Shared settings: the server uses these rules; the client uses them for labels.
-- Changing a client's copy cannot change the server's cash, price, or hatch roll.
local AlienData = {}

export type Alien = {
	DisplayName: string,
	Rarity: string,
	SlimePerSecond: number,
	BodyColor: { number },
	PassiveName: string,
	PassiveDescription: string,
}

-- Farming snapshots contain copied inventories and planting beds; no private objects.
export type State = { [string]: any }

export type Result = {
	Success: boolean,
	Message: string,
	AlienId: string?,
}

AlienData.StartingCash = 100
AlienData.StarterAlienId = "Slimelet"
AlienData.MaxAliens = 25
AlienData.ProductionInterval = 1
AlienData.SellCooldown = 0.5
AlienData.UpgradePrices = { 150, 400, 900, 1800, 3500 }
AlienData.BonusPerLevel = 0.10
AlienData.MaxEquipped = 3
AlienData.AlienOrder = { "Slimelet", "Glowbug", "Starling", "Blossom", "Ember", "Frost", "Nebula" }
AlienData.EggOrder = { "Starter", "Botanical", "Cosmic" }

AlienData.Aliens = {
	Slimelet = { DisplayName = "Gloop", Rarity = "Common", SlimePerSecond = 1, BodyColor = { 146, 235, 78 }, PassiveName = "Green Thumb", PassiveDescription = "All crops grow 10% faster." },
	Glowbug = { DisplayName = "Orbit", Rarity = "Uncommon", SlimePerSecond = 3, BodyColor = { 91, 189, 250 }, PassiveName = "Hydro Helper", PassiveDescription = "Watering adds 10% more growth." },
	Starling = { DisplayName = "Starlight", Rarity = "Rare", SlimePerSecond = 6, BodyColor = { 174, 137, 252 }, PassiveName = "Lucky Stars", PassiveDescription = "New crops have an extra 8% golden mutation chance." },
	Blossom = { DisplayName = "Petal", Rarity = "Rare", SlimePerSecond = 8, BodyColor = { 251, 154, 200 }, PassiveName = "Berry Bloom", PassiveDescription = "Berry harvests are worth 25% more." },
	Ember = { DisplayName = "Cinder", Rarity = "Epic", SlimePerSecond = 12, BodyColor = { 248, 169, 83 }, PassiveName = "Crystal Keeper", PassiveDescription = "Crystal harvests are worth 35% more." },
	Frost = { DisplayName = "Sprout", Rarity = "Epic", SlimePerSecond = 18, BodyColor = { 103, 213, 174 }, PassiveName = "Seed Saver", PassiveDescription = "20% chance to keep a seed when planting." },
	Nebula = { DisplayName = "Nova", Rarity = "Legendary", SlimePerSecond = 30, BodyColor = { 255, 214, 91 }, PassiveName = "Cosmic Touch", PassiveDescription = "4% chance for new crops to gain a 3x cosmic mutation." },
} :: { [string]: Alien }

AlienData.StarterEgg = {
	Id = "Starter",
	DisplayName = "Starter Egg",
	Price = 50,
	HatchCooldown = 2,
	RequiredLevel = 0,
	Color = { 139, 244, 166 },
	-- Weights add up to 100: 60%, 30%, and 10%. The server rolls the result.
	Pool = {
		{ AlienId = "Slimelet", Weight = 60 },
		{ AlienId = "Glowbug", Weight = 30 },
		{ AlienId = "Starling", Weight = 10 },
	},
}

AlienData.Eggs = {
	Starter = AlienData.StarterEgg,
	Botanical = {
		Id = "Botanical", DisplayName = "Botanical Egg", Price = 250, HatchCooldown = 2,
		RequiredLevel = 1, Color = { 255, 160, 200 },
		Pool = { { AlienId = "Glowbug", Weight = 35 }, { AlienId = "Blossom", Weight = 50 }, { AlienId = "Ember", Weight = 15 } },
	},
	Cosmic = {
		Id = "Cosmic", DisplayName = "Cosmic Egg", Price = 1000, HatchCooldown = 2,
		RequiredLevel = 2, Color = { 179, 147, 255 },
		Pool = { { AlienId = "Starling", Weight = 30 }, { AlienId = "Frost", Weight = 55 }, { AlienId = "Nebula", Weight = 15 } },
	},
}

return AlienData
