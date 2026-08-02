local BuyMenu = {}

local PANEL_WIDTH = BUYMENU_PANEL_WIDTH
local OPTION_HEIGHT = BUYMENU_OPTION_HEIGHT
local OPTION_GAP = BUYMENU_OPTION_GAP
local TITLE_OFFSET_Y = BUYMENU_TITLE_OFFSET_Y
local MONEY_OFFSET_Y = BUYMENU_MONEY_OFFSET_Y
local OPTIONS_OFFSET_Y = BUYMENU_OPTIONS_OFFSET_Y

local isOpen = false
local selection = 1
local optionRects = {}
local sortedWeapons = {}
local lastMouseX = -1
local lastMouseY = -1
local useMouseSelection = true

local function getWeaponsSortedByPrice()
    local all = {}
    for model, stats in pairs(WEAPONS) do
        if not stats.hidden then
            table.insert(all, model)
        end
    end
    table.sort(all, function(a, b)
        return WEAPONS[a].price < WEAPONS[b].price
    end)
    return all
end

local function playerHasWeapon(model)
    for i = 1, Inventory.MAX_SLOTS do
        local weapon = weapons[i]
        if weapon and weapon.model == model then return true end
    end
    return false
end

local function canAffordWeapon(model)
    return player.money >= WEAPONS[model].price
end

local function wrapSelection(index)
    if index < 1 then return #sortedWeapons end
    if index > #sortedWeapons then return 1 end
    return index
end

local function isPointInRect(x, y, rect)
    return x >= rect.x and x <= rect.x + rect.w and
           y >= rect.y and y <= rect.y + rect.h
end

local function buyWeapon(model)
    player.money = player.money - WEAPONS[model].price
    local slot = Inventory.findFirstEmptySlot()
    if not slot then return end
    weapons[slot] = Weapon.create(model)
    if slot <= Inventory.HOTBAR_SLOTS then
        currentWeaponIndex = slot
    end
end

local function getMouseSelectionState()
    local mouseX = love.mouse.getX() + camera.x
    local mouseY = love.mouse.getY() + camera.y
    local mouseMoved = mouseX ~= lastMouseX or mouseY ~= lastMouseY
    if mouseMoved then
        lastMouseX = mouseX
        lastMouseY = mouseY
    end
    return mouseX, mouseY, mouseMoved
end

local function updateHover(rect, mouseX, mouseY, index)
    if isPointInRect(mouseX, mouseY, rect) then
        selection = index
    end
end

local function drawPanel(px, py, panelHeight)
    love.graphics.setColor(0.15, 0.15, 0.15, 0.95)
    love.graphics.rectangle("fill", px, py, PANEL_WIDTH, panelHeight)
    love.graphics.setColor(0.4, 0.4, 0.4)
    love.graphics.rectangle("line", px, py, PANEL_WIDTH, panelHeight)
end

local function drawTitle(px, py)
    local font = Fonts.get(36)
    love.graphics.setFont(font)
    love.graphics.setColor(1, 1, 1)
    local title = "WEAPON SHOP"
    local titleW = font:getWidth(title)
    love.graphics.print(title, px + PANEL_WIDTH / 2 - titleW / 2, py + TITLE_OFFSET_Y)
end

local function drawMoney(px, py)
    local font = Fonts.get(20)
    love.graphics.setFont(font)
    love.graphics.setColor(1, 0.8, 0.2)
    local text = "$" .. player.money
    local textW = font:getWidth(text)
    love.graphics.print(text, px + PANEL_WIDTH / 2 - textW / 2, py + MONEY_OFFSET_Y)
end

local function drawSelectionHighlight(rect, index)
    if index == selection then
        love.graphics.setColor(0.3, 0.5, 0.7)
        love.graphics.rectangle("fill", rect.x, rect.y, rect.w, rect.h)
    end
end

local function drawWeaponIcon(rect, model)
    local alpha = playerHasWeapon(model) and 0.4 or 1
    Textures.draw("slot_" .. model, rect.x + 4, rect.y + 4, 28, 28, alpha)
end

local function drawWeaponName(rect, model)
    local font = Fonts.get(22)
    love.graphics.setFont(font)
    love.graphics.print(model, rect.x + 40, rect.y + 6)
end

local function drawWeaponPrice(rect, model)
    if canAffordWeapon(model) then
        love.graphics.setColor(1, 0.8, 0.2)
    else
        love.graphics.setColor(0.8, 0.3, 0.3)
    end
    love.graphics.print("$" .. WEAPONS[model].price, rect.x + rect.w - 74, rect.y + 8)
end

local function drawWeaponStatus(rect, model)
    local font = Fonts.get(18)
    love.graphics.setFont(font)
    if playerHasWeapon(model) then
        love.graphics.setColor(0.4, 0.4, 0.4)
        love.graphics.print("OWNED", rect.x + rect.w - 80, rect.y + 8)
    else
        drawWeaponPrice(rect, model)
    end
end

local function drawWeaponOption(px, optionY, i, model, mouseX, mouseY, mouseMoved)
    local rect = { x = px + 15, y = optionY, w = PANEL_WIDTH - 30, h = OPTION_HEIGHT }
    table.insert(optionRects, rect)

    if mouseMoved and useMouseSelection then
        updateHover(rect, mouseX, mouseY, i)
    end

    drawSelectionHighlight(rect, i)
    drawWeaponIcon(rect, model)
    drawWeaponName(rect, model)
    drawWeaponStatus(rect, model)
end

local function drawWeaponOptions(px, py, mouseX, mouseY, mouseMoved)
    local optionY = py + OPTIONS_OFFSET_Y
    for i, model in ipairs(sortedWeapons) do
        drawWeaponOption(px, optionY, i, model, mouseX, mouseY, mouseMoved)
        optionY = optionY + OPTION_GAP
    end
end

function BuyMenu.open()
    ignoreMouseUntilRelease = true
    sortedWeapons = getWeaponsSortedByPrice()
    isOpen = true
    selection = 1
    optionRects = {}
    useMouseSelection = true
    lastMouseX = -1
    lastMouseY = -1
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
        selection = wrapSelection(selection - 1)
    elseif action == "menu_down" then
        useMouseSelection = false
        selection = wrapSelection(selection + 1)
    elseif action == "menu_confirm" then
        BuyMenu:confirmPurchase()
    end
end

function BuyMenu.wheelmoved(direction)
    if direction > 0 then
        selection = wrapSelection(selection - 1)
    elseif direction < 0 then
        selection = wrapSelection(selection + 1)
    end
end

function BuyMenu:confirmPurchase()
    local model = sortedWeapons[selection]
    if not model or playerHasWeapon(model) then return end
    if not Inventory.findFirstEmptySlot() then
        Toast.show("Inventory full!", 2)
        return
    end
    if canAffordWeapon(model) then
        buyWeapon(model)
    end
end

function BuyMenu.mousepressed(worldX, worldY)
    for i, rect in ipairs(optionRects) do
        if isPointInRect(worldX, worldY, rect) then
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

    local mouseX, mouseY, mouseMoved = getMouseSelectionState()
    drawPanel(px, py, panelHeight)
    drawTitle(px, py)
    drawMoney(px, py)
    drawWeaponOptions(px, py, mouseX, mouseY, mouseMoved)
end

return BuyMenu
