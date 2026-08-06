-- Generic stackable inventory item. Distinct from Weapon: it is not
-- equippable and its stacking is managed by the inventory layer.

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

return Item
