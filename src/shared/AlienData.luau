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

AlienData.Aliens = {
	Slimelet = { DisplayName = "Slimelet", Rarity = "Common", SlimePerSecond = 1, BodyColor = { 100, 226, 123 } },
	Glowbug = { DisplayName = "Glowbug", Rarity = "Uncommon", SlimePerSecond = 3, BodyColor = { 64, 220, 215 } },
	Starling = { DisplayName = "Starling", Rarity = "Rare", SlimePerSecond = 6, BodyColor = { 184, 143, 255 } },
} :: { [string]: Alien }

AlienData.StarterEgg = {
	Id = "Starter",
	DisplayName = "Starter Egg",
	Price = 50,
	HatchCooldown = 2,
	-- Weights add up to 100: 60%, 30%, and 10%. The server rolls the result.
	Pool = {
		{ AlienId = "Slimelet", Weight = 60 },
		{ AlienId = "Glowbug", Weight = 30 },
		{ AlienId = "Starling", Weight = 10 },
	},
}

return AlienData
