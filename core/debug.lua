local Debug = {}

Debug.enabled = false

local function applyZoomTransform(state)
    local camera = state.camera
    love.graphics.translate(state.scrWidth / 2, state.scrHeight / 2)
    love.graphics.scale(camera.zoom)
    love.graphics.translate(-state.scrWidth / 2, -state.scrHeight / 2)
end

function Debug.toggle()
    Debug.enabled = not Debug.enabled
end

function Debug.isEnabled()
    return Debug.enabled
end

function Debug.handleKey(state, key)
    if require("core.input").isActionBoundToKey("debug_toggle", key) then
        Debug.toggle()
        return true
    end
    return false
end

function Debug.drawGridOverlay(state)
    if not Debug.enabled then return end
    love.graphics.push()
    applyZoomTransform(state)
    state.grid:debugDraw()
    love.graphics.pop()
end

return Debug