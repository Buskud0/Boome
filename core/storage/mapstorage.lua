local MapStorage = {}

local MAPS_DIR = "maps"
local SELECTED_FILE = "selected_map.txt"
local LEGACY_FILE = "map.txt"

local baseDir = nil

local function isWindows()
    return package.config:sub(1, 1) == "\\"
end

local function readFile(path)
    local f = io.open(path, "r")
    if not f then return nil end
    local content = f:read("*a")
    f:close()
    return content
end

local function writeFile(path, content)
    local f = io.open(path, "w")
    if not f then return false end
    f:write(content or "")
    f:close()
    return true
end

function MapStorage.getBaseDir()
    if baseDir then return baseDir end
    local source = love.filesystem.getSource()
    if source and source:match("%.love$") then
        source = source:match("^(.*)[/\\]") or source
    end
    baseDir = source or love.filesystem.getWorkingDirectory()
    return baseDir
end

function MapStorage.mapsDir()
    return MapStorage.getBaseDir() .. "/" .. MAPS_DIR
end

function MapStorage.pathFor(name)
    return MapStorage.mapsDir() .. "/" .. name .. ".txt"
end

function MapStorage.selectedPath()
    return MapStorage.getBaseDir() .. "/" .. SELECTED_FILE
end

function MapStorage.legacyPath()
    return MapStorage.getBaseDir() .. "/" .. LEGACY_FILE
end

function MapStorage.ensureDirectory()
    local dir = MapStorage.mapsDir()
    if isWindows() then
        os.execute('if not exist "' .. dir .. '" mkdir "' .. dir .. '"')
    else
        os.execute('mkdir -p "' .. dir .. '"')
    end
end

function MapStorage.isValidName(name)
    if not name then return false end
    if name == "" then return false end
    if name:match("[/\\%c]") then return false end
    return not name:match("^%s+$")
end

function MapStorage.mapExists(name)
    if not MapStorage.isValidName(name) then return false end
    return readFile(MapStorage.pathFor(name)) ~= nil
end

function MapStorage.listMaps()
    MapStorage.ensureDirectory()
    local names = {}
    local dir = MapStorage.mapsDir()
    local cmd = isWindows() and ('dir /b "' .. dir .. '"') or ('ls -1 "' .. dir .. '"')
    local pipe = io.popen(cmd)
    if pipe then
        for line in pipe:lines() do
            local name = line:match("^(.*)%.txt$")
            if name then table.insert(names, name) end
        end
        pipe:close()
    end
    table.sort(names)
    return names
end

function MapStorage.loadMap(name)
    if not MapStorage.isValidName(name) then return nil end
    return readFile(MapStorage.pathFor(name))
end

function MapStorage.saveMap(name, content)
    if not MapStorage.isValidName(name) then return false end
    MapStorage.ensureDirectory()
    return writeFile(MapStorage.pathFor(name), content or "")
end

function MapStorage.deleteMap(name)
    if not MapStorage.isValidName(name) then return false end
    if not MapStorage.mapExists(name) then return false end
    return os.remove(MapStorage.pathFor(name))
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
    local name = readFile(MapStorage.selectedPath())
    if not name then return nil end
    name = name:gsub("%s+", "")
    if name == "" then return nil end
    return name
end

function MapStorage.setSelectedMap(name)
    if not MapStorage.isValidName(name) then return false end
    return writeFile(MapStorage.selectedPath(), name)
end

function MapStorage.migrateLegacyMap(defaultName)
    local content = readFile(MapStorage.legacyPath())
    if not content then return false end
    if not MapStorage.saveMap(defaultName, content) then return false end
    os.remove(MapStorage.legacyPath())
    return true
end

return MapStorage
