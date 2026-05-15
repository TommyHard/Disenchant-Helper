local addonName, DH = ...
local L = DH.L

DH.UI = DH.UI or {}

local ROW_HEIGHT = 26
local GAP = 10
local LIST_BOTTOM_PAD = 26

local MIN_W, MIN_H = 900, 420

local function AddTooltip(frame, title, textFuncOrString)
  frame:SetScript("OnEnter", function(selfObj)
    GameTooltip:SetOwner(selfObj, "ANCHOR_RIGHT")
    if title and title ~= "" then GameTooltip:AddLine(title) end

    local text = textFuncOrString
    if type(textFuncOrString) == "function" then
      text = textFuncOrString()
    end

    if text and text ~= "" then
      GameTooltip:AddLine(text, 0.85, 0.85, 0.85, true)
    end
    GameTooltip:Show()
  end)
  frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

local function SaveFramePlacement(frame, db)
  if not db or not db.frame then return end
  db.frame.w, db.frame.h = frame:GetSize()
  local point, _, _, x, y = frame:GetPoint(1)
  db.frame.point = point or "CENTER"
  db.frame.x = x or 0
  db.frame.y = y or 0
end

local function RestoreFramePlacement(frame, db)
  if not db or not db.frame then return end
  frame:ClearAllPoints()
  frame:SetPoint(db.frame.point or "CENTER", UIParent, db.frame.point or "CENTER", db.frame.x or 0, db.frame.y or 0)
  frame:SetSize(db.frame.w or MIN_W, db.frame.h or 520)
end

local function SetResizeMinimum(frame, minW, minH)
  if type(frame.SetResizeBounds) == "function" then
    frame:SetResizeBounds(minW, minH)
  end
end

local function ResetWindow()
  if not DH.UI or not DH.UI.MainFrame then return end
  local frame = DH.UI.MainFrame

  frame:ClearAllPoints()
  frame:SetPoint("CENTER")
  frame:SetSize(MIN_W, MIN_H)

  if DH.DB and DH.DB.frame then
    DH.DB.frame.point = "CENTER"
    DH.DB.frame.x, DH.DB.frame.y = 0, 0
    DH.DB.frame.w, DH.DB.frame.h = MIN_W, MIN_H
  end
end

local function GetAddonVersion()
  if C_AddOns and C_AddOns.GetAddOnMetadata then
    return C_AddOns.GetAddOnMetadata(addonName, "Version")
  end
  return nil
end

local function CreateGroupBox(parent, titleText)
  local f = CreateFrame("Frame", nil, parent, "BackdropTemplate")
  f:SetBackdrop({
    bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
    edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 8, right = 8, top = 8, bottom = 8 },
  })

  local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  title:SetPoint("TOPLEFT", 12, -10)
  title:SetText(titleText)

  f.Title = title
  return f
end

local function CreateRow(button)
  local b = CreateFrame("Frame", nil, button)
  b:SetAllPoints(button)

  b.icon = b:CreateTexture(nil, "ARTWORK")
  b.icon:SetSize(20, 20)
  b.icon:SetPoint("LEFT", 6, 0)

  b.name = b:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  b.name:SetPoint("LEFT", b.icon, "RIGHT", 8, 0)
  b.name:SetPoint("RIGHT", b, "RIGHT", -120, 0)
  b.name:SetJustifyH("LEFT")

  b.ilvl = b:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  b.ilvl:SetPoint("RIGHT", b, "RIGHT", -70, 0)
  b.ilvl:SetJustifyH("RIGHT")

  b.count = b:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  b.count:SetPoint("RIGHT", -12, 0)
  b.count:SetJustifyH("RIGHT")

  return b
end

local function CreateScrollList(parent, onClick, tooltipText)
  local host = CreateFrame("Frame", nil, parent)
  host:SetPoint("TOPLEFT", 10, -32)
  host:SetPoint("BOTTOMRIGHT", -28, 10 + LIST_BOTTOM_PAD)

  host.ScrollBox = CreateFrame("Frame", nil, host, "WowScrollBoxList")
  host.ScrollBox:SetPoint("TOPLEFT", 0, 0)
  host.ScrollBox:SetPoint("BOTTOMRIGHT", -18, 0)

  host.ScrollBar = CreateFrame("EventFrame", nil, host, "MinimalScrollBar")
  host.ScrollBar:SetPoint("TOPLEFT", host.ScrollBox, "TOPRIGHT", 2, 0)
  host.ScrollBar:SetPoint("BOTTOMLEFT", host.ScrollBox, "BOTTOMRIGHT", 2, 0)

  local view = CreateScrollBoxListLinearView()
  view:SetElementExtent(ROW_HEIGHT)
  view:SetElementInitializer("Button", function(button, elementData)
    if not button.__inited then
      button.__inited = true
      button:SetHeight(ROW_HEIGHT)

      local hl = button:CreateTexture(nil, "HIGHLIGHT")
      hl:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
      hl:SetBlendMode("ADD")
      hl:SetAllPoints(button)

      button:SetScript("OnEnter", function(selfBtn)
        GameTooltip:SetOwner(selfBtn, "ANCHOR_RIGHT")
        if selfBtn.link then
          GameTooltip:SetHyperlink(selfBtn.link)
          GameTooltip:AddLine(" ")
        end
        if tooltipText and tooltipText ~= "" then
          GameTooltip:AddLine(tooltipText, 0.8, 0.8, 0.8, true)
        end
        GameTooltip:Show()
      end)
      button:SetScript("OnLeave", function() GameTooltip:Hide() end)

      local row = CreateRow(button)
      button.icon  = row.icon
      button.name  = row.name
      button.count = row.count
      button.ilvl  = row.ilvl
    end

    button.icon:SetTexture(elementData.icon or 0)
    button.name:SetText(elementData.name or "?")
    button.count:SetText("x" .. tostring(elementData.count or 0))
    button.ilvl:SetText(elementData.ilvl and ("ilvl " .. elementData.ilvl) or "")

    button.key = elementData.key
    button.link = elementData.link

    button:SetScript("OnClick", function(_, mouseButton)
      if mouseButton == "LeftButton" and button.key then
        onClick(button.key)
      end
    end)
  end)

  ScrollUtil.InitScrollBoxListWithScrollBar(host.ScrollBox, host.ScrollBar, view)

  host.DataProvider = CreateDataProvider()
  host.ScrollBox:SetDataProvider(host.DataProvider)

  function host:SetData(list)
    self.DataProvider:Flush()
    for _, e in ipairs(list or {}) do
      self.DataProvider:Insert(e)
    end
  end

  return host
end

local function MinimapButton_Reposition(btn)
  local db = DH.DB and DH.DB.minimap
  if not db then return end
  local angle = (db.angle or 220) * math.pi / 180
  local radius = 80
  btn:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)
end

local function CreateMinimapButton()
  if DH.UI.MinimapButton then return end
  if not DH.DB or not DH.DB.minimap or DH.DB.minimap.hide then return end

  local btn = CreateFrame("Button", "DisenchantHelperMinimapButton", Minimap)
  btn:SetSize(32, 32)
  btn:SetFrameStrata("MEDIUM")
  btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")

  local icon = btn:CreateTexture(nil, "ARTWORK")
  icon:SetSize(20, 20)
  icon:SetPoint("CENTER", 0, 1)
  icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

  local customIcon = "Interface\\AddOns\\DisenchantHelper\\Media\\Disenchant.tga"
  local fallbackIcon = "Interface\\Icons\\INV_Enchant_Disenchant"

  if C_Texture and type(C_Texture.GetFileIDFromPath) == "function" then
    local fileID = C_Texture.GetFileIDFromPath(customIcon)
    icon:SetTexture(fileID and customIcon or fallbackIcon)
  else
    icon:SetTexture(customIcon)
    if not icon:GetTexture() then
      icon:SetTexture(fallbackIcon)
    end
  end

  if type(icon.SetMaskTexture) == "function" then
    icon:SetMaskTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask")
  end

  btn.icon = icon

  local border = btn:CreateTexture(nil, "OVERLAY")
  border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
  border:SetSize(56, 56)
  border:SetPoint("CENTER", 10, -12)

  btn:SetScript("OnClick", function(_, mouseButton)
    if mouseButton == "LeftButton" then
      if IsShiftKeyDown and IsShiftKeyDown() then
        ResetWindow()
        return
      end
      if DH.UI and DH.UI.MainFrame then
        local show = not DH.UI.MainFrame:IsShown()
        if show then DH:FullRescan() end
        DH.UI.MainFrame:SetShown(show)
      end
    end
  end)

  btn:SetScript("OnEnter", function(selfBtn)
    GameTooltip:SetOwner(selfBtn, "ANCHOR_LEFT")
    GameTooltip:AddLine(L.ADDON_TITLE)
    GameTooltip:AddLine(L.TIP_MINIMAP or "", 0.8, 0.8, 0.8, true)
    GameTooltip:Show()
  end)
  btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

  btn:SetMovable(true)
  btn:EnableMouse(true)
  btn:RegisterForDrag("RightButton")
  btn:SetScript("OnDragStart", function(selfBtn)
    selfBtn:SetScript("OnUpdate", function(selfUpdate)
      local mx, my = Minimap:GetCenter()
      local px, py = GetCursorPosition()
      local scale = UIParent:GetScale()
      px, py = px / scale, py / scale
      local dx, dy = px - mx, py - my
      local ang = math.deg(math.atan2(dy, dx))
      DH.DB.minimap.angle = ang
      MinimapButton_Reposition(selfUpdate)
    end)
  end)
  btn:SetScript("OnDragStop", function(selfBtn)
    selfBtn:SetScript("OnUpdate", nil)
    MinimapButton_Reposition(selfBtn)
  end)

  DH.UI.MinimapButton = btn
  MinimapButton_Reposition(btn)
end

function DH:CreateUI()
  if self.UI.MainFrame then return end

  local frame = CreateFrame("Frame", "DisenchantHelperFrame", UIParent, "BackdropTemplate")
  frame:SetClampedToScreen(true)
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", frame.StartMoving)
  frame:SetScript("OnDragStop", function()
    frame:StopMovingOrSizing()
    SaveFramePlacement(frame, DH.DB)
  end)

  frame:SetResizable(true)
  SetResizeMinimum(frame, MIN_W, MIN_H)

  frame:SetBackdrop({
    bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
    edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 8, right = 8, top = 8, bottom = 8 },
  })

  tinsert(UISpecialFrames, frame:GetName())

  local title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
  title:SetPoint("TOP", frame, "TOP", 0, -14)
  title:SetJustifyH("CENTER")

  local ver = GetAddonVersion()
  if ver and ver ~= "" then
    title:SetText(string.format("%s %s", L.ADDON_TITLE, ver))
  else
    title:SetText(L.ADDON_TITLE)
  end

  local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", -16, -16)
  close:SetScale(0.8)

  local resize = CreateFrame("Button", nil, frame)
  resize:SetSize(18, 18)
  resize:SetPoint("BOTTOMRIGHT", -8, 8)
  resize:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
  resize:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
  resize:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
  resize:SetScript("OnMouseDown", function() frame:StartSizing("BOTTOMRIGHT") end)
  resize:SetScript("OnMouseUp", function()
    frame:StopMovingOrSizing()
    SaveFramePlacement(frame, DH.DB)
  end)

  local resetBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  resetBtn:SetSize(140, 22)
  resetBtn:SetPoint("BOTTOMRIGHT", -24, 20)
  resetBtn:SetText(L.RESET_POS or "Reset position")
  AddTooltip(resetBtn, L.RESET_POS or "", L.TIP_RESET_POS or "")
  resetBtn:SetScript("OnClick", function() ResetWindow() end)

  local controls = CreateFrame("Frame", nil, frame)
  controls:SetPoint("TOPLEFT", 14, -46)
  controls:SetPoint("TOPRIGHT", -14, -46)
  controls:SetHeight(62)

  local function MakeCB(text, tipText, qualityEnum, x)
    local cb = CreateFrame("CheckButton", nil, controls, "UICheckButtonTemplate")
    cb.linkage = cb
    cb:SetPoint("TOPLEFT", x, 0)
    cb.text:SetText(text)
    cb:SetChecked(DH.DB and DH.DB.filters and DH.DB.filters[qualityEnum] or false)
    cb:SetScript("OnClick", function(selfBtn)
      DH:SetQualityFilter(qualityEnum, selfBtn:GetChecked())
      DH:FullRescan()
    end)
    AddTooltip(cb, text, tipText)
    return cb
  end

  local x = 0
  MakeCB(L.QUALITY_COMMON,   L.TIP_FILTER_COMMON,   Enum.ItemQuality.Common,   x); x = x + 120
  MakeCB(L.QUALITY_UNCOMMON, L.TIP_FILTER_UNCOMMON, Enum.ItemQuality.Uncommon, x); x = x + 120
  MakeCB(L.QUALITY_RARE,     L.TIP_FILTER_RARE,     Enum.ItemQuality.Rare,     x); x = x + 120
  MakeCB(L.QUALITY_EPIC,     L.TIP_FILTER_EPIC,     Enum.ItemQuality.Epic,     x); x = x + 120

  local moveAll = CreateFrame("Button", nil, controls, "UIPanelButtonTemplate")
  moveAll:SetSize(140, 24)
  moveAll:SetPoint("TOPRIGHT", -310, 0)
  moveAll:SetText(L.MOVE_ALL)
  moveAll:SetScript("OnClick", function() DH:MoveAllToQueue() end)
  AddTooltip(moveAll, L.MOVE_ALL, L.TIP_MOVE_ALL)

  local clear = CreateFrame("Button", nil, controls, "UIPanelButtonTemplate")
  clear:SetSize(120, 24)
  clear:SetPoint("TOPRIGHT", -180, 0)
  clear:SetText(L.CLEAR)
  clear:SetScript("OnClick", function() DH:ClearQueue() end)
  AddTooltip(clear, L.CLEAR, L.TIP_CLEAR)

  local secureCastBtn = CreateFrame("Button", nil, controls, "SecureActionButtonTemplate, UIPanelButtonTemplate")
  secureCastBtn:SetSize(160, 24)
  secureCastBtn:SetPoint("TOPRIGHT", -10, 0)
  secureCastBtn:RegisterForClicks("AnyDown")
  secureCastBtn:SetText(L.CAST_DISENCHANT)

  secureCastBtn:SetAttribute("type", "macro")
  secureCastBtn:SetAttribute("macrotext", "/stopmacro")
  secureCastBtn:SetAttribute("type1", "macro")
  secureCastBtn:SetAttribute("macrotext1", "/stopmacro")

  self.UI.CastBtn = secureCastBtn
  self.UI.CastBtnTextIdle = L.CAST_DISENCHANT
  self.UI.CastBtnTextCasting = L.CAST_DISENCHANTING or L.CAST_DISENCHANT

  local spinner = secureCastBtn:CreateTexture(nil, "OVERLAY")
  spinner:SetSize(14, 14)
  spinner:SetPoint("LEFT", 8, 0)
  spinner:SetTexture("Interface\\Common\\StreamCircle")
  spinner:Hide()
  self.UI.CastSpinner = spinner

  local ag = spinner:CreateAnimationGroup()
  ag:SetLooping("REPEAT")
  local rot = ag:CreateAnimation("Rotation")
  rot:SetDuration(0.85)
  rot:SetDegrees(360)
  self.UI.CastSpinnerAnim = ag

  function self.UI:SetDisenchantIndicator(on)
    if on then
      self.CastSpinner:Show()
      if not self.CastSpinnerAnim:IsPlaying() then
        self.CastSpinnerAnim:Play()
      end
    else
      if self.CastSpinnerAnim:IsPlaying() then
        self.CastSpinnerAnim:Stop()
      end
      self.CastSpinner:Hide()
    end
  end

  function self.UI:SetCastButtonCasting(on)
    if not self.CastBtn then return end
    if on then
      self.CastBtn:SetText(self.CastBtnTextCasting)
    else
      self.CastBtn:SetText(self.CastBtnTextIdle)
    end
  end

  local function GetAutoLootOn()
    return (GetCVar and GetCVar("autoLootDefault") == "1") or false
  end

  local function SetAutoLootOn(on)
    if not SetCVar then return end
    SetCVar("autoLootDefault", on and "1" or "0")
  end

  local function ToggleAutoLoot()
    local on = GetAutoLootOn()
    SetAutoLootOn(not on)
  end

  local autoLootCB = CreateFrame("CheckButton", nil, controls, "UICheckButtonTemplate")
  autoLootCB:SetPoint("TOPRIGHT", secureCastBtn, "BOTTOMRIGHT", 4, -5)
  autoLootCB:SetChecked(GetAutoLootOn())

  autoLootCB.text:SetText(L.AUTOLOOT or "Auto Loot")
  autoLootCB.text:ClearAllPoints()
  autoLootCB.text:SetPoint("RIGHT", autoLootCB, "LEFT", -5, 0)
  autoLootCB.text:SetJustifyH("RIGHT")

  autoLootCB:SetScript("OnClick", function(selfBtn)
    ToggleAutoLoot()
    selfBtn:SetChecked(GetAutoLootOn())
  end)

  AddTooltip(autoLootCB, (L.AUTOLOOT or "Auto Loot"), (L.TIP_AUTOLOOT or "Включает/выключает Auto Loot (CVar autoLootDefault)."))
  self.UI.AutoLootCB = autoLootCB

  local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  hint:SetPoint("TOPLEFT", controls, "BOTTOMLEFT", 0, -4)
  hint:SetText("")
  hint:SetJustifyH("LEFT")

  AddTooltip(secureCastBtn, L.CAST_DISENCHANT, function()
    local st = DH and DH.CastStatus
    if not st or st.ok then
      return L.TIP_CAST or ""
    end
    if st.reason == "IN_COMBAT" then
      return (L.TIP_CAST or "") .. "\n" .. (L.TIP_IN_COMBAT or "Unavailable in combat.")
    elseif st.reason == "QUEUE_EMPTY" then
      return (L.TIP_CAST or "") .. "\n" .. (L.TIP_QUEUE_EMPTY or "Queue is empty.")
    elseif st.reason == "NO_ITEMID" then
      return (L.TIP_CAST or "") .. "\n" .. (L.TIP_NO_ITEMID or "Item ID not found.")
    elseif st.reason == "SPELL_NOT_KNOWN" then
      return (L.TIP_CAST or "") .. "\n" .. (L.TIP_SPELL_NOT_KNOWN or "Disenchant is not known.")
    elseif st.reason == "SPELL_NAME_NIL" then
      return (L.TIP_CAST or "") .. "\n" .. (L.TIP_SPELL_NAME_NIL or "Unable to resolve spell name.")
    end
    return L.TIP_CAST or ""
  end)

  local searchBox = CreateFrame("EditBox", nil, controls, "SearchBoxTemplate")
  searchBox:SetSize(260, 24)
  searchBox:SetPoint("BOTTOMLEFT", 10, 0)
  searchBox:SetAutoFocus(false)
  searchBox:SetText(DH.DB and DH.DB.search or "")
  searchBox.Instructions:SetText(L.SEARCH)
  searchBox:SetScript("OnTextChanged", function(selfBox)
    if SearchBoxTemplate_OnTextChanged then
      SearchBoxTemplate_OnTextChanged(selfBox)
    end
    DH:SetSearchText(selfBox:GetText() or "")
    if DH.UI and DH.UI.RefreshLists then
      DH.UI:RefreshLists()
    end
  end)

  local nextLine = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  nextLine:SetPoint("BOTTOM", frame, "BOTTOM", 0, 25)
  nextLine:SetJustifyH("CENTER")
  nextLine:SetText("")

  local leftBox = CreateGroupBox(frame, L.AVAILABLE_ITEMS)
  leftBox:SetPoint("TOPLEFT", 14, -120)
  leftBox:SetPoint("BOTTOMLEFT", 14, 46)
  leftBox:SetPoint("RIGHT", frame, "CENTER", -GAP/2, 0)

  local refresh = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  refresh:SetSize(110, 22)
  refresh:SetPoint("BOTTOMRIGHT", leftBox, "TOPRIGHT", -10, 6)
  refresh:SetText(L.REFRESH)
  refresh:SetScript("OnClick", function() DH:FullRescan() end)
  AddTooltip(refresh, L.REFRESH, L.TIP_REFRESH)
  self.UI.RefreshBtn = refresh


  local rightBox = CreateGroupBox(frame, L.DISENCHANT_QUEUE)
  rightBox:SetPoint("TOPRIGHT", -14, -120)
  rightBox:SetPoint("BOTTOMRIGHT", -14, 46)
  rightBox:SetPoint("LEFT", frame, "CENTER", GAP/2, 0)

  local leftTotal = leftBox:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  leftTotal:SetPoint("BOTTOMLEFT", 12, 10)
  leftTotal:SetJustifyH("LEFT")
  leftTotal:SetText("")

  local rightTotal = rightBox:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  rightTotal:SetPoint("BOTTOMLEFT", 12, 10)
  rightTotal:SetJustifyH("LEFT")
  rightTotal:SetText("")

  local availableList = CreateScrollList(leftBox, function(itemID) DH:MoveOneToQueue(itemID) end, L.TOOLTIP_AVAIL)
  local queueList     = CreateScrollList(rightBox, function(itemID) DH:MoveOneToAvailable(itemID) end, L.TOOLTIP_QUEUE)

  self.UI.MainFrame = frame
  self.UI.AvailableList = availableList
  self.UI.QueueList = queueList
  self.UI.Hint = hint
  self.UI.NextLine = nextLine
  self.UI.LeftTotal = leftTotal
  self.UI.RightTotal = rightTotal

  function self.UI:SetHintText(text)
    hint:SetText(text or "")
  end

  local function UpdateNextLine()
    local entry = DH:GetNextQueueEntry()
    if not entry then
      nextLine:SetText((L.NEXT_ITEM or "Next:") .. " " .. (L.NEXT_ITEM_NONE or "Queue is empty."))
    else
      nextLine:SetText((L.NEXT_ITEM or "Next:") .. " " .. (entry.name or (entry.link or "")))
    end
  end

  local function UpdateTotals()
    local a = DH:GetTotalCount("available")
    local q = DH:GetTotalCount("queue")
    leftTotal:SetText(string.format("%s %d", L.TOTAL or "Total:", a))
    rightTotal:SetText(string.format("%s %d", L.TOTAL or "Total:", q))
  end

  function self.UI:RefreshLists()
    availableList:SetData(DH:GetListData("available"))
    queueList:SetData(DH:GetListData("queue"))
    UpdateNextLine()
    UpdateTotals()

    if DH and DH.IsDisenchanting then
      self:SetCastButtonCasting(true)
      if self.CastBtn then self.CastBtn:Disable() end
    else
      self:SetCastButtonCasting(false)
      if DH and type(DH.UpdateCastButton) == "function" then
        DH:UpdateCastButton(self.CastBtn)
      end
    end

    if self.AutoLootCB then
      self.AutoLootCB:SetChecked(GetAutoLootOn())
    end

    local st = DH and DH.CastStatus
    if st and not st.ok then
      if st.reason == "IN_COMBAT" then
        hint:SetText(L.HINT_IN_COMBAT or "")
      elseif st.reason == "QUEUE_EMPTY" then
        hint:SetText(L.HINT_QUEUE_EMPTY or "")
      elseif st.reason == "SPELL_NOT_KNOWN" then
        hint:SetText(L.HINT_SPELL_NOT_KNOWN or "")
      else
        hint:SetText("")
      end
    else
      hint:SetText("")
    end
  end

  RestoreFramePlacement(frame, DH.DB)
  CreateMinimapButton()
  frame:Hide()
end