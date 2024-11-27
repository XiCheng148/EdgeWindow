# EdgeWindow

EdgeWindow 是一个基于 Hammerspoon 的 macOS 窗口工具，它专注于将窗口隐藏到屏幕边缘这一个功能，以便更高效地管理窗口布局。

## ✨ 特性

- ⌨️ 一键隐藏：一键将窗口隐藏到屏幕左或者右边缘
- 🖱️ 快速预览：将鼠标移动到屏幕边缘自动显示/隐藏窗口
- 🔄 状态记忆：记住窗口的位置和大小
- 📱 独立空间：支持 macOS 多桌面空间
- 🎨 菜单栏控制：提供便捷的菜单栏操作界面

## 🚀 安装

1. 首先安装 [Hammerspoon](https://www.hammerspoon.org/)
2. 克隆此仓库到 Hammerspoon 的配置目录：
```bash
   git clone https://github.com/yourusername/EdgeWindow.git ~/.hammerspoon/EdgeWindow
```
3. 在 Hammerspoon 的 init.lua 中添加：
   ```lua
   require("EdgeWindow")
   ```
4. 重载 Hammerspoon 配置

## ⚙️ 配置

编辑 `config.lua` 文件来自定义设置：

## 🎮 使用方法

### 快捷键

- `Cmd + Ctrl + ←`：将窗口移动到左侧
- `Cmd + Ctrl + →`：将窗口移动到右侧
- `Cmd + Ctrl + H`：清除所有窗口布局

### 鼠标操作

1. 将窗口拖动到屏幕左边缘：窗口会自动吸附到左半屏
2. 将窗口拖动到屏幕右边缘：窗口会自动吸附到右半屏
3. 移动鼠标到屏幕边缘：显示隐藏的窗口
4. 移动鼠标离开边缘：隐藏窗口

### 菜单栏

点击菜单栏图标可以：
- 查看当前管理的窗口列表
- 快速将窗口移动到左右两侧
- 清除所有窗口布局

### 窗口状态管理优化
当前实现中，窗口事件的处理是同步的，在窗口数量较多时可能会造成性能问题。

#### 性能问题的典型场景

1. 频繁的同步处理：
- 用户拖动窗口时，每个位置变化都会触发处理
- 窗口动画过程中（最大化/最小化）的每一帧
- 多窗口同时移动（如 Mission Control 激活时）
- 调整窗口大小时的连续位置变化

2. 短时间内的重复事件：
- 窗口靠近边缘时的多次吸附判断
- 用户快速移动窗口造成的抖动
- 窗口显示/隐藏动画过程中的状态切换
- 系统行为（全屏、分屏）触发的连续状态变化

3. 频繁的UI更新：
- 窗口状态变化时的菜单栏更新
- 鼠标移动触发的窗口预览显示/隐藏
- 多窗口联动导致的连锁更新
- 需要显示窗口实时位置信息时

以下是相应的优化建议：

1. 添加事件队列机制：
```lua
-- 事件队列管理器
local EventQueue = {
    queue = {},
    processing = false,
    batchSize = 10,        -- 每批处理的事件数量
    processInterval = 16   -- 处理间隔(ms)
}

function EventQueue:push(event)
    table.insert(self.queue, event)
    self:startProcessing()
end

function EventQueue:processBatch(batch)
    -- 对同一个窗口的多个事件进行合并
    local windowEvents = {}
    for _, event in ipairs(batch) do
        local windowId = event.window:id()
        windowEvents[windowId] = event
    end
    
    -- 处理合并后的事件
    for _, event in pairs(windowEvents) do
        self:handleEvent(event)
    end
end
```

2. 状态批量更新：
```lua
-- 状态批量更新管理器
local StateUpdateManager = {
    pendingUpdates = {},
    updateInterval = 16  -- 更新间隔(ms)
}

function StateUpdateManager:queueUpdate(windowId, stateChanges)
    if not self.pendingUpdates[windowId] then
        self.pendingUpdates[windowId] = {}
    end
    -- 合并状态更新
    for key, value in pairs(stateChanges) do
        self.pendingUpdates[windowId][key] = value
    end
    
    self:scheduleUpdate()
end
```

这些优化可以：
- 减少频繁的同步处理
- 合并短时间内的重复事件
- 批量处理状态更新
- 减少UI更新频率
- 降低CPU和内存使用

建议根据实际使用场景调整 `batchSize` 和 `processInterval` 参数以获得最佳性能。

## 🔧 故障排除

如果遇到问题：

1. 确保 Hammerspoon 已被授予辅助功能权限
2. 检查控制台日志中是否有错误信息
3. 尝试重新加载 Hammerspoon 配置
4. 确认快捷键没有被其他应用程序占用

## 🤝 贡献

欢迎提交 Pull Request 或创建 Issue！

## 📄 许可证

MIT License
