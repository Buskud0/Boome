--bullets slow down zombies when hit
--add more different kinds of zombies
--work on the menu

require "conf"
require "core.config"
Object = require "lib.classic"
Input = require "core.input"
Textures = require "core.textures"
require "entities.entity"
require "entities.player"
require "entities.bullet"
require "entities.zombie"
require "ui.damagetext"
require "systems.weapon"
require "ui.menu"
require "core.grid"
require "entities.PowerUp"
Collisions = require "core.collisions"
HUD = require "ui.hud"
Horde = require "gamemodes.horde"
MapBuilder = require "gamemodes.mapbuilder"
Inventory = require "ui.inventory"
BuyMenu = require "ui.buymenu"
MapBuilderHUD = require "ui.mapbuilder_hud"
ItemBrowser = require "ui.item_browser"
Toast = require "ui.toast"

gameMode = "horde"
ignoreMouseUntilRelease = false
debugDraw = false

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

function love.load()
    scrWidth, scrHeight = love.graphics.getDimensions()
    love.graphics.setBackgroundColor(0.6, 0.6, 0.6)
    Horde.loadScoreRecord()
    loadCursor()
    Input.load()
    Textures.load("images/block_spritesheet.png", 40)
    Textures.define("empty", 1)
    Textures.define("dirt", 2)
    Textures.define("grass", 3)
    Textures.define("shop", 4)
    Textures.define("stone", 5)
    Textures.define("rock_path", 6)
    Textures.define("water", 7)
    Textures.define("wood_wall", 8)
    Textures.load("images/object_spritesheet.png", 40)
    Textures.define("toxic_barrel", 1)
    Textures.define("barrel", 2)
    Textures.define("bush", 3)
    Textures.define("tree", 4)
    Textures.load("images/entity_spritesheet.png", 40)
    Textures.define("player", 1)
    Textures.define("zombie_normal", 2)
    Textures.define("zombie_heavy", 3)
    Textures.define("zombie_light", 4)
    Textures.define("bullet", 5)
    Textures.define("powerup_health", 6)
    Textures.define("powerup_money", 7)
    Textures.load("images/item_spritesheet.png", 40)
    Inventory.load()
    resetGame()
    MapBuilder.load()
end

function resetGame()
    mapWidth = MAP_WIDTH
    mapHeight = MAP_HEIGHT
    killCount = 0
    currentWeaponIndex = 1
    gameMode = "horde"
    Horde.reset()
    camera = {x=0, y=0, zoom=1}
    grid = Grid()
    MapBuilder.load()
    menu = Menu()
    player = Player(mapWidth/2 - 20, mapHeight/2 - 20)
    bullets = {}
    zombies = {}
    weapons = {}
    damageTexts = {}
    powerUps = {}
    table.insert(weapons, Weapon("M9"))
    paused = false
    BuyMenu.close()
end

function tryMove(entity, dx, dy, constrainToMap)
    if constrainToMap == nil then constrainToMap = true end
    local cx, cy = entity:getCenter()
    local r = entity.radius
    local newX = entity.x + dx
    local newY = entity.y + dy

    if not grid:isCircleBlocked(newX + entity.width / 2, cy, r) and (not constrainToMap or (newX >= 0 and newX <= mapWidth - entity.width)) then
        entity.x = newX
        cx = newX + entity.width / 2
    end
    if not grid:isCircleBlocked(cx, newY + entity.height / 2, r) and (not constrainToMap or (newY >= 0 and newY <= mapHeight - entity.height)) then
        entity.y = newY
    end
    resolveStuck(entity)
end

function resolveStuck(entity)
    if entity.x < 0 then entity.x = 0
    elseif entity.x > mapWidth - entity.width then entity.x = mapWidth - entity.width end
    if entity.y < 0 then entity.y = 0
    elseif entity.y > mapHeight - entity.height then entity.y = mapHeight - entity.height end

    local cx, cy = entity:getCenter()
    local r = entity.radius
    if not grid:isCircleBlocked(cx, cy, r) then return end

    local maxOffset = math.max(grid.tileSize, math.ceil(r))
    for offset = 1, maxOffset do
        if not grid:isCircleBlocked(cx + offset, cy, r) then
            entity.x = entity.x + offset
            break
        elseif not grid:isCircleBlocked(cx - offset, cy, r) then
            entity.x = entity.x - offset
            break
        elseif not grid:isCircleBlocked(cx, cy + offset, r) then
            entity.y = entity.y + offset
            break
        elseif not grid:isCircleBlocked(cx, cy - offset, r) then
            entity.y = entity.y - offset
            break
        end
    end
end

function love.update(dt)
    if not paused then
        if gameMode == "horde" then
            Horde.mainUpdate(dt)
        elseif gameMode == "mapbuilder" then
            MapBuilder.update(dt)
        end
    end
    Toast.update(dt)
    menu:update(dt)
end

function love.draw()
    love.graphics.translate(-camera.x, -camera.y)

    if gameMode == "horde" then
        Horde.draw()
    elseif gameMode == "mapbuilder" then
        MapBuilder.draw()
    end

    if debugDraw then grid:debugDraw() end
    if paused then menu:draw() end
    Toast.draw()
end

function love.keypressed(key)
    if key == "f3" then debugDraw = not debugDraw; return end
    if key == "f2" and gameMode == "horde" then
        local mx, my = love.mouse.getPosition()
        local zombie = Zombie("normal", mx + camera.x, my + camera.y)
        resolveStuck(zombie)
        table.insert(zombies, zombie)
        return
    end

    local action = Input.getActionForKey(key)

    if gameMode == "mapbuilder" and MapBuilder.handleKey(key, action) then
        return
    end

    if action == "pause" then
        if BuyMenu.isOpen() then
            BuyMenu.close()
        elseif menu:isOpen() then
            menu:closeSubmenu()
            paused = menu:isOpen()
        else
            menu:openSubmenu("main")
            paused = menu:isOpen()
        end
    elseif action == "buy" then
        if not menu:isOpen() and gameMode == "horde" then
            BuyMenu.toggle()
        end
    elseif menu:isOpen() then
        menu:handleAction(action)
        paused = menu:isOpen()
    elseif BuyMenu.isOpen() then
        BuyMenu.handleAction(action)
    elseif gameMode == "horde" then
        Horde.handleKey(key, action)
    end
    updateCursor()
end

function love.mousepressed(x, y, button)
    if button == 1 and menu:isOpen() then
        menu:mousepressed(x + camera.x, y + camera.y)
        paused = menu:isOpen()
    elseif button == 1 and BuyMenu.isOpen() then
        BuyMenu.mousepressed(x + camera.x, y + camera.y)
    elseif gameMode == "horde" then
        Inventory.mousepressed(x + camera.x, y + camera.y, button)
    elseif gameMode == "mapbuilder" then
        MapBuilder.handleClick(x, y, button)
    end
    updateCursor()
end

function love.mousereleased(x, y, button)
    ignoreMouseUntilRelease = false
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
    if gameMode == "mapbuilder" then
        MapBuilder.handleWheel(y)
        return
    end
    if BuyMenu.isOpen() then
        BuyMenu.wheelmoved(y)
        return
    end
    if y > 0 then
        Horde.cycleWeapon(-1)
    elseif y < 0 then
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
    camera.zoom = 1
end

function randNegPos(number)
    local number = number or 1
    return number * (math.random(0, 1) == 0 and -1 or 1)
end
