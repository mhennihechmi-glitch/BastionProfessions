local _, ns = ...

local ML = {}
ns.ML = ML

local function out(msg) DEFAULT_CHAT_FRAME:AddMessage("|cff00b4ffBastion Professions|r " .. tostring(msg)) end

local SOURCE_NOTE = {
    vendor = "|cff909090vendor|r",
    craft  = "|cffe0a030you craft|r",
}

-- ---------- list lookup ----------

function ML:List(key)
    key = string.lower(key or "")
    -- An empty key must not match: find("", 1, true) succeeds against every
    -- label, so a blank would silently pick whichever list came first.
    if key == "" then return nil end
    local l = ns.lists[key]
    if l then return l, key end
    -- a bare name is fine too, so "/mats engineering" finds the engi list
    for k, v in pairs(ns.lists) do
        if string.lower(v.label):find(key, 1, true) then return v, k end
    end
end

-- ---------- what you already hold ----------

-- Bags always; the bank only while its frame is open, because the client
-- gives us nothing for bank slots otherwise. Saying "you still need 117
-- Saronite" when 117 are sitting in the bank would be worse than useless,
-- so the count says where it looked.
local function ownedCounts()
    local have, sawBank = {}, false
    local bags = { 0, 1, 2, 3, 4 }
    if BankFrame and BankFrame:IsShown() then
        sawBank = true
        bags[#bags+1] = -1
        for b = 5, 11 do bags[#bags+1] = b end
    end
    for _, bag in ipairs(bags) do
        local slots = GetContainerNumSlots(bag) or 0
        for slot = 1, slots do
            local link = GetContainerItemLink(bag, slot)
            if link then
                local name = link:match("%[(.-)%]")
                local _, count = GetContainerItemInfo(bag, slot)
                if name then
                    have[string.lower(name)] = (have[string.lower(name)] or 0) + (count or 1)
                end
            end
        end
    end
    return have, sawBank
end

ns.OwnedCounts = ownedCounts

-- ---------- Auctionator ----------

local function auctionatorReady()
    return AUCTIONATOR_SHOPPING_LISTS ~= nil and Atr_SList ~= nil
end

local function findSList(name)
    for _, sl in ipairs(AUCTIONATOR_SHOPPING_LISTS) do
        if not sl.isRecents and sl.name == name then return sl end
    end
end

-- Deliberately NOT Atr_SList.create(). That helper ends by refreshing the
-- shopping list dropdown, which reads the global `this` and is only set while
-- a frame event is running. Called from a slash command it throws, and the
-- list is already half created by then. Building the table directly skips it;
-- the dropdown rebuilds itself the next time it is opened anyway.
local function getOrMakeSList(name)
    local sl = findSList(name)
    if sl then return sl, false end
    sl = setmetatable({ name = name, items = {} }, Atr_SList)
    table.insert(AUCTIONATOR_SHOPPING_LISTS, sl)
    table.sort(AUCTIONATOR_SHOPPING_LISTS, Atr_SortSlists)
    return sl, true
end

-- ---------- commands ----------

function ML:Push(key, includeAll)
    if not auctionatorReady() then
        out("|cffff5050Auctionator is not loaded.|r Type |cffffffff/mats|r for the list and buy it by hand.")
        return
    end
    local list, k = self:List(key)
    if not list then self:Help() return end

    -- A renamed list would otherwise leave its old copy in the dropdown,
    -- still asking for everything the old route needed.
    for _, old in ipairs(list.oldLabels or {}) do
        for i = #AUCTIONATOR_SHOPPING_LISTS, 1, -1 do
            local o = AUCTIONATOR_SHOPPING_LISTS[i]
            if not o.isRecents and o.name == old then
                table.remove(AUCTIONATOR_SHOPPING_LISTS, i)
                out(("Removed the old list \"|cffffffff%s|r\"."):format(old))
            end
        end
    end

    local sl, created = getOrMakeSList(list.label)

    -- Rebuilt from scratch rather than appended. Auctionator's AddItem does
    -- not check for duplicates, so pushing twice would otherwise leave you
    -- searching for Saronite Bar five times over.
    local hadItems = #sl.items
    wipe(sl.items)
    sl.isSorted = false

    local added, skipped = 0, 0
    for _, row in ipairs(list.items) do
        local name, _, source = row[1], row[2], row[3]
        if includeAll or source == "ah" then
            table.insert(sl.items, name)
            added = added + 1
        else
            skipped = skipped + 1
        end
    end

    out(("%s list \"|cffffffff%s|r\" with |cffffffff%d|r item%s.")
        :format(created and "Created" or (hadItems > 0 and "Replaced" or "Filled"),
                list.label, added, added == 1 and "" or "s"))
    if skipped > 0 and not includeAll then
        out(("Left out |cffffffff%d|r you should not buy at the auction house. |cff909090/mats %s all|r adds them anyway.")
            :format(skipped, k))
    end
    out("Open the auction house, Shopping tab, and pick it from the dropdown.")
end

-- The panel's push: exactly the names given, into the profession's list.
-- Same rebuild-not-append rule as Push, so pressing it twice is harmless.
function ML:PushNames(label, names, what)
    if not auctionatorReady() then
        out("|cffff5050Auctionator is not loaded.|r Buy from the list in the panel by hand.")
        return false
    end
    local sl, created = getOrMakeSList(label)
    wipe(sl.items)
    sl.isSorted = false
    for _, n in ipairs(names) do table.insert(sl.items, n) end
    out(("%s list \"|cffffffff%s|r\" with |cffffffff%d|r item%s%s.")
        :format(created and "Created" or "Replaced", label, #names, #names == 1 and "" or "s",
                what and (" (" .. what .. ")") or ""))
    out("Open the auction house, Shopping tab, and pick it from the dropdown.")
    return true
end
ML.AuctionatorReady = auctionatorReady

-- Takes a list out of Auctionator's dropdown. True if there was one.
function ML:RemoveSList(name)
    if not auctionatorReady() then return false end
    for i = #AUCTIONATOR_SHOPPING_LISTS, 1, -1 do
        local sl = AUCTIONATOR_SHOPPING_LISTS[i]
        if not sl.isRecents and sl.name == name then
            table.remove(AUCTIONATOR_SHOPPING_LISTS, i)
            return true
        end
    end
    return false
end

function ML:Need(key)
    local list = self:List(key)
    if not list then self:Help() return end

    local have, sawBank = ownedCounts()
    local missing, done = {}, 0
    for _, row in ipairs(list.items) do
        local name, want, source = row[1], row[2], row[3]
        local got = have[string.lower(name)] or 0
        if got >= want then
            done = done + 1
        else
            missing[#missing+1] = { name = name, need = want - got, got = got,
                                    want = want, source = source }
        end
    end

    out(("|cffffffff%s|r: %d of %d done%s")
        :format(list.label, done, #list.items,
                sawBank and "" or " |cff909090(bags only, open your bank to count it)|r"))
    if #missing == 0 then
        out("|cff60ff60Everything on the list is in your bags.|r")
        return
    end
    -- Alphabetical, because the printed list is read against the auction
    -- house search box, not against the levelling order. Case-insensitive so
    -- "Star Ruby" and "star ruby" cannot land apart.
    table.sort(missing, function(a, b)
        return string.lower(a.name) < string.lower(b.name)
    end)

    for _, m in ipairs(missing) do
        local note = SOURCE_NOTE[m.source]
        out(("  |cffffffff%d|r x %s%s%s"):format(
            m.need, m.name,
            m.got > 0 and ("  |cff909090(have %d of %d)|r"):format(m.got, m.want) or "",
            note and ("  " .. note) or ""))
    end
end

function ML:Show(key)
    local list = self:List(key)
    if not list then self:Help() return end
    out("|cffffffff" .. list.label .. "|r")

    -- Sorted on a copy. ns.lists is the source of truth for Plan.lua and for
    -- the pusher, and reordering it in place to make one printout nicer would
    -- quietly reorder those too.
    local rows = {}
    for i, row in ipairs(list.items) do rows[i] = row end
    table.sort(rows, function(a, b) return string.lower(a[1]) < string.lower(b[1]) end)

    for _, row in ipairs(rows) do
        local note = SOURCE_NOTE[row[3]]
        out(("  |cffffffff%d|r x %s%s"):format(row[2], row[1], note and ("  " .. note) or ""))
    end
end

function ML:Clear(key)
    if not auctionatorReady() then out("Auctionator is not loaded.") return end
    local list = self:List(key)
    if not list then self:Help() return end
    for i = #AUCTIONATOR_SHOPPING_LISTS, 1, -1 do
        local sl = AUCTIONATOR_SHOPPING_LISTS[i]
        if not sl.isRecents and sl.name == list.label then
            table.remove(AUCTIONATOR_SHOPPING_LISTS, i)
            out(("Removed the Auctionator list \"|cffffffff%s|r\"."):format(list.label))
            return
        end
    end
    out(("No Auctionator list called \"%s\" to remove."):format(list.label))
end

function ML:Help()
    out("|cffffffffBastion Professions|r")
    out("  |cffffffff/mats|r            open the panel (opens by itself with a profession window)")
    out("  |cffffffff/mats need|r       what you still need, counting your bags")
    out("  |cffffffff/mats push|r       build the Auctionator shopping list")
    out("  |cffffffff/mats push all|r   include the vendor and self-crafted items too")
    out("  |cffffffff/mats show|r       print the full list with quantities")
    out("  |cffffffff/mats clear|r      delete the Auctionator list again")
    out("  |cffffffff/mats level|r      crafting button that follows your skill")
    out("  |cffffffff/mats level plan|r print the whole route, marking where you are")
    out("  |cffffffff/mats level key|r  change the key, default SHIFT-W")
    out("  |cffffffff/mats level next|r skip a step  |cff909090(or shift-click the button)|r")
    out("  |cffffffff/mats level auto|r back to following your skill  |cff909090(ctrl-click)|r")
    out("  |cffffffff/mats autoyes off|r enchanting: let the next press answer \"replace?\" instead")
    local names = {}
    for k, v in pairs(ns.lists) do names[#names+1] = ("%s |cff909090(%s)|r"):format(k, v.label) end
    table.sort(names)
    out("  lists: " .. table.concat(names, ", "))
    out("  |cff909090Add a list name to any command, e.g. /mats push engi|r")
end

-- ---------- slash ----------

local function onlyList()
    -- With several professions, the one the button is following.
    if ns.ActiveKey and ns.lists[ns.ActiveKey()] then return ns.ActiveKey() end
    local k = next(ns.lists)
    return (next(ns.lists, k) == nil) and k or nil   -- nil once there are two
end

SlashCmdList["BASTIONPROF"] = function(msg)
    local args = {}
    for w in string.gmatch(msg or "", "%S+") do args[#args+1] = string.lower(w) end

    -- A bare /mats opens the panel; /mats need still prints to chat.
    if not args[1] and ns.TogglePanel then ns.TogglePanel() return end
    local cmd = args[1] or "need"
    -- With a single list defined the name is noise, so it may be left off.
    local key = args[2] or onlyList()

    if cmd == "push" or cmd == "ah" or cmd == "import" then
        -- "/mats push all" and "/mats push engi all" both mean everything
        local all = (args[2] == "all") or (args[3] == "all")
        if args[2] == "all" then key = onlyList() end
        ML:Push(key, all)
    elseif cmd == "need" or cmd == "missing" then
        ML:Need(key)
    elseif cmd == "show" or cmd == "list" then
        ML:Show(key)
    elseif cmd == "clear" or cmd == "delete" then
        ML:Clear(key)
    elseif cmd == "level" or cmd == "craft" then
        -- "key" takes a value that must keep its case and dashes, so it is
        -- pulled from the raw message rather than the lowercased word list.
        ML:Level(args[2], (msg or ""):match("^%s*%S+%s+%S+%s+(%S+)"))
    elseif cmd == "autoyes" then
        BastionProfessionsDB = BastionProfessionsDB or {}
        if args[2] == "off" then BastionProfessionsDB.autoYes = false
        elseif args[2] == "on" then BastionProfessionsDB.autoYes = nil end
        out(("Enchanting: the replace/bind question after the button's own enchant is %s.")
            :format(BastionProfessionsDB.autoYes == false and "|cffffd070left for your next press|r" or "|cff60ff60answered yes for you|r"))
    elseif cmd == "help" or cmd == "?" then
        ML:Help()
    else
        -- a bare "/mats engi" is a need check for that list
        if ML:List(cmd) then ML:Need(cmd) else ML:Need(onlyList()) end
    end
end
SLASH_BASTIONPROF1 = "/mats"
SLASH_BASTIONPROF2 = "/shoplist"

-- A list whose label changed is replaced on login, so the auction house never
-- keeps offering the old route's mats just because nobody typed /mats push.
-- Only fires while an old-label list is still there, so a list you cleared on
-- purpose is not brought back.
local login = CreateFrame("Frame")
login:RegisterEvent("PLAYER_LOGIN")
login:SetScript("OnEvent", function()
    if not auctionatorReady() then return end
    for key, list in pairs(ns.lists) do
        for _, old in ipairs(list.oldLabels or {}) do
            if findSList(old) then ML:Push(key) break end
        end
    end
end)
