-- Pause menu rendering. Attaches methods to the Menu factory.

local Config = require "core.config"
local Fonts = require "core.fonts"
local Input = require "core.input"

local PANEL_WIDTH = Config.MENU_PANEL_WIDTH
local OPTION_HEIGHT = Config.MENU_OPTION_HEIGHT
local OPTION_GAP = Config.MENU_OPTION_GAP
local TITLE_OFFSET_Y = Config.MENU_TITLE_OFFSET_Y
local OPTIONS_OFFSET_Y = Config.MENU_OPTIONS_OFFSET_Y

return function(Menu)
    function Menu:draw()
        self.optionRects = {}
        local screen = self:currentScreen()
        if not screen then return end

        local panelHeight = OPTIONS_OFFSET_Y + #screen.options * OPTION_GAP
        local px = self.state.scrWidth / 2 - PANEL_WIDTH / 2 + self.state.camera.x
        local py = self.state.scrHeight / 2 - panelHeight / 2 + self.state.camera.y

        self:drawPanel(px, py, panelHeight)
        self:drawTitle(screen.title, px, py)
        self:drawOptions(screen, px, py)
    end

    function Menu:drawPanel(px, py, panelHeight)
        love.graphics.setColor(0.15, 0.15, 0.15, 0.95)
        love.graphics.rectangle("fill", px, py, PANEL_WIDTH, panelHeight)
        love.graphics.setColor(0.4, 0.4, 0.4)
        love.graphics.rectangle("line", px, py, PANEL_WIDTH, panelHeight)
    end

    function Menu:drawTitle(title, px, py)
        local font = Fonts.get(36)
        love.graphics.setFont(font)
        love.graphics.setColor(1, 1, 1)
        local titleW = font:getWidth(title)
        love.graphics.print(title, px + PANEL_WIDTH / 2 - titleW / 2, py + TITLE_OFFSET_Y)
    end

    function Menu:drawOptions(screen, px, py)
        local mouseX, mouseY = Input.getMousePosition()
        mouseX = mouseX + self.state.camera.x
        mouseY = mouseY + self.state.camera.y
        local mouseMoved = self:_updateMousePosition(mouseX, mouseY)

        local font = Fonts.get(24)
        local optionY = py + OPTIONS_OFFSET_Y
        for i, entry in ipairs(screen.options) do
            local label = self:_resolveLabel(entry.label)
            local rect = { x = px + 15, y = optionY, w = PANEL_WIDTH - 30, h = OPTION_HEIGHT }

            if mouseMoved then
                self:updateHover(entry, rect, mouseX, mouseY, i)
            end

            self:drawOption(entry, rect, label, font, i)
            self.optionRects[i] = rect
            optionY = optionY + OPTION_GAP
        end
    end

    function Menu:_updateMousePosition(mouseX, mouseY)
        local mouseMoved = mouseX ~= self.lastMouseX or mouseY ~= self.lastMouseY
        if mouseMoved then
            self.lastMouseX = mouseX
            self.lastMouseY = mouseY
        end
        return mouseMoved
    end

    function Menu:_resolveLabel(label)
        if type(label) == "function" then
            return label()
        end
        return label
    end

    function Menu:drawOption(entry, rect, label, font, index)
        if index == self.selection and entry.action then
            love.graphics.setColor(0.3, 0.5, 0.7)
            love.graphics.rectangle("fill", rect.x, rect.y, rect.w, rect.h)
        end

        love.graphics.setFont(font)
        love.graphics.setColor(1, 1, 1)
        local labelW = font:getWidth(label)
        love.graphics.print(label, rect.x + rect.w / 2 - labelW / 2, rect.y + 6)
    end

    function Menu:updateHover(entry, rect, mouseX, mouseY, index)
        if entry.action and
           mouseX >= rect.x and mouseX <= rect.x + rect.w and
           mouseY >= rect.y and mouseY <= rect.y + rect.h then
            self.selection = index
        end
    end
end