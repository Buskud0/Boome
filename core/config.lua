-- ============================================================
-- Settings grouped by the file that uses them
-- ============================================================

-- main.lua
MAP_WIDTH = 1000
MAP_HEIGHT = 1000
HORDE_CAMERA_ZOOM = 1.3

-- gamemodes/horde.lua
STARTING_ZOMBIE_COUNT = 10
ROUND_FREEZE_TIME = 0
ROUND_TEXT_TIME = 5

-- gamemodes/mapbuilder.lua
MAPBUILDER_PAN_SPEED = 300
MAPBUILDER_BLOCK_SIZE = 4
MAPBUILDER_DRAG_THRESHOLD = 10
MAPBUILDER_MAX_UNDO = 100
MAPBUILDER_PLACE_INTERVAL = 0.08
MAPBUILDER_QUICK_ACCESS_COUNT = 10
MAPBUILDER_ZOOM_FACTOR = 1.1
MAPBUILDER_ZOOM_MAX = 10
MAPBUILDER_ZOOM_MIN = 0.1

-- ui/map_select.lua
MAP_SELECT_PANEL_WIDTH = 520
MAP_SELECT_ROW_HEIGHT = 42
MAP_SELECT_ROW_GAP = 8
MAP_SELECT_TITLE_OFFSET_Y = 16
MAP_SELECT_PADDING = 20
MAP_SELECT_BUTTON_WIDTH = 64
MAP_SELECT_MAX_VISIBLE_ROWS = 12

-- world/grid.lua
GRID_BLOCK_SIZE = 4

-- core/pathfinding.lua
PATHFINDING_MAX_ITERATIONS = 10000

-- core/fonts.lua
FONTS_PATH = "fonts/Gamer.ttf"

-- systems/weapon.lua
WEAPON_BULLET_SPEED = 1500
WEAPON_SCOPE_PAN_SPEED = 8

-- systems/melee.lua
MELEE_STAB_DURATION = 0.15
MELEE_STAB_STAMINA_COST = 10
MELEE_SWING_DURATION = 0.15
MELEE_SWING_HALF_ANGLE = math.rad(45)
MELEE_SWING_STAMINA_COST = 15

-- entities/entity.lua
ENTITY_HIT_SLOW_DURATION = 0.5
ENTITY_HIT_SLOW_FACTOR = 0.5

-- entities/player.lua
PLAYER_FOV = math.rad(100)
PLAYER_LIGHT_CORNER_EPS = math.rad(0.1)
PLAYER_LIGHT_DARKNESS = 0.2
PLAYER_LIGHT_GRID_TIE_BREAK = 1e-6
PLAYER_LIGHT_SEGMENTS = 48
PLAYER_MAX_STAMINA = 100
PLAYER_MIN_SCOPED_FOV = math.rad(5)
PLAYER_PERIPHERAL_ALPHA = 0.35
PLAYER_PERIPHERAL_RADIUS = 100
PLAYER_SCOPED_FOV_BASE = 90
PLAYER_SCOPED_FOV_PER_SCOPE = 0.4
PLAYER_SPEED = 150
PLAYER_SPRINT_DRAIN_RATE = 50
PLAYER_SPRINT_MULTIPLIER = 1.5
PLAYER_STAMINA_RECOVERY_RATE = 50
STAMINA_REGEN_DELAY = 0.5
STAMINA_SPRINT_THRESHOLD = 20

-- entities/zombie.lua
ZOMBIE_PATH_RECALC_INTERVAL = 0.3
ZOMBIE_SEPARATION_RADIUS = 30
ZOMBIE_SEPARATION_WEIGHT = 0.7
ZOMBIE_WAYPOINT_RADIUS = 6

-- ui/inventory.lua
INVENTORY_BACKPACK_ROW_OFFSET = 30
INVENTORY_BACKPACK_SLOTS = 5
INVENTORY_BACKPACK_TITLE = "BACKPACK"
INVENTORY_BACKPACK_TITLE_SIZE = 16
INVENTORY_CHEST_SLOTS = 5
INVENTORY_CHEST_TITLE = "BARREL"
INVENTORY_DRAG_THRESHOLD = 10
INVENTORY_HOTBAR_SLOTS = 5
INVENTORY_SLOT_GAP = 8
INVENTORY_SLOT_SIZE = 52
INTERACT_RANGE = 80
WEAPON_PICKUP_DELAY = 2

-- ui/mapbuilder_hud.lua
MAPBUILDER_HUD_BOTTOM_MARGIN = 12
MAPBUILDER_HUD_BUTTON_HEIGHT = 36
MAPBUILDER_HUD_BUTTON_WIDTH = 80
MAPBUILDER_HUD_SLOT_GAP = 8
MAPBUILDER_HUD_SLOT_SIZE = 52

-- ui/toast.lua
TOAST_FADE_DURATION = 0.5
TOAST_GAP = 8
TOAST_HEIGHT = 30
TOAST_INVENTORY_OFFSET_Y = 12
TOAST_MAX_TOASTS = 3
TOAST_SLOT_SIZE = 52

-- ui/hud.lua
HUD_BAR_HEIGHT = 8
HUD_BAR_WIDTH = 100
HUD_MONEY_COUNT_RATE = 20

-- ui/item_browser.lua
ITEM_BROWSER_DRAG_THRESHOLD = 10
ITEM_BROWSER_HEADER_HEIGHT = 70
ITEM_BROWSER_ITEM_CELL_GAP = 28
ITEM_BROWSER_ITEM_CELL_SIZE = 60
ITEM_BROWSER_ITEMS_PER_ROW = 5
ITEM_BROWSER_PANEL_HEIGHT = 400
ITEM_BROWSER_PANEL_WIDTH = 500

-- ui/menu.lua
MENU_OPTION_GAP = 42
MENU_OPTION_HEIGHT = 36
MENU_OPTIONS_OFFSET_Y = 60
MENU_PANEL_WIDTH = 350
MENU_TITLE_OFFSET_Y = 10

-- ui/buymenu.lua
BUYMENU_MONEY_OFFSET_Y = 48
BUYMENU_OPTION_GAP = 50
BUYMENU_OPTION_HEIGHT = 36
BUYMENU_OPTIONS_OFFSET_Y = 85
BUYMENU_PANEL_WIDTH = 420
BUYMENU_TITLE_OFFSET_Y = 10

BLOCK_ITEMS = {
    dirt = { name = "Dirt", material = "dirt", health = 0, blocksMovement = false, blocksVision = false, speedMultiplier = 0.85 },
    grass = { name = "Grass", material = "grass", health = 0, blocksMovement = false, blocksVision = false, speedMultiplier = 1 },
    rock_path = { name = "Rock Path", material = "rock_path", health = 0, blocksMovement = false, blocksVision = false, speedMultiplier = 1 },
    shop = { name = "Shop", material = "shop", health = 0, blocksMovement = true, blocksVision = false, speedMultiplier = 1 },
    stone = { name = "Stone", material = "stone", health = 3000, blocksMovement = true, blocksVision = false, speedMultiplier = 1 },
    water = { name = "Water", material = "water", health = 0, blocksMovement = false, blocksVision = false, speedMultiplier = 0.5 },
    wood_wall = { name = "Wood Wall", material = "wood_wall", health = 1000, blocksMovement = true, blocksVision = true, speedMultiplier = 1 },
}

OBJECT_ITEMS = {
    toxic_barrel = { name = "Toxic Barrel", material = "toxic_barrel", health = 100, blocksMovement = true, blocksVision = false, chest = true },
    barrel = { name = "Barrel", material = "barrel", health = 80, blocksMovement = true, blocksVision = false, chest = true },
    bush = { name = "Bush", material = "bush", health = 40, blocksMovement = false, blocksVision = false, speedMultiplier = 0.3, regrows = true },
    tree = { name = "Tree", material = "tree", health = 250, blocksMovement = true, blocksVision = false, regrows = true },
}

BUILDING_ITEMS = {}
for k, v in pairs(BLOCK_ITEMS) do BUILDING_ITEMS[k] = v end
for k, v in pairs(OBJECT_ITEMS) do BUILDING_ITEMS[k] = v end

WEAPONS = {
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
        penetrationLoss = 20,
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
        penetrationLoss = 9,
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
        penetrationLoss = 75,
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
        penetrationLoss = 14,
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
        penetrationLoss = 17,
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
