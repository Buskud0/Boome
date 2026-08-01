local Inventory = {}

local SLOT_SIZE = 52
local SLOT_GAP = 8
local HOTBAR_SLOTS = 5
local BACKPACK_SLOTS = 5
local BACKPACK_ROW_OFFSET = 30
local BACKPACK_TITLE = "BACKPACK"
local BACKPACK_TITLE_SIZE = 16
local DRAG_THRESHOLD = 10

Inventory.MAX_SLOTS = HOTBAR_SLOTS + BACKPACK_SLOTS
Inventory.HOTBAR_SLOTS = HOTBAR_SLOTS
Inventory.isOpen = false
Inventory.dragSlot = nil
Inventory.dragStartX = 0
Inventory.dragStartY = 0

function Inventory.getSlotCount()
    return Inventory.isOpen and Inventory.MAX_SLOTS or HOTBAR_SLOTS
end

function Inventory.findFirstEmptySlot()
    for i = 1, Inventory.MAX_SLOTS do
        if not weapons[i] then
            return i
        end
    end
    return nil
end

function Inventory.open()
    Inventory.isOpen = true
end

function Inventory.close()
    Inventory.isOpen = false
end

function Inventory.toggle()
    Inventory.isOpen = not Inventory.isOpen
end

function Inventory.getBackpackWidth()
    return BACKPACK_SLOTS * SLOT_SIZE + (BACKPACK_SLOTS - 1) * SLOT_GAP
end

function Inventory.getSlotRects()
    local totalWidth = Inventory.getBackpackWidth()
    local startX = math.floor(scrWidth / 2 - totalWidth / 2 + camera.x)
    local rects = {}
    for i = 1, Inventory.getSlotCount() do
        local slotX = startX + ((i - 1) % HOTBAR_SLOTS) * (SLOT_SIZE + SLOT_GAP)
        local row = math.floor((i - 1) / HOTBAR_SLOTS)
        local slotY = (scrHeight - SLOT_SIZE - 12 + camera.y) - row * (SLOT_SIZE + SLOT_GAP)
            - (row > 0 and BACKPACK_ROW_OFFSET or 0)
        rects[i] = { x = slotX, y = slotY, w = SLOT_SIZE, h = SLOT_SIZE }
    end
    return rects
end

function Inventory.load()
    Textures.load("images/item_spritesheet.png", 40)
    local weaponSprites = {
        BAYONET = 1,
        AK47 = 2,
        ["MAC-10"] = 3,
        ["REMINGTON-870"] = 4,
        M9 = 5,
        AWP = 6,
        AXE = 7,
    }
    for model, idx in pairs(weaponSprites) do
        Textures.define("slot_" .. model, idx)
    end
end

function Inventory.draw()
    Inventory.drawBackpackPanel()
    local rects = Inventory.getSlotRects()

    for i = 1, Inventory.getSlotCount() do
        local rect = rects[i]
        if weapons[i] then
            Inventory:drawSlot(rect.x, rect.y, weapons[i], i == currentWeaponIndex, i)
        else
            Inventory:drawEmptySlot(rect.x, rect.y, i)
        end
    end

    Inventory.drawHeldItemName(rects)
    Inventory.drawDragGhost()
end

function Inventory.drawBackpackPanel()
    if not Inventory.isOpen then return end
    local rects = Inventory.getSlotRects()
    local backpackRow = rects[HOTBAR_SLOTS + 1]
    local pad = 6
    local titleH = 26

    love.graphics.setColor(0, 0, 0, 0.4)
    love.graphics.rectangle("fill",
        backpackRow.x - pad, backpackRow.y - titleH - pad,
        Inventory.getBackpackWidth() + pad * 2,
        titleH + SLOT_SIZE + pad * 2)

    Inventory:drawCenteredText(BACKPACK_TITLE,
        backpackRow.x + Inventory.getBackpackWidth() / 2,
        backpackRow.y - titleH + 4, BACKPACK_TITLE_SIZE, {0.9, 0.9, 0.9})
end

function Inventory.drawHeldItemName(rects)
    local weapon = weapons[currentWeaponIndex]
    if not weapon then
        local rect = rects[1]
        if rect then
            Inventory:drawCenteredText("FISTS", rect.x + Inventory.getBackpackWidth() / 2, rect.y - 18, 18, {1, 1, 1})
        end
        return
    end

    local rect = rects[currentWeaponIndex]
    if not rect then return end
    Inventory:drawCenteredText(weapon.model, rect.x + rect.w / 2, rect.y - 18, 18, {1, 1, 1})
end

function Inventory.drawDragGhost()
    if not Inventory.dragSlot then return end
    local mx, my = love.mouse.getPosition()
    local weapon = weapons[Inventory.dragSlot]
    if not weapon then return end
    Textures.draw("slot_" .. weapon.model, mx + camera.x - 20, my + camera.y - 20, 40, 40, 0.8)
end

function Inventory:drawSlot(x, y, weapon, isActive, index)
    Inventory:drawSlotFrame(x, y, isActive)
    Inventory:drawSlotIcon(x, y, weapon.model)
    Inventory:drawSlotIndex(x, y, index, {1, 1, 1})

    if weapon.magSize then
        Inventory:drawAmmo(x, y, weapon)
    end
end

function Inventory:drawEmptySlot(x, y, index)
    love.graphics.setColor(0.08, 0.08, 0.08, 0.6)
    love.graphics.rectangle("fill", x, y, SLOT_SIZE, SLOT_SIZE)
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("line", x, y, SLOT_SIZE, SLOT_SIZE)

    Inventory:drawSlotIndex(x, y, index, {0.3, 0.3, 0.3})
end

function Inventory:drawSlotFrame(x, y, isActive)
    if isActive then
        love.graphics.setColor(0.3, 0.5, 0.7, 0.9)
    else
        love.graphics.setColor(0.15, 0.15, 0.15, 0.8)
    end
    love.graphics.rectangle("fill", x, y, SLOT_SIZE, SLOT_SIZE)

    love.graphics.setColor(0.4, 0.4, 0.4)
    love.graphics.rectangle("line", x, y, SLOT_SIZE, SLOT_SIZE)
end

function Inventory:drawSlotIcon(x, y, model)
    local padding = 5
    Textures.draw("slot_" .. model, x + padding, y + padding, SLOT_SIZE - padding * 2, SLOT_SIZE - padding * 2)
end

function Inventory:drawSlotIndex(x, y, index, color)
    if index > HOTBAR_SLOTS then return end
    local font = Fonts.get(16)
    love.graphics.setFont(font)
    love.graphics.setColor(color)
    love.graphics.print(tostring(index), x + 3, y + 2)
end

function Inventory:drawAmmo(x, y, weapon)
    local ammo = weapon.capacity .. "/" .. weapon.magSize
    local font = Fonts.get(16)
    love.graphics.setFont(font)
    local textW = font:getWidth(ammo)
    local barY = y + SLOT_SIZE - 16

    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", x + 2, barY, SLOT_SIZE - 4, 16)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(ammo, x + SLOT_SIZE / 2 - textW / 2, barY + (16 - font:getHeight()) / 2)
end

function Inventory:drawCenteredText(text, centerX, y, size, color)
    local font = Fonts.get(size)
    love.graphics.setFont(font)
    local textW = font:getWidth(text)
    love.graphics.setColor(color)
    love.graphics.print(text, centerX - textW / 2, y)
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
    if slotIndex <= HOTBAR_SLOTS then
        if currentWeaponIndex == slotIndex then
            currentWeaponIndex = nil
        elseif weapons[slotIndex] then
            currentWeaponIndex = slotIndex
        else
            currentWeaponIndex = nil
        end
    end
    Inventory.dragSlot = nil
end

function Inventory.trySwapWithTarget(worldX, worldY)
    local targetIndex = Inventory.slotIndexAtPosition(worldX, worldY)
    if targetIndex then
        local sourceIndex = Inventory.dragSlot
        local temp = weapons[targetIndex]
        weapons[targetIndex] = weapons[sourceIndex]
        weapons[sourceIndex] = temp
        Inventory.keepSelectionValid(sourceIndex, targetIndex)
    end
    Inventory.dragSlot = nil
end

function Inventory.keepSelectionValid(sourceIndex, targetIndex)
    if sourceIndex > HOTBAR_SLOTS then
        return
    end
    if targetIndex <= HOTBAR_SLOTS and weapons[targetIndex] then
        currentWeaponIndex = targetIndex
    elseif weapons[sourceIndex] then
        currentWeaponIndex = sourceIndex
    else
        for i = 1, HOTBAR_SLOTS do
            if weapons[i] then
                currentWeaponIndex = i
                return
            end
        end
        currentWeaponIndex = 1
    end
end

return Inventory
