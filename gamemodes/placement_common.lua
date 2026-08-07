-- Shared placement helpers for gamemodes (map builder + horde). Attaches to a
-- gamemode factory. Factories must expose `self.state.grid` (and `self.state`
-- for toasts); the mouse->grid conversion is left to each gamemode.

local Config = require "core.config"

local BLOCK_SIZE = Config.MAPBUILDER_BLOCK_SIZE

return function(Mode)
    function Mode:isObjectMaterial(material)
        return Config.OBJECT_ITEMS[material] ~= nil
    end

    function Mode:snapToGrid(col, row)
        local snappedCol = math.floor((col - 1) / BLOCK_SIZE) * BLOCK_SIZE + 1
        local snappedRow = math.floor((row - 1) / BLOCK_SIZE) * BLOCK_SIZE + 1
        return snappedCol, snappedRow
    end

    function Mode:canPlaceAt(col, row, material)
        local grid = self.state.grid
        if col < 1 or col + BLOCK_SIZE - 1 > grid.cols
        or row < 1 or row + BLOCK_SIZE - 1 > grid.rows then return false end
        if self:isObjectMaterial(material) then
            return grid:isAreaFreeOfObjects(col, row, BLOCK_SIZE)
        end
        return grid:isAreaFreeOfBlocks(col, row, BLOCK_SIZE)
    end

    function Mode:placeAt(col, row, material)
        local grid = self.state.grid
        if self:isObjectMaterial(material) then
            grid:placeObject(col, row, material)
        else
            grid:placeBlock(col, row, material)
        end
    end

    function Mode:drawPlacementOutline(col, row, tileSize, isValid)
        if isValid then
            love.graphics.setColor(0.3, 0.5, 1.0, 0.15)
        else
            love.graphics.setColor(1.0, 0.3, 0.3, 0.15)
        end
        love.graphics.rectangle("fill", (col - 1) * tileSize, (row - 1) * tileSize, BLOCK_SIZE * tileSize, BLOCK_SIZE * tileSize)
        if isValid then
            love.graphics.setColor(0.3, 0.5, 1.0, 0.6)
        else
            love.graphics.setColor(1.0, 0.3, 0.3, 0.6)
        end
        love.graphics.rectangle("line", (col - 1) * tileSize, (row - 1) * tileSize, BLOCK_SIZE * tileSize, BLOCK_SIZE * tileSize)
    end
end
