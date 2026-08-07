local Container = {}
Container.__index = Container

function Container.new(size)
    return setmetatable({ size = size, slots = {} }, Container)
end

function Container:get(i)
    return self.slots[i]
end

function Container:set(i, item)
    if i < 1 or i > self.size then return false end
    self.slots[i] = item
    return true
end

return Container