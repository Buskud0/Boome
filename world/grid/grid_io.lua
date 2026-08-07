-- Grid persistence: saving records to text and loading them back.
-- Attaches methods to the Grid class.

return function(Grid)
    function Grid:saveData()
        local lines = {}
        for _, record in ipairs(self.blockRecords) do
            if record.material ~= "grass" then
                table.insert(lines, record.col .. "," .. record.row .. "," .. record.material)
            end
        end
        for _, record in ipairs(self.objectRecords) do
            table.insert(lines, "o," .. record.col .. "," .. record.row .. "," .. record.material)
        end
        return table.concat(lines, "\n")
    end

    function Grid:loadData(data)
        self.grid = {}
        self.objects = {}
        self.blockRecords = {}
        self.objectRecords = {}
        if not data or #data == 0 then return end
        for line in data:gmatch("[^\r\n]+") do
            local x, y, material = line:match("^o,(%d+),(%d+),(%S+)$")
            if x then
                self:placeObject(tonumber(x), tonumber(y), material)
            else
                x, y, material = line:match("^(%d+),(%d+),(%S+)$")
                if x and material ~= "grass" then
                    self:placeBlock(tonumber(x), tonumber(y), material)
                end
            end
        end
    end
end
