-- Grid damage handling: damaging/destroying tiles, drops and regrowth.
-- Attaches methods to the Grid class; requires the class at attach time.

local Config = require "core.config"
local WeaponPickup = require "entities.weapon_pickup"

return function(Grid)
    function Grid:_damageRecord(list, index, record, amount)
        record.health = record.health - amount
        if record.health <= 0 then
            self:_dropContents(record)
            if self:_regrows(record.material) then
                table.insert(self.regrowingRecords, { col = record.col, row = record.row, material = record.material, object = list == self.objectRecords })
            end
            table.remove(list, index)
            self:rebuildGrid()
            return true
        end
        return false
    end

    function Grid:_dropContents(record)
        if not record.contents then return end
        local cx, cy = self:recordWorldCenter(record)
        for i = 1, record.contents.size do
            local item = record.contents:get(i)
            if item then
                record.contents:set(i, nil)
                table.insert(self.state.weaponPickups, WeaponPickup(self.state, cx, cy, item))
            end
        end
    end

    function Grid:_regrows(material)
        local item = Config.BUILDING_ITEMS[material]
        return item and item.regrows == true
    end

    function Grid:regrowAll()
        for _, pending in ipairs(self.regrowingRecords) do
            if pending.object then
                self:placeObject(pending.col, pending.row, pending.material)
            else
                self:placeBlock(pending.col, pending.row, pending.material)
            end
        end
        self.regrowingRecords = {}
    end

    function Grid:_destructibleRecordAt(col, row)
        for _, list in ipairs({ self.blockRecords, self.objectRecords }) do
            local index, record = self:findBlockRecord(col, row, list)
            if index and record.health > 0 then
                return list, index, record
            end
        end
        return nil
    end

    function Grid:hasDestructibleTile(worldX, worldY)
        local col, row = self:tileAt(worldX, worldY)
        if not col then return false end
        return self:_destructibleRecordAt(col, row) ~= nil
    end

    function Grid:destructibleRecordAt(worldX, worldY)
        local col, row = self:tileAt(worldX, worldY)
        if not col then return nil end
        local _, _, record = self:_destructibleRecordAt(col, row)
        return record
    end

    function Grid:damageTile(worldX, worldY, amount)
        local col, row = self:tileAt(worldX, worldY)
        if not col then return false end
        local list, index, record = self:_destructibleRecordAt(col, row)
        if not list then return false end
        self:_damageRecord(list, index, record, amount)
        return true
    end

    function Grid:_healthBrightness(record)
        local maxHealth = self:_maxHealth(record.material)
        if maxHealth <= 0 then return 1 end
        return math.max(0, math.min(1, record.health / maxHealth))
    end
end
