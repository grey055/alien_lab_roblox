--!strict
-- Cute garden companions made entirely from Roblox parts. The same model is
-- used in the garden, egg reveal, and collection cards, without external assets.
local AlienData = require(script.Parent:WaitForChild("AlienData"))
local SlimeModel = {}

function SlimeModel.Create(alienId: string): Model
	local alien = assert(AlienData.Aliens[alienId], "Unknown alien: " .. alienId)
	local color = Color3.fromRGB(alien.BodyColor[1], alien.BodyColor[2], alien.BodyColor[3])
	-- These two characters have a distinct silhouette and palette in the garden.
	if alienId == "Frost" then color = Color3.fromRGB(70, 218, 167) end
	if alienId == "Nebula" then color = Color3.fromRGB(255, 208, 76) end
	local dark = Color3.fromRGB(22, 42, 50)
	local light = color:Lerp(Color3.new(1, 1, 1), 0.42)
	local shade = color:Lerp(dark, 0.24)
	local white = Color3.fromRGB(250, 255, 252)
	local model = Instance.new("Model")
	model.Name = alien.DisplayName
	model:SetAttribute("CompanionStyle", "GardenChibi")

	local function piece(name: string, size: Vector3, position: Vector3, tint: Color3, shape: Enum.PartType?, parent: Instance?): Part
		local item = Instance.new("Part")
		item.Name = name
		item.Size = size
		item.Position = position
		item.Color = tint
		item.Material = Enum.Material.SmoothPlastic
		local requestedShape = shape or Enum.PartType.Ball
		item.Shape = if requestedShape == Enum.PartType.Ball then Enum.PartType.Block else requestedShape
		if requestedShape == Enum.PartType.Ball then
			-- A built-in stretched sphere gives the head and glossy eyes their
			-- intended oval shape without downloading an external mesh asset.
			local mesh = Instance.new("SpecialMesh"); mesh.MeshType = Enum.MeshType.Sphere; mesh.Parent = item
		end
		item.Anchored = true
		item.CanCollide = false
		item.CanTouch = false
		item.CanQuery = false
		item.CastShadow = name == "Body" or name == "Head"
		item.Parent = parent or model
		return item
	end

	local function glow(name: string, size: Vector3, position: Vector3, tint: Color3): Part
		local p = piece(name, size, position, tint)
		p.Material = Enum.Material.Neon
		return p
	end

	-- The big head, small torso, and short legs give each species a toy-like shape.
	local body = piece("Body", Vector3.new(1.9, 1.8, 1.55), Vector3.new(0, 1.75, 0), color)
	piece("Belly", Vector3.new(1.30, 1.25, 0.32), Vector3.new(0, 1.72, -0.68), light)
	piece("Head", Vector3.new(3.14, 2.64, 2.50), Vector3.new(0, 3.49, 0), color)
	piece("ForeheadShine", Vector3.new(0.59, 0.24, 0.10), Vector3.new(-0.68, 4.38, -0.81), color:Lerp(white, 0.74)).CFrame *= CFrame.Angles(0, 0, -0.28)
	piece("TinyShine", Vector3.new(0.17, 0.14, 0.08), Vector3.new(-0.20, 4.45, -0.80), color:Lerp(white, 0.70))

	local function limb(name: string, position: Vector3, size: Vector3, tint: Color3, offset: Vector3): Model
		local group = Instance.new("Model")
		group.Name = name
		group.Parent = model
		local root = piece(name .. "Root", size, position, tint, nil, group)
		root.PivotOffset = CFrame.new(offset)
		group.PrimaryPart = root
		return group
	end

	for _, side in { -1, 1 } do
		local suffix = if side < 0 then "Left" else "Right"
		local arm = limb(suffix .. "Arm", Vector3.new(side * 1.15, 1.88, 0), Vector3.new(0.68, 1.18, 0.72), color, Vector3.new(0, 0.50, 0))
		piece("Hand", Vector3.new(0.84, 0.71, 0.86), Vector3.new(side * 1.33, 1.37, -0.14), color, nil, arm)
		piece("HandShine", Vector3.new(0.21, 0.17, 0.08), Vector3.new(side * 1.37, 1.54, -0.55), light, nil, arm)
		limb(suffix .. "Leg", Vector3.new(side * 0.52, 0.45, 0), Vector3.new(0.81, 0.88, 0.91), shade, Vector3.new(0, 0.42, 0))
	end

	-- Several layers make glossy, expressive eyes without image decals.
	for _, side in { -1, 1 } do
		local suffix = if side < 0 then "Left" else "Right"
		local x = side * 0.65
		piece("Eye" .. suffix, Vector3.new(0.75, 1.03, 0.24), Vector3.new(x, 3.52, -1.13), dark)
		piece("Iris" .. suffix, Vector3.new(0.47, 0.39, 0.09), Vector3.new(x, 3.28, -1.25), shade)
		piece("EyeShine" .. suffix, Vector3.new(0.24, 0.29, 0.07), Vector3.new(x - 0.10, 3.77, -1.27), white)
		piece("EyeSpark" .. suffix, Vector3.new(0.09, 0.10, 0.06), Vector3.new(x + 0.13, 3.40, -1.29), white)
		piece("Cheek" .. suffix, Vector3.new(0.46, 0.19, 0.09), Vector3.new(side * 1.03, 3.07, -1.02), Color3.fromRGB(255, 171, 185))
		-- Hidden eyelids are animated only by the tagged world-pet controller.
		local lid = piece("Eyelid" .. suffix, Vector3.new(0.80, 1.08, 0.10), Vector3.new(x, 3.52, -1.34), color)
		lid.Transparency = 1
		local line = piece("Blink" .. suffix, Vector3.new(0.50, 0.08, 0.06), Vector3.new(x, 3.49, -1.41), dark)
		line.Transparency = 1
	end
	-- Three tiny rounded strokes make a smile, rather than a flat black bar.
	for _, side in { -1, 1 } do
		local p = piece("SmileCorner", Vector3.new(0.12, 0.22, 0.08), Vector3.new(side * 0.18, 2.98, -1.15), dark)
		p.CFrame *= CFrame.Angles(0, 0, side * 0.45)
	end
	piece("Smile", Vector3.new(0.30, 0.10, 0.08), Vector3.new(0, 2.91, -1.18), dark)

	if alienId == "Slimelet" then
		-- Glossy green drips, a soft curl, and small lime freckles.
		piece("SlimeCurlBase", Vector3.new(0.67, 0.52, 0.64), Vector3.new(0.15, 4.77, 0.01), color)
		piece("SlimeCurl", Vector3.new(0.77, 0.64, 0.61), Vector3.new(0.43, 5.05, 0.01), color).CFrame *= CFrame.Angles(0, 0, 0.45)
		piece("CurlShine", Vector3.new(0.27, 0.15, 0.09), Vector3.new(0.41, 5.22, -0.27), light)
		for _, side in { -1, 1 } do
			piece("HeadDrip", Vector3.new(0.37, 0.72, 0.26), Vector3.new(side * 1.32, 3.96, -0.57), shade)
			piece("ShoulderDrip", Vector3.new(0.35, 0.54, 0.28), Vector3.new(side * 0.83, 2.14, -0.54), light)
		end
		piece("Freckle", Vector3.new(0.22, 0.20, 0.08), Vector3.new(-0.35, 1.94, -0.89), light)
		piece("Freckle", Vector3.new(0.15, 0.15, 0.08), Vector3.new(0.32, 1.48, -0.90), light)
	elseif alienId == "Glowbug" then
		-- A curious blue technician with headphones, a scarf, and an emitter.
		local navy = Color3.fromRGB(46, 76, 126)
		for _, side in { -1, 1 } do
			piece("Headphone", Vector3.new(0.44, 1.03, 1.04), Vector3.new(side * 1.52, 3.56, 0), navy)
			glow("HeadphoneLight", Vector3.new(0.16, 0.61, 0.64), Vector3.new(side * 1.75, 3.56, -0.02), Color3.fromRGB(112, 245, 255))
			local stalk = piece("Antenna", Vector3.new(0.18, 0.79, 0.18), Vector3.new(side * 0.72, 4.94, 0), navy)
			stalk.CFrame *= CFrame.Angles(0, 0, -side * 0.33)
			glow("AntennaTip", Vector3.new(0.43, 0.43, 0.43), Vector3.new(side * 0.86, 5.29, 0), Color3.fromRGB(128, 247, 255))
		end
		piece("Scarf", Vector3.new(2.05, 0.53, 1.60), Vector3.new(0, 2.35, 0), navy)
		piece("ScarfTail", Vector3.new(0.41, 0.91, 0.21), Vector3.new(0.55, 1.91, -0.81), navy).CFrame *= CFrame.Angles(0, 0, 0.30)
		piece("ChestEmitterRim", Vector3.new(0.57, 0.57, 0.17), Vector3.new(-0.24, 2.15, -0.86), navy)
		glow("ChestEmitter", Vector3.new(0.33, 0.33, 0.12), Vector3.new(-0.24, 2.15, -0.98), Color3.fromRGB(137, 248, 255))
		piece("UtilityPouch", Vector3.new(0.73, 0.50, 0.22), Vector3.new(-0.25, 1.34, -0.88), navy)
	elseif alienId == "Blossom" then
		-- A pink axolotl companion: three translucent frills on each cheek.
		for _, side in { -1, 1 } do
			for row = -1, 1 do
				local gill = piece("Gill", Vector3.new(0.88, 0.35, 0.36), Vector3.new(side * 1.78, 3.54 + row * 0.52, 0.05), light)
				gill.CFrame *= CFrame.Angles(0, 0, side * row * 0.40)
				gill.Transparency = 0.15
				piece("GillSpot", Vector3.new(0.20, 0.12, 0.08), Vector3.new(side * 1.99, 3.54 + row * 0.52, -0.12), white)
			end
		end
		piece("Tail", Vector3.new(0.52, 1.30, 0.75), Vector3.new(0, 1.57, 1.05), light).CFrame *= CFrame.Angles(-0.55, 0, 0)
		piece("BellyHeartLeft", Vector3.new(0.32, 0.37, 0.12), Vector3.new(-0.11, 1.88, -0.90), color)
		piece("BellyHeartRight", Vector3.new(0.32, 0.37, 0.12), Vector3.new(0.11, 1.88, -0.90), color)
	elseif alienId == "Ember" then
		-- Amber crystal clusters make the rocky guardian easy to recognize.
		local amber = Color3.fromRGB(255, 169, 56)
		local rock = Color3.fromRGB(158, 101, 62)
		for i = -1, 1 do
			local crystal = piece("CrownCrystal", Vector3.new(0.55, 0.79 - math.abs(i) * 0.12, 0.55), Vector3.new(i * 0.75, 4.91, 0.02), amber, Enum.PartType.Block)
			crystal.CFrame *= CFrame.Angles(0.15, 0.70, i * 0.40)
			piece("CrownRock", Vector3.new(0.34, 0.33, 0.33), Vector3.new(i * 0.70, 4.58, -0.48), rock, Enum.PartType.Block).CFrame *= CFrame.Angles(0.2, 0.6, 0.3)
		end
		for _, side in { -1, 1 } do
			piece("TempleRock", Vector3.new(0.46, 0.46, 0.45), Vector3.new(side * 1.32, 3.18, -0.16), rock, Enum.PartType.Block).CFrame *= CFrame.Angles(0.2, 0.3, side * 0.3)
			piece("BellyRock", Vector3.new(0.32, 0.31, 0.12), Vector3.new(side * 0.44, 1.64, -0.91), rock, Enum.PartType.Block).CFrame *= CFrame.Angles(0, 0, side * 0.5)
		end
	elseif alienId == "Frost" then
		-- A mint leaf spirit with a sprout and soft leaf-shaped ears.
		for _, side in { -1, 1 } do
			for row = 0, 1 do
				local leaf = piece("LeafEar", Vector3.new(0.45, 0.92, 0.30), Vector3.new(side * 1.73, 3.88 - row * 0.71, 0.07), shade)
				leaf.CFrame *= CFrame.Angles(0, 0, side * (0.90 + row * 0.40))
			end
			piece("SproutLeaf", Vector3.new(0.47, 1.01, 0.29), Vector3.new(side * 0.33, 5.01, 0.03), Color3.fromRGB(60, 190, 125)).CFrame *= CFrame.Angles(0, 0, -side * 0.70)
			piece("ChestLeaf", Vector3.new(0.30, 0.68, 0.13), Vector3.new(side * 0.28, 2.04, -0.85), shade).CFrame *= CFrame.Angles(0, 0, -side * 0.45)
		end
		piece("LeafStem", Vector3.new(0.15, 0.52, 0.15), Vector3.new(0, 4.88, 0.03), shade)
	elseif alienId == "Nebula" then
		-- Golden friendly horns, pointed ears, and a warm little dragon tail.
		local orange = Color3.fromRGB(246, 140, 47)
		for _, side in { -1, 1 } do
			piece("HornBase", Vector3.new(0.57, 0.60, 0.54), Vector3.new(side * 0.86, 4.72, 0.03), orange)
			piece("HornTip", Vector3.new(0.38, 0.67, 0.36), Vector3.new(side * 0.94, 5.07, 0.04), orange).CFrame *= CFrame.Angles(0, 0, -side * 0.35)
			piece("DragonEar", Vector3.new(0.91, 0.34, 0.46), Vector3.new(side * 1.74, 3.78, 0.04), color).CFrame *= CFrame.Angles(0, 0, side * 0.48)
			piece("BrowSpot", Vector3.new(0.24, 0.20, 0.08), Vector3.new(side * 0.88, 4.21, -0.96), orange)
			piece("Fang", Vector3.new(0.12, 0.18, 0.08), Vector3.new(side * 0.10, 2.92, -1.23), white)
		end
		piece("DragonTail", Vector3.new(0.34, 0.50, 1.22), Vector3.new(0.10, 1.49, 1.12), orange).CFrame *= CFrame.Angles(0.35, 0.30, 0)
		piece("TailTip", Vector3.new(0.43, 0.47, 0.40), Vector3.new(0.25, 1.85, 1.65), orange, Enum.PartType.Block).CFrame *= CFrame.Angles(0.3, 0.5, 0.6)
	else
		-- Starling is the violet celestial companion with a floating halo.
		local gold = Color3.fromRGB(255, 224, 124)
		for _, side in { -1, 1 } do
			piece("CelestialEar", Vector3.new(0.52, 0.76, 0.53), Vector3.new(side * 1.22, 4.56, 0.09), light).CFrame *= CFrame.Angles(0, 0, -side * 0.35)
			piece("StarCheek", Vector3.new(0.13, 0.30, 0.09), Vector3.new(side * 1.09, 3.18, -1.05), gold).CFrame *= CFrame.Angles(0, 0, math.pi / 4)
		end
		for i = 1, 12 do
			local angle = i * math.pi * 2 / 12
			glow("Halo", Vector3.new(0.25, 0.09, 0.25), Vector3.new(math.cos(angle) * 0.65, 5.18, math.sin(angle) * 0.49), gold)
		end
		glow("StarCharm", Vector3.new(0.35, 0.35, 0.13), Vector3.new(0, 2.02, -0.91), gold).CFrame *= CFrame.Angles(0, 0, math.pi / 4)
	end

	model.PrimaryPart = body
	-- Model:GetPivot() starts at the floor so farms and UI can place it easily.
	body.PivotOffset = CFrame.new(0, -1.75, 0)
	return model
end

return SlimeModel
