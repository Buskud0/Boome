-- Entity movement through the grid: blocked movement, wall sliding and
-- stuck-entity resolution.

local Movement = {}

function Movement.tryMove(state, entity, dx, dy, constrainToMap)
    if constrainToMap == nil then constrainToMap = true end
    local nx, ny = entity.x + dx, entity.y + dy

    if Movement.canMoveTo(state, entity, nx, ny, constrainToMap) then
        Movement.setEntityPosition(state, entity, nx, ny)
        return
    end

    local slideX, slideY = Movement.findBestSlidePosition(state, entity, nx, ny, dx, dy, constrainToMap)
    Movement.setEntityPosition(state, entity, slideX, slideY)
end

function Movement.setEntityPosition(state, entity, x, y)
    entity.x, entity.y = x, y
    Movement.resolveStuck(state, entity)
end

function Movement.canMoveTo(state, entity, x, y, constrainToMap)
    if constrainToMap then
        if x < 0 or x > state.mapWidth - entity.width then return false end
        if y < 0 or y > state.mapHeight - entity.height then return false end
    end
    local cx = x + entity.width / 2
    local cy = y + entity.height / 2
    return not state.grid:isCircleBlocked(cx, cy, entity.radius)
end

function Movement.findBestSlidePosition(state, entity, nx, ny, dx, dy, constrainToMap)
    local bx, by = entity.x, entity.y
    local hx, hy = Movement.findHorizontalSlide(state, entity, bx, by, nx, ny, constrainToMap)
    local vx, vy = Movement.findVerticalSlide(state, entity, bx, by, nx, ny, constrainToMap)
    local slideX, slideY = Movement.pickLongerSlide(bx, by, hx, hy, vx, vy)
    return Movement.tryCornerNudge(state, entity, bx, by, nx, ny, dx, dy, slideX, slideY, constrainToMap)
end

function Movement.findHorizontalSlide(state, entity, bx, by, nx, ny, constrainToMap)
    local hx, hy = bx, by
    if Movement.canMoveTo(state, entity, nx, hy, constrainToMap) then hx = nx end
    if Movement.canMoveTo(state, entity, hx, ny, constrainToMap) then hy = ny end
    return hx, hy
end

function Movement.findVerticalSlide(state, entity, bx, by, nx, ny, constrainToMap)
    local vx, vy = bx, by
    if Movement.canMoveTo(state, entity, vx, ny, constrainToMap) then vy = ny end
    if Movement.canMoveTo(state, entity, nx, vy, constrainToMap) then vx = nx end
    return vx, vy
end

function Movement.pickLongerSlide(bx, by, hx, hy, vx, vy)
    if math.abs(vx - bx) + math.abs(vy - by) > math.abs(hx - bx) + math.abs(hy - by) then
        return vx, vy
    end
    return hx, hy
end

function Movement.tryCornerNudge(state, entity, bx, by, nx, ny, dx, dy, slideX, slideY, constrainToMap)
    local movedX = slideX ~= bx
    local movedY = slideY ~= by
    if not ((dx ~= 0 and not movedX) or (dy ~= 0 and not movedY)) then
        return slideX, slideY
    end

    if dx ~= 0 and not movedX then
        for _, yn in ipairs({1, -1}) do
            if Movement.canMoveTo(state, entity, nx, by + yn, constrainToMap) then
                return nx, by + yn
            end
        end
    end

    if dy ~= 0 and not movedY then
        for _, xn in ipairs({1, -1}) do
            if Movement.canMoveTo(state, entity, bx + xn, ny, constrainToMap) then
                return bx + xn, ny
            end
        end
    end

    return slideX, slideY
end

function Movement.resolveStuck(state, entity)
    Movement.clampEntityToMap(state, entity)
    if not Movement.isEntityStuck(state, entity) then return end
    local bestX, bestY = Movement.findNearestClearCenter(state, entity)
    if bestX then
        entity.x = bestX - entity.width / 2
        entity.y = bestY - entity.height / 2
    end
end

function Movement.clampEntityToMap(state, entity)
    if entity.x < 0 then entity.x = 0
    elseif entity.x > state.mapWidth - entity.width then entity.x = state.mapWidth - entity.width end
    if entity.y < 0 then entity.y = 0
    elseif entity.y > state.mapHeight - entity.height then entity.y = state.mapHeight - entity.height end
end

function Movement.isEntityStuck(state, entity)
    local cx, cy = entity:getCenter()
    return state.grid:isCircleBlocked(cx, cy, entity.radius)
end

function Movement.findNearestClearCenter(state, entity)
    local grid = state.grid
    local cx, cy = entity:getCenter()
    local startCol = math.floor(cx / grid.tileSize) + 1
    local startRow = math.floor(cy / grid.tileSize) + 1
    local bestX, bestY, bestDistSq
    local maxRadius = 30

    for radius = 1, maxRadius do
        for row = startRow - radius, startRow + radius do
            for col = startCol - radius, startCol + radius do
                if math.max(math.abs(col - startCol), math.abs(row - startRow)) == radius then
                    if col >= 1 and col <= grid.cols and row >= 1 and row <= grid.rows then
                        local tx = (col - 1) * grid.tileSize + grid.tileSize / 2
                        local ty = (row - 1) * grid.tileSize + grid.tileSize / 2
                        if not grid:isCircleBlocked(tx, ty, entity.radius) then
                            local distSq = (tx - cx) * (tx - cx) + (ty - cy) * (ty - cy)
                            if not bestDistSq or distSq < bestDistSq then
                                bestDistSq = distSq
                                bestX, bestY = tx, ty
                            end
                        end
                    end
                end
            end
        end
        if bestX then break end
    end

    return bestX, bestY
end

return Movement
