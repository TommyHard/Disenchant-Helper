local addonName, DH = ...
local L = DH.L

local function UISetHint(text)
  if DH.UI and type(DH.UI.SetHintText) == "function" then
    DH.UI:SetHintText(text)
  end
end

local function UIRefresh()
  if DH.UI and type(DH.UI.RefreshLists) == "function" then
    DH.UI:RefreshLists()
  end
end

local function GetScanBagIDs()
  local bags = {0, 1, 2, 3, 4}
  if Enum and Enum.BagIndex and Enum.BagIndex.ReagentBag then
    table.insert(bags, Enum.BagIndex.ReagentBag)
  end
  return bags
end

local function IsQualityAllowed(quality, filters)
  if not quality then return false end
  return filters[quality] == true
end

local function IsLikelyDisenchantable(itemLink, itemInfo)
  if not itemLink or not itemInfo then return false end
  if C_Item and C_Item.IsEquippableItem then
    return C_Item.IsEquippableItem(itemLink)
  end
  return IsEquippableItem and IsEquippableItem(itemLink)
end

local function EnsureGroup(map, itemID, icon, name, quality, link)
  local g = map[itemID]
  if not g then
    g = {
      itemID = itemID,
      icon = icon,
      name = name,
      quality = quality,
      link = link,
      locations = {},
    }
    map[itemID] = g
  else
    if not g.link and link then g.link = link end
    if not g.name and name then g.name = name end
    if not g.icon and icon then g.icon = icon end
    if not g.quality and quality then g.quality = quality end
  end
  return g
end

local function AddLocation(group, bag, slot)
  table.insert(group.locations, { bag = bag, slot = slot })
end

local function RemoveOneLocation(group)
  return table.remove(group.locations)
end

local function CleanupEmpty(map, key)
  local g = map[key]
  if g and #g.locations == 0 then
    map[key] = nil
  end
end

function DH:InitState()
  self.State = self.State or {}
  self.State.available = {}
  self.State.queue     = {}
  self.Filters = self.Filters or {}
end

function DH:ApplyDBToState()
  if not self.DB then return end

  wipe(self.Filters)
  for q, v in pairs(self.DB.filters or {}) do
    self.Filters[q] = v and true or false
  end

  self.SearchText = self.DB.search or ""

  self.DB.queueWanted = self.DB.queueWanted or {}
  local normalized = {}
  for k, v in pairs(self.DB.queueWanted) do
    local itemID = tonumber(k)
    local n = tonumber(v) or 0
    if itemID and n > 0 then
      normalized[itemID] = n
    end
  end
  wipe(self.DB.queueWanted)
  for itemID, n in pairs(normalized) do
    self.DB.queueWanted[itemID] = n
  end

  self.QueueWanted = self.DB.queueWanted
end

function DH:SetQualityFilter(quality, enabled)
  self.Filters[quality] = enabled and true or false
  if self.DB and self.DB.filters then
    self.DB.filters[quality] = enabled and true or false
  end
end

function DH:SetSearchText(text)
  self.SearchText = text or ""
  if self.DB then
    self.DB.search = self.SearchText
  end
end

function DH:NoFiltersSelected()
  for _, v in pairs(self.Filters) do
    if v then return false end
  end
  return true
end

function DH:SyncQueueWantedFromState()
  if not self.DB then return end
  self.DB.queueWanted = self.DB.queueWanted or {}
  wipe(self.DB.queueWanted)

  for itemID, g in pairs(self.State.queue) do
    local c = #g.locations
    if c and c > 0 then
      self.DB.queueWanted[itemID] = c
    end
  end

  self.QueueWanted = self.DB.queueWanted
end

function DH:ApplyQueueWantedToState()
  local wantedMap = self.QueueWanted
  if not wantedMap then return end

  for itemID, wanted in pairs(wantedMap) do
    wanted = tonumber(wanted) or 0
    if wanted > 0 then
      local ag = self.State.available[itemID]
      if ag and #ag.locations > 0 then
        local moveCount = math.min(wanted, #ag.locations)
        local qg = EnsureGroup(self.State.queue, itemID, ag.icon, ag.name, ag.quality, ag.link)

        for _ = 1, moveCount do
          local loc = RemoveOneLocation(ag)
          if loc then
            AddLocation(qg, loc.bag, loc.slot)
          end
        end

        CleanupEmpty(self.State.available, itemID)
      end
    end
  end
end

function DH:FullRescan()
  if not self.State then return end

  wipe(self.State.available)
  wipe(self.State.queue)

  if self:NoFiltersSelected() then
    UISetHint(L.NO_FILTERS)
    UIRefresh()
    return
  else
    UISetHint("")
  end

  for _, bag in ipairs(GetScanBagIDs()) do
    local numSlots = C_Container.GetContainerNumSlots(bag)
    if numSlots and numSlots > 0 then
      for slot = 1, numSlots do
        local info = C_Container.GetContainerItemInfo(bag, slot)
        if info and info.itemID then
          local itemID = info.itemID
          local link = C_Container.GetContainerItemLink(bag, slot)

          if link
            and IsQualityAllowed(info.quality, self.Filters)
            and IsLikelyDisenchantable(link, info)
          then
            local name = info.hyperlink or link
            local icon = info.iconFileID
            local g = EnsureGroup(self.State.available, itemID, icon, name, info.quality, link)
            AddLocation(g, bag, slot)
          end
        end
      end
    end
  end

  self:ApplyQueueWantedToState()
  self:SyncQueueWantedFromState()
  UIRefresh()
end

function DH:MoveOneToQueue(itemID)
  local ag = self.State.available[itemID]
  if not ag or #ag.locations == 0 then return end

  local loc = RemoveOneLocation(ag)
  CleanupEmpty(self.State.available, itemID)

  local qg = EnsureGroup(self.State.queue, itemID, ag.icon, ag.name, ag.quality, ag.link)
  AddLocation(qg, loc.bag, loc.slot)

  self:SyncQueueWantedFromState()
  UIRefresh()
end

function DH:MoveOneToAvailable(itemID)
  local qg = self.State.queue[itemID]
  if not qg or #qg.locations == 0 then return end

  local loc = RemoveOneLocation(qg)
  CleanupEmpty(self.State.queue, itemID)

  local ag = EnsureGroup(self.State.available, itemID, qg.icon, qg.name, qg.quality, qg.link)
  AddLocation(ag, loc.bag, loc.slot)

  self:SyncQueueWantedFromState()
  UIRefresh()
end

function DH:MoveAllToQueue()
  for itemID, ag in pairs(self.State.available) do
    local qg = EnsureGroup(self.State.queue, itemID, ag.icon, ag.name, ag.quality, ag.link)
    for _, loc in ipairs(ag.locations) do
      AddLocation(qg, loc.bag, loc.slot)
    end
  end
  wipe(self.State.available)

  self:SyncQueueWantedFromState()
  UIRefresh()
end

function DH:ClearQueue()
  for itemID, qg in pairs(self.State.queue) do
    local ag = EnsureGroup(self.State.available, itemID, qg.icon, qg.name, qg.quality, qg.link)
    for _, loc in ipairs(qg.locations) do
      AddLocation(ag, loc.bag, loc.slot)
    end
  end
  wipe(self.State.queue)

  self:SyncQueueWantedFromState()
  UIRefresh()
end

function DH:GetTotalCount(which)
  local map = (which == "available") and self.State.available or self.State.queue
  local total = 0
  for _, g in pairs(map) do
    total = total + (#g.locations or 0)
  end
  return total
end

local function GetIlvl(link)
  if not link then return nil end
  if C_Item and C_Item.GetDetailedItemLevelInfo then
    return C_Item.GetDetailedItemLevelInfo(link)
  end
  if GetDetailedItemLevelInfo then
    return GetDetailedItemLevelInfo(link)
  end
  return nil
end

local function PassSearch(nameOrLink, searchText)
  if not searchText or searchText == "" then return true end
  local s = string.lower(searchText)
  local t = string.lower(tostring(nameOrLink or ""))
  return t:find(s, 1, true) ~= nil
end

function DH:GetListData(which)
  local out = {}
  local search = self.SearchText or ""

  if which == "available" then
    local map = self.State.available
    for itemID, g in pairs(map) do
      local name = g.name or (g.link or tostring(itemID))
      if PassSearch(name, search) or PassSearch(g.link, search) then
        table.insert(out, {
          key = itemID,
          itemID = itemID,
          name = name,
          icon = g.icon,
          count = #g.locations,
          quality = g.quality,
          link = g.link,
          ilvl = GetIlvl(g.link),
        })
      end
    end
  else
    local wantedMap = self.QueueWanted or (self.DB and self.DB.queueWanted) or {}

    for itemID, wanted in pairs(wantedMap) do
      wanted = tonumber(wanted) or 0
      if wanted > 0 then
        local g = self.State.queue and self.State.queue[itemID]
        local name = (g and g.name) or (g and g.link) or tostring(itemID)
        local link = g and g.link or nil
        if PassSearch(name, search) or PassSearch(link, search) then
          table.insert(out, {
            key = itemID,
            itemID = itemID,
            name = name,
            icon = g and g.icon or nil,
            count = wanted,
            quality = g and g.quality or nil,
            link = link,
            ilvl = GetIlvl(link),
          })
        end
      end
    end
  end

  table.sort(out, function(a, b)
    if a.quality ~= b.quality then
      return (a.quality or 0) > (b.quality or 0)
    end
    return tostring(a.name) < tostring(b.name)
  end)

  return out
end

function DH:GetNextQueueEntry()
  local data = self:GetListData("queue")
  return data[1]
end

function DH:GetNextQueueLocation()
  local pruned = false
  local guard = 0

  while true do
    guard = guard + 1
    if guard > 500 then return nil end

    local entry = self:GetNextQueueEntry()
    if not entry then
      if pruned then UIRefresh() end
      return nil
    end

    local itemID = tonumber(entry.itemID)
    local g = itemID and self.State.queue and self.State.queue[itemID]

    if g and g.locations and #g.locations > 0 then
      local loc = g.locations[#g.locations]
      if pruned then UIRefresh() end
      return loc.bag, loc.slot, entry
    end

    if itemID and type(self.AdjustQueueWanted) == "function" then
      self:AdjustQueueWanted(itemID, -1)
      pruned = true
    else
      self.DB.queueWanted = self.DB.queueWanted or {}
      local cur = tonumber(self.DB.queueWanted[itemID]) or 0
      cur = cur - 1
      if cur <= 0 then self.DB.queueWanted[itemID] = nil else self.DB.queueWanted[itemID] = cur end
      self.QueueWanted = self.DB.queueWanted
      pruned = true
    end
  end
end