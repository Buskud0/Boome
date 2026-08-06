-- Map select: rendering. Attaches methods to the MapSelect factory.

local Fonts = require "core.fonts"

local PANEL_WIDTH = require("core.config").MAP_SELECT_PANEL_WIDTH
local PADDING = require("core.config").MAP_SELECT_PADDING

local COL = {
    dim = { 0, 0, 0, 0.6 },
    panel = { 0.12, 0.12, 0.12, 0.97 },
    border = { 0.4, 0.4, 0.4 },
    selected = { 0.25, 0.35, 0.5 },
    edit = { 0.35, 0.6, 0.4 },
    delete = { 0.62, 0.25, 0.25 },
    rename = { 0.5, 0.5, 0.5 },
    primary = { 0.32, 0.55, 0.8 },
}

local function drawCentered(text, centerX, centerY, size, alpha)
    local font = Fonts.get(size)
    love.graphics.setFont(font)
    love.graphics.setColor(1, 1, 1, alpha or 1)
    love.graphics.print(text, centerX - font:getWidth(text) / 2, centerY)
end

return function(MapSelect)
    function MapSelect:draw()
        if not self.isOpen then return end

        love.graphics.push()
        love.graphics.origin()

        self:drawShade()

        self:buildLayout()
        local panel = self:panelBox()

        self:drawPanel(panel)
        self:drawRows(panel)
        self:drawBottom(panel)

        if self.prompt then self:drawPrompt() end
        if self.confirm then self:drawConfirm() end

        love.graphics.pop()
    end

    function MapSelect:drawShade()
        love.graphics.setColor(COL.dim)
        love.graphics.rectangle("fill", 0, 0, self.state.scrWidth, self.state.scrHeight)
    end

    function MapSelect:drawPanel(panel)
        self:drawBox(panel)
        local title = self.mode == "horde" and "SWITCH HORDE MAP" or "MAP SELECT"
        drawCentered(title, panel.x + PANEL_WIDTH / 2, panel.y + PADDING, 28, 1)
    end

    function MapSelect:drawRows(panel)
        for _, row in ipairs(self.rows) do
            if row.index == self.selected then
                love.graphics.setColor(COL.selected)
                love.graphics.rectangle("fill", row.hit.x, row.hit.y, row.hit.w, row.hit.h)
            end
            if self.mode == "builder" then
                self:drawButton(row.delete, "Delete", 15, COL.delete)
                self:drawButton(row.rename, "Rename", 15, COL.rename)
                self:drawButton(row.edit, "Edit", 15, COL.edit)
            end
            self:drawLabel(row.name, row.hit.x + 8, row.hit.y + 8, 20)
        end
    end

    function MapSelect:drawBottom(panel)
        for _, btn in ipairs(self.bottomButtons) do
            self:drawButton(btn.rect, btn.label, 18, COL.primary)
        end
        self:drawLabel("Esc - back", panel.x + PADDING, panel.y + panel.h - 22, 14)
    end

    function MapSelect:drawPrompt()
        local box = self.modal
        self:drawBox(box)
        self:drawLabel(self.prompt.kind == "rename" and "Rename map" or "New map name", box.x + 20, box.y + 14, 22)
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("line", box.progress.x, box.progress.y, box.progress.w, box.progress.h)
        self:drawButton(box.cancel, "Cancel", 16, COL.delete)
        self:drawButton(box.ok, "OK", 16, COL.edit)
        self:drawLabel(self.prompt.buffer .. "|", box.progress.x + 6, box.progress.y - 2, 20)
    end

    function MapSelect:drawConfirm()
        local box = self.modal
        self:drawBox(box)
        self:drawLabel("Delete '" .. self.confirm.map .. "'?", box.x + 20, box.y + 18, 20)
        self:drawButton(box.cancel, "Cancel", 16, COL.delete)
        self:drawButton(box.ok, "Yes", 16, COL.edit)
    end

    function MapSelect:drawBox(rect)
        love.graphics.setColor(COL.panel)
        love.graphics.rectangle("fill", rect.x, rect.y, rect.w, rect.h)
        love.graphics.setColor(COL.border)
        love.graphics.rectangle("line", rect.x, rect.y, rect.w, rect.h)
    end

    function MapSelect:drawButton(rect, label, size, color)
        if not rect then return end
        love.graphics.setColor(color)
        love.graphics.rectangle("fill", rect.x, rect.y, rect.w, rect.h)
        local th = Fonts.get(size):getHeight()
        drawCentered(label, rect.x + rect.w / 2, rect.y + (rect.h - th) / 2, size, 1)
    end

    function MapSelect:drawLabel(text, x, y, size)
        love.graphics.setFont(Fonts.get(size))
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(text, x, y)
    end
end
