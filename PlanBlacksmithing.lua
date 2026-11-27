local _, ns = ...

-- The 1-450 Blacksmithing route, as data. Same shape as the Engineering one
-- in Plan.lua: one entry per step, `to` decides which step is current, `mats`
-- is what ONE craft takes.
--
-- Source: Lost Unison's "WotLK Warmane Icecrown Guides" (docx, Nov 2026),
-- Blacksmithing "Leveling 1 to 450". The guide's counts already assume +3 a
-- skill-up. Per-craft mats are the guide's "Total Material" divided by its
-- quantity; where the guide gives a range ("32-53") the top of it is used, so
-- the shopping list covers the unlucky case.
--
-- Left out on purpose: the "Expensive but more profit" rods (Silver, Arcanite,
-- Fel Iron, Eternium, and the second Titanium Rod run). The guide marks them
-- optional and its own material summary does not count them.
--
-- One correction: the guide's summary says 44 Fel Iron Bar, but its own TBC
-- steps use 54 (12 + 8 + 10 + 6 + 18). The list is built from the steps, so
-- it says 54.
ns.plan = ns.plan or {}
ns.plan["bs"] = {
    label = "Blacksmithing 1-450",
    skill = "Blacksmithing",
    gain = 3,
    train = {
        [75]  = "Journeyman Blacksmithing (from 50)",
        [150] = "Expert Blacksmithing (from 125)",
        [225] = "Artisan Blacksmithing (from 200)",
        [300] = "Master Blacksmithing (from 275)",
        [375] = "Grand Master Blacksmithing (from 350, in Northrend)",
    },
    -- The level where the profession's own perk unlocks, the point many stop
    -- at. From the guide: "At level 400 Blacksmithing, you unlock Socket
    -- Bracer and Socket Gloves."
    bis = { level = 400, what = "Socket Bracer and Socket Gloves (an extra gem in your own bracers and gloves)",
            why = "400 is enough for the Blacksmithing bonus: Socket Bracer and Socket Gloves, one extra gem socket in your own bracers and gloves. Nothing past 400 adds to it." },
    vendor = { ["Green Dye"] = true },
    steps = {
        -- Classic
        { from = 1,   to = 25,  craft = "Rough Sharpening Stone",  count = 8,
          mats = { ["Rough Stone"] = 1 } },
        { from = 25,  to = 85,  craft = "Rough Grinding Stone",    count = 53,
          mats = { ["Rough Stone"] = 2 } },
        { from = 85,  to = 100, craft = "Coarse Grinding Stone",   count = 21,
          mats = { ["Coarse Stone"] = 2 } },
        { from = 100, to = 112, craft = "Runed Copper Belt",       count = 4,
          mats = { ["Copper Bar"] = 10 } },
        { from = 112, to = 127, craft = "Rough Bronze Leggings",   count = 5,
          mats = { ["Bronze Bar"] = 6 } },
        { from = 127, to = 151, craft = "Heavy Grinding Stone",    count = 26,
          mats = { ["Heavy Stone"] = 3 } },
        { from = 151, to = 157, craft = "Golden Rod",              count = 2,
          mats = { ["Gold Bar"] = 1, ["Coarse Grinding Stone"] = 2 } },
        { from = 157, to = 166, craft = "Green Iron Leggings",     count = 3,
          mats = { ["Iron Bar"] = 8, ["Heavy Grinding Stone"] = 1, ["Green Dye"] = 1 } },
        { from = 166, to = 190, craft = "Green Iron Bracers",      count = 8,
          mats = { ["Iron Bar"] = 6, ["Green Dye"] = 1 } },
        { from = 190, to = 202, craft = "Golden Scale Bracers",    count = 4,
          mats = { ["Steel Bar"] = 5, ["Heavy Grinding Stone"] = 2 } },
        { from = 202, to = 208, craft = "Truesilver Rod",          count = 2,
          mats = { ["Truesilver Bar"] = 1, ["Heavy Grinding Stone"] = 1 } },
        { from = 208, to = 220, craft = "Truesilver Skeleton Key", count = 11,
          mats = { ["Truesilver Bar"] = 1, ["Solid Grinding Stone"] = 1 } },
        { from = 220, to = 226, craft = "Heavy Mithril Gauntlet",  count = 2,
          mats = { ["Mithril Bar"] = 6, ["Mageweave Cloth"] = 4 } },
        { from = 226, to = 232, craft = "Mithril Scale Pants",     count = 2,
          mats = { ["Mithril Bar"] = 12 } },
        { from = 232, to = 250, craft = "Mithril Coif",            count = 6,
          mats = { ["Mithril Bar"] = 10, ["Mageweave Cloth"] = 6 } },
        { from = 250, to = 262, craft = "Dense Grinding Stone",    count = 10,
          mats = { ["Dense Stone"] = 4 } },
        { from = 262, to = 277, craft = "Thorium Bracers",         count = 5,
          mats = { ["Thorium Bar"] = 8 } },
        { from = 277, to = 280, craft = "Thorium Bracers",         count = 2, again = true,
          mats = { ["Thorium Bar"] = 8 } },
        { from = 280, to = 301, craft = "Thorium Helm",            count = 7,
          mats = { ["Thorium Bar"] = 12, ["Star Ruby"] = 1 } },

        -- TBC
        { from = 301, to = 310, craft = "Fel Iron Chain Coif",     count = 3,
          mats = { ["Fel Iron Bar"] = 4 } },
        { from = 310, to = 316, craft = "Fel Iron Plate Belt",     count = 2,
          mats = { ["Fel Iron Bar"] = 4 } },
        { from = 316, to = 322, craft = "Fel Iron Chain Gloves",   count = 2,
          mats = { ["Fel Iron Bar"] = 5 } },
        { from = 322, to = 325, craft = "Fel Iron Chain Bracers",  count = 1,
          mats = { ["Fel Iron Bar"] = 6 } },
        { from = 325, to = 337, craft = "Lesser Rune of Warding",  count = 16,
          mats = { ["Adamantite Bar"] = 1 } },
        { from = 337, to = 340, craft = "Fel Iron Chain Tunic",    count = 2,
          mats = { ["Fel Iron Bar"] = 9 } },
        { from = 340, to = 352, craft = "Lesser Ward of Shielding", count = 11,
          note = "Not a trainer recipe: buy Plans: Lesser Ward of Shielding (AH, or a vendor in Outland) before 340.",
          mats = { ["Adamantite Bar"] = 1 } },

        -- WotLK
        { from = 352, to = 361, craft = "Cobalt Boots",            count = 3,
          mats = { ["Cobalt Bar"] = 4 } },
        { from = 361, to = 370, craft = "Cobalt Triangle Shield",  count = 3,
          mats = { ["Cobalt Bar"] = 4 } },
        { from = 370, to = 382, craft = "Cobalt Gauntlets",        count = 4,
          mats = { ["Cobalt Bar"] = 5 } },
        { from = 382, to = 385, craft = "Spiked Cobalt Boots",     count = 1,
          mats = { ["Cobalt Bar"] = 7 } },
        { from = 385, to = 391, craft = "Spiked Cobalt Shoulders", count = 2,
          mats = { ["Cobalt Bar"] = 7 } },
        { from = 391, to = 397, craft = "Notched Cobalt War Axe",  count = 2,
          mats = { ["Cobalt Bar"] = 10 } },
        { from = 397, to = 400, craft = "Spiked Cobalt Belt",      count = 1,
          mats = { ["Cobalt Bar"] = 7 } },
        { from = 400, to = 406, craft = "Horned Cobalt Helm",      count = 2,
          mats = { ["Cobalt Bar"] = 8 } },
        { from = 406, to = 415, craft = "Deadly Saronite Dirk",    count = 3,
          mats = { ["Saronite Bar"] = 7, ["Crystallized Air"] = 2 } },
        { from = 415, to = 421, craft = "Eternal Belt Buckle",     count = 2,
          mats = { ["Saronite Bar"] = 4, ["Eternal Earth"] = 1, ["Eternal Water"] = 1,
                   ["Eternal Shadow"] = 1 } },
        { from = 421, to = 430, craft = "Titanium Rod",            count = 3,
          mats = { ["Saronite Bar"] = 2, ["Titanium Bar"] = 1 } },
        { from = 430, to = 445, craft = "Titanium Skeleton Key",   count = 11,
          mats = { ["Saronite Bar"] = 4, ["Titanium Bar"] = 1 } },
        { from = 445, to = 450, craft = "Titansteel Shield Wall",  count = 2,
          mats = { ["Saronite Bar"] = 4, ["Titansteel Bar"] = 3, ["Frozen Orb"] = 1 } },
    },
    -- Bought, not made, and not a reagent of any step.
    extra = {
        { "Plans: Lesser Ward of Shielding", 1, "ah", learns = "Lesser Ward of Shielding" },
    },
}
