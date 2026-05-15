local addonName, DH = ...
local L = DH.L or {}

if GetLocale() ~= "ruRU" then return end

L.ADDON_TITLE        = "DisenchantHelper"
L.AVAILABLE_ITEMS    = "Доступные предметы"
L.DISENCHANT_QUEUE   = "Очередь распыления"

L.QUALITY_COMMON     = "Обычное"
L.QUALITY_UNCOMMON   = "Необычное"
L.QUALITY_RARE       = "Редкое"
L.QUALITY_EPIC       = "Эпическое"

L.MOVE_ALL           = "перенести всё"
L.REFRESH            = "обновить"
L.CLEAR              = "очистить"

L.SEARCH             = "Поиск..."
L.CAST_DISENCHANT    = "Распылить"

L.TOOLTIP_AVAIL      = "ЛКМ: перенести 1 предмет в очередь"
L.TOOLTIP_QUEUE      = "ЛКМ: убрать 1 предмет из очереди"
L.NO_FILTERS         = "Выберите хотя бы одно качество для отображения."
L.NEXT_ITEM          = "Следующий:"
L.NEXT_ITEM_NONE     = "Очередь пуста."

L.TIP_FILTER_COMMON   = "Отображать предметы качества Common"
L.TIP_FILTER_UNCOMMON = "Отображать предметы качества Uncommon"
L.TIP_FILTER_RARE     = "Отображать предметы качества Rare"
L.TIP_FILTER_EPIC     = "Отображать предметы качества Epic"

L.TIP_MOVE_ALL        = "Переместить все предметы в очередь на распыление"
L.TIP_REFRESH         = "Пересканировать сумки и обновить списки"
L.TIP_CLEAR           = "Удалить все предметы из очереди на распыление"
L.TIP_CAST            = "Распылить предмет из очереди"
L.TIP_MINIMAP         = "ЛКМ: открыть/закрыть окно\nПКМ: перетащить\nShift+ЛКМ: сбросить позицию"

L.TOTAL = "Всего:"

L.RESET_POS = "Сброс позиции"
L.TIP_RESET_POS = "Сбросить позицию окна в центр и установить минимальный размер"

L.AUTOLOOT = "Автосборщик"
L.TIP_AUTOLOOT = "Включить встроенный авто-сбор предметов, чтобы отключить появление окна добычи."

L.HINT_IN_COMBAT = "Недоступно в бою."
L.HINT_QUEUE_EMPTY = "Очередь пуста."
L.HINT_SPELL_NOT_KNOWN = "Распыление не изучено."

L.TIP_IN_COMBAT = "Недоступно в бою."
L.TIP_QUEUE_EMPTY = "Очередь пуста."
L.TIP_NO_ITEMID = "Не удалось определить ID предмета."
L.TIP_SPELL_NOT_KNOWN = "Распыление не изучено."
L.TIP_SPELL_NAME_NIL = "Не удалось получить имя заклинания."

L.CAST_DISENCHANTING = "Распыление..."