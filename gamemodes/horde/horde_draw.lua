-- Horde rendering: world, HUD and round overlays.
-- Attaches methods to the Horde factory.

local Config = require "core.config"
local Fonts = require "core.fonts"
local Interact = require "world.physics.interact"

local ROUND_TEXT_TIME = Config.ROUND_TEXT_TIME

return function(Horde)
    function Horde:draw()
        self:applyCameraZoom()
        self:drawWorld()
        self.state.player:drawLocalLighting()
        self:drawHUD()
    end

    function Horde:drawWorld()
        self:drawMap()
        self.state.grid:drawObjects()
        self:drawPowerUps()
        self:drawWeaponPickups()
        self:drawZombies()
        self.state.player:draw()
        self.state.grid:drawBushesAboveEntities()
        self:drawBullets()
        if self.state.weapon then self.state.weapon:drawWorld() end
        self:drawZombieAttacks()
        self:drawGrenades()
        self:drawExplosions()
        self:drawDamageTexts()
        Interact.draw(self.state, self)
        love.graphics.pop()
    end

    function Horde:drawMap()
        love.graphics.setColor(0.2, 0.2, 0.2)
        love.graphics.rectangle("fill", 0, 0, self.state.mapWidth, self.state.mapHeight)
        self.state.grid:drawGrassBase()
        self.state.grid:drawBlocks()
    end

    function Horde:drawPowerUps()
        for _, powerUp in ipairs(self.state.powerUps) do
            powerUp:draw()
        end
    end

    function Horde:drawBullets()
        for _, bullet in ipairs(self.state.bullets) do
            bullet:draw()
        end
    end

    function Horde:drawZombies()
        for _, zombie in ipairs(self.state.zombies) do
            zombie:draw()
        end
    end

    function Horde:drawZombieAttacks()
        for _, zombie in ipairs(self.state.zombies) do
            zombie:drawStab()
        end
    end

    function Horde:drawDamageTexts()
        for _, damageText in ipairs(self.state.damageTexts) do
            damageText:draw()
        end
    end

    function Horde:drawGrenades()
        for _, grenade in ipairs(self.state.grenades) do
            grenade:draw()
        end
    end

    function Horde:drawExplosions()
        for _, explosion in ipairs(self.state.explosions) do
            explosion:draw()
        end
    end

    function Horde:drawWeaponPickups()
        for _, pickup in ipairs(self.state.weaponPickups) do
            pickup:draw()
        end
    end

    function Horde:drawHUD()
        if self.state.weapon then self.state.weapon:draw() end
        self.state.hud:draw()
        self.state.inventory:draw()
        self:drawOverlay()
        self.state.buyMenu:draw()
        self.state.craftMenu:draw()
    end

    function Horde:drawOverlay()
        if not (self.roundTextTimer and self.roundTextTimer > 0) then return end
        local alpha = math.max(0, self.roundTextTimer / ROUND_TEXT_TIME)
        self:drawCenteredText("WAVE " .. self.state.currentRound, self.state.scrWidth / 2 + self.state.camera.x, self.state.scrHeight / 2 - 40 + self.state.camera.y, 80, alpha)
    end

    function Horde:drawCenteredText(text, centerX, centerY, size, alpha)
        local font = Fonts.get(size)
        love.graphics.setFont(font)
        love.graphics.setColor(1, 1, 1, alpha)
        local textW = font:getWidth(text)
        love.graphics.print(text, centerX - textW / 2, centerY)
    end
end