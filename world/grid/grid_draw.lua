-- Grid drawing. Attaches methods to the Grid class.

local Config = require "core.config"
local Textures = require "core.textures"

local BLOCK_SIZE = Config.GRID_BLOCK_SIZE

return function(Grid)
    function Grid:_drawRecord(record)
        Textures.draw(record.material, (record.col - 1) * self.tileSize, (record.row - 1) * self.tileSize, 40, 40, 1, self:_healthBrightness(record))
    end

    -- Empty tiles are grass. This is drawn first so it sits behind every real
    -- block, and grass is never stored as a record in map files.
    function Grid:drawGrassBase()
        for row = 1, self.rows, BLOCK_SIZE do
            for col = 1, self.cols, BLOCK_SIZE do
                if not self.grid[self:_index(col, row)] then
                    Textures.draw("grass", (col - 1) * self.tileSize, (row - 1) * self.tileSize, 40, 40, 1, 1)
                end
            end
        end
    end

    function Grid:drawBlocks()
        for _, record in ipairs(self.blockRecords) do
            self:_drawRecord(record)
        end
    end

    function Grid:drawObjects()
        for _, record in ipairs(self.objectRecords) do
            if record.material ~= "bush" then
                self:_drawRecord(record)
            end
        end
    end

    function Grid:drawBushesAboveEntities()
        for _, record in ipairs(self.objectRecords) do
            if record.material == "bush" then
                self:_drawRecord(record)
            end
        end
    end

    function Grid:draw()
        self:drawGrassBase()
        self:drawBlocks()
        self:drawObjects()
    end

    function Grid:debugDraw()
        local ts = self.tileSize
        love.graphics.setColor(1, 0, 0, 0.3)
        for row = 1, self.rows do
            for col = 1, self.cols do
                if self:isTileBlocked(col, row) then
                    love.graphics.rectangle("fill", (col - 1) * ts, (row - 1) * ts, ts, ts)
                end
            end
        end
        love.graphics.setColor(1, 1, 1, 1)
    end
end
