local MapBuilder = {}

local PAN_SPEED = MAPBUILDER_PAN_SPEED
local ZOOM_MIN = MAPBUILDER_ZOOM_MIN
local ZOOM_MAX = MAPBUILDER_ZOOM_MAX
local ZOOM_FACTOR = MAPBUILDER_ZOOM_FACTOR
local QUICK_ACCESS_COUNT = MAPBUILDER_QUICK_ACCESS_COUNT
MapBuilder.QUICK_ACCESS_COUNT = QUICK_ACCESS_COUNT
local PLACE_INTERVAL = MAPBUILDER_PLACE_INTERVAL
local BLOCK_SIZE = MAPBUILDER_BLOCK_SIZE

MapBuilder.quickAccess = {}
MapBuilder.selectedSlot = 1
MapBuilder.hasUnsavedChanges = false
MapBuilder.undoStack = {}
MapBuilder.redoStack = {}
MapBuilder.hasSavedFile = false
MapBuilder.placeCooldown = 0
MapBuilder.lastPlacedCol = 0
MapBuilder.lastPlacedRow = 0
MapBuilder.dragSlot = nil
MapBuilder.dragStartX = 0
MapBuilder.dragStartY = 0
MapBuilder.currentMapName = nil

local MAX_UNDO = MAPBUILDER_MAX_UNDO
local DRAG_THRESHOLD = MAPBUILDER_DRAG_THRESHOLD

function MapBuilder.enter(mapName)
    MapBuilder.currentMapName = mapName or MapBuilder.currentMapName
    MapBuilder.load()
    MapBuilder.resetCamera()
    MapBuilder.resetEditSession()
end

function MapBuilder.grassFillData()
    local tileSize = 10
    local cols = math.floor(mapWidth / tileSize)
    local rows = math.floor(mapHeight / tileSize)
    local blockCols = math.ceil(cols / BLOCK_SIZE)
    local blockRows = math.ceil(rows / BLOCK_SIZE)
    local lines = {}
    for br = 0, blockRows - 1 do
        for bc = 0, blockCols - 1 do
            table.insert(lines, (1 + bc * BLOCK_SIZE) .. "," .. (1 + br * BLOCK_SIZE) .. ",grass")
        end
    end
    return table.concat(lines, "\n")
end

function MapBuilder.resetCamera()
    camera.x = 0
    camera.y = 0
    camera.zoom = 1
end

function MapBuilder.resetEditSession()
    MapBuilder.quickAccess = {}
    MapBuilder.selectedSlot = 1
    MapBuilder.resetHistory()
end

function MapBuilder.resetHistory()
    MapBuilder.undoStack = {}
    MapBuilder.redoStack = {}
end

function MapBuilder.updateCameraPan(dt)
    if ItemBrowser.isOpen then return end
    local speed = PAN_SPEED * dt
    if Input.isDown("move_up") then camera.y = camera.y - speed end
    if Input.isDown("move_down") then camera.y = camera.y + speed end
    if Input.isDown("move_left") then camera.x = camera.x - speed end
    if Input.isDown("move_right") then camera.x = camera.x + speed end
end

function MapBuilder.processContinuousPlacement(dt)
    if not MapBuilder.canPlaceNow(dt) then return end
    if not MapBuilder.hasPlacementButtonDown() then return end
    if not MapBuilder.isPointerOnValidTile() then return end

    local col, row = MapBuilder.getHoveredTile()
    if col == MapBuilder.lastPlacedCol and row == MapBuilder.lastPlacedRow then return end

    MapBuilder.performPlacementAction(col, row)
    MapBuilder.recordPlacedTile(col, row)
end

function MapBuilder.canPlaceNow(dt)
    if ignoreMouseUntilRelease then return false end
    if MapBuilder.dragSlot then return false end
    if ItemBrowser.isOpen then return false end

    MapBuilder.placeCooldown = MapBuilder.placeCooldown - dt
    return MapBuilder.placeCooldown <= 0
end

function MapBuilder.hasPlacementButtonDown()
    return love.mouse.isDown(1) or love.mouse.isDown(2)
end

function MapBuilder.isPointerOnValidTile()
    local col, row = MapBuilder.getHoveredTile()
    if col < 1 or col > grid.cols or row < 1 or row > grid.rows then return false end

    local mx, my = love.mouse.getPosition()
    return not MapBuilderHUD.isPointerOverHUD(mx + camera.x, my + camera.y)
end

function MapBuilder.getHoveredTile()
    local mx, my = love.mouse.getPosition()
    return MapBuilder.screenToGrid(mx, my)
end

function MapBuilder.performPlacementAction(col, row)
    if love.mouse.isDown(1) then
        MapBuilder.removeBlockAtTile(col, row)
    else
        MapBuilder.placeBlock(col, row, true)
    end
end

function MapBuilder.recordPlacedTile(col, row)
    MapBuilder.lastPlacedCol = col
    MapBuilder.lastPlacedRow = row
    MapBuilder.placeCooldown = PLACE_INTERVAL
end

function MapBuilder.update(dt)
    MapBuilder.updateCameraPan(dt)
    MapBuilder.processContinuousPlacement(dt)
end

function MapBuilder.wheelmoved(direction, mouseX, mouseY)
    local oldZoom = camera.zoom
    camera.zoom = MapBuilder.getZoomAfterScroll(direction, oldZoom)
    MapBuilder.panCameraToKeepCursor(oldZoom, mouseX, mouseY)
end

function MapBuilder.getZoomAfterScroll(direction, oldZoom)
    if direction > 0 then
        return math.min(ZOOM_MAX, oldZoom * ZOOM_FACTOR)
    elseif direction < 0 then
        return math.max(ZOOM_MIN, oldZoom / ZOOM_FACTOR)
    end
    return oldZoom
end

function MapBuilder.panCameraToKeepCursor(oldZoom, mouseX, mouseY)
    local ratio = camera.zoom / oldZoom
    camera.x = (mouseX + camera.x) * ratio - mouseX
    camera.y = (mouseY + camera.y) * ratio - mouseY
end

function MapBuilder.setQuickAccess(slot, itemKey)
    if slot < 1 or slot > QUICK_ACCESS_COUNT then return end
    MapBuilder.quickAccess[slot] = BUILDING_ITEMS[itemKey]
end

function MapBuilder.isSelectedItemObject()
    local item = MapBuilder.quickAccess[MapBuilder.selectedSlot]
    if not item then return false end
    return OBJECT_ITEMS[item.material] ~= nil
end

function MapBuilder.screenToGrid(screenX, screenY)
    local worldX = (screenX + camera.x) / camera.zoom
    local worldY = (screenY + camera.y) / camera.zoom
    return math.floor(worldX / grid.tileSize) + 1, math.floor(worldY / grid.tileSize) + 1
end

function MapBuilder.placeBlock(col, row, silent)
    if not MapBuilder.isValidTile(col, row) then return false end
    local selectedItem = MapBuilder.quickAccess[MapBuilder.selectedSlot]
    if not selectedItem then return false end

    if MapBuilder.isSelectedItemObject() then
        if not MapBuilder.tryPlaceObject(col, row, selectedItem, silent) then return false end
    else
        if not MapBuilder.tryPlaceBlock(col, row, selectedItem, silent) then return false end
    end

    MapBuilder.finishSuccessfulPlacement()
    return true
end

function MapBuilder.isValidTile(col, row)
    return col >= 1 and col <= grid.cols and row >= 1 and row <= grid.rows
end

function MapBuilder.tryPlaceObject(col, row, item, silent)
    if not grid:isAreaFreeOfObjects(col, row, BLOCK_SIZE) then
        if not silent then Toast.show("Area occupied by another object", 1.5) end
        return false
    end
    grid:placeObject(col, row, item.material)
    table.insert(MapBuilder.undoStack, { type = "object_place", col = col, row = row, material = item.material })
    return true
end

function MapBuilder.snapToBlockGrid(col, row)
    local snappedCol = math.floor((col - 1) / BLOCK_SIZE) * BLOCK_SIZE + 1
    local snappedRow = math.floor((row - 1) / BLOCK_SIZE) * BLOCK_SIZE + 1
    return snappedCol, snappedRow
end

function MapBuilder.tryPlaceBlock(col, row, item, silent)
    col, row = MapBuilder.snapToBlockGrid(col, row)
    if not grid:isAreaFreeOfBlocks(col, row, BLOCK_SIZE) then
        if not silent then Toast.show("Area occupied by another block", 1.5) end
        return false
    end
    grid:placeBlock(col, row, item.material)
    table.insert(MapBuilder.undoStack, { type = "block_place", col = col, row = row, material = item.material })
    return true
end

function MapBuilder.finishSuccessfulPlacement()
    MapBuilder.trimUndoStack()
    MapBuilder.redoStack = {}
    MapBuilder.hasUnsavedChanges = true
end

function MapBuilder.trimUndoStack()
    if #MapBuilder.undoStack > MAX_UNDO then
        table.remove(MapBuilder.undoStack, 1)
    end
end

function MapBuilder.removeBlockAtTile(col, row)
    if not MapBuilder.isValidTile(col, row) then return false end
    if MapBuilder.tryRemoveObjectAtTile(col, row) then return true end
    if MapBuilder.tryRemoveBlockAtTile(col, row) then return true end
    return false
end

function MapBuilder.tryRemoveObjectAtTile(col, row)
    local index, record = grid:findBlockRecord(col, row, grid.objectRecords)
    if not index then return false end
    grid:removeObject(record.col, record.row)
    table.insert(MapBuilder.undoStack, { type = "object_remove", col = record.col, row = record.row, material = record.material })
    MapBuilder.finishSuccessfulRemoval(record.col, record.row)
    return true
end

function MapBuilder.tryRemoveBlockAtTile(col, row)
    local index, record = grid:findBlockRecord(col, row, grid.blockRecords)
    if not index then return false end
    grid:removeBlock(record.col, record.row)
    table.insert(MapBuilder.undoStack, { type = "block_remove", col = record.col, row = record.row, material = record.material })
    MapBuilder.finishSuccessfulRemoval(record.col, record.row)
    return true
end

function MapBuilder.finishSuccessfulRemoval(col, row)
    MapBuilder.lastPlacedCol = col
    MapBuilder.lastPlacedRow = row
    MapBuilder.trimUndoStack()
    MapBuilder.redoStack = {}
    MapBuilder.hasUnsavedChanges = true
end

function MapBuilder.pickBlock(x, y)
    local record = MapBuilder.findRecordAtScreen(x, y)
    if not record then return end

    local itemKey = MapBuilder.findItemKeyForMaterial(record.material)
    if not itemKey then return end

    MapBuilder.addItemToQuickAccess(itemKey)
end

function MapBuilder.findRecordAtScreen(x, y)
    local col, row = MapBuilder.screenToGrid(x, y)
    if not MapBuilder.isValidTile(col, row) then return nil end

    local _, record = grid:findBlockRecord(col, row, grid.objectRecords)
    if not record then
        _, record = grid:findBlockRecord(col, row, grid.blockRecords)
    end
    return record
end

function MapBuilder.findItemKeyForMaterial(material)
    for key, item in pairs(BUILDING_ITEMS) do
        if item.material == material then return key end
    end
    return nil
end

function MapBuilder.addItemToQuickAccess(itemKey)
    for slot = 1, QUICK_ACCESS_COUNT do
        if not MapBuilder.quickAccess[slot] then
            MapBuilder.setQuickAccess(slot, itemKey)
            return
        end
    end
    MapBuilder.setQuickAccess(MapBuilder.selectedSlot, itemKey)
end

function MapBuilder.undo()
    local action = MapBuilder.popAction(MapBuilder.undoStack)
    if not action then return end

    local inverseType = MapBuilder.getInverseActionType(action.type)
    MapBuilder.applyAction(inverseType, action)
    MapBuilder.pushAction(MapBuilder.redoStack, inverseType, action)

    MapBuilder.hasUnsavedChanges = true
    Toast.show("Undo", 1)
end

function MapBuilder.redo()
    local action = MapBuilder.popAction(MapBuilder.redoStack)
    if not action then return end

    MapBuilder.applyAction(action.type, action)
    MapBuilder.pushAction(MapBuilder.undoStack, action.type, action)

    MapBuilder.hasUnsavedChanges = true
    Toast.show("Redo", 1)
end

function MapBuilder.popAction(stack)
    local action = stack[#stack]
    if action then table.remove(stack) end
    return action
end

function MapBuilder.pushAction(stack, actionType, action)
    table.insert(stack, { type = actionType, col = action.col, row = action.row, material = action.material })
end

function MapBuilder.getInverseActionType(actionType)
    if actionType:find("_place", 1, true) then
        return actionType:gsub("_place$", "_remove")
    end
    return actionType:gsub("_remove$", "_place")
end

function MapBuilder.applyAction(actionType, action)
    if actionType:find("_remove", 1, true) then
        MapBuilder.removePlacedRecord(actionType, action)
    else
        MapBuilder.reinsertPlacedRecord(actionType, action)
    end
end

function MapBuilder.removePlacedRecord(actionType, action)
    local records = MapBuilder.getRecordsForAction(actionType)
    for i = #records, 1, -1 do
        if records[i].col == action.col and records[i].row == action.row then
            table.remove(records, i)
            break
        end
    end
    grid:rebuildGrid()
end

function MapBuilder.reinsertPlacedRecord(actionType, action)
    local placeFn = MapBuilder.getPlaceFnForAction(actionType)
    placeFn(grid, action.col, action.row, action.material)
end

function MapBuilder.getRecordsForAction(actionType)
    if actionType:find("block", 1, true) then return grid.blockRecords end
    return grid.objectRecords
end

function MapBuilder.getPlaceFnForAction(actionType)
    if actionType:find("block", 1, true) then return grid.placeBlock end
    return grid.placeObject
end

function MapBuilder.revert()
    if not MapBuilder.hasUnsavedChanges or not MapBuilder.hasSavedFile then return end
    MapBuilder.load()
    MapBuilder.resetHistory()
    Toast.show("Reverted", 1)
end

function MapBuilder.drawBackground()
    love.graphics.setColor(0.45, 0.45, 0.45)
    love.graphics.rectangle("fill", 0, 0, mapWidth, mapHeight)
    grid:draw()
    grid:drawBushesAboveEntities()
end

function MapBuilder.drawGridLines(tileSize)
    local blockPx = BLOCK_SIZE * tileSize
    love.graphics.setColor(0.2, 0.2, 0.2)
    for x = 0, mapWidth, blockPx do
        love.graphics.line(x, 0, x, mapHeight)
    end
    for y = 0, mapHeight, blockPx do
        love.graphics.line(0, y, mapWidth, y)
    end
end

function MapBuilder.drawHoverIndicator(tileSize)
    local mx, my = love.mouse.getPosition()
    local col, row = MapBuilder.screenToGrid(mx, my)
    if not MapBuilder.isValidTile(col, row) then return end

    if ItemBrowser.isOpen or MapBuilderHUD.isPointerOverHUD(mx + camera.x, my + camera.y) then return end

    if not MapBuilder.isSelectedItemObject() then
        col, row = MapBuilder.snapToBlockGrid(col, row)
    end

    love.graphics.setColor(0.3, 0.5, 1.0, 0.1)
    love.graphics.rectangle("fill", (col - 1) * tileSize, (row - 1) * tileSize, BLOCK_SIZE * tileSize, BLOCK_SIZE * tileSize)
    love.graphics.setColor(0.3, 0.5, 1.0, 0.5)
    love.graphics.rectangle("line", (col - 1) * tileSize, (row - 1) * tileSize, BLOCK_SIZE * tileSize, BLOCK_SIZE * tileSize)
end

function MapBuilder.draw()
    love.graphics.push()
    love.graphics.scale(camera.zoom)
    MapBuilder.drawBackground()
    MapBuilder.drawGridLines(grid.tileSize)
    MapBuilder.drawHoverIndicator(grid.tileSize)
    love.graphics.pop()
    if ItemBrowser.isOpen then
        ItemBrowser.draw()
    end
    MapBuilderHUD.draw()
    MapBuilder.drawDragGhost()
end

function MapBuilder.drawDragGhost()
    if not MapBuilder.dragSlot then return end
    local mx, my = love.mouse.getPosition()
    local item = MapBuilder.quickAccess[MapBuilder.dragSlot]
    if not item then return end
    Textures.draw(item.material, mx + camera.x - 20, my + camera.y - 20, 40, 40, 0.8)
end

function MapBuilder.handleKey(key, action)
    if MapBuilder.handleCtrlShortcut(key) then return true end

    if not ItemBrowser.isOpen then
        if action == "inventory" and not paused then
            ItemBrowser.toggle()
            ItemBrowser.consumeNextText = true
            return true
        end

        if MapBuilder.handleKeyNumberSlot(key) then return true end

        return false
    end

    return MapBuilder.handleItemBrowserKey(key, action)
end

function MapBuilder.handleCtrlShortcut(key)
    if Input.isActionBoundToKey("undo", key) then
        MapBuilder.undo()
        if ItemBrowser.isOpen then ItemBrowser.consumeNextText = true end
        return true
    elseif Input.isActionBoundToKey("redo", key) then
        MapBuilder.redo()
        if ItemBrowser.isOpen then ItemBrowser.consumeNextText = true end
        return true
    end
    return false
end

function MapBuilder.handleKeyNumberSlot(key)
    for slot = 1, QUICK_ACCESS_COUNT do
        if Input.isActionBoundToKey("slot" .. slot, key) then
            MapBuilder.selectedSlot = slot
            return true
        end
    end
    return false
end

function MapBuilder.handleItemBrowserKey(key, action)
    if action == "inventory" or action == "pause" then
        if action == "pause" and ItemBrowser.searchFocused then
            ItemBrowser.searchFocused = false
            return true
        end
        if action == "inventory" and ItemBrowser.searchFocused then
            return true
        end
        ItemBrowser.close()
        ItemBrowser.consumeNextText = true
        return true
    end

    if Input.isActionBoundToKey("search_backspace", key) then
        if ItemBrowser.searchFocused then
            ItemBrowser.handleDelete()
        end
        return true
    end

    if Input.isActionBoundToKey("search_focus", key) then
        if not ItemBrowser.searchFocused then
            ItemBrowser.searchFocused = true
            ItemBrowser.consumeNextText = true
        end
        return true
    end

    return false
end

function MapBuilder.handleClick(x, y, button)
    local wx = x + camera.x
    local wy = y + camera.y

    if button == 1 and MapBuilder.dragSlot then return end

    if ItemBrowser.isOpen then
        if button == 1 then
            if MapBuilder.isPointerOnSaveButton(wx, wy) then
                MapBuilder.save()
            elseif MapBuilder.isPointerOnRevertButton(wx, wy) then
                MapBuilder.revert()
            else
                local slotIndex = MapBuilder.slotIndexAtPosition(wx, wy)
                if slotIndex then
                    MapBuilder.startSlotDrag(slotIndex, wx, wy)
                else
                    ItemBrowser.mousepressed(wx, wy)
                end
            end
        elseif button == 2 then
            local slotIndex = MapBuilder.slotIndexAtPosition(wx, wy)
            if slotIndex then
                MapBuilder.dropItemFromSlot(slotIndex)
            end
        end
        return
    end

    if button == 1 then
        MapBuilder.handleLeftClick(wx, wy, x, y)
    elseif button == 2 then
        MapBuilder.handleRightClick(wx, wy, x, y)
    elseif button == 3 then
        MapBuilder.handleMiddleClick(x, y)
    end
end

function MapBuilder.handleLeftClick(wx, wy, x, y)
    if MapBuilder.isPointerOnSaveButton(wx, wy) then
        MapBuilder.save()
        return
    end

    if MapBuilder.isPointerOnRevertButton(wx, wy) then
        MapBuilder.revert()
        return
    end

    local slotIndex = MapBuilder.slotIndexAtPosition(wx, wy)
    if slotIndex then
        MapBuilder.startSlotDrag(slotIndex, wx, wy)
        return
    end

    MapBuilder.handleGridRemove(x, y)
end

function MapBuilder.handleRightClick(wx, wy, x, y)
    local slotIndex = MapBuilder.slotIndexAtPosition(wx, wy)
    if slotIndex then
        MapBuilder.dropItemFromSlot(slotIndex)
        return
    end
    if MapBuilderHUD.isPointerOverHUD(wx, wy) then return end
    local col, row = MapBuilder.screenToGrid(x, y)
    MapBuilder.placeBlock(col, row)
    MapBuilder.recordPlacedTile(col, row)
end

function MapBuilder.handleMiddleClick(x, y)
    if MapBuilderHUD.isPointerOverHUD(x + camera.x, y + camera.y) then return end
    MapBuilder.pickBlock(x, y)
end

function MapBuilder.handleGridRemove(x, y)
    local col, row = MapBuilder.screenToGrid(x, y)
    if MapBuilder.removeBlockAtTile(col, row) then
        MapBuilder.recordPlacedTile(col, row)
    end
end

function MapBuilder.isPointerOnSaveButton(wx, wy)
    local rect = MapBuilderHUD.getSaveButtonRect()
    return MapBuilder.isPointInRect(wx, wy, rect)
end

function MapBuilder.isPointerOnRevertButton(wx, wy)
    local rect = MapBuilderHUD.getRevertButtonRect()
    return MapBuilder.isPointInRect(wx, wy, rect)
end

function MapBuilder.isPointInRect(x, y, rect)
    return x >= rect.x and x <= rect.x + rect.w and y >= rect.y and y <= rect.y + rect.h
end

function MapBuilder.slotIndexAtPosition(wx, wy)
    local rects = MapBuilderHUD.getSlotRects()
    for i, rect in ipairs(rects) do
        if MapBuilder.isPointInRect(wx, wy, rect) then
            return i
        end
    end
    return nil
end

function MapBuilder.startSlotDrag(slotIndex, wx, wy)
    MapBuilder.dragSlot = slotIndex
    MapBuilder.dragStartX = wx
    MapBuilder.dragStartY = wy
end

function MapBuilder.handleMouseRelease(x, y, button)
    if button == 1 then
        if MapBuilder.dragSlot then
            MapBuilder.finalizeSlotDrag(x, y)
            return
        end

        if ItemBrowser.isOpen then
            ItemBrowser.mousereleased(x + camera.x, y + camera.y)
        end
    end
end

function MapBuilder.finalizeSlotDrag(x, y)
    local wx = x + camera.x
    local wy = y + camera.y

    if MapBuilder.isDragClick(wx, wy) then
        MapBuilder.completeSlotClick(MapBuilder.dragSlot)
        return
    end

    if MapBuilder.trySwapSlotWithTarget(wx, wy) then return end

    MapBuilder.completeSlotClick(MapBuilder.dragSlot)
end

function MapBuilder.isDragClick(wx, wy)
    local dx = wx - MapBuilder.dragStartX
    local dy = wy - MapBuilder.dragStartY
    return dx * dx + dy * dy < DRAG_THRESHOLD * DRAG_THRESHOLD
end

function MapBuilder.completeSlotClick(slotIndex)
    MapBuilder.selectedSlot = slotIndex
    MapBuilder.dragSlot = nil
end

function MapBuilder.dropItemFromSlot(slotIndex)
    if not MapBuilder.quickAccess[slotIndex] then return end
    MapBuilder.quickAccess[slotIndex] = nil
    if MapBuilder.dragSlot == slotIndex then MapBuilder.dragSlot = nil end
    Toast.show("Item removed", 1)
end

function MapBuilder.trySwapSlotWithTarget(wx, wy)
    local targetIndex = MapBuilder.slotIndexAtPosition(wx, wy)
    if not targetIndex then return false end
    local temp = MapBuilder.quickAccess[targetIndex]
    MapBuilder.quickAccess[targetIndex] = MapBuilder.quickAccess[MapBuilder.dragSlot]
    MapBuilder.quickAccess[MapBuilder.dragSlot] = temp
    MapBuilder.selectedSlot = targetIndex
    MapBuilder.dragSlot = nil
    return true
end

function MapBuilder.handleTextInput(text)
    if ItemBrowser.isOpen then
        ItemBrowser.handleTextInput(text)
    end
end

function MapBuilder.handleWheel(y)
    if y ~= 0 then
        if ItemBrowser.isOpen then
            ItemBrowser.scrollY = math.max(0, ItemBrowser.scrollY - y * 40)
            ItemBrowser.clampScroll()
        else
            local mx, my = love.mouse.getPosition()
            MapBuilder.wheelmoved(y, mx, my)
        end
    end
end

function MapBuilder.save()
    local content = grid:saveData()
    if #content == 0 then
        Toast.show("Nothing to save", 1)
        return
    end
    MapStorage.saveMap(MapBuilder.currentMapName, content)
    MapBuilder.hasUnsavedChanges = false
    MapBuilder.hasSavedFile = true
    Toast.show("Map saved", 1)
end

function MapBuilder.load()
    local content = MapStorage.loadMap(MapBuilder.currentMapName)
    if not content then
        MapBuilder.resetGrid()
        return
    end
    grid:loadData(content)
    MapBuilder.hasUnsavedChanges = false
    MapBuilder.hasSavedFile = true
end

function MapBuilder.resetGrid()
    grid.grid = {}
    grid.objects = {}
    grid.blockRecords = {}
    grid.objectRecords = {}
end

return MapBuilder
