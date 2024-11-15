return {
  MOVE_THRESHOLD = 10,  -- 移动判定阈值
  ANIMATION_DURATION = 0.1,  -- 动画持续时间(时间长会有卡卡的感觉)
  EDGE_PEEK_SIZE = 6,  -- 边缘露出的宽度
  EDGE_TRIGGER_SIZE = 6,  -- 边缘触发器的宽度
  MOUSE_CHECK_INTERVAL = 0.3,  -- 鼠标移动检查间隔
  ALONE_SPACE = true, -- 独立桌面空间
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
}
