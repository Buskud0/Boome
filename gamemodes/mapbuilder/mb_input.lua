-- Map builder: input handling (keyboard, mouse, wheel, pan). Attaches to factory.

local Config = require "core.config"
local Input = require "core.input"

local PAN_SPEED = Config.MAPBUILDER_PAN_SPEED
local ZOOM_MIN = Config.MAPBUILDER_ZOOM_MIN
local ZOOM_MAX = Config.MAPBUILDER_ZOOM_MAX
local ZOOM_FACTOR = Config.MAPBUILDER_ZOOM_FACTOR
local DRAG_THRESHOLD = Config.MAPBUILDER_DRAG_THRESHOLD

return function(MapBuilder)
    function MapBuilder:update(dt)
        self:updateCameraPan(dt)
        self:processContinuousPlacement(dt)
    end

    function MapBuilder:updateCameraPan(dt)
        if self.state.itemBrowser.isOpen then return end
        local speed = PAN_SPEED * dt
        local camera = self.state.camera
        if Input.isDown("move_up") then camera.y = camera.y - speed end
        if Input.isDown("move_down") then camera.y = camera.y + speed end
        if Input.isDown("move_left") then camera.x = camera.x - speed end
        if Input.isDown("move_right") then camera.x = camera.x + speed end
    end

    function MapBuilder:wheelmoved(direction, mouseX, mouseY)
        local camera = self.state.camera
        local oldZoom = camera.zoom
        camera.zoom = self:getZoomAfterScroll(direction, oldZoom)
        self:panCameraToKeepCursor(oldZoom, mouseX, mouseY)
    end

    function MapBuilder:getZoomAfterScroll(direction, oldZoom)
        if direction > 0 then
            return math.min(ZOOM_MAX, oldZoom * ZOOM_FACTOR)
        elseif direction < 0 then
            return math.max(ZOOM_MIN, oldZoom / ZOOM_FACTOR)
        end
        return oldZoom
    end

    function MapBuilder:panCameraToKeepCursor(oldZoom, mouseX, mouseY)
        local camera = self.state.camera
        local ratio = camera.zoom / oldZoom
        camera.x = (mouseX + camera.x) * ratio - mouseX
        camera.y = (mouseY + camera.y) * ratio - mouseY
    end

    function MapBuilder:handleKey(key, action)
        if self:handleCtrlShortcut(key) then return true end

        if not self.state.itemBrowser.isOpen then
            if action == "inventory" and not self.state.paused then
                self.state.itemBrowser:toggle()
                self.state.itemBrowser.consumeNextText = true
                return true
            end

            if self:handleKeyNumberSlot(key) then return true end

            return false
        end

        return self:handleItemBrowserKey(key, action)
    end

    function MapBuilder:handleCtrlShortcut(key)
        if Input.isActionBoundToKey("undo", key) then
            self:undo()
            if self.state.itemBrowser.isOpen then self.state.itemBrowser.consumeNextText = true end
            return true
        elseif Input.isActionBoundToKey("redo", key) then
            self:redo()
            if self.state.itemBrowser.isOpen then self.state.itemBrowser.consumeNextText = true end
            return true
        end
        return false
    end

    function MapBuilder:handleKeyNumberSlot(key)
        for slot = 1, self.QUICK_ACCESS_COUNT do
            if Input.isActionBoundToKey("slot" .. slot, key) then
                self.selectedSlot = slot
                return true
            end
        end
        return false
    end

    function MapBuilder:handleItemBrowserKey(key, action)
        local itemBrowser = self.state.itemBrowser
        if action == "inventory" or action == "pause" then
            if action == "pause" and itemBrowser.searchFocused then
                itemBrowser.searchFocused = false
                return true
            end
            if action == "inventory" and itemBrowser.searchFocused then
                return true
            end
            itemBrowser:close()
            itemBrowser.consumeNextText = true
            return true
        end

        if Input.isActionBoundToKey("search_backspace", key) then
            if itemBrowser.searchFocused then
                itemBrowser:handleDelete()
            end
            return true
        end

        if Input.isActionBoundToKey("search_focus", key) then
            if not itemBrowser.searchFocused then
                itemBrowser.searchFocused = true
                itemBrowser.consumeNextText = true
            end
            return true
        end

        return false
    end

    function MapBuilder:handleClick(x, y, button)
        local camera = self.state.camera
        local wx = x + camera.x
        local wy = y + camera.y

        if button == 1 and self.dragSlot then return end

        if self.state.itemBrowser.isOpen then
            if button == 1 then
                if self:isPointerOnSaveButton(wx, wy) then
                    self:save()
                elseif self:isPointerOnRevertButton(wx, wy) then
                    self:revert()
                else
                    local slotIndex = self:slotIndexAtPosition(wx, wy)
                    if slotIndex then
                        self:startSlotDrag(slotIndex, wx, wy)
                    else
                        self.state.itemBrowser:mousepressed(wx, wy)
                    end
                end
            elseif button == 2 then
                local slotIndex = self:slotIndexAtPosition(wx, wy)
                if slotIndex then
                    self:dropItemFromSlot(slotIndex)
                end
            end
            return
        end

        if button == 1 then
            self:handleLeftClick(wx, wy, x, y)
        elseif button == 2 then
            self:handleRightClick(wx, wy, x, y)
        elseif button == 3 then
            self:handleMiddleClick(x, y)
        end
    end

    function MapBuilder:handleLeftClick(wx, wy, x, y)
        if self:isPointerOnSaveButton(wx, wy) then
            self:save()
            return
        end

        if self:isPointerOnRevertButton(wx, wy) then
            self:revert()
            return
        end

        local slotIndex = self:slotIndexAtPosition(wx, wy)
        if slotIndex then
            self:startSlotDrag(slotIndex, wx, wy)
            return
        end

        self:handleGridRemove(x, y)
    end

    function MapBuilder:handleRightClick(wx, wy, x, y)
        local slotIndex = self:slotIndexAtPosition(wx, wy)
        if slotIndex then
            self:dropItemFromSlot(slotIndex)
            return
        end
        if self.state.mapBuilderHUD:isPointerOverHUD(wx, wy) then return end
        local col, row = self:screenToGrid(x, y)
        self:placeBlock(col, row)
        self:recordPlacedTile(col, row)
    end

    function MapBuilder:handleMiddleClick(x, y)
        if self.state.mapBuilderHUD:isPointerOverHUD(x + self.state.camera.x, y + self.state.camera.y) then return end
        self:pickBlock(x, y)
    end

    function MapBuilder:handleGridRemove(x, y)
        local col, row = self:screenToGrid(x, y)
        if self:removeBlockAtTile(col, row) then
            self:recordPlacedTile(col, row)
        end
    end

    function MapBuilder:handleMouseRelease(x, y, button)
        if button == 1 then
            if self.dragSlot then
                self:finalizeSlotDrag(x, y)
                return
            end

            if self.state.itemBrowser.isOpen then
                self.state.itemBrowser:mousereleased(x + self.state.camera.x, y + self.state.camera.y)
            end
        end
    end

    function MapBuilder:finalizeSlotDrag(x, y)
        local camera = self.state.camera
        local wx = x + camera.x
        local wy = y + camera.y

        if self:isDragClick(wx, wy) then
            self:completeSlotClick(self.dragSlot)
            return
        end

        if self:trySwapSlotWithTarget(wx, wy) then return end

        self:completeSlotClick(self.dragSlot)
    end

    function MapBuilder:isDragClick(wx, wy)
        local dx = wx - self.dragStartX
        local dy = wy - self.dragStartY
        return dx * dx + dy * dy < DRAG_THRESHOLD * DRAG_THRESHOLD
    end

    function MapBuilder:handleTextInput(text)
        if self.state.itemBrowser.isOpen then
            self.state.itemBrowser:handleTextInput(text)
        end
    end

    function MapBuilder:handleWheel(y)
        if y ~= 0 then
            if self.state.itemBrowser.isOpen then
                self.state.itemBrowser.scrollY = math.max(0, self.state.itemBrowser.scrollY - y * 40)
                self.state.itemBrowser:clampScroll()
            else
                local mx, my = love.mouse.getPosition()
                self:wheelmoved(y, mx, my)
            end
        end
    end
end