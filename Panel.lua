local _, ns = ...

-- The panel: everything in one place, stuck to the side of the profession
-- window.
--
--   * Open Blacksmithing and it shows Blacksmithing. Nothing to pick.
--   * The big button is the same crafting button as /mats level (it clicks
--     it), so it follows your live skill and every craft is your own click.
--     Shift-W does the same while the panel is open.
--   * Below it, every mat the rest of the route takes, as have / need,
--     counting your bags (and your bank while it is open).
--   * Push missing: only what you still lack goes into the Auctionator
--     shopping list. Push all: the whole route.
--
-- Also opens with /mats, and from a small "Professions" button on the auction house.

local ML = ns.ML
local ROWS, ROWH = 12, 16
local ORDER = { "engi", "bs", "jc", "ench" }
local SHORT = { engi = "Engi", bs = "Blacksmith", jc = "Jewelcraft", ench = "Enchant" }
local SOURCE = {
    ah     = "|cff8fd0ffAH|r",
    vendor = "|cff909090vendor|r",
    craft  = "|cffe0a030craft|r",
}

local function out(msg) DEFAULT_CHAT_FRAME:AddMessage("|cff00b4ffBastion Professions|r " .. tostring(msg)) end
local function me() return UnitName and UnitName("player") or "?" end

local panel, scroll, rowsUI, craftBtn, tabs = nil, nil, {}, nil, {}
local data = {}              -- the rows on screen
local docked = nil           -- the frame the panel is stuck to, if any
local pendingShow            -- asked to open in combat; opens when it ends

----------------------------------------------------------------------
-- what the panel shows
----------------------------------------------------------------------

-- Your skill for a profession: the open window, else the character's skill
-- list, else the last number seen on this character.
local function skillFor(key)
    local plan = ns.plan[key]
    local live, _, maxRank = ns.SkillNow(plan.skill)
    local rank = live
    if not rank then rank, maxRank = ns.SkillOf(plan.skill) end
    BastionProfessionsDB = BastionProfessionsDB or {}
    BastionProfessionsDB.skill = BastionProfessionsDB.skill or {}
    BastionProfessionsDB.skill[me()] = BastionProfessionsDB.skill[me()] or {}
    if rank then
        BastionProfessionsDB.skill[me()][key] = rank
        return rank, maxRank, true
    end
    return BastionProfessionsDB.skill[me()][key], nil, false
end

-- Recipe names in the open window, kept per character so a formula on the
-- list ticks off once learned, even with the window closed.
local function rememberKnown()
    local key = ns.KeyForSkill(GetTradeSkillLine and GetTradeSkillLine())
    if not key or not GetNumTradeSkills then return end
    BastionProfessionsDB = BastionProfessionsDB or {}
    BastionProfessionsDB.known = BastionProfessionsDB.known or {}
    BastionProfessionsDB.known[me()] = BastionProfessionsDB.known[me()] or {}
    local k = BastionProfessionsDB.known[me()][key] or {}
    BastionProfessionsDB.known[me()][key] = k
    for i = 1, (GetNumTradeSkills() or 0) do
        local n, kind = GetTradeSkillInfo(i)
        if n and kind ~= "header" then k[n] = true end
    end
end

-- The two levels the panel works to: the profession's BiS level (where its
-- own perk unlocks) and the end of the route. Engineering's route already
-- ends at its BiS level, so it has just the one.
function ns.Goals(key)
    local plan = ns.plan[key]
    local last = plan.steps[#plan.steps].to
    local bis = plan.bis and plan.bis.level
    if not bis or bis >= last then return nil, last end
    return bis, last
end

-- One row per mat: have, still needed to the BiS level, still needed to
-- the end. Alphabetical (user's call, 26 Nov), so a mat is easy to find.
function ns.PanelRows(key)
    local plan = ns.plan[key]
    local skill = skillFor(key) or 0
    local have, sawBank = ns.OwnedCounts()
    local bis, last = ns.Goals(key)
    local toBis = {}
    if bis then
        for _, r in ipairs(ns.Needs(key, skill, bis)) do toBis[r[1]] = r[2] end
    end
    local rows = {}
    local short = { bis = 0, bisAH = 0, last = 0, lastAH = 0 }
    for _, r in ipairs(ns.Needs(key, skill, last)) do
        local name, need, source = r[1], r[2], r[3]
        local got = have[name:lower()] or 0
        local learned = r.learns and ns.Known(key, r.learns)
        if learned then got = need end
        local row = { name = name, need = need, needBis = bis and (toBis[name] or 0) or need,
                      have = got, source = source, learns = r.learns, learned = learned }
        row.done = got >= row.need
        row.doneBis = got >= row.needBis
        if not row.done then
            short.last = short.last + 1
            if source == "ah" then short.lastAH = short.lastAH + 1 end
        end
        if not row.doneBis then
            short.bis = short.bis + 1
            if source == "ah" then short.bisAH = short.bisAH + 1 end
        end
        rows[#rows + 1] = row
    end
    table.sort(rows, function(a, b) return a.name:lower() < b.name:lower() end)
    return rows, { short = short, sawBank = sawBank, skill = skill, plan = plan, bis = bis, last = last }
end

----------------------------------------------------------------------
-- drawing
----------------------------------------------------------------------

local function cell(got, need)
    if need <= 0 then return "|cff60ff60-|r" end
    if got >= need then return ("|cff60ff60%d|r"):format(need) end
    return ("|cffffffff%d|r"):format(need)
end

local function drawRows()
    if not panel then return end
    local offset = FauxScrollFrame_GetOffset(scroll)
    for i = 1, ROWS do
        local ui, r = rowsUI[i], data[i + offset]
        if r then
            local col = r.done and "|cff60ff60" or (r.have > 0 and "|cffffd070" or "|cffffffff")
            ui.name:SetText(col .. r.name .. "|r")
            if r.learns then
                ui.have:SetText("")
                ui.bis:SetText("")
                ui.last:SetText(r.learned and "|cff60ff60learned|r" or "|cffff8080formula|r")
            else
                ui.have:SetText(col .. r.have .. "|r")
                ui.bis:SetText(panel.hasBis and cell(r.have, r.needBis) or "")
                ui.last:SetText(cell(r.have, r.need))
            end
            ui.src:SetText(SOURCE[r.source] or "")
            ui.data = r
            ui:Show()
        else
            ui.data = nil
            ui:Hide()
        end
    end
    FauxScrollFrame_Update(scroll, #data, ROWS, ROWH)
end

local function stepText(st, info)
    local plan = info.plan
    if not st then return "" end
    if st.closed then
        return ("|cff909090Open your %s window to craft.|r"):format(plan.skill)
    end
    if st.done then return "|cff60ff60Route finished.|r" end
    if st.train then return "|cffff8040Train: " .. st.train .. "|r" end
    if not st.step then return "" end
    local s = st.step
    local line = ("Now: |cffffffff%s|r  %d-%d  |cff808080step %d/%d|r")
        :format(st.shown or s.craft, s.from, s.to, st.i or 0, st.n or 0)
    local nxt = plan.steps[(st.i or 0) + 1]
    if nxt then line = line .. ("\nNext: %s at %d"):format(nxt.craft, nxt.from) end
    if st.missingRecipe and s.note then line = line .. "\n|cffff8080" .. s.note .. "|r"
    elseif st.missingRecipe then line = line .. "\n|cffff8080Learn " .. st.missingRecipe .. " first.|r" end
    if st.tool then line = line .. "\n|cffff8080Needs " .. st.tool .. " (stand at one / carry it).|r" end
    if st.noTarget then
        line = line .. "\n|cffff8080Enchants go on an item in your bags: put a cheap one there (grey, white or green).|r"
    end
    return line
end

-- "BiS at 400: Socket Bracer and Socket Gloves (23 to go)", or, once there,
-- that it is reached and the rest is optional.
local function bisText(plan, skill)
    local b = plan.bis
    if not b then return "" end
    if (skill or 0) >= b.level then
        local last = plan.steps[#plan.steps].to
        return ("|cff60ff60BiS reached (%d): %s.|r%s"):format(b.level, b.what,
            last > b.level and ("\n|cff909090Going on to %d is optional.|r"):format(last) or "")
    end
    return ("|cffffd070BiS at %d:|r %s  |cff808080(%d to go)|r"):format(b.level, b.what, b.level - (skill or 0))
end

function ns.RefreshPanel()
    if not panel or not panel:IsShown() then return end
    local key = ns.ActiveKey()
    local plan = ns.plan[key]
    for k, t in pairs(tabs) do
        if k == key then t:LockHighlight() else t:UnlockHighlight() end
    end

    local rows, info = ns.PanelRows(key)
    data = rows
    local skill, live = info.skill, ns.SkillNow(plan.skill)
    panel.skill:SetText(("|cffffd070%s|r  %d / %d%s"):format(plan.skill, skill or 0,
        info.last, live and "" or "  |cff808080(window closed)|r"))
    panel.bar:SetMinMaxValues(0, info.last)
    panel.bar:SetValue(skill or 0)
    panel.bisLine:SetText(bisText(plan, skill))

    local st = ns.levelState
    if st and st.key ~= key then st = { closed = true } end
    panel.step:SetText(stepText(st or { closed = true }, info))

    -- the craft button mirrors the real button's label
    local lb = _G.BastionProfLevelButton
    craftBtn:SetText(lb and lb.label:GetText() or "")
    if st and st.target then
        panel.target:SetText(("Enchants go on: |cffffffff%s|r"):format(st.target.name))
        panel.target:Show(); panel.nextItem:Show()
    else
        panel.target:Hide(); panel.nextItem:Hide()
    end

    -- Columns and buttons: "to 400" and "to 450", or just one when the route
    -- ends at its BiS level (Engineering).
    panel.hasBis = info.bis ~= nil
    panel.hBis:SetText(info.bis and ("to %d"):format(info.bis) or "")
    panel.hLast:SetText(("to %d"):format(info.last))
    if info.bis then
        panel.pushBis:SetText(("Push mats to %d (BiS)"):format(info.bis))
        panel.pushBis:Show()
        panel.pushLast:SetText(("Push mats to %d"):format(info.last))
        panel.pushLast:ClearAllPoints()
        panel.pushLast:SetPoint("LEFT", panel.pushBis, "RIGHT", 4, 0)
        panel.pushLast:SetWidth(132)
    else
        panel.pushBis:Hide()
        panel.pushLast:SetText(("Push mats to %d (BiS)"):format(info.last))
        panel.pushLast:ClearAllPoints()
        panel.pushLast:SetPoint("BOTTOMLEFT", 10, 10)
        panel.pushLast:SetWidth(286)
    end

    local sh = info.short
    local parts = {}
    if info.bis then
        parts[#parts + 1] = sh.bis == 0 and ("|cff60ff60all set for %d|r"):format(info.bis)
            or ("to %d: %d short"):format(info.bis, sh.bis)
    end
    parts[#parts + 1] = sh.last == 0 and ("|cff60ff60all set for %d|r"):format(info.last)
        or ("to %d: %d short"):format(info.last, sh.last)
    panel.summary:SetText(table.concat(parts, "   ")
        .. (info.sawBank and "" or "\n|cff808080Bags only; open your bank to count it too.|r"))
    drawRows()
end

----------------------------------------------------------------------
-- pushing
----------------------------------------------------------------------

-- What you are still short of to reach `toBis` (the BiS level) or the end,
-- that the auction house sells.
local function push(toBis)
    local key = ns.ActiveKey()
    local plan = ns.plan[key]
    local rows, info = ns.PanelRows(key)
    local level = (toBis and info.bis) or info.last
    local names = {}
    for _, r in ipairs(rows) do
        local need = (toBis and info.bis) and r.needBis or r.need
        if r.source == "ah" and not r.learned and need > 0 and r.have < need then
            names[#names + 1] = r.name
        end
    end
    if #names == 0 then
        out(("|cff60ff60Nothing missing to buy for %d.|r"):format(level))
        return
    end
    -- One list per profession, named after what is in it. Pushing replaces
    -- the profession's other one (the other goal, or an older "1-450" list),
    -- so the dropdown never offers a list that no longer matches.
    local name = ns.ListName(key, toBis)
    for _, old in ipairs({ plan.label, ns.ListName(key, true), ns.ListName(key, false) }) do
        if old ~= name and ML:RemoveSList(old) then out(("Removed the old list \"|cffffffff%s|r\"."):format(old)) end
    end
    ML:PushNames(name, names, ("what you are missing to reach %d"):format(level))
end

-- "Jewelcrafting to 370 (BiS)" or "Jewelcrafting to 450".
function ns.ListName(key, toBis)
    local plan = ns.plan[key]
    local bis, last = ns.Goals(key)
    if toBis and bis then return ("%s to %d (BiS)"):format(plan.skill, bis) end
    -- Engineering's route ends at its BiS level, so its one list is the BiS one
    if not bis and plan.bis and plan.bis.level == last then
        return ("%s to %d (BiS)"):format(plan.skill, last)
    end
    return ("%s to %d"):format(plan.skill, last)
end
ns.PushFor = push

----------------------------------------------------------------------
-- building
----------------------------------------------------------------------

local function small(parent, text, w)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetWidth(w); b:SetHeight(20)
    b:SetText(text)
    return b
end

local function build()
    if panel then return end
    local lb = ns.BuildLevelButton()
    if not lb._floating then lb:Hide() end

    panel = CreateFrame("Frame", "BastionProfPanel", UIParent)
    panel:SetWidth(310); panel:SetHeight(500)
    panel:SetPoint("CENTER", UIParent, "CENTER", 260, 40)
    panel:SetFrameStrata("HIGH")
    panel:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
                        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                        tile = true, tileSize = 16, edgeSize = 16,
                        insets = { left = 4, right = 4, top = 4, bottom = 4 } })
    panel:SetBackdropColor(0.05, 0.05, 0.08, 0.95)
    panel:EnableMouse(true)
    panel:SetMovable(true)
    panel:RegisterForDrag("LeftButton")
    -- Drag it anywhere. Next to the profession window the spot is
    -- remembered relative to that window, so it follows the window and
    -- comes back there next time (useful when another addon already uses
    -- the space on the right).
    panel:SetScript("OnDragStart", function(s)
        if InCombatLockdown() then return end
        s:StartMoving()
    end)
    panel:SetScript("OnDragStop", function(s)
        s:StopMovingOrSizing()
        if not docked or InCombatLockdown() then return end
        local ps, ts = s:GetEffectiveScale(), docked:GetEffectiveScale()
        local dx = (s:GetLeft() * ps - docked:GetRight() * ts) / ps
        local dy = (s:GetTop() * ps - docked:GetTop() * ts) / ps
        BastionProfessionsDB = BastionProfessionsDB or {}
        BastionProfessionsDB.dock = BastionProfessionsDB.dock or {}
        BastionProfessionsDB.dock[docked:GetName() or "?"] = { x = dx, y = dy }
        s:ClearAllPoints()
        s:SetPoint("TOPLEFT", docked, "TOPRIGHT", dx, dy)
    end)
    panel:Hide()
    tinsert(UISpecialFrames, "BastionProfPanel")

    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", 12, -10)
    title:SetText("Bastion Professions")
    local close = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", 0, 0)

    -- profession tabs; an open profession window overrides them
    local prev
    for _, k in ipairs(ORDER) do
        if ns.plan[k] then
            local t = small(panel, SHORT[k], 72)
            if prev then t:SetPoint("LEFT", prev, "RIGHT", 2, 0) else t:SetPoint("TOPLEFT", 10, -30) end
            t:SetScript("OnClick", function()
                ns.SetActiveKey(k); ns.RefreshLevel(); ns.RefreshPanel()
            end)
            tabs[k] = t
            prev = t
        end
    end

    panel.skill = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    panel.skill:SetPoint("TOPLEFT", 12, -58)
    panel.bar = CreateFrame("StatusBar", nil, panel)
    panel.bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    panel.bar:SetStatusBarColor(0.2, 0.6, 1)
    panel.bar:SetPoint("TOPLEFT", 12, -74); panel.bar:SetPoint("TOPRIGHT", -12, -74)
    panel.bar:SetHeight(6)
    local bbg = panel.bar:CreateTexture(nil, "BACKGROUND")
    bbg:SetAllPoints(); bbg:SetTexture(0, 0, 0, 0.6)

    panel.step = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    panel.step:SetPoint("TOPLEFT", 12, -86); panel.step:SetPoint("TOPRIGHT", -12, -86)
    panel.step:SetJustifyH("LEFT"); panel.step:SetJustifyV("TOP")
    panel.step:SetHeight(40)

    panel.bisLine = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    panel.bisLine:SetPoint("TOPLEFT", 12, -128); panel.bisLine:SetPoint("TOPRIGHT", -12, -128)
    panel.bisLine:SetJustifyH("LEFT"); panel.bisLine:SetJustifyV("TOP")
    panel.bisLine:SetHeight(26)

    -- The big button clicks the real crafting button, so there is one set of
    -- rules for both and every craft is still your press.
    craftBtn = CreateFrame("Button", "BastionProfPanelCraft", panel,
                           "SecureActionButtonTemplate,UIPanelButtonTemplate")
    craftBtn:SetWidth(286); craftBtn:SetHeight(32)
    craftBtn:SetPoint("TOP", 0, -158)
    craftBtn:SetAttribute("type", "click")
    craftBtn:SetAttribute("clickbutton", lb)
    craftBtn:RegisterForClicks("AnyUp")
    craftBtn:SetScript("OnEnter", function(s) ns.LevelTooltip(s, "ANCHOR_RIGHT") end)
    craftBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    local fs = craftBtn:GetFontString()
    if fs then fs:SetWidth(276) end

    panel.target = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    panel.target:SetPoint("TOPLEFT", 12, -198); panel.target:SetWidth(200); panel.target:SetJustifyH("LEFT")
    panel.nextItem = small(panel, "Other item", 80)
    panel.nextItem:SetPoint("TOPRIGHT", -10, -194)
    panel.nextItem:SetScript("OnClick", function()
        local st = ns.levelState
        if st and st.enchantSlot then ns.NextEnchantTarget(st.enchantSlot) end
    end)

    -- column headers: still needed to the BiS level, and to the end
    local function head(text, x, w, just)
        local h = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        h:SetPoint("TOPLEFT", 12 + x, -220); h:SetWidth(w); h:SetJustifyH(just or "RIGHT")
        h:SetText(text)
        return h
    end
    head("Still needed", 0, 112, "LEFT")
    head("have", 112, 30)
    panel.hBis = head("", 142, 40)
    panel.hLast = head("", 182, 40)

    scroll = CreateFrame("ScrollFrame", "BastionProfPanelScroll", panel, "FauxScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 10, -236)
    scroll:SetWidth(266); scroll:SetHeight(ROWS * ROWH)
    scroll:SetScript("OnVerticalScroll", function(self, offset)
        FauxScrollFrame_OnVerticalScroll(self, offset, ROWH, drawRows)
    end)
    for i = 1, ROWS do
        local r = CreateFrame("Button", nil, panel)
        r:SetHeight(ROWH); r:SetWidth(266)
        r:SetPoint("TOPLEFT", 12, -236 - (i - 1) * ROWH)
        local function col(x, w, just)
            local f = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            f:SetPoint("LEFT", x, 0); f:SetWidth(w); f:SetJustifyH(just or "RIGHT")
            return f
        end
        r.name = col(0, 112, "LEFT")
        r.have = col(112, 30)
        r.bis  = col(142, 40)
        r.last = col(182, 40)
        r.src  = col(226, 40)
        r:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
        r:SetScript("OnEnter", function(s)
            local d = s.data
            if not d then return end
            GameTooltip:SetOwner(s, "ANCHOR_RIGHT")
            local _, link = GetItemInfo(d.name)
            if link then GameTooltip:SetHyperlink(link) else GameTooltip:SetText(d.name) end
            GameTooltip:AddLine(" ")
            local bis, last = ns.Goals(ns.ActiveKey())
            GameTooltip:AddLine(("You have %d."):format(d.have), 1, 1, 1)
            if bis then GameTooltip:AddLine(("Still needed to reach %d: %d"):format(bis, d.needBis), 1, 1, 1) end
            GameTooltip:AddLine(("Still needed to reach %d: %d"):format(last, d.need), 1, 1, 1)
            if d.source == "craft" then
                GameTooltip:AddLine("An earlier step of the route makes this.", 0.9, 0.7, 0.2, true)
            elseif d.source == "vendor" then
                GameTooltip:AddLine("Sold by a vendor; not pushed to the AH list.", 0.7, 0.7, 0.7, true)
            end
            GameTooltip:Show()
        end)
        r:SetScript("OnLeave", function() GameTooltip:Hide() end)
        rowsUI[i] = r
    end

    panel.summary = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    panel.summary:SetPoint("BOTTOMLEFT", 12, 36); panel.summary:SetPoint("BOTTOMRIGHT", -12, 36)
    panel.summary:SetJustifyH("LEFT")

    -- Two pushes: what you are short of to reach the BiS level, and to the
    -- end. Each puts only the missing AH items into the Auctionator list.
    local function pushTip(b, toBis)
        b:SetScript("OnEnter", function(s)
            local bis, last = ns.Goals(ns.ActiveKey())
            local lvl = (toBis and bis) or last
            local plan = ns.plan[ns.ActiveKey()]
            GameTooltip:SetOwner(s, "ANCHOR_TOP")
            GameTooltip:SetText(s:GetText())
            -- why this level, in one short paragraph
            if lvl == (plan.bis and plan.bis.level) and plan.bis.why then
                GameTooltip:AddLine(plan.bis.why, 1, 1, 1, true)
            elseif plan.bis then
                GameTooltip:AddLine(("Everything to %d, the max. Past %d it is optional: the %s bonus is already yours at %d.")
                    :format(lvl, plan.bis.level, plan.skill, plan.bis.level), 1, 1, 1, true)
            end
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(("Click to put what you are still short of into the Auctionator shopping list \"%s\". Vendor items and things you craft on the way are left out.")
                :format(ns.ListName(ns.ActiveKey(), toBis)), 0.75, 0.75, 0.75, true)
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end
    panel.pushBis = small(panel, "Push mats to BiS", 150)
    panel.pushBis:SetPoint("BOTTOMLEFT", 10, 10)
    panel.pushBis:SetScript("OnClick", function() push(true) end)
    pushTip(panel.pushBis, true)
    panel.pushLast = small(panel, "Push mats to 450", 132)
    panel.pushLast:SetPoint("LEFT", panel.pushBis, "RIGHT", 4, 0)
    panel.pushLast:SetScript("OnClick", function() push(false) end)
    pushTip(panel.pushLast, false)

    panel:SetScript("OnShow", function()
        -- the key presses the panel's button, the one you can see
        if not lb._floating then ns.BindKey("BastionProfPanelCraft") end
        ns.RefreshLevel(); ns.RefreshPanel()
    end)
    panel:SetScript("OnHide", function()
        if not lb._floating then ns.UnbindKey() end
    end)
    -- a craft batch fires a bag update per bag per craft; redraw at most
    -- every 0.3 s instead of on each one
    ns.OnLevelRefresh(function() if ns.QueuePanelRefresh then ns.QueuePanelRefresh() end end)
end

function ns.PanelShown() return panel and panel:IsShown() end

-- Stuck to the right edge of the profession window while it is open, free
-- (and movable) otherwise.
local function dock(to)
    if InCombatLockdown() then return false end
    build()
    panel:ClearAllPoints()
    if to then
        -- where you dragged it last time, else just right of the window (the
        -- profession window's art has a transparent margin on the right)
        local saved = BastionProfessionsDB and BastionProfessionsDB.dock and BastionProfessionsDB.dock[to:GetName() or "?"]
        if saved then
            panel:SetPoint("TOPLEFT", to, "TOPRIGHT", saved.x, saved.y)
        else
            panel:SetPoint("TOPLEFT", to, "TOPRIGHT", (to == TradeSkillFrame) and -34 or 2, -12)
        end
        docked = to
    else
        panel:SetPoint("CENTER", UIParent, "CENTER", 260, 40)
        docked = nil
    end
    return true
end

local function showPanel(anchor)
    if InCombatLockdown() then
        pendingShow = anchor or true
        out("opens when you leave combat.")
        return
    end
    dock(anchor)
    panel:Show()
end

function ns.TogglePanel()
    if panel and panel:IsShown() then
        if not InCombatLockdown() then panel:Hide() end
        return
    end
    if TradeSkillFrame and TradeSkillFrame:IsShown() then showPanel(TradeSkillFrame)
    elseif AuctionFrame and AuctionFrame:IsShown() then showPanel(AuctionFrame)
    else showPanel(nil) end
end

----------------------------------------------------------------------
-- events
----------------------------------------------------------------------

local throttle = CreateFrame("Frame")
throttle:Hide()
throttle:SetScript("OnUpdate", function(s, e)
    s.t = (s.t or 0) + e
    if s.t < 0.3 then return end
    s.t = 0; s:Hide()
    ns.RefreshPanel()
end)

ns.QueuePanelRefresh = function() throttle:Show() end

-- Crossing the BiS level while crafting: say so, loudly, once. Many people
-- stop there, so it should not be missable.
local lastSkill = {}
function ns.AnnounceBis(key)
    local plan = ns.plan[key]
    local b = plan and plan.bis
    if not b then return end
    local msg = ("%s %d: BiS reached! %s unlocked."):format(plan.skill, b.level, b.what)
    out("|cff60ff60" .. msg .. "|r")
    local last = plan.steps[#plan.steps].to
    if last > b.level then out(("|cff909090Going on to %d is optional.|r"):format(last)) end
    if RaidNotice_AddMessage and RaidWarningFrame then
        RaidNotice_AddMessage(RaidWarningFrame, msg, (ChatTypeInfo and ChatTypeInfo["RAID_WARNING"]) or { r = 1, g = 1, b = 0 })
    end
    if PlaySound then PlaySound("LEVELUPSOUND") end
end
ns.OnLevelRefresh(function(st)
    if not st or not st.key or not st.skill or st.closed then return end
    local b = ns.plan[st.key].bis
    local prev = lastSkill[st.key]
    lastSkill[st.key] = st.skill
    if b and prev and prev < b.level and st.skill >= b.level then ns.AnnounceBis(st.key) end
end)

local ev = CreateFrame("Frame")
for _, e in ipairs({ "PLAYER_LOGIN", "TRADE_SKILL_SHOW", "TRADE_SKILL_CLOSE", "TRADE_SKILL_UPDATE",
                     "BAG_UPDATE", "BANKFRAME_OPENED", "BANKFRAME_CLOSED", "SKILL_LINES_CHANGED",
                     "AUCTION_HOUSE_SHOW", "PLAYER_REGEN_ENABLED" }) do
    ev:RegisterEvent(e)
end
ev:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        BastionProfessionsDB = BastionProfessionsDB or {}
        if BastionProfessionsDB.lastKey then ns.SetActiveKey(BastionProfessionsDB.lastKey) end
    elseif event == "TRADE_SKILL_SHOW" then
        rememberKnown()
        local key = ns.KeyForSkill(GetTradeSkillLine())
        if key and (BastionProfessionsDB or {}).autoShow ~= false then
            ns.SetActiveKey(key)
            showPanel(TradeSkillFrame)
        end
    elseif event == "TRADE_SKILL_UPDATE" then
        rememberKnown()
        throttle:Show()
    elseif event == "TRADE_SKILL_CLOSE" then
        if panel and docked and not InCombatLockdown() then panel:Hide() end
    elseif event == "AUCTION_HOUSE_SHOW" then
        if AuctionFrame and not ns._ahButton then
            local b = small(AuctionFrame, "Professions", 90)
            b:SetPoint("TOPRIGHT", AuctionFrame, "TOPRIGHT", -70, -14)
            b:SetScript("OnClick", function() ns.TogglePanel() end)
            ns._ahButton = b
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        if pendingShow then
            local a = pendingShow
            pendingShow = nil
            showPanel(a ~= true and a or nil)
        end
    else
        throttle:Show()
    end
end)

