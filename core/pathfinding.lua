local Pathfinding = {}

local SQRT2 = math.sqrt(2)
local MAX_ITERATIONS = PATHFINDING_MAX_ITERATIONS

local NEIGHBORS = {
    { dx = 1,  dy = 0,  cost = 1 },
    { dx = -1, dy = 0,  cost = 1 },
    { dx = 0,  dy = 1,  cost = 1 },
    { dx = 0,  dy = -1, cost = 1 },
    { dx = 1,  dy = 1,  cost = SQRT2 },
    { dx = 1,  dy = -1, cost = SQRT2 },
    { dx = -1, dy = 1,  cost = SQRT2 },
    { dx = -1, dy = -1, cost = SQRT2 },
}

local Heap = {}
Heap.__index = Heap

function Heap.new()
    return setmetatable({ items = {} }, Heap)
end

function Heap:push(node)
    local items = self.items
    table.insert(items, node)
    local i = #items
    while i > 1 do
        local parent = math.floor(i / 2)
        if items[i].f < items[parent].f then
            items[i], items[parent] = items[parent], items[i]
            i = parent
        else
            break
        end
    end
end

function Heap:pop()
    local items = self.items
    local top = items[1]
    local last = table.remove(items)
    if #items > 0 then
        items[1] = last
        local i = 1
        while true do
            local left = i * 2
            local right = left + 1
            local smallest = i
            if left <= #items and items[left].f < items[smallest].f then smallest = left end
            if right <= #items and items[right].f < items[smallest].f then smallest = right end
            if smallest == i then break end
            items[i], items[smallest] = items[smallest], items[i]
            i = smallest
        end
    end
    return top
end

function Heap:isEmpty()
    return #self.items == 0
end

local function heuristic(dx, dy)
    local ax = math.abs(dx)
    local ay = math.abs(dy)
    return math.max(ax, ay) + (SQRT2 - 1) * math.min(ax, ay)
end

local function tileIndex(col, row, cols)
    return (row - 1) * cols + col
end

-- A tile is walkable when an entity circle of the given radius can sit at its
-- center without overlapping any blocking block/object.
local function computeWalkableMap(grid, radius)
    local cols, rows = grid.cols, grid.rows
    local ts = grid.tileSize
    local walkable = {}
    for row = 1, rows do
        walkable[row] = {}
        for col = 1, cols do
            local cx = (col - 1) * ts + ts / 2
            local cy = (row - 1) * ts + ts / 2
            walkable[row][col] = not grid:isCircleBlocked(cx, cy, radius)
        end
    end
    return walkable
end

-- The walkable map only depends on the grid layout and entity radius, both of
-- which stay fixed during horde mode, so cache it across path requests.
local walkableCache = { grid = nil, radius = nil, map = nil }

local function getWalkableMap(grid, radius)
    if walkableCache.grid == grid and walkableCache.radius == radius then
        return walkableCache.map
    end
    walkableCache.grid = grid
    walkableCache.radius = radius
    walkableCache.map = computeWalkableMap(grid, radius)
    return walkableCache.map
end

local function findNearestWalkable(walkable, cols, rows, targetCol, targetRow)
    local best, bestDist
    for row = 1, rows do
        for col = 1, cols do
            if walkable[row][col] then
                local d = (col - targetCol) * (col - targetCol) + (row - targetRow) * (row - targetRow)
                if not bestDist or d < bestDist then
                    bestDist = d
                    best = { col = col, row = row }
                end
            end
        end
    end
    return best
end

function Pathfinding.findPath(startCol, startRow, endCol, endRow, grid, radius)
    radius = radius or 15
    local cols, rows = grid.cols, grid.rows

    local walkable = getWalkableMap(grid, radius)

    -- If the target tile is inside a wall (e.g., the player stands against one),
    -- aim for the nearest walkable tile instead.
    if not walkable[endRow][endCol] then
        local nearest = findNearestWalkable(walkable, cols, rows, endCol, endRow)
        if not nearest then return {} end
        endCol, endRow = nearest.col, nearest.row
    end

    if not walkable[startRow][startCol] then return {} end

    local cameFrom = {}
    local gScore = {}
    local open = Heap.new()
    local closed = {}

    local startKey = tileIndex(startCol, startRow, cols)
    gScore[startKey] = 0
    open:push({ col = startCol, row = startRow, key = startKey, f = heuristic(endCol - startCol, endRow - startRow) })

    local iterations = 0

    while not open:isEmpty() and iterations < MAX_ITERATIONS do
        iterations = iterations + 1
        local current = open:pop()

        if current.col == endCol and current.row == endRow then
            local path = {}
            local key = current.key
            while key do
                local col = (key - 1) % cols + 1
                local row = math.floor((key - 1) / cols) + 1
                table.insert(path, 1, { col = col, row = row })
                key = cameFrom[key]
            end
            return path
        end

        if not closed[current.key] then
            closed[current.key] = true
            local currentG = gScore[current.key]
            for _, neighbor in ipairs(NEIGHBORS) do
                local nCol = current.col + neighbor.dx
                local nRow = current.row + neighbor.dy
                if nCol >= 1 and nCol <= cols and nRow >= 1 and nRow <= rows and walkable[nRow][nCol] then
                    local nKey = tileIndex(nCol, nRow, cols)
                    if not closed[nKey] then
                        local tentativeG = currentG + neighbor.cost
                        if not gScore[nKey] or tentativeG < gScore[nKey] then
                            gScore[nKey] = tentativeG
                            cameFrom[nKey] = current.key
                            open:push({ col = nCol, row = nRow, key = nKey, f = tentativeG + heuristic(endCol - nCol, endRow - nRow) })
                        end
                    end
                end
            end
        end
    end

    return {}
end

return Pathfinding
