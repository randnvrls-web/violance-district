--[[
    🔥 VIOLENCE DISTRICT - ALL IN ONE (NO KEY) 🔥
    Fitur:
        1. ESP (Killer, Survivor, Generator)
        2. Auto Generator (Skill Check Perfect)
        3. Aimbot (Auto Aim ke Killer)
    Kontrol:
        - F2: Toggle Aimbot
        - F3: Toggle ESP
        - F4: Toggle Generator
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")

-- ================================================================
-- KONFIGURASI
-- ================================================================
local CONFIG = {
    ESP_DISTANCE = 200,
    AIM_DISTANCE = 250,
    AIM_LINE_OF_SIGHT = false,
}

-- ================================================================
-- VARIABEL
-- ================================================================
local espObjects = {}
local espEnabled = true
local genEnabled = true
local aimEnabled = false
local lastESPUpdate = 0
local frame = nil

-- ================================================================
-- DETEKSI KILLER
-- ================================================================
local function isKiller(player)
    if player == LocalPlayer then return false end
    if not player.Character then return false end
    if player:GetAttribute("role") == "Killer" then return true end
    if player:GetAttribute("IsKiller") == true then return true end
    if player.Team and player.Team.Name:lower():find("killer") then return true end
    local hum = player.Character:FindFirstChild("Humanoid")
    if hum and hum.MaxHealth > 150 then return true end
    return false
end

-- ================================================================
-- ESP (DENGAN FALLBACK)
-- ================================================================
local function clearESP()
    for _, obj in pairs(espObjects) do
        pcall(function() obj.Visible = false end)
    end
    espObjects = {}
end

local function createESPBox(pos, color, text, onScreen)
    if not onScreen then return nil end
    local success, box = pcall(Drawing.new, "Square")
    if not success then return nil end
    box.Thickness = 1.5
    box.Color = color
    box.Transparency = 1
    box.Visible = true
    box.Filled = false
    box.From = Vector2.new(pos.X - 15, pos.Y - 30)
    box.To = Vector2.new(pos.X + 15, pos.Y + 30)
    local success2, label = pcall(Drawing.new, "Text")
    if not success2 then return { box = box } end
    label.Size = 12
    label.Color = Color3.new(1, 1, 1)
    label.Center = true
    label.Visible = true
    label.Text = text
    label.Position = Vector2.new(pos.X, pos.Y - 35)
    return { box = box, label = label }
end

local function updateESP()
    clearESP()
    if not espEnabled then return end
    local myPos = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myPos then return end
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local char = player.Character
            if char then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                local hum = char:FindFirstChild("Humanoid")
                if hrp and hum and hum.Health > 0 then
                    local dist = (hrp.Position - myPos.Position).Magnitude
                    if dist <= CONFIG.ESP_DISTANCE then
                        local pos, onScreen = Camera:WorldToScreenPoint(hrp.Position)
                        if onScreen then
                            local isK = isKiller(player)
                            local color = isK and Color3.new(1, 0, 0) or Color3.new(0, 1, 0)
                            local label = isK and "🔴 KILLER" or "🟢 SURVIVOR"
                            local esp = createESPBox(pos, color, label .. " [" .. math.floor(dist) .. "s]", onScreen)
                            if esp then
                                if esp.box then table.insert(espObjects, esp.box) end
                                if esp.label then table.insert(espObjects, esp.label) end
                            end
                        end
                    end
                end
            end
        end
    end
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and (obj.Name:lower():find("generator") or obj.Name:lower():find("gen")) then
            local dist = (obj.Position - myPos.Position).Magnitude
            if dist <= CONFIG.ESP_DISTANCE then
                local pos, onScreen = Camera:WorldToScreenPoint(obj.Position)
                if onScreen then
                    local esp = createESPBox(pos, Color3.new(0, 1, 1), "⚡ GENERATOR [" .. math.floor(dist) .. "s]", onScreen)
                    if esp then
                        if esp.box then table.insert(espObjects, esp.box) end
                        if esp.label then table.insert(espObjects, esp.label) end
                    end
                end
            end
        end
    end
end

RunService.Heartbeat:Connect(function()
    if tick() - lastESPUpdate > 0.2 then
        updateESP()
        lastESPUpdate = tick()
    end
end)

-- ================================================================
-- AUTO GENERATOR
-- ================================================================
local function findSkillCheckPosition()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if playerGui then
        for _, gui in pairs(playerGui:GetDescendants()) do
            if gui:IsA("Frame") or gui:IsA("ImageLabel") then
                local name = gui.Name:lower()
                if name:find("skillcheck") or name:find("skill") then
                    if gui.Visible and gui.AbsoluteSize.X > 10 then
                        local pos = gui.AbsolutePosition
                        local size = gui.AbsoluteSize
                        return Vector2.new(pos.X + size.X/2, pos.Y + size.Y/2)
                    end
                end
            end
        end
    end
    return nil
end

local function clickSkillCheck()
    local pos = findSkillCheckPosition()
    if pos then
        VirtualInputManager:SendMouseMovement(pos.X, pos.Y, 0, 0)
        task.wait(0.02)
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
        task.wait(0.03)
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
        return true
    end
    return false
end

local function findGenerator()
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and (obj.Name:lower():find("generator") or obj.Name:lower():find("gen")) then
            return obj
        end
    end
    return nil
end

task.spawn(function()
    while task.wait(0.3) do
        if genEnabled then
            if not clickSkillCheck() then
                local gen = findGenerator()
                if gen then
                    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        hrp.CFrame = CFrame.new(gen.Position + Vector3.new(0, 2, 0))
                    end
                end
            end
        end
    end
end)

-- ================================================================
-- AIMBOT
-- ================================================================
local function getTarget()
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    local mousePos = UserInputService:GetMouseLocation()
    local center = Vector2.new(mousePos.X, mousePos.Y)
    local best, bestScore = nil, math.huge
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and isKiller(player) then
            local char = player.Character
            if char then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local dist = (hrp.Position - root.Position).Magnitude
                    if dist <= CONFIG.AIM_DISTANCE then
                        local pos, onScreen = Camera:WorldToScreenPoint(hrp.Position)
                        if onScreen then
                            local screenDist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                            if screenDist < bestScore then
                                bestScore = screenDist
                                best = player
                            end
                        end
                    end
                end
            end
        end
    end
    return best
end

RunService.RenderStepped:Connect(function()
    if aimEnabled then
        local target = getTarget()
        if target and target.Character then
            local head = target.Character:FindFirstChild("Head")
            if head then
                Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, head.Position)
            end
        end
    end
end)

-- ================================================================
-- GUI (DI POJOK KIRI ATAS)
-- ================================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "VDAllInOne"
screenGui.ResetOnSpawn = false
screenGui.Parent = LocalPlayer.PlayerGui

frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 200, 0, 170)
frame.Position = UDim2.new(0, 10, 0, 10)
frame.BackgroundColor3 = Color3.new(0.08, 0.08, 0.12)
frame.BackgroundTransparency = 0.2
frame.BorderSizePixel = 1
frame.BorderColor3 = Color3.new(0.2, 0.2, 0.3)
frame.ClipsDescendants = true
frame.Parent = screenGui
frame.Visible = true

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 25)
title.Text = "🔥 VD ALL IN ONE"
title.BackgroundColor3 = Color3.new(0.15, 0.15, 0.25)
title.TextColor3 = Color3.new(1, 0.5, 0)
title.TextScaled = true
title.Parent = frame

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 30, 0, 25)
toggleBtn.Position = UDim2.new(1, -32, 0, 0)
toggleBtn.Text = "✕"
toggleBtn.BackgroundColor3 = Color3.new(0.3, 0.1, 0.1)
toggleBtn.TextColor3 = Color3.new(1, 1, 1)
toggleBtn.TextScaled = true
toggleBtn.Parent = frame
toggleBtn.MouseButton1Click:Connect(function()
    frame.Visible = not frame.Visible
end)

local dragging = false
local dragStart, frameStart
title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        frameStart = frame.Position
    end
end)
title.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(0, frameStart.X.Offset + delta.X, 0, frameStart.Y.Offset + delta.Y)
    end
end)
title.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

local function createButton(text, y, flag, defaultState)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.85, 0, 0, 25)
    btn.Position = UDim2.new(0.075, 0, y, 0)
    btn.Text = text .. ": " .. (defaultState and "ON" or "OFF")
    btn.BackgroundColor3 = Color3.new(0.12, 0.12, 0.2)
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.TextSize = 12
    btn.BorderSizePixel = 1
    btn.BorderColor3 = Color3.new(0.2, 0.2, 0.3)
    btn.Parent = frame
    btn.MouseButton1Click:Connect(function()
        if flag == "ESP" then
            espEnabled = not espEnabled
            btn.Text = "ESP: " .. (espEnabled and "ON" or "OFF")
            if not espEnabled then clearESP() end
        elseif flag == "Generator" then
            genEnabled = not genEnabled
            btn.Text = "Generator: " .. (genEnabled and "ON" or "OFF")
        elseif flag == "Aimbot" then
            aimEnabled = not aimEnabled
            btn.Text = "Aimbot: " .. (aimEnabled and "ON" or "OFF")
        end
    end)
    return btn
end

createButton("ESP", 0.18, "ESP", true)
createButton("Generator", 0.38, "Generator", true)
createButton("Aimbot", 0.58, "Aimbot", false)

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(0.9, 0, 0, 20)
statusLabel.Position = UDim2.new(0.05, 0, 0.78, 0)
statusLabel.Text = "✅ Script Active"
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.new(0, 1, 0)
statusLabel.TextSize = 11
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = frame

-- ================================================================
-- KEYBINDS
-- ================================================================
local function updateButtons()
    for _, child in pairs(frame:GetChildren()) do
        if child:IsA("TextButton") then
            if child.Text:find("ESP") then
                child.Text = "ESP: " .. (espEnabled and "ON" or "OFF")
            elseif child.Text:find("Generator") then
                child.Text = "Generator: " .. (genEnabled and "ON" or "OFF")
            elseif child.Text:find("Aimbot") then
                child.Text = "Aimbot: " .. (aimEnabled and "ON" or "OFF")
            end
        end
    end
end

UserInputService.InputBegan:Connect(function(input, g)
    if g then return end
    if input.KeyCode == Enum.KeyCode.F2 then
        aimEnabled = not aimEnabled
        updateButtons()
    elseif input.KeyCode == Enum.KeyCode.F3 then
        espEnabled = not espEnabled
        updateButtons()
        if not espEnabled then clearESP() end
    elseif input.KeyCode == Enum.KeyCode.F4 then
        genEnabled = not genEnabled
        updateButtons()
    end
end)

print("🔥 VD All In One Loaded!")
print("   F2: Aimbot | F3: ESP | F4: Generator")
print("   GUI di pojok kiri atas, klik ✕ untuk tutup/buka")