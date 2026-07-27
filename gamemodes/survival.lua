local Survival = {}

-------------------------------------------------------------------
-- State machine: "intro" -> "spawning" -> "waiting"
-------------------------------------------------------------------

function Survival.reset()
    currentRound = 1
    zombieCount = STARTING_ZOMBIE_COUNT
    Survival.state = "intro"
    Survival.introTimer = 5
    Survival.spawnQueue = {}
    Survival.spawnTimer = 0
    Survival:buildQueue()
end

function Survival.update(dt)
    if Survival.state == "intro" then
        Survival.introTimer = Survival.introTimer - dt
        if Survival.introTimer <= 0 then
            Survival.state = "spawning"
            Survival.spawnTimer = 1
        end

    elseif Survival.state == "spawning" then
        Survival.spawnTimer = Survival.spawnTimer - dt
        if Survival.spawnTimer <= 0 and #Survival.spawnQueue > 0 then
            local zombieType = table.remove(Survival.spawnQueue, 1)
            spawnZombie(zombieType)
            Survival.spawnTimer = 1
        end
        if #Survival.spawnQueue == 0 then
            Survival.state = "waiting"
        end

    elseif Survival.state == "waiting" then
        if #zombies == 0 then
            currentRound = currentRound + 1
            zombieCount = zombieCount + 2
            for i, weapon in ipairs(weapons) do
                weapon.reloadCooldown = 0
                weapon.capacity = weapon.magSize
            end
            Survival:buildQueue()
            Survival.state = "intro"
            Survival.introTimer = 5
        end
    end
end

-------------------------------------------------------------------
-- Queue
-------------------------------------------------------------------

function Survival:buildQueue()
    local queue = {}
    local function append(count, zombieType)
        for i = 1, math.floor(count) do
            table.insert(queue, zombieType)
        end
    end

    append(zombieCount, "normal")
    append(currentRound / 3, "heavy")
    append(currentRound / 2, "light")

    for i = #queue, 2, -1 do
        local j = math.random(i)
        queue[i], queue[j] = queue[j], queue[i]
    end

    Survival.spawnQueue = queue
end

-------------------------------------------------------------------
-- Drawing
-------------------------------------------------------------------

function Survival.draw()
    if Survival.state ~= "intro" then return end

    local alpha = math.max(0, Survival.introTimer / 5)
    local text = "WAVE " .. currentRound
    local font = love.graphics.newFont("fonts/Gamer.ttf", 80)

    love.graphics.setFont(font)
    love.graphics.setColor(1, 1, 1, alpha)
    local textW = font:getWidth(text)
    love.graphics.print(text, scrWidth / 2 - textW / 2 + camera.x, scrHeight / 2 - 40 + camera.y)
end

return Survival
