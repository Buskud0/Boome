local Object = require "lib.classic"
local Textures = require "core.textures"

local Bullet = Object:extend()

function Bullet:new(x, y, dx, dy, damage)
	self.x = x
	self.y = y
	self.width = 8
	self.height = 8
	self.radius = 4
	self.dx = dx
	self.dy = dy
	self.damage = damage
	self.hitZombies = {}
	self.penetratedTiles = {}
	self.sprite = "bullet"
end

function Bullet:applyHit(targetHealthBefore)
    self.damage = self.damage - targetHealthBefore
    return self.damage > 0
end

function Bullet:draw()
    Textures.draw(self.sprite, self.x, self.y, self.width, self.height)
end

function Bullet:update(dt)
	self.x = self.x + (self.dx * dt)
    self.y = self.y + (self.dy * dt)
end

return Bullet
