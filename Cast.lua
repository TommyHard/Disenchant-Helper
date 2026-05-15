local addonName, DH = ...
local L = DH.L

local DISENCHANT_SPELL_ID = 13262

local function GetSpellNameStable(spellID)
  if C_Spell and type(C_Spell.GetSpellInfo) == "function" then
    local info = C_Spell.GetSpellInfo(spellID)
    if info and info.name and info.name ~= "" then
      return info.name
    end
  end
  if type(GetSpellInfo) == "function" then
    local name = GetSpellInfo(spellID)
    if name and name ~= "" then return name end
  end
  return nil
end

local function IsDisenchantKnown()
  if type(IsPlayerSpell) == "function" and IsPlayerSpell(DISENCHANT_SPELL_ID) then
    return true
  end
  if type(IsSpellKnown) == "function" and IsSpellKnown(DISENCHANT_SPELL_ID) then
    return true
  end
  if C_SpellBook and type(C_SpellBook.IsSpellKnown) == "function" and C_SpellBook.IsSpellKnown(DISENCHANT_SPELL_ID) then
    return true
  end
  return false
end

local function SetMacro(btn, macro)
  btn:SetAttribute("type", "macro")
  btn:SetAttribute("macrotext", macro)
  btn:SetAttribute("type1", "macro")
  btn:SetAttribute("macrotext1", macro)
end

local function SetSafeDisabled(btn)
  SetMacro(btn, "/stopmacro")
  btn:SetAttribute("dh_itemid", nil)
  btn:SetAttribute("dh_bag", nil)
  btn:SetAttribute("dh_slot", nil)
  btn:Disable()
end

function DH:UpdateCastButton(btn)
  if not btn then return end

  if self.IsDisenchanting then
    self.CastStatus = { ok = false, reason = "CASTING" }
    SetSafeDisabled(btn)
    return
  end

  if InCombatLockdown and InCombatLockdown() then
    self.CastStatus = { ok = false, reason = "IN_COMBAT" }
    SetSafeDisabled(btn)
    return
  end

  local bag, slot, entry = self:GetNextQueueLocation()
  if not entry then
    self.CastStatus = { ok = false, reason = "QUEUE_EMPTY" }
    SetSafeDisabled(btn)
    return
  end

  local itemID = tonumber(entry.itemID) or tonumber(entry.key)
  if not itemID then
    self.CastStatus = {
      ok = false,
      reason = "NO_ITEMID",
      entryKey = entry.key,
      entryName = entry.name,
      entryLink = entry.link,
    }
    SetSafeDisabled(btn)
    return
  end

  if not IsDisenchantKnown() then
    self.CastStatus = {
      ok = false,
      reason = "SPELL_NOT_KNOWN",
      itemID = itemID,
      entryKey = entry.key,
      entryName = entry.name,
      entryLink = entry.link,
    }
    SetSafeDisabled(btn)
    return
  end

  local spellName = GetSpellNameStable(DISENCHANT_SPELL_ID)
  if not spellName or spellName == "" then
    self.CastStatus = {
      ok = false,
      reason = "SPELL_NAME_NIL",
      itemID = itemID,
      entryKey = entry.key,
      entryName = entry.name,
      entryLink = entry.link,
    }
    SetSafeDisabled(btn)
    return
  end

  btn:SetAttribute("dh_itemid", itemID)
  btn:SetAttribute("dh_bag", tonumber(bag))
  btn:SetAttribute("dh_slot", tonumber(slot))

  local macro
  local nb = tonumber(bag)
  local ns = tonumber(slot)
  if nb and ns then
    macro = string.format("/cast %s\n/use %d %d", spellName, nb, ns)
  else
    macro = string.format("/cast %s\n/use item:%d", spellName, itemID)
  end

  SetMacro(btn, macro)
  btn:Enable()

  self.CastStatus = {
    ok = true,
    reason = "OK",
    macro = macro,
    spellName = spellName,
    itemID = itemID,
    entryKey = entry.key,
    entryName = entry.name,
    entryLink = entry.link,
    bag = nb,
    slot = ns,
  }
end