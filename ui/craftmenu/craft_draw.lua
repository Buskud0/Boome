-- Workshop crafting: rendering. Attaches methods to the CraftMenu factory.

local Config = require "core.config"
local Fonts = require "core.fonts"
local Textures = require "core.textures"

local PANEL_WIDTH = Config.CRAFTMENU_PANEL_WIDTH
local OPTION_HEIGHT = Config.CRAFTMENU_OPTION_HEIGHT
local OPTION_GAP = Config.CRAFTMENU_OPTION_GAP
local TITLE_OFFSET_Y = Config.CRAFTMENU_TITLE_OFFSET_Y
local OPTIONS_OFFSET_Y = Config.CRAFTMENU_OPTIONS_OFFSET_Y
local MATERIAL_GAP = Config.CRAFTMENU_MATERIAL_GAP

return function(CraftMenu)
    function CraftMenu:draw()
        if not self.isOpen then return end

        self.optionRects = {}
        local optionCount = #self.sortedItems
        local panelHeight = OPTIONS_OFFSET_Y + optionCount * OPTION_GAP + 16
        local px = math.floor(self.state.scrWidth / 2 - PANEL_WIDTH / 2 + self.state.camera.x)
        local py = math.floor(self.state.scrHeight / 2 - panelHeight / 2 + self.state.camera.y)

        local mouseX, mouseY, mouseMoved = self:getMouseSelectionState()
        self:drawPanel(px, py, panelHeight)
        self:drawTitle(px, py)
        self:drawRecipeOptions(px, py, mouseX, mouseY, mouseMoved)
    end

    function CraftMenu:drawPanel(px, py, panelHeight)
        love.graphics.setColor(0.15, 0.15, 0.15, 0.95)
        love.graphics.rectangle("fill", px, py, PANEL_WIDTH, panelHeight)
        love.graphics.setColor(0.4, 0.4, 0.4)
        love.graphics.rectangle("line", px, py, PANEL_WIDTH, panelHeight)
    end

    function CraftMenu:drawTitle(px, py)
        local font = Fonts.get(36)
        love.graphics.setFont(font)
        love.graphics.setColor(1, 1, 1)
        local title = "WORKSHOP"
        local titleW = font:getWidth(title)
        love.graphics.print(title, px + PANEL_WIDTH / 2 - titleW / 2, py + TITLE_OFFSET_Y)
    end

    function CraftMenu:drawSelectionHighlight(rect, index)
        if index == self.selection then
            love.graphics.setColor(0.3, 0.5, 0.7)
            love.graphics.rectangle("fill", rect.x, rect.y, rect.w, rect.h)
        end
    end

    function CraftMenu:drawOutputIcon(rect, model)
        Textures.draw("slot_" .. model, rect.x + 6, rect.y + 6, 32, 32, 1)
    end

    function CraftMenu:drawOutputName(rect, model)
        local font = Fonts.get(22)
        love.graphics.setFont(font)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(Config.ITEMS[model].name, rect.x + 48, rect.y + 9)
    end

    function CraftMenu:drawMaterials(rect, model)
        local materials = self:materialsFor(model)
        local size = 30
        local y = rect.y + (rect.h - size) / 2
        local x = rect.x + rect.w - 16 - size
        for i = #materials, 1, -1 do
            local mat = materials[i]
            local has = self.state.inventory:countModel(mat[1]) >= mat[2]
            self:drawMaterialIcon(mat[1], mat[2], has, x, y, size)
            x = x - MATERIAL_GAP
        end
    end

    function CraftMenu:drawMaterialIcon(material, count, has, x, y, size)
        if has then
            love.graphics.setColor(0.2, 0.6, 0.2)
        else
            love.graphics.setColor(0.6, 0.2, 0.2)
        end
        love.graphics.rectangle("fill", x, y, size, size)
        Textures.draw("slot_" .. material, x + 2, y + 2, size - 4, size - 4, 1)
        local font = Fonts.get(14)
        love.graphics.setFont(font)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("x" .. count, x + 2, y + size - 4)
    end

    function CraftMenu:drawRecipeOption(px, optionY, i, model, mouseX, mouseY, mouseMoved)
        local rect = { x = px + 15, y = optionY, w = PANEL_WIDTH - 30, h = OPTION_HEIGHT }
        table.insert(self.optionRects, rect)

        if mouseMoved and self.useMouseSelection then
            self:updateHover(rect, mouseX, mouseY, i)
        end

        self:drawSelectionHighlight(rect, i)
        self:drawOutputIcon(rect, model)
        self:drawOutputName(rect, model)
        self:drawMaterials(rect, model)
    end

    function CraftMenu:drawRecipeOptions(px, py, mouseX, mouseY, mouseMoved)
        local optionY = py + OPTIONS_OFFSET_Y
        for i, model in ipairs(self.sortedItems) do
            self:drawRecipeOption(px, optionY, i, model, mouseX, mouseY, mouseMoved)
            optionY = optionY + OPTION_GAP
        end
    end
end
