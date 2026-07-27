local Textures = {}

function Textures.load(filename, tileSize)
    local image = love.graphics.newImage(filename)
    local sheetWidth = image:getWidth()
    local sheetHeight = image:getHeight()
    local cols = sheetWidth / tileSize
    local rows = sheetHeight / tileSize

    Textures.image = image
    Textures.tileSize = tileSize
    Textures.quads = {}
    Textures.materials = {}

    local i = 1
    for y = 0, rows - 1 do
        for x = 0, cols - 1 do
            Textures.quads[i] = love.graphics.newQuad(
                x * tileSize, y * tileSize,
                tileSize, tileSize,
                sheetWidth, sheetHeight
            )
            i = i + 1
        end
    end
end

function Textures.define(material, tileIndex)
    Textures.materials[material] = tileIndex
end

function Textures.draw(material, x, y)
    local index = Textures.materials[material]
    if index then
        love.graphics.draw(Textures.image, Textures.quads[index], x, y)
    end
end

function Textures.getTileSize()
    return Textures.tileSize
end

return Textures
