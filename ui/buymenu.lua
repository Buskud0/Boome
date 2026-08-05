-- Weapon shop menu. State-injected factory.

local Config = require "core.config"
local Fonts = require "core.fonts"
local Textures = require "core.textures"
local WeaponDefs = require "systems.weapon.weapon_defs"

local BuyMenu = {}
BuyMenu.__index = BuyMenu

local PANEL_WIDTH = Config.BUYMENU_PANEL_WIDTH
local OPTION_HEIGHT = Config.BUYMENU_OPTION_HEIGHT
local OPTION_GAP = Config.BUYMENU_OPTION_GAP
local TITLE_OFFSET_Y = Config.BUYMENU_TITLE_OFFSET_Y
local MONEY_OFFSET_Y = Config.BUYMENU_MONEY_OFFSET_Y
local OPTIONS_OFFSET_Y = Config.BUYMENU_OPTIONS_OFFSET_Y

function BuyMenu.new(state)
    local self = setmetatable({}, BuyMenu)
    self.state = state
    self.isOpen = false
    self.selection = 1
    self.optionRects = {}
    self.sortedWeapons = {}
    self.lastMouseX = -1
    self.lastMouseY = -1
    self.useMouseSelection = true
    return self
end

function BuyMenu:getWeaponsSortedByPrice()
    local all = {}
    for model, stats in pairs(Config.WEAPONS) do
        if not stats.hidden then
            table.insert(all, model)
        end
    end
    table.sort(all, function(a, b)
        return Config.WEAPONS[a].price < Config.WEAPONS[b].price
    end)
    return all
end

function BuyMenu:playerHasWeapon(model)
    for i = 1, self.state.inventory.MAX_SLOTS do
        local weapon = self.state.weapons[i]
        if weapon and weapon.model == model then return true end
    end
    return false
end

function BuyMenu:canAffordWeapon(model)
    return self.state.player.money >= Config.WEAPONS[model].price
end

function BuyMenu:wrapSelection(index)
    if index < 1 then return #self.sortedWeapons end
    if index > #self.sortedWeapons then return 1 end
    return index
end

function BuyMenu:buyWeapon(model)
    self.state.player.money = self.state.player.money - Config.WEAPONS[model].price
    local slot = self.state.inventory:findFirstEmptySlot()
    if not slot then return end
    self.state.weapons[slot] = WeaponDefs.create(self.state, model)
    if slot <= self.state.inventory.HOTBAR_SLOTS then
        self.state.currentWeaponIndex = slot
    end
end

function BuyMenu:getMouseSelectionState()
    local camera = self.state.camera
    local mouseX = love.mouse.getX() + camera.x
    local mouseY = love.mouse.getY() + camera.y
    local mouseMoved = mouseX ~= self.lastMouseX or mouseY ~= self.lastMouseY
    if mouseMoved then
        self.lastMouseX = mouseX
        self.lastMouseY = mouseY
    end
    return mouseX, mouseY, mouseMoved
end

function BuyMenu:updateHover(rect, mouseX, mouseY, index)
    if self:isPointInRect(mouseX, mouseY, rect) then
        self.selection = index
    end
end

function BuyMenu:isPointInRect(x, y, rect)
    return x >= rect.x and x <= rect.x + rect.w and y >= rect.y and y <= rect.y + rect.h
end

function BuyMenu:open()
    self.state.ignoreMouseUntilRelease = true
    self.sortedWeapons = self:getWeaponsSortedByPrice()
    self.isOpen = true
    self.selection = 1
    self.optionRects = {}
    self.useMouseSelection = true
    self.lastMouseX = -1
    self.lastMouseY = -1
end

function BuyMenu:close()
    self.isOpen = false
    self.optionRects = {}
    self.sortedWeapons = {}
end

function BuyMenu:toggle()
    if self.isOpen then self:close() else self:open() end
end

function BuyMenu:handleAction(action)
    if action == "menu_up" then
        self.useMouseSelection = false
        self.selection = self:wrapSelection(self.selection - 1)
    elseif action == "menu_down" then
        self.useMouseSelection = false
        self.selection = self:wrapSelection(self.selection + 1)
    elseif action == "menu_confirm" then
        self:confirmPurchase()
    end
end

function BuyMenu:wheelmoved(direction)
    if direction > 0 then
        self.selection = self:wrapSelection(self.selection - 1)
    elseif direction < 0 then
        self.selection = self:wrapSelection(self.selection + 1)
    end
end

function BuyMenu:confirmPurchase()
    local model = self.sortedWeapons[self.selection]
    if not model or self:playerHasWeapon(model) then return end
    if not self.state.inventory:findFirstEmptySlot() then
        self.state.toast:show("Inventory full!", 2)
        return
    end
    if self:canAffordWeapon(model) then
        self:buyWeapon(model)
    end
end

function BuyMenu:mousepressed(worldX, worldY)
    for i, rect in ipairs(self.optionRects) do
        if self:isPointInRect(worldX, worldY, rect) then
            self.selection = i
            self:confirmPurchase()
            return
        end
    end
    self:close()
end

---------------------------------- drawing ---------------------------------

function BuyMenu:draw()
    if not self.isOpen then return end

    self.optionRects = {}
    local optionCount = #self.sortedWeapons
    local panelHeight = OPTIONS_OFFSET_Y + optionCount * OPTION_GAP + 16
    local px = math.floor(self.state.scrWidth / 2 - PANEL_WIDTH / 2 + self.state.camera.x)
    local py = math.floor(self.state.scrHeight / 2 - panelHeight / 2 + self.state.camera.y)

    local mouseX, mouseY, mouseMoved = self:getMouseSelectionState()
    self:drawPanel(px, py, panelHeight)
    self:drawTitle(px, py)
    self:drawMoney(px, py)
    self:drawWeaponOptions(px, py, mouseX, mouseY, mouseMoved)
end

function BuyMenu:drawPanel(px, py, panelHeight)
    love.graphics.setColor(0.15, 0.15, 0.15, 0.95)
    love.graphics.rectangle("fill", px, py, PANEL_WIDTH, panelHeight)
    love.graphics.setColor(0.4, 0.4, 0.4)
    love.graphics.rectangle("line", px, py, PANEL_WIDTH, panelHeight)
end

function BuyMenu:drawTitle(px, py)
    local font = Fonts.get(36)
    love.graphics.setFont(font)
    love.graphics.setColor(1, 1, 1)
    local title = "WEAPON SHOP"
    local titleW = font:getWidth(title)
    love.graphics.print(title, px + PANEL_WIDTH / 2 - titleW / 2, py + TITLE_OFFSET_Y)
end

function BuyMenu:drawMoney(px, py)
    local font = Fonts.get(20)
    love.graphics.setFont(font)
    love.graphics.setColor(1, 0.8, 0.2)
    local text = "$" .. self.state.player.money
    local textW = font:getWidth(text)
    love.graphics.print(text, px + PANEL_WIDTH / 2 - textW / 2, py + MONEY_OFFSET_Y)
end

function BuyMenu:drawSelectionHighlight(rect, index)
    if index == self.selection then
        love.graphics.setColor(0.3, 0.5, 0.7)
        love.graphics.rectangle("fill", rect.x, rect.y, rect.w, rect.h)
    end
end

function BuyMenu:drawWeaponIcon(rect, model)
    local alpha = self:playerHasWeapon(model) and 0.4 or 1
    Textures.draw("slot_" .. model, rect.x + 4, rect.y + 4, 28, 28, alpha)
end

function BuyMenu:drawWeaponName(rect, model)
    local font = Fonts.get(22)
    love.graphics.setFont(font)
    love.graphics.print(model, rect.x + 40, rect.y + 6)
end

function BuyMenu:drawWeaponPrice(rect, model)
    if self:canAffordWeapon(model) then
        love.graphics.setColor(1, 0.8, 0.2)
    else
        love.graphics.setColor(0.8, 0.3, 0.3)
    end
    love.graphics.print("$" .. Config.WEAPONS[model].price, rect.x + rect.w - 74, rect.y + 8)
end

function BuyMenu:drawWeaponStatus(rect, model)
    local font = Fonts.get(18)
    love.graphics.setFont(font)
    if self:playerHasWeapon(model) then
        love.graphics.setColor(0.4, 0.4, 0.4)
        love.graphics.print("OWNED", rect.x + rect.w - 80, rect.y + 8)
    else
        self:drawWeaponPrice(rect, model)
    end
end

function BuyMenu:drawWeaponOption(px, optionY, i, model, mouseX, mouseY, mouseMoved)
    local rect = { x = px + 15, y = optionY, w = PANEL_WIDTH - 30, h = OPTION_HEIGHT }
    table.insert(self.optionRects, rect)

    if mouseMoved and self.useMouseSelection then
        self:updateHover(rect, mouseX, mouseY, i)
    end

    self:drawSelectionHighlight(rect, i)
    self:drawWeaponIcon(rect, model)
    self:drawWeaponName(rect, model)
    self:drawWeaponStatus(rect, model)
end

function BuyMenu:drawWeaponOptions(px, py, mouseX, mouseY, mouseMoved)
    local optionY = py + OPTIONS_OFFSET_Y
    for i, model in ipairs(self.sortedWeapons) do
        self:drawWeaponOption(px, optionY, i, model, mouseX, mouseY, mouseMoved)
        optionY = optionY + OPTION_GAP
    end
end

return BuyMenu