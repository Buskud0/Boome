require "conf"
require "core.config"
Object = require "lib.classic"
Input = require "core.input"
Textures = require "core.textures"
Fonts = require "core.fonts"
require "entities.entity"
require "entities.player"
require "entities.bullet"
require "entities.zombie"
require "entities.damage_text"
require "systems.weapon"
require "systems.melee"
require "ui.menu"
require "world.grid"
require "entities.powerup"
Collisions = require "core.collisions"
HUD = require "ui.hud"
Horde = require "gamemodes.horde"
MapBuilder = require "gamemodes.mapbuilder"
Inventory = require "ui.inventory"
BuyMenu = require "ui.buymenu"
MapBuilderHUD = require "ui.mapbuilder_hud"
ItemBrowser = require "ui.item_browser"
Toast = require "ui.toast"
Debug = require "core.debug"

ignoreMouseUntilRelease = false

function loadCursor()
    local img = love.graphics.newImage("images/crosshair.png")
    local cursorSize = 20
    local canvas = love.graphics.newCanvas(cursorSize, cursorSize)
    love.graphics.setCanvas(canvas)
    love.graphics.draw(img, 0, 0, 0, cursorSize / img:getWidth(), cursorSize / img:getHeight())
    love.graphics.setCanvas()
    local imgData = canvas:newImageData()
    cursor = love.mouse.newCursor(imgData, cursorSize / 2, cursorSize / 2)
    updateCursor()
end

function updateCursor()
    if menu and gameMode == "horde" and not menu:isOpen() and not BuyMenu.isOpen() then
        love.mouse.setCursor(cursor)
    else
        love.mouse.setCursor(love.mouse.getSystemCursor("arrow"))
    end
end

function screenToWorld(sx, sy)
    local cx, cy = scrWidth / 2, scrHeight / 2
    return (sx + camera.x - cx) / camera.zoom + cx,
           (sy + camera.y - cy) / camera.zoom + cy
end

function worldToScreen(wx, wy)
    local cx, cy = scrWidth / 2, scrHeight / 2
    return (wx - cx) * camera.zoom - camera.x + cx,
           (wy - cy) * camera.zoom - camera.y + cy
end

function love.load()
    initializeDisplay()
    Horde.loadScoreRecord()
    loadCursor()
    Input.load()
    Grid.load()
    Entity.load()
    Inventory.load()
    resetGame()
end

function initializeDisplay()
    scrWidth, scrHeight = love.graphics.getDimensions()
    love.graphics.setBackgroundColor(0.6, 0.6, 0.6)
end

function resetGame()
    setWorldConstants()
    Horde.reset()
    resetCamera()
    grid = Grid()
    MapBuilder.load()
    menu = Menu()
    resetPlayer()
    resetEntityLists()
    paused = false
    BuyMenu.close()
end

function setWorldConstants()
    mapWidth = MAP_WIDTH
    mapHeight = MAP_HEIGHT
    killCount = 0
    currentWeaponIndex = 1
    fists = Weapon.create("FISTS")
    HUD.reset()
    gameMode = "horde"
end

function resetCamera()
    camera = { x = 0, y = 0, zoom = HORDE_CAMERA_ZOOM }
end

function resetPlayer()
    player = Player(mapWidth / 2 - 20, mapHeight / 2 - 20)
end

function resetEntityLists()
    bullets = {}
    zombies = {}
    weapons = {}
    damageTexts = {}
    powerUps = {}
end

function tryMove(entity, dx, dy, constrainToMap)
    if constrainToMap == nil then constrainToMap = true end
    local nx, ny = entity.x + dx, entity.y + dy

    if canMoveTo(entity, nx, ny, constrainToMap) then
        setEntityPosition(entity, nx, ny)
        return
    end

    local slideX, slideY = findBestSlidePosition(entity, nx, ny, dx, dy, constrainToMap)
    setEntityPosition(entity, slideX, slideY)
end

function setEntityPosition(entity, x, y)
    entity.x, entity.y = x, y
    resolveStuck(entity)
end

function canMoveTo(entity, x, y, constrainToMap)
    if constrainToMap then
        if x < 0 or x > mapWidth - entity.width then return false end
        if y < 0 or y > mapHeight - entity.height then return false end
    end
    local cx = x + entity.width / 2
    local cy = y + entity.height / 2
    return not grid:isCircleBlocked(cx, cy, entity.radius)
end

function findBestSlidePosition(entity, nx, ny, dx, dy, constrainToMap)
    local bx, by = entity.x, entity.y
    local hx, hy = findHorizontalSlide(entity, bx, by, nx, ny, constrainToMap)
    local vx, vy = findVerticalSlide(entity, bx, by, nx, ny, constrainToMap)
    local slideX, slideY = pickLongerSlide(bx, by, hx, hy, vx, vy)
    return tryCornerNudge(entity, bx, by, nx, ny, dx, dy, slideX, slideY, constrainToMap)
end

function findHorizontalSlide(entity, bx, by, nx, ny, constrainToMap)
    local hx, hy = bx, by
    if canMoveTo(entity, nx, hy, constrainToMap) then hx = nx end
    if canMoveTo(entity, hx, ny, constrainToMap) then hy = ny end
    return hx, hy
end

function findVerticalSlide(entity, bx, by, nx, ny, constrainToMap)
    local vx, vy = bx, by
    if canMoveTo(entity, vx, ny, constrainToMap) then vy = ny end
    if canMoveTo(entity, nx, vy, constrainToMap) then vx = nx end
    return vx, vy
end

function pickLongerSlide(bx, by, hx, hy, vx, vy)
    if math.abs(vx - bx) + math.abs(vy - by) > math.abs(hx - bx) + math.abs(hy - by) then
        return vx, vy
    end
    return hx, hy
end

function tryCornerNudge(entity, bx, by, nx, ny, dx, dy, slideX, slideY, constrainToMap)
    local movedX = slideX ~= bx
    local movedY = slideY ~= by
    if not ((dx ~= 0 and not movedX) or (dy ~= 0 and not movedY)) then
        return slideX, slideY
    end

    if dx ~= 0 and not movedX then
        for _, yn in ipairs({1, -1}) do
            if canMoveTo(entity, nx, by + yn, constrainToMap) then
                return nx, by + yn
            end
        end
    end

    if dy ~= 0 and not movedY then
        for _, xn in ipairs({1, -1}) do
            if canMoveTo(entity, bx + xn, ny, constrainToMap) then
                return bx + xn, ny
            end
        end
    end

    return slideX, slideY
end

function resolveStuck(entity)
    clampEntityToMap(entity)
    if not isEntityStuck(entity) then return end
    local bestX, bestY = findNearestClearCenter(entity)
    if bestX then
        entity.x = bestX - entity.width / 2
        entity.y = bestY - entity.height / 2
    end
end

function clampEntityToMap(entity)
    if entity.x < 0 then entity.x = 0
    elseif entity.x > mapWidth - entity.width then entity.x = mapWidth - entity.width end
    if entity.y < 0 then entity.y = 0
    elseif entity.y > mapHeight - entity.height then entity.y = mapHeight - entity.height end
end

function isEntityStuck(entity)
    local cx, cy = entity:getCenter()
    return grid:isCircleBlocked(cx, cy, entity.radius)
end

function findNearestClearCenter(entity)
    local cx, cy = entity:getCenter()
    local startCol = math.floor(cx / grid.tileSize) + 1
    local startRow = math.floor(cy / grid.tileSize) + 1
    local bestX, bestY, bestDistSq
    local maxRadius = 30

    for radius = 1, maxRadius do
        for row = startRow - radius, startRow + radius do
            for col = startCol - radius, startCol + radius do
                if math.max(math.abs(col - startCol), math.abs(row - startRow)) == radius then
                    if col >= 1 and col <= grid.cols and row >= 1 and row <= grid.rows then
                        local tx = (col - 1) * grid.tileSize + grid.tileSize / 2
                        local ty = (row - 1) * grid.tileSize + grid.tileSize / 2
                        if not grid:isCircleBlocked(tx, ty, entity.radius) then
                            local distSq = (tx - cx) * (tx - cx) + (ty - cy) * (ty - cy)
                            if not bestDistSq or distSq < bestDistSq then
                                bestDistSq = distSq
                                bestX, bestY = tx, ty
                            end
                        end
                    end
                end
            end
        end
        if bestX then break end
    end

    return bestX, bestY
end

function love.update(dt)
    if not paused then
        updateActiveGameMode(dt)
    end
    Toast.update(dt)
end

function updateActiveGameMode(dt)
    if gameMode == "horde" then
        Horde.mainUpdate(dt)
    elseif gameMode == "mapbuilder" then
        MapBuilder.update(dt)
    end
end

function love.draw()
    love.graphics.translate(-camera.x, -camera.y)
    drawActiveGameMode()
    Debug.drawGridOverlay()
    drawScreenSpaceUI()
end

function drawActiveGameMode()
    if gameMode == "horde" then
        Horde.draw()
    elseif gameMode == "mapbuilder" then
        MapBuilder.draw()
    end
end

function drawScreenSpaceUI()
    if paused then menu:draw() end
    Toast.draw()
end

function love.keypressed(key)
    if Debug.handleKey(key) then return end
    if handleDebugSpawn(key) then return end

    local action = Input.getActionForKey(key)
    if handleGameModeKey(key, action) then return end

    handlePlayerAction(action, key)
    updateCursor()
end

function handleDebugSpawn(key)
    if Input.isActionBoundToKey("debug_spawn", key) and gameMode == "horde" then
        spawnZombieAtMouse()
        return true
    end
    return false
end

function spawnZombieAtMouse()
    local wx, wy = screenToWorld(love.mouse.getPosition())
    local zombie = Zombie("normal", wx, wy)
    resolveStuck(zombie)
    table.insert(zombies, zombie)
end

function handleGameModeKey(key, action)
    if gameMode == "mapbuilder" and MapBuilder.handleKey(key, action) then
        return true
    end
    return false
end

function handlePlayerAction(action, key)
    if action == "pause" then
        togglePause()
    elseif action == "buy" then
        toggleBuyMenu()
    else
        handleActiveMenuInput(action, key)
    end
end

function togglePause()
    if BuyMenu.isOpen() then
        BuyMenu.close()
    elseif menu:isOpen() then
        menu:closeSubmenu()
        paused = menu:isOpen()
    else
        menu:openSubmenu("main")
        paused = menu:isOpen()
    end
end

function toggleBuyMenu()
    if not menu:isOpen() and gameMode == "horde" then
        BuyMenu.toggle()
    end
end

function handleActiveMenuInput(action, key)
    if menu:isOpen() then
        menu:handleAction(action)
        paused = menu:isOpen()
    elseif BuyMenu.isOpen() then
        BuyMenu.handleAction(action)
    elseif gameMode == "horde" then
        Horde.handleKey(key, action)
    end
end

function love.mousepressed(x, y, button)
    dispatchMousePressed(x, y, button)
    updateCursor()
end

function dispatchMousePressed(x, y, button)
    if button == 1 and menu:isOpen() then
        ignoreMouseUntilRelease = true
        menu:mousepressed(x + camera.x, y + camera.y)
        paused = menu:isOpen()
    elseif button == 1 and BuyMenu.isOpen() then
        ignoreMouseUntilRelease = true
        BuyMenu.mousepressed(x + camera.x, y + camera.y)
    elseif gameMode == "horde" then
        Inventory.mousepressed(x + camera.x, y + camera.y, button)
    elseif gameMode == "mapbuilder" then
        MapBuilder.handleClick(x, y, button)
    end
end

function love.mousereleased(x, y, button)
    ignoreMouseUntilRelease = false
    dispatchMouseReleased(x, y, button)
end

function dispatchMouseReleased(x, y, button)
    if gameMode == "horde" and not menu:isOpen() and not BuyMenu.isOpen() then
        Inventory.mousereleased(x + camera.x, y + camera.y, button)
    end
    if gameMode == "mapbuilder" then
        MapBuilder.handleMouseRelease(x, y, button)
    end
end

function love.textinput(text)
    if ItemBrowser.consumeNextText then
        ItemBrowser.consumeNextText = false
        return
    end
    if gameMode == "mapbuilder" then
        MapBuilder.handleTextInput(text)
    end
end

function love.wheelmoved(x, y)
    if paused then return end
    dispatchWheel(y)
end

function dispatchWheel(direction)
    if gameMode == "mapbuilder" then
        MapBuilder.handleWheel(direction)
        return
    end
    if BuyMenu.isOpen() then
        BuyMenu.wheelmoved(direction)
        return
    end
    cycleWeaponByWheel(direction)
end

function cycleWeaponByWheel(direction)
    if direction > 0 then
        Horde.cycleWeapon(-1)
    else
        Horde.cycleWeapon(1)
    end
end

function love.quit()
    Horde.saveScoreRecord()
end

function enterMapBuilder()
    ignoreMouseUntilRelease = true
    gameMode = "mapbuilder"
    paused = false
    updateCursor()
    MapBuilder.enter()
end

function enterHordeMode()
    ignoreMouseUntilRelease = true
    gameMode = "horde"
    updateCursor()
    resetCamera()
end

function randNegPos(number)
    local number = number or 1
    return number * (math.random() * 2 - 1)
end
