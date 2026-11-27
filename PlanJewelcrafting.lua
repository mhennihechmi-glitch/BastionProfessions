local _, ns = ...

-- The 1-450 Jewelcrafting route. Same shape as Plan.lua.
--
-- Source: Lost Unison's "WotLK Warmane Icecrown Guides" (docx, Nov 2026),
-- Jewelcrafting "Leveling 1 to 450". The "Alternative:" rows (statues from
-- stone, the Northrend rings that need disenchanting) are left out; the guide's
-- material summary counts only the main rows, and so does this.
--
-- Guide typos corrected here:
--   * 340-346 Jagged Deep Peridot says quantity 7 but material 2. Six points
--     at +3 is 2 crafts, and the summary's 12 Deep Peridot only adds up with
--     2. So 2.
--   * "Golden Bar" is Gold Bar, "Emerald Lion RIng" is Emerald Lion Ring.
--   * 145-151 Golden Ring of Power needs skill 180, so it cannot be learned at
--     145. Golden Dragon Ring (2 Gold Bar, 2 Delicate Copper Wire, 1 Jade) is
--     used instead. Fixed 26 Nov after the button asked for it at 147.
--   * 151-176 Mithril Filigree says 8 crafts; 25 points at +3 is 9, so the
--     list asks 28 Mithril Bar, not 26.
--
-- `anyWith` steps: the guide says "any gem crafted from Shadow Crystal". The
-- button picks, at the moment you click, a recipe you know whose ONLY reagent
-- is one of those gems, preferring the colour that still gives the most skill.
-- `craft` is just what the plan prints.
--
-- Icy Prism has a 20 hour cooldown, so 427-450 is one craft a day. When it is
-- on cooldown the button offers a meta gem instead (the guide's alternative)
-- if you have an Earthsiege or Skyflare Diamond in your bags.
ns.plan = ns.plan or {}
ns.plan["jc"] = {
    label = "Jewelcrafting 1-450",
    skill = "Jewelcrafting",
    gain = 3,
    train = {
        [75]  = "Journeyman Jewelcrafting (from 50; Exodar or Silvermoon)",
        [150] = "Expert Jewelcrafting (from 125; Exodar or Silvermoon)",
        [225] = "Artisan Jewelcrafting (from 200; Exodar or Silvermoon)",
        [300] = "Master Jewelcrafting (from 275; Exodar or Silvermoon)",
        [375] = "Grand Master Jewelcrafting (from 350, Dalaran)",
    },
    -- Dragon's Eye gems (+34 instead of +20, up to three). Checked on Wowhead
    -- (WotLK Classic data, 24 Nov 2026): the cut gem says "Requires
    -- Jewelcrafting (350)" but is bind on pickup, so you have to cut it
    -- yourself, and every Design: ... Dragon's Eye says "Requires
    -- Jewelcrafting (370)". So 370 is when you can actually have them.
    bis = { level = 370, what = "Dragon's Eye gems (+34 instead of +20, up to three, you cut them yourself)",
            why = "370 is enough for the Jewelcrafting bonus: Dragon's Eye gems, +34 instead of +20 (for example 34 haste instead of 20), up to three in your gear. They are bind on pickup, so you cut them yourself, and the cutting designs need 370." },
    vendor = {},
    steps = {
        -- Classic
        { from = 1,   to = 52,  craft = "Delicate Copper Wire",          count = 26,
          mats = { ["Copper Bar"] = 2 } },
        { from = 52,  to = 91,  craft = "Bronze Setting",                count = 29,
          mats = { ["Bronze Bar"] = 2 } },
        { from = 91,  to = 97,  craft = "Solid Bronze Ring",             count = 5,
          mats = { ["Bronze Bar"] = 4 } },
        { from = 97,  to = 100, craft = "Bronze Torc",                   count = 1,
          mats = { ["Bronze Bar"] = 6, ["Bronze Setting"] = 1, ["Lesser Moonstone"] = 1 } },
        { from = 100, to = 145, craft = "Ring of Twilight Shadows",      count = 21,
          mats = { ["Shadowgem"] = 2, ["Bronze Bar"] = 2 } },
        -- guide says Golden Ring of Power, but that needs 180 (warcraft.wiki.gg
        -- recipe table: 180/190/200/210), so at 145 nobody can learn it. Golden
        -- Dragon Ring is the trainer ring that is orange here (135/165/180/195).
        { from = 145, to = 151, craft = "Golden Dragon Ring",            count = 2,
          mats = { ["Gold Bar"] = 2, ["Delicate Copper Wire"] = 2, ["Jade"] = 1 } },
        -- guide says 8, but 151-176 is 25 points: 9 crafts at +3 (2 more Mithril)
        { from = 151, to = 176, craft = "Mithril Filigree",              count = 9,
          mats = { ["Mithril Bar"] = 2 } },
        { from = 176, to = 187, craft = "Solid Stone Statue",            count = 5,
          mats = { ["Solid Stone"] = 10 } },
        { from = 187, to = 202, craft = "Citrine Ring of Rapid Healing", count = 5,
          mats = { ["Citrine"] = 1, ["Mithril Bar"] = 2 } },
        { from = 202, to = 211, craft = "Amulet of Truesight",           count = 3,
          mats = { ["Truesilver Bar"] = 8 } },
        { from = 211, to = 226, craft = "Aquamarine Signet",             count = 5,
          mats = { ["Aquamarine"] = 3, ["Flask of Mojo"] = 4 } },
        { from = 226, to = 256, craft = "Thorium Setting",               count = 18,
          mats = { ["Thorium Bar"] = 1 } },
        { from = 256, to = 262, craft = "Truesilver Healing Ring",       count = 2,
          mats = { ["Truesilver Bar"] = 1, ["Heart of the Wild"] = 1 } },
        { from = 262, to = 280, craft = "Simple Opal Ring",              count = 6,
          mats = { ["Large Opal"] = 1, ["Thorium Setting"] = 1 } },
        { from = 280, to = 292, craft = "Sapphire Pendant of Winter Night", count = 4,
          mats = { ["Blue Sapphire"] = 1, ["Essence of Undeath"] = 1, ["Thorium Setting"] = 1 } },
        { from = 292, to = 301, craft = "Emerald Lion Ring",             count = 3,
          mats = { ["Huge Emerald"] = 2, ["Thorium Setting"] = 1 } },

        -- TBC
        { from = 301, to = 322, craft = "Radiant Deep Peridot",          count = 9,
          mats = { ["Deep Peridot"] = 1 } },
        { from = 322, to = 325, craft = "Jagged Deep Peridot",           count = 1,
          mats = { ["Deep Peridot"] = 1 } },
        { from = 325, to = 337, craft = "Glinting Flame Spessarite",     count = 4,
          mats = { ["Flame Spessarite"] = 1 } },
        { from = 337, to = 340, craft = "Sovereign Shadow Draenite",     count = 2,
          mats = { ["Shadow Draenite"] = 1 } },
        { from = 340, to = 346, craft = "Jagged Deep Peridot",           count = 2, again = true,
          mats = { ["Deep Peridot"] = 1 } },
        { from = 346, to = 352, craft = "Glinting Flame Spessarite",     count = 4, again = true,
          mats = { ["Flame Spessarite"] = 1 } },

        -- WotLK
        { from = 352, to = 397, craft = "Any Shadow Crystal gem",        count = 17,
          anyWith = { "Shadow Crystal" },
          mats = { ["Shadow Crystal"] = 1 } },
        { from = 397, to = 427, craft = "Any Forest Emerald gem",        count = 13,
          anyWith = { "Forest Emerald" },
          mats = { ["Forest Emerald"] = 1 } },
        { from = 427, to = 450, craft = "Icy Prism",                     count = 8,
          note = "Icy Prism has a 20 hour cooldown: one a day. With an Earthsiege or Skyflare Diamond in your bags the button cuts a meta gem instead while it is on cooldown.",
          alt = { craft = "Any meta gem", anyWith = { "Earthsiege Diamond", "Skyflare Diamond" } },
          mats = { ["Frozen Orb"] = 1, ["Chalcedony"] = 1, ["Shadow Crystal"] = 1, ["Dark Jade"] = 1 } },
    },
}
