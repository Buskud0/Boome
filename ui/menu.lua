Menu = Object:extend()

local function buildScreens()
    return {
        main = {
            title = "PAUSED",
            options = {
                { label = "Resume",             action = "resume" },
                { label = function() return gameMode == "mapbuilder" and "Horde Mode" or "Map Builder" end, action = "toggle_mode" },
                { label = "Multiplayer Server", action = "coming_soon" },
                { label = "Lobby Settings",     action = "screen_lobby" },
                { label = "Stats",              action = "screen_stats" },
                { label = "Quit",               action = "quit" },
            },
        },
        stats = {
            title = "STATS",
            options = {
                { label = function() return "Max kills: " .. Horde.maxKills end,   action = nil },
                { label = function() return "Max rounds: " .. Horde.maxRounds end, action = nil },
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

local PANEL_WIDTH = 350
local OPTION_HEIGHT = 36
local OPTION_GAP = 42
local TITLE_OFFSET_Y = 10
local OPTIONS_OFFSET_Y = 60

-------------------------------------------------------------------
-- Lifecycle
-------------------------------------------------------------------

function Menu:new()
    self.screens = buildScreens()
    self.stack = {}
    self.selection = 1
    self.lastMouseX = -1
    self.lastMouseY = -1
    self.notification = nil
    self.notificationTimeLeft = 0
    self.optionRects = {}
end

function Menu:update(dt)
    if self.notificationTimeLeft > 0 then
        self.notificationTimeLeft = self.notificationTimeLeft - dt
        if self.notificationTimeLeft <= 0 then
            self.notification = nil
        end
    end
end

-------------------------------------------------------------------
-- Screen stack
-------------------------------------------------------------------

function Menu:currentScreen()
    return self.screens[self.stack[#self.stack]]
end

function Menu:openSubmenu(name)
    ignoreMouseUntilRelease = true
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

-------------------------------------------------------------------
-- Input
-------------------------------------------------------------------

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

-------------------------------------------------------------------
-- Actions
-------------------------------------------------------------------

function Menu:doAction(action)
    if action == "resume" then
        self.stack = {}
    elseif action == "back" then
        self:closeSubmenu()
    elseif action == "toggle_mode" then
        self.stack = {}
        if gameMode == "mapbuilder" then
            enterHordeMode()
        else
            enterMapBuilder()
        end
    elseif action == "coming_soon" then
        self.notification = "Coming soon!"
        self.notificationTimeLeft = 2
    elseif action == "quit" then
        love.event.quit()
    elseif action:match("^screen_") then
        self:openSubmenu(action:match("^screen_(.+)$"))
    end
end

-------------------------------------------------------------------
-- Drawing
-------------------------------------------------------------------

function Menu:draw()
    self.optionRects = {}
    local screen = self:currentScreen()
    if not screen then return end

    local panelHeight = OPTIONS_OFFSET_Y + #screen.options * OPTION_GAP
    local px = scrWidth / 2 - PANEL_WIDTH / 2 + camera.x
    local py = scrHeight / 2 - panelHeight / 2 + camera.y

    self:drawPanel(px, py, panelHeight)
    self:drawTitle(screen.title, px, py)
    self:drawOptions(screen, px, py)
    self:drawNotification(px, py, panelHeight)
end

function Menu:drawPanel(px, py, panelHeight)
    love.graphics.setColor(0.15, 0.15, 0.15, 0.95)
    love.graphics.rectangle("fill", px, py, PANEL_WIDTH, panelHeight)
    love.graphics.setColor(0.4, 0.4, 0.4)
    love.graphics.rectangle("line", px, py, PANEL_WIDTH, panelHeight)
end

function Menu:drawTitle(title, px, py)
    local font = love.graphics.newFont("fonts/Gamer.ttf", 36)
    love.graphics.setFont(font)
    love.graphics.setColor(1, 1, 1)
    local titleW = font:getWidth(title)
    love.graphics.print(title, px + PANEL_WIDTH / 2 - titleW / 2, py + TITLE_OFFSET_Y)
end

function Menu:drawOptions(screen, px, py)
    local mouseX, mouseY = Input.getMousePosition()
    mouseX = mouseX + camera.x
    mouseY = mouseY + camera.y
    local mouseMoved = mouseX ~= self.lastMouseX or mouseY ~= self.lastMouseY
    if mouseMoved then
        self.lastMouseX = mouseX
        self.lastMouseY = mouseY
    end

    local font = love.graphics.newFont("fonts/Gamer.ttf", 24)
    local optionY = py + OPTIONS_OFFSET_Y
    for i, entry in ipairs(screen.options) do
        local label = type(entry.label) == "function" and entry.label() or entry.label
        local rect = { x = px + 15, y = optionY, w = PANEL_WIDTH - 30, h = OPTION_HEIGHT }

        if mouseMoved then
            self:updateHover(entry, rect, mouseX, mouseY, i)
        end

        if i == self.selection and entry.action then
            love.graphics.setColor(0.3, 0.5, 0.7)
            love.graphics.rectangle("fill", rect.x, rect.y, rect.w, rect.h)
        end

        love.graphics.setFont(font)
        love.graphics.setColor(1, 1, 1)
        local labelW = font:getWidth(label)
        love.graphics.print(label, px + PANEL_WIDTH / 2 - labelW / 2, optionY + 6)

        self.optionRects[i] = rect
        optionY = optionY + OPTION_GAP
    end
end

function Menu:updateHover(entry, rect, mouseX, mouseY, index)
    if entry.action and
       mouseX >= rect.x and mouseX <= rect.x + rect.w and
       mouseY >= rect.y and mouseY <= rect.y + rect.h then
        self.selection = index
    end
end

function Menu:drawNotification(px, py, panelHeight)
    if not self.notification then return end
    local font = love.graphics.newFont("fonts/Gamer.ttf", 20)
    love.graphics.setFont(font)
    love.graphics.setColor(1, 0.8, 0.2)
    local msgW = font:getWidth(self.notification)
    love.graphics.print(self.notification, px + PANEL_WIDTH / 2 - msgW / 2, py + panelHeight + 10)
end
