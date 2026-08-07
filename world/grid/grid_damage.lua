-- Grid damage handling: damaging/destroying tiles, drops and regrowth.
-- Attaches methods to the Grid class; requires the class at attach time.

local Config = require "core.config"
local WeaponPickup = require "entities.weapon_pickup"
local Item = require "core.item"
local Explosion = require "world.physics.explosion"
local Collision = require "world.physics.collision"

local TOXIC_EXPLOSION = Config.TOXIC_BARREL_EXPLOSION

return function(Grid)
    function Grid:_damageRecord(list, index, record, amount, noExplode)
        record.health = record.health - amount
        if record.health <= 0 then
            self:_dropContents(record)
            self:_dropMaterialLoot(record)
            if self:_regrows(record.material) then
                table.insert(self.regrowingRecords, { col = record.col, row = record.row, material = record.material, object = list == self.objectRecords })
            end
            table.remove(list, index)
            self:rebuildGrid()
            if not noExplode and record.material == "toxic_barrel" then
                local cx, cy = self:recordWorldCenter(record)
                Explosion.detonate(self.state, cx, cy, TOXIC_EXPLOSION.radius, TOXIC_EXPLOSION.maxDamage, TOXIC_EXPLOSION.minDamage)
            end
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
                table.insert(self.state.weaponPickups, WeaponPickup(self.state, cx, cy, item, 0))
            end
        end
    end

    function Grid:_dropMaterialLoot(record)
        local drops = Config.OBJECT_DROPS[record.material]
        if not drops then return end
        local cx, cy = self:recordWorldCenter(record)
        for _, drop in ipairs(drops) do
            table.insert(self.state.weaponPickups, WeaponPickup(self.state, cx, cy, Item.new(drop[1], drop[2]), 0))
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
        for _, list in ipairs({ self.objectRecords, self.blockRecords }) do
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

    function Grid:destructibleRecordNear(worldX, worldY, radius)
        local minCol = math.max(1, math.floor((worldX - radius) / self.tileSize) + 1)
        local maxCol = math.min(self.cols, math.floor((worldX + radius) / self.tileSize) + 1)
        local minRow = math.max(1, math.floor((worldY - radius) / self.tileSize) + 1)
        local maxRow = math.min(self.rows, math.floor((worldY + radius) / self.tileSize) + 1)
        local best, bestD = nil, radius * radius
        for row = minRow, maxRow do
            for col = minCol, maxCol do
                local _, _, record = self:_destructibleRecordAt(col, row)
                if record then
                    local x, y, w, h = self:recordWorldRect(record)
                    local closestX = math.max(x, math.min(worldX, x + w))
                    local closestY = math.max(y, math.min(worldY, y + h))
                    local dx = worldX - closestX
                    local dy = worldY - closestY
                    local d = dx * dx + dy * dy
                    if d <= bestD then
                        bestD = d
                        best = record
                    end
                end
            end
        end
        return best
    end

    function Grid:damageRecord(record, amount)
        for _, list in ipairs({ self.objectRecords, self.blockRecords }) do
            for i = #list, 1, -1 do
                if list[i] == record then
                    self:_damageRecord(list, i, record, amount)
                    return true
                end
            end
        end
        return false
    end

    function Grid:_damageTileAt(worldX, worldY, amount, noExplode)
        local col, row = self:tileAt(worldX, worldY)
        if not col then return false end
        local list, index, record = self:_destructibleRecordAt(col, row)
        if not list then return false end
        self:_damageRecord(list, index, record, amount, noExplode)
        return true
    end

    function Grid:damageTile(worldX, worldY, amount)
        return self:_damageTileAt(worldX, worldY, amount)
    end

    function Grid:damageTileBlast(worldX, worldY, amount)
        return self:_damageTileAt(worldX, worldY, amount, true)
    end

    function Grid:repairRecord(record)
        local maxHealth = self:_maxHealth(record.material)
        if maxHealth <= 0 then return false end
        record.health = maxHealth
        return true
    end

    -- All destructible records whose tile rect the given sector touches.
    function Grid:destructibleRecordsInSector(px, py, dirX, dirY, halfAngle, radius)
        local records = {}
        for _, list in ipairs({ self.objectRecords, self.blockRecords }) do
            for _, record in ipairs(list) do
                if record.health > 0 then
                    local x, y, w, h = self:recordWorldRect(record)
                    if self:_rectHitsSector(px, py, dirX, dirY, halfAngle, radius, x, y, w, h) then
                        records[#records + 1] = record
                    end
                end
            end
        end
        return records
    end

    function Grid:_closestRectPoint(px, py, x, y, w, h)
        return math.max(x, math.min(px, x + w)), math.max(y, math.min(py, y + h))
    end

    function Grid:_rectHitsSector(px, py, dirX, dirY, halfAngle, radius, x, y, w, h)
        local cx, cy = self:_closestRectPoint(px, py, x, y, w, h)
        if Collision.circleHitsSector(px, py, dirX, dirY, halfAngle, radius, cx, cy, 0) then
            return true
        end
        local corners = {
            { x, y },
            { x + w, y },
            { x, y + h },
            { x + w, y + h },
        }
        for _, corner in ipairs(corners) do
            if Collision.circleHitsSector(px, py, dirX, dirY, halfAngle, radius, corner[1], corner[2], 0) then
                return true
            end
        end
        return false
    end

    function Grid:_healthBrightness(record)
        local maxHealth = self:_maxHealth(record.material)
        if maxHealth <= 0 then return 1 end
        return math.max(0, math.min(1, record.health / maxHealth))
    end
end
