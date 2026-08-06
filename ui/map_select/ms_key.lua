-- Map select: keyboard and mouse input. Attaches methods to the MapSelect factory.

local Config = require "core.config"
local Input = require "core.input"

local NAME_LIMIT = 24
local MAX_VISIBLE = Config.MAP_SELECT_MAX_VISIBLE_ROWS

local function isPointInRect(x, y, rect)
    if not rect then return false end
    return x >= rect.x and x <= rect.x + rect.w and y >= rect.y and y <= rect.y + rect.h
end

return function(MapSelect)
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
end
