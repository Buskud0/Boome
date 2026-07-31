local Input = {}

local MODIFIER_KEYS = {
    ctrl = { "lctrl", "rctrl" },
    shift = { "lshift", "rshift" },
    alt = { "lalt", "ralt" },
}

function Input.load()
    local bindings = {}
    local contents = love.filesystem.read("binds.txt")
    if contents then
        for line in contents:gmatch("[^\r\n]+") do
            if not line:match("^%s*#") and not line:match("^%s*$") then
                local action, key = line:match("^%s*(%S+)%s*=%s*(%S+)%s*$")
                if action and key then
                    bindings[action] = key
                end
            end
        end
    end
    Input.bindings = bindings
end

function Input.isDown(action)
    local key = Input.bindings[action]
    if not key then return false end
    if Input.isMouseBinding(key) then
        return love.mouse.isDown(Input.getMouseButton(key))
    end
    if MODIFIER_KEYS[key] then
        return Input.isModifierDown(key)
    end
    return love.keyboard.isDown(key)
end

function Input.isMouseBinding(key)
    return key:match("^mouse") ~= nil
end

function Input.getMouseButton(key)
    return tonumber(key:match("%d+"))
end

function Input.getBindingParts(binding)
    local key = binding
    local modifiers = {}
    while true do
        local modifier, rest = key:match("^(%a+)[+](.+)$")
        if modifier and MODIFIER_KEYS[modifier] then
            table.insert(modifiers, modifier)
            key = rest
        else
            break
        end
    end
    return key, modifiers
end

function Input.isModifierDown(modifier)
    local keys = MODIFIER_KEYS[modifier]
    if not keys then return false end
    for _, key in ipairs(keys) do
        if love.keyboard.isDown(key) then return true end
    end
    return false
end

function Input.areModifiersDown(modifiers)
    for _, modifier in ipairs(modifiers) do
        if not Input.isModifierDown(modifier) then return false end
    end
    return true
end

function Input.isActionBoundToKey(action, key)
    local binding = Input.bindings[action]
    if not binding then return false end
    local boundKey, modifiers = Input.getBindingParts(binding)
    return boundKey == key and Input.areModifiersDown(modifiers)
end

function Input.getActionForKey(key)
    local actions = {}
    for action, binding in pairs(Input.bindings) do
        local boundKey, modifiers = Input.getBindingParts(binding)
        if boundKey == key and Input.areModifiersDown(modifiers) then
            table.insert(actions, action)
        end
    end
    table.sort(actions)
    return actions[1]
end

function Input.getMousePosition()
    return love.mouse.getX(), love.mouse.getY()
end

return Input
