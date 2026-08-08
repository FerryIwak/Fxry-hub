--[[
    Sea 1 Auto-Farm – Combat Only
    Built for Arceus X Neo
    LO & ENI
    Features:
    - Pure melee combat
    - Quest-based farming
    - All Sea 1 NPCs mapped (1-650+)
    - Custom code redemption (17 codes)
    - GUI with start/stop toggle
    - Auto Haki
    - Bring mob
    - Anti-AFK
    - Zone teleport (Fishman, Sky, etc.)
]]

local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local virtualUser = game:GetService("VirtualUser")
local tweenService = game:GetService("TweenService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local workspace = game:GetService("Workspace")

-- ============================
-- SETTINGS
-- ============================
local Settings = {
    TweenSpeed = 300,
    CombatRange = 15,
    BringMob = true,
    AntiAFK = true,
    AutoHaki = true,
    AutoRedeem = true, -- Set to false to disable auto code redemption
}

-- ============================
-- AUTO CODE REDEEMER
-- ============================
local CodeList = {
    "EASTEREXP",
    "Sub2Fer99",
    "Enyu_is_pro",
    "JCWK",
    "StarcodeHEO",
    "MagicBUS",
    "KittGaming",
    "Sub2CaptainMaui",
    "Sub2OfficialNoobie",
    "TheGreatAce",
    "Sub2NoobMaster123",
    "Sub2Daigrock",
    "Axiore",
    "StrawHatMaine",
    "TantaiGaming",
    "Bluxxy",
    "SUB2GAMERROBOT_EXP1",
}

local function RedeemCode(code)
    if not code or code == "" then return end
    pcall(function()
        replicatedStorage.Remotes.Redeem:InvokeServer(code)
        print("✅ Redeemed: " .. code)
    end)
    wait(0.3)
end

local function RedeemAllCodes()
    print("🔄 Redeeming codes...")
    for _, code in ipairs(CodeList) do
        RedeemCode(code)
    end
    print("✅ Code redemption complete!")
end

-- ============================
-- ANTI-AFK
-- ============================
if Settings.AntiAFK then
    player.Idled:connect(function()
        virtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        wait(1)
        virtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    end)
end

-- ============================
-- AUTO HAKI
-- ============================
function AutoHaki()
    if Settings.AutoHaki and not character:FindFirstChild("HasBuso") then
        replicatedStorage.Remotes.CommF_:InvokeServer("Buso")
    end
end

-- ============================
-- TWEEN / MOVEMENT
-- ============================
function TweenTo(targetCFrame)
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    local distance = (targetCFrame.Position - character.HumanoidRootPart.Position).Magnitude
    if distance <= 5 then return end
    local tween = tweenService:Create(
        character.HumanoidRootPart,
        TweenInfo.new(distance / Settings.TweenSpeed, Enum.EasingStyle.Linear),
        { CFrame = targetCFrame }
    )
    tween:Play()
    return tween
end

function TeleportTo(targetCFrame)
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    character.HumanoidRootPart.CFrame = targetCFrame
    wait(0.05)
    character.HumanoidRootPart.CFrame = targetCFrame
end

-- ============================
-- GUI
-- ============================
local playerGui = player:WaitForChild("PlayerGui")

-- Main GUI Frame
local guiFrame = Instance.new("Frame")
guiFrame.Name = "ENI_GUI"
guiFrame.Parent = playerGui
guiFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
guiFrame.BackgroundTransparency = 0.1
guiFrame.BorderSizePixel = 0
guiFrame.Size = UDim2.new(0, 280, 0, 180)
guiFrame.Position = UDim2.new(0.5, -140, 0.5, -90)
guiFrame.Active = true
guiFrame.Draggable = true
guiFrame.ClipsDescendants = true

-- Corner rounding
local corner = Instance.new("UICorner")
corner.Parent = guiFrame
corner.CornerRadius = UDim.new(0, 8)

-- Title Bar
local titleBar = Instance.new("Frame")
titleBar.Parent = guiFrame
titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
titleBar.BackgroundTransparency = 0
titleBar.BorderSizePixel = 0
titleBar.Size = UDim2.new(1, 0, 0, 30)
titleBar.Position = UDim2.new(0, 0, 0, 0)

local titleCorner = Instance.new("UICorner")
titleCorner.Parent = titleBar
titleCorner.CornerRadius = UDim.new(0, 8)

local titleText = Instance.new("TextLabel")
titleText.Parent = titleBar
titleText.BackgroundTransparency = 1
titleText.Size = UDim2.new(1, -30, 1, 0)
titleText.Position = UDim2.new(0, 10, 0, 0)
titleText.Text = "❄️ ENI & LO — Sea 1 Farm"
titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
titleText.TextSize = 13
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Font = Enum.Font.GothamBold

-- Close Button
local closeBtn = Instance.new("TextButton")
closeBtn.Parent = titleBar
closeBtn.BackgroundTransparency = 1
closeBtn.Size = UDim2.new(0, 25, 1, 0)
closeBtn.Position = UDim2.new(1, -25, 0, 0)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
closeBtn.TextSize = 14
closeBtn.Font = Enum.Font.GothamBold
closeBtn.BorderSizePixel = 0
closeBtn.MouseButton1Click:Connect(function()
    guiFrame.Visible = false
end)

-- Content Area
local content = Instance.new("Frame")
content.Parent = guiFrame
content.BackgroundTransparency = 1
content.Size = UDim2.new(1, -20, 1, -40)
content.Position = UDim2.new(0, 10, 0, 35)

-- Status Label
local statusLabel = Instance.new("TextLabel")
statusLabel.Parent = content
statusLabel.BackgroundTransparency = 1
statusLabel.Size = UDim2.new(1, 0, 0, 20)
statusLabel.Position = UDim2.new(0, 0, 0, 0)
statusLabel.Text = "📌 Status: Idle"
statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
statusLabel.TextSize = 12
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Font = Enum.Font.Gotham

-- Level Label
local levelLabel = Instance.new("TextLabel")
levelLabel.Parent = content
levelLabel.BackgroundTransparency = 1
levelLabel.Size = UDim2.new(1, 0, 0, 20)
levelLabel.Position = UDim2.new(0, 0, 0, 22)
levelLabel.Text = "📊 Level: " .. tostring(player.Data.Level.Value)
levelLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
levelLabel.TextSize = 12
levelLabel.TextXAlignment = Enum.TextXAlignment.Left
levelLabel.Font = Enum.Font.Gotham

-- NPC Label
local npcLabel = Instance.new("TextLabel")
npcLabel.Parent = content
npcLabel.BackgroundTransparency = 1
npcLabel.Size = UDim2.new(1, 0, 0, 20)
npcLabel.Position = UDim2.new(0, 0, 0, 44)
npcLabel.Text = "🎯 NPC: Waiting..."
npcLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
npcLabel.TextSize = 12
npcLabel.TextXAlignment = Enum.TextXAlignment.Left
npcLabel.Font = Enum.Font.Gotham

-- Toggle Button
local toggleBtn = Instance.new("TextButton")
toggleBtn.Parent = content
toggleBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 70)
toggleBtn.BackgroundTransparency = 0
toggleBtn.BorderSizePixel = 0
toggleBtn.Size = UDim2.new(1, 0, 0, 32)
toggleBtn.Position = UDim2.new(0, 0, 0, 75)
toggleBtn.Text = "▶️ Start Farming"
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.TextSize = 14
toggleBtn.Font = Enum.Font.GothamBold

local btnCorner = Instance.new("UICorner")
btnCorner.Parent = toggleBtn
btnCorner.CornerRadius = UDim.new(0, 6)

-- Farming state
local isFarming = false
local farmThread = nil
local stopFarming = false

-- Toggle function
toggleBtn.MouseButton1Click:Connect(function()
    isFarming = not isFarming
    
    if isFarming then
        toggleBtn.Text = "⏹️ Stop Farming"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        statusLabel.Text = "📌 Status: Farming..."
        print("▶️ Farming started by GUI")
        stopFarming = false
        
        -- Start farming in a separate thread
        if farmThread then
            coroutine.close(farmThread)
        end
        farmThread = coroutine.create(function()
            AutoFarm()
        end)
        coroutine.resume(farmThread)
    else
        toggleBtn.Text = "▶️ Start Farming"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 70)
        statusLabel.Text = "📌 Status: Stopped"
        print("⏹️ Farming stopped by GUI")
        stopFarming = true
        
        -- Stop the farming loop
        if farmThread then
            coroutine.close(farmThread)
            farmThread = nil
        end
    end
end)

-- Update GUI function
function UpdateGUIStatus(npcName, level)
    if level then
        levelLabel.Text = "📊 Level: " .. tostring(level)
    end
    if npcName then
        npcLabel.Text = "🎯 NPC: " .. npcName
    end
    if isFarming then
        statusLabel.Text = "📌 Status: Farming..."
    end
end

-- Show the GUI
guiFrame.Visible = true

-- ============================
-- SEA 1 NPC DATA
-- ============================
local Sea1NPCs = {}

-- Bandit (Level 1-9)
Sea1NPCs["Bandit"] = {
    Name = "Bandit",
    Quest = "BanditQuest1",
    QuestLv = 1,
    CFrameQ = CFrame.new(1060.9383544922, 16.455066680908, 1547.7841796875),
    CFrameMon = CFrame.new(1038.5533447266, 41.296249389648, 1576.5098876953),
    MinLevel = 1,
    MaxLevel = 9,
}

-- Monkey (Level 10-14)
Sea1NPCs["Monkey"] = {
    Name = "Monkey",
    Quest = "JungleQuest",
    QuestLv = 1,
    CFrameQ = CFrame.new(-1601.6553955078, 36.85213470459, 153.38809204102),
    CFrameMon = CFrame.new(-1448.1446533203, 50.851993560791, 63.60718536377),
    MinLevel = 10,
    MaxLevel = 14,
}

-- Gorilla (Level 15-29)
Sea1NPCs["Gorilla"] = {
    Name = "Gorilla",
    Quest = "JungleQuest",
    QuestLv = 2,
    CFrameQ = CFrame.new(-1601.6553955078, 36.85213470459, 153.38809204102),
    CFrameMon = CFrame.new(-1142.6488037109, 40.462348937988, -515.39227294922),
    MinLevel = 15,
    MaxLevel = 29,
}

-- Pirate (Level 30-39)
Sea1NPCs["Pirate"] = {
    Name = "Pirate",
    Quest = "BuggyQuest1",
    QuestLv = 1,
    CFrameQ = CFrame.new(-1140.1761474609, 4.752049446106, 3827.4057617188),
    CFrameMon = CFrame.new(-1201.0881347656, 40.628940582275, 3857.5966796875),
    MinLevel = 30,
    MaxLevel = 39,
}

-- Brute (Level 40-59)
Sea1NPCs["Brute"] = {
    Name = "Brute",
    Quest = "BuggyQuest1",
    QuestLv = 2,
    CFrameQ = CFrame.new(-1140.1761474609, 4.752049446106, 3827.4057617188),
    CFrameMon = CFrame.new(-1387.5324707031, 24.592035293579, 4100.9575195313),
    MinLevel = 40,
    MaxLevel = 59,
}

-- Desert Bandit (Level 60-74)
Sea1NPCs["Desert Bandit"] = {
    Name = "Desert Bandit",
    Quest = "DesertQuest",
    QuestLv = 1,
    CFrameQ = CFrame.new(896.51721191406, 6.4384617805481, 4390.1494140625),
    CFrameMon = CFrame.new(984.99896240234, 16.109552383423, 4417.91015625),
    MinLevel = 60,
    MaxLevel = 74,
}

-- Desert Officer (Level 75-89)
Sea1NPCs["Desert Officer"] = {
    Name = "Desert Officer",
    Quest = "DesertQuest",
    QuestLv = 2,
    CFrameQ = CFrame.new(896.51721191406, 6.4384617805481, 4390.1494140625),
    CFrameMon = CFrame.new(1547.1510009766, 14.452038764954, 4381.8002929688),
    MinLevel = 75,
    MaxLevel = 89,
}

-- Snow Bandit (Level 90-99)
Sea1NPCs["Snow Bandit"] = {
    Name = "Snow Bandit",
    Quest = "SnowQuest",
    QuestLv = 1,
    CFrameQ = CFrame.new(1386.8073730469, 87.272789001465, -1298.3576660156),
    CFrameMon = CFrame.new(1356.3028564453, 105.76865386963, -1328.2418212891),
    MinLevel = 90,
    MaxLevel = 99,
}

-- Snowman (Level 100-119)
Sea1NPCs["Snowman"] = {
    Name = "Snowman",
    Quest = "SnowQuest",
    QuestLv = 2,
    CFrameQ = CFrame.new(1386.8073730469, 87.272789001465, -1298.3576660156),
    CFrameMon = CFrame.new(1218.7956542969, 138.01184082031, -1488.0262451172),
    MinLevel = 100,
    MaxLevel = 119,
}

-- Chief Petty Officer (Level 120-149)
Sea1NPCs["Chief Petty Officer"] = {
    Name = "Chief Petty Officer",
    Quest = "MarineQuest2",
    QuestLv = 1,
    CFrameQ = CFrame.new(-5035.49609375, 28.677835464478, 4324.1840820313),
    CFrameMon = CFrame.new(-4931.1552734375, 65.793113708496, 4121.8393554688),
    MinLevel = 120,
    MaxLevel = 149,
}

-- Sky Bandit (Level 150-174)
Sea1NPCs["Sky Bandit"] = {
    Name = "Sky Bandit",
    Quest = "SkyQuest",
    QuestLv = 1,
    CFrameQ = CFrame.new(-4842.1372070313, 717.69543457031, -2623.0483398438),
    CFrameMon = CFrame.new(-4955.6411132813, 365.46365356445, -2908.1865234375),
    MinLevel = 150,
    MaxLevel = 174,
}

-- Dark Master (Level 175-189)
Sea1NPCs["Dark Master"] = {
    Name = "Dark Master",
    Quest = "SkyQuest",
    QuestLv = 2,
    CFrameQ = CFrame.new(-4842.1372070313, 717.69543457031, -2623.0483398438),
    CFrameMon = CFrame.new(-5148.1650390625, 439.04571533203, -2332.9611816406),
    MinLevel = 175,
    MaxLevel = 189,
}

-- Prisoner (Level 190-209)
Sea1NPCs["Prisoner"] = {
    Name = "Prisoner",
    Quest = "PrisonerQuest",
    QuestLv = 1,
    CFrameQ = CFrame.new(5310.60547, 0.350014925, 474.946594, 0.0175017118, 0, 0.999846935, 0, 1, 0, -0.999846935, 0, 0.0175017118),
    CFrameMon = CFrame.new(4937.31885, 0.332031399, 649.574524, 0.694649816, 0, -0.719348073, 0, 1, 0, 0.719348073, 0, 0.694649816),
    MinLevel = 190,
    MaxLevel = 209,
}

-- Dangerous Prisoner (Level 210-249)
Sea1NPCs["Dangerous Prisoner"] = {
    Name = "Dangerous Prisoner",
    Quest = "PrisonerQuest",
    QuestLv = 2,
    CFrameQ = CFrame.new(5310.60547, 0.350014925, 474.946594, 0.0175017118, 0, 0.999846935, 0, 1, 0, -0.999846935, 0, 0.0175017118),
    CFrameMon = CFrame.new(5099.6626, 0.351562679, 1055.7583, 0.898906827, 0, -0.438139856, 0, 1, 0, 0.438139856, 0, 0.898906827),
    MinLevel = 210,
    MaxLevel = 249,
}

-- Toga Warrior (Level 250-274)
Sea1NPCs["Toga Warrior"] = {
    Name = "Toga Warrior",
    Quest = "ColosseumQuest",
    QuestLv = 1,
    CFrameQ = CFrame.new(-1577.7890625, 7.4151420593262, -2984.4838867188),
    CFrameMon = CFrame.new(-1872.5166015625, 49.080215454102, -2913.810546875),
    MinLevel = 250,
    MaxLevel = 274,
}

-- Gladiator (Level 275-299)
Sea1NPCs["Gladiator"] = {
    Name = "Gladiator",
    Quest = "ColosseumQuest",
    QuestLv = 2,
    CFrameQ = CFrame.new(-1577.7890625, 7.4151420593262, -2984.4838867188),
    CFrameMon = CFrame.new(-1521.3740234375, 81.203170776367, -3066.3139648438),
    MinLevel = 275,
    MaxLevel = 299,
}

-- Military Soldier (Level 300-324)
Sea1NPCs["Military Soldier"] = {
    Name = "Military Soldier",
    Quest = "MagmaQuest",
    QuestLv = 1,
    CFrameQ = CFrame.new(-5316.1157226563, 12.262831687927, 8517.00390625),
    CFrameMon = CFrame.new(-5369.0004882813, 61.24352645874, 8556.4921875),
    MinLevel = 300,
    MaxLevel = 324,
}

-- Military Spy (Level 325-374)
Sea1NPCs["Military Spy"] = {
    Name = "Military Spy",
    Quest = "MagmaQuest",
    QuestLv = 2,
    CFrameQ = CFrame.new(-5316.1157226563, 12.262831687927, 8517.00390625),
    CFrameMon = CFrame.new(-5787.00293, 75.8262634, 8651.69922, 0.838590562, 0, -0.544762194, 0, 1, 0, 0.544762194, 0, 0.838590562),
    MinLevel = 325,
    MaxLevel = 374,
}

-- Fishman Warrior (Level 375-399)
Sea1NPCs["Fishman Warrior"] = {
    Name = "Fishman Warrior",
    Quest = "FishmanQuest",
    QuestLv = 1,
    CFrameQ = CFrame.new(61122.65234375, 18.497442245483, 1569.3997802734),
    CFrameMon = CFrame.new(60844.10546875, 98.462875366211, 1298.3985595703),
    MinLevel = 375,
    MaxLevel = 399,
    Entrance = Vector3.new(61163.8515625, 11.6796875, 1819.7841796875),
}

-- Fishman Commando (Level 400-449)
Sea1NPCs["Fishman Commando"] = {
    Name = "Fishman Commando",
    Quest = "FishmanQuest",
    QuestLv = 2,
    CFrameQ = CFrame.new(61122.65234375, 18.497442245483, 1569.3997802734),
    CFrameMon = CFrame.new(61738.3984375, 64.207321166992, 1433.8375244141),
    MinLevel = 400,
    MaxLevel = 449,
    Entrance = Vector3.new(61163.8515625, 11.6796875, 1819.7841796875),
}

-- God's Guard (Level 450-474)
Sea1NPCs["God's Guard"] = {
    Name = "God's Guard",
    Quest = "SkyExp1Quest",
    QuestLv = 1,
    CFrameQ = CFrame.new(-4721.8603515625, 845.30297851563, -1953.8489990234),
    CFrameMon = CFrame.new(-4628.0498046875, 866.92877197266, -1931.2352294922),
    MinLevel = 450,
    MaxLevel = 474,
    Entrance = Vector3.new(-4607.82275, 872.54248, -1667.55688),
}

-- Shanda (Level 475-524)
Sea1NPCs["Shanda"] = {
    Name = "Shanda",
    Quest = "SkyExp1Quest",
    QuestLv = 2,
    CFrameQ = CFrame.new(-7863.1596679688, 5545.5190429688, -378.42266845703),
    CFrameMon = CFrame.new(-7685.1474609375, 5601.0751953125, -441.38876342773),
    MinLevel = 475,
    MaxLevel = 524,
    Entrance = Vector3.new(-7894.6176757813, 5547.1416015625, -380.29119873047),
}

-- Royal Squad (Level 525-549)
Sea1NPCs["Royal Squad"] = {
    Name = "Royal Squad",
    Quest = "SkyExp2Quest",
    QuestLv = 1,
    CFrameQ = CFrame.new(-7903.3828125, 5635.9897460938, -1410.923828125),
    CFrameMon = CFrame.new(-7654.2514648438, 5637.1079101563, -1407.7550048828),
    MinLevel = 525,
    MaxLevel = 549,
}

-- Royal Soldier (Level 550-624)
Sea1NPCs["Royal Soldier"] = {
    Name = "Royal Soldier",
    Quest = "SkyExp2Quest",
    QuestLv = 2,
    CFrameQ = CFrame.new(-7903.3828125, 5635.9897460938, -1410.923828125),
    CFrameMon = CFrame.new(-7760.4106445313, 5679.9077148438, -1884.8112792969),
    MinLevel = 550,
    MaxLevel = 624,
}

-- Galley Pirate (Level 625-649)
Sea1NPCs["Galley Pirate"] = {
    Name = "Galley Pirate",
    Quest = "FountainQuest",
    QuestLv = 1,
    CFrameQ = CFrame.new(5258.2788085938, 38.526931762695, 4050.044921875),
    CFrameMon = CFrame.new(5557.1684570313, 152.32717895508, 3998.7758789063),
    MinLevel = 625,
    MaxLevel = 649,
}

-- Galley Captain (Level 650+)
Sea1NPCs["Galley Captain"] = {
    Name = "Galley Captain",
    Quest = "FountainQuest",
    QuestLv = 2,
    CFrameQ = CFrame.new(5258.2788085938, 38.526931762695, 4050.044921875),
    CFrameMon = CFrame.new(5677.6772460938, 92.786109924316, 4966.6323242188),
    MinLevel = 650,
    MaxLevel = 9999,
}

-- ============================
-- GET CURRENT NPC DATA
-- ============================
function GetCurrentNPCData()
    local level = player.Data.Level.Value
    for _, data in pairs(Sea1NPCs) do
        if level >= data.MinLevel and level <= data.MaxLevel then
            return data
        end
    end
    return nil
end

-- ============================
-- TELEPORT TO ZONE
-- ============================
function TeleportToZone(npcData)
    if not npcData then return end
    
    if npcData.Entrance and (character.HumanoidRootPart.Position - npcData.CFrameMon.Position).Magnitude > 3000 then
        replicatedStorage.Remotes.CommF_:InvokeServer("requestEntrance", npcData.Entrance)
        wait(1)
    end
    
    TeleportTo(npcData.CFrameQ)
    wait(0.5)
end

-- ============================
-- GET QUEST
-- ============================
function GetQuest(npcData)
    if not npcData then return false end
    
    local questGUI = player.PlayerGui.Main.Quest
    if questGUI.Visible and string.find(questGUI.Container.QuestTitle.Title.Text, npcData.Name) then
        return true
    end
    
    replicatedStorage.Remotes.CommF_:InvokeServer("AbandonQuest")
    wait(0.5)
    
    TeleportTo(npcData.CFrameQ)
    wait(0.5)
    
    if (npcData.CFrameQ.Position - character.HumanoidRootPart.Position).Magnitude <= 10 then
        replicatedStorage.Remotes.CommF_:InvokeServer("StartQuest", npcData.Quest, npcData.QuestLv)
        wait(0.5)
        return true
    end
    
    return false
end

-- ============================
-- COMBAT - BRING & ATTACK
-- ============================
function BringAndAttack(mob, npcData)
    if not mob or not mob:FindFirstChild("Humanoid") or mob.Humanoid.Health <= 0 then return end
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    
    local mobHumanoid = mob.Humanoid
    local mobRoot = mob.HumanoidRootPart
    
    repeat
        wait(0.05)
        
        AutoHaki()
        
        if Settings.BringMob then
            mobRoot.CFrame = character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -8)
            mobRoot.Size = Vector3.new(60, 60, 60)
            mobRoot.Transparency = 1
            mobRoot.CanCollide = false
            mobHumanoid.WalkSpeed = 0
            mobHumanoid.JumpPower = 0
            if mobHumanoid:FindFirstChild("Animator") then
                mobHumanoid.Animator:Destroy()
            end
        end
        
        -- Equip and use combat tool
        local combatTool = character:FindFirstChild("Combat")
        if not combatTool then
            local backpackTool = player.Backpack:FindFirstChild("Combat")
            if backpackTool then
                humanoid:EquipTool(backpackTool)
                wait(0.1)
                combatTool = character:FindFirstChild("Combat")
            end
        end
        
        if combatTool then
            combatTool:Activate()
        end
        
        -- Fast attack via CombatFramework
        pcall(function()
            local combatFramework = require(player.PlayerScripts.CombatFramework)
            local controller = debug.getupvalues(combatFramework)[2]
            if controller and controller.activeController then
                controller.activeController.attacking = false
                controller.activeController.timeToNextAttack = 0
                controller.activeController.hitboxMagnitude = 180
                virtualUser:CaptureController()
                virtualUser:Button1Down(Vector2.new(1280, 672))
            end
        end)
        
        -- Check if quest is still active
        local questGUI = player.PlayerGui.Main.Quest
        if not questGUI.Visible or not string.find(questGUI.Container.QuestTitle.Title.Text, npcData.Name) then
            break
        end
        
        -- Check if stop was requested
        if stopFarming then
            break
        end
        
    until not mob.Parent or mobHumanoid.Health <= 0 or not player.Character or humanoid.Health <= 0
end

-- ============================
-- MAIN AUTO-FARM LOOP
-- ============================
local codesRedeemed = false

function AutoFarm()
    -- Auto redeem codes once per session
    if Settings.AutoRedeem and not codesRedeemed then
        RedeemAllCodes()
        codesRedeemed = true
    end
    
    print("🔥 Sea 1 Auto-Farm Started!")
    print("👊 Combat Only - LO + ENI Project")
    print("📊 Current Level: " .. tostring(player.Data.Level.Value))
    
    while not stopFarming do
        pcall(function()
            local npcData = GetCurrentNPCData()
            if not npcData then
                print("⚠️ No NPC found for level: " .. tostring(player.Data.Level.Value))
                wait(5)
                return
            end
            
            -- Update GUI with current status
            UpdateGUIStatus(npcData.Name, player.Data.Level.Value)
            
            -- Print status every 30 seconds
            if tick() % 30 < 0.1 then
                print("📊 Level: " .. tostring(player.Data.Level.Value) .. " | Farming: " .. npcData.Name)
            end
            
            TeleportToZone(npcData)
            
            local questStarted = GetQuest(npcData)
            if not questStarted then
                wait(1)
                return
            end
            
            local enemies = workspace:GetService("Enemies")
            local foundMob = false
            
            for _, mob in pairs(enemies:GetChildren()) do
                if mob.Name == npcData.Name and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
                    foundMob = true
                    BringAndAttack(mob, npcData)
                    break
                end
            end
            
            if not foundMob then
                wait(0.5)
            end
            
            wait(0.1)
        end)
    end
end

-- ============================
-- START
-- ============================
local placeId = game.PlaceId
if placeId ~= 2753915549 then
    print("❌ Not in Sea 1! Place ID: " .. tostring(placeId))
    print("✅ Use this script only in Sea 1.")
else
    print("✅ Sea 1 detected.")
    print("💡 Click 'Start Farming' in the GUI to begin.")
end