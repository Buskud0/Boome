Grid = Object:extend()

function Grid:new()
    self.grid = {}
    self.tileSize = 40
    self.cols = mapHeight / self.tileSize
    self.rows = mapWidth / self.tileSize

    self:colorTile("wall", 10, 10)
    self:colorTile("wall", 10, 11)
    self:colorTile("wall", 10, 12)
    self:colorTile("wall", 10, 13)
    self:colorTile("wall", 10, 14)
end

function Grid:draw()
    for y = 1, self.cols do
        for x = 1, self.rows do
            local i = self:index(x, y, self.cols)
            local material = "empty"
            if self.grid[i] == "wall" then material = "wall" end
            Textures.draw(material, (x-1)*self.tileSize, (y-1)*self.tileSize)
        end
    end
end

function Grid:index(x, y, width)
    return (y - 1) * width + x
end

function Grid:colorTile(material, x, y)
    self.grid[(y-1) * self.cols + x] = material
end

function Grid:isBlocked(px, py, w, h)
    local corners = {
        {px, py},
        {px + w - 1, py},
        {px, py + h - 1},
        {px + w - 1, py + h - 1},
    }
    for _, corner in ipairs(corners) do
        local col = math.floor(corner[1] / self.tileSize) + 1
        local row = math.floor(corner[2] / self.tileSize) + 1
        if col >= 1 and col <= self.cols and row >= 1 and row <= self.rows then
            if self.grid[(row-1) * self.cols + col] == "wall" then
                return true
            end
        end
    end
    return false
end