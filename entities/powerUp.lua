powerUp = Object:extend()

function powerUp:new(x, y, type)
	self.x = x
	self.y = y
	self.width = 20
	self.height = 20
    self.type = type
    self.isPickedUp = false
    if self.type == "health" then 
        self.color = {0.8, 0.2, 0.2} 
        self.amount = 25
    end
    if self.type == "money" then 
        self.color = {1, 0.8, 0.2} 
        self.amount = 100
    end
end

function powerUp:update(dt) 
	if(Collisions.check(player, self)) then
        if self.type == "health" and player.health < 100 then 
            player.health = math.min(player.health + 25, 100)
            self.isPickedUp = true
        end 
        if self.type == "money" then 
            player.money = player.money + 100
            self.isPickedUp = true
        end

        for i, powerUp in ipairs(powerUps) do
            if powerUp == self and powerUp.isPickedUp then 
                print("picked up " .. self.type)
                table.insert(damageTexts, DamageText("+" .. self.amount .. " " .. self.type, self.x, self.y, 1.5, self.color))
                table.remove(powerUps, i)
                break
            end
        end
    end
end

function powerUp:draw()
	love.graphics.setColor(self.color)
	love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
end