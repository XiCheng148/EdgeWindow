local EdgeManager = require("EdgeManager")
local log = require("log")

-- 设置Hammerspoon窗口过滤器的日志级别
hs.window.filter.setLogLevel("error")

-- 初始化边缘管理器
local function initializeEdgeManager()
    local manager = EdgeManager:new()

    -- 注册程序退出时的清理回调
    hs.shutdownCallback = function()
        if manager then
            manager:destroy()
        end
    end

    return manager
end

-- 使用错误处理包装初始化过程
local success, manager = xpcall(initializeEdgeManager, function(err)
    log.error("Initialization", "Failed to initialize EdgeManager", debug.traceback())
    return err
end)

-- 将manager暴露到全局作用域以便调试
_G.edgeManager = manager
