
-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character
if not Character then
    Character = LocalPlayer.CharacterAdded:Wait()
end

local Humanoid = Character:WaitForChild("Humanoid")
local RootPart = Character:WaitForChild("HumanoidRootPart")
local Terrain = Workspace:FindFirstChildOfClass("Terrain")

local DefaultWalkSpeed = Humanoid.WalkSpeed
local DefaultJumpPower = Humanoid.JumpPower or 50
local DefaultJumpHeight = Humanoid.JumpHeight or 7.2

local UpgradeRemotes = ReplicatedStorage:WaitForChild("UpgradeRemotes")
local PurchaseHealthUpgrade = UpgradeRemotes:WaitForChild("PurchaseHealthUpgrade")
local PurchaseWeaponUpgrade = UpgradeRemotes:WaitForChild("PurchaseWeaponUpgrade")
local WaveRemotes = ReplicatedStorage:WaitForChild("WaveRemotes")
local SkipVote = WaveRemotes:WaitForChild("SkipVote")
local GearRemotes = ReplicatedStorage:WaitForChild("GearRemotes")
local GearPurchase = GearRemotes:WaitForChild("GearPurchase")

local ZombieDamageRemote = nil
local function EnsureZombieRemote()
    if ZombieDamageRemote then return true end
    pcall(function()
        local zr = ReplicatedStorage:WaitForChild("ZombieRemotes")
        ZombieDamageRemote = zr:WaitForChild("ZombieDamage", 5)
    end)
    return ZombieDamageRemote ~= nil
end
EnsureZombieRemote()

local function FireZombieDamage(zombieId, damage)
    if not EnsureZombieRemote() then return end
    local ok = pcall(function()
        ZombieDamageRemote:FireServer(zombieId, damage)
    end)
    if not ok then
        EnsureZombieRemote()
    end
end

local Config = {

    KillAuraEnabled = false,
    KillAuraMode = "V1",
    KillAuraRange = 5000,
    KillAuraDamage = 999999999,
    KillAuraV2Multiplier = 1,
    AutoEquip = false,
    AutoBuyWeapon = false,
    AutoBuyHealth = false,
    AutoBuyGear = false,
    AutoSkipWave = false,

    ZombieESP = false,
    PlayerESP = false,
    NoFog = false,
    FullBright = false,

    SpeedHack = false,
    SpeedValue = 24,
    JumpHack = false,
    JumpValue = 100,
    TPSafeGround = false,
    TPSafeSky = false,
    TPSafeZoneV2 = false,
    Fly = false,
    FlySpeed = 50,
    Noclip = false,

    AntiAFK = false,
    FPSUncap = false,
    FPSCap = 60,
    FPSBooster = false,
    DPIScale = 100,

    SelectedGear = "AutoTurret",
}

local WeaponTier = {
    Pistol = 1, ShotGun = 2, Rifle = 3,
    Minigun = 4, Revolver = 5, DualPistols = 6,
    SMG = 7, CombatShotgun = 8, BurstRifle = 9,
    AK47 = 10, Sniper = 11, HeavyRifle = 12,
    Flamethrower = 13, MP5 = 14, USPS = 15,
    GoldenAK47 = 16, EmberSMG = 17, LavaRifle = 18,
    CoreBreaker = 19, LavaBow = 20, InfernoMinigun = 21,
    LavaGatling = 22, GumdropBlaster = 23, ArticStriker = 24,
    GalacticWeaver = 25, WorldEnder = 26, TommyGun = 27,
}

local WeaponDamage = {
    Pistol = 17, Revolver = 65, DualPistols = 35,
    USPS = 50, ShotGun = 40, SMG = 12,
    CombatShotgun = 55, MP5 = 20, Rifle = 60,
    BurstRifle = 160, AK47 = 90, Sniper = 500,
    TommyGun = 70, HeavyRifle = 155, Minigun = 13,
    Flamethrower = 104, GrenadeLauncher = 600, GumdropBlaster = 750,
    ArticStriker = 400, GoldenAK47 = 450, EmberSMG = 275,
    LavaRifle = 523, CoreBreaker = 629, LavaBow = 2160,
    InfernoMinigun = 364, LavaGatling = 880, GalacticWeaver = 800,
    WorldEnder = 1440, RPG = 1000, Plasma = 1500,
}

local GunConfig = nil
pcall(function()
    local data = ReplicatedStorage:WaitForChild("Data")
    GunConfig = require(data:WaitForChild("GunConfig"))
end)

local function GetToolDamage(tool)
    if not tool then return 10 end
    if GunConfig and GunConfig.Guns and GunConfig.Guns[tool.Name] then
        return GunConfig.Guns[tool.Name].Damage
    end
    local attr = tool:GetAttribute("Damage")
    if attr then return attr end
    local val = tool:FindFirstChild("Damage")
    if val and (val:IsA("NumberValue") or val:IsA("IntValue")) then
        return val.Value
    end
    return WeaponDamage[tool.Name] or 10
end

local BestWeapon = nil
local BestTier = -1

local function ScanForBestWeapon(container)
    if not container then return end
    for _, item in ipairs(container:GetChildren()) do
        if item:IsA("Tool") and item:FindFirstChild("Handle") then
            local tier = WeaponTier[item.Name] or 0
            if tier > BestTier then
                BestTier = tier
                BestWeapon = item
            end
        end
    end
end

local function TryAutoEquip()
    if not Config.AutoEquip then return end
    BestTier = -1
    BestWeapon = nil
    ScanForBestWeapon(Character)
    ScanForBestWeapon(LocalPlayer:FindFirstChild("Backpack"))
    if BestWeapon and BestWeapon ~= Character:FindFirstChildOfClass("Tool") then
        pcall(function()
            Humanoid:EquipTool(BestWeapon)
        end)
    end
end

local function GetZombies()
    local results = {}

    local zc = _G.ZombieClient
    if zc and zc.Zombies then
        for id, data in pairs(zc.Zombies) do
            if data and not data.IsDying then
                local pos = data.CurrentPosition or data.TargetPosition
                if pos then
                    table.insert(results, { id = id, pos = pos, data = data })
                end
            end
        end
        if #results > 0 then return results end
    end

    local folder = Workspace:FindFirstChild("Zombies_Local")
    if folder then
        for _, child in ipairs(folder:GetChildren()) do
            if child:IsA("Model") and child.PrimaryPart then
                local id = tonumber(child.Name:match("%d+$"))
                          or child:GetAttribute("ZombieId")
                if id then
                    table.insert(results, { id = id, pos = child.PrimaryPart.Position, model = child })
                end
            end
        end
        if #results > 0 then return results end
    end

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.PrimaryPart then
            local nameLow = obj.Name:lower()
            if nameLow:find("zombie") then
                local id = tonumber(obj.Name:match("%d+$"))
                          or obj:GetAttribute("ZombieId")
                          or obj:GetAttribute("Id")
                if id then
                    local duplicate = false
                    for _, r in ipairs(results) do
                        if r.id == id then duplicate = true; break end
                    end
                    if not duplicate then
                        table.insert(results, { id = id, pos = obj.PrimaryPart.Position, model = obj })
                    end
                end
            end
        end
    end

    return results
end

local KillCooldowns = {}
local KILL_COOLDOWN = 0.15
local KillAuraV2Active = false

task.spawn(function()
    while true do
        task.wait(30)
        local now = os.clock()
        for id, t in pairs(KillCooldowns) do
            if now - t > 10 then KillCooldowns[id] = nil end
        end
    end
end)

local function KillAuraV1()
    if not Config.KillAuraEnabled or Config.KillAuraMode ~= "V1" then return end
    if not EnsureZombieRemote() then return end
    if not RootPart or not RootPart.Parent then
        Character = LocalPlayer.Character
        if Character then
            RootPart = Character:FindFirstChild("HumanoidRootPart")
            Humanoid = Character:FindFirstChild("Humanoid")
        end
        if not RootPart then return end
    end
    local myPos = RootPart.Position
    local now = os.clock()
    for _, zombie in ipairs(GetZombies()) do
        if typeof(zombie.pos) == "Vector3" then
            if (zombie.pos - myPos).Magnitude <= Config.KillAuraRange then
                local id = zombie.id
                if not KillCooldowns[id] or now - KillCooldowns[id] >= KILL_COOLDOWN then
                    KillCooldowns[id] = now
                    FireZombieDamage(id, Config.KillAuraDamage)
                end
            end
        end
    end
end

task.spawn(function()
    while true do
        task.wait(0.05)
        if Config.KillAuraEnabled and Config.KillAuraMode == "V2" then
            if not KillAuraV2Active then
                Config.AutoEquip = true
                TryAutoEquip()
                KillAuraV2Active = true
            end
            if not EnsureZombieRemote() then continue end
            if not Character or not Character.Parent or not Humanoid or not RootPart or not RootPart.Parent then
                Character = LocalPlayer.Character
                if Character then
                    Humanoid = Character:FindFirstChild("Humanoid")
                    RootPart = Character:FindFirstChild("HumanoidRootPart")
                end
            else
                local tool = Character:FindFirstChildOfClass("Tool")
                local damage = math.floor(GetToolDamage(tool) * Config.KillAuraV2Multiplier)
                local now = os.clock()
                for _, zombie in ipairs(GetZombies()) do
                    if typeof(zombie.pos) == "Vector3" then
                        local id = zombie.id
                        if not KillCooldowns[id] or now - KillCooldowns[id] >= KILL_COOLDOWN then
                            KillCooldowns[id] = now
                            FireZombieDamage(id, damage)
                        end
                    end
                end
            end
        else
            if KillAuraV2Active then KillAuraV2Active = false end
        end
    end
end)

local AutoBuyTimers = { Weapon = 0, Health = 0, Gear = 0 }
local AutoBuyNotified = { Weapon = false, Health = false, Gear = false }

local function Notify(title, desc, t)

end

local function AutoBuyTick()
    local now = os.clock()

    if Config.AutoBuyWeapon and now - AutoBuyTimers.Weapon > 0.5 then
        AutoBuyTimers.Weapon = now
        pcall(function() PurchaseWeaponUpgrade:FireServer() end)
        if not AutoBuyNotified.Weapon then
            AutoBuyNotified.Weapon = true
            Notify("Auto Buy", "Weapon Upgrade is active", 2)
        end
    end
    if not Config.AutoBuyWeapon then AutoBuyNotified.Weapon = false end

    if Config.AutoBuyHealth and now - AutoBuyTimers.Health > 0.5 then
        AutoBuyTimers.Health = now
        pcall(function() PurchaseHealthUpgrade:FireServer() end)
        if not AutoBuyNotified.Health then
            AutoBuyNotified.Health = true
            Notify("Auto Buy", "Health Upgrade is active", 2)
        end
    end
    if not Config.AutoBuyHealth then AutoBuyNotified.Health = false end

    if Config.AutoBuyGear and now - AutoBuyTimers.Gear > 0.3 then
        AutoBuyTimers.Gear = now
        pcall(function() GearPurchase:FireServer(Config.SelectedGear) end)
        if not AutoBuyNotified.Gear then
            AutoBuyNotified.Gear = true
            Notify("Auto Buy", Config.SelectedGear .. " is active", 2)
        end
    end
    if not Config.AutoBuyGear then AutoBuyNotified.Gear = false end
end

local SafeGroundCFrame = nil
local SafeZoneV2CFrame = nil
local SkyOrigPos = nil
local SkyPlatform = nil

local function UpdateSpeed()
    if not Humanoid then return end
    if Config.SpeedHack then
        Humanoid.WalkSpeed = Config.SpeedValue
    else
        if Humanoid.WalkSpeed ~= DefaultWalkSpeed then
            Humanoid.WalkSpeed = DefaultWalkSpeed
        end
    end
    if Config.JumpHack then
        if Humanoid.UseJumpPower then
            Humanoid.JumpPower = Config.JumpValue
        else
            Humanoid.JumpHeight = Config.JumpValue / 7
        end
    else
        if Humanoid.UseJumpPower then
            if Humanoid.JumpPower ~= DefaultJumpPower then Humanoid.JumpPower = DefaultJumpPower end
        else
            if Humanoid.JumpHeight ~= DefaultJumpHeight then Humanoid.JumpHeight = DefaultJumpHeight end
        end
    end
end

local SafeGroundPos = Vector3.new(22.22, 4, -167.02)
local function UpdateTPSafeGround()
    if not RootPart then return end
    if Config.TPSafeGround then
        if not SafeGroundCFrame then
            SafeGroundCFrame = RootPart.CFrame
            RootPart.CFrame = CFrame.new(SafeGroundPos)
        end
    else
        if SafeGroundCFrame then
            RootPart.CFrame = SafeGroundCFrame
            SafeGroundCFrame = nil
        end
    end
end

local SafeZoneV2Pos = Vector3.new(-340.99, 458.54, -321.69)
local function UpdateTPSafeZoneV2()
    if not RootPart then return end
    if Config.TPSafeZoneV2 then
        if not SafeZoneV2CFrame then
            SafeZoneV2CFrame = RootPart.CFrame
            RootPart.CFrame = CFrame.new(SafeZoneV2Pos)
        end
    else
        if SafeZoneV2CFrame then
            RootPart.CFrame = SafeZoneV2CFrame
            SafeZoneV2CFrame = nil
        end
    end
end

local function UpdateTPSafeSky()
    if not RootPart then return end
    if Config.TPSafeSky then
        if not SkyOrigPos then
            SkyOrigPos = RootPart.Position
            local skyY = SkyOrigPos.Y + 40
            if not SkyPlatform then
                SkyPlatform = Instance.new("Part")
                SkyPlatform.Name = "SkyPlatform"
                SkyPlatform.Size = Vector3.new(50, 2, 50)
                SkyPlatform.Anchored = true
                SkyPlatform.Transparency = 1
                SkyPlatform.CanCollide = true
                SkyPlatform.Position = Vector3.new(SkyOrigPos.X, skyY - SkyPlatform.Size.Y / 2, SkyOrigPos.Z)
                SkyPlatform.Parent = Workspace
            end
            RootPart.CFrame = CFrame.new(SkyOrigPos.X, skyY + (Humanoid.HipHeight or RootPart.Size.Y / 2), SkyOrigPos.Z)
        end
        if SkyPlatform then
            SkyPlatform.Position = Vector3.new(RootPart.Position.X, SkyPlatform.Position.Y, RootPart.Position.Z)
        end
    else
        if SkyOrigPos then
            RootPart.CFrame = CFrame.new(SkyOrigPos)
            SkyOrigPos = nil
        end
        if SkyPlatform then SkyPlatform:Destroy(); SkyPlatform = nil end
    end
end

local function UpdateNoclip()
    if not Character or not Config.Noclip then return end
    for _, part in ipairs(Character:GetDescendants()) do
        if part:IsA("BasePart") then part.CanCollide = false end
    end
end

local BodyGyro = nil
local BodyVelocity = nil
local MobileFlyGui = nil
local MobileInput = { up = false, down = false }

local function CreateMobileFlyButtons()
    if MobileFlyGui then return end
    local gui = Instance.new("ScreenGui")
    gui.Name = "MobileFlyButtons"
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 10
    gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    local btnUp = Instance.new("TextButton")
    btnUp.Size = UDim2.new(0, 80, 0, 80)
    btnUp.Position = UDim2.new(1, -90, 0.5, -90)
    btnUp.Text = "â¬† Fly Up"
    btnUp.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
    btnUp.TextColor3 = Color3.new(1, 1, 1)
    btnUp.BorderSizePixel = 0
    btnUp.Parent = gui

    local btnDown = Instance.new("TextButton")
    btnDown.Size = UDim2.new(0, 80, 0, 80)
    btnDown.Position = UDim2.new(1, -90, 0.5, 10)
    btnDown.Text = "â¬‡ Fly Down"
    btnDown.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
    btnDown.TextColor3 = Color3.new(1, 1, 1)
    btnDown.BorderSizePixel = 0
    btnDown.Parent = gui

    btnUp.MouseButton1Down:Connect(function() MobileInput.up = true end)
    btnUp.MouseButton1Up:Connect(function() MobileInput.up = false end)
    btnDown.MouseButton1Down:Connect(function() MobileInput.down = true end)
    btnDown.MouseButton1Up:Connect(function() MobileInput.down = false end)

    MobileFlyGui = { gui = gui, input = MobileInput }
end

local function DestroyMobileFlyButtons()
    if MobileFlyGui then
        pcall(function() MobileFlyGui.gui:Destroy() end)
        MobileFlyGui = nil
    end
end

local function EnableFly()
    if not RootPart then return end
    Humanoid.PlatformStand = true
    if not BodyGyro then
        BodyGyro = Instance.new("BodyGyro")
        BodyGyro.MaxTorque = Vector3.new(400000, 400000, 400000)
        BodyGyro.P = 30000
        BodyGyro.Parent = RootPart
    end
    if not BodyVelocity then
        BodyVelocity = Instance.new("BodyVelocity")
        BodyVelocity.MaxForce = Vector3.new(400000, 400000, 400000)
        BodyVelocity.Velocity = Vector3.zero
        BodyVelocity.Parent = RootPart
    end
    if UserInputService.TouchEnabled then
        CreateMobileFlyButtons()
    end
end

local function DisableFly()
    if Humanoid then Humanoid.PlatformStand = false end
    if BodyGyro then BodyGyro:Destroy(); BodyGyro = nil end
    if BodyVelocity then BodyVelocity:Destroy(); BodyVelocity = nil end
    DestroyMobileFlyButtons()
end

local function UpdateFlyVelocity()
    if not BodyVelocity or not BodyGyro then return end
    local cam = Workspace.CurrentCamera
    if not cam then return end

    local dir = Vector3.zero

    if not UserInputService.TouchEnabled then

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            dir = dir + cam.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            dir = dir - cam.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            dir = dir + cam.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            dir = dir - cam.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            dir = dir + Vector3.yAxis
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            dir = dir - Vector3.yAxis
        end
    else

        if Humanoid and Humanoid.MoveDirection.Magnitude > 0 then
            local md = Humanoid.MoveDirection
            dir = cam.CFrame.LookVector * md.Z + cam.CFrame.RightVector * md.X
        end
        if MobileFlyGui and MobileFlyGui.input.up then dir = dir + Vector3.yAxis end
        if MobileFlyGui and MobileFlyGui.input.down then dir = dir - Vector3.yAxis end
    end

    if dir.Magnitude > 0 then
        BodyVelocity.Velocity = dir.Unit * Config.FlySpeed
    else
        BodyVelocity.Velocity = Vector3.zero
    end
    BodyGyro.CFrame = cam.CFrame
end

local ESPObjects = {}

local function ClearESP()
    for _, gui in ipairs(ESPObjects) do
        pcall(function() gui:Destroy() end)
    end
    ESPObjects = {}
end

local function RefreshESP()
    ClearESP()
    if Config.ZombieESP then
        for _, zombie in ipairs(GetZombies()) do
            if zombie.model and zombie.model.PrimaryPart then
                local bb = Instance.new("BillboardGui")
                bb.AlwaysOnTop = true
                bb.Size = UDim2.new(0, 80, 0, 30)
                bb.StudsOffset = Vector3.new(0, 2.5, 0)
                bb.Parent = zombie.model.PrimaryPart
                local lbl = Instance.new("TextLabel")
                lbl.BackgroundTransparency = 1
                lbl.Size = UDim2.new(1, 0, 1, 0)
                lbl.TextColor3 = Color3.fromRGB(255, 60, 60)
                lbl.TextStrokeTransparency = 0.5
                lbl.Text = "Zombie"
                lbl.Parent = bb
                table.insert(ESPObjects, bb)
            end
        end
    end
    if Config.PlayerESP then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local bb = Instance.new("BillboardGui")
                    bb.AlwaysOnTop = true
                    bb.Size = UDim2.new(0, 100, 0, 25)
                    bb.StudsOffset = Vector3.new(0, 3, 0)
                    bb.Parent = hrp
                    local lbl = Instance.new("TextLabel")
                    lbl.BackgroundTransparency = 1
                    lbl.Size = UDim2.new(1, 0, 1, 0)
                    lbl.TextColor3 = Color3.fromRGB(0, 255, 100)
                    lbl.TextStrokeTransparency = 0.5
                    lbl.Text = plr.Name
                    lbl.Parent = bb
                    table.insert(ESPObjects, bb)
                end
            end
        end
    end
end

local SavedLighting = {}

local function SetFullBright(enabled)
    if enabled then
        if not SavedLighting.saved then
            SavedLighting = {
                Ambient = Lighting.Ambient,
                Brightness = Lighting.Brightness,
                OutdoorAmbient = Lighting.OutdoorAmbient,
                ClockTime = Lighting.ClockTime,
                GlobalShadows = Lighting.GlobalShadows,
                saved = true,
            }
        end
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.Brightness = 3
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
        Lighting.ClockTime = 14
        Lighting.GlobalShadows = false
        if not Config.NoFog then
            Lighting.FogEnd = 999999
            Lighting.FogStart = 99999
        end
    else
        if SavedLighting.saved then
            Lighting.Ambient = SavedLighting.Ambient
            Lighting.Brightness = SavedLighting.Brightness
            Lighting.OutdoorAmbient = SavedLighting.OutdoorAmbient
            Lighting.ClockTime = SavedLighting.ClockTime
            Lighting.GlobalShadows = SavedLighting.GlobalShadows
            SavedLighting.saved = false
        end
        if not Config.NoFog then
            Lighting.FogEnd = 5000
            Lighting.FogStart = 1000
        end
    end
end

local function SetNoFog(enabled)
    if enabled then
        Lighting.FogEnd = 999999
        Lighting.FogStart = 99999
    else
        if not Config.FullBright then
            Lighting.FogEnd = 5000
            Lighting.FogStart = 1000
        end
    end
end

local function ApplyFPSSettings()
    if Config.FPSUncap then
        pcall(function() setfpscap(Config.FPSCap) end)
    else
        pcall(function() setfpscap(0) end)
    end
end

local FPSBoostActive = false
local FPSBoostSaved = {}
local FPSBoostConn = nil

local function EnableFPSBooster()
    if FPSBoostActive then return end
    FPSBoostActive = true

    FPSBoostSaved.GlobalShadows = Lighting.GlobalShadows
    FPSBoostSaved.Brightness = Lighting.Brightness
    FPSBoostSaved.FogEnd = Lighting.FogEnd
    pcall(function() FPSBoostSaved.TerrainDeco = Terrain.Decoration end)
    pcall(function() FPSBoostSaved.WaterWaveSize = Terrain.WaterWaveSize end)
    pcall(function() FPSBoostSaved.WaterWaveSpeed = Terrain.WaterWaveSpeed end)
    pcall(function() FPSBoostSaved.WaterReflect = Terrain.WaterReflectance end)
    pcall(function() FPSBoostSaved.WaterTransp = Terrain.WaterTransparency end)
    pcall(function() FPSBoostSaved.QualityLevel = settings().rendering.QualityLevel end)

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            pcall(function()
                obj.Material = Enum.Material.SmoothPlastic
                obj.Reflectance = 0
                obj.CastShadow = false
            end)
        elseif obj:IsA("Decal") or obj:IsA("Texture") then
            pcall(function() obj:Destroy() end)
        end
    end

    for _, child in ipairs(Lighting:GetChildren()) do
        if child:IsA("PostProcessEffect") then
            pcall(function() child.Enabled = false end)
        end
    end

    if Terrain then
        pcall(function() Terrain.Decoration = false end)
        pcall(function() Terrain.WaterWaveSize = 0 end)
        pcall(function() Terrain.WaterWaveSpeed = 0 end)
        pcall(function() Terrain.WaterReflectance = 0 end)
        pcall(function() Terrain.WaterTransparency = 0 end)
    end

    local clouds = Workspace:FindFirstChild("Clouds")
    if clouds then pcall(function() clouds:Destroy() end) end
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("ParticleEmitter") then
            pcall(function() obj:Destroy() end)
        end
    end

    pcall(function()
        settings().physics.PhysicsEnvironmentalThrottle = Enum.EnviromentalPhysicsThrottle.Always
    end)
    pcall(function()
        settings().rendering.QualityLevel = Enum.QualityLevel.Level1
    end)

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            pcall(function()
                obj.Velocity = Vector3.zero
                obj.RotVelocity = Vector3.zero
            end)
        end
    end

    Lighting.GlobalShadows = false
    Lighting.Brightness = 3
    Lighting.FogEnd = 9000000000

    pcall(function()
        if sethiddenproperty then
            sethiddenproperty(Lighting, "Technology", Enum.Technology.Compatibility)
        end
    end)

    FPSBoostConn = game.DescendantAdded:Connect(function(obj)
        if not Config.FPSBooster then return end
        if obj:IsA("BasePart") then
            pcall(function()
                obj.Material = Enum.Material.SmoothPlastic
                obj.Reflectance = 0
                obj.CastShadow = false
            end)
        elseif obj:IsA("Decal") then
            pcall(function() obj:Destroy() end)
        end
    end)

    Notify("FPS Booster", "Ultra FPS Boost enabled!", 2)
end

local function DisableFPSBooster()
    if not FPSBoostActive then return end
    FPSBoostActive = false

    if FPSBoostConn then FPSBoostConn:Disconnect(); FPSBoostConn = nil end

    pcall(function() Lighting.GlobalShadows = FPSBoostSaved.GlobalShadows end)
    pcall(function() Lighting.Brightness = FPSBoostSaved.Brightness end)
    pcall(function() Lighting.FogEnd = FPSBoostSaved.FogEnd end)

    for _, child in ipairs(Lighting:GetChildren()) do
        if child:IsA("PostProcessEffect") then
            pcall(function() child.Enabled = true end)
        end
    end

    if Terrain then
        pcall(function() Terrain.Decoration = FPSBoostSaved.TerrainDeco end)
        pcall(function() Terrain.WaterWaveSize = FPSBoostSaved.WaterWaveSize end)
        pcall(function() Terrain.WaterWaveSpeed = FPSBoostSaved.WaterWaveSpeed end)
        pcall(function() Terrain.WaterReflectance = FPSBoostSaved.WaterReflect end)
        pcall(function() Terrain.WaterTransparency = FPSBoostSaved.WaterTransp end)
    end

    pcall(function()
        settings().rendering.QualityLevel = FPSBoostSaved.QualityLevel
    end)

    Notify("FPS Booster", "Disabled - Settings restored", 2)
end

local AntiAFKIdledConn = nil
local AntiAFKJumpTimer = 0
local AntiAFKMoveTimer = 0
local AntiAFKMoveDir = false

local function SetupAntiAFK()
    if AntiAFKIdledConn then AntiAFKIdledConn:Disconnect() end
    AntiAFKIdledConn = LocalPlayer.Idled:Connect(function()
        if Config.AntiAFK then
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end
    end)
end
SetupAntiAFK()

local function AntiAFKTick()
    if not Config.AntiAFK or Config.Fly then return end
    if not Humanoid or Humanoid.Health <= 0 or not RootPart then return end
    local now = os.clock()
    if now - AntiAFKJumpTimer > 7 then
        AntiAFKJumpTimer = now
        pcall(function() Humanoid.Jump = true end)
    end
    if now - AntiAFKMoveTimer > 30 then
        AntiAFKMoveTimer = now
        AntiAFKMoveDir = not AntiAFKMoveDir
        local dir = AntiAFKMoveDir and 1 or -1
        pcall(function()
            Humanoid:Move(Vector3.new(dir, 0, 0), true)
            task.wait(0.1)
            Humanoid:Move(Vector3.new(0, 0, 0), true)
        end)
    end
end

local BlackScreenGui = nil
local function SetBlackScreen(enabled)
    if enabled then
        if not BlackScreenGui then
            BlackScreenGui = Instance.new("ScreenGui", LocalPlayer.PlayerGui)
            BlackScreenGui.Name = "BlackScreen"
            BlackScreenGui.IgnoreGuiInset = true
            BlackScreenGui.DisplayOrder = 2000000000
            local frame = Instance.new("Frame", BlackScreenGui)
            frame.BackgroundColor3 = Color3.new(0, 0, 0)
            frame.Size = UDim2.new(1, 0, 1, 0)
            frame.BorderSizePixel = 0
        end
    else
        if BlackScreenGui then BlackScreenGui:Destroy(); BlackScreenGui = nil end
    end
end

LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
    Humanoid = char:WaitForChild("Humanoid")
    RootPart = char:WaitForChild("HumanoidRootPart")
    DefaultWalkSpeed = Humanoid.WalkSpeed
    DefaultJumpPower = Humanoid.JumpPower or 50
    DefaultJumpHeight = Humanoid.JumpHeight or 7.2

    Config.TPSafeGround = false; SafeGroundCFrame = nil
    Config.TPSafeSky = false; SkyOrigPos = nil
    Config.TPSafeZoneV2 = false; SafeZoneV2CFrame = nil
    if SkyPlatform then SkyPlatform:Destroy(); SkyPlatform = nil end

    AutoBuyNotified.Weapon = false
    AutoBuyNotified.Health = false
    AutoBuyNotified.Gear = false

    DisableFly()
    SetupAntiAFK()
    if Config.FPSBooster then
        task.wait(0.5)
        EnableFPSBooster()
    end
end)

local ESPTimer = 0
local HeartbeatConn = RunService.Heartbeat:Connect(function()
    KillAuraV1()
    AutoBuyTick()
    TryAutoEquip()
    UpdateSpeed()
    UpdateTPSafeGround()
    UpdateTPSafeZoneV2()
    UpdateTPSafeSky()
    UpdateNoclip()
    AntiAFKTick()

    if Config.Fly then
        EnableFly()
        UpdateFlyVelocity()
    else
        DisableFly()
    end

    local now = os.clock()
    if now - ESPTimer > 1 then
        ESPTimer = now
        if Config.ZombieESP or Config.PlayerESP then
            RefreshESP()
        else
            ClearESP()
        end
    end
end)

-- MAIN HUB FUNCTION
local WindUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"
))()

WindUI:Notify({
    Title = "KyoHub",
    Content = "Please be patient while we set things up.",
    Duration = 2,
})

function LoadMainHub()

    local Window = WindUI:CreateWindow({
        Title = "KyoHub",
        Icon = "star",
        Theme = "Midnight",
        Size = UDim2.fromOffset(620, 460),
        HasOutline = true,
        Acrylic = true,
    })

    -- Tabs (INSIDE FUNCTION)
    local HomeTab = Window:Tab({
        Title = "Home",
        Icon = "house"
    })

    local MainTab = Window:Tab({
        Title = "Main",
        Icon = "star"
    })

    local ExtraTab = Window:Tab({
        Title = "Extra",
        Icon = "star",
    })
    -- Sections
    local InfoSection = HomeTab:Section({
        Title = "Information",
        Opened = true
    })

    InfoSection:Paragraph({
    Title = "Welcome",
    Desc = "Thank you for using KyoHub! If you want to help us Grow our server and participate in growing our community, then feel free to join our discord server, also if you want you could apply for content creator role and promote our script!"
})

    InfoSection:Button({
    Title = "Copy Discord Invite",
    Callback = function()
        setclipboard("https://discord.gg/3MRs9AKy")

        WindUI:Notify({
            Title = "Copied",
            Content = "Our Discord invite copied to clipboard",
            Duration = 2
        })
    end
})

    HomeTab:Paragraph({
    Title = "Player Info",
    Desc = "Username: "..game.Players.LocalPlayer.Name
})

    InfoSection:Paragraph({
    Title = "Become a CC to support us",
    Desc = "To Help grow our discord community, you could become a content creator in our server, by showcasing and promoting our script in tiktok, or youtube through making shorts or long form videos its up to you, or you could become a talker in our community!"
})


HomeTab:Toggle({
    Title = "Transparency",
    Icon = "palette",
    Value = WindUI:GetTransparency(),
    Callback = function(v)
        Window:ToggleTransparency(v)
    end
})
    
    
    local CombatBox = MainTab:Section({
        Title = "Kill Aura",
        Icon = "crosshair",
        Opened = true
    })

    CombatBox:Toggle({
        Title = "Kill Aura",
        Default = false,
        Tooltip = "Fire ZombieDamage remote on all zombies in range",
        Callback = function(v) Config.KillAuraEnabled = v end,
})

    CombatBox:Dropdown({
        Title = "Mode",
        Default = "V1",
        Values = { "V1", "V2" },
        Callback = function(v) Config.KillAuraMode = v end,
})
    
    CombatBox:Slider({
        Title = "Range",
        Rounding = 1,
        Value = {
        Min = 100,
        Max = 5000,
        Default = 5000,
    },
        Callback = function(v) Config.KillAuraRange = v end,
    }) 

    CombatBox:Divider()

    CombatBox:Slider({
        Title = "Damage (V1)",
        Rounding = 1,
        Value = {
        Min = 1000,
        Max = 999999999,
        Default = 999999999,
    },
        Callback = function(v)
            Config.KillAuraDamage = v
        end
    })

    CombatBox:Slider({
        Title = "Multiplier (V2)",
        Rounding = 1,
        Value = {
        Min = 1,
        Max = 100,
        Default = 1,
    },
        Callback = function(v)
            Config.KillAuraV2Multiplier = v
        end
    })

local Autos = MainTab:Section({
      Title = "Auto",
      Icon = "crosshair",
      Opened = true
})

Autos:Toggle({
    Title = "Auto Equip",
    Default = false,
    Callback = function(v) Config.AutoEquip = v end,
})

Autos:Divider()

Autos:Toggle({
    Title = "Auto Buy Weapon",
    Default = false,
    Callback = function(v)
        Config.AutoBuyWeapon = v
        if v then 
    WindUI:Notify({
           Title = "Auto Buy Weapon",
           Content = "Auto Buy Weapon enabled",
           Duration = 2
    })
                end
    end,
})

Autos:Toggle({
    Title = "Auto Buy Health",
    Default = false,
    Callback = function(v)
        Config.AutoBuyHealth = v
        if v then 
    WindUI:Notify({
        Title = "Auto Health",
        Content = "Auto Health Upgrade enabled",
        Duration = 2
    })
                end
    end,
})

Autos:AddToggle({
    Title = "Auto Buy Gear",
    Default = false,
    Callback = function(v)
        Config.AutoBuyGear = v
        if v then
    WindUI:Notify({
        Title = "Auto Buy",
        Content = "Weapon Upgrade enabled",
        Duration = 2
    })
                end
    end,
})

Autos:AddDropdown({
    Title = "Gear Type",
    Default = "AutoTurret",
    Values = {
        "Landmine","LaserTurret","AutoTurret","Barricade","SteelBarricade",
        "FlamethrowerTurret","ShockwaveMine","HealingStation","MendingTower",
        "StimShot","Molotov","VanguardTurret","Cloak","Shuriken","BladeFury",
        "SoulHarvester","RaiseUndead","DeathNova","FragGrenade","Deadeye",
        "TargetMark","Drone","Spikes","Bunker",
    },
    Callback = function(v) Config.SelectedGear = v end,
})

local MiscCombatBox = MainTab:Section({
      Title = "Misc",
      Icon = "star", 
      Opened = true
)}

MiscCombatBox:AddToggle({
    Title = "Auto Skip Wave",
    Default = false,
    Callback = function(v) Config.AutoSkipWave = v end,
})

local Misc = ExtraTab:Section({
      Title = "Miscellaneous",
      Icon = "star",
      Opened = true
)}

Misc:Toggle({
    Title = "Speed Increase",
    Default = false,
    Callback = function(v) Config.SpeedHack = v end,
})
    
    
Misc:Slider({
    Title = "Walk Speed",
    Default = 24,
    Value = {
    Min = 16,
    Max = 200,
    Rounding = 0,
},
    Callback = function(v) Config.SpeedValue = v end,
})
    
Misc:Toggle({
    Title = "Jump Hack",
    Default = false,
    Callback = function(v) Config.JumpHack = v end,
})

Misc:Slider({
    Title = "Jump Power",
    Default = 100,
    Value = {
    Min = 50,
    Max = 500,
    Rounding = 0,
},
    Callback = function(v) Config.JumpValue = v end,
})

Misc:Toggle({
    Title = "Fly",
    Default = false,
    Callback = function(v)
        Config.Fly = v
        if not v then DisableFly() end
    end,
})

Misc:Slider({
    Title = "Fly Speed",
    Default = 50,
    Value = {
    Min = 10,
    Max = 200,
    Rounding = 0,
},
    Callback = function(v) Config.FlySpeed = v end,
})

Misc:Toggle({
    Title = "Noclip",
    Default = false,
    Callback = function(v) Config.Noclip = v end,
})

Misc:Toggle
    Title = "TP Safe Ground",
    Default = false,
    Callback = function(v) Config.TPSafeGround = v end,
})

Misc:Toggle({
    Title = "TP Safe Sky",
    Default = false,
    Callback = function(v)
        Config.TPSafeSky = v
        if not v then
            if SkyOrigPos and RootPart then RootPart.CFrame = CFrame.new(SkyOrigPos) end
            SkyOrigPos = nil
            if SkyPlatform then SkyPlatform:Destroy(); SkyPlatform = nil end
        end
    end,
})

Misc:Toggle({
    Title = "TP Safe Zone V2",
    Default = false,
    Callback = function(v) Config.TPSafeZoneV2 = v end,
})

Misc:Toggle({
    Title = "Zombie ESP",
    Default = false,
    Callback = function(v)
        Config.ZombieESP = v
        RefreshESP()
    end,
})

Misc:Toggle({
    Title = "Player ESP",
    Default = false,
    Callback = function(v)
        Config.PlayerESP = v
        RefreshESP()
    end,
})

Misc:AddDivider()
Misc:AddLabel("Lighting & FPS")

Misc:Toggle({
    Title = "FPS Uncap",
    Default = false,
    Callback = function(v) Config.FPSUncap = v; ApplyFPSSettings() end,
})

Misc:Slider({
    Title = "FPS Cap",
    Default = 60,
    Value = {
    Min = 10,
    Max = 600,
    Rounding = 0,
},
    Callback = function(v)
        Config.FPSCap = v
        if Config.FPSUncap then ApplyFPSSettings() end
    end,
})

Misc:Toggle({
    Title = "Anti AFK",
    Default = false,
    Callback = function(v)
        Config.AntiAFK = v
        if v then
            SetupAntiAFK()
        else
            if AntiAFKIdledConn then AntiAFKIdledConn:Disconnect() end
        end
    end,
})

Misc:Toggle({
    Title = "No Fog",
    Default = false,
    Callback = function(v) Config.NoFog = v; SetNoFog(v) end,
})

Misc:Toggle({
    Title = "Full Bright",
    Default = false,
    Callback = function(v) Config.FullBright = v; SetFullBright(v) end,
})

Misc:Toggle({
    Title = "FPS Booster",
    Default = false,
    Callback = function(v)
        Config.FPSBooster = v
        if v then EnableFPSBooster() else DisableFPSBooster() end
    end,
})

end
LoadMainHub()
