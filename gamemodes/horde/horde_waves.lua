-- Horde wave spawning: building the spawn queue and placing zombies.
-- Attaches methods to the Horde factory.

local Zombie = require "entities.zombie"
local Movement = require "world.physics.movement"

return function(Horde)
    function Horde:buildQueue()
        local queue = {}
        self:addZombiesToQueue(queue, self.zombieCount, "normal")
        self:addZombiesToQueue(queue, self.state.currentRound / 3, "heavy")
        self:addZombiesToQueue(queue, self.state.currentRound / 2, "light")
        self:shuffleQueue(queue)
        self.spawnQueue = queue
    end

    function Horde:addZombiesToQueue(queue, count, zombieType)
        for i = 1, math.floor(count) do
            table.insert(queue, zombieType)
        end
    end

    function Horde:shuffleQueue(queue)
        for i = #queue, 2, -1 do
            local j = math.random(i)
            queue[i], queue[j] = queue[j], queue[i]
        end
    end

    function Horde:spawnNextQueuedZombie()
        local zombieType = table.remove(self.spawnQueue, 1)
        self:spawnZombie(zombieType)
        self.spawnTimer = 2
    end

    function Horde:spawnZombie(type)
        local x, y = self:findRandomSpawnPosition()
        local zombie = Zombie(self.state, type, x, y)
        Movement.resolveStuck(self.state, zombie)
        table.insert(self.state.zombies, zombie)
    end

    function Horde:findRandomSpawnPosition()
        local minDistance = 500
        local player = self.state.player
        local x, y
        repeat
            x = math.random(0, self.state.mapWidth)
            y = math.random(0, self.state.mapHeight)
        until math.sqrt((x - player.x) ^ 2 + (y - player.y) ^ 2) > minDistance
        return x, y
    end
end
