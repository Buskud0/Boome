-- Horde wave spawning: building the spawn queue and placing zombies.
-- Attaches methods to the Horde factory.

local Config = require "core.config"
local Zombie = require "entities.zombie"
local Movement = require "world.physics.movement"

local TYPE_COSTS = Config.ZOMBIE_TYPE_COSTS
local LIGHT_UNLOCK_ROUND = Config.ZOMBIE_LIGHT_UNLOCK_ROUND
local HEAVY_UNLOCK_ROUND = Config.ZOMBIE_HEAVY_UNLOCK_ROUND

return function(Horde)
    function Horde:roundBudget()
        local round = self.state.currentRound
        local budget = Config.ZOMBIE_BUDGET_BASE + Config.ZOMBIE_BUDGET_LINEAR * round + Config.ZOMBIE_BUDGET_QUAD * round * round
        return math.floor(math.min(budget, Config.ZOMBIE_BUDGET_CAP))
    end

    function Horde:pickZombieType()
        local round = self.state.currentRound
        local lightWeight = round >= LIGHT_UNLOCK_ROUND and Config.ZOMBIE_LIGHT_WEIGHT_BASE + Config.ZOMBIE_LIGHT_WEIGHT_GROWTH * round or 0
        local heavyWeight = round >= HEAVY_UNLOCK_ROUND and Config.ZOMBIE_HEAVY_WEIGHT_BASE + Config.ZOMBIE_HEAVY_WEIGHT_GROWTH * round or 0
        lightWeight = math.min(Config.ZOMBIE_WEIGHT_CAP, lightWeight)
        heavyWeight = math.min(Config.ZOMBIE_WEIGHT_CAP, heavyWeight)
        local normalWeight = math.max(Config.ZOMBIE_NORMAL_WEIGHT_MIN, 1 - lightWeight - heavyWeight)

        local roll = math.random() * (normalWeight + lightWeight + heavyWeight)
        if roll < normalWeight then return "normal" end
        if roll < normalWeight + lightWeight then return "light" end
        return "heavy"
    end

    function Horde:buildQueue()
        local queue = {}
        local budget = self:roundBudget()
        while budget > 0 do
            local zombieType = self:pickZombieType()
            local cost = TYPE_COSTS[zombieType] or 1
            if cost > budget then
                budget = 0
            else
                table.insert(queue, zombieType)
                budget = budget - cost
            end
        end
        self:shuffleQueue(queue)
        self.spawnQueue = queue
    end

    function Horde:shuffleQueue(queue)
        for i = #queue, 2, -1 do
            local j = math.random(i)
            queue[i], queue[j] = queue[j], queue[i]
        end
    end

    function Horde:getSpawnInterval()
        return math.max(Config.ZOMBIE_SPAWN_INTERVAL_MIN, Config.ZOMBIE_SPAWN_INTERVAL_BASE - Config.ZOMBIE_SPAWN_INTERVAL_PER_ROUND * self.state.currentRound)
    end

    function Horde:activeCap()
        return math.min(Config.ZOMBIE_ACTIVE_CAP_BASE + Config.ZOMBIE_ACTIVE_CAP_PER_ROUND * self.state.currentRound, Config.ZOMBIE_ACTIVE_CAP_MAX)
    end

    function Horde:spawnNextQueuedZombie()
        if #self.state.zombies >= self:activeCap() then
            self.spawnTimer = Config.ZOMBIE_CAP_RETRY_INTERVAL
            return
        end
        local zombieType = table.remove(self.spawnQueue, 1)
        self:spawnZombie(zombieType)
        self.spawnTimer = self:getSpawnInterval()
    end

    function Horde:spawnZombie(type)
        local x, y = self:findRandomSpawnPosition()
        local zombie = Zombie(self.state, type, x, y)
        Movement.resolveStuck(self.state, zombie)
        table.insert(self.state.zombies, zombie)
    end

    function Horde:pickBorderPoint()
        local mapW = self.state.mapWidth
        local mapH = self.state.mapHeight
        local px, py = self.state.player:getCenter()

        local edges = {
            { dirX = 0, dirY = -1, dist = py },       -- top
            { dirX = 0, dirY = 1, dist = mapH - py }, -- bottom
            { dirX = -1, dirY = 0, dist = px },       -- left
            { dirX = 1, dirY = 0, dist = mapW - px }, -- right
        }

        local sum = 0
        for _, edge in ipairs(edges) do sum = sum + edge.dist end
        if sum <= 0 then return px, py end

        local roll = math.random() * sum
        local chosen = edges[#edges]
        for _, edge in ipairs(edges) do
            roll = roll - edge.dist
            if roll <= 0 then chosen = edge break end
        end

        local margin = 40
        if chosen.dirY ~= 0 then
            local y = chosen.dirY < 0 and margin or mapH - margin
            return math.random(margin, mapW - margin), y
        else
            local x = chosen.dirX < 0 and margin or mapW - margin
            return x, math.random(margin, mapH - margin)
        end
    end

    function Horde:findRandomSpawnPosition()
        local player = self.state.player
        local minDistance = Config.ZOMBIE_SPAWN_MIN_DISTANCE
        local maxAttempts = Config.ZOMBIE_SPAWN_MAX_ATTEMPTS
        local px, py = player:getCenter()
        local bestX, bestY, bestDist = px, py, -1

        for i = 1, maxAttempts do
            local x, y = self:pickBorderPoint()
            local dx, dy = x - px, y - py
            local dist = math.sqrt(dx * dx + dy * dy)
            if dist >= minDistance then return x, y end
            if dist > bestDist then
                bestDist, bestX, bestY = dist, x, y
            end
        end
        return bestX, bestY
    end
end
