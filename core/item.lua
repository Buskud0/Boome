-- Generic stackable inventory item. Distinct from Weapon: it is not
-- equippable and its stacking is managed by the inventory layer.
-- Items are selectable in any slot and expose a no-op weapon-like interface
-- so equipping one behaves like equipping a weapon without doing anything.

local Config = require "core.config"

local Item = {}
Item.__index = Item

function Item.new(model, count)
    local stats = Config.ITEMS[model]
    if not stats then error("unknown item model: " .. model) end
    local self = setmetatable({
        model = model,
        count = count or 1,
        isItem = true,
    }, Item)
    return self
end

function Item:update(dt) end
function Item:draw() end
function Item:drawWorld() end
function Item:isScoping() return false end
function Item:updateScope(dt) end

return Item
