local Textures = {}

local materialRegistry = {}
local currentSheet = nil

function Textures.load(filename, tileSize)
    local image = love.graphics.newImage(filename)
    currentSheet = {
        image = image,
        tileSize = tileSize,
        quads = Textures.buildQuads(image, tileSize),
    }
end

function Textures.buildQuads(image, tileSize)
    local sheetWidth, sheetHeight = image:getWidth(), image:getHeight()
    local cols, rows = sheetWidth / tileSize, sheetHeight / tileSize

    local quads = {}
    local i = 1
    for y = 0, rows - 1 do
        for x = 0, cols - 1 do
            quads[i] = love.graphics.newQuad(
                x * tileSize, y * tileSize,
                tileSize, tileSize,
                sheetWidth, sheetHeight
            )
            i = i + 1
        end
    end
    return quads
end

function Textures.define(material, tileIndex)
    if currentSheet and currentSheet.quads[tileIndex] then
        materialRegistry[material] = {
            image = currentSheet.image,
            quad = currentSheet.quads[tileIndex],
            tileSize = currentSheet.tileSize
        }
    end
end

function Textures.draw(material, x, y, w, h, alpha, brightness, rot)
    local entry = materialRegistry[material]
    if not entry then return end
    local b = brightness or 1
    local drawW = w or entry.tileSize
    local drawH = h or entry.tileSize
    love.graphics.setColor(b, b, b, alpha or 1)
    local sx = drawW / entry.tileSize
    local sy = drawH / entry.tileSize
    if rot and rot ~= 0 then
        love.graphics.draw(entry.image, entry.quad, x + drawW / 2, y + drawH / 2, rot, sx, sy, entry.tileSize / 2, entry.tileSize / 2)
    else
        love.graphics.draw(entry.image, entry.quad, x, y, 0, sx, sy)
    end
end

return Textures
