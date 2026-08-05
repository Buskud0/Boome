-- Grid vision queries: per-tile occlusion, shadow-caster corners and
-- segment raycasting. Attaches methods to the Grid class.

local Config = require "core.config"

return function(Grid)
    local BLOCK_SIZE = Config.GRID_BLOCK_SIZE

    function Grid:isTileVisionBlocked(col, row)
        if col < 1 or col > self.cols or row < 1 or row > self.rows then return false end
        local material = self.objects[self:_index(col, row)] or self.grid[self:_index(col, row)]
        if material then
            local item = Config.BUILDING_ITEMS[material]
            if item and item.blocksVision then return true end
        end
        return false
    end

    function Grid:getVisionCornerAngles(px, py, minAngle, maxAngle)
        local angles = {}
        local ts = self.tileSize
        local size = BLOCK_SIZE * ts
        for _, record in ipairs(self.blockRecords) do
            local item = Config.BUILDING_ITEMS[record.material]
            if item and item.blocksVision then
                local x1 = (record.col - 1) * ts
                local y1 = (record.row - 1) * ts
                local x2 = x1 + size
                local y2 = y1 + size
                local corners = { {x1, y1}, {x2, y1}, {x1, y2}, {x2, y2} }
                for i = 1, 4 do
                    local a = math.atan2(corners[i][2] - py, corners[i][1] - px)
                    if a >= minAngle and a <= maxAngle then
                        angles[#angles + 1] = a
                    end
                end
            end
        end
        return angles
    end

    function Grid:segmentBlocksVision(x1, y1, x2, y2)
        local ts = self.tileSize
        local col = math.floor(x1 / ts) + 1
        local row = math.floor(y1 / ts) + 1
        local endCol = math.floor(x2 / ts) + 1
        local endRow = math.floor(y2 / ts) + 1

        local dx = x2 - x1
        local dy = y2 - y1

        local stepX = 0
        if col < endCol then stepX = 1 elseif col > endCol then stepX = -1 end
        local stepY = 0
        if row < endRow then stepY = 1 elseif row > endRow then stepY = -1 end

        local tDeltaX = stepX ~= 0 and (ts / math.abs(dx)) or math.huge
        local tDeltaY = stepY ~= 0 and (ts / math.abs(dy)) or math.huge

        local tMaxX, tMaxY = math.huge, math.huge
        if stepX == 1 then
            tMaxX = (col * ts - x1) / math.abs(dx)
        elseif stepX == -1 then
            tMaxX = (x1 - (col - 1) * ts) / math.abs(dx)
        end
        if stepY == 1 then
            tMaxY = (row * ts - y1) / math.abs(dy)
        elseif stepY == -1 then
            tMaxY = (y1 - (row - 1) * ts) / math.abs(dy)
        end

        while true do
            if self:isTileVisionBlocked(col, row) then return true end
            if col == endCol and row == endRow then return false end
            if tMaxX < tMaxY then
                tMaxX = tMaxX + tDeltaX
                col = col + stepX
            else
                tMaxY = tMaxY + tDeltaY
                row = row + stepY
            end
        end
    end
end
