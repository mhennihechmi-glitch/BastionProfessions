local _, ns = ...

-- The 1-450 Engineering route, as data.
-- Source: Lost Unison's "WotLK Warmane Icecrown" guide, updated version
-- (18 Nov 2026).
--
-- One entry per step of the guide, in order. `to` is the skill level the step
-- carries you to, and that is what decides which step is current: the first
-- one whose `to` is above your present skill. Nothing here asks what you have
-- already made, because the skill number already knows.
--
-- `craft` is the exact recipe name as the trainer teaches it, because that is
-- what the tradeskill window is searched for. A typo does not throw, it just
-- means the button never finds the recipe. Names were checked against the
-- "You create:" lines in your own chat log (Mithril Tube, Thorium Shells).
--
-- `count` is the guide's figure. It is a guide, not a guarantee: proc luck
-- moves it either way, which is why the button recomputes the step from your
-- live skill after every craft rather than counting presses.
--
-- `prep` is something to make first, in the amount the step needs in your
-- bags, when the guide does not give it a skill range of its own: the Fel
-- Iron Casings for the bombs, and the extra Volatile Blasting Triggers for
-- Box of Bombs (the 12 from 370-376 all go into the Explosive Decoys).
-- `makes` is how many one craft produces, where it is more than one and a
-- later step depends on it (your log shows Volatile Blasting Trigger x2 and
-- Elemental Blasting Powder x4 a craft; 2 is used here to stay on the safe
-- side).
ns.plan = {
    ["engi"] = {
        label = "Engineering 1-450",
        skill = "Engineering",
        -- Nitro Boosts needs 405, the last tinker most raiders want.
        bis = { level = 405, what = "Nitro Boosts and every other glove, cloak and belt tinker",
                why = "405 is enough for the Engineering bonus: Nitro Boosts on your boots and every glove, cloak, belt and helm tinker raiders use. Most people stop here." },
        -- Warmane Icecrown: every skill-up is +3, not +1. Measured in your
        -- chat log (1 Nov: 1, 4, 7, 10 ... one craft each), and it is what
        -- the guide's counts assume (6 Coarse Blasting Powder for 15 points).
        gain = 3,
        -- The skill cap of each rank, and what to train to lift it.
        train = {
            [75]  = "Journeyman Engineering (from 50)",
            [150] = "Expert Engineering (from 125)",
            [225] = "Artisan Engineering (from 200)",
            [300] = "Master Engineering (from 275)",
            [375] = "Grand Master Engineering (from 350, in Northrend)",
        },
        steps = {
            -- Classic
            { from = 1,   to = 40,  craft = "Rough Blasting Powder",      count = 40,
              mats = { ["Rough Stone"] = 1 } },
            { from = 40,  to = 52,  craft = "Handful of Copper Bolts",    count = 6,
              mats = { ["Copper Bar"] = 1 } },
            { from = 52,  to = 55,  craft = "Arclight Spanner",           count = 1,
              mats = { ["Copper Bar"] = 6 } },
            { from = 55,  to = 76,  craft = "Copper Tube",                count = 7,
              mats = { ["Copper Bar"] = 2, ["Weak Flux"] = 1 } },
            { from = 76,  to = 91,  craft = "Coarse Blasting Powder",     count = 6,
              mats = { ["Coarse Stone"] = 1 } },
            { from = 91,  to = 127, craft = "Silver Contact",             count = 15,
              mats = { ["Silver Bar"] = 1 } },
            { from = 127, to = 136, craft = "Heavy Blasting Powder",      count = 5,
              mats = { ["Heavy Stone"] = 1 } },
            { from = 136, to = 151, craft = "Whirring Bronze Gizmo",      count = 10,
              mats = { ["Bronze Bar"] = 2, ["Wool Cloth"] = 1 } },
            { from = 151, to = 175, craft = "Gold Power Core",            count = 15,
              mats = { ["Gold Bar"] = 1 } },
            { from = 175, to = 178, craft = "Gyromatic Micro-Adjustor",   count = 1,
              mats = { ["Steel Bar"] = 4 } },
            { from = 178, to = 196, craft = "Solid Blasting Powder",      count = 30,
              mats = { ["Solid Stone"] = 2 } },
            { from = 196, to = 202, craft = "Mithril Tube",               count = 3,
              mats = { ["Mithril Bar"] = 3 } },
            { from = 202, to = 220, craft = "Unstable Trigger",           count = 8,
              mats = { ["Mithril Bar"] = 1, ["Mageweave Cloth"] = 1, ["Solid Blasting Powder"] = 1 } },
            { from = 220, to = 232, craft = "Hi-Impact Mithril Slugs",    count = 7,
              mats = { ["Mithril Bar"] = 1, ["Solid Blasting Powder"] = 1 } },
            { from = 232, to = 247, craft = "Spellpower Goggles Xtreme",  count = 5,
              mats = { ["Thick Leather"] = 4, ["Star Ruby"] = 2 } },
            { from = 247, to = 250, craft = "Mithril Gyro-Shot",          count = 2,
              mats = { ["Mithril Bar"] = 2, ["Solid Blasting Powder"] = 2 } },
            { from = 250, to = 262, craft = "Dense Blasting Powder",      count = 30,
              mats = { ["Dense Stone"] = 2 } },
            -- the guide comes back to Gyro-Shot once the powder is done
            { from = 262, to = 265, craft = "Mithril Gyro-Shot",          count = 2, again = true,
              mats = { ["Mithril Bar"] = 2, ["Solid Blasting Powder"] = 2 } },
            { from = 265, to = 286, craft = "Thorium Widget",             count = 8,
              mats = { ["Thorium Bar"] = 3, ["Runecloth"] = 1 } },
            { from = 286, to = 301, craft = "Thorium Shells",             count = 8,
              mats = { ["Thorium Bar"] = 2, ["Dense Blasting Powder"] = 1 } },

            -- TBC
            { from = 301, to = 310, craft = "Handful of Fel Iron Bolts",  count = 14,
              mats = { ["Fel Iron Bar"] = 1 } },
            { from = 310, to = 322, craft = "Elemental Blasting Powder",  count = 20, makes = 2,
              mats = { ["Mote of Fire"] = 1, ["Mote of Earth"] = 2 } },
            { from = 322, to = 325, craft = "Fel Iron Bomb",              count = 3,
              prep = { craft = "Fel Iron Casing", need = 3, makes = 1, mats = { ["Fel Iron Bar"] = 3 } },
              mats = { ["Fel Iron Casing"] = 1, ["Handful of Fel Iron Bolts"] = 2,
                       ["Elemental Blasting Powder"] = 1 } },
            { from = 325, to = 337, craft = "Adamantite Grenade",         count = 4,
              mats = { ["Adamantite Bar"] = 4, ["Handful of Fel Iron Bolts"] = 2,
                       ["Elemental Blasting Powder"] = 1 } },
            { from = 337, to = 355, craft = "White Smoke Flare",          count = 25,
              note = "The schematic is a vendor recipe, not a trainer one: buy Schematic: White Smoke Flare before 337. Schematic: Green Smoke Flare works too (same skill range, plus 1 Green Dye from a vendor per craft).",
              -- Same skill colours as White (Wowhead: 335/335/345/355), same
              -- mats plus a Green Dye. Which one you can get depends on where
              -- you quested in Outland, so the button takes either.
              orCraft = { "Green Smoke Flare" },
              mats = { ["Elemental Blasting Powder"] = 1, ["Netherweave Cloth"] = 1 } },

            -- WotLK
            { from = 355, to = 370, craft = "Handful of Cobalt Bolts",    count = 10,
              mats = { ["Cobalt Bar"] = 2 } },
            { from = 370, to = 376, craft = "Volatile Blasting Trigger",  count = 6, makes = 2,
              mats = { ["Cobalt Bar"] = 3, ["Crystallized Water"] = 1 } },
            { from = 376, to = 385, craft = "Overcharged Capacitor",      count = 4,
              mats = { ["Cobalt Bar"] = 4, ["Crystallized Earth"] = 1 } },
            { from = 385, to = 391, craft = "Explosive Decoy",            count = 4,
              mats = { ["Frostweave Cloth"] = 1, ["Volatile Blasting Trigger"] = 3 } },
            { from = 391, to = 400, craft = "Froststeel Tube",            count = 4,
              mats = { ["Cobalt Bar"] = 8, ["Crystallized Water"] = 1 } },
            { from = 400, to = 406, craft = "Diamond-cut Refractor Scope", count = 3,
              mats = { ["Froststeel Tube"] = 1, ["Handful of Cobalt Bolts"] = 2 } },
            { from = 406, to = 415, craft = "Box of Bombs",               count = 3,
              -- the guide says 7 triggers here; one craft makes 2, and the
              -- boxes take 3, so 2 crafts do it. The spare Cobalt stays.
              prep = { craft = "Volatile Blasting Trigger", need = 3, makes = 2,
                       mats = { ["Cobalt Bar"] = 3, ["Crystallized Water"] = 1 } },
              mats = { ["Saronite Bar"] = 5, ["Volatile Blasting Trigger"] = 1 } },
            { from = 415, to = 427, craft = "Saronite Razorheads",        count = 18,
              mats = { ["Saronite Bar"] = 2 } },
            { from = 427, to = 430, craft = "MOLL-E",                     count = 1,
              mats = { ["Saronite Bar"] = 8, ["Eternal Air"] = 8 } },
            { from = 430, to = 436, craft = "Heartseeker Scope",          count = 2,
              mats = { ["Saronite Bar"] = 10, ["Twilight Opal"] = 2 } },
            { from = 436, to = 450, craft = "Gnomish Army Knife",         count = 7,
              mats = { ["Saronite Bar"] = 10, ["Skinning Knife"] = 1,
                       ["Mining Pick"] = 1, ["Blacksmith Hammer"] = 1 } },
        },
    },
}

-- Where this copy of the route stops: 450, or 405 for the guild build
-- (405 unlocks Nitro Boosts, which is the point of the profession for most
-- raiders). Everything past it is cut here, once, at load, so the button, the
-- printed plan and the shopping list all agree.
ns.ROUTE_END = ns.ROUTE_END or 405

-- Engineering only. The other professions' files load after this one and
-- always run to 450; Nitro Boosts at 405 is an Engineering reason.
if ns.ROUTE_END < 450 then
    local stop = ns.ROUTE_END
    for _, plan in pairs({ ns.plan.engi }) do
        local kept = {}
        for _, s in ipairs(plan.steps) do
            if s.from < stop then
                if s.to > stop then s.to = stop end
                kept[#kept + 1] = s
            end
        end
        plan.steps = kept
        plan.label = (plan.label:gsub("1%-450", "1-" .. stop))
    end
    for _, list in pairs({ ns.lists and ns.lists.engi }) do
        local kept = {}
        for _, row in ipairs(list.items) do
            local n = row[2] - (row.after405 or 0)
            if n > 0 then kept[#kept + 1] = { row[1], n, row[3] } end
        end
        list.items = kept
        list.label = (list.label:gsub("1%-450", "1-" .. stop))
        -- the label is the old one again; a 1-450 list from an earlier
        -- push is the one to take out now
        list.oldLabels = { "Engineering 1-450" }
    end
end

-- The step your present skill puts you in: the first one you have not
-- finished. Returns the step and its position, or nil at max.
function ns.StepFor(key, skill)
    local plan = ns.plan[key]
    if not plan then return nil end
    for i, s in ipairs(plan.steps) do
        if skill < s.to then return s, i, #plan.steps end
    end
    return nil, #plan.steps, #plan.steps
end
