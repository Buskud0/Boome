-- Map selection screen: list, create/rename/delete, and start builders.
-- State-injected factory.

local Config = require "core.config"
local Fonts = require "core.fonts"
local Input = require "core.input"
local MapStorage = require "core.storage.mapstorage"

local MapSelect = {}
MapSelect.__index = MapSelect

local PANEL_WIDTH = Config.MAP_SELECT_PANEL_WIDTH
local ROW_HEIGHT = Config.MAP_SELECT_ROW_HEIGHT
local ROW_GAP = Config.MAP_SELECT_ROW_GAP
local PADDING = Config.MAP_SELECT_PADDING
local BUTTON_WIDTH = Config.MAP_SELECT_BUTTON_WIDTH
local MAX_VISIBLE = Config.MAP_SELECT_MAX_VISIBLE_ROWS
local NAME_LIMIT = 24
local TITLE_HEIGHT = 28

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

function MapSelect.new(state)
    local self = setmetatable({}, MapSelect)
    self.state = state
    self.isOpen = false
    self.mode = "builder" -- "builder" or "horde"
    self.previousMode = "horde"
    self.list = {}
    self.selected = 1
    self.scroll = 0
    self.rows = {}
    self.bottomButtons = {}
    self.prompt = nil -- { kind = "create"|"rename", buffer, map }
    self.confirm = nil -- { kind = "delete", map }
    self.modal = nil
    return self
end

local function isPointInRect(x, y, rect)
    if not rect then return false end
    return x >= rect.x and x <= rect.x + rect.w and y >= rect.y and y <= rect.y + rect.h
end

local function drawCentered(horde, text, centerX, centerY, size, alpha)
    horde:drawCenteredText(text, centerX, centerY, size, alpha)
end

function MapSelect:open(mode)
    self.mode = mode
    self.isOpen = true
    self.selected = 1
    self.scroll = 0
    self:refreshList()
    self:selectCurrentMap()
end

function MapSelect:selectCurrentMap()
    local current = self.state.selectedMapName
    if not current then return end
    for i, name in ipairs(self.list) do
        if name == current then
            self.selected = i
            self:keepSelectedVisible()
            return
        end
    end
end

function MapSelect:refreshList()
    self.list = MapStorage.listMaps()
    self:clampSelection()
    self:clampScroll()
end

function MapSelect:selectedMapName()
    if self.selected >= 1 and self.selected <= #self.list then
        return self.list[self.selected]
    end
    return nil
end

function MapSelect:clampSelection()
    if #self.list == 0 then
        self.selected = 1
        return
    end
    if self.selected > #self.list then self.selected = #self.list end
    if self.selected < 1 then self.selected = 1 end
end

function MapSelect:clampScroll()
    local maxScroll = math.max(0, #self.list - MAX_VISIBLE)
    self.scroll = math.min(math.max(0, self.scroll), maxScroll)
end

function MapSelect:close()
    self.isOpen = false
    self.prompt = nil
    self.confirm = nil
end

function MapSelect:closeModal()
    self.prompt = nil
    self.confirm = nil
end

--------------------------------- layout ---------------------------------

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

---------------------------------- keyboard ---------------------------------

function MapSelect:handleKey(key, action)
    if self.prompt then return self:handlePromptKey(action) end
    if self.confirm then return self:handlePromptKey(action) end

    if action == "pause" then
        self.state.leaveMapSelect()
        return true
    end

    if action == "menu_up" then
        self:moveSelection(-1)
        return true
    elseif action == "menu_down" then
        self:moveSelection(1)
        return true
    elseif action == "menu_confirm" then
        local name = self:selectedMapName()
        if name then self:start(name) end
        return true
    end

    if self.mode == "builder" and Input.isActionBoundToKey("delete_map", key) then
        local name = self:selectedMapName()
        if name then self:beginDelete(name) end
        return true
    end

    return false
end

function MapSelect:handlePromptKey(action)
    if action == "pause" then
        self.prompt = nil
        self.confirm = nil
        return true
    end
    if action == "menu_confirm" then
        if self.prompt then self:submitPrompt() else self:acceptConfirm() end
        return true
    end
    if action == "search_backspace" then
        if self.prompt then self:handleBackspace() end
        return true
    end
    return false
end

function MapSelect:moveSelection(delta)
    if #self.list == 0 then return end
    self.selected = self.selected + delta
    self:clampSelection()
    self:keepSelectedVisible()
end

function MapSelect:keepSelectedVisible()
    if self.selected < self.scroll + 1 then
        self.scroll = self.selected - 1
    elseif self.selected > self.scroll + MAX_VISIBLE then
        self.scroll = self.selected - MAX_VISIBLE
    end
    self:clampScroll()
end

function MapSelect:handleTextInput(text)
    if not self.prompt then return end
    if #self.prompt.buffer >= NAME_LIMIT then return end
    self.prompt.buffer = self.prompt.buffer .. text
end

function MapSelect:handleBackspace()
    if not self.prompt then return end
    self.prompt.buffer = self.prompt.buffer:sub(1, -2)
end

--------------------------------- actions ---------------------------------

function MapSelect:start(name)
    self:close()
    if self.mode == "horde" then
        self.state.startHordeWith(name)
    else
        self.state.enterBuilderWith(name)
    end
    return true
end

function MapSelect:beginCreate()
    self.prompt = { kind = "create", buffer = "" }
end

function MapSelect:beginRename(name)
    self.prompt = { kind = "rename", map = name, buffer = name }
end

function MapSelect:beginDelete(name)
    self.confirm = { kind = "delete", map = name }
end

function MapSelect:submitPrompt()
    if self.prompt.kind == "create" then
        self:confirmCreate() else self:confirmRename() end
end

function MapSelect:confirmCreate()
    local name = self:cleanName(self.prompt.buffer)
    if not MapStorage.isValidName(name) then
        self.state.toast:show("Invalid name", 1.5)
        return
    end
    if MapStorage.mapExists(name) then
        self.state.toast:show("A map with that name exists", 1.5)
        return
    end
    MapStorage.saveMap(name, self.state.mapBuilder:grassFillData() or "")
    self.prompt = nil
    self:refreshList()
    self:start(name) -- enter
    self:start(name)
end

function MapSelect:confirmRename()
    local oldName = self.prompt.map
    local newName = self:cleanName(self.prompt.buffer)
    if not MapStorage.isValidName(newName) then
        self.state.toast:show("Invalid name", 1.5)
        return
    end
    if newName == oldName then
        self.prompt = nil
        return
    end
    if MapStorage.mapExists(newName) then
        self.state.toast:show("A map with that name exists", 1.5)
        return
    end
    if MapStorage.renameMap(oldName, newName) then
        if self.state.selectedMapName == oldName then self.state.selectedMapName = newName end
    else
        self.state.toast:show("Rename failed", 1.5)
    end
    self.prompt = nil
    self:refreshList()
end

function MapSelect:cleanName(buffer)
    return buffer:gsub("^%s+", ""):gsub("%s+$", "")
end

function MapSelect:acceptConfirm()
    if self.confirm and self.confirm.kind == "delete" then
        self:confirmDelete()
    end
end

function MapSelect:confirmDelete()
    local name = self.confirm.map
    MapStorage.deleteMap(name)
    self.confirm = nil
    self:refreshList()
end

---------------------------------- mouse ---------------------------------

function MapSelect:mousepressed(x, y, button)
    if button ~= 1 then return end
    self:buildLayout()

    if self.prompt or self.confirm then
        self:clickModal(x, y)
        return
    end

    for _, row in ipairs(self.rows) do
        if self.mode == "builder" and isPointInRect(x, y, row.delete) then
            self:beginDelete(row.name)
            return
        elseif self.mode == "builder" and isPointInRect(x, y, row.rename) then
            self:beginRename(row.name)
            return
        elseif self.mode == "builder" and isPointInRect(x, y, row.edit) then
            self:start(row.name)
            return
        elseif isPointInRect(x, y, row.hit) then
            self.selected = row.index
            self:keepSelectedVisible()
            if self.mode == "builder" then self:start(row.name) end
            return
        end
    end

    for _, btn in ipairs(self.bottomButtons) do
        if isPointInRect(x, y, btn.rect) then
            btn.callback()
            return
        end
    end
end

function MapSelect:clickModal(x, y)
    if not self.modal then return end
    if isPointInRect(x, y, self.modal.cancel) then
        self:closeModal()
    elseif isPointInRect(x, y, self.modal.ok) then
        if self.prompt then self:submitPrompt() else self:acceptConfirm() end
    end
end

---------------------------------------- drawing ----------------------------------------

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
    drawCentered(self.state.horde, title, panel.x + PANEL_WIDTH / 2, panel.y + PADDING, 28, 1)
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
    drawCentered(self.state.horde, label, rect.x + rect.w / 2, rect.y + (rect.h - th) / 2, size, 1)
end

function MapSelect:drawLabel(text, x, y, size)
    love.graphics.setFont(Fonts.get(size))
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(text, x, y)
end

return MapSelect