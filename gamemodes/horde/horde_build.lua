-- Horde building: placing blocks/objects from the inventory like the map
-- builder. Attaches methods to the Horde factory.

local Config = require "core.config"
local Coordinates = require "core.coordinates"

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
        if not self:isObjectMaterial(material) then
            col, row = self:snapToGrid(col, row)
        end
        return { material = material, col = col, row = row }
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
        if not self:canPlaceAt(target.col, target.row, target.material) then return end
        self:placeBuild(target)
        self.lastPlacedCol, self.lastPlacedRow = target.col, target.row
        self.buildCooldown = PLACE_INTERVAL
    end

    function Horde:placeBuild(target)
        self:placeAt(target.col, target.row, target.material)
        local index = self.state.currentWeaponIndex
        if index then
            self.state.inventory:decrementItemSlot(index, 1)
        end
    end

    function Horde:drawBuildOutline()
        local target = self:buildTarget()
        if not target then return end
        local valid = self:canPlaceAt(target.col, target.row, target.material)
        local tileSize = self.state.grid.tileSize
        self:drawPlacementOutline(target.col, target.row, tileSize, valid)
    end
end