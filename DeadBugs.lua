-- DeadBugs: WoW addon that hides Lua/UI errors, restores interface, and logs all error events with multi-language support.
-- Description:
-- • Hides annoying Lua and UI error popups in WoW Classic/MoP.
-- • Automatically restores broken interface elements after errors.
-- • Logs all error events and provides powerful search/filter/statistics commands.
-- • Supports Russian and English languages.
-- • Keeps logs between sessions and auto-cleans old entries.
-- DeadBugs commands:
-- /deadbugs                - show last hidden errors
-- /deadbugs clear          - clear all error logs
-- /deadbugs word           - search errors by word
-- /deadbugs fixed          - only interface restore errors
-- /deadbugs forbidden      - only Blizzard UI block errors
-- /deadbugs all            - all errors without filter
-- /deadbugs stats          - error category statistics
-- /deadbugs last           - last error (type and time)
-- DeadBugs команды:
-- /deadbugs                - показать последние скрытые ошибки
-- /deadbugs clear          - очистить все логи ошибок
-- /deadbugs слово          - поиск по логам ошибок
-- /deadbugs fixed          - только ошибки восстановления интерфейса
-- /deadbugs forbidden      - только ошибки блокировки Blizzard UI
-- /deadbugs all            - все ошибки без фильтрации
-- /deadbugs stats          - статистика по категориям ошибок
-- /deadbugs last           - последняя ошибка (тип и время)
local DeadBugs = {}
DeadBugs.logs = DeadBugsLogs or {}

local MAX_LOG_SIZE = 500
local LOG_MAX_AGE_DAYS = 7

local function AddLog(entry)
    table.insert(DeadBugs.logs, entry)
    if #DeadBugs.logs > MAX_LOG_SIZE then
        table.remove(DeadBugs.logs, 1)
    end
end

local function RemoveOldLogs()
    local now = time()
    local cutoff = now - LOG_MAX_AGE_DAYS * 24 * 60 * 60
    local newLogs = {}
    for _, log in ipairs(DeadBugs.logs) do
        -- log.time может быть в формате "%H:%M:%S" или "%Y-%m-%d %H:%M:%S"
        -- Для совместимости используем дату из SavedVariables, если есть
        if log.timestamp and log.timestamp >= cutoff then
            table.insert(newLogs, log)
        elseif not log.timestamp then
            -- Если timestamp нет, оставляем (старые записи)
            table.insert(newLogs, log)
        end
    end
    DeadBugs.logs = newLogs
end

-- Перехватчик ошибок
seterrorhandler(function(err)
    AddLog({
        time = date("%H:%M:%S"),
        timestamp = time(),
        msg = err
    })
    -- Не показываем стандартное окно ошибки
end)

-- Отключаем стандартное окно ошибок, если оно есть
if ScriptErrorsFrame then
    ScriptErrorsFrame:UnregisterAllEvents()
    ScriptErrorsFrame:Hide()
end

-- Отключаем UIErrorsFrame для Lua ошибок (но не для игровых сообщений)
if UIErrorsFrame then
    hooksecurefunc(UIErrorsFrame, "AddMessage", function(self, msg, ...)
        if type(msg) == "string" and msg:find("Interface\\AddOns") then
            self:Clear()
        end
    end)
end

local function CountErrors()
    local lua, forbidden, fixed = 0, 0, 0
    for _, log in ipairs(DeadBugs.logs) do
        if log.msg:find("RestoreUI error") then
            fixed = fixed + 1
        elseif log.msg:find("ADDON_ACTION_FORBIDDEN") or log.msg:find("ADDON_ACTION_BLOCKED") then
            forbidden = forbidden + 1
        else
            lua = lua + 1
        end
    end
    return lua, forbidden, fixed
end

local function LastError()
    local log = DeadBugs.logs[#DeadBugs.logs]
    if not log then
        print("|cff00ff00DeadBugs:|r Нет ошибок.")
        return
    end
    local errType = "Lua"
    if log.msg:find("RestoreUI error") then
        errType = "RestoreUI"
    elseif log.msg:find("ADDON_ACTION_FORBIDDEN") or log.msg:find("ADDON_ACTION_BLOCKED") then
        errType = "Forbidden/Blocked"
    end
    print(string.format("|cff00ff00DeadBugs:|r Последняя ошибка [%s] %s: %s", log.time, errType,
        log.msg:gsub("\n", " ")))
end

local L = {}
if GetLocale() == "ruRU" then
    L.help = "Справка по командам аддона:"
    L.cmd_deadbugs = "/deadbugs                - показать последние скрытые ошибки"
    L.cmd_clear = "/deadbugs clear          - очистить все логи ошибок"
    L.cmd_word = "/deadbugs слово          - поиск по логам ошибок"
    L.cmd_fixed = "/deadbugs fixed          - только ошибки восстановления интерфейса"
    L.cmd_forbidden = "/deadbugs forbidden      - только ошибки блокировки Blizzard UI"
    L.cmd_all = "/deadbugs all            - все ошибки без фильтрации"
    L.cmd_stats = "/deadbugs stats          - статистика по категориям ошибок"
    L.cmd_last = "/deadbugs last           - последняя ошибка (тип и время)"
    L.cleared = "Выполнена очистка всех логов ошибок."
    L.fixed = "Ошибки восстановления интерфейса:"
    L.fixed_none = "Нет ошибок, которые пытался устранить аддон."
    L.forbidden = "Ошибки блокировки Blizzard UI:"
    L.forbidden_none = "Нет ошибок типа ADDON_ACTION_FORBIDDEN/BLOCKED."
    L.all = "Все ошибки за сессию:"
    L.none = "Нет ошибок."
    L.stats = "Статистика по категориям ошибок:"
    L.last = "Последняя ошибка:"
    L.search = "Поиск по логам ошибок по запросу: '%s'"
    L.search_none = "Нет ошибок по запросу '%s'"
    L.latest = "Последние скрытые ошибки:"
    L.no_hidden = "Нет скрытых ошибок."
else
    L.help = "DeadBugs command help:"
    L.cmd_deadbugs = "/deadbugs                - show last hidden errors"
    L.cmd_clear = "/deadbugs clear          - clear all error logs"
    L.cmd_word = "/deadbugs word           - search errors by word"
    L.cmd_fixed = "/deadbugs fixed          - only interface restore errors"
    L.cmd_forbidden = "/deadbugs forbidden      - only Blizzard UI block errors"
    L.cmd_all = "/deadbugs all            - all errors without filter"
    L.cmd_stats = "/deadbugs stats          - error category statistics"
    L.cmd_last = "/deadbugs last           - last error (type and time)"
    L.cleared = "All error logs cleared."
    L.fixed = "Interface restore errors:"
    L.fixed_none = "No errors attempted to fix by addon."
    L.forbidden = "Blizzard UI block errors:"
    L.forbidden_none = "No ADDON_ACTION_FORBIDDEN/BLOCKED errors."
    L.all = "All errors this session:"
    L.none = "No errors."
    L.stats = "Error category statistics:"
    L.last = "Last error:"
    L.search = "Searching error logs for: '%s'"
    L.search_none = "No errors found for '%s'"
    L.latest = "Last hidden errors:"
    L.no_hidden = "No hidden errors."
end

-- Команда для просмотра логов
SLASH_DEADBUGS1 = "/deadbugs"
SlashCmdList["DEADBUGS"] = function(msg)
    msg = (msg and msg:trim():lower()) or ""
    RemoveOldLogs()
    if msg == "help" or msg == "?" then
        print("|cff00ff00DeadBugs:|r " .. L.help)
        print("|cffffff00" .. L.cmd_deadbugs .. "|r")
        print("|cffffff00" .. L.cmd_clear .. "|r")
        print("|cffffff00" .. L.cmd_word .. "|r")
        print("|cffffff00" .. L.cmd_fixed .. "|r")
        print("|cffffff00" .. L.cmd_forbidden .. "|r")
        print("|cffffff00" .. L.cmd_all .. "|r")
        print("|cffffff00" .. L.cmd_stats .. "|r")
        print("|cffffff00" .. L.cmd_last .. "|r")
        return
    elseif msg == "clear" then
        print("|cff00ff00DeadBugs:|r " .. L.cleared)
        DeadBugs.logs = {}
        DeadBugsLogs = {}
        return
    elseif msg == "fixed" then
        print("|cff00ff00DeadBugs:|r " .. L.fixed)
        local found = 0
        for i, log in ipairs(DeadBugs.logs) do
            if log.msg:find("RestoreUI error") then
                print(string.format("[%s] %s", log.time, log.msg:gsub("\n", " ")))
                found = found + 1
            end
        end
        if found == 0 then
            print("|cff00ff00DeadBugs:|r " .. L.fixed_none)
        end
        return
    elseif msg == "forbidden" then
        print("|cff00ff00DeadBugs:|r " .. L.forbidden)
        local found = 0
        for i, log in ipairs(DeadBugs.logs) do
            if log.msg:find("ADDON_ACTION_FORBIDDEN") or log.msg:find("ADDON_ACTION_BLOCKED") then
                print(string.format("[%s] %s", log.time, log.msg:gsub("\n", " ")))
                found = found + 1
            end
        end
        if found == 0 then
            print("|cff00ff00DeadBugs:|r " .. L.forbidden_none)
        end
        return
    elseif msg == "all" then
        print("|cff00ff00DeadBugs:|r " .. L.all)
        if #DeadBugs.logs == 0 then
            print("|cff00ff00DeadBugs:|r " .. L.none)
            return
        end
        for i, log in ipairs(DeadBugs.logs) do
            print(string.format("[%s] %s", log.time, log.msg:gsub("\n", " ")))
        end
        return
    elseif msg == "stats" then
        print("|cff00ff00DeadBugs:|r " .. L.stats)
        local lua, forbidden, fixed = CountErrors()
        print("Lua: " .. lua)
        print("Forbidden/Blocked: " .. forbidden)
        print("RestoreUI: " .. fixed)
        print("Total: " .. #DeadBugs.logs)
        return
    elseif msg == "last" then
        print("|cff00ff00DeadBugs:|r " .. L.last)
        LastError()
        return
    elseif msg ~= "" then
        print("|cff00ff00DeadBugs:|r " .. string.format(L.search, msg))
        local found = 0
        for i, log in ipairs(DeadBugs.logs) do
            if log.msg:lower():find(msg:lower(), 1, true) then
                print(string.format("[%s] %s", log.time, log.msg:gsub("\n", " ")))
                found = found + 1
            end
        end
        if found == 0 then
            print("|cff00ff00DeadBugs:|r " .. string.format(L.search_none, msg))
        end
        return
    end
    print("|cff00ff00DeadBugs:|r " .. L.latest)
    if #DeadBugs.logs == 0 then
        print("|cff00ff00DeadBugs:|r " .. L.no_hidden)
        return
    end
    for i, log in ipairs(DeadBugs.logs) do
        print(string.format("[%s] %s", log.time, log.msg:gsub("\n", " ")))
    end
end

-- Сохраняем логи между сессиями
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGOUT")
f:SetScript("OnEvent", function()
    DeadBugsLogs = DeadBugs.logs
end)

-- Автоматическое восстановление основных UI-элементов
local function SafeCall(func, ...)
    local ok, err = pcall(func, ...)
    if not ok then
        table.insert(DeadBugs.logs, {
            time = date("%H:%M:%S"),
            msg = "RestoreUI error: " .. tostring(err)
        })
    end
end

local function RestoreUI()
    local frames = {"PlayerFrame", "TargetFrame", "MinimapCluster", "MainMenuBar", "ChatFrame1"}
    for _, name in ipairs(frames) do
        local f = _G[name]
        if f and type(f.IsForbidden) ~= "function" then
            SafeCall(function()
                if f.Show and not f:IsShown() then
                    f:Show()
                end
                if f.EnableMouse and not f:IsMouseEnabled() then
                    f:EnableMouse(true)
                end
            end)
        end
    end
end

local restoreTicker = C_Timer.NewTicker(10, RestoreUI) -- Проверять реже, каждые 10 секунд

-- Логирование системных ошибок типа ADDON_ACTION_FORBIDDEN
local forbiddenEvents = {"ADDON_ACTION_FORBIDDEN", "ADDON_ACTION_BLOCKED"}
local forbiddenFrame = CreateFrame("Frame")
forbiddenFrame:RegisterEvent("ADDON_ACTION_FORBIDDEN")
forbiddenFrame:RegisterEvent("ADDON_ACTION_BLOCKED")
forbiddenFrame:SetScript("OnEvent", function(self, event, addon, func)
    table.insert(DeadBugs.logs, {
        time = date("%H:%M:%S"),
        msg = string.format(
            "[%s] Модификация '%s' пыталась вызвать защищённую функцию '%s'.",
            event, addon or "?", func or "?")
    })
end)

-- Попытка скрыть стандартное окно ошибок Blizzard (Blizzard_Forbidden addon)
local blizzardForbidden = _G["StaticPopupDialogs"]["ADDON_ACTION_FORBIDDEN"]
if blizzardForbidden then
    blizzardForbidden.OnAccept = function()
    end
    blizzardForbidden.OnCancel = function()
    end
end

local forbiddenPopupFrame = _G["StaticPopup1"]
if forbiddenPopupFrame and forbiddenPopupFrame:IsShown() then
    forbiddenPopupFrame:Hide()
end

-- Changelog:
-- v1.0
-- - Initial release: hides Lua/UI errors, restores interface, logs errors.
-- - Added commands for log viewing, searching, filtering, and statistics.
-- - Multi-language support (English/Russian).
-- - Log size and age limits, auto-cleaning old entries.
-- - SavedVariables support for persistent logs.
-- - UI error popup suppression and automatic interface recovery.
