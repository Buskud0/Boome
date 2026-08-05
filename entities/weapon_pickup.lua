local Object = require "lib.classic"
local Config = require "core.config"
local Collision = require "world.physics.collision"
local DamageText = require "entities.damage_text"
local Textures = require "core.textures"

local WeaponPickup = Object:extend()

local PICKUP_DELAY = Config.WEAPON_PICKUP_DELAY

function WeaponPickup:new(state, x, y, weapon, delay)
    self.state = state
    self.x = x
    self.y = y
    self.width = 24
    self.height = 24
    self.radius = 12
    self.weapon = weapon
    self.pickupDelay = delay or PICKUP_DELAY
end

function WeaponPickup:draw()
    Textures.draw("slot_" .. self.weapon.model, self.x - self.width / 2, self.y - self.height / 2, self.width, self.height)
end

function WeaponPickup:update(dt)
    if self.pickupDelay > 0 then
        self.pickupDelay = self.pickupDelay - dt
        return
    end
    if self:_tryCollect() then
        self:_collect()
    end
end

function WeaponPickup:_tryCollect()
    if not Collision.check(self.state.player, self) then return false end
    return self.state.inventory:findFirstEmptySlot() ~= nil
end

function WeaponPickup:_collect()
    local slot = self.state.inventory:findFirstEmptySlot()
    if not slot then return end
    self.state.inventory:setSlot(slot, self.weapon)
    table.insert(self.state.damageTexts, DamageText(self.weapon.model, self.x, self.y, 1.5, {0.9, 0.9, 0.9}))
    self:_removeFromWorld()
end

function WeaponPickup:_removeFromWorld()
    for i, pickup in ipairs(self.state.weaponPickups) do
        if pickup == self then
            table.remove(self.state.weaponPickups, i)
            break
        end
    end
end

return WeaponPickup