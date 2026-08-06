-- Toast notifications: core state and lifecycle. Draw behavior is attached by
-- the mixin required at the bottom of this file.

local Config = require "core.config"

local MAX_TOASTS = Config.TOAST_MAX_TOASTS

local Toast = {}
Toast.__index = Toast

function Toast.new(state)
    local self = setmetatable({}, Toast)
    self.state = state
    self.activeToasts = {}
    return self
end

function Toast:show(message, duration)
    if #self.activeToasts >= MAX_TOASTS then
        table.remove(self.activeToasts, 1)
    end
    table.insert(self.activeToasts, {
        message = message,
        timer = duration,
    })
end

function Toast:update(dt)
    for i = #self.activeToasts, 1, -1 do
        local toast = self.activeToasts[i]
        toast.timer = toast.timer - dt
        if toast.timer <= 0 then
            table.remove(self.activeToasts, i)
        end
    end
end

require("ui.toast.toast_draw")(Toast)

return Toast
