-- Map select: core state and lifecycle. Layout, input, actions and draw
-- behavior are attached by the mixins required at the bottom of this file.

local Config = require "core.config"
local MapStorage = require "core.storage.mapstorage"

local MAX_VISIBLE = Config.MAP_SELECT_MAX_VISIBLE_ROWS

local MapSelect = {}
MapSelect.__index = MapSelect

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

require("ui.map_select.ms_layout")(MapSelect)
require("ui.map_select.ms_key")(MapSelect)
require("ui.map_select.ms_actions")(MapSelect)
require("ui.map_select.ms_draw")(MapSelect)

return MapSelect
