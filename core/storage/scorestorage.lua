-- Persistence for the best-round / best-kills score record.

local ScoreStorage = {}

local RECORD_FILE = "record.txt"

function ScoreStorage.load()
    local record = love.filesystem.read(RECORD_FILE)
    if not record then return 0, 0 end
    local maxRounds, maxKills = record:match("(%d+)%s+(%d+)")
    return tonumber(maxRounds) or 0, tonumber(maxKills) or 0
end

function ScoreStorage.save(maxRounds, maxKills)
    love.filesystem.write(RECORD_FILE, maxRounds .. " " .. maxKills)
end

return ScoreStorage
