-- ---------------------------------------------------------------------------
-- Fix: Remove lava and ammoniacal solution tiles from the effects
-- ---------------------------------------------------------------------------
local projectile = data.raw["projectile"]["atomic-rocket"]
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
        expression = "clamp(0.02 + 0.8 * tree_small_noise, 0, 1)"
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

spawn_tree_in_vulcanus("ashland-lichen-tree", 0.05)
spawn_tree_in_vulcanus("ashland-lichen-tree-flaming", 0.02)

data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.entity.settings["ashland-lichen-tree"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.entity.settings["ashland-lichen-tree-flaming"] = {}

-- ---------------------------------------------------------------------------
-- Fix: Scale down the number vulcanus simple entity spawned
-- ---------------------------------------------------------------------------
local function scale_entity_autoplace(type_name, entity_name, factor)
    local proto = data.raw[type_name] and data.raw[type_name][entity_name]
    if proto and proto.autoplace and proto.autoplace.probability_expression then
        proto.autoplace.probability_expression =
            "(" .. factor .. ") * (" .. proto.autoplace.probability_expression .. ")"
    end
end

scale_entity_autoplace("simple-entity", "vulcanus-chimney", 0.2)
scale_entity_autoplace("simple-entity", "vulcanus-chimney-faded", 0.2)
scale_entity_autoplace("simple-entity", "vulcanus-chimney-cold", 0.2)
scale_entity_autoplace("simple-entity", "vulcanus-chimney-short", 0.2)
scale_entity_autoplace("simple-entity", "vulcanus-chimney-truncated", 0.2)
scale_entity_autoplace("simple-entity", "huge-volcanic-rock", 0.4)
scale_entity_autoplace("simple-entity", "big-volcanic-rock", 0.4)

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
local pollution_setting = settings.startup["eon_patch_gleba_enemies_react_to_pollution"]
if pollution_setting and pollution_setting.value then
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
end

-- ---------------------------------------------------------------------------
-- Fix: Use tungsten-plate
-- ---------------------------------------------------------------------------
local use_tungsten_setting = settings.startup["eon_patch_use_tungsten_plate"]
if use_tungsten_setting and use_tungsten_setting.value then
    local demolisher_corpses = {
        "small-demolisher-corpse",
        "medium-demolisher-corpse",
        "big-demolisher-corpse",
    }

    for _, name in ipairs(demolisher_corpses) do
        local corpse = data.raw["simple-entity"] and data.raw["simple-entity"][name]
        local minable = corpse and corpse.minable
        local results = minable and minable.results

        if results then
            for _, result in pairs(results) do
                if result.type == "item" and result.name == "tungsten-ore" then
                    result.name = "tungsten-plate"
                end
            end
        end
    end

    local foundry_recipe = data.raw["recipe"]["foundry"]
    if foundry_recipe and not foundry_recipe.hidden then
        for _, ingredient in pairs(foundry_recipe.ingredients) do
            if ingredient.name == "tungsten-carbide" then
                ingredient.name = "tungsten-plate"
            end
        end

        if mods["quality"] then
            local recycling = require("__quality__/prototypes/recycling")
            recycling.generate_recycling_recipe(foundry_recipe)
        end
    end
end
