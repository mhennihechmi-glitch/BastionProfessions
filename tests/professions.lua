-- Blacksmithing, Jewelcrafting and Enchanting, plus the panel.
-- Run from tests/: lua professions.lua

local checks, failed = 0, false
local function ok(label, cond)
    checks = checks + 1
    print((cond and "  PASS  " or "  FAIL  ") .. label)
    if not cond then failed = true end
end
local function section(s) print("\n=== " .. s .. " ===") end

-- ---------- a client ----------
local function stub(kind, name)
    local t = { _kind = kind, _name = name, _scripts = {}, _attrs = {}, _shown = true }
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
    function t:Show() self._shown = true; if self._scripts.OnShow then self._scripts.OnShow(self) end end
    function t:Hide() self._shown = false; if self._scripts.OnHide then self._scripts.OnHide(self) end end
    function t:IsShown() return self._shown end
    function t:CreateFontString() return stub("FontString") end
    function t:GetFontString() return stub("FontString") end
    if name then _G[name] = t end
    return t
end
FRAMES = {}
function CreateFrame(k, n) local f = stub(k, n); FRAMES[#FRAMES+1] = f; return f end
UIParent = stub("Frame", "UIParent")
GameTooltip = stub("Frame", "GameTooltip")
CHAT = {}
DEFAULT_CHAT_FRAME = { AddMessage = function(_, m) CHAT[#CHAT+1] = m end }
SlashCmdList, UISpecialFrames = {}, {}
tinsert = table.insert
function wipe(t) for k in pairs(t) do t[k] = nil end return t end
function UnitName() return "Wizax" end
GT = 1000
function GetTime() return GT end
function FauxScrollFrame_GetOffset() return 0 end
function FauxScrollFrame_Update() end
function FauxScrollFrame_OnVerticalScroll() end

-- the tradeskill window
SKILL, SKILL_LINE, MAXRANK = 1, "Blacksmithing", 450
RECIPES = {}     -- { name, kind, numAvailable, reagents = {..}, cd = n, tools = {name, has} }
function GetTradeSkillLine() return SKILL_LINE, SKILL, MAXRANK end
function GetNumTradeSkills() return #RECIPES end
function GetTradeSkillInfo(i)
    local r = RECIPES[i]; if not r then return nil end
    return r[1], r[2] or "optimal", r[3] or 10
end
function GetTradeSkillNumMade() return 1 end
function GetTradeSkillNumReagents(i) return #(RECIPES[i].reagents or { "x", "y" }) end
function GetTradeSkillReagentInfo(i, n) return (RECIPES[i].reagents or {})[n] end
function GetTradeSkillCooldown(i) return RECIPES[i].cd end
function GetTradeSkillTools(i) local t = RECIPES[i].tools; if t then return t[1], t[2] end end
function DoTradeSkill() end
ITEMS = {}
function GetItemCount(name) return ITEMS[name] or 0 end
function InCombatLockdown() return false end
function IsShiftKeyDown() return false end
function IsControlKeyDown() return false end
function SetOverrideBindingClick() end
function ClearOverrideBindings() end

-- bags: BAG[bag][slot] = { link, count }
BAG = { [0] = {}, {}, {}, {}, {} }
ITEMINFO = {}    -- name -> { quality, ilvl, equipLoc }
function GetContainerNumSlots(b) return BAG[b] and 16 or 0 end
function GetContainerItemLink(b, s) return BAG[b] and BAG[b][s] and BAG[b][s][1] end
function GetContainerItemInfo(b, s) local x = BAG[b] and BAG[b][s]; return nil, x and x[2] end
function GetItemInfo(x)
    local name = x:match("%[(.-)%]") or x
    local i = ITEMINFO[name]
    if not i then return nil end
    return name, x, i[1], i[2], 0, "Armor", "Misc", 1, i[3]
end
local nextId = 1000
local function item(bag, slot, name, count, quality, ilvl, loc)
    nextId = nextId + 1
    BAG[bag][slot] = { ("|cffffffff|Hitem:%d:0:0:0|h[%s]|h|r"):format(nextId, name), count or 1 }
    if quality then ITEMINFO[name] = { quality, ilvl, loc } end
    return nextId
end

-- popups
HOOKS = {}
function hooksecurefunc(name, fn) local orig = _G[name]; _G[name] = function(...) local r = orig and orig(...); fn(...); return r end end
function StaticPopup_Show(which) POPUP = which end
function StaticPopup_Hide(which) if POPUP == which then POPUP = nil end; HIDDEN = which end
function ReplaceEnchant() REPLACED = (REPLACED or 0) + 1 end
function BindEnchant() BOUND = (BOUND or 0) + 1 end

-- Auctionator
AUCTIONATOR_SHOPPING_LISTS = {}
Atr_SList = {}
function Atr_SortSlists() return false end

local ns = { ROUTE_END = 405 }
for _, f in ipairs({ "Lists.lua", "Plan.lua", "PlanBlacksmithing.lua", "PlanJewelcrafting.lua",
                     "PlanEnchanting.lua", "Build.lua", "Core.lua", "Level.lua", "Panel.lua" }) do
    assert(loadfile("../" .. f))("BastionProfessions", ns)
end
local ML = ns.ML
BastionProfessionsDB = {}

local function total(key, name)
    for _, r in ipairs(ns.lists[key].items) do if r[1] == name then return r[2], r[3] end end
    return 0
end

----------------------------------------------------------------------
section("each route runs 1 to 450 with no gaps")
----------------------------------------------------------------------
for _, key in ipairs({ "bs", "jc", "ench" }) do
    local p, gap, short = ns.plan[key], 0, 0
    local prev = 1
    for _, s in ipairs(p.steps) do
        if s.from ~= prev then gap = gap + 1 end
        prev = s.to
        -- at +3 a skill-up a step can never need fewer crafts than its points / 3
        if s.count < math.ceil((s.to - s.from) / 3) then short = short + 1 end
    end
    ok(key .. ": starts at 1, no gaps, ends at 450", gap == 0 and prev == 450)
    ok(key .. ": no step has fewer crafts than its points need", short == 0)
end
ok("Engineering still stops at 405 by default", ns.plan.engi.steps[#ns.plan.engi.steps].to == 405)
ok("and the others do not",                     ns.plan.bs.steps[#ns.plan.bs.steps].to == 450)

----------------------------------------------------------------------
section("the lists add up to the guide")
----------------------------------------------------------------------
ok("BS Cobalt Bar 108",   total("bs", "Cobalt Bar") == 108)
ok("BS Saronite Bar 87",  total("bs", "Saronite Bar") == 87)
ok("BS Thorium Bar 140",  total("bs", "Thorium Bar") == 140)
ok("BS Mithril Bar 96",   total("bs", "Mithril Bar") == 96)
ok("BS Rough Stone 114",  total("bs", "Rough Stone") == 114)
ok("BS Fel Iron Bar 54 (the guide's 44 is short)", total("bs", "Fel Iron Bar") == 54)
ok("BS Green Dye is a vendor item",  select(2, total("bs", "Green Dye")) == "vendor")
ok("BS grinding stones the route makes are not bought", select(2, total("bs", "Heavy Grinding Stone")) == "craft")
ok("JC Bronze Bar 126",   total("jc", "Bronze Bar") == 126)
ok("JC Deep Peridot 12",  total("jc", "Deep Peridot") == 12)
ok("JC Shadow Crystal 25", total("jc", "Shadow Crystal") == 25)
ok("JC Thorium Setting is made, not bought", select(2, total("jc", "Thorium Setting")) == "craft")
ok("Enchanting Strange Dust 99",  total("ench", "Strange Dust") == 99)
ok("Enchanting Dream Dust 202",   total("ench", "Dream Dust") == 202)
ok("Enchanting Soul Dust 44",     total("ench", "Soul Dust") == 44)
ok("Enchanting Greater Cosmic Essence 42", total("ench", "Greater Cosmic Essence") == 42)
ok("Enchanting Dream Shard 26 (18 + 8 for the two formulas)", total("ench", "Dream Shard") == 26)
ok("Enchanting Infinite Dust 273 (the guide's 246 is short)", total("ench", "Infinite Dust") == 273)
ok("the runed rods are made, the plain rods bought",
   select(2, total("ench", "Runed Silver Rod")) == "craft" and select(2, total("ench", "Silver Rod")) == "ah")
ok("Copper Rod is a vendor item", select(2, total("ench", "Copper Rod")) == "vendor")

----------------------------------------------------------------------
section("still needed follows your skill")
----------------------------------------------------------------------
local function need(key, skill, name)
    for _, r in ipairs(ns.Needs(key, skill)) do if r[1] == name then return r[2] end end
    return 0
end
ok("at 1 the rest of the route is the whole list", need("bs", 1, "Cobalt Bar") == 108)
ok("at 352 all the Cobalt is still to come",       need("bs", 352, "Cobalt Bar") == 108)
ok("at 400 only the helm's 16 Cobalt is left",     need("bs", 400, "Cobalt Bar") == 16)
ok("at 403, half way through the helm, 8",         need("bs", 403, "Cobalt Bar") == 8)
ok("at 450 nothing",                               #ns.Needs("bs", 450) == 0)
ok("Engineering at 1 still asks the guide's 40 Rough Stone", need("engi", 1, "Rough Stone") == 40)

----------------------------------------------------------------------
section("the button follows whichever window is open")
----------------------------------------------------------------------
RECIPES = {}
local seen = {}
for _, key in ipairs({ "bs" }) do
    for _, s in ipairs(ns.plan[key].steps) do
        if not seen[s.craft] then RECIPES[#RECIPES+1] = { s.craft, "optimal", 20 }; seen[s.craft] = true end
    end
end
ML:Level()
local btn = _G.BastionProfLevelButton
local function label() return btn.label:GetText() or "" end
local function macro() return btn:GetAttribute("macrotext") or "" end
SKILL_LINE, SKILL = "Blacksmithing", 1; ns.RefreshLevel()
ok("Blacksmithing open: the button is on Blacksmithing", ns.ActiveKey() == "bs")
ok("skill 1 makes Rough Sharpening Stone", label():find("Rough Sharpening Stone", 1, true) ~= nil)
ok("24 points at +3: 8 queued", macro():find(",8)", 1, true) ~= nil)
local wrong = 0
for lvl = 1, 449 do
    SKILL = lvl; ns.RefreshLevel()
    if not label():find(ns.StepFor("bs", lvl).craft, 1, true) then wrong = wrong + 1 end
end
ok("all 449 Blacksmithing levels point at the right recipe", wrong == 0)

-- no anvil
SKILL = 352; ns.RefreshLevel()
for _, r in ipairs(RECIPES) do if r[1] == "Cobalt Boots" then r.tools = { "Anvil", false } end end
ns.RefreshLevel()
ok("no anvil: it says so",       label():find("needs: Anvil", 1, true) ~= nil)
ok("and casts nothing",          macro() == "")
for _, r in ipairs(RECIPES) do r.tools = nil end

-- Engineering is untouched when its window opens
RECIPES = {}
seen = {}
for _, s in ipairs(ns.plan.engi.steps) do
    if not seen[s.craft] then RECIPES[#RECIPES+1] = { s.craft, "optimal", 20 }; seen[s.craft] = true end
    if s.prep and not seen[s.prep.craft] then RECIPES[#RECIPES+1] = { s.prep.craft, "optimal", 20 }; seen[s.prep.craft] = true end
end
SKILL_LINE, SKILL = "Engineering", 1; ns.RefreshLevel()
ok("Engineering open: back on Engineering", ns.ActiveKey() == "engi"
   and label():find("Rough Blasting Powder", 1, true) ~= nil)
ITEMS = { ["Fel Iron Casing"] = 3, ["Volatile Blasting Trigger"] = 3 }
wrong = 0
for lvl = 1, 404 do
    SKILL = lvl; ns.RefreshLevel()
    if not label():find(ns.StepFor("engi", lvl).craft, 1, true) then wrong = wrong + 1 end
end
ok("all 404 Engineering levels still right with the other routes loaded", wrong == 0)
ITEMS = {}
-- the Green Smoke Flare schematic instead of the White one
for _, r in ipairs(RECIPES) do if r[1] == "White Smoke Flare" then r[1] = "Green Smoke Flare" end end
SKILL = 340; ns.RefreshLevel()
ok("only Green Smoke Flare known: the button makes that", label():find("Green Smoke Flare", 1, true) ~= nil and macro() ~= "")
for _, r in ipairs(RECIPES) do if r[1] == "Green Smoke Flare" then r[1] = "Something Else" end end
ns.RefreshLevel()
ok("neither known: it names both", label():find("need: White Smoke Flare or Green Smoke Flare", 1, true) ~= nil)
for _, r in ipairs(RECIPES) do if r[1] == "Something Else" then r[1] = "White Smoke Flare" end end

----------------------------------------------------------------------
section("Jewelcrafting: any Shadow Crystal gem, and Icy Prism")
----------------------------------------------------------------------
RECIPES = {
    { "Jewelcrafting", "header", 0 },
    { "Icy Prism", "optimal", 0, reagents = { "Frozen Orb", "Chalcedony", "Shadow Crystal", "Dark Jade" } },
    { "Glowing Shadow Crystal", "easy", 5, reagents = { "Shadow Crystal" } },
    { "Sovereign Shadow Crystal", "optimal", 5, reagents = { "Shadow Crystal" } },
    { "Purified Shadow Crystal", "trivial", 5, reagents = { "Shadow Crystal" } },
    { "Bold Bloodstone", "optimal", 5, reagents = { "Bloodstone" } },
}
SKILL_LINE, SKILL = "Jewelcrafting", 360; ns.RefreshLevel()
ok("Jewelcrafting open: on Jewelcrafting", ns.ActiveKey() == "jc")
ok("it picks the orange Shadow Crystal cut", label():find("Sovereign Shadow Crystal", 1, true) ~= nil)
ok("never Icy Prism (four reagents) for this step", label():find("Icy Prism", 1, true) == nil)
RECIPES[4][3] = 0; ns.RefreshLevel()
ok("no mats for the orange one: the green one you can make", label():find("Glowing Shadow Crystal", 1, true) ~= nil)
RECIPES[4][3] = 5
RECIPES[#RECIPES+1] = { "Icy Prism", "optimal", 3, reagents = { "Frozen Orb", "Chalcedony", "Shadow Crystal", "Dark Jade" }, cd = 0 }
table.remove(RECIPES, 2)
SKILL = 430; ns.RefreshLevel()
ok("430: Icy Prism", label():find("Icy Prism", 1, true) ~= nil)
RECIPES[#RECIPES].cd = 5 * 3600 + 7 * 60; ns.RefreshLevel()
ok("on cooldown with no diamond: says when it is ready", label():find("ready in 5h 07m", 1, true) ~= nil and macro() == "")
RECIPES[#RECIPES+1] = { "Relentless Earthsiege Diamond", "optimal", 2, reagents = { "Earthsiege Diamond" } }
ns.RefreshLevel()
ok("with a diamond: cuts a meta gem instead", label():find("Relentless Earthsiege Diamond", 1, true) ~= nil)

----------------------------------------------------------------------
section("Enchanting: onto a cheap item in your bags")
----------------------------------------------------------------------
RECIPES = { { "Enchanting", "header", 0 },
            { "Enchant Bracer - Minor Health", "optimal", 20 },
            { "Runed Copper Rod", "optimal", 1 },
            { "Enchant Bracers - Striking", "optimal", 9 } }
SKILL_LINE, SKILL = "Enchanting", 10; ns.RefreshLevel()
ok("Enchanting open: on Enchanting", ns.ActiveKey() == "ench")
ok("no bracer in bags: it asks for one", label():find("put a bracer in your bags", 1, true) ~= nil and macro() == "")
item(0, 3, "Bracers of the Raid", 1, 4, 264, "INVTYPE_WRIST")        -- epic: never
local setId = item(0, 4, "Set Bracers", 1, 2, 200, "INVTYPE_WRIST")  -- in an equipment set: never
function GetNumEquipmentSets() return 1 end
function GetEquipmentSetInfo() return "Tank" end
function GetEquipmentSetItemIDs() return { setId } end
ns.RefreshLevel()
ok("an epic bracer and a set bracer are never used", label():find("put a bracer", 1, true) ~= nil)
item(1, 2, "Cheap Bracer", 1, 1, 10, "INVTYPE_WRIST")
item(1, 5, "Green Bracer", 1, 2, 30, "INVTYPE_WRIST")
ns.RefreshLevel()
ok("it picks the higher-level cheap bracer", label():find("on Green Bracer", 1, true) ~= nil)
ok("and the macro enchants it, then puts it on that bag slot",
   macro() == "/run DoTradeSkill(2)\n/use 1 5")
ns.NextEnchantTarget("bracer")
ok("Other item switches to the next one", label():find("on Cheap Bracer", 1, true) ~= nil
   and macro() == "/run DoTradeSkill(2)\n/use 1 2")
ok("and remembers it", BastionProfessionsDB.enchTarget and BastionProfessionsDB.enchTarget.bracer ~= nil)
-- the game asks to replace the old enchant
StaticPopup1 = stub("Frame"); StaticPopup1.which = "REPLACE_ENCHANT"; StaticPopup1._shown = true
ns.RefreshLevel()
ok("replace question: the next press answers it", macro() == "/click StaticPopup1Button1"
   and label():find("press again", 1, true) ~= nil)
StaticPopup1.which = "DELETE_ITEM"
ns.RefreshLevel()
ok("any other popup is never clicked", macro():find("StaticPopup", 1, true) == nil)
StaticPopup1._shown = false
-- the button's own enchant: the question is answered for you
ns.RefreshLevel()
btn._scripts.PreClick(btn)
StaticPopup_Show("REPLACE_ENCHANT")
ok("our enchant: replace is answered yes", REPLACED == 1 and HIDDEN == "REPLACE_ENCHANT")
btn._scripts.PreClick(btn)
StaticPopup_Show("BIND_ENCHANT")
ok("our enchant on an unbound item: bind is answered yes", BOUND == 1)
-- an enchant you cast yourself, not through the button
StaticPopup_Show("REPLACE_ENCHANT")
ok("a hand-cast enchant still asks", REPLACED == 1)
-- a different popup right after a press is never touched
btn._scripts.PreClick(btn)
HIDDEN = nil
StaticPopup_Show("DELETE_ITEM")
ok("any other popup is left alone", HIDDEN == nil and REPLACED == 1)
ns._enchantPressAt = nil
-- turned off: back to the next press answering it
BastionProfessionsDB.autoYes = false
btn._scripts.PreClick(btn)
StaticPopup_Show("REPLACE_ENCHANT")
ok("/mats autoyes off: not answered", REPLACED == 1)
BastionProfessionsDB.autoYes = nil; ns._enchantPressAt = nil
-- rods are crafted in a batch like anything else
SKILL = 2; ns.RefreshLevel()
ok("Runed Copper Rod is a normal craft", macro():find("DoTradeSkill(3,1)", 1, true) ~= nil)
-- the client says Bracers where an older plan says Bracer (or the other way)
RECIPES[4][1] = "Enchant Bracer - Striking"
SKILL = 365; ns.RefreshLevel()
ok("Bracer and Bracers are the same recipe", label():find("Enchant Bracer - Striking", 1, true) ~= nil)

----------------------------------------------------------------------
section("the panel")
----------------------------------------------------------------------
ns.TogglePanel()
local P = _G.BastionProfPanel
ok("the panel opens", P and P:IsShown())
-- bags: 40 Cobalt
BAG = { [0] = {}, {}, {}, {}, {} }
item(0, 1, "Cobalt Bar", 20); item(0, 2, "Cobalt Bar", 20)
ns.SetActiveKey("bs")
SKILL_LINE, SKILL = "Blacksmithing", 352
RECIPES = { { "Cobalt Boots", "optimal", 5 } }
ns.RefreshLevel(); ns.RefreshPanel()
local rows = ns.PanelRows("bs")
local function row(n) for _, r in ipairs(rows) do if r.name == n then return r end end end
local cob, sar = row("Cobalt Bar"), row("Saronite Bar")
ok("Blacksmithing BiS is 400, the route ends at 450", select(1, ns.Goals("bs")) == 400 and select(2, ns.Goals("bs")) == 450)
ok("at 352: Cobalt to 400 is 92, to 450 is 108", cob and cob.needBis == 92 and cob.need == 108 and cob.have == 40)
ok("Saronite is not needed for 400, 87 for 450", sar and sar.needBis == 0 and sar.need == 87)
ok("Engineering has one goal: its route ends at its BiS 405", select(1, ns.Goals("engi")) == nil and select(2, ns.Goals("engi")) == 405)
local pushed
local real = ML.PushNames
ML.PushNames = function(self, label, names) pushed = { label = label, names = names }; return real(self, label, names) end
local function press(text) for _, f in ipairs(FRAMES) do if f._t == text and f._scripts.OnClick then f._scripts.OnClick(f) return true end end end
local function pushedHas(n) for _, x in ipairs(pushed and pushed.names or {}) do if x == n then return true end end end
ok("the BiS push button is labelled for 400", press("Push mats to 400 (BiS)"))
ok("to 400: Cobalt (40 of 92) is pushed",        pushedHas("Cobalt Bar"))
ok("to 400: Saronite (only for 400+) is not",    not pushedHas("Saronite Bar"))
ok("the list is named after its goal",           pushed and pushed.label == "Blacksmithing to 400 (BiS)")
pushed = nil
ok("the 450 push button is there", press("Push mats to 450"))
ok("to 450: Saronite is pushed",                 pushedHas("Saronite Bar"))
ok("nothing from a vendor or made by the route", not pushedHas("Green Dye") and not pushedHas("Heavy Grinding Stone"))
ok("the 450 list is named for 450",             pushed and pushed.label == "Blacksmithing to 450")
ok("and it replaced the 400 one: one list per profession",
   #AUCTIONATOR_SHOPPING_LISTS == 1 and AUCTIONATOR_SHOPPING_LISTS[1].name == "Blacksmithing to 450")
ok("Engineering's one list is its BiS one", ns.ListName("engi", false) == "Engineering to 405 (BiS)")
ok("Jewelcrafting's BiS list", ns.ListName("jc", true) == "Jewelcrafting to 370 (BiS)")
-- crossing 400 says so
CHAT = {}
SKILL = 399; ns.RefreshLevel()
SKILL = 400; ns.RefreshLevel()
local said = false
for _, m in ipairs(CHAT) do if m:find("BiS reached", 1, true) and m:find("Socket Bracer", 1, true) then said = true end end
ok("reaching 400 announces BiS reached", said)
CHAT = {}
SKILL = 401; ns.RefreshLevel()
said = false
for _, m in ipairs(CHAT) do if m:find("BiS reached", 1, true) then said = true end end
ok("and only once", not said)
-- a tab sticks while another window is open
SKILL_LINE = "Blacksmithing"; ns.RefreshLevel()
for _, f in ipairs(FRAMES) do if f._t == "Enchant" and f._scripts.OnClick then f._scripts.OnClick(f) end end
ok("Enchant tab with Blacksmithing open: the panel shows Enchanting", ns.ActiveKey() == "ench")
ok("and the button asks for the Enchanting window", label():find("open Enchanting", 1, true) ~= nil)

print(("\nRESULT: %s (%d checks)"):format(failed and "failures above" or "all assertions passed", checks))
os.exit(failed and 1 or 0)
