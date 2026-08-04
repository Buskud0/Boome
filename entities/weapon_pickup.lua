WeaponPickup = Object:extend()

function WeaponPickup:new(x, y, weapon, delay)
    self.x = x
    self.y = y
    self.width = 24
    self.height = 24
    self.radius = 12
    self.weapon = weapon
    self.pickupDelay = delay or WEAPON_PICKUP_DELAY
end

function WeaponPickup:draw()
    local padding = 3
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
    if not Collisions.check(player, self) then return false end
    return Inventory.findFirstEmptySlot() ~= nil
end

function WeaponPickup:_collect()
    local slot = Inventory.findFirstEmptySlot()
    if not slot then return end
    Inventory.setSlot(slot, self.weapon)
    table.insert(damageTexts, DamageText(self.weapon.model, self.x, self.y, 1.5, {0.9, 0.9, 0.9}))
    self:_removeFromWorld()
end

function WeaponPickup:_removeFromWorld()
    for i, pickup in ipairs(weaponPickups) do
        if pickup == self then
            table.remove(weaponPickups, i)
            break
        end
    end
end