-- Proximity interactions: an "OPEN ..." prompt over nearby interactables
-- (shop, barrels, ...) and the click handler that triggers their action.
-- New interactables register themselves in Interact.TYPES.

local Config = require "core.config"
local Fonts = require "core.fonts"
local Coordinates = require "core.coordinates"

local function isPointInRect(x, y, rect)
    return x >= rect.x and x <= rect.x + rect.w and y >= rect.y and y <= rect.y + rect.h
end

local Interact = {}

Interact.TYPES = {
    shop = {
        kind = "shop",
        lines = { "OPEN", "SHOP" },
        canShow = function(state)
            return not state.buyMenu.isOpen and not state.inventory.isOpen
        end,
        activate = function(state)
            if not state.buyMenu.isOpen then state.buyMenu:open() end
        end,
    },
    chest = {
        kind = "chest",
        lines = { "OPEN", "BARREL" },
        canShow = function(state)
            return not state.inventory.isOpen and not state.buyMenu.isOpen
        end,
        activate = function(state, record)
            if not state.inventory.isOpen then state.inventory:openChest(record) end
        end,
    },
    workshop = {
        kind = "workshop",
        lines = { "OPEN", "WORKSHOP" },
        labelFit = true,
        canShow = function(state)
            return not state.craftMenu.isOpen and not state.buyMenu.isOpen and not state.inventory.isOpen
        end,
        activate = function(state)
            if not state.craftMenu.isOpen then state.craftMenu:open() end
        end,
    },
    repair = {
        kind = "repair",
        lines = { "REPAIR" },
        labelFit = true,
        canShow = function(state, record)
            return state.inventory and state.inventory:repairMaterialFor(record) ~= nil
        end,
        activate = function(state, record)
            if state.inventory then state.inventory:repairRecord(record) end
        end,
    },
}

function Interact.forKind(kind)
    for _, def in pairs(Interact.TYPES) do
        if def.kind == kind then return def end
    end
    return nil
end

function Interact.hasOpenMenu(state)
    return state.buyMenu.isOpen or state.inventory.isOpen or state.craftMenu.isOpen
end

function Interact.isActive(state, holder)
    return holder.interactButtonRect ~= nil
end

function Interact.labelSize(def, rect)
    if not def.labelFit then return 16 end
    local maxWidth = rect.w - 4
    for _, size in ipairs({ 16, 14, 12, 10, 8, 7, 6 }) do
        local font = Fonts.get(size)
        local fits = true
        for _, line in ipairs(def.lines) do
            if font:getWidth(line) > maxWidth then
                fits = false
                break
            end
        end
        if fits then return size end
    end
    return 6
end

function Interact.buttonRect(grid, record)
    local x, y, w, h = grid:recordWorldRect(record)
    return { x = x, y = y, w = w, h = h }
end

function Interact.update(state, holder)
    holder.interactRecord = nil
    holder.interactKind = nil
    holder.interactButtonRect = nil
    if state.buyMenu.isOpen or state.inventory.isOpen or state.craftMenu.isOpen or (state.menu and state.menu:isOpen()) then
        return
    end
    if not state.player or not state.grid then return end
    local cx, cy = state.player:getCenter()
    local repairable
    local weapon = state.weapon
    if weapon and weapon.isItem then
        repairable = Config.REPAIR_TOOLS[weapon.model]
    end
    local record, kind = state.grid:nearestInteractable(cx, cy, Config.INTERACT_RANGE, repairable)
    if not record then return end
    local def = Interact.forKind(kind)
    if not def or not def.canShow(state, record) then return end
    holder.interactRecord = record
    holder.interactKind = kind
    holder.interactButtonRect = Interact.buttonRect(state.grid, record)
end

function Interact.tryActivate(state, sx, sy, holder)
    local rect = holder.interactButtonRect
    if not rect then return false end
    local wx, wy = Coordinates.screenToWorld(state, sx, sy)
    if not isPointInRect(wx, wy, rect) then return false end
    local def = Interact.forKind(holder.interactKind)
    if not def then return false end
    if def.canShow(state, holder.interactRecord) then def.activate(state, holder.interactRecord) end
    return true
end

function Interact.activateNearest(state, holder)
    if Interact.hasOpenMenu(state) then return false end
    if not holder.interactRecord or not holder.interactKind then return false end
    local def = Interact.forKind(holder.interactKind)
    if not def then return false end
    if def.canShow(state, holder.interactRecord) then def.activate(state, holder.interactRecord) end
    return true
end

function Interact.draw(state, holder)
    local rect = holder.interactButtonRect
    if not rect then return end
    local def = Interact.forKind(holder.interactKind)
    if not def then return end

    local hovered = false
    local mx, my = love.mouse.getPosition()
    local wx, wy = Coordinates.screenToWorld(state, mx, my)
    if isPointInRect(wx, wy, rect) then hovered = true end

    local x, y, w, h = rect.x, rect.y, rect.w, rect.h
    if hovered then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setLineWidth(2)
    else
        love.graphics.setColor(0.9, 0.9, 0.9, 0.9)
        love.graphics.setLineWidth(1)
    end
    love.graphics.rectangle("line", x + 2, y + 2, w - 4, h - 4)
    love.graphics.setLineWidth(1)

    local font = Fonts.get(Interact.labelSize(def, rect))
    love.graphics.setFont(font)
    love.graphics.setColor(1, 1, 1)
    local lineHeight = font:getHeight() * 0.8
    local startY = y + h / 2 - lineHeight * #def.lines / 2
    for i, lineText in ipairs(def.lines) do
        local lineW = font:getWidth(lineText)
        love.graphics.print(lineText, x + w / 2 - lineW / 2, startY + (i - 1) * lineHeight)
    end
end

return Interact
