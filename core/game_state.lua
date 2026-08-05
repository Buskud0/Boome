-- Owns all runtime state for a game session. Entities and modules receive a
-- reference and read their data from here, so nothing relies on globals.
-- The singleton modules (horde, mapBuilder, inventory, ...) are attached by
-- main.lua before reset() runs.

local Config = require "core.config"
local Grid = require "world.grid.grid"
local Player = require "entities.player"
local WeaponDefs = require "systems.weapon.weapon_defs"
local Menu = require "ui.menu"

local GameState = {}
GameState.__index = GameState

function GameState.new()
    return setmetatable({}, GameState)
end

function GameState:reset()
    self.mapWidth = Config.MAP_WIDTH
    self.mapHeight = Config.MAP_HEIGHT
    self.killCount = 0
    self.currentWeaponIndex = 1
    self.camera = { x = 0, y = 0, zoom = Config.HORDE_CAMERA_ZOOM }
    self.bullets = {}
    self.zombies = {}
    self.weapons = {}
    self.damageTexts = {}
    self.powerUps = {}
    self.weaponPickups = {}
    self.ignoreMouseUntilRelease = false
    self.paused = false
    self.gameMode = "horde"

    self.grid = Grid(self)
    self.fists = WeaponDefs.create(self, "FISTS")
    self.weapon = self.fists

    self.mapBuilder.currentMapName = self.selectedMapName
    self.mapBuilder:load()

    self.player = Player(self, self.mapWidth / 2 - 20, self.mapHeight / 2 - 20)

    self.horde:reset()
    self.hud:reset()
    self.buyMenu:close()
    self.menu = Menu.new(self)
end

return GameState
