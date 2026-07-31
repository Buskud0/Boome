local Debug = {}

Debug.enabled = false

local function applyZoomTransform()
    love.graphics.translate(scrWidth / 2, scrHeight / 2)
    love.graphics.scale(camera.zoom)
    love.graphics.translate(-scrWidth / 2, -scrHeight / 2)
end

function Debug.toggle()
    Debug.enabled = not Debug.enabled
end

function Debug.isEnabled()
    return Debug.enabled
end

function Debug.handleKey(key)
    if Input.isActionBoundToKey("debug_toggle", key) then
        Debug.toggle()
        return true
    end
    return false
end

function Debug.drawGridOverlay()
    if not Debug.enabled then return end
    love.graphics.push()
    applyZoomTransform()
    grid:debugDraw()
    love.graphics.pop()
end

return Debug
