local currentWave = 0
local enemiesLeft = 0
local activeEnemies = {}
local activeWave = nil
local isPracticing = false
local currentDifficulty = nil
local currentArenaIndex = nil

local arenaExitCoords = vector3(1371.439, -589.892, 73.189)

local difficultyRewards = {
    Easy = 200,
    Medium = 350,
    Hard = 500
}

local difficultyEnemyCounts = {
    Easy = 5,
    Medium = 10,
    Hard = 15,
}

exports['qtarget']:AddBoxZone('practice_target', Config.TargetCoords, 1.5, 1.5, {
    name = 'practice_target',
    heading = Config.PedHeading,
    debugPoly = false,
    minZ = Config.TargetCoords.z - 1,
    maxZ = Config.TargetCoords.z + 1,
}, {
    options = {
        {
            icon = 'fas fa-bullseye',
            label = 'Start Practice',
            action = function()
                TriggerEvent('ad-practice:start')
            end
        }
    },
    distance = 2.5
})

RegisterNetEvent('ad-practice:start', function()
    lib.registerContext({
        id = 'ad_difficulty',
        title = 'Select Difficulty',
        description = 'End practice early with /endpractice',
        options = {
            { title = 'Easy', description = '5 enemies', event = 'ad-practice:startWaves', args = { difficulty = 'Easy' } },
            { title = 'Medium', description = '10 enemies', event = 'ad-practice:startWaves', args = { difficulty = 'Medium' } },
            { title = 'Hard', description = '15 enemies', event = 'ad-practice:startWaves', args = { difficulty = 'Hard' } },
            { title = 'End Practice', description = 'End the practice early using /endpractice command', disabled = true }
        }
    })

    lib.showContext('ad_difficulty')
end)

local function shuffle(tbl)
    for i = #tbl, 2, -1 do
        local j = math.random(1, i)
        tbl[i], tbl[j] = tbl[j], tbl[i]
    end
end

local function buildWaveDataForArena(arenaIndex, difficulty)
    local arena = Config.Locations[arenaIndex]
    if not arena then return nil end

    local enemySpawns = arena.enemySpawns
    local enemyCount = difficultyEnemyCounts[difficulty] or 5

    local waves = {}

    for i = 1, enemyCount do
        local spawnIndex = ((i - 1) % #enemySpawns) + 1
        local pos = enemySpawns[spawnIndex]

        local armor = 0
        if difficulty == 'Medium' then armor = 50
        elseif difficulty == 'Hard' then armor = 100
        end

        table.insert(waves, {
            model = 's_m_y_blackops_01',
            coords = vector3(pos.x, pos.y, pos.z),
            heading = pos.w or 0.0,
            health = 200,
            armor = armor,
        })
    end

    return waves
end

RegisterNetEvent('ad-practice:startWaves', function(data)
    local difficulty = data.difficulty
    if not difficultyEnemyCounts[difficulty] then
        lib.notify({ title = 'Error', description = 'Invalid difficulty selected.', type = 'error' })
        return
    end

    local arenaCount = #Config.Locations
    currentArenaIndex = math.random(1, arenaCount)
    local arena = Config.Locations[currentArenaIndex]

    currentDifficulty = difficulty

    activeWave = buildWaveDataForArena(currentArenaIndex, difficulty)
    if not activeWave or #activeWave == 0 then
        lib.notify({ title = 'Error', description = 'Failed to build enemy waves.', type = 'error' })
        return
    end

    shuffle(activeWave)

    currentWave = 0
    enemiesLeft = #activeWave
    activeEnemies = {}
    isPracticing = true

    local player = PlayerPedId()

    SetEntityCoords(player, arena.playerSpawn)
    SetEntityHeading(player, 0.0)
    FreezeEntityPosition(player, true)
    lib.notify({ title = 'Practice Starting', description = ('Get Ready! Arena: %s'):format(arena.label), type = 'info' })
    Wait(3000)
    FreezeEntityPosition(player, false)

    lib.showTextUI(('Enemies left: %s'):format(enemiesLeft), { position = 'right-center', icon = 'crosshairs' })

    spawnNextEnemy()
end)

function spawnNextEnemy()
    currentWave = currentWave + 1
    if currentWave > #activeWave then
        CreateThread(function()
            Wait(3000)
            endPractice("You defeated all enemies!", currentDifficulty)
        end)
        return
    end

    local wave = activeWave[currentWave]
    local model = joaat(wave.model)
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(0) end

    local ped = CreatePed(4, model, wave.coords.x, wave.coords.y, wave.coords.z, wave.heading or 0.0, true, false)

    SetEntityAsMissionEntity(ped, true, true)
    SetEntityInvincible(ped, false)
    SetEntityMaxHealth(ped, wave.health)
    SetEntityHealth(ped, wave.health)
    SetPedArmour(ped, wave.armor)
    SetPedFleeAttributes(ped, 0, false)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedDiesWhenInjured(ped, true)

    GiveWeaponToPed(ped, WEAPON_PISTOL, 250, false, true)
    SetCurrentPedWeapon(ped, WEAPON_PISTOL, true)
    SetPedInfiniteAmmo(ped, true, WEAPON_PISTOL)
    SetPedAccuracy(ped, 0)
    SetPedCombatAbility(ped, 0)
    SetPedCanSwitchWeapon(ped, false)

    FreezeEntityPosition(ped, true)

    RequestAnimDict("gestures@m@standing@casual")
    while not HasAnimDictLoaded("gestures@m@standing@casual") do Wait(0) end
    TaskPlayAnim(ped, "gestures@m@standing@casual", "gesture_point", 8.0, -8.0, -1, 1, 0, false, false, false)

    table.insert(activeEnemies, ped)

    CreateThread(function()
        while DoesEntityExist(ped) do
            Wait(250)
            if IsEntityDead(ped) then
                enemiesLeft = enemiesLeft - 1
                DeleteEntity(ped)
                lib.hideTextUI()
                if enemiesLeft > 0 then
                    lib.showTextUI(('Enemies left: %s'):format(enemiesLeft), { position = 'right-center', icon = 'crosshairs' })
                end
                Wait(2000)
                spawnNextEnemy()
                return
            end
        end
    end)
end

function endPractice(msg, difficulty)
    isPracticing = false
    lib.hideTextUI()

    for _, ped in pairs(activeEnemies) do
        if DoesEntityExist(ped) then
            DeleteEntity(ped)
        end
    end
    activeEnemies = {}

    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)

    ClearPedBloodDamage(playerPed)
    ClearPedWetness(playerPed)
    ClearPedEnvDirt(playerPed)

    ClearAreaOfProjectiles(playerCoords, 50.0, 0)
    ClearAreaOfObjects(playerCoords, 50.0, 0)
    ClearAreaOfPeds(playerCoords, 50.0, 1)

    SetEntityCoords(playerPed, arenaExitCoords)

    if difficulty and difficultyRewards[difficulty] then
        local reward = difficultyRewards[difficulty]
    else
        if msg then
            lib.notify({ title = 'Practice Ended', description = msg, type = 'info' })
        end
    end
end

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then
        lib.hideTextUI()
        for _, ped in pairs(activeEnemies) do
            if DoesEntityExist(ped) then DeleteEntity(ped) end
        end
    end
end)
