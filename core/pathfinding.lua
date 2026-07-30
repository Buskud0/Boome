local Pathfinding = {}

local COST = 10
local MAX_ITERATIONS = 10000

local function manhattan(a, b)
    return (math.abs(a.col - b.col) + math.abs(a.row - b.row)) * COST
end

local DIRECTIONS = {
    { col = 0, row = -1, cost = COST },
    { col = 0, row = 1,  cost = COST },
    { col = -1, row = 0, cost = COST },
    { col = 1, row = 0,  cost = COST },
}

local function isTileBlocked(grid, col, row)
    local idx = (row - 1) * grid.cols + col
    if grid.grid[idx] then
        local item = BUILDING_ITEMS[grid.grid[idx]]
        if item and item.blocksMovement then return true end
    end
    if grid.objects[idx] then
        local item = BUILDING_ITEMS[grid.objects[idx]]
        if item and item.blocksMovement then return true end
    end
    return false
end

-- Dilation: tiles within `clearance` tiles of any blocked tile are non-walkable
local function computeWalkableMap(grid, clearance)
    local walkable = {}
    for row = 1, grid.rows do
        walkable[row] = {}
        for col = 1, grid.cols do
            walkable[row][col] = true
        end
    end
    for row = 1, grid.rows do
        for col = 1, grid.cols do
            if isTileBlocked(grid, col, row) then
                for dy = -clearance, clearance do
                    local nr = row + dy
                    if nr >= 1 and nr <= grid.rows then
                        for dx = -clearance, clearance do
                            local nc = col + dx
                            if nc >= 1 and nc <= grid.cols then
                                walkable[nr][nc] = false
                            end
                        end
                    end
                end
            end
        end
    end
    return walkable
end

local Heap = {}
Heap.__index = Heap

function Heap:new()
    return setmetatable({ items = {}, size = 0 }, self)
end

function Heap:push(node)
    self.size = self.size + 1
    local i = self.size
    self.items[i] = node
    while i > 1 do
        local parent = math.floor(i / 2)
        if self.items[parent].f <= self.items[i].f then break end
        self.items[parent], self.items[i] = self.items[i], self.items[parent]
        i = parent
    end
end

function Heap:pop()
    if self.size == 0 then return nil end
    local root = self.items[1]
    self.items[1] = self.items[self.size]
    self.items[self.size] = nil
    self.size = self.size - 1
    local i = 1
    while true do
        local smallest = i
        local left = i * 2
        local right = i * 2 + 1
        if left <= self.size and self.items[left].f < self.items[smallest].f then
            smallest = left
        end
        if right <= self.size and self.items[right].f < self.items[smallest].f then
            smallest = right
        end
        if smallest == i then break end
        self.items[i], self.items[smallest] = self.items[smallest], self.items[i]
        i = smallest
    end
    return root
end

function Heap:isEmpty()
    return self.size == 0
end

function Pathfinding.findPath(startCol, startRow, endCol, endRow, grid, clearance)
    startCol = math.max(1, math.min(grid.cols, startCol))
    startRow = math.max(1, math.min(grid.rows, startRow))
    endCol = math.max(1, math.min(grid.cols, endCol))
    endRow = math.max(1, math.min(grid.rows, endRow))

    if startCol == endCol and startRow == endRow then
        return {}
    end

    local walkable = computeWalkableMap(grid, clearance or 2)

    if not walkable[endRow][endCol] then
        local found = false
        for radius = 1, 10 do
            for dc = -radius, radius do
                local nc = endCol + dc
                if nc >= 1 and nc <= grid.cols then
                    for _, dr in ipairs({ -radius, radius }) do
                        local nr = endRow + dr
                        if nr >= 1 and nr <= grid.rows and walkable[nr][nc] then
                            endCol, endRow = nc, nr
                            found = true
                            break
                        end
                    end
                end
            end
            if found then break end
            for dr = -(radius - 1), radius - 1 do
                local nr = endRow + dr
                if nr >= 1 and nr <= grid.rows then
                    for _, dc in ipairs({ -radius, radius }) do
                        local nc = endCol + dc
                        if nc >= 1 and nc <= grid.cols and walkable[nr][nc] then
                            endCol, endRow = nc, nr
                            found = true
                            break
                        end
                    end
                end
            end
            if found then break end
        end
    end

    if not walkable[startRow][startCol] or not walkable[endRow][endCol] then
        return {}
    end

    local open = Heap:new()
    local bestG = {}
    local cameFrom = {}

    local startKey = startCol .. "," .. startRow
    bestG[startKey] = 0
    local startH = manhattan({col = startCol, row = startRow}, {col = endCol, row = endRow})
    open:push({ col = startCol, row = startRow, g = 0, h = startH, f = startH })

    for _ = 1, MAX_ITERATIONS do
        if open:isEmpty() then return {} end

        local current = open:pop()
        local currentKey = current.col .. "," .. current.row

        if current.g > (bestG[currentKey] or math.huge) then
            -- stale entry
        elseif current.col == endCol and current.row == endRow then
            local path = {}
            while current do
                table.insert(path, 1, { col = current.col, row = current.row })
                local parent = cameFrom[current.col .. "," .. current.row]
                if not parent then break end
                current = parent
            end
            return path
        else
            for _, dir in ipairs(DIRECTIONS) do
                local ncol = current.col + dir.col
                local nrow = current.row + dir.row
                local nkey = ncol .. "," .. nrow

                if ncol >= 1 and ncol <= grid.cols and nrow >= 1 and nrow <= grid.rows
                   and walkable[nrow][ncol] then
                    local g = current.g + dir.cost
                    if g < (bestG[nkey] or math.huge) then
                        bestG[nkey] = g
                        local h = manhattan({col = ncol, row = nrow}, {col = endCol, row = endRow})
                        open:push({ col = ncol, row = nrow, g = g, h = h, f = g + h })
                        cameFrom[nkey] = { col = current.col, row = current.row }
                    end
                end
            end
        end
    end

    return {}
end

return Pathfinding
