local log = require("log")
local config = require("config")

local WindowManager = {}
WindowManager.__index = WindowManager

function WindowManager:new()
    local self = setmetatable({}, WindowManager)
    self.windows = {}
    return self
end

function WindowManager:calculateHiddenFrame(window, edge)
    local frame = window:frame()
    local hiddenFrame = frame:copy()
    local screen = window:screen():frame()  -- 使用窗口所在的屏幕
    local screenFrame = window:screen():fullFrame()  -- 获取屏幕的绝对坐标

    if edge == "left" then
        hiddenFrame.x = screenFrame.x - frame.w + config.EDGE_PEEK_SIZE
    elseif edge == "right" then
        hiddenFrame.x = screenFrame.x + screen.w - config.EDGE_PEEK_SIZE
    end

    log.info("Hidden Frame", string.format("Hidden frame: %s", hiddenFrame))
    return hiddenFrame
end

function WindowManager:addWindow(window, edge)
    local id = window:id()
    local frame = window:frame()
    local screen = window:screen()
    local currentSpace = hs.spaces.focusedSpace()
    local edgeString = ""
    if edge == "left" then
        edgeString = "←"
    elseif edge == "right" then
        edgeString = "→"
    else
        edgeString = "⚠️"
    end
    local title = window:title()
    self.windows[id] = {
        window = window,
        title = edgeString .. "  " .. title,
        screen = screen,  -- 添加屏幕信息
        originalFrame = frame,
        edgeFrame = self:calculateEdgeFrame(window, edge),
        hiddenFrame = self:calculateHiddenFrame(window, edge),
        triggerZone = self:calculateTriggerZone(window, edge),
        space = currentSpace,
        edge = edge
    }
    log.info("Added window", string.format("Added window %d to %s edge", id, edge))
    log.saveWindowsToJson(self.windows)
    return self.windows[id]
end

function WindowManager:removeWindow(windowId)
    self.windows[windowId] = nil
    log.info("Remove Window", string.format(windowId))
    log.saveWindowsToJson(self.windows)
end

function WindowManager:getWindow(windowId)
    return self.windows[windowId]
end

function WindowManager:getAllWindows()
    return self.windows
end

-- 计算触发区域
function WindowManager:calculateTriggerZone(window, edge)
    local frame = window:frame()
    local screen = window:screen():frame()
    local screenFrame = window:screen():fullFrame()  -- 获取屏幕的绝对坐标
    local triggerWidth = config.EDGE_TRIGGER_SIZE + 1
    local zone = {
        y = frame.y,
        h = frame.h
    }

    if edge == "left" then
        zone.x = screenFrame.x  -- 使用屏幕的绝对X坐标
        zone.w = triggerWidth
    elseif edge == "right" then
        zone.x = screenFrame.x + screen.w - (triggerWidth)
        zone.w = triggerWidth
    end

    log.info("Trigger Zone", string.format("Trigger zone: %s", zone))
    return zone
end

function WindowManager:calculateEdgeFrame(window, edge)
    local frame = window:frame()
    local edgeFrame = frame:copy()
    local screen = window:screen():frame()
    local screenFrame = window:screen():fullFrame()  -- 获取屏幕的绝对坐标

    if edge == "left" then
        edgeFrame.x = screenFrame.x  -- 使用屏幕的绝对X坐标
    elseif edge == "right" then
        edgeFrame.x = screenFrame.x + screen.w - frame.w
    end

    log.info("Edge Frame", string.format("Edge frame: %s", edgeFrame))
    return edgeFrame
end

return WindowManager
