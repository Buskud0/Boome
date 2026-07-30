local MapBuilder = {}

local PAN_SPEED = 300
local ZOOM_MIN = 0.1
local ZOOM_MAX = 10
local ZOOM_FACTOR = 1.1
local QUICK_ACCESS_COUNT = 10
MapBuilder.QUICK_ACCESS_COUNT = QUICK_ACCESS_COUNT
local PLACE_INTERVAL = 0.08
MapBuilder.PLACE_INTERVAL = PLACE_INTERVAL
local BLOCK_SIZE = 4

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

local MAX_UNDO = 100
local DRAG_THRESHOLD = 10

function MapBuilder.enter()
    camera.x = 0
    camera.y = 0
    camera.zoom = 1
    MapBuilder.quickAccess = {}
    MapBuilder.selectedSlot = 1
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
    if ignoreMouseUntilRelease then return end
    if MapBuilder.dragSlot then return end
    MapBuilder.placeCooldown = MapBuilder.placeCooldown - dt
    if MapBuilder.placeCooldown > 0 then return end
    if ItemBrowser.isOpen then return end

    if not love.mouse.isDown(1) and not love.mouse.isDown(2) then return end

    local mx, my = love.mouse.getPosition()
    local col, row = MapBuilder.screenToGrid(mx, my)
    if col < 1 or col > grid.cols or row < 1 or row > grid.rows then return end
    if col == MapBuilder.lastPlacedCol and row == MapBuilder.lastPlacedRow then return end

    local wx = mx + camera.x
    local wy = my + camera.y
    if MapBuilderHUD.isPointerOverHUD(wx, wy) then return end

    if love.mouse.isDown(1) then
        MapBuilder.removeBlockAtTile(col, row)
    else
        MapBuilder.placeBlock(col, row, true)
    end

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
    if direction > 0 then
        camera.zoom = math.min(ZOOM_MAX, camera.zoom * ZOOM_FACTOR)
    elseif direction < 0 then
        camera.zoom = math.max(ZOOM_MIN, camera.zoom / ZOOM_FACTOR)
    end
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
    if col < 1 or col > grid.cols or row < 1 or row > grid.rows then return false end
    local selectedItem = MapBuilder.quickAccess[MapBuilder.selectedSlot]
    if not selectedItem then return false end

    if MapBuilder.isSelectedItemObject() then
        if not grid:isAreaFreeOfObjects(col, row, BLOCK_SIZE) then
            if not silent then Toast.show("Area occupied by another object", 1.5) end
            return false
        end
        grid:placeObject(col, row, selectedItem.material)
        table.insert(MapBuilder.undoStack, {
            type = "object_place",
            col = col,
            row = row,
            material = selectedItem.material,
        })
    else
        if not grid:isAreaFreeOfBlocks(col, row, BLOCK_SIZE) then
            if not silent then Toast.show("Area occupied by another block", 1.5) end
            return false
        end
        grid:placeBlock(col, row, selectedItem.material)
        table.insert(MapBuilder.undoStack, {
            type = "block_place",
            col = col,
            row = row,
            material = selectedItem.material,
        })
    end

    if #MapBuilder.undoStack > MAX_UNDO then
        table.remove(MapBuilder.undoStack, 1)
    end
    MapBuilder.redoStack = {}
    MapBuilder.hasUnsavedChanges = true
    return true
end

function MapBuilder.removeBlockAtTile(col, row)
    if col < 1 or col > grid.cols or row < 1 or row > grid.rows then return false end

    local index, record = grid:findBlockRecord(col, row, grid.objectRecords)
    if index then
        grid:removeObject(record.col, record.row)
        table.insert(MapBuilder.undoStack, {
            type = "object_remove",
            col = record.col,
            row = record.row,
            material = record.material,
        })
        MapBuilder.lastPlacedCol = record.col
        MapBuilder.lastPlacedRow = record.row
        if #MapBuilder.undoStack > MAX_UNDO then
            table.remove(MapBuilder.undoStack, 1)
        end
        MapBuilder.redoStack = {}
        MapBuilder.hasUnsavedChanges = true
        return true
    end

    local index, record = grid:findBlockRecord(col, row, grid.blockRecords)
    if index then
        grid:removeBlock(record.col, record.row)
        table.insert(MapBuilder.undoStack, {
            type = "block_remove",
            col = record.col,
            row = record.row,
            material = record.material,
        })
        MapBuilder.lastPlacedCol = record.col
        MapBuilder.lastPlacedRow = record.row
        if #MapBuilder.undoStack > MAX_UNDO then
            table.remove(MapBuilder.undoStack, 1)
        end
        MapBuilder.redoStack = {}
        MapBuilder.hasUnsavedChanges = true
        return true
    end

    return false
end

function MapBuilder.pickBlock(x, y)
    local col, row = MapBuilder.screenToGrid(x, y)
    if col < 1 or col > grid.cols or row < 1 or row > grid.rows then return end

    local _, record = grid:findBlockRecord(col, row, grid.objectRecords)
    if not record then
        _, record = grid:findBlockRecord(col, row, grid.blockRecords)
    end
    if not record then return end

    local itemKey
    for key, item in pairs(BUILDING_ITEMS) do
        if item.material == record.material then
            itemKey = key
            break
        end
    end
    if not itemKey then return end

    for slot = 1, QUICK_ACCESS_COUNT do
        if not MapBuilder.quickAccess[slot] then
            MapBuilder.setQuickAccess(slot, itemKey)
            return
        end
    end

    MapBuilder.setQuickAccess(MapBuilder.selectedSlot, itemKey)
end

function MapBuilder.undo()
    local action = MapBuilder.undoStack[#MapBuilder.undoStack]
    if not action then return end
    table.remove(MapBuilder.undoStack)

    if action.type == "block_place" or action.type == "object_place" then
        local records = (action.type == "block_place") and grid.blockRecords or grid.objectRecords
        for i = #records, 1, -1 do
            if records[i].col == action.col and records[i].row == action.row then
                table.remove(records, i)
                break
            end
        end
        grid:rebuildGrid()
        table.insert(MapBuilder.redoStack, {
            type = action.type == "block_place" and "block_remove" or "object_remove",
            col = action.col,
            row = action.row,
            material = action.material,
        })
    else
        local placeFn = (action.type == "block_remove") and grid.placeBlock or grid.placeObject
        placeFn(grid, action.col, action.row, action.material)
        table.insert(MapBuilder.redoStack, {
            type = action.type == "block_remove" and "block_place" or "object_place",
            col = action.col,
            row = action.row,
            material = action.material,
        })
    end

    MapBuilder.hasUnsavedChanges = true
    Toast.show("Undo", 1)
end

function MapBuilder.redo()
    local action = MapBuilder.redoStack[#MapBuilder.redoStack]
    if not action then return end
    table.remove(MapBuilder.redoStack)

    if action.type == "block_place" or action.type == "object_place" then
        local placeFn = (action.type == "block_place") and grid.placeBlock or grid.placeObject
        placeFn(grid, action.col, action.row, action.material)
        table.insert(MapBuilder.undoStack, action)
    else
        local records = (action.type == "block_remove") and grid.blockRecords or grid.objectRecords
        for i = #records, 1, -1 do
            if records[i].col == action.col and records[i].row == action.row then
                table.remove(records, i)
                break
            end
        end
        grid:rebuildGrid()
        table.insert(MapBuilder.undoStack, {
            type = action.type == "block_remove" and "block_place" or "object_place",
            col = action.col,
            row = action.row,
            material = action.material,
        })
    end

    MapBuilder.hasUnsavedChanges = true
    Toast.show("Redo", 1)
end

function MapBuilder.revert()
    if not MapBuilder.hasUnsavedChanges or not MapBuilder.hasSavedFile then return end
    MapBuilder.load()
    MapBuilder.undoStack = {}
    MapBuilder.redoStack = {}
    Toast.show("Reverted", 1)
end

function MapBuilder.drawBackground()
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", 0, 0, mapWidth, mapHeight)
    grid:draw()
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
    if col < 1 or col > grid.cols or row < 1 or row > grid.rows then return end

    local wx = mx + camera.x
    local wy = my + camera.y
    if ItemBrowser.isOpen or MapBuilderHUD.isPointerOverHUD(wx, wy) then return end

    love.graphics.setColor(0.3, 0.5, 1.0, 0.1)
    love.graphics.rectangle("fill", (col - 1) * tileSize, (row - 1) * tileSize, BLOCK_SIZE * tileSize, BLOCK_SIZE * tileSize)
    love.graphics.setColor(0.3, 0.5, 1.0, 0.5)
    love.graphics.rectangle("line", (col - 1) * tileSize, (row - 1) * tileSize, BLOCK_SIZE * tileSize, BLOCK_SIZE * tileSize)
end

function MapBuilder.draw()
    love.graphics.push()
    love.graphics.scale(camera.zoom)
    MapBuilder.drawBackground()
    local tileSize = grid.tileSize
    MapBuilder.drawGridLines(tileSize)
    MapBuilder.drawHoverIndicator(tileSize)
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
    love.graphics.setColor(1, 1, 1, 0.8)
    Textures.draw(item.material, mx + camera.x - 20, my + camera.y - 20, 40, 40)
end

function MapBuilder.handleKey(key, action)
    if MapBuilder.handleCtrlShortcut(key) then return true end

    if not ItemBrowser.isOpen then
        if action == "browser" and not paused then
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
    local ctrl = love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")
    if not ctrl then return false end
    if key == "z" then
        MapBuilder.undo()
        if ItemBrowser.isOpen then ItemBrowser.consumeNextText = true end
        return true
    elseif key == "y" then
        MapBuilder.redo()
        if ItemBrowser.isOpen then ItemBrowser.consumeNextText = true end
        return true
    end
    return false
end

function MapBuilder.handleKeyNumberSlot(key)
    local slotNum = key == "0" and 10 or tonumber(key)
    if not slotNum or slotNum < 1 or slotNum > QUICK_ACCESS_COUNT then return false end
    MapBuilder.selectedSlot = slotNum
    return true
end

function MapBuilder.handleItemBrowserKey(key, action)
    if action == "browser" or key == "escape" then
        if key == "escape" and ItemBrowser.searchFocused then
            ItemBrowser.searchFocused = false
            return true
        end
        if action == "browser" and ItemBrowser.searchFocused then
            return true
        end
        ItemBrowser.close()
        ItemBrowser.consumeNextText = true
        return true
    end

    if key == "backspace" then
        if ItemBrowser.searchFocused then
            ItemBrowser.handleKeyPressed("backspace")
        end
        return true
    end

    if key == "space" then
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
    if MapBuilderHUD.isPointerOverHUD(wx, wy) then return end
    local col, row = MapBuilder.screenToGrid(x, y)
    MapBuilder.placeBlock(col, row)
    MapBuilder.lastPlacedCol = col
    MapBuilder.lastPlacedRow = row
    MapBuilder.placeCooldown = MapBuilder.PLACE_INTERVAL
end

function MapBuilder.handleMiddleClick(x, y)
    if MapBuilderHUD.isPointerOverHUD(x + camera.x, y + camera.y) then return end
    MapBuilder.pickBlock(x, y)
end

function MapBuilder.handleGridRemove(x, y)
    local col, row = MapBuilder.screenToGrid(x, y)
    if MapBuilder.removeBlockAtTile(col, row) then
        MapBuilder.lastPlacedCol = col
        MapBuilder.lastPlacedRow = row
        MapBuilder.placeCooldown = MapBuilder.PLACE_INTERVAL
    end
end

function MapBuilder.isPointerOnSaveButton(wx, wy)
    local rect = MapBuilderHUD.getSaveButtonRect()
    return wx >= rect.x and wx <= rect.x + rect.w and wy >= rect.y and wy <= rect.y + rect.h
end

function MapBuilder.isPointerOnRevertButton(wx, wy)
    local rect = MapBuilderHUD.getRevertButtonRect()
    return wx >= rect.x and wx <= rect.x + rect.w and wy >= rect.y and wy <= rect.y + rect.h
end

function MapBuilder.slotIndexAtPosition(wx, wy)
    local rects = MapBuilderHUD.getSlotRects()
    for i, rect in ipairs(rects) do
        if wx >= rect.x and wx <= rect.x + rect.w and wy >= rect.y and wy <= rect.y + rect.h then
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

    if MapBuilder.tryClearSlotOnItemBrowser(wx, wy) then return end
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

function MapBuilder.tryClearSlotOnItemBrowser(wx, wy)
    if not ItemBrowser.isOpen then return false end
    local px = math.floor(scrWidth / 2 - 250 + camera.x)
    local py = math.floor(scrHeight / 2 - 200 + camera.y)
    if wx < px or wx > px + 500 or wy < py or wy > py + 400 then return false end
    MapBuilder.quickAccess[MapBuilder.dragSlot] = nil
    MapBuilder.dragSlot = nil
    return true
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
    love.filesystem.write("map.txt", content)
    MapBuilder.hasUnsavedChanges = false
    MapBuilder.hasSavedFile = true
    Toast.show("Map saved", 1)
end

function MapBuilder.load()
    local content = love.filesystem.read("map.txt")
    if not content then
        grid.grid = {}
        grid.objects = {}
        grid.blockRecords = {}
        grid.objectRecords = {}
        print("Map file not found")
        return
    end
    grid:loadData(content)
    MapBuilder.hasUnsavedChanges = false
    MapBuilder.hasSavedFile = true
    print("Map loaded: " .. (#grid.blockRecords + #grid.objectRecords) .. " blocks")
end

return MapBuilder
