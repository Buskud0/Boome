local Fonts = {}

local FONT_PATH = require("core.config").FONTS_PATH
local cache = {}

function Fonts.get(size)
    if not cache[size] then
        cache[size] = love.graphics.newFont(FONT_PATH, size)
    end
    return cache[size]
end

return Fonts
