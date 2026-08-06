-- ============================================================
-- Central configuration.
-- Every constant / data table lives here so modules can
-- alias what they need as a local at the top of the file.
-- ============================================================

local Config = {}

-- main.lua
Config.MAP_WIDTH = 1000
Config.MAP_HEIGHT = 1000
Config.HORDE_CAMERA_ZOOM = 1.3

-- gamemodes/horde.lua
Config.ROUND_FREEZE_TIME = 0
Config.ROUND_TEXT_TIME = 5

-- gamemodes/horde_waves.lua
Config.ZOMBIE_BUDGET_BASE = 10
Config.ZOMBIE_BUDGET_LINEAR = 3
Config.ZOMBIE_BUDGET_QUAD = 0.25
Config.ZOMBIE_BUDGET_CAP = 200
Config.ZOMBIE_TYPE_COSTS = { rotter = 1, runner = 1, lastBreath = 3, spidor = 1 }
Config.ZOMBIE_RUNNER_UNLOCK_ROUND = 2
Config.ZOMBIE_LASTBREATH_UNLOCK_ROUND = 3
Config.ZOMBIE_SPIDOR_UNLOCK_ROUND = 1
Config.ZOMBIE_RUNNER_WEIGHT_BASE = 0.1
Config.ZOMBIE_RUNNER_WEIGHT_GROWTH = 0.03
Config.ZOMBIE_LASTBREATH_WEIGHT_BASE = 0.05
Config.ZOMBIE_LASTBREATH_WEIGHT_GROWTH = 0.04
Config.ZOMBIE_SPIDOR_WEIGHT_BASE = 0.4
Config.ZOMBIE_SPIDOR_WEIGHT_FALLOFF = 0.04
Config.ZOMBIE_WEIGHT_CAP = 0.35
Config.ZOMBIE_ROTTER_WEIGHT_MIN = 0.3
Config.ZOMBIE_STATS = {
    runner = { speed = 100, maxHealth = 50, color = {0.8, 0.6, 0} },
    rotter = { speed = 50, maxHealth = 100, color = {1, 0.2, 0} },
    lastBreath = { speed = 25, maxHealth = 300, color = {1, 0.2, 0.5} },
    spidor = { speed = 50, maxHealth = 60, color = {0.4, 0, 0.8} },
}
Config.ZOMBIE_REWARDS = { runner = 5, rotter = 10, lastBreath = 15, spidor = 8 }
Config.ZOMBIE_SPAWN_INTERVAL_BASE = 2
Config.ZOMBIE_SPAWN_INTERVAL_MIN = 0.4
Config.ZOMBIE_SPAWN_INTERVAL_PER_ROUND = 0.06
Config.ZOMBIE_ACTIVE_CAP_BASE = 20
Config.ZOMBIE_ACTIVE_CAP_PER_ROUND = 1
Config.ZOMBIE_ACTIVE_CAP_MAX = 60
Config.ZOMBIE_SPAWN_MIN_DISTANCE = 500
Config.ZOMBIE_SPAWN_MAX_ATTEMPTS = 30
Config.ZOMBIE_CAP_RETRY_INTERVAL = 0.2

-- gamemodes/mapbuilder.lua
Config.MAPBUILDER_PAN_SPEED = 300
Config.MAPBUILDER_BLOCK_SIZE = 4
Config.MAPBUILDER_DRAG_THRESHOLD = 10
Config.MAPBUILDER_MAX_UNDO = 100
Config.MAPBUILDER_PLACE_INTERVAL = 0
Config.MAPBUILDER_QUICK_ACCESS_COUNT = 10
Config.MAPBUILDER_ZOOM_FACTOR = 1.1
Config.MAPBUILDER_ZOOM_MAX = 10
Config.MAPBUILDER_ZOOM_MIN = 0.1

-- ui/map_select.lua
Config.MAP_SELECT_PANEL_WIDTH = 520
Config.MAP_SELECT_ROW_HEIGHT = 42
Config.MAP_SELECT_ROW_GAP = 8
Config.MAP_SELECT_TITLE_OFFSET_Y = 16
Config.MAP_SELECT_PADDING = 20
Config.MAP_SELECT_BUTTON_WIDTH = 64
Config.MAP_SELECT_MAX_VISIBLE_ROWS = 12

-- world/grid.lua
Config.GRID_BLOCK_SIZE = 4

-- world/pathfinding.lua
Config.PATHFINDING_MAX_ITERATIONS = 10000

-- core/fonts.lua
Config.FONTS_PATH = "fonts/Gamer.ttf"

-- systems/weapon.lua
Config.WEAPON_BULLET_SPEED = 1500
Config.WEAPON_SCOPE_PAN_SPEED = 8

-- systems/melee.lua
Config.MELEE_STAB_DURATION = 0.15
Config.MELEE_STAB_STAMINA_COST = 10
Config.MELEE_SWING_DURATION = 0.15
Config.MELEE_SWING_HALF_ANGLE = math.rad(45)
Config.MELEE_SWING_STAMINA_COST = 15

-- entities/entity.lua
Config.ENTITY_HIT_SLOW_DURATION = 0.5
Config.ENTITY_HIT_SLOW_FACTOR = 0.5

-- entities/player.lua
Config.PLAYER_FOV = math.rad(100)
Config.PLAYER_LIGHT_CORNER_EPS = math.rad(0.1)
Config.PLAYER_LIGHT_DARKNESS = 0.2
Config.PLAYER_LIGHT_GRID_TIE_BREAK = 1e-6
Config.PLAYER_LIGHT_SEGMENTS = 48
Config.PLAYER_MAX_STAMINA = 100
Config.PLAYER_MIN_SCOPED_FOV = math.rad(5)
Config.PLAYER_PERIPHERAL_ALPHA = 0.35
Config.PLAYER_PERIPHERAL_RADIUS = 100
Config.PLAYER_SCOPED_FOV_BASE = 90
Config.PLAYER_SCOPED_FOV_PER_SCOPE = 0.4
Config.PLAYER_SPEED = 150
Config.PLAYER_SPRINT_DRAIN_RATE = 50
Config.PLAYER_SPRINT_MULTIPLIER = 1.5
Config.PLAYER_STAMINA_RECOVERY_RATE = 50
Config.STAMINA_REGEN_DELAY = 0.5
Config.STAMINA_SPRINT_THRESHOLD = 20

-- entities/zombie.lua
Config.ZOMBIE_PATH_RECALC_INTERVAL = 0.3
Config.ZOMBIE_SEPARATION_RADIUS = 30
Config.ZOMBIE_SEPARATION_WEIGHT = 0.7
Config.ZOMBIE_WAYPOINT_RADIUS = 6

-- ui/inventory.lua
Config.INVENTORY_BACKPACK_ROW_OFFSET = 30
Config.INVENTORY_BACKPACK_SLOTS = 5
Config.INVENTORY_BACKPACK_TITLE = "BACKPACK"
Config.INVENTORY_BACKPACK_TITLE_SIZE = 16
Config.INVENTORY_CHEST_SLOTS = 5
Config.INVENTORY_CHEST_TITLE = "BARREL"
Config.INVENTORY_DRAG_THRESHOLD = 10
Config.INVENTORY_HOTBAR_SLOTS = 5
Config.INVENTORY_SLOT_GAP = 8
Config.INVENTORY_SLOT_SIZE = 52
Config.INTERACT_RANGE = 80
Config.WEAPON_PICKUP_DELAY = 2

-- ui/mapbuilder_hud.lua
Config.MAPBUILDER_HUD_BOTTOM_MARGIN = 12
Config.MAPBUILDER_HUD_BUTTON_HEIGHT = 36
Config.MAPBUILDER_HUD_BUTTON_WIDTH = 80
Config.MAPBUILDER_HUD_SLOT_GAP = 8
Config.MAPBUILDER_HUD_SLOT_SIZE = 52

-- ui/toast.lua
Config.TOAST_FADE_DURATION = 0.5
Config.TOAST_GAP = 8
Config.TOAST_HEIGHT = 30
Config.TOAST_INVENTORY_OFFSET_Y = 12
Config.TOAST_MAX_TOASTS = 3
Config.TOAST_SLOT_SIZE = 52

-- ui/hud.lua
Config.HUD_BAR_HEIGHT = 8
Config.HUD_BAR_WIDTH = 100
Config.HUD_MONEY_COUNT_RATE = 20

-- ui/item_browser.lua
Config.ITEM_BROWSER_DRAG_THRESHOLD = 10
Config.ITEM_BROWSER_HEADER_HEIGHT = 70
Config.ITEM_BROWSER_ITEM_CELL_GAP = 28
Config.ITEM_BROWSER_ITEM_CELL_SIZE = 60
Config.ITEM_BROWSER_ITEMS_PER_ROW = 5
Config.ITEM_BROWSER_PANEL_HEIGHT = 400
Config.ITEM_BROWSER_PANEL_WIDTH = 500

-- ui/menu.lua
Config.MENU_OPTION_GAP = 42
Config.MENU_OPTION_HEIGHT = 36
Config.MENU_OPTIONS_OFFSET_Y = 60
Config.MENU_PANEL_WIDTH = 350
Config.MENU_TITLE_OFFSET_Y = 10

-- ui/buymenu.lua
Config.BUYMENU_MONEY_OFFSET_Y = 48
Config.BUYMENU_OPTION_GAP = 50
Config.BUYMENU_OPTION_HEIGHT = 36
Config.BUYMENU_OPTIONS_OFFSET_Y = 85
Config.BUYMENU_PANEL_WIDTH = 420
Config.BUYMENU_TITLE_OFFSET_Y = 10

Config.BLOCK_ITEMS = {
    dirt = { name = "Dirt", material = "dirt", health = 0, blocksMovement = false, blocksVision = false, speedMultiplier = 1 },
    grass = { name = "Grass", material = "grass", health = 0, blocksMovement = false, blocksVision = false, speedMultiplier = 1 },
    rock_path = { name = "Rock Path", material = "rock_path", health = 0, blocksMovement = false, blocksVision = false, speedMultiplier = 1 },
    shop = { name = "Shop", material = "shop", health = 0, blocksMovement = true, blocksVision = false, speedMultiplier = 1 },
    workshop = { name = "Workshop", material = "workshop", health = 0, blocksMovement = true, blocksVision = false, speedMultiplier = 1 },
    stone_wall = { name = "Stone Wall", material = "stone_wall", health = 3000, blocksMovement = true, blocksVision = false, speedMultiplier = 1 },
    water = { name = "Water", material = "water", health = 0, blocksMovement = false, blocksVision = false, speedMultiplier = 0.5 },
    wood_wall = { name = "Wood Wall", material = "wood_wall", health = 1000, blocksMovement = true, blocksVision = true, speedMultiplier = 1 },
    sand = { name = "Sand", material = "sand", health = 0, blocksMovement = false, blocksVision = false, speedMultiplier = 1 },
    glass = { name = "Glass", material = "glass", health = 50, blocksMovement = true, blocksVision = false, speedMultiplier = 1 },
}

Config.OBJECT_ITEMS = {
    toxic_barrel = { name = "Toxic Barrel", material = "toxic_barrel", health = 200, blocksMovement = true, blocksVision = false, penetrative = false },
    barrel = { name = "Barrel", material = "barrel", health = 150, blocksMovement = true, blocksVision = false, chest = true, penetrative = false },
    bush = { name = "Bush", material = "bush", health = 60, blocksMovement = false, blocksVision = false, speedMultiplier = 0.3, regrows = true, penetrative = true, bulletproof = true },
    tree = { name = "Tree", material = "tree", health = 500, blocksMovement = true, blocksVision = false, regrows = true, penetrative = false },
    stone = { name = "Stone", material = "stone", health = 1500, blocksMovement = true, blocksVision = false, regrows = true, penetrative = false },
    barricade = { name = "Barricade", material = "barricade", health = 500, blocksMovement = true, blocksVision = false, bulletproof = true },
}

Config.BUILDING_ITEMS = {}
for k, v in pairs(Config.BLOCK_ITEMS) do Config.BUILDING_ITEMS[k] = v end
for k, v in pairs(Config.OBJECT_ITEMS) do Config.BUILDING_ITEMS[k] = v end

-- grid_damage.lua: drops spawned when a material is destroyed (model, count).
Config.OBJECT_DROPS = {
    tree = { { "STICKS", 1 } },
    stone = { { "ROCKS", 1 } },
}

-- world/physics/explosion.lua
Config.TOXIC_BARREL_EXPLOSION = { radius = 140, maxDamage = 150, minDamage = 30 }

-- entities/grenade.lua
Config.GRENADE_EXPLOSION = { radius = 140, maxDamage = 150, minDamage = 30 }
Config.GRENADE_THROW_SPEED = 420
Config.GRENADE_DRAG = 2.5         -- fraction of speed lost per second while flying
Config.GRENADE_SPIN = 8           -- radians per second while airborne
Config.GRENADE_FUSE = 1
Config.GRENADE_COOLDOWN = 0.8

-- Stackable inventory items (core/item.lua, ui/inventory)
Config.ITEMS = {
    GRENADE = { name = "Grenade", price = 0, stackAmount = 5, stackSize = 99, throwable = true },
    STICKS = { name = "Sticks", price = 0, stackAmount = 1, stackSize = 99, hidden = true },
    ROCKS = { name = "Rocks", price = 0, stackAmount = 1, stackSize = 99, hidden = true },
}

Config.WEAPONS = {
    M9 = {
        automatic = false,
        damage = 13,
        magSize = 15,
        reloadTime = 1,
        firerate = 0.15,
        bulletAmount = 1,
        spread = 4,
        hipfireSpread = 8,
        price = 0,
        scope = 50,
    },
    ["MAC-10"] = {
        automatic = true,
        damage = 9,
        magSize = 30,
        reloadTime = 2,
        firerate = 0.06,
        bulletAmount = 1,
        spread = 7,
        hipfireSpread = 15,
        price = 0,
        scope = 50,
    },
    AWP = {
        automatic = false,
        damage = 299,
        magSize = 5,
        reloadTime = 3,
        firerate = 1.5,
        bulletAmount = 1,
        spread = 2,
        hipfireSpread = 14,
        price = 0,
        scope = 200,
    },
    ["REMINGTON-870"] = {
        automatic = false,
        damage = 14,
        magSize = 5,
        reloadTime = 4,
        firerate = 1,
        bulletAmount = 13,
        spread = 13,
        hipfireSpread = 25,
        price = 0,
        scope = 50,
    },
    AK47 = {
        automatic = true,
        damage = 29,
        magSize = 30,
        reloadTime = 3,
        firerate = 0.12,
        bulletAmount = 1,
        spread = 4,
        hipfireSpread = 8,
        price = 0,
        scope = 100,
    },
    BAYONET = {
        weaponType = "melee",
        automatic = false,
        damage = 53,
        firerate = 0.4,
        price = 0,
        range = 30,
        stabStaminaCost = 10,
        swingStaminaCost = 15,
    },
    FISTS = {
        weaponType = "melee",
        automatic = false,
        damage = 27,
        firerate = 0.3,
        price = 0,
        range = 20,
        stabStaminaCost = 7,
        swingStaminaCost = 10,
        hidden = true,
    },
    AXE = {
        weaponType = "melee",
        automatic = false,
        damage = 100,
        firerate = 0.8,
        price = 0,
        range = 40,
        stabStaminaCost = 45,
        swingStaminaCost = 60,
    },
}

return Config
