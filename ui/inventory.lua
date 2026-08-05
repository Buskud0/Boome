-- Inventory: slot storage, panels (player + chest), drag/swap and selection.
-- State-injected factory.

local Config = require "core.config"
local Fonts = require "core.fonts"
local Textures = require "core.textures"
local WeaponPickup = require "entities.weapon_pickup"

local Inventory = {}
Inventory.__index = Inventory

local SLOT_SIZE = Config.INVENTORY_SLOT_SIZE
local SLOT_GAP = Config.INVENTORY_SLOT_GAP
local HOTBAR_SLOTS = Config.INVENTORY_HOTBAR_SLOTS
local BACKPACK_SLOTS = Config.INVENTORY_BACKPACK_SLOTS
local BACKPACK_ROW_OFFSET = Config.INVENTORY_BACKPACK_ROW_OFFSET
local BACKPACK_TITLE = Config.INVENTORY_BACKPACK_TITLE
local BACKPACK_TITLE_SIZE = Config.INVENTORY_BACKPACK_TITLE_SIZE
local CHEST_SLOTS = Config.INVENTORY_CHEST_SLOTS
local CHEST_TITLE = Config.INVENTORY_CHEST_TITLE
local DRAG_THRESHOLD = Config.INVENTORY_DRAG_THRESHOLD
local INTERACT_RANGE = Config.INTERACT_RANGE
local PANEL_PADDING = 6
local PANEL_TITLE_HEIGHT = 26

function Inventory.new(state)
    local self = setmetatable({}, Inventory)
    self.state = state
    self.MAX_SLOTS = HOTBAR_SLOTS + BACKPACK_SLOTS
    self.HOTBAR_SLOTS = HOTBAR_SLOTS
    self.isOpen = false
    self.chest = nil -- { container = Container, record }
    self.drag = nil  -- { panel, slot, startX, startY }
    return self
end

--------------------------------- lifecycle ---------------------------------

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

function Inventory:open()
    self.isOpen = true
end

function Inventory:close()
    self.isOpen = false
    self:closeChest()
    self:clearDrag()
end

function Inventory:toggle()
    if self.isOpen then self:close() else self:open() end
end

function Inventory:closeChest()
    self.chest = nil
end

function Inventory:refreshChest()
    if not self.isOpen then
        self:closeChest()
        return
    end
    if not self.state.player or not self.state.grid then return end
    local cx, cy = self.state.player:getCenter()
    local record = self.state.grid:nearestChest(cx, cy, INTERACT_RANGE)
    if not record then
        self:closeChest()
        return
    end
    if self.chest and self.chest.record == record then
        return
    end
    self.chest = { container = record.contents, record = record }
end

function Inventory:findFirstEmptySlot()
    for i = 1, self.MAX_SLOTS do
        if not self.state.weapons[i] then
            return i
        end
    end
    return nil
end

function Inventory:setSlot(slot, item)
    self.state.weapons[slot] = item
end

---------------------------------- panels ---------------------------------

function Inventory:playerPanel()
    return {
        id = "player",
        count = self.isOpen and self.MAX_SLOTS or HOTBAR_SLOTS,
        frameIndex = HOTBAR_SLOTS + 1,
        width = function() return self:getBackpackWidth() end,
        rects = function() return self:getPlayerRects() end,
        title = BACKPACK_TITLE,
        showTitle = function() return self.isOpen end,
        showIndex = function(i) return i <= HOTBAR_SLOTS end,
        get = function(i) return self.state.weapons[i] end,
        set = function(i, item) self.state.weapons[i] = item end,
    }
end

function Inventory:chestPanel()
    if not self.chest then return nil end
    return {
        id = "chest",
        count = CHEST_SLOTS,
        frameIndex = 1,
        width = function()
            return CHEST_SLOTS * SLOT_SIZE + (CHEST_SLOTS - 1) * SLOT_GAP
        end,
        rects = function() return self:getChestRects() end,
        title = CHEST_TITLE,
        showTitle = function() return true end,
        showIndex = function() return false end,
        get = function(i) return self.chest.container:get(i) end,
        set = function(i, item) self.chest.container:set(i, item) end,
    }
end

function Inventory:panels()
    local panels = { self:playerPanel() }
    local chest = self:chestPanel()
    if chest then panels[#panels + 1] = chest end
    return panels
end

function Inventory:isPlayerPanel(panel)
    return panel and panel.id == "player"
end

---------------------------------- layout ---------------------------------

function Inventory:getBackpackWidth()
    return BACKPACK_SLOTS * SLOT_SIZE + (BACKPACK_SLOTS - 1) * SLOT_GAP
end

function Inventory:getPlayerRects()
    local state = self.state
    local totalWidth = self:getBackpackWidth()
    local startX = math.floor(state.scrWidth / 2 - totalWidth / 2 + state.camera.x)
    local rects = {}
    for i = 1, self.MAX_SLOTS do
        local slotX = startX + ((i - 1) % HOTBAR_SLOTS) * (SLOT_SIZE + SLOT_GAP)
        local row = math.floor((i - 1) / HOTBAR_SLOTS)
        local slotY = (state.scrHeight - SLOT_SIZE - 12 + state.camera.y) - row * (SLOT_SIZE + SLOT_GAP)
            - (row > 0 and BACKPACK_ROW_OFFSET or 0)
        rects[i] = { x = slotX, y = slotY, w = SLOT_SIZE, h = SLOT_SIZE }
    end
    return rects
end

function Inventory:getChestRects()
    local rects = {}
    if not self.chest then return rects end
    local startX = self:getPanelStartX()
    local backpackY = self:getPlayerRects()[HOTBAR_SLOTS + 1].y
    local chestY = backpackY - PANEL_TITLE_HEIGHT - PANEL_PADDING - SLOT_SIZE - SLOT_GAP * 2
    for i = 1, CHEST_SLOTS do
        local slotX = startX + (i - 1) * (SLOT_SIZE + SLOT_GAP)
        rects[i] = { x = slotX, y = chestY, w = SLOT_SIZE, h = SLOT_SIZE }
    end
    return rects
end

function Inventory:getPanelStartX()
    return math.floor(self.state.scrWidth / 2 - self:getBackpackWidth() / 2 + self.state.camera.x)
end

function Inventory:rectHit(rect, worldX, worldY)
    return worldX >= rect.x and worldX <= rect.x + rect.w
        and worldY >= rect.y and worldY <= rect.y + rect.h
end

function Inventory:getPanelAt(worldX, worldY)
    for _, panel in ipairs(self:panels()) do
        for i, rect in ipairs(panel.rects()) do
            if self:rectHit(rect, worldX, worldY) then
                return panel, i
            end
        end
    end
    return nil, nil
end

function Inventory:getItemAt(panel, slot)
    return panel.get(slot)
end

function Inventory:setItemAt(panel, slot, item)
    panel.set(slot, item)
end

--------------------------------- container ops ---------------------------------

function Inventory:moveItem(srcPanel, srcSlot, dstPanel, dstSlot)
    local temp = self:getItemAt(srcPanel, srcSlot)
    self:setItemAt(srcPanel, srcSlot, self:getItemAt(dstPanel, dstSlot))
    self:setItemAt(dstPanel, dstSlot, temp)
    local touchesPlayer = self:isPlayerPanel(srcPanel) or self:isPlayerPanel(dstPanel)
    if touchesPlayer then
        local srcIndex = self:isPlayerPanel(srcPanel) and srcSlot or nil
        local dstIndex = self:isPlayerPanel(dstPanel) and dstSlot or nil
        self:keepSelectionValid(srcIndex, dstIndex)
    end
end

function Inventory:dropItemAt(panel, slot)
    local item = self:getItemAt(panel, slot)
    if not item then return end
    self:setItemAt(panel, slot, nil)
    if self:isPlayerPanel(panel) then
        self:keepSelectionValid(slot, slot)
    end
    local cx, cy = self.state.player:getCenter()
    table.insert(self.state.weaponPickups, WeaponPickup(self.state, cx, cy, item))
end

function Inventory:dropHeldWeapon()
    if not self.state.currentWeaponIndex or not self.state.weapons[self.state.currentWeaponIndex] then return end
    self:dropItemAt(self:playerPanel(), self.state.currentWeaponIndex)
    self.state.currentWeaponIndex = nil
end

---------------------------------- input ---------------------------------

function Inventory:mousepressed(worldX, worldY, button)
    if button == 2 then
        self:handleRightClick(worldX, worldY)
        return
    end
    if button ~= 1 then return end
    local panel, slot = self:getPanelAt(worldX, worldY)
    if panel and self:getItemAt(panel, slot) then
        self:startDrag(panel, slot, worldX, worldY)
    end
end

function Inventory:handleRightClick(worldX, worldY)
    if not self.isOpen then return end
    local panel, slot = self:getPanelAt(worldX, worldY)
    if panel and self:getItemAt(panel, slot) then
        self:dropItemAt(panel, slot)
    end
end

function Inventory:startDrag(panel, slot, worldX, worldY)
    self.drag = {
        panel = panel,
        slot = slot,
        startX = worldX,
        startY = worldY,
    }
end

function Inventory:clearDrag()
    self.drag = nil
end

function Inventory:dragItem()
    return self:getItemAt(self.drag.panel, self.drag.slot)
end

function Inventory:isDragClick(worldX, worldY)
    local dx = worldX - self.drag.startX
    local dy = worldY - self.drag.startY
    return dx * dx + dy * dy < DRAG_THRESHOLD * DRAG_THRESHOLD
end

function Inventory:mousereleased(worldX, worldY, button)
    if button ~= 1 or not self.drag then return end
    if self:isDragClick(worldX, worldY) then
        self:selectWeaponSlot(self.drag.panel, self.drag.slot)
        return
    end
    self:trySwapWithTarget(worldX, worldY)
end

function Inventory:selectWeaponSlot(panel, slot)
    if self:isPlayerPanel(panel) and slot <= HOTBAR_SLOTS then
        self:toggleWeaponSelection(slot)
    end
    self:clearDrag()
end

function Inventory:toggleWeaponSelection(slot)
    if self.state.currentWeaponIndex == slot then
        self.state.currentWeaponIndex = nil
    elseif self.state.weapons[slot] then
        self.state.currentWeaponIndex = slot
    else
        self.state.currentWeaponIndex = nil
    end
end

function Inventory:trySwapWithTarget(worldX, worldY)
    local targetPanel, targetIndex = self:getPanelAt(worldX, worldY)
    if targetPanel then
        self:moveItem(self.drag.panel, self.drag.slot, targetPanel, targetIndex)
    end
    self:clearDrag()
end

function Inventory:keepSelectionValid(sourceIndex, targetIndex)
    local weapons = self.state.weapons
    if targetIndex and targetIndex <= HOTBAR_SLOTS and weapons[targetIndex] then
        self.state.currentWeaponIndex = targetIndex
        return
    end
    if sourceIndex and sourceIndex <= HOTBAR_SLOTS and weapons[sourceIndex] then
        self.state.currentWeaponIndex = sourceIndex
        return
    end
    for i = 1, HOTBAR_SLOTS do
        if weapons[i] then
            self.state.currentWeaponIndex = i
            return
        end
    end
    self.state.currentWeaponIndex = nil
end

---------------------------------- drawing ---------------------------------

function Inventory:draw()
    self:refreshChest()
    for _, panel in ipairs(self:panels()) do
        self:drawPanelFrame(panel)
        self:drawPanelSlots(panel)
    end
    self:drawHeldItemName()
    self:drawDragGhost()
end

function Inventory:drawPanelFrame(panel)
    if not panel.showTitle() then return end
    local rects = panel.rects()
    local frame = rects[panel.frameIndex]
    if not frame then return end
    love.graphics.setColor(0, 0, 0, 0.4)
    love.graphics.rectangle("fill",
        frame.x - PANEL_PADDING, frame.y - PANEL_TITLE_HEIGHT - PANEL_PADDING,
        panel.width() + PANEL_PADDING * 2,
        PANEL_TITLE_HEIGHT + SLOT_SIZE + PANEL_PADDING * 2)
    self:drawCenteredText(panel.title,
        frame.x + panel.width() / 2,
        frame.y - PANEL_TITLE_HEIGHT + 4, BACKPACK_TITLE_SIZE, {0.9, 0.9, 0.9})
end

function Inventory:drawPanelSlots(panel)
    local rects = panel.rects()
    for i = 1, panel.count do
        local rect = rects[i]
        local item = panel.get(i)
        local showIndex = panel.showIndex(i)
        if item then
            self:drawSlot(rect.x, rect.y, item,
                self:isActiveSlot(panel, i), i, showIndex)
        else
            self:drawEmptySlot(rect.x, rect.y, i, showIndex)
        end
    end
end

function Inventory:isActiveSlot(panel, slot)
    return self:isPlayerPanel(panel) and slot == self.state.currentWeaponIndex
end

function Inventory:drawHeldItemName()
    local state = self.state
    local weapon = state.weapons[state.currentWeaponIndex]
    local rects = self:getPlayerRects()
    local label = weapon and weapon.model or "FISTS"
    local rect = weapon and rects[state.currentWeaponIndex] or rects[1]
    if not rect then return end
    local centerX = self:getPanelStartX() + self:getBackpackWidth() / 2
    self:drawCenteredText(label, centerX, rect.y - 18, 18, {1, 1, 1})
end

function Inventory:drawDragGhost()
    if not self.drag then return end
    local mx, my = love.mouse.getPosition()
    local weapon = self:dragItem()
    if not weapon then return end
    local camera = self.state.camera
    Textures.draw("slot_" .. weapon.model, mx + camera.x - 20, my + camera.y - 20, 40, 40, 0.8)
end

function Inventory:drawSlot(x, y, weapon, isActive, index, showIndex)
    self:drawSlotFrame(x, y, isActive)
    self:drawSlotIcon(x, y, weapon.model)
    if showIndex then
        self:drawSlotIndex(x, y, index, {1, 1, 1})
    end
    if weapon.magSize then
        self:drawAmmo(x, y, weapon)
    end
end

function Inventory:drawEmptySlot(x, y, index, showIndex)
    love.graphics.setColor(0.08, 0.08, 0.08, 0.6)
    love.graphics.rectangle("fill", x, y, SLOT_SIZE, SLOT_SIZE)
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("line", x, y, SLOT_SIZE, SLOT_SIZE)
    if showIndex then
        self:drawSlotIndex(x, y, index, {0.3, 0.3, 0.3})
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