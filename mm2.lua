-- Murder Mystery 2 Power GUI
-- Features: ESP, God Mode, Noclip, Speed, Auto Collect Coins, Grab Gun, Invisibility
-- Optimized to reduce lag when becoming murderer

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")
if not LocalPlayer then return end

-- Anti-detection measures
local function protectInstance(instance)
    if not instance then return end
    for _,v in pairs(getconnections(instance.Changed)) do
        v:Disable()
    end
    for _,v in pairs(getconnections(instance.ChildAdded)) do
        v:Disable()
    end
    for _,v in pairs(getconnections(instance.DescendantAdded)) do
        v:Disable()
    end
end

-- Settings
local settings = {
    revealRoles = false,
    godMode = false,
    noclip = false,
    invisible = false,
    speed = 16,
    maxSpeed = 100,
    noclipSpeed = 1,
    grabGunEnabled = false,
    autoCollectCoins = false,
    coinCollectRange = 50,
    coinCollectSpeed = 30,
    guiVisible = true,
    guiMinimized = false,
    espUpdateInterval = 0.5
}

-- ESP Setup
local espParts = {}
local espLabels = {}
local roleCache = {}
local lastEspUpdate = 0

-- Create ESP for player
local function createESP(player)
    if espParts[player] or player == LocalPlayer then return end
    
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local espPart = Instance.new("BoxHandleAdornment")
    espPart.Name = "ESP_"..player.Name
    espPart.Size = char.HumanoidRootPart.Size + Vector3.new(2, 4, 2)
    espPart.Transparency = 0.3
    espPart.Color3 = Color3.new(1, 1, 1)
    espPart.AlwaysOnTop = true
    espPart.ZIndex = 10
    espPart.Adornee = char.HumanoidRootPart
    espPart.Parent = char.HumanoidRootPart
    protectInstance(espPart)
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESPLabel_"..player.Name
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Adornee = char.HumanoidRootPart
    billboard.Parent = char.HumanoidRootPart
    protectInstance(billboard)
    
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = player.Name
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3 = Color3.new(0, 0, 0)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.Parent = billboard
    protectInstance(label)
    
    espParts[player] = espPart
    espLabels[player] = label
    
    local function updateColor()
        if not char or not char:FindFirstChild("HumanoidRootPart") then return end
        
        local backpack = player:FindFirstChild("Backpack")
        local hasKnife = (backpack and backpack:FindFirstChild("Knife")) or (char:FindFirstChild("Knife"))
        local hasGun = (backpack and backpack:FindFirstChild("Gun")) or (char:FindFirstChild("Gun"))
        
        if hasKnife then
            roleCache[player] = "Murderer"
            espPart.Color3 = Color3.new(1, 0, 0) -- Red
            label.TextColor3 = Color3.new(1, 0, 0)
        elseif hasGun then
            roleCache[player] = "Sheriff"
            espPart.Color3 = Color3.new(0, 0, 1) -- Blue
            label.TextColor3 = Color3.new(0, 0, 1)
        else
            roleCache[player] = "Innocent"
            espPart.Color3 = Color3.new(0, 1, 0) -- Green
            label.TextColor3 = Color3.new(0, 1, 0)
        end
        
        label.Text = player.Name .. " (" .. (roleCache[player] or "Unknown") .. ")"
    end
    
    updateColor()
    
    local function trackItems()
        local backpack = player:WaitForChild("Backpack")
        
        local function checkItems()
            task.wait(0.5)
            updateColor()
        end
        
        backpack.ChildAdded:Connect(checkItems)
        backpack.ChildRemoved:Connect(checkItems)
        
        char.ChildAdded:Connect(function(child)
            if child.Name == "Knife" or child.Name == "Gun" then
                checkItems()
            end
        end)
        
        char.ChildRemoved:Connect(function(child)
            if child.Name == "Knife" or child.Name == "Gun" then
                checkItems()
            end
        end)
    end
    
    trackItems()
    
    player.CharacterAdded:Connect(function(newChar)
        task.wait(1)
        char = newChar
        if not char:FindFirstChild("HumanoidRootPart") then return end
        
        espPart.Adornee = char.HumanoidRootPart
        espPart.Parent = char.HumanoidRootPart
        
        if billboard then
            billboard.Adornee = char.HumanoidRootPart
            billboard.Parent = char.HumanoidRootPart
        end
        
        trackItems()
    end)
end

-- Remove ESP
local function removeESP(player)
    if espParts[player] then
        espParts[player]:Destroy()
        espParts[player] = nil
    end
    if espLabels[player] then
        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local billboard = char.HumanoidRootPart:FindFirstChild("ESPLabel_"..player.Name)
            if billboard then billboard:Destroy() end
        end
        espLabels[player] = nil
    end
    roleCache[player] = nil
end

-- Update ESP
local function updateESP()
    if not settings.revealRoles or tick() - lastEspUpdate < settings.espUpdateInterval then return end
    lastEspUpdate = tick()
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if settings.revealRoles then
                if player.Character then
                    createESP(player)
                end
            else
                removeESP(player)
            end
        end
    end
end

-- Player handlers
local function onPlayerAdded(player)
    player.CharacterAdded:Connect(function()
        if settings.revealRoles then
            createESP(player)
        end
    end)
    
    player.CharacterRemoving:Connect(function()
        removeESP(player)
    end)
end

for _, player in pairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        onPlayerAdded(player)
    end
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(removeESP)

-- Gun Handling
local function findNearestGun()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end
    
    local rootPart = char.HumanoidRootPart
    local nearestGun = nil
    local minDistance = math.huge

    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj.Name == "Gun" and obj:IsA("Tool") and (obj.Parent == Workspace or obj.Parent:IsA("Model")) then
            local distance = (rootPart.Position - obj:GetPivot().Position).Magnitude
            if distance < minDistance and distance < 15 then
                minDistance = distance
                nearestGun = obj
            end
        end
    end
    return nearestGun
end

local function grabGun()
    if not settings.grabGunEnabled then return end
    local gun = findNearestGun()
    if gun then
        firetouchinterest(LocalPlayer.Character.HumanoidRootPart, gun.Handle, 0)
        firetouchinterest(LocalPlayer.Character.HumanoidRootPart, gun.Handle, 1)
        task.wait(0.5)
        settings.grabGunEnabled = false
    end
end

local function autoPickGun()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local pChar = player.Character
            if pChar and pChar:FindFirstChild("Humanoid") and pChar.Humanoid.Health <= 0 then
                local backpack = player:FindFirstChild("Backpack")
                local hasGun = (backpack and backpack:FindFirstChild("Gun")) or (pChar:FindFirstChild("Gun"))
                
                if hasGun then
                    local gun = backpack and backpack:FindFirstChild("Gun") or pChar:FindFirstChild("Gun")
                    if gun then
                        firetouchinterest(char.HumanoidRootPart, gun.Handle, 0)
                        firetouchinterest(char.HumanoidRootPart, gun.Handle, 1)
                        task.wait(1)
                        return
                    end
                end
            end
        end
    end
end

-- Teleport to Sheriff
local function teleportToSheriff()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local pChar = player.Character
            if pChar and pChar:FindFirstChild("HumanoidRootPart") then
                local backpack = player:FindFirstChild("Backpack")
                local hasGun = (backpack and backpack:FindFirstChild("Gun")) or (pChar:FindFirstChild("Gun"))
                
                if hasGun then
                    char:MoveTo(pChar.HumanoidRootPart.Position + Vector3.new(0, 0, -5))
                    task.wait(1)
                    return
                end
            end
        end
    end
end

-- Invisibility
local function setInvisibility(state)
    if not LocalPlayer.Character then return end
    
    for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.LocalTransparencyModifier = state and 1 or 0
            if part:FindFirstChildOfClass("Decal") then
                part:FindFirstChildOfClass("Decal").Transparency = state and 1 or 0
            end
        elseif part:IsA("Accessory") and part:FindFirstChild("Handle") then
            part.Handle.LocalTransparencyModifier = state and 1 or 0
        end
    end
    
    settings.invisible = state
end

-- Auto Collect Coins
local lastCoinCollect = 0
local coinCollectCooldown = 0.3

local function collectCoins()
    if not settings.autoCollectCoins then return end
    if tick() - lastCoinCollect < coinCollectCooldown then return end
    
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local rootPart = char.HumanoidRootPart
    
    local mapFolder = Workspace:FindFirstChild("Map") or Workspace:FindFirstChild("MapFolder")
    if not mapFolder then return end
    
    for _, obj in pairs(mapFolder:GetDescendants()) do
        if obj.Name == "Coin" and obj:IsA("BasePart") then
            local distance = (rootPart.Position - obj.Position).Magnitude
            if distance < settings.coinCollectRange then
                lastCoinCollect = tick()
                
                firetouchinterest(rootPart, obj, 0)
                firetouchinterest(rootPart, obj, 1)
                
                if settings.noclip then
                    local direction = (obj.Position - rootPart.Position).Unit
                    rootPart.CFrame = rootPart.CFrame + (direction * math.min(settings.coinCollectSpeed * 0.1, distance * 0.9))
                else
                    rootPart.CFrame = CFrame.new(obj.Position + Vector3.new(0, 3, 0))
                end
                break
            end
        end
    end
end

-- GUI Setup
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MM2PowerGUI_"..tostring(math.random(10000,99999))
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
screenGui.ResetOnSpawn = false
protectInstance(screenGui)

local mainContainer = Instance.new("Frame")
mainContainer.Name = "MainContainer"
mainContainer.Size = UDim2.new(0, 600, 0, 350)
mainContainer.Position = UDim2.new(0.5, -300, 0.1, 0)
mainContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
mainContainer.BackgroundTransparency = 0.2
mainContainer.BorderSizePixel = 0
mainContainer.Parent = screenGui
protectInstance(mainContainer)

-- Make GUI draggable
local dragging
local dragInput
local dragStart
local startPos

local function updateInput(input)
    local delta = input.Position - dragStart
    mainContainer.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

mainContainer.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = mainContainer.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

mainContainer.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        updateInput(input)
    end
end)

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 10)
uiCorner.Parent = mainContainer
protectInstance(uiCorner)

-- Title Bar
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
titleBar.Parent = mainContainer
protectInstance(titleBar)

local tbCorner = Instance.new("UICorner")
tbCorner.CornerRadius = UDim.new(0, 10)
tbCorner.Parent = titleBar
protectInstance(tbCorner)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(0.5, 0, 1, 0)
title.Position = UDim2.new(0, 0, 0, 0)
title.Text = "MM2 Power GUI"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.Parent = titleBar
protectInstance(title)

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 20, 0, 20)
closeButton.Position = UDim2.new(1, -25, 0, 10)
closeButton.Text = "X"
closeButton.TextColor3 = Color3.fromRGB(255, 0, 0)
closeButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
closeButton.Font = Enum.Font.Gotham
closeButton.TextSize = 12
closeButton.Parent = titleBar
protectInstance(closeButton)

local cbCorner = Instance.new("UICorner")
cbCorner.CornerRadius = UDim.new(0, 5)
cbCorner.Parent = closeButton
protectInstance(cbCorner)

closeButton.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

local minimizeButton = Instance.new("TextButton")
minimizeButton.Size = UDim2.new(0, 20, 0, 20)
minimizeButton.Position = UDim2.new(1, -50, 0, 10)
minimizeButton.Text = "-"
minimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
minimizeButton.Font = Enum.Font.Gotham
minimizeButton.TextSize = 14
minimizeButton.Parent = titleBar
protectInstance(minimizeButton)

local mbCorner = Instance.new("UICorner")
mbCorner.CornerRadius = UDim.new(0, 5)
mbCorner.Parent = minimizeButton
protectInstance(mbCorner)

minimizeButton.MouseButton1Click:Connect(function()
    settings.guiMinimized = not settings.guiMinimized
    if settings.guiMinimized then
        mainContainer.Size = UDim2.new(0, 600, 0, 40)
        for _, child in pairs(mainContainer:GetChildren()) do
            if child ~= titleBar then
                child.Visible = false
            end
        end
    else
        mainContainer.Size = UDim2.new(0, 600, 0, 350)
        for _, child in pairs(mainContainer:GetChildren()) do
            child.Visible = true
        end
    end
end)

local toggleGuiButton = Instance.new("TextButton")
toggleGuiButton.Size = UDim2.new(0, 40, 0, 20)
toggleGuiButton.Position = UDim2.new(0.5, -20, 0, 10)
toggleGuiButton.Text = "Toggle"
toggleGuiButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleGuiButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
toggleGuiButton.Font = Enum.Font.Gotham
toggleGuiButton.TextSize = 12
toggleGuiButton.Parent = titleBar
protectInstance(toggleGuiButton)

local tgCorner = Instance.new("UICorner")
tgCorner.CornerRadius = UDim.new(0, 5)
tgCorner.Parent = toggleGuiButton
protectInstance(tgCorner)

toggleGuiButton.MouseButton1Click:Connect(function()
    settings.guiVisible = not settings.guiVisible
    mainContainer.Visible = settings.guiVisible
end)

-- Three Panel Layout
local leftPanel = Instance.new("Frame")
leftPanel.Name = "LeftPanel"
leftPanel.Size = UDim2.new(0.33, -5, 1, -40)
leftPanel.Position = UDim2.new(0, 0, 0, 40)
leftPanel.BackgroundTransparency = 1
leftPanel.Parent = mainContainer
protectInstance(leftPanel)

local middlePanel = Instance.new("Frame")
middlePanel.Name = "MiddlePanel"
middlePanel.Size = UDim2.new(0.33, -5, 1, -40)
middlePanel.Position = UDim2.new(0.33, 0, 0, 40)
middlePanel.BackgroundTransparency = 1
middlePanel.Parent = mainContainer
protectInstance(middlePanel)

local rightPanel = Instance.new("Frame")
rightPanel.Name = "RightPanel"
rightPanel.Size = UDim2.new(0.34, 0, 1, -40)
rightPanel.Position = UDim2.new(0.66, 0, 0, 40)
rightPanel.BackgroundTransparency = 1
rightPanel.Parent = mainContainer
protectInstance(rightPanel)

-- Left Panel (Main Settings)
local leftTitle = Instance.new("TextLabel")
leftTitle.Size = UDim2.new(1, 0, 0, 30)
leftTitle.Text = "Main Settings"
leftTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
leftTitle.BackgroundTransparency = 1
leftTitle.Font = Enum.Font.GothamBold
leftTitle.TextSize = 14
leftTitle.Parent = leftPanel
protectInstance(leftTitle)

local revealRolesButton = Instance.new("TextButton")
revealRolesButton.Size = UDim2.new(0.9, 0, 0, 40)
revealRolesButton.Position = UDim2.new(0.05, 0, 0.1, 0)
revealRolesButton.Text = "Reveal Roles: OFF"
revealRolesButton.TextColor3 = Color3.fromRGB(255, 255, 255)
revealRolesButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
revealRolesButton.Font = Enum.Font.Gotham
revealRolesButton.TextSize = 12
revealRolesButton.Parent = leftPanel
protectInstance(revealRolesButton)

local rrCorner = Instance.new("UICorner")
rrCorner.CornerRadius = UDim.new(0, 8)
rrCorner.Parent = revealRolesButton
protectInstance(rrCorner)

revealRolesButton.MouseButton1Click:Connect(function()
    settings.revealRoles = not settings.revealRoles
    revealRolesButton.Text = "Reveal Roles: " .. (settings.revealRoles and "ON" or "OFF")
    if settings.revealRoles then
        updateESP()
    else
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                removeESP(player)
            end
        end
    end
end)

local godModeButton = Instance.new("TextButton")
godModeButton.Size = UDim2.new(0.9, 0, 0, 40)
godModeButton.Position = UDim2.new(0.05, 0, 0.2, 0)
godModeButton.Text = "God Mode: OFF"
godModeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
godModeButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
godModeButton.Font = Enum.Font.Gotham
godModeButton.TextSize = 12
godModeButton.Parent = leftPanel
protectInstance(godModeButton)

local gmCorner = Instance.new("UICorner")
gmCorner.CornerRadius = UDim.new(0, 8)
gmCorner.Parent = godModeButton
protectInstance(gmCorner)

godModeButton.MouseButton1Click:Connect(function()
    settings.godMode = not settings.godMode
    godModeButton.Text = "God Mode: " .. (settings.godMode and "ON" or "OFF")
    local function applyGodMode(char)
        local hum = char:WaitForChild("Humanoid")
        if hum then
            hum.MaxHealth = math.huge
            hum.Health = math.huge
            hum.Died:Connect(function()
                task.wait(0.5)
                applyGodMode(char)
            end)
        end
    end
    if settings.godMode then
        applyGodMode(LocalPlayer.Character)
        LocalPlayer.CharacterAdded:Connect(applyGodMode)
    end
end)

local invisibleButton = Instance.new("TextButton")
invisibleButton.Size = UDim2.new(0.9, 0, 0, 40)
invisibleButton.Position = UDim2.new(0.05, 0, 0.3, 0)
invisibleButton.Text = "Invisible: OFF"
invisibleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
invisibleButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
invisibleButton.Font = Enum.Font.Gotham
invisibleButton.TextSize = 12
invisibleButton.Parent = leftPanel
protectInstance(invisibleButton)

local invCorner = Instance.new("UICorner")
invCorner.CornerRadius = UDim.new(0, 8)
invCorner.Parent = invisibleButton
protectInstance(invCorner)

invisibleButton.MouseButton1Click:Connect(function()
    settings.invisible = not settings.invisible
    invisibleButton.Text = "Invisible: " .. (settings.invisible and "ON" or "OFF")
    setInvisibility(settings.invisible)
end)

local grabGunButton = Instance.new("TextButton")
grabGunButton.Size = UDim2.new(0.9, 0, 0, 40)
grabGunButton.Position = UDim2.new(0.05, 0, 0.4, 0)
grabGunButton.Text = "Grab Gun: OFF"
grabGunButton.TextColor3 = Color3.fromRGB(255, 255, 255)
grabGunButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
grabGunButton.Font = Enum.Font.Gotham
grabGunButton.TextSize = 12
grabGunButton.Parent = leftPanel
protectInstance(grabGunButton)

local ggCorner = Instance.new("UICorner")
ggCorner.CornerRadius = UDim.new(0, 8)
ggCorner.Parent = grabGunButton
protectInstance(ggCorner)

grabGunButton.MouseButton1Click:Connect(function()
    settings.grabGunEnabled = not settings.grabGunEnabled
    grabGunButton.Text = "Grab Gun: " .. (settings.grabGunEnabled and "ON" or "OFF")
    if settings.grabGunEnabled then
        grabGun()
    end
end)

-- Middle Panel (Movement)
local middleTitle = Instance.new("TextLabel")
middleTitle.Size = UDim2.new(1, 0, 0, 30)
middleTitle.Text = "Movement"
middleTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
middleTitle.BackgroundTransparency = 1
middleTitle.Font = Enum.Font.GothamBold
middleTitle.TextSize = 14
middleTitle.Parent = middlePanel
protectInstance(middleTitle)

local noclipButton = Instance.new("TextButton")
noclipButton.Size = UDim2.new(0.9, 0, 0, 40)
noclipButton.Position = UDim2.new(0.05, 0, 0.1, 0)
noclipButton.Text = "Noclip: OFF"
noclipButton.TextColor3 = Color3.fromRGB(255, 255, 255)
noclipButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
noclipButton.Font = Enum.Font.Gotham
noclipButton.TextSize = 12
noclipButton.Parent = middlePanel
protectInstance(noclipButton)

local ncCorner = Instance.new("UICorner")
ncCorner.CornerRadius = UDim.new(0, 8)
ncCorner.Parent = noclipButton
protectInstance(ncCorner)

noclipButton.MouseButton1Click:Connect(function()
    settings.noclip = not settings.noclip
    noclipButton.Text = "Noclip: " .. (settings.noclip and "ON" or "OFF")
end)

local speedBox = Instance.new("TextBox")
speedBox.Size = UDim2.new(0.6, 0, 0, 30)
speedBox.Position = UDim2.new(0.05, 0, 0.25, 0)
speedBox.Text = tostring(settings.speed)
speedBox.TextColor3 = Color3.fromRGB(255, 255, 255)
speedBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
speedBox.Font = Enum.Font.Gotham
speedBox.TextSize = 14
speedBox.Parent = middlePanel
protectInstance(speedBox)

local sbCorner = Instance.new("UICorner")
sbCorner.CornerRadius = UDim.new(0, 8)
sbCorner.Parent = speedBox
protectInstance(sbCorner)

local setSpeedButton = Instance.new("TextButton")
setSpeedButton.Size = UDim2.new(0.3, 0, 0, 30)
setSpeedButton.Position = UDim2.new(0.65, 0, 0.25, 0)
setSpeedButton.Text = "Set Speed"
setSpeedButton.TextColor3 = Color3.fromRGB(255, 255, 255)
setSpeedButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
setSpeedButton.Font = Enum.Font.Gotham
setSpeedButton.TextSize = 12
setSpeedButton.Parent = middlePanel
protectInstance(setSpeedButton)

local ssCorner = Instance.new("UICorner")
ssCorner.CornerRadius = UDim.new(0, 8)
ssCorner.Parent = setSpeedButton
protectInstance(ssCorner)

setSpeedButton.MouseButton1Click:Connect(function()
    local newSpeed = tonumber(speedBox.Text)
    if newSpeed and newSpeed >= 16 and newSpeed <= settings.maxSpeed then
        settings.speed = newSpeed
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.WalkSpeed = settings.speed
        end
    else
        speedBox.Text = tostring(settings.speed)
    end
end)

local teleportSheriffButton = Instance.new("TextButton")
teleportSheriffButton.Size = UDim2.new(0.9, 0, 0, 40)
teleportSheriffButton.Position = UDim2.new(0.05, 0, 0.4, 0)
teleportSheriffButton.Text = "TP to Sheriff"
teleportSheriffButton.TextColor3 = Color3.fromRGB(255, 255, 255)
teleportSheriffButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
teleportSheriffButton.Font = Enum.Font.Gotham
teleportSheriffButton.TextSize = 12
teleportSheriffButton.Parent = middlePanel
protectInstance(teleportSheriffButton)

local tsCorner = Instance.new("UICorner")
tsCorner.CornerRadius = UDim.new(0, 8)
tsCorner.Parent = teleportSheriffButton
protectInstance(tsCorner)

teleportSheriffButton.MouseButton1Click:Connect(function()
    teleportToSheriff()
end)

local autoCollectButton = Instance.new("TextButton")
autoCollectButton.Size = UDim2.new(0.9, 0, 0, 40)
autoCollectButton.Position = UDim2.new(0.05, 0, 0.55, 0)
autoCollectButton.Text = "Auto Collect: OFF"
autoCollectButton.TextColor3 = Color3.fromRGB(255, 255, 255)
autoCollectButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
autoCollectButton.Font = Enum.Font.Gotham
autoCollectButton.TextSize = 12
autoCollectButton.Parent = middlePanel
protectInstance(autoCollectButton)

local acCorner = Instance.new("UICorner")
acCorner.CornerRadius = UDim.new(0, 8)
acCorner.Parent = autoCollectButton
protectInstance(acCorner)

autoCollectButton.MouseButton1Click:Connect(function()
    settings.autoCollectCoins = not settings.autoCollectCoins
    autoCollectButton.Text = "Auto Collect: " .. (settings.autoCollectCoins and "ON" or "OFF")
end)

-- Right Panel (Information)
local rightTitle = Instance.new("TextLabel")
rightTitle.Size = UDim2.new(1, 0, 0, 30)
rightTitle.Text = "Information"
rightTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
rightTitle.BackgroundTransparency = 1
rightTitle.Font = Enum.Font.GothamBold
rightTitle.TextSize = 14
rightTitle.Parent = rightPanel
protectInstance(rightTitle)

local function createClickableLabel(parent, text, position, url)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0.9, 0, 0, 30)
    frame.Position = position
    frame.BackgroundTransparency = 1
    frame.Parent = parent
    protectInstance(frame)
    
    local label = Instance.new("TextButton")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.Text = text
    label.TextColor3 = Color3.fromRGB(100, 150, 255)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    protectInstance(label)
    
    local underline = Instance.new("Frame")
    underline.Size = UDim2.new(1, 0, 0, 1)
    underline.Position = UDim2.new(0, 0, 1, -1)
    underline.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
    underline.Parent = frame
    protectInstance(underline)
    
    label.MouseButton1Click:Connect(function()
        if url then
            local success, err = pcall(function()
                HttpService:GetAsync(url, true)
            end)
            if not success then
                setclipboard(url)
                statusLabel.Text = "Status: URL copied to clipboard!"
                task.wait(3)
                statusLabel.Text = "Status: Ready"
            end
        end
    end)
    
    return label
end

-- Create clickable links
createClickableLabel(rightPanel, "Discord: example#1234", UDim2.new(0.05, 0, 0.1, 0), "https://discord.gg/")
createClickableLabel(rightPanel, "YouTube: example", UDim2.new(0.05, 0, 0.2, 0), "https://youtube.com/")

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(0.9, 0, 0, 60)
statusLabel.Position = UDim2.new(0.05, 0, 0.5, 0)
statusLabel.Text = "Status: Ready"
statusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 14
statusLabel.Parent = rightPanel
protectInstance(statusLabel)

-- Noclip Implementation
local function applyNoclip(char)
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local rootPart = char.HumanoidRootPart
    
    if settings.noclip then
        rootPart.Velocity = Vector3.new(0, 0, 0)
        rootPart.CanCollide = false
        
        local moveDirection = Vector3.new(0, 0, 0)
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            moveDirection = moveDirection + Vector3.new(0, 0, -1)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            moveDirection = moveDirection + Vector3.new(0, 0, 1)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            moveDirection = moveDirection + Vector3.new(-1, 0, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            moveDirection = moveDirection + Vector3.new(1, 0, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            moveDirection = moveDirection + Vector3.new(0, 1, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            moveDirection = moveDirection + Vector3.new(0, -1, 0)
        end
        
        if moveDirection.Magnitude > 0 then
            moveDirection = moveDirection.Unit * settings.noclipSpeed
            rootPart.CFrame = rootPart.CFrame + moveDirection
        end
    else
        rootPart.CanCollide = true
    end
end

-- Character Handler
local function onCharacterAdded(char)
    local humanoid = char:WaitForChild("Humanoid")
    local rootPart = char:WaitForChild("HumanoidRootPart")
    
    -- Check if we became murderer to adjust performance
    local isMurderer = false
    local function checkRole()
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        local char = LocalPlayer.Character
        isMurderer = (backpack and backpack:FindFirstChild("Knife")) or (char and char:FindFirstChild("Knife"))
        
        -- Adjust ESP update frequency if murderer
        settings.espUpdateInterval = isMurderer and 1 or 0.5
    end
    
    checkRole()
    
    LocalPlayer.CharacterAdded:Connect(function()
        task.wait(1)
        checkRole()
    end)
    
    LocalPlayer.Backpack.ChildAdded:Connect(checkRole)
    LocalPlayer.Backpack.ChildRemoved:Connect(checkRole)
    
    if settings.godMode then
        local function applyGodMode(ch)
            local hum = ch:WaitForChild("Humanoid")
            if hum then
                hum.MaxHealth = math.huge
                hum.Health = math.huge
                hum.Died:Connect(function()
                    task.wait(0.5)
                    applyGodMode(ch)
                end)
            end
        end
        applyGodMode(char)
    end
    
    if settings.invisible then
        setInvisibility(true)
    end
    
    if humanoid then
        humanoid.WalkSpeed = settings.speed
    end
    
    -- Main game loop with optimized updates
    RunService.Stepped:Connect(function()
        applyNoclip(char)
        
        -- Only run these features occasionally when murderer to reduce lag
        if not isMurderer or tick() % 2 < 0.1 then
            autoPickGun()
            collectCoins()
        end
    end)
end

LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
if LocalPlayer.Character then onCharacterAdded(LocalPlayer.Character) end

-- Optimized ESP updates
RunService.RenderStepped:Connect(function()
    updateESP()
end)

-- F1 Hotkey for GUI Toggle
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.F1 then
        settings.guiVisible = not settings.guiVisible
        mainContainer.Visible = settings.guiVisible
    end
end)

-- Anti-AFK
local VirtualUser = game:GetService("VirtualUser")
game:GetService("Players").LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-- Randomize script name to prevent detection
local scriptName = "MM2Power_"..tostring(math.random(10000,99999))
getgenv()[scriptName] = true