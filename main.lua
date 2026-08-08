-- Thin boot: creates a GameState, attaches the state-injected singletons and
-- dispatches LÖVE callbacks to the active game mode. No globals.

require "conf"

local Input = require "core.input"
local GameState = require "core.game_state"
local Coordinates = require "core.coordinates"
local MapStorage = require "core.storage.mapstorage"
local ScoreStorage = require "core.storage.scorestorage"
local Debug = require "core.debug"

local Entity = require "entities.entity"
local Zombie = require "entities.zombie"
local Movement = require "world.physics.movement"
local Grid = require "world.grid.grid"
local Inventory = require "ui.inventory"
local BuyMenu = require "ui.buymenu"
local CraftMenu = require "ui.craftmenu"
local MapSelect = require "ui.map_select"
local MapBuilderHUD = require "ui.mapbuilder_hud"
local ItemBrowser = require "ui.item_browser"
local Toast = require "ui.toast"
local HUD = require "ui.hud"
local Horde = require "gamemodes.horde.horde"
local MapBuilder = require "gamemodes.mapbuilder.mapbuilder"
local Interact = require "world.physics.interact"

local state
local cursor

-------------------------------- cursor ---------------------------------

local function loadCursor()
    local img = love.graphics.newImage("images/crosshair.png")
    local cursorSize = 20
    local canvas = love.graphics.newCanvas(cursorSize, cursorSize)
    love.graphics.setCanvas(canvas)
    love.graphics.draw(img, 0, 0, 0, cursorSize / img:getWidth(), cursorSize / img:getHeight())
    love.graphics.setCanvas()
    local imgData = canvas:newImageData()
    cursor = love.mouse.newCursor(imgData, cursorSize / 2, cursorSize / 2)
end

local function updateCursor()
    if not state or not state.menu then
        love.mouse.setCursor(love.mouse.getSystemCursor("arrow"))
        return
    end
    if state.gameMode == "horde" and not state.menu:isOpen() and not state.buyMenu.isOpen and not state.craftMenu.isOpen then
        love.mouse.setCursor(cursor)
    else
        love.mouse.setCursor(love.mouse.getSystemCursor("arrow"))
    end
end

-------------------------------- boot ---------------------------------

function setupMapStorage()
    if #MapStorage.listMaps() == 0 then
        if not MapStorage.migrateLegacyMap("default") then
            MapStorage.saveMap("default", "")
        end
    end
    local stored = MapStorage.getSelectedMap()
    if stored and MapStorage.mapExists(stored) then
        state.selectedMapName = stored
    else
        state.selectedMapName = MapStorage.listMaps()[1] or "default"
        MapStorage.setSelectedMap(state.selectedMapName)
    end
end

function love.load()
    state = GameState.new()
    state.scrWidth, state.scrHeight = love.graphics.getDimensions()
    love.graphics.setBackgroundColor(0.6, 0.6, 0.6)

    Input.load()
    Grid.load()
    Entity.load()
    Inventory.load()
    loadCursor()

    state.toast = Toast.new(state)
    state.hud = HUD.new(state)
    state.inventory = Inventory.new(state)
    state.buyMenu = BuyMenu.new(state)
    state.craftMenu = CraftMenu.new(state)
    state.mapBuilderHUD = MapBuilderHUD.new(state)
    state.itemBrowser = ItemBrowser.new(state)
    state.mapBuilder = MapBuilder.new(state)
    state.mapSelect = MapSelect.new(state)
    state.horde = Horde.new(state)

    state.enterMapSelect = function(mode) enterMapSelect(mode) end
    state.leaveMapSelect = function() leaveMapSelect() end
    state.enterBuilderWith = function(name) enterBuilderWith(name) end
    state.startHordeWith = function(name) startHordeWith(name) end

    setupMapStorage()
    state:reset()
    updateCursor()
end

-------------------------------- update ---------------------------------

function love.update(dt)
    if not state.paused then
        updateActiveGameMode(dt)
    end
    state.toast:update(dt)
end

function updateActiveGameMode(dt)
    if state.gameMode == "horde" then
        state.horde:mainUpdate(dt)
    elseif state.gameMode == "mapbuilder" then
        state.mapBuilder:update(dt)
    end
end

function drawActiveGameMode()
    if state.gameMode == "horde" then
        state.horde:draw()
    elseif state.gameMode == "mapbuilder" then
        state.mapBuilder:draw()
    elseif state.gameMode == "select" then
        state.mapSelect:draw()
    end
end

function love.draw()
    love.graphics.translate(-state.camera.x, -state.camera.y)
    drawActiveGameMode()
    Debug.drawGridOverlay(state)
    drawScreenSpaceUI()
end

function drawScreenSpaceUI()
    if state.paused and state.menu then state.menu:draw() end
    state.toast:draw()
end

-------------------------------- input ---------------------------------

function love.keypressed(key)
    if Debug.handleKey(state, key) then return end
    if handleDebugSpawn(key) then return end
    if handleStopSpawn(key) then return end

    local action = Input.getActionForKey(key)
    if state.gameMode == "select" and state.mapSelect.isOpen then
        if state.mapSelect:handleKey(key, action) then updateCursor() end
        return
    end
    if handleGameModeKey(key, action) then return end

    handlePlayerAction(action, key)
    updateCursor()
end

function handleDebugSpawn(key)
    if Input.isActionBoundToKey("debug_spawn", key) and state.gameMode == "horde" then
        spawnZombieAtMouse()
        return true
    end
    return false
end

function handleStopSpawn(key)
    if Input.isActionBoundToKey("stop_spawn", key) and state.gameMode == "horde" then
        state.horde.spawnEnabled = not state.horde.spawnEnabled
        if state.horde.spawnEnabled then
            state.toast:show("Zombie spawning resumed", 1.5)
        else
            state.toast:show("Zombie spawning stopped", 1.5)
        end
        return true
    end
    return false
end

function spawnZombieAtMouse()
    local wx, wy = Coordinates.screenToWorld(state, love.mouse.getPosition())
    local zombie = Zombie(state, "rotter", wx, wy)
    Movement.resolveStuck(state, zombie)
    table.insert(state.zombies, zombie)
end

function handleGameModeKey(key, action)
    if state.gameMode == "mapbuilder" and state.mapBuilder:handleKey(key, action) then
        return true
    end
    return false
end

function handlePlayerAction(action, key)
    if action == "pause" then
        togglePause()
    else
        handleActiveMenuInput(action, key)
    end
end

function togglePause()
    if state.buyMenu.isOpen then
        state.buyMenu:close()
    elseif state.craftMenu.isOpen then
        state.craftMenu:close()
    elseif state.menu:isOpen() then
        state.menu:closeSubmenu()
        state.paused = state.menu:isOpen()
    else
        state.menu:openSubmenu("main")
        state.paused = state.menu:isOpen()
    end
end

function handleActiveMenuInput(action, key)
    if state.menu:isOpen() then
        state.menu:handleAction(action)
        state.paused = state.menu:isOpen()
    elseif state.buyMenu.isOpen then
        if action == "inventory" or action == "interact" then
            state.buyMenu:close()
        else
            state.buyMenu:handleAction(action)
        end
    elseif state.craftMenu.isOpen then
        if action == "inventory" or action == "interact" then
            state.craftMenu:close()
        else
            state.craftMenu:handleAction(action)
        end
    elseif state.gameMode == "horde" then
        if action == "interact" then
            if state.inventory.isOpen then
                state.inventory:close()
            else
                Interact.activateNearest(state, state.horde)
            end
        else
            state.horde:handleKey(key, action)
        end
    end
end

function love.mousepressed(x, y, button)
    dispatchMousePressed(x, y, button)
    updateCursor()
end

function dispatchMousePressed(x, y, button)
    if state.gameMode == "select" and state.mapSelect.isOpen then
        state.ignoreMouseUntilRelease = true
        state.mapSelect:mousepressed(x, y, button)
    elseif button == 1 and state.menu:isOpen() then
        state.ignoreMouseUntilRelease = true
        state.menu:mousepressed(x + state.camera.x, y + state.camera.y)
        state.paused = state.menu:isOpen()
    elseif button == 1 and state.buyMenu.isOpen then
        state.ignoreMouseUntilRelease = true
        state.buyMenu:mousepressed(x + state.camera.x, y + state.camera.y)
    elseif button == 1 and state.craftMenu.isOpen then
        state.ignoreMouseUntilRelease = true
        if not state.craftMenu:mousepressed(x + state.camera.x, y + state.camera.y) then
            state.inventory:mousepressed(x + state.camera.x, y + state.camera.y, button)
        end
    elseif state.gameMode == "horde" then
        if button == 2 and Interact.tryActivate(state, x, y, state.horde) then return end
        state.inventory:mousepressed(x + state.camera.x, y + state.camera.y, button)
    elseif state.gameMode == "mapbuilder" then
        state.mapBuilder:handleClick(x, y, button)
    end
end

function love.mousereleased(x, y, button)
    state.ignoreMouseUntilRelease = false
    dispatchMouseReleased(x, y, button)
end

function love.mousemoved(x, y, dx, dy)
    if state.buyMenu.isOpen then
        state.buyMenu:mousemoved(x + state.camera.x, y + state.camera.y)
    end
end

function dispatchMouseReleased(x, y, button)
    if state.buyMenu.isOpen then state.buyMenu:mousereleased() end
    if state.gameMode == "horde" and not state.menu:isOpen() and not state.buyMenu.isOpen then
        state.inventory:mousereleased(x + state.camera.x, y + state.camera.y, button)
    end
    if state.gameMode == "mapbuilder" then
        state.mapBuilder:handleMouseRelease(x, y, button)
    end
end

function love.textinput(text)
    if state.gameMode == "select" and state.mapSelect.isOpen then
        state.mapSelect:handleTextInput(text)
        return
    end
    if state.itemBrowser.consumeNextText then
        state.itemBrowser.consumeNextText = false
        return
    end
    if state.gameMode == "mapbuilder" then
        state.mapBuilder:handleTextInput(text)
    end
end

function love.wheelmoved(x, y)
    if state.paused then return end
    dispatchWheel(y)
end

function dispatchWheel(direction)
    if state.gameMode == "mapbuilder" then
        state.mapBuilder:handleWheel(direction)
        return
    end
    if state.buyMenu.isOpen then
        state.buyMenu:wheelmoved(direction)
        return
    end
    if state.craftMenu.isOpen then
        state.craftMenu:wheelmoved(direction)
        return
    end
    if direction > 0 then
        state.horde:cycleWeapon(-1)
    else
        state.horde:cycleWeapon(1)
    end
end

function love.quit()
    if state and state.horde then
        ScoreStorage.save(state.horde.maxRounds, state.horde.maxKills)
    end
end

-------------------------------- mode transitions ---------------------------------

function enterMapSelect(mode)
    state.ignoreMouseUntilRelease = true
    state.mapSelect.previousMode = state.gameMode
    state.gameMode = "select"
    state.paused = false
    state.mapSelect:open(mode)
    updateCursor()
end

function leaveMapSelect()
    state.mapSelect:close()
    state.gameMode = state.mapSelect.previousMode or "horde"
    state.paused = true
    state.menu:openSubmenu("main")
    updateCursor()
end

function enterBuilderWith(mapName)
    state.selectedMapName = mapName
    MapStorage.setSelectedMap(mapName)
    state.mapBuilder.currentMapName = mapName
    state.ignoreMouseUntilRelease = true
    state.gameMode = "mapbuilder"
    state.paused = false
    state.mapBuilder:enter(mapName)
    updateCursor()
end

function startHordeWith(mapName)
    state.selectedMapName = mapName
    MapStorage.setSelectedMap(mapName)
    state.mapBuilder.currentMapName = mapName
    state:reset()
    updateCursor()
end