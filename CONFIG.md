# Hammerspoon 窗口管理配置说明

## 配置项说明

### 1. 移动阈值
```lua
MOVE_THRESHOLD = 30  -- 单位：像素
```
- **作用**：判定窗口是否已经移动的最小距离
- **注意事项**：
  - 值太小可能导致轻微抖动就触发移动
  - 值太大会让窗口移动不够敏感
- **建议值**：8-30 像素

### 2. 动画持续时间
```lua
ANIMATION_DURATION = 0.1  -- 单位：秒
```
- **作用**：控制窗口移动/隐藏的动画时长
- **注意事项**：
  - 值太大会让操作感觉卡顿
  - 值太小动画会显得突兀
  - 会影响 CPU 使用率
  - 0 就是使用系统默认的动画（通常情况下没问题，但有些特殊的窗口会导致动画消失）
- **建议值**：0-0.2 秒 

### 3. 边缘露出宽度
```lua
EDGE_PEEK_SIZE = 6  -- 单位：像素
```
- **作用**：窗口隐藏时在屏幕边缘露出的宽度
- **注意事项**：
  - 值太小可能难以发现隐藏的窗口
  - 值太大会占用过多屏幕空间
  - 需要考虑高分辨率屏幕的缩放比例
- **建议值**：4-8 像素

### 4. 边缘触发区域宽度
```lua
EDGE_TRIGGER_SIZE = 6  -- 单位：像素
```
- **作用**：鼠标触发窗口显示的感应区域宽度
- **注意事项**：
  - 值太小不容易触发
  - 值太大容易误触发
  - 建议与 EDGE_PEEK_SIZE 保持一致或稍大
- **建议值**：6-10 像素

### 5. 独立空间模式
```lua
ALONE_SPACE = true
```
- **作用**：控制是否在不同的 macOS 空间（桌面）独立管理窗口
- **注意事项**：
  - true：每个空间独立管理窗口状态
  - false：所有空间共享窗口状态
  - 切换后需要重新设置窗口
- **建议值**：根据个人使用习惯选择

### 6. 快捷键设置
```lua
HOTKEYS = {
    LEFT = {
        mods = {"cmd", "ctrl"},
        key = "left"
    },
    RIGHT = {
        mods = {"cmd", "ctrl"},
        key = "right"
    },
    CLEAR = {
        mods = {"cmd", "ctrl"},
        key = "h"
    }
}
```
- **作用**：定义操作快捷键
- **可用修饰键**：
  - cmd（⌘）
  - ctrl（⌃）
  - alt/option（⌥）
  - shift（⇧）
- **注意事项**：
  - 避免与系统快捷键冲突
  - 保持快捷键的一致性和直观性
  - 考虑用户的键盘布局

## 性能优化建议

1. **动画设置**：
   - 在低性能设备上可以减小 `ANIMATION_DURATION`
   - 如果感觉动画卡顿，可以调整或禁用动画

2. **触发区域**：
   - 高分辨率屏幕可能需要适当增加 `EDGE_PEEK_SIZE` 和 `EDGE_TRIGGER_SIZE`
   - 多显示器设置下建议适当增加触发区域

3. **移动阈值**：
   - 使用触控板的用户可能需要更小的 `MOVE_THRESHOLD`
   - 使用鼠标的用户可以适当增加阈值

## 配置示例

### 标准配置（一般用户）
```lua
return {
    MOVE_THRESHOLD = 10,
    ANIMATION_DURATION = 0.1,
    EDGE_PEEK_SIZE = 6,
    EDGE_TRIGGER_SIZE = 6,
    ALONE_SPACE = true,
    HOTKEYS = {
        LEFT = { mods = {"cmd", "ctrl"}, key = "left" },
        RIGHT = { mods = {"cmd", "ctrl"}, key = "right" },
        CLEAR = { mods = {"cmd", "ctrl"}, key = "h" }
    }
}
```

### 高性能配置
```lua
return {
    MOVE_THRESHOLD = 8,
    ANIMATION_DURATION = 0.05,
    EDGE_PEEK_SIZE = 4,
    EDGE_TRIGGER_SIZE = 4,
    ALONE_SPACE = true,
    HOTKEYS = {
        LEFT = { mods = {"cmd", "ctrl"}, key = "left" },
        RIGHT = { mods = {"cmd", "ctrl"}, key = "right" },
        CLEAR = { mods = {"cmd", "ctrl"}, key = "h" }
    }
}
```

### 高分辨率屏幕配置
```lua
return {
    MOVE_THRESHOLD = 15,
    ANIMATION_DURATION = 0.1,
    EDGE_PEEK_SIZE = 10,
    EDGE_TRIGGER_SIZE = 10,
    ALONE_SPACE = true,
    HOTKEYS = {
        LEFT = { mods = {"cmd", "ctrl"}, key = "left" },
        RIGHT = { mods = {"cmd", "ctrl"}, key = "right" },
        CLEAR = { mods = {"cmd", "ctrl"}, key = "h" }
    }
}
```
