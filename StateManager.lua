local StateManager = {}
StateManager.__index = StateManager

function StateManager:new()
    local self = setmetatable({}, StateManager)
    self.states = {}
    self.windowStates = {}  -- 添加窗口状态跟踪
    return self
end

function StateManager:setState(windowId, state)
    self.states[windowId] = state
end

function StateManager:getState(windowId)
    return self.states[windowId]
end

function StateManager:removeState(windowId)
    self.states[windowId] = nil
end

function StateManager:isWindowMoving(windowId)
    local state = self.states[windowId]
    return state and state.isMoving or false
end

function StateManager:setWindowMoving(windowId, isMoving)
    local state = self.states[windowId] or {}
    state.isMoving = isMoving
    self.states[windowId] = state
end

function StateManager:setWindowHidden(windowId, isHidden)
    self.windowStates[windowId] = isHidden
end

function StateManager:isWindowHidden(windowId)
    return self.windowStates[windowId] == true
end

return StateManager
