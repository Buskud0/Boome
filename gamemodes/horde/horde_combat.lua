-- Horde combat: kills, rewards, pickups, weapon handling and updating
-- game-world lists. Attaches methods to the Horde factory.

local PowerUp = require "entities.powerup"
local Input = require "core.input"

return function(Horde)
    function Horde:onZombieKilled(zombie, index)
        self:removeZombie(zombie, index)
        self.state.killCount = self.state.killCount + 1
        self:rewardKill(zombie)
        self:maybeDropPowerUp(zombie)
    end

    function Horde:removeZombie(zombie, index)
        table.remove(self.state.zombies, index)
    end

    function Horde:rewardKill(zombie)
        if zombie.type == "light" then self.state.player.money = self.state.player.money + 5 end
        if zombie.type == "normal" then self.state.player.money = self.state.player.money + 10 end
        if zombie.type == "heavy" then self.state.player.money = self.state.player.money + 15 end
    end

    function Horde:maybeDropPowerUp(zombie)
        local powerUpChance = math.random(1, 10)
        if powerUpChance == 1 then table.insert(self.state.powerUps, PowerUp(self.state, zombie.x, zombie.y, "money")) end
        if powerUpChance == 2 then table.insert(self.state.powerUps, PowerUp(self.state, zombie.x, zombie.y, "health")) end
    end

    function Horde:updateDamageTexts(dt)
        for i = #self.state.damageTexts, 1, -1 do
            self.state.damageTexts[i]:update(dt)
            if self.state.damageTexts[i].destruct then table.remove(self.state.damageTexts, i) end
        end
    end

    function Horde:setActiveWeapon()
        local newWeapon = self.state.fists
        local index = self.state.currentWeaponIndex
        if index and index <= self.state.inventory.HOTBAR_SLOTS and self.state.weapons[index] then
            newWeapon = self.state.weapons[index]
        end
        if newWeapon ~= self.state.weapon then
            self:resetScope(newWeapon)
        end
        self.state.weapon = newWeapon
    end

    function Horde:resetScope(newWeapon)
        for _, w in ipairs({ self.state.weapon, newWeapon }) do
            if w and w.scopeProgress ~= nil then
                w.scopeProgress = 0
                w.scopeOffsetX = 0
                w.scopeOffsetY = 0
            end
        end
    end

    function Horde:updateActiveWeapon(dt)
        if not self.state.buyMenu.isOpen and self.state.weapon then
            self.state.weapon:update(dt)
        end
    end

    function Horde:updateBullets(dt)
        for _, bullet in ipairs(self.state.bullets) do
            bullet:update(dt)
        end
    end

    function Horde:updateZombies(dt)
        for i, zombie in ipairs(self.state.zombies) do
            zombie:update(dt)
            if zombie.health <= 0 then self:onZombieKilled(zombie, i) end
        end
    end

    function Horde:updatePowerUps(dt)
        for _, powerUp in ipairs(self.state.powerUps) do
            powerUp:update(dt)
        end
    end

    function Horde:updateWeaponPickups(dt)
        for _, pickup in ipairs(self.state.weaponPickups) do
            pickup:update(dt)
        end
    end

    function Horde:updateExplosions(dt)
        for i = #self.state.explosions, 1, -1 do
            self.state.explosions[i]:update(dt)
            if self.state.explosions[i].destruct then table.remove(self.state.explosions, i) end
        end
    end

    function Horde:cycleWeapon(direction)
        local start = self.state.currentWeaponIndex or (direction > 0 and 0 or 6)
        local target = self:findNextWeaponSlot(start, direction)
        if target then
            self.state.currentWeaponIndex = target
        end
    end

    function Horde:findNextWeaponSlot(startIndex, direction)
        local target = startIndex + direction
        while target >= 1 and target <= 5 do
            if self.state.weapons[target] then return target end
            target = target + direction
        end
        return nil
    end

    function Horde:handleKey(key, action)
        if self:handleWeaponSlotKey(key) then return end
        if action == "reload" then
            self:handleReload()
        elseif action == "inventory" then
            self.state.inventory:toggle()
        elseif action == "drop" then
            self.state.inventory:dropHeldWeapon()
        elseif action == "cycle_prev" then
            self:cycleWeapon(-1)
        elseif action == "cycle_next" then
            self:cycleWeapon(1)
        end
    end

    function Horde:handleReload()
        local weapon = self.state.weapon
        if weapon and weapon.magSize and weapon.capacity < weapon.magSize then
            weapon.capacity = 0
        end
    end

    function Horde:handleWeaponSlotKey(key)
        for slot = 1, 5 do
            if Input.isActionBoundToKey("weapon" .. slot, key) then
                if self.state.currentWeaponIndex == slot then
                    self.state.currentWeaponIndex = nil
                elseif self.state.weapons[slot] then
                    self.state.currentWeaponIndex = slot
                else
                    self.state.currentWeaponIndex = nil
                end
                return true
            end
        end
        return false
    end
end