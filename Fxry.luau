--[[
    Fxry's Delta-Optimized Blox Fruits Suite
    =========================================
    - Specifically tuned for Delta Executor (mobile)
    - Redz-Style Auto Farm
    - Auto Quest | Auto Heal | Auto Collect | Auto Teleport
    - Auto Unlock Sea 2 & Sea 3
    - ESP (Enemy + Fruit)
    - Full Touch GUI
    - Anti-AFK
    - No keybinds (Delta-friendly)
]]

-- Delta compatibility: use pcall for everything
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local RootPart = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid")

-- ============================================================
-- CONFIGURATION
-- ============================================================
local Config = {
    MobAura = true,
    AutoQuest = true,
    AutoHeal = true,
    HealPercent = 30,
    AutoCollect = true,
    TeleportOnNoTarget = true,
    TargetLevel = 2550,
    UseAbilities = true,
    Sea2Level = 700,
    Sea3Level = 1500,
    AutoUnlockSea2 = true,
    AutoUnlockSea3 = true,
    ESPEnabled = true,
    ESPColor = Color3.fromRGB(255, 0, 0),
    AntiAFK = true,
}

-- ============================================================
-- STATE
-- ============================================================
local FarmState = {
    Running = true,
    Status = "Idle",
    Target = nil,
    Kills = 0,
    Level = 0,
    LastAttack = 0,
}

-- ============================================================
-- SAFE UTILITY FUNCTIONS (Delta-friendly)
-- ============================================================
local function GetCurrentSea()
    local success, result = pcall(function()
        local spawnLocation = Player:FindFirstChild("SpawnLocation")
        if spawnLocation then
            local loc = spawnLocation.Value or ""
            if string.find(loc, "Sea 3") or string.find(loc, "Third Sea") then return 3 end
            if string.find(loc, "Sea 2") or string.find(loc, "Second Sea") then return 2 end
            return 1
        end
        if Workspace:FindFirstChild("Sea3Portal") then return 3 end
        if Workspace:FindFirstChild("Sea2Portal") then return 2 end
        if Workspace:FindFirstChild("Castle on the Sea") then return 2 end
        return 1
    end)
    return success and result or 1
end

local function GetPlayerLevel()
    local success, result = pcall(function()
        return Player:FindFirstChild("Level") and Player.Level.Value or 0
    end)
    return success and result or 0
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
        end
        return false
    elseif type(location) == "Vector3" then
        RootPart.CFrame = CFrame.new(location)
        return true
    end
    return false
end

local function UseAbility(key)
    local keyMap = {["Q"]=1,["E"]=2,["R"]=3,["F"]=4,["X"]=5,["C"]=6,["V"]=7,["Z"]=8}
    local k = keyMap[key]
    if k then
        pcall(function() VirtualUser:ClickButton2(k) end)
        return true
    end
    return false
end

local function FireRemote(remoteName, ...)
    local remote = ReplicatedStorage:FindFirstChild("Remotes") and 
                   ReplicatedStorage.Remotes:FindFirstChild(remoteName)
    if remote then
        pcall(function() remote:FireServer(...) end)
        return true
    end
    return false
end

-- ============================================================
-- ESP (Delta-friendly - no Highlights if unsupported)
-- ============================================================
local ESPObjects = {}

local function ClearESP()
    for _, obj in pairs(ESPObjects) do
        pcall(function() obj:Destroy() end)
    end
    ESPObjects = {}
end

local function CreateESP(target, color)
    if not Config.ESPEnabled or not target then return end
    pcall(function()
        local highlight = Instance.new("Highlight")
        highlight.Name = "Fxry_ESP"
        highlight.Adornee = target
        highlight.FillColor = color or Config.ESPColor
        highlight.FillTransparency = 0.4
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.OutlineTransparency = 0.2
        highlight.Parent = target
        table.insert(ESPObjects, highlight)
    end)
end

local function UpdateESP()
    ClearESP()
    if not Config.ESPEnabled then return end
    
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") then
            if v.Name ~= Player.Name and v.Humanoid.Health > 0 then
                local dist = (v.HumanoidRootPart.Position - RootPart.Position).Magnitude
                if dist < 500 then
                    CreateESP(v, Config.ESPColor)
                end
            end
        end
    end
end

-- ============================================================
-- MOB FINDER
-- ============================================================
local function FindMobs()
    local mobs = {}
    local charPos = RootPart.Position
    local searchRadius = 450
    
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj:FindFirstChild("HumanoidRootPart") then
            local hum = obj.Humanoid
            if hum.Health > 0 and obj ~= Character and obj.Name ~= Player.Name then
                local pos = obj.HumanoidRootPart.Position
                local dist = (pos - charPos).Magnitude
                
                if dist < searchRadius then
                    local isEnemy = false
                    if obj:FindFirstChild("Head") and obj.Head:FindFirstChild("Health") then
                        isEnemy = true
                    end
                    if obj:FindFirstChild("IsEnemy") and obj.IsEnemy.Value == true then
                        isEnemy = true
                    end
                    if string.find(obj.Name, "NPC") or string.find(obj.Name, "Mob") or
                       string.find(obj.Name, "Enemy") or string.find(obj.Name, "Pirate") or
                       string.find(obj.Name, "Marine") or string.find(obj.Name, "Bandit") or
                       string.find(obj.Name, "Zombie") or string.find(obj.Name, "Monster") then
                        isEnemy = true
                    end
                    
                    if isEnemy then
                        table.insert(mobs, {
                            Object = obj,
                            RootPart = obj.HumanoidRootPart,
                            Position = pos,
                            Distance = dist,
                            Humanoid = hum,
                            Name = obj.Name,
                            Health = hum.Health,
                            MaxHealth = hum.MaxHealth,
                        })
                    end
                end
            end
        end
    end
    
    table.sort(mobs, function(a, b) return a.Distance < b.Distance end)
    return mobs
end

-- ============================================================
-- COMBAT
-- ============================================================
local function MoveToTarget(target)
    if not target or not target.RootPart then return false end
    
    local targetPos = target.RootPart.Position
    local dist = (targetPos - RootPart.Position).Magnitude
    
    if dist > 25 then
        pcall(function()
            RootPart.CFrame = CFrame.new(RootPart.Position, targetPos)
            VirtualUser:Button2Down("W")
            task.wait(0.05)
            VirtualUser:Button2Up("W")
        end)
        if dist > 60 then
            UseAbility("Q")
            task.wait(0.1)
        end
        return false
    end
    return true
end

local function Combat(target)
    if not target or not target.Humanoid or target.Humanoid.Health <= 0 then return end
    
    local now = tick()
    if now - FarmState.LastAttack < 0.05 then return end
    FarmState.LastAttack = now
    
    pcall(function()
        VirtualUser:ClickButton2(0)
        task.wait(0.02)
        
        if Config.UseAbilities then
            VirtualUser:ClickButton2(1) -- Q
            task.wait(0.02)
            VirtualUser:ClickButton2(2) -- E
            task.wait(0.02)
            VirtualUser:ClickButton2(3) -- R
            task.wait(0.02)
            VirtualUser:ClickButton2(5) -- X
            task.wait(0.02)
            VirtualUser:ClickButton2(6) -- C
            task.wait(0.02)
        end
    end)
end

-- ============================================================
-- AUTO HEAL
-- ============================================================
local function AutoHeal()
    if not Config.AutoHeal then return end
    pcall(function()
        local hp = Humanoid.Health
        local maxHp = Humanoid.MaxHealth
        if (hp / maxHp) * 100 < Config.HealPercent then
            UseAbility("F")
            task.wait(0.5)
        end
    end)
end

-- ============================================================
-- AUTO QUEST
-- ============================================================
local function AutoQuest()
    if not Config.AutoQuest then return end
    
    pcall(function()
        local remote = ReplicatedStorage:FindFirstChild("Remotes") and 
                       ReplicatedStorage.Remotes:FindFirstChild("StartQuest")
        if remote then
            local level = GetPlayerLevel()
            local npc = "Village Elder"
            if level >= 100 then npc = "Marine Captain" end
            if level >= 300 then npc = "Pirate Captain" end
            if level >= 600 then npc = "Sky Knight" end
            if level >= 1000 then npc = "Dragon" end
            if level >= 1500 then npc = "King" end
            if level >= 2000 then npc = "Elder" end
            remote:FireServer(npc)
            task.wait(0.3)
        end
    end)
end

-- ============================================================
-- AUTO TELEPORT
-- ============================================================
local function TeleportToIsland()
    if not Config.TeleportOnNoTarget then return end
    
    local level = GetPlayerLevel()
    local islands = {
        [0] = "Jungle", [100] = "Prison", [300] = "Ice",
        [600] = "Sky", [1000] = "Water 7",
        [1500] = "Castle on the Sea", [2000] = "Mansion"
    }
    
    local targetIsland = "Jungle"
    for lvl, island in pairs(islands) do
        if level >= lvl then targetIsland = island end
    end
    TeleportTo(targetIsland)
end

-- ============================================================
-- AUTO COLLECT
-- ============================================================
local function AutoCollect()
    if not Config.AutoCollect then return end
    
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Part") and (string.find(obj.Name, "Drop") or string.find(obj.Name, "Fruit") or string.find(obj.Name, "Bel")) then
            if (obj.Position - RootPart.Position).Magnitude < 30 then
                pcall(function()
                    firetouchinterest(obj, Character, 0)
                    task.wait(0.02)
                    firetouchinterest(obj, Character, 1)
                end)
            end
        end
    end
end

-- ============================================================
-- MAIN FARM LOOP
-- ============================================================
local function FarmLoop()
    print("[Fxry] Delta farm started!")
    
    while FarmState.Running do
        task.wait(0.05)
        
        pcall(function()
            Character = Player.Character or Player.CharacterAdded:Wait()
            if not Character then return end
            RootPart = Character:FindFirstChild("HumanoidRootPart")
            Humanoid = Character:FindFirstChild("Humanoid")
            if not RootPart or not Humanoid then return end
        end)
        
        if not Character or not RootPart or not Humanoid then
            task.wait(1)
            continue
        end
        
        if Humanoid.Health <= 0 then
            FarmState.Status = "Dead"
            task.wait(3)
            continue
        end
        
        FarmState.Level = GetPlayerLevel()
        if FarmState.Level >= Config.TargetLevel then
            FarmState.Status = "✅ Target Reached!"
            FarmState.Running = false
            break
        end
        
        AutoHeal()
        AutoQuest()
        
        local mobs = FindMobs()
        local target = mobs[1]
        
        if target then
            FarmState.Target = target
            FarmState.Status = "⚔️ " .. target.Name
            if Config.ESPEnabled then CreateESP(target.Object, Config.ESPColor) end
            
            if MoveToTarget(target) then
                Combat(target)
            end
        else
            FarmState.Status = "🔍 Searching..."
            if Config.TeleportOnNoTarget then
                TeleportToIsland()
                task.wait(0.5)
            end
        end
        
        AutoCollect()
        if Config.ESPEnabled and math.random(1, 20) == 1 then UpdateESP() end
    end
    
    FarmState.Status = "⏹ Stopped"
    print("[Fxry] Farm stopped.")
end

-- ============================================================
-- SEA UNLOCK
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
            if string.find(string.lower(v.Name or ""), string.lower(npcName)) then
                local dist = (v.HumanoidRootPart.Position - playerPos).Magnitude
                if dist < radius then return v end
            end
        end
    end
    return nil
end

local function InteractWithNPC(npc, triggers)
    if not npc then return false end
    
    pcall(function()
        local npcPos = npc.HumanoidRootPart.Position
        if (npcPos - RootPart.Position).Magnitude > 15 then
            RootPart.CFrame = CFrame.new(RootPart.Position, npcPos)
            VirtualUser:Button2Down("W")
            task.wait(0.5)
            VirtualUser:Button2Up("W")
        end
        
        VirtualUser:ClickButton2(0)
        task.wait(0.3)
        VirtualUser:ClickButton2(2)
        task.wait(0.3)
    end)
    
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
                            pcall(function() btn:Click() end)
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
        pcall(function()
            RootPart.CFrame = portal.CFrame + Vector3.new(0, 5, 0)
            task.wait(0.5)
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
        if not FarmState.Running then
            FarmState.Running = true
            spawn(FarmLoop)
        end
        task.wait(2)
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
                if tick() - startTime > 8 then TouchPortal(config.PortalName) end
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

local function UnlockSea2() return UnlockSea(2) end
local function UnlockSea3() return UnlockSea(3) end

-- ============================================================
-- GUI (Delta-optimized)
-- ============================================================
local function CreateDeltaGUI()
    local success, screenGui = pcall(function()
        return Instance.new("ScreenGui")
    end)
    if not success then
        print("[Fxry] GUI creation failed. Using console mode.")
        return
    end
    
    screenGui.Name = "FxryDeltaGUI"
    screenGui.Parent = Player.PlayerGui
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 320, 0, 390)
    frame.Position = UDim2.new(0, 10, 0, 10)
    frame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    frame.BackgroundTransparency = 0.1
    frame.BorderSizePixel = 2
    frame.BorderColor3 = Color3.fromRGB(255, 0, 150)
    frame.Parent = screenGui
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 35)
    title.Text = "🔥 Fxry | Delta"
    title.TextColor3 = Color3.fromRGB(255, 50, 200)
    title.TextScaled = true
    title.BackgroundTransparency = 1
    title.P