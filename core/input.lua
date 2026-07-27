local Input = {}

function Input.load()
    local bindings = {}
    local contents = love.filesystem.read("input.txt")
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
    if key then
        if key:match("^mouse") then
            local btn = tonumber(key:match("%d+"))
            return love.mouse.isDown(btn)
        end
        return love.keyboard.isDown(key)
    end
    return false
end

function Input.getActionForKey(key)
    for action, boundKey in pairs(Input.bindings) do
        if boundKey == key then return action end
    end
    return nil
end

function Input.getMousePosition()
    return love.mouse.getX(), love.mouse.getY()
end

return Input
