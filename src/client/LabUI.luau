--!strict
-- Compact top-left HUD with a real 3D slime icon and matching farm colors.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SlimeModel = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("SlimeModel"))
local LabUI = {}
local mint = Color3.fromRGB(127, 242, 160)
local light = Color3.fromRGB(234, 250, 239)
local muted = Color3.fromRGB(152, 183, 164)

local function round(parent: Instance, radius: number)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
end

local function border(parent: Instance, color: Color3)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = 1
	stroke.Transparency = 0.25
	stroke.Parent = parent
end

local function frame(parent: Instance, name: string, position: UDim2, size: UDim2, color: Color3): Frame
	local item = Instance.new("Frame")
	item.Name = name
	item.Position = position
	item.Size = size
	item.BackgroundColor3 = color
	item.BorderSizePixel = 0
	item.Parent = parent
	return item
end

local function text(parent: Instance, name: string, value: string, position: UDim2, size: UDim2, fontSize: number, tint: Color3): TextLabel
	local item = Instance.new("TextLabel")
	item.Name = name
	item.Text = value
	item.Position = position
	item.Size = size
	item.BackgroundTransparency = 1
	item.TextColor3 = tint
	item.Font = Enum.Font.Gotham
	item.TextSize = fontSize
	item.TextXAlignment = Enum.TextXAlignment.Left
	item.TextYAlignment = Enum.TextYAlignment.Center
	item.TextWrapped = true
	item.Parent = parent
	return item
end

function LabUI.Create(playerGui: PlayerGui)
	local gui = Instance.new("ScreenGui")
	gui.Name = "AlienLabUI"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 10
	-- Respect Roblox's top-bar inset; the HUD sits directly below it on the left.
	local panel = frame(gui, "Panel", UDim2.fromOffset(12, 12), UDim2.new(1, -24, 0, 360), Color3.fromRGB(17, 34, 27))
	panel.BackgroundTransparency = 0.04
	round(panel, 18)
	border(panel, Color3.fromRGB(77, 128, 94))
	local limit = Instance.new("UISizeConstraint")
	limit.MaxSize = Vector2.new(310, 360)
	limit.Parent = panel

	local badge = frame(panel, "LabDot", UDim2.fromOffset(15, 20), UDim2.fromOffset(10, 10), mint)
	round(badge, 5)
	local title = text(panel, "Title", "ALIEN LAB", UDim2.fromOffset(34, 12), UDim2.new(1, -115, 0, 26), 17, light)
	title.Font = Enum.Font.GothamBold
	text(panel, "Subtitle", "YOUR FARM", UDim2.new(1, -94, 0, 17), UDim2.fromOffset(80, 18), 10, muted)

	-- Cash card: a green currency badge plus a bold, readable balance.
	local cashCard = frame(panel, "CashCard", UDim2.fromOffset(12, 50), UDim2.new(1, -24, 0, 66), Color3.fromRGB(29, 62, 42))
	round(cashCard, 13)
	local coin = frame(cashCard, "CashIcon", UDim2.fromOffset(13, 14), UDim2.fromOffset(38, 38), mint)
	round(coin, 19)
	local dollar = text(coin, "Dollar", "$", UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), 25, Color3.fromRGB(24, 68, 40))
	dollar.Font = Enum.Font.GothamBold
	dollar.TextXAlignment = Enum.TextXAlignment.Center
	text(cashCard, "CashCaption", "CASH", UDim2.fromOffset(64, 7), UDim2.new(1, -76, 0, 19), 10, muted)
	local cash = text(cashCard, "Cash", "Loading...", UDim2.fromOffset(64, 26), UDim2.new(1, -76, 0, 30), 25, mint)
	cash.Font = Enum.Font.GothamBold

	-- Slime card: the total is beside the icon; production sits underneath it.
	local slimeCard = frame(panel, "SlimeCard", UDim2.fromOffset(12, 124), UDim2.new(1, -24, 0, 87), Color3.fromRGB(27, 49, 39))
	round(slimeCard, 13)
	local icon = Instance.new("ViewportFrame")
	icon.Name = "SlimeIcon"
	icon.Position = UDim2.fromOffset(6, 10)
	icon.Size = UDim2.fromOffset(58, 63)
	icon.BackgroundTransparency = 1
	icon.Ambient = Color3.fromRGB(210, 255, 218)
	icon.LightColor = Color3.new(1, 1, 1)
	icon.LightDirection = Vector3.new(-1, -1, -2)
	icon.Parent = slimeCard
	local world = Instance.new("WorldModel")
	world.Parent = icon
	SlimeModel.Create("Slimelet").Parent = world
	local camera = Instance.new("Camera")
	camera.FieldOfView = 34
	camera.CFrame = CFrame.lookAt(Vector3.new(0, 2.1, -8), Vector3.new(0, 1.5, 0))
	camera.Parent = icon
	icon.CurrentCamera = camera
	text(slimeCard, "SlimeCaption", "SLIME", UDim2.fromOffset(72, 7), UDim2.new(1, -82, 0, 18), 10, muted)
	local slime = text(slimeCard, "Slime", "Loading...", UDim2.fromOffset(72, 25), UDim2.new(1, -82, 0, 31), 25, light)
	slime.Font = Enum.Font.GothamBold
	local production = text(slimeCard, "Production", "Production: -- / sec", UDim2.fromOffset(72, 59), UDim2.new(1, -80, 0, 20), 11, mint)
	local aliens = text(panel, "Aliens", "Your garden is loading...", UDim2.fromOffset(16, 218), UDim2.new(1, -32, 0, 21), 12, muted)

	local function button(name: string, caption: string, position: UDim2, size: UDim2): TextButton
		local item = Instance.new("TextButton")
		item.Name = name
		item.Text = caption
		item.Position = position
		item.Size = size
		item.BackgroundColor3 = mint
		item.TextColor3 = Color3.fromRGB(20, 55, 31)
		item.Font = Enum.Font.GothamBold
		item.TextSize = 13
		item.TextWrapped = true
		item.BorderSizePixel = 0
		item.Parent = panel
		round(item, 11)
		return item
	end
	local hatch = button("Hatch", "Loading...", UDim2.fromOffset(12, 248), UDim2.new(0.57, -16, 0, 40))
	local sell = button("Sell", "Sell slime", UDim2.new(0.57, 0, 0, 248), UDim2.new(0.43, -12, 0, 40))
	local result = text(panel, "HatchResult", "Last hatch: none yet", UDim2.fromOffset(16, 295), UDim2.new(1, -32, 0, 24), 12, light)
	local status = text(panel, "Status", "Meet your slimes in the garden!", UDim2.fromOffset(16, 325), UDim2.new(1, -32, 0, 26), 11, muted)
	gui.Parent = playerGui
	return { Cash = cash, Slime = slime, Production = production, Aliens = aliens, Hatch = hatch, Sell = sell, Result = result, Status = status }
end

function LabUI.SetButtonEnabled(button: TextButton, enabled: boolean)
	button.Active = enabled
	button.AutoButtonColor = enabled
	button.BackgroundColor3 = if enabled then mint else Color3.fromRGB(50, 68, 57)
	button.TextColor3 = if enabled then Color3.fromRGB(20, 55, 31) else muted
end

return LabUI
