local _, ns = ...

-- Quantities are the whole point: Auctionator's own shopping lists hold item
-- NAMES only, so the numbers have to live here or they are lost.
--
-- source tells the pusher where an item actually comes from:
--   "ah"     buy it at the auction house
--   "vendor" a trade goods vendor sells it for coppers and the AH rarely
--            carries it at all, so searching for it just wastes a scan
--   "craft"  you make it yourself from mats already on this list, so buying
--            it would mean paying twice for the same bars
--
-- after405 = how much of that row is only for 405-450. A copy built to stop
-- at 405 (ns.ROUTE_END in Plan.lua) takes it off, and drops the row at 0.
ns.lists = {
    ["engi"] = {
        label = "Engineering 1-450",
        oldLabels = { "Engineering 1-405" },
        items = {
            -- Lost Unison's Icecrown guide, updated version (18 Nov 2026).
            -- The guide's own totals, except where its own steps use more:
            -- those are raised and say so. tests/plan.lua checks every row
            -- against what Plan.lua consumes.

            -- Classic
            { "Rough Stone",                40, "ah"     },
            { "Copper Bar",                 26, "ah"     },
            { "Weak Flux",                   7, "vendor" },
            { "Coarse Stone",                6, "ah"     },
            { "Silver Bar",                 15, "ah"     },
            { "Heavy Stone",                 5, "ah"     },
            { "Bronze Bar",                 20, "ah"     },
            { "Wool Cloth",                 10, "ah"     },
            { "Gold Bar",                   15, "ah"     },
            { "Steel Bar",                   4, "ah"     },
            { "Solid Stone",                60, "ah"     },
            -- guide says 28, but its steps use 32: 9 tubes, 8 triggers,
            -- 7 slugs, and two rounds of Gyro-Shot at 4 each
            { "Mithril Bar",                32, "ah"     },
            { "Mageweave Cloth",             8, "ah"     },
            { "Thick Leather",              20, "ah"     },
            { "Star Ruby",                  10, "ah"     },
            { "Dense Stone",                60, "ah"     },
            { "Thorium Bar",                40, "ah"     },
            { "Runecloth",                   8, "ah"     },

            -- TBC
            -- guide says 14, which covers the bolts only. The 3 Fel Iron
            -- Casings for the bombs take 9 more.
            { "Fel Iron Bar",               23, "ah"     },
            { "Fel Iron Casing",             3, "craft"  },
            { "Mote of Fire",               20, "ah"     },
            { "Mote of Earth",              40, "ah"     },
            { "Adamantite Bar",             16, "ah"     },
            { "Netherweave Cloth",          25, "ah"     },

            -- guide: 80 to 405 plus 21 for 405-450. Its steps use 86 + 6 for
            -- the two extra triggers at 406, so 101 covers it with spare.
            { "Cobalt Bar",                101, "ah",     after405 = 15 },
            { "Crystallized Earth",          4, "ah"     },
            { "Crystallized Water",         17, "ah",     after405 = 7 },
            { "Frostweave Cloth",            4, "ah"     },

            -- WotLK 405-450
            { "Saronite Bar",              149, "ah",     after405 = 149 },
            { "Eternal Air",                 8, "ah",     after405 = 8 },
            { "Twilight Opal",               4, "ah",     after405 = 4 },
            { "Skinning Knife",              7, "vendor", after405 = 7 },
            { "Mining Pick",                 7, "vendor", after405 = 7 },
            { "Blacksmith Hammer",           7, "vendor", after405 = 7 },
        },
    },
}
