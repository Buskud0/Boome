Grid = Object:extend()

local BLOCK_SIZE = GRID_BLOCK_SIZE

function Grid:new()
    self.grid = {}
    self.objects = {}
    self.blockRecords = {}
    self.objectRecords = {}
    self.tileSize = 10
    self.cols = math.floor(mapWidth / self.tileSize)
    self.rows = math.floor(mapHeight / self.tileSize)
end

function Grid.load()
    Textures.load("images/block_spritesheet.png", 40)
    Textures.define("dirt", 2)
    Textures.define("grass", 3)
    Textures.define("shop", 4)
    Textures.define("stone", 5)
    Textures.define("rock_path", 6)
    Textures.define("water", 7)
    Textures.define("wood_wall", 8)
    Textures.load("images/object_spritesheet.png", 40)
    Textures.define("toxic_barrel", 1)
    Textures.define("barrel", 2)
    Textures.define("bush", 3)
    Textures.define("tree", 4)
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
end

function Grid:_fillArea(target, col, row, material)
    for dy = 0, BLOCK_SIZE - 1 do
        for dx = 0, BLOCK_SIZE - 1 do
            local c = col + dx
            local r = row + dy
            if c >= 1 and c <= self.cols and r >= 1 and r <= self.rows then
                target[(r - 1) * self.cols + c] = material
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
    table.insert(self.blockRecords, { col = col, row = row, material = material })
    self:_fillArea(self.grid, col, row, material)
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
    table.insert(self.objectRecords, { col = col, row = row, material = material })
    self:_fillArea(self.objects, col, row, material)
end

function Grid:removeObject(col, row)
    local index, record = self:findBlockRecord(col, row, self.objectRecords)
    if not index then return false end
    table.remove(self.objectRecords, index)
    self:rebuildGrid()
    return true
end

function Grid:isTileBlocked(col, row)
    if col < 1 or col > self.cols or row < 1 or row > self.rows then return true end
    local idx = (row - 1) * self.cols + col
    if self.grid[idx] then
        local item = BUILDING_ITEMS[self.grid[idx]]
        if item and item.blocksMovement then return true end
    end
    if self.objects[idx] then
        local item = BUILDING_ITEMS[self.objects[idx]]
        if item and item.blocksMovement then return true end
    end
    return false
end

function Grid:isCircleBlocked(cx, cy, radius)
    local minCol = math.max(1, math.floor((cx - radius) / self.tileSize) + 1)
    local maxCol = math.min(self.cols, math.floor((cx + radius) / self.tileSize) + 1)
    local minRow = math.max(1, math.floor((cy - radius) / self.tileSize) + 1)
    local maxRow = math.min(self.rows, math.floor((cy + radius) / self.tileSize) + 1)

    for row = minRow, maxRow do
        for col = minCol, maxCol do
            if self:isTileBlocked(col, row) then
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

function Grid:isAreaFreeOfBlocks(col, row, size)
    for dy = 0, size - 1 do
        for dx = 0, size - 1 do
            local c = col + dx
            local r = row + dy
            if c >= 1 and c <= self.cols and r >= 1 and r <= self.rows then
                local idx = (r - 1) * self.cols + c
                if self.grid[idx] then return false end
            end
        end
    end
    return true
end

function Grid:isAreaFreeOfObjects(col, row, size)
    for dy = 0, size - 1 do
        for dx = 0, size - 1 do
            local c = col + dx
            local r = row + dy
            if c >= 1 and c <= self.cols and r >= 1 and r <= self.rows then
                local idx = (r - 1) * self.cols + c
                if self.objects[idx] then return false end
            end
        end
    end
    return true
end

function Grid:getMaterialAt(worldX, worldY)
    local col = math.floor(worldX / self.tileSize) + 1
    local row = math.floor(worldY / self.tileSize) + 1
    if col < 1 or col > self.cols or row < 1 or row > self.rows then return nil end
    local idx = (row - 1) * self.cols + col
    return self.objects[idx] or self.grid[idx]
end

function Grid:isTileVisionBlocked(col, row)
    if col < 1 or col > self.cols or row < 1 or row > self.rows then return false end
    local idx = (row - 1) * self.cols + col
    local material = self.objects[idx] or self.grid[idx]
    if material then
        local item = BUILDING_ITEMS[material]
        if item and item.blocksVision then return true end
    end
    return false
end

function Grid:getVisionCornerAngles(px, py, minAngle, maxAngle)
    local angles = {}
    local ts = self.tileSize
    local size = BLOCK_SIZE * ts
    for _, record in ipairs(self.blockRecords) do
        local item = BUILDING_ITEMS[record.material]
        if item and item.blocksVision then
            local x1 = (record.col - 1) * ts
            local y1 = (record.row - 1) * ts
            local x2 = x1 + size
            local y2 = y1 + size
            local corners = { {x1, y1}, {x2, y1}, {x1, y2}, {x2, y2} }
            for i = 1, 4 do
                local a = math.atan2(corners[i][2] - py, corners[i][1] - px)
                if a >= minAngle and a <= maxAngle then
                    angles[#angles + 1] = a
                end
            end
        end
    end
    return angles
end

function Grid:segmentBlocksVision(x1, y1, x2, y2)
    local ts = self.tileSize
    local col = math.floor(x1 / ts) + 1
    local row = math.floor(y1 / ts) + 1
    local endCol = math.floor(x2 / ts) + 1
    local endRow = math.floor(y2 / ts) + 1

    local dx = x2 - x1
    local dy = y2 - y1

    local stepX = 0
    if col < endCol then stepX = 1 elseif col > endCol then stepX = -1 end
    local stepY = 0
    if row < endRow then stepY = 1 elseif row > endRow then stepY = -1 end

    local tDeltaX = stepX ~= 0 and (ts / math.abs(dx)) or math.huge
    local tDeltaY = stepY ~= 0 and (ts / math.abs(dy)) or math.huge

    local tMaxX, tMaxY = math.huge, math.huge
    if stepX == 1 then
        tMaxX = (col * ts - x1) / math.abs(dx)
    elseif stepX == -1 then
        tMaxX = (x1 - (col - 1) * ts) / math.abs(dx)
    end
    if stepY == 1 then
        tMaxY = (row * ts - y1) / math.abs(dy)
    elseif stepY == -1 then
        tMaxY = (y1 - (row - 1) * ts) / math.abs(dy)
    end

    while true do
        if self:isTileVisionBlocked(col, row) then return true end
        if col == endCol and row == endRow then return false end
        if tMaxX < tMaxY then
            tMaxX = tMaxX + tDeltaX
            col = col + stepX
        else
            tMaxY = tMaxY + tDeltaY
            row = row + stepY
        end
    end
end

function Grid:drawBlocks()
    for _, record in ipairs(self.blockRecords) do
        Textures.draw(record.material, (record.col - 1) * self.tileSize, (record.row - 1) * self.tileSize, 40, 40)
    end
end

function Grid:drawObjects()
    for _, record in ipairs(self.objectRecords) do
        if record.material ~= "bush" then
            Textures.draw(record.material, (record.col - 1) * self.tileSize, (record.row - 1) * self.tileSize, 40, 40)
        end
    end
end

function Grid:drawBushesAboveEntities()
    for _, record in ipairs(self.objectRecords) do
        if record.material == "bush" then
            Textures.draw(record.material, (record.col - 1) * self.tileSize, (record.row - 1) * self.tileSize, 40, 40)
        end
    end
end

function Grid:draw()
    self:drawBlocks()
    self:drawObjects()
end

function Grid:saveData()
    local lines = {}
    for _, record in ipairs(self.blockRecords) do
        table.insert(lines, record.col .. "," .. record.row .. "," .. record.material)
    end
    for _, record in ipairs(self.objectRecords) do
        table.insert(lines, "o," .. record.col .. "," .. record.row .. "," .. record.material)
    end
    return table.concat(lines, "\n")
end

function Grid:loadData(data)
    self.grid = {}
    self.objects = {}
    self.blockRecords = {}
    self.objectRecords = {}
    if not data or #data == 0 then return end
    for line in data:gmatch("[^\r\n]+") do
        local x, y, material = line:match("^o,(%d+),(%d+),(%S+)$")
        if x then
            self:placeObject(tonumber(x), tonumber(y), material)
        else
            x, y, material = line:match("^(%d+),(%d+),(%S+)$")
            if x then
                self:placeBlock(tonumber(x), tonumber(y), material)
            end
        end
    end
end

function Grid:debugDraw()
    local ts = self.tileSize
    love.graphics.setColor(1, 0, 0, 0.3)
    for row = 1, self.rows do
        for col = 1, self.cols do
            if self:isTileBlocked(col, row) then
                love.graphics.rectangle("fill", (col - 1) * ts, (row - 1) * ts, ts, ts)
            end
        end
    end
    love.graphics.setColor(1, 1, 1, 1)
end
