local addonName, DH = ...

DH.L = DH.L or {}
local L = DH.L

L.ADDON_TITLE        = "DisenchantHelper"
L.AVAILABLE_ITEMS    = "Available items"
L.DISENCHANT_QUEUE   = "Disenchant queue"

L.QUALITY_COMMON     = "Common"
L.QUALITY_UNCOMMON   = "Uncommon"
L.QUALITY_RARE       = "Rare"
L.QUALITY_EPIC       = "Epic"

L.MOVE_ALL           = "Move all"
L.REFRESH            = "Refresh"
L.CLEAR              = "Clear"

L.TOOLTIP_AVAIL      = "Left click: move 1 item to queue"
L.TOOLTIP_QUEUE      = "Left click: remove 1 item from queue"
L.NO_FILTERS         = "Select at least one quality to show items."

L.SEARCH          = "Search..."
L.CAST_DISENCHANT = "Cast Disenchant"
L.NEXT_ITEM       = "Next:"
L.NEXT_ITEM_NONE  = "Queue is empty."

L.TIP_FILTER_COMMON   = "Show Common quality items"
L.TIP_FILTER_UNCOMMON = "Show Uncommon quality items"
L.TIP_FILTER_RARE     = "Show Rare quality items"
L.TIP_FILTER_EPIC     = "Show Epic quality items"

L.TIP_MOVE_ALL        = "Move all items to disenchant queue"
L.TIP_REFRESH         = "Rescan bags and refresh lists"
L.TIP_CLEAR           = "Remove all items from disenchant queue"
L.TIP_CAST            = "Cast Disenchant"
L.TIP_MINIMAP         = "Left click: toggle window\nRight click: drag\nShift + LMB: reset position"

L.TOTAL = "Total:"

L.RESET_POS = "Reset position"
L.TIP_RESET_POS = "Reset window position to center and size to minimum"

L.AUTOLOOT = "AutoLoot"
L.TIP_AUTOLOOT = "Enable built-in auto-looting to disable the loot window from appearing."

L.HINT_IN_COMBAT = "Unavailable in combat."
L.HINT_QUEUE_EMPTY = "Queue is empty."
L.HINT_SPELL_NOT_KNOWN = "Disenchant is not known."

L.TIP_IN_COMBAT = "Unavailable in combat."
L.TIP_QUEUE_EMPTY = "Queue is empty."
L.TIP_NO_ITEMID = "Item ID not found."
L.TIP_SPELL_NOT_KNOWN = "Disenchant is not known."
L.TIP_SPELL_NAME_NIL = "Unable to resolve spell name."

L.CAST_DISENCHANTING = "Disenchanting..."