local Inventory = {}

local SLOT_SIZE = 52
local SLOT_GAP = 8
local SLOT_COUNT = 5
local WEAPON_SLOT_ORDER = {"M9", "MAC-10", "REMINGTON-870", "AWP", "AK47"}

function Inventory.load()
    for i, model in ipairs(WEAPON_SLOT_ORDER) do
        Textures.define("slot_" .. model, i)
    end
end

function Inventory.draw()
    local totalWidth = SLOT_COUNT * SLOT_SIZE + (SLOT_COUNT - 1) * SLOT_GAP
    local startX = math.floor(scrWidth / 2 - totalWidth / 2 + camera.x)
    local slotY = scrHeight - SLOT_SIZE - 12 + camera.y

    for i = 1, SLOT_COUNT do
        local slotX = startX + (i - 1) * (SLOT_SIZE + SLOT_GAP)
        if weapons[i] then
            Inventory:drawSlot(slotX, slotY, weapons[i].model, i == currentWeaponIndex, i)
        else
            Inventory:drawEmptySlot(slotX, slotY, i)
        end
    end
end

function Inventory:drawSlot(x, y, model, isActive, index)
    if isActive then
        love.graphics.setColor(0.3, 0.5, 0.7, 0.9)
    else
        love.graphics.setColor(0.15, 0.15, 0.15, 0.8)
    end
    love.graphics.rectangle("fill", x, y, SLOT_SIZE, SLOT_SIZE)

    love.graphics.setColor(0.4, 0.4, 0.4)
    love.graphics.rectangle("line", x, y, SLOT_SIZE, SLOT_SIZE)

    local padding = 5
    Textures.draw("slot_" .. model, x + padding, y + padding, SLOT_SIZE - padding * 2, SLOT_SIZE - padding * 2)

    local font = love.graphics.newFont("fonts/Gamer.ttf", 14)
    love.graphics.setFont(font)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(tostring(index), x + 3, y + 3)
end

function Inventory:drawEmptySlot(x, y, index)
    love.graphics.setColor(0.08, 0.08, 0.08, 0.6)
    love.graphics.rectangle("fill", x, y, SLOT_SIZE, SLOT_SIZE)

    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("line", x, y, SLOT_SIZE, SLOT_SIZE)

    local font = love.graphics.newFont("fonts/Gamer.ttf", 14)
    love.graphics.setFont(font)
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.print(tostring(index), x + 3, y + 3)
end

return Inventory
