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
        if state.toast then
            if Debug.enabled then
                state.toast:show("Debug ON", 1.5)
            else
                state.toast:show("Debug OFF", 1.5)
            end
        end
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