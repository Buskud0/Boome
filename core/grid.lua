Grid = Object:extend()

local BLOCK_SIZE = 4

function Grid:new()
    self.grid = {}
    self.objects = {}
    self.blockRecords = {}
    self.objectRecords = {}
    self.tileSize = 10
    self.cols = math.floor(mapWidth / self.tileSize)
    self.rows = math.floor(mapHeight / self.tileSize)
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

function Grid:_clearArea(target, col, row)
    for dy = 0, BLOCK_SIZE - 1 do
        for dx = 0, BLOCK_SIZE - 1 do
            local c = col + dx
            local r = row + dy
            if c >= 1 and c <= self.cols and r >= 1 and r <= self.rows then
                target[(r - 1) * self.cols + c] = nil
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

function Grid:isBlocked(px, py, w, h)
    local corners = {
        {px, py},
        {px + w - 1, py},
        {px, py + h - 1},
        {px + w - 1, py + h - 1},
    }
    for _, corner in ipairs(corners) do
        local col = math.floor(corner[1] / self.tileSize) + 1
        local row = math.floor(corner[2] / self.tileSize) + 1
        if col >= 1 and col <= self.cols and row >= 1 and row <= self.rows then
            if self:isTileBlocked(col, row) then return true end
        end
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

function Grid:getMaterialAtTile(col, row)
    if col < 1 or col > self.cols or row < 1 or row > self.rows then return nil end
    local idx = (row - 1) * self.cols + col
    return self.objects[idx] or self.grid[idx]
end

function Grid:drawBlocks()
    for _, record in ipairs(self.blockRecords) do
        Textures.draw(record.material, (record.col - 1) * self.tileSize, (record.row - 1) * self.tileSize, 40, 40)
    end
end

function Grid:drawObjects()
    for _, record in ipairs(self.objectRecords) do
        Textures.draw(record.material, (record.col - 1) * self.tileSize, (record.row - 1) * self.tileSize, 40, 40)
    end
end

function Grid:draw()
    self:drawBlocks()
    self:drawObjects()
end

function Grid:drawMaterial(material)
    for _, record in ipairs(self.blockRecords) do
        if record.material == material then
            Textures.draw(material, (record.col - 1) * self.tileSize, (record.row - 1) * self.tileSize, 40, 40)
        end
    end
end

function Grid:getObjectAt(worldX, worldY)
    local col = math.floor(worldX / self.tileSize) + 1
    local row = math.floor(worldY / self.tileSize) + 1
    if col < 1 or col > self.cols or row < 1 or row > self.rows then return nil end
    local idx = (row - 1) * self.cols + col
    return self.objects[idx]
end

function Grid:clearTile(col, row)
    local idx = (row - 1) * self.cols + col
    self.grid[idx] = nil
end

function Grid:colorTile(material, col, row)
    local idx = (row - 1) * self.cols + col
    self.grid[idx] = material
end

function Grid:clearObject(col, row)
    local idx = (row - 1) * self.cols + col
    self.objects[idx] = nil
end

function Grid:placeObjectTile(material, col, row)
    local idx = (row - 1) * self.cols + col
    self.objects[idx] = material
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
