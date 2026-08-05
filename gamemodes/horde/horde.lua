-- Horde mode core: round flow, reset, and the main update loop.
-- State is injected via the constructor; gameplay state lives on the instance.

local Config = require "core.config"
local ScoreStorage = require "core.storage.scorestorage"
local EntityCollision = require "world.physics.entity_collision"

local Horde = {}
Horde.__index = Horde

local STARTING_ZOMBIE_COUNT = Config.STARTING_ZOMBIE_COUNT
local ROUND_FREEZE_TIME = Config.ROUND_FREEZE_TIME
local ROUND_TEXT_TIME = Config.ROUND_TEXT_TIME

function Horde.new(state)
    local self = setmetatable({}, Horde)
    self.state = state
    self.maxRounds, self.maxKills = ScoreStorage.load()
    return self
end

function Horde:reset()
    self.state.inventory:close()
    self.state.currentRound = 1
    self.zombieCount = STARTING_ZOMBIE_COUNT
    self.waveState = "intro"
    self.introTimer = ROUND_FREEZE_TIME
    self.roundTextTimer = ROUND_TEXT_TIME
    self.spawnQueue = {}
    self.spawnTimer = 0
    self:buildQueue()
end

function Horde:waveUpdate(dt)
    if self.roundTextTimer and self.roundTextTimer > 0 then
        self.roundTextTimer = math.max(0, self.roundTextTimer - dt)
    end
    if self.waveState == "intro" then
        self:updateIntro(dt)
    elseif self.waveState == "spawning" then
        self:updateSpawning(dt)
    elseif self.waveState == "waiting" then
        self:updateWaiting()
    end
end

function Horde:updateIntro(dt)
    self.introTimer = self.introTimer - dt
    if self.introTimer <= 0 then
        self.waveState = "spawning"
        self.spawnTimer = 2
    end
end

function Horde:updateSpawning(dt)
    self.spawnTimer = self.spawnTimer - dt
    if self.spawnTimer <= 0 and #self.spawnQueue > 0 then
        self:spawnNextQueuedZombie()
    end
    if #self.spawnQueue == 0 then
        self.waveState = "waiting"
    end
end

function Horde:updateWaiting()
    if #self.state.zombies == 0 then
        self:startNextRound()
    end
end

function Horde:startNextRound()
    self.state.currentRound = self.state.currentRound + 1
    self.zombieCount = self.zombieCount + 2
    self.state.grid:regrowAll()
    self:refillWeaponAmmo()
    self:buildQueue()
    self.waveState = "intro"
    self.introTimer = ROUND_FREEZE_TIME
    self.roundTextTimer = ROUND_TEXT_TIME
end

function Horde:refillWeaponAmmo()
    for _, w in ipairs(self.state.weapons) do
        if w.magSize then
            w.reloadCooldown = 0
            w.capacity = w.magSize
        end
    end
end

function Horde:updateScoreRecord()
    if self.state.currentRound - 1 > self.maxRounds then self.maxRounds = self.state.currentRound - 1 end
    if self.state.killCount > self.maxKills then self.maxKills = self.state.killCount end
end

function Horde:mainUpdate(dt)
    self:setActiveWeapon()
    self:waveUpdate(dt)
    self.state.player:update(dt)
    if self.state.player.health <= 0 then
        self.state:reset()
        return
    end
    self:updateActiveWeapon(dt)
    self:updateCamera(dt)
    EntityCollision.bulletVsZombie(self.state)
    EntityCollision.seperateZombies(self.state)
    self:updateBullets(dt)
    EntityCollision.bulletVsWalls(self.state)
    self:updateZombies(dt)
    self:updatePowerUps(dt)
    self:updateWeaponPickups(dt)
    self:updateDamageTexts(dt)
    self:updateScoreRecord()
    self.state.hud:update(dt)
end

require("gamemodes.horde.horde_waves")(Horde)
require("gamemodes.horde.horde_combat")(Horde)
require("gamemodes.horde.horde_camera")(Horde)
require("gamemodes.horde.horde_draw")(Horde)

return Horde
