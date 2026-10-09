--!strict
-- A small art kit for the cosmic garden. Every object uses ordinary Roblox
-- parts, so beginners can inspect the built world while Play is running.
local Decor = {}
local lavender = Color3.fromRGB(137, 143, 211)
local purple = Color3.fromRGB(101, 80, 157)
local cyan = Color3.fromRGB(113, 242, 255)
local pink = Color3.fromRGB(240, 151, 248)
local cream = Color3.fromRGB(255, 237, 190)
local wood = Color3.fromRGB(153, 102, 75)

function Decor.Part(parent: Instance, name: string, size: Vector3, at: CFrame, tint: Color3, shape: Enum.PartType?): Part
	local p = Instance.new("Part")
	p.Name = name; p.Size = size; p.CFrame = at; p.Color = tint
	p.Anchored = true; p.Material = Enum.Material.SmoothPlastic
	-- A sphere mesh preserves stretched oval shapes. Native Ball parts render
	-- as round spheres, which would shrink mushroom roofs and soft leaves.
	local requestedShape = shape or Enum.PartType.Block
	p.Shape = if requestedShape == Enum.PartType.Ball then Enum.PartType.Block else requestedShape
	if requestedShape == Enum.PartType.Ball then
		local mesh = Instance.new("SpecialMesh"); mesh.MeshType = Enum.MeshType.Sphere; mesh.Parent = p
	end
	p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

function Decor.Ball(parent: Instance, name: string, size: Vector3, at: CFrame, tint: Color3): Part
	local p = Decor.Part(parent, name, size, at, tint, Enum.PartType.Ball)
	p.CanCollide = false
	return p
end

function Decor.Disk(parent: Instance, name: string, diameter: number, height: number, at: CFrame, tint: Color3): Part
	return Decor.Part(parent, name, Vector3.new(height, diameter, diameter), at * CFrame.Angles(0, 0, math.pi / 2), tint, Enum.PartType.Cylinder)
end

local function glow(p: Part, tint: Color3, range: number)
	p.Material = Enum.Material.Neon
	local light = Instance.new("PointLight")
	light.Color = tint; light.Brightness = 0.65; light.Range = range; light.Shadows = false; light.Parent = p
end

function Decor.Board(parent: Instance, name: string, at: CFrame, size: Vector3, title: string, subtitle: string, tint: Color3): Part
	local board = Decor.Part(parent, name, size, at, wood)
	local trim = Decor.Part(parent, "BoardInset", size - Vector3.new(0.35, 0.3, 0), at * CFrame.new(0, 0, -size.Z * 0.52), Color3.fromRGB(117, 75, 61))
	trim.CanCollide = false
	local gui = Instance.new("SurfaceGui")
	gui.Name = "SignFace"; gui.Face = Enum.NormalId.Front; gui.PixelsPerStud = 32
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; gui.LightInfluence = 0.1; gui.Parent = trim
	local heading = Instance.new("TextLabel")
	heading.Name = "Title"; heading.BackgroundTransparency = 1; heading.Size = UDim2.fromScale(0.94, 0.62)
	heading.Position = UDim2.fromScale(0.03, 0.05); heading.Font = Enum.Font.FredokaOne
	heading.Text = title; heading.TextScaled = true; heading.TextColor3 = tint; heading.TextStrokeTransparency = 0.85; heading.Parent = gui
	local detail = Instance.new("TextLabel")
	detail.Name = "Subtitle"; detail.BackgroundTransparency = 1; detail.Position = UDim2.fromScale(0.06, 0.67)
	detail.Size = UDim2.fromScale(0.88, 0.24); detail.Font = Enum.Font.GothamMedium
	detail.Text = subtitle; detail.TextScaled = true; detail.TextColor3 = cream; detail.Parent = gui
	return board
end

function Decor.Lantern(parent: Instance, at: CFrame)
	Decor.Part(parent, "LanternPost", Vector3.new(0.65, 3.6, 0.65), at * CFrame.new(0, 1.8, 0), wood)
	Decor.Part(parent, "LanternFrame", Vector3.new(1.35, 0.3, 1.35), at * CFrame.new(0, 3.65, 0), wood)
	local lamp = Decor.Part(parent, "WarmLantern", Vector3.new(0.9, 1, 0.9), at * CFrame.new(0, 4.25, 0), Color3.fromRGB(255, 218, 119))
	glow(lamp, lamp.Color, 13)
	Decor.Part(parent, "LanternRoof", Vector3.new(1.45, 0.3, 1.45), at * CFrame.new(0, 4.9, 0), wood)
end

function Decor.Crystal(parent: Instance, at: CFrame, height: number, tint: Color3)
	for i = 1, 3 do
		local angle = i * 2.2
		local length = height * (if i == 1 then 1 else 0.55)
		local p = Decor.Part(parent, "CosmicCrystal", Vector3.new(length * 0.32, length, length * 0.32),
			at * CFrame.new(math.cos(angle) * height * 0.2, length * 0.5, math.sin(angle) * height * 0.2) * CFrame.Angles(0.13, angle, 0.16), tint)
		p.Material = Enum.Material.Neon; p.CanCollide = false
		local cap = Instance.new("WedgePart")
		cap.Name = "CrystalPoint"; cap.Size = Vector3.new(length * 0.32, length * 0.35, length * 0.32)
		cap.CFrame = p.CFrame * CFrame.new(0, length * 0.63, 0); cap.Color = tint
		cap.Material = Enum.Material.Neon; cap.Anchored = true; cap.CanCollide = false; cap.Parent = parent
	end
end

function Decor.Mushroom(parent: Instance, at: CFrame, scale: number, tint: Color3)
	Decor.Part(parent, "MushroomStem", Vector3.new(scale * 0.7, scale * 2.7, scale * 0.7), at * CFrame.new(0, scale * 1.35, 0), cream)
	local cap = Decor.Ball(parent, "MushroomCap", Vector3.new(scale * 3, scale * 1.25, scale * 3), at * CFrame.new(0, scale * 3, 0), tint)
	for i = 1, 5 do
		local angle = i * math.pi * 2 / 5
		Decor.Ball(parent, "MushroomSpot", Vector3.new(scale * 0.5, scale * 0.16, scale * 0.5),
			at * CFrame.new(math.cos(angle) * scale * 0.75, scale * 3.55, math.sin(angle) * scale * 0.75), cream)
	end
	if scale > 2 then
		local light = Instance.new("PointLight"); light.Color = tint; light.Range = 15; light.Brightness = 0.25; light.Parent = cap
	end
end

function Decor.Plant(parent: Instance, at: CFrame, scale: number, tint: Color3)
	for i = 1, 4 do
		local angle = i * math.pi / 2
		Decor.Ball(parent, "WildLeaf", Vector3.new(scale * 0.7, scale * 2.5, scale * 0.36),
			at * CFrame.new(math.cos(angle) * scale * 0.5, scale, math.sin(angle) * scale * 0.5) * CFrame.Angles(0, angle, -0.5), tint)
	end
end

local function ring(parent: Instance, at: CFrame, radius: number, tint: Color3)
	for i = 1, 24 do
		local angle = i * math.pi * 2 / 24
		local p = Decor.Part(parent, "OrbitalRing", Vector3.new(0.25, 0.3, radius * math.pi / 12 + 0.12),
			at * CFrame.Angles(0, angle, 0) * CFrame.new(radius, 0, 0), tint)
		p.Material = Enum.Material.Neon; p.CanCollide = false
	end
end

local function shop(parent: Instance, kind: string, at: CFrame, tint: Color3, subtitle: string): Part
	local booth = Instance.new("Model"); booth.Name = kind .. "Shop"; booth.Parent = parent
	Decor.Disk(booth, "ShopDeck", 19, 0.5, at * CFrame.new(0, 0.25, 0), Color3.fromRGB(224, 192, 150))
	Decor.Part(booth, "BackWall", Vector3.new(15, 8, 1), at * CFrame.new(0, 4, 4.5), cream)
	for _, side in { -1, 1 } do
		Decor.Part(booth, "Pillar", Vector3.new(1.2, 10, 1.2), at * CFrame.new(side * 7, 5, -3.5), wood)
	end
	local counter = Decor.Part(booth, "ShopCounter", Vector3.new(14, 3.1, 4), at * CFrame.new(0, 1.8, -3.5), wood)
	Decor.Part(booth, "CounterTop", Vector3.new(14.6, 0.4, 4.6), at * CFrame.new(0, 3.55, -3.5), Color3.fromRGB(245, 207, 154))
	Decor.Ball(booth, "MushroomRoof", Vector3.new(22, 7, 20), at * CFrame.new(0, 10.5, 0), tint)
	for i = 1, 7 do
		local angle = i * math.pi * 2 / 7
		Decor.Ball(booth, "RoofSpot", Vector3.new(2.6, 0.3, 2.2), at * CFrame.new(math.cos(angle) * 6.5, 13.45, math.sin(angle) * 5.5), cream)
	end
	local title = ({ Seeds = "SEED SHOP", Tools = "TOOL SHOP", Eggs = "EGG SHOP", Sell = "HARVEST MARKET" })[kind]
	Decor.Board(booth, "ShopSign", at * CFrame.new(0, 8.8, -8.8), Vector3.new(14, 3.2, 0.5), title, subtitle, Color3.new(1, 1, 1))
	Decor.Lantern(booth, at * CFrame.new(-8, 0.5, -7))
	Decor.Lantern(booth, at * CFrame.new(8, 0.5, -7))
	-- Display merchandise makes the shops readable even before opening a menu.
	for i = -1, 1 do
		local offset = at * CFrame.new(i * 4, 4.6, -3.5)
		if kind == "Seeds" then
			Decor.Part(booth, "SeedPacket", Vector3.new(2.2, 2.4, 0.6), offset, tint:Lerp(cream, 0.4))
			Decor.Plant(booth, offset * CFrame.new(0, -0.8, -0.5), 0.4, Color3.fromRGB(97, 180, 104))
		elseif kind == "Eggs" then
			Decor.Ball(booth, "DisplayEgg", Vector3.new(2, 2.6, 2), offset, (if i == -1 then Color3.fromRGB(158, 243, 121) elseif i == 0 then cyan else pink))
		elseif kind == "Tools" then
			Decor.Part(booth, "WateringCan", Vector3.new(1.7, 1.3, 1.4), offset, cyan)
			Decor.Part(booth, "CanSpout", Vector3.new(1.1, 0.4, 0.4), offset * CFrame.new(1.1, 0.25, 0) * CFrame.Angles(0, 0, 0.35), cyan)
		else
			Decor.Part(booth, "HarvestCrate", Vector3.new(2.5, 1.1, 2), offset, wood)
			Decor.Ball(booth, "HarvestFruit", Vector3.new(1.5, 1.5, 1.5), offset * CFrame.new(0, 0.75, 0), Color3.fromRGB(255, 174, 72))
		end
	end
	return counter
end

function Decor.Hub(parent: Instance): { [string]: BasePart }
	local ground = 6
	-- The broad upper island completely covers the default checkerboard around
	-- the playable area. Cliff chunks and mist turn its edge into a floating world.
	local island = Decor.Disk(parent, "FloatingGardenIsland", 282, 7, CFrame.new(0, ground - 3.5, 0), lavender)
	island.Material = Enum.Material.Grass
	for i = 1, 22 do
		local angle = i * math.pi * 2 / 22
		local at = Vector3.new(math.sin(angle) * 129, -7, math.cos(angle) * 129)
		local cliff = Decor.Part(parent, "FloatingCliff", Vector3.new(23, 24 + (i % 3) * 6, 25), CFrame.new(at) * CFrame.Angles(0.12, angle, 0.12), purple:Lerp(lavender, (i % 4) * 0.08))
		cliff.Material = Enum.Material.Slate
	end
	Decor.Disk(parent, "PlazaRim", 65, 0.6, CFrame.new(0, ground + 0.3, 0), Color3.fromRGB(111, 114, 176))
	Decor.Disk(parent, "CentralPlaza", 59, 0.2, CFrame.new(0, ground + 0.7, 0), Color3.fromRGB(227, 207, 190))
	for i = 0, 5 do
		local angle = i * math.pi / 3
		local at = CFrame.new(0, ground, 0) * CFrame.Angles(0, angle, 0)
		Decor.Part(parent, "GardenPath", Vector3.new(10, 0.25, 91), at * CFrame.new(0, 0.2, 53), Color3.fromRGB(229, 209, 179))
		for z = 35, 62, 9 do
			Decor.Ball(parent, "PathStone", Vector3.new(4, 0.35, 2.5), at * CFrame.new((z % 2 - 0.5) * 3, 0.42, z), Color3.fromRGB(199, 176, 169))
		end
		Decor.Lantern(parent, at * CFrame.new(7, 0.35, 49))
	end
	local stations: { [string]: BasePart } = {}
	local settings = {
		{ Kind = "Seeds", At = Vector3.new(-34, ground, -28), Tint = Color3.fromRGB(188, 145, 239), Sub = "Plant something extraordinary" },
		{ Kind = "Tools", At = Vector3.new(34, ground, -28), Tint = Color3.fromRGB(108, 204, 235), Sub = "A little help for your garden" },
		{ Kind = "Eggs", At = Vector3.new(-34, ground, 28), Tint = Color3.fromRGB(239, 144, 194), Sub = "Meet your next garden helper" },
		{ Kind = "Sell", At = Vector3.new(34, ground, 28), Tint = Color3.fromRGB(239, 177, 100), Sub = "Fresh harvests, happy wallets" },
	}
	for _, setting in settings do
		local toward = -setting.At * Vector3.new(1, 0, 1)
		local yaw = math.atan2(-toward.X, -toward.Z)
		stations[setting.Kind] = shop(parent, setting.Kind, CFrame.new(setting.At) * CFrame.Angles(0, yaw, 0), setting.Tint, setting.Sub)
	end
	-- The planet shrine and quest captain are the unmistakable center of town.
	Decor.Disk(parent, "EventShrine", 20, 0.8, CFrame.new(0, ground + 1.05, 0), purple)
	Decor.Disk(parent, "ShrineStep", 16, 0.4, CFrame.new(0, ground + 1.65, 0), Color3.fromRGB(179, 170, 226))
	local planet = Decor.Ball(parent, "QuestPlanet", Vector3.new(7, 7, 7), CFrame.new(0, ground + 7, 1), Color3.fromRGB(98, 197, 249))
	planet.Material = Enum.Material.Glass; planet.Transparency = 0.12
	ring(parent, CFrame.new(0, ground + 7, 1) * CFrame.Angles(0.3, 0, 0.4), 5.3, cyan)
	for i = 1, 4 do
		local angle = i * math.pi / 2
		Decor.Part(parent, "ShrinePillar", Vector3.new(1.2, 3, 1.2), CFrame.new(math.sin(angle) * 8, ground + 3, math.cos(angle) * 8), purple)
		local orb = Decor.Ball(parent, "ShrineLight", Vector3.new(1.8, 1.8, 1.8), CFrame.new(math.sin(angle) * 8, ground + 5, math.cos(angle) * 8), cyan)
		glow(orb, cyan, 13)
	end
	-- Small distant islands, plants, mushrooms, and crystals frame the village.
	for i = 1, 18 do
		local angle = i * math.pi * 2 / 18
		local at = CFrame.new(math.sin(angle) * 127, ground, math.cos(angle) * 127)
		Decor.Mushroom(parent, at, 2.1 + (i % 3) * 0.6, if i % 2 == 0 then pink else Color3.fromRGB(180, 149, 246))
		Decor.Crystal(parent, at * CFrame.new(5, 0, 3), 3 + i % 4, if i % 2 == 0 then cyan else pink)
		Decor.Plant(parent, at * CFrame.new(-5, 0, -2), 1.7, Color3.fromRGB(91, 186, 177))
	end
	for i = 1, 8 do
		local angle = i * math.pi / 4
		local at = CFrame.new(math.sin(angle) * 194, 23 + (i % 3) * 10, math.cos(angle) * 194)
		Decor.Disk(parent, "DistantIsland", 24 + i % 3 * 5, 5, at, lavender)
		local rock = Decor.Part(parent, "DistantIslandRock", Vector3.new(20, 19, 20), at * CFrame.new(0, -10, 0) * CFrame.Angles(0.2, angle, 0.1), purple)
		rock.Material = Enum.Material.Slate
		Decor.Mushroom(parent, at * CFrame.new(0, 2.5, 0), 2.5, pink)
		ring(parent, at * CFrame.new(0, -7, 0), 18, cyan)
	end
	return stations
end

function Decor.Farm(parent: Instance, at: CFrame)
	Decor.Part(parent, "GardenFoundation", Vector3.new(61, 1, 48), at * CFrame.new(0, -0.35, 0), Color3.fromRGB(121, 111, 161))
	local floor = Decor.Part(parent, "GardenFloor", Vector3.new(59, 0.4, 46), at * CFrame.new(0, 0.35, 0), Color3.fromRGB(151, 161, 205))
	floor.Material = Enum.Material.Grass
	Decor.Part(parent, "CenterWalk", Vector3.new(3.4, 0.15, 41), at * CFrame.new(0, 0.63, 0), Color3.fromRGB(240, 216, 172))
	Decor.Part(parent, "GardenEntrance", Vector3.new(57, 0.15, 6), at * CFrame.new(0, 0.64, -18), Color3.fromRGB(236, 208, 171))
	for _, x in { -29, 29 } do
		for _, z in { -23, -9, 7, 23 } do Decor.Lantern(parent, at * CFrame.new(x, 0.6, z)) end
		for y = 1.9, 3.1, 1.2 do Decor.Part(parent, "FenceRail", Vector3.new(0.4, 0.45, 46), at * CFrame.new(x, y, 0), wood) end
	end
	for _, z in { -23, 23 } do
		for _, x in { -21, -7, 7, 21 } do
			if z > 0 then Decor.Part(parent, "FencePost", Vector3.new(0.7, 3.2, 0.7), at * CFrame.new(x, 2.1, z), wood) end
		end
		for y = 1.9, 3.1, 1.2 do
			if z > 0 then Decor.Part(parent, "FenceRail", Vector3.new(58, 0.45, 0.4), at * CFrame.new(0, y, z), wood)
			else
				for _, side in { -1, 1 } do Decor.Part(parent, "EntranceRail", Vector3.new(23, 0.45, 0.4), at * CFrame.new(side * 17, y, z), wood) end
			end
		end
	end
	for _, side in { -1, 1 } do
		Decor.Plant(parent, at * CFrame.new(side * 27, 0.6, 19), 1.4, Color3.fromRGB(102, 202, 167))
		Decor.Crystal(parent, at * CFrame.new(side * 26, 0.6, -12), 2.4, if side < 0 then cyan else pink)
	end
end

function Decor.Lighting()
	local Lighting = game:GetService("Lighting")
	Lighting.ClockTime = 14.5; Lighting.Brightness = 2.2
	Lighting.Ambient = Color3.fromRGB(146, 138, 190); Lighting.OutdoorAmbient = Color3.fromRGB(171, 173, 213)
	Lighting.ColorShift_Top = Color3.fromRGB(238, 199, 255); Lighting.EnvironmentDiffuseScale = 0.6
	Lighting.EnvironmentSpecularScale = 0.8; Lighting.ExposureCompensation = 0.12
	Lighting.FogColor = Color3.fromRGB(168, 161, 223); Lighting.FogStart = 150; Lighting.FogEnd = 390
	local atmosphere = Lighting:FindFirstChild("GardenAtmosphere") or Lighting:FindFirstChildOfClass("Atmosphere")
	if not atmosphere then atmosphere = Instance.new("Atmosphere"); atmosphere.Name = "GardenAtmosphere"; atmosphere.Parent = Lighting end
	if atmosphere:IsA("Atmosphere") then
		atmosphere.Density = 0.38; atmosphere.Offset = 0.12; atmosphere.Color = Color3.fromRGB(195, 180, 235)
		atmosphere.Decay = Color3.fromRGB(102, 114, 176); atmosphere.Glare = 0.15; atmosphere.Haze = 2.1
	end
	local bloom = Lighting:FindFirstChild("GardenBloom")
	if not bloom then bloom = Instance.new("BloomEffect"); bloom.Name = "GardenBloom"; bloom.Parent = Lighting end
	if bloom:IsA("BloomEffect") then bloom.Intensity = 0.2; bloom.Size = 18; bloom.Threshold = 1.4 end
end

return Decor
