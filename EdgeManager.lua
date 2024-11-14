local EdgeManager = {}
EdgeManager.__index = EdgeManager

local config = require("config")
local utils = require("utils")
local WindowManager = require("WindowManager")
local StateManager = require("StateManager")
local ErrorHandler = require("ErrorHandler")

function EdgeManager:new()
    local self = setmetatable({}, EdgeManager)
    self.windowManager = WindowManager:new()
    self.stateManager = StateManager:new()
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

function EdgeManager:handleMouseMove(point)
    for _, info in pairs(self.windowManager:getAllWindows()) do
        if self:shouldShowWindow(point, info) then
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
    local zone = info.triggerZone
    return point.x >= zone.x and
        point.x <= zone.x + zone.w and
        point.y >= zone.y and
        point.y <= zone.y + zone.h
end

function EdgeManager:handleHotkey(edge)
    return ErrorHandler.wrap(function()
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
                    self:rehideWindow(windowInfo)
                end
            end)
        else
            -- todo
        end
    end, "handleHotkey")()
end

function EdgeManager:removeWindow(window)
    local info = self.windowManager:getWindow(window:id())
    if info then
        if info.leaveWatcher then
            info.leaveWatcher:stop()
        end
        self.windowManager:removeWindow(window:id())
        self.stateManager:removeState(window:id())
    end
end

function EdgeManager:rehideWindow(info)
    self.stateManager:setWindowMoving(info.window:id(), true)
    info.window:setFrame(info.hiddenFrame, config.ANIMATION_DURATION)
    hs.timer.doAfter(config.ANIMATION_DURATION, function()
        self.stateManager:setWindowMoving(info.window:id(), false)
    end)
end

function EdgeManager:showWindow(info)
    self.stateManager:setWindowMoving(info.window:id(), true)
    info.window:setFrame(info.edgeFrame, config.ANIMATION_DURATION)

    hs.timer.doAfter(config.ANIMATION_DURATION, function()
        info.window:focus()
        self.stateManager:setWindowMoving(info.window:id(), false)
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
    end
end

function EdgeManager:destroy()
    if self.mouseWatcher then
        self.mouseWatcher:stop()
        self.mouseWatcher = nil
    end

    for _, info in pairs(self.windowManager:getAllWindows()) do
        if info.leaveWatcher then
            info.leaveWatcher:stop()
            info.leaveWatcher = nil
        end
        -- 确保窗口回到原始位置
        info.window:setFrame(info.originalFrame)
    end

    self.windowManager = nil
    self.stateManager = nil
    collectgarbage("collect")
end

return EdgeManager
