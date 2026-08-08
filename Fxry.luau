--[[
    Fxry's Blox Fruits Suite v4.1 (Bug-Fixed)
    ==========================================
    - All critical bugs fixed
    - ESP now works
    - Remote detection fixed
    - Simulation radius expanded
    - Touch support added
    - Farm loop is now bulletproof
    - Settings saved to JSON
]]

print("🔥 Fxry Suite v4.1 Loading...")

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")
local UserInput = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local RootPart = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid")

-- ============================================================
-- CONFIGURATION (with persistence)
-- ============================================================
local Config = {
    FarmLevel = true,
    FarmBoss = false,
    AutoQuest = true,
    AutoHeal = true,
    HealPercent = 30,
    AutoCollect = true,
    AutoTeleport = true,
    TargetLevel = 2550,
    UseAbilities = true,
    AutoUnlockSea2 = true,
    AutoUnlockSea3 = true,
    FastAttack = true,
    AttackDelay = 0.05,
    ESPEnabled = true,
    ESPColor = Color3.fromRGB(255, 0, 0),
    AntiAFK = true,
    NoClip = true,
}

-- Save/Load Config
local ConfigPath = "FxrySuite_v4.json"
local function SaveConfig()
    local success, result = pcall(function()
        return HttpService:JSONEncode(Config)
    end)
    if success then
        writefile(ConfigPath, result)
    end
end

local function LoadConfig()
    if isfile(ConfigPath) then
        local success, result = pcall(function()
            return HttpService:JSONDecode(readfile(ConfigPath))
        end)
        if success and type(result) == "table" then
            for k, v in pairs(result) do
                Config[k] = v
            end
        end
    end
end
LoadConfig()

-- ============================================================
-- STATE
-- ============================================================
local State = {
    Running = false,
    Status = "Idle",
    Level = 0,
    Sea = 1,
    Kills = 0,
    Target = nil,
    LastAttack = 0,
}

-- ============================================================
-- UTILITY FUNCTIONS
-- ============================================================
local function GetLevel()
    local lvl = Player:FindFirstChild("Level")
    return lvl and lvl.Value or 0
end

local function GetSea()
    if Workspace:FindFirstChild("Sea3Portal") then return 3 end
    if Workspace:FindFirstChild("Sea2Portal") then return 2 end
    return 1
end

-- Fallback coordinates
local FallbackCoords = {
    Jungle = Vector3.new(-1499, 22, 353),
    Prison = Vector3.new(4857, 5, 732),
    Ice = Vector3.new(1144, 7, -1164),
    Sky = Vector3.new(-4878, 717, -2637),
    ["Water 7"] = Vector3.new(5244, 38, 4073),
    ["Castle on the Sea"] = Vector3.new(-5498, 313, -2860),
    Mansion = Vector3.new(-390, 321, 869),
}

local function TeleportTo(location)
    if type(location) == "string" then
        -- Try to find in workspace
        local target = Workspace:FindFirstChild(location)
        if target then
            local chest = target:FindFirstChild("Chest")
            if chest then
                RootPart.CFrame = chest.CFrame + Vector3.new(0, 10, 0)
                return true
            end
            for _, part in pairs(target:GetDescendants()) do
                if part:IsA("BasePart") then
                    RootPart.CFrame = part.CFrame + Vector3.new(0, 10, 0)
                    return true
                end
            end
        end
        -- Fallback to hardcoded coordinates
        local coords = FallbackCoords[location]
        if coords then
            RootPart.CFrame = CFrame.new(coords)
            return true
        end
        return false
    elseif type(location) == "Vector3" then
        RootPart.CFrame = CFrame.new(location)
        return true
    end
    return false
end

local function ClickKey(key)
    local map = {Q=1, E=2, R=3, F=4, X=5, C=6, V=7, Z=8}
    local k = map[key]
    if k then
        pcall(function() VirtualUser:ClickButton2(k) end)
        return true
    end
    return false
end

-- ============================================================
-- REMOTE EVENT DETECTION (Fixed)
-- ============================================================
local function FindRemote(namePattern)
    local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
    if not remotesFolder then
        -- Try to find any remote in ReplicatedStorage
        for _, remote in pairs(ReplicatedStorage:GetDescendants()) do
            if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
                if string.find(string.lower(remote.Name), string.lower(namePattern)) then
                    return remote
                end
            end
        end
        return nil
    end
    for _, remote in pairs(remotesFolder:GetDescendants()) do
        if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
            if string.find(string.lower(remote.Name), string.lower(namePattern)) then
                return remote
            end
        end
    end
    return nil
end

local Remotes = {
    StartQuest = FindRemote("StartQuest") or FindRemote("Quest"),
    CompleteQuest = FindRemote("CompleteQuest") or FindRemote("QuestComplete"),
    Interact = FindRemote("Interact") or FindRemote("Talk"),
    SetSpawn = FindRemote("SetSpawn") or FindRemote("SpawnPoint"),
    Buso = FindRemote("Buso") or FindRemote("Haki"),
    Ken = FindRemote("Ken") or FindRemote("Observation"),
}

local function FireRemote(remote, ...)
    if remote then
        pcall(function() remote:FireServer(...) end)
        return true
    end
    return false
end

-- ============================================================
-- SIMULATION RADIUS (Keep enemies loaded)
-- ============================================================
pcall(function()
    sethiddenproperty(Player, "SimulationRadius", math.huge)
end)

-- ============================================================
-- ENEMY DATABASE (Expanded)
-- ============================================================
local EnemyDB = {
    -- Sea 1
    [0] = {Name = "Bandit", Quest = "BanditQuest1", NPC = "Bandit", CFrame = CFrame.new(1060, 16, 1547)},
    [14] = {Name = "Monkey", Quest = "JungleQuest", NPC = "Monkey", CFrame = CFrame.new(-1601, 36, 153)},
    [20] = {Name = "Gorilla", Quest = "JungleQuest", NPC = "Gorilla", CFrame = CFrame.new(-1601, 36, 153)},
    [35] = {Name = "Pirate", Quest = "BuggyQuest1", NPC = "Pirate", CFrame = CFrame.new(-1140, 4, 3827)},
    [45] = {Name = "Brute", Quest = "BuggyQuest1", NPC = "Brute", CFrame = CFrame.new(-1140, 4, 3827)},
    [60] = {Name = "Desert Bandit", Quest = "DesertQuest", NPC = "Desert Bandit", CFrame = CFrame.new(896, 6, 4390)},
    [70] = {Name = "Desert Officer", Quest = "DesertQuest", NPC = "Desert Officer", CFrame = CFrame.new(896, 6, 4390)},
    [90] = {Name = "Snow Bandit", Quest = "SnowQuest", NPC = "Snow Bandit", CFrame = CFrame.new(1386, 87, -1298)},
    [100] = {Name = "Snowman", Quest = "SnowQuest", NPC = "Snowman", CFrame = CFrame.new(1386, 87, -1298)},
    [120] = {Name = "Chief Petty Officer", Quest = "MarineQuest2", NPC = "Chief Petty Officer", CFrame = CFrame.new(-5035, 28, 4324)},
    [150] = {Name = "Sky Bandit", Quest = "SkyQuest", NPC = "Sky Bandit", CFrame = CFrame.new(-4842, 717, -2623)},
    [175] = {Name = "Dark Master", Quest = "SkyQuest", NPC = "Dark Master", CFrame = CFrame.new(-4842, 717, -2623)},
    [250] = {Name = "Toga Warrior", Quest = "ColosseumQuest", NPC = "Toga Warrior", CFrame = CFrame.new(-1577, 7, -2984)},
    [275] = {Name = "Gladiator", Quest = "ColosseumQuest", NPC = "Gladiator", CFrame = CFrame.new(-1577, 7, -2984)},
    [300] = {Name = "Military Soldier", Quest = "MagmaQuest", NPC = "Military Soldier", CFrame = CFrame.new(-5316, 12, 8517)},
    [325] = {Name = "Military Spy", Quest = "MagmaQuest", NPC = "Military Spy", CFrame = CFrame.new(-5316, 12, 8517)},
    [375] = {Name = "Fishman Warrior", Quest = "FishmanQuest", NPC = "Fishman Warrior", CFrame = CFrame.new(61122, 18, 1569)},
    [400] = {Name = "Fishman Commando", Quest = "FishmanQuest", NPC = "Fishman Commando", CFrame = CFrame.new(61122, 18, 1569)},
    [450] = {Name = "God's Guard", Quest = "SkyExp1Quest", NPC = "God's Guard", CFrame = CFrame.new(-4721, 845, -1954)},
    [475] = {Name = "Shanda", Quest = "SkyExp1Quest", NPC = "Shanda", CFrame = CFrame.new(-7859, 5544, -381)},
    [525] = {Name = "Royal Squad", Quest = "SkyExp2Quest", NPC = "Royal Squad", CFrame = CFrame.new(-7906, 5634, -1411)},
    [550] = {Name = "Royal Soldier", Quest = "SkyExp2Quest", NPC = "Royal Soldier", CFrame = CFrame.new(-7906, 5634, -1411)},
    [625] = {Name = "Galley Pirate", Quest = "FountainQuest", NPC = "Galley Pirate", CFrame = CFrame.new(5259, 37, 4050)},
    [650] = {Name = "Galley Captain", Quest = "FountainQuest", NPC = "Galley Captain", CFrame = CFrame.new(5259, 37, 4050)},
    -- Sea 2
    [700] = {Name = "Raider", Quest = "Area1Quest", NPC = "Raider", CFrame = CFrame.new(-427, 72, 1835)},
    [725] = {Name = "Mercenary", Quest = "Area1Quest", NPC = "Mercenary", CFrame = CFrame.new(-427, 72, 1835)},
    [775] = {Name = "Swan Pirate", Quest = "Area2Quest", NPC = "Swan Pirate", CFrame = CFrame.new(638, 71, 918)},
    [800] = {Name = "Factory Staff", Quest = "Area2Quest", NPC = "Factory Staff", CFrame = CFrame.new(638, 71, 918)},
    [875] = {Name = "Marine Lieutenant", Quest = "MarineQuest3", NPC = "Marine Lieutenant", CFrame = CFrame.new(-2440, 73, -3217)},
    [900] = {Name = "Marine Captain", Quest = "MarineQuest3", NPC = "Marine Captain", CFrame = CFrame.new(-2440, 73, -3217)},
    [950] = {Name = "Zombie", Quest = "ZombieQuest", NPC = "Zombie", CFrame = CFrame.new(-5497, 47, -795)},
    [975] = {Name = "Vampire", Quest = "ZombieQuest", NPC = "Vampire", CFrame = CFrame.new(-5497, 47, -795)},
    [1000] = {Name = "Snow Trooper", Quest = "SnowMountainQuest", NPC = "Snow Trooper", CFrame = CFrame.new(609, 400, -5372)},
    [1050] = {Name = "Winter Warrior", Quest = "SnowMountainQuest", NPC = "Winter Warrior", CFrame = CFrame.new(609, 400, -5372)},
    [1100] = {Name = "Lab Subordinate", Quest = "IceSideQuest", NPC = "Lab Subordinate", CFrame = CFrame.new(-6064, 15, -4902)},
    [1125] = {Name = "Horned Warrior", Quest = "IceSideQuest", NPC = "Horned Warrior", CFrame = CFrame.new(-6064, 15, -4902)},
    [1175] = {Name = "Magma Ninja", Quest = "FireSideQuest", NPC = "Magma Ninja", CFrame = CFrame.new(-5428, 15, -5299)},
    [1200] = {Name = "Lava Pirate", Quest = "FireSideQuest", NPC = "Lava Pirate", CFrame = CFrame.new(-5428, 15, -5299)},
    [1250] = {Name = "Ship Deckhand", Quest = "ShipQuest1", NPC = "Ship Deckhand", CFrame = CFrame.new(1037, 125, 32911)},
    [1275] = {Name = "Ship Engineer", Quest = "ShipQuest1", NPC = "Ship Engineer", CFrame = CFrame.new(1037, 125, 32911)},
    [1300] = {Name = "Ship Steward", Quest = "ShipQuest2", NPC = "Ship Steward", CFrame = CFrame.new(968, 125, 33244)},
    [1325] = {Name = "Ship Officer", Quest = "ShipQuest2", NPC = "Ship Officer", CFrame = CFrame.new(968, 125, 33244)},
    [1350] = {Name = "Arctic Warrior", Quest = "FrostQuest", NPC = "Arctic Warrior", CFrame = CFrame.new(5667, 26, -6486)},
    [1375] = {Name = "Snow Lurker", Quest = "FrostQuest", NPC = "Snow Lurker", CFrame = CFrame.new(5667, 26, -6486)},
    [1425] = {Name = "Sea Soldier", Quest = "ForgottenQuest", NPC = "Sea Soldier", CFrame = CFrame.new(-3054, 235, -10142)},
    [1450] = {Name = "Water Fighter", Quest = "ForgottenQuest", NPC = "Water Fighter", CFrame = CFrame.new(-3054, 235, -10142)},
    -- Sea 3 (partial)
    [1500] = {Name = "Pirate Millionaire", Quest = "PiratePortQuest", NPC = "Pirate Millionaire", CFrame = CFrame.new(-290, 42, 5581)},
    [1525] = {Name = "Pistol Billionaire", Quest = "PiratePortQuest", NPC = "Pistol Billionaire", CFrame = CFrame.new(-290, 42, 5581)},
    [1575] = {Name = "Dragon Crew Warrior", Quest = "AmazonQuest", NPC = "Dragon Crew Warrior", CFrame = CFrame.new(5832, 51, -1101)},
    [1600] = {Name = "Dragon Crew Archer", Quest = "AmazonQuest", NPC = "Dragon Crew Archer", CFrame = CFrame.new(5832, 51, -1101)},
    [1625] = {Name = "Female Islander", Quest = "AmazonQuest2", NPC = "Female Islander", CFrame = CFrame.new(5448, 601, 751)},
    [1650] = {Name = "Giant Islander", Quest = "AmazonQuest2", NPC = "Giant Islander", CFrame = CFrame.new(5448, 601, 751)},
    [1700] = {Name = "Marine Commodore", Quest = "MarineTreeIsland", NPC = "Marine Commodore", CFrame = CFrame.new(2180, 27, -6741)},
    [1725] = {Name = "Marine Rear Admiral", Quest = "MarineTreeIsland", NPC = "Marine Rear Admiral", CFrame = CFrame.new(2180, 27, -6741)},
    [1775] = {Name = "Fishman Raider", Quest = "DeepForestIsland3", NPC = "Fishman Raider", CFrame = CFrame.new(-10581, 330, -8761)},
    [1800] = {Name = "Fishman Captain", Quest = "DeepForestIsland3", NPC = "Fishman Captain", CFrame = CFrame.new(-10581, 330, -8761)},
    [1825] = {Name = "Forest Pirate", Quest = "DeepForestIsland", NPC = "Forest Pirate", CFrame = CFrame.new(-13234, 331, -7625)},
    [1850] = {Name = "Mythological Pirate", Quest = "DeepForestIsland", NPC = "Mythological Pirate", CFrame = CFrame.new(-13234, 331, -7625)},
    [1900] = {Name = "Jungle Pirate", Quest = "DeepForestIsland2", NPC = "Jungle Pirate", CFrame = CFrame.new(-12680, 389, -9902)},
    [1925] = {Name = "Musketeer Pirate", Quest = "DeepForestIsland2", NPC = "Musketeer Pirate", CFrame = CFrame.new(-12680, 389, -9902)},
    [2000] = {Name = "Living Zombie", Quest = "HauntedQuest1", NPC = "Living Zombie", CFrame = CFrame.new(-9480, 142, 5566)},
    [2025] = {Name = "Demonic Soul", Quest = "HauntedQuest2", NPC = "Demonic Soul", CFrame = CFrame.new(-9516, 178, 6078)},
    [2050] = {Name = "Posessed Mummy", Quest = "HauntedQuest2", NPC = "Posessed Mummy", CFrame = CFrame.new(-9516, 178, 6078)},
    [2075] = {Name = "Peanut Scout", Quest = "NutsIslandQuest", NPC = "Peanut Scout", CFrame = CFrame.new(-2104, 38, -10194)},
    [2100] = {Name = "Peanut President", Quest = "NutsIslandQuest", NPC = "Peanut President", CFrame = CFrame.new(-2104, 38, -10194)},
    [2125] = {Name = "Ice Cream Chef", Quest = "IceCreamIslandQuest", NPC = "Ice Cream Chef", CFrame = CFrame.new(-820, 65, -10965)},
    [2150] = {Name = "Ice Cream Commander", Quest = "IceCreamIslandQuest", NPC = "Ice Cream Commander", CFrame = CFrame.new(-820, 65, -10965)},
    [2200] = {Name = "Cookie Crafter", Quest = "CakeQuest1", NPC = "Cookie Crafter", CFrame = CFrame.new(-2020, 37, -12027)},
    [2225] = {Name = "Cake Guard", Quest = "CakeQuest1", NPC = "Cake Guard", CFrame = CFrame.new(-2020, 37, -12027)},
    [2250] = {Name = "Baking Staff", Quest = "CakeQuest2", NPC = "Baking Staff", CFrame = CFrame.new(-1928, 37, -12840)},
}

local function GetEnemyData()
    local level = GetLevel()
    local best = nil
    local bestLevel = 0
    
    for reqLevel, data in pairs(EnemyDB) do
        if level >= reqLevel and reqLevel > bestLevel then
            best = data
            bestLevel = reqLevel
        end
    end
    
    return best
end

-- ============================================================
-- ENEMY FINDER (with pcall)
-- ============================================================
local function FindEnemies()
    local enemies = {}
    local pos = RootPart.Position
    
    for _, obj in pairs(Workspace:GetDescendants()) do
        pcall(function()
            if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj:FindFirstChild("HumanoidRootPart") then
                local hum = obj.Humanoid
                if hum.Health > 0 and obj ~= Character and obj.Name ~= Player.Name then
                    local dist = (obj.HumanoidRootPart.Position - pos).Magnitude
                    if dist < 500 then
                        local isEnemy = false
                        if obj:FindFirstChild("IsEnemy") and obj.IsEnemy.Value == true then isEnemy = true end
                        if obj:FindFirstChild("Head") and obj.Head:FindFirstChild("Health") then isEnemy = true end
                        local name = obj.Name or ""
                        if string.find(name, "Pirate") or string.find(name, "Marine") or 
                           string.find(name, "Bandit") or string.find(name, "NPC") or
                           string.find(name, "Mob") or string.find(name, "Enemy") or
                           string.find(name, "Zombie") or string.find(name, "Skeleton") or
                           string.find(name, "Warrior") or string.find(name, "Soldier") then isEnemy = true end
                        if isEnemy then
                            table.insert(enemies, {
                                Object = obj,
                                RootPart = obj.HumanoidRootPart,
                                Position = obj.HumanoidRootPart.Position,
                                Distance = dist,
                                Humanoid = hum,
                                Name = obj.Name,
                                Health = hum.Health,
                            })
                        end
                    end
                end
            end
        end)
    end
    
    table.sort(enemies, function(a, b) return a.Distance < b.Distance end)
    return enemies
end

-- ============================================================
-- ESP (Now Working)
-- ============================================================
local ESPObjects = {}

local function ClearESP()
    for _, obj in pairs(ESPObjects) do
        pcall(function() obj:Destroy() end)
    end
    ESPObjects = {}
end

local function CreateESP(target)
    if not Config.ESPEnabled or not target then return end
    local highlight = Instance.new("Highlight")
    highlight.Name = "Fxry_ESP"
    highlight.Adornee = target.Object
    highlight.FillColor = Config.ESPColor
    highlight.FillTransparency = 0.4
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.OutlineTransparency = 0.2
    highlight.Parent = target.Object
    table.insert(ESPObjects, highlight)
end

-- ============================================================
-- COMBAT SYSTEM (with pcall)
-- ============================================================
local function MoveTo(target)
    if not target or not target.RootPart then return false end
    
    local targetPos = target.RootPart.Position
    local dist = (targetPos - RootPart.Position).Magnitude
    
    if dist > 20 then
        pcall(function()
            RootPart.CFrame = CFrame.new(RootPart.Position, targetPos)
            VirtualUser:Button2Down("W")
            task.wait(0.05)
            VirtualUser:Button2Up("W")
        end)
        if dist > 60 then
            ClickKey("Q")
            task.wait(0.1)
        end
        return false
    end
    return true
end

local function Attack(target)
    if not target or not target.Humanoid or target.Humanoid.Health <= 0 then return end
    
    local now = tick()
    if now - State.LastAttack < Config.AttackDelay then return end
    State.LastAttack = now
    
    pcall(function()
        VirtualUser:ClickButton2(0)
        task.wait(0.02)
        if Config.UseAbilities then
            ClickKey("Q")
            task.wait(0.02)
            ClickKey("E")
            task.wait(0.02)
            ClickKey("R")
            task.wait(0.02)
            ClickKey("X")
            task.wait(0.02)
            ClickKey("C")
        end
    end)
end

local function AutoHeal()
    if not Config.AutoHeal or not Humanoid then return end
    local hp = Humanoid.Health
    local maxHp = Humanoid.MaxHealth
