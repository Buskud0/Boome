-- Horde building: placing blocks/objects from the inventory like the map
-- builder. Attaches methods to the Horde factory.

local Config = require "core.config"
local Coordinates = require "core.coordinates"

local BLOCK_SIZE = Config.MAPBUILDER_BLOCK_SIZE
local PLACE_INTERVAL = Config.PLAYER_PLACE_INTERVAL

return function(Horde)
    function Horde:buildMaterial()
        local weapon = self.state.weapon
        if not weapon or not weapon.isItem then return nil end
        local item = Config.ITEMS[weapon.model]
        if not item or not item.placeable then return nil end
        return item.placeable
    end

    function Horde:buildTarget()
        local material = self:buildMaterial()
        if not material then return nil end
        local wx, wy = Coordinates.screenToWorld(self.state, love.mouse.getPosition())
        local col, row = self.state.grid:tileAt(wx, wy)
        if not col then return nil end
        local isObject = Config.OBJECT_ITEMS[material] ~= nil
        if not isObject then
            col, row = self:snapToBlockGrid(col, row)
        end
        return { material = material, col = col, row = row, isObject = isObject }
    end

    function Horde:snapToBlockGrid(col, row)
        local snappedCol = math.floor((col - 1) / BLOCK_SIZE) * BLOCK_SIZE + 1
        local snappedRow = math.floor((row - 1) / BLOCK_SIZE) * BLOCK_SIZE + 1
        return snappedCol, snappedRow
    end

    function Horde:isBuildValid(target)
        local grid = self.state.grid
        if target.col < 1 or target.col + BLOCK_SIZE - 1 > grid.cols
        or target.row < 1 or target.row + BLOCK_SIZE - 1 > grid.rows then return false end
        if target.isObject then
            return grid:isAreaFreeOfObjects(target.col, target.row, BLOCK_SIZE)
        end
        return grid:isAreaFreeOfBlocks(target.col, target.row, BLOCK_SIZE)
    end

    function Horde:updateBuild(dt)
        if self.state.menu and self.state.menu:isOpen() then return end
        if self.state.inventory.isOpen or self.state.buyMenu.isOpen or self.state.craftMenu.isOpen then return end
        if self.state.ignoreMouseUntilRelease then return end
        local target = self:buildTarget()
        if not target then return end
        if self.buildCooldown then self.buildCooldown = self.buildCooldown - dt end
        if self.buildCooldown and self.buildCooldown > 0 then return end
        if not love.mouse.isDown(1) then
            self.lastPlacedCol, self.lastPlacedRow = nil, nil
            return
        end
        if target.col == self.lastPlacedCol and target.row == self.lastPlacedRow then return end
        if not self:isBuildValid(target) then return end
        self:placeBuild(target)
        self.lastPlacedCol, self.lastPlacedRow = target.col, target.row
        self.buildCooldown = PLACE_INTERVAL
    end

    function Horde:placeBuild(target)
        local grid = self.state.grid
        if target.isObject then
            grid:placeObject(target.col, target.row, target.material)
        else
            grid:placeBlock(target.col, target.row, target.material)
        end
        local index = self.state.currentWeaponIndex
        if index then
            self.state.inventory:decrementItemSlot(index, 1)
        end
    end

    function Horde:drawBuildOutline()
        local target = self:buildTarget()
        if not target then return end
        local valid = self:isBuildValid(target)
        local tileSize = self.state.grid.tileSize
        local x = (target.col - 1) * tileSize
        local y = (target.row - 1) * tileSize
        local size = BLOCK_SIZE * tileSize
        if valid then
            love.graphics.setColor(0.3, 0.5, 1.0, 0.15)
        else
            love.graphics.setColor(1.0, 0.3, 0.3, 0.15)
        end
        love.graphics.rectangle("fill", x, y, size, size)
        if valid then
            love.graphics.setColor(0.3, 0.5, 1.0, 0.6)
        else
            love.graphics.setColor(1.0, 0.3, 0.3, 0.6)
        end
        love.graphics.rectangle("line", x, y, size, size)
    end
end
