-- The levelling route, and the one thing that keeps it honest.
--
-- The shopping list and the craft plan are two hand-written descriptions of
-- the same guide. Nothing stops them drifting, and when they do the symptom
-- is not an error: you buy everything the list asked for, fly to a trainer,
-- and find out at skill 336 that you are 20 Netherweave Cloth short. That is
-- a real example. It was missing from the list and from the guide's own
-- summary, and only the step that uses it knew.
--
-- So the test is: every reagent any step needs is either on the shopping
-- list, or is something an earlier step makes.

local checks, failed = 0, false
local function ok(label, cond)
    checks = checks + 1
    print((cond and "  PASS  " or "  FAIL  ") .. label)
    if not cond then failed = true end
end
local function section(s) print("\n=== " .. s .. " ===") end

local ns = { ROUTE_END = 450 }   -- the full route; route405.lua tests the default
assert(loadfile("../Lists.lua"))("BastionProfessions", ns)
assert(loadfile("../Plan.lua"))("BastionProfessions", ns)

local plan = ns.plan.engi
local list = ns.lists.engi

----------------------------------------------------------------------
section("the route is continuous and goes all the way")
----------------------------------------------------------------------

ok("it starts at 1",  plan.steps[1].from == 1)
ok("it ends at 450",  plan.steps[#plan.steps].to == 450)

local gaps = {}
for i = 2, #plan.steps do
    local prev, cur = plan.steps[i-1], plan.steps[i]
    if cur.from ~= prev.to then
        gaps[#gaps+1] = ("%d -> %d"):format(prev.to, cur.from)
    end
end
-- A gap is a skill range with no instruction: the button would point at the
-- next step's recipe while it is still red, or at nothing at all.
ok("no gaps between steps", #gaps == 0)
for _, g in ipairs(gaps) do print("        gap at " .. g) end

local backwards = false
for _, s in ipairs(plan.steps) do if s.to <= s.from then backwards = true end end
ok("every step moves forward", not backwards)

----------------------------------------------------------------------
section("every reagent is accounted for")
----------------------------------------------------------------------

local onList = {}
for _, it in ipairs(list.items) do onList[it[1]] = it[2] end

local crafted = {}
local missing = {}
for _, s in ipairs(plan.steps) do
    -- a prep is made at the start of its step, from mats that must exist too
    if s.prep then
        for mat in pairs(s.prep.mats or {}) do
            if not onList[mat] and not crafted[mat] then
                missing[#missing+1] = mat .. "  (needed at " .. s.from .. " for " .. s.prep.craft .. ")"
            end
        end
        crafted[s.prep.craft] = true
    end
    for mat in pairs(s.mats or {}) do
        if not onList[mat] and not crafted[mat] then
            missing[#missing+1] = mat .. "  (needed at " .. s.from .. " for " .. s.craft .. ")"
        end
    end
    crafted[s.craft] = true          -- made by this step, available to later ones
end
ok("nothing a step needs is unbuyable and unmade", #missing == 0)
for _, m in ipairs(missing) do print("        MISSING  " .. m) end

----------------------------------------------------------------------
section("the quantities cover the plan")
----------------------------------------------------------------------

-- Not an exact match: the guide rounds, procs vary, and some mats are bought
-- in round numbers. But the list should never be WILDLY short of what the
-- steps consume, which is what a transcription slip looks like.
local need, made = {}, {}
for _, s in ipairs(plan.steps) do
    for mat, per in pairs(s.mats or {}) do
        need[mat] = (need[mat] or 0) + per * (s.count or 0)
    end
    made[s.craft] = (made[s.craft] or 0) + (s.count or 0) * (s.makes or 1)
    if s.prep then
        local crafts = math.ceil(s.prep.need / (s.prep.makes or 1))
        for mat, per in pairs(s.prep.mats or {}) do
            need[mat] = (need[mat] or 0) + per * crafts
        end
        made[s.prep.craft] = (made[s.prep.craft] or 0) + crafts * (s.prep.makes or 1)
    end
end
local short = {}
for mat, n in pairs(need) do
    local have = onList[mat]
    if have and have * 2 < n then
        short[#short+1] = ("%s: list has %d, steps use %d"):format(mat, have, n)
    end
end
ok("no item is less than half what the steps consume", #short == 0)
for _, m in ipairs(short) do print("        " .. m) end

-- Stricter, for bought items: the updated guide's summary was short in two
-- places (Mithril 28 for 32 used, Fel Iron 14 for 23), and the list now
-- carries what the steps use. Buying everything must get you to 450.
local under = {}
for _, it in ipairs(list.items) do
    local name, have, src = it[1], it[2], it[3]
    if src ~= "craft" and need[name] and have < need[name] then
        under[#under+1] = ("%s: list has %d, steps use %d"):format(name, have, need[name])
    end
end
ok("every bought item covers what the steps use", #under == 0)
for _, m in ipairs(under) do print("        " .. m) end

-- And what you craft along the way is enough for what uses it later.
local thin = {}
for mat, n in pairs(need) do
    if made[mat] and made[mat] < n then
        thin[#thin+1] = ("%s: made %d, used %d"):format(mat, made[mat], n)
    end
end
ok("crafted reagents cover what later steps use", #thin == 0)
for _, m in ipairs(thin) do print("        " .. m) end

----------------------------------------------------------------------
section("the step for a given skill level")
----------------------------------------------------------------------

-- This is what the button asks after every craft. Getting it wrong by one
-- means making something that has gone grey.
local s1 = ns.StepFor("engi", 1)
ok("skill 1 is the first step",       s1 and s1.craft == "Rough Blasting Powder")
local s39 = ns.StepFor("engi", 39)
ok("39 is still the first step",      s39 and s39.craft == "Rough Blasting Powder")
local s40 = ns.StepFor("engi", 40)
ok("40 has moved on",                 s40 and s40.craft == "Handful of Copper Bolts")
local s336 = ns.StepFor("engi", 336)
ok("336 is still grenades",           s336 and s336.craft == "Adamantite Grenade")
local s404 = ns.StepFor("engi", 404)
ok("404 is the scope",                s404 and s404.craft == "Diamond-cut Refractor Scope")
local s449 = ns.StepFor("engi", 449)
ok("449 is the last step",            s449 and s449.craft == "Gnomish Army Knife")
ok("450 is finished",                 ns.StepFor("engi", 450) == nil)
ok("so is anything above it",         ns.StepFor("engi", 999) == nil)

-- Every level from 1 to 449 has to land somewhere, or the button goes blank
-- partway up and the only clue is that it stopped working.
local blanks = {}
for lvl = 1, 449 do
    if not ns.StepFor("engi", lvl) then blanks[#blanks+1] = lvl end
end
ok("every skill level from 1 to 449 has a step", #blanks == 0)
if #blanks > 0 then print(("        %d blank level(s), first at %d"):format(#blanks, blanks[1])) end

----------------------------------------------------------------------
section("recipe names are plausible")
----------------------------------------------------------------------

-- The tradeskill window is searched by exact name. A typo does not throw, it
-- means the button silently never finds the recipe.
local dupes, seen = {}, {}
for _, s in ipairs(plan.steps) do
    -- the guide does come back to Mithril Gyro-Shot; that one is marked
    if seen[s.craft] and not s.again then dupes[#dupes+1] = s.craft end
    seen[s.craft] = true
end
ok("no recipe is used by two steps unless marked", #dupes == 0)
for _, d in ipairs(dupes) do print("        twice: " .. d) end

-- every rank cap sits inside the route, so the button can say "train"
for cap in pairs(plan.train) do
    ok("cap " .. cap .. " falls inside a step", ns.StepFor("engi", cap) ~= nil)
end
ok("Warmane gain is 3 a skill-up", plan.gain == 3)

local bad = {}
for _, s in ipairs(plan.steps) do
    if s.craft:match("^%s") or s.craft:match("%s$") or s.craft == "" then
        bad[#bad+1] = ("%q"):format(s.craft)
    end
    if not s.count or s.count < 1 then bad[#bad+1] = s.craft .. " has no count" end
end
ok("no stray whitespace or missing counts", #bad == 0)
for _, m in ipairs(bad) do print("        " .. m) end

print(("\nRESULT: %s (%d checks)"):format(
    failed and "failures above" or "all assertions passed", checks))
os.exit(failed and 1 or 0)
