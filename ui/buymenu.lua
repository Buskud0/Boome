local BuyMenu = {}

local PANEL_WIDTH = 420
local OPTION_HEIGHT = 36
local OPTION_GAP = 50
local TITLE_OFFSET_Y = 10
local MONEY_OFFSET_Y = 48
local OPTIONS_OFFSET_Y = 85

local isOpen = false
local selection = 1
local optionRects = {}
local sortedWeapons = {}
local lastMouseX = -1
local lastMouseY = -1
local useMouseSelection = true

function BuyMenu.open()
    ignoreMouseUntilRelease = true
    sortedWeapons = buildAllWeaponsSorted()
    isOpen = true
    selection = 1
    optionRects = {}
    useMouseSelection = true
    lastMouseX = -1
    lastMouseY = -1
end

function buildAllWeaponsSorted()
    local all = {}
    for model in pairs(WEAPONS) do
        table.insert(all, model)
    end
    table.sort(all, function(a, b)
        return WEAPONS[a].price < WEAPONS[b].price
    end)
    return all
end

function playerHasWeapon(model)
    for _, weapon in ipairs(weapons) do
        if weapon.model == model then return true end
    end
    return false
end

function BuyMenu.close()
    isOpen = false
    optionRects = {}
    sortedWeapons = {}
end

function BuyMenu.isOpen()
    return isOpen
end

function BuyMenu.toggle()
    if isOpen then BuyMenu.close() else BuyMenu.open() end
end

function BuyMenu.handleAction(action)
    if action == "menu_up" then
        useMouseSelection = false
        selection = selection - 1
        if selection < 1 then selection = #sortedWeapons end
    elseif action == "menu_down" then
        useMouseSelection = false
        selection = selection + 1
        if selection > #sortedWeapons then selection = 1 end
    elseif action == "menu_confirm" then
        BuyMenu:confirmPurchase()
    end
end

function BuyMenu.wheelmoved(direction)
    if direction > 0 then
        selection = selection - 1
        if selection < 1 then selection = #sortedWeapons end
    elseif direction < 0 then
        selection = selection + 1
        if selection > #sortedWeapons then selection = 1 end
    end
end

function BuyMenu:confirmPurchase()
    local model = sortedWeapons[selection]
    if not model or playerHasWeapon(model) then return end
    if #weapons >= 5 then
        Toast.show("Inventory full!", 2)
        return
    end
    local stats = WEAPONS[model]
    if player.money >= stats.price then
        player.money = player.money - stats.price
        table.insert(weapons, Weapon(model))
        currentWeaponIndex = #weapons
    end
end

function BuyMenu.mousepressed(worldX, worldY)
    for i, rect in ipairs(optionRects) do
        if worldX >= rect.x and worldX <= rect.x + rect.w and
           worldY >= rect.y and worldY <= rect.y + rect.h then
            selection = i
            BuyMenu:confirmPurchase()
            return
        end
    end
    BuyMenu.close()
end

function BuyMenu.draw()
    if not isOpen then return end

    optionRects = {}
    local optionCount = #sortedWeapons
    local panelHeight = OPTIONS_OFFSET_Y + optionCount * OPTION_GAP + 16
    local px = math.floor(scrWidth / 2 - PANEL_WIDTH / 2 + camera.x)
    local py = math.floor(scrHeight / 2 - panelHeight / 2 + camera.y)

    local mouseX = love.mouse.getX() + camera.x
    local mouseY = love.mouse.getY() + camera.y
    local mouseMoved = mouseX ~= lastMouseX or mouseY ~= lastMouseY
    if mouseMoved then
        lastMouseX = mouseX
        lastMouseY = mouseY
    end

    drawPanel(px, py, panelHeight)
    drawTitle(px, py)
    drawMoney(px, py)
    drawWeaponOptions(px, py, mouseX, mouseY, mouseMoved)
end

function drawPanel(px, py, panelHeight)
    love.graphics.setColor(0.15, 0.15, 0.15, 0.95)
    love.graphics.rectangle("fill", px, py, PANEL_WIDTH, panelHeight)
    love.graphics.setColor(0.4, 0.4, 0.4)
    love.graphics.rectangle("line", px, py, PANEL_WIDTH, panelHeight)
end

function drawTitle(px, py)
    local font = love.graphics.newFont("fonts/Gamer.ttf", 36)
    love.graphics.setFont(font)
    love.graphics.setColor(1, 1, 1)
    local title = "WEAPON SHOP"
    local titleW = font:getWidth(title)
    love.graphics.print(title, px + PANEL_WIDTH / 2 - titleW / 2, py + TITLE_OFFSET_Y)
end

function drawMoney(px, py)
    local font = love.graphics.newFont("fonts/Gamer.ttf", 20)
    love.graphics.setFont(font)
    love.graphics.setColor(1, 0.8, 0.2)
    local text = "$" .. player.money
    local textW = font:getWidth(text)
    love.graphics.print(text, px + PANEL_WIDTH / 2 - textW / 2, py + MONEY_OFFSET_Y)
end

function drawWeaponOption(px, optionY, i, model, mouseX, mouseY, mouseMoved)
    local stats = WEAPONS[model]
    local isOwned = playerHasWeapon(model)
    local canAfford = player.money >= stats.price
    local rect = { x = px + 15, y = optionY, w = PANEL_WIDTH - 30, h = OPTION_HEIGHT }

    table.insert(optionRects, rect)

    if mouseMoved and useMouseSelection then
        updateHover(rect, mouseX, mouseY, i)
    end

    if i == selection then
        love.graphics.setColor(0.3, 0.5, 0.7)
        love.graphics.rectangle("fill", rect.x, rect.y, rect.w, rect.h)
    end

    if isOwned then
        love.graphics.setColor(0.4, 0.4, 0.4)
    else
        love.graphics.setColor(1, 1, 1)
    end
    Textures.draw("slot_" .. model, rect.x + 4, rect.y + 4, 28, 28)

    local font = love.graphics.newFont("fonts/Gamer.ttf", 22)
    love.graphics.setFont(font)
    love.graphics.print(model, rect.x + 40, optionY + 6)

    local smallFont = love.graphics.newFont("fonts/Gamer.ttf", 18)
    love.graphics.setFont(smallFont)
    if isOwned then
        love.graphics.setColor(0.4, 0.4, 0.4)
        love.graphics.print("OWNED", rect.x + rect.w - 80, optionY + 8)
    elseif canAfford then
        love.graphics.setColor(1, 0.8, 0.2)
        love.graphics.print("$" .. stats.price, rect.x + rect.w - 74, optionY + 8)
    else
        love.graphics.setColor(0.8, 0.3, 0.3)
        love.graphics.print("$" .. stats.price, rect.x + rect.w - 74, optionY + 8)
    end
end

function drawWeaponOptions(px, py, mouseX, mouseY, mouseMoved)
    local optionY = py + OPTIONS_OFFSET_Y

    for i, model in ipairs(sortedWeapons) do
        drawWeaponOption(px, optionY, i, model, mouseX, mouseY, mouseMoved)
        optionY = optionY + OPTION_GAP
    end
end

function updateHover(rect, mouseX, mouseY, index)
    if mouseX >= rect.x and mouseX <= rect.x + rect.w and
       mouseY >= rect.y and mouseY <= rect.y + rect.h then
        selection = index
    end
end

return BuyMenu
