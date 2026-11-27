local _, ns = ...

-- Shopping lists and "what is still needed", worked out from the routes.
--
-- Engineering keeps its hand-checked list in Lists.lua (tests/plan.lua holds
-- it against the route). The other professions get theirs built here from
-- their steps, so the list and the route cannot drift apart: change a step
-- and the list follows.
--
-- A row is { name, quantity, source } like Lists.lua, source being
--   "ah"      buy it at the auction house
--   "vendor"  a vendor sells it; not worth an auction house search
--   "craft"   an earlier step of the route makes it

ns.lists = ns.lists or {}

-- Everything the route itself makes, so it is never put on a shopping list.
local function madeByRoute(plan)
    local set = {}
    for _, s in ipairs(plan.steps) do
        if not s.anyWith then set[s.craft] = true end
        if s.prep then set[s.prep.craft] = true end
    end
    return set
end

local function sortedMats(mats)
    local names = {}
    for n in pairs(mats or {}) do names[#names + 1] = n end
    table.sort(names)
    return names
end

-- Adds a step's reagents for `crafts` crafts (plus its prep) to the tally,
-- keeping first-use order so the panel lists things in the order you need
-- them.
local function tally(order, qty, step, crafts, withPrep)
    local function add(n, q)
        if q <= 0 then return end
        if not qty[n] then order[#order + 1] = n; qty[n] = 0 end
        qty[n] = qty[n] + q
    end
    if withPrep and step.prep then
        local runs = math.ceil(step.prep.need / (step.prep.makes or 1))
        for _, n in ipairs(sortedMats(step.prep.mats)) do add(n, step.prep.mats[n] * runs) end
    end
    for _, n in ipairs(sortedMats(step.mats)) do add(n, step.mats[n] * crafts) end
end

local function sourceFor(plan, made, name, override)
    if override then return override end
    if plan.vendor and plan.vendor[name] then return "vendor" end
    if made[name] then return "craft" end
    return "ah"
end

-- The whole-route list for a profession that has no hand-written one.
local function buildList(key, plan)
    local order, qty = {}, {}
    for _, s in ipairs(plan.steps) do tally(order, qty, s, s.count, true) end
    local extraOf = {}
    for _, e in ipairs(plan.extra or {}) do
        if not qty[e[1]] then order[#order + 1] = e[1]; qty[e[1]] = 0 end
        qty[e[1]] = qty[e[1]] + e[2]
        extraOf[e[1]] = e
    end
    local made, items = madeByRoute(plan), {}
    for _, n in ipairs(order) do
        local e = extraOf[n]
        items[#items + 1] = { n, qty[n], sourceFor(plan, made, n, e and e[3]),
                              learns = e and e.learns }
    end
    return { label = plan.label, items = items, built = true }
end

for key, plan in pairs(ns.plan) do
    if not ns.lists[key] then ns.lists[key] = buildList(key, plan) end
end

-- Where a reagent comes from, for any profession.
function ns.SourceOf(key, name)
    local list = ns.lists[key]
    for _, row in ipairs(list and list.items or {}) do
        if row[1] == name then return row[3] end
    end
    local plan = ns.plan[key]
    return sourceFor(plan, madeByRoute(plan), name)
end

-- Recipes you have learned, per character, seen the last time each window
-- was open. Lets a formula on the list tick itself off.
function ns.Known(key, recipe)
    local me = UnitName and UnitName("player") or "?"
    local k = BastionProfessionsDB and BastionProfessionsDB.known and BastionProfessionsDB.known[me]
    return k and k[key] and k[key][recipe] or false
end

-- What the route still takes from `skill` up to `upTo` (default: the end):
-- the current step pro rata (half done, half the mats), every later step in
-- full, and a step that runs past `upTo` cut there the same way. The list of
-- rows is in first-use order.
--   { name, need, source, learns }
function ns.Needs(key, skill, upTo)
    local plan = ns.plan[key]
    if not plan then return {} end
    skill = skill or 0
    upTo = upTo or plan.steps[#plan.steps].to
    local order, qty = {}, {}
    for _, s in ipairs(plan.steps) do
        if s.to > skill and s.from < upTo then
            local span = s.to - s.from
            local left = math.min(s.to, upTo) - math.max(skill, s.from)
            local crafts = (span > 0) and math.ceil(s.count * left / span) or s.count
            -- prep only before the step is reached; once you are in it the
            -- casings or triggers are either in your bags or the button is
            -- making them, and the bag count says which
            tally(order, qty, s, crafts, skill < s.from)
        end
    end
    local made, rows = madeByRoute(plan), {}
    for _, n in ipairs(order) do
        rows[#rows + 1] = { n, qty[n], ns.SourceOf(key, n) }
    end
    -- a formula or plan is only still needed while the step that uses it is
    -- ahead of you
    local function stillAhead(recipe)
        for _, s in ipairs(plan.steps) do
            if s.craft == recipe then return s.to > skill and s.from < upTo end
        end
        return true
    end
    for _, e in ipairs(plan.extra or {}) do
        local wanted = true
        if e.learns then wanted = stillAhead(e.learns) and not ns.Known(key, e.learns) end
        if e.forFormulas then wanted = skill < 442 and upTo > 430 end
        if wanted then
            local merged = false
            for _, r in ipairs(rows) do
                if r[1] == e[1] then r[2] = r[2] + e[2]; merged = true break end
            end
            if not merged then rows[#rows + 1] = { e[1], e[2], e[3], learns = e.learns } end
        end
    end
    return rows
end

-- Your skill in a profession without its window open, from the character's
-- skill list. Remembered too, so the panel knows where you are on an alt
-- that has not opened the window this session.
function ns.SkillOf(skillName)
    if GetNumSkillLines and GetSkillLineInfo then
        for i = 1, (GetNumSkillLines() or 0) do
            local name, header, _, rank, _, _, maxRank = GetSkillLineInfo(i)
            if name == skillName and not header then return rank, maxRank end
        end
    end
    return nil
end
