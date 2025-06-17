Config = {}

Config.TargetCoords = vector3(1371.783, -590.644, 73.179) -- Where you interact with qtarget
Config.PedHeading = 30.0 -- DO NOT CHANGE THIS

Config.Locations = {
    [1] = {
        label = "Area 1", -- Name
        playerSpawn = vector3(1674.163, -63.374, 172.776), -- where the player spawns
        enemySpawns = {
            -- where the enemies spawn
            vector4(1667.503, -28.728, 172.773, 205.0),
            vector4(1664.562, -30.913, 181.768, 205),
            vector4(1670.988, -28.135, 182.768, 195.0),
            vector4(1665.442, -28.537, 195.935, 190.0),
        }
    },

    [2] = {
        label = "Area 2", -- Name
        playerSpawn = vector3(1721.653, -1651.629, 111.552), -- where the player spawns
        enemySpawns = {
            -- where the enemies spawn
            vector4(1716.806, -1616.815, 117.542, 200.0),
            vector4(1745.235, -1599.058, 121.081, 155.0),
            vector4(1735.953, -1600.517, 117.708, 160.0),
            vector4(1735.640, -1615.082, 111.440, 170.0),
        }
    }
}

-- Dynamic wave generation using the above arena data
waveData = {
    Easy = {
        waves = {}
    },
    Medium = {
        waves = {}
    },
    Hard = {
        waves = {}
    }
}

-- Auto-fill wave data based on Config.Locations[1].enemySpawns
local easyCount, mediumCount, hardCount = 5, 10, 15
local spawnPoints = Config.Locations[1].enemySpawns

for i = 1, easyCount do
    local index = ((i - 1) % #spawnPoints) + 1
    local pos = spawnPoints[index]
    table.insert(waveData.Easy.waves, {
        model = 's_m_y_blackops_01',
        coords = vector3(pos.x, pos.y, pos.z),
        heading = pos.w,
        health = 200, -- Healt 200 = max
        armor = 0 -- armor 100 = max
    })
end

for i = 1, mediumCount do
    local index = ((i - 1) % #spawnPoints) + 1
    local pos = spawnPoints[index]
    table.insert(waveData.Medium.waves, {
        model = 's_m_y_blackops_01',
        coords = vector3(pos.x, pos.y, pos.z),
        heading = pos.w,
        health = 200, -- Healt 200 = max
        armor = 50 -- armor 100 = max
    })
end

for i = 1, hardCount do
    local index = ((i - 1) % #spawnPoints) + 1
    local pos = spawnPoints[index]
    table.insert(waveData.Hard.waves, {
        model = 's_m_y_blackops_01',
        coords = vector3(pos.x, pos.y, pos.z),
        heading = pos.w,
        health = 200, -- Healt 200 = max
        armor = 100 -- armor 100 = max
    })
end
