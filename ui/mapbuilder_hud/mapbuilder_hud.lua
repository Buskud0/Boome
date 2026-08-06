-- Map builder HUD: quick-access slots and save/revert buttons.
-- Core state, layout rects and hit-testing. Drawing is attached by the
-- mixin required at the bottom of this file.

local Config = require "core.config"

local MapBuilderHUD = {}
MapBuilderHUD.__index = MapBuilderHUD

local SLOT_SIZE = Config.MAPBUILDER_HUD_SLOT_SIZE
local SLOT_GAP = Config.MAPBUILDER_HUD_SLOT_GAP
local HUD_BOTTOM_MARGIN = Config.MAPBUILDER_HUD_BOTTOM_MARGIN
local BUTTON_WIDTH = Config.MAPBUILDER_HUD_BUTTON_WIDTH
local BUTTON_HEIGHT = Config.MAPBUILDER_HUD_BUTTON_HEIGHT

local function isPointInRect(x, y, rect)
    return x >= rect.x and x <= rect.x + rect.w and y >= rect.y and y <= rect.y + rect.h
end

function MapBuilderHUD.new(state)
    local self = setmetatable({}, MapBuilderHUD)
    self.state = state
    return self
end

function MapBuilderHUD:getSlotRects()
    local state = self.state
    local count = state.mapBuilder.QUICK_ACCESS_COUNT
    local totalWidth = count * SLOT_SIZE + (count - 1) * SLOT_GAP
    local startX = math.floor(state.scrWidth / 2 - totalWidth / 2 + state.camera.x)
    local slotY = state.scrHeight - SLOT_SIZE - HUD_BOTTOM_MARGIN + state.camera.y
    local rects = {}
    for i = 1, count do
        local slotX = startX + (i - 1) * (SLOT_SIZE + SLOT_GAP)
        rects[i] = { x = slotX, y = slotY, w = SLOT_SIZE, h = SLOT_SIZE }
    end
    return rects
end

function MapBuilderHUD:getSaveButtonRect()
    local state = self.state
    return { x = state.scrWidth - BUTTON_WIDTH - 16 + state.camera.x, y = 16 + state.camera.y, w = BUTTON_WIDTH, h = BUTTON_HEIGHT }
end

function MapBuilderHUD:getRevertButtonRect()
    local saveRect = self:getSaveButtonRect()
    return { x = saveRect.x - BUTTON_WIDTH - 8, y = saveRect.y, w = BUTTON_WIDTH, h = BUTTON_HEIGHT }
end

function MapBuilderHUD:isPointerOverHUD(worldX, worldY)
    for _, rect in ipairs(self:getSlotRects()) do
        if isPointInRect(worldX, worldY, rect) then return true end
    end
    if isPointInRect(worldX, worldY, self:getSaveButtonRect()) then return true end
    if isPointInRect(worldX, worldY, self:getRevertButtonRect()) then return true end
    return false
end

require("ui.mapbuilder_hud.mbh_draw")(MapBuilderHUD)

return MapBuilderHUD
