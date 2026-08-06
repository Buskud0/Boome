-- Player vision and local lighting (FOV cone, peripheral glow).
-- Attaches methods to the Player class.

local Config = require "core.config"
local Coordinates = require "core.coordinates"

return function(Player)
    local FOV = Config.PLAYER_FOV
    local LIGHT_CORNER_EPS = Config.PLAYER_LIGHT_CORNER_EPS
    local LIGHT_DARKNESS = Config.PLAYER_LIGHT_DARKNESS
    local LIGHT_GRID_TIE_BREAK = Config.PLAYER_LIGHT_GRID_TIE_BREAK
    local LIGHT_SEGMENTS = Config.PLAYER_LIGHT_SEGMENTS
    local MIN_SCOPED_FOV = Config.PLAYER_MIN_SCOPED_FOV
    local PERIPHERAL_ALPHA = Config.PLAYER_PERIPHERAL_ALPHA
    local PERIPHERAL_RADIUS = Config.PLAYER_PERIPHERAL_RADIUS
    local SCOPED_FOV_BASE = Config.PLAYER_SCOPED_FOV_BASE
    local SCOPED_FOV_PER_SCOPE = Config.PLAYER_SCOPED_FOV_PER_SCOPE

    function Player:getFov()
        local scoped = self:_getScopedFov()
        local progress = self.state.weapon and self.state.weapon.scopeProgress or 0
        return FOV + (scoped - FOV) * progress
    end

    function Player:_getScopedFov()
        local scope = self.state.weapon and self.state.weapon.scope or 50
        local fov = SCOPED_FOV_BASE - SCOPED_FOV_PER_SCOPE * scope
        return math.max(math.rad(fov), MIN_SCOPED_FOV)
    end

    function Player:drawLocalLighting()
        love.graphics.push()
        love.graphics.origin()

        love.graphics.stencil(function()
            love.graphics.setColor(1, 1, 1)
            love.graphics.polygon("fill", self:_getLightConeVertices())
        end, "replace", 1)

        love.graphics.setStencilTest("less", 1)
        love.graphics.setColor(0, 0, 0, LIGHT_DARKNESS)
        love.graphics.rectangle("fill", 0, 0, self.state.scrWidth, self.state.scrHeight)
        love.graphics.setStencilTest()

        love.graphics.pop()
    end

    function Player:_getLightConeVertices()
        local px, py = self:getCenter()
        local aimAngle = self:_getAimAngle(px, py)
        local rayAngles = self:_getRayAngles(px, py, aimAngle)
        return self:_castVisionRays(px, py, rayAngles, self:_getVisionRadius())
    end

    function Player:cacheAim()
        local px, py = self:getCenter()
        self.aimAngle = self:_computeAimAngle(px, py)
    end

    function Player:_getAimAngle(px, py)
        if self.state.paused and self.aimAngle then return self.aimAngle end
        return self:_computeAimAngle(px, py)
    end

    function Player:_computeAimAngle(px, py)
        local dx, dy = Coordinates.aimDirection(self.state, px, py)
        if dx == 0 and dy == 0 then return -math.pi / 2 end
        local step = self:getFov() / LIGHT_SEGMENTS
        return math.floor(math.atan2(dy, dx) / step + 0.5) * step
    end

    function Player:_getVisionRadius()
        return math.sqrt(self.state.mapWidth * self.state.mapWidth + self.state.mapHeight * self.state.mapHeight)
    end

    function Player:_getRayAngles(px, py, aimAngle)
        local fov = self:getFov()
        local half = fov / 2
        local step = fov / LIGHT_SEGMENTS
        local minAngle = aimAngle - half
        local maxAngle = aimAngle + half

        local rayAngles = {}
        for i = 0, LIGHT_SEGMENTS do
            rayAngles[#rayAngles + 1] = minAngle + step * i
        end

        local grid = self.state.grid
        local corners = grid:getVisionCornerAngles(px, py, minAngle - LIGHT_CORNER_EPS, maxAngle + LIGHT_CORNER_EPS)
        for i = 1, #corners do
            rayAngles[#rayAngles + 1] = corners[i] - LIGHT_CORNER_EPS
            rayAngles[#rayAngles + 1] = corners[i] + LIGHT_CORNER_EPS
        end

        table.sort(rayAngles)
        return rayAngles
    end

    function Player:_castVisionRays(px, py, rayAngles, radius)
        local vertices = {}
        local sx, sy = Coordinates.worldToScreen(self.state, px, py)
        vertices[#vertices + 1] = sx
        vertices[#vertices + 1] = sy
        for i = 1, #rayAngles do
            local hx, hy = self:_castVisionRay(px, py, rayAngles[i], radius)
            local vx, vy = Coordinates.worldToScreen(self.state, hx, hy)
            vertices[#vertices + 1] = vx
            vertices[#vertices + 1] = vy
        end
        return vertices
    end

    function Player:_castVisionRay(x, y, angle, maxDist)
        local grid = self.state.grid
        local ts = grid.tileSize
        local dx = math.cos(angle)
        local dy = math.sin(angle)
        local maxX = x + dx * maxDist
        local maxY = y + dy * maxDist

        local col = math.floor(x / ts) + 1
        local row = math.floor(y / ts) + 1
        local endCol = math.floor(maxX / ts) + 1
        local endRow = math.floor(maxY / ts) + 1

        local stepX = 0
        if dx > 0 then stepX = 1 elseif dx < 0 then stepX = -1 end
        local stepY = 0
        if dy > 0 then stepY = 1 elseif dy < 0 then stepY = -1 end

        local tDeltaX = stepX ~= 0 and (ts / math.abs(dx)) or math.huge
        local tDeltaY = stepY ~= 0 and (ts / math.abs(dy)) or math.huge

        local tMaxX, tMaxY = math.huge, math.huge
        if stepX == 1 then
            tMaxX = (col * ts - x) / math.abs(dx)
        elseif stepX == -1 then
            tMaxX = (x - (col - 1) * ts) / math.abs(dx)
        end
        if stepY == 1 then
            tMaxY = (row * ts - y) / math.abs(dy)
        elseif stepY == -1 then
            tMaxY = (y - (row - 1) * ts) / math.abs(dy)
        end

        while true do
            if col == endCol and row == endRow then return maxX, maxY end
            local tHit
            if tMaxX < tMaxY - LIGHT_GRID_TIE_BREAK then
                tHit = tMaxX
                tMaxX = tMaxX + tDeltaX
                col = col + stepX
            else
                tHit = tMaxY
                tMaxY = tMaxY + tDeltaY
                row = row + stepY
            end
            if grid:isTileVisionBlocked(col, row) then
                return x + dx * tHit, y + dy * tHit
            end
        end
    end

    function Player:isInVisionCone(wx, wy)
        local px, py = self:getCenter()
        local dx, dy = wx - px, wy - py
        local dist = math.sqrt(dx * dx + dy * dy)
        if dist == 0 then return true end

        local aimAngle = self:_getAimAngle(px, py)
        local dot = dx * math.cos(aimAngle) + dy * math.sin(aimAngle)
        return dot >= dist * math.cos(self:getFov() / 2)
    end

    function Player:getVisibilityAlphaFor(wx, wy)
        if self:isInVisionCone(wx, wy) then return 1 end
        local px, py = self:getCenter()
        local dx, dy = wx - px, wy - py
        local distSq = dx * dx + dy * dy
        if distSq <= PERIPHERAL_RADIUS * PERIPHERAL_RADIUS then return PERIPHERAL_ALPHA end
        return 0
    end
end
