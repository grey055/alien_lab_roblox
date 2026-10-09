--!strict
-- Reusable little crops for planting beds and shop previews. Growth is drawn
-- in four stages; the server decides their progress, harvest value, and mutation.
local FarmData = require(script.Parent:WaitForChild("FarmData"))
local CropModel = {}

function CropModel.Create(cropId: string, stage: number?, mutation: string?): Model
	local crop = assert(FarmData.Crops[cropId], "Unknown crop: " .. cropId)
	local growthStage = math.clamp(math.floor(stage or 4), 1, 4)
	local mutationName = mutation or "Normal"
	local tint = Color3.fromRGB(crop.Color[1], crop.Color[2], crop.Color[3])
	if mutationName == "Golden" then tint = Color3.fromRGB(255, 211, 97)
	elseif mutationName == "Cosmic" then tint = Color3.fromRGB(174, 143, 255) end
	local green = Color3.fromRGB(79, 171, 128)
	local cream = Color3.fromRGB(255, 238, 201)
	local model = Instance.new("Model"); model.Name = crop.DisplayName
	model:SetAttribute("CropId", cropId); model:SetAttribute("Stage", growthStage); model:SetAttribute("Mutation", mutationName)
	local function p(name: string, size: Vector3, at: CFrame, color: Color3, ball: boolean?): Part
		local part = Instance.new("Part")
		part.Name = name; part.Size = size; part.CFrame = at; part.Color = color
		part.Shape = Enum.PartType.Block
		if ball then
			-- Built-in sphere meshes stretch with Size to form leaves and caps.
			local mesh = Instance.new("SpecialMesh"); mesh.MeshType = Enum.MeshType.Sphere; mesh.Parent = part
		end
		part.Material = Enum.Material.SmoothPlastic; part.Anchored = true
		part.CanCollide = false; part.CanTouch = false; part.CanQuery = false
		part.TopSurface = Enum.SurfaceType.Smooth; part.BottomSurface = Enum.SurfaceType.Smooth
		part.Parent = model; return part
	end
	local pivot = p("CropPivot", Vector3.new(0.1, 0.1, 0.1), CFrame.new(), green)
	pivot.Transparency = 1; model.PrimaryPart = pivot
	local function leaf(at: CFrame, size: number)
		for _, side in { -1, 1 } do
			p("CropLeaf", Vector3.new(size * 0.85, size * 0.25, size * 0.45),
				at * CFrame.new(side * size * 0.3, 0.1, 0) * CFrame.Angles(0, side * 0.15, side * 0.4), green, true)
		end
	end
	local factor = ({ 0.24, 0.52, 0.78, 1 })[growthStage]
	for i = 1, 4 do
		local at = CFrame.new(if i % 2 == 0 then 2.2 else -2.2, 0, if i > 2 then 1.75 else -1.75)
		if growthStage == 1 then
			p("SeedlingStem", Vector3.new(0.13, 0.65, 0.13), at * CFrame.new(0, 0.32, 0), green)
			leaf(at * CFrame.new(0, 0.6, 0), 0.8)
		else
			local s = factor
			if cropId == "StarCarrot" then
				p("CarrotRoot", Vector3.new(1.35 * s, 2.2 * s, 1.35 * s), at * CFrame.new(0, 1.03 * s, 0), tint, true)
				leaf(at * CFrame.new(0, 2.15 * s, 0), 1.55 * s)
				leaf(at * CFrame.new(0, 2.2 * s, 0) * CFrame.Angles(0, math.pi / 2, 0), 1.25 * s)
				p("CarrotShine", Vector3.new(0.28, 0.5, 0.13) * s, at * CFrame.new(-0.25 * s, 1.3 * s, -0.6 * s), cream, true)
			elseif cropId == "MoonBerry" then
				p("BerryStem", Vector3.new(0.25, 1.8 * s, 0.25), at * CFrame.new(0, 0.9 * s, 0), green)
				p("BerryBush", Vector3.new(2.5, 1.9, 2) * s, at * CFrame.new(0, 1.65 * s, 0), Color3.fromRGB(81, 156, 161), true)
				for j = 1, 5 do
					local angle = j * math.pi * 2 / 5
					local berry = p("MoonBerry", Vector3.new(0.85, 0.85, 0.85) * s,
						at * CFrame.new(math.cos(angle) * 1.05 * s, (1.6 + j % 2 * 0.3) * s, math.sin(angle) * 0.85 * s), tint, true)
					p("BerryGlint", Vector3.new(0.18, 0.18, 0.1) * s, berry.CFrame * CFrame.new(-0.13 * s, 0.15 * s, -0.36 * s), cream, true)
				end
			elseif cropId == "GlowShroom" then
				p("GlowStem", Vector3.new(0.5, 1.8, 0.5) * s, at * CFrame.new(0, 0.9 * s, 0), cream)
				local cap = p("GlowCap", Vector3.new(2.6, 1.3, 2.6) * s, at * CFrame.new(0, 2 * s, 0), tint, true)
				if growthStage == 4 then cap.Material = Enum.Material.Neon end
				for j = 1, 3 do
					local angle = j * math.pi * 2 / 3
					p("ShroomSpot", Vector3.new(0.45, 0.12, 0.45) * s,
						at * CFrame.new(math.cos(angle) * 0.6 * s, 2.57 * s, math.sin(angle) * 0.6 * s), cream, true)
				end
			elseif cropId == "CrystalBloom" then
				leaf(at * CFrame.new(0, 0.35 * s, 0), 1.3 * s)
				for j = 1, 3 do
					local angle = j * math.pi * 2 / 3
					local height = (if j == 1 then 3.2 else 2.1) * s
					local crystal = p("CropCrystal", Vector3.new(0.6 * s, height, 0.6 * s),
						at * CFrame.new(math.cos(angle) * 0.4 * s, height * 0.5, math.sin(angle) * 0.4 * s) * CFrame.Angles(0.12, angle, 0.14), tint)
					crystal.Material = Enum.Material.Neon
					local point = Instance.new("WedgePart"); point.Name = "CrystalTip"
					point.Size = Vector3.new(0.6 * s, 0.7 * s, 0.6 * s); point.CFrame = crystal.CFrame * CFrame.new(0, height * 0.5 + 0.25 * s, 0)
					point.Color = tint; point.Material = Enum.Material.Neon; point.Anchored = true; point.CanCollide = false
					point.CanTouch = false; point.CanQuery = false; point.Parent = model
				end
			elseif cropId == "CometMelon" then
				leaf(at * CFrame.new(0, 0.25, 0), 1.8 * s)
				p("Melon", Vector3.new(2.5, 2.4, 2.5) * s, at * CFrame.new(0, 1.2 * s, 0), tint, true)
				for _, side in { -1, 1 } do
					p("MelonStripe", Vector3.new(0.24, 1.85, 0.17) * s,
						at * CFrame.new(side * 0.63 * s, 1.28 * s, -1.12 * s) * CFrame.Angles(0, 0, side * 0.13), tint:Lerp(green, 0.55), true)
				end
				leaf(at * CFrame.new(0, 2.45 * s, 0), 0.9 * s)
			else -- The quest crop looks like a tiny planet on a living stalk.
				p("NebulaStem", Vector3.new(0.3, 2, 0.3) * s, at * CFrame.new(0, s, 0), green)
				leaf(at * CFrame.new(0, 1.1 * s, 0), 1.65 * s)
				local orb = p("NebulaFruit", Vector3.new(1.55, 1.55, 1.55) * s, at * CFrame.new(0, 2.4 * s, 0), tint, true)
				orb.Material = Enum.Material.Neon
				for j = 1, 6 do
					local angle = j * math.pi / 3
					p("NebulaOrbit", Vector3.new(0.18, 0.18, 0.18) * s,
						at * CFrame.new(math.sin(angle) * 1.15 * s, (2.4 + math.cos(angle) * 0.25) * s, math.cos(angle) * 1.15 * s), cream, true).Material = Enum.Material.Neon
				end
			end
		end
	end
	if growthStage == 4 and mutationName ~= "Normal" then
		local sparkle = Instance.new("Sparkles"); sparkle.Name = "MutationSparkles"
		sparkle.SparkleColor = if mutationName == "Golden" then Color3.fromRGB(255, 225, 130) else Color3.fromRGB(158, 249, 255)
		sparkle.Parent = pivot
	end
	return model
end

return CropModel
