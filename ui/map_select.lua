local MapSelect = {}

local PANEL_WIDTH = MAP_SELECT_PANEL_WIDTH
local ROW_HEIGHT = MAP_SELECT_ROW_HEIGHT
local ROW_GAP = MAP_SELECT_ROW_GAP
local PADDING = MAP_SELECT_PADDING
local BUTTON_WIDTH = MAP_SELECT_BUTTON_WIDTH
local MAX_VISIBLE = MAP_SELECT_MAX_VISIBLE_ROWS
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

MapSelect.isOpen = false
MapSelect.mode = "builder" -- "builder" or "horde"
MapSelect.previousMode = "horde"
MapSelect.list = {}
MapSelect.selected = 1
MapSelect.scroll = 0
MapSelect.rows = {}
MapSelect.bottomButtons = {}
MapSelect.prompt = nil -- { kind = "create"|"rename", buffer, map }
MapSelect.confirm = nil -- { kind = "delete", map }

function MapSelect.open(mode)
    MapSelect.mode = mode
    MapSelect.isOpen = true
    MapSelect.selected = 1
    MapSelect.scroll = 0
    MapSelect.refreshList()
    MapSelect.selectCurrentMap()
end

function MapSelect.selectCurrentMap()
    local current = selectedMapName
    if not current then return end
    for i, name in ipairs(MapSelect.list) do
        if name == current then
            MapSelect.selected = i
            MapSelect.keepSelectedVisible()
            return
        end
    end
end

function MapSelect.refreshList()
    MapSelect.list = MapStorage.listMaps()
    MapSelect.clampSelection()
    MapSelect.clampScroll()
end

function MapSelect.selectedMapName()
    if MapSelect.selected >= 1 and MapSelect.selected <= #MapSelect.list then
        return MapSelect.list[MapSelect.selected]
    end
    return nil
end

function MapSelect.clampSelection()
    if #MapSelect.list == 0 then
        MapSelect.selected = 1
        return
    end
    if MapSelect.selected > #MapSelect.list then MapSelect.selected = #MapSelect.list end
    if MapSelect.selected < 1 then MapSelect.selected = 1 end
end

function MapSelect.clampScroll()
    local maxScroll = math.max(0, #MapSelect.list - MAX_VISIBLE)
    MapSelect.scroll = math.min(math.max(0, MapSelect.scroll), maxScroll)
end

function MapSelect.close()
    MapSelect.isOpen = false
    MapSelect.prompt = nil
    MapSelect.confirm = nil
end

function MapSelect.closeModal()
    MapSelect.prompt = nil
    MapSelect.confirm = nil
end

------------------------------ layout ------------------------------

function MapSelect.visibleCount()
    local count = #MapSelect.list - MapSelect.scroll
    if count < 0 then count = 0 end
    return math.min(count, MAX_VISIBLE)
end

function MapSelect.listHeight()
    return MapSelect.visibleCount() * (ROW_HEIGHT + ROW_GAP)
end

function MapSelect.panelHeight()
    local bottom = ROW_HEIGHT + (MapSelect.mode == "horde" and ROW_GAP or 0)
    return PADDING + TITLE_HEIGHT + 12 + MapSelect.listHeight() + ROW_GAP + bottom + PADDING
end

function MapSelect.centerBox(w, h)
    return { x = scrWidth / 2 - w / 2, y = scrHeight / 2 - h / 2, w = w, h = h }
end

function MapSelect.panelBox()
    local h = MapSelect.panelHeight()
    return MapSelect.centerBox(PANEL_WIDTH, h)
end

function MapSelect.listTop(panel)
    return panel.y + PADDING + TITLE_HEIGHT + 12
end

function MapSelect.computeRows(panel)
    MapSelect.rows = {}
    local right = panel.x + PANEL_WIDTH - PADDING
    local btnH = ROW_HEIGHT - 10
    local gap = 6
    for i = 1, MapSelect.visibleCount() do
        local index = MapSelect.scroll + i
        local y = MapSelect.listTop(panel) + (i - 1) * (ROW_HEIGHT + ROW_GAP)
        local btnY = y + (ROW_HEIGHT - btnH) / 2
        local deleteR = { x = right - BUTTON_WIDTH, y = btnY, w = BUTTON_WIDTH, h = btnH }
        local renameR = { x = deleteR.x - gap - BUTTON_WIDTH, y = btnY, w = BUTTON_WIDTH, h = btnH }
        local editR = { x = renameR.x - gap - BUTTON_WIDTH, y = btnY, w = BUTTON_WIDTH, h = btnH }
        MapSelect.rows[i] = {
            index = index,
            name = MapSelect.list[index],
            hit = { x = panel.x + PADDING, y = y, w = PANEL_WIDTH - PADDING * 2, h = ROW_HEIGHT },
            edit = MapSelect.mode == "builder" and editR or nil,
            rename = MapSelect.mode == "builder" and renameR or nil,
            delete = MapSelect.mode == "builder" and deleteR or nil,
        }
    end
end

function MapSelect.buildBottom(panel)
    MapSelect.bottomButtons = {}
    local bottomY = MapSelect.listTop(panel) + MapSelect.listHeight() + ROW_GAP
    local h = ROW_HEIGHT
    local innerW = PANEL_WIDTH - PADDING * 2
    local function add(x, w, label, callback)
        table.insert(MapSelect.bottomButtons, { label = label, rect = { x = x, y = bottomY, w = w, h = h }, callback = callback })
    end
    if MapSelect.mode == "horde" then
        add(panel.x + PADDING, innerW, "Start", function()
            local name = MapSelect.selectedMapName()
            if name then MapSelect.start(name) end
        end)
    else
        add(panel.x + PADDING, innerW, "Create New", function() MapSelect.beginCreate() end)
    end
end

function MapSelect.buildModal()
    MapSelect.modal = nil
    if MapSelect.prompt then
        MapSelect.modal = MapSelect.centerBox(440, 130)
        MapSelect.modal.progress = { x = MapSelect.modal.x + 20, y = MapSelect.modal.y + 58, w = 400, h = 24 }
        MapSelect.modal.ok = MapSelect.centerBox(132, 28)
        MapSelect.modal.ok.x = MapSelect.modal.x + MapSelect.modal.w - 142
        MapSelect.modal.ok.y = MapSelect.modal.y + MapSelect.modal.h - 38
        MapSelect.modal.cancel = MapSelect.centerBox(110, 28)
        MapSelect.modal.cancel.x = MapSelect.modal.ok.x - 6 - 110
        MapSelect.modal.cancel.y = MapSelect.modal.y + MapSelect.modal.h - 38
    elseif MapSelect.confirm then
        MapSelect.modal = MapSelect.centerBox(420, 130)
        local bw, bh, gap = 100, 28, 12
        local y = MapSelect.modal.y + MapSelect.modal.h - 38
        local leftX = MapSelect.modal.x + (MapSelect.modal.w - bw * 2 - gap) / 2
        MapSelect.modal.cancel = { x = leftX, y = y, w = bw, h = bh }
        MapSelect.modal.ok = { x = leftX + bw + gap, y = y, w = bw, h = bh }
    end
end

function MapSelect.buildLayout()
    MapSelect.computeRows(MapSelect.panelBox())
    MapSelect.buildBottom(MapSelect.panelBox())
    MapSelect.buildModal()
end

------------------------------ keyboard ------------------------------

function MapSelect.handleKey(key, action)
    if MapSelect.prompt then return MapSelect.handlePromptKey(action) end
    if MapSelect.confirm then return MapSelect.handleConfirmKey(action) end

    if action == "pause" then
        leaveMapSelect()
        return true
    end

    if action == "menu_up" then
        MapSelect.moveSelection(-1)
        return true
    elseif action == "menu_down" then
        MapSelect.moveSelection(1)
        return true
    elseif action == "menu_confirm" then
        local name = MapSelect.selectedMapName()
        if name then MapSelect.start(name) end
        return true
    end

    if MapSelect.mode == "builder" and Input.isActionBoundToKey("delete_map", key) then
        local name = MapSelect.selectedMapName()
        if name then MapSelect.beginDelete(name) end
        return true
    end

    if Input.isActionBoundToKey("search_backspace", key) then
        MapSelect.handleBackspace()
        return true
    end

    return false
end

function MapSelect.handlePromptKey(action)
    if action == "pause" then
        MapSelect.prompt = nil
        return true
    end
    if action == "menu_confirm" then
        MapSelect.submitPrompt()
        return true
    end
    if action == "search_backspace" then
        MapSelect.handleBackspace()
        return true
    end
    return false
end

function MapSelect.handleConfirmKey(action)
    if action == "pause" then
        MapSelect.confirm = nil
        return true
    end
    if action == "menu_confirm" then
        MapSelect.acceptConfirm()
        return true
    end
    return false
end

function MapSelect.moveSelection(delta)
    if #MapSelect.list == 0 then return end
    MapSelect.selected = MapSelect.selected + delta
    MapSelect.clampSelection()
    MapSelect.keepSelectedVisible()
end

function MapSelect.keepSelectedVisible()
    if MapSelect.selected < MapSelect.scroll + 1 then
        MapSelect.scroll = MapSelect.selected - 1
    elseif MapSelect.selected > MapSelect.scroll + MAX_VISIBLE then
        MapSelect.scroll = MapSelect.selected - MAX_VISIBLE
    end
    MapSelect.clampScroll()
end

function MapSelect.handleTextInput(text)
    if not MapSelect.prompt then return end
    if #MapSelect.prompt.buffer >= NAME_LIMIT then return end
    MapSelect.prompt.buffer = MapSelect.prompt.buffer .. text
end

function MapSelect.handleBackspace()
    if not MapSelect.prompt then return end
    MapSelect.prompt.buffer = MapSelect.prompt.buffer:sub(1, -2)
end

------------------------------ actions ------------------------------

function MapSelect.start(name)
    MapSelect.close()
    if MapSelect.mode == "horde" then
        startHordeWith(name)
    else
        enterBuilderWith(name)
    end
end

function MapSelect.beginCreate()
    MapSelect.prompt = { kind = "create", buffer = "" }
end

function MapSelect.beginRename(name)
    MapSelect.prompt = { kind = "rename", map = name, buffer = name }
end

function MapSelect.beginDelete(name)
    MapSelect.confirm = { kind = "delete", map = name }
end

function MapSelect.submitPrompt()
    if MapSelect.prompt.kind == "create" then
        MapSelect.confirmCreate()
    else
        MapSelect.confirmRename()
    end
end

function MapSelect.cleanName(buffer)
    return buffer:gsub("^%s+", ""):gsub("%s+$", "")
end

function MapSelect.confirmCreate()
    local name = MapSelect.cleanName(MapSelect.prompt.buffer)
    if not MapStorage.isValidName(name) then
        Toast.show("Invalid name", 1.5)
        return
    end
    if MapStorage.mapExists(name) then
        Toast.show("A map with that name exists", 1.5)
        return
    end
    MapStorage.saveMap(name, MapBuilder.grassFillData())
    MapSelect.prompt = nil
    MapSelect.refreshList()
    MapSelect.start(name)
end

function MapSelect.confirmRename()
    local oldName = MapSelect.prompt.map
    local newName = MapSelect.cleanName(MapSelect.prompt.buffer)
    if not MapStorage.isValidName(newName) then
        Toast.show("Invalid name", 1.5)
        return
    end
    if newName == oldName then
        MapSelect.prompt = nil
        return
    end
    if MapStorage.mapExists(newName) then
        Toast.show("A map with that name exists", 1.5)
        return
    end
    if MapStorage.renameMap(oldName, newName) then
        if selectedMapName == oldName then selectedMapName = newName end
    else
        Toast.show("Rename failed", 1.5)
    end
    MapSelect.prompt = nil
    MapSelect.refreshList()
end

function MapSelect.acceptConfirm()
    if MapSelect.confirm.kind == "delete" then
        MapSelect.confirmDelete()
    end
end

function MapSelect.confirmDelete()
    local name = MapSelect.confirm.map
    MapStorage.deleteMap(name)
    MapSelect.confirm = nil
    MapSelect.refreshList()
end

------------------------------ mouse ------------------------------

function MapSelect.mousepressed(x, y, button)
    if button ~= 1 then return end
    MapSelect.buildLayout()

    if MapSelect.prompt then
        MapSelect.clickModal(x, y)
        return
    end
    if MapSelect.confirm then
        MapSelect.clickModal(x, y)
        return
    end

    for _, row in ipairs(MapSelect.rows) do
        if MapSelect.mode == "builder" and MapBuilder.isPointInRect(x, y, row.delete) then
            MapSelect.beginDelete(row.name)
            return
        elseif MapSelect.mode == "builder" and MapBuilder.isPointInRect(x, y, row.rename) then
            MapSelect.beginRename(row.name)
            return
        elseif MapSelect.mode == "builder" and MapBuilder.isPointInRect(x, y, row.edit) then
            MapSelect.start(row.name)
            return
        elseif MapBuilder.isPointInRect(x, y, row.hit) then
            MapSelect.selected = row.index
            MapSelect.keepSelectedVisible()
            if MapSelect.mode == "builder" then MapSelect.start(row.name) end
            return
        end
    end

    for _, btn in ipairs(MapSelect.bottomButtons) do
        if MapBuilder.isPointInRect(x, y, btn.rect) then
            btn.callback()
            return
        end
    end
end

function MapSelect.clickModal(x, y)
    if not MapSelect.modal then return end
    if MapBuilder.isPointInRect(x, y, MapSelect.modal.cancel) then
        MapSelect.closeModal()
    elseif MapBuilder.isPointInRect(x, y, MapSelect.modal.ok) then
        if MapSelect.prompt then MapSelect.submitPrompt() else MapSelect.acceptConfirm() end
    end
end

------------------------------ drawing ------------------------------

function MapSelect.draw()
    if not MapSelect.isOpen then return end

    love.graphics.push()
    love.graphics.origin()

    love.graphics.setColor(COL.dim)
    love.graphics.rectangle("fill", 0, 0, scrWidth, scrHeight)

    MapSelect.buildLayout()
    local panel = MapSelect.panelBox()

    MapSelect.drawPanel(panel)
    MapSelect.drawRows(panel)
    MapSelect.drawBottom(panel)

    if MapSelect.prompt then MapSelect.drawPrompt() end
    if MapSelect.confirm then MapSelect.drawConfirm() end

    love.graphics.pop()
end

function MapSelect.drawPanel(panel)
    MapSelect.drawBox(panel)
    local title = MapSelect.mode == "horde" and "SWITCH HORDE MAP" or "MAP SELECT"
    Horde.drawCenteredText(title, panel.x + PANEL_WIDTH / 2, panel.y + PADDING, 28, 1)
end

function MapSelect.drawRows(panel)
    for _, row in ipairs(MapSelect.rows) do
        if row.index == MapSelect.selected then
            love.graphics.setColor(COL.selected)
            love.graphics.rectangle("fill", row.hit.x, row.hit.y, row.hit.w, row.hit.h)
        end
        if MapSelect.mode == "builder" then
            MapSelect.drawButton(row.delete, "Delete", 15, COL.delete)
            MapSelect.drawButton(row.rename, "Rename", 15, COL.rename)
            MapSelect.drawButton(row.edit, "Edit", 15, COL.edit)
        end
        MapSelect.drawLabel(row.name, row.hit.x + 8, row.hit.y + 8, 20)
    end
end

function MapSelect.drawBottom(panel)
    for _, btn in ipairs(MapSelect.bottomButtons) do
        MapSelect.drawButton(btn.rect, btn.label, 18, COL.primary)
    end
    MapSelect.drawLabel("Esc - back", panel.x + PADDING, panel.y + panel.h - 22, 14)
end

function MapSelect.drawPrompt()
    local box = MapSelect.modal
    MapSelect.drawBox(box)
    MapSelect.drawLabel(MapSelect.prompt.kind == "rename" and "Rename map" or "New map name", box.x + 20, box.y + 14, 22)
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("line", box.progress.x, box.progress.y, box.progress.w, box.progress.h)
    MapSelect.drawButton(box.cancel, "Cancel", 16, COL.delete)
    MapSelect.drawButton(box.ok, "OK", 16, COL.edit)
    MapSelect.drawLabel(MapSelect.prompt.buffer .. "|", box.progress.x + 6, box.progress.y - 2, 20)
end

function MapSelect.drawConfirm()
    local box = MapSelect.modal
    MapSelect.drawBox(box)
    MapSelect.drawLabel("Delete '" .. MapSelect.confirm.map .. "'?", box.x + 20, box.y + 18, 20)
    MapSelect.drawButton(box.cancel, "Cancel", 16, COL.delete)
    MapSelect.drawButton(box.ok, "Yes", 16, COL.edit)
end

function MapSelect.drawBox(rect)
    love.graphics.setColor(COL.panel)
    love.graphics.rectangle("fill", rect.x, rect.y, rect.w, rect.h)
    love.graphics.setColor(COL.border)
    love.graphics.rectangle("line", rect.x, rect.y, rect.w, rect.h)
end

function MapSelect.drawButton(rect, label, size, color)
    love.graphics.setColor(color)
    love.graphics.rectangle("fill", rect.x, rect.y, rect.w, rect.h)
    local th = Fonts.get(size):getHeight()
    Horde.drawCenteredText(label, rect.x + rect.w / 2, rect.y + (rect.h - th) / 2, size, 1)
end

function MapSelect.drawLabel(text, x, y, size)
    love.graphics.setFont(Fonts.get(size))
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(text, x, y)
end

return MapSelect