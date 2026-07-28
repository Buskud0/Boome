local MapBuilder = {}

local PAN_SPEED = 300
local ZOOM_MIN = 0.1
local ZOOM_MAX = 10
local ZOOM_FACTOR = 1.1
local QUICK_ACCESS_COUNT = 10
MapBuilder.QUICK_ACCESS_COUNT = QUICK_ACCESS_COUNT
local PLACE_INTERVAL = 0.08
MapBuilder.PLACE_INTERVAL = PLACE_INTERVAL

MapBuilder.quickAccess = {}
MapBuilder.selectedSlot = 1
MapBuilder.hasUnsavedChanges = false
MapBuilder.undoStack = {}
MapBuilder.redoStack = {}
MapBuilder.hasSavedFile = false
MapBuilder.placeCooldown = 0
MapBuilder.lastPlacedCol = 0
MapBuilder.lastPlacedRow = 0

local MAX_UNDO = 100

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
        MapBuilder.removeBlock(col, row)
    else
        MapBuilder.placeBlock(col, row)
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

function MapBuilder.screenToGrid(screenX, screenY)
    local tileSize = Textures.getTileSize()
    local worldX = (screenX + camera.x) / camera.zoom
    local worldY = (screenY + camera.y) / camera.zoom
    return math.floor(worldX / tileSize) + 1, math.floor(worldY / tileSize) + 1
end

function MapBuilder.placeBlock(col, row)
    if col < 1 or col > grid.cols or row < 1 or row > grid.rows then return false end
    local selectedItem = MapBuilder.quickAccess[MapBuilder.selectedSlot]
    if not selectedItem or grid.grid[(row-1) * grid.cols + col] then return false end
    grid:colorTile(selectedItem.material, col, row)
    MapBuilder.pushAction({ col = col, row = row, newMaterial = selectedItem.material, oldMaterial = nil })
    MapBuilder.hasUnsavedChanges = true
    return true
end

function MapBuilder.removeBlock(col, row)
    if col < 1 or col > grid.cols or row < 1 or row > grid.rows then return false end
    local oldMaterial = grid.grid[(row-1) * grid.cols + col]
    if not oldMaterial then return false end
    grid:clearTile(col, row)
    MapBuilder.pushAction({ col = col, row = row, newMaterial = nil, oldMaterial = oldMaterial })
    MapBuilder.hasUnsavedChanges = true
    return true
end

function MapBuilder.pushAction(action)
    table.insert(MapBuilder.undoStack, action)
    if #MapBuilder.undoStack > MAX_UNDO then
        table.remove(MapBuilder.undoStack, 1)
    end
    MapBuilder.redoStack = {}
end

function MapBuilder.undo()
    local action = MapBuilder.undoStack[#MapBuilder.undoStack]
    if not action then return end
    table.remove(MapBuilder.undoStack)

    if action.oldMaterial then
        grid:colorTile(action.oldMaterial, action.col, action.row)
    else
        grid:clearTile(action.col, action.row)
    end

    table.insert(MapBuilder.redoStack, action)
    MapBuilder.hasUnsavedChanges = true
end

function MapBuilder.redo()
    local action = MapBuilder.redoStack[#MapBuilder.redoStack]
    if not action then return end
    table.remove(MapBuilder.redoStack)

    if action.newMaterial then
        grid:colorTile(action.newMaterial, action.col, action.row)
    else
        grid:clearTile(action.col, action.row)
    end

    table.insert(MapBuilder.undoStack, action)
    MapBuilder.hasUnsavedChanges = true
end

function MapBuilder.revert()
    if not MapBuilder.hasUnsavedChanges or not MapBuilder.hasSavedFile then return end
    MapBuilder.load()
    MapBuilder.undoStack = {}
    MapBuilder.redoStack = {}
end

function MapBuilder.drawBackground()
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", 0, 0, mapWidth, mapHeight)
    grid:draw()
end

function MapBuilder.drawGridLines(tileSize)
    love.graphics.setColor(0.25, 0.25, 0.25)
    for x = 0, mapWidth, tileSize do
        love.graphics.line(x, 0, x, mapHeight)
    end
    for y = 0, mapHeight, tileSize do
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
    love.graphics.rectangle("fill", (col - 1) * tileSize, (row - 1) * tileSize, tileSize, tileSize)
end

function MapBuilder.draw()
    love.graphics.push()
    love.graphics.scale(camera.zoom)
    MapBuilder.drawBackground()
    local tileSize = Textures.getTileSize()
    MapBuilder.drawGridLines(tileSize)
    MapBuilder.drawHoverIndicator(tileSize)
    love.graphics.pop()
    if ItemBrowser.isOpen then
        ItemBrowser.draw()
    end
    MapBuilderHUD.draw()
end

function MapBuilder.handleKey(key, action)
    local ctrl = love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")
    if ctrl then
        if key == "z" then
            MapBuilder.undo()
            if ItemBrowser.isOpen then ItemBrowser.consumeNextText = true end
            return true
        elseif key == "y" then
            MapBuilder.redo()
            if ItemBrowser.isOpen then ItemBrowser.consumeNextText = true end
            return true
        end
    end

    if not ItemBrowser.isOpen then
        if action == "browser" and not paused then
            ItemBrowser.toggle()
            ItemBrowser.consumeNextText = true
            return true
        end

        local slot = tonumber(key)
        if slot and slot >= 1 and slot <= QUICK_ACCESS_COUNT then
            MapBuilder.selectedSlot = slot
            return true
        end

        return false
    end

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

    if ItemBrowser.isOpen then
        if button == 1 then
            ItemBrowser.mousepressed(wx, wy)
        end
        return
    end

    if button == 1 then
        local saveRect = MapBuilderHUD.getSaveButtonRect()
        if wx >= saveRect.x and wx <= saveRect.x + saveRect.w and
           wy >= saveRect.y and wy <= saveRect.y + saveRect.h then
            MapBuilder.save()
            return
        end

        local revertRect = MapBuilderHUD.getRevertButtonRect()
        if wx >= revertRect.x and wx <= revertRect.x + revertRect.w and
           wy >= revertRect.y and wy <= revertRect.y + revertRect.h then
            MapBuilder.revert()
            return
        end

        local slotRects = MapBuilderHUD.getSlotRects()
        for i, rect in ipairs(slotRects) do
            if wx >= rect.x and wx <= rect.x + rect.w and
               wy >= rect.y and wy <= rect.y + rect.h then
                MapBuilder.selectedSlot = i
                return
            end
        end

        local col, row = MapBuilder.screenToGrid(x, y)
        if MapBuilder.removeBlock(col, row) then
            MapBuilder.lastPlacedCol = col
            MapBuilder.lastPlacedRow = row
            MapBuilder.placeCooldown = MapBuilder.PLACE_INTERVAL
        end
    elseif button == 2 then
        if MapBuilderHUD.isPointerOverHUD(wx, wy) then return end
        local col, row = MapBuilder.screenToGrid(x, y)
        if MapBuilder.placeBlock(col, row) then
            MapBuilder.lastPlacedCol = col
            MapBuilder.lastPlacedRow = row
            MapBuilder.placeCooldown = MapBuilder.PLACE_INTERVAL
        end
    end
end

function MapBuilder.handleMouseRelease(x, y, button)
    if button == 1 and ItemBrowser.isOpen then
        ItemBrowser.mousereleased(x + camera.x, y + camera.y)
    end
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
    local data = {}
    for y = 1, grid.cols do
        for x = 1, grid.rows do
            local i = (y - 1) * grid.cols + x
            if grid.grid[i] then
                table.insert(data, x .. "," .. y .. "," .. grid.grid[i])
            end
        end
    end
    local content = table.concat(data, "\n")
    love.filesystem.write("map.txt", content)
    MapBuilder.hasUnsavedChanges = false
    MapBuilder.hasSavedFile = true
    print("Map saved: " .. #data .. " blocks")
end

function MapBuilder.load()
    local content = love.filesystem.read("map.txt")
    if not content then return end

    grid.grid = {}
    for line in content:gmatch("[^\r\n]+") do
        local x, y, material = line:match("^(%d+),(%d+),(%S+)$")
        if x and y and material then
            grid:colorTile(material, tonumber(x), tonumber(y))
        end
    end
    MapBuilder.hasUnsavedChanges = false
    MapBuilder.hasSavedFile = true
    print("Map loaded")
end

return MapBuilder
