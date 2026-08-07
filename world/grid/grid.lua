-- The world grid: block/object placement, occupancy tests and lookups.
-- Runtime state (map size, etc.) is read from the injected game state.

local Object = require "lib.classic"
local Config = require "core.config"
local Container = require "core.container"
local Textures = require "core.textures"

local Grid = Object:extend()

local BLOCK_SIZE = Config.GRID_BLOCK_SIZE
local CHEST_SLOTS = Config.INVENTORY_CHEST_SLOTS

function Grid:new(state)
    self.state = state
    self.grid = {}
    self.objects = {}
    self.blockRecords = {}
    self.objectRecords = {}
    self.tileSize = 10
    self.cols = math.floor(state.mapWidth / self.tileSize)
    self.rows = math.floor(state.mapHeight / self.tileSize)
    self.regrowingRecords = {}
    self.layoutVersion = 0
end

function Grid.load()
    Textures.load("images/block_spritesheet.png", 40)
    Textures.define("grass", 1)
    Textures.define("dirt", 2)
    Textures.define("workshop", 3)
    Textures.define("stone_wall", 4)
    Textures.define("slot_STONE_WALL", 4)
    Textures.define("rock_path", 5)
    Textures.define("water", 6)
    Textures.define("wood_wall", 7)
    Textures.define("sand", 8)
    Textures.define("glass", 9)
    Textures.define("slot_GLASS", 9)
    Textures.define("shop", 10)
    Textures.define("barricade", 11)
    Textures.define("slot_BARRICADE", 11)
    Textures.load("images/object_spritesheet.png", 40)
    Textures.define("toxic_barrel", 1)
    Textures.define("barrel", 2)
    Textures.define("slot_BARREL", 2)
    Textures.define("bush", 3)
    Textures.define("tree", 4)
    Textures.define("stone", 5)
    Textures.define("slot_STICKS", 6)
    Textures.define("slot_ROCKS", 7)
    Textures.define("sand_object", 8)
    Textures.define("slot_SAND", 8)
end

function Grid:_index(col, row)
    return (row - 1) * self.cols + col
end

function Grid:rebuildGrid()
    for i = 1, self.cols * self.rows do
        self.grid[i] = nil
        self.objects[i] = nil
    end
    for _, record in ipairs(self.blockRecords) do
        self:_fillArea(self.grid, record.col, record.row, record.material)
    end
    for _, record in ipairs(self.objectRecords) do
        self:_fillArea(self.objects, record.col, record.row, record.material)
    end
    self:_touchLayout()
end

function Grid:_touchLayout()
    self.layoutVersion = self.layoutVersion + 1
end

function Grid:_fillArea(target, col, row, material)
    for dy = 0, BLOCK_SIZE - 1 do
        for dx = 0, BLOCK_SIZE - 1 do
            local c = col + dx
            local r = row + dy
            if c >= 1 and c <= self.cols and r >= 1 and r <= self.rows then
                target[self:_index(c, r)] = material
            end
        end
    end
end

function Grid:findBlockRecord(col, row, records)
    for i = #records, 1, -1 do
        local r = records[i]
        if col >= r.col and col < r.col + BLOCK_SIZE
        and row >= r.row and row < r.row + BLOCK_SIZE then
            return i, r
        end
    end
    return nil
end

function Grid:placeBlock(col, row, material)
    col = math.max(1, math.min(self.cols - BLOCK_SIZE + 1, col))
    row = math.max(1, math.min(self.rows - BLOCK_SIZE + 1, row))
    table.insert(self.blockRecords, { col = col, row = row, material = material, health = self:_maxHealth(material) })
    self:_fillArea(self.grid, col, row, material)
    self:_touchLayout()
end

function Grid:removeBlock(col, row)
    local index, record = self:findBlockRecord(col, row, self.blockRecords)
    if not index then return false end
    table.remove(self.blockRecords, index)
    self:rebuildGrid()
    return true
end

function Grid:placeObject(col, row, material)
    col = math.max(1, math.min(self.cols - BLOCK_SIZE + 1, col))
    row = math.max(1, math.min(self.rows - BLOCK_SIZE + 1, row))
    table.insert(self.objectRecords, { col = col, row = row, material = material, health = self:_maxHealth(material), contents = self:_newContents(material) })
    self:_fillArea(self.objects, col, row, material)
    self:_touchLayout()
end

function Grid:_newContents(material)
    local item = Config.BUILDING_ITEMS[material]
    if item and item.chest then return Container.new(CHEST_SLOTS) end
    return nil
end

function Grid:removeObject(col, row)
    local index, record = self:findBlockRecord(col, row, self.objectRecords)
    if not index then return false end
    table.remove(self.objectRecords, index)
    self:rebuildGrid()
    return true
end

function Grid:isTileBlocked(col, row, ignoreShootThrough)
    if col < 1 or col > self.cols or row < 1 or row > self.rows then return true end
    local idx = self:_index(col, row)
    if self:_tileBlocksMovement(self.grid[idx], ignoreShootThrough) then return true end
    if self:_tileBlocksMovement(self.objects[idx], ignoreShootThrough) then return true end
    return false
end

function Grid:_tileBlocksMovement(material, ignoreShootThrough)
    if not material then return false end
    local item = Config.BUILDING_ITEMS[material]
    if not item or not item.blocksMovement then return false end
    if not ignoreShootThrough then return true end
    return not (item.bulletproof and not item.stopsBullets)
end

function Grid:isCircleBlocked(cx, cy, radius, ignoreShootThrough)
    local minCol = math.max(1, math.floor((cx - radius) / self.tileSize) + 1)
    local maxCol = math.min(self.cols, math.floor((cx + radius) / self.tileSize) + 1)
    local minRow = math.max(1, math.floor((cy - radius) / self.tileSize) + 1)
    local maxRow = math.min(self.rows, math.floor((cy + radius) / self.tileSize) + 1)

    for row = minRow, maxRow do
        for col = minCol, maxCol do
            if self:isTileBlocked(col, row, ignoreShootThrough) then
                local tileX = (col - 1) * self.tileSize
                local tileY = (row - 1) * self.tileSize
                local closestX = math.max(tileX, math.min(cx, tileX + self.tileSize))
                local closestY = math.max(tileY, math.min(cy, tileY + self.tileSize))
                if (cx - closestX) * (cx - closestX) + (cy - closestY) * (cy - closestY) < radius * radius then
                    return true
                end
            end
        end
    end
    return false
end

function Grid:_isAreaFree(col, row, size, tiles, ignoreMaterial)
    for dy = 0, size - 1 do
        for dx = 0, size - 1 do
            local c = col + dx
            local r = row + dy
            if c >= 1 and c <= self.cols and r >= 1 and r <= self.rows then
                local material = tiles[self:_index(c, r)]
                if material and material ~= ignoreMaterial then return false end
            end
        end
    end
    return true
end

function Grid:isAreaFreeOfBlocks(col, row, size)
    return self:_isAreaFree(col, row, size, self.grid, "grass")
end

function Grid:isAreaFreeOfObjects(col, row, size)
    return self:_isAreaFree(col, row, size, self.objects)
end

function Grid:tileAt(worldX, worldY)
    local col = math.floor(worldX / self.tileSize) + 1
    local row = math.floor(worldY / self.tileSize) + 1
    if col < 1 or col > self.cols or row < 1 or row > self.rows then return nil end
    return col, row
end

function Grid:_maxHealth(material)
    local item = Config.BUILDING_ITEMS[material]
    if item and item.health and item.health > 0 then return item.health end
    return 0
end

function Grid:getMaterialAt(worldX, worldY)
    local col, row = self:tileAt(worldX, worldY)
    if not col then return nil end
    return self.objects[self:_index(col, row)] or self.grid[self:_index(col, row)]
end

function Grid:recordWorldRect(record)
    local size = BLOCK_SIZE * self.tileSize
    return (record.col - 1) * self.tileSize, (record.row - 1) * self.tileSize, size, size
end

function Grid:recordWorldCenter(record)
    local x, y, w, h = self:recordWorldRect(record)
    return x + w / 2, y + h / 2
end

function Grid:nearestInteractable(worldX, worldY, range, repairable)
    -- When a repair tool is equipped, a damaged repairable object takes
    -- priority over openable prompts (barrel/shop/workshop).
    if repairable then
        local best, bestDist = nil, range * range
        for _, list in ipairs({ self.objectRecords, self.blockRecords }) do
            for _, record in ipairs(list) do
                if repairable[record.material] and record.health < self:_maxHealth(record.material) then
                    local cx, cy = self:recordWorldCenter(record)
                    local px, py = worldX - cx, worldY - cy
                    local d = px * px + py * py
                    if d <= bestDist then
                        bestDist = d
                        best = record
                    end
                end
            end
        end
        if best then return best, "repair" end
    end
    local best, bestDist, bestKind = nil, range * range, nil
    for _, record in ipairs(self.objectRecords) do
        if record.contents then
            local cx, cy = self:recordWorldCenter(record)
            local px, py = worldX - cx, worldY - cy
            local d = px * px + py * py
            if d <= bestDist then
                bestDist = d
                best, bestKind = record, "chest"
            end
        end
    end
    for _, record in ipairs(self.blockRecords) do
        if record.material == "shop" or record.material == "workshop" then
            local cx, cy = self:recordWorldCenter(record)
            local px, py = worldX - cx, worldY - cy
            local d = px * px + py * py
            if d <= bestDist then
                bestDist = d
                best, bestKind = record, record.material == "shop" and "shop" or "workshop"
            end
        end
    end
    return best, bestKind
end

require("world.grid.grid_damage")(Grid)
require("world.grid.grid_vision")(Grid)
require("world.grid.grid_io")(Grid)
require("world.grid.grid_draw")(Grid)

return Grid
