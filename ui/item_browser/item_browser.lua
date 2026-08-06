-- Building-item browser: core state and lifecycle. Filtering, drag/drop and
-- draw behavior are attached by the mixins required at the bottom of this file.

local Config = require "core.config"

local PANEL_WIDTH = Config.ITEM_BROWSER_PANEL_WIDTH
local PANEL_HEIGHT = Config.ITEM_BROWSER_PANEL_HEIGHT

local function buildItemList()
    local all = {}
    for key, item in pairs(Config.BLOCK_ITEMS) do
        table.insert(all, { key = key, name = item.name, material = item.material })
    end
    for key, item in pairs(Config.OBJECT_ITEMS) do
        table.insert(all, { key = key, name = item.name, material = item.material })
    end
    table.sort(all, function(a, b) return a.name < b.name end)
    return all
end

local ItemBrowser = {}
ItemBrowser.__index = ItemBrowser

function ItemBrowser.new(state)
    local self = setmetatable({}, ItemBrowser)
    self.state = state
    self.allItems = buildItemList()
    self.isOpen = false
    self.searchQuery = ""
    self.filteredItems = {}
    self.draggedItem = nil
    self.scrollY = 0
    self.consumeNextText = false
    self.searchFocused = false
    self.dragStartX = 0
    self.dragStartY = 0
    return self
end

function ItemBrowser:getPanelPosition()
    local px = math.floor(self.state.scrWidth / 2 - PANEL_WIDTH / 2 + self.state.camera.x)
    local py = math.floor(self.state.scrHeight / 2 - PANEL_HEIGHT / 2 + self.state.camera.y)
    return px, py
end

function ItemBrowser:open()
    self.state.ignoreMouseUntilRelease = true
    if #self.allItems == 0 then self.allItems = buildItemList() end
    self.isOpen = true
    self.searchQuery = ""
    self.scrollY = 0
    self.draggedItem = nil
    self.searchFocused = false
    self.dragStartX = 0
    self.dragStartY = 0
    self:filterItems()
end

function ItemBrowser:close()
    self.isOpen = false
    self.draggedItem = nil
    self.searchFocused = false
end

function ItemBrowser:toggle()
    if self.isOpen then self:close() else self:open() end
end

require("ui.item_browser.ib_filter")(ItemBrowser)
require("ui.item_browser.ib_drag")(ItemBrowser)
require("ui.item_browser.ib_draw")(ItemBrowser)

return ItemBrowser
