-- Map builder: rendering. Attaches methods to the MapBuilder factory.

local Config = require "core.config"
local Textures = require "core.textures"

local BLOCK_SIZE = Config.MAPBUILDER_BLOCK_SIZE

return function(MapBuilder)
    function MapBuilder:draw()
        local camera = self.state.camera
        love.graphics.push()
        love.graphics.scale(camera.zoom)
        self:drawBackground()
        self:drawGridLines(self.state.grid.tileSize)
        self:drawHoverIndicator(self.state.grid.tileSize)
        love.graphics.pop()
        if self.state.itemBrowser.isOpen then
            self.state.itemBrowser:draw()
        end
        self.state.mapBuilderHUD:draw()
        self:drawDragGhost()
    end

    function MapBuilder:drawBackground()
        love.graphics.setColor(0.45, 0.45, 0.45)
        love.graphics.rectangle("fill", 0, 0, self.state.mapWidth, self.state.mapHeight)
        self.state.grid:draw()
        self.state.grid:drawBushesAboveEntities()
    end

    function MapBuilder:drawGridLines(tileSize)
        local blockPx = BLOCK_SIZE * tileSize
        love.graphics.setColor(0.2, 0.2, 0.2)
        local mapWidth, mapHeight = self.state.mapWidth, self.state.mapHeight
        for x = 0, mapWidth, blockPx do
            love.graphics.line(x, 0, x, mapHeight)
        end
        for y = 0, mapHeight, blockPx do
            love.graphics.line(0, y, mapWidth, y)
        end
    end

    function MapBuilder:drawHoverIndicator(tileSize)
        local mx, my = love.mouse.getPosition()
        local col, row = self:screenToGrid(mx, my)
        if not self:isValidTile(col, row) then return end

        if self.state.itemBrowser.isOpen or self.state.mapBuilderHUD:isPointerOverHUD(mx + self.state.camera.x, my + self.state.camera.y) then return end

        if not self:isSelectedItemObject() then
            col, row = self:snapToBlockGrid(col, row)
        end

        love.graphics.setColor(0.3, 0.5, 1.0, 0.1)
        love.graphics.rectangle("fill", (col - 1) * tileSize, (row - 1) * tileSize, BLOCK_SIZE * tileSize, BLOCK_SIZE * tileSize)
        love.graphics.setColor(0.3, 0.5, 1.0, 0.5)
        love.graphics.rectangle("line", (col - 1) * tileSize, (row - 1) * tileSize, BLOCK_SIZE * tileSize, BLOCK_SIZE * tileSize)
    end

    function MapBuilder:drawDragGhost()
        if not self.dragSlot then return end
        local mx, my = love.mouse.getPosition()
        local camera = self.state.camera
        local item = self.quickAccess[self.dragSlot]
        if not item then return end
        Textures.draw(item.material, mx + camera.x - 20, my + camera.y - 20, 40, 40, 0.8)
    end
end