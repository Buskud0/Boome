-- Factory for instantiating the right weapon subclass from a model name.

local Config = require "core.config"
local Weapon = require "systems.weapon.weapon"
local Melee = require "systems.weapon.melee"

local WeaponDefs = {}

function WeaponDefs.create(state, model)
    local stats = Config.WEAPONS[model]
    if stats and stats.weaponType == "melee" then
        return Melee(state, model)
    end
    return Weapon.Gun(state, model)
end

return WeaponDefs
