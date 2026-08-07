-- Map builder: core state and lifecycle. Placement, history, input and draw
-- behavior are attached by the mixins required at the bottom of this file.

local Config = require "core.config"
local MapStorage = require "core.storage.mapstorage"

local MapBuilder = {}
MapBuilder.__index = MapBuilder

local QUICK_ACCESS_COUNT = Config.MAPBUILDER_QUICK_ACCESS_COUNT
local BLOCK_SIZE = Config.MAPBUILDER_BLOCK_SIZE

function MapBuilder.new(state)
    local self = setmetatable({}, MapBuilder)
    self.state = state
    self.QUICK_ACCESS_COUNT = QUICK_ACCESS_COUNT
    self.quickAccess = {}
    self.selectedSlot = 1
    self.hasUnsavedChanges = false
    self.hasSavedFile = false
    self.undoStack = {}
    self.redoStack = {}
    self.placeCooldown = 0
    self.lastPlacedCol = 0
    self.lastPlacedRow = 0
    self.dragSlot = nil
    self.dragStartX = 0
    self.dragStartY = 0
    self.currentMapName = nil
    return self
end

function MapBuilder:enter(mapName)
    self.currentMapName = mapName or self.currentMapName
    self:load()
    self:resetCamera()
    self:resetEditSession()
end

function MapBuilder:grassFillData()
    local tileSize = 10
    local cols = math.floor(self.state.mapWidth / tileSize)
    local rows = math.floor(self.state.mapHeight / tileSize)
    local blockCols = math.ceil(cols / BLOCK_SIZE)
    local blockRows = math.ceil(rows / BLOCK_SIZE)
    local lines = {}
    for br = 0, blockRows - 1 do
        for bc = 0, blockCols - 1 do
            table.insert(lines, (1 + bc * BLOCK_SIZE) .. "," .. (1 + br * BLOCK_SIZE) .. ",grass")
        end
    end
    return table.concat(lines, "\n")
end

function MapBuilder:resetCamera()
    local camera = self.state.camera
    camera.x = 0
    camera.y = 0
    camera.zoom = 1
end

function MapBuilder:resetEditSession()
    self.quickAccess = {}
    self.selectedSlot = 1
    self:resetHistory()
end

function MapBuilder:resetHistory()
    self.undoStack = {}
    self.redoStack = {}
end

function MapBuilder:isPointInRect(x, y, rect)
    return x >= rect.x and x <= rect.x + rect.w and y >= rect.y and y <= rect.y + rect.h
end

function MapBuilder:isValidTile(col, row)
    local grid = self.state.grid
    return col >= 1 and col <= grid.cols and row >= 1 and row <= grid.rows
end

function MapBuilder:screenToGrid(screenX, screenY)
    local grid = self.state.grid
    local camera = self.state.camera
    local worldX = (screenX + camera.x) / camera.zoom
    local worldY = (screenY + camera.y) / camera.zoom
    return math.floor(worldX / grid.tileSize) + 1, math.floor(worldY / grid.tileSize) + 1
end

function MapBuilder:getHoveredTile()
    local mx, my = love.mouse.getPosition()
    return self:screenToGrid(mx, my)
end

function MapBuilder:slotIndexAtPosition(wx, wy)
    local rects = self.state.mapBuilderHUD:getSlotRects()
    for i, rect in ipairs(rects) do
        if self:isPointInRect(wx, wy, rect) then
            return i
        end
    end
    return nil
end

function MapBuilder:isPointerOnSaveButton(wx, wy)
    return self:isPointInRect(wx, wy, self.state.mapBuilderHUD:getSaveButtonRect())
end

function MapBuilder:isPointerOnRevertButton(wx, wy)
    return self:isPointInRect(wx, wy, self.state.mapBuilderHUD:getRevertButtonRect())
end

function MapBuilder:startSlotDrag(slotIndex, wx, wy)
    self.dragSlot = slotIndex
    self.dragStartX = wx
    self.dragStartY = wy
end

function MapBuilder:dropItemFromSlot(slotIndex)
    if not self.quickAccess[slotIndex] then return end
    self.quickAccess[slotIndex] = nil
    if self.dragSlot == slotIndex then self.dragSlot = nil end
    self.state.toast:show("Item removed", 1)
end

function MapBuilder:completeSlotClick(slotIndex)
    self.selectedSlot = slotIndex
    self.dragSlot = nil
end

function MapBuilder:trySwapSlotWithTarget(wx, wy)
    local targetIndex = self:slotIndexAtPosition(wx, wy)
    if not targetIndex then return false end
    local temp = self.quickAccess[targetIndex]
    self.quickAccess[targetIndex] = self.quickAccess[self.dragSlot]
    self.quickAccess[self.dragSlot] = temp
    self.selectedSlot = targetIndex
    self.dragSlot = nil
    return true
end

function MapBuilder:save()
    local content = self.state.grid:saveData()
    if #content == 0 then
        self.state.toast:show("Nothing to save", 1)
        return
    end
    MapStorage.saveMap(self.currentMapName, content)
    self.hasUnsavedChanges = false
    self.hasSavedFile = true
    self.state.toast:show("Map saved", 1)
end

function MapBuilder:load()
    local content = MapStorage.loadMap(self.currentMapName)
    if not content then
        self:resetGrid()
        return
    end
    self.state.grid:loadData(content)
    self.hasUnsavedChanges = false
    self.hasSavedFile = true
end

function MapBuilder:resetGrid()
    local grid = self.state.grid
    grid.grid = {}
    grid.objects = {}
    grid.blockRecords = {}
    grid.objectRecords = {}
end

require("gamemodes.mapbuilder.mb_placement")(MapBuilder)
require("gamemodes.mapbuilder.mb_history")(MapBuilder)
require("gamemodes.mapbuilder.mb_input")(MapBuilder)
require("gamemodes.mapbuilder.mb_draw")(MapBuilder)

return MapBuilder