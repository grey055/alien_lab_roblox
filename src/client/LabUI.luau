--!strict
-- A small UI built in code, so syncing with Rojo is enough to install it.
local LabUI = {}

function LabUI.Create(playerGui: PlayerGui)
	local gui = Instance.new("ScreenGui")
	gui.Name = "AlienLabUI"
	gui.ResetOnSpawn = false -- Keep the panel when your character respawns.
	gui.DisplayOrder = 10

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.Position = UDim2.fromOffset(16, 16)
	panel.Size = UDim2.new(1, -32, 0, 390)
	panel.BackgroundColor3 = Color3.fromRGB(22, 28, 40)
	panel.BorderSizePixel = 0
	panel.Parent = gui
	local limit = Instance.new("UISizeConstraint")
	limit.MaxSize = Vector2.new(360, 390)
	limit.Parent = panel
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = panel

	local function label(name: string, text: string, y: number, height: number, size: number): TextLabel
		local item = Instance.new("TextLabel")
		item.Name = name
		item.Text = text
		item.Position = UDim2.fromOffset(16, y)
		item.Size = UDim2.new(1, -32, 0, height)
		item.BackgroundTransparency = 1
		item.TextColor3 = Color3.fromRGB(235, 240, 250)
		item.Font = Enum.Font.Gotham
		item.TextSize = size
		item.TextXAlignment = Enum.TextXAlignment.Left
		item.TextYAlignment = Enum.TextYAlignment.Center
		item.TextWrapped = true
		item.Parent = panel
		return item
	end

	local function button(name: string, text: string, y: number): TextButton
		local item = Instance.new("TextButton")
		item.Name = name
		item.Text = text
		item.Position = UDim2.fromOffset(16, y)
		item.Size = UDim2.new(1, -32, 0, 42)
		item.BackgroundColor3 = Color3.fromRGB(73, 172, 123)
		item.TextColor3 = Color3.fromRGB(255, 255, 255)
		item.Font = Enum.Font.GothamBold
		item.TextSize = 16
		item.TextWrapped = true
		item.BorderSizePixel = 0
		item.Parent = panel
		local rounding = Instance.new("UICorner")
		rounding.CornerRadius = UDim.new(0, 8)
		rounding.Parent = item
		return item
	end

	local title = label("Title", "ALIEN LAB v0.1", 12, 32, 22)
	title.Font = Enum.Font.GothamBold
	label("Hint", "Aliens make slime. Sell it to buy more eggs!", 46, 38, 14)
	local cash = label("Cash", "Cash: loading...", 91, 26, 20)
	local slime = label("Slime", "Slime: loading...", 121, 26, 20)
	local production = label("Production", "Production: -- / second", 154, 22, 15)
	local aliens = label("Aliens", "Aliens: --", 179, 22, 15)
	local hatch = button("Hatch", "Loading...", 215)
	local sell = button("Sell", "Sell all slime", 267)
	local result = label("HatchResult", "Last hatch: none yet", 319, 32, 14)
	local status = label("Status", "Session progress only; saving comes later.", 355, 28, 12)
	status.TextColor3 = Color3.fromRGB(180, 190, 205)

	-- Parent the finished UI once, after its children are ready.
	gui.Parent = playerGui
	return {
		Cash = cash,
		Slime = slime,
		Production = production,
		Aliens = aliens,
		Hatch = hatch,
		Sell = sell,
		Result = result,
		Status = status,
	}
end

function LabUI.SetButtonEnabled(button: TextButton, enabled: boolean)
	button.Active = enabled
	button.AutoButtonColor = enabled
	button.BackgroundColor3 = if enabled
		then Color3.fromRGB(73, 172, 123)
		else Color3.fromRGB(70, 80, 95)
end

return LabUI
