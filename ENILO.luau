--[[
    Sea 1 Auto-Farm – Combat Only
    Built for Arceus X Neo
    LO & ENI
    Features:
    - Pure melee combat
    - Quest-based farming
    - All Sea 1 NPCs mapped (1-650+)
    - Custom code redemption (17 codes)
    - Mobile-friendly GUI with start/stop toggle
    - Auto Haki
    - Bring mob
    - Anti-AFK
    - Zone teleport (Fishman, Sky, etc.)
]]

local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local VirtualUser = game:GetService("VirtualUser")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

-- ============================
-- SETTINGS
-- ============================
local Settings = {
    TweenSpeed = 300,
    CombatRange = 15,
    BringMob = true,
    AntiAFK = true,
    AutoHaki = true,
    AutoRedeem = true,
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

local function RedeemCode(code: string)
    if code == "" then
        return
    end
    pcall(function()
        ReplicatedStorage.Remotes.Redeem:InvokeServer(code)
        print("✅ Redeemed: " .. code)
    end)
    task.wait(0.3)
end

local function RedeemAllCodes()
    print("🔄 Redeeming codes...")
    for _, code in CodeList do
        RedeemCode(code)
    end
    print("✅ Code redemption complete!")
end

-- ============================
-- ANTI-AFK
-- ============================
if Settings.AntiAFK then
    Player.Idled:Connect(function()
        VirtualUser:Button2Down(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
    end)
end

-- ============================
-- AUTO HAKI
-- ============================
local function AutoHaki()
    if Settings.AutoHaki and not Character:FindFirstChild("HasBuso") then
        ReplicatedStorage.Remotes.CommF_:InvokeServer("Buso")
    end
end

-- ============================
-- TWEEN / MOVEMENT
-- ============================
local function TweenTo(targetCFrame: CFrame)
    if not Character or not Character:FindFirstChild("HumanoidRootPart") then
        return
    end
    local distance = (targetCFrame.Position - Character.HumanoidRootPart.Position).Magnitude
    if distance <= 5 then
        return
    end
    local tween = TweenService:Create(
        Character.HumanoidRootPart,
        TweenInfo.new(distance / Settings.TweenSpeed, Enum.EasingStyle.Linear),
        { CFrame = targetCFrame }
    )
    tween:Play()
    return tween
end

local function TeleportTo(targetCFrame: CFrame)
    if not Character or not Character:FindFirstChild("HumanoidRootPart") then
        return
    end
    Character.HumanoidRootPart.CFrame = targetCFrame
    task.wait(0.05)
    Character.HumanoidRootPart.CFrame = targetCFrame
end

-- ============================
-- GUI (Mobile-Friendly)
-- ============================
local PlayerGui = Player:WaitForChild("PlayerGui")

local isMobile = UserInputService.TouchEnabled or UserInputService.TouchGuaranteed or not UserInputService.MouseEnabled
local scale = if isMobile then 1.4 else 1.0

local GuiFrame = Instance.new("Frame")
GuiFrame.Name = "ENI_GUI"
GuiFrame.Parent = PlayerGui
GuiFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
GuiFrame.BackgroundTransparency = 0.05
GuiFrame.BorderSizePixel = 0
GuiFrame.Size = UDim2.new(0, 320 * scale, 0, 220 * scale)
GuiFrame.Position = UDim2.new(0.5, -160 * scale, 0.5, -110 * scale)
GuiFrame.Active = true
GuiFrame.Draggable = true
GuiFrame.ClipsDescendants = true

local Corner = Instance.new("UICorner")
Corner.Parent = GuiFrame
Corner.CornerRadius = UDim.new(0, 12)

local Shadow = Instance.new("UIStroke")
Shadow.Parent = GuiFrame
Shadow.Color = Color3.fromRGB(0, 0, 0)
Shadow.Thickness = 2
Shadow.Transparency = 0.6

local TitleBar = Instance.new("Frame")
TitleBar.Parent = GuiFrame
TitleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
TitleBar.BackgroundTransparency = 0
TitleBar.BorderSizePixel = 0
TitleBar.Size = UDim2.new(1, 0, 0, 36 * scale)
TitleBar.Position = UDim2.new(0, 0, 0, 0)

local TitleCorner = Instance.new("UICorner")
TitleCorner.Parent = TitleBar
TitleCorner.CornerRadius = UDim.new(0, 12)

local TitleText = Instance.new("TextLabel")
TitleText.Parent = TitleBar
TitleText.BackgroundTransparency = 1
TitleText.Size = UDim2.new(1, -40 * scale, 1, 0)
TitleText.Position = UDim2.new(0, 12 * scale, 0, 0)
TitleText.Text = "❄️ ENI & LO — Sea 1"
TitleText.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleText.TextSize = 14 * scale
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.Font = Enum.Font.GothamBold

local CloseBtn = Instance.new("TextButton")
CloseBtn.Parent = TitleBar
CloseBtn.BackgroundTransparency = 1
CloseBtn.Size = UDim2.new(0, 32 * scale, 1, 0)
CloseBtn.Position = UDim2.new(1, -32 * scale, 0, 0)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
CloseBtn.TextSize = 16 * scale
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.BorderSizePixel = 0
CloseBtn.MouseButton1Click:Connect(function()
    GuiFrame.Visible = false
end)

local Content = Instance.new("Frame")
Content.Parent = GuiFrame
Content.BackgroundTransparency = 1
Content.Size = UDim2.new(1, -24 * scale, 1, -44 * scale)
Content.Position = UDim2.new(0, 12 * scale, 0, 40 * scale)

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Parent = Content
StatusLabel.BackgroundTransparency = 1
StatusLabel.Size = UDim2.new(1, 0, 0, 24 * scale)
StatusLabel.Position = UDim2.new(0, 0, 0, 0)
StatusLabel.Text = "📌 Status: Idle"
StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusLabel.TextSize = 13 * scale
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Font = Enum.Font.Gotham

local LevelLabel = Instance.new("TextLabel")
LevelLabel.Parent = Content
LevelLabel.BackgroundTransparency = 1
LevelLabel.Size = UDim2.new(1, 0, 0, 24 * scale)
LevelLabel.Position = UDim2.new(0, 0, 0, 26 * scale)
LevelLabel.Text = "📊 Level: " .. tostring(Player.Data.Level.Value)
LevelLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
LevelLabel.TextSize = 13 * scale
LevelLabel.TextXAlignment = Enum.TextXAlignment.Left
LevelLabel.Font = Enum.Font.Gotham

local NPCLabel = Instance.new("TextLabel")
NPCLabel.Parent = Content
NPCLabel.BackgroundTransparency = 1
NPCLabel.Size = UDim2.new(1, 0, 0, 24 * scale)
NPCLabel.Position = UDim2.new(0, 0, 0, 52 * scale)
NPCLabel.Text = "🎯 NPC: Waiting..."
NPCLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
NPCLabel.TextSize = 13 * scale
NPCLabel.TextXAlignment = Enum.TextXAlignment.Left
NPCLabel.Font = Enum.Font.Gotham

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Parent = Content
ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 70)
ToggleBtn.BackgroundTransparency = 0
ToggleBtn.BorderSizePixel = 0
ToggleBtn.Size = UDim2.new(1, 0, 0, 44 * scale)
ToggleBtn.Position = UDim2.new(0, 0, 0, 82 * scale)
ToggleBtn.Text = "▶️ Start Farming"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.TextSize = 16 * scale
ToggleBtn.Font = Enum.Font.GothamBold

local BtnCorner = Instance.new("UICorner")
BtnCorner.Parent = ToggleBtn
BtnCorner.CornerRadius = UDim.new(0, 10)

-- Farming state
local isFarming = false
local farmThread = nil
local stopFarming = false

-- Toggle function
ToggleBtn.MouseButton1Click:Connect(function()
    isFarming = not isFarming

    if isFarming then
        ToggleBtn.Text = "⏹️ Stop Farming"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        StatusLabel.Text = "📌 Status: Farming..."
        print("▶️ Farming started by GUI")
        stopFarming = false

        if farmThread then
            coroutine.close(farmThread)
        end
        farmThread = coroutine.create(function()
            AutoFarm()
        end)
        coroutine.resume(farmThread)
    else
        ToggleBtn.Text = "▶️ Start Farming"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 70)
        StatusLabel.Text = "📌 Status: Stopped"
        print("⏹️ Farming stopped by GUI")
        stopFarming = true

        if farmThread then
            coroutine.close(farmThread)
            farmThread = nil
        end
    end
end)

-- Update GUI function
function UpdateGUIStatus(npcName: string?, level: number?)
    if level then
        LevelLabel.Text = "📊 Level: " .. tostring(level)
    end
    if npcName then
        NPCLabel.Text = "🎯 NPC: " .. npcName
    end
    if isFarming then
        StatusLabel.Text = "📌 Status: Farming..."
    end
end

-- Show the GUI
GuiFrame.Visible = true
GuiFrame.ZIndex = 999

-- ============================
-- SEA 1 NPC DATA
-- ============================
type NPCData = {
    Name: string,
    Quest: string,
    QuestLv: number,
    CFrameQ: CFrame,
    CFrameMon: CFrame,
    MinLevel: number,
    MaxLevel: number,
    Entrance: Vector3?,
}

local Sea1NPCs: { [string]: NPCData } = {}

Sea1NPCs["Bandit"] = {
    Name = "Bandit",
    Quest = "BanditQuest1",
    QuestLv = 1,
    CFrameQ = CFrame.new(1060.9383544922, 16.455066680908, 1547.7841796875),
    CFrameMon = CFrame.new(1038.5533447266, 41.296249389648, 1576.5098876953),
    MinLevel = 1,
    MaxLevel = 9,
}

Sea1NPCs["Monkey"] = {
    Name = "Monkey",
    Quest = "JungleQuest",
    QuestLv = 1,
    CFrameQ = CFrame.new(-1601.6553955078, 36.85213470459, 153.38809204102),
    CFrameMon = CFrame.new(-1448.1446533203, 50.851993560791, 63.60718536377),
    MinLevel = 10,
    MaxLevel = 14,
}

Sea1NPCs["Gorilla"] = {
    Name = "Gorilla",
    Quest = "JungleQuest",
    QuestLv = 2,
    CFrameQ = CFrame.new(-1601.6553955078, 36.85213470459, 153.38809204102),
    CFrameMon = CFrame.new(-1142.6488037109, 40.462348937988, -515.39227294922),
    MinLevel = 15,
    MaxLevel = 29,
}

Sea1NPCs["Pirate"] = {
    Name = "Pirate",
    Quest = "BuggyQuest1",
    QuestLv = 1,
    CFrameQ = CFrame.new(-1140.1761474609, 4.752049446106, 3827.4057617188),
    CFrameMon = CFrame.new(-1201.0881347656, 40.628940582275, 3857.5966796875),
    MinLevel = 30,
    MaxLevel = 39,
}

Sea1NPCs["Brute"] = {
    Name = "Brute",
    Quest = "BuggyQuest1",
    QuestLv = 2,
    CFrameQ = CFrame.new(-1140.1761474609, 4.752049446106, 3827.4057617188),
    CFrameMon = CFrame.new(-1387.5324707031, 24.592035293579, 4100.9575195313),
    MinLevel = 40,
    MaxLevel = 59,
}

Sea1NPCs["Desert Bandit"] = {
    Name = "Desert Bandit",
    Quest = "DesertQuest",
    QuestLv = 1,
    CFrameQ = CFrame.new(896.51721191406, 6.4384617805481, 4390.1494140625),
    CFrameMon = CFrame.new(984.99896240234, 16.109552383423, 4417.91015625),
    MinLevel = 60,
    MaxLevel = 74,
}

Sea1NPCs["Desert Officer"] = {
    Name = "Desert Officer",
    Quest = "DesertQuest",
    QuestLv = 2,
    CFrameQ = CFrame.new(896.51721191406, 6.4384617805481, 4390.1494140625),
    CFrameMon = CFrame.new(1547.1510009766, 14.452038764954, 4381.8002929688),
    MinLevel = 75,
    MaxLevel = 89,
}

Sea1NPCs["Snow Bandit"] = {
    Name = "Snow Bandit",
    Quest = "SnowQuest",
    QuestLv = 1,
    CFrameQ = CFrame.new(1386.8073730469, 87.272789001465, -1298.3576660156),
    CFrameMon = CFrame.new(1356.3028564453, 105.76865386963, -1328.2418212891),
    MinLevel = 90,
    MaxLevel = 99,
}

Sea1NPCs["Snowman"] = {
    Name = "Snowman",
    Quest = "SnowQuest",
    QuestLv = 2,
    CFrameQ = CFrame.new(1386.8073730469, 87.272789001465, -1298.3576660156),
    CFrameMon = CFrame.new(1218.7956542969, 138.01184082031, -1488.0262451172),
    MinLevel = 100,
    MaxLevel = 119,
}

Sea1NPCs["Chief Petty Officer"] = {
    Name = "Chief Petty Officer",
    Quest = "MarineQuest2",
    QuestLv = 1,
    CFrameQ = CFrame.new(-5035.49609375, 28.677835464478, 4324.1840820313),
    CFrameMon = CFrame.new(-4931.1552734375, 65.793113708496, 4121.8393554688),
    MinLevel = 120,
    MaxLevel = 149,
}

Sea1NPCs["Sky Bandit"] = {
    Name = "Sky Bandit",
    Quest = "SkyQuest",
    QuestLv = 1,
    CFrameQ = CFrame.new(-4842.1372070313, 717.69543457031, -2623.0483398438),
    CFrameMon = CFrame.new(-4955.6411132813, 365.46365356445, -2908.1865234375),
    MinLevel = 150,
    MaxLevel = 174,
}

Sea1NPCs["Dark Master"] = {
    Name = "Dark Master",
    Quest = "SkyQuest",
    QuestLv = 2,
    CFrameQ = CFrame.new(-4842.1372070313, 717.69543457031, -2623.0483398438),
    CFrameMon = CFrame.new(-5148.1650390625, 439.04571533203, -2332.9611816406),
    MinLevel = 175,
    MaxLevel = 189,
}

Sea1NPCs["Prisoner"] = {
    Name = "Prisoner",
    Quest = "PrisonerQuest",
    QuestLv = 1,
    CFrameQ = CFrame.new(5310.60547, 0.350014925, 474.946594, 0.0175017118, 0, 0.999846935, 0, 1, 0, -0.999846935, 0, 0.0175017118),
    CFrameMon = CFrame.new(4937.31885, 0.332031399, 649.574524, 0.694649816, 0, -0.719348073, 0, 1, 0, 0.719348073, 0, 0.694649816),
    MinLevel = 190,
    MaxLevel = 209,
}

Sea1NPCs["Dangerous Prisoner"] = {
    Name = "Dangerous Prisoner",
    Quest = "PrisonerQuest",
    QuestLv = 2,
    CFrameQ = CFrame.new(5310.60547, 0.350014925, 474.946594, 0.0175017118, 0, 0.999846935, 0, 1, 0, -0.999846935, 0, 0.0175017118),
    CFrameMon = CFrame.new(5099.6626, 0.351562679, 1055.7583, 0.898906827, 0, -0.438139856, 0, 1, 0, 0.438139856, 0, 0.898906827),
    MinLevel = 210,
    MaxLevel = 249,
}

Sea1NPCs["Toga Warrior"] = {
    Name = "Toga Warrior",
    Quest = "ColosseumQuest",
    QuestLv = 1,
    CFrameQ = CFrame.new(-1577.7890625, 7.4151420593262, -2984.4838867188),
    CFrameMon = CFrame.new(-1872.5166015625, 49.080215454102, -2913.810546875),
    MinLevel = 250,
    MaxLevel = 274,
}

Sea1NPCs["Gladiator"] = {
    Name = "Gladiator",
    Quest = "ColosseumQuest",
    QuestLv = 2,
    CFrameQ = CFrame.new(-1577.7890625, 7.4151420593262, -2984.4838867188),
    CFrameMon = CFrame.new(-1521.3740234375, 81.203170776367, -3066.3139648438),
    MinLevel = 275,
    MaxLevel = 299,
}

Sea1NPCs["Military Soldier"] = {
    Name = "Military Soldier",
    Quest = "MagmaQuest",
    QuestLv = 1,
    CFrameQ = CFrame.new(-5316.1157226563, 12.262831687927, 8517.00390625),
    CFrameMon = CFrame.new(-5369.0004882813, 61.24352645874, 8556.4921875),
    MinLevel = 300,
    MaxLevel = 324,
}

Sea1NPCs["Military Spy"] = {
    Name = "Military Spy",
    Quest = "MagmaQuest",
    QuestLv = 2,
    CFrameQ = CFrame.new(-5316.1157226563, 12.262831687927, 8517.00390625),
    CFrameMon = CFrame.new(-5787.00293, 75.8262634, 8651.69922, 0.838590562, 0, -0.544762194, 0, 1, 0, 0.544762194, 0, 0.838590562),
    MinLevel = 325,
    MaxLevel = 374,
}

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

Sea1NPCs["Royal Squad"] = {
    Name = "Royal Squad",
    Quest = "SkyExp2Quest",
    QuestLv = 1,
    CFrameQ = CFrame.new(-7903.3828125, 5635.9897460938, -1410.923828125),
    CFrameMon = CFrame.new(-7654.2514648438, 5637.1079101563, -1407.7550048828),
    MinLevel = 525,
    MaxLevel = 549,
}

Sea1NPCs["Royal Soldier"] = {
    Name = "Royal Soldier",
    Quest = "SkyExp2Quest",
    QuestLv = 2,
    CFrameQ = CFrame.new(-7903.3828125, 5635.9897460938, -1410.923828125),
    CFrameMon = CFrame.new(-7760.4106445313, 5679.9077148438, -1884.8112792969),
    MinLevel = 550,
    MaxLevel = 624,
}

Sea1NPCs["Galley Pirate"] = {
    Name = "Galley Pirate",
    Quest = "FountainQuest",
    QuestLv = 1,
    CFrameQ = CFrame.new(5258.2788085938, 38.526931762695, 4050.044921875),
    CFrameMon = CFrame.new(5557.1684570313, 152.32717895508, 3998.7758789063),
    MinLevel = 625,
    MaxLevel = 649,
}

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
local function GetCurrentNPCData(): NPCData?
    local level = Player.Data.Level.Value
    for _, data in Sea1NPCs do
        if level >= data.MinLevel and level <= data.MaxLevel then
            return data
        end
    end
    return nil
end

-- ============================
-- TELEPORT TO ZONE
-- ============================
local function TeleportToZone(npcData: NPCData?)
    if not npcData then
        return
    end

    if npcData.Entrance and (Character.HumanoidRootPart.Position - npcData.CFrameMon.Position).Magnitude > 3000 then
        ReplicatedStorage.Remotes.CommF_:InvokeServer("requestEntrance", npcData.Entrance)
        task.wait(1)
    end

    TeleportTo(npcData.CFrameQ)
    task.wait(0.5)
end

-- ============================
-- GET QUEST
-- ============================
local function GetQuest(npcData: NPCData?): boolean
    if not npcData then
        return false
    end

    local questGUI = Player.PlayerGui.Main.Quest
    if questGUI.Visible and string.find(questGUI.Container.QuestTitle.Title.Text, npcData.Name) then
        return true
    end

    ReplicatedStorage.Remotes.CommF_:InvokeServer("AbandonQuest")
    task.wait(0.5)

    TeleportTo(npcData.CFrameQ)
    task.wait(0.5)

    if (npcData.CFrameQ.Position - Character.HumanoidRootPart.Position).Magnitude <= 10 then
        ReplicatedStorage.Remotes.CommF_:InvokeServer("StartQuest", npcData.Quest, npcData.QuestLv)
        task.wait(0.5)
        return true
    end

    return false
end

-- ============================
-- COMBAT - BRING & ATTACK
-- ============================
local function BringAndAttack(mob: Model, npcData: NPCData?)
    if not mob or not mob:FindFirstChild("Humanoid") or mob.Humanoid.Health <= 0 then
        return
    end
    if not Character or not Character:FindFirstChild("HumanoidRootPart") then
        return
    end

    local mobHumanoid = mob.Humanoid
    local mobRoot = mob.HumanoidRootPart

    repeat
        task.wait(0.05)

        AutoHaki()

        if Settings.BringMob then
            mobRoot.CFrame = Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -8)
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
        local combatTool = Character:FindFirstChild("Combat")
        if not combatTool then
            local backpackTool = Player.Backpack:FindFirstChild("Combat")
            if backpackTool then
                Humanoid:EquipTool(backpackTool)
                task.wait(0.1)
                combatTool = Character:FindFirstChild("Combat")
            end
        end

        if combatTool then
            combatTool:Activate()
        end

        -- Fast attack via CombatFramework
        pcall(function()
            local combatFramework = require(Player.PlayerScripts.CombatFramework)
            local controller = debug.getupvalues(combatFramework)[2]
            if controller and controller.activeController then
                controller.activeController.attacking = false
                controller.activeController.timeToNextAttack = 0
                controller.activeController.hitboxMagnitude = 180
                VirtualUser:CaptureController()
                VirtualUser:Button1Down(Vector2.new(1280, 672))
            end
        end)

        -- Check if quest is still active
        local questGUI = Player.PlayerGui.Main.Quest
        if not questGUI.Visible or not string.find(questGUI.Container.QuestTitle.Title.Text, npcData.Name) then
            break
        end

        -- Check if stop was requested
        if stopFarming then
            break
        end

    until not mob.Parent or mobHumanoid.Health <= 0 or not Player.Character or Humanoid.Health <= 0
end

-- ============================
-- MAIN AUTO-FARM LOOP
-- ============================
local codesRedeemed = false

function AutoFarm()
    if Settings.AutoRedeem and not codesRedeemed then
        RedeemAllCodes()
        codesRedeemed = true
    end

    print("🔥 Sea 1 Auto-Farm Started!")
    print("👊 Combat Only - LO + ENI Project")
    print("📊 Current Level: " .. tostring(Player.Data.Level.Value))

    while not stopFarming do
        pcall(function()
            local npcData = GetCurrentNPCData()
            if not npcData then
                print("⚠️ No NPC found for level: " .. tostring(Player.Data.Level.Value))
                task.wait(5)
                return
            end

            -- Update GUI with current status
            UpdateGUIStatus(npcData.Name, Player.Data.Level.Value)

            -- Print status every 30 seconds
            if tick() % 30 < 0.1 then
                print("📊 Level: " .. tostring(Player.Data.Level.Value) .. " | Farming: " .. npcData.Name)
            end

            TeleportToZone(npcData)

            local questStarted = GetQuest(npcData)
            if not questStarted then
                task.wait(1)
                return
            end

            local enemies = Workspace:GetService("Enemies")
            local foundMob = false

            for _, mob in enemies:GetChildren() do
                if mob.Name == npcData.Name and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
                    foundMob = true
                    BringAndAttack(mob, npcData)
                    break
                end
            end

            if not foundMob then
                task.wait(0.5)
            end

            task.wait(0.1)
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