-- The guild build: the same files, cut at 405 by ns.ROUTE_END.
local checks, failed = 0, false
local function ok(l, c) checks = checks + 1; print((c and "  PASS  " or "  FAIL  ") .. l); if not c then failed = true end end

local ns = {}   -- the default this copy ships with
assert(loadfile("../Lists.lua"))("BastionProfessions", ns)
assert(loadfile("../Plan.lua"))("BastionProfessions", ns)
local plan, list = ns.plan.engi, ns.lists.engi

ok("labelled 1-405", plan.label == "Engineering 1-405" and list.label == "Engineering 1-405")
ok("the route ends at 405", plan.steps[#plan.steps].to == 405)
ok("last step is the scope", plan.steps[#plan.steps].craft == "Diamond-cut Refractor Scope")
ok("404 still has a step, 405 is done", ns.StepFor("engi", 404) ~= nil and ns.StepFor("engi", 405) == nil)
local onList = {}
for _, it in ipairs(list.items) do onList[it[1]] = it end
ok("no Saronite, Eternal Air, Twilight Opal or knives", not onList["Saronite Bar"] and not onList["Eternal Air"]
   and not onList["Twilight Opal"] and not onList["Skinning Knife"] and not onList["Mining Pick"] and not onList["Blacksmith Hammer"])
ok("Cobalt 86, Water 10", onList["Cobalt Bar"][2] == 86 and onList["Crystallized Water"][2] == 10)
ok("an old 1-450 list gets removed", list.oldLabels[1] == "Engineering 1-450")

-- every bought item still covers what the remaining steps use
local need = {}
for _, s in ipairs(plan.steps) do
    for m, per in pairs(s.mats or {}) do need[m] = (need[m] or 0) + per * s.count end
    if s.prep then
        local c = math.ceil(s.prep.need / (s.prep.makes or 1))
        for m, per in pairs(s.prep.mats or {}) do need[m] = (need[m] or 0) + per * c end
    end
end
local under = {}
for _, it in ipairs(list.items) do
    if it[3] ~= "craft" and need[it[1]] and it[2] < need[it[1]] then under[#under + 1] = it[1] end
end
ok("every bought item covers the 1-405 steps", #under == 0)
for _, u in ipairs(under) do print("        short: " .. u) end
local unused = {}
for _, it in ipairs(list.items) do
    if it[3] ~= "craft" and not need[it[1]] then unused[#unused + 1] = it[1] end
end
ok("nothing on the list that 1-405 never uses", #unused == 0)
for _, u in ipairs(unused) do print("        unused: " .. u) end

print(("\n%d checks, %s"):format(checks, failed and "FAILED" or "all passed"))
os.exit(failed and 1 or 0)
