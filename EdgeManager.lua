local EdgeManager = {}
EdgeManager.__index = EdgeManager
local log = require("log")
local config = require("config")
local WindowManager = require("WindowManager")
local StateManager = require("StateManager")
local Menubar = require("Menubar")

function EdgeManager:new()
    local self = setmetatable({}, EdgeManager)
    self.windowManager = WindowManager:new()
    self.stateManager = StateManager:new()

    -- 创建菜单栏，只传入需要的回调函数
    self.menubar = Menubar:new({
        addToLeft = function()
            self:handleHotkey("left")
        end,
        addToRight = function()
            self:handleHotkey("right")
        end,
        clearAll = function()
            self:clearAll()
        end,
        getAllWindows = function()
            return self.windowManager:getAllWindows()
        end
    })

    self:init()
    return self
end

function EdgeManager:init()
    -- 缓存更多频繁使用的值
    self.mainScreen = hs.screen.mainScreen()
    self.mainScreenFrame = self.mainScreen:fullFrame()
    self.triggerSize = config.EDGE_TRIGGER_SIZE
    self.moveThreshold = config.MOVE_THRESHOLD
    self.animationDuration = config.ANIMATION_DURATION
    self.aloneSpace = config.ALONE_SPACE

    -- 监听屏幕变化时更新所有缓存
    hs.screen.watcher.new(function()
        self.mainScreen = hs.screen.mainScreen()
        self.mainScreenFrame = self.mainScreen:fullFrame()
    end):start()

    self:setupWindowFilter()
    self:setupMouseEventTap()
    self:setupHotkeys()
end

function EdgeManager:isPointInRect(point, rect)
    -- 先检查 y 轴，因为通常触发区域是垂直的长条
    if point.y < rect.y or point.y > rect.y + rect.h then
        return false
    end
    return point.x >= rect.x and point.x <= rect.x + rect.w
end

function EdgeManager:setupWindowFilter()
    -- 合并窗口事件监听
    local windowFilter = hs.window.filter.new()
    local events = {
        [hs.window.filter.windowUnfocused] = self.handleWindowUnfocus,
        [hs.window.filter.windowDestroyed] = self.handleWindowClosed,
        [hs.window.filter.windowMoved] = self.handleWindowMoved
    }

    for event, handler in pairs(events) do
        windowFilter:subscribe(event, function(window)
            handler(self, window)
        end)
    end
end

function EdgeManager:handleWindowMoved(window)
    local info = self.windowManager:getWindow(window:id())
    if not info then return end

    -- 如果窗口正在进行显示/隐藏动画，忽略这次移动
    if self.stateManager:isWindowMoving(window:id()) then
        return
    end

    local currentFrame = window:frame()

    -- 检查是否是用户手动拖动
    -- 通过比较当前位置与原始位置和隐藏位置的关系来判断
    local isAtEdgePosition =
        math.abs(currentFrame.x - info.edgeFrame.x) < config.MOVE_THRESHOLD or
        math.abs(currentFrame.x - info.hiddenFrame.x) < config.MOVE_THRESHOLD

    -- 如果不在边缘位置，说明是用户手动拖动
    if not isAtEdgePosition then
        -- 移除窗口管理
        hs.alert.show(string.format("🔄 移除「%s」", window:title()))
        if info.leaveWatcher then
            info.leaveWatcher:stop()
            info.leaveWatcher = nil
        end
        self.windowManager:removeWindow(window:id())
        self.stateManager:removeState(window:id())
        self.menubar:updateMenu()
        return
    end

    -- 如果只是 y 轴移动，更新相关位置信息
    if currentFrame.y ~= info.hiddenFrame.y then
        -- 更新各种frame的y轴位置
        info.hiddenFrame.y = currentFrame.y
        info.edgeFrame.y = currentFrame.y
        -- 更新触发区域的y轴位置
        info.triggerZone.y = currentFrame.y
    end
    self.menubar:updateMenu()
end

-- 添加节流函数
local function throttle(fn, limit)
    local lastRun = 0
    local timer = nil
    return function(...)
        local args = { ... }
        local now = hs.timer.secondsSinceEpoch()

        -- 如果距离上次执行时间超过限制，立即执行
        if (now - lastRun) >= limit then
            lastRun = now
            return fn(table.unpack(args))
        end

        -- 否则，取消之前的计时器（如果存在）并设置新的计时器
        if timer then
            timer:stop()
        end

        -- 设置新的计时器，确保函数最终会被执行
        timer = hs.timer.doAfter(limit - (now - lastRun), function()
            lastRun = hs.timer.secondsSinceEpoch()
            fn(table.unpack(args))
        end)
    end
end

function EdgeManager:setupMouseEventTap()
    local throttledMouseMoved = throttle(function(e)
        if not self.windowManager then return end

        -- 使用单次循环检查多个状态
        local windows = self.windowManager:getAllWindows()
        for _, info in pairs(windows) do
            local windowId = info.window:id()
            if self.stateManager:isWindowMoving(windowId) or
                not self.stateManager:isWindowHidden(windowId) then
                return
            end
        end

        local point = hs.mouse.absolutePosition()
        self:handleWindowsMouseEvent(point, windows)
    end, 0.033)

    -- 设置事件监听
    self.mouseEventTap = hs.eventtap.new(
        { hs.eventtap.event.types.mouseMoved },
        function(e)
            throttledMouseMoved(e)
            return false
        end
    )

    self.mouseEventTap:start()
end

function EdgeManager:handleWindowsMouseEvent(point, windows)
    -- 先缓存边缘检查结果
    local isNearLeftEdge = point.x <= self.triggerSize
    local isNearRightEdge = point.x >= self.mainScreenFrame.w - self.triggerSize

    if not (isNearLeftEdge or isNearRightEdge) then
        return
    end

    for _, info in pairs(windows) do
        local windowId = info.window:id()

        -- 如果窗口正在移动，跳过处理
        if self.stateManager:isWindowMoving(windowId) then
            goto continue
        end

        -- 使用 shouldShowWindow 检查空间和触发区域
        if self:shouldShowWindow(point, info) then
            -- 如果窗口当前是隐藏的，显示它
            if self.stateManager:isWindowHidden(windowId) then
                self:showWindow(info)
                break -- 显示一个窗口后就退出循环
            end
        else
            -- 检查鼠标是否在窗口区域外
            if not self.stateManager:isWindowHidden(windowId) and
                not self:isPointInRect(point, info.window:frame()) then
                -- 如果鼠标在窗口外且窗口是显示的，隐藏它
                self:rehideWindow(info)
                break -- 隐藏一个窗口后就退出循环
            end
        end

        ::continue::
    end
end

function EdgeManager:setupHotkeys()
    hs.hotkey.bind(
        config.HOTKEYS.LEFT.mods,
        config.HOTKEYS.LEFT.key,
        function()
            self:handleHotkey("left")
        end
    )

    hs.hotkey.bind(
        config.HOTKEYS.RIGHT.mods,
        config.HOTKEYS.RIGHT.key,
        function()
            self:handleHotkey("right")
        end
    )

    hs.hotkey.bind(
        config.HOTKEYS.CLEAR.mods,
        config.HOTKEYS.CLEAR.key,
        function()
            self:clearAll()
        end
    )
end

function EdgeManager:handleWindowUnfocus(window)
    local info = self.windowManager:getWindow(window:id())
    if not info then return end

    local currentFrame = window:frame()
    local isShown = math.abs(currentFrame.x - info.originalFrame.x) < config.MOVE_THRESHOLD

    if isShown then
        self:rehideWindow(info)
    end
end

function EdgeManager:handleWindowClosed(window)
    local info = self.windowManager:getWindow(window:id())
    if info then
        local windowTitle = window:title() or "未知窗口"
        log.action("🚫", string.format("关闭「%s」", windowTitle))
        -- 清理窗口相关的所有状态
        if info.leaveWatcher then
            info.leaveWatcher:stop()
            info.leaveWatcher = nil
        end
        self.windowManager:removeWindow(window:id())
        self.stateManager:removeState(window:id())
        self.stateManager:setWindowHidden(window:id(), false)
        self.menubar:updateMenu()
    end
end

function EdgeManager:shouldShowWindow(point, info)
    local currentSpace = hs.spaces.focusedSpace()
    local zone = info.triggerZone

    -- 没开启独立空间直接计算触发区域
    if not config.ALONE_SPACE then
        return self:isPointInRect(point, zone)
    end

    -- 开启独立空间需要判断保存的空间和当前的空间是否相同
    return currentSpace == info.space and self:isPointInRect(point, zone)
end

function EdgeManager:handleHotkey(edge)
    log.action("⌨️", string.format("触发边缘: %s", edge == "left" and "左" or "右"))
    -- 获取当前焦点窗口
    local window = hs.window.focusedWindow()
    if not window then
        hs.alert.show("⚠️ 未能找到活动窗口")
        return
    end

    -- 获取当前窗口所在的屏幕
    local currentScreen = window:screen()
    if not currentScreen then
        -- todo
        return
    end

    -- 检查窗口是否已经被管理
    local info = self.windowManager:getWindow(window:id())

    -- 如果窗口已经被管理
    if info then
        -- 如果窗口在同一边，直接显示
        if info.edge == edge then
            if not self.stateManager:isWindowMoving(window:id()) then
                self:showWindow(info)
            end
            return
        end

        -- 如果窗口在另一边，先移除它并等待动画完成
        self.stateManager:setWindowMoving(window:id(), true)

        -- 恢复窗口到原始位置
        window:setFrame(info.originalFrame, config.ANIMATION_DURATION)

        -- 清理原有的监视器和状态
        if info.leaveWatcher then
            info.leaveWatcher:stop()
            info.leaveWatcher = nil
        end

        -- 移除窗口管理
        self.windowManager:removeWindow(window:id())
        self.menubar:updateMenu()

        -- 等待动画完成后添加到新的边缘
        hs.timer.doAfter(config.ANIMATION_DURATION, function()
            self.stateManager:setWindowMoving(window:id(), false)

            -- 添加到新的边缘
            local windowInfo = self.windowManager:addWindow(window, edge)
            if windowInfo then
                -- 确保窗口被正确添加后再隐藏
                hs.timer.doAfter(0.1, function()
                    if self.windowManager:getWindow(window:id()) then
                        self:rehideWindow(windowInfo)
                    end
                end)
            end
        end)

        return
    end

    -- 如果窗口还未被管理，直接添加
    local windowInfo = self.windowManager:addWindow(window, edge)
    if windowInfo then
        -- 确保窗口被正确添加后再隐藏
        hs.timer.doAfter(0.1, function()
            if self.windowManager:getWindow(window:id()) then
                self.stateManager:setWindowHidden(window:id(), false)
                self:rehideWindow(windowInfo)
            end
        end)
    else
        -- todo
    end
    self.menubar:updateMenu()
end

function EdgeManager:rehideWindow(info)
    local windowTitle = info.window:title() or "未知窗口"
    log.action("🚫", string.format("隐藏「%s」", windowTitle))

    self.stateManager:setWindowMoving(info.window:id(), true)
    info.window:setFrame(info.hiddenFrame, config.ANIMATION_DURATION)
    hs.timer.doAfter(config.ANIMATION_DURATION, function()
        self.stateManager:setWindowMoving(info.window:id(), false)
        self.stateManager:setWindowHidden(info.window:id(), true)
    end)
end

function EdgeManager:showWindow(info)
    local windowId = info.window:id()
    if not self.stateManager:isWindowHidden(windowId) or
        self.stateManager:isWindowMoving(windowId) then
        return
    end

    -- 获取窗口标题
    local windowTitle = info.window:title() or "未知窗口"
    log.action("👀", string.format("显示「%s」", windowTitle))

    self.stateManager:setWindowMoving(windowId, true)
    info.window:focus()
    info.window:setFrame(info.edgeFrame, config.ANIMATION_DURATION)

    hs.timer.doAfter(config.ANIMATION_DURATION, function()
        self.stateManager:setWindowMoving(windowId, false)
        self.stateManager:setWindowHidden(info.window:id(), false)
    end)

    self:setupLeaveWatcher(info)
end

function EdgeManager:setupLeaveWatcher(info)
    if info.leaveWatcher then
        info.leaveWatcher:stop()
        info.leaveWatcher = nil
    end

    local throttledLeaveCheck = throttle(function(e)
        local point = hs.mouse.absolutePosition()
        local frame = info.window:frame()

        if not self:isPointInRect(point, frame) and
            not self.stateManager:isWindowMoving(info.window:id()) then
            info.leaveWatcher:stop()
            info.leaveWatcher = nil
            self:rehideWindow(info)
        end
    end, 0.05) -- 可以适当提高检查间隔，减少性能消耗

    info.leaveWatcher = hs.eventtap.new(
        { hs.eventtap.event.types.mouseMoved },
        throttledLeaveCheck
    )

    info.leaveWatcher:start()
end

function EdgeManager:clearAll()
    if not self.windowManager then return end
    
    -- 先收集所有需要处理的窗口信息
    local windowsToRemove = {}
    for windowId, info in pairs(self.windowManager:getAllWindows()) do
        windowsToRemove[windowId] = info
    end
    
    -- 处理收集到的窗口
    for windowId, info in pairs(windowsToRemove) do
        -- 立即停止所有监视器
        if info.leaveWatcher then
            info.leaveWatcher:stop()
            info.leaveWatcher = nil
        end
        
        -- 批量处理状态更新
        self.stateManager:setWindowMoving(windowId, true)
        info.window:setFrame(info.originalFrame, self.animationDuration)
        info.window:focus()
        
        -- 使用闭包保存 windowId，避免创建额外的表
        hs.timer.doAfter(self.animationDuration, function()
            if self.stateManager then -- 检查是否已被销毁
                self.stateManager:setWindowMoving(windowId, false)
            end
        end)
        
        -- 移除窗口管理
        self.windowManager:removeWindow(windowId)
        self.stateManager:removeState(windowId)
        self.stateManager:setWindowHidden(windowId, false)
    end
    
    self.menubar:updateMenu()
    hs.alert.show('✨ 已清除所有窗口')
end

function EdgeManager:destroy()
    if self.mouseEventTap then
        self.mouseEventTap:stop()
        self.mouseEventTap = nil
    end
    self.windowManager = nil
    self.stateManager = nil
    self:clearAll()
    collectgarbage("collect")
    log.operation("🔧 系统已销毁")
end

return EdgeManager
