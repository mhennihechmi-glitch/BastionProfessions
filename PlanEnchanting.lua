local _, ns = ...

-- The 1-450 Enchanting route. Same shape as Plan.lua.
--
-- Source: Lost Unison's "WotLK Warmane Icecrown Guides" (docx, Nov 2026),
-- Enchanting "Leveling 1 to 450". `craft` is the recipe name as the
-- tradeskill window shows it ("Enchant Bracer - Minor Health"); the guide
-- drops the "Enchant " part. Northrend bracer enchants are "Bracers" in the
-- client, which the recipe lookup treats as the same word.
--
-- Every "Enchant ..." step needs an item to go on. The button picks one in
-- your bags (see Level.lua, enchant targets) and never touches what you wear.
--
-- Guide summary errors, corrected by building the list from the steps:
--   * Infinite Dust: summary 246, steps use 273.
--   * Arcane Dust: summary 85, steps use 90 (the Runed Eternium Rod's 6).
--   * Vision Dust: summary 57, steps use 59.
--   * Primal Might (Runed Adamantite Rod) is missing from the summary.
-- "3 Simple Wood (vendor)" is on the summary but no step uses it, so it is
-- left out.
ns.plan = ns.plan or {}
ns.plan["ench"] = {
    label = "Enchanting 1-450",
    skill = "Enchanting",
    gain = 3,
    train = {
        [75]  = "Journeyman Enchanter (from 50)",
        [150] = "Expert Enchanter (from 125)",
        [225] = "Artisan Enchanter (from 200)",
        [300] = "Master Enchanter (from 275, in Outland: Hellfire Peninsula)",
        [375] = "Grand Master Enchanter (from 350, Dalaran)",
    },
    -- Ring enchants on your own rings need Enchanting 400. The guide describes
    -- the perk but gives no level; 400 is the game's requirement.
    bis = { level = 400, what = "Ring enchants on your own rings (Greater Assault, Greater Spellpower, Stamina)",
            why = "400 is enough for the Enchanting bonus: enchanting your own two rings (Greater Assault +40 attack power, Greater Spellpower +23 spell power, or Stamina +30 each). Only enchanters can put these on." },
    vendor = { ["Copper Rod"] = true, ["Crystal Vial"] = true, ["Imbued Vial"] = true },
    steps = {
        -- Classic
        { from = 1,   to = 4,   craft = "Runed Copper Rod",                count = 1,
          mats = { ["Copper Rod"] = 1, ["Strange Dust"] = 1, ["Lesser Magic Essence"] = 1 } },
        { from = 4,   to = 70,  craft = "Enchant Bracer - Minor Health",   count = 22,
          mats = { ["Strange Dust"] = 1 } },
        { from = 70,  to = 91,  craft = "Enchant Bracer - Minor Health",   count = 10, again = true,
          mats = { ["Strange Dust"] = 1 } },
        { from = 91,  to = 121, craft = "Enchant Bracer - Minor Stamina",  count = 10,
          mats = { ["Strange Dust"] = 3 } },
        { from = 121, to = 136, craft = "Enchant Bracer - Minor Strength", count = 6,
          mats = { ["Strange Dust"] = 5 } },
        { from = 136, to = 139, craft = "Runed Silver Rod",                count = 1,
          mats = { ["Silver Rod"] = 1, ["Strange Dust"] = 6, ["Greater Magic Essence"] = 3,
                   ["Runed Copper Rod"] = 1 } },
        { from = 139, to = 142, craft = "Enchant Bracer - Lesser Stamina", count = 1,
          mats = { ["Soul Dust"] = 2 } },
        { from = 142, to = 187, craft = "Enchant Bracer - Lesser Strength", count = 20,
          note = "Formula from the AH: Formula: Enchant Bracer - Lesser Strength.",
          mats = { ["Soul Dust"] = 2 } },
        { from = 187, to = 190, craft = "Runed Golden Rod",                count = 1,
          mats = { ["Golden Rod"] = 1, ["Iridescent Pearl"] = 1, ["Greater Astral Essence"] = 2,
                   ["Soul Dust"] = 2, ["Runed Silver Rod"] = 1 } },
        { from = 190, to = 220, craft = "Enchant Bracer - Strength",       count = 14,
          mats = { ["Vision Dust"] = 1 } },
        { from = 220, to = 223, craft = "Runed Truesilver Rod",            count = 1,
          mats = { ["Truesilver Rod"] = 1, ["Black Pearl"] = 1, ["Greater Mystic Essence"] = 2,
                   ["Vision Dust"] = 2, ["Runed Golden Rod"] = 1 } },
        { from = 223, to = 247, craft = "Enchant Cloak - Greater Defense", count = 11,
          mats = { ["Vision Dust"] = 3 } },
        { from = 247, to = 250, craft = "Enchant Shield - Stamina",        count = 2,
          note = "Formula from the AH: Formula: Enchant Shield - Stamina.",
          mats = { ["Vision Dust"] = 5 } },
        { from = 250, to = 262, craft = "Lesser Mana Oil",                 count = 4,
          note = "Formula from the AH, or Kania in Silithus.",
          mats = { ["Dream Dust"] = 3, ["Purple Lotus"] = 2, ["Crystal Vial"] = 1 } },
        { from = 262, to = 265, craft = "Enchant Boots - Greater Stamina", count = 1,
          note = "Formula from the AH: Formula: Enchant Boots - Greater Stamina.",
          mats = { ["Dream Dust"] = 5 } },
        { from = 265, to = 286, craft = "Enchant Shield - Greater Stamina", count = 7,
          note = "Formula is bind on pickup: Mythrin'dir in Undercity (Horde) or Daniel Bartlett in Darnassus (Alliance).",
          mats = { ["Dream Dust"] = 5 } },

        -- TBC
        { from = 286, to = 325, craft = "Enchant Shield - Greater Stamina", count = 30, again = true,
          mats = { ["Dream Dust"] = 5 } },
        { from = 325, to = 328, craft = "Runed Arcanite Rod",              count = 1,
          note = "Formula is bind on pickup: Lorelae Wintersong in Moonglade.",
          mats = { ["Arcanite Rod"] = 1, ["Golden Pearl"] = 1, ["Illusion Dust"] = 10,
                   ["Greater Eternal Essence"] = 4, ["Runed Truesilver Rod"] = 1,
                   ["Large Brilliant Shard"] = 2 } },
        { from = 328, to = 331, craft = "Runed Fel Iron Rod",              count = 1,
          mats = { ["Fel Iron Rod"] = 1, ["Greater Eternal Essence"] = 4,
                   ["Large Brilliant Shard"] = 6, ["Runed Arcanite Rod"] = 1 } },
        { from = 331, to = 340, craft = "Enchant Shield - Major Stamina",  count = 4,
          note = "Formula from the AH, or Madame Ruby in Shattrath.",
          mats = { ["Arcane Dust"] = 15 } },
        { from = 340, to = 352, craft = "Superior Wizard Oil",             count = 8,
          note = "Formula from the AH, or Madame Ruby in Shattrath.",
          mats = { ["Arcane Dust"] = 3, ["Nightmare Vine"] = 1, ["Imbued Vial"] = 1 } },

        -- WotLK
        { from = 352, to = 361, craft = "Enchant Cloak - Speed",           count = 3,
          mats = { ["Infinite Dust"] = 6 } },
        { from = 361, to = 370, craft = "Enchant Bracers - Striking",      count = 3,
          mats = { ["Infinite Dust"] = 6 } },
        { from = 370, to = 373, craft = "Runed Adamantite Rod",            count = 1,
          mats = { ["Adamantite Rod"] = 1, ["Greater Planar Essence"] = 8,
                   ["Large Prismatic Shard"] = 8, ["Primal Might"] = 1, ["Runed Fel Iron Rod"] = 1 } },
        { from = 373, to = 382, craft = "Enchant Chest - Super Stats",     count = 3,
          mats = { ["Infinite Dust"] = 4, ["Lesser Cosmic Essence"] = 2 } },
        { from = 382, to = 385, craft = "Runed Eternium Rod",              count = 1,
          mats = { ["Eternium Rod"] = 1, ["Greater Planar Essence"] = 6, ["Arcane Dust"] = 6,
                   ["Runed Adamantite Rod"] = 1 } },
        { from = 385, to = 397, craft = "Enchant Boots - Icewalker",       count = 4,
          mats = { ["Infinite Dust"] = 8, ["Crystallized Water"] = 1 } },
        { from = 397, to = 406, craft = "Enchant Cloak - Superior Agility", count = 3,
          mats = { ["Infinite Dust"] = 9 } },
        { from = 406, to = 415, craft = "Enchant Gloves - Expertise",      count = 3,
          mats = { ["Infinite Dust"] = 12 } },
        { from = 415, to = 427, craft = "Enchant Gloves - Major Agility",  count = 4,
          mats = { ["Greater Cosmic Essence"] = 4, ["Dream Shard"] = 1 } },
        { from = 427, to = 430, craft = "Runed Titanium Rod",              count = 1,
          mats = { ["Titanium Rod"] = 1, ["Infinite Dust"] = 40, ["Greater Cosmic Essence"] = 12,
                   ["Dream Shard"] = 8, ["Runed Eternium Rod"] = 1 } },
        { from = 430, to = 442, craft = "Enchant Cloak - Mighty Armor",    count = 4,
          note = "Formula costs 4 Dream Shard from Vanessa Sellers in Dalaran.",
          mats = { ["Infinite Dust"] = 15, ["Greater Cosmic Essence"] = 2 } },
        { from = 442, to = 450, craft = "Enchant Boots - Tuskarr's Vitality", count = 3,
          note = "Formula costs 4 Dream Shard from Vanessa Sellers in Dalaran.",
          mats = { ["Infinite Dust"] = 10, ["Greater Cosmic Essence"] = 2, ["Dream Shard"] = 2 } },
    },
    -- Bought, not a reagent of any step. `learns` lets the panel tick a
    -- formula off once the recipe is in your book.
    extra = {
        { "Formula: Enchant Bracer - Lesser Strength", 1, "ah", learns = "Enchant Bracer - Lesser Strength" },
        { "Formula: Enchant Shield - Stamina",         1, "ah", learns = "Enchant Shield - Stamina" },
        { "Formula: Lesser Mana Oil",                  1, "ah", learns = "Lesser Mana Oil" },
        { "Formula: Enchant Boots - Greater Stamina",  1, "ah", learns = "Enchant Boots - Greater Stamina" },
        { "Formula: Enchant Shield - Greater Stamina", 1, "vendor", learns = "Enchant Shield - Greater Stamina" },
        { "Formula: Runed Arcanite Rod",               1, "vendor", learns = "Runed Arcanite Rod" },
        { "Formula: Enchant Shield - Major Stamina",   1, "ah", learns = "Enchant Shield - Major Stamina" },
        { "Formula: Superior Wizard Oil",              1, "ah", learns = "Superior Wizard Oil" },
        -- the two Dalaran formulas, paid in Dream Shards
        { "Dream Shard",                               8, "ah", forFormulas = true },
    },
}
