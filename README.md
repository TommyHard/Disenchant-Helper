# Disenchant Helper

> A structured and efficient World of Warcraft add-on designed to optimize the routine process of disenchanting items. It introduces a dedicated queue system, allowing enchanters to filter, select, and process gear systematically without manually searching through bags.

---

## Core Features

### 1. Interactive Queue Management
The add-on features a dual-pane interface separating "Available Items" and the "Disenchant Queue". 
* **Item Allocation:** Move items from your bags to the queue individually or in bulk using the `Move all` function.
* **Persistent State:** The queue state and wanted item counts are saved across sessions in the `DisenchantHelperDB`.
* **Bag Scanning:** Automatically scans base bags and the reagent bag for equippable, disenchantable items.

### 2. Advanced Filtering & Search
Quickly isolate specific gear to prevent accidental disenchantment of valuable items.
* **Quality Filters:** Toggle visibility for **Common**, **Uncommon**, **Rare**, and **Epic** item qualities.
* **Text Search:** A built-in search bar allows filtering by item name or hyperlink.
* **Item Level Display:** Displays the item level (ilvl) directly within the list rows for better decision-making.

### 3. Secure One-Click Processing
Streamlines the actual disenchanting action into a single, secure button.
* **Macro Generation:** Dynamically generates a secure `/cast Disenchant \n /use <bag> <slot>` macro for the next item in the queue.
* **Combat Safety:** Automatically disables the cast button while in combat (`InCombatLockdown`) to prevent UI taint and Lua errors.
* **Event Tracking:** Listens to `UNIT_SPELLCAST_*` events to accurately track successful disenchantments, automatically removing processed items from the queue and updating the UI.

### 4. Quality of Life Utilities
* **AutoLoot Integration:** A built-in toggle for the game's default `autoLootDefault` CVar, suppressing the loot window for faster processing.
* **Minimap Integration:** Includes a minimap button for quick access (powered by `LibDBIcon-1.0` and `LibDataBroker-1.1`), with support for dragging and Addon Compartment integration.
* **Customizable UI:** The main window is movable, resizable, and remembers its position on the screen.

---

## Usage & Commands

| Command / Action | Description |
| :--- | :--- |
| `/dh` | Toggles the main Disenchant Helper interface. |
| **Left-Click (Minimap)** | Opens or closes the add-on window. |
| **Shift + Left-Click (Minimap)** | Resets the add-on window to its default center position and minimum size. |

---

## Technical Information

| Specification | Details |
| :--- | :--- |
| **Game Client** | World of Warcraft |
| **Expansion** | Midnight |
| **Version** | `12.0` - `12.05` |
| **Dependency** | None (Embedded libraries: `LibStub`, `CallbackHandler-1.0`, `LibDataBroker-1.1`, `LibDBIcon-1.0`) |

---

## Installation

1. Download the latest release.
2. Extract the `DisenchantHelper` folder into your World of Warcraft AddOns directory:
   > `World of Warcraft/_retail_/Interface/AddOns/`
3. Launch the game and ensure the add-on is enabled in the character selection screen.