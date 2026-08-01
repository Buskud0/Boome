PowerUp = Object:extend()

function PowerUp:new(x, y, type)
	self.x = x
	self.y = y
	self.width = 20
	self.height = 20
    self.radius = 10
    self.type = type
    self.lifetime = 6
    self.opacity = 1
    self:_initByType()
end

function PowerUp:_initByType()
    if self.type == "health" then
        self.color = {0.8, 0.2, 0.2}
        self.amount = 25
        self.sprite = "powerup_health"
    elseif self.type == "money" then
        self.color = {1, 0.8, 0.2}
        self.amount = 100
        self.sprite = "powerup_money"
    end
end

function PowerUp:draw()
    Textures.draw(self.sprite, self.x, self.y, self.width, self.height, self.opacity)
end

function PowerUp:update(dt)
    self.lifetime = self.lifetime - dt
    if self.lifetime <= 0 then
        self:_expire()
        return
    end
    self:_updateOpacity()
    if self:_tryPickup() then
        self:_collect()
    end
end

function PowerUp:_updateOpacity()
    if self.lifetime >= 2 then return end
    self.opacity = math.max(0, self.lifetime / 2)
end

function PowerUp:_tryPickup()
    if not Collisions.check(player, self) then return false end
    if self.type == "health" and player.health < 100 then
        player.health = math.min(player.health + self.amount, 100)
        return true
    end
    if self.type == "money" then
        player.money = player.money + self.amount
        return true
    end
    return false
end

function PowerUp:_removeFromWorld()
    for i, powerUp in ipairs(powerUps) do
        if powerUp == self then
            table.remove(powerUps, i)
            break
        end
    end
end

function PowerUp:_collect()
    table.insert(damageTexts, DamageText("+" .. self.amount .. " " .. self.type, self.x, self.y, 1.5, self.color))
    self:_removeFromWorld()
end

function PowerUp:_expire()
    self:_removeFromWorld()
end