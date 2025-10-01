Grid = Object:extend()

function Grid:new()
    self.grid = {}
    self.tileSize = 40
    self.cols = mapHeight / self.tileSize
    self.rows = mapWidth / self.tileSize

    for y = 1, self.rows do
        for x = 1, self.cols do
            local index = (y-1) * self.cols + x
        end
    end

    --self:colorTile("wall", 6, 2)
end

function Grid:update(dt)
end

function Grid:draw()
    --love.graphics.setColor({0.5, 0.5, 0.5})
    for y = 1, self.cols do
        for x = 1, self.rows do
            local i = self:index(x, y, self.cols)

            if self.grid[i] == "wall" then
                love.graphics.setColor({0, 0, 0})
            else
                love.graphics.setColor({0.4, 0.4, 0.4})
            end

            love.graphics.rectangle("fill", (x-1)*self.tileSize, (y-1)*self.tileSize, self.tileSize-1, self.tileSize-1)
        end
    end
end

function Grid:index(x, y, width)
    return (y - 1) * width + x
end

function Grid:colorTile(material, x, y)
    self.grid[(y-1) * self.cols + x] = material
end