local Inventory = {}

local SLOT_SIZE = 52
local SLOT_GAP = 8
local SLOT_COUNT = 5
local WEAPON_SLOT_ORDER = {"M9", "MAC-10", "REMINGTON-870", "AWP", "AK47"}
local DRAG_THRESHOLD = 10

Inventory.dragSlot = nil
Inventory.dragStartX = 0
Inventory.dragStartY = 0

function Inventory.getSlotRects()
    local totalWidth = SLOT_COUNT * SLOT_SIZE + (SLOT_COUNT - 1) * SLOT_GAP
    local startX = math.floor(scrWidth / 2 - totalWidth / 2 + camera.x)
    local slotY = scrHeight - SLOT_SIZE - 12 + camera.y
    local rects = {}
    for i = 1, SLOT_COUNT do
        local slotX = startX + (i - 1) * (SLOT_SIZE + SLOT_GAP)
        rects[i] = { x = slotX, y = slotY, w = SLOT_SIZE, h = SLOT_SIZE }
    end
    return rects
end

function Inventory.load()
    local weaponSprites = {
        knife = 1,
        AK47 = 2,
        ["MAC-10"] = 3,
        ["REMINGTON-870"] = 4,
        M9 = 5,
        AWP = 6,
    }
    for model, idx in pairs(weaponSprites) do
        Textures.define("slot_" .. model, idx)
    end
end

function Inventory.draw()
    local rects = Inventory.getSlotRects()

    for i = 1, SLOT_COUNT do
        local rect = rects[i]
        if weapons[i] then
            Inventory:drawSlot(rect.x, rect.y, weapons[i].model, i == currentWeaponIndex, i)
        else
            Inventory:drawEmptySlot(rect.x, rect.y, i)
        end
    end

    Inventory.drawDragGhost()
end

function Inventory.drawDragGhost()
    if not Inventory.dragSlot then return end
    local mx, my = love.mouse.getPosition()
    local weapon = weapons[Inventory.dragSlot]
    if not weapon then return end
    love.graphics.setColor(1, 1, 1, 0.8)
    Textures.draw("slot_" .. weapon.model, mx + camera.x - 20, my + camera.y - 20, 40, 40)
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

function Inventory.mousepressed(worldX, worldY, button)
    if button ~= 1 then return end
    local slotIndex = Inventory.slotIndexAtPosition(worldX, worldY)
    if slotIndex and weapons[slotIndex] then
        Inventory.startDrag(slotIndex, worldX, worldY)
    end
end

function Inventory.startDrag(slotIndex, worldX, worldY)
    Inventory.dragSlot = slotIndex
    Inventory.dragStartX = worldX
    Inventory.dragStartY = worldY
end

function Inventory.slotIndexAtPosition(worldX, worldY)
    local rects = Inventory.getSlotRects()
    for i, rect in ipairs(rects) do
        if worldX >= rect.x and worldX <= rect.x + rect.w and
           worldY >= rect.y and worldY <= rect.y + rect.h then
            return i
        end
    end
    return nil
end

function Inventory.mousereleased(worldX, worldY, button)
    if button ~= 1 or not Inventory.dragSlot then return end

    if Inventory.isDragClick(worldX, worldY) then
        Inventory.selectWeaponSlot(Inventory.dragSlot)
        return
    end

    Inventory.trySwapWithTarget(worldX, worldY)
end

function Inventory.isDragClick(worldX, worldY)
    local dx = worldX - Inventory.dragStartX
    local dy = worldY - Inventory.dragStartY
    return dx * dx + dy * dy < DRAG_THRESHOLD * DRAG_THRESHOLD
end

function Inventory.selectWeaponSlot(slotIndex)
    if weapons[slotIndex] then
        currentWeaponIndex = slotIndex
    end
    Inventory.dragSlot = nil
end

function Inventory.trySwapWithTarget(worldX, worldY)
    local targetIndex = Inventory.slotIndexAtPosition(worldX, worldY)
    if targetIndex then
        local temp = weapons[targetIndex]
        weapons[targetIndex] = weapons[Inventory.dragSlot]
        weapons[Inventory.dragSlot] = temp
        currentWeaponIndex = targetIndex
    end
    Inventory.dragSlot = nil
end

return Inventory
