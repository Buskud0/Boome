-- Map select: layout and rect math. Attaches methods to the MapSelect factory.

local Config = require "core.config"

local PANEL_WIDTH = Config.MAP_SELECT_PANEL_WIDTH
local ROW_HEIGHT = Config.MAP_SELECT_ROW_HEIGHT
local ROW_GAP = Config.MAP_SELECT_ROW_GAP
local PADDING = Config.MAP_SELECT_PADDING
local BUTTON_WIDTH = Config.MAP_SELECT_BUTTON_WIDTH
local MAX_VISIBLE = Config.MAP_SELECT_MAX_VISIBLE_ROWS
local TITLE_HEIGHT = 28

return function(MapSelect)
    function MapSelect:visibleCount()
        local count = #self.list - self.scroll
        if count < 0 then count = 0 end
        return math.min(count, MAX_VISIBLE)
    end

    function MapSelect:listHeight()
        return self:visibleCount() * (ROW_HEIGHT + ROW_GAP)
    end

    function MapSelect:panelHeight()
        local bottom = ROW_HEIGHT + (self.mode == "horde" and ROW_GAP or 0)
        return PADDING + TITLE_HEIGHT + 12 + self:listHeight() + ROW_GAP + bottom + PADDING
    end

    function MapSelect:centerBox(w, h)
        return { x = self.state.scrWidth / 2 - w / 2, y = self.state.scrHeight / 2 - h / 2, w = w, h = h }
    end

    function MapSelect:panelBox()
        return self:centerBox(PANEL_WIDTH, self:panelHeight())
    end

    function MapSelect:listIdxTop(panel)
        return panel.y + PADDING + TITLE_HEIGHT + 12
    end

    function MapSelect:computeRows(panel)
        self.rows = {}
        local right = panel.x + PANEL_WIDTH - PADDING
        local btnH = ROW_HEIGHT - 10
        local gap = 6
        for i = 1, self:visibleCount() do
            local index = self.scroll + i
            local y = self:listIdxTop(panel) + (i - 1) * (ROW_HEIGHT + ROW_GAP)
            local btnY = y + (ROW_HEIGHT - btnH) / 2
            local deleteR = { x = right - BUTTON_WIDTH, y = btnY, w = BUTTON_WIDTH, h = btnH }
            local renameR = { x = deleteR.x - gap - BUTTON_WIDTH, y = btnY, w = BUTTON_WIDTH, h = btnH }
            local editR = { x = renameR.x - gap - BUTTON_WIDTH, y = btnY, w = BUTTON_WIDTH, h = btnH }
            self.rows[i] = {
                index = index,
                name = self.list[index],
                hit = { x = panel.x + PADDING, y = y, w = PANEL_WIDTH - PADDING * 2, h = ROW_HEIGHT },
                edit = self.mode == "builder" and editR or nil,
                rename = self.mode == "builder" and renameR or nil,
                delete = self.mode == "builder" and deleteR or nil,
            }
        end
    end

    function MapSelect:buildBottom(panel)
        self.bottomButtons = {}
        local bottomY = self:listIdxTop(panel) + self:listHeight() + ROW_GAP
        local h = ROW_HEIGHT
        local innerW = PANEL_WIDTH - PADDING * 2
        local function add(x, w, label, callback)
            table.insert(self.bottomButtons, { label = label, rect = { x = x, y = bottomY, w = w, h = h }, callback = callback })
        end
        if self.mode == "horde" then
            add(panel.x + PADDING, innerW, "Start", function()
                local name = self:selectedMapName()
                if name then self:start(name) end
            end)
        else
            add(panel.x + PADDING, innerW, "Create New", function() self:beginCreate() end)
        end
    end

    function MapSelect:buildModal()
        self.modal = nil
        if self.prompt then
            self.modal = self:centerBox(440, 130)
            self.modal.progress = { x = self.modal.x + 20, y = self.modal.y + 58, w = 400, h = 24 }
            self.modal.ok = self:centerBox(132, 28)
            self.modal.ok.x = self.modal.x + self.modal.w - 142
            self.modal.ok.y = self.modal.y + self.modal.h - 38
            self.modal.cancel = self:centerBox(110, 28)
            self.modal.cancel.x = self.modal.ok.x - 6 - 110
            self.modal.cancel.y = self.modal.y + self.modal.h - 38
        elseif self.confirm then
            self.modal = self:centerBox(420, 130)
            local bw, bh, gap = 100, 28, 12
            local y = self.modal.y + self.modal.h - 38
            local leftX = self.modal.x + (self.modal.w - bw * 2 - gap) / 2
            self.modal.cancel = { x = leftX, y = y, w = bw, h = bh }
            self.modal.ok = { x = leftX + bw + gap, y = y, w = bw, h = bh }
        end
    end

    function MapSelect:buildLayout()
        self:computeRows(self:panelBox())
        self:buildBottom(self:panelBox())
        self:buildModal()
    end
end
