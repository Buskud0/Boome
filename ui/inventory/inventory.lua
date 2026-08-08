-- Inventory: core state and lifecycle. Panels/container ops, input, layout
-- and draw behavior are attached by the mixins required at the bottom.

local Config = require "core.config"
local Textures = require "core.textures"

local HOTBAR_SLOTS = Config.INVENTORY_HOTBAR_SLOTS
local BACKPACK_SLOTS = Config.INVENTORY_BACKPACK_SLOTS
local INTERACT_RANGE = Config.INTERACT_RANGE

local Inventory = {}
Inventory.__index = Inventory

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

function Inventory.load()
    Textures.load("images/item_spritesheet.png", 40)
    local weaponSprites = {
        BAYONET = 1,
        AK47 = 2,
        ["MAC-10"] = 3,
        ["REMINGTON-870"] = 4,
        M9 = 5,
        AWP = 6,
        GRENADE = 7,
        SHOVEL = 8,
        AXE = 9,
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

function Inventory:openChest(record)
    self.chest = { container = record.contents, record = record }
    self:open()
end

function Inventory:closeChest()
    self.chest = nil
end

function Inventory:refreshChest()
    if not self.isOpen then
        self:closeChest()
        return
    end
    if self.state.craftMenu and self.state.craftMenu.isOpen then
        self:closeChest()
        return
    end
    if not self.chest or not self.state.player or not self.state.grid then return end
    local cx, cy = self.state.player:getCenter()
    local record, kind = self.state.grid:nearestInteractable(cx, cy, INTERACT_RANGE)
    if not record or record ~= self.chest.record or kind ~= "chest" then
        self:closeChest()
    end
end

require("ui.inventory.inventory_state")(Inventory)
require("ui.inventory.inventory_stack")(Inventory)
require("ui.inventory.inventory_layout")(Inventory)
require("ui.inventory.inventory_input")(Inventory)
require("ui.inventory.inventory_draw")(Inventory)

return Inventory
