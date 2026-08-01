local Fonts = {}

local FONT_PATH = "fonts/Gamer.ttf"
local cache = {}

function Fonts.get(size)
    if not cache[size] then
        cache[size] = love.graphics.newFont(FONT_PATH, size)
    end
    return cache[size]
end

return Fonts
