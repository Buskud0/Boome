-- Thrown grenade projectile: travels straight, slows down, bounces off walls
-- and the map edge, and detonates when its fuse runs out.

local Object = require "lib.classic"
local Config = require "core.config"
local Textures = require "core.textures"
local Explosion = require "world.physics.explosion"

local THROW_SPEED = Config.GRENADE_THROW_SPEED
local DRAG = Config.GRENADE_DRAG
local SPIN = Config.GRENADE_SPIN
local FUSE = Config.GRENADE_FUSE
local EXPLOSION = Config.GRENADE_EXPLOSION
local SPRITE = "slot_GRENADE"

local Grenade = Object:extend()

function Grenade:new(state, x, y, dirX, dirY, speed)
    self.state = state
    self.width = 20
    self.height = 20
    self.x = x - self.width / 2
    self.y = y - self.height / 2
    self.radius = 10
    self.vx = dirX * (speed or THROW_SPEED)
    self.vy = dirY * (speed or THROW_SPEED)
    self.rot = 0
    self.fuse = FUSE
    self.destruct = false
end

function Grenade:getCenter()
    return self.x + self.width / 2, self.y + self.height / 2
end

function Grenade:update(dt)
    self.fuse = self.fuse - dt
    if self.fuse <= 0 then
        self:explode()
        return
    end
    local drag = math.max(0, 1 - DRAG * dt)
    self.vx = self.vx * drag
    self.vy = self.vy * drag
    self.rot = self.rot + SPIN * dt
    self:_move(dt)
end

function Grenade:explode()
    local cx, cy = self:getCenter()
    Explosion.detonate(self.state, cx, cy, EXPLOSION.radius, EXPLOSION.maxDamage, EXPLOSION.minDamage)
    self.destruct = true
end

function Grenade:_move(dt)
    local nx = self.x + self.vx * dt
    local ny = self.y + self.vy * dt

    if self:_canMoveTo(nx, ny) then
        self.x, self.y = nx, ny
        return
    end

    if self:_canMoveTo(nx, self.y) then
        self.x = nx
    else
        self.vx = -self.vx
    end

    if self:_canMoveTo(self.x, ny) then
        self.y = ny
    else
        self.vy = -self.vy
    end
end

function Grenade:_canMoveTo(x, y)
    if x < 0 or x > self.state.mapWidth - self.width then return false end
    if y < 0 or y > self.state.mapHeight - self.height then return false end
    local cx = x + self.width / 2
    local cy = y + self.height / 2
    return not self.state.grid:isCircleBlocked(cx, cy, self.radius, true)
end

function Grenade:draw()
    Textures.draw(SPRITE, self.x, self.y, self.width, self.height, 1, 1, self.rot)
end

return Grenade
