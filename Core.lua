local addonName, DH = ...

DH.DB = nil
DH.L = DH.L or setmetatable({}, { __index = function(_, k) return k end })

local DISENCHANT_SPELL_ID = 13262

DH.Events = CreateFrame("Frame")
DH.Events:RegisterEvent("PLAYER_LOGIN")
DH.Events:RegisterEvent("BAG_UPDATE_DELAYED")

DH.Events:RegisterEvent("UNIT_SPELLCAST_START")
DH.Events:RegisterEvent("UNIT_SPELLCAST_STOP")
DH.Events:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
DH.Events:RegisterEvent("UNIT_SPELLCAST_FAILED")
DH.Events:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")

SLASH_DISENCHANTHELPER1 = "/dh"
SlashCmdList["DISENCHANTHELPER"] = function()
  if DH.UI and DH.UI.MainFrame then
    local show = not DH.UI.MainFrame:IsShown()
  if show then DH:FullRescan() end
  DH.UI.MainFrame:SetShown(show)
  end
end

local function DefaultDB()
  return {
    frame = { w = 860, h = 520, point = "CENTER", x = 0, y = 0 },
    filters = {
      [Enum.ItemQuality.Common]   = false,
      [Enum.ItemQuality.Uncommon] = false,
      [Enum.ItemQuality.Rare]     = false,
      [Enum.ItemQuality.Epic]     = false,
    },
    search = "",
    queueWanted = {},
    minimap = { hide = false, angle = 220 },
  }
end

function DH:EnsureDB()
  DisenchantHelperDB = DisenchantHelperDB or DefaultDB()

  local db = DisenchantHelperDB
  local def = DefaultDB()

  db.frame = db.frame or def.frame
  db.filters = db.filters or def.filters
  db.search = db.search or def.search
  db.queueWanted = db.queueWanted or def.queueWanted
  db.minimap = db.minimap or def.minimap

  for k, v in pairs(def.filters) do
    if db.filters[k] == nil then db.filters[k] = v end
  end

  if db.minimap.hide == nil then db.minimap.hide = def.minimap.hide end
  if db.minimap.angle == nil then db.minimap.angle = def.minimap.angle end

  self.DB = db
end

DH._rescanTimer = nil
function DH:RequestRescan(delay)
  delay = delay or 0.10
  if self._rescanTimer and self._rescanTimer.Cancel then
    self._rescanTimer:Cancel()
  end
  self._rescanTimer = C_Timer.NewTimer(delay, function()
    DH._rescanTimer = nil
    DH:FullRescan()
  end)
end

function DH:SetDisenchantIndicator(on)
  if DH.UI and type(DH.UI.SetDisenchantIndicator) == "function" then
    DH.UI:SetDisenchantIndicator(on and true or false)
  end
end

function DH:SetDisenchantLock(on)
  self.IsDisenchanting = on and true or false

  if self.UI and self.UI.SetCastButtonCasting then
    self.UI:SetCastButtonCasting(self.IsDisenchanting)
  end

  if self.UI and self.UI.CastBtn then
    if self.IsDisenchanting then
      self.UI.CastBtn:Disable()
    else
      self:UpdateCastButton(self.UI.CastBtn)
    end
  end

  if self.UI and type(self.UI.RefreshLists) == "function" then
    self.UI:RefreshLists()
  end
end

function DH:OnDisenchantSucceeded()
  local st = self.CastStatus
  local itemID = st and tonumber(st.itemID)
  local bag = st and tonumber(st.bag)
  local slot = st and tonumber(st.slot)

  if itemID then
    if type(self.AdjustQueueWanted) == "function" then
      self:AdjustQueueWanted(itemID, -1)
    elseif self.DB and self.DB.queueWanted then
      local cur = tonumber(self.DB.queueWanted[itemID]) or 0
      cur = cur - 1
      if cur <= 0 then self.DB.queueWanted[itemID] = nil else self.DB.queueWanted[itemID] = cur end
      self.QueueWanted = self.DB.queueWanted
    end
  end

  if itemID and bag and slot and self.State and self.State.queue then
    local g = self.State.queue[itemID]
    if g and g.locations then
      for idx = #g.locations, 1, -1 do
        local loc = g.locations[idx]
        if loc and loc.bag == bag and loc.slot == slot then
          table.remove(g.locations, idx)
          break
        end
      end
      if #g.locations == 0 then
        g.wanted = (self.QueueWanted and self.QueueWanted[itemID]) or g.wanted
      end
    end
  end

  if self.UI and self.UI.RefreshLists then
    self.UI:RefreshLists()
  end
end

DH.Events:SetScript("OnEvent", function(_, event, ...)
  if event == "PLAYER_LOGIN" then
    DH:EnsureDB()
    DH:InitState()
    DH:ApplyDBToState()
    DH:CreateUI()
    DH.IsDisenchanting = false
    DH.BagsDirty = false
    DH:FullRescan()

  elseif event == "BAG_UPDATE_DELAYED" then
    DH.BagsDirty = true

  elseif event == "UNIT_SPELLCAST_START" then
    local unit, _, spellID = ...
    if unit == "player" and spellID == DISENCHANT_SPELL_ID then
      DH:SetDisenchantIndicator(true)
      DH:SetDisenchantLock(true)
    end

  elseif event == "UNIT_SPELLCAST_STOP" then
    local unit, _, spellID = ...
    if unit == "player" and spellID == DISENCHANT_SPELL_ID then
      DH:SetDisenchantIndicator(false)
      DH:SetDisenchantLock(false)
    end

  elseif event == "UNIT_SPELLCAST_FAILED" then
    local unit, _, spellID = ...
    if unit == "player" and spellID == DISENCHANT_SPELL_ID then
      DH:SetDisenchantIndicator(false)
      DH:SetDisenchantLock(false)
    end

  elseif event == "UNIT_SPELLCAST_INTERRUPTED" then
    local unit, _, spellID = ...
    if unit == "player" and spellID == DISENCHANT_SPELL_ID then
      DH:SetDisenchantIndicator(false)
      DH:SetDisenchantLock(false)
    end

  elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
    local unit, _, spellID = ...
    if unit == "player" and spellID == DISENCHANT_SPELL_ID then
      DH:SetDisenchantIndicator(false)
      DH:SetDisenchantLock(false)
      DH:OnDisenchantSucceeded()
    end
  end
end)
