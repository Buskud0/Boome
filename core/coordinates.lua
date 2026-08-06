-- Screen <-> world coordinate conversions.
-- The view is derived from the runtime state (camera + screen size).

local Coordinates = {}

function Coordinates.screenToWorld(state, sx, sy)
    local cx, cy = state.scrWidth / 2, state.scrHeight / 2
    return (sx + state.camera.x - cx) / state.camera.zoom + cx,
           (sy + state.camera.y - cy) / state.camera.zoom + cy
end

function Coordinates.worldToScreen(state, wx, wy)
    local cx, cy = state.scrWidth / 2, state.scrHeight / 2
    return (wx - cx) * state.camera.zoom - state.camera.x + cx,
           (wy - cy) * state.camera.zoom - state.camera.y + cy
end

-- Normalized direction from (fromX, fromY) toward the mouse cursor.
-- Returns 0, 0 when the cursor is exactly on the origin.
function Coordinates.aimDirection(state, fromX, fromY)
    local mx, my = Coordinates.screenToWorld(state, love.mouse.getPosition())
    local dx, dy = mx - fromX, my - fromY
    local length = math.sqrt(dx * dx + dy * dy)
    if length == 0 then return 0, 0 end
    return dx / length, dy / length
end

return Coordinates
