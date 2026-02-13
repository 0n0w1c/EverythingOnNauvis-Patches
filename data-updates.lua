-- ---------------------------------------------------------------------------
-- Fix: Remove lava and ammoniacal solution tiles from the effects
-- ---------------------------------------------------------------------------
local projectile = data.raw.projectile and data.raw.projectile["atomic-rocket"]
if projectile
    and projectile.action
    and projectile.action.action_delivery
    and projectile.action.action_delivery.target_effects
then
    local remove = {
        ["nuke-effects-vulcanus"] = true,
        ["nuke-effects-aquilo"] = true,
    }

    local filtered = {}
    for _, effect in ipairs(projectile.action.action_delivery.target_effects) do
        if not (effect.type == "create-entity" and remove[effect.entity_name]) then
            table.insert(filtered, effect)
        end
    end

    projectile.action.action_delivery.target_effects = filtered
end

-- ---------------------------------------------------------------------------
-- Fix: Remove fish from Vulcanus areas
-- ---------------------------------------------------------------------------
local fish = data.raw["fish"] and data.raw["fish"]["fish"]
if fish and fish.autoplace and fish.autoplace.probability_expression then
    fish.autoplace.probability_expression =
        "eon_mask_off_vulcano_terrain(" .. fish.autoplace.probability_expression .. ")"
end

-- ---------------------------------------------------------------------------
-- Fix: Remove dead-grey-trunk from Vulcanus areas
-- ---------------------------------------------------------------------------
local dead_tree = data.raw["tree"] and data.raw["tree"]["dead-grey-trunk"]
if dead_tree and dead_tree.autoplace and dead_tree.autoplace.probability_expression then
    dead_tree.autoplace.probability_expression =
        "eon_mask_off_vulcano_terrain(" .. dead_tree.autoplace.probability_expression .. ")"
end

-- ---------------------------------------------------------------------------
-- Fix: Add ashland trees to Vulcanus areas
-- ---------------------------------------------------------------------------
data:extend({
    {
        type = "noise-expression",
        name = "eon_vulcanus_ashland_tree_density",
        -- 0.02 = baseline chance, 0.1 = how “patchy”
        expression = "clamp(0.02 + 0.1 * tree_small_noise, 0, 1)"
    },
})

local function spawn_tree_in_vulcanus(tree_name, multiplier)
    local tree = data.raw["tree"] and data.raw["tree"][tree_name]
    if not (tree and tree.autoplace) then return end

    multiplier = multiplier or 1

    tree.autoplace.probability_expression =
        "eon_mask_vulcano_terrain(" ..
        (multiplier == 1 and "eon_vulcanus_ashland_tree_density"
            or (multiplier .. " * eon_vulcanus_ashland_tree_density")) ..
        ")"
end

spawn_tree_in_vulcanus("ashland-lichen-tree", 1.0)
spawn_tree_in_vulcanus("ashland-lichen-tree-flaming", 0.25)

data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.entity.settings["ashland-lichen-tree"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.entity.settings["ashland-lichen-tree-flaming"] = {}

-- ---------------------------------------------------------------------------
-- Fix: Add lubricant as a prerequisite for the foundry technology
-- ---------------------------------------------------------------------------
local foundry = data.raw["technology"]["foundry"]
if foundry and foundry.prerequisites then
    local found = false
    for _, prerequisite in ipairs(foundry.prerequisites) do
        if prerequisite == "lubricant" then
            found = true
            break
        end
    end

    if not found then table.insert(foundry.prerequisites, "lubricant") end
end

-- ---------------------------------------------------------------------------
-- Fix: Remove calcite resource category
-- ---------------------------------------------------------------------------
local calcite = data.raw["resource"]["calcite"]
if calcite then
    calcite.category = nil
end

-- ---------------------------------------------------------------------------
-- Fix: Gleba units react to pollution
-- ---------------------------------------------------------------------------
local setting = settings.startup["eon_patch_gleba_enemies_react_to_pollution"]
if setting and setting.value then
    local function move_key_spores_to_pollution(absorptions)
        if not absorptions then return end
        if absorptions.spores == nil then return end

        if absorptions.pollution == nil then
            absorptions.pollution = absorptions.spores
        end

        absorptions.spores = nil
    end

    for _, tile in pairs(data.raw["tile"] or {}) do
        move_key_spores_to_pollution(tile.absorptions_per_second)
    end

    for _, proto in pairs(data.raw["unit"] or {}) do
        move_key_spores_to_pollution(proto.absorptions_to_join_attack)
    end

    for _, proto in pairs(data.raw["spider-unit"] or {}) do
        move_key_spores_to_pollution(proto.absorptions_to_join_attack)
    end

    for _, proto in pairs(data.raw["unit-spawner"] or {}) do
        move_key_spores_to_pollution(proto.absorptions_per_second)
    end
end

if data.raw["plant"]["jellystem"] then
    data.raw["plant"]["jellystem"].harvest_emissions = {
        pollution = 15,
    }
end

if data.raw["plant"]["yumako-tree"] then
    data.raw["plant"]["yumako-tree"].harvest_emissions = {
        pollution = 15,
    }
end

if data.raw["agricultural-tower"]["agricultural-camp"] then
    data.raw["agricultural-tower"]["agricultural-camp"].energy_source.emissions_per_minute = {
        pollution = 4,
    }
end

if data.raw["agricultural-tower"]["agricultural-tower"] then
    data.raw["agricultural-tower"]["agricultural-tower"].energy_source.emissions_per_minute = {
        pollution = 4,
    }
end
