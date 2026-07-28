MAP_WIDTH = 1000
MAP_HEIGHT = 1000
STARTING_ZOMBIE_COUNT = 2

PLAYER_SPEED = 175
PLAYER_MAX_STAMINA = 100
PLAYER_SPRINT_MULTIPLIER = 1.5
PLAYER_SPRINT_DRAIN_RATE = 80
PLAYER_STAMINA_RECOVERY_RATE = 40
PLAYER_SPRINT_THRESHOLD = 30

WEAPON_BULLET_SPEED = 1500

BUILDING_ITEMS = {
    wood_wall = { name = "Wood Wall", material = "wood_wall", destructable = true, blocksMovement = true },
    barrel = { name = "Barrel", material = "barrel", destructable = true, blocksMovement = true },
    bush = { name = "Bush", material = "bush", destructable = true, blocksMovement = false },
    stone = { name = "Stone", material = "stone", destructable = true, blocksMovement = true },
    toxic_barrel = { name = "Toxic Barrel", material = "toxic_barrel", destructable = true, blocksMovement = true },
    tree = { name = "Tree", material = "tree", destructable = true, blocksMovement = true },
    shop = { name = "Shop", material = "shop", destructable = false, blocksMovement = true },
    dirt = { name = "Dirt", material = "dirt", destructable = false, blocksMovement = false },
    grass = { name = "Grass", material = "grass", destructable = false, blocksMovement = false },
    rock_path = { name = "Rock Path", material = "rock_path", destructable = false, blocksMovement = false },
    water = { name = "Water", material = "water", destructable = false, blocksMovement = false },
}

WEAPONS = {
    M9 = {
        automatic = false,
        damage = 13,
        magSize = 15,
        reloadTime = 1,
        firerate = 0.15,
        bulletAmount = 1,
        spread = 2,
        price = 0,
    },
    ["MAC-10"] = {
        automatic = true,
        damage = 9,
        magSize = 30,
        reloadTime = 2,
        firerate = 0.06,
        bulletAmount = 1,
        spread = 7,
        price = 5,
    },
    ["REMINGTON-870"] = {
        automatic = false,
        damage = 14,
        magSize = 5,
        reloadTime = 4,
        firerate = 1,
        bulletAmount = 13,
        spread = 13,
        price = 5,
    },
    AWP = {
        automatic = false,
        damage = 307,
        magSize = 5,
        reloadTime = 3,
        firerate = 1.5,
        bulletAmount = 1,
        spread = 0,
        price = 5,
    },
    AK47 = {
        automatic = true,
        damage = 29,
        magSize = 30,
        reloadTime = 3,
        firerate = 0.12,
        bulletAmount = 1,
        spread = 3,
        price = 5,
    },
}
