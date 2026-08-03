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

function Textures.draw(material, x, y, w, h, alpha, brightness)
    local entry = materialRegistry[material]
    if not entry then return end
    local b = brightness or 1
    love.graphics.setColor(b, b, b, alpha or 1)
    local sx = (w or entry.tileSize) / entry.tileSize
    local sy = (h or entry.tileSize) / entry.tileSize
    love.graphics.draw(entry.image, entry.quad, x, y, 0, sx, sy)
end

return Textures
