--!strict
-- Edit these prices and timers to balance your own alien farming game.
local FarmData = {}
FarmData.BedCount = 12
FarmData.StartingSeeds = { StarCarrot = 5 }
FarmData.CropOrder = { "StarCarrot", "MoonBerry", "GlowShroom", "CrystalBloom", "CometMelon" }
FarmData.Crops = {
	StarCarrot = { DisplayName = "Star Carrot", SeedPrice = 10, GrowSeconds = 20, SellValue = 28, Color = { 255, 164, 74 }, Category = "Root", Event = false },
	MoonBerry = { DisplayName = "Moon Berry", SeedPrice = 40, GrowSeconds = 35, SellValue = 100, Color = { 92, 207, 255 }, Category = "Berry", Event = false },
	GlowShroom = { DisplayName = "Glow Shroom", SeedPrice = 100, GrowSeconds = 50, SellValue = 260, Color = { 251, 133, 207 }, Category = "Mushroom", Event = false },
	CrystalBloom = { DisplayName = "Crystal Bloom", SeedPrice = 250, GrowSeconds = 75, SellValue = 620, Color = { 173, 121, 251 }, Category = "Crystal", Event = false },
	CometMelon = { DisplayName = "Comet Melon", SeedPrice = 500, GrowSeconds = 90, SellValue = 1350, Color = { 141, 238, 184 }, Category = "Fruit", Event = false },
	NebulaSprout = { DisplayName = "Nebula Sprout", SeedPrice = 0, GrowSeconds = 45, SellValue = 0, Color = { 125, 250, 245 }, Category = "Event", Event = true },
}
FarmData.ToolOrder = { "WateringCan", "Sprinkler", "Scanner" }
FarmData.Tools = {
	WateringCan = { DisplayName = "Stellar Watering Can", Price = 120, Color = { 103, 208, 255 }, Description = "Watering adds 30% growth instead of 15%. Each plant can be watered once." },
	Sprinkler = { DisplayName = "Orbit Sprinkler", Price = 750, Color = { 124, 247, 192 }, Description = "A permanent upgrade: all crops grow 20% faster." },
	Scanner = { DisplayName = "Mutation Scanner", Price = 450, Color = { 203, 161, 255 }, Description = "New crops gain an extra 5% chance for a golden mutation worth 2x." },
}
FarmData.Event = { Title = "THE COMET HARVEST", CropId = "NebulaSprout", Required = 3,
	CashReward = 500, SeedRewardId = "CrystalBloom", SeedRewardCount = 2 }
FarmData.MutationMultiplier = { Normal = 1, Golden = 2, Cosmic = 3 }
return FarmData
