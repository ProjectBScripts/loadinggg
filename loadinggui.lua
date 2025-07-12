-- Services
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer
local PlayerGui = localPlayer:WaitForChild("PlayerGui")

-- Pet Chances
local eggChances = {
	["Common Egg"] = {["Dog"] = 33, ["Bunny"] = 33, ["Golden Lab"] = 33},
	["Rare Egg"] = {["Orange Tabby"] = 33.33, ["Spotted Deer"] = 25, ["Pig"] = 16.67, ["Rooster"] = 16.67, ["Monkey"] = 8.33},
	["Night Egg"] = {["Hedgehog"] = 47, ["Mole"] = 23.5, ["Frog"] = 21.16, ["Echo Frog"] = 8.35, ["Night Owl"] = 0, ["Raccoon"] = 0},
	["Bug Egg"] = {["Snail"] = 40, ["Giant Ant"] = 35, ["Caterpillar"] = 25, ["Dragon Fly"] = 0},
	["Bee Egg"] = {["Bee"] = 65, ["Honey Bee"] = 20, ["Bear Bee"] = 10, ["Queen Bee"] = 0},
	["Dinosaur Egg"] = {["T-Rex"] = 0, ["Raptor"] = 25, ["Stegosaurus"] = 30, ["Triceratops"] = 45},
}

-- State
local displayedEggs = {}
local lockedPets = {}
local autoRerollOn = false
local autoStopOn = false
local rerollCooldown = false

-- Utilities
local function weightedRandom(options)
	local total, pool = 0, {}
	for pet, chance in pairs(options) do
		if chance > 0 then
			total += chance
			table.insert(pool, {pet, chance})
		end
	end
	local roll, sum = math.random() * total, 0
	for _, item in ipairs(pool) do
		sum += item[2]
		if roll <= sum then return item[1] end
	end
	return pool[1] and pool[1][1]
end

local function getRandomPet(eggName, last)
	local pool = eggChances[eggName]
	if not pool then return nil end
	for _ = 1, 5 do
		local pet = weightedRandom(pool)
		if pet ~= last or math.random() < 0.3 then return pet end
	end
	return last
end

local function createEspGui(target, text, isLocked)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "PetESP"
	billboard.Adornee = target:FindFirstChildWhichIsA("BasePart") or target.PrimaryPart or target
	billboard.Size = UDim2.new(0, 200, 0, 50)
	billboard.StudsOffset = Vector3.new(0, 2.5, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = target

	local label = Instance.new("TextLabel", billboard)
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.TextColor3 = isLocked and Color3.fromRGB(0, 255, 0) or Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0
	label.TextScaled = true
	label.Font = Enum.Font.SourceSansBold
	label.Text = text

	return billboard
end

local function handleESP(egg)
	if egg:GetAttribute("OWNER") ~= localPlayer.Name then return end
	local eggName, objectId = egg:GetAttribute("EggName"), egg:GetAttribute("OBJECT_UUID")
	if not eggName or not objectId or displayedEggs[objectId] then return end

	local pet = getRandomPet(eggName)
	local gui = createEspGui(egg, eggName .. " | " .. pet, lockedPets[pet])
	displayedEggs[objectId] = {
		egg = egg,
		gui = gui,
		label = gui:FindFirstChild("TextLabel"),
		eggName = eggName,
		lastPet = pet
	}
end

local function cleanupESP(egg)
	local id = egg:GetAttribute("OBJECT_UUID")
	if id and displayedEggs[id] then
		displayedEggs[id].gui:Destroy()
		displayedEggs[id] = nil
	end
end

for _, egg in CollectionService:GetTagged("PetEggServer") do handleESP(egg) end
CollectionService:GetInstanceAddedSignal("PetEggServer"):Connect(handleESP)
CollectionService:GetInstanceRemovedSignal("PetEggServer"):Connect(cleanupESP)

-- GUI
local gui = Instance.new("ScreenGui", PlayerGui)
gui.Name = "ProjectB_GUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true

-- Toggle Button
local toggle = Instance.new("TextButton", gui)
toggle.Size = UDim2.new(0, 50, 0, 50)
toggle.Position = UDim2.new(0, 10, 0.5, -25)
toggle.Text = "P"
toggle.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
toggle.TextColor3 = Color3.new(1, 1, 1)
toggle.Font = Enum.Font.GothamBlack
toggle.TextSize = 24
toggle.ZIndex = 10

-- Draggable toggle
local dragging, dragOffset
toggle.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragOffset = input.Position - toggle.AbsolutePosition
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = false
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		toggle.Position = UDim2.new(0, input.Position.X - dragOffset.X, 0, input.Position.Y - dragOffset.Y)
	end
end)

-- Main GUI
local main = Instance.new("Frame", gui)
main.Size = UDim2.new(0, 300, 0, 300)
main.Position = UDim2.new(0, 70, 0.5, -150)
main.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
main.BorderSizePixel = 0
main.Visible = true

local header = Instance.new("TextLabel", main)
header.Size = UDim2.new(1, 0, 0, 30)
header.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
header.Text = "   ProjectB HUB"
header.TextXAlignment = Enum.TextXAlignment.Left
header.Font = Enum.Font.GothamBold
header.TextSize = 16
header.TextColor3 = Color3.new(1, 1, 1)

local close = Instance.new("TextButton", header)
close.Position = UDim2.new(1, -30, 0, 3)
close.Size = UDim2.new(0, 24, 0, 24)
close.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
close.Text = "X"
close.Font = Enum.Font.GothamBold
close.TextSize = 14
close.TextColor3 = Color3.new(1, 1, 1)
close.MouseButton1Click:Connect(function()
	gui:Destroy()
end)

-- Draggable main
local draggingMain, dragStart, startPos
header.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingMain = true
		dragStart = input.Position
		startPos = main.Position
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if draggingMain and input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = input.Position - dragStart
		main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingMain = false
	end
end)

-- Buttons
local function createButton(text, y)
	local btn = Instance.new("TextButton", main)
	btn.Size = UDim2.new(1, -20, 0, 28)
	btn.Position = UDim2.new(0, 10, 0, y)
	btn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 14
	btn.Text = text
	return btn
end

local autoBtn = createButton("Auto Reroll: OFF", 40)
local manualBtn = createButton("Manual Reroll", 80)
local stopBtn = createButton("Auto Stop: OFF", 120)

autoBtn.MouseButton1Click:Connect(function()
	autoRerollOn = not autoRerollOn
	autoBtn.Text = "Auto Reroll: " .. (autoRerollOn and "ON" or "OFF")
	autoBtn.BackgroundColor3 = autoRerollOn and Color3.fromRGB(0, 180, 90) or Color3.fromRGB(180, 60, 60)
end)

manualBtn.MouseButton1Click:Connect(function()
	for _, data in pairs(displayedEggs) do
		local pet = getRandomPet(data.eggName, data.lastPet)
		data.label.Text = data.eggName .. " | " .. pet
		data.label.TextColor3 = lockedPets[pet] and Color3.fromRGB(0, 255, 0) or Color3.new(1, 1, 1)
		data.lastPet = pet
	end
end)

stopBtn.MouseButton1Click:Connect(function()
	autoStopOn = not autoStopOn
	stopBtn.Text = "Auto Stop: " .. (autoStopOn and "ON" or "OFF")
	stopBtn.BackgroundColor3 = autoStopOn and Color3.fromRGB(0, 180, 90) or Color3.fromRGB(180, 60, 60)
end)

-- Checklist
local checklist = Instance.new("ScrollingFrame", main)
checklist.Size = UDim2.new(1, -20, 0, 120)
checklist.Position = UDim2.new(0, 10, 0, 160)
checklist.CanvasSize = UDim2.new(0, 0, 0, 300)
checklist.ScrollBarThickness = 4
checklist.BackgroundColor3 = Color3.fromRGB(50, 50, 50)

local pets = {"Raccoon", "Dragon Fly", "Queen Bee", "Disco Bee", "Butterfly", "T-Rex", "Stegosaurus", "Triceratops", "Echo Frog"}
for i, pet in ipairs(pets) do
	lockedPets[pet] = false
	local btn = Instance.new("TextButton", checklist)
	btn.Size = UDim2.new(1, 0, 0, 20)
	btn.Position = UDim2.new(0, 0, 0, (i - 1) * 22)
	btn.Text = "[ ] " .. pet
	btn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 13
	btn.MouseButton1Click:Connect(function()
		lockedPets[pet] = not lockedPets[pet]
		btn.Text = (lockedPets[pet] and "[X] " or "[ ] ") .. pet
	end)
end

-- Toggle GUI
toggle.MouseButton1Click:Connect(function()
	main.Visible = not main.Visible
end)

-- Auto reroll
task.spawn(function()
	while true do
		if autoRerollOn and not rerollCooldown then
			rerollCooldown = true
			for _, data in pairs(displayedEggs) do
				local pet = getRandomPet(data.eggName, data.lastPet)
				data.label.Text = data.eggName .. " | " .. pet
				data.label.TextColor3 = lockedPets[pet] and Color3.fromRGB(0, 255, 0) or Color3.new(1, 1, 1)
				data.lastPet = pet
				if lockedPets[pet] and autoStopOn then
					autoRerollOn = false
					autoBtn.Text = "Auto Reroll: OFF"
					autoBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
					break
				end
			end
			task.wait(1)
			rerollCooldown = false
		else
			task.wait(0.2)
		end
	end
end)
