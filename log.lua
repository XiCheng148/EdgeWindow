local log = {}

local fs = require("hs.fs")
local json = require("hs.json")

-- 日志文件路径
local LOG_FILE = os.getenv("HOME") .. "/.hammerspoon/logs/app.log"
local LOG_DIR = os.getenv("HOME") .. "/.hammerspoon/logs/"
-- 添加保存路径常量
local WINDOWS_JSON_PATH = os.getenv("HOME") .. "/.hammerspoon/logs/windows.json"

-- 日志级别
local LOG_LEVELS = {
    ACTION = "[Action]",
    INFO = "[Info]",
    ERROR = "[Error]"
}

-- 最大日志文件大小 (1MB)
local MAX_LOG_SIZE = 1024 * 1024

-- 确保日志目录存在
if not fs.mkdir(LOG_DIR) then
    print("Failed to create log directory")
end

-- 检查并轮换日志文件
local function rotateLogFile()
    local attr = fs.attributes(LOG_FILE)
    if not attr then return end

    if attr.size >= MAX_LOG_SIZE then
        local timestamp = os.date("%Y%m%d_%H%M%S")
        local newName = LOG_FILE .. "." .. timestamp .. ".old"
        os.rename(LOG_FILE, newName)
    end
end

-- 写入日志的通用函数
local function writeLog(level, message)
    rotateLogFile()
    print(message)

    local file = io.open(LOG_FILE, "a")
    if file then
        local timestamp = os.date("%Y-%m-%d %H:%M:%S")
        file:write(string.format("[%s] %s %s\n", timestamp, level, message))
        file:close()
    end
end

-- 记录操作日志
function log.action(action, details)
    local message = string.format("%s - %s", action, details or "")
    writeLog(LOG_LEVELS.ACTION, message)
end

-- 记录信息日志
function log.info(category, details)
    local message = string.format("%s - %s", category, details or "")
    writeLog(LOG_LEVELS.INFO, message)
end

-- 记录错误日志
function log.error(errorType, message, stackTrace)
    local errorMsg = string.format("%s - %s\n%s",
        errorType,
        message,
        stackTrace or debug.traceback())
    writeLog(LOG_LEVELS.ERROR, errorMsg)
end

-- 清理旧日志文件（保留最近7天的日志）
function log.cleanup()
    local days = 7
    local now = os.time()

    local iter, dir_obj = fs.dir(LOG_DIR)
    if iter then
        for file in iter, dir_obj do
            if file:match("%.old$") then
                local filepath = LOG_DIR .. file
                local attr = fs.attributes(filepath)
                if attr and (now - attr.modification) > (days * 24 * 60 * 60) then
                    os.remove(filepath)
                end
            end
        end
    end
end

function log.saveWindowsToJson(windows)
    -- 创建一个新的表来存储可序列化的数据
    local serializableWindows = {}

    for id, info in pairs(windows) do
        -- 只保存需要的数据，避免保存不可序列化的对象
        serializableWindows[tostring(id)] = {
            id = id,
            edge = info.edge,
            originalFrame = {
                x = info.originalFrame.x,
                y = info.originalFrame.y,
                w = info.originalFrame.w,
                h = info.originalFrame.h
            },
            edgeFrame = {
                x = info.edgeFrame.x,
                y = info.edgeFrame.y,
                w = info.edgeFrame.w,
                h = info.edgeFrame.h
            },
            hiddenFrame = {
                x = info.hiddenFrame.x,
                y = info.hiddenFrame.y,
                w = info.hiddenFrame.w,
                h = info.hiddenFrame.h
            },
            triggerZone = {
                x = info.triggerZone.x,
                y = info.triggerZone.y,
                w = info.triggerZone.w,
                h = info.triggerZone.h
            }
        }
    end

    -- 转换为 JSON 字符串
    local jsonString = json.encode(serializableWindows, true) -- true 为美化输出

    -- 写入文件
    local file = io.open(WINDOWS_JSON_PATH, "w")
    if file then
        file:write(jsonString)
        file:close()
        log.info("JSON Save", "Successfully saved windows data to JSON")
    else
        log.error("JSON Save", "Failed to save windows data to JSON")
    end
end

return log
