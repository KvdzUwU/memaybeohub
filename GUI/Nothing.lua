repeat task.wait() until game:IsLoaded()
repeat task.wait() until game.Players
repeat task.wait() until game.Players.LocalPlayer
wait(5)
local L = loadstring(game:HttpGet("https://raw.githubusercontent.com/KvdzCoder/memaybeo/main/OrionLib.lua"))()

local RS = game:GetService("ReplicatedStorage")
local WS = game:GetService("Workspace")
local P = game:GetService("Players")
local VIM = game:GetService("VirtualInputManager")
local RunS = game:GetService("RunService")
local player = P.LocalPlayer
local character = player.Character
local PlayerGui = player.PlayerGui

local REMOTE = RS.Remote
local BINDABLE = RS.Bindable
local mobs = {}
local eggData = {}
local eggDisplayNameToNameLookUp = {}
local petsToFuse = {}
local store = require(RS.ModuleScripts.LocalDairebStore)
local data = store.GetStoreProxy("GameData")
local Ignore_Rarities = {"Mythical", "Secret", "Raid", "Divine"}
local Ignore_World = {"Raid", "Tower", "Titan", "Christmas"}
local passivesToKeep = {}
local objectives = PlayerGui.MainGui.Quest.Objectives
local passiveStats = require(RS.ModuleScripts.PassiveStats)
local eggStats = require(RS.ModuleScripts.EggStats)
local petStats = require(RS.ModuleScripts.PetStats)
local Open = 20
local PET_TEXT_FORMAT = "%s (%s) | UID: %s | Level %s"

--Main
local selectedMob = nil
local autoFarm = nil
local farmAllMobs = nil
local autoQuest = nil
local autoClick = nil
local autoCollect = nil
local equippingTeam = false
local reEquippingPets = false
local Mintute = nil
local walkspeed = 50
local jumpPower = 50
local autoOpen = nil
local selectedFuse = nil
local autoFuse = nil
local passiveMachine = nil
local slotPassive = nil
local selecteduse = nil
local useToken = false
local pettoRoll = nil
local autoSecret = nil

----Functions
---Anti AFK
function AntiAFK()
    player.Idled:Connect(function()
            VU:Button2Down(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
            task.wait(1)
            VU:Button2Up(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
        end)
        warn("ANTI-AFK: ON")
end
---Get Pet
function getPets()
    return data:GetData("Pets")
end

--GetPetTextFormat
function getPetTextFormat(pet)
    local displayName = petStats[pet.PetId].DisplayName or player.Name --VIP character
    return string.format(PET_TEXT_FORMAT, pet.CustomName, displayName, pet.UID, pet.Level)
end

---Passive
--pet to Roll info
function getPetsToRollInto()
    table.clear(pettoRoll)
    local pets = getPets()
    for _, pet in pairs(pets) do
        table.insert(pettoRoll, getPetTextFormat(pet))
    end
    return pettoRoll
end

function getRollablePets()
    local pets = getPets()
    local fuseable = {}
    local equippedPets = getEquippedPetsDict()
    for _, pet in pairs(pets) do
        local id = pet.PetId
        local canFuse = false
        local expression = pet.Passive and (pet.Passive == "Luck3" or passivesToKeep[pet.Passive])

        if not expression then
            if not equippedPets[pet.UID] then
                local rarity = petStats[id].Rarity

                if id ~= "VIP" and rarity ~= "Secret" and rarity ~= "Divine" and rarity ~= "Special" then
                    if not table.find(IGNORED_RARITIES, rarity) then
                        canFuse = true
                    elseif rarity == "Mythical" and not pet.Shiny then
                        canFuse = true
                    elseif rarity == "Raid" and not pet.Shiny then
                        canFuse = true
                    end
                end

                if canFuse then
                    table.insert(fuseable, pet.UID)
                end
            end
        end
    end

    return fuseable
end
--check use to roll passive
spawn(function()
	while task.wait(30) do
if selecteduse == "Token" then
    useToken = true
else
    useToken = false
end
		end
	end)

--Pet To Fuse
function getFuseablePets()
    local pets = getPets()
    local fuseable = {}
    local equippedPets = getEquippedPetsDict()
    for _, pet in pairs(pets) do
        local id = pet.PetId
        local canFuse = false
        local expression = pet.Passive and (pet.Passive == "Luck3" or passivesToKeep[pet.Passive])
        if not expression then
            if not equippedPets[pet.UID] then
                local rarity = petStats[id].Rarity
                if id ~= "VIP" and rarity ~= "Secret" and rarity ~= "Divine" and rarity ~= "Special" then
                    if not table.find(Ignore_Rarities, rarity) then
                        canFuse = true
                    elseif rarity == "Mythical" and not pet.Shiny then
                        canFuse = true
                    elseif rarity == "Raid" and not pet.Shiny then
                        canFuse = true
                    end
                end

                if canFuse then
                    table.insert(fuseable, pet.UID)
                end
            end
        end
    end

    return fuseable
end

function getPetsToFuseInto()
    table.clear(petsToFuse)
    local pets = getPets()

    for _, pet in pairs(pets) do
        table.insert(petsToFuse, getPetTextFormat(pet))
    end
    return petsToFuse
end

--Star Data
function getEggStats()
    for eggName, info in pairs(eggStats) do
        if info.Currency ~= "Robux" and not info.Hidden then
            local eggModel = WS.Worlds:FindFirstChild(eggName, true)
            local s = string.format("%s (%s)", info.DisplayName, eggName)
            table.insert(eggData, s)
            eggDisplayNameToNameLookUp[s] = eggName
        end
    end
    return eggData
end

--getMobs
function getMobs()
    for _, enemy in ipairs(WS.Worlds[player.World.Value].Enemies:GetChildren()) do
        if not table.find(mobs, enemy.DisplayName.Value) then
            table.insert(mobs, enemy.DisplayName.Value)
        end
    end
    return mobs
end

--getTarget
function getTarget(name, world)
    if not table.find(Ignore_World, world) then
        local enemies = WS.Worlds[world].Enemies
        for _, enemy in ipairs(enemies:GetChildren()) do
            if enemy:FindFirstChild("DisplayName") and enemy.DisplayName.Value == name and enemy:FindFirstChild("HumanoidRootPart") then
                return enemy
            end
        end
    end
end

--retreat
function retreat()
    VIM:SendKeyEvent(true,"R",false,game)
end

--movePetsToPlayer
function movePetsToPlayer()
    for _, pet in ipairs(player.Pets:GetChildren()) do
        local targetPart = pet.Value:FindFirstChild("TargetPart")
        local humanoidRootPart = pet.Value:FindFirstChild("HumanoidRootPart")

        if targetPart and humanoidRootPart then
            targetPart.CFrame = character.HumanoidRootPart.CFrame
            humanoidRootPart.CFrame = character.HumanoidRootPart.CFrame
        end
    end
end

--Re Equip Pets
function unequipPets()
    local uids = {}
    for _, pet in ipairs(player.Pets:GetChildren()) do
        local UID = pet.Value.Data.UID.Value
        table.insert(uids, UID)
        REMOTE.ManagePet:FireServer(UID, "Unequip")
    end
    return uids
end

function equipPets(uids)
    for i, uid in ipairs(uids) do
        REMOTE.ManagePet:FireServer(uid, "Equip", i)
    end
end

function equipTeam(teamTab)
    equippingTeam = true
    task.wait(0.1)
    unequipPets()
    task.wait(0.1)
    equipPets(teamTab)
    equippingTeam = false
end

function reEquipPets()
    while equippingTeam do
        task.wait()
    end
    reEquippingPets = true
    local uids = unequipPets()
    task.wait()
    equipPets(uids)
    reEquippingPets = false
end

function initHiddenUnitsFolder()
        if not RS:FindFirstChild("HIDDEN_UNITS") then
            local folder = Instance.new("Folder")
            folder.Name = "HIDDEN_UNITS"
            folder.Parent = RS
        end
end

function init()
        getMobs()
        getPetsToFuseInto()
        getEggStats()
        initHiddenUnitsFolder()
        antiAFK()

        player.CharacterAdded:Connect(onCharacterAdded)
        warn("Init completed")
    end
init()    
local A =
    L:MakeWindow(
    {
        Name = "Jerry Premium | AFS",
        IntroEnabled = true,
        IntroText = "Jerry Hub",
        IntroIcon = "rbxassetid://14299284116",
        HidePremium = false,
        SaveConfig = true,
        ConfigFolder = "Jerry Hub"
    }
)

local B = A:MakeTab({Name = "Main", Icon = "rbxassetid://14299284116", PremiumOnly = false})
local C = A:MakeTab({Name = "Local Player", Icon = "rbxassetid://14299284116", PremiumOnly = false})
local D = A:MakeTab({Name = "Star", Icon = "rbxassetid://14299284116", PremiumOnly = false})
local E = A:MakeTab({Name = "TT/Meteor/DF", Icon = "rbxassetid://14299284116", PremiumOnly = false})
local F = A:MakeTab({Name = "Teleport", Icon = "rbxassetid://14299284116", PremiumOnly = false})
local G = A:MakeTab({Name = "Auto Passive", Icon = "rbxassetid://14299284116",PremiumOnly = false})
local H = A:MakeTab({Name = "Misc", Icon = "rbxassetid://14299284116",PremiumOnly = false})
local I = A:MakeTab({Name = "Other", Icon = "rbxassetid://14299284116",PremiumOnly = false})
L:MakeNotification({Name = "Jerry Hub", Content = "Loading Anime Fighter Simulator", Image = "rbxassetid://14299284116", Time = 10})

B:AddSection({Name = "Farm"})

local mobsDropdown = B:AddDropdown(
    {
        Name = "Select Mobs",
        Default = nil,
        Options = mobs,
        Callback = function(v)
            selectedMob = v
        end
    }
)

B:AddButton(
    {
        Name = "Refresh Mobs",
        Callback = function()
            selectedMob = nil
            mobs = {}
            mobs = getMobs()
            mobsDropdown:Refresh(mobs, true)
        end
    }
)

B:AddToggle(
    {
        Name = "Farm Selected Mob",
        Default = false,
        Callback = function(v)
            autoFarm = v
        end
    }
)

B:AddToggle(
    {
        Name = "Farm All Mobs",
        Default = false,
        Callback = function(v)
            farmAllMobs = v
        end
    }
)

B:AddToggle(
    {
        Name = "Auto Quest",
        Default = false,
        Callback = function(v)
            autoQuest = v
        end
    }
)

B:AddSection({Name = "Extra"})

B:AddToggle(
    {
        Name = "Auto Click Damage",
        Default = false,
        Callback = function(v)
            autoClick = v
        end
    }
)

B:AddToggle(
    {
        Name = "Auto Collect",
        Default = false,
        Callback = function(v)
            autoCollect = v
        end
    }
)

B:AddToggle(
    {
        Name = "Attack while Ult",
        Default = false,
        Callback = function(v)
            ultskip = v
        end
    }
)

B:AddDropdown(
    {
        Name = "Time to Re Equipt Pets",
        Default = nil,
        Options = {"3", "5", "10", "15", "30"},
        Callback = function(v)
            Mintute = v
        end
    }
)

B:AddToggle(
    {
        Name = "Auto Re Equipt Pets",
        Default = false,
        Callback = function(v)
            autoReEquipPets = v
        end
    }
)

C:AddSection({Name = "Local Player"})

C:AddSlider(
    {
        Name = "Walk Speed",
        Min = 16,
	    Max = 200,
	    Default = 50,
	    Color = Color3.fromRGB(255,255,255),
	    Increment = 10,
	    ValueName = "Walk Speed",
        Callback = function(v)
            walkspeed = v
            character.Humanoid.WalkSpeed = v
        end
    }
)

C:AddSlider(
    {
        Name = "Walk Speed",
        Min = 16,
	    Max = 500,
	    Default = 50,
	    Color = Color3.fromRGB(255,255,255),
	    Increment = 10,
	    ValueName = "Walk Speed",
        Callback = function(v)
            jumpPower = v
            character.Humanoid.JumpPower = v
        end
    }
)

D:AddSection({Name = "Auto Open"})

D:AddDropdown(
    {
        Name = "Select Star",
        Default = nil,
        Options = eggData,
        Callback = function(v)
            Star = eggDisplayNameToNameLookUp[v]
        end
    }
)

D:AddToggle(
    {
        Name = "Auto Open",
        Default = false,
        Callback = function(v)
            autoOpen = v
        end
    }
)

D:AddToggle(
    {
        Name = "Auto Max Open",
        Default = false,
        Callback = function(v)
            MaxOpen = v
        end
    }
)

D:AddSection({Name = "Auto Fuse"})

local fighterFuseDropdown = D:AddDropdown(
    {
        Name = "Select Fighter To Fuse",
        Default = nil,
        Options = petsToFuse,
        Callback = function(v)
            selectedFuse = v
        end
    }
)

D:AddButton(
    {
        Name = "Refresh Fuse",
        Callback = function()
            selectedFuse = nil
            petsToFuse = getPetsToFuseInto()
            fighterFuseDropdown:Refresh(petsToFuse, true)
        end
    }
)

D:AddToggle(
    {
        Name = "Auto Fuse",
        Default = false,
        Callback = function(v)
            autoFuse = v
        end
    }
)

G:AddDropdown(
    {
        Name = "Select Passive Machine",
        Default = nil,
        Options = {"Normal", "Summer", "Requiem"},
        Callback = function(v)
            passiveMachine = v
        end
    }
)

G:AddDropdown(
    {
        Name = "Select Slot",
        Default = nil,
        Options = {"1", "2"},
        Callback = function(v)
            slotPassive = v
        end
    }
)

G:AddDropdown(
    {
        Name = "Select Use",
        Default = nil,
        Options = {"Shard", "Token"},
        Callback = function(v)
            selecteduse = v
        end
    }
)

G:AddDropdown(
    {
        Name = "Select Fighter to Roll",
        Default = nil,
        Options = petsToFuse,
        Callback = function(v)
            pettoRoll = v
        end
    }
)
---Auto Passive

---Star
--Auto Fuse
spawn(function()
    while task.wait() do
        if autoFuse and selectedFuse then
            local petToFuse
            local petsToFeed = getFuseablePets()
            if petsToFeed and petToFuse then
                REMOTE.FeedPets:FireServer(petsToFeed, petToFuse)
            end
            task.wait(2)
            table.clear(petsToFeed)
            table.clear(pets)
            petsToFeed = nil
            petToFuse = nil
        elseif autoFuse and not selectedFuse then
            L:MakeNotification({Name = "Error", Content = "Select Fighter to Fuse", Image = "rbxassetid://14299284116", Time = 5})
            task.wait(3)
        end
    end
end)

--Max Open
spawn(function()
    while task.wait(1) do
        if MaxOpen and Star then
            REMOTE.AttemptMultiOpen:FireServer(Star)
        end
    end
end)

--Auto Open
spawn(function()
    local conn
    conn = RunS.RenderStepped:Connect(function()
    if not autoOpen then
        conn:Disconnect()
        conn = nil
        autoOpen = nil
        Star = nil
        return
    end
        if autoOpen and Star ~= nil and not table.find(Ignore_World, player.World.Value) then
            spawn(function()
                if selectedEggAutoSummon then
                    local egg = WS.Worlds:FindFirstChild(selectedEggAutoSummon, true)
                    if egg then
                        REMOTE.OpenEgg:InvokeServer(egg, Open)
                    end
                end
            end)
        end
    end)
end)

---Local Player
--Jump Power 
character.Humanoid:GetPropertyChangedSignal("JumpPower"):Connect(function()
    local newJumpPower = character.Humanoid.JumpPower

    if newJumpPower < jumpPower then
        character.Humanoid.JumpPower = jumpPower
    end
end)

--Walk Speed
character.Humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
    local newWalkSpeed = character.Humanoid.WalkSpeed

    if newWalkSpeed < walkspeed then
        character.Humanoid.WalkSpeed = walkspeed
    end
end)

---Main
--Auto Re Equip Pets
spawn(function()
    while task.wait(1) do
        if autoReEquipPets then
            reEquipPets()
            task.wait(Mintute*60)
        end
    end
end)

--Toggle Speed
function setPetSpeed(speed)
    for _, tab in pairs(passiveStats) do
        if tab.Effects then
            tab.Effects.Speed = speed
        end
    end
    reEquipPets()
end

--Attack while ult
spawn(function()
    while task.wait(0.3) do
        if ultskip then
            for _, pet in pairs(player.Pets:GetChildren()) do
                task.spawn(function()
                    REMOTE.PetAttack:FireServer(pet.Value)
                    REMOTE.PetAbility:FireServer(pet.Value)
                end)
            end
        end
    end
end)

--Auto Collect
spawn(function()
    while task.wait() do
        if autoCollect then
            for _, v in ipairs(WS.Effects:GetDescendants()) do
                if v.Name == "Base" then
                    v.CFrame = character.HumanoidRootPart.CFrame
                end
            end
        end
    end
end)

--Auto Click Damage
spawn(function()
    local conn
    conn = RunS.RenderStepped:Connect(function()
        if not autoClick then
            conn:Disconnect()
            conn = nil
            autoClick = nil
            return
        end
        if autoClick then
            REMOTE.ClickerDamage:FireServer()
            REMOTE.ClickerDamage:FireServer()
        end
    end)
end)

---auto Quest
--auto Accept Quest
spawn(function()
    while task.wait() do
        if autoQuest and not table.find(Ignore_World, player.World.Value) then
            local NPC = WS.Worlds[player.World.Value][player.World.Value]
            REMOTE.StartQuest:FireServer(NPC)
            REMOTE.FinishQuest:FireServer(NPC)
            REMOTE.FinishQuestline:FireServer(NPC)
        end
    end
end)

--auto Farm Quest
spawn(function()
    while task.wait() do
        if autoQuest and objectives:FindFirstChild("QuestText") and not table.find(Ignore_World, player.World.Value) then
            for _, obj in ipairs(objectives:GetChildren()) do
                if obj.Name == "QuestText" and obj.TextColor3 ~= Color3.fromRGB(0, 242, 38) then
                    local world = WS.Worlds[player.World.Value]
                    local enemySpawns = world.EnemySpawners
                    local enemyModels = world.Enemies:GetChildren()
                    for _, enemy in ipairs(enemyModels) do
                        if enemy:FindFirstChild("HumanoidRootPart") and enemy:FindFirstChild("Health") and enemy.Health.Value > 0 then
                            local found = string.match(obj.Text, enemy.DisplayName.Value)
                            if found then
                                local enemySpawn
                                for _, spawn in ipairs(enemySpawns:GetChildren()) do
                                    if spawn.CurrentEnemy.Value == enemy then
                                        enemySpawn = spawn
                                        break
                                    end
                                end
                                if enemySpawn and enemy ~= nil and enemy:FindFirstChild("Attackers") then
                                    character.HumanoidRootPart.CFrame = enemy.HumanoidRootPart.CFrame
                                    movePetsToPlayer()
                                    task.wait()
                                    repeat
                                        if enemy ~= nil and enemy:FindFirstChild("Attackers") and table.find(enemyModels, enemy) then
                                            BINDABLE.SendPet:Fire(enemy, true)
                                        end
                                        enemy = enemySpawn.CurrentEnemy.Value
                                        task.wait()
                                    until _G.disabled
                                    or player.World.Value ~= world.Name
                                    or enemy == nil
                                    or enemy:FindFirstChild("Attackers") == nil
                                    or table.find(enemyModels, enemy) == nil
                                    or not autoQuest
                                    or table.find(Ignore_World, player.World.Value)
                                end
                                retreat()
                            end
                        end
                    end
                    table.clear(enemyModels)
                    ememyModels = nil
                end
            end
        end
    end
end)

--Farm All Mobs
spawn(function()
    while task.wait() do
        if farmAllMobs and not autoFarm and not table.find(Ignore_World, player.World.Value) then
            local cWorld = player.World.Value
            local enemySpawns = WS.Worlds[cWorld].EnemySpawners
            local enemyModels = WS.Worlds[cWorld].Enemies:GetChildren()

            for _, target in ipairs(enemyModels) do
                if not farmAllMobs then
                    break
                end

                if target:FindFirstChild("Attackers") then
                    local enemySpawn

                    for _, spawn in ipairs(enemySpawns:GetChildren()) do
                        if spawn.CurrentEnemy.Value == target then
                            enemySpawn = spawn
                            break
                        end
                    end

                    if enemySpawn ~= nil then
                        character.HumanoidRootPart.CFrame = target.HumanoidRootPart.CFrame
                        movePetsToPlayer()

                        repeat
                            if target ~= nil and target:FindFirstChild("Attackers") and table.find(enemyModels, target) then
                                BINDABLE.SendPet:Fire(target, true)
                            end
                            target = enemySpawn.CurrentEnemy.Value
                            task.wait()
                        until _G.disabled
                        or player.World.Value ~= cWorld
                        or target == nil
                        or target:FindFirstChild("Attackers") == nil
                        or table.find(enemyModels, target) == nil
                        or not farmAllMobs
                        or table.find(Ignore_World, player.World.Value)
                        retreat()
                    end
                end
            end
            table.clear(enemyModels)
            ememyModels = nil
        elseif farmAllMobs and autoFarm then
            L:MakeNotification({Name = "Error", Content = "Can only 1 Farm", Image = "rbxassetid://14299284116", Time = 5})
            task.wait(5)
        end
    end
end)

--Farm Selected Mob
spawn(function()
    while task.wait() do
        if autoFarm and not farmAllMobs and selectedMob and not table.find(Ignore_World, player.World.Value) then
            local cWorld = player.World.Value
            local target = getTarget(selectedMob, cWorld)
            local enemySpawns = WS.Worlds[cWorld].EnemySpawners
            local enemyModels = WS.Worlds[cWorld].Enemies:GetChildren()

            if target ~= nil and target:FindFirstChild("Attackers") then
                local enemySpawn

                for _, spawn in ipairs(enemySpawns:GetChildren()) do
                    if spawn.CurrentEnemy.Value == target then
                        enemySpawn = spawn
                        break
                    end
                end

                if enemySpawn ~= nil then
                    character.HumanoidRootPart.CFrame = target.HumanoidRootPart.CFrame

                    repeat
                        if target ~= nil and target:FindFirstChild("Attackers") and table.find(enemyModels, target) then
                            BINDABLE.SendPet:Fire(target, true)
                        end

                        target = enemySpawn.CurrentEnemy.Value
                        task.wait()
                    until _G.disabled
                    or player.World.Value ~= cWorld
                    or target == nil
                    or target:FindFirstChild("Attackers") == nil
                    or table.find(enemyModels, target) == nil
                    or not autoFarm
                    or table.find(Ignore_World, player.World.Value)
                    retreat()
                end
            end
            table.clear(enemyModels)
            ememyModels = nil
        elseif autoFarm and not selectedMob then
            L:MakeNotification({Name = "Error", Content = "Select Mob", Image = "rbxassetid://14299284116", Time = 5})
            task.wait(5)
        elseif autoFarm and farmAllMobs then
            L:MakeNotification({Name = "Error", Content = "Can only 1 Farm", Image = "rbxassetid://14299284116", Time = 5})
            task.wait(5)
        end
    end
end)

L:Init()
