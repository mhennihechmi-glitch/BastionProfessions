-- The crafting button, driven without a client.
--
-- The one behaviour worth guarding: it decides what to make from your LIVE
-- skill number after every update, never from a count of how many times you
-- clicked. Counting clicks means a lucky run of skill-ups leaves you making
-- something that has gone grey, and a dry one moves you on too early.

local checks, failed = 0, false
local function ok(label, cond)
    checks = checks + 1
    print((cond and "  PASS  " or "  FAIL  ") .. label)
    if not cond then failed = true end
end
local function section(s) print("\n=== " .. s .. " ===") end

-- a client
local function stub(kind, name)
    local t = { _kind = kind, _name = name, _scripts = {}, _attrs = {} }
    setmetatable(t, { __index = function(_, k)
        if type(k) == "string" and k:match("^%u") then
            return function() return stub("Frame") end
        end
    end })
    function t:SetScript(e, fn) self._scripts[e] = fn end
    function t:GetScript(e) return self._scripts[e] end
    function t:SetAttribute(k, v) self._attrs[k] = v end
    function t:GetAttribute(k) return self._attrs[k] end
    function t:RegisterEvent(e) self._ev = self._ev or {}; self._ev[e] = true end
    function t:SetText(v) self._t = v end
    function t:GetText() return self._t end
    function t:Show() self._shown = true end
    function t:Hide() self._shown = false end
    function t:CreateFontString() return stub("FontString") end
    if name then _G[name] = t end
    return t
end
local frames = {}
function CreateFrame(k, n) local f = stub(k, n); frames[#frames+1] = f; return f end
UIParent = stub("Frame", "UIParent")
GameTooltip = stub("Frame", "GameTooltip")
CHAT = {}
DEFAULT_CHAT_FRAME = { AddMessage = function(_, m) CHAT[#CHAT+1] = m end }
SlashCmdList = {}

-- the tradeskill window
SKILL, SKILL_LINE = 1, "Engineering"
RECIPES = {}       -- { {name, kind, numAvailable}, ... }
MAXRANK = 450
function GetTradeSkillLine() return SKILL_LINE, SKILL, MAXRANK end
ITEMS = {}
function GetItemCount(name) return ITEMS[name] or 99 end
function GetNumTradeSkills() return #RECIPES end
function GetTradeSkillInfo(i)
    local r = RECIPES[i]
    if not r then return nil end
    return r[1], r[2] or "optimal", r[3] or 10
end
function GetTradeSkillNumMade() return 1 end
function DoTradeSkill() end
function InCombatLockdown() return IN_COMBAT end
SHIFT_DOWN, CTRL_DOWN = false, false
function IsShiftKeyDown() return SHIFT_DOWN end
function IsControlKeyDown() return CTRL_DOWN end
IN_COMBAT = false
BINDINGS = {}
function SetOverrideBindingClick(owner, prio, key, button)
    BINDINGS[#BINDINGS+1] = { key = key, button = button }
end
function ClearOverrideBindings() BINDINGS = {} end

local ns = { ROUTE_END = 450 }   -- the full route; route405.lua tests the default
assert(loadfile("../Lists.lua"))("BastionProfessions", ns)
assert(loadfile("../Plan.lua"))("BastionProfessions", ns)
assert(loadfile("../Core.lua"))("BastionProfessions", ns)
assert(loadfile("../Level.lua"))("BastionProfessions", ns)
local ML = ns.ML

-- every recipe the plan ever asks for, all craftable
local have = {}
for _, s in ipairs(ns.plan.engi.steps) do
    if not have[s.craft] then RECIPES[#RECIPES+1] = { s.craft, "optimal", 20 }; have[s.craft] = true end
    if s.prep and not have[s.prep.craft] then
        RECIPES[#RECIPES+1] = { s.prep.craft, "optimal", 20 }; have[s.prep.craft] = true
    end
end

ML:Level()
local btn = _G.BastionProfLevelButton
ok("the button was built", btn ~= nil)

local function macro() return btn:GetAttribute("macrotext") or "" end
local function label() return btn.label:GetText() or "" end
local function indexOf(name)
    for i, r in ipairs(RECIPES) do if r[1] == name then return i end end
end

----------------------------------------------------------------------
section("it points at the step your skill is in")
----------------------------------------------------------------------

SKILL = 1;   ns.RefreshLevel()
ok("skill 1 makes Rough Blasting Powder", label():find("Rough Blasting Powder") ~= nil)
ok("and the macro targets that row",
   macro():find(("DoTradeSkill(%d,"):format(indexOf("Rough Blasting Powder")), 1, true) ~= nil)

----------------------------------------------------------------------
section("it retargets itself when the skill crosses a step")
----------------------------------------------------------------------

SKILL = 39;  ns.RefreshLevel()
local before = macro()
SKILL = 40;  ns.RefreshLevel()
ok("39 and 40 are different steps", macro() ~= before)
ok("40 is Handful of Copper Bolts", label():find("Handful of Copper Bolts") ~= nil)

-- Straight from 1 to 300 without passing through the middle: the button has
-- to catch up from whatever the number says, not from where it last was.
SKILL = 312; ns.RefreshLevel()
ok("a jump lands on the right step", label():find("Elemental Blasting Powder") ~= nil)

-- Every level, in order, must produce the recipe the plan names for it.
local wrong = 0
for lvl = 1, 449 do
    SKILL = lvl; ns.RefreshLevel()
    local step = ns.StepFor("engi", lvl)
    if not label():find(step.craft, 1, true) then wrong = wrong + 1 end
end
ok("all 449 levels point at the right recipe", wrong == 0)

----------------------------------------------------------------------
section("it stops at 450")
----------------------------------------------------------------------

SKILL = 450; ns.RefreshLevel()
ok("it says done",          label():find("done") ~= nil)
ok("and casts nothing",     macro() == "")

----------------------------------------------------------------------
section("it will not point at a recipe you do not have")
----------------------------------------------------------------------

-- The scope is learned from the trainer at 390. Arriving at 393 without
-- having trained it is a normal thing to happen, not an error.
local keep = RECIPES
RECIPES = {}
for _, r in ipairs(keep) do
    if r[1] ~= "Diamond-cut Refractor Scope" then RECIPES[#RECIPES+1] = r end
end
SKILL = 401; ns.RefreshLevel()
ok("it names what is missing", label():find("need: Diamond-cut Refractor Scope", 1, true) ~= nil)
ok("and casts nothing",        macro() == "")
RECIPES = keep

----------------------------------------------------------------------
section("no mats means no craft, not a failed one")
----------------------------------------------------------------------

for _, r in ipairs(RECIPES) do r[3] = 0 end
SKILL = 1; ns.RefreshLevel()
ok("it says there are no mats", label():find("no mats") ~= nil)
ok("and casts nothing",         macro() == "")
for _, r in ipairs(RECIPES) do r[3] = 20 end

----------------------------------------------------------------------
section("the wrong profession window is not used")
----------------------------------------------------------------------

SKILL_LINE = "Blacksmithing"
SKILL = 1; ns.RefreshLevel()
ok("it asks for the right window", label():find("open Engineering") ~= nil)
ok("and casts nothing",            macro() == "")
SKILL_LINE = "Engineering"

----------------------------------------------------------------------
section("the row is found by name every time")
----------------------------------------------------------------------

-- Collapsing a header or typing in the search box renumbers every row. A
-- remembered index then points at a different recipe, which would craft the
-- wrong thing rather than failing.
SKILL = 1; ns.RefreshLevel()
local firstMacro = macro()
table.insert(RECIPES, 1, { "Engineering", "header", 0 })
ns.RefreshLevel()
ok("inserting a header moved the target", macro() ~= firstMacro)
ok("and it still names the right recipe",
   macro():find(("DoTradeSkill(%d,"):format(indexOf("Rough Blasting Powder")), 1, true) ~= nil)
ok("a header is never the target",
   (function()
        local i = tonumber(macro():match("DoTradeSkill%((%d+)"))
        return i and RECIPES[i][2] ~= "header"
    end)())

----------------------------------------------------------------------
section("it queues what could finish the step at +3 a skill-up")
----------------------------------------------------------------------

-- Warmane gives +3 a skill-up, so (step.to - skill) / 3 crafts, rounded up,
-- is the most that can still be useful. More than that keeps crafting after
-- the step has gone grey.
local function batchOf() return tonumber(macro():match("DoTradeSkill%(%d+,(%d+)%)")) end

for _, r in ipairs(RECIPES) do r[3] = 999 end   -- mats for days

SKILL = 1;  ns.RefreshLevel()
ok("39 points to go, 13 queued", batchOf() == 13)
SKILL = 34; ns.RefreshLevel()
ok("6 points to go, 2 queued",   batchOf() == 2)
SKILL = 37; ns.RefreshLevel()
ok("3 points to go, 1 queued",   batchOf() == 1)
SKILL = 39; ns.RefreshLevel()
ok("1 point to go, 1 queued",    batchOf() == 1)

-- Never zero or negative: the button has to stay clickable on the last point.
local bad = 0
for lvl = 1, 449 do
    SKILL = lvl; ns.RefreshLevel()
    local b = batchOf()
    local step = ns.StepFor("engi", lvl)
    if not b or b < 1 or b > math.ceil((step.to - lvl) / 3) then bad = bad + 1 end
end
ok("every level queues between 1 and what is left of the step", bad == 0)

----------------------------------------------------------------------
section("the batch is also capped by your reagents")
----------------------------------------------------------------------

-- The window already knows how many you can make. Queueing more than that
-- means the tail of the queue fails on an empty bag.
for _, r in ipairs(RECIPES) do r[3] = 4 end
SKILL = 1; ns.RefreshLevel()
ok("mats for 4, so 4 queued even with 13 useful", batchOf() == 4)

for _, r in ipairs(RECIPES) do r[3] = 1 end
SKILL = 1; ns.RefreshLevel()
ok("mats for 1, so 1", batchOf() == 1)

for _, r in ipairs(RECIPES) do r[3] = 999 end

----------------------------------------------------------------------
section("the key is an override, held only while the button is up")
----------------------------------------------------------------------

-- An override rather than a real binding, so your own Shift-W returns the
-- moment the button is hidden and nothing is written to your keybind file.
BastionProfessionsDB = {}
BINDINGS = {}
ML:Level()
ok("showing it binds one key",     #BINDINGS == 1)
ok("the default is SHIFT-W",       BINDINGS[1] and BINDINGS[1].key == "SHIFT-W")
ok("to the button itself",         BINDINGS[1] and BINDINGS[1].button == "BastionProfLevelButton")

ML:Level("off")
ok("hiding it releases the key",   #BINDINGS == 0)

ML:Level("key", "ALT-E")
ML:Level()
ok("the key can be changed",       BINDINGS[1] and BINDINGS[1].key == "ALT-E")
ok("and it is remembered",         BastionProfessionsDB.levelKey == "ALT-E")

-- Changing a binding in combat is blocked by the client, so it must not be
-- attempted: the error is thrown at you, not swallowed.
ML:Level("off")
IN_COMBAT = true
BINDINGS = {}
ML:Level()
ok("in combat it binds nothing rather than erroring", #BINDINGS == 0)
IN_COMBAT = false
BastionProfessionsDB.levelKey = nil

----------------------------------------------------------------------
section("shift-click skips a step")
----------------------------------------------------------------------

-- A step can be unusable for reasons the skill number cannot see: a
-- reputation recipe you do not have, or reagents that cost more than the next
-- step's. Skipping is the escape hatch.
BastionProfessionsDB = {}
for _, r in ipairs(RECIPES) do r[3] = 999 end
ML:Level("auto")
SKILL = 1; ns.RefreshLevel()
ok("starts on step 1", label():find("Rough Blasting Powder") ~= nil)

SHIFT_DOWN = true
btn._scripts.PostClick()
SHIFT_DOWN = false
ok("shift-click moved on",      label():find("Handful of Copper Bolts") ~= nil)
ok("and says it is a skip",     label():find("skipped") ~= nil)
ok("skill itself did not move", SKILL == 1)

SHIFT_DOWN = true
btn._scripts.PostClick()
SHIFT_DOWN = false
ok("it can skip again",         label():find("Arclight Spanner") ~= nil)

----------------------------------------------------------------------
section("a skipped step batches from the step, not from your skill")
----------------------------------------------------------------------

-- Still at skill 1 but shown step 3, which runs 52-55. Measuring the batch
-- from skill 1 would queue 18 crafts to cover a gap that was jumped over.
local function batchOf2() return tonumber(macro():match("DoTradeSkill%(%d+,(%d+)%)")) end
ok("it queues the step's own span, not the gap", batchOf2() == 1)

----------------------------------------------------------------------
section("ctrl-click goes back to following your skill")
----------------------------------------------------------------------

CTRL_DOWN = true
btn._scripts.PostClick()
CTRL_DOWN = false
ok("back on step 1",        label():find("Rough Blasting Powder") ~= nil)
ok("and no longer marked",  label():find("skipped") == nil)

----------------------------------------------------------------------
section("a skip clears itself once your skill catches up")
----------------------------------------------------------------------

-- Otherwise it is a mode you can forget you are in, and the button looks
-- wrong for the rest of the evening with nothing explaining why.
SKILL = 1; ns.RefreshLevel()
SHIFT_DOWN = true; btn._scripts.PostClick(); SHIFT_DOWN = false
ok("skipped to step 2", label():find("Handful of Copper Bolts") ~= nil)

SKILL = 45; ns.RefreshLevel()      -- skill now naturally in step 2
ok("still step 2",            label():find("Handful of Copper Bolts") ~= nil)
ok("but no longer a skip",    label():find("skipped") == nil)

SKILL = 60; ns.RefreshLevel()      -- and past it
ok("it follows the skill again", label():find("Copper Tube") ~= nil)

----------------------------------------------------------------------
section("it will not skip past the end")
----------------------------------------------------------------------

SKILL = 449; ns.RefreshLevel()
local lastLabel = label()
SHIFT_DOWN = true; btn._scripts.PostClick(); SHIFT_DOWN = false
ok("the last step stays put", label() == lastLabel)

-- Skipping every step from the bottom must not run off the end either.
SKILL = 1; ML:Level("auto"); ns.RefreshLevel()
for _ = 1, 60 do
    SHIFT_DOWN = true; btn._scripts.PostClick(); SHIFT_DOWN = false
end
ok("60 skips land on the last step",
   label():find("Gnomish Army Knife", 1, true) ~= nil)
ok("and it still has something to craft", batchOf2() and batchOf2() >= 1)
ML:Level("auto")

----------------------------------------------------------------------
section("it stops you at a rank cap to train")
----------------------------------------------------------------------

-- At the cap nothing gains skill. Queueing anyway burns mats for nothing.
MAXRANK = 75; SKILL = 75; ns.RefreshLevel()
ok("at 75/75 it says train Journeyman", label():find("train: Journeyman Engineering", 1, true) ~= nil)
ok("and casts nothing",                 macro() == "")
MAXRANK = 150; ns.RefreshLevel()
ok("trained: back to crafting",         label():find("Copper Tube", 1, true) ~= nil)
MAXRANK = 375; SKILL = 375; ns.RefreshLevel()
ok("375 asks for Grand Master, in Northrend", label():find("Grand Master Engineering (from 350, in Northrend)", 1, true) ~= nil)
MAXRANK = 450; SKILL = 374; ns.RefreshLevel()
ok("below the cap it crafts",           label():find("Volatile Blasting Trigger", 1, true) ~= nil)

----------------------------------------------------------------------
section("it makes what a step needs in your bags first")
----------------------------------------------------------------------

-- Fel Iron Casing has no range of its own in the guide: make 3, then bombs.
ITEMS["Fel Iron Casing"] = 0
SKILL = 322; ns.RefreshLevel()
ok("no casings: it makes 3 first",  label():find("first: Fel Iron Casing", 1, true) ~= nil and batchOf2() == 3)
ok("and targets the casing row",
   macro():find(("DoTradeSkill(%d,"):format(indexOf("Fel Iron Casing")), 1, true) ~= nil)
ITEMS["Fel Iron Casing"] = 2; ns.RefreshLevel()
ok("2 in bags: 1 more",             batchOf2() == 1)
ITEMS["Fel Iron Casing"] = 3; ns.RefreshLevel()
ok("3 in bags: on to the bombs",    label():find("Fel Iron Bomb", 1, true) ~= nil and label():find("first") == nil)

-- Box of Bombs: 3 triggers, 2 per craft
ITEMS["Volatile Blasting Trigger"] = 0
SKILL = 406; ns.RefreshLevel()
ok("no triggers: 2 crafts make 3+", label():find("first: Volatile Blasting Trigger", 1, true) ~= nil and batchOf2() == 2)
ITEMS["Volatile Blasting Trigger"] = 1; ns.RefreshLevel()
ok("1 in bags: 1 craft",            batchOf2() == 1)
ITEMS["Volatile Blasting Trigger"] = nil; ns.RefreshLevel()
ok("enough: Box of Bombs",          label():find("Box of Bombs", 1, true) ~= nil)

-- the prep recipe not learned yet
ITEMS["Fel Iron Casing"] = 0
keep = RECIPES; RECIPES = {}
for _, r in ipairs(keep) do if r[1] ~= "Fel Iron Casing" then RECIPES[#RECIPES+1] = r end end
SKILL = 322; ns.RefreshLevel()
ok("missing casing recipe is named", label():find("need: Fel Iron Casing", 1, true) ~= nil and macro() == "")
RECIPES = keep; ITEMS = {}

print(("\nRESULT: %s (%d checks)"):format(
    failed and "failures above" or "all assertions passed", checks))
os.exit(failed and 1 or 0)
