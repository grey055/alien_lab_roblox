--!strict
-- Shared settings: the server uses these rules; the client uses them for labels.
-- Changing a client's copy cannot change the server's cash, price, or hatch roll.
local AlienData = {}

export type Alien = {
	DisplayName: string,
	Rarity: string,
	SlimePerSecond: number,
	BodyColor: { number },
}

export type State = {
	Cash: number,
	Slime: number,
	ProductionRate: number,
	AlienCount: number,
	HatchCooldownRemaining: number,
	LastHatchedAlienId: string?,
	LabLevel: number,
	Discovered: { string },
	SaveStatus: string,
	WeakestAlienId: string,
}

export type Result = {
	Success: boolean,
	Message: string,
	AlienId: string?,
}

AlienData.StartingCash = 100
AlienData.StarterAlienId = "Slimelet"
AlienData.MaxAliens = 25
AlienData.CashPerSlime = 1
AlienData.ProductionInterval = 1
AlienData.SellCooldown = 0.5
AlienData.UpgradePrices = { 150, 400, 900, 1800, 3500 }
AlienData.BonusPerLevel = 0.25
AlienData.AlienOrder = { "Slimelet", "Glowbug", "Starling", "Blossom", "Ember", "Frost", "Nebula" }
AlienData.EggOrder = { "Starter", "Botanical", "Cosmic" }

AlienData.Aliens = {
	Slimelet = { DisplayName = "Slimelet", Rarity = "Common", SlimePerSecond = 1, BodyColor = { 100, 226, 123 } },
	Glowbug = { DisplayName = "Glowbug", Rarity = "Uncommon", SlimePerSecond = 3, BodyColor = { 64, 220, 215 } },
	Starling = { DisplayName = "Starling", Rarity = "Rare", SlimePerSecond = 6, BodyColor = { 184, 143, 255 } },
	Blossom = { DisplayName = "Blossom", Rarity = "Rare", SlimePerSecond = 8, BodyColor = { 255, 148, 191 } },
	Ember = { DisplayName = "Ember", Rarity = "Epic", SlimePerSecond = 12, BodyColor = { 255, 152, 83 } },
	Frost = { DisplayName = "Frost", Rarity = "Epic", SlimePerSecond = 18, BodyColor = { 146, 218, 255 } },
	Nebula = { DisplayName = "Nebula", Rarity = "Legendary", SlimePerSecond = 30, BodyColor = { 160, 113, 255 } },
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
