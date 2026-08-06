-- Horde camera: following the player, clamping to the map and applying zoom.
-- Attaches methods to the Horde factory.

return function(Horde)
    function Horde:updateCamera(dt)
        self:followPlayer()
        if self.state.weapon and not self.state.buyMenu.isOpen then self.state.weapon:updateScope(dt) end
        self:clampCameraToMap()
    end

    function Horde:followPlayer()
        local cx, cy = self.state.scrWidth / 2, self.state.scrHeight / 2
        self.state.camera.x = (self.state.player.x - cx) * self.state.camera.zoom
        self.state.camera.y = (self.state.player.y - cy) * self.state.camera.zoom
    end

    function Horde:clampCameraToMap()
        local camera = self.state.camera
        local cx, cy = self.state.scrWidth / 2, self.state.scrHeight / 2
        local minCamX = cx * (1 - camera.zoom)
        local minCamY = cy * (1 - camera.zoom)
        local maxCamX = (self.state.mapWidth - cx) * camera.zoom - cx
        local maxCamY = (self.state.mapHeight - cy) * camera.zoom - cy

        if camera.x < minCamX then camera.x = minCamX end
        if camera.y < minCamY then camera.y = minCamY end
        if camera.x > maxCamX then camera.x = maxCamX end
        if camera.y > maxCamY then camera.y = maxCamY end
    end

    function Horde:applyCameraZoom()
        love.graphics.push()
        love.graphics.translate(self.state.scrWidth / 2, self.state.scrHeight / 2)
        love.graphics.scale(self.state.camera.zoom)
        love.graphics.translate(-self.state.scrWidth / 2, -self.state.scrHeight / 2)
    end
end