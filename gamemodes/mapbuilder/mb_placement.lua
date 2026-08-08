-- Map builder: placement logic. Attaches methods to the MapBuilder factory.

local Config = require "core.config"

local PLACE_INTERVAL = Config.MAPBUILDER_PLACE_INTERVAL

local function buildingItems()
    return Config.BUILDING_ITEMS
end

return function(MapBuilder)
    function MapBuilder:setQuickAccess(slot, itemKey)
        if slot < 1 or slot > self.QUICK_ACCESS_COUNT then return end
        self.quickAccess[slot] = buildingItems()[itemKey]
    end

    function MapBuilder:isSelectedItemObject()
        local item = self.quickAccess[self.selectedSlot]
        if not item then return false end
        return self:isObjectMaterial(item.material)
    end

    function MapBuilder:processContinuousPlacement(dt)
        if not self:canPlaceNow(dt) then return end
        if not self:hasPlacementButtonDown() then return end
        if not self:isPointerOnValidTile() then return end

        local col, row = self:getHoveredTile()
        if col == self.lastPlacedCol and row == self.lastPlacedRow then return end

        self:performPlacementAction(col, row)
        self:recordPlacedTile(col, row)
    end

    function MapBuilder:canPlaceNow(dt)
        local state = self.state
        if state.ignoreMouseUntilRelease then return false end
        if self.dragSlot then return false end
        if state.itemBrowser.isOpen then return false end

        self.placeCooldown = self.placeCooldown - dt
        return self.placeCooldown <= 0
    end

    function MapBuilder:hasPlacementButtonDown()
        return love.mouse.isDown(1) or love.mouse.isDown(2)
    end

    function MapBuilder:isPointerOnValidTile()
        local col, row = self:getHoveredTile()
        local grid = self.state.grid
        if col < 1 or col > grid.cols or row < 1 or row > grid.rows then return false end

        local mx, my = love.mouse.getPosition()
        local camera = self.state.camera
        return not self.state.mapBuilderHUD:isPointerOverHUD(mx + camera.x, my + camera.y)
    end

    function MapBuilder:performPlacementAction(col, row)
        if love.mouse.isDown(1) then
            self:removeBlockAtTile(col, row)
        else
            self:placeBlock(col, row, true)
        end
    end

    function MapBuilder:recordPlacedTile(col, row)
        self.lastPlacedCol = col
        self.lastPlacedRow = row
        self.placeCooldown = PLACE_INTERVAL
    end

    function MapBuilder:placeBlock(col, row, silent)
        if not self:isValidTile(col, row) then return false end
        local selectedItem = self.quickAccess[self.selectedSlot]
        if not selectedItem then return false end

        if self:isSelectedItemObject() then
            if not self:tryPlaceObject(col, row, selectedItem, silent) then return false end
        else
            if not self:tryPlaceBlock(col, row, selectedItem, silent) then return false end
        end

        self:finishSuccessfulPlacement()
        return true
    end

    function MapBuilder:tryPlaceObject(col, row, item, silent)
        if not self:canPlaceAt(col, row, item.material) then
            if not silent then self.state.toast:show("Area occupied by another object", 1.5) end
            return false
        end
        self:placeAt(col, row, item.material)
        table.insert(self.undoStack, { type = "object_place", col = col, row = row, material = item.material })
        return true
    end

    function MapBuilder:tryPlaceBlock(col, row, item, silent)
        col, row = self:snapToGrid(col, row)
        if not self:canPlaceAt(col, row, item.material) then
            if not silent then self.state.toast:show("Area occupied by another block", 1.5) end
            return false
        end
        self:placeAt(col, row, item.material)
        table.insert(self.undoStack, { type = "block_place", col = col, row = row, material = item.material })
        return true
    end

    function MapBuilder:finishSuccessfulPlacement()
        self:trimUndoStack()
        self.redoStack = {}
        self.hasUnsavedChanges = true
    end

    function MapBuilder:trimUndoStack()
        if #self.undoStack > Config.MAPBUILDER_MAX_UNDO then
            table.remove(self.undoStack, 1)
        end
    end

    function MapBuilder:removeBlockAtTile(col, row)
        if not self:isValidTile(col, row) then return false end
        if self:tryRemoveObjectAtTile(col, row) then return true end
        if self:tryRemoveBlockAtTile(col, row) then return true end
        return false
    end

    function MapBuilder:tryRemoveObjectAtTile(col, row)
        local grid = self.state.grid
        local index, record = grid:findBlockRecord(col, row, grid.objectRecords)
        if not index then return false end
        grid:removeObject(record.col, record.row)
        table.insert(self.undoStack, { type = "object_remove", col = record.col, row = record.row, material = record.material })
        self:finishSuccessfulRemoval(record.col, record.row)
        return true
    end

    function MapBuilder:tryRemoveBlockAtTile(col, row)
        local grid = self.state.grid
        local index, record = grid:findBlockRecord(col, row, grid.blockRecords)
        if not index then return false end
        grid:removeBlock(record.col, record.row)
        table.insert(self.undoStack, { type = "block_remove", col = record.col, row = record.row, material = record.material })
        self:finishSuccessfulRemoval(record.col, record.row)
        return true
    end

    function MapBuilder:finishSuccessfulRemoval(col, row)
        self.lastPlacedCol = col
        self.lastPlacedRow = row
        self:trimUndoStack()
        self.redoStack = {}
        self.hasUnsavedChanges = true
    end

    function MapBuilder:pickBlock(x, y)
        local record = self:findRecordAtScreen(x, y)
        if not record then return end
        local itemId = self:findItemKeyForMaterial(record.material)
        if not itemId then return end
        self:addItemToQuickAccess(itemId)
    end

    function MapBuilder:findRecordAtScreen(x, y)
        local col, row = self:screenToGrid(x, y)
        if not self:isValidTile(col, row) then return nil end

        local grid = self.state.grid
        local _, record = grid:findBlockRecord(col, row, grid.objectRecords)
        if not record then
            _, record = grid:findBlockRecord(col, row, grid.blockRecords)
        end
        return record
    end

    function MapBuilder:findItemKeyForMaterial(material)
        for key, item in pairs(buildingItems()) do
            if item.material == material then return key end
        end
        return nil
    end

    function MapBuilder:addItemToQuickAccess(itemId)
        for slot = 1, self.QUICK_ACCESS_COUNT do
            if not self.quickAccess[slot] then
                self:setQuickAccess(slot, itemId)
                return
            end
        end
        self:setQuickAccess(self.selectedSlot, itemId)
    end
end