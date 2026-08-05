-- Pause menu: screen stack, keyboard/mouse selection and actions.

local Config = require "core.config"
local Input = require "core.input"

local Menu = {}
Menu.__index = Menu

local PANEL_WIDTH = Config.MENU_PANEL_WIDTH
local OPTION_HEIGHT = Config.MENU_OPTION_HEIGHT
local OPTION_GAP = Config.MENU_OPTION_GAP
local TITLE_OFFSET_Y = Config.MENU_TITLE_OFFSET_Y
local OPTIONS_OFFSET_Y = Config.MENU_OPTIONS_OFFSET_Y

local function buildMainOptions(self)
    local options = {
        { label = "Resume",         action = "resume" },
        { label = "Build Maps",     action = "enter_editor" },
    }
    if self.state.gameMode == "mapbuilder" then
        table.insert(options, { label = "Switch to Horde", action = "enter_horde_now" })
    else
        table.insert(options, { label = "Switch Horde Map", action = "enter_horde_map" })
    end
    table.insert(options, { label = "Multiplayer Server", action = "coming_soon" })
    table.insert(options, { label = "Lobby Settings",     action = "screen_lobby" })
    table.insert(options, { label = "Stats",              action = "screen_stats" })
    table.insert(options, { label = "Quit",               action = "quit" })
    return options
end

local function buildScreens(self)
    return {
        main = {
            title = "PAUSED",
            options = function() return buildMainOptions(self) end,
        },
        stats = {
            title = "STATS",
            options = {
                { label = function() return "Max kills: " .. self.state.horde.maxKills end,   action = nil },
                { label = function() return "Max rounds: " .. self.state.horde.maxRounds end, action = nil },
                { label = "Back", action = "back" },
            },
        },
        lobby = {
            title = "LOBBY SETTINGS",
            options = {
                { label = "Player name", action = nil },
                { label = "Map size",    action = nil },
                { label = "Max players", action = nil },
                { label = "Back",       action = "back" },
            },
        },
    }
end

function Menu.new(state)
    local self = setmetatable({}, Menu)
    self.state = state
    self.screens = buildScreens(self)
    self.stack = {}
    self.selection = 1
    self.lastMouseX = -1
    self.lastMouseY = -1
    self.optionRects = {}
    return self
end

function Menu:currentScreen()
    local screen = self.screens[self.stack[#self.stack]]
    if screen and type(screen.options) == "function" then
        return { title = screen.title, options = screen.options() }
    end
    return screen
end

function Menu:openSubmenu(name)
    self.state.ignoreMouseUntilRelease = true
    table.insert(self.stack, name)
    self:resetFocus()
end

function Menu:closeSubmenu()
    table.remove(self.stack)
    self:resetFocus()
end

function Menu:isOpen()
    return #self.stack > 0
end

function Menu:resetFocus()
    self.selection = 1
    self.optionRects = {}
end

function Menu:handleAction(action)
    if action == "menu_up" then
        self:selectPrevious()
    elseif action == "menu_down" then
        self:selectNext()
    elseif action == "menu_confirm" then
        self:confirmCurrentSelection()
    end
end

function Menu:mousepressed(worldX, worldY)
    local index = self:optionAtPosition(worldX, worldY)
    if index then
        self.selection = index
        self:confirmCurrentSelection()
    end
end

function Menu:selectPrevious()
    local options = self:currentScreen().options
    self.selection = self.selection - 1
    if self.selection < 1 then
        self.selection = #options
    end
end

function Menu:selectNext()
    local options = self:currentScreen().options
    self.selection = self.selection + 1
    if self.selection > #options then
        self.selection = 1
    end
end

function Menu:optionAtPosition(x, y)
    for i, rect in ipairs(self.optionRects) do
        if x >= rect.x and x <= rect.x + rect.w and
           y >= rect.y and y <= rect.y + rect.h then
            return i
        end
    end
    return nil
end

function Menu:confirmCurrentSelection()
    local entry = self:currentScreen().options[self.selection]
    if entry and entry.action then
        self:doAction(entry.action)
    end
end

function Menu:doAction(action)
    if action == "resume" then
        self.stack = {}
    elseif action == "back" then
        self:closeSubmenu()
    elseif action == "enter_editor" then
        self.stack = {}
        self.state.paused = false
        self.state.enterMapSelect("builder")
    elseif action == "enter_horde_map" then
        self.stack = {}
        self.state.paused = false
        self.state.enterMapSelect("horde")
    elseif action == "enter_horde_now" then
        self.stack = {}
        self.state.paused = false
        self.state.startHordeWith(self.state.mapBuilder.currentMapName)
    elseif action == "coming_soon" then
        self.state.toast:show("Coming soon!", 2)
    elseif action == "quit" then
        love.event.quit()
    elseif action:match("^screen_") then
        self:openSubmenu(action:match("^screen_(.+)$"))
    end
end

require("ui.menu.menu_draw")(Menu)

return Menu
