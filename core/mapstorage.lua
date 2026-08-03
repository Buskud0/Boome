local MapStorage = {}

local MAPS_DIR = "maps"
local SELECTED_FILE = "selected_map.txt"
local LEGACY_FILE = "map.txt"

function MapStorage.pathFor(name)
    return MAPS_DIR .. "/" .. name .. ".txt"
end

function MapStorage.ensureDirectory()
    love.filesystem.createDirectory(MAPS_DIR)
end

function MapStorage.isValidName(name)
    if not name then return false end
    if name == "" then return false end
    if name:match("[/\\%c]") then return false end
    return not name:match("^%s+$")
end

function MapStorage.mapExists(name)
    if not MapStorage.isValidName(name) then return false end
    return love.filesystem.getInfo(MapStorage.pathFor(name)) ~= nil
end

function MapStorage.listMaps()
    MapStorage.ensureDirectory()
    local names = {}
    for _, file in ipairs(love.filesystem.getDirectoryItems(MAPS_DIR)) do
        local name = file:match("^(.*)%.txt$")
        if name then table.insert(names, name) end
    end
    table.sort(names)
    return names
end

function MapStorage.loadMap(name)
    if not MapStorage.isValidName(name) then return nil end
    return love.filesystem.read(MapStorage.pathFor(name))
end

function MapStorage.saveMap(name, content)
    if not MapStorage.isValidName(name) then return false end
    MapStorage.ensureDirectory()
    return love.filesystem.write(MapStorage.pathFor(name), content or "")
end

function MapStorage.deleteMap(name)
    if not MapStorage.isValidName(name) then return false end
    if not MapStorage.mapExists(name) then return false end
    return love.filesystem.remove(MapStorage.pathFor(name))
end

function MapStorage.renameMap(oldName, newName)
    if not MapStorage.isValidName(newName) then return false end
    if MapStorage.mapExists(newName) then return false end
    local content = MapStorage.loadMap(oldName)
    if content == nil then return false end
    if not MapStorage.saveMap(newName, content) then return false end
    MapStorage.deleteMap(oldName)
    return true
end

function MapStorage.getSelectedMap()
    local name = love.filesystem.read(SELECTED_FILE)
    if not name then return nil end
    name = name:gsub("%s+", "")
    if name == "" then return nil end
    return name
end

function MapStorage.setSelectedMap(name)
    if not MapStorage.isValidName(name) then return false end
    return love.filesystem.write(SELECTED_FILE, name)
end

function MapStorage.migrateLegacyMap(defaultName)
    if not love.filesystem.getInfo(LEGACY_FILE) then return false end
    local content = love.filesystem.read(LEGACY_FILE)
    if not MapStorage.saveMap(defaultName, content) then return false end
    love.filesystem.remove(LEGACY_FILE)
    return true
end

return MapStorage
