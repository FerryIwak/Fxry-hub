--[[
    Fxry's Core Blox Fruits Suite v3.0
    ===================================
    Features:
    - Auto Farm (Level/Boss/Sea Beast)
    - Auto Quest
    - Auto Collect Drops
    - Auto Unlock Sea 2 (Level 700+)
    - Auto Unlock Sea 3 (Level 1500+)
    - ESP (Enemy)
    - Teleport System
    - Full GUI
    - Anti-AFK
    - Keybinds
    - No external dependencies
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")
local UserInput = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local RootPart = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid")

-- ============================================================
-- CONFIGURATION
-- ============================================================
local Config = {
    FarmMode = "Level",           -- "Level" | "Boss" | "SeaBeast"
    AutoQuest = true,
    AutoTeleport = true,
    AutoAttack = true,
    AutoCollect = true,
    TargetLevel = 2550,
    SafeDistance = 20,
    AttackCooldown = 0.3,
    UseFruit = true,
    FruitName = "Magma",
    Sea2Level = 700,
    Sea3Level = 1500,
    AutoUnlockSea2 = true,
    AutoUnlockSea3 = true,
    ESPEnabled = true,
    ESPColor = Color3.fromRGB(255, 0, 0),
    AntiAFK = true,
}

-- ============================================================
-- UTILITY FUNCTIONS
-- ============================================================
local function GetCurrentSea()
    local spawnLocation = Player:FindFirstChild("SpawnLocation")
    if spawnLocation then
        local loc = spawnLocation.Value or ""
        if string.find(loc, "Sea 3") or string.find(loc, "Third Sea") then return 3 end
        if string.find(loc, "Sea 2") or string.find(loc, "Second Sea") then return 2 end
        return 1
    end
    if Workspace:FindFirstChild("Sea3Portal") or Workspace:FindFirstChild("ThirdSeaPortal") then return 3 end
    if Workspace:FindFirstChild("Sea2Portal") or Workspace:FindFirstChild("SecondSeaPortal") then return 2 end
    if Workspace:FindFirstChild("Castle on the Sea") then return 2 end
    if Workspace:FindFirstChild("Mansion") or Workspace:FindFirstChild("Dragon") then return 1 end
    return 1
end

local function GetPlayerLevel()
    return Player:FindFirstChild("Level") and Player.Level.Value or 0
end

local function TeleportTo(location)
    if type(location) == "string" then
        local target = Workspace:FindFirstChild(location)
        if target then
            local chest = target:FindFirstChild("Chest")
            if chest then
                RootPart.CFrame = chest.CFrame + Vector3.new(0, 10, 0)
                return true
            end
            local parts = target:GetDescendants()
            for _, part in pairs(parts) do
                if part:IsA("BasePart") then
                    RootPart.CFrame = part.CFrame + Vector3.new(0, 10, 0)
                    return true
                end
            end
        end
        return false
    elseif type(location) == "Vector3" then
        RootPart.CFrame = CFrame.new(location)
        return true
    end
    return false
end

local function UseAbility(key)
    local keyMap = {
        ["Q"] = 1, ["E"] = 2, ["R"] = 3, ["F"] = 4,
        ["X"] = 5, ["C"] = 6, ["V"] = 7, ["Z"] = 8
    }
    local k = keyMap[key]
    if k then
        VirtualUser:ClickButton2(k)
        return true
    end
    return false
end

local function FireRemote(remoteName, ...)
    local remote = ReplicatedStorage:FindFirstChild("Remotes") and 
                   ReplicatedStorage.Remotes:FindFirstChild(remoteName)
    if remote then
        remote:FireServer(...)
        return true
    end
    return false
end

-- ============================================================
-- ESP SYSTEM
-- ============================================================
local ESPObjects = {}

local function ClearESP()
    for _, obj in pairs(ESPObjects) do
        pcall(function() obj:Destroy() end)
    end
    ESPObjects = {}
end

local function CreateESP(target, color, label)
    if not Config.ESPEnabled or not target then return end
    local highlight = Instance.new("Highlight")
    highlight.Name = "Fxry_ESP"
    highlight.Adornee = target
    highlight.FillColor = color or Config.ESPColor
    highlight.FillTransparency = 0.4
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.OutlineTransparency = 0.2
    highlight.Parent = target
    table.insert(ESPObjects, highlight)
    
    if label then
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "Fxry_ESP_Label"
        billboard.Size = UDim2.new(0, 120, 0, 30)
        billboard.Adornee = target
        billboard.Parent = target
        table.insert(ESPObjects, billboard)
        
        local text = Instance.new("TextLabel")
        text.Size = UDim2.new(1, 0, 1, 0)
        text.BackgroundTransparency = 1
        text.TextColor3 = Color3.fromRGB(255, 255, 255)
        text.TextStrokeTransparency = 0.2
        text.Text = label or "ENEMY"
        text.Parent = billboard
        table.insert(ESPObjects, text)
    end
end

local function UpdateESP()
    ClearESP()
    if not Config.ESPEnabled then return end
    
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") then
            if v.Name ~= Player.Name and v.Humanoid.Health > 0 then
                local dist = (v.HumanoidRootPart.Position - RootPart.Position).Magnitude
                if dist < 500 then
                    CreateESP(v, Config.ESPColor, string.format("%s [%.0fm]", v.Name, dist))
                end
            end
        end
    end
end

-- ============================================================
-- FARMING SYSTEM
-- ============================================================
local isFarming = true
local currentTarget = nil
local isAttacking = false
local farmStatus = "Idle"

local function GetClosestMob()
    local closest = nil
    local shortestDist = math.huge
    local playerPos = RootPart.Position
    
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") then
            if v.Name ~= Player.Name and v.Humanoid.Health > 0 then
                local dist = (v.HumanoidRootPart.Position - playerPos).Magnitude
                if dist < shortestDist and dist < 600 then
                    if v:FindFirstChild("Head") and v.Head:FindFirstChild("Health") then
                        closest = v
                        shortestDist = dist
                    elseif v:FindFirstChild("IsEnemy") and v.IsEnemy.Value == true then
                        closest = v
                        shortestDist = dist
                    end
                end
            end
        end
    end
    return closest
end

local function GetQuest()
    local questData = Player:FindFirstChild("QuestData")
    if questData and questData:FindFirstChild("Quest") then
        return questData.Quest.Value
    end
    return nil
end

local function HasQuest()
    return GetQuest() ~= nil
end

local function StartQuest()
    local level = GetPlayerLevel()
    local npcMap = {
        [0] = "Village Elder",
        [100] = "Marine Captain",
        [300] = "Pirate Captain",
        [600] = "Sky Knight",
        [1000] = "Dragon",
        [1500] = "King",
        [2000] = "Elder"
    }
    local npc = "Village Elder"
    for lvl, name in pairs(npcMap) do
        if level >= lvl then npc = name end
    end
    return FireRemote("StartQuest", npc)
end

local function CompleteQuest()
    return FireRemote("CompleteQuest")
end

local function CollectDrops()
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("Part") and (string.find(v.Name, "Drop") or string.find(v.Name, "Fruit")) then
            local dist = (v.Position - RootPart.Position).Magnitude
            if dist < 30 then
                pcall(function()
                    firetouchinterest(v, Character, 0)
                    task.wait(0.05)
                    firetouchinterest(v, Character, 1)
                end)
            end
        end
    end
end

local function FarmLoop()
    while isFarming do
        task.wait(0.1)
        
        Character = Player.Character or Player.CharacterAdded:Wait()
        if not Character then task.wait(1) continue end
        RootPart = Character:FindFirstChild("HumanoidRootPart")
        Humanoid = Character:FindFirstChild("Humanoid")
        if not RootPart or not Humanoid then task.wait(1) continue end
        
        local level = GetPlayerLevel()
        if level >= Config.TargetLevel then
            farmStatus = "Target Reached"
            isFarming = false
            break
        end
        
        if Config.AutoQuest then
            if not HasQuest() then
                StartQuest()
                task.wait(0.5)
            else
                local quest = GetQuest()
                if quest and quest.Progress and quest.Progress >= quest.Required then
                    CompleteQuest()
                    task.wait(0.3)
                end
            end
        end
        
        local target = GetClosestMob()
        if target then
            currentTarget = target
            farmStatus = "Farming: " .. target.Name
            if Config.ESPEnabled then
                CreateESP(target, Config.ESPColor, target.Name)
            end
        else
            farmStatus = "Searching..."
            if Config.AutoTeleport then
                local spots = {
                    [0] = "Jungle",
                    [100] = "Prison",
                    [300] = "Ice",
                    [600] = "Sky",
                    [1000] = "Water 7",
                    [1500] = "Castle on the Sea",
                    [2000] = "Mansion",
                }
                local bestSpot = "Jungle"
                for lvl, spot in pairs(spots) do
                    if level >= lvl then bestSpot = spot end
                end
                TeleportTo(bestSpot)
                task.wait(1)
            end
            task.wait(0.5)
            continue
        end
        
        local targetPos = target.HumanoidRootPart.Position
        local distance = (targetPos - RootPart.Position).Magnitude
        
        if distance > Config.SafeDistance then
            RootPart.CFrame = CFrame.new(RootPart.Position, targetPos)
            VirtualUser:Button2Down("W")
            task.wait(0.1)
            VirtualUser:Button2Up("W")
        else
            if Config.AutoAttack and not isAttacking then
                isAttacking = true
                VirtualUser:ClickButton2(0)
                task.wait(Config.AttackCooldown)
                if Config.UseFruit then
                    UseAbility("Z")
                    task.wait(0.15)
                    UseAbility("X")
                    task.wait(0.15)
                    UseAbility("C")
                end
                isAttacking = false
            end
        end
        
        if Config.AutoCollect then
            CollectDrops()
        end
        
        if Config.ESPEnabled and math.random(1, 10) == 1 then
            UpdateESP()
        end
    end
end

-- ============================================================
-- SEA UNLOCK SYSTEM
-- ============================================================
local SeaConfig = {
    Sea2 = {
        RequiredLevel = 700,
        NPCLocation = "Ice Castle",
        NPCName = "Experienced Captain",
        TeleportSpot = Vector3.new(-1200, 80, -2500),
        PortalName = "Sea2Portal",
        DialogTriggers = {"Yes", "Confirm", "Travel"},
    },
    Sea3 = {
        RequiredLevel = 1500,
        NPCLocation = "Castle on the Sea",
        NPCName = "King",
        TeleportSpot = Vector3.new(-2800, 50, -1500),
        PortalName = "Sea3Portal",
        DialogTriggers = {"Yes", "Confirm", "Travel", "To Third Sea"},
    },
}

local function FindNPC(npcName, radius)
    radius = radius or 500
    local playerPos = RootPart.Position
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") then
            local name = v.Name or ""
            if string.find(string.lower(name), string.lower(npcName)) then
                local dist = (v.HumanoidRootPart.Position - playerPos).Magnitude
                if dist < radius then return v end
            end
        end
    end
    return nil
end

local function InteractWithNPC(npc, triggers)
    if not npc then return false end
    
    local npcPos = npc.HumanoidRootPart.Position
    local distance = (npcPos - RootPart.Position).Magnitude
    if distance > 15 then
        RootPart.CFrame = CFrame.new(RootPart.Position, npcPos)
        VirtualUser:Button2Down("W")
        task.wait(0.5)
        VirtualUser:Button2Up("W")
    end
    
    VirtualUser:ClickButton2(0)
    task.wait(0.3)
    VirtualUser:ClickButton2(2)
    task.wait(0.3)
    FireRemote("InteractNPC", npc.Name)
    FireRemote("TalkToNPC", npc.Name)
    
    for i = 1, 5 do
        local gui = Player.PlayerGui:FindFirstChild("Dialog")
        if gui then
            for _, btn in pairs(gui:GetDescendants()) do
                if btn:IsA("TextButton") then
                    local text = btn.Text or ""
                    for _, trigger in pairs(triggers or {}) do
                        if string.find(text, trigger) then
                            btn:Click()
                            task.wait(0.5)
                            return true
                        end
                    end
                end
            end
        end
        task.wait(0.3)
    end
    return false
end

local function TouchPortal(portalName)
    local portal = Workspace:FindFirstChild(portalName)
    if not portal then
        for _, v in pairs(Workspace:GetDescendants()) do
            if v:IsA("Part") and string.find(string.lower(v.Name), "portal") then
                portal = v
                break
            end
        end
    end
    if portal then
        RootPart.CFrame = portal.CFrame + Vector3.new(0, 5, 0)
        task.wait(0.5)
        pcall(function()
            firetouchinterest(portal, Character, 0)
            task.wait(0.2)
            firetouchinterest(portal, Character, 1)
        end)
        return true
    end
    return false
end

local function UnlockSea(seaNumber)
    local config = seaNumber == 3 and SeaConfig.Sea3 or SeaConfig.Sea2
    local seaName = seaNumber == 3 and "Third Sea" or "Second Sea"
    local currentSea = GetCurrentSea()
    
    if currentSea >= seaNumber then
        print("[Fxry] Already in " .. seaName)
        return true
    end
    if currentSea == 3 and seaNumber == 2 then
        print("[Fxry] Can't go back to Sea 2 from Sea 3")
        return false
    end
    
    print("[Fxry] Unlocking " .. seaName .. "...")
    
    while GetPlayerLevel() < config.RequiredLevel do
        print("[Fxry] Farming to " .. config.RequiredLevel .. "... Level: " .. GetPlayerLevel())
        if not isFarming then
            isFarming = true
            spawn(FarmLoop)
        end
        task.wait(2)
    end
    
    if not isFarming then
        isFarming = true
        spawn(FarmLoop)
    end
    
    TeleportTo(config.NPCLocation)
    task.wait(2)
    local npc = FindNPC(config.NPCName, 800)
    if not npc then
        RootPart.CFrame = CFrame.new(config.TeleportSpot)
        task.wait(2)
        npc = FindNPC(config.NPCName, 500)
    end
    
    if npc then
        if InteractWithNPC(npc, config.DialogTriggers) then
            task.wait(2)
            local startTime = tick()
            while GetCurrentSea() < seaNumber and (tick() - startTime) < 15 do
                if tick() - startTime > 8 then
                    TouchPortal(config.PortalName)
                end
                task.wait(1)
            end
            if GetCurrentSea() >= seaNumber then
                print("[Fxry] Successfully unlocked " .. seaName .. "!")
                return true
            end
        end
    end
    
    if TouchPortal(config.PortalName) then
        task.wait(3)
        if GetCurrentSea() >= seaNumber then
            print("[Fxry] Unlocked via portal!")
            return true
        end
    end
    
    print("[Fxry] Auto-unlock failed. Manual intervention may be needed.")
    return false
end

local function UnlockSea2()
    return UnlockSea(2)
end

local function UnlockSea3()
    if GetCurrentSea() < 2 then
        print("[Fxry] Need to unlock Sea 2 first.")
        local success = UnlockSea(2)
        if not success then return false end
        task.wait(3)
        Character = Player.Character or Player.CharacterAdded:Wait()
        RootPart = Character:WaitForChild("HumanoidRootPart")
    end
    return UnlockSea(3)
end

-- ============================================================
-- GUI SYSTEM
-- ============================================================
local function CreateGUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "Fxry_SuiteGUI"
    screenGui.Parent = Player.PlayerGui
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 340, 0, 420)
    frame.Position = UDim2.new(0, 10, 0, 10)
    frame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    frame.BackgroundTransparency = 0.1
    frame.BorderSizePixel = 2
    frame.BorderColor3 = Color3.fromRGB(255, 0, 150)
    frame.Parent = screenGui
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 45)
    title.Text = "⚡ Fxry SUITE v3.0"
    title.TextColor3 = Color3.fromRGB(255, 50, 200)
    title.TextScaled = true
    title.BackgroundTransparency = 1
    title.Parent = frame
    
    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, 0, 0, 25)
    status.Position = UDim2.new(0, 0, 0, 45)
    status.Text = "Status: Idle"
    status.TextColor3 = Color3.fromRGB(200, 200, 200)
    status.TextScaled = true
    status.BackgroundTransparency = 1
    status.Parent = frame
    _G.Fxry_StatusLabel = status
    
    local farmBtn = Instance.new("TextButton")
    farmBtn.Size = UDim2.new(0, 140, 0, 35)
    farmBtn.Position = UDim2.new(0, 10, 0, 75)
    farmBtn.Text = "▶ START FARM"
    farmBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
    farmBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    farmBtn.Parent = frame
    farmBtn.MouseButton1Click:Connect(function()
        isFarming = not isFarming
        farmBtn.Text = isFarming and "⏹ STOP FARM" or "▶ START FARM"
        farmBtn.BackgroundColor3 = isFarming and Color3.fromRGB(200, 50, 50) or Color3.fromRGB(50, 200, 50)
        if isFarming then
            spawn(FarmLoop)
            status.Text = "Status: Farming"
        else
            status.Text = "Status: Stopped"
        end
    end)
    
    local toggles = {
        {name = "Auto Quest", key = "AutoQuest", y = 120},
        {name = "Auto Teleport", key = "AutoTeleport", y = 155},
        {name = "Auto Collect", key = "AutoCollect", y = 190},
        {name = "ESP", key = "ESPEnabled", y = 225},
        {name = "Use Fruit", key = "UseFruit", y = 260},
    }
    
    for _, toggle in pairs(toggles) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 140, 0, 28)
        btn.Position = UDim2.new(0, 10 + ((toggle.y - 120) / 35) % 2 * 150, 0, toggle.y)
        btn.Text = toggle.name .. ": " .. (Config[toggle.key] and "ON" or "OFF")
        btn.BackgroundColor3 = Config[toggle.key] and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Parent = frame
        btn.MouseButton1Click:Connect(function()
            Config[toggle.key] = not Config[toggle.key]
            btn.Text = toggle.name .. ": " .. (Config[toggle.key] and "ON" or "OFF")
            btn.BackgroundColor3 = Config[toggle.key] and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
            if toggle.key == "ESPEnabled" and not Config.ESPEnabled then
                ClearESP()
            end
        end)
    end
    
    local sea2Btn = Instance.new("TextButton")
    sea2Btn.Size = UDim2.new(0, 140, 0, 30)
    sea2Btn.Position = UDim2.new(0, 10, 0, 295)
    sea2Btn.Text = "🌊 UNLOCK SEA 2"
    sea2Btn.BackgroundColor3 = Color3.fromRGB(100, 50, 200)
    sea2Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    sea2Btn.Parent = frame
    sea2Btn.MouseButton1Click:Connect(function()
        sea2Btn.Text = "⏳ UNLOCKING..."
        sea2Btn.BackgroundColor3 = Color3.fromRGB(200, 100, 50)
        spawn(function()
            local success = UnlockSea2()
            sea2Btn.Text = success and "✅ SEA 2 UNLOCKED" or "❌ FAILED"
            sea2Btn.BackgroundColor3 = success and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
            task.wait(3)
            sea2Btn.Text = "🌊 UNLOCK SEA 2"
            sea2Btn.BackgroundColor3 = Color3.fromRGB(100, 50, 200)
        end)
    end)
    
    local sea3Btn = Instance.new("TextButton")
    sea3Btn.Size = UDim2.new(0, 140, 0, 30)
    sea3Btn.Position = UDim2.new(0, 160, 0, 295)
    sea3Btn.Text = "🌊🌊 UNLOCK SEA 3"
    sea3Btn.BackgroundColor3 = Color3.fromRGB(200, 50, 150)
    sea3Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    sea3Btn.Parent = frame
    sea3Btn.MouseButton1Click:Connect(function()
        sea3Btn.Text = "⏳ UNLOCKING..."
        sea3Btn.BackgroundColor3 = Color3.fromRGB(200, 100, 50)
        spawn(function()
            local success = UnlockSea3()
            sea3Btn.Text = success and "✅ SEA 3 UNLOCKED" or "❌ FAILED"
            sea3Btn.BackgroundColor3 = success and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
            task.wait(3)
            sea3Btn.Text = "🌊🌊 UNLOCK SEA 3"
            sea3Btn.BackgroundColor3 = Color3.fromRGB(200, 50, 150)
        end)
    end)
    
    local teleports = {"Jungle", "Prison", "Ice", "Sky", "Water 7", "Dragon", "Mansion", "Castle on the Sea"}
    for i, name in ipairs(teleports) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 75, 0, 22)
        btn.Position = UDim2.new(0, 10 + ((i-1) % 4) * 80, 0, 335 + math.floor((i-1) / 4) * 27)
        btn.Text = name
        btn.BackgroundColor3 = Color3.fromRGB(40, 40, 80)
        btn.TextColor3 = Color3.fromRGB(200, 200, 200)
        btn.TextScaled = true
        btn.Parent = frame
        btn.MouseButton1Click:Connect(function()
            TeleportTo(name)
        end)
    end
    
    spawn(function()
        while true do
            task.wait(0.5)
            local sea = GetCurrentSea()
            local level = GetPlayerLevel()
            local statusText = _G.Fxry_StatusLabel
            if statusText then
                statusText.Text = string.format("Lv.%d | Sea %d | %s", level, sea, farmStatus)
            end
        end
    end)
end

-- ============================================================
-- ANTI-AFK & KEYBINDS
-- ============================================================
local function SetupAntiAFK()
    if not Config.AntiAFK then return end
    Player.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(VirtualUser.Button2)
    end)
end

local function SetupKeybinds()
    UserInput.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.F9 then
            isFarming = not isFarming
            print(isFarming and "[Fxry] Farm started" or "[Fxry] Farm stopped")
            if isFarming then spawn(FarmLoop) end
        end
        if input.KeyCode == Enum.KeyCode.F10 then
            Config.ESPEnabled = not Config.ESPEnabled
            if not Config.ESPEnabled then ClearESP() end
            print("[Fxry] ESP " .. (Config.ESPEnabled and "ON" or "OFF"))
        end
        if input.KeyCode == Enum.KeyCode.F11 then
            UnlockSea2()
        end
        if input.KeyCode == Enum.KeyCode.F12 then
            UnlockSea3()
        end
        if input.KeyCode == Enum.KeyCode.RightShift then
            isFarming = false
            TeleportTo("Jungle")
            print("[Fxry] Emergency stop! Teleported to Jungle.")
        end
    end)
end

-- ============================================================
-- AUTO-START
-- ============================================================
local function AutoStart()
    print("[Fxry] Fxry's Core Blox Fruits Suite v3.0 loaded.")
    print("[Fxry] Current Sea: " .. GetCurrentSea() .. " | Level: " .. GetPlayerLevel())
    
    isFarming = true
    spawn(FarmLoop)
    
    local level = GetPlayerLevel()
    local sea = GetCurrentSea()
    
    if Config.AutoUnlockSea2 and sea == 1 and level >= Config.Sea2Level then
        print("[Fxry] Auto-unlocking Sea 2...")
        task.wait(2)
        spawn(UnlockSea2)
    end
    
    if Config.AutoUnlockSea3 and sea == 2 and level >= Config.Sea3Level then
        print("[Fxry] Auto-unlocking Sea 3...")
        task.wait(2)
        spawn(UnlockSea3)
    end
end

-- ============================================================
-- GLOBAL EXPOSURE
-- ============================================================
_G.Fxry = {
    Farm = FarmLoop,
    UnlockSea2 = UnlockSea2,
    UnlockSea3 = UnlockSea3,
    UnlockSea = UnlockSea,
    GetCurrentSea = GetCurrentSea,
    GetLevel = GetPlayerLevel,
    Teleport = TeleportTo,
    ToggleFarm = function() isFarming = not isFarming end,
    ToggleESP = function() Config.ESPEnabled = not Config.ESPEnabled; if not Config.ESPEnabled then ClearESP() end end,
    Status = function() return farmStatus end,
    Config = Config,
}

-- ============================================================
-- INITIALIZE
-- ============================================================
CreateGUI()
SetupAntiAFK()
SetupKeybinds()

spawn(function()
    while true do
        task.wait(2)
        if Config.ESPEnabled then
            pcall(UpdateESP)
        end
    end
end)

spawn(AutoStart)

print([[
================================================
  ⚡ Fxry'S CORE BLOX FRUITS SUITE v3.0 ⚡
================================================
  Commands:
  _G.Fxry.Farm()          - Start farming
  _G.Fxry.UnlockSea2()    - Unlock Sea 2
  _G.Fxry.UnlockSea3()    - Unlock Sea 3
  _G.Fxry.Teleport("loc") - Teleport to location
  _G.Fxry.ToggleFarm()    - Toggle farm
  _G.Fxry.ToggleESP()     - Toggle ESP
  
  Keybinds:
  F9  - Toggle Farm
  F10 - Toggle ESP
  F11 - Unlock Sea 2
  F12 - Unlock Sea 3
  RShift - Emergency Stop
  
  GUI is in the top-left corner.
================================================
]])