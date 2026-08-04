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

function Container:remove(i)
    local item = self.slots[i]
    if item then self.slots[i] = nil end
    return item
end

function Container:findEmpty()
    for i = 1, self.size do
        if not self.slots[i] then return i end
    end
    return nil
end

function Container:add(item)
    local i = self:findEmpty()
    if i then self.slots[i] = item end
    return i
end

function Container:swap(a, b)
    self.slots[a], self.slots[b] = self.slots[b], self.slots[a]
end

function Container:count()
    local n = 0
    for _ in pairs(self.slots) do n = n + 1 end
    return n
end

function Container:isFull()
    for i = 1, self.size do
        if not self.slots[i] then return false end
    end
    return true
end

return Container