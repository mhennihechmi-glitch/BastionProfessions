-- Drives the real addon files against a stubbed 3.3.5a client plus a stubbed
-- Auctionator, so the list that lands in AUCTIONATOR_SHOPPING_LISTS is the
-- one the game would get.
unpack = table.unpack
function wipe(t) for k in pairs(t) do t[k] = nil end return t end

local printed = {}
DEFAULT_CHAT_FRAME = { AddMessage = function(_, m) printed[#printed+1] = tostring(m) end }
SlashCmdList = {}

-- --- stubbed Auctionator ---
Atr_SList = {}; Atr_SList.__index = Atr_SList
function Atr_SortSlists(x, y)
  if x.isRecents then return true end
  if y.isRecents then return false end
  return string.lower(x.name) < string.lower(y.name)
end
AUCTIONATOR_SHOPPING_LISTS = { { name = "Recent Searches", items = { "Saronite Ore" }, isRecents = 1 } }

-- --- stubbed bags ---
local BAGS = {}
BankFrame = { IsShown = function() return false end }
function GetContainerNumSlots(bag) return BAGS[bag] and #BAGS[bag] or 0 end
function GetContainerItemLink(bag, slot)
  local e = BAGS[bag] and BAGS[bag][slot]
  return e and ("|cffffffff|Hitem:1:0:0:0:0:0:0:0:80|h[%s]|h|r"):format(e[1]) or nil
end
function GetContainerItemInfo(bag, slot)
  local e = BAGS[bag] and BAGS[bag][slot]
  if not e then return nil end
  return "tex", e[2], false, 1, false
end

local AD = "../"   -- run from the tests folder, like the other tests
local ns = {}
assert(loadfile(AD .. "Lists.lua"))("BastionProfessions", ns)
local LOGIN
function CreateFrame() return { RegisterEvent = function() end,
  SetScript = function(_, _, fn) LOGIN = fn end } end
-- what an account looks like before the rename reaches it
table.insert(AUCTIONATOR_SHOPPING_LISTS, { name = "Engineering 1-405", items = { "Froststeel Tube", "Fel Iron Bar" } })
assert(loadfile(AD .. "Core.lua"))("BastionProfessions", ns)

local ML = ns.ML
local run = SlashCmdList["BASTIONPROF"]

local failed = false
local function ok(label, cond)
  print((cond and "  PASS  " or "  FAIL  ") .. label); if not cond then failed = true end
end

print("=== login swaps the old 1-405 list for the new 1-450 one ===")
LOGIN()
local function named(n) for _, sl in ipairs(AUCTIONATOR_SHOPPING_LISTS) do if sl.name == n then return sl end end end
ok("the 1-405 list is gone on login",  named("Engineering 1-405") == nil)
ok("the 1-450 list is there",          named("Engineering 1-450") ~= nil)
local hasSaronite, hasTube = false, false
for _, i in ipairs(named("Engineering 1-450").items) do
  if i == "Saronite Bar" then hasSaronite = true end
  if i == "Froststeel Tube" then hasTube = true end
end
ok("it goes to 450: Saronite is on it", hasSaronite)
ok("the old bought Froststeel Tubes are not", not hasTube)
LOGIN()
ok("a second login changes nothing",   #AUCTIONATOR_SHOPPING_LISTS == 2)
-- back to the state the rest of this file starts from
for i = #AUCTIONATOR_SHOPPING_LISTS, 1, -1 do
  if not AUCTIONATOR_SHOPPING_LISTS[i].isRecents then table.remove(AUCTIONATOR_SHOPPING_LISTS, i) end
end
-- Colour codes sit between the number and the name, so strip them before
-- matching or every assertion is really testing the escape sequences.
local function chat()
  return (table.concat(printed, "\n"):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""))
end
local function clearChat() printed = {} end
local function slist(name)
  for _, sl in ipairs(AUCTIONATOR_SHOPPING_LISTS) do
    if sl.name == name then return sl end
  end
end
local LABEL = "Engineering 1-450"

-- how many of each source the data file holds
local nAH, nOther = 0, 0
for _, row in ipairs(ns.lists.engi.items) do
  if row[3] == "ah" then nAH = nAH + 1 else nOther = nOther + 1 end
end

print("=== the source data itself ===")
-- Counted from the list rather than hardcoded. A fixed number here means
-- adding one material turns three assertions red for no reason, and the only
-- thing it was ever checking was that the list had not been emptied.
local N = #ns.lists.engi.items
ok("the list is not empty", N > 20)
local dupe, seen = nil, {}
for _, row in ipairs(ns.lists.engi.items) do
  if seen[row[1]] then dupe = row[1] end
  seen[row[1]] = true
end
ok("no item is listed twice", dupe == nil)
local badQty
for _, row in ipairs(ns.lists.engi.items) do
  if type(row[2]) ~= "number" or row[2] < 1 then badQty = row[1] end
  if row[3] ~= "ah" and row[3] ~= "vendor" and row[3] ~= "craft" then badQty = row[1] end
end
ok("every row has a sane quantity and source", badQty == nil)
print(("    %d to buy at the AH, %d from a vendor or your own forge"):format(nAH, nOther))

print("=== push builds the Auctionator list ===")
clearChat(); run("push")
local sl = slist(LABEL)
ok("the list exists",                 sl ~= nil)
ok("it holds only the AH items",      sl and #sl.items == nAH)
ok("Mithril Bar is on it",           sl and (function() for _,i in ipairs(sl.items) do if i=="Mithril Bar" then return true end end end)())
ok("Weak Flux is not (vendor)",       sl and (function() for _,i in ipairs(sl.items) do if i=="Weak Flux" then return false end end return true end)())
ok("Volatile Blasting Trigger is not (you craft it)",
   sl and (function() for _,i in ipairs(sl.items) do if i=="Volatile Blasting Trigger" then return false end end return true end)())
ok("it says what it left out",        chat():find("Left out", 1, true) ~= nil)

print("=== pushing twice must not double the list ===")
run("push"); run("push")
sl = slist(LABEL)
ok("still exactly one list",          (function() local n=0 for _,s in ipairs(AUCTIONATOR_SHOPPING_LISTS) do if s.name==LABEL then n=n+1 end end return n end)() == 1)
ok("still the same item count",       #sl.items == nAH)

print("=== the Recents list is left alone ===")
ok("Recents survived",                AUCTIONATOR_SHOPPING_LISTS[1].isRecents == 1)
ok("and still sorts first",           AUCTIONATOR_SHOPPING_LISTS[1].name == "Recent Searches")
ok("Recents keeps its own items",     AUCTIONATOR_SHOPPING_LISTS[1].items[1] == "Saronite Ore")

print("=== push all takes everything ===")
run("push all")
sl = slist(LABEL)
ok("every item is on it",             #sl.items == N)
ok("Weak Flux included now",          (function() for _,i in ipairs(sl.items) do if i=="Weak Flux" then return true end end end)())

print("=== need counts what is in your bags ===")
BAGS = {
  [0] = { { "Mithril Bar", 10 }, { "Mithril Bar", 10 } },   -- two stacks, must add up
  [1] = { { "Cobalt Bar", 101 }, { "Copper Bar", 26 } },     -- exactly enough of both
}
clearChat(); run("need")
local c = chat()
ok("partial stacks are summed",       c:find("12 x Mithril Bar", 1, true) ~= nil)
ok("it shows how far along you are",  c:find("have 20 of 32", 1, true) ~= nil)
ok("a finished item drops off",       c:find("Cobalt Bar", 1, true) == nil)
ok("so does the other finished one",  c:find("Copper Bar", 1, true) == nil)
ok("the done count is right",         c:find("2 of " .. N, 1, true) ~= nil)
ok("it warns the bank was not read",  c:find("bags only", 1, true) ~= nil)
ok("vendor items are tagged",         c:find("vendor", 1, true) ~= nil)
ok("crafted items are tagged",        c:find("you craft", 1, true) ~= nil)

print("=== with the bank open it reads the bank too ===")
BankFrame = { IsShown = function() return true end }
BAGS[-1] = { { "Mithril Bar", 60 } }
clearChat(); run("need")
c = chat()
ok("bank stock counts",               c:find("Mithril Bar", 1, true) == nil)
ok("no bags-only warning now",        c:find("bags only", 1, true) == nil)
BankFrame = { IsShown = function() return false end }

print("=== the old 1-405 list is taken out ===")
table.insert(AUCTIONATOR_SHOPPING_LISTS, { name = "Engineering 1-405", items = { "Froststeel Tube", "Fel Iron Bar" } })
run("push")
ok("old list removed",                slist("Engineering 1-405") == nil)
ok("new list still there",            slist(LABEL) ~= nil)
local notube = true
for _, i in ipairs(slist(LABEL).items) do if i == "Froststeel Tube" then notube = false end end
ok("no bought Froststeel Tube on it", notube)

print("=== clear removes it again ===")
run("clear")
ok("the list is gone",                slist(LABEL) == nil)
ok("Recents is still there",          AUCTIONATOR_SHOPPING_LISTS[1].isRecents == 1)

print("=== it survives Auctionator being absent ===")
local keep = AUCTIONATOR_SHOPPING_LISTS
AUCTIONATOR_SHOPPING_LISTS = nil
clearChat()
local safe = pcall(run, "push")
ok("push does not error",             safe)
ok("and says why",                    chat():find("not loaded", 1, true) ~= nil)
AUCTIONATOR_SHOPPING_LISTS = keep

print("=== odd input ===")
clearChat()
ok("a bad list name shows help",      pcall(run, "push nonsense") and chat():find("/mats push", 1, true) ~= nil)
ok("bare /mats does not error",       pcall(run, ""))
ok("/mats help does not error",       pcall(run, "help"))
ok("/mats show does not error",       pcall(run, "show"))

print("\n=== what prints to chat is alphabetical ===")

-- The printed list is read against the auction house search box, not against
-- the levelling order, so it goes A to Z. The order in Lists.lua follows the
-- guide and stays that way.
local function namesFrom(lines)
    local out = {}
    for _, line in ipairs(lines) do
        -- "  |cffffffff20|r x Rough Stone  |cff909090...|r"
        local n = line:match("|r x ([^|]+)")
        if n then out[#out+1] = (n:gsub("%s+$", "")) end
    end
    return out
end

local function sortedAZ(t)
    for i = 2, #t do
        if string.lower(t[i]) < string.lower(t[i-1]) then return false, t[i-1], t[i] end
    end
    return true
end

printed = {}
ML:Show("engi")
local shown = namesFrom(printed)
ok("show printed the whole list", #shown == #ns.lists.engi.items)
local okSort, a, b = sortedAZ(shown)
ok("and in alphabetical order", okSort)
if not okSort then print(("        %s came before %s"):format(a, b)) end
print("        first three: " .. table.concat({shown[1], shown[2], shown[3]}, ", "))

-- Sorting must not reorder the source. Plan.lua and the Auctionator pusher
-- both read ns.lists, and the guide's order matters to them.
local firstInData = ns.lists.engi.items[1][1]
ok("the source list is untouched", firstInData == "Rough Stone")

printed = {}
ML:Need("engi")
local needed = namesFrom(printed)
ok("need printed something", #needed > 0)
local okNeed, c, d = sortedAZ(needed)
ok("and it is alphabetical too", okNeed)
if not okNeed then print(("        %s came before %s"):format(c, d)) end

print(failed and "\nRESULT: failures above" or "\nRESULT: all assertions passed")
