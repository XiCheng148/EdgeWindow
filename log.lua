local log = {}

local fs = require("hs.fs")

-- 日志文件路径
local LOG_FILE = os.getenv("HOME") .. "/.hammerspoon/logs/app.log"
local LOG_DIR = os.getenv("HOME") .. "/.hammerspoon/logs/"

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

return log
