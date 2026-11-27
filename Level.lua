local _, ns = ...

-- /mats level -- the crafting button for a profession levelling route.
--
-- What it does: works out which step of the plan your CURRENT skill number
-- puts you in, finds that recipe in the open tradeskill window, and points a
-- button at it. Craft, skill goes up, and the moment it crosses into the next
-- step the button retargets itself. You never look up what to make next.
--
-- What it cannot do, and why there is no version that can:
--
--   DoTradeSkill is driven from a secure button here, so every craft is one
--   of your clicks. Nothing in this file presses anything. A timer that
--   clicked for you would be the thing Warmane bans for, and it would also
--   have to guess when a craft finished, which it cannot.
--
-- The step is recomputed from live skill after every update rather than by
-- counting presses, so a lucky run of skill-ups moves you on early and a dry
-- one keeps you where you are. The guide's counts are an estimate; your skill
-- number is a fact.

local ML = ns.ML
-- Which profession the button follows. The open tradeskill window decides:
-- open Blacksmithing and it is Blacksmithing. With no window (or one with
-- no route, like Tailoring) it stays on the last one used.
local KEY = "engi"
function ns.ActiveKey() return KEY end
function ns.SetActiveKey(k)
    if k and ns.plan[k] and k ~= KEY then
        KEY = k
        ns.forcedStepReset()
        if BastionProfessionsDB then BastionProfessionsDB.lastKey = k end
    end
end
local function keyForSkill(name)
    if not name then return nil end
    for k, p in pairs(ns.plan) do if p.skill == name then return k end end
end
ns.KeyForSkill = keyForSkill

local function out(msg) DEFAULT_CHAT_FRAME:AddMessage("|cff00b4ffBastion Professions|r " .. tostring(msg)) end

----------------------------------------------------------------------
-- reading the tradeskill window
----------------------------------------------------------------------

function ns.SkillNow(wantName)
    if not GetTradeSkillLine then return nil end
    local name, rank, maxRank = GetTradeSkillLine()
    if not name or name == "UNKNOWN" then return nil end
    if wantName and name ~= wantName then return nil, name end
    return rank, name, maxRank
end

-- The recipe's row in the open window, by name. Searched every time rather
-- than remembered: collapsing a header or typing in the search box renumbers
-- every row, and a remembered index then points at a different recipe.
--
-- Exact name first. Then a forgiving match, because the guide and the client
-- spell some enchants differently: the guide drops "Enchant ", and Northrend
-- bracer enchants are "Bracers" in the client but "Bracer" in older ones.
local function norm(n)
    n = n:lower():gsub("^enchant ", ""):gsub("bracers", "bracer"):gsub("%s+", " ")
    return n
end
function ns.FindRecipe(craftName)
    if not GetNumTradeSkills or not craftName then return nil end
    local total = GetNumTradeSkills() or 0
    for i = 1, total do
        local n, kind = GetTradeSkillInfo(i)
        if n == craftName and kind ~= "header" then return i, kind end
    end
    local want = norm(craftName)
    for i = 1, total do
        local n, kind = GetTradeSkillInfo(i)
        if n and kind ~= "header" and norm(n) == want then return i, kind end
    end
end

-- "Any gem cut from Shadow Crystal": a recipe you know whose ONLY reagent is
-- one of `names`. Prefers one you have mats for, then the colour that gives
-- the most skill (orange over yellow over green), never a grey one.
local RANK = { optimal = 4, medium = 3, easy = 2, trivial = 0 }
function ns.FindAnyWith(names)
    if not GetNumTradeSkills or not GetTradeSkillNumReagents then return nil end
    local want = {}
    for _, n in ipairs(names) do want[n] = true end
    local best, bestScore, bestKind, bestName
    for i = 1, (GetNumTradeSkills() or 0) do
        local n, kind, avail = GetTradeSkillInfo(i)
        if n and kind ~= "header" and (RANK[kind] or 0) > 0
           and GetTradeSkillNumReagents(i) == 1 then
            local rn = GetTradeSkillReagentInfo(i, 1)
            if rn and want[rn] then
                local score = ((avail or 0) > 0 and 100 or 0) + (RANK[kind] or 0)
                if not bestScore or score > bestScore then
                    best, bestScore, bestKind, bestName = i, score, kind, n
                end
            end
        end
    end
    return best, bestKind, bestName
end

-- The tools a recipe needs that you do not have right now: an anvil, a
-- forge, a Blacksmith Hammer, a Jeweler's Kit, the right runed rod. The
-- window's "can make" count does not look at tools, so without this the
-- button would queue a craft the client then refuses.
function ns.MissingTool(index)
    if not GetTradeSkillTools or not index then return nil end
    local t = { GetTradeSkillTools(index) }
    for i = 1, #t, 2 do
        if t[i] and not t[i + 1] then return t[i] end
    end
end

----------------------------------------------------------------------
-- enchant targets
----------------------------------------------------------------------
-- An "Enchant ..." recipe makes nothing: it goes onto an item. The button
-- puts it on one in your BAGS, never on what you are wearing, and only on a
-- grey, white or green item that is not in an equipment set, so a spare set
-- of raid gear in your bags is never touched. Enchanting the same cheap item
-- over and over is how this is levelled; the client asks to replace the old
-- enchant, and the next press answers that.
local SLOT = {
    bracer = { INVTYPE_WRIST = true },
    cloak  = { INVTYPE_CLOAK = true },
    chest  = { INVTYPE_CHEST = true, INVTYPE_ROBE = true },
    boots  = { INVTYPE_FEET = true },
    gloves = { INVTYPE_HAND = true },
    shield = { INVTYPE_SHIELD = true },
}
local SLOT_WORD = { bracer = "a bracer", cloak = "a cloak", chest = "a chest piece",
                    boots = "boots", gloves = "gloves", shield = "a shield" }

-- "bracer" for "Enchant Bracers - Striking", nil for a rod or an oil.
function ns.EnchantSlot(craft)
    local w = craft and craft:match("^Enchant (%a+) %-")
    if not w then return nil end
    w = w:lower():gsub("s$", "")
    if w == "boot" then w = "boots" elseif w == "glove" then w = "gloves" end
    return SLOT[w] and w or nil
end

local function setItems()
    local out = {}
    if not GetNumEquipmentSets or not GetEquipmentSetInfo or not GetEquipmentSetItemIDs then return out end
    for i = 1, (GetNumEquipmentSets() or 0) do
        local name = GetEquipmentSetInfo(i)
        local ids = name and GetEquipmentSetItemIDs(name)
        for _, id in pairs(ids or {}) do if id and id > 0 then out[id] = true end end
    end
    return out
end

-- All items in your bags this enchant could go on, best first.
function ns.EnchantCandidates(slotWord)
    local locs = SLOT[slotWord]
    if not locs then return {} end
    local inSet, picked = setItems(), BastionProfessionsDB and BastionProfessionsDB.enchTarget and BastionProfessionsDB.enchTarget[slotWord]
    local list = {}
    for bag = 0, 4 do
        for slot = 1, (GetContainerNumSlots(bag) or 0) do
            local link = GetContainerItemLink(bag, slot)
            local id = link and tonumber(link:match("item:(%d+)"))
            if id and not inSet[id] then
                local name, _, quality, ilvl, _, _, _, _, equipLoc = GetItemInfo(link)
                if name and locs[equipLoc] and (quality or 9) <= 2 then
                    list[#list + 1] = { bag = bag, slot = slot, link = link, id = id, name = name,
                                        ilvl = ilvl or 0, picked = (picked == id) }
                end
            end
        end
    end
    -- The one you chose first, then the highest item level (Northrend
    -- enchants refuse low-level items), then a stable order.
    table.sort(list, function(a, b)
        if a.picked ~= b.picked then return a.picked end
        if a.ilvl ~= b.ilvl then return a.ilvl > b.ilvl end
        return a.bag * 100 + a.slot < b.bag * 100 + b.slot
    end)
    return list
end

-- Move on to the next candidate, and remember it for this kind of item.
function ns.NextEnchantTarget(slotWord)
    local list = ns.EnchantCandidates(slotWord)
    if #list < 2 then return list[1] end
    BastionProfessionsDB = BastionProfessionsDB or {}
    BastionProfessionsDB.enchTarget = BastionProfessionsDB.enchTarget or {}
    local nextOne = list[2]
    for i, c in ipairs(list) do
        if c.picked then nextOne = list[i % #list + 1] break end
    end
    BastionProfessionsDB.enchTarget[slotWord] = nextOne.id
    ns.RefreshLevel()
    return nextOne
end

-- The client's own "replace the enchant?" or "this will bind it" question
-- after an enchant. The next press of the button is the yes, so it is still
-- one of your clicks; only these two questions are ever answered, never any
-- other popup that happens to be up.
local ENCHANT_ASKS = { REPLACE_ENCHANT = "replace the old enchant", BIND_ENCHANT = "bind the item to you" }
function ns.EnchantQuestion()
    for i = 1, 4 do
        local f = _G["StaticPopup" .. i]
        if f and f:IsShown() and ENCHANT_ASKS[f.which] then return i, ENCHANT_ASKS[f.which] end
    end
end

-- How many you could make right now, which the window already works out for
-- us from the reagents in your bags.
function ns.Makeable(index)
    if not index or not GetTradeSkillNumMade then return 0 end
    local _, _, numAvailable = GetTradeSkillInfo(index)
    return numAvailable or 0
end

----------------------------------------------------------------------
-- the button
----------------------------------------------------------------------

local btn, state

-- Skipping a step by hand.
--
-- The button normally derives everything from your skill number, which is the
-- right default and needs no input. But a step can be unusable for reasons the
-- skill number cannot see: the recipe is a reputation reward you do not have,
-- or the reagents cost more than the next step's, or you simply want past it.
--
-- So this holds an absolute step index to use INSTEAD of the one your skill
-- implies, and only ever a LATER one. It is not a saved setting: it clears
-- itself the moment your skill catches up, so a skip is a nudge rather than a
-- mode you can forget you are in and then wonder why the button is wrong.
local forcedStep = nil
function ns.forcedStepReset() forcedStep = nil end

local function effectiveStep(key, skill)
    local step, i, n = ns.StepFor(key, skill)
    if not step then return nil, i, n, false end

    if forcedStep then
        -- Caught up: the skip has served its purpose and stops applying.
        if forcedStep <= i then
            forcedStep = nil
        elseif forcedStep > n then
            forcedStep = nil
        else
            return ns.plan[key].steps[forcedStep], forcedStep, n, true
        end
    end
    return step, i, n, false
end

local function describe()
    if not state or not state.step then return "" end
    local s = state.step
    return ("%s  %d/%d"):format(s.craft, state.skill or 0, s.to)
end

-- Everything the panel shows comes from here, so the button and the panel
-- can never disagree about what is next.
ns.levelState = nil
local listeners = {}
function ns.OnLevelRefresh(fn) listeners[#listeners + 1] = fn end

local function setMacro(text)
    if not btn then return end
    if InCombatLockdown and InCombatLockdown() then return end
    btn:SetAttribute("macrotext", text)
end

local function refresh()
    -- The open window picks the profession.
    local openName = GetTradeSkillLine and GetTradeSkillLine()
    if openName ~= ns._lastOpen then
        ns._lastOpen = openName
        local k = keyForSkill(openName)
        if k then ns.SetActiveKey(k) end
    end

    local plan = ns.plan[KEY]
    local skill, lineName, maxRank = ns.SkillNow(plan.skill)
    if not skill then
        btn.label:SetText(lineName and ("open " .. plan.skill) or ("open " .. plan.skill))
        setMacro("")
        state = { key = KEY, closed = true }
        return
    end

    -- An enchant just asked "replace?" or "bind?": the next press says yes.
    local pop, what = ns.EnchantQuestion()
    if pop then
        setMacro(("/click StaticPopup%dButton1"):format(pop))
        btn.label:SetText("|cffffd070press again: " .. what .. "|r")
        state = { key = KEY, skill = skill, asking = what }
        return
    end

    local step, i, n, skipped = effectiveStep(KEY, skill)
    if not step then
        btn.label:SetText(("%s done: %d"):format(plan.skill, skill))
        setMacro("")
        state = { key = KEY, skill = skill, done = true }
        return
    end

    -- At the cap of your rank nothing gains skill until you train. Without
    -- this the button keeps queueing crafts that give nothing.
    if maxRank and plan.train and plan.train[maxRank] and skill >= maxRank and not skipped then
        btn.label:SetText("|cffff8040train: " .. plan.train[maxRank] .. "|r")
        setMacro("")
        state = { key = KEY, step = step, i = i, n = n, skill = skill, train = plan.train[maxRank] }
        return
    end

    -- Something the step needs in your bags first (casings, triggers).
    local target, prepping, have = step, false, 0
    if step.prep and GetItemCount then
        have = GetItemCount(step.prep.craft) or 0
        if have < step.prep.need then target, prepping = step.prep, true end
    end

    local index, kind, shownName
    if target.anyWith then
        index, kind, shownName = ns.FindAnyWith(target.anyWith)
    else
        index, kind = ns.FindRecipe(target.craft)
        -- a step that another recipe does just as well (Green Smoke Flare
        -- for White): use that one if it is the one you know
        if not index and target.orCraft then
            for _, c in ipairs(target.orCraft) do
                index, kind = ns.FindRecipe(c)
                if index then break end
            end
        end
        -- the client's own spelling, which is what you see in the window
        shownName = (index and GetTradeSkillInfo(index)) or target.craft
    end

    -- Icy Prism and other cooldown crafts: use the step's alternative while
    -- it is cooling down, if you have the mats for that.
    local cooldown
    if index and GetTradeSkillCooldown then
        local cd = GetTradeSkillCooldown(index)
        if cd and cd > 0 then
            cooldown = cd
            if step.alt then
                local ai, ak, an = ns.FindAnyWith(step.alt.anyWith)
                if ai and ns.Makeable(ai) > 0 then index, kind, shownName, cooldown = ai, ak, an, nil end
            end
        end
    end

    state = { key = KEY, step = step, i = i, n = n, skill = skill, index = index, skipped = skipped,
              prepping = prepping, shown = shownName, kind = kind }

    if not index then
        -- Known-missing is a real state, not an error: White Smoke Flare is a
        -- vendor schematic and you will hit this step without it.
        local what = target.anyWith and ("a recipe using " .. table.concat(target.anyWith, " or "))
            or (target.orCraft and (target.craft .. " or " .. table.concat(target.orCraft, " or ")))
            or target.craft
        btn.label:SetText("|cffff8080need: " .. what .. "|r")
        setMacro("")
        state.missingRecipe = what
        -- said once per step, not on every bag update
        if step.note and not prepping and ns._noted ~= step then
            ns._noted = step
            out(step.craft .. " -- " .. step.note)
        end
        return
    end

    if cooldown then
        local h = math.floor(cooldown / 3600)
        local m = math.floor((cooldown % 3600) / 60)
        btn.label:SetText(("|cffffd070%s ready in %dh %02dm|r"):format(shownName, h, m))
        setMacro("")
        state.cooldown = cooldown
        return
    end

    local tool = ns.MissingTool(index)
    if tool then
        btn.label:SetText("|cffff8080needs: " .. tool .. "|r")
        setMacro("")
        state.tool = tool
        return
    end

    local canMake = ns.Makeable(index)
    if canMake < 1 then
        btn.label:SetText("|cffffd070no mats: " .. shownName .. "|r")
        setMacro("")
        state.noMats = true
        return
    end

    -- Enchants: one per press, onto an item in your bags.
    local slotWord = ns.EnchantSlot(shownName)
    if slotWord then
        local c = ns.EnchantCandidates(slotWord)[1]
        state.enchantSlot = slotWord
        if not c then
            btn.label:SetText("|cffff8080put " .. SLOT_WORD[slotWord] .. " in your bags|r")
            setMacro("")
            state.noTarget = true
            return
        end
        state.target = c
        setMacro(("/run DoTradeSkill(%d)\n/use %d %d"):format(index, c.bag, c.slot))
        btn.label:SetText(("%s |cff808080on %s  %d/%d  step %d/%d%s|r")
            :format(shownName, c.name, skill, step.to, i, n,
                    skipped and " |cffff8040skipped|r" or ""))
        return
    end

    if prepping then
        local makes = step.prep.makes or 1
        local batch = math.ceil((step.prep.need - have) / makes)
        if canMake < batch then batch = canMake end
        if batch < 1 then batch = 1 end
        setMacro(("/run DoTradeSkill(%d,%d)"):format(index, batch))
        btn.label:SetText(("first: %s |cffffd070x%d|r  |cff808080for %s, %d/%d|r")
            :format(target.craft, batch, step.craft, have, step.prep.need))
        state.batch = batch
        return
    end

    -- Queue the fewest crafts that could finish the step.
    --
    -- On Warmane every skill-up is +3 (plan.gain), so (step.to - skill) / 3
    -- crafts, rounded up, is the most that can still be useful: if every one
    -- of them skills up, the step is done. Queueing step.to - skill, as the
    -- first version did, kept crafting for two thirds of the queue after the
    -- step had finished, burning mats on something that no longer gives skill.
    -- When yellow and green crafts miss, the button simply offers the rest on
    -- the next click.
    --
    -- Then capped again by what your reagents actually allow, which the
    -- tradeskill window has already worked out, so a short queue stops rather
    -- than erroring on the craft that runs out.
    -- Measured from where the step BEGINS, not from your skill. On a skipped
    -- step your skill is still below step.from, and using it would queue the
    -- whole gap you jumped over.
    local base = skill
    if base < step.from then base = step.from end
    local batch = math.ceil((step.to - base) / (plan.gain or 1))
    if canMake < batch then batch = canMake end
    if batch < 1 then batch = 1 end
    state.batch = batch

    setMacro(("/run DoTradeSkill(%d,%d)"):format(index, batch))
    local grey = (kind == "trivial") and "|cff909090" or ""
    btn.label:SetText(("%s%s|r |cffffd070x%d|r  |cff808080%d/%d  step %d/%d%s|r")
        :format(grey, shownName, batch, skill, step.to, i, n,
                skipped and " |cffff8040skipped|r" or ""))
end

function ns.RefreshLevel()
    if not btn then return end
    refresh()
    ns.levelState = state
    for _, fn in ipairs(listeners) do pcall(fn, state) end
end

local function build()
    if btn then return end
    btn = CreateFrame("Button", "BastionProfLevelButton", UIParent,
                      "SecureActionButtonTemplate,UIPanelButtonTemplate")
    btn:SetWidth(280); btn:SetHeight(26)
    btn:SetPoint("CENTER", UIParent, "CENTER", 0, -180)
    btn:SetMovable(true)
    btn:RegisterForDrag("RightButton")
    btn:SetScript("OnDragStart", function(s) s:StartMoving() end)
    btn:SetScript("OnDragStop", function(s) s:StopMovingOrSizing() end)
    btn:SetAttribute("type", "macro")
    -- Shift and ctrl do no secure action at all, so the handler below is free
    -- to mean something else with them. Without this, a shift-click would
    -- craft AND skip, which is the one combination nobody wants.
    btn:SetAttribute("shift-type", "none")
    btn:SetAttribute("ctrl-type", "none")
    btn:RegisterForClicks("AnyUp")
    -- Remember when this button cast an enchant onto its own cheap target,
    -- so the "replace?" / "bind?" question that follows can be answered for
    -- you. Only then: an enchant you cast by hand still asks.
    btn:SetScript("PreClick", function()
        local st = ns.levelState
        if st and st.target and not st.asking and not IsShiftKeyDown() and not IsControlKeyDown() then
            ns._enchantPressAt = GetTime()
        end
    end)
    btn:SetScript("PostClick", function()
        if IsShiftKeyDown() then
            ML:Level("next")
        elseif IsControlKeyDown() then
            ML:Level("auto")
        end
    end)
    btn.label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    btn.label:SetPoint("CENTER")
    btn:SetScript("OnEnter", function(s) ns.LevelTooltip(s, "ANCHOR_TOP") end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    ns._hookLevelEvents()
end

-- One tooltip for the floating button and the panel's button.
function ns.LevelTooltip(s, anchor)
        GameTooltip:SetOwner(s, anchor or "ANCHOR_TOP")
        GameTooltip:SetText(ns.plan[KEY].label)
        if state and state.train then
            GameTooltip:AddLine("Skill cap reached. Train " .. state.train .. ".", 1, 0.5, 0.25, true)
        elseif state and state.asking then
            GameTooltip:AddLine("The game asks to " .. state.asking .. ". Press again for yes.", 1, 0.82, 0.2, true)
        elseif state and state.step then
            if state.target then
                GameTooltip:AddLine(("Each press: %s onto %s in your bags."):format(state.shown, state.target.name), 1, 1, 1, true)
            end
            if state.prepping then
                GameTooltip:AddLine(("First %d %s for %s."):format(state.step.prep.need,
                    state.step.prep.craft, state.step.craft), 1, 1, 1)
            end
            GameTooltip:AddLine(("Making %s until %d."):format(state.shown or state.step.craft, state.step.to), 1, 1, 1)
            if state.step.note then GameTooltip:AddLine(state.step.note, 1, 0.8, 0.4, true) end
        end
        GameTooltip:AddLine("Click to queue as many as can still gain skill.", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("It retargets itself as your skill rises.", 0.8, 0.8, 0.8)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Shift-click: skip to the next step", 1, 0.82, 0.2)
        GameTooltip:AddLine("Ctrl-click: back to following your skill", 1, 0.82, 0.2)
        if state and state.skipped then
            GameTooltip:AddLine("Skipped ahead. Clears itself when your skill", 1, 0.5, 0.25)
            GameTooltip:AddLine("catches up.", 1, 0.5, 0.25)
        end
        GameTooltip:AddLine("Right-drag to move. /mats level off to hide.", 0.8, 0.8, 0.8)
        GameTooltip:Show()
end

function ns._hookLevelEvents()

    -- Skill changes, bag changes and the window reopening all move the
    -- answer, and all three are cheap to react to.
    local ev = CreateFrame("Frame")
    ev:RegisterEvent("TRADE_SKILL_UPDATE")
    ev:RegisterEvent("TRADE_SKILL_SHOW")
    ev:RegisterEvent("TRADE_SKILL_CLOSE")
    ev:RegisterEvent("SKILL_LINES_CHANGED")
    ev:RegisterEvent("BAG_UPDATE")
    ev:RegisterEvent("REPLACE_ENCHANT")
    ev:SetScript("OnEvent", function() ns.RefreshLevel() end)
    -- The enchant questions are popups; refresh when one opens or closes so
    -- the button flips to "press again" and back.
    if hooksecurefunc then
        if StaticPopup_Show then
            hooksecurefunc("StaticPopup_Show", function(which)
                if which ~= "REPLACE_ENCHANT" and which ~= "BIND_ENCHANT" then return end
                -- Our own enchant, cast by your press a moment ago, onto the
                -- cheap item the button picked: say yes. Anything else (an
                -- enchant you cast yourself, on any item) keeps the question.
                -- /mats autoyes off turns this off; the next press then
                -- answers it, as before.
                local recent = ns._enchantPressAt and GetTime() - ns._enchantPressAt < 3
                if recent and (not BastionProfessionsDB or BastionProfessionsDB.autoYes ~= false) then
                    ns._enchantPressAt = nil
                    if which == "REPLACE_ENCHANT" and ReplaceEnchant then ReplaceEnchant()
                    elseif which == "BIND_ENCHANT" and BindEnchant then BindEnchant() end
                    if StaticPopup_Hide then StaticPopup_Hide(which) end
                end
                ns.RefreshLevel()
            end)
        end
        if StaticPopup_OnHide then
            hooksecurefunc("StaticPopup_OnHide", function() ns.RefreshLevel() end)
        end
    end
end
ns.BuildLevelButton = function() build(); return btn end

-- Bound only while the button is on screen, and as an OVERRIDE rather than a
-- real binding, so your own Shift-W comes straight back the moment the button
-- is hidden and nothing is written to your keybind file.
local function bindKey(target)
    if not btn or InCombatLockdown() then return end
    local key = (BastionProfessionsDB and BastionProfessionsDB.levelKey) or "SHIFT-W"
    ClearOverrideBindings(btn)
    SetOverrideBindingClick(btn, true, key, target or "BastionProfLevelButton")
    return key
end

ns.BindKey = function(target) return bindKey(target) end
local function unbindKey()
    -- Changing a binding in combat is blocked, so the clear waits. The button
    -- is hidden either way; the key just keeps working until you drop combat.
    if btn and not InCombatLockdown() then ClearOverrideBindings(btn) end
end
ns.UnbindKey = function() unbindKey() end
ns.FloatingShown = function() return btn and btn._floating end

function ML:Level(arg, rest)
    arg = (arg or ""):lower()
    if arg == "off" or arg == "hide" then
        if btn then btn:Hide(); btn._floating = false end
        -- the panel holds the key while it is open
        if not (ns.PanelShown and ns.PanelShown()) then unbindKey() end
        out("levelling button hidden, " .. (((BastionProfessionsDB and BastionProfessionsDB.levelKey) or "SHIFT-W")) .. " released.")
        return
    end
    if arg == "next" or arg == "skip" then
        local plan = ns.plan[KEY]
        local skill = ns.SkillNow(plan.skill)
        if not skill then out("open your " .. plan.skill .. " window first.") return end
        local _, i, n = effectiveStep(KEY, skill)
        if not i or i >= n then out("already on the last step.") return end
        forcedStep = i + 1
        ns.RefreshLevel()
        out(("skipped to step %d: |cffffffff%s|r  |cff909090(clears itself when your skill reaches %d)|r")
            :format(forcedStep, plan.steps[forcedStep].craft, plan.steps[forcedStep].from))
        return
    end
    if arg == "auto" or arg == "back" or arg == "reset" then
        if not forcedStep then out("already following your skill.") return end
        forcedStep = nil
        ns.RefreshLevel()
        out("back to following your skill.")
        return
    end
    if arg == "key" then
        if not rest or rest == "" then
            out("current key: " .. ((BastionProfessionsDB and BastionProfessionsDB.levelKey) or "SHIFT-W"))
            out("  |cff909090/mats level key ALT-E|r  to change it")
            return
        end
        BastionProfessionsDB = BastionProfessionsDB or {}
        BastionProfessionsDB.levelKey = rest:upper()
        if btn and btn:IsShown() then bindKey() end
        out("key set to " .. BastionProfessionsDB.levelKey .. ".")
        return
    end
    if arg == "plan" then
        local plan = ns.plan[KEY]
        local skill = ns.SkillNow(plan.skill) or 0
        local trained = {}
        for i, s in ipairs(plan.steps) do
            for cap, what in pairs(plan.train or {}) do
                if s.to > cap and not trained[cap] then
                    trained[cap] = true
                    out(("|cffff8040   train %s|r"):format(what))
                end
            end
            local mark = (skill < s.to and skill >= s.from) and "|cff00ff00>|r"
                      or (skill >= s.to and "|cff606060x|r" or " ")
            if s.prep then
                out(("%s          first %d %s"):format(mark, s.prep.need, s.prep.craft))
            end
            out(("%s %3d-%3d  %2dx %s"):format(mark, s.from, s.to, s.count, s.craft))
        end
        return
    end
    build()
    btn:Show()
    btn._floating = true
    ns.RefreshLevel()
    local key = bindKey()
    out(("levelling button up%s. It queues as many as can still gain skill, and")
        :format(key and (", bound to |cffffd070" .. key .. "|r") or ""))
    out("retargets itself as your skill rises.")
    if not ns.SkillNow(ns.plan[KEY].skill) then
        out("open your " .. ns.plan[KEY].skill .. " window and it will pick up from there.")
    end
end
