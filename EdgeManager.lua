local EdgeManager = {}
EdgeManager.__index = EdgeManager
local log = require("log")
local config = require("config")
local WindowManager = require("WindowManager")
local StateManager = require("StateManager")
local Menubar = require("Menubar")

local lastMouseCheck = 0

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
    self:setupWindowFilter()
    self:setupMouseWatcher()
    self:setupHotkeys()
end

function EdgeManager:isPointInRect(point, rect)
    return point.x >= rect.x and point.x <= rect.x + rect.w and
        point.y >= rect.y and point.y <= rect.y + rect.h
end

function EdgeManager:setupWindowFilter()
    local windowFilter = hs.window.filter.new()
    windowFilter:subscribe(hs.window.filter.windowUnfocused, function(window)
        self:handleWindowUnfocus(window)
    end)

    -- 添加窗口关闭事件监听
    windowFilter:subscribe(hs.window.filter.windowDestroyed, function(window)
        self:handleWindowClosed(window)
    end)

    -- 添加窗口移动事件监听
    windowFilter:subscribe(hs.window.filter.windowMoved, function(window)
        self:handleWindowMoved(window)
    end)
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

function EdgeManager:setupMouseWatcher()
    self.mouseWatcher = hs.eventtap.new({ hs.eventtap.event.types.mouseMoved }, function(e)
        self:handleMouseMove(hs.mouse.absolutePosition())
    end)
    self.mouseWatcher:start()
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

function EdgeManager:handleMouseMove(point)
    local now = hs.timer.secondsSinceEpoch()
    if now - lastMouseCheck < config.MOUSE_CHECK_INTERVAL then
        return
    end
    lastMouseCheck = now

    for _, info in pairs(self.windowManager:getAllWindows()) do
        if self.stateManager:isWindowHidden(info.window:id()) and
            self:shouldShowWindow(point, info) then
            hs.timer.doAfter(0.1, function()
                if self:shouldShowWindow(hs.mouse.absolutePosition(), info) then
                    self:showWindow(info)
                end
            end)
            break
        end
    end
end

function EdgeManager:shouldShowWindow(point, info)
    local currentSpace = hs.spaces.focusedSpace()
    local zone = info.triggerZone
    -- 没开启独立空间直接计算
    if not config.ALONE_SPACE then
        return point.x >= zone.x and
            point.x <= zone.x + zone.w and
            point.y >= zone.y and
            point.y <= zone.y + zone.h
    end
    -- 开启独立空间需要判断保存的空间和当前的空间是否相同
    if config.ALONE_SPACE and currentSpace == info.space then
        return point.x >= zone.x and
            point.x <= zone.x + zone.w and
            point.y >= zone.y and
            point.y <= zone.y + zone.h
    end
end

function EdgeManager:handleHotkey(edge)
    log.action("Hotkey", string.format("Triggered edge: %s", edge))
    -- 获取当前焦点窗口
    local window = hs.window.focusedWindow()
    if not window then
        -- todo
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
    log.action("Window", string.format("Hiding window %d", info.window:id()))
    self.stateManager:setWindowMoving(info.window:id(), true)
    info.window:setFrame(info.hiddenFrame, config.ANIMATION_DURATION)
    hs.timer.doAfter(config.ANIMATION_DURATION, function()
        self.stateManager:setWindowMoving(info.window:id(), false)
        self.stateManager:setWindowHidden(info.window:id(), true)
    end)
end

function EdgeManager:showWindow(info)
    log.action("Window", string.format("Showing window %d", info.window:id()))
    if not self.stateManager:isWindowHidden(info.window:id()) then
        return
    end

    self.stateManager:setWindowMoving(info.window:id(), true)
    info.window:setFrame(info.edgeFrame, config.ANIMATION_DURATION)

    hs.timer.doAfter(config.ANIMATION_DURATION, function()
        info.window:focus()
        self.stateManager:setWindowMoving(info.window:id(), false)
        self.stateManager:setWindowHidden(info.window:id(), false)
    end)

    self:setupLeaveWatcher(info)
end

function EdgeManager:setupLeaveWatcher(info)
    if info.leaveWatcher then
        info.leaveWatcher:stop()
        info.leaveWatcher = nil
    end

    info.leaveWatcher = hs.eventtap.new({ hs.eventtap.event.types.mouseMoved }, function(e)
        local point = hs.mouse.absolutePosition()
        local frame = info.window:frame()

        if not self:isPointInRect(point, frame) and
            not self.stateManager:isWindowMoving(info.window:id()) then
            info.leaveWatcher:stop()
            info.leaveWatcher = nil
            self:rehideWindow(info)
        end
    end)

    info.leaveWatcher:start()
end

function EdgeManager:clearAll()
    log.action("Window", "Clearing all windows")
    for _, info in pairs(self.windowManager:getAllWindows()) do
        self.stateManager:setWindowMoving(info.window:id(), true)
        info.window:setFrame(info.originalFrame, config.ANIMATION_DURATION)
        hs.timer.doAfter(config.ANIMATION_DURATION, function()
            self.stateManager:setWindowMoving(info.window:id(), false)
        end)
        if info.leaveWatcher then
            info.leaveWatcher:stop()
        end
        self.windowManager:removeWindow(info.window:id())
        self.stateManager:removeState(info.window:id())
        self.stateManager:setWindowHidden(info.window:id(), false)
    end
    self.menubar:updateMenu()
end

function EdgeManager:destroy()
    if self.mouseWatcher then
        self.mouseWatcher:stop()
        self.mouseWatcher = nil
    end
    self.windowManager = nil
    self.stateManager = nil
    self:clearAll()
    collectgarbage("collect")
    log.operation("销毁")
end

return EdgeManager
