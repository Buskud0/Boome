local Inventory = {}

local SLOT_SIZE = INVENTORY_SLOT_SIZE
local SLOT_GAP = INVENTORY_SLOT_GAP
local HOTBAR_SLOTS = INVENTORY_HOTBAR_SLOTS
local BACKPACK_SLOTS = INVENTORY_BACKPACK_SLOTS
local BACKPACK_ROW_OFFSET = INVENTORY_BACKPACK_ROW_OFFSET
local BACKPACK_TITLE = INVENTORY_BACKPACK_TITLE
local BACKPACK_TITLE_SIZE = INVENTORY_BACKPACK_TITLE_SIZE
local CHEST_SLOTS = INVENTORY_CHEST_SLOTS
local CHEST_TITLE = INVENTORY_CHEST_TITLE
local DRAG_THRESHOLD = INVENTORY_DRAG_THRESHOLD
local PANEL_PADDING = 6
local PANEL_TITLE_HEIGHT = 26

Inventory.MAX_SLOTS = HOTBAR_SLOTS + BACKPACK_SLOTS
Inventory.HOTBAR_SLOTS = HOTBAR_SLOTS
Inventory.isOpen = false
Inventory.chest = nil   -- { container = Container, record }
Inventory.drag = nil    -- { panel, slot, startX, startY }

--------------------------------- lifecycle ---------------------------------

Inventory.load = function()
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

function Inventory.open()
    Inventory.isOpen = true
end

function Inventory.close()
    Inventory.isOpen = false
    Inventory.closeChest()
    Inventory.clearDrag()
end

function Inventory.toggle()
    if Inventory.isOpen then Inventory.close() else Inventory.open() end
end

function Inventory.closeChest()
    Inventory.chest = nil
end

function Inventory.refreshChest()
    if not Inventory.isOpen then
        Inventory.closeChest()
        return
    end
    local cx, cy = player:getCenter()
    local record = grid:nearestChest(cx, cy, INTERACT_RANGE)
    if not record then
        Inventory.closeChest()
        return
    end
    if Inventory.chest and Inventory.chest.record == record then
        return
    end
    Inventory.chest = { container = record.contents, record = record }
end

function Inventory.findFirstEmptySlot()
    for i = 1, Inventory.MAX_SLOTS do
        if not weapons[i] then
            return i
        end
    end
    return nil
end

function Inventory.setSlot(slot, item)
    weapons[slot] = item
end

--------------------------------- panels ---------------------------------

local function playerPanel()
    return {
        id = "player",
        count = Inventory.isOpen and Inventory.MAX_SLOTS or HOTBAR_SLOTS,
        frameIndex = HOTBAR_SLOTS + 1,
        width = Inventory.getBackpackWidth,
        rects = Inventory.getPlayerRects,
        title = BACKPACK_TITLE,
        showTitle = function() return Inventory.isOpen end,
        showIndex = function(i) return i <= HOTBAR_SLOTS end,
        get = function(i) return weapons[i] end,
        set = function(i, item) weapons[i] = item end,
    }
end

local function chestPanel()
    if not Inventory.chest then return nil end
    return {
        id = "chest",
        count = CHEST_SLOTS,
        frameIndex = 1,
        width = function()
            return CHEST_SLOTS * SLOT_SIZE + (CHEST_SLOTS - 1) * SLOT_GAP
        end,
        rects = Inventory.getChestRects,
        title = CHEST_TITLE,
        showTitle = function() return true end,
        showIndex = function() return false end,
        get = function(i) return Inventory.chest.container:get(i) end,
        set = function(i, item) Inventory.chest.container:set(i, item) end,
    }
end

function Inventory.panels()
    local panels = { playerPanel() }
    local chest = chestPanel()
    if chest then panels[#panels + 1] = chest end
    return panels
end

function Inventory.isPlayerPanel(panel)
    return panel and panel.id == "player"
end

--------------------------------- layout ---------------------------------

function Inventory.getBackpackWidth()
    return BACKPACK_SLOTS * SLOT_SIZE + (BACKPACK_SLOTS - 1) * SLOT_GAP
end

function Inventory.getPlayerRects()
    local totalWidth = Inventory.getBackpackWidth()
    local startX = math.floor(scrWidth / 2 - totalWidth / 2 + camera.x)
    local rects = {}
    for i = 1, Inventory.MAX_SLOTS do
        local slotX = startX + ((i - 1) % HOTBAR_SLOTS) * (SLOT_SIZE + SLOT_GAP)
        local row = math.floor((i - 1) / HOTBAR_SLOTS)
        local slotY = (scrHeight - SLOT_SIZE - 12 + camera.y) - row * (SLOT_SIZE + SLOT_GAP)
            - (row > 0 and BACKPACK_ROW_OFFSET or 0)
        rects[i] = { x = slotX, y = slotY, w = SLOT_SIZE, h = SLOT_SIZE }
    end
    return rects
end

function Inventory.getChestRects()
    local rects = {}
    if not Inventory.chest then return rects end
    local startX = Inventory.getPanelStartX()
    local backpackY = Inventory.getPlayerRects()[HOTBAR_SLOTS + 1].y
    local chestY = backpackY - PANEL_TITLE_HEIGHT - PANEL_PADDING - SLOT_SIZE - SLOT_GAP * 2
    for i = 1, CHEST_SLOTS do
        local slotX = startX + (i - 1) * (SLOT_SIZE + SLOT_GAP)
        rects[i] = { x = slotX, y = chestY, w = SLOT_SIZE, h = SLOT_SIZE }
    end
    return rects
end

function Inventory.getPanelStartX()
    return math.floor(scrWidth / 2 - Inventory.getBackpackWidth() / 2 + camera.x)
end

function Inventory.rectHit(rect, worldX, worldY)
    return worldX >= rect.x and worldX <= rect.x + rect.w
        and worldY >= rect.y and worldY <= rect.y + rect.h
end

function Inventory.getPanelAt(worldX, worldY)
    for _, panel in ipairs(Inventory.panels()) do
        for i, rect in ipairs(panel.rects()) do
            if Inventory.rectHit(rect, worldX, worldY) then
                return panel, i
            end
        end
    end
    return nil, nil
end

function Inventory.getItemAt(panel, slot)
    return panel.get(slot)
end

function Inventory.setItemAt(panel, slot, item)
    panel.set(slot, item)
end

--------------------------------- container ops ---------------------------------

function Inventory.moveItem(srcPanel, srcSlot, dstPanel, dstSlot)
    local temp = Inventory.getItemAt(srcPanel, srcSlot)
    Inventory.setItemAt(srcPanel, srcSlot, Inventory.getItemAt(dstPanel, dstSlot))
    Inventory.setItemAt(dstPanel, dstSlot, temp)
    local touchesPlayer = Inventory.isPlayerPanel(srcPanel) or Inventory.isPlayerPanel(dstPanel)
    if touchesPlayer then
        local srcIndex = Inventory.isPlayerPanel(srcPanel) and srcSlot or nil
        local dstIndex = Inventory.isPlayerPanel(dstPanel) and dstSlot or nil
        Inventory.keepSelectionValid(srcIndex, dstIndex)
    end
end

function Inventory.dropItemAt(panel, slot)
    local item = Inventory.getItemAt(panel, slot)
    if not item then return end
    Inventory.setItemAt(panel, slot, nil)
    if Inventory.isPlayerPanel(panel) then
        Inventory.keepSelectionValid(slot, slot)
    end
    local cx, cy = player:getCenter()
    table.insert(weaponPickups, WeaponPickup(cx, cy, item))
end

function Inventory.dropHeldWeapon()
    if not currentWeaponIndex or not weapons[currentWeaponIndex] then return end
    Inventory.dropItemAt(playerPanel(), currentWeaponIndex)
    currentWeaponIndex = nil
end

--------------------------------- input ---------------------------------

function Inventory.mousepressed(worldX, worldY, button)
    if button == 2 then
        Inventory.handleRightClick(worldX, worldY)
        return
    end
    if button ~= 1 then return end
    local panel, slot = Inventory.getPanelAt(worldX, worldY)
    if panel and Inventory.getItemAt(panel, slot) then
        Inventory.startDrag(panel, slot, worldX, worldY)
    end
end

function Inventory.handleRightClick(worldX, worldY)
    if not Inventory.isOpen then return end
    local panel, slot = Inventory.getPanelAt(worldX, worldY)
    if panel and Inventory.getItemAt(panel, slot) then
        Inventory.dropItemAt(panel, slot)
    end
end

function Inventory.startDrag(panel, slot, worldX, worldY)
    Inventory.drag = {
        panel = panel,
        slot = slot,
        startX = worldX,
        startY = worldY,
    }
end

function Inventory.clearDrag()
    Inventory.drag = nil
end

function Inventory.dragItem()
    return Inventory.getItemAt(Inventory.drag.panel, Inventory.drag.slot)
end

function Inventory.isDragClick(worldX, worldY)
    local dx = worldX - Inventory.drag.startX
    local dy = worldY - Inventory.drag.startY
    return dx * dx + dy * dy < DRAG_THRESHOLD * DRAG_THRESHOLD
end

function Inventory.mousereleased(worldX, worldY, button)
    if button ~= 1 or not Inventory.drag then return end
    if Inventory.isDragClick(worldX, worldY) then
        Inventory.selectWeaponSlot(Inventory.drag.panel, Inventory.drag.slot)
        return
    end
    Inventory.trySwapWithTarget(worldX, worldY)
end

function Inventory.selectWeaponSlot(panel, slot)
    if Inventory.isPlayerPanel(panel) and slot <= HOTBAR_SLOTS then
        Inventory.toggleWeaponSelection(slot)
    end
    Inventory.clearDrag()
end

function Inventory.toggleWeaponSelection(slot)
    if currentWeaponIndex == slot then
        currentWeaponIndex = nil
    elseif weapons[slot] then
        currentWeaponIndex = slot
    else
        currentWeaponIndex = nil
    end
end

function Inventory.trySwapWithTarget(worldX, worldY)
    local targetPanel, targetIndex = Inventory.getPanelAt(worldX, worldY)
    if targetPanel then
        Inventory.moveItem(Inventory.drag.panel, Inventory.drag.slot, targetPanel, targetIndex)
    end
    Inventory.clearDrag()
end

function Inventory.keepSelectionValid(sourceIndex, targetIndex)
    if targetIndex and targetIndex <= HOTBAR_SLOTS and weapons[targetIndex] then
        currentWeaponIndex = targetIndex
        return
    end
    if sourceIndex and sourceIndex <= HOTBAR_SLOTS and weapons[sourceIndex] then
        currentWeaponIndex = sourceIndex
        return
    end
    for i = 1, HOTBAR_SLOTS do
        if weapons[i] then
            currentWeaponIndex = i
            return
        end
    end
    currentWeaponIndex = nil
end

--------------------------------- drawing ---------------------------------

function Inventory.draw()
    Inventory.refreshChest()
    for _, panel in ipairs(Inventory.panels()) do
        Inventory.drawPanelFrame(panel)
        Inventory.drawPanelSlots(panel)
    end
    Inventory.drawHeldItemName()
    Inventory.drawDragGhost()
end

function Inventory.drawPanelFrame(panel)
    if not panel.showTitle() then return end
    local rects = panel.rects()
    local frame = rects[panel.frameIndex]
    if not frame then return end
    love.graphics.setColor(0, 0, 0, 0.4)
    love.graphics.rectangle("fill",
        frame.x - PANEL_PADDING, frame.y - PANEL_TITLE_HEIGHT - PANEL_PADDING,
        panel.width() + PANEL_PADDING * 2,
        PANEL_TITLE_HEIGHT + SLOT_SIZE + PANEL_PADDING * 2)
    Inventory:drawCenteredText(panel.title,
        frame.x + panel.width() / 2,
        frame.y - PANEL_TITLE_HEIGHT + 4, BACKPACK_TITLE_SIZE, {0.9, 0.9, 0.9})
end

function Inventory.drawPanelSlots(panel)
    local rects = panel.rects()
    for i = 1, panel.count do
        local rect = rects[i]
        local item = panel.get(i)
        local showIndex = panel.showIndex(i)
        if item then
            Inventory:drawSlot(rect.x, rect.y, item,
                Inventory.isActiveSlot(panel, i), i, showIndex)
        else
            Inventory:drawEmptySlot(rect.x, rect.y, i, showIndex)
        end
    end
end

function Inventory.isActiveSlot(panel, slot)
    return Inventory.isPlayerPanel(panel) and slot == currentWeaponIndex
end

function Inventory.drawHeldItemName()
    local weapon = weapons[currentWeaponIndex]
    local rects = Inventory.getPlayerRects()
    local label = weapon and weapon.model or "FISTS"
    local rect = weapon and rects[currentWeaponIndex] or rects[1]
    if not rect then return end
    Inventory:drawCenteredText(label,
        rect.x + Inventory.getBackpackWidth() / 2, rect.y - 18, 18, {1, 1, 1})
end

function Inventory.drawDragGhost()
    if not Inventory.drag then return end
    local mx, my = love.mouse.getPosition()
    local weapon = Inventory.dragItem()
    if not weapon then return end
    Textures.draw("slot_" .. weapon.model, mx + camera.x - 20, my + camera.y - 20, 40, 40, 0.8)
end

function Inventory:drawSlot(x, y, weapon, isActive, index, showIndex)
    Inventory:drawSlotFrame(x, y, isActive)
    Inventory:drawSlotIcon(x, y, weapon.model)
    if showIndex then
        Inventory:drawSlotIndex(x, y, index, {1, 1, 1})
    end
    if weapon.magSize then
        Inventory:drawAmmo(x, y, weapon)
    end
end

function Inventory:drawEmptySlot(x, y, index, showIndex)
    love.graphics.setColor(0.08, 0.08, 0.08, 0.6)
    love.graphics.rectangle("fill", x, y, SLOT_SIZE, SLOT_SIZE)
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("line", x, y, SLOT_SIZE, SLOT_SIZE)
    if showIndex then
        Inventory:drawSlotIndex(x, y, index, {0.3, 0.3, 0.3})
    end
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

return Inventory