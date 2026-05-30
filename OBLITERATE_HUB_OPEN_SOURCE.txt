local Start = tick()
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local VirtualUser = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")
local GuiService = game:GetService("GuiService")
local StarterGui = game:GetService("StarterGui")
local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")
local isLeftClickHeld = false
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
        isLeftClickHeld = true
    end
end)
UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isLeftClickHeld = false
    end
end)
UserInputService.WindowFocusReleased:Connect(function()
    isLeftClickHeld = false
end)
local NetworkFolder = nil
local packagesIndex = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("_Index")
for i = 1, 10 do
    for _, child in ipairs(packagesIndex:GetChildren()) do
        if child.Name:match("^leifstout_networker") then
            local networkerFolder = child:WaitForChild("networker", 0.2)
            local remotes = networkerFolder and networkerFolder:WaitForChild("_remotes", 0.2)
            if remotes and remotes:FindFirstChild("RollService") then
                NetworkFolder = remotes
                break
            end
        end
    end
    if NetworkFolder then break end
    task.wait(0.2)
end
if not NetworkFolder then
    local highestVersion = nil
    local highestNum = -1
    for _, child in ipairs(packagesIndex:GetChildren()) do
        local verStr = child.Name:match("^leifstout_networker@([%d%.]+)")
        if verStr then
            local major, minor, patch = verStr:match("(%d+)%.(%d+)%.(%d+)")
            if major and minor and patch then
                local num = tonumber(major) * 10000 + tonumber(minor) * 100 + tonumber(patch)
                if num > highestNum then
                    highestNum = num
                    highestVersion = child
                end
            end
        end
    end
    if highestVersion then
        local networkerFolder = highestVersion:WaitForChild("networker", 1)
        NetworkFolder = networkerFolder and networkerFolder:WaitForChild("_remotes", 1)
    end
end
if not NetworkFolder then
    NetworkFolder = packagesIndex:WaitForChild("leifstout_networker@0.3.1"):WaitForChild("networker"):WaitForChild("_remotes")
end
local Services = {
    Roll = NetworkFolder:WaitForChild("RollService"):WaitForChild("RemoteFunction"),
    Loot = NetworkFolder:WaitForChild("LootService"):WaitForChild("RemoteFunction"),
    Rebirth = NetworkFolder:WaitForChild("RebirthService"):WaitForChild("RemoteFunction"),
    Zones = NetworkFolder:WaitForChild("ZonesService"):WaitForChild("RemoteFunction"),
    Inventory = NetworkFolder:WaitForChild("InventoryService"):WaitForChild("RemoteFunction"),
    Upgrade = NetworkFolder:WaitForChild("UpgradeService"):WaitForChild("RemoteFunction"),
    Codes = NetworkFolder:WaitForChild("CodeService"):WaitForChild("RemoteFunction"),
    Boosts = NetworkFolder:WaitForChild("BoostService"):WaitForChild("RemoteFunction"),
    FruitExtractor = NetworkFolder:WaitForChild("FruitExtractorService"):WaitForChild("RemoteFunction"),
    OfflineEarnings = NetworkFolder:WaitForChild("OfflineEarningsService"):WaitForChild("RemoteFunction"),
    Index = NetworkFolder:WaitForChild("IndexService"):WaitForChild("RemoteFunction"),
    Crafting = NetworkFolder:WaitForChild("CraftingService"):WaitForChild("RemoteFunction"),
    XpTransfer = NetworkFolder:WaitForChild("XpTransferService"):WaitForChild("RemoteFunction"),
    SlimeGun = NetworkFolder:WaitForChild("SlimeGunService"):WaitForChild("RemoteFunction"),
    SlimeUpgrade = NetworkFolder:WaitForChild("SlimeUpgradeService"):WaitForChild("RemoteFunction"),
    Tutorial = NetworkFolder:WaitForChild("TutorialService"):WaitForChild("RemoteFunction"),
    LikeGroup = NetworkFolder:WaitForChild("LikeGroupService"):WaitForChild("RemoteEvent"),
    Gameplay = NetworkFolder:WaitForChild("GameplayService"):WaitForChild("RemoteEvent")
}
local Source = ReplicatedStorage:WaitForChild("Source")
local Game = Source:WaitForChild("Game")
local Items = Game:WaitForChild("Items")
local Features = Source:WaitForChild("Features")
local SlimesController = require(Items:WaitForChild("Slimes"))
local EnemiesController = require(Items:WaitForChild("Enemies"))
local RarityTiers = require(Items:WaitForChild("RarityTiers"))
local FoodController = require(Items:WaitForChild("Food"))
local ImageIds = require(Game:WaitForChild("AssetIds"):WaitForChild("ImageIds"))
local LootController = require(Features:WaitForChild("Loot"):WaitForChild("LootServiceClient"))
local ZonesController = require(Items:WaitForChild("Zones"))
local RecipesController = require(Features:WaitForChild("Crafting"):WaitForChild("Recipes"))
local GameplayServiceClient = require(Features:WaitForChild("Gameplay"):WaitForChild("GameplayServiceClient"))
local UfoEventServiceClient = require(Features:WaitForChild("UfoEvent"):WaitForChild("UfoEventServiceClient"))
local DataServiceClient = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("DataService")).client
local InventoryServiceUtils = require(Features:WaitForChild("Inventory"):WaitForChild("InventoryServiceUtils"))
local XpTransferServiceUtils = require(Features:WaitForChild("XpTransfer"):WaitForChild("XpTransferServiceUtils"))
local UpgradeServiceUtils = require(Features:WaitForChild("Upgrades"):WaitForChild("UpgradeServiceUtils"))
local PlayerUpgradeUtils = require(Features:WaitForChild("Upgrades"):WaitForChild("PlayerUpgradeUtils"))
local GoopGunServiceUtils = require(Features:WaitForChild("GoopGun"):WaitForChild("GoopGunServiceUtils"))
local RebirthServiceUtils = require(Features:WaitForChild("Rebirth"):WaitForChild("RebirthServiceUtils"))
local function isBoostActive(boostName)
    local boosts = DataServiceClient:get("boosts")
    if not boosts or not boosts[boostName] then return false end
    local expiration = boosts[boostName].expirationTime or 0
    local serverTime = workspace:GetServerTimeNow() or os.time()
    return expiration > serverTime
end
local function getItemAmount(itemId)
    local items = DataServiceClient:get("items")
    return (items and items[itemId]) or 0
end
local function getEquippedSlimes()
    local equipped = DataServiceClient:get("equipped")
    return equipped or {}
end
local function getArmedSpecialDiceCount()
    local armed = DataServiceClient:get("armedSpecialDice")
    return armed and #armed or 0
end
local SlimeUpgradeTreeNodes = {
    lightning = {
        origin = "lightningOrigin",
        fruit = "lightningFruit",
        nodes = {
            "chainLightning1", "chainLightning2", "chainLightning3", "chainLightning4",
            "lightningBlast1", "lightningBlast2", "lightningBlast3", "lightningBlast4"
        }
    },
    fire = {
        origin = "fireOrigin",
        fruit = "fireFruit",
        nodes = {
            "fireBall1", "fireBall2", "fireBall3", "fireBall4",
            "fireBlast1", "fireBlast2", "fireBlast3", "fireBlast4"
        }
    },
    ice = {
        origin = "iceOrigin",
        fruit = "iceFruit",
        nodes = {
            "frostShard1", "frostShard2", "frostShard3", "frostShard4", "frostShard5", "frostShard6",
            "frostSpike1", "frostSpike2", "frostSpike3", "frostSpike4", "frostSpike5", "frostSpike6"
        }
    },
    sword = {
        origin = "swordOrigin",
        fruit = "swordFruit",
        nodes = {
            "swordSlash1", "swordSlash2", "swordSlash3", "swordSlash4", "swordSlash5", "swordSlash6",
            "skySword1", "skySword2", "skySword3", "skySword4", "skySword5", "skySword6"
        }
    },
    magic = {
        origin = "magicianOrigin",
        fruit = "magicianFruit",
        nodes = {
            "cardThrow1", "cardThrow2", "cardThrow3", "cardThrow4", "cardThrow5", "cardThrow6",
            "bowlingHat1", "bowlingHat2", "bowlingHat3", "bowlingHat4", "bowlingHat5", "bowlingHat6"
        }
    },
    universe = {
        origin = "universeOrigin",
        fruit = "universeFruit",
        nodes = {
            "blackhole1", "blackhole2", "blackhole3", "blackhole4", "blackhole5", "blackhole6",
            "meteor1", "meteor2", "meteor3", "meteor4", "meteor5", "meteor6",
            "ufo1", "ufo2", "ufo3", "ufo4"
        }
    }
}
local Config = {
    AutoRoll = false,
    AutoCollectLoot = false,
    AutoRebirth = false,
    AutoPurchaseZones = false,
    AutoEquipBest = false,
    AutoUpgrades = false,
    RollDelay = 0.1,
    AutoBoostAll = false,
    AutoBoostLuck = false,
    AutoBoostUltraLuck = false,
    AutoBoostCurrency = false,
    AutoBoostRollSpeed = false,
    AutoFeedEquipped = false,
    FeedTargetSlot = "All Team Slimes",
    FeedStopLevel = 10,
    AutoTpBestZone = false,
    AntiAFK = false,
    AutoClaimIndex = false,
    AutoUnlockRecipes = false,
    AutoShootSlimeGun = false,
    AutoFarmSlimes = false,
    AutoCraftSelected = false,
    SelectedCraftRecipe = "crafty",
    AutoTpToCrafting = false,
    AutoUpgradeSlimes = false,
    SlimeUpgradesUseFruits = false,
    AutoTpToUfo = false,
    AutoRejoin = false,
    AutoExtractFruits = false,
    RollAlertSound = false,
    RollAlertWebhook = "",
    RollAlertRarity = 100000,
    RebirthLimit = false,
    MaxRebirthLimit = 50,
    RebirthBoostProtection = false,
    AutoArmJackpot = false,
    AutoArmInverted = false,
    AutoArmShiny = false,
    AutoArmHuge = false,
    AutoArmBig = false,
    AutoPauseSpecialRolls = false,
    ShowLiveFeedHUD = true,
    EfficientFarm = false,
    EfficientFarmMode = "Balanced Progress",
    EfficientFarmBalanceTolerance = 15,
    EfficientFarmPushKillTime = 8,
    EfficientFarmMinGoopPercent = 60
}
local function getCraftingMachinePosition()
    for _, inst in ipairs(CollectionService:GetTagged("CraftingMachine")) do
        local part = inst:FindFirstChild("Root") or inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart", true)
        if part then
            return part.Position, inst
        end
    end
    return nil
end
local function getMachineZoneId(machineInst)
    local cur = machineInst
    while cur do
        if cur:IsA("Model") then
            local zoneNum = tonumber(cur.Name)
            if zoneNum then
                return tostring(zoneNum)
            end
        end
        cur = cur.Parent
    end
    return "1"
end
local function findIngredientsForRecipe(recipeId)
    local recipe = RecipesController.getRecipe(recipeId)
    if not recipe or not recipe.inputs then return nil end
    local inventory = DataServiceClient:get("inventory") or {}
    local equipped = getEquippedSlimes()
    local equippedSet = {}
    for _, uid in ipairs(equipped) do
        equippedSet[uid] = true
    end
    local candidateUids = {}
    local usedSet = {}
    for _, input in ipairs(recipe.inputs) do
        local requiredSlimeId = input.id
        local matchedUid = nil
        for uid, slime in pairs(inventory) do
            if slime.id == requiredSlimeId and not equippedSet[uid] and not usedSet[uid] then
                matchedUid = uid
                break
            end
        end
        if matchedUid then
            table.insert(candidateUids, matchedUid)
            usedSet[matchedUid] = true
        else
            return nil
        end
    end
    return candidateUids
end
local function getTeamDamage()
    local inventory = DataServiceClient:get("inventory") or {}
    local equipped = getEquippedSlimes()
    local totalDmg = 0
    for _, uid in ipairs(equipped) do
        local slime = inventory[uid]
        if slime then
            local stats = InventoryServiceUtils.getSlimeStats(uid, slime)
            if stats and stats.damage then
                totalDmg = totalDmg + stats.damage
            end
        end
    end
    return totalDmg
end
local function resolveSlimeDataFromInventory(uid, inventoryValue)
    if not uid or inventoryValue == nil then
        return nil
    end
    local slimeData = nil
    pcall(function()
        slimeData = InventoryServiceUtils.getSlimeData(uid, inventoryValue)
    end)
    if type(slimeData) == "table" then
        return slimeData
    end
    if type(inventoryValue) == "table" then
        return inventoryValue
    end
    return nil
end
local function getEquippedTeamInfo()
    local inventory = DataServiceClient:get("inventory") or {}
    local equipped = getEquippedSlimes()
    local team = {}
    for slot, equippedEntry in ipairs(equipped) do
        local uid = equippedEntry
        local slime = resolveSlimeDataFromInventory(uid, inventory[uid])
        if type(equippedEntry) == "table" then
            uid = equippedEntry.uid or equippedEntry.uuid or equippedEntry.id or equippedEntry[1] or slot
            slime = resolveSlimeDataFromInventory(uid, inventory[uid]) or equippedEntry
        end
        if type(slime) == "table" then
            local slimeDef = SlimesController.getSlime(slime.id)
            local baseName = slimeDef and slimeDef.name or tostring(slime.id or "Unknown")
            local displayName = baseName
            pcall(function()
                local mutations = require(Features:WaitForChild("Mutations"):WaitForChild("Mutations"))
                displayName = mutations.getDisplayName(baseName, slime.mutations or {})
            end)
            table.insert(team, {
                slot = slot,
                uid = uid,
                name = displayName,
                level = tonumber(slime.level) or 1,
                xp = tonumber(slime.xp) or 0,
            })
        else
            table.insert(team, {
                slot = slot,
                uid = uid,
                name = "Unresolved",
                level = 0,
                xp = 0,
            })
        end
    end
    return team
end
local function getUpgradeData()
    return DataServiceClient:get("upgrades") or {}
end
local ZoneGoopPerKill = {
    [1] = 1,
    [2] = 1,
    [3] = 1,
    [4] = 2,
    [5] = 3,
    [6] = 4,
    [7] = 7,
    [8] = 9,
    [9] = 11,
    [10] = 13,
    [11] = 16,
    [12] = 20,
    [13] = 27,
    [14] = 38,
    [15] = 53,
    [16] = 74,
    [17] = 104,
    [18] = 145,
    [19] = 203,
    [20] = 285,
    [21] = 398,
    [22] = 558,
    [23] = 781,
    [24] = 1093,
    [25] = 1531,
    [26] = 2143,
    [27] = 3000,
    [28] = 4200,
    [29] = 5880,
    [30] = 8233,
    [31] = 11526,
    [32] = 16136,
    [33] = 22590,
    [34] = 31600,
    [35] = 44200,
    [36] = 67100,
    [37] = 86600,
    [38] = 121000,
}
local function getZoneGoopPerKill(zoneId)
    if ZoneGoopPerKill[zoneId] then
        return ZoneGoopPerKill[zoneId]
    end
    local lastKnownZone = 38
    local value = ZoneGoopPerKill[lastKnownZone]
    for _ = lastKnownZone + 1, zoneId do
        value = value * 1.4
    end
    return value
end
local function getNextRebirthInfo()
    local rebirths = DataServiceClient:get("rebirths") or 0
    local goop = DataServiceClient:get("goop") or 0
    local cost = RebirthServiceUtils.getCost(rebirths)
    local needed = math.max(cost - goop, 0)
    return {
        rebirths = rebirths,
        currentGoop = goop,
        cost = cost,
        needed = needed,
    }
end
local LiveFarmStats = {}
local LiveFarmState = {
    lastGoop = nil,
    currentZone = nil,
    zoneStartedAt = nil,
    currentSignature = nil,
}
local function getLiveZoneStats(zoneId, signature)
    signature = signature or "unknown"
    local stats = LiveFarmStats[zoneId]
    if not stats or stats.signature ~= signature then
        LiveFarmStats[zoneId] = {
            signature = signature,
            startedAt = os.clock(),
            lastSeenAt = os.clock(),
            goopGained = 0,
            kills = 0,
            lastKillAt = nil,
        }
    end
    return LiveFarmStats[zoneId]
end
local function resetLiveZoneStats(zoneId, signature)
    LiveFarmStats[zoneId] = {
        signature = signature or LiveFarmState.currentSignature or "unknown",
        startedAt = os.clock(),
        lastSeenAt = os.clock(),
        goopGained = 0,
        kills = 0,
        lastKillAt = nil,
    }
end
local function getMeasuredRatesForZone(zoneId, signature)
    local stats = LiveFarmStats[zoneId]
    if not stats or (signature and stats.signature ~= signature) then
        return nil
    end
    local elapsed = math.max(os.clock() - stats.startedAt, 0.001)
    local goopPerSecond = stats.goopGained / elapsed
    local killsPerSecond = stats.kills / elapsed
    return {
        elapsed = elapsed,
        kills = stats.kills,
        goopGained = stats.goopGained,
        killsPerSecond = killsPerSecond,
        goopPerSecond = goopPerSecond,
        isConfident = elapsed >= 12 and stats.kills >= 3 and stats.goopGained > 0,
    }
end
local function getFarmUpgradeInfo(upgrades)
    local ownsSlimeGun = UpgradeServiceUtils.ownsUpgrade("slimeGun", upgrades)
    local ownsGoop = UpgradeServiceUtils.ownsUpgrade("goop", upgrades)
    local slimeGunDamageLevel = ownsSlimeGun and UpgradeServiceUtils.getUpgradeLevel("slimeGunDamage", upgrades) or 0
    local slimeGunFireRateLevel = ownsSlimeGun and UpgradeServiceUtils.getUpgradeLevel("slimeGunFireRate", upgrades) or 0
    local slimeGunLootLevel = ownsSlimeGun and UpgradeServiceUtils.getUpgradeLevel("slimeGunLoot", upgrades) or 0
    local coinLevel = UpgradeServiceUtils.getUpgradeLevel("coinIncome", upgrades)
    local goopDropLevel = ownsGoop and UpgradeServiceUtils.getUpgradeLevel("goopDropRate", upgrades) or 0
    local doubleGoopLevel = ownsGoop and UpgradeServiceUtils.getUpgradeLevel("doubleGoop", upgrades) or 0
    local enemyCountLevel = UpgradeServiceUtils.getUpgradeLevel("enemyCount", upgrades)
    local enemySpawnSpeedLevel = UpgradeServiceUtils.getUpgradeLevel("enemySpawnSpeed", upgrades)
    return {
        ownsSlimeGun = ownsSlimeGun,
        ownsGoop = ownsGoop,
        slimeGunDamageLevel = slimeGunDamageLevel,
        slimeGunFireRateLevel = slimeGunFireRateLevel,
        slimeGunLootLevel = slimeGunLootLevel,
        coinLevel = coinLevel,
        goopDropLevel = goopDropLevel,
        doubleGoopLevel = doubleGoopLevel,
        enemyCountLevel = enemyCountLevel,
        enemySpawnSpeedLevel = enemySpawnSpeedLevel,
        fireRate = ownsSlimeGun and GoopGunServiceUtils.getFireRate(upgrades) or 0,
        gunDamageMultiplier = ownsSlimeGun and GoopGunServiceUtils.getDamageMultiplier(upgrades) or 0,
        slimeGunLootMultiplier = ownsSlimeGun and UpgradeServiceUtils.getUpgradeValue("slimeGunLoot", slimeGunLootLevel) or 1,
        coinMultiplier = UpgradeServiceUtils.getUpgradeValue("coinIncome", coinLevel) or 1,
        goopDropRate = ownsGoop and UpgradeServiceUtils.getGoopDropRate(upgrades) or 0,
        doubleGoopChance = ownsGoop and UpgradeServiceUtils.getDoubleGoopChance(upgrades) or 0,
        maxEnemies = PlayerUpgradeUtils.getMaxEnemies(upgrades),
        enemySpawnSpeed = UpgradeServiceUtils.getUpgradeValue("enemySpawnSpeed", enemySpawnSpeedLevel) or 1,
    }
end
local function getFarmBuildSignature(teamDmg, upgradeInfo)
    return table.concat({
        tostring(math.floor(teamDmg or 0)),
        upgradeInfo.ownsSlimeGun and "gunY" or "gunN",
        tostring(upgradeInfo.slimeGunDamageLevel or 0),
        tostring(upgradeInfo.slimeGunFireRateLevel or 0),
        tostring(upgradeInfo.slimeGunLootLevel or 0),
        tostring(upgradeInfo.coinLevel or 0),
        upgradeInfo.ownsGoop and "goopY" or "goopN",
        tostring(upgradeInfo.goopDropLevel or 0),
        tostring(upgradeInfo.doubleGoopLevel or 0),
        tostring(upgradeInfo.enemyCountLevel or 0),
        tostring(upgradeInfo.enemySpawnSpeedLevel or 0),
    }, "|")
end
local function getFarmingRatesForZone(zoneId, teamDmg, upgradeInfo, farmSignature)
    local zoneInfo = ZonesController.getZone(zoneId)
    if not (zoneInfo and zoneInfo.enemies and zoneInfo.enemies[1]) then
        return nil
    end
    local enemyInfo = EnemiesController.getEnemyInfo(zoneInfo.enemies[1])
    if not enemyInfo then
        return nil
    end
    local health = enemyInfo.health or 10
    local coinReward = enemyInfo.reward or 0
    local fireRate = upgradeInfo.fireRate
    if not fireRate or fireRate <= 0 then
        fireRate = 0
    end
    local gunDamage = math.max(teamDmg * (upgradeInfo.gunDamageMultiplier or 0), 0)
    local slimeDps = teamDmg / 1.2
    local gunDps = fireRate > 0 and (gunDamage / fireRate) or 0
    local totalDps = math.max(slimeDps + gunDps, 1)
    local timeToKill = fireRate > 0 and math.max(health / totalDps, fireRate) or (health / totalDps)
    local rawKillsPerSecond = 1 / timeToKill
    local maxEnemies = math.max(tonumber(upgradeInfo.maxEnemies) or 1, 1)
    local enemySpawnSpeed = math.max(tonumber(upgradeInfo.enemySpawnSpeed) or 1, 0.1)
    local spawnLimitedKillsPerSecond = maxEnemies * enemySpawnSpeed
    local killsPerSecond = math.min(rawKillsPerSecond, spawnLimitedKillsPerSecond)
    local effectiveTimeToKill = killsPerSecond > 0 and (1 / killsPerSecond) or timeToKill
    local coinMultiplier = upgradeInfo.coinMultiplier
    if not coinMultiplier or coinMultiplier <= 0 then
        coinMultiplier = 1
    end
    local slimeGunLootMultiplier = upgradeInfo.slimeGunLootMultiplier
    if not slimeGunLootMultiplier or slimeGunLootMultiplier <= 0 then
        slimeGunLootMultiplier = 1
    end
    local goopDropRate = upgradeInfo.goopDropRate or 0
    local doubleGoopChance = upgradeInfo.doubleGoopChance or 0
    local expectedGoopPerKill = getZoneGoopPerKill(zoneId) * goopDropRate * (1 + doubleGoopChance)
    local measured = getMeasuredRatesForZone(zoneId, farmSignature)
    local goopPerSecond = expectedGoopPerKill * killsPerSecond
    return {
        zone = zoneId,
        health = health,
        reward = coinReward,
        upgradeInfo = upgradeInfo,
        measured = measured,
        usingMeasured = false,
        timeToKill = effectiveTimeToKill,
        estimatedTimeToKill = timeToKill,
        rawKillsPerSecond = rawKillsPerSecond,
        spawnLimitedKillsPerSecond = spawnLimitedKillsPerSecond,
        killsPerSecond = killsPerSecond,
        estimatedKillsPerSecond = killsPerSecond,
        coinsPerSecond = coinReward * coinMultiplier * slimeGunLootMultiplier * killsPerSecond,
        estimatedCoinsPerSecond = coinReward * coinMultiplier * slimeGunLootMultiplier * killsPerSecond,
        goopPerKill = expectedGoopPerKill,
        estimatedGoopPerSecond = expectedGoopPerKill * killsPerSecond,
        goopPerSecond = goopPerSecond,
    }
end
local function getOptimalFarmingZone()
    local maxZone = math.max(
        tonumber(DataServiceClient:get("maxZone")) or 1,
        tonumber(DataServiceClient:get("furthestZone")) or 1,
        tonumber(DataServiceClient:get("zone")) or 1
    )
    local teamDmg = getTeamDamage()
    if teamDmg <= 0 then teamDmg = 1 end
    local upgrades = getUpgradeData()
    local upgradeInfo = getFarmUpgradeInfo(upgrades)
    local farmSignature = getFarmBuildSignature(teamDmg, upgradeInfo)
    LiveFarmState.currentSignature = farmSignature
    local rebirthInfo = getNextRebirthInfo()
    local candidates = {}
    for z = 1, maxZone do
        pcall(function()
            local rates = getFarmingRatesForZone(z, teamDmg, upgradeInfo, farmSignature)
            if rates then
                table.insert(candidates, rates)
            end
        end)
    end
    local eligibleFastestKill = 0
    local eligibleFastestCoins = 0
    local maxRates = {
        kill = nil,
        coins = nil,
        goop = nil,
    }
    for _, rates in ipairs(candidates) do
        eligibleFastestKill = math.max(eligibleFastestKill, rates.killsPerSecond)
        eligibleFastestCoins = math.max(eligibleFastestCoins, rates.coinsPerSecond)
        if not maxRates.kill or rates.killsPerSecond > maxRates.kill.killsPerSecond then
            maxRates.kill = rates
        end
        if not maxRates.coins or rates.coinsPerSecond > maxRates.coins.coinsPerSecond then
            maxRates.coins = rates
        end
        if not maxRates.goop or rates.goopPerSecond > maxRates.goop.goopPerSecond then
            maxRates.goop = rates
        end
    end
    local best, bestScore = nil, -1
    for _, rates in ipairs(candidates) do
        local score = rates.goopPerSecond
        if score <= 0 then
            local killScore = eligibleFastestKill > 0 and rates.killsPerSecond / eligibleFastestKill or 0
            local coinScore = eligibleFastestCoins > 0 and rates.coinsPerSecond / eligibleFastestCoins or 0
            score = (killScore * 0.8) + (coinScore * 0.2)
        end
        rates.efficiencyScore = score
        rates.rebirthEtaSeconds = rates.goopPerSecond > 0 and (rebirthInfo.needed / rates.goopPerSecond) or math.huge
        if score > bestScore then
            bestScore = score
            best = rates
        end
    end
    if not best then
        table.sort(candidates, function(a, b)
            return a.timeToKill < b.timeToKill
        end)
        best = candidates[1]
        maxRates.kill = maxRates.kill or best
        maxRates.coins = maxRates.coins or best
        maxRates.goop = maxRates.goop or best
    end
    if best and not best.rebirthEtaSeconds then
        best.rebirthEtaSeconds = best.goopPerSecond > 0 and (rebirthInfo.needed / best.goopPerSecond) or math.huge
    end
    local mode = Config.EfficientFarmMode or "Balanced Progress"
    local selected = best
    local modeNote = "Goop"
    local topGoop = maxRates.goop and maxRates.goop.goopPerSecond or 0
    local balanceTolerance = math.clamp((tonumber(Config.EfficientFarmBalanceTolerance) or 15) / 100, 0, 1)
    local minGoopPercent = math.clamp((tonumber(Config.EfficientFarmMinGoopPercent) or 60) / 100, 0, 1)
    local pushKillTime = math.max(tonumber(Config.EfficientFarmPushKillTime) or 8, 0.1)
    if mode == "Balanced Progress" then
        local floorGoop = topGoop * (1 - balanceTolerance)
        modeNote = ("Balanced %d%%"):format(math.floor((Config.EfficientFarmBalanceTolerance or 15) + 0.5))
        for _, rates in ipairs(candidates) do
            if rates.goopPerSecond >= floorGoop and (not selected or rates.zone > selected.zone) then
                selected = rates
            end
        end
    elseif mode == "Push Highest Zone" then
        modeNote = "Highest"
        for _, rates in ipairs(candidates) do
            if not selected or rates.zone > selected.zone then
                selected = rates
            end
        end
    elseif mode == "Highest Fast Zone" then
        modeNote = ("Fast %.1fs"):format(pushKillTime)
        selected = nil
        for _, rates in ipairs(candidates) do
            if rates.timeToKill <= pushKillTime and (not selected or rates.zone > selected.zone) then
                selected = rates
            end
        end
        selected = selected or best
    elseif mode == "Newest Good Goop" then
        local floorGoop = topGoop * minGoopPercent
        modeNote = ("Newest %d%%G"):format(math.floor((Config.EfficientFarmMinGoopPercent or 60) + 0.5))
        selected = nil
        for _, rates in ipairs(candidates) do
            if rates.goopPerSecond >= floorGoop and (not selected or rates.zone > selected.zone) then
                selected = rates
            end
        end
        selected = selected or best
    elseif mode == "Coin Farm" then
        modeNote = "Coins"
        selected = maxRates.coins or best
    elseif mode == "Kill Speed" then
        modeNote = "Kills"
        selected = maxRates.kill or best
    elseif mode == "Rebirth Sprint" then
        modeNote = "Rebirth"
        selected = maxRates.goop or best
    else
        modeNote = "Goop"
        selected = maxRates.goop or best
    end
    if selected and not selected.rebirthEtaSeconds then
        selected.rebirthEtaSeconds = selected.goopPerSecond > 0 and (rebirthInfo.needed / selected.goopPerSecond) or math.huge
    end
    if selected then
        selected.modeNote = modeNote
    end
    return selected and selected.zone or 1, selected, maxRates, rebirthInfo
end
local isTeleporting = false
local function teleportToZone(zoneId)
    if isTeleporting then return false, "Already teleporting" end
    isTeleporting = true
    local success, err
    pcall(function()
        local character = LocalPlayer.Character
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            rootPart.Anchored = false
        end
        success, err = Services.Zones:InvokeServer("requestTeleportZone", zoneId)
        if success then
            local start = tick()
            while tick() - start < 3 do
                if DataServiceClient:get("zone") == zoneId then
                    break
                end
                task.wait(0.1)
            end
            task.wait(0.5)
        end
    end)
    isTeleporting = false
    return success, err
end
local Library = nil
local ThemeManager = nil
local SaveManager = nil
if not getgenv().syn then
    getgenv().syn = {
        protect_gui = function() end
    }
end
if not getgenv().iswindowactive then
    getgenv().iswindowactive = function() return true end
end
if not getgenv().keypress then
    getgenv().keypress = function() end
end
if not getgenv().keyrelease then
    getgenv().keyrelease = function() end
end
local successLib, resLib = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/wally-rblx/LinoriaLib/main/Library.lua"))()
end)
if successLib and resLib then
    Library = resLib
else
    local successLib2, resLib2 = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua"))()
    end)
    if successLib2 and resLib2 then
        Library = resLib2
    end
end
if not Library then
    error("Failed to load Linoria UI Library! All fallbacks failed.")
end
local successTheme, resTheme = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/wally-rblx/LinoriaLib/main/addons/ThemeManager.lua"))()
end)
if successTheme and resTheme then
    ThemeManager = resTheme
else
    ThemeManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/addons/ThemeManager.lua"))()
end
local successSave, resSave = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/wally-rblx/LinoriaLib/main/addons/SaveManager.lua"))()
end)
if successSave and resSave then
    SaveManager = resSave
else
    SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/addons/SaveManager.lua"))()
end
local NotificationCooldowns = {}
local function notifyOnce(key, message, duration, cooldown)
    local now = tick()
    cooldown = cooldown or 10
    if not NotificationCooldowns[key] or now - NotificationCooldowns[key] >= cooldown then
        NotificationCooldowns[key] = now
        Library:Notify(message, duration or 3)
    end
end
local ToggleConfigKeys = {
    AutoTpToUfoToggle = "AutoTpToUfo",
    AutoTpBestZoneToggle = "AutoTpBestZone",
    AutoFarmSlimesToggle = "AutoFarmSlimes",
    EfficientFarmToggle = "EfficientFarm",
    AutoTpToCraftingToggle = "AutoTpToCrafting",
}
local ToggleConflicts = {
    AutoTpToUfoToggle = { "AutoFarmSlimesToggle", "EfficientFarmToggle", "AutoTpToCraftingToggle" },
    AutoTpBestZoneToggle = { "EfficientFarmToggle", "AutoTpToCraftingToggle" },
    AutoFarmSlimesToggle = { "EfficientFarmToggle", "AutoTpToUfoToggle", "AutoTpBestZoneToggle", "AutoTpToCraftingToggle" },
    EfficientFarmToggle = { "AutoFarmSlimesToggle", "AutoTpToUfoToggle", "AutoTpBestZoneToggle", "AutoTpToCraftingToggle" },
    AutoTpToCraftingToggle = { "AutoTpToUfoToggle", "AutoTpBestZoneToggle", "AutoFarmSlimesToggle", "EfficientFarmToggle" },
}
local function setToggleValue(toggleName, value)
    local toggle = Toggles and Toggles[toggleName]
    if toggle and toggle.Value ~= value then
        local ok = pcall(function()
            toggle:SetValue(value)
        end)
        return ok
    end
    return false
end
local function applyToggleConflicts(enabledToggle)
    for _, otherToggle in ipairs(ToggleConflicts[enabledToggle] or {}) do
        local configKey = ToggleConfigKeys[otherToggle]
        if configKey and Config[configKey] then
            Config[configKey] = false
            setToggleValue(otherToggle, false)
            notifyOnce(
                "conflict_" .. enabledToggle .. "_" .. otherToggle,
                "Disabled a conflicting teleport/farm option.",
                3,
                2
            )
        end
    end
end
local function getUnlockedZone()
    return tonumber(DataServiceClient:get("maxZone")) or tonumber(DataServiceClient:get("zone")) or 1
end
local function isZoneUnlocked(zoneId)
    zoneId = tonumber(zoneId)
    if not zoneId then
        return true
    end
    return getUnlockedZone() >= zoneId
end
local function getActiveUfoZone()
    local state = UfoEventServiceClient and UfoEventServiceClient.state
    return state and tonumber(state.zoneId) or nil
end
local function getUnlockedUfoDropPosition()
    local ufoZone = getActiveUfoZone()
    if not ufoZone or not isZoneUnlocked(ufoZone) then
        return nil, ufoZone
    end
    local ok, pos = pcall(function()
        return UfoEventServiceClient:getItemDropPosition()
    end)
    if ok and pos then
        return pos, ufoZone
    end
    return nil, ufoZone
end
local function getFriendStatus(player)
    local ok, status = pcall(function()
        return LocalPlayer:GetFriendStatus(player)
    end)
    return ok and status or nil
end
local function shouldPromptFriendRequest(player)
    if not player or player == LocalPlayer then
        return false
    end
    local isFriend = false
    pcall(function()
        isFriend = LocalPlayer:IsFriendsWithAsync(player.UserId)
    end)
    if isFriend then
        return false
    end
    local status = getFriendStatus(player)
    if status == Enum.FriendStatus.Friend
        or status == Enum.FriendStatus.FriendRequestSent
        or status == Enum.FriendStatus.FriendRequestReceived then
        return false
    end
    return true
end
local function promptFriendRequest(player)
    for _ = 1, 30 do
        local ok = pcall(function()
            StarterGui:SetCore("PromptSendFriendRequest", player)
        end)
        if ok then
            return true
        end
        task.wait(0.1)
    end
    return false
end
local Window = Library:CreateWindow({
    Title = "OBLITERATE Hub | Slime RNG",
    Center = true,
    AutoShow = false
})
local mainToggle = Library.Toggle
local RollFeedWindow = Library:CreateWindow({
    Title = "OBLITERATE | ROLL LIVE FEED",
    Size = UDim2.fromOffset(340, 220),
    Position = UDim2.new(0.8, -350, 0.05, 0),
    AutoShow = false
})
local sig = table.remove(Library.Signals)
if sig then
    sig:Disconnect()
end
Library.Toggle = mainToggle
local RollFeedTab = RollFeedWindow:AddTab("Roll Feed")
local HUDGroupBox = RollFeedTab:AddLeftGroupbox("Live Roll Feed")
local LeftSideScroll = HUDGroupBox.Container.Parent.Parent.Parent
if LeftSideScroll and LeftSideScroll:IsA("ScrollingFrame") then
    LeftSideScroll.Size = UDim2.new(1, -14, 1, -16)
end
local HUDLabels = {}
for i = 1, 5 do
    HUDLabels[i] = HUDGroupBox:AddLabel("Roll #" .. i .. ": Waiting...")
end
task.spawn(Library.Toggle)
RollFeedWindow.Holder.Visible = Config.ShowLiveFeedHUD
local Tabs = {
    Farming = Window:AddTab("Farming"),
    Progression = Window:AddTab("Progression"),
    Inventory = Window:AddTab("Inventory"),
    Combat = Window:AddTab("Combat"),
    Database = Window:AddTab("Database"),
    ["UI Settings"] = Window:AddTab("Settings")
}
local function addImageCard(groupbox, options)
    options = options or {}
    local container = groupbox.Container
    local height = options.Height or 62
    local frame = Instance.new("Frame")
    frame.Name = options.Name or "PremiumImageCard"
    frame.BackgroundColor3 = Color3.fromRGB(22, 22, 31)
    frame.BorderSizePixel = 0
    frame.Size = UDim2.new(1, -4, 0, height)
    frame.ZIndex = 5
    frame.Parent = container
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 5)
    corner.Parent = frame
    local stroke = Instance.new("UIStroke")
    stroke.Color = options.StrokeColor or Color3.fromRGB(105, 92, 180)
    stroke.Transparency = 0.22
    stroke.Thickness = 1
    stroke.Parent = frame
    local image = Instance.new("ImageLabel")
    image.Name = "Icon"
    image.BackgroundTransparency = 1
    image.Image = options.Image or ""
    image.ScaleType = Enum.ScaleType.Fit
    image.Size = UDim2.fromOffset(height - 14, height - 14)
    image.Position = UDim2.fromOffset(7, 7)
    image.ZIndex = 6
    image.Parent = frame
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.BackgroundTransparency = 1
    title.Font = Library.Font or Enum.Font.Code
    title.Text = options.Title or ""
    title.TextColor3 = options.TitleColor or Color3.fromRGB(235, 235, 255)
    title.TextSize = 14
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextTruncate = Enum.TextTruncate.AtEnd
    title.Size = UDim2.new(1, -height - 10, 0, 20)
    title.Position = UDim2.fromOffset(height, 8)
    title.ZIndex = 6
    title.Parent = frame
    local caption = Instance.new("TextLabel")
    caption.Name = "Caption"
    caption.BackgroundTransparency = 1
    caption.Font = Library.Font or Enum.Font.Code
    caption.Text = options.Caption or ""
    caption.TextColor3 = options.CaptionColor or Color3.fromRGB(150, 235, 218)
    caption.TextSize = 12
    caption.TextXAlignment = Enum.TextXAlignment.Left
    caption.TextWrapped = true
    caption.Size = UDim2.new(1, -height - 10, 1, -30)
    caption.Position = UDim2.fromOffset(height, 28)
    caption.ZIndex = 6
    caption.Parent = frame
    pcall(function()
        groupbox:AddBlank(5)
        groupbox:Resize()
    end)
    return {
        Frame = frame,
        Image = image,
        Title = title,
        Caption = caption,
        Set = function(_, newImage, newTitle, newCaption)
            image.Image = newImage or image.Image
            title.Text = newTitle or title.Text
            caption.Text = newCaption or caption.Text
        end
    }
end
local Mutations = require(Features:WaitForChild("Mutations"):WaitForChild("Mutations"))
local InventoryServiceUtils = require(Features:WaitForChild("Inventory"):WaitForChild("InventoryServiceUtils"))
local Abbreviate = require(ReplicatedStorage:WaitForChild("Source"):WaitForChild("Core"):WaitForChild("UI"):WaitForChild("Abbreviate"))
local CoreRollBox = Tabs.Farming:AddLeftGroupbox("Roll Automation")
addImageCard(CoreRollBox, {
    Image = ImageIds.dice,
    Title = "Roll Engine",
    Caption = "Auto roll, luck checks, and rare-roll routing",
    StrokeColor = Color3.fromRGB(120, 98, 230),
})
local RollHistory = {}
local RollFeedHudBox = Tabs.Farming:AddLeftGroupbox("Live Feed HUD")
addImageCard(RollFeedHudBox, {
    Image = ImageIds.bonusRoll,
    Title = "Live Feed",
    Caption = "Recent rolls with rarity color highlights",
    StrokeColor = Color3.fromRGB(80, 185, 210),
})
RollFeedHudBox:AddToggle("ShowLiveFeedHUDToggle", {
    Text = "Show Live Feed HUD",
    Default = true,
    Tooltip = "Toggles visibility of the independent floating Live Feed window",
    Callback = function(Value)
        Config.ShowLiveFeedHUD = Value
        if RollFeedWindow and RollFeedWindow.Holder then
            RollFeedWindow.Holder.Visible = Value
        end
    end
})
local RollAlertBox = Tabs.Farming:AddLeftGroupbox("Roll Alerts")
RollAlertBox:AddToggle("RollAlertSoundToggle", {
    Text = "Sound Alert",
    Default = false,
    Tooltip = "Play a warning alarm sound locally when a rare roll occurs",
    Callback = function(Value)
        Config.RollAlertSound = Value
    end
})
RollAlertBox:AddInput("RollAlertRarityInputBox", {
    Default = "100000",
    Numeric = true,
    Finished = true,
    Text = "Alert Rarity Threshold",
    Tooltip = "Type a threshold (e.g. 100000 for 1 in 100K). Rolls rarer than this trigger alerts.",
    Callback = function(Value)
        local num = tonumber(Value)
        if num then
            Config.RollAlertRarity = num
        end
    end
})
RollAlertBox:AddInput("RollAlertWebhookInputBox", {
    Default = "",
    Numeric = false,
    Finished = true,
    Text = "Discord Webhook URL",
    Placeholder = "https://discord.com/api/webhooks/...",
    Tooltip = "Send webhook post notification for rare rolls",
    Callback = function(Value)
        Config.RollAlertWebhook = Value
    end
})
local function handleNewRoll(slime)
    if not slime or not slime.id then return end
    local slimeDef = SlimesController.getSlime(slime.id)
    if not slimeDef then return end
    local slimeName = slimeDef.name
    local displayName = slimeName
    pcall(function()
        displayName = Mutations.getDisplayName(slimeName, slime.mutations or {})
    end)
    local rarityText = "1/1"
    local rarityVal = 1
    pcall(function()
        local slimeData = {
            id = slime.id,
            mutations = slime.mutations or {},
            level = 1,
            xp = 0
        }
        rarityVal = InventoryServiceUtils.getRarity(slimeData)
        rarityText = "1 / " .. Abbreviate(math.ceil(rarityVal))
    end)
    local tier = nil
    pcall(function()
        tier = RarityTiers.getTier(1 / rarityVal)
    end)
    table.insert(RollHistory, 1, {
        displayName = displayName,
        rarityText = rarityText,
        tier = tier
    })
    if #RollHistory > 5 then
        table.remove(RollHistory, 6)
    end
    for i = 1, 5 do
        local roll = RollHistory[i]
        local label = HUDLabels[i]
        if label then
            local textLabel = label.TextLabel
            if roll then
                local tierName = roll.tier and roll.tier.name or "Basic"
                label:SetText(string.format("Roll #%d: [%s] %s - %s", i, tierName, roll.displayName, roll.rarityText))
                local uiGradient = textLabel:FindFirstChildWhichIsA("UIGradient")
                if roll.tier and roll.tier.gradient then
                    if not uiGradient then
                        uiGradient = Instance.new("UIGradient")
                        uiGradient.Parent = textLabel
                    end
                    uiGradient.Color = roll.tier.gradient
                    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                else
                    if uiGradient then
                        uiGradient:Destroy()
                    end
                    textLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
                end
            else
                label:SetText("Roll #" .. i .. ": Waiting...")
                local uiGradient = textLabel:FindFirstChildWhichIsA("UIGradient")
                if uiGradient then
                    uiGradient:Destroy()
                end
                textLabel.TextColor3 = Color3.fromRGB(150, 150, 160)
            end
        end
    end
    pcall(function()
        if rarityVal >= Config.RollAlertRarity then
            if Config.RollAlertSound then
                task.spawn(function()
                    local SoundController = require(ReplicatedStorage:WaitForChild("Source"):WaitForChild("Core"):WaitForChild("Platform"):WaitForChild("SoundController"))
                    local Sounds = require(ReplicatedStorage:WaitForChild("Source"):WaitForChild("Game"):WaitForChild("AssetIds"):WaitForChild("Sounds"))
                    if SoundController and Sounds then
                        SoundController:Play(Sounds.misc.serverBoost)
                    end
                end)
            end
            if Config.RollAlertWebhook ~= "" then
                task.spawn(function()
                    local request = (syn and syn.request) or http_request or request or http.request
                    if request then
                        local payload = {
                            embeds = {
                                {
                                    title = "🎉 Rare Slime Rolled!",
                                    color = 16762880,
                                    fields = {
                                        { name = "Slime", value = tostring(displayName), inline = true },
                                        { name = "Odds", value = "1 in " .. Abbreviate(math.ceil(rarityVal)), inline = true },
                                        { name = "Player", value = tostring(LocalPlayer.Name), inline = true }
                                    },
                                    timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
                                }
                            }
                        }
                        pcall(function()
                            request({
                                Url = Config.RollAlertWebhook,
                                Method = "POST",
                                Headers = { ["Content-Type"] = "application/json" },
                                Body = game:GetService("HttpService"):JSONEncode(payload)
                            })
                        end)
                    end
                end)
            end
        end
    end)
end
CoreRollBox:AddToggle("AutoRollToggle", {
    Text = "Auto Roll Slimes",
    Default = false,
    Tooltip = "Enable/disable automatic rolling of slimes",
    Callback = function(Value)
        Config.AutoRoll = Value
    end
})
CoreRollBox:AddSlider("RollDelaySlider", {
    Text = "Roll Delay (ms)",
    Default = 10,
    Min = 5,
    Max = 100,
    Rounding = 1,
    Suffix = "ms",
    Compact = false,
    Callback = function(Value)
        Config.RollDelay = Value / 100
    end
})
CoreRollBox:AddToggle("AutoEquipBestToggle", {
    Text = "Auto Equip Best",
    Default = false,
    Tooltip = "Automatically equip the strongest slimes from inventory",
    Callback = function(Value)
        Config.AutoEquipBest = Value
    end
})
CoreRollBox:AddToggle("AutoPauseSpecialRollsToggle", {
    Text = "Smart Special Roll Manager",
    Default = false,
    Tooltip = "Automatically pauses Special Rolls when no luck boosts are active",
    Callback = function(Value)
        Config.AutoPauseSpecialRolls = Value
    end
})
local FarmingCollectBox = Tabs.Farming:AddRightGroupbox("Collection")
addImageCard(FarmingCollectBox, {
    Image = ImageIds.lootIcon,
    Title = "Loot Stream",
    Caption = "Coins, fruit, drops, goop, and rebirth flow",
    StrokeColor = Color3.fromRGB(105, 210, 120),
})
FarmingCollectBox:AddToggle("AutoCollectLootToggle", {
    Text = "Auto Loot Vacuum",
    Default = false,
    Tooltip = "Automatically vacuum all spawned items, coins, and fruit drops",
    Callback = function(Value)
        Config.AutoCollectLoot = Value
    end
})
FarmingCollectBox:AddToggle("AutoTpToUfoToggle", {
    Text = "Auto TP to UFO",
    Default = false,
    Tooltip = "Automatically teleport below active alien UFO drops",
    Callback = function(Value)
        if Value then
            local ufoZone = getActiveUfoZone()
            if ufoZone and not isZoneUnlocked(ufoZone) then
                setToggleValue("AutoTpToUfoToggle", false)
                Config.AutoTpToUfo = false
                notifyOnce("ufo_zone_locked_toggle", ("UFO is in Zone %d, but your best unlocked zone is %d."):format(ufoZone, getUnlockedZone()), 4, 5)
                return
            end
            applyToggleConflicts("AutoTpToUfoToggle")
        end
        Config.AutoTpToUfo = Value
        if Value then
            Library:Notify("Auto UFO Teleporter: Active beneath active drop zones!", 3.5)
        end
    end
})
FarmingCollectBox:AddToggle("AutoRebirthToggle", {
    Text = "Auto Rebirth Player",
    Default = false,
    Tooltip = "Automatically rebirth whenever requirements are satisfied",
    Callback = function(Value)
        Config.AutoRebirth = Value
    end
})
FarmingCollectBox:AddToggle("AntiAFKToggle", {
    Text = "Anti-AFK (Prevent Kick)",
    Default = false,
    Tooltip = "Prevent getting kicked for idling",
    Callback = function(Value)
        Config.AntiAFK = Value
        if Value then
            Library:Notify("Anti-AFK Enabled: Idle detection bypassed!", 4)
        end
    end
})
FarmingCollectBox:AddToggle("RebirthLimitToggle", {
    Text = "Limit Rebirths",
    Default = false,
    Tooltip = "Stop auto rebirthing once target rebirths count is achieved",
    Callback = function(Value)
        Config.RebirthLimit = Value
    end
})
FarmingCollectBox:AddInput("MaxRebirthsInputBox", {
    Default = "50",
    Numeric = true,
    Finished = true,
    Text = "Max Rebirths Limit",
    Tooltip = "Input your maximum target rebirths count",
    Callback = function(Value)
        local num = tonumber(Value)
        if num then
            Config.MaxRebirthLimit = num
        end
    end
})
FarmingCollectBox:AddToggle("RebirthBoostProtectionToggle", {
    Text = "Protect Active Boosts",
    Default = false,
    Tooltip = "Pause Auto Rebirth if you have any active temporary luck or speed boosters running",
    Callback = function(Value)
        Config.RebirthBoostProtection = Value
    end
})
local AutoProgressionBox = Tabs.Progression:AddLeftGroupbox("Progression")
addImageCard(AutoProgressionBox, {
    Image = ImageIds.rebirth,
    Title = "Rebirth Route",
    Caption = "Goop target, upgrades, and zone advancement",
    StrokeColor = Color3.fromRGB(170, 115, 245),
})
AutoProgressionBox:AddToggle("AutoPurchaseZonesToggle", {
    Text = "Auto Buy Zones",
    Default = false,
    Tooltip = "Automatically buy subsequent map zones when affordable",
    Callback = function(Value)
        Config.AutoPurchaseZones = Value
    end
})
AutoProgressionBox:AddToggle("AutoTpBestZoneToggle", {
    Text = "Auto TP Best Zone",
    Default = false,
    Tooltip = "Automatically teleport to your highest unlocked zone",
    Callback = function(Value)
        if Value then
            applyToggleConflicts("AutoTpBestZoneToggle")
        end
        Config.AutoTpBestZone = Value
    end
})
AutoProgressionBox:AddToggle("AutoUpgradesToggle", {
    Text = "Auto Buy Upgrades",
    Default = false,
    Tooltip = "Automatically upgrade luck, inventory size, backpack, and speed",
    Callback = function(Value)
        Config.AutoUpgrades = Value
    end
})
local ManualTeleportBox = Tabs.Progression:AddLeftGroupbox("Zone Teleport")
addImageCard(ManualTeleportBox, {
    Image = ImageIds.teleporter,
    Title = "Zone Network",
    Caption = "Jump directly to unlocked farming zones",
    StrokeColor = Color3.fromRGB(85, 170, 255),
})
local TeleportOptions = {}
local ZoneMap = {}
for i = 1, ZonesController.getMaxZone() do
    local zone = ZonesController.getZone(i)
    table.insert(TeleportOptions, zone.name)
    ZoneMap[zone.name] = zone.id or i
end
ManualTeleportBox:AddDropdown("TeleportZoneDropdown", {
    Values = TeleportOptions,
    Default = "Grasslands",
    Multi = false,
    Text = "Teleport Zone",
    Callback = function(Value)
        local zoneIndex = ZoneMap[Value]
        if zoneIndex then
            task.spawn(function()
                local success, err = teleportToZone(zoneIndex)
                if success then
                    Library:Notify("Teleported! Successfully teleported to " .. Value, 3)
                else
                    Library:Notify("Teleport Failed: " .. (err or "Zone locked!"), 3)
                end
            end)
        end
    end
})
local ShortcutsBox = Tabs.Progression:AddRightGroupbox("Shortcuts")
ShortcutsBox:AddButton({
    Text = "Skip Tutorial",
    Func = function()
        task.spawn(function()
            local steps = {
                "init", "firstRoll", "rollCompleted", "enemySpawned", "enemyKilled",
                "secondRoll", "secondRollCompleted", "thirdRoll", "thirdRollCompleted",
                "openUpgrades", "buyBackpackUpgrade", "closeUpgrades", "openBackpack",
                "equipBetterSlime", "closeBackpack", "earnCoins200", "openUpgradeForAuto",
                "buyAutoUpgrade", "closeUpgradeForAuto", "earnCoins400", "unlockZone2"
            }
            Library:Notify("Bypassing Tutorial via validation sequence simulation...", 3.5)
            for _, step in ipairs(steps) do
                Services.Tutorial:InvokeServer("requestAdvanceStep", step)
                task.wait(0.08)
            end
            Library:Notify("Tutorial Skipped! All game modes and zones are fully unlocked!", 4.5)
        end)
    end,
    DoubleClick = false,
    Tooltip = "Bypasses the introductory tutorial instantly"
})
ShortcutsBox:AddButton({
    Text = "Claim Group Luck",
    Func = function()
        task.spawn(function()
            Services.LikeGroup:FireServer("requestConfirmPrompt")
            Library:Notify("Permanent Group Luck Boost verified on server side.", 4)
        end)
    end,
    DoubleClick = false,
    Tooltip = "Verify server group link to claim a permanent luck boost"
})
local SlimeFeedingBox = Tabs.Inventory:AddLeftGroupbox("Feeding & XP")
addImageCard(SlimeFeedingBox, {
    Image = ImageIds.snackPack,
    Title = "Feed Loadout",
    Caption = "XP, food routing, and equipped slime growth",
    StrokeColor = Color3.fromRGB(245, 175, 90),
})
local refreshFeedTargets
SlimeFeedingBox:AddToggle("AutoFeedEquippedToggle", {
    Text = "Auto Feed Equipped",
    Default = false,
    Tooltip = "Automatically feeds equipped slimes utilizing standard inventory food items",
    Callback = function(Value)
        Config.AutoFeedEquipped = Value
        if Value then
            refreshFeedTargets()
        end
    end
})
local FeedTargetMap = {
    ["All Team Slimes"] = { mode = "all" }
}
local TeamCountLabel = SlimeFeedingBox:AddLabel("Team: scanning...")
local TeamPreviewLabel = SlimeFeedingBox:AddLabel("Equipped: none", true)
SlimeFeedingBox:AddDropdown("FeedTargetDropdown", {
    Values = { "All Team Slimes" },
    Default = "All Team Slimes",
    Multi = false,
    Text = "Feed Target",
    Tooltip = "Choose all equipped slimes or one exact slime currently on your team.",
    Callback = function(Value)
        Config.FeedTargetSlot = Value
    end
})
refreshFeedTargets = function()
    local team = getEquippedTeamInfo()
    local values = { "All Team Slimes" }
    FeedTargetMap = {
        ["All Team Slimes"] = { mode = "all" }
    }
    local preview = {}
    for _, entry in ipairs(team) do
        if entry.name ~= "Empty" then
            local label = ("Slot %d - %s (Lv %d)"):format(entry.slot, entry.name, entry.level)
            table.insert(values, label)
            table.insert(preview, ("S%d %s L%d"):format(entry.slot, entry.name, entry.level))
            FeedTargetMap[label] = {
                mode = "uid",
                uid = entry.uid,
                slot = entry.slot,
            }
        end
    end
    if Options.FeedTargetDropdown and Options.FeedTargetDropdown.SetValues then
        pcall(function()
            Options.FeedTargetDropdown:SetValues(values)
        end)
    end
    if not FeedTargetMap[Config.FeedTargetSlot] then
        Config.FeedTargetSlot = "All Team Slimes"
        if Options.FeedTargetDropdown then
            pcall(function()
                Options.FeedTargetDropdown:SetValue("All Team Slimes")
            end)
        end
    end
    TeamCountLabel:SetText(("Team: %d equipped"):format(#preview))
    TeamPreviewLabel:SetText(#preview > 0 and ("Equipped: " .. table.concat(preview, " | ")) or "Equipped: none")
end
SlimeFeedingBox:AddButton({
    Text = "Refresh Team Feed List",
    Func = function()
        refreshFeedTargets()
        Library:Notify("Team feed list refreshed.", 2.5)
    end,
    DoubleClick = false,
    Tooltip = "Rescans equipped slimes and updates the feed target dropdown."
})
SlimeFeedingBox:AddInput("FeedStopLevelInputBox", {
    Default = "10",
    Numeric = true,
    Finished = true,
    Text = "Stop Feeding At Level",
    Tooltip = "Auto feed skips slimes at or above this level.",
    Callback = function(Value)
        local num = tonumber(Value)
        if num then
            Config.FeedStopLevel = math.max(1, math.floor(num))
        end
    end
})
task.defer(refreshFeedTargets)
SlimeFeedingBox:AddToggle("AutoArmJackpotToggle", {
    Text = "Auto Arm Jackpot Spins",
    Default = false,
    Tooltip = "Automatically arms Jackpot Spins from inventory",
    Callback = function(Value)
        Config.AutoArmJackpot = Value
    end
})
SlimeFeedingBox:AddToggle("AutoArmInvertedToggle", {
    Text = "Auto Arm Inverted Dice",
    Default = false,
    Tooltip = "Automatically arms Inverted Dice from inventory",
    Callback = function(Value)
        Config.AutoArmInverted = Value
    end
})
SlimeFeedingBox:AddToggle("AutoArmShinyToggle", {
    Text = "Auto Arm Shiny Dice",
    Default = false,
    Tooltip = "Automatically arms Shiny Dice from inventory",
    Callback = function(Value)
        Config.AutoArmShiny = Value
    end
})
SlimeFeedingBox:AddToggle("AutoArmHugeToggle", {
    Text = "Auto Arm Huge Dice",
    Default = false,
    Tooltip = "Automatically arms Huge Dice from inventory",
    Callback = function(Value)
        Config.AutoArmHuge = Value
    end
})
SlimeFeedingBox:AddToggle("AutoArmBigToggle", {
    Text = "Auto Arm Big Dice",
    Default = false,
    Tooltip = "Automatically arms Big Dice from inventory",
    Callback = function(Value)
        Config.AutoArmBig = Value
    end
})
SlimeFeedingBox:AddButton({
    Text = "Transfer Idle XP",
    Func = function()
        task.spawn(function()
            local inventory = DataServiceClient:get("inventory") or {}
            local equipped = getEquippedSlimes()
            if #equipped == 0 then
                Library:Notify("XP Transfer Error: Please equip at least one slime first!", 4)
                return
            end
            local outputSlimeUid = equipped[1]
            local equippedSet = {}
            for _, uid in ipairs(equipped) do
                equippedSet[uid] = true
            end
            local inputEntries = {}
            for uid, slime in pairs(inventory) do
                if not equippedSet[uid] and type(slime) == "table" then
                    local slimeData = resolveSlimeDataFromInventory(uid, slime)
                    local accumulatedXp = 0
                    pcall(function()
                        accumulatedXp = InventoryServiceUtils.getAccumulatedXp(slimeData)
                    end)
                    if accumulatedXp > 0 then
                        table.insert(inputEntries, {
                            uid = uid,
                            xp = accumulatedXp
                        })
                    end
                end
            end
            table.sort(inputEntries, function(a, b)
                return a.xp > b.xp
            end)
            if #inputEntries > 0 then
                local transferred = 0
                local lastError = nil
                for _, entry in ipairs(inputEntries) do
                    local success, err = Services.XpTransfer:InvokeServer("requestTransferXp", entry.uid, outputSlimeUid)
                    if success then
                        transferred = transferred + 1
                    else
                        lastError = err
                    end
                    task.wait(0.15)
                end
                if transferred > 0 then
                    Library:Notify(("XP Transferred! Moved idle XP from %d slime(s) into your main slime."):format(transferred), 4.5)
                elseif lastError then
                    Library:Notify("XP Transfer failed: " .. tostring(lastError), 4.5)
                else
                    Library:Notify("XP Transfer failed! Ensure the XP Transfer Machine is unlocked first.", 4.5)
                end
            elseif not XpTransferServiceUtils.isMachineUnlocked(DataServiceClient:get("unlocks")) then
                Library:Notify("XP Transfer machine is locked. Unlock it first.", 4)
            else
                local success, err = Services.XpTransfer:InvokeServer("requestTransferXp", outputSlimeUid, outputSlimeUid)
                if success then
                    Library:Notify("XP Transfer completed.", 3)
                else
                    Library:Notify("No idle slimes with transferrable XP were found. " .. tostring(err or ""), 4)
                end
            end
        end)
    end,
    DoubleClick = false,
    Tooltip = "Transfers all accrued XP from unequipped slimes to your primary equipped slime"
})
local SlimeUpgradeTreeBox = Tabs.Inventory:AddRightGroupbox("Upgrade Tree")
addImageCard(SlimeUpgradeTreeBox, {
    Image = ImageIds.upgradeHexYellow,
    Title = "Slime Tree",
    Caption = "Fruit paths and combat skill upgrades",
    StrokeColor = Color3.fromRGB(230, 205, 95),
})
SlimeUpgradeTreeBox:AddToggle("AutoUpgradeSlimesToggle", {
    Text = "Auto Upgrade Slimes",
    Default = false,
    Tooltip = "Automatically levels up elements along upgrade trees",
    Callback = function(Value)
        Config.AutoUpgradeSlimes = Value
    end
})
SlimeUpgradeTreeBox:AddToggle("SlimeUpgradesUseFruitsToggle", {
    Text = "Use Fruits (Origins)",
    Default = false,
    Tooltip = "Consumes rare fruits to activate upgrade tree origins",
    Callback = function(Value)
        Config.SlimeUpgradesUseFruits = Value
        if Value then
            Library:Notify("Fruit Consumption: Upgrader will use rare fruits to unlock tree origins!", 4)
        end
    end
})
local FruitExtractorBox = Tabs.Inventory:AddLeftGroupbox("Fruit Extractor")
addImageCard(FruitExtractorBox, {
    Image = ImageIds.fruitIcons.universeFruit,
    Title = "Fruit Extractor",
    Caption = "Recover fruit from unequipped slimes",
    StrokeColor = Color3.fromRGB(120, 160, 255),
})
FruitExtractorBox:AddToggle("AutoExtractFruitsToggle", {
    Text = "Auto Extract Fruits",
    Default = false,
    Tooltip = "Automatically extracts power fruits from unequipped slimes in the background",
    Callback = function(Value)
        Config.AutoExtractFruits = Value
    end
})
FruitExtractorBox:AddButton({
    Text = "Unlock Extractor",
    Func = function()
        task.spawn(function()
            local success = Services.FruitExtractor:InvokeServer("requestUnlockMachine")
            if success then
                Library:Notify("Fruit Extractor unlocked successfully!", 4)
            else
                Library:Notify("Unlock failed or already unlocked.", 4)
            end
        end)
    end,
    DoubleClick = false,
    Tooltip = "Instantly unlocks the Fruit Extractor Machine"
})
FruitExtractorBox:AddButton({
    Text = "Extract All Fruits",
    Func = function()
        task.spawn(function()
            local inventory = DataServiceClient:get("inventory")
            if not inventory then
                Library:Notify("Could not load slime inventory data.", 3)
                return
            end
            local extractedCount = 0
            for uid, slime in pairs(inventory) do
                if slime.fruit then
                    local success = Services.FruitExtractor:InvokeServer("requestExtractFruits", uid)
                    if success then
                        extractedCount = extractedCount + 1
                    end
                    task.wait(0.2)
                end
            end
            Library:Notify("Extraction Complete: Reclaimed Power Fruits from " .. extractedCount .. " slimes!", 4)
        end)
    end,
    DoubleClick = false,
    Tooltip = "Extracts and reclaims all power fruits from slimes in your inventory"
})
FruitExtractorBox:AddButton({
    Text = "Reclaim All Fed Fruits",
    Func = function()
        task.spawn(function()
            local inventory = DataServiceClient:get("inventory")
            local equipped = getEquippedSlimes()
            if not inventory then
                Library:Notify("Reclaim Error: Could not load slime inventory data.", 3)
                return
            end
            local equippedSet = {}
            for _, uid in ipairs(equipped) do
                equippedSet[uid] = true
            end
            local targets = {}
            for uid, slime in pairs(inventory) do
                local hasFruit = false
                if slime.unlockedTrees and next(slime.unlockedTrees) ~= nil then
                    hasFruit = true
                end
                if slime.fruit then
                    hasFruit = true
                end
                if hasFruit and not equippedSet[uid] then
                    table.insert(targets, uid)
                end
            end
            if #targets == 0 then
                Library:Notify("No unequipped slimes with active fruits were found.", 4)
                return
            end
            Library:Notify("Reclaim Sweep: Salvaging fruits from " .. #targets .. " slimes...", 4)
            local reclaimedCount = 0
            for _, uid in ipairs(targets) do
                local success = Services.Inventory:InvokeServer("requestUseFruitRemover", uid)
                if success then
                    reclaimedCount = reclaimedCount + 1
                end
                task.wait(0.2)
            end
            Library:Notify("Reclaim Complete! Successfully salvaged fruits from " .. reclaimedCount .. " slimes.", 4.5)
        end)
    end,
    DoubleClick = false,
    Tooltip = "Strips and reclaims all power fruits from unequipped slimes in inventory"
})
local XpTransferMachineBox = Tabs.Inventory:AddRightGroupbox("XP Transfer")
XpTransferMachineBox:AddButton({
    Text = "Unlock XP Transfer",
    Func = function()
        task.spawn(function()
            local success = Services.XpTransfer:InvokeServer("requestUnlockMachine")
            if success then
                Library:Notify("XP Transfer Machine unlocked successfully!", 4)
            else
                Library:Notify("Unlock failed or already unlocked.", 4)
            end
        end)
    end,
    DoubleClick = false,
    Tooltip = "Instantly unlocks the XP Transfer Machine"
})
local AutoIndexRecipesBox = Tabs.Inventory:AddLeftGroupbox("Index & Recipes")
AutoIndexRecipesBox:AddToggle("AutoClaimIndexToggle", {
    Text = "Auto Claim Index",
    Default = false,
    Tooltip = "Automatically claims mutation collection indexes",
    Callback = function(Value)
        Config.AutoClaimIndex = Value
    end
})
AutoIndexRecipesBox:AddToggle("AutoUnlockRecipesToggle", {
    Text = "Auto Unlock Recipes",
    Default = false,
    Tooltip = "Automatically unlocks all standard blueprint crafting recipes",
    Callback = function(Value)
        Config.AutoUnlockRecipes = Value
    end
})
local AdvancedAutoCrafterBox = Tabs.Inventory:AddRightGroupbox("Auto Crafter")
local RecipeDropdownOptions = { "crafty", "thorn", "geode", "slimeSlimeSlime", "puffy", "astro", "sunny", "melly", "sweetie", "mossy" }
AdvancedAutoCrafterBox:AddDropdown("CraftRecipeDropdown", {
    Values = RecipeDropdownOptions,
    Default = "crafty",
    Multi = false,
    Text = "Craft Recipe",
    Callback = function(Value)
        Config.SelectedCraftRecipe = Value
    end
})
AdvancedAutoCrafterBox:AddToggle("AutoCraftSelectedToggle", {
    Text = "Auto Craft",
    Default = false,
    Tooltip = "Continuously crafts the chosen item if materials are owned",
    Callback = function(Value)
        Config.AutoCraftSelected = Value
    end
})
AdvancedAutoCrafterBox:AddToggle("AutoTpToCraftingToggle", {
    Text = "Auto TP to Crafter",
    Default = false,
    Tooltip = "Teleports to the crafting machine dynamically for fabrication",
    Callback = function(Value)
        if Value then
            applyToggleConflicts("AutoTpToCraftingToggle")
        end
        Config.AutoTpToCrafting = Value
    end
})
local CombatGoopGunBox = Tabs.Combat:AddLeftGroupbox("Goop Gun")
addImageCard(CombatGoopGunBox, {
    Image = ImageIds.slimeGun,
    Title = "Goop Gun",
    Caption = "Fast target cycling, mark damage, and rebirth goop farming",
    StrokeColor = Color3.fromRGB(135, 255, 120),
})
CombatGoopGunBox:AddToggle("AutoShootSlimeGunToggle", {
    Text = "Auto Shoot Slime Gun",
    Default = false,
    Tooltip = "Instantly fires the slime/goop gun at active enemies at maximum speed",
    Callback = function(Value)
        Config.AutoShootSlimeGun = Value
        if Value then
            Library:Notify("Auto Shoot Active: Blasting all active enemies at maximum speed!", 4)
        end
    end
})
CombatGoopGunBox:AddToggle("AutoFarmSlimesToggle", {
    Text = "Auto Farm Slimes",
    Default = false,
    Tooltip = "Automatically teleports you to active enemies and auto shoots them",
    Callback = function(Value)
        if Value then
            applyToggleConflicts("AutoFarmSlimesToggle")
        end
        Config.AutoFarmSlimes = Value
        if Value then
            Library:Notify("Auto Farm Active: Teleporting and shooting slimes automatically!", 4)
        end
    end
})
CombatGoopGunBox:AddToggle("EfficientFarmToggle", {
    Text = "Efficient Farm",
    Default = false,
    Tooltip = "Teleports to the fastest efficient zone for reaching your next rebirth goop requirement",
    Callback = function(Value)
        if Value then
            applyToggleConflicts("EfficientFarmToggle")
        end
        Config.EfficientFarm = Value
        if Value then
            Library:Notify("Efficient Farm Active: Auto-calculating optimal farming zone...", 4)
        end
    end
})
CombatGoopGunBox:AddDropdown("EfficientFarmModeDropdown", {
    Values = {
        "Balanced Progress",
        "Pure Goop",
        "Rebirth Sprint",
        "Newest Good Goop",
        "Highest Fast Zone",
        "Push Highest Zone",
        "Coin Farm",
        "Kill Speed"
    },
    Default = "Balanced Progress",
    Multi = false,
    Text = "Farm Mode",
    Tooltip = "Choose how Efficient Farm picks zones",
    Callback = function(Value)
        Config.EfficientFarmMode = Value
    end
})
CombatGoopGunBox:AddSlider("EfficientFarmBalanceSlider", {
    Text = "Balance Range",
    Default = 15,
    Min = 0,
    Max = 50,
    Rounding = 0,
    Suffix = "%",
    Compact = true,
    Callback = function(Value)
        Config.EfficientFarmBalanceTolerance = Value
    end
})
CombatGoopGunBox:AddSlider("EfficientFarmGoopFloorSlider", {
    Text = "Newest Goop Floor",
    Default = 60,
    Min = 10,
    Max = 100,
    Rounding = 0,
    Suffix = "%",
    Compact = true,
    Callback = function(Value)
        Config.EfficientFarmMinGoopPercent = Value
    end
})
CombatGoopGunBox:AddSlider("EfficientFarmKillTimeSlider", {
    Text = "Fast Zone TTK",
    Default = 8,
    Min = 1,
    Max = 30,
    Rounding = 1,
    Suffix = "s",
    Compact = true,
    Callback = function(Value)
        Config.EfficientFarmPushKillTime = Value
    end
})
local TeamDamageLabel = CombatGoopGunBox:AddLabel("Team Damage: Calculating...")
local OptimalZoneLabel = CombatGoopGunBox:AddLabel("Optimal Zone: Calculating...")
local OptimalKillRateLabel = CombatGoopGunBox:AddLabel("Kill: Calculating...")
local OptimalCoinRateLabel = CombatGoopGunBox:AddLabel("Coins/s: Calculating...")
local OptimalGoopRateLabel = CombatGoopGunBox:AddLabel("Goop/s: Calculating...")
local RebirthNeedLabel = CombatGoopGunBox:AddLabel("Need: Calculating...")
local RebirthEtaLabel = CombatGoopGunBox:AddLabel("ETA: Calculating...")
local FarmUpgradeLabel = CombatGoopGunBox:AddLabel("Upg: Calculating...")
local FarmMeasureLabel = CombatGoopGunBox:AddLabel("Mode: Estimating...")
local MaxKillRateLabel = CombatGoopGunBox:AddLabel("Max K/s: Calculating...")
local MaxCoinRateLabel = CombatGoopGunBox:AddLabel("Max C/s: Calculating...")
local MaxGoopRateLabel = CombatGoopGunBox:AddLabel("Max G/s: Calculating...")
local function fmtDuration(seconds)
    if not seconds or seconds == math.huge or seconds ~= seconds then
        return "n/a"
    elseif seconds <= 0 then
        return "now"
    elseif seconds < 60 then
        return string.format("%.0fs", seconds)
    elseif seconds < 3600 then
        return string.format("%.1fm", seconds / 60)
    elseif seconds < 86400 then
        return string.format("%.1fh", seconds / 3600)
    else
        return string.format("%.1fd", seconds / 86400)
    end
end
local function makeCompactLabel(label)
    pcall(function()
        local textLabel = label.TextLabel
        if textLabel then
            textLabel.TextXAlignment = Enum.TextXAlignment.Left
            textLabel.TextWrapped = false
            textLabel.TextScaled = true
            textLabel.TextSize = 12
        end
    end)
    return label
end
makeCompactLabel(TeamDamageLabel)
makeCompactLabel(OptimalZoneLabel)
makeCompactLabel(OptimalKillRateLabel)
makeCompactLabel(OptimalCoinRateLabel)
makeCompactLabel(OptimalGoopRateLabel)
makeCompactLabel(RebirthNeedLabel)
makeCompactLabel(RebirthEtaLabel)
makeCompactLabel(FarmUpgradeLabel)
makeCompactLabel(FarmMeasureLabel)
makeCompactLabel(MaxKillRateLabel)
makeCompactLabel(MaxCoinRateLabel)
makeCompactLabel(MaxGoopRateLabel)
local SystemAutomationBox = Tabs.Combat:AddRightGroupbox("System")
SystemAutomationBox:AddToggle("AutoRejoinToggle", {
    Text = "Auto Rejoin",
    Default = false,
    Tooltip = "Instantly teleports you back to the server if kicked or disconnected",
    Callback = function(Value)
        Config.AutoRejoin = Value
    end
})
SystemAutomationBox:AddButton({
    Text = "Prompt Friend Server",
    Func = function()
        task.spawn(function()
            local targets = {}
            for _, player in ipairs(Players:GetPlayers()) do
                if shouldPromptFriendRequest(player) then
                    table.insert(targets, player)
                end
            end
            if #targets == 0 then
                Library:Notify("No non-friend players found to prompt.", 3)
                return
            end
            Library:Notify(("Prompting friend requests for %d player(s). Confirm each Roblox prompt."):format(#targets), 5)
            local prompted = 0
            for _, player in ipairs(targets) do
                if player.Parent == Players and shouldPromptFriendRequest(player) then
                    if promptFriendRequest(player) then
                        prompted = prompted + 1
                    end
                    task.wait(5)
                end
            end
            Library:Notify(("Friend prompts shown: %d/%d"):format(prompted, #targets), 4)
        end)
    end,
    DoubleClick = true,
    Tooltip = "Shows Roblox's friend request prompt for each non-friend in the server. You still confirm each request."
})
local BoosterAutoBox = Tabs.Combat:AddLeftGroupbox("Boosters")
addImageCard(BoosterAutoBox, {
    Image = ImageIds.boosts.ultraLuck,
    Title = "Boost Stack",
    Caption = "Luck, currency, and roll-speed consumables",
    StrokeColor = Color3.fromRGB(255, 205, 90),
})
BoosterAutoBox:AddToggle("AutoBoostAllToggle", {
    Text = "Auto All Boosts",
    Default = false,
    Tooltip = "Automatically consumes and activates all standard booster items",
    Callback = function(Value)
        Config.AutoBoostAll = Value
    end
})
local boosterMapping = {
    ["Luck Boost"] = "AutoBoostLuck",
    ["Ultra Luck Boost"] = "AutoBoostUltraLuck",
    ["Currency Boost"] = "AutoBoostCurrency",
    ["Roll Speed Boost"] = "AutoBoostRollSpeed"
}
local SelectedBoostKey = "Luck Boost"
BoosterAutoBox:AddDropdown("SelectBoostDropdown", {
    Values = { "Luck Boost", "Ultra Luck Boost", "Currency Boost", "Roll Speed Boost" },
    Default = "Luck Boost",
    Multi = false,
    Text = "Select Boost",
    Callback = function(Value)
        SelectedBoostKey = Value
    end
})
BoosterAutoBox:AddButton({
    Text = "Toggle Boost",
    Func = function()
        local configKey = boosterMapping[SelectedBoostKey]
        if configKey then
            Config[configKey] = not Config[configKey]
            Library:Notify(SelectedBoostKey .. " auto-activation: " .. (Config[configKey] and "ENABLED" or "DISABLED"), 3.5)
        end
    end,
    DoubleClick = false,
    Tooltip = "Enables/disables the chosen booster auto-activation"
})
local CodesRedemptionBox = Tabs.Combat:AddRightGroupbox("Codes")
CodesRedemptionBox:AddInput("CustomCodeInputBox", {
    Default = "",
    Numeric = false,
    Finished = true,
    Text = "Enter Custom Code",
    Placeholder = "Type active code here...",
    Tooltip = "Press Enter inside the box or click the button below to redeem code",
    Callback = function(Value)
        if Value ~= "" then
            task.spawn(function()
                local success, msg = Services.Codes:InvokeServer("redeem", Value)
                Library:Notify(success and "Code Success: Successfully redeemed " .. Value or tostring(msg), 4)
            end)
        end
    end
})
CodesRedemptionBox:AddButton({
    Text = "Redeem Entered Code",
    Func = function()
        local code = Options.CustomCodeInputBox.Value
        if code and code ~= "" then
            task.spawn(function()
                local success, msg = Services.Codes:InvokeServer("redeem", code)
                Library:Notify(success and "Code Success: Successfully redeemed " .. code or tostring(msg), 4)
            end)
        end
    end,
    DoubleClick = false,
    Tooltip = "Redeems whatever code is currently typed in the textbox"
})
CodesRedemptionBox:AddButton({
    Text = "Redeem All Codes",
    Func = function()
        task.spawn(function()
            local activeCodes = { "release", "slime", "luck", "coins", "update1", "freeboost", "megaluck", "100kvisits" }
            pcall(function()
                local request = (syn and syn.request) or http_request or request or http.request
                if request then
                    local res = request({
                        Url = "https://raw.githubusercontent.com/SlimeRNG/Codes/main/active_codes.json",
                        Method = "GET"
                    })
                    if res and res.StatusCode == 200 then
                        local list = game:GetService("HttpService"):JSONDecode(res.Body)
                        if type(list) == "table" and #list > 0 then
                            activeCodes = list
                        end
                    end
                end
            end)
            Library:Notify("Attempting to redeem " .. #activeCodes .. " active codes...", 3.5)
            for _, code in ipairs(activeCodes) do
                local success, msg = Services.Codes:InvokeServer("redeem", code)
                if success then
                    Library:Notify("Code Success: Successfully redeemed " .. code, 3)
                end
                task.wait(0.2)
            end
            Library:Notify("Redemption sweep completed!", 3)
        end)
    end,
    DoubleClick = false,
    Tooltip = "Sequentially attempts to redeem all standard active promotional codes (dynamic auto-update)"
})
local ZoneNames = {
    [0] = "Grasslands", "Desert", "Polar", "Volcano", "Islands",
    "Cave", "Heaven", "Jungle", "Canyon", "Mushroom Forest",
    "Moon", "Redwood Forest", "Meteor", "Candyland", "Cherry Grove",
    "Crystal Cavern", "Pumpkin Patch", "Atlantis", "River", "Pyramids",
    "Graveyard", "Hot Springs", "Tribe", "Toxic Wasteland", "Steampunk",
    "Winter Wonderland", "Farm", "Jungle Temple", "Underworld", "Swamp",
    "Mushroom Village", "The Void", "Honeycomb", "Glow Mine", "Alien Planet",
    "Spooky House", "Skull Island", "Slime Inc.", "Ancient Portal", "Racetrack"
}
local SlimeDB = {
    {id="goopy",name="Goopy",weight=1e12,dmg=4,hp=10,img="rbxassetid://125014847814930",zone=0},
    {id="sunset",name="Sunset",weight=5e11,dmg=5,hp=15,img="rbxassetid://121554969636389",zone=0},
    {id="fin",name="Fin",weight=3e11,dmg=6,hp=20,img="rbxassetid://87279507965562",zone=0},
    {id="leafy",name="Leafy",weight=2e11,dmg=7,hp=22,img="rbxassetid://110387483496665",zone=0},
    {id="cat",name="Meow",weight=6.2e10,dmg=8,hp=27,img="rbxassetid://90044737038788",zone=0},
    {id="glo",name="Glo",weight=3.8e10,dmg=10,hp=30,img="rbxassetid://71398008901155",zone=0},
    {id="buggy",name="Buggy",weight=2.1e10,dmg=13,hp=36,img="rbxassetid://127031604553936",zone=0},
    {id="boomy",name="Scorchy",weight=1.35e10,dmg=15,hp=43,img="rbxassetid://79434801790939",zone=0},
    {id="brutis",name="Brutis",weight=8.2e9,dmg=18,hp=50,img="rbxassetid://96141106213410",zone=0},
    {id="frankenSlime",name="Frankenslime",weight=5.2e9,dmg=20,hp=60,img="rbxassetid://101295677521483",zone=0},
    {id="orca",name="Orca",weight=3e9,dmg=25,hp=72,img="rbxassetid://81818054985491",zone=0},
    {id="spike",name="Spike",weight=1.7e9,dmg=29,hp=88,img="rbxassetid://121766812104264",zone=0},
    {id="axolotl",name="Axolotl",weight=9e8,dmg=36,hp=105,img="rbxassetid://138568829545430",zone=1},
    {id="spidey",name="Spidey",weight=5.04e8,dmg=43,hp=121,img="rbxassetid://110453196439519",zone=1},
    {id="mushy",name="Mushy",weight=2.77e8,dmg=50,hp=148,img="rbxassetid://132119790080032",zone=2},
    {id="rocky",name="Rocky",weight=1.55e8,dmg=58,hp=176,img="rbxassetid://119389913033936",zone=3},
    {id="lucky",name="Lucky",weight=1e8,dmg=67,hp=200,img="rbxassetid://88659965344315",zone=3},
    {id="stump",name="Stump",weight=6e7,dmg=75,hp=232,img="rbxassetid://104526065478721",zone=4},
    {id="lily",name="Pondy",weight=4e7,dmg=85,hp=256,img="rbxassetid://73633156837156",zone=4},
    {id="icy",name="Icy",weight=2.5e7,dmg=96,hp=290,img="rbxassetid://107549341119743",zone=5},
    {id="orbit",name="Orbit",weight=1.7e7,dmg=115,hp=344,img="rbxassetid://134237961759276",zone=5},
    {id="aegis",name="Aegis",weight=1e7,dmg=138,hp=414,img="rbxassetid://129596888311355",zone=6},
    {id="wicked",name="Wicked",weight=6.6e6,dmg=166,hp=496,img="rbxassetid://90719636941813",zone=6},
    {id="king",name="King",weight=4e6,dmg=189,hp=567,img="rbxassetid://131487299588107",zone=7},
    {id="guest",name="Guest",weight=2.5e6,dmg=208,hp=624,img="rbxassetid://106886986086246",zone=7},
    {id="ninja",name="Ninja",weight=1.7e6,dmg=230,hp=690,img="rbxassetid://71329585399252",zone=8},
    {id="buzz",name="Buzz",weight=1e6,dmg=270,hp=810,img="rbxassetid://91579123196118",zone=8},
    {id="stormy",name="Stormy",weight=7e5,dmg=291,hp=870,img="rbxassetid://138295134331622",zone=9},
    {id="bucky",name="Bucky",weight=4.5e5,dmg=333,hp=999,img="rbxassetid://120383542839889",zone=9},
    {id="pokey",name="Pokey",weight=3e5,dmg=371,hp=1111,img="rbxassetid://101200748535156",zone=10},
    {id="slimeSlime",name="SlimeSlime",weight=2e5,dmg=419,hp=1256,img="rbxassetid://83334448391499",zone=10},
    {id="unicorn",name="Unicorn",weight=1.2e5,dmg=508,hp=1524,img="rbxassetid://82469966827101",zone=11},
    {id="wizzy",name="Wizzy",weight=8e4,dmg=612,hp=1836,img="rbxassetid://84211538001633",zone=11},
    {id="flour",name="Petal",weight=5.5e4,dmg=734,hp=2300,img="rbxassetid://124937734770442",zone=12},
    {id="shelly",name="Shelly",weight=3.5e4,dmg=880,hp=2640,img="rbxassetid://113644834208086",zone=12},
    {id="derpy",name="Derpy",weight=2.4e4,dmg=1050,hp=3150,img="rbxassetid://107448058521795",zone=13},
    {id="otto",name="Octo",weight=1.6e4,dmg=1260,hp=3780,img="rbxassetid://139658326612671",zone=13},
    {id="halo",name="Halo",weight=1.1e4,dmg=1512,hp=4500,img="rbxassetid://119632823896702",zone=14},
    {id="bomber",name="Bomber",weight=7e3,dmg=1810,hp=5430,img="rbxassetid://118802012619593",zone=14},
    {id="ufo",name="UFO",weight=4.5e3,dmg=2172,hp=6516,img="rbxassetid://84571567979840",zone=15},
    {id="witchy",name="Witchy",weight=3e3,dmg=2600,hp=7800,img="rbxassetid://95792608661411",zone=15},
    {id="blackhole",name="Blackhole",weight=2e3,dmg=3120,hp=9360,img="rbxassetid://75291163669132",zone=16},
    {id="ember",name="Ember",weight=1.25e3,dmg=3744,hp=11200,img="rbxassetid://109587061202149",zone=16},
    {id="pumpkin",name="Pumpkin",weight=777,dmg=4492,hp=13500,img="rbxassetid://73520789212019",zone=17},
    {id="ouchy",name="Ouchy",weight=490,dmg=5400,hp=16200,img="rbxassetid://71018813544154",zone=17},
    {id="sharky",name="Sharky",weight=333,dmg=6500,hp=19400,img="rbxassetid://110042731614016",zone=18},
    {id="dino",name="Dino",weight=212,dmg=7800,hp=23400,img="rbxassetid://136570963279793",zone=18},
    {id="monke",name="Monke",weight=140,dmg=9360,hp=28000,img="rbxassetid://77496763719646",zone=19},
    {id="prickly",name="Prickly",weight=90,dmg=11200,hp=33700,img="rbxassetid://84926848454541",zone=19},
    {id="zoomy",name="Zoomy",weight=63,dmg=13400,hp=40300,img="rbxassetid://140487313117811",zone=20},
    {id="waxie",name="Waxie",weight=43,dmg=16100,hp=48200,img="rbxassetid://124352884305657",zone=20},
    {id="drakey",name="Drakey",weight=29,dmg=19300,hp=58000,img="rbxassetid://89226334072502",zone=21},
    {id="germy",name="Germy",weight=19,dmg=23100,hp=70000,img="rbxassetid://114695028781494",zone=21},
    {id="palmy",name="Palmy",weight=12.5,dmg=27700,hp=83000,img="rbxassetid://117868893544144",zone=22},
    {id="snazzy",name="Snazzy",weight=8,dmg=33200,hp=100000,img="rbxassetid://72729644483167",zone=22},
    {id="bemmy",name="Bemmy",weight=5.2,dmg=40000,hp=120000,img="rbxassetid://127485383568253",zone=23},
    {id="mato",name="Mato",weight=3.2,dmg=48000,hp=144000,img="rbxassetid://113995789351545",zone=23},
    {id="frosty",name="Frosty",weight=2,dmg=57600,hp=172000,img="rbxassetid://128497431011038",zone=24},
    {id="pouchy",name="Pouchy",weight=1.25,dmg=70000,hp=210000,img="rbxassetid://90338928566181",zone=24},
    {id="hoppity",name="Hoppity",weight=0.8,dmg=84000,hp=252000,img="rbxassetid://126583635183345",zone=25},
    {id="shady",name="Shady",weight=0.54,dmg=100000,hp=300000,img="rbxassetid://139585610533005",zone=25},
    {id="galaxy",name="Galaxy",weight=0.31,dmg=120000,hp=360000,img="rbxassetid://120882053341325",zone=26},
    {id="painty",name="Painty",weight=0.19,dmg=145000,hp=435000,img="rbxassetid://76182996459728",zone=26},
    {id="patty",name="Patty",weight=0.115,dmg=174000,hp=522000,img="rbxassetid://90737239703154",zone=27},
    {id="broclee",name="Broclee",weight=0.075,dmg=210000,hp=630000,img="rbxassetid://76190194778817",zone=27},
    {id="meaty",name="Meaty",weight=0.05,dmg=256000,hp=777000,img="rbxassetid://85657138480145",zone=28},
    {id="zappy",name="Zappy",weight=0.032,dmg=308000,hp=924000,img="rbxassetid://138602335586757",zone=28},
    {id="baconHair",name="Bacon Hair",weight=0.02,dmg=370000,hp=1110000,img="rbxassetid://91350608281509",zone=29},
    {id="cow",name="Cow",weight=0.0128,dmg=444000,hp=1330000,img="rbxassetid://83453807032104",zone=29},
    {id="cowboy",name="Cowboy",weight=0.008,dmg=533000,hp=1600000,img="rbxassetid://96333265636635",zone=30},
    {id="cyber",name="Cyber",weight=0.00512,dmg=640000,hp=1920000,img="rbxassetid://95098148000079",zone=30},
    {id="frenchy",name="Frenchy",weight=0.0033,dmg=770000,hp=2300000,img="rbxassetid://133532932049823",zone=31},
    {id="eggy",name="Eggy",weight=0.0021,dmg=920000,hp=2760000,img="rbxassetid://134295490913430",zone=31},
    {id="dumpy",name="Dumpy",weight=0.00135,dmg=1100000,hp=3300000,img="rbxassetid://121611533441013",zone=32},
    {id="chef",name="Chef",weight=0.00086,dmg=1330000,hp=4000000,img="rbxassetid://81346056366216",zone=32},
    {id="twinkle",name="Twinkle",weight=0.00055,dmg=1600000,hp=4800000,img="rbxassetid://127986973029366",zone=33},
    {id="bot",name="Bot",weight=0.00035,dmg=1900000,hp=5700000,img="rbxassetid://102820484218130",zone=33},
    {id="sushi",name="Sushi",weight=0.000225,dmg=2300000,hp=6900000,img="rbxassetid://128436462645396",zone=34},
    {id="knighty",name="Knighty",weight=0.000144,dmg=2760000,hp=8280000,img="rbxassetid://121528138792522",zone=34},
    {id="crafty",name="Crafty",weight=0,dmg=90,hp=270,img="rbxassetid://80275578334225",zone=0,craft=true},
    {id="thorn",name="Thorn",weight=0,dmg=167,hp=500,img="rbxassetid://132737359040574",zone=0,craft=true},
    {id="geode",name="Geode",weight=0,dmg=300,hp=900,img="rbxassetid://120112215527315",zone=0,craft=true},
    {id="slimeSlimeSlime",name="SlimeSlimeSlime",weight=0,dmg=676,hp=2028,img="rbxassetid://116751290384627",zone=0,craft=true},
    {id="puffy",name="Puffy",weight=0,dmg=1400,hp=4200,img="rbxassetid://126480065415699",zone=0,craft=true},
    {id="astro",name="Astro",weight=0,dmg=4100,hp=12300,img="rbxassetid://84474255602247",zone=0,craft=true},
    {id="sunny",name="Sunny",weight=0,dmg=8100,hp=24300,img="rbxassetid://124866647020868",zone=0,craft=true},
    {id="melly",name="Melly",weight=0,dmg=31000,hp=93000,img="rbxassetid://105418599267634",zone=0,craft=true},
    {id="sweetie",name="Sweetie",weight=0,dmg=93000,hp=279000,img="rbxassetid://117564828375077",zone=0,craft=true},
    {id="mossy",name="Mossy",weight=0,dmg=1000000,hp=3000000,img="rbxassetid://80228617535148",zone=0,craft=true},
}
local MutationData = {
    {id="big",     name="BIG",      odds=0.01,  statMult=4},
    {id="huge",    name="HUGE",     odds=0.001, statMult=10},
    {id="shiny",   name="Shiny",    odds=0.004, statMult=6},
    {id="inverted",name="Inverted", odds=0.0004,statMult=13},
}
local TotalWeight = 0
for _, s in ipairs(SlimeDB) do
    if not s.craft then TotalWeight = TotalWeight + s.weight end
end
local function fmtNum(n)
    if n >= 1e15 then return string.format("%.1fQ", n / 1e15)
    elseif n >= 1e12 then return string.format("%.1fT", n / 1e12)
    elseif n >= 1e9 then return string.format("%.1fB", n / 1e9)
    elseif n >= 1e6 then return string.format("%.1fM", n / 1e6)
    elseif n >= 1e3 then return string.format("%.1fK", n / 1e3)
    else return tostring(math.floor(n)) end
end
local function fmtRarity(weight)
    if weight <= 0 then return "Craftable" end
    local odds = weight / TotalWeight
    if odds <= 0 then return "???" end
    local oneIn = 1 / odds
    return "1 in " .. fmtNum(oneIn)
end
local SlimeLookup = {}
local SlimeNameListRare = {}
local SlimeNameListCraft = {}
for _, s in ipairs(SlimeDB) do
    SlimeLookup[s.name] = s
    if s.craft then
        table.insert(SlimeNameListCraft, s.name)
    else
        table.insert(SlimeNameListRare, s.name)
    end
end
table.sort(SlimeNameListRare, function(a, b)
    return SlimeLookup[a].weight < SlimeLookup[b].weight
end)
local SlimeNameList = {}
for _, n in ipairs(SlimeNameListRare) do table.insert(SlimeNameList, n) end
for _, n in ipairs(SlimeNameListCraft) do table.insert(SlimeNameList, n) end
local DbSelectBox = Tabs.Database:AddLeftGroupbox("Slime Lookup")
local SelectedDbSlime = SlimeNameList[1]
local SelectedSlimePreview = addImageCard(DbSelectBox, {
    Image = SlimeLookup[SelectedDbSlime] and SlimeLookup[SelectedDbSlime].img or "",
    Title = SelectedDbSlime or "Selected Slime",
    Caption = "Preview, rarity, stats, and source zone",
    StrokeColor = Color3.fromRGB(110, 95, 230),
})
local function updateSelectedSlimePreview()
    local s = SlimeLookup[SelectedDbSlime]
    if not s then return end
    local zoneName = ZoneNames[s.zone] or ("Zone " .. s.zone)
    SelectedSlimePreview:Set(
        s.img,
        s.name,
        string.format("%s | DMG %s | %s", fmtRarity(s.weight), fmtNum(s.dmg), zoneName)
    )
end
updateSelectedSlimePreview()
DbSelectBox:AddDropdown("DbSlimeDropdown", {
    Values = SlimeNameList,
    Default = SelectedDbSlime,
    Multi = false,
    Text = "Select Slime",
    Callback = function(Value)
        SelectedDbSlime = Value
        updateSelectedSlimePreview()
    end
})
DbSelectBox:AddButton({
    Text = "Show Base Stats",
    Func = function()
        local s = SlimeLookup[SelectedDbSlime]
        if not s then Library:Notify("Slime not found!", 3) return end
        local zoneName = ZoneNames[s.zone] or ("Zone " .. s.zone)
        local rarity = fmtRarity(s.weight)
        local lines = {
            "=== " .. s.name .. " ===",
            "Image: " .. s.img,
            "Rarity: " .. rarity,
            "DMG: " .. fmtNum(s.dmg) .. " | HP: " .. fmtNum(s.hp),
            "Zone: " .. zoneName,
        }
        if s.craft then
            table.insert(lines, "Type: Craftable Only")
        end
        Library:Notify(table.concat(lines, "\n"), 8)
    end,
    DoubleClick = false,
    Tooltip = "Show base stats for the selected slime"
})
DbSelectBox:AddButton({
    Text = "Show Mutation Stats",
    Func = function()
        local s = SlimeLookup[SelectedDbSlime]
        if not s then Library:Notify("Slime not found!", 3) return end
        local lines = {"=== " .. s.name .. " Mutations ==="}
        for _, m in ipairs(MutationData) do
            local mDmg = s.dmg * m.statMult
            local mHp = s.hp * m.statMult
            table.insert(lines, m.name .. ": DMG " .. fmtNum(mDmg) .. " | HP " .. fmtNum(mHp) .. " (x" .. m.statMult .. ")")
        end
        local combos = {
            {a=1,b=3,name="BIG Shiny"},{a=1,b=4,name="BIG Inverted"},
            {a=2,b=3,name="HUGE Shiny"},{a=2,b=4,name="HUGE Inverted"},
        }
        table.insert(lines, "--- Combos ---")
        for _, c in ipairs(combos) do
            local mult = MutationData[c.a].statMult * MutationData[c.b].statMult
            table.insert(lines, c.name .. ": DMG " .. fmtNum(s.dmg * mult) .. " | HP " .. fmtNum(s.hp * mult) .. " (x" .. mult .. ")")
        end
        Library:Notify(table.concat(lines, "\n"), 12)
    end,
    DoubleClick = false,
    Tooltip = "Show all mutation variants for the selected slime"
})
DbSelectBox:AddButton({
    Text = "Copy Image ID",
    Func = function()
        local s = SlimeLookup[SelectedDbSlime]
        if not s then Library:Notify("Slime not found!", 3) return end
        if setclipboard then
            setclipboard(s.img)
            Library:Notify("Copied: " .. s.img, 3)
        else
            Library:Notify("ID: " .. s.img, 5)
        end
    end,
    DoubleClick = false,
    Tooltip = "Copy the slime's Roblox asset image ID to clipboard"
})
local DbQuickRefBox = Tabs.Database:AddRightGroupbox("Rarest Slimes")
local rarestSlime = SlimeLookup[SlimeNameListRare[1]]
if rarestSlime then
    addImageCard(DbQuickRefBox, {
        Image = rarestSlime.img,
        Title = "Rarest Indexed Slime",
        Caption = string.format("%s | %s", rarestSlime.name, fmtRarity(rarestSlime.weight)),
        StrokeColor = Color3.fromRGB(195, 140, 255),
    })
end
for i = 1, math.min(10, #SlimeNameListRare) do
    local n = SlimeNameListRare[i]
    local s = SlimeLookup[n]
    local rarity = fmtRarity(s.weight)
    DbQuickRefBox:AddLabel(s.name .. ": " .. rarity)
end
local DbMutRefBox = Tabs.Database:AddRightGroupbox("Mutation Odds")
DbMutRefBox:AddLabel("BIG: 1 in 100 (x4 stats)")
DbMutRefBox:AddLabel("HUGE: 1 in 1,000 (x10 stats)")
DbMutRefBox:AddLabel("Shiny: 1 in 250 (x6 stats)")
DbMutRefBox:AddLabel("Inverted: 1 in 2,500 (x13 stats)")
DbMutRefBox:AddDivider()
DbMutRefBox:AddLabel("Combos stack multiply:")
DbMutRefBox:AddLabel("BIG+Shiny = x24")
DbMutRefBox:AddLabel("BIG+Inverted = x52")
DbMutRefBox:AddLabel("HUGE+Shiny = x60")
DbMutRefBox:AddLabel("HUGE+Inverted = x130")
local DbCraftBox = Tabs.Database:AddLeftGroupbox("Craftable Slimes")
local strongestCraftable = nil
for _, n in ipairs(SlimeNameListCraft) do
    local s = SlimeLookup[n]
    if s and (not strongestCraftable or s.dmg > strongestCraftable.dmg) then
        strongestCraftable = s
    end
end
if strongestCraftable then
    addImageCard(DbCraftBox, {
        Image = strongestCraftable.img,
        Title = "Top Craftable",
        Caption = string.format("%s | %s DMG", strongestCraftable.name, fmtNum(strongestCraftable.dmg)),
        StrokeColor = Color3.fromRGB(120, 220, 180),
    })
end
for _, n in ipairs(SlimeNameListCraft) do
    local s = SlimeLookup[n]
    DbCraftBox:AddLabel(s.name .. ": " .. fmtNum(s.dmg) .. " DMG")
end
local DbStatsBox = Tabs.Database:AddRightGroupbox("DB Stats")
DbStatsBox:AddLabel("Total Slimes: " .. #SlimeDB)
DbStatsBox:AddLabel("Rollable: " .. #SlimeNameListRare)
DbStatsBox:AddLabel("Craftable: " .. #SlimeNameListCraft)
DbStatsBox:AddLabel("Mutations: " .. #MutationData)
DbStatsBox:AddLabel("Total Weight: " .. fmtNum(TotalWeight))
local MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("Menu")
MenuGroup:AddButton("Unload Script Hub", function()
    Library:Unload()
end)
MenuGroup:AddLabel("Menu Toggle Bind"):AddKeyPicker("MenuKeybind", {
    Default = "RightShift",
    NoUI = true,
    Text = "Menu keybind"
})
Library.ToggleKeybind = Options.MenuKeybind
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
ThemeManager:SetFolder("OBLITERATE_Hub")
SaveManager:SetFolder("OBLITERATE_Hub/SlimeRNG")
SaveManager:BuildConfigSection(Tabs["UI Settings"])
ThemeManager:ApplyToTab(Tabs["UI Settings"])
Library:SetWatermarkVisibility(true)
Library:SetWatermark("OBLITERATE Hub | Slime RNG")
Library.KeybindFrame.Visible = true
local LoadElapsed = math.floor((tick() - Start) * 1000)
Library:Notify(("Done loading OBLITERATE Hub! (%d ms)"):format(LoadElapsed), 4)
Library:Notify("Press RightShift to open/close menu!", 4)
LocalPlayer.Idled:Connect(function()
    if Config.AntiAFK then
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new(0, 0))
        end)
    end
end)
task.spawn(function()
    while true do
        task.wait(60)
        if Config.AntiAFK then
            pcall(function()
                VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                task.wait(0.2)
                VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            end)
        end
    end
end)
GuiService.ErrorMessageChanged:Connect(function()
    if Config.AutoRejoin then
        task.wait(5)
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end
end)
task.spawn(function()
    task.wait(5)
    pcall(function()
        Services.OfflineEarnings:InvokeServer("requestClaim")
    end)
end)
task.spawn(function()
    task.wait(3)
    pcall(function()
        Services.LikeGroup:FireServer("requestConfirmPrompt")
    end)
end)
task.spawn(function()
    while true do
        task.wait(Config.RollDelay)
        if Config.AutoRoll then
            pcall(function()
                local results = Services.Roll:InvokeServer("requestRoll")
                if results and type(results) == "table" then
                    for _, rollResult in ipairs(results) do
                        local slime = rollResult[#rollResult]
                        if slime and type(slime) == "table" and slime.id then
                            handleNewRoll(slime)
                        end
                    end
                end
            end)
        end
    end
end)
task.spawn(function()
    while true do
        task.wait()
        if Config.AutoCollectLoot then
            local activeLoot = LootController.lootById
            if activeLoot then
                for uniqueId, _ in pairs(activeLoot) do
                    task.spawn(function()
                        pcall(function()
                            Services.Loot:InvokeServer("requestCollect", uniqueId)
                        end)
                    end)
                end
            end
        end
    end
end)
task.spawn(function()
    while true do
        task.wait()
        if Config.AutoRebirth then
            local canRebirth = true
            if Config.RebirthLimit then
                local currentRebirths = DataServiceClient:get("rebirths") or 0
                if currentRebirths >= Config.MaxRebirthLimit then
                    canRebirth = false
                end
            end
            if canRebirth and Config.RebirthBoostProtection then
                local boosters = { "luck", "ultraLuck", "currency", "rollSpeed" }
                for _, bName in ipairs(boosters) do
                    if isBoostActive(bName) then
                        canRebirth = false
                        notifyOnce("rebirth_boost_protected", "Auto Rebirth paused while a temporary boost is active.", 3, 30)
                        break
                    end
                end
            end
            if canRebirth then
                pcall(function()
                    Services.Rebirth:InvokeServer("requestRebirth")
                end)
            end
        end
    end
end)
task.spawn(function()
    while true do
        task.wait()
        if Config.AutoPurchaseZones then
            pcall(function()
                Services.Zones:InvokeServer("requestPurchaseZone")
            end)
        end
    end
end)
task.spawn(function()
    while true do
        task.wait()
        if Config.AutoEquipBest then
            pcall(function()
                Services.Inventory:InvokeServer("requestEquipBest")
            end)
        end
    end
end)
local UpgradeTree = require(Features:WaitForChild("Upgrades"):WaitForChild("UpgradeTree"))
local TutorialServiceClient = require(Features:WaitForChild("Tutorial"):WaitForChild("TutorialServiceClient"))
task.spawn(function()
    while true do
        task.wait()
        if Config.AutoUpgrades then
            local upgrades = DataServiceClient:get("upgrades") or {}
            local coins = DataServiceClient:get("coins") or 0
            local rollCurrency = DataServiceClient:get("rollCurrency") or 0
            for _, tree in pairs(UpgradeTree) do
                for upgradeId, upgrade in pairs(tree) do
                    if not upgrades[upgradeId] then
                        local canUnlock = false
                        pcall(function()
                            canUnlock = TutorialServiceClient:canUnlockUpgrade(upgradeId)
                        end)
                        if canUnlock == nil then canUnlock = true end
                        if canUnlock then
                            local dependency = upgrade.dependency
                            local depMet = false
                            if not dependency or dependency == "origin" then
                                depMet = true
                            elseif upgrades[dependency] then
                                depMet = true
                            end
                            if depMet then
                                local cost = upgrade.cost
                                local canAfford = true
                                local currency, amount
                                if cost then
                                    currency = cost.currency
                                    amount = cost.amount
                                    if currency == "coins" then
                                        canAfford = (coins >= amount)
                                    elseif currency == "rollCurrency" then
                                        canAfford = (rollCurrency >= amount)
                                    else
                                        canAfford = false
                                    end
                                end
                                if canAfford then
                                    if cost then
                                        if currency == "coins" then
                                            coins = coins - amount
                                        elseif currency == "rollCurrency" then
                                            rollCurrency = rollCurrency - amount
                                        end
                                    end
                                    task.spawn(function()
                                        pcall(function()
                                            Services.Upgrade:InvokeServer("requestUnlock", upgradeId)
                                        end)
                                    end)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)
task.spawn(function()
    while true do
        task.wait()
        local boostMapping = {
            { active = Config.AutoBoostLuck or Config.AutoBoostAll, name = "luck" },
            { active = Config.AutoBoostUltraLuck or Config.AutoBoostAll, name = "ultraLuck" },
            { active = Config.AutoBoostCurrency or Config.AutoBoostAll, name = "currency" },
            { active = Config.AutoBoostRollSpeed or Config.AutoBoostAll, name = "rollSpeed" }
        }
        for _, b in ipairs(boostMapping) do
            if b.active then
                local active = false
                pcall(function()
                    active = isBoostActive(b.name)
                end)
                if not active then
                    pcall(function()
                        Services.Boosts:InvokeServer("requestUseBoost", b.name)
                    end)
                end
            end
        end
    end
end)
local function getSlimeXpToLevel(slime, targetLevel)
    local level = math.max(1, tonumber(slime and slime.level) or 1)
    local xp = math.max(0, tonumber(slime and slime.xp) or 0)
    targetLevel = math.max(1, tonumber(targetLevel) or 1)
    if level >= targetLevel then
        return 0
    end
    local remaining = math.max(0, (100 * level) - xp)
    for nextLevel = level + 1, targetLevel - 1 do
        remaining = remaining + (100 * nextLevel)
    end
    return remaining
end
local function getFeedTarget(equipped, inventory)
    local selectedSlot = tostring(Config.FeedTargetSlot or "All Team Slimes")
    local targetLevel = math.max(1, tonumber(Config.FeedStopLevel) or 10)
    local mappedTarget = FeedTargetMap and FeedTargetMap[selectedSlot]
    if mappedTarget and mappedTarget.mode == "uid" then
        local slime = resolveSlimeDataFromInventory(mappedTarget.uid, inventory[mappedTarget.uid])
        if type(slime) == "table" and (tonumber(slime.level) or 1) < targetLevel then
            return mappedTarget.uid, slime, mappedTarget.slot
        end
        return nil
    end
    if selectedSlot ~= "All Slots" and selectedSlot ~= "All Team Slimes" then
        local slot = tonumber(selectedSlot:match("%d+"))
        local slimeUid = slot and equipped[slot]
        local slime = slimeUid and resolveSlimeDataFromInventory(slimeUid, inventory[slimeUid])
        if type(slime) == "table" and (tonumber(slime.level) or 1) < targetLevel then
            return slimeUid, slime, slot
        end
        return nil
    end
    for slot, slimeUid in ipairs(equipped) do
        local slime = resolveSlimeDataFromInventory(slimeUid, inventory[slimeUid])
        if type(slime) == "table" and (tonumber(slime.level) or 1) < targetLevel then
            return slimeUid, slime, slot
        end
    end
    return nil
end
local function getBestFoodForRemainingXp(remainingXp)
    local bestFallback = nil
    local bestFit = nil
    for _, food in ipairs(FoodController.getSortedFoods()) do
        local owned = getItemAmount(food.id)
        if owned > 0 then
            if not bestFallback or food.xp < bestFallback.xp then
                bestFallback = food
            end
            if food.xp <= remainingXp and (not bestFit or food.xp > bestFit.xp) then
                bestFit = food
            end
        end
    end
    return bestFit or bestFallback
end
task.spawn(function()
    while true do
        task.wait(0.2)
        if Config.AutoFeedEquipped then
            pcall(function()
                local inventory = DataServiceClient:get("inventory") or {}
                local equipped = getEquippedSlimes()
                local slimeUid, slime, slot = getFeedTarget(equipped, inventory)
                if not slimeUid then
                    notifyOnce("auto_feed_threshold_met", "Auto Feed paused: selected equipped slimes are at/above the stop level.", 3, 20)
                    return
                end
                local remainingXp = getSlimeXpToLevel(slime, Config.FeedStopLevel)
                local food = getBestFoodForRemainingXp(remainingXp)
                if not food then
                    notifyOnce("auto_feed_no_food", "Auto Feed paused: no food items found.", 3, 20)
                    return
                end
                local success = Services.Inventory:InvokeServer("requestUseFood", food.id, slimeUid, 1)
                if success then
                    notifyOnce(
                        "auto_feed_slot_" .. tostring(slot),
                        ("Feeding Slot %d until Level %d."):format(slot, Config.FeedStopLevel),
                        2,
                        10
                    )
                end
            end)
        end
    end
end)
task.spawn(function()
    while true do
        task.wait()
        if getArmedSpecialDiceCount() < 3 then
            local dicePriority = {
                { id = "jackpotSpin", active = Config.AutoArmJackpot },
                { id = "invertedDice", active = Config.AutoArmInverted },
                { id = "shinyDice", active = Config.AutoArmShiny },
                { id = "hugeDice", active = Config.AutoArmHuge },
                { id = "bigDice", active = Config.AutoArmBig }
            }
            for _, dice in ipairs(dicePriority) do
                if dice.active and getItemAmount(dice.id) > 0 then
                    pcall(function()
                        Services.Inventory:InvokeServer("requestUseItem", dice.id)
                    end)
                    break
                end
            end
        end
    end
end)
task.spawn(function()
    while true do
        task.wait(1)
        if Config.AutoTpBestZone then
            local ufoDropPosition = nil
            if Config.AutoTpToUfo then
                ufoDropPosition = getUnlockedUfoDropPosition()
            end
            if ufoDropPosition then
                continue
            end
            local max = DataServiceClient:get("maxZone")
            local current = DataServiceClient:get("zone")
            if max and current and max > current then
                teleportToZone(max)
            end
        end
    end
end)
task.spawn(function()
    while true do
        task.wait()
        if Config.AutoClaimIndex then
            local categories = { "basic", "big", "huge", "shiny", "inverted" }
            for _, category in ipairs(categories) do
                pcall(function()
                    Services.Index:InvokeServer("requestClaimReward", category)
                end)
            end
        end
    end
end)
task.spawn(function()
    while true do
        task.wait()
        if Config.AutoUnlockRecipes then
            local recipes = { "crafty", "thorn", "geode", "slimeSlimeSlime", "puffy", "astro", "sunny", "melly" }
            for _, recipeId in ipairs(recipes) do
                pcall(function()
                    Services.Crafting:InvokeServer("requestUnlockRecipe", recipeId)
                end)
            end
        end
    end
end)
local function equipSlimeGun()
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
    if humanoid then
        local tool = character:FindFirstChild("SlimeGun")
        if not tool then
            local backpack = LocalPlayer:FindFirstChild("Backpack")
            local gun = backpack and backpack:FindFirstChild("SlimeGun")
            if gun then
                humanoid:EquipTool(gun)
            end
        end
    end
end
local function getBestEnemy(enemies)
    local list = {}
    for enemyId, enemy in pairs(enemies) do
        if enemy and enemy.health and enemy.health > 0 and enemy.model then
            table.insert(list, { id = enemyId, data = enemy })
        end
    end
    if #list == 0 then return nil, nil end
    table.sort(list, function(a, b)
        local aModelName = a.data.model and a.data.model.Name or ""
        local bModelName = b.data.model and b.data.model.Name or ""
        local aIsUfo = aModelName:lower():find("ufo") or aModelName:lower():find("alien")
        local bIsUfo = bModelName:lower():find("ufo") or bModelName:lower():find("alien")
        if aIsUfo and not bIsUfo then return true end
        if bIsUfo and not aIsUfo then return false end
        local aIsBoss = aModelName:lower():find("boss")
        local bIsBoss = bModelName:lower():find("boss")
        if aIsBoss and not bIsBoss then return true end
        if bIsBoss and not aIsBoss then return false end
        local aMax = a.data.maxHealth or 0
        local bMax = b.data.maxHealth or 0
        if aMax ~= bMax then
            return aMax > bMax
        end
        return a.id < b.id
    end)
    return list[1].id, list[1].data
end
local function getShootEnemyList(enemies)
    local list = {}
    for enemyId, enemy in pairs(enemies) do
        if enemy and enemy.health and enemy.health > 0 and enemy.model and not enemy.dead then
            table.insert(list, { id = enemyId, data = enemy })
        end
    end
    table.sort(list, function(a, b)
        local aHealth = a.data.health or a.data.maxHealth or 0
        local bHealth = b.data.health or b.data.maxHealth or 0
        if aHealth ~= bHealth then
            return aHealth < bHealth
        end
        return a.id < b.id
    end)
    return list
end
task.spawn(function()
    local nextShootIndex = 1
    local lastShotAt = 0
    local seenEnemyIds = {}
    local pendingSpawnShots = {}
    local pendingSpawnSet = {}
    while true do
        task.wait(0.01)
        local active = Config.AutoShootSlimeGun or Config.AutoFarmSlimes
        if active then
            pcall(function()
                local gameplay = GameplayServiceClient.gameplay
                if gameplay and gameplay.enemies then
                    local targets = getShootEnemyList(gameplay.enemies)
                    if #targets > 0 then
                        local liveIds = {}
                        for _, target in ipairs(targets) do
                            liveIds[target.id] = true
                            if not seenEnemyIds[target.id] and not pendingSpawnSet[target.id] then
                                table.insert(pendingSpawnShots, target.id)
                                pendingSpawnSet[target.id] = true
                            end
                            seenEnemyIds[target.id] = true
                        end
                        for enemyId in pairs(seenEnemyIds) do
                            if not liveIds[enemyId] then
                                seenEnemyIds[enemyId] = nil
                                pendingSpawnSet[enemyId] = nil
                            end
                        end
                        local upgrades = getUpgradeData()
                        local fireRate = GoopGunServiceUtils.getFireRate(upgrades)
                        if not fireRate or fireRate <= 0 then
                            fireRate = 0.167
                        end
                        local now = os.clock()
                        if now - lastShotAt >= math.max(fireRate * 0.85, 0.03) then
                            local targetId = nil
                            while #pendingSpawnShots > 0 and not targetId do
                                local queuedId = table.remove(pendingSpawnShots, 1)
                                pendingSpawnSet[queuedId] = nil
                                if liveIds[queuedId] then
                                    targetId = queuedId
                                end
                            end
                            if not targetId then
                                if nextShootIndex > #targets then
                                    nextShootIndex = 1
                                end
                                targetId = targets[nextShootIndex].id
                                nextShootIndex = nextShootIndex + 1
                            end
                            if targetId then
                                lastShotAt = now
                                task.spawn(function()
                                    pcall(function()
                                        Services.SlimeGun:InvokeServer("tryFireSlimeGun", targetId)
                                    end)
                                end)
                            end
                        end
                    else
                        nextShootIndex = 1
                        seenEnemyIds = {}
                        pendingSpawnShots = {}
                        pendingSpawnSet = {}
                    end
                end
            end)
        else
            nextShootIndex = 1
            seenEnemyIds = {}
            pendingSpawnShots = {}
            pendingSpawnSet = {}
        end
    end
end)
task.spawn(function()
    while true do
        task.wait(0.02)
        local active = Config.AutoFarmSlimes
        if active and not isTeleporting then
            pcall(function()
                local gameplay = GameplayServiceClient.gameplay
                if gameplay and gameplay.enemies then
                    local targetId, targetEnemy = getBestEnemy(gameplay.enemies)
                    local character = LocalPlayer.Character
                    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
                    if rootPart then
                        if targetEnemy then
                            local pos = targetEnemy.model:GetPivot().Position
                            if pos then
                                pcall(equipSlimeGun)
                                rootPart.Anchored = true
                                rootPart.CFrame = CFrame.new(pos.X, pos.Y, pos.Z)
                                rootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                            end
                        else
                            if rootPart.Anchored then
                                rootPart.Anchored = false
                            end
                        end
                    end
                end
            end)
        else
            pcall(function()
                local character = LocalPlayer.Character
                local rootPart = character and character:FindFirstChild("HumanoidRootPart")
                if rootPart and rootPart.Anchored then
                    rootPart.Anchored = false
                end
            end)
        end
    end
end)
task.spawn(function()
    while true do
        task.wait()
        if Config.AutoUpgradeSlimes then
            pcall(function()
                local inventory = DataServiceClient:get("inventory") or {}
                local equipped = getEquippedSlimes()
                for _, slimeUid in ipairs(equipped) do
                    local slime = inventory[slimeUid]
                    if slime then
                        local level = slime.level or 1
                        local spentPoints = 0
                        local ownedUpgrades = slime.upgrades or {}
                        for treeKey, tree in pairs(SlimeUpgradeTreeNodes) do
                            for _, nodeId in ipairs(tree.nodes) do
                                if ownedUpgrades[nodeId] then
                                    spentPoints = spentPoints + 1
                                end
                            end
                        end
                        local availablePoints = math.max(0, level - 1) - spentPoints
                        local unlockedTrees = slime.unlockedTrees or {}
                        for treeKey, tree in pairs(SlimeUpgradeTreeNodes) do
                            if not unlockedTrees[tree.origin] then
                                if Config.SlimeUpgradesUseFruits then
                                    local fruitAmount = getItemAmount(tree.fruit)
                                    if fruitAmount >= 3 then
                                        Services.SlimeUpgrade:InvokeServer("requestUnlock", slimeUid, tree.origin)
                                    end
                                end
                            else
                                for idx, nodeId in ipairs(tree.nodes) do
                                    if not ownedUpgrades[nodeId] then
                                        local dep = (idx == 1) and tree.origin or tree.nodes[idx - 1]
                                        local depMet = (dep == tree.origin and unlockedTrees[dep]) or ownedUpgrades[dep]
                                        if depMet and availablePoints >= 1 then
                                            Services.SlimeUpgrade:InvokeServer("requestUnlock", slimeUid, nodeId)
                                            availablePoints = availablePoints - 1
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end)
        end
    end
end)
task.spawn(function()
    local lastStartedRecipe = nil
    local lastMachineId = nil
    while true do
        task.wait(0.5)
        if Config.AutoCraftSelected then
            pcall(function()
                local recipeId = Config.SelectedCraftRecipe
                local activeAutoCrafts = DataServiceClient:get("activeAutoCrafts") or {}
                local pos, machineInst = getCraftingMachinePosition()
                if machineInst then
                    local machineId = getMachineZoneId(machineInst)
                    local craftState = activeAutoCrafts[machineId]
                    local isCurrentlyCraftingThis = craftState and craftState.recipeId == recipeId
                    if not isCurrentlyCraftingThis then
                        local ingredientUids = findIngredientsForRecipe(recipeId)
                        if ingredientUids then
                            local character = LocalPlayer.Character
                            local rootPart = character and character:FindFirstChild("HumanoidRootPart")
                            if Config.AutoTpToCrafting and rootPart and pos then
                                rootPart.CFrame = CFrame.new(pos + Vector3.new(0, 3, 4))
                                task.wait(0.2)
                            end
                            local success = Services.Crafting:InvokeServer("requestStartAutoCraft", recipeId, ingredientUids, 999, machineId)
                            if success then
                                lastStartedRecipe = recipeId
                                lastMachineId = machineId
                                Library:Notify("Started native auto-crafting for " .. recipeId .. "!", 3)
                            end
                        end
                    end
                end
            end)
        else
            if lastStartedRecipe and lastMachineId then
                pcall(function()
                    Services.Crafting:InvokeServer("requestStopAutoCraft", lastMachineId)
                end)
                lastStartedRecipe = nil
                lastMachineId = nil
                Library:Notify("Stopped native auto-crafting.", 3)
            end
        end
    end
end)
task.spawn(function()
    while true do
        task.wait()
        if Config.AutoTpToUfo then
            pcall(function()
                local ufoZone = getActiveUfoZone()
                if ufoZone and not isZoneUnlocked(ufoZone) then
                    Config.AutoTpToUfo = false
                    setToggleValue("AutoTpToUfoToggle", false)
                    notifyOnce("ufo_zone_locked_loop", ("UFO is in Zone %d, but your best unlocked zone is %d. Auto UFO TP disabled."):format(ufoZone, getUnlockedZone()), 4, 10)
                    return
                end
                local pos = getUnlockedUfoDropPosition()
                if pos then
                    local character = LocalPlayer.Character
                    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
                    if rootPart then
                        rootPart.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
                    end
                end
            end)
        end
    end
end)
task.spawn(function()
    while true do
        task.wait(1)
        if Config.AutoExtractFruits then
            pcall(function()
                local inventory = DataServiceClient:get("inventory")
                local equipped = getEquippedSlimes()
                if inventory and #equipped > 0 then
                    local equippedSet = {}
                    for _, uid in ipairs(equipped) do
                        equippedSet[uid] = true
                    end
                    for uid, slime in pairs(inventory) do
                        if slime.fruit and not equippedSet[uid] then
                            Services.FruitExtractor:InvokeServer("requestExtractFruits", uid)
                            task.wait(0.2)
                        end
                    end
                end
            end)
        end
    end
end)
task.spawn(function()
    while true do
        task.wait(1)
        if Config.AutoPauseSpecialRolls then
            pcall(function()
                local progression = DataServiceClient:get("specialRollProgression")
                if progression then
                    local isAnyLuckBoost = isBoostActive("luck") or isBoostActive("ultraLuck")
                    local rolls = { "golden", "diamond", "void", "galaxy" }
                    for _, rollType in ipairs(rolls) do
                        local rollData = progression[rollType]
                        if rollData then
                            local shouldPause = not isAnyLuckBoost
                            if rollData.paused ~= shouldPause then
                                pcall(function()
                                    Services.Roll:InvokeServer("requestSetSpecialRollPaused", rollType, shouldPause)
                                end)
                            end
                        end
                    end
                end
            end)
        end
    end
end)
pcall(function()
    LiveFarmState.lastGoop = DataServiceClient:get("goop") or 0
    DataServiceClient:getChangedSignal("goop"):Connect(function(newGoop)
        local currentGoop = newGoop or DataServiceClient:get("goop") or 0
        local previousGoop = LiveFarmState.lastGoop
        LiveFarmState.lastGoop = currentGoop
        if previousGoop and currentGoop > previousGoop then
            local zoneId = tonumber(DataServiceClient:get("zone") or LiveFarmState.currentZone or 1) or 1
            local stats = getLiveZoneStats(zoneId, LiveFarmState.currentSignature)
            stats.goopGained = stats.goopGained + (currentGoop - previousGoop)
            stats.lastSeenAt = os.clock()
        end
    end)
end)
pcall(function()
    local GameplayClientClass = require(Features:WaitForChild("Gameplay"):WaitForChild("Classes"):WaitForChild("GameplayClient"))
    if GameplayClientClass and GameplayClientClass.enemyRemovedSignal then
        GameplayClientClass.enemyRemovedSignal:Connect(function()
            local zoneId = tonumber(DataServiceClient:get("zone") or LiveFarmState.currentZone or 1) or 1
            local stats = getLiveZoneStats(zoneId, LiveFarmState.currentSignature)
            stats.kills = stats.kills + 1
            stats.lastKillAt = os.clock()
            stats.lastSeenAt = stats.lastKillAt
        end)
    end
end)
task.spawn(function()
    while true do
        task.wait(2)
        pcall(function()
            local currentZone = tonumber(DataServiceClient:get("zone") or 1) or 1
            if LiveFarmState.currentZone ~= currentZone then
                LiveFarmState.currentZone = currentZone
                LiveFarmState.zoneStartedAt = os.clock()
            end
            local teamDmg = getTeamDamage()
            local currentUpgradeInfo = getFarmUpgradeInfo(getUpgradeData())
            LiveFarmState.currentSignature = getFarmBuildSignature(teamDmg, currentUpgradeInfo)
            getLiveZoneStats(currentZone, LiveFarmState.currentSignature)
            local optimal, rates, maxRates, rebirthInfo = getOptimalFarmingZone()
            local zoneInfo = optimal and ZonesController.getZone(optimal)
            local zoneName = zoneInfo and zoneInfo.name or "Unknown"
            TeamDamageLabel:SetText(string.format("Team DMG: %s", fmtNum(teamDmg)))
            OptimalZoneLabel:SetText(string.format("%s: Z%d %s", rates and rates.modeNote or "Eff Zone", optimal or 1, zoneName))
            if rates then
                OptimalKillRateLabel:SetText(string.format("K: %.2f/s T: %.2fs", rates.killsPerSecond, rates.timeToKill))
                OptimalCoinRateLabel:SetText(string.format("C/s: %s", fmtNum(rates.coinsPerSecond)))
                OptimalGoopRateLabel:SetText(string.format("G/s: %s", fmtNum(rates.goopPerSecond)))
                RebirthNeedLabel:SetText(string.format("Need: %s goop", fmtNum(rebirthInfo and rebirthInfo.needed or 0)))
                RebirthEtaLabel:SetText(string.format("ETA: %s", fmtDuration(rates.rebirthEtaSeconds)))
                local upg = rates.upgradeInfo
                if upg then
                    FarmUpgradeLabel:SetText(string.format(
                        "Upg: Gun %s FR%d DMG%d | Goop %s G%d D%d",
                        upg.ownsSlimeGun and "Y" or "N",
                        upg.slimeGunFireRateLevel,
                        upg.slimeGunDamageLevel,
                        upg.ownsGoop and "Y" or "N",
                        upg.goopDropLevel,
                        upg.doubleGoopLevel
                    ))
                else
                    FarmUpgradeLabel:SetText("Upg: n/a")
                end
                FarmMeasureLabel:SetText(string.format(
                    "%s | cap %.2f/s E%d S%d",
                    Config.EfficientFarmMode or "Balanced Progress",
                    rates.spawnLimitedKillsPerSecond or 0,
                    upg and upg.enemyCountLevel or 0,
                    upg and upg.enemySpawnSpeedLevel or 0
                ))
                local maxKill = maxRates and maxRates.kill
                local maxCoins = maxRates and maxRates.coins
                local maxGoop = maxRates and maxRates.goop
                MaxKillRateLabel:SetText(maxKill and string.format("Max K/s: %.2f Z%d", maxKill.killsPerSecond, maxKill.zone) or "Max K/s: n/a")
                MaxCoinRateLabel:SetText(maxCoins and string.format("Max C/s: %s Z%d", fmtNum(maxCoins.coinsPerSecond), maxCoins.zone) or "Max C/s: n/a")
                MaxGoopRateLabel:SetText(maxGoop and string.format("Max G/s: %s Z%d", fmtNum(maxGoop.goopPerSecond), maxGoop.zone) or "Max G/s: n/a")
            else
                OptimalKillRateLabel:SetText("K: n/a")
                OptimalCoinRateLabel:SetText("C/s: n/a")
                OptimalGoopRateLabel:SetText("G/s: n/a")
                RebirthNeedLabel:SetText("Need: n/a")
                RebirthEtaLabel:SetText("ETA: n/a")
                FarmUpgradeLabel:SetText("Upg: n/a")
                FarmMeasureLabel:SetText("Mode: n/a")
                MaxKillRateLabel:SetText("Max K/s: n/a")
                MaxCoinRateLabel:SetText("Max C/s: n/a")
                MaxGoopRateLabel:SetText("Max G/s: n/a")
            end
            if Config.EfficientFarm then
                local current = DataServiceClient:get("zone")
                if optimal and current and current ~= optimal then
                    teleportToZone(optimal)
                end
            end
        end)
    end
end)
