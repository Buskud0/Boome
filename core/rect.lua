local Rect = {}

function Rect.hit(x, y, rect)
    if not rect then return false end
    return x >= rect.x and x <= rect.x + rect.w
        and y >= rect.y and y <= rect.y + rect.h
end

return Rect
