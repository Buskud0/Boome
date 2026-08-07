-- Workshop crafting: core state and lifecycle. Crafting logic and draw
-- behavior are attached by the mixins required at the bottom of this file.

local CraftMenu = {}
CraftMenu.__index = CraftMenu

function CraftMenu.new(state)
    local self = setmetatable({}, CraftMenu)
    self.state = state
    self.isOpen = false
    self.selection = 1
    self.optionRects = {}
    self.sortedItems = {}
    self.lastMouseX = -1
    self.lastMouseY = -1
    self.useMouseSelection = true
    return self
end

function CraftMenu:open()
    self.state.ignoreMouseUntilRelease = true
    self.sortedItems = self:getRecipesSorted()
    self.isOpen = true
    self.selection = 1
    self.optionRects = {}
    self.useMouseSelection = true
    self.lastMouseX = -1
    self.lastMouseY = -1
    self.state.inventory:open()
end

function CraftMenu:close()
    self.isOpen = false
    self.optionRects = {}
    self.sortedItems = {}
    self.state.inventory:close()
end

require("ui.craftmenu.craft_logic")(CraftMenu)
require("ui.craftmenu.craft_draw")(CraftMenu)
require("ui.menu_common")(CraftMenu)

return CraftMenu
