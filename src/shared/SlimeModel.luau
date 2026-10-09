--!strict
-- The same friendly blob appears in your farm and in the HUD's slime icon.
-- All pieces are native Roblox parts; no external meshes or images are needed.
local AlienData = require(script.Parent:WaitForChild("AlienData"))
local SlimeModel = {}

function SlimeModel.Create(alienId: string): Model
	local alien = assert(AlienData.Aliens[alienId], "Unknown alien: " .. alienId)
	local color = Color3.fromRGB(alien.BodyColor[1], alien.BodyColor[2], alien.BodyColor[3])
	local model = Instance.new("Model")
	model.Name = alien.DisplayName

	local function piece(name: string, size: Vector3, position: Vector3, tint: Color3, ball: boolean): Part
		local item = Instance.new("Part")
		item.Name = name
		item.Size = size
		item.Position = position
		item.Color = tint
		item.Material = Enum.Material.SmoothPlastic
		item.Shape = if ball then Enum.PartType.Ball else Enum.PartType.Block
		item.Anchored = true
		item.CanCollide = false
		item.CanTouch = false
		item.CanQuery = false
		item.CastShadow = name == "Body"
		item.Parent = model
		return item
	end

	local body = piece("Body", Vector3.new(4, 2.9, 3.5), Vector3.new(0, 1.45, 0), color, true)
	piece("Skirt", Vector3.new(4.3, 0.9, 3.9), Vector3.new(0, 0.45, 0), color, true)
	local dark = Color3.fromRGB(24, 48, 38)
	for _, side in { -1, 1 } do
		piece("Eye", Vector3.new(0.66, 0.77, 0.38), Vector3.new(side * 0.72, 1.7, -1.5), Color3.new(1, 1, 1), true)
		piece("Pupil", Vector3.new(0.29, 0.43, 0.18), Vector3.new(side * 0.72, 1.67, -1.72), dark, true)
		piece("Cheek", Vector3.new(0.45, 0.22, 0.14), Vector3.new(side * 1.14, 1.2, -1.46), Color3.fromRGB(255, 162, 178), true)
	end
	piece("Smile", Vector3.new(0.58, 0.14, 0.16), Vector3.new(0, 1.04, -1.64), dark, true)
	piece("Shine", Vector3.new(0.8, 0.3, 0.12), Vector3.new(-0.72, 2.32, -1.25), color:Lerp(Color3.new(1, 1, 1), 0.7), true)
	if alienId == "Glowbug" then
		local tip = piece("Glow", Vector3.new(0.55, 0.55, 0.55), Vector3.new(0, 3.05, 0), Color3.fromRGB(191, 255, 140), true)
		tip.Material = Enum.Material.Neon
	elseif alienId == "Starling" then
		for _, side in { -1, 1 } do
			piece("Crest", Vector3.new(0.55, 0.85, 0.55), Vector3.new(side * 0.55, 2.9, 0), Color3.fromRGB(255, 224, 112), true)
		end
	end

	model.PrimaryPart = body
	-- Use the floor as the model's pivot, so its feet always meet the garden.
	body.PivotOffset = CFrame.new(0, -1.45, 0)
	return model
end

return SlimeModel
